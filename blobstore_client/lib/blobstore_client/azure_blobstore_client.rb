# Copyright (c) 2013 Uhuru Software, Inc.

require "azure"

module Bosh
  module Blobstore
    class AzureBlobstoreClient < BaseClient

      CHUNCK_SIZE = 1024 * 128

      attr_reader :storage_account_name, :storage_access_key, :container_name

      # Blobstore client for Azure Block Blobs
      def initialize(options)
        super(options)
 
        @storage_account_name = @options[:storage_account_name]
        @storage_access_key = @options[:storage_access_key]
        @container_name = @options[:container_name]
      
        Azure.config.storage_account_name = @storage_account_name 
        Azure.config.storage_access_key = @storage_access_key 
        @azure_blob_client = Azure::BlobService.new

      end

      # Create a Azure block blob from a file
      def create_file(object_id, file)
        object_id ||= generate_object_id

        blocks = []
        block_index = 0

        while true
          break if file.eof?
          chunck = file.read(CHUNCK_SIZE)

          # "...all block IDs must be the same length." http://msdn.microsoft.com/en-us/library/windowsazure/dd135726.aspx
          block_id = "%010d" % block_index

          @azure_blob_client.create_blob_block(@container_name, object_id, block_id, chunck)
          blocks << [block_id, :uncommited]

          block_index += 1
        end

        # Create the blob from the previous uploaded chuncked blocks
        blob = @azure_blob_client.commit_blob_blocks(@container_name, object_id, blocks)

        #content = file.read
        #blob = @azure_blob_client.create_block_blob(@container_name, object_id, content)

        object_id
      rescue Azure::Core::Error => e
        raise BlobstoreError, "Failed to create object '#{object_id}': #{e.inspect}"
      end
      
      # Download a Azure block blob to a file
      def get_file(object_id, file)
        blob = @azure_blob_client.get_blob_properties(@container_name, object_id)
        total_len = blob.properties[:content_length]
        cur_len = 0

        while cur_len < total_len
          blob, content = @azure_blob_client.get_blob(
            @container_name, 
            object_id, 
            {:start_range => cur_len, :end_range => (cur_len + CHUNCK_SIZE - 1)} )
          cur_len += content.length
          file.write(content)
        end

        #blob, content = @azure_blob_client.get_blob(@container_name, object_id)
        #file.write(content)
      end
      
      # Delete a Azure block blob
      def delete_object(object_id)
        @azure_blob_client.delete_blob(@container_name, object_id)
      rescue Azure::Core::Error => e
        raise BlobstoreError, "Failed to delete object '#{object_id}: #{e.message}'"
      end
     
      # Check if the Azure block blob exists
      def object_exists?(object_id)
        @azure_blob_client.get_blob_properties(@container_name, object_id)
        true
      rescue Azure::Core::Error => e
        false
      end
      
    end
  end
end
