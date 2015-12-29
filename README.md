**If you're viewing this at https://github.com/collectiveidea/delayed_job_active_record,
you're reading the documentation for the master branch.
[View documentation for the latest release
(4.1.0).](https://github.com/collectiveidea/delayed_job_active_record/tree/v4.1.0)**

# DelayedJob ActiveRecord Backend

[![Gem Version](https://badge.fury.io/rb/delayed_job_active_record.png)](https://rubygems.org/gems/delayed_job_active_record)
[![Build Status](https://travis-ci.org/collectiveidea/delayed_job_active_record.png)](https://travis-ci.org/collectiveidea/delayed_job_active_record)
[![Dependency Status](https://gemnasium.com/collectiveidea/delayed_job_active_record.png)](https://gemnasium.com/collectiveidea/delayed_job_active_record)
[![Code Climate](https://codeclimate.com/github/collectiveidea/delayed_job_active_record.png)](https://codeclimate.com/github/collectiveidea/delayed_job_active_record)
[![Coverage Status](https://coveralls.io/repos/collectiveidea/delayed_job_active_record/badge.png?branch=master)](https://coveralls.io/r/collectiveidea/delayed_job_active_record)

## Installation

Add the gem to your Gemfile:

    gem 'delayed_job_active_record'

Run `bundle install`.

If you're using Rails, run the generator to create the migration for the
delayed_job table.

    rails g delayed_job:active_record
    rake db:migrate

## Problems locking jobs

You can try using the legacy locking code. It is usually slower but works better for certain people.

    Delayed::Backend::ActiveRecord.configuration.reserve_sql_strategy = :default_sql

## Upgrading from 2.x to 3.0.0

If you're upgrading from Delayed Job 2.x, run the upgrade generator to create a
migration to add a column to your delayed_jobs table.

    rails g delayed_job:upgrade
    rake db:migrate

That's it. Use [delayed_job as normal](http://github.com/collectiveidea/delayed_job).
