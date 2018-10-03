**If you're viewing this at https://github.com/collectiveidea/delayed_job_active_record,
you're reading the documentation for the master branch.
[View documentation for the latest release
(4.1.3).](https://github.com/collectiveidea/delayed_job_active_record/tree/v4.1.3)**

# DelayedJob ActiveRecord Backend

[![Gem Version](https://img.shields.io/gem/v/delayed_job_active_record.svg)](https://rubygems.org/gems/delayed_job_active_record)
[![Build Status](https://img.shields.io/travis/collectiveidea/delayed_job_active_record.svg)](https://travis-ci.org/collectiveidea/delayed_job_active_record)
[![Dependency Status](https://img.shields.io/gemnasium/collectiveidea/delayed_job_active_record.svg)](https://gemnasium.com/collectiveidea/delayed_job_active_record)
[![Code Climate](https://img.shields.io/codeclimate/github/collectiveidea/delayed_job_active_record.svg)](https://codeclimate.com/github/collectiveidea/delayed_job_active_record)
[![Coverage Status](https://img.shields.io/coveralls/collectiveidea/delayed_job_active_record.svg)](https://coveralls.io/r/collectiveidea/delayed_job_active_record)

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
