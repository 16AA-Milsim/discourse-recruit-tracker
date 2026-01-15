# frozen_string_literal: true

class AddRankPrefixesToRecruitTrackerStatusChanges < ActiveRecord::Migration[7.0]
  def change
    add_column :discourse_recruit_tracker_status_changes, :user_rank_prefix, :string, limit: 50
    add_column :discourse_recruit_tracker_status_changes, :changed_by_rank_prefix, :string, limit: 50
  end
end
