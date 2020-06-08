# coding: utf-8

@password = "password"

@testuser = User.create!(name: "Sample User",
             email: "sample@email.com",
             employee_number: 1,
             uid: 1,
             password: @password,
             password_confirmation: @password,
             admin: true)
if @testuser
    puts "Admin User Sucess."
end

name  = "上長A"
email = "sample1@email.com"
password = @password
@testuser = User.create!(name: name,
          email: email,
          employee_number: 1000,
          uid: 1000,
          password: password,
          password_confirmation: password,
          admin: false,
          superior: true)
if @testuser
    puts "Superior1 User Sucess."
end

name  = "上長B"
email = "sample2@email.com"
password = @password
@testuser = User.create!(name: name,
          email: email,
          employee_number: 1001,
          uid: 1001,
          password: password,
          password_confirmation: password,
          admin: false,
          superior: true)
if @testuser
    puts "Superior2 User Sucess."
end

name  = "社員1"
email = "sample-1@email.com"
password = @password
@testuser = User.create!(name: name,
          email: email,
          employee_number: 1,
          uid: 1,
          password: password,
          password_confirmation: password,
          admin: false,
          superior: false)
if @testuser
    puts "Employee1 User Sucess."
end

name  = "社員2"
email = "sample-2@email.com"
password = @password
@testuser = User.create!(name: name,
          email: email,
          employee_number: 2,
          uid: 2,
          password: password,
          password_confirmation: password,
          admin: false,
          superior: false)
if @testuser
    puts "Employee2 User Sucess."
end
# 2.times do |n|
#     n = n+2
#     name  = Faker::Name.name
#     email = "sample#{n+1}@email.com"
#     password = @password
#     @testuser = User.create!(name: name,
#                 email: email,
#                 employee_number: n+1,
#                 uid: n+1,
#                 password: password,
#                 password_confirmation: password,
#                 admin: false,
#                 superior: false)
# end
# if @testuser
#     puts "General User Sucess."
# end