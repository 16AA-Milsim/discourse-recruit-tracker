# frozen_string_literal: true

# name: discourse-recruit-tracker
# about: Recruit tracking for the 16AA Milsim unit.
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: https://github.com/16AA-Milsim/discourse-recruit-tracker
# required_version: 2.7.0

enabled_site_setting :discourse_recruit_tracker_enabled

module ::DiscourseRecruitTracker
  PLUGIN_NAME = "discourse-recruit-tracker"
end

require_relative "lib/discourse_recruit_tracker/engine"

after_initialize do
  # Code which should run after Rails has finished booting
end
