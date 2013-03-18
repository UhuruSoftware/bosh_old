require "rspec"
require "rspec/core/rake_task"

namespace :spec do
  desc "Run BOSH integration tests against a local sandbox"
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = "spec/integration/**/*_spec.rb"
    t.rspec_opts = %w(--format documentation --color)
  end

  desc "Run unit and functional tests for each BOSH component gem"
  task :unit do
    builds = Dir['*'].select {|f| File.directory?(f) && File.exists?("#{f}/spec")}
    builds -= ['bat']

    builds.each do |build|
      puts "-----#{build}-----"
      system("cd #{build} && bundle exec rspec spec") || raise("#{build} failed to build unit tests")
    end
  end

  namespace :external do
    desc "AWS CPI can exercise the VM lifecycle"
    RSpec::Core::RakeTask.new(:vm_lifecycle) do |t|
      t.pattern = "spec/external/cpi_spec.rb"
      t.rspec_opts = %w(--format documentation --color)
    end

    desc "AWS bootstrap CLI can provision and destroy resources"
    RSpec::Core::RakeTask.new(:aws_bootstrap) do |t|
      t.pattern = "spec/external/aws_bootstrap_spec.rb"
      t.rspec_opts = %w(--format documentation --color)
    end
  end

  namespace :system do
    namespace :aws do
      desc "Run AWS MicroBOSH deployment suite"
      RSpec::Core::RakeTask.new(:micro) do |t|
        t.pattern = "spec/system/aws/**/*_spec.rb"
        t.rspec_opts = %w(--format documentation --color --tag ~cf --tag ~full)
      end

      desc "Run AWS CF deployment suite"
      RSpec::Core::RakeTask.new(:cf) do |t|
        t.pattern = "spec/system/aws/**/*_spec.rb"
        t.rspec_opts = %w(--format documentation --color --tag cf)
      end
    end

    desc "Run AWS system-wide suite"
    RSpec::Core::RakeTask.new(:aws) do |t|
      t.pattern = "spec/system/aws/**/*_spec.rb"
      t.rspec_opts = %w(--format documentation --color)
    end
  end
end

desc "Run unit and integration specs"
task :spec => ["spec:unit", "spec:integration"]
