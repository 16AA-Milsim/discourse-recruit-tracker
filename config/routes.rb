# frozen_string_literal: true

DiscourseRecruitTracker::Engine.routes.draw do
  get "/" => "overview#index", constraints: { format: :html }
  get "/overview" => "overview#list", defaults: { format: :json }
  get "/users/:id" => "users#show", defaults: { format: :json }
  put "/users/:id/status" => "users#update_status", defaults: { format: :json }
  post "/users/:id/notes" => "notes#create", defaults: { format: :json }
  put "/notes/:id" => "notes#update", defaults: { format: :json }
  delete "/notes/:id" => "notes#destroy", defaults: { format: :json }
end
