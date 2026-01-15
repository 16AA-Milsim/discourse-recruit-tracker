# frozen_string_literal: true

DiscourseRecruitTracker::Engine.routes.draw do
  get "/" => "overview#index", defaults: { format: :html }
  get "/overview" => "overview#list", defaults: { format: :json }
  get "/audit" => "overview#audit_log", constraints: { format: :json }, defaults: { format: :json }
  get "/audit" => "overview#audit", defaults: { format: :html }
  put "/users/:id/status" => "users#update_status", defaults: { format: :json }
  post "/users/:id/notes" => "notes#create", defaults: { format: :json }
end
