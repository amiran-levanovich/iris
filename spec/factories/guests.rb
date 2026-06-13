FactoryBot.define do
  factory :guest do
    sequence(:name) { |n| "Guest #{n}" }
    sequence(:email) { |n| "guest#{n}@example.com" }
    phone { "+49 30 1234567" }
  end
end
