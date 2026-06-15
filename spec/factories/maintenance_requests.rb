FactoryBot.define do
  factory :maintenance_request do
    room
    title { "Leaking faucet" }
    category { "plumbing" }
    priority { "medium" }

    trait :in_progress do
      status { "in_progress" }
    end

    trait :resolved do
      status { "resolved" }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end
end
