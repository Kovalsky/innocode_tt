# README


* Ruby version
    * 3.4.6

For manual setup:
  PostgreSQL on 5432 port
  Redis on 6379 port

mv .env.example .env
add your GOOGLE_MAPS_API_KEY to .env file

bundle install
rake db:create db:migrate

Or build with docker:
    docker build -t innocode_tt .

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

    route = Route.create(
      title: "Kyiv-Lviv Route",
      origin: "50.450240400493975:30.524468009758962",
      destination: "49.84422673062658:24.026473914219874",
      last_updated_at: Time.current
    )

    service = GoogleDistanceService.new(route:)
    service.call

    REDIS_STORE.get("GoogleDistanceService:#{route.id}")
    route.reload.last_updated_at


For dockerized rails console:
    docker run --rm -it -e RAILS_ENV=development innocode_tt bash -lc "./bin/rails console"
Or for dockerized rspec:
    docker run --rm -it -e RAILS_ENV=test innocode_tt bash -lc "bundle exec rspec spec/services/google_distance_service_spec.rb"
