# DelayedJob ActiveRecord Backend [![Build Status](http://travis-ci.org/collectiveidea/delayed_job_active_record.png)](https://travis-ci.org/collectiveidea/delayed_job_active_record) [![Dependency Status](https://gemnasium.com/collectiveidea/delayed_job_active_record.png)](https://gemnasium.com/collectiveidea/delayed_job_active_record)

## Installation

Add the gem to your Gemfile:

    gem 'delayed_job_active_record'

Run `bundle install`.

If you're using Rails, run the generator to create the migration for the delayed_job table.

    rails g delayed_job:active_record
    rake db:migrate
    
## Upgrading from 2.x to 3.0.0

If you're upgrading from Delayed Job 2.x, run the upgrade generator to create a migration to add a column to your delayed_jobs table.

    rails g delayed_job:upgrade
    rake db:migrate

That's it. Use [delayed_job as normal](http://github.com/collectiveidea/delayed_job).

## How to contribute

If you find what looks like a bug:

* Search the [mailing list](http://groups.google.com/group/delayed_job) to see if anyone else had the same issue.
* Check the [GitHub issue tracker](http://github.com/collectiveidea/delayed_job_active_record/issues/) to see if anyone else has reported issue.
* If you don't see anything, create an issue with information on how to reproduce it.

If you want to contribute an enhancement or a fix:

* Fork the project on github.
* Make your changes with tests.
* Commit the changes without making changes to the Rakefile or any other files that aren't related to your enhancement or fix
* Send a pull request.
