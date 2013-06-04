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

  let (:content) { "foobar" }

  after(:each) do
    azure.delete(@oid) if @oid
    azure.delete(@oid2) if @oid2
  end

  describe "Store object" do
    it "should upload a string" do
      @oid = azure.create("foobar")
      @oid.should_not be_nil
    end

    it "should create a object with specified id" do
      @oid = azure.create("foobar", "obecjt-id-1")
      @oid.should eq "obecjt-id-1"
    end

    it "should upload a file" do
      Tempfile.new("bar") do |file|
        @oid = azure.create(file)
        @oid.should_not be_nil
      end
    end

    it "should handle uploading the same object twice" do
      @oid = azure.create("bar")
      @oid.should_not be_nil
      @oid2 = azure.create("foobar")
      @oid2.should_not be_nil
      @oid.should_not eq @oid2
    end
  end

  describe "Get object" do

    it "should save to a file" do
      @oid = azure.create(content)
      file = Tempfile.new("contents")
      azure.get(@oid, file)
      file.rewind
      file.read.should eq content
    end

    it "should return the contents" do
      @oid = azure.create(content)
      azure.get(@oid).should eq content
    end

    it "should raise an exception if the object id is invalid" do
      expect {
        azure.get("notpresent")
      }.to raise_error Bosh::Blobstore::BlobstoreError
    end

  end

  describe "Delete object" do
    it "should delete object" do
      @oid = azure.create(content)
      azure.delete(@oid)
      @oid = nil
    end

    it "should raise an exception if the object id is invalid" do
      expect {
        azure.delete("notpresent")
      }.to raise_error Bosh::Blobstore::BlobstoreError
    end

  end

  context "Big objects" do
    let(:file_content_100mib) do
      file = Tempfile.new("content_100mb")
      (1024 * 1024 * 1).times do |i|
        file.write("x" * 100)
      end
      file.rewind
      file
    end

    it "should upload a big file" do
      @oid = azure.create(file_content_100mib)
      @oid.should_not be_nil
    end

    it "should download a big file" do
      @oid = azure.create(file_content_100mib)
      Tempfile.new("downloaded_content") do |file|
        azure.get(@oid, file)
        file.rewind
        (1024 * 1024 * 1).times do
          file.read(100).should eq ("x" * 100)
          puts @oid
        end
      end

    end

  end

end