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
    gem "mysql2", "~> 0.4.5"
    gem "pg", "~> 0.18"
    gem "sqlite3"
  end

  gem "rspec", ">= 3"

  gem "simplecov", ">= 0.20.0", require: false
  gem "simplecov-lcov", ">= 0.8.0", require: false
end

group :rubocop do
  gem "rubocop"
  gem "rubocop-packaging"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "rubocop-rspec"
end

gemspec
