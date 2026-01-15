# frozen_string_literal: true

module DiscourseRecruitTracker
  class CreateNote
    include Service::Base

    # @!method self.call(guardian:, params:)
    #   @param [Guardian] guardian
    #   @param [Hash] params
    #   @option params [Integer] :user_id
    #   @option params [String] :note
    #   @return [Service::Base::Context]

    policy :can_manage

    params do
      attribute :user_id, :integer
      attribute :note, :string
      validates :user_id, presence: true
      validates :note, length: { maximum: 2000 }, allow_blank: true
    end

    model :user

    transaction do
      step :create_note
      step :log_action
    end

    private

    def can_manage(guardian:)
      DiscourseRecruitTracker::Access.can_manage?(guardian.user)
    end

    def fetch_user(params:)
      User.find_by(id: params.user_id)
    end

    def create_note(user:, guardian:, params:)
      note_text = params.note.to_s.strip

      if note_text.blank?
        cleared = DiscourseRecruitTracker::Note.where(user_id: user.id).delete_all.positive?
        context[:note] = nil
        context[:created] = false
        context[:cleared] = cleared
        return
      end

      note = DiscourseRecruitTracker::Note.find_or_initialize_by(user_id: user.id)
      created = note.new_record?
      note.note = note_text
      note.created_by_id = guardian.user.id
      note.save!
      DiscourseRecruitTracker::Note.where(user_id: user.id).where.not(id: note.id).delete_all

      context[:note] = note
      context[:created] = created
      context[:cleared] = false
    end

    def log_action(guardian:, user:, note:, created:, cleared:)
      return if note.blank? && !cleared

      action_name =
        if cleared
          "recruit_tracker_note_cleared"
        elsif created
          "recruit_tracker_note_created"
        else
          "recruit_tracker_note_updated"
        end

      UserHistory.create!(
        action: UserHistory.actions[:custom_staff],
        acting_user_id: guardian.user.id,
        target_user_id: user.id,
        custom_type: action_name,
        details: "note_id: #{note&.id}",
      )
      DiscourseRecruitTracker::AuditLog.trim!
    end
  end
end
