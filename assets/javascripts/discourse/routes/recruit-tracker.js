import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

/**
 * Route for the recruit tracker overview page.
 */
export default class RecruitTrackerRoute extends DiscourseRoute {
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
   * Loads the overview data from the API.
   *
   * @returns {Promise<Object>}
   */
  async model() {
    return await ajax("/recruit-tracker/overview.json");
  }

  /**
   * Provides the document title token for the route.
   *
   * @returns {string}
   */
  titleToken() {
    return i18n("discourse_recruit_tracker.title");
  }
}
