# frozen_string_literal: true

# name: discourse-recruit-tracker
# about: Recruit tracking for the 16AA Milsim unit.
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: https://github.com/16AA-Milsim/discourse-recruit-tracker
# required_version: 2.7.0

enabled_site_setting :discourse_recruit_tracker_enabled
register_asset "stylesheets/common/discourse-recruit-tracker.scss"

module ::DiscourseRecruitTracker
  PLUGIN_NAME = "discourse-recruit-tracker"
  STATUS_FIELD = "discourse_recruit_tracker_status"
  MANUAL_FIELD = "discourse_recruit_tracker_manual"
  RECRUIT_GROUP_NAME = "Recruit"
end

require_relative "lib/discourse_recruit_tracker/engine"
require_relative "lib/discourse_recruit_tracker/access"
require_relative "lib/discourse_recruit_tracker/audit_log"
require_relative "lib/discourse_recruit_tracker/status_config"
require_relative "lib/discourse_recruit_tracker/discord_notifier"

Discourse::Application.routes.append do
  mount ::DiscourseRecruitTracker::Engine, at: "/recruit-tracker"
end

after_initialize do
  register_user_custom_field_type(::DiscourseRecruitTracker::STATUS_FIELD, :string, max_length: 50)
  register_user_custom_field_type(::DiscourseRecruitTracker::MANUAL_FIELD, :boolean)

  require_relative "app/models/discourse_recruit_tracker/note"
  require_relative "app/models/discourse_recruit_tracker/status_change"

  require_relative "app/services/discourse_recruit_tracker/create_note"
  require_relative "app/services/discourse_recruit_tracker/update_manual_tracking"
  require_relative "app/services/discourse_recruit_tracker/update_status"

  require_relative "app/jobs/regular/discourse_recruit_tracker/notify_discord"

  require_relative "app/controllers/discourse_recruit_tracker/base_controller"
  require_relative "app/controllers/discourse_recruit_tracker/overview_controller"
  require_relative "app/controllers/discourse_recruit_tracker/notes_controller"
  require_relative "app/controllers/discourse_recruit_tracker/users_controller"
  require_relative "app/controllers/discourse_recruit_tracker/manual_controller"

  add_to_serializer(:found_user, :rank_prefix) do
    next unless defined?(::DiscourseRankOnNames)
    next unless SiteSetting.respond_to?(:rank_on_names_enabled)
    next unless SiteSetting.rank_on_names_enabled

    ::DiscourseRankOnNames.prefix_for_user(object)
  end

  on(:group_user_created) do |user, group|
    next unless SiteSetting.discourse_recruit_tracker_enabled
    next unless group&.name == ::DiscourseRecruitTracker::RECRUIT_GROUP_NAME
    next if user.custom_fields[::DiscourseRecruitTracker::STATUS_FIELD].present?

    user.custom_fields[::DiscourseRecruitTracker::STATUS_FIELD] =
      ::DiscourseRecruitTracker::StatusConfig::STATUS_KEYS.first
    user.save_custom_fields
  end
end
