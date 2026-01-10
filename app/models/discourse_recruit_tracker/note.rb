# frozen_string_literal: true

module DiscourseRecruitTracker
  class Note < ::ActiveRecord::Base
    self.table_name = "discourse_recruit_tracker_notes"

    belongs_to :user
    belongs_to :created_by, class_name: "User"

    validates :user_id, presence: true
    validates :created_by_id, presence: true
    validates :note, presence: true, length: { maximum: 2000 }
  end
end
