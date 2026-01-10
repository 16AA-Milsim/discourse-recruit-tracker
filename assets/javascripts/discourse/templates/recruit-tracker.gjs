import { LinkTo } from "@ember/routing";
import RouteTemplate from "ember-route-template";
import UserAvatar from "discourse/components/user-avatar";
import formatDate from "discourse/helpers/format-date";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <div class="recruit-tracker">
      <div class="container">
        <header class="recruit-tracker__header">
          <h1 class="recruit-tracker__title">
            {{i18n "discourse_recruit_tracker.title"}}
          </h1>
          <p class="recruit-tracker__subtitle">
            {{i18n "discourse_recruit_tracker.overview.subtitle"}}
          </p>
        </header>

        <div class="recruit-tracker__columns">
          {{#each @model.columns as |column|}}
            <section class="recruit-tracker__column">
              <h2 class="recruit-tracker__column-title">{{column.label}}</h2>
              {{#if column.users.length}}
                <ul class="recruit-tracker__users">
                  {{#each column.users as |user|}}
                    <li class="recruit-tracker__user">
                      <UserAvatar @user={{user}} @size="small" />
                      <div class="recruit-tracker__user-meta">
                        <LinkTo
                          @route="user"
                          @model={{user.username}}
                          class="recruit-tracker__user-name"
                        >
                          {{if user.name user.name user.username}}
                        </LinkTo>
                        {{#if user.name}}
                          <span class="recruit-tracker__user-handle">
                            @{{user.username}}
                          </span>
                        {{/if}}
                      </div>
                      {{#if user.last_changed_at}}
                        <span class="recruit-tracker__user-updated">
                          {{formatDate
                            user.last_changed_at
                            format="tiny"
                            noTitle="true"
                          }}
                        </span>
                      {{/if}}
                    </li>
                  {{/each}}
                </ul>
              {{else}}
                <div class="recruit-tracker__empty">
                  {{i18n "discourse_recruit_tracker.overview.empty_column"}}
                </div>
              {{/if}}
            </section>
          {{/each}}
        </div>
      </div>
    </div>
  </template>
);
