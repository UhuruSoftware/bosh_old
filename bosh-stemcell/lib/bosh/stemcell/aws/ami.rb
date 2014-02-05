require 'cloud'
require 'bosh_aws_cpi'
require 'ostruct'
require 'yaml'
require 'rake'
require 'bosh/stemcell/aws/region'

module Bosh::Stemcell::Aws
  class Ami
    attr_reader :stemcell

    def initialize(stemcell, region)
      @stemcell = stemcell
      @region = region
    end

    def publish
      cloud_config = OpenStruct.new(logger: Logger.new('ami.log'), task_checkpoint: nil)
      Bosh::Clouds::Config.configure(cloud_config)

      cloud = Bosh::Clouds::Provider.create('aws', options)

      stemcell.extract do |tmp_dir, stemcell_manifest|
        ami_id = cloud.create_stemcell("#{tmp_dir}/image", stemcell_manifest['cloud_properties'])
        cloud.ec2.images[ami_id].public = true
        ami_id
      end
    end

    private

    attr_reader :region

    def options
      # just fake the registry struct, as we don't use it
      {
        'aws' => aws,
        'registry' => {
          'endpoint' => 'http://fake.registry',
          'user' => 'fake',
          'password' => 'fake'
        }
      }
    end

    def aws
      access_key_id = ENV['BOSH_AWS_ACCESS_KEY_ID']
      secret_access_key = ENV['BOSH_AWS_SECRET_ACCESS_KEY']

      {
        'default_key_name' => 'fake',
        'region' => region.name,
        'access_key_id' => access_key_id,
        'secret_access_key' => secret_access_key
      }
    end
  end
end
