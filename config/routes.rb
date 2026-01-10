# frozen_string_literal: true

DiscourseRecruitTracker::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::DiscourseRecruitTracker::Engine, at: "discourse-recruit-tracker" }
