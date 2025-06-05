require "sidekiq"
require "sidekiq/web"

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

if Rails.env.production?
  Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
    [ user, password ] == [ "admin", "admin" ]
  end
end
