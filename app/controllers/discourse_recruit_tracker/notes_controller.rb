# frozen_string_literal: true

module DiscourseRecruitTracker
  class NotesController < BaseController
    before_action :ensure_can_manage!

    def create
      DiscourseRecruitTracker::CreateNote.call(guardian:, params: create_note_params) do
        on_success do |note:|
          render_json_dump(note: serialize_note(note))
        end
        on_model_not_found(:user) { raise Discourse::NotFound }
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages.join(", "), status: 422)
        end
        on_failed_step(:create_note) do |step|
          render_json_error(step.error, status: 422)
        end
      end
    end

    private

    def create_note_params
      { user_id: params[:id], note: params[:note] }
    end

    def serialize_note(note)
      return nil if note.blank?

      {
        id: note.id,
        note: note.note,
        created_at: note.created_at,
        created_by: {
          id: note.created_by.id,
          username: note.created_by.username,
          avatar_template: note.created_by.avatar_template,
        },
      }
    end
  end
end
