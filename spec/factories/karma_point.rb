FactoryBot.define do
  factory :karma_point do
    founder { create :founder }
    points { [10, 20, 30, 40, 50].sample }
    activity_type { Faker::Lorem.words(10).join ' ' }
  end
end
