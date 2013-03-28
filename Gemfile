source 'https://rubygems.org'

gem 'rake'

group :test do
  platforms :jruby do
    case ENV['CI_DB_ADAPTER']
    when 'mysql'
      gem 'activerecord-jdbcmysql-adapter'
      gem 'jdbc-mysql'
    when 'postgresql'
      gem 'activerecord-jdbcpostgresql-adapter'
      gem 'jdbc-postgres'
    else
      gem 'activerecord-jdbcsqlite3-adapter'
      gem 'jdbc-sqlite3'
    end
  end

  platforms :ruby, :mswin, :mingw do
    case ENV['CI_DB_ADAPTER']
    when 'mysql'
      gem 'mysql', '~> 2.8.1'
    when 'postgresql'
      gem 'pg'
    else
      gem 'sqlite3'
    end
  end

  gem 'coveralls', :require => false
  gem 'rspec', '>= 2.11'
  gem 'simplecov', :require => false

  gem 'activerecord', "~> #{ENV['CI_AR_VERSION']}" if ENV['CI_AR_VERSION']
end

gemspec
