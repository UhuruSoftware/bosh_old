module Bosh
end

require 'logger'

require 'redis'
require "yajl"
require 'uuidtools'

require "agent/version"
require "agent/config"
require "agent/message/configure"
require "agent/handler"

module Bosh::Agent

  class << self
    def run(options = {})
      Runner.new(options).start
    end
  end

  class Runner < Struct.new(:config, :pubsub_redis, :redis)

    def initialize(options)
      self.config = Bosh::Agent::Config.setup(options)
    end

    def start
      $stdout.sync = true
      if Config.configure
        Bosh::Agent::Message::Configure.process(nil)
      end
      Bosh::Agent::Handler.start
    end
  end

end

if __FILE__ == $0
  options = {
    "configure" => true,
    "logging" => { "level" => "DEBUG" },
    "redis" => { "host" => "localhost" }
  }
  Bosh::Agent.run(options)
end
