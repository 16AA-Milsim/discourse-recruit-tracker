# frozen_string_literal: true

module DiscourseRecruitTracker
  class UsersController < BaseController
    before_action :ensure_can_view!, only: [:show]
    before_action :ensure_can_manage!, only: [:update_status]

    def show
      user = User.find_by(id: params[:id])
      raise Discourse::NotFound if user.blank?

      status = user.custom_fields[DiscourseRecruitTracker::STATUS_FIELD]
      notes = DiscourseRecruitTracker::Note.where(user_id: user.id).includes(:created_by)
      history = DiscourseRecruitTracker::StatusChange.where(user_id: user.id).includes(:changed_by)

      render_json_dump(
        user_id: user.id,
        status: status,
        status_label: DiscourseRecruitTracker::StatusConfig.label_for(status),
        status_options: DiscourseRecruitTracker::StatusConfig.status_options,
        can_manage: DiscourseRecruitTracker::Access.can_manage?(current_user),
        notes: serialize_notes(notes),
        history: serialize_history(history),
      )
    end

    def update_status
      DiscourseRecruitTracker::UpdateStatus.call(guardian:, params: update_status_params) do
        on_success do |status:, previous_status:, changed:|
          render_json_dump(
            status: status,
            status_label: DiscourseRecruitTracker::StatusConfig.label_for(status),
            previous_status: previous_status,
            changed: changed,
          )
        end
        on_model_not_found(:user) { raise Discourse::NotFound }
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages.join(", "), status: 422)
        end
        on_failed_step(:validate_status) do |step|
          render_json_error(step.error, status: 422)
        end
      end
    end

    private

    def update_status_params
      { user_id: params[:id], status: params[:status] }
    end

    def serialize_notes(notes)
      notes.order(pinned: :desc, created_at: :desc).map do |note|
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

    def serialize_history(changes)
      changes.order(created_at: :desc).map do |change|
        {
          id: change.id,
          previous_status: change.previous_status,
          previous_label: status_label(change.previous_status),
          new_status: change.new_status,
          new_label: status_label(change.new_status),
          created_at: change.created_at,
          changed_by: {
            id: change.changed_by.id,
            username: change.changed_by.username,
            avatar_template: change.changed_by.avatar_template,
          },
        }
      end
    end

    def status_label(status)
      return I18n.t("discourse_recruit_tracker.status.none") if status.blank?

      DiscourseRecruitTracker::StatusConfig.label_for(status)
    end
  end
end
