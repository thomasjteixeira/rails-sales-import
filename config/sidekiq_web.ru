require "sidekiq/web"
require_relative "environment"

run Sidekiq::Web
