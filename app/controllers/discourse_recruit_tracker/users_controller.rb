# frozen_string_literal: true

module DiscourseRecruitTracker
  class UsersController < BaseController
    before_action :ensure_can_manage!

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
  end
end
