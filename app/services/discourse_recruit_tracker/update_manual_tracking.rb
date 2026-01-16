# frozen_string_literal: true

module DiscourseRecruitTracker
  class UpdateManualTracking
    include Service::Base

    # @!method self.call(guardian:, params:)
    #   @param [Guardian] guardian
    #   @param [Hash] params
    #   @option params [Integer] :user_id
    #   @option params [String] :username
    #   @option params [Boolean] :enabled
    #   @return [Service::Base::Context]

    policy :can_manage

    params do
      attribute :user_id, :integer
      attribute :username, :string
      attribute :enabled, :boolean

      validates :enabled, inclusion: { in: [true, false] }

      validate :user_reference

      def user_reference
        return if user_id.present? || username.present?

        errors.add(:base, I18n.t("discourse_recruit_tracker.errors.user_required"))
      end
    end

    model :user

    step :apply
    step :log_action

    private

    def can_manage(guardian:)
      DiscourseRecruitTracker::Access.can_manage?(guardian.user)
    end

    def fetch_user(params:)
      return User.find_by(id: params.user_id) if params.user_id.present?
      return User.find_by_username(params.username) if params.username.present?
    end

    def apply(user:, params:)
      if params.enabled
        apply_enable(user)
      else
        apply_disable(user)
      end

      context[:user] = user
    end

    def apply_enable(user)
      unless allowed_manual_user?(user)
        context.fail!(error: I18n.t("discourse_recruit_tracker.errors.manual_group_required"))
        return
      end

      if recruit_group_member?(user)
        context.fail!(
          error: I18n.t("discourse_recruit_tracker.errors.manual_already_recruit"),
        )
        return
      end

      if manual_tracker?(user)
        context[:changed] = false
        return
      end

      user.custom_fields[DiscourseRecruitTracker::MANUAL_FIELD] = true
      if user.custom_fields[DiscourseRecruitTracker::STATUS_FIELD].blank?
        user.custom_fields[DiscourseRecruitTracker::STATUS_FIELD] =
          DiscourseRecruitTracker::StatusConfig::STATUS_KEYS.first
      end
      user.save_custom_fields

      context[:changed] = true
    end

    def apply_disable(user)
      if recruit_group_member?(user)
        context.fail!(
          error: I18n.t("discourse_recruit_tracker.errors.manual_cannot_remove_recruit"),
        )
        return
      end

      unless manual_tracker?(user)
        context.fail!(error: I18n.t("discourse_recruit_tracker.errors.manual_not_tracked"))
        return
      end

      user.custom_fields.delete(DiscourseRecruitTracker::MANUAL_FIELD)
      user.save_custom_fields

      context[:changed] = true
    end

    def log_action(guardian:, user:, params:, changed:)
      return unless changed

      action_name =
        if params.enabled
          "recruit_tracker_manual_added"
        else
          "recruit_tracker_manual_removed"
        end

      UserHistory.create!(
        action: UserHistory.actions[:custom_staff],
        acting_user_id: guardian.user.id,
        target_user_id: user.id,
        custom_type: action_name,
        details: "target_user_id: #{user.id}",
      )
      DiscourseRecruitTracker::AuditLog.trim!
    end

    def manual_tracker?(user)
      user.custom_fields[DiscourseRecruitTracker::MANUAL_FIELD].present?
    end

    def recruit_group_member?(user)
      GroupUser
        .joins(:group)
        .exists?(
          user_id: user.id,
          groups: {
            name: DiscourseRecruitTracker::RECRUIT_GROUP_NAME,
          },
        )
    end

    def allowed_manual_user?(user)
      group_ids = manual_add_group_ids
      return true if group_ids.blank?

      GroupUser.exists?(user_id: user.id, group_id: group_ids)
    end

    def manual_add_group_ids
      SiteSetting.discourse_recruit_tracker_manual_add_groups_map || []
    end
  end
end
