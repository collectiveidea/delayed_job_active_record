# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = "delayed_job_active_record"
  spec.version     = "4.1.11"
  spec.summary     = "ActiveRecord backend for DelayedJob"
  spec.description = "ActiveRecord backend for Delayed::Job, originally authored by Tobias Lütke"

  spec.licenses = "MIT"

  spec.authors  = ["David Genord II", "Brian Ryckbost", "Matt Griffin", "Erik Michaels-Ober"]
  spec.email    = ["david@collectiveidea.com", "bryckbost@gmail.com", "matt@griffinonline.org", "sferik@gmail.com"]
  spec.homepage = "http://github.com/collectiveidea/delayed_job_active_record"

  spec.files         = %w[CONTRIBUTING.md LICENSE.md README.md delayed_job_active_record.gemspec] + Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.metadata = { "rubygems_mfa_required" => "true" }

  spec.add_dependency "activerecord", [">= 3.0", "< 9.0"]
  spec.add_dependency "delayed_job",  [">= 3.0", "< 5"]
end
