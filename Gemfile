source :rubygems

gem 'rake'

group :test do

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
