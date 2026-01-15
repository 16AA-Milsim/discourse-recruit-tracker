import { service } from "@ember/service";
import moment from "moment";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

/**
 * Route for the recruit tracker audit log page.
 */
export default class RecruitTrackerAuditRoute extends DiscourseRoute {
  @service router;
  @service siteSettings;

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
   * Loads the audit log data from the API.
   *
   * @returns {Promise<Object>}
   */
  async model() {
    const data = await ajax("/recruit-tracker/audit.json");
    const auditDateFormat = "DD/MM/YYYY HH:mm";

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
    return i18n("discourse_recruit_tracker.audit.title");
  }
}
