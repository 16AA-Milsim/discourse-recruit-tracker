# frozen_string_literal: true

module DiscourseRecruitTracker
  class DeleteNote
    include Service::Base

    # @!method self.call(guardian:, params:)
    #   @param [Guardian] guardian
    #   @param [Hash] params
    #   @option params [Integer] :note_id
    #   @return [Service::Base::Context]

    policy :can_manage

    params do
      attribute :note_id, :integer
      validates :note_id, presence: true
    end

    model :note

    transaction do
      step :destroy_note
      step :log_action
    end

    private

    def can_manage(guardian:)
      DiscourseRecruitTracker::Access.can_manage?(guardian.user)
    end

    def fetch_note(params:)
      DiscourseRecruitTracker::Note.find_by(id: params.note_id)
    end

    def destroy_note(note:)
      note.destroy!
    end

    def log_action(guardian:, note:)
      StaffActionLogger.new(guardian.user).log_custom(
        "recruit_tracker_note_deleted",
        target_user_id: note.user_id,
        note_id: note.id,
      )
    end
  end
end
