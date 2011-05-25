# DelayedJob ActiveRecord Backend

Please note! This is a pre-release version intended for use only with DelayedJob 3.0

## Installation

Add the gems to your Gemfile:

    gem 'delayed_job'
    gem 'delayed_job_active_record'

Run `bundle install`

If you're using Rails, run the generator to create the migration for the delayed_job table: `rails g delayed_job:active_record`

That's it. Use [delayed_job as normal](http://github.com/collectiveidea/delayed_job).