# frozen_string_literal: true

module DiscourseRecruitTracker
  class StatusChange < ::ActiveRecord::Base
    self.table_name = "discourse_recruit_tracker_status_changes"

    belongs_to :user
    belongs_to :changed_by, class_name: "User"

    validates :user_id, presence: true
    validates :changed_by_id, presence: true
    validates :previous_status, length: { maximum: 100 }, allow_nil: true
    validates :new_status, length: { maximum: 100 }, allow_nil: true
  end
end
