namespace :git do
  task :pull do
    require 'bosh/dev/shipit_lifecycle'
    Bosh::Dev::ShipitLifecycle.new.pull
  end

  task :push do
    require 'bosh/dev/shipit_lifecycle'
    Bosh::Dev::ShipitLifecycle.new.push
  end

  desc 'Git promote a branch to another'
  task :promote_branch, [:dev_branch, :stable_branch] do |_, args|
    require 'logger'
    require 'bosh/dev/git_promoter'
    promoter = Bosh::Dev::GitPromoter.new(Logger.new(STDERR))
    promoter.promote(args.dev_branch, args.stable_branch)
  end

  desc 'Git tag a sha with a build number'
  task :tag_and_push, [:sha, :build_number] do |_, args|
    require 'logger'
    require 'bosh/dev/git_tagger'
    tagger = Bosh::Dev::GitTagger.new(Logger.new(STDERR))
    tagger.tag_and_push(args.sha, args.build_number)
  end
end
