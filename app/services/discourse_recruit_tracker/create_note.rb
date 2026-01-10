# frozen_string_literal: true

module DiscourseRecruitTracker
  class CreateNote
    include Service::Base

    # @!method self.call(guardian:, params:)
    #   @param [Guardian] guardian
    #   @param [Hash] params
    #   @option params [Integer] :user_id
    #   @option params [String] :note
    #   @option params [Boolean] :pinned
    #   @return [Service::Base::Context]

    policy :can_manage

    params do
      attribute :user_id, :integer
      attribute :note, :string
      attribute :pinned, :boolean
      validates :user_id, presence: true
      validates :note, presence: true, length: { maximum: 2000 }
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
        context.fail!(error: I18n.t("discourse_recruit_tracker.errors.note_blank"))
      end

      note =
        DiscourseRecruitTracker::Note.create!(
          user_id: user.id,
          created_by_id: guardian.user.id,
          note: note_text,
          pinned: params.pinned == true,
        )

      context[:note] = note
    end

    def log_action(guardian:, user:, note:)
      StaffActionLogger.new(guardian.user).log_custom(
        "recruit_tracker_note_created",
        target_user_id: user.id,
        note_id: note.id,
      )
    end
  end
end
