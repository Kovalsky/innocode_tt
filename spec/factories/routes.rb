FactoryBot.define do
  factory :route do
    title { Faker::Address.city  }
    origin { "#{Faker::Address.latitude}:#{Faker::Address.longitude}" }
    destination { "#{Faker::Address.latitude}:#{Faker::Address.longitude}" }
    last_updated_at { Faker::Time.backward(days: rand(1..30), period: :evening) }
  end
end
