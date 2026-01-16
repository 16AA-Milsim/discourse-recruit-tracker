import { action } from "@ember/object";
import { service } from "@ember/service";
import moment from "moment";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";
import RecruitTrackerAddUserModal from "discourse/plugins/discourse-recruit-tracker/discourse/components/modal/recruit-tracker-add-user";

/**
 * Route for the recruit tracker overview page.
 */
export default class RecruitTrackerRoute extends DiscourseRoute {
  @service router;
  @service siteSettings;
  @service modal;

  /**
   * Redirects if the plugin is disabled.
   *
   * @returns {void}
   */
  beforeModel() {
    if (!this.siteSettings.discourse_recruit_tracker_enabled) {
      this.router.transitionTo(
        "unknown",
        window.location.pathname.replace(/^\//, "")
      );
    }
  }

  /**
   * Loads the overview data from the API.
   *
   * @returns {Promise<Object>}
   */
  async model() {
    const data = await ajax("/recruit-tracker/overview.json");
    const joinDateFormat = "DD/MM/YYYY";
    const auditDateFormat = "DD/MM/YYYY HH:mm";
    const joinDateEnabled = data.join_date_enabled === true;

    data.columns = (data.columns || []).map((column) => {
      const users = (column.users || []).map((user) => {
        const joinDate = joinDateEnabled && user.join_date && moment(user.join_date);
        const joinDateDisplay =
          joinDate && joinDate.isValid() ? joinDate.format(joinDateFormat) : null;

        return { ...user, join_date_display: joinDateDisplay };
      });

      return { ...column, users };
    });

    data.audit_log = (data.audit_log || []).map((entry) => {
      const auditDate = entry.created_at && moment(entry.created_at);
      const auditDateDisplay =
        auditDate && auditDate.isValid()
          ? auditDate.format(auditDateFormat)
          : null;

      return { ...entry, created_at_display: auditDateDisplay };
    });

    return data;
  }

  /**
   * Provides the document title token for the route.
   *
   * @returns {string}
   */
  titleToken() {
    return i18n("discourse_recruit_tracker.title");
  }

  /**
   * Opens the add-to-tracker modal.
   *
   * @returns {void}
   */
  @action
  openAddUserModal() {
    const allowedGroupNames = this.currentModel?.manual_allowed_groups || [];
    this.modal.show(RecruitTrackerAddUserModal, {
      model: { allowedGroupNames },
    });
  }
}
