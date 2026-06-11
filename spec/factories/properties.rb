FactoryBot.define do
  factory :property do
    sequence(:name) { |n| "Hotel Iris #{n}" }
    street { "Hauptstrasse 1" }
    city { "Berlin" }
    postal_code { "10115" }
    country { "Germany" }
  end
end
