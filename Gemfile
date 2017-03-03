source "https://rubygems.org"

gem "rake"

group :test do
  platforms :jruby do
    gem 'activerecord-jdbcmysql-adapter', git: 'https://github.com/jruby/activerecord-jdbc-adapter', branch: 'rails-5'

    gem 'activerecord-jdbcpostgresql-adapter', git: 'https://github.com/jruby/activerecord-jdbc-adapter', branch: 'rails-5'

    gem 'activerecord-jdbcsqlite3-adapter', git: 'https://github.com/jruby/activerecord-jdbc-adapter', branch: 'rails-5'
  end

  platforms :ruby, :mswin, :mingw do
    gem 'mysql2', '~> 0.4.5'
    gem "pg"
    gem "sqlite3"
  end

  gem "coveralls", require: false
  gem "rspec", ">= 3"
  gem "rubocop", ">= 0.23"
  gem "simplecov", require: false
end

gemspec
