# frozen_string_literal: true

module DiscourseRecruitTracker
  class StatusConfig
    STATUS_KEYS = %w[
      pending_recruit_training
      attended_recruit_training
      eligible_for_assessment
      pending_promotion_decision
    ].freeze

    DEFAULT_LABELS = {
      "pending_recruit_training" => "Pending Recruit Training",
      "attended_recruit_training" => "Attended Recruit Training",
      "eligible_for_assessment" => "Eligible for Assessment",
      "pending_promotion_decision" => "Pending Promotion Decision",
    }.freeze

    LABEL_SETTINGS = {
      "pending_recruit_training" => :discourse_recruit_tracker_status_pending_label,
      "attended_recruit_training" => :discourse_recruit_tracker_status_attended_label,
      "eligible_for_assessment" => :discourse_recruit_tracker_status_eligible_label,
      "pending_promotion_decision" => :discourse_recruit_tracker_status_promotion_label,
    }.freeze

    def self.valid_status?(status)
      status.blank? || STATUS_KEYS.include?(status.to_s)
    end

    def self.label_for(status)
      key = status.to_s
      setting = LABEL_SETTINGS[key]
      return "" if setting.nil?

      SiteSetting.public_send(setting).presence || DEFAULT_LABELS[key]
    end

    def self.status_options
      STATUS_KEYS.map { |key| { id: key, name: label_for(key) } }
    end

    def self.columns_for(users_by_status)
      STATUS_KEYS.map do |key|
        {
          key: key,
          label: label_for(key),
          users: users_by_status[key] || [],
        }
      end
    end
  end
end
