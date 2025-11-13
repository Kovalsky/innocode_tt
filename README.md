# README


* Ruby version

*  Dependencies
    * PostgreSQL on 5432 port
    * Redis on 6379 port

* Database initialization
    * rake db:create
    * rake db:migrate


To run service spec:
rspec spec/services/google_distance_service_spec.rb

Or to check manually in rails console:

rails c

    # need to be set manually in console because store initialized in app on each puma's processes fork
    REDIS_STORE = RedisStore.new(
      url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/"),
      pool_size: ENV.fetch("REDIS_POOL_SIZE", 5).to_i,
      timeout: ENV.fetch("REDIS_POOL_TIMEOUT", 5).to_i
    )

    service = GoogleDistanceService.new(route: 'driving', origin: 'New York, NY', destination: 'Los Angeles, CA')
    service.call

