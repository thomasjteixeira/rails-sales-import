if Rails.env.production?
  # Configure SQLite for production
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
end
