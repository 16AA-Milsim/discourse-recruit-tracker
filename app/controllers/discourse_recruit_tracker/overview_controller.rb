# frozen_string_literal: true

module DiscourseRecruitTracker
  class OverviewController < BaseController
    before_action :ensure_can_view!
    before_action :ensure_can_manage!, only: [:audit, :audit_log]

    def index
      render html: "", layout: "application"
    end

    def audit
      render html: "", layout: "application"
    end

    def list
      join_date_enabled = join_date_enabled?
      users = users_with_status(include_join_date: join_date_enabled)
      last_changes = last_changes_for(users)
      notes = notes_by_user_id(users)
      users_by_status = build_users_by_status(users, last_changes, join_date_enabled, notes)
      can_manage = DiscourseRecruitTracker::Access.can_manage?(current_user)

      render_json_dump(
        columns: DiscourseRecruitTracker::StatusConfig.columns_for(users_by_status),
        can_manage: can_manage,
        join_date_enabled: join_date_enabled,
        audit_log:
          can_manage ? audit_log_entries(limit: DiscourseRecruitTracker::AuditLog::OVERVIEW_LIMIT) : [],
      )
    end

    def audit_log
      render_json_dump(
        audit_log: audit_log_entries(limit: DiscourseRecruitTracker::AuditLog::MAX_ENTRIES),
      )
    end

    private

    def users_with_status(include_join_date:)
      status_field = ActiveRecord::Base.connection.quote(DiscourseRecruitTracker::STATUS_FIELD)
      scope =
        User
          .joins(group_users: :group)
          .joins(
            "LEFT JOIN user_custom_fields status_fields " \
            "ON status_fields.user_id = users.id " \
            "AND status_fields.name = #{status_field}",
          )
          .where(groups: { name: recruit_group_name })
          .where(
            "status_fields.value IS NULL OR status_fields.value IN (?)",
            DiscourseRecruitTracker::StatusConfig::STATUS_KEYS,
          )

      if include_join_date
        join_date_field = join_date_field_name
        quoted_join_date_field = ActiveRecord::Base.connection.quote(join_date_field)

        scope =
          scope
            .joins(
              "LEFT JOIN user_custom_fields join_dates " \
              "ON join_dates.user_id = users.id " \
              "AND join_dates.name = #{quoted_join_date_field}",
            )
            .select(
              "users.id, users.username, users.name, users.title, users.uploaded_avatar_id, users.created_at, " \
              "status_fields.value AS recruit_status, " \
              "join_dates.value AS join_date",
            )
      else
        scope =
          scope.select(
            "users.id, users.username, users.name, users.title, users.uploaded_avatar_id, users.created_at, " \
            "status_fields.value AS recruit_status",
          )
      end

      scope
    end

    def last_changes_for(users)
      return {} if users.blank?

      DiscourseRecruitTracker::StatusChange
        .where(user_id: users.map(&:id))
        .order(created_at: :desc)
        .group_by(&:user_id)
    end

    def build_users_by_status(users, last_changes, join_date_enabled, notes_by_user_id)
      users_by_status = Hash.new { |hash, key| hash[key] = [] }

      users.each do |user|
        status = user.read_attribute(:recruit_status).presence || default_status_key
        last_change = last_changes[user.id]&.first
        join_date = join_date_enabled ? user.read_attribute(:join_date) : nil
        parsed_join_date = parse_join_date(join_date)
        note = notes_by_user_id[user.id]
        status_neighbors = status_neighbors(status)

        data = serialize_user(user).merge(
          status: status,
          status_label: DiscourseRecruitTracker::StatusConfig.label_for(status),
          last_changed_at: last_change&.created_at,
          join_date: join_date,
          note: note&.note,
          previous_status: status_neighbors[:previous],
          next_status: status_neighbors[:next],
          previous_label: status_neighbors[:previous_label],
          next_label: status_neighbors[:next_label],
        )

        users_by_status[status] << {
          data: data,
          join_date: parsed_join_date,
          created_at: user.created_at,
        }
      end

      users_by_status.transform_values do |entries|
        entries
          .sort_by do |entry|
            join_date = entry[:join_date]
            [
              join_date ? 0 : 1,
              join_date || Date.new(1970, 1, 1),
              entry[:created_at] || Time.at(0),
            ]
          end
          .map { |entry| entry[:data] }
      end
    end

    def audit_log_entries(limit:)
      entries = status_audit_log_entries(limit: limit) + note_audit_log_entries(limit: limit)
      entries.sort_by { |entry| entry[:created_at] || Time.at(0) }.reverse.take(limit)
    end

    def status_audit_log_entries(limit:)
      DiscourseRecruitTracker::StatusChange
        .includes(:user, :changed_by)
        .order(created_at: :desc)
        .limit(limit)
        .filter_map do |change|
          next if change.user.blank? || change.changed_by.blank?

          {
            id: change.id,
            created_at: change.created_at,
            previous_status: change.previous_status,
            previous_label: status_label(change.previous_status),
            new_status: change.new_status,
            new_label: status_label(change.new_status),
            user: serialize_user(change.user, rank_prefix: change.user_rank_prefix),
            changed_by: serialize_user(change.changed_by, rank_prefix: change.changed_by_rank_prefix),
          }
        end
    end

    def note_audit_log_entries(limit:)
      UserHistory
        .where(action: UserHistory.actions[:custom_staff], custom_type: note_audit_types)
        .includes(:acting_user, :target_user)
        .order(created_at: :desc)
        .limit(limit)
        .filter_map do |entry|
          target_user = resolve_note_target_user(entry)
          next if target_user.blank? || entry.acting_user.blank?

          {
            id: "note-#{entry.id}",
            created_at: entry.created_at,
            note_label: note_audit_label(entry.custom_type),
            user: serialize_user(target_user),
            changed_by: serialize_user(entry.acting_user),
          }
        end
    end

    def status_label(status)
      return I18n.t("discourse_recruit_tracker.status.none") if status.blank?

      DiscourseRecruitTracker::StatusConfig.label_for(status)
    end

    def serialize_user(user, rank_prefix: nil)
      {
        id: user.id,
        username: user.username,
        name: user.name,
        title: user.title,
        avatar_template: user.avatar_template,
        rank_prefix: rank_prefix.presence || rank_prefix_for(user),
      }
    end

    def join_date_field_name
      return ::Orbat::Service::JOIN_DATE_FIELD if defined?(::Orbat::Service::JOIN_DATE_FIELD)

      "orbat_join_date"
    end

    def join_date_enabled?
      plugin = Discourse.plugins.find { |registered| registered.name == "discourse-orbat" }
      plugin&.enabled?
    end

    def notes_by_user_id(users)
      return {} if users.blank?

      DiscourseRecruitTracker::Note
        .where(user_id: users.map(&:id))
        .order(updated_at: :desc, created_at: :desc)
        .group_by(&:user_id)
        .transform_values(&:first)
    end

    def parse_join_date(value)
      return if value.blank?

      Date.iso8601(value)
    rescue ArgumentError
      nil
    end

    def status_neighbors(status)
      keys = DiscourseRecruitTracker::StatusConfig::STATUS_KEYS
      index = keys.index(status)
      return { previous: nil, next: nil, previous_label: nil, next_label: nil } if index.nil?

      {
        previous: index.positive? ? keys[index - 1] : nil,
        next: index < (keys.length - 1) ? keys[index + 1] : nil,
        previous_label:
          index.positive? ? DiscourseRecruitTracker::StatusConfig.label_for(keys[index - 1]) : nil,
        next_label:
          index < (keys.length - 1) ? DiscourseRecruitTracker::StatusConfig.label_for(keys[index + 1]) : nil,
      }
    end

    def recruit_group_name
      DiscourseRecruitTracker::RECRUIT_GROUP_NAME
    end

    def default_status_key
      DiscourseRecruitTracker::StatusConfig::STATUS_KEYS.first
    end

    def note_audit_types
      %w[
        recruit_tracker_note_created
        recruit_tracker_note_updated
        recruit_tracker_note_cleared
      ]
    end

    def note_audit_label(custom_type)
      case custom_type
      when "recruit_tracker_note_created"
        I18n.t("discourse_recruit_tracker.audit.note_created")
      when "recruit_tracker_note_cleared"
        I18n.t("discourse_recruit_tracker.audit.note_cleared")
      else
        I18n.t("discourse_recruit_tracker.audit.note_updated")
      end
    end

    def resolve_note_target_user(entry)
      return entry.target_user if entry.target_user.present?

      user_id = entry.details.to_s[/target_user_id:\s*(\d+)/, 1]
      return if user_id.blank?

      User.find_by(id: user_id)
    end
  end
end
