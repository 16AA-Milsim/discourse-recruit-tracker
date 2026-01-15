# frozen_string_literal: true

module Jobs
  class DiscourseRecruitTrackerNotifyDiscord < ::Jobs::Base
    def execute(args)
      return unless SiteSetting.discourse_recruit_tracker_discord_notifications_enabled

      webhook_url = SiteSetting.discourse_recruit_tracker_discord_webhook_url
      return if webhook_url.blank?

      user = User.find_by(id: args[:user_id])
      actor = User.find_by(id: args[:actor_id])
      return if user.blank? || actor.blank?

      payload = build_payload(user, actor, args[:previous_status], args[:new_status])

      Excon.post(
        webhook_url,
        body: payload.to_json,
        headers: { "Content-Type" => "application/json" },
      )
    rescue => e
      Rails.logger.warn("[discourse-recruit-tracker] Discord notify failed: #{e.class} #{e.message}")
    end

    private

    def build_payload(user, actor, previous_status, new_status)
      previous_label = status_label(previous_status)
      new_label = status_label(new_status)

      content = build_message(actor, user, previous_label, new_label)

      payload = { content: content }

      username = SiteSetting.discourse_recruit_tracker_discord_webhook_username.presence
      avatar_url = SiteSetting.discourse_recruit_tracker_discord_webhook_avatar_url.presence

      payload[:username] = username if username
      payload[:avatar_url] = avatar_url if avatar_url

      payload
    end

    def build_message(actor, user, previous_label, new_label)
      template = SiteSetting.discourse_recruit_tracker_discord_message_template
      template = template.presence || I18n.t("discourse_recruit_tracker.discord.status_change")

      I18n.interpolate(
        template,
        actor: actor.username,
        user: user.username,
        previous: previous_label,
        current: new_label,
      )
    rescue I18n::MissingInterpolationArgument
      I18n.t(
        "discourse_recruit_tracker.discord.status_change",
        user: user.username,
        actor: actor.username,
        previous: previous_label,
        current: new_label,
      )
    end

    def status_label(status)
      return I18n.t("discourse_recruit_tracker.status.none") if status.blank?

      DiscourseRecruitTracker::StatusConfig.label_for(status)
    end
  end
end
