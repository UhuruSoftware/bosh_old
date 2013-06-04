require 'spec_helper'

describe Bosh::Blobstore::AzureBlobstoreClient do
  def azure_storage_account_name
    v = ENV['STORAGE_ACCOUNT_NAME']
    raise "Missing STORAGE_ACCOUNT_NAME environment variable." unless v
    v
  end

  def azure_storage_access_key
    v = ENV['STORAGE_ACCESS_KEY']
    rause "Missing STORAGE_ACCESS_KEY environment variable." unless v
    v
  end

  def container_name
    @container_name
    end

  before(:all) do
    Azure.config.storage_account_name = azure_storage_account_name
    Azure.config.storage_access_key = azure_storage_access_key

    @azure_blob_service = Azure::BlobService.new
    @container_name = "test-container-%08x" % rand(2**23)

    container = @azure_blob_service.create_container(@container_name )
    #@azure_blob_service.get_container_properties(@container_name)
  end

  after (:all) do
    @azure_blob_service.delete_container(@container_name)
  end

  let(:azure_options) do
    {
       :storage_account_name => azure_storage_account_name,
       :storage_access_key => azure_storage_access_key,
       :container_name => @container_name
    }
  end

  let(:azure) do
    Bosh::Blobstore::Client.create("azure", azure_options)
  end

  describe("store object") do
    it "should upload a string" do
      @oid = azure.create("foobar")
      @oid.should_not be_nil
    end
  end


end