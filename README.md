# **Discourse Recruit Tracker** Plugin

**Plugin Summary**

Recruit tracking for the 16AA Milsim unit.

For more information, please see: https://github.com/16AA-Milsim/discourse-recruit-tracker

## Overview

Discourse Recruit Tracker provides an internal workflow to track recruit
progression to full membership. It stores the current status on the user and
keeps a status history and staff notes for auditability.

## Workflow statuses (configurable labels)

Status keys are fixed, but labels are configurable via site settings:

- pending_recruit_training
- attended_recruit_training
- eligible_for_assessment
- pending_promotion_decision

Once a recruit is promoted, clear the status to remove them from the workflow.
Users in the `Recruit` group appear on the overview by default; staff can
manually add non-recruit members for special cases. Recruits and manually added
members with no status default to "Pending Recruit Training" on the overview.

## Permissions

Access is group-based and controlled by two site settings:

- discourse_recruit_tracker_view_groups: who can view status and the overview
- discourse_recruit_tracker_manage_groups: who can view status, change status and manage notes

## Data storage

- Current status: user custom field `discourse_recruit_tracker_status`
- History: `discourse_recruit_tracker_status_changes` table (stores rank prefixes at change time)
- Notes: `discourse_recruit_tracker_notes` table (single note per recruit; saves overwrite the existing note)

## UI locations

- Overview: `/recruit-tracker` (columns for each status)
- Overview cards show the recruit note, include manager-only edit/remove buttons for manually tracked users, and offer left/right arrows to step status backward/forward.
- Audit log: overview page (latest 20 entries, visible to manage groups only); full log at `/recruit-tracker/audit` (latest 500 entries).
- Rank on Names integration: if `discourse-rank-on-names` is enabled, rank prefixes are shown with usernames.

## Discord notifications (optional)

If enabled, status changes enqueue a Discord webhook notification using:

- discourse_recruit_tracker_discord_notifications_enabled
- discourse_recruit_tracker_discord_webhook_url
- discourse_recruit_tracker_discord_webhook_username
- discourse_recruit_tracker_discord_webhook_avatar_url
- discourse_recruit_tracker_discord_message_template (placeholders: %{actor}, %{user}, %{previous}, %{current})
- discourse_recruit_tracker_discord_server
- discourse_recruit_tracker_discord_channel

Notifications are only sent when a recruit moves from "Attended Recruit Training"
to "Eligible for Assessment".
