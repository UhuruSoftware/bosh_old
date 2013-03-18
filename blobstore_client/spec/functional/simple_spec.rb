require 'spec_helper'
require 'tempfile'
require 'thin'
require 'simple_blobstore_server'
require 'net/http'

describe Bosh::Blobstore::SimpleBlobstoreClient do
  BLOBSTORE_DIR = '/tmp/bosh_test_blobstore'
  before(:all) do
    options = {
        'path' => BLOBSTORE_DIR,
        'users' => {'bs_admin' => 'bs_pass'}
      }

    @server = Thin::Server.new('0.0.0.0', 9590) do
      use Rack::CommonLogger
      map "/" do
        run Bosh::Blobstore::SimpleBlobstoreServer.new(options)
      end
    end
    Thread.start { @server.start }
    tries = 0
    while true
      tries += 1
      req = Net::HTTP.new('localhost', 9590)
      begin
        req.head("/")
        break
      rescue Errno::ECONNREFUSED => e
        raise e if tries >= 20
        sleep(0.1)
      end
    end
  end

  after(:all) do
    @server.stop!
  end

  before do
    FileUtils.mkdir_p(BLOBSTORE_DIR)
  end

  after do
    FileUtils.rm_rf(BLOBSTORE_DIR)
  end

  let(:blob_store_client) { described_class.new({endpoint: "http://localhost:9590", user: 'bs_admin', password:'bs_pass'})}

  it 'not find a non existing object' do
    blob_store_client.exists?("unknown_resource").should be_false
  end

  it 'should find an existing object' do
    blob_id = blob_store_client.create("existing_resource", 'id')
    blob_store_client.exists?(blob_id).should be_true
    blob_store_client.exists?('id').should be_true
  end

  it 'should get an existing object' do
    blob_id = blob_store_client.create("existing_resource", 'id')
    contents = blob_store_client.get(blob_id)
    contents.should == "existing_resource"
    contents = blob_store_client.get('id')
    contents.should == "existing_resource"
  end

  it 'should delete an existing object' do
    blob_id = blob_store_client.create("existing_resource")
    blob_store_client.delete(blob_id)
    blob_store_client.exists?(blob_id).should be_false
  end

end