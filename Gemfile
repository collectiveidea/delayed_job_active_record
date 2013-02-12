source :rubygems

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

  gem 'rspec', '>= 2.11'
end

gemspec
