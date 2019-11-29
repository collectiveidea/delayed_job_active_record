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

  gem "coveralls", require: false
  gem "rspec", ">= 3"
  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "simplecov", require: false
end

gemspec
