require 'spec_helper'

describe Bosh::Blobstore::SimpleBlobstoreClient do

  let(:response) { mock(HTTP::Message) }
  let(:httpclient) { mock(HTTPClient) }

  before(:each) do
    HTTPClient.stub(:new).and_return(httpclient)
  end

  describe 'options' do

    it 'should set up authentication when present' do
      response.stub(status: 200, content: 'content_id')

      httpclient.should_receive(:get).with('http://localhost/resources/foo', {},
                                           {'Authorization' => 'Basic am9objpzbWl0aA=='}).and_return(response)
      client = Bosh::Blobstore::SimpleBlobstoreClient.new({'endpoint' => 'http://localhost',
                                                           'user' => 'john',
                                                           'password' => 'smith'})
      client.get('foo')
    end

  end

  describe 'operations' do
    let(:client) { Bosh::Blobstore::SimpleBlobstoreClient.new('endpoint' => 'http://localhost') }

    it 'should create an object' do
      response.stub(status: 200, content: 'content_id')
      httpclient.should_receive(:post) do |*args|
        uri, body, _ = args
        uri.should eql('http://localhost/resources')
        body.should be_kind_of(Hash)
        body[:content].should be_kind_of(File)
        body[:content].read.should eql('some object')
        response
      end

      client.create('some object').should eql('content_id')
    end

    it 'should accept object id suggestion' do
      response.stub(status: 200, content: 'foobar')
      httpclient.should_receive(:post) do |uri, body, _|
        uri.should eql('http://localhost/resources/foobar')
        body.should be_kind_of(Hash)
        body[:content].should be_kind_of(File)
        body[:content].read.should eql('some object')
        response
      end

      client.create('some object', 'foobar').should eql('foobar')
    end

    it 'should raise an exception when there is an error creating an object' do
      response.stub(status: 500, content: nil)

      httpclient.stub(:post => response)

      expect {
        client.create('some object')
      }.to raise_error Bosh::Blobstore::BlobstoreError, /Could not create object/
    end

    it 'should fetch an object' do
      response.stub(status: 200)
      httpclient.should_receive(:get).with('http://localhost/resources/some object', {}, {}).
          and_yield('content_id').
          and_return(response)

      client.get('some object').should eql('content_id')
    end

    it 'should raise an exception when there is an error fetching an object' do
      response.stub(status: 500, content: 'error message')
      httpclient.should_receive(:get).with('http://localhost/resources/some object', {}, {}).and_return(response)

      expect {
        client.get('some object')
      }.to raise_error Bosh::Blobstore::BlobstoreError, /Could not fetch object/
    end

    it 'should delete an object' do
      response.stub(status: 204, content: '')
      httpclient.should_receive(:delete).with('http://localhost/resources/some object', {}).and_return(response)

      client.delete('some object')
    end

    it 'should raise an exception when there is an error deleting an object' do
      response.stub(status: 404, content: '')
      httpclient.should_receive(:delete).with('http://localhost/resources/some object', {}).and_return(response)

      expect {
        client.delete('some object')
      }.to raise_error Bosh::Blobstore::BlobstoreError, /Could not delete object/
    end

    describe '#exists?' do
      it 'should return true for an object that already exists' do
        response.stub(status: 200)

        httpclient.should_receive(:head).with('http://localhost/resources/foobar', {:header => {}}).and_return(response)
        client.exists?('foobar').should be_true
      end

      it 'should return false for an object that does not exist' do
        response.stub(status: 404)

        httpclient.should_receive(:head).with('http://localhost/resources/doesntexist', {:header => {}}).and_return(response)
        client.exists?('doesntexist').should be_false
      end

      it 'should raise a BlobstoreError if response status is neither 200 nor 404' do
        response.stub(status: 500, content: '')

        httpclient.should_receive(:head).with('http://localhost/resources/foobar', {:header => {}}).and_return(response)

        expect {
          client.exists?('foobar')
        }.to raise_error Bosh::Blobstore::BlobstoreError, /Could not get object existence/
      end
    end
  end
end