# coding: utf-8
require File.expand_path('../lib/bosh_cli_plugin_aws/version', __FILE__)

version = Bosh::Aws::VERSION

Gem::Specification.new do |s|
  s.name        = 'bosh_cli_plugin_aws'
  s.version     = version
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'BOSH plugin to easily create and delete an AWS VPC'
  s.description = "BOSH plugin to easily create and delete an AWS VPC\n#{`git rev-parse HEAD`[0, 6]}"
  s.author      = 'VMware'
  s.homepage    = 'https://github.com/cloudfoundry/bosh'
  s.license     = 'Apache 2.0'
  s.email       = 'support@cloudfoundry.com'
  s.required_ruby_version = Gem::Requirement.new('>= 1.9.3')

  s.files         = `git ls-files -- lib/* templates/* migrations/*`.split($/)
  s.require_paths = ['lib', 'migrations']

  s.add_dependency 'bosh_cli',              "~>#{version}"
  s.add_dependency 'bosh_aws_cpi',          "~>#{version}"
  s.add_dependency 'bosh_cli_plugin_micro', "~>#{version}"
  s.add_dependency 'bosh-stemcell',         "~>#{version}"

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-its'
end
