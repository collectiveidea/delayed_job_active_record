# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Test against Ruby 3.4 and 4.0, Rails 8.1, and JRuby 10.

## [4.1.11] - 2024-11-09

### Changed

- Allow Active Record 8. ([#242])

## [4.1.10] - 2024-08-19

### Fixed

- `before_fork` raised an error on Rails 7.2, a regression in 4.1.9. ([#236])

## [4.1.9] - 2024-08-15

### Changed

- Skip locked rows when reserving jobs on PostgreSQL 9.5 and later. ([#215], [@stevenharman])
- Use the optimized MySQL reservation query with the Trilogy adapter. ([#222], [@taketo1113])

### Fixed

- Fix the deprecation warning for `clear_all_connections!` on Rails 7.1. ([#226], [@c960657])

## [4.1.9.rc1] - 2024-08-15

### Changed

- Pre-release to validate the trusted publishing build.
- Skip locked rows when reserving jobs on PostgreSQL 9.5 and later. ([#215], [@stevenharman])
- Use the optimized MySQL reservation query with the Trilogy adapter. ([#222], [@taketo1113])

### Fixed

- Fix the deprecation warning for `clear_all_connections!` on Rails 7.1. ([#226], [@c960657])

## [4.1.8] - 2023-10-13

### Fixed

- Read `default_timezone` and `timestamped_migrations` from `ActiveRecord` on Rails 7.1, which removed them from `ActiveRecord::Base`. ([#216])
- Fix the deprecation warning for `ActiveRecord::Base.clear_all_connections!` on Rails 7.1. ([#218], [@bjer])

## [4.1.7] - 2022-01-18

### Changed

- Allow Active Record 7.0. ([#205])

## [4.1.6] - 2021-03-26

### Removed

- Revert the Railtie added in 4.1.5. ([#191])

## [4.1.5] - 2020-12-09

### Added

- Add a Railtie that sets the Active Record backend once Active Record loads. ([#172], [@p8])

### Changed

- Allow Active Record 6.1. ([#184])
- The default SQL strategy reads only job IDs until it locks a job. ([#165], [@racerpeter])

### Fixed

- Remove the `force` option from the generated migration. ([#152], [@rvasquez-flip4new])

## [4.1.4] - 2019-08-20

### Changed

- Allow Active Record 6.0. ([#167])

## [4.1.4.beta1] - 2019-02-18

### Changed

- Allow Active Record 6.0.

## [4.1.3] - 2018-04-13

### Changed

- Allow Active Record 5.2. ([#154], [@pixeltrix])
- Use the optimized PostgreSQL reservation query with the PostGIS adapter. ([#117], [@stestaub])

## [4.1.2] - 2017-05-27

### Changed

- Allow Active Record 5.1. ([#138], [@laserlemon])
- Generated migrations specify the Active Record version on Rails 5 and later.

## [4.1.1] - 2016-05-16

### Added

- `Delayed::Backend::ActiveRecord.configuration.reserve_sql_strategy` selects the optimized or the default SQL for reserving jobs. ([#111], [@klausmeyer])

### Changed

- Allow Active Record 5.0. ([#118], [@mvastola])

## [4.1.0] - 2015-09-24

### Changed

- Allow delayed_job 4.1.

## [4.0.3] - 2014-12-22

### Changed

- Allow Active Record 4.2. ([#98], [@eitoball])

### Fixed

- Reserving jobs failed on MySQL 5.6.4 and later, which stores fractional seconds. ([#96], [@domitian])
- Fix the deprecation warning for `timestamps` in the generated migration.

## [4.0.2] - 2014-08-19

### Changed

- Extract the reservation strategies into separate methods. ([#89], [@csmuc])

## [4.0.1] - 2014-04-12

### Changed

- Allow Active Record 4.1. ([#86], [@MSch])

## [4.0.0] - 2013-07-30

### Added

- Support the Teradata adapter. ([#67], [@evgenyrahman])

### Fixed

- Add a missing require for the Active Record generators.

## [4.0.0.beta3] - 2013-05-28

### Added

- Support the MSSQL adapter. ([#57], [@avinmathew])

### Changed

- Allow delayed_job 3.0 and Active Record 3.0 again.
- The generated migration adds `NOT NULL` constraints. ([#52], [@croaky])
- Only declare `attr_accessible` when mass assignment security is loaded, as with `protected_attributes` on Rails 4.

### Fixed

- Failed jobs were reserved again and re-run repeatedly. ([#53], [@eric88])
- The generators raised `NameError` on Rails 4. ([#58], [@cofyc])

## [4.0.0.beta2] - 2013-04-02

### Changed

- Use optimized SQL to reserve jobs on PostgreSQL and MySQL, and read ahead on other databases. ([#46])

### Fixed

- The migration generator failed on Rails 4. ([#41], [#45], [@michalczapko])

## [0.4.4] - 2013-04-02

### Changed

- Use optimized SQL to reserve jobs on PostgreSQL and MySQL, and read ahead on other databases.

## [4.0.0.beta1] - 2013-03-02

### Changed

- **Breaking:** Require delayed_job 4.0 and Active Record 3.0 or later.
- Support Rails 4. ([#39], [@agrobbin])

## [0.4.3] - 2013-03-02

### Changed

- Reserve jobs with SQL that works on more databases, including SQL Server. ([#38], [@superchris])

## [0.4.2] - 2013-02-26

### Fixed

- Reserving jobs on PostgreSQL quoted the table name as a column name. ([#37], [@shiroginne])

## [0.4.1] - 2013-02-12

### Fixed

- Reserving jobs failed on MySQL.

## [0.4.0] - 2013-02-10

### Changed

- Lock jobs in a single query, which works better with many workers. ([#29], [@scosman])

### Removed

- **Breaking:** Support for Rails 2. ([#26], [@rwz])

### Fixed

- `locked_at` and `locked_by` weren't cleared when a job was rescheduled.
- Fix the primary key deprecation warning.

## [0.3.3] - 2012-09-30

### Changed

- Prefix the jobs table name with `ActiveRecord::Base.table_name_prefix`. ([#19], [@tmikoss])
- Require Active Record older than 4.0.

### Fixed

- Define the scopes as class methods to avoid `ActiveRecord::ConnectionNotEstablished` when loading. ([#10], [#16], [@guiocavalcanti])

## [0.3.2] - 2012-01-30

### Fixed

- Fix the `set_table_name` deprecation warning on Rails 3.2.

## [0.3.1] - 2012-01-01

### Fixed

- The upgrade migration didn't work before Rails 3.1.

## [0.3.0] - 2011-12-30

### Added

- `rails generate delayed_job:upgrade` adds the `queue` column for upgrades from delayed_job 2.x.

### Changed

- Require delayed_job 3.0.

## [0.2.2] - 2011-12-30

### Fixed

- Declare the job attributes as accessible for mass assignment.

## [0.2.1] - 2011-11-30

### Changed

- Allow the latest delayed_job 3.0 prerelease. ([#2], [@sferik])

## [0.2.0] - 2011-09-29

### Added

- Initial release, extracted from delayed_job.

[Unreleased]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.11...HEAD
[4.1.11]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.10...v4.1.11
[4.1.10]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.9...v4.1.10
[4.1.9]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.8...v4.1.9
[4.1.9.rc1]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.8...v4.1.9.rc1
[4.1.8]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.7...v4.1.8
[4.1.7]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.6...v4.1.7
[4.1.6]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.5...v4.1.6
[4.1.5]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.4...v4.1.5
[4.1.4]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.3...v4.1.4
[4.1.4.beta1]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.3...v4.1.4.beta1
[4.1.3]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.2...v4.1.3
[4.1.2]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.1...v4.1.2
[4.1.1]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.1.0...v4.1.1
[4.1.0]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.0.3...v4.1.0
[4.0.3]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.0.2...v4.0.3
[4.0.2]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.0.1...v4.0.2
[4.0.1]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.0.0...v4.0.1
[4.0.0]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.0.0.beta3...v4.0.0
[4.0.0.beta3]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.0.0.beta2...v4.0.0.beta3
[4.0.0.beta2]: https://github.com/collectiveidea/delayed_job_active_record/compare/v4.0.0.beta1...v4.0.0.beta2
[0.4.4]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.4.3...v0.4.4
[4.0.0.beta1]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.4.3...v4.0.0.beta1
[0.4.3]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.3.3...v0.4.0
[0.3.3]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.2.2...v0.3.0
[0.2.2]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/collectiveidea/delayed_job_active_record/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/collectiveidea/delayed_job_active_record/releases/tag/v0.2.0

[#2]: https://github.com/collectiveidea/delayed_job_active_record/pull/2
[#10]: https://github.com/collectiveidea/delayed_job_active_record/issues/10
[#16]: https://github.com/collectiveidea/delayed_job_active_record/pull/16
[#19]: https://github.com/collectiveidea/delayed_job_active_record/pull/19
[#26]: https://github.com/collectiveidea/delayed_job_active_record/pull/26
[#29]: https://github.com/collectiveidea/delayed_job_active_record/pull/29
[#37]: https://github.com/collectiveidea/delayed_job_active_record/pull/37
[#38]: https://github.com/collectiveidea/delayed_job_active_record/pull/38
[#39]: https://github.com/collectiveidea/delayed_job_active_record/pull/39
[#41]: https://github.com/collectiveidea/delayed_job_active_record/issues/41
[#45]: https://github.com/collectiveidea/delayed_job_active_record/pull/45
[#46]: https://github.com/collectiveidea/delayed_job_active_record/pull/46
[#52]: https://github.com/collectiveidea/delayed_job_active_record/pull/52
[#53]: https://github.com/collectiveidea/delayed_job_active_record/pull/53
[#57]: https://github.com/collectiveidea/delayed_job_active_record/pull/57
[#58]: https://github.com/collectiveidea/delayed_job_active_record/pull/58
[#67]: https://github.com/collectiveidea/delayed_job_active_record/pull/67
[#86]: https://github.com/collectiveidea/delayed_job_active_record/pull/86
[#89]: https://github.com/collectiveidea/delayed_job_active_record/pull/89
[#96]: https://github.com/collectiveidea/delayed_job_active_record/pull/96
[#98]: https://github.com/collectiveidea/delayed_job_active_record/pull/98
[#111]: https://github.com/collectiveidea/delayed_job_active_record/pull/111
[#117]: https://github.com/collectiveidea/delayed_job_active_record/pull/117
[#118]: https://github.com/collectiveidea/delayed_job_active_record/pull/118
[#138]: https://github.com/collectiveidea/delayed_job_active_record/pull/138
[#152]: https://github.com/collectiveidea/delayed_job_active_record/pull/152
[#154]: https://github.com/collectiveidea/delayed_job_active_record/pull/154
[#165]: https://github.com/collectiveidea/delayed_job_active_record/pull/165
[#167]: https://github.com/collectiveidea/delayed_job_active_record/pull/167
[#172]: https://github.com/collectiveidea/delayed_job_active_record/pull/172
[#184]: https://github.com/collectiveidea/delayed_job_active_record/pull/184
[#191]: https://github.com/collectiveidea/delayed_job_active_record/pull/191
[#205]: https://github.com/collectiveidea/delayed_job_active_record/pull/205
[#215]: https://github.com/collectiveidea/delayed_job_active_record/pull/215
[#216]: https://github.com/collectiveidea/delayed_job_active_record/pull/216
[#218]: https://github.com/collectiveidea/delayed_job_active_record/pull/218
[#222]: https://github.com/collectiveidea/delayed_job_active_record/pull/222
[#226]: https://github.com/collectiveidea/delayed_job_active_record/pull/226
[#236]: https://github.com/collectiveidea/delayed_job_active_record/pull/236
[#242]: https://github.com/collectiveidea/delayed_job_active_record/pull/242

[@agrobbin]: https://github.com/agrobbin
[@avinmathew]: https://github.com/avinmathew
[@bjer]: https://github.com/bjer
[@c960657]: https://github.com/c960657
[@cofyc]: https://github.com/cofyc
[@croaky]: https://github.com/croaky
[@csmuc]: https://github.com/csmuc
[@domitian]: https://github.com/domitian
[@eitoball]: https://github.com/eitoball
[@eric88]: https://github.com/eric88
[@evgenyrahman]: https://github.com/evgenyrahman
[@guiocavalcanti]: https://github.com/guiocavalcanti
[@klausmeyer]: https://github.com/klausmeyer
[@laserlemon]: https://github.com/laserlemon
[@michalczapko]: https://github.com/michalczapko
[@MSch]: https://github.com/MSch
[@mvastola]: https://github.com/mvastola
[@p8]: https://github.com/p8
[@pixeltrix]: https://github.com/pixeltrix
[@racerpeter]: https://github.com/racerpeter
[@rvasquez-flip4new]: https://github.com/rvasquez-flip4new
[@rwz]: https://github.com/rwz
[@scosman]: https://github.com/scosman
[@sferik]: https://github.com/sferik
[@shiroginne]: https://github.com/shiroginne
[@stestaub]: https://github.com/stestaub
[@stevenharman]: https://github.com/stevenharman
[@superchris]: https://github.com/superchris
[@taketo1113]: https://github.com/taketo1113
[@tmikoss]: https://github.com/tmikoss
