import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

const PLUGIN_API_VERSION = "1.20.0";

/**
 * Determines whether the current user can access the overview page.
 *
 * @param {Object} siteSettings
 * @param {Object|null} currentUser
 * @returns {boolean}
 */
function canView(siteSettings, currentUser) {
  if (!siteSettings?.discourse_recruit_tracker_enabled) {
    return false;
  }

  if (!currentUser) {
    return false;
  }

  const allowed = [
    siteSettings.discourse_recruit_tracker_view_groups,
    siteSettings.discourse_recruit_tracker_manage_groups,
  ]
    .filter(Boolean)
    .join("|")
    .split("|")
    .map((id) => parseInt(id, 10))
    .filter((id) => Number.isInteger(id));

  if (allowed.length === 0) {
    return false;
  }

  const userGroups = currentUser.groups || [];
  return userGroups.some((group) => allowed.includes(group.id));
}

export default {
  name: "discourse-recruit-tracker-nav",

  initialize() {
    withPluginApi(PLUGIN_API_VERSION, (api) => {
      const siteSettings = api.container.lookup("service:site-settings");

      if (!siteSettings?.discourse_recruit_tracker_enabled) {
        return;
      }

      api.addCommunitySectionLink((BaseCommunitySectionLink) => {
        return class extends BaseCommunitySectionLink {
          get name() {
            return "recruit-tracker";
          }

          get route() {
            return "recruit-tracker";
          }

          get currentWhen() {
            return "recruit-tracker";
          }

          get title() {
            return i18n("discourse_recruit_tracker.nav_link");
          }

          get text() {
            return i18n("discourse_recruit_tracker.nav_link");
          }

          get prefixValue() {
            return "list";
          }

          get shouldDisplay() {
            return canView(this.siteSettings, this.currentUser);
          }
        };
      });
    });
  },
};
