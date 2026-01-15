# frozen_string_literal: true

module DiscourseRecruitTracker
  module Access
    extend self

    def can_view?(user)
      group_allowed?(user, view_group_ids + manage_group_ids)
    end

    def can_manage?(user)
      group_allowed?(user, manage_group_ids)
    end

    private

    def view_group_ids
      SiteSetting.discourse_recruit_tracker_view_groups_map || []
    end

    def manage_group_ids
      SiteSetting.discourse_recruit_tracker_manage_groups_map || []
    end

    def group_allowed?(user, group_ids)
      return false if user.blank?
      return false if group_ids.blank?

      GroupUser.exists?(user_id: user.id, group_id: group_ids)
    end
  end
end
