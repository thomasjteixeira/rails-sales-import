if Rails.env.production?
  # Configure SQLite for production when database is ready
  Rails.application.config.after_initialize do
    if ActiveRecord::Base.connection_pool.connected?
      # Enable WAL mode for better concurrency
      ActiveRecord::Base.connection.execute("PRAGMA journal_mode=WAL;")

      # Set busy timeout
      ActiveRecord::Base.connection.execute("PRAGMA busy_timeout=5000;")

      # Enable foreign key constraints
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys=ON;")

      # Optimize for production
      ActiveRecord::Base.connection.execute("PRAGMA synchronous=NORMAL;")
      ActiveRecord::Base.connection.execute("PRAGMA cache_size=1000;")
      ActiveRecord::Base.connection.execute("PRAGMA temp_store=memory;")

      Rails.logger.info "SQLite production optimizations applied"
    end
  rescue => e
    Rails.logger.warn "Could not apply SQLite optimizations: #{e.message}"
  end
end
