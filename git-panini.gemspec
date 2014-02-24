# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git/panini/version'

Gem::Specification.new do |spec|
  spec.name          = "git-panini"
  spec.version       = Git::Panini::VERSION
  spec.authors       = ["draftcode"]
  spec.email         = ["draftcode@gmail.com"]
  spec.description   = "Fetch from Dropbox repository"
  spec.summary       = "Fetch from Dropbox repository"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_dependency "rugged"
  spec.add_dependency "thor"
end
