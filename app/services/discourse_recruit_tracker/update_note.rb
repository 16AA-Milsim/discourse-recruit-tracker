# frozen_string_literal: true

module DiscourseRecruitTracker
  class UpdateNote
    include Service::Base

    # @!method self.call(guardian:, params:)
    #   @param [Guardian] guardian
    #   @param [Hash] params
    #   @option params [Integer] :note_id
    #   @option params [String, nil] :note
    #   @option params [Boolean, nil] :pinned
    #   @return [Service::Base::Context]

    policy :can_manage

    params do
      attribute :note_id, :integer
      attribute :note, :string
      attribute :pinned, :boolean
      validates :note_id, presence: true
    end

    model :note

    transaction do
      step :update_note
      step :log_action
    end

    private

    def can_manage(guardian:)
      DiscourseRecruitTracker::Access.can_manage?(guardian.user)
    end

    def fetch_note(params:)
      DiscourseRecruitTracker::Note.find_by(id: params.note_id)
    end

    def update_note(note:, params:)
      if params.note
        note_text = params.note.to_s.strip
        if note_text.blank?
          context.fail!(error: I18n.t("discourse_recruit_tracker.errors.note_blank"))
        end
        note.note = note_text
      end

      if params.pinned != nil
        note.pinned = params.pinned
      end

      note.save!
    end

    def log_action(guardian:, note:)
      StaffActionLogger.new(guardian.user).log_custom(
        "recruit_tracker_note_updated",
        target_user_id: note.user_id,
        note_id: note.id,
      )
    end
  end
end
