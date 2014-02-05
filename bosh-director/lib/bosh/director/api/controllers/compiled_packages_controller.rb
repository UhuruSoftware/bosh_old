require 'json'
require 'tempfile'
require 'bosh/director/api/controllers/base_controller'
require 'bosh/director/api/stemcell_manager'
require 'bosh/director/compiled_package_group'
require 'bosh/director/compiled_packages_exporter'
require 'bosh/director/stale_file_killer'
require 'bosh/director/jobs/import_compiled_packages'

module Bosh::Director
  module Api::Controllers
    class CompiledPackagesController < BaseController
      post '/compiled_package_groups/export', consumes: [:json] do
        stemcell = find_stemcell_by_name_and_version
        release_version = find_release_version_by_name_and_version

        output_dir = File.join(Dir.tmpdir, 'compiled_packages')
        FileUtils.mkdir_p(output_dir)

        killer = StaleFileKiller.new(output_dir)
        killer.kill

        compiled_packages = CompiledPackageGroup.new(release_version, stemcell)
        blobstore_client = App.instance.blobstores.blobstore
        exporter = CompiledPackagesExporter.new(compiled_packages, blobstore_client)

        output_path = File.join(output_dir, "compiled_packages_#{Time.now.to_f}.tar.gz")
        exporter.export(output_path)

        send_file(output_path, type: :tgz)
      end

      post '/compiled_package_groups/import', consumes: [:tgz] do
        tempdir = Dir.mktmpdir
        export_path = File.join(tempdir, 'compiled_packages_export.tgz')
        # the job is responsible for cleaning this up
        File.open(export_path, 'w') do |f|
          while buf = request.body.read(4096)
            f.write(buf)
          end
        end

        task = JobQueue.new.enqueue(@user, Jobs::ImportCompiledPackages, 'import compiled packages', [tempdir])
        redirect "/tasks/#{task.id}"
      end

      def find_stemcell_by_name_and_version
        stemcell_manager = Api::StemcellManager.new
        stemcell_manager.find_by_name_and_version(
          body_params['stemcell_name'], body_params['stemcell_version'])
      end

      def find_release_version_by_name_and_version
        release_manager = Api::ReleaseManager.new
        release = release_manager.find_by_name(body_params['release_name'])
        release_manager.find_version(release, body_params['release_version'])
      end

      def body_params
        @body_params ||= JSON.load(request.body)
      end
    end
  end
end
