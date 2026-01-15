import cookie from "discourse/lib/cookie";
import { withPluginApi } from "discourse/lib/plugin-api";

const PLUGIN_API_VERSION = "1.20.0";
const MODE_COOKIE_NAME = "forced_color_mode";

function detectSchemeType() {
  const forcedMode = cookie(MODE_COOKIE_NAME);
  if (forcedMode === "dark" || forcedMode === "light") {
    return forcedMode;
  }

  if (forcedMode === "auto") {
    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  }

  const schemeType = getComputedStyle(document.documentElement)
    .getPropertyValue("--scheme-type")
    .trim();

  if (schemeType === "dark" || schemeType === "light") {
    return schemeType;
  }

  return window.matchMedia("(prefers-color-scheme: dark)").matches
    ? "dark"
    : "light";
}

function updateRecruitTrackerScheme() {
  const schemeType = detectSchemeType();

  if (schemeType) {
    document.documentElement.dataset.rtScheme = schemeType;
  }
}

export default {
  name: "discourse-recruit-tracker-color-scheme",

  initialize() {
    withPluginApi(PLUGIN_API_VERSION, (api) => {
      updateRecruitTrackerScheme();
      api.onAppEvent("interface-color:changed", updateRecruitTrackerScheme);
      api.onPageChange(updateRecruitTrackerScheme);
    });
  },
};
