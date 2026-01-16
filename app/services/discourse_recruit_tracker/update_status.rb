# frozen_string_literal: true

module DiscourseRecruitTracker
  class UpdateStatus
    include Service::Base

    # @!method self.call(guardian:, params:)
    #   @param [Guardian] guardian
    #   @param [Hash] params
    #   @option params [Integer] :user_id
    #   @option params [String, nil] :status
    #   @return [Service::Base::Context]

    policy :can_manage

    params do
      attribute :user_id, :integer
      attribute :status, :string
      validates :user_id, presence: true
    end

    model :user

    transaction do
      step :validate_status
      step :apply_status
      step :log_action
      step :notify_discord
    end

    private

    def can_manage(guardian:)
      DiscourseRecruitTracker::Access.can_manage?(guardian.user)
    end

    def fetch_user(params:)
      User.find_by(id: params.user_id)
    end

    def validate_status(params:)
      status = params.status.presence
      return if DiscourseRecruitTracker::StatusConfig.valid_status?(status)

      context.fail!(error: I18n.t("discourse_recruit_tracker.errors.invalid_status"))
    end

    def apply_status(user:, guardian:, params:)
      previous_status = user.custom_fields[DiscourseRecruitTracker::STATUS_FIELD]
      if previous_status.blank? && (recruit_group_member?(user) || manual_tracker?(user))
        previous_status = DiscourseRecruitTracker::StatusConfig::STATUS_KEYS.first
      end
      new_status = params.status.presence

      if previous_status == new_status
        context[:changed] = false
        context[:status] = previous_status
        context[:previous_status] = previous_status
        context[:change] = nil
        return
      end

      if new_status.present?
        user.custom_fields[DiscourseRecruitTracker::STATUS_FIELD] = new_status
      else
        user.custom_fields.delete(DiscourseRecruitTracker::STATUS_FIELD)
      end

      user.save_custom_fields

      change =
        DiscourseRecruitTracker::StatusChange.create!(
          user_id: user.id,
          changed_by_id: guardian.user.id,
          previous_status: previous_status,
          new_status: new_status,
          user_rank_prefix: rank_prefix_for(user),
          changed_by_rank_prefix: rank_prefix_for(guardian.user),
        )

      context[:changed] = true
      context[:status] = new_status
      context[:previous_status] = previous_status
      context[:change] = change
    end

    def log_action(guardian:, user:, previous_status:, status:, changed:)
      return unless changed

      StaffActionLogger.new(guardian.user).log_custom(
        "recruit_tracker_status_change",
        target_user_id: user.id,
        previous_status: previous_status,
        new_status: status,
      )
      DiscourseRecruitTracker::AuditLog.trim!
    end

    def notify_discord(guardian:, user:, previous_status:, status:, changed:)
      return unless changed

      DiscourseRecruitTracker::DiscordNotifier.notify_status_change(
        user: user,
        previous_status: previous_status,
        new_status: status,
        actor: guardian.user,
      )
    end

    def rank_prefix_for(user)
      return nil unless rank_on_names_enabled?

      ::DiscourseRankOnNames.prefix_for_user(user)
    end

    def recruit_group_member?(user)
      GroupUser
        .joins(:group)
        .exists?(user_id: user.id, groups: { name: DiscourseRecruitTracker::RECRUIT_GROUP_NAME })
    end

    def manual_tracker?(user)
      user.custom_fields[DiscourseRecruitTracker::MANUAL_FIELD].present?
    end

    def rank_on_names_enabled?
      return @rank_on_names_enabled unless @rank_on_names_enabled.nil?

      @rank_on_names_enabled =
        defined?(::DiscourseRankOnNames) &&
          SiteSetting.respond_to?(:rank_on_names_enabled) &&
          SiteSetting.rank_on_names_enabled
    end
  end
end
