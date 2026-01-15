# frozen_string_literal: true

module DiscourseRecruitTracker
  module AuditLog
    MAX_ENTRIES = 500
    OVERVIEW_LIMIT = 20
    NOTE_CUSTOM_TYPES = %w[
      recruit_tracker_note_created
      recruit_tracker_note_updated
      recruit_tracker_note_cleared
    ].freeze

    module_function

    def trim!
      keep = combined_keep_entries
      keep_status_ids = keep.select { |entry| entry[:type] == :status }.map { |entry| entry[:id] }
      keep_note_ids = keep.select { |entry| entry[:type] == :note }.map { |entry| entry[:id] }

      trim_status_changes(keep_status_ids)
      trim_note_histories(keep_note_ids)
    end

    def combined_keep_entries
      entries = status_entries + note_entries
      entries.sort_by! { |entry| entry[:created_at] }
      entries.reverse!
      entries.take(MAX_ENTRIES)
    end

    def status_entries
      DiscourseRecruitTracker::StatusChange
        .order(created_at: :desc)
        .limit(MAX_ENTRIES)
        .pluck(:id, :created_at)
        .map { |id, created_at| { type: :status, id: id, created_at: created_at } }
    end

    def note_entries
      note_scope =
        UserHistory.where(action: UserHistory.actions[:custom_staff], custom_type: NOTE_CUSTOM_TYPES)

      note_scope
        .order(created_at: :desc)
        .limit(MAX_ENTRIES)
        .pluck(:id, :created_at)
        .map { |id, created_at| { type: :note, id: id, created_at: created_at } }
    end

    def trim_status_changes(keep_ids)
      scope = DiscourseRecruitTracker::StatusChange
      if keep_ids.any?
        scope.where.not(id: keep_ids).delete_all
      else
        scope.delete_all
      end
    end

    def trim_note_histories(keep_ids)
      scope =
        UserHistory.where(action: UserHistory.actions[:custom_staff], custom_type: NOTE_CUSTOM_TYPES)
      if keep_ids.any?
        scope.where.not(id: keep_ids).delete_all
      else
        scope.delete_all
      end
    end
  end
end
