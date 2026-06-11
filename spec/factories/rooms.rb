FactoryBot.define do
  factory :room do
    property
    sequence(:number) { |n| format("%03d", n) }
    room_type { "double" }
    capacity { 2 }
    nightly_rate_cents { 12_000 }

    trait :cleaning do
      status { "cleaning" }
    end

    trait :out_of_service do
      status { "out_of_service" }
    end
  end
end
