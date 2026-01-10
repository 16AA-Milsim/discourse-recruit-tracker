# frozen_string_literal: true

class CreateDiscourseRecruitTrackerTables < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_recruit_tracker_status_changes do |t|
      t.integer :user_id, null: false
      t.integer :changed_by_id, null: false
      t.string :previous_status
      t.string :new_status
      t.timestamps null: false
    end

    add_index :discourse_recruit_tracker_status_changes, :user_id
    add_index :discourse_recruit_tracker_status_changes, :changed_by_id
    add_index :discourse_recruit_tracker_status_changes,
              %i[user_id created_at],
              name: "idx_drtsc_user_created_at"

    create_table :discourse_recruit_tracker_notes do |t|
      t.integer :user_id, null: false
      t.integer :created_by_id, null: false
      t.text :note, null: false
      t.boolean :pinned, null: false, default: false
      t.timestamps null: false
    end

    add_index :discourse_recruit_tracker_notes, :user_id
    add_index :discourse_recruit_tracker_notes,
              %i[user_id pinned created_at],
              name: "idx_drtn_user_pinned_created_at"
    add_index :discourse_recruit_tracker_notes, :created_by_id
  end
end
