import { classNames } from "@ember-decorators/component";
import avatar from "discourse/helpers/avatar";
import formatUsername from "discourse/helpers/format-username";
import SelectKitRowComponent from "select-kit/components/select-kit/select-kit-row";

/**
 * @component recruit-tracker-user-chooser-row
 * @param {Object} item
 */
@classNames("user-row")
export default class RecruitTrackerUserChooserRow extends SelectKitRowComponent {
  /**
   * Returns the rank-prefixed username for display.
   *
   * @returns {string}
   */
  get displayUsername() {
    const username = this.item?.username;
    if (!username) {
      return "";
    }

    const prefix = this.item?.rank_prefix;
    return prefix ? `${prefix} ${username}` : username;
  }

  <template>
    {{avatar this.item imageSize="tiny"}}

    <span class="username">{{formatUsername this.displayUsername}}</span>

    {{#if this.item.name}}
      <span class="name">{{this.item.name}}</span>
    {{/if}}
  </template>
}
