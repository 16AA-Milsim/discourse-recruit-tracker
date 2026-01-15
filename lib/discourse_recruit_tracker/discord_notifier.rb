# frozen_string_literal: true

module DiscourseRecruitTracker
  class DiscordNotifier
    def self.notify_status_change(user:, previous_status:, new_status:, actor:)
      return unless SiteSetting.discourse_recruit_tracker_discord_notifications_enabled
      return unless announce_transition?(previous_status, new_status)

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

    def self.announce_transition?(previous_status, new_status)
      previous_status == "attended_recruit_training" &&
        new_status == "eligible_for_assessment"
    end
    private_class_method :announce_transition?
  end
end
