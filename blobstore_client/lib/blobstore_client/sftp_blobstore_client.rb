require "net/sftp"

module Bosh
  module Blobstore
    class SftpBlobstoreClient < BaseClient

      def initialize(options)
        super(options)
        @endpoint = @options[:endpoint]
        @user = @options[:user]
        @blobstore_path = @options[:blobstore_path]
        @password = @options[:password] || "password"
      end

      def create_file(id, file)
        id ||= generate_object_id
        file_path = "#{@blobstore_path}#{id}"

        begin
          Net::SFTP.start(@endpoint, @user, :password => @password) do |sftp|
            sftp.upload!(file, file_path)

            sftp.stat!(file_path) do |response|
              unless response.ok?
                raise BlobstoreError,
                      "Could not create object, #{file_path}"
              end
            end
          end

          id
        rescue Net::SSH::AuthenticationFailed
          raise BlobstoreError, "Authentication failed"
        end
      end

      def get_file(id, file)
        file_path = "#{@blobstore_path}#{id}"
        begin
          Net::SFTP.start(@endpoint, @user, :password => @password) do |sftp|
            sftp.stat!(file_path) do |response|
              unless response.ok?
                raise BlobstoreError,
                      "Could not fetch object, #{file_path}"
              end
            end

            sftp.file.open(file_path, 'r') do |remote_file|
              data = remote_file.read(1024 * 1024)
              while data.length != 0
                file.write(data)
                data = remote_file.read(1024 * 1024)
              end

            end
          end
        rescue Net::SSH::AuthenticationFailed
          raise BlobstoreError, "Authentication failed"
        end
      end

      def delete_object(id)
        file = "#{@blobstore_path}#{id}"
        begin
          Net::SFTP.start(@endpoint, @user, :password => @password) do |sftp|
            response = sftp.remove!("#{file}")

            unless response.ok?
              raise BlobstoreError, "Could not delete object, #{file}"
            end

          end
        rescue Net::SSH::AuthenticationFailed
          raise BlobstoreError, "Authentication failed"
        end
      end

      def object_exists?(id)
        file = "#{@blobstore_path}#{id}"
        begin
          Net::SFTP.start(@endpoint, @user, :password => @password) do |sftp|
            begin
              sftp.stat!(file) do |response|
                false if response.code == 2
              end
            rescue Net::SFTP::StatusException
              return false
            end
          end

          true
        rescue Net::SSH::AuthenticationFailed
          raise BlobstoreError, "Authentication failed"
        end
      end

    end
  end
end
