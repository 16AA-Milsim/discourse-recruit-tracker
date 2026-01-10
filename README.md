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

## Permissions

Access is group-based and controlled by two site settings:

- discourse_recruit_tracker_view_groups: who can view status and the overview
- discourse_recruit_tracker_manage_groups: who can change status and manage notes

Viewing and managing are independent to allow role overlap without forcing
identical permissions.

## Data storage

- Current status: user custom field `discourse_recruit_tracker_status`
- History: `discourse_recruit_tracker_status_changes` table
- Notes: `discourse_recruit_tracker_notes` table

## UI locations

- Overview: `/recruit-tracker` (columns for each status)
- User profile: a Recruit Tracking panel shown to authorized viewers

## Discord notifications (optional)

If enabled, status changes enqueue a Discord webhook notification using:

- discourse_recruit_tracker_discord_notifications_enabled
- discourse_recruit_tracker_discord_webhook_url
- discourse_recruit_tracker_discord_webhook_username
- discourse_recruit_tracker_discord_webhook_avatar_url
- discourse_recruit_tracker_discord_server
- discourse_recruit_tracker_discord_channel
