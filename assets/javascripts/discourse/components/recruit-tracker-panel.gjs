import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { or } from "truth-helpers";
import DButton from "discourse/components/d-button";
import Form from "discourse/components/form";
import UserAvatar from "discourse/components/user-avatar";
import icon from "discourse/helpers/d-icon";
import formatDate from "discourse/helpers/format-date";
import loadingSpinner from "discourse/helpers/loading-spinner";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

/**
 * @component recruit-tracker-panel
 * @param {User} user
 */
export default class RecruitTrackerPanel extends Component {
  @service dialog;

  /** @type {boolean} */
  @tracked isLoading = true;

  /** @type {boolean} */
  @tracked isVisible = false;

  /** @type {Object|null} */
  @tracked data = null;

  /** @type {Object} */
  @tracked statusFormData = { status: null };

  /** @type {Object} */
  @tracked noteFormData = { note: "", pinned: false };

  /** @type {Object|null} */
  statusFormApi = null;

  /** @type {Object|null} */
  noteFormApi = null;

  /**
   * Returns whether the current user can manage recruit data.
   *
   * @returns {boolean}
   */
  get canManage() {
    return this.data?.can_manage === true;
  }

  /**
   * Returns the current status label, or the configured empty label.
   *
   * @returns {string}
   */
  get statusLabel() {
    return this.data?.status_label || i18n("discourse_recruit_tracker.status.none");
  }

  /**
   * Returns the status options for the select input.
   *
   * @returns {Array<Object>}
   */
  get statusOptions() {
    return this.data?.status_options || [];
  }

  /**
   * Returns the current notes list.
   *
   * @returns {Array<Object>}
   */
  get notes() {
    return this.data?.notes || [];
  }

  /**
   * Returns the status history list.
   *
   * @returns {Array<Object>}
   */
  get history() {
    return this.data?.history || [];
  }

  /**
   * Registers the status form API for later updates.
   *
   * @param {Object} api
   */
  @action
  registerStatusFormApi(api) {
    this.statusFormApi = api;
  }

  /**
   * Registers the note form API for later updates.
   *
   * @param {Object} api
   */
  @action
  registerNoteFormApi(api) {
    this.noteFormApi = api;
  }

  /**
   * Loads recruit tracking data for the user.
   */
  @action
  async loadData() {
    if (!this.args.user?.id) {
      this.isVisible = false;
      this.isLoading = false;
      return;
    }

    this.isLoading = true;

    try {
      const data = await ajax(`/recruit-tracker/users/${this.args.user.id}.json`);
      this.data = data;
      this.statusFormData = { status: data.status };
      this.noteFormData = { note: "", pinned: false };
      this.statusFormApi?.set("status", data.status);
      this.noteFormApi?.setProperties({ note: "", pinned: false });
      this.isVisible = true;
    } catch (error) {
      if (error?.jqXHR?.status !== 404) {
        popupAjaxError(error);
      }
      this.isVisible = false;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Submits a status update.
   *
   * @param {Object} data
   */
  @action
  async submitStatus(data) {
    try {
      await ajax(`/recruit-tracker/users/${this.args.user.id}/status`, {
        type: "PUT",
        data: { status: data.status },
      });
      await this.loadData();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  /**
   * Submits a new recruit note.
   *
   * @param {Object} data
   */
  @action
  async submitNote(data) {
    try {
      await ajax(`/recruit-tracker/users/${this.args.user.id}/notes`, {
        type: "POST",
        data: { note: data.note, pinned: data.pinned },
      });
      await this.loadData();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  /**
   * Toggles the pinned state of a note.
   *
   * @param {Object} note
   */
  @action
  async togglePin(note) {
    try {
      await ajax(`/recruit-tracker/notes/${note.id}`, {
        type: "PUT",
        data: { pinned: !note.pinned },
      });
      await this.loadData();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  /**
   * Confirms and deletes a note.
   *
   * @param {Object} note
   */
  @action
  deleteNote(note) {
    this.dialog.yesNoConfirm({
      message: i18n("discourse_recruit_tracker.notes.confirm_delete"),
      didConfirm: () => this.performDelete(note),
    });
  }

  /**
   * Deletes a note after confirmation.
   *
   * @param {Object} note
   */
  @action
  async performDelete(note) {
    try {
      await ajax(`/recruit-tracker/notes/${note.id}`, {
        type: "DELETE",
      });
      await this.loadData();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    {{#if (or this.isVisible this.isLoading)}}
      <section
        class="recruit-tracker-panel user-profile-primary-outlet"
        {{didInsert this.loadData}}
      >
        <header class="recruit-tracker-panel__header">
          <h2 class="recruit-tracker-panel__title">
            {{i18n "discourse_recruit_tracker.panel.title"}}
          </h2>
          {{#if this.isLoading}}
            <span class="recruit-tracker-panel__loading">
              {{loadingSpinner size="small"}}
            </span>
          {{/if}}
        </header>

        {{#if this.isVisible}}
          <div class="recruit-tracker-panel__section">
            <div class="recruit-tracker-panel__status">
              <span class="recruit-tracker-panel__status-label">
                {{i18n "discourse_recruit_tracker.status.label"}}
              </span>
              <span class="recruit-tracker-panel__status-value">
                {{this.statusLabel}}
              </span>
            </div>

            {{#if this.canManage}}
              <Form
                @data={{this.statusFormData}}
                @onRegisterApi={{this.registerStatusFormApi}}
                @onSubmit={{this.submitStatus}}
                class="recruit-tracker-panel__form"
                as |form|
              >
                <form.Field
                  @name="status"
                  @title={{i18n "discourse_recruit_tracker.status.update"}}
                  @format="large"
                  as |field|
                >
                  <field.Select as |select|>
                    {{#each this.statusOptions as |option|}}
                      <select.Option @value={{option.id}}>
                        {{option.name}}
                      </select.Option>
                    {{/each}}
                  </field.Select>
                </form.Field>
                <form.Actions>
                  <form.Submit
                    @label="discourse_recruit_tracker.status.save"
                    class="btn-primary"
                  />
                </form.Actions>
              </Form>
            {{/if}}
          </div>

          <div class="recruit-tracker-panel__section">
            <div class="recruit-tracker-panel__section-header">
              <h3>{{i18n "discourse_recruit_tracker.notes.title"}}</h3>
            </div>

            {{#if this.notes.length}}
              <ul class="recruit-tracker-panel__notes">
                {{#each this.notes as |note|}}
                  <li class="recruit-tracker-panel__note">
                    <div class="recruit-tracker-panel__note-header">
                      <UserAvatar @user={{note.created_by}} @size="tiny" />
                      <span class="recruit-tracker-panel__note-user">
                        {{note.created_by.username}}
                      </span>
                      <span class="recruit-tracker-panel__note-date">
                        {{formatDate note.created_at format="tiny" noTitle="true"}}
                      </span>
                      {{#if note.pinned}}
                        <span class="recruit-tracker-panel__note-pinned">
                          {{icon "thumbtack"}}
                        </span>
                      {{/if}}
                    </div>
                    <p class="recruit-tracker-panel__note-body">{{note.note}}</p>
                    {{#if this.canManage}}
                      <div class="recruit-tracker-panel__note-actions">
                        <DButton
                          @action={{fn this.togglePin note}}
                          @icon="thumbtack"
                          @label={{if
                            note.pinned
                            "discourse_recruit_tracker.notes.unpin"
                            "discourse_recruit_tracker.notes.pin"
                          }}
                          @buttonClass="btn-small"
                        />
                        <DButton
                          @action={{fn this.deleteNote note}}
                          @icon="trash-can"
                          @label="discourse_recruit_tracker.notes.delete"
                          @buttonClass="btn-small btn-danger"
                        />
                      </div>
                    {{/if}}
                  </li>
                {{/each}}
              </ul>
            {{else}}
              <div class="recruit-tracker-panel__empty">
                {{i18n "discourse_recruit_tracker.notes.empty"}}
              </div>
            {{/if}}

            {{#if this.canManage}}
              <Form
                @data={{this.noteFormData}}
                @onRegisterApi={{this.registerNoteFormApi}}
                @onSubmit={{this.submitNote}}
                class="recruit-tracker-panel__form"
                as |form|
              >
                <form.Field
                  @name="note"
                  @title={{i18n "discourse_recruit_tracker.notes.add"}}
                  @format="full"
                  @validation="required:trim|length:1,2000"
                  as |field|
                >
                  <field.Textarea rows="3" />
                </form.Field>
                <form.Field
                  @name="pinned"
                  @title={{i18n "discourse_recruit_tracker.notes.pin_label"}}
                  as |field|
                >
                  <field.Checkbox />
                </form.Field>
                <form.Actions>
                  <form.Submit
                    @label="discourse_recruit_tracker.notes.save"
                    class="btn-primary"
                  />
                </form.Actions>
              </Form>
            {{/if}}
          </div>

          <div class="recruit-tracker-panel__section">
            <div class="recruit-tracker-panel__section-header">
              <h3>{{i18n "discourse_recruit_tracker.history.title"}}</h3>
            </div>
            {{#if this.history.length}}
              <ul class="recruit-tracker-panel__history">
                {{#each this.history as |entry|}}
                  <li class="recruit-tracker-panel__history-entry">
                    <span class="recruit-tracker-panel__history-date">
                      {{formatDate entry.created_at format="tiny" noTitle="true"}}
                    </span>
                    <span class="recruit-tracker-panel__history-status">
                      {{entry.previous_label}}
                      {{i18n "discourse_recruit_tracker.history.arrow"}}
                      {{entry.new_label}}
                    </span>
                    <span class="recruit-tracker-panel__history-user">
                      {{entry.changed_by.username}}
                    </span>
                  </li>
                {{/each}}
              </ul>
            {{else}}
              <div class="recruit-tracker-panel__empty">
                {{i18n "discourse_recruit_tracker.history.empty"}}
              </div>
            {{/if}}
          </div>
        {{/if}}
      </section>
    {{/if}}
  </template>
}
