# frozen_string_literal: true

module DiscourseRecruitTracker
  class DiscordNotifier
    def self.notify_status_change(user:, previous_status:, new_status:, actor:)
      return unless SiteSetting.discourse_recruit_tracker_discord_notifications_enabled

      webhook_url = SiteSetting.discourse_recruit_tracker_discord_webhook_url
      return if webhook_url.blank?

      Jobs.enqueue(
        :discourse_recruit_tracker_notify_discord,
        user_id: user.id,
        actor_id: actor.id,
        previous_status: previous_status,
        new_status: new_status,
      )
    end
  end
end
