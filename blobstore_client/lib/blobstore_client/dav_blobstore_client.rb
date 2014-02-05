# Copyright (c) 2009-2012 VMware, Inc.

require 'base64'
require 'httpclient'
require 'digest/sha1'

module Bosh
  module Blobstore
    class DavBlobstoreClient < BaseClient

      def initialize(options)
        super(options)
        @client = HTTPClient.new

        if @options[:ssl_no_verify]
          @client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        @endpoint = @options[:endpoint]

        #@bucket = @options[:bucket] || "resources" # dav (or simple) doesn't support buckets
        @headers = {'Translate' => 'f'}

        user = @options[:user]
        password = @options[:password]

        @client.connect_timeout = @options[:connect_timeout] if @options[:connect_timeout]
        @client.send_timeout = @options[:send_timeout] if @options[:send_timeout]
        @client.receive_timeout = @options[:receive_timeout] if @options[:receive_timeout]
        @client.keep_alive_timeout = @options[:keep_alive_timeout] if @options[:keep_alive_timeout]

        if user && password
          @headers['Authorization'] = 'Basic ' +
            Base64.encode64("#{user}:#{password}").strip
        end
      end

      def url(id)
        prefix = Digest::SHA1.hexdigest(id)[0, 2]

        [@endpoint, prefix, id].compact.join('/')
      end

      def create_file(id, file)
        id ||= generate_object_id

        response = @client.put(url(id), file, @headers)

        raise BlobstoreError, "Could not create object, #{response.status}/#{response.content}" if response.status != 201

        id
      end

      def get_file(id, file)
        # Continue to download the data from the current position of the file,
        # This will enable resumable downloads.
        start_offset = file.size
        headers = @headers.clone
        headers["Range"] = "bytes=#{start_offset}-" unless start_offset == 0

        response = @client.get(url(id), {}, headers) do |block|
          file.write(block)
        end

        unless [200, 206].include? response.status
          raise BlobstoreError, "Could not fetch object, #{response.status}/#{response.content}"
        end

      end

      def delete_object(id)
        response = @client.delete(url(id), @headers)

        raise BlobstoreError, "Could not delete object, #{response.status}/#{response.content}" if response.status != 204
      end

      def object_exists?(id)
        response = @client.head(url(id), header: @headers)
        if response.status == 200
          true
        elsif response.status == 404
          false
        else
          raise BlobstoreError, "Could not get object existence, #{response.status}/#{response.content}"
        end
      end
    end
  end
end
