# coding: utf-8

@password = "000000"

User.create!(name: "Sample User",
             email: "sample@email.com",
             password: @password,
             password_confirmation: @password,
             admin: true)

puts "Sample User Sucess."

120.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = @password
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password)
end

puts "User Create Sucess."