require 'spec_helper'
require 'bosh/stemcell/disk_image'

module Bosh::Stemcell
  describe DiskImage do
    let(:shell) { instance_double('Bosh::Core::Shell', run: nil) }

    let(:kpartx_map_output) { 'add map FAKE_LOOP1p1 (252:3): 0 3997984 linear /dev/loop1 63' }
    let(:options) do
      {
        image_file_path: '/path/to/FAKE_IMAGE',
        image_mount_point: '/fake/mnt'
      }
    end

    subject(:disk_image) { DiskImage.new(options) }

    before do
      Bosh::Core::Shell.stub(:new).and_return(shell)
    end

    describe '#initialize' do
      it 'requires an image_file_path' do
        options.delete(:image_file_path)
        expect { DiskImage.new(options) }.to raise_error /key not found: :image_file_path/
      end

      it 'requires an mount_point' do
        options.delete(:image_mount_point)

        dir_mock = class_double('Dir').as_stubbed_const
        dir_mock.should_receive(:mktmpdir).and_return('/fake/tmpdir')

        expect(DiskImage.new(options).image_mount_point).to eq('/fake/tmpdir')
      end
    end

    describe '#mount' do
      it 'maps the file to a loop device' do
        losetup_commad = 'sudo losetup --show --find /path/to/FAKE_IMAGE'
        shell.stub(:run).with(losetup_commad, output_command: false).and_return('/dev/loop0')
        shell.should_receive(:run).with('sudo kpartx -av /dev/loop0',
                                        output_command: false).and_return(kpartx_map_output)

        disk_image.mount
      end

      it 'mounts the loop device' do
        losetup_commad = 'sudo losetup --show --find /path/to/FAKE_IMAGE'
        shell.stub(:run).with(losetup_commad, output_command: false).and_return('/dev/loop0')
        shell.stub(:run).with('sudo kpartx -av /dev/loop0', output_command: false).and_return(kpartx_map_output)

        shell.should_receive(:run).with('sudo mount /dev/mapper/FAKE_LOOP1p1 /fake/mnt', output_command: false)

        disk_image.mount
      end

      context 'when the device does not exist' do
        let(:mount_command) do
          'sudo mount /dev/mapper/FAKE_LOOP1p1 /fake/mnt'
        end

        let(:mount_error) do
          "Failed: '#{mount_command}' from /fake/mnt/blah/blah/bosh-stemcell, with exit status 8192\n\n"
        end

        before do
          disk_image.stub(:sleep)
        end

        it 'runs mount a second time after sleeping long enough for the device node to be created' do
          losetup_commad = 'sudo losetup --show --find /path/to/FAKE_IMAGE'
          shell.stub(:run).with(losetup_commad, output_command: false).and_return('/dev/loop0')
          shell.stub(:run).with('sudo kpartx -av /dev/loop0', output_command: false).and_return(kpartx_map_output)
          shell.should_receive(:run).with(mount_command, output_command: false).ordered.and_raise(mount_error)
          disk_image.should_receive(:sleep).with(0.5)
          shell.should_receive(:run).with(mount_command, output_command: false).ordered

          disk_image.mount
        end

        context 'when the second mount command fails' do
          it 'raises an error' do
            losetup_commad = 'sudo losetup --show --find /path/to/FAKE_IMAGE'
            shell.stub(:run).with(losetup_commad, output_command: false).and_return('/dev/loop0')
            shell.stub(:run).with('sudo kpartx -av /dev/loop0', output_command: false).and_return(kpartx_map_output)
            shell.should_receive(:run).with(mount_command, output_command: false).ordered.twice.and_raise(mount_error)

            expect { disk_image.mount }.to raise_error(mount_error)
          end
        end
      end

      context 'when the mount command fails' do
        it 'runs mount a second time' do
          losetup_commad = 'sudo losetup --show --find /path/to/FAKE_IMAGE'
          shell.stub(:run).with(losetup_commad, output_command: false).and_return('/dev/loop0')
          shell.stub(:run).with('sudo kpartx -av /dev/loop0', output_command: false).and_return(kpartx_map_output)
          shell.should_receive(:run).
            with('sudo mount /dev/mapper/FAKE_LOOP1p1 /fake/mnt', output_command: false).ordered.
            and_raise(RuntimeError, 'UNEXEPECTED')

          expect { disk_image.mount }.to raise_error(RuntimeError, 'UNEXEPECTED')
        end
      end
    end

    describe '#unmount' do
      before do
        disk_image.stub(device: '/dev/loop0') # pretend we've mounted
      end

      it 'unmounts the loop device and then unmaps the file' do
        shell.should_receive(:run).with('sudo umount /fake/mnt', output_command: false).ordered
        shell.should_receive(:run).with('sudo kpartx -dv /dev/loop0', output_command: false).ordered
        shell.should_receive(:run).with('sudo losetup -dv /dev/loop0', output_command: false).ordered

        disk_image.unmount
      end

      it 'unmaps the file even if unmounting the device fails' do
        shell.should_receive(:run).with('sudo umount /fake/mnt', output_command: false).and_raise
        shell.should_receive(:run).with('sudo kpartx -dv /dev/loop0', output_command: false).ordered
        shell.should_receive(:run).with('sudo losetup -dv /dev/loop0', output_command: false).ordered

        expect { disk_image.unmount }.to raise_error
      end
    end

    describe '#while_mounted' do
      it 'mounts the disk, calls the provided block, and unmounts' do
        fake_thing = double('FakeThing')
        losetup_commad = 'sudo losetup --show --find /path/to/FAKE_IMAGE'
        shell.stub(:run).with(losetup_commad, output_command: false).and_return('/dev/loop0')
        shell.stub(:run).with('sudo kpartx -av /dev/loop0', output_command: false).and_return(kpartx_map_output)
        shell.should_receive(:run).with('sudo mount /dev/mapper/FAKE_LOOP1p1 /fake/mnt', output_command: false)
        fake_thing.should_receive(:fake_call).with(disk_image).ordered
        shell.should_receive(:run).with('sudo umount /fake/mnt', output_command: false).ordered
        shell.should_receive(:run).with('sudo kpartx -dv /dev/loop0', output_command: false).ordered
        shell.should_receive(:run).with('sudo losetup -dv /dev/loop0', output_command: false).ordered

        disk_image.while_mounted do |image|
          fake_thing.fake_call(image)
        end
      end

      context 'when the block raises and error' do
        it 'mounts the disk, calls the provided block, and unmounts' do
          losetup_commad = 'sudo losetup --show --find /path/to/FAKE_IMAGE'
          shell.stub(:run).with(losetup_commad, output_command: false).and_return('/dev/loop0')
          shell.stub(:run).with('sudo kpartx -av /dev/loop0', output_command: false).and_return(kpartx_map_output)
          shell.should_receive(:run).with('sudo mount /dev/mapper/FAKE_LOOP1p1 /fake/mnt', output_command: false)

          shell.should_receive(:run).with('sudo umount /fake/mnt', output_command: false).ordered
          shell.should_receive(:run).with('sudo kpartx -dv /dev/loop0', output_command: false).ordered
          shell.should_receive(:run).with('sudo losetup -dv /dev/loop0', output_command: false).ordered

          expect { disk_image.while_mounted { |_| raise } }.to raise_error
        end
      end
    end
  end
end
