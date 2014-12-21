# coding: utf-8

Gem::Specification.new do |spec|
  spec.add_dependency "activerecord", [">= 3.0", "< 4.3"]
  spec.add_dependency "delayed_job",  [">= 3.0", "< 4.1"]
  spec.authors        = ["Brian Ryckbost", "Matt Griffin", "Erik Michaels-Ober"]
  spec.description    = "ActiveRecord backend for Delayed::Job, originally authored by Tobias Lütke"
  spec.email          = ["bryckbost@gmail.com", "matt@griffinonline.org", "sferik@gmail.com"]
  spec.files          = %w(CONTRIBUTING.md LICENSE.md README.md delayed_job_active_record.gemspec) + Dir["lib/**/*.rb"]
  spec.homepage       = "http://github.com/collectiveidea/delayed_job_active_record"
  spec.licenses       = ["MIT"]
  spec.name           = "delayed_job_active_record"
  spec.require_paths  = ["lib"]
  spec.summary        = "ActiveRecord backend for DelayedJob"
  spec.version        = "4.0.2-rails420"
end
