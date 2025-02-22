# frozen_string_literal: true

require_relative "lib/rails_model_viz/version"

Gem::Specification.new do |spec|
  spec.name = "rails_model_viz"
  spec.version = RailsModelViz::VERSION
  spec.authors = ["Peter Takahashi", "Seiya Takahashi"]
  spec.email = ["seiya4@icloud.com"]

  spec.summary       = "A Rails engine that visualizes your ActiveRecord models and associations using Mermaid.js."
  spec.description   = <<~DESC
    **Rails Model Viz** is a development tool that automatically visualizes your Rails application's models, 
    associations, and (optionally) column details using Mermaid.js. This gem provides both a command-line task 
    and a Rails Engine interface, allowing you to view interactive entity-relationship diagrams (ER diagrams) 
    directly in your browser. It helps developers quickly understand, explore, and document the structure of 
    their ActiveRecord models.
  DESC
  spec.homepage      = "https://github.com/PeterTakahashi/rails_model_viz"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = 'https://github.com/PeterTakahashi/rails_model_viz/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib", "app"]
end
