# frozen_string_literal: true

module DiscourseRecruitTracker
  class OverviewController < BaseController
    before_action :ensure_can_view!

    def index
      render html: "", layout: "application"
    end

    def list
      users = users_with_status
      last_changes = last_changes_for(users)
      users_by_status = build_users_by_status(users, last_changes)

      render_json_dump(
        columns: DiscourseRecruitTracker::StatusConfig.columns_for(users_by_status),
      )
    end

    private

    def users_with_status
      User
        .joins(:user_custom_fields)
        .where(
          user_custom_fields: {
            name: DiscourseRecruitTracker::STATUS_FIELD,
            value: DiscourseRecruitTracker::StatusConfig::STATUS_KEYS,
          },
        )
        .select(
          "users.id, users.username, users.name, users.uploaded_avatar_id, user_custom_fields.value AS recruit_status",
        )
    end

    def last_changes_for(users)
      return {} if users.blank?

      DiscourseRecruitTracker::StatusChange
        .where(user_id: users.map(&:id))
        .order(created_at: :desc)
        .group_by(&:user_id)
    end

    def build_users_by_status(users, last_changes)
      users.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |user, result|
        status = user.read_attribute(:recruit_status)
        last_change = last_changes[user.id]&.first

        result[status] << {
          id: user.id,
          username: user.username,
          name: user.name,
          avatar_template: user.avatar_template,
          status: status,
          status_label: DiscourseRecruitTracker::StatusConfig.label_for(status),
          last_changed_at: last_change&.created_at,
        }
      end
    end
  end
end
