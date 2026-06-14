FactoryBot.define do
  factory :reservation do
    guest
    room
    internal_id { ReservationCode.generate }
    check_in_on { Date.current }
    check_out_on { Date.current.next_day(3) }
    nightly_rate_cents { 12_000 }

    trait :checked_in do
      status { "checked_in" }
    end

    trait :checked_out do
      status { "checked_out" }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end
end
