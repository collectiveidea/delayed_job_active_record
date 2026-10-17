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

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.2")
    gem "simplecov", ">= 1.2", require: false
  else
    # SimpleCov 1.0 requires Ruby 3.2
    gem "simplecov", ">= 0.20.0", require: false
  end
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
