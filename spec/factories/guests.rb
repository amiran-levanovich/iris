FactoryBot.define do
  factory :guest do
    first_name { "Ada" }
    sequence(:last_name) { |n| "Lovelace#{n}" }
    sequence(:email) { |n| "guest#{n}@example.com" }
    phone { "+49 30 1234567" }
    street { "1 Test Street" }
    city { "Berlin" }
    postal_code { "10115" }
    country { "DE" }
  end
end
