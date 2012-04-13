# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name              = 'delayed_job_active_record'
  s.version           = '0.3.2'
  s.authors           = ["Brian Ryckbost", "Matt Griffin", "Erik Michaels-Ober"]
  s.summary           = 'ActiveRecord backend for DelayedJob'
  s.description       = 'ActiveRecord backend for DelayedJob, originally authored by Tobias Luetke'
  s.email             = ['bryckbost@gmail.com', 'matt@griffinonline.org', 'sferik@gmail.com']
  s.extra_rdoc_files  = 'README.md'
  s.files             = Dir.glob('{contrib,lib,recipes,spec}/**/*') +
                        %w(LICENSE README.md)
  s.homepage          = 'http://github.com/collectiveidea/delayed_job_active_record'
  s.rdoc_options      = ["--main", "README.md", "--inline-source", "--line-numbers"]
  s.require_paths     = ["lib"]
  s.test_files        = Dir.glob('spec/**/*')

  s.add_runtime_dependency     'activerecord', ['>= 2.1.0', '< 4']
  s.add_runtime_dependency     'delayed_job',  '~> 3.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3'
end
