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

    def update
      DiscourseRecruitTracker::UpdateNote.call(guardian:, params: update_note_params) do
        on_success do |note:|
          render_json_dump(note: serialize_note(note))
        end
        on_model_not_found(:note) { raise Discourse::NotFound }
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages.join(", "), status: 422)
        end
        on_failed_step(:update_note) do |step|
          render_json_error(step.error, status: 422)
        end
      end
    end

    def destroy
      DiscourseRecruitTracker::DeleteNote.call(guardian:, params: delete_note_params) do
        on_success { render_json_dump(success: true) }
        on_model_not_found(:note) { raise Discourse::NotFound }
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages.join(", "), status: 422)
        end
      end
    end

    private

    def create_note_params
      { user_id: params[:id], note: params[:note], pinned: params[:pinned] }
    end

    def update_note_params
      { note_id: params[:id], note: params[:note], pinned: params[:pinned] }
    end

    def delete_note_params
      { note_id: params[:id] }
    end

    def serialize_note(note)
      {
        id: note.id,
        note: note.note,
        pinned: note.pinned,
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
