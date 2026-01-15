# frozen_string_literal: true

module DiscourseRecruitTracker
  class BaseController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in
    before_action :ensure_recruit_tracker_enabled

    private

    def ensure_recruit_tracker_enabled
      raise Discourse::NotFound unless SiteSetting.discourse_recruit_tracker_enabled
    end

    def ensure_can_view!
      raise Discourse::NotFound unless DiscourseRecruitTracker::Access.can_view?(current_user)
    end

    def ensure_can_manage!
      raise Discourse::NotFound unless DiscourseRecruitTracker::Access.can_manage?(current_user)
    end

    def rank_on_names_enabled?
      return @rank_on_names_enabled unless @rank_on_names_enabled.nil?

      @rank_on_names_enabled =
        defined?(::DiscourseRankOnNames) &&
          SiteSetting.respond_to?(:rank_on_names_enabled) &&
          SiteSetting.rank_on_names_enabled
    end

    def rank_prefix_for(user)
      return nil unless rank_on_names_enabled?

      ::DiscourseRankOnNames.prefix_for_user(user)
    end
  end
end
