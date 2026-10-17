**If you're viewing this at https://github.com/collectiveidea/delayed_job_active_record,
you're reading the documentation for the master branch.
[View documentation for the latest release
(4.1.11).](https://github.com/collectiveidea/delayed_job_active_record/tree/v4.1.11)**

# DelayedJob ActiveRecord Backend

[![Gem Version](https://badge.fury.io/rb/delayed_job_active_record.svg)][gem]
[![CI](https://github.com/collectiveidea/delayed_job_active_record/actions/workflows/ci.yml/badge.svg)][ci]
[![Coverage Status](https://coveralls.io/repos/collectiveidea/delayed_job_active_record/badge.svg?branch=master)][coveralls]

[gem]: https://rubygems.org/gems/delayed_job_active_record
[ci]: https://github.com/collectiveidea/delayed_job_active_record/actions/workflows/ci.yml
[coveralls]: https://coveralls.io/r/collectiveidea/delayed_job_active_record

The Active Record backend for [Delayed::Job][delayed_job]. It stores jobs in a
database table and works with PostgreSQL, MySQL (via mysql2 or Trilogy),
SQLite, and other databases Active Record supports.

See the [CHANGELOG](CHANGELOG.md) for what's new in each release.

[delayed_job]: https://github.com/collectiveidea/delayed_job

## Installation

delayed_job_active_record requires Ruby 3.2 or later and Active Record 6.0 or
later.

Add the gem to your `Gemfile`:

```ruby
gem "delayed_job_active_record"
```

Run `bundle install`.

If you're using Rails, run the generator to create the migration for the
`delayed_jobs` table, then run the migration:

    bin/rails generate delayed_job:active_record
    bin/rails db:migrate

The table name honors `ActiveRecord::Base.table_name_prefix`.

That's it. Use [delayed_job as normal][delayed_job].

## Problems locking jobs

By default, workers reserve jobs with SQL optimized for the database.
PostgreSQL locks the next job in a single `UPDATE ... RETURNING` query,
skipping rows other workers have locked on PostgreSQL 9.5 and later. MySQL and
Trilogy use `UPDATE ... LIMIT`, and MSSQL and Teradata use an `UPDATE` with a
subquery. Other databases use the default strategy, which reads a few candidate
job IDs and locks the first one it can.

If the optimized SQL causes problems with your database, you can switch to the
default strategy, which is usually slower, in an initializer:

```ruby
Delayed::Backend::ActiveRecord.configure do |config|
  config.reserve_sql_strategy = :default_sql
end
```

## Upgrading from delayed_job 2.x

If you're upgrading from delayed_job 2.x, run the upgrade generator to create a
migration that adds the `queue` column to your `delayed_jobs` table:

    bin/rails generate delayed_job:upgrade
    bin/rails db:migrate
