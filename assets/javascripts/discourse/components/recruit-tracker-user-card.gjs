import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

/**
 * @component recruit-tracker-user-card
 * @param {Object} user
 * @param {boolean} canManage
 * @param {boolean} joinDateEnabled
 */
export default class RecruitTrackerUserCard extends Component {
  @service router;

  /** @type {boolean} */
  @tracked isEditing = false;

  /** @type {Object} */
  @tracked noteFormData = { note: "" };

  /**
   * Returns whether the user can move status left.
   *
   * @returns {boolean}
   */
  get canStepLeft() {
    return this.args.canManage && Boolean(this.args.user?.previous_status);
  }

  /**
   * Returns whether the user can move status right.
   *
   * @returns {boolean}
   */
  get canStepRight() {
    return this.args.canManage && Boolean(this.args.user?.next_status);
  }

  /**
   * Returns whether the user can be removed from the tracker.
   *
   * @returns {boolean}
   */
  get canRemoveFromTracker() {
    return (
      this.args.canManage &&
      Boolean(this.args.user?.manual_included) &&
      !this.args.user?.recruit_member
    );
  }

  /**
   * Returns the tooltip for moving left.
   *
   * @returns {string}
   */
  get leftTitle() {
    const label = this.args.user?.previous_label;
    if (!label) {
      return i18n("discourse_recruit_tracker.status.move_left");
    }

    return i18n("discourse_recruit_tracker.status.move_to", { status: label });
  }

  /**
   * Returns the tooltip for moving right.
   *
   * @returns {string}
   */
  get rightTitle() {
    const label = this.args.user?.next_label;
    if (!label) {
      return i18n("discourse_recruit_tracker.status.move_right");
    }

    return i18n("discourse_recruit_tracker.status.move_to", { status: label });
  }

  /**
   * Returns the label key for the note button.
   *
   * @returns {string}
   */
  get noteButtonLabelKey() {
    return this.args.user?.note
      ? "discourse_recruit_tracker.notes.edit"
      : "discourse_recruit_tracker.notes.add_button";
  }

  /**
   * Updates the recruit status to the provided value.
   *
   * @param {string|null} newStatus
   * @returns {Promise<void>}
   */
  @action
  async stepStatus(newStatus) {
    if (!newStatus) {
      return;
    }

    try {
      await ajax(`/recruit-tracker/users/${this.args.user.id}/status`, {
        type: "PUT",
        data: { status: newStatus },
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  /**
   * Opens the inline note editor.
   */
  @action
  startEdit() {
    this.noteFormData = { note: this.args.user?.note || "" };
    this.isEditing = true;
  }

  /**
   * Cancels the inline note editor.
   */
  @action
  cancelEdit() {
    this.isEditing = false;
  }

  /**
   * Saves the recruit note.
   *
   * @param {Object} data
   */
  @action
  async submitNote(data) {
    try {
      await ajax(`/recruit-tracker/users/${this.args.user.id}/notes`, {
        type: "POST",
        data: { note: data.note },
      });
      this.isEditing = false;
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  /**
   * Removes the user from the tracker.
   *
   * @returns {Promise<void>}
   */
  @action
  async removeFromTracker() {
    try {
      await ajax(`/recruit-tracker/manual/${this.args.user.id}`, {
        type: "DELETE",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <li class="recruit-tracker__user">
      <div class="recruit-tracker__user-meta">
        <LinkTo
          @route="user"
          @model={{@user.username}}
          class="recruit-tracker__user-name"
        >
          {{#if @user.rank_prefix}}{{@user.rank_prefix}} {{/if}}
          {{@user.username}}
        </LinkTo>
        {{#if @user.title}}
          <span class="recruit-tracker__user-title">{{@user.title}}</span>
        {{/if}}
        {{#if @joinDateEnabled}}
          <span class="recruit-tracker__user-join-date">
            {{#if @user.join_date_display}}
              {{i18n
                "discourse_recruit_tracker.join_date.value"
                date=@user.join_date_display
              }}
            {{else}}
              {{i18n "discourse_recruit_tracker.join_date.unknown"}}
            {{/if}}
          </span>
        {{/if}}
        {{#if this.isEditing}}
          <Form
            @data={{this.noteFormData}}
            @onSubmit={{this.submitNote}}
            class="recruit-tracker__note-form"
            as |form|
          >
            <form.Field
              @name="note"
              @title={{i18n "discourse_recruit_tracker.notes.add"}}
              @format="full"
              @validation="length:0,2000"
              as |field|
            >
              <field.Textarea rows="4" />
            </form.Field>
            <form.Actions>
              <form.Submit
                @label="discourse_recruit_tracker.notes.save"
                class="btn-primary"
              />
              <DButton
                @action={{this.cancelEdit}}
                @label="discourse_recruit_tracker.notes.cancel"
                class="btn-secondary"
              />
            </form.Actions>
          </Form>
        {{else}}
          {{#if @canManage}}
            {{#if @user.note}}
              <div class="recruit-tracker__user-note">
                <span class="recruit-tracker__user-note-label">
                  {{i18n "discourse_recruit_tracker.notes.title"}}:
                </span>
                <div class="recruit-tracker__user-note-text">{{@user.note}}</div>
              </div>
            {{/if}}
          {{/if}}
          {{#if @canManage}}
            <div class="recruit-tracker__user-actions">
              <DButton
                @action={{this.startEdit}}
                @label={{this.noteButtonLabelKey}}
                class="btn-small recruit-tracker__action-button"
              />
              {{#if this.canRemoveFromTracker}}
                <DButton
                  @action={{this.removeFromTracker}}
                  @label="discourse_recruit_tracker.manual.remove_button"
                  class="btn-small recruit-tracker__action-button"
                />
              {{/if}}
            </div>
          {{/if}}
        {{/if}}
      </div>

      {{#if this.canStepLeft}}
        <DButton
          @icon="arrow-left"
          @action={{fn this.stepStatus @user.previous_status}}
          @translatedTitle={{this.leftTitle}}
          @translatedAriaLabel={{this.leftTitle}}
          class="btn-small recruit-tracker__status-step recruit-tracker__status-step--left"
        />
      {{/if}}

      {{#if this.canStepRight}}
        <DButton
          @icon="arrow-right"
          @action={{fn this.stepStatus @user.next_status}}
          @translatedTitle={{this.rightTitle}}
          @translatedAriaLabel={{this.rightTitle}}
          class="btn-small recruit-tracker__status-step recruit-tracker__status-step--right"
        />
      {{/if}}
    </li>
  </template>
}
