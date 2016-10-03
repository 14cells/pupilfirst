FactoryGirl.define do
  factory :founder do
    # Since name validation is strict, and we can't rely on Faker to supply proper names, we'll restrict the set.
    first_name { %w(Douglas Oren Arlie Libby Ilene Lorenzo Sebastian Micheal Kari Tina).sample }
    last_name { %w(Simonis Marquardt Torphy McCullough Funk Sporer Heller Yundt McGlynn Lang).sample }
    born_on { 20.years.ago }
    gender Founder::GENDER_MALE
    email { Faker::Internet.email }
    password 'password'
    password_confirmation 'password'
  end
end
