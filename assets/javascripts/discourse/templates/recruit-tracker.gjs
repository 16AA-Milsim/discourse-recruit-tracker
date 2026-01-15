import { LinkTo } from "@ember/routing";
import RouteTemplate from "ember-route-template";
import { i18n } from "discourse-i18n";
import RecruitTrackerUserCard from "discourse/plugins/discourse-recruit-tracker/discourse/components/recruit-tracker-user-card";

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
          <div class="recruit-tracker__column-headers">
            {{#each @model.columns as |column|}}
              <div class="recruit-tracker__column-header">{{column.label}}</div>
            {{/each}}
          </div>

          <div class="recruit-tracker__column-lists">
            {{#each @model.columns as |column|}}
              <div class="recruit-tracker__column-list">
                {{#if column.users.length}}
                  <ul class="recruit-tracker__users">
                    {{#each column.users as |user|}}
                      <RecruitTrackerUserCard
                        @user={{user}}
                        @canManage={{@model.can_manage}}
                        @joinDateEnabled={{@model.join_date_enabled}}
                      />
                    {{/each}}
                  </ul>
                {{else}}
                  <div class="recruit-tracker__empty">
                    {{i18n "discourse_recruit_tracker.overview.empty_column"}}
                  </div>
                {{/if}}
              </div>
            {{/each}}
          </div>
        </div>

        {{#if @model.can_manage}}
          <section class="recruit-tracker__audit">
            <details class="recruit-tracker__audit-toggle">
              <summary class="recruit-tracker__audit-summary">
                <span class="recruit-tracker__audit-title">
                  {{i18n "discourse_recruit_tracker.audit.title"}}
                </span>
                <span class="recruit-tracker__audit-subtitle">
                  {{i18n "discourse_recruit_tracker.audit.subtitle"}}
                </span>
                <span class="recruit-tracker__audit-hint">
                  {{i18n "discourse_recruit_tracker.audit.toggle_hint"}}
                </span>
              </summary>

              {{#if @model.audit_log.length}}
                <ul class="recruit-tracker__audit-list">
                  {{#each @model.audit_log as |entry|}}
                    <li class="recruit-tracker__audit-entry">
                      <div class="recruit-tracker__audit-meta">
                        <div class="recruit-tracker__audit-user">
                          <LinkTo @route="user" @model={{entry.user.username}}>
                            {{#if
                              entry.user.rank_prefix
                            }}{{entry.user.rank_prefix}} {{/if}}
                            {{entry.user.username}}
                          </LinkTo>
                        </div>
                        <div class="recruit-tracker__audit-change">
                          {{#if entry.note_label}}
                            <span class="recruit-tracker__audit-status">
                              {{entry.note_label}}
                            </span>
                          {{else}}
                            <span class="recruit-tracker__audit-status">
                              {{entry.previous_label}}
                            </span>
                            <span class="recruit-tracker__audit-arrow">
                              {{i18n "discourse_recruit_tracker.history.arrow"}}
                            </span>
                            <span class="recruit-tracker__audit-status">
                              {{entry.new_label}}
                            </span>
                          {{/if}}
                          <span class="recruit-tracker__audit-by">
                            {{i18n "discourse_recruit_tracker.audit.by"}}
                          </span>
                          <LinkTo
                            @route="user"
                            @model={{entry.changed_by.username}}
                            class="recruit-tracker__audit-actor"
                          >
                            {{#if
                              entry.changed_by.rank_prefix
                            }}{{entry.changed_by.rank_prefix}} {{/if}}
                            {{entry.changed_by.username}}
                          </LinkTo>
                        </div>
                      </div>
                      <span class="recruit-tracker__audit-date">
                        {{if
                          entry.created_at_display
                          entry.created_at_display
                          "?"
                        }}
                      </span>
                    </li>
                  {{/each}}
                </ul>
              {{else}}
                <div class="recruit-tracker__empty">
                  {{i18n "discourse_recruit_tracker.audit.empty"}}
                </div>
              {{/if}}
              <div class="recruit-tracker__audit-actions">
                <LinkTo
                  @route="recruit-tracker-audit"
                  class="recruit-tracker__audit-link"
                >
                  {{i18n "discourse_recruit_tracker.audit.view_full"}}
                </LinkTo>
              </div>
            </details>
          </section>
        {{/if}}
      </div>
    </div>
  </template>
);
