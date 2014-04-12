# coding: utf-8

Gem::Specification.new do |spec|
  spec.add_dependency   'activerecord', ['>= 3.0', '< 4.2']
  spec.add_dependency   'delayed_job',  ['>= 3.0', '< 4.1']
  spec.authors        = ["Brian Ryckbost", "Matt Griffin", "Erik Michaels-Ober"]
  spec.description    = 'ActiveRecord backend for Delayed::Job, originally authored by Tobias Lütke'
  spec.email          = ['bryckbost@gmail.com', 'matt@griffinonline.org', 'sferik@gmail.com']
  spec.files          = %w(CONTRIBUTING.md LICENSE.md README.md Rakefile delayed_job_active_record.gemspec)
  spec.files         += Dir.glob("lib/**/*.rb")
  spec.files         += Dir.glob("spec/**/*")
  spec.homepage       = 'http://github.com/collectiveidea/delayed_job_active_record'
  spec.licenses       = ['MIT']
  spec.name           = 'delayed_job_active_record'
  spec.require_paths  = ['lib']
  spec.summary        = 'ActiveRecord backend for DelayedJob'
  spec.test_files     = Dir.glob("spec/**/*")
  spec.version        = '4.0.1'
end
