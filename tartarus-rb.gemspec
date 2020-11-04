require_relative 'lib/tartarus/rb/version'

Gem::Specification.new do |spec|
  spec.name          = "tartarus-rb"
  spec.version       = Tartarus::Rb::VERSION
  spec.authors       = ["Karol Galanciak"]
  spec.email         = ["karol.galanciak@gmail.com"]

  spec.summary       = %q{A gem for archving (deleting) old records you no longer need. Send them straight to tartarus!}
  spec.description   = %q{A gem for archving (deleting) old records you no longer need. Send them straight to tartarus!}
  spec.homepage      = "https://github.com/BookingSync/tartarus-rb"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", ">= 5"
  spec.add_dependency "sidekiq-cron", "~> 1"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-sidekiq"

  spec.add_development_dependency "activerecord", "~> 6"
  spec.add_development_dependency "sqlite3"
end
