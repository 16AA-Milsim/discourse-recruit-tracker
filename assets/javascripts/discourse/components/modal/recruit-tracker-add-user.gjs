import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import UserChooser from "select-kit/components/user-chooser";

/**
 * @component recruit-tracker-add-user
 * @param {Function} closeModal
 */
export default class RecruitTrackerAddUserModal extends Component {
  @service router;

  /** @type {string|null} */
  @tracked flash = null;

  /** @type {boolean} */
  @tracked saving = false;

  /** @type {Object} */
  @tracked formData = { username: [] };

  /** @type {Object|null} */
  formApi = null;

  /**
   * Returns the allowed group names for user search.
   *
   * @returns {Array<string>|null}
   */
  get allowedGroupNames() {
    const names = this.args.model?.allowedGroupNames || [];
    return names.length ? names : null;
  }

  /**
   * Normalizes the selected username.
   *
   * @param {string|Array<string>} value
   * @returns {string|null}
   */
  normalizeUsername(value) {
    if (Array.isArray(value)) {
      return value.length ? value[0] : null;
    }

    return value || null;
  }

  /**
   * Registers the FormKit API.
   *
   * @param {Object} api
   * @returns {void}
   */
  @action
  registerApi(api) {
    this.formApi = api;
  }

  /**
   * Submits the modal form.
   *
   * @returns {void}
   */
  @action
  submitForm() {
    this.formApi?.submit();
  }

  /**
   * Cancels the modal.
   *
   * @returns {void}
   */
  @action
  cancel() {
    this.args.closeModal();
  }

  /**
   * Submits the form data.
   *
   * @param {Object} data
   * @returns {Promise<void>}
   */
  @action
  async submit(data) {
    const username = this.normalizeUsername(data.username);
    if (!username) {
      this.flash = i18n("discourse_recruit_tracker.manual.errors.user_required");
      return;
    }

    this.flash = null;
    this.saving = true;
    try {
      await ajax("/recruit-tracker/manual", {
        type: "POST",
        data: { username },
      });
      this.args.closeModal();
      this.router.refresh();
    } catch (error) {
      this.flash = extractError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <DModal
      @title={{i18n "discourse_recruit_tracker.manual.add_title"}}
      @closeModal={{@closeModal}}
      @flash={{this.flash}}
    >
      <:body>
        <Form
          @data={{this.formData}}
          @onSubmit={{this.submit}}
          @onRegisterApi={{this.registerApi}}
          as |form|
        >
          <form.Field
            @name="username"
            @title={{i18n "discourse_recruit_tracker.manual.user_label"}}
            @validation="required"
            @format="full"
            as |field|
          >
            <field.Custom>
              <UserChooser
                @value={{field.value}}
                @onChange={{field.set}}
                @options={{hash
                  componentForRow="recruit-tracker-user-chooser-row"
                  groupMembersOf=this.allowedGroupNames
                  maximum=1
                  excludeCurrentUser=false
                  headerAriaLabel=(i18n
                    "discourse_recruit_tracker.manual.user_label"
                  )
                }}
              />
            </field.Custom>
          </form.Field>
        </Form>
      </:body>
      <:footer>
        <DButton
          @action={{this.submitForm}}
          @label="discourse_recruit_tracker.manual.add_submit"
          @disabled={{this.saving}}
          class="btn-primary"
        />
        <DButton
          @action={{this.cancel}}
          @label="discourse_recruit_tracker.manual.cancel"
          @disabled={{this.saving}}
          class="btn-secondary"
        />
      </:footer>
    </DModal>
  </template>
}
