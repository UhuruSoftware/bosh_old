require 'bosh/dev/aws'
require 'bosh/dev/aws/receipts'
require 'bosh_cli_plugin_aws/microbosh_manifest'

module Bosh::Dev::Aws
  class MicroBoshDeploymentManifest
    def initialize(env)
      @receipts = Receipts.new(env)
    end

    def access_key_id
      manifest.access_key_id
    end

    def secret_access_key
      manifest.secret_access_key
    end

    def director_name
      "micro-#{manifest.name}"
    end

    def write
      File.write(manifest.file_name, manifest.to_yaml)
    end

    private

    attr_reader :receipts

    def manifest
      @manifest ||= Bosh::Aws::MicroboshManifest.new(
        YAML.load_file(receipts.vpc_outfile_path),
        YAML.load_file(receipts.route53_outfile_path),
        hm_director_user: 'admin',
        hm_director_password: 'admin'
      )
    end
  end
end
