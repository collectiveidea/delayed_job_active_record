# frozen_string_literal: true

source "https://rubygems.org"

gem "rake"

group :test do
  # Default JRuby to the newest Rails the JDBC adapters all support.
  # Without a pin the resolver would pair a modern Active Record with an
  # ancient 1.x adapter, which has no upper bound on activerecord. JRuby
  # 10.1 removed the Java APIs the stable 72.x adapters were compiled
  # against, so only the Rails 8 prerelease adapters work there.
  if RUBY_ENGINE == "jruby"
    if Gem::Version.new(JRUBY_VERSION) >= Gem::Version.new("10.1")
      jdbc_version = "80.0.pre1"
      gem "activerecord", "~> 8.0.0"
    else
      jdbc_version = "~> 72"
      gem "activerecord", "~> 7.2.0"
    end
    gem "activerecord-jdbcmysql-adapter", jdbc_version
    gem "activerecord-jdbcpostgresql-adapter", jdbc_version
    gem "activerecord-jdbcsqlite3-adapter", jdbc_version
  end

  platforms :ruby, :windows do
    gem "mysql2", "~> 0.5.0"
    gem "pg", "~> 1.1"
    gem "sqlite3"
    gem "trilogy"
  end

  gem "rspec", ">= 3"

  gem "simplecov", ">= 1.2", require: false
  gem "simplecov-lcov", ">= 0.8", require: false
end

group :rubocop do
  gem "rubocop"
  gem "rubocop-packaging"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "rubocop-rspec"
end

gemspec
