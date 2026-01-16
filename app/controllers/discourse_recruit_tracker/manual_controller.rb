# frozen_string_literal: true

module DiscourseRecruitTracker
  class ManualController < BaseController
    before_action :ensure_can_manage!

    def create
      DiscourseRecruitTracker::UpdateManualTracking.call(guardian:, params: create_params) do
        on_success { |user:, changed:| render_json_dump(user_id: user.id, changed: changed) }
        on_model_not_found(:user) { raise Discourse::NotFound }
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages.join(", "), status: 422)
        end
        on_failed_step(:apply) { |step| render_json_error(step.error, status: 422) }
      end
    end

    def destroy
      DiscourseRecruitTracker::UpdateManualTracking.call(guardian:, params: destroy_params) do
        on_success { |user:, changed:| render_json_dump(user_id: user.id, changed: changed) }
        on_model_not_found(:user) { raise Discourse::NotFound }
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages.join(", "), status: 422)
        end
        on_failed_step(:apply) { |step| render_json_error(step.error, status: 422) }
      end
    end

    private

    def create_params
      { username: params[:username], enabled: true }
    end

    def destroy_params
      { user_id: params[:id], enabled: false }
    end
  end
end
