# Copyright (c) 2009-2012 VMware, Inc.

require 'base64'
require 'httpclient'

module Bosh
  module Blobstore
    class SimpleBlobstoreClient < BaseClient

      def initialize(options)
        super(options)
        @client = HTTPClient.new
        @endpoint = @options[:endpoint]
        @bucket = @options[:bucket] || 'resources'
        @headers = {}
        user = @options[:user]
        password = @options[:password]
        if user && password
          @headers['Authorization'] = 'Basic ' +
            Base64.encode64("#{user}:#{password}").strip
        end
      end

      def url(id = nil)
        ["#{@endpoint}/#{@bucket}", id].compact.join('/')
      end

      def create_file(id, file)
        response = @client.post(url(id), { content: file }, @headers)
        if response.status != 200
          raise BlobstoreError,
                "Could not create object, #{response.status}/#{response.content}"
        end
        response.content
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
          raise BlobstoreError,
                "Could not fetch object, #{response.status}/#{response.content}"
        end
      end

      def delete_object(id)
        response = @client.delete(url(id), @headers)
        if response.status != 204
          raise BlobstoreError,
                "Could not delete object, #{response.status}/#{response.content}"
        end
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
