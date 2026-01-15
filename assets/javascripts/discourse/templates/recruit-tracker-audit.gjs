import { LinkTo } from "@ember/routing";
import RouteTemplate from "ember-route-template";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <div class="recruit-tracker">
      <div class="container">
        <header class="recruit-tracker__audit-header">
          <h1 class="recruit-tracker__audit-title">
            {{i18n "discourse_recruit_tracker.audit.title"}}
          </h1>
          <p class="recruit-tracker__audit-subtitle">
            {{i18n "discourse_recruit_tracker.audit.full_subtitle"}}
          </p>
          <LinkTo @route="recruit-tracker" class="recruit-tracker__audit-back">
            {{i18n "discourse_recruit_tracker.audit.back"}}
          </LinkTo>
        </header>

        {{#if @model.audit_log.length}}
          <ul class="recruit-tracker__audit-list">
            {{#each @model.audit_log as |entry|}}
              <li class="recruit-tracker__audit-entry">
                <div class="recruit-tracker__audit-meta">
                  <div class="recruit-tracker__audit-user">
                    <LinkTo @route="user" @model={{entry.user.username}}>
                      {{#if entry.user.rank_prefix}}{{entry.user.rank_prefix}}
                      {{/if}}
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
                  {{if entry.created_at_display entry.created_at_display "?"}}
                </span>
              </li>
            {{/each}}
          </ul>
        {{else}}
          <div class="recruit-tracker__empty">
            {{i18n "discourse_recruit_tracker.audit.empty"}}
          </div>
        {{/if}}
      </div>
    </div>
  </template>
);
