# frozen_string_literal: true

source "https://rubygems.org"

gem "rake"

group :test do
  platforms :jruby do
    gem "activerecord-jdbcmysql-adapter"
    gem "activerecord-jdbcpostgresql-adapter"
    gem "activerecord-jdbcsqlite3-adapter"
  end

  platforms :ruby, :mswin, :mingw do
    gem "mysql2", "~> 0.5.0"
    gem "pg", "~> 1.1"
    gem "sqlite3"
    gem "trilogy"
  end

  gem "rspec", ">= 3"

  gem "simplecov", ">= 0.20.0", require: false
  gem "simplecov-lcov", ">= 0.8.0", require: false
end

group :rubocop do
  gem "rubocop", "~> 1.88"
  gem "rubocop-packaging", "~> 0.6"
  gem "rubocop-performance", "~> 1.27"
  gem "rubocop-rails", "~> 2.38"
  gem "rubocop-rspec", "~> 3.10"
end

gemspec
