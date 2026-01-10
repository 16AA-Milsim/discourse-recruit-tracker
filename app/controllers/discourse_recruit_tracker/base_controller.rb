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
  end
end
