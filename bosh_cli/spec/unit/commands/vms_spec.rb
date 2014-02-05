require 'spec_helper'
require 'cli'

describe Bosh::Cli::Command::Vms do
  subject(:command) { described_class.new }

  before { command.stub(director: director, logged_in?: true, nl: nil, say: nil) }
  let(:director) { double(Bosh::Cli::Client::Director) }

  describe 'list' do
    before { command.options[:target] = target }
    let(:target) { 'http://example.org' }

    context 'with no arguments' do
      def perform
        command.list
      end

      context 'when there are multiple deployments' do
        before { director.stub(:list_deployments) { [{ 'name' => 'dep1' }, { 'name' => 'dep2' }] } }

        it 'lists vms in all deployments' do
          command.should_receive(:show_deployment).with('dep1', target: target)
          command.should_receive(:show_deployment).with('dep2', target: target)
          perform
        end
      end

      context 'when there no deployments' do
        before { director.stub(:list_deployments) { [] } }

        it 'raises an error' do
          expect { perform }.to raise_error(Bosh::Cli::CliError, 'No deployments')
        end
      end
    end

    context 'with a deployment argument' do
      def perform
        command.list('dep1')
      end

      context 'when deployment with given name can be found' do
        it 'lists vms in the deployment' do
          command.should_receive(:show_deployment).with('dep1', target: target)
          command.list('dep1')
        end
      end
    end
  end

  describe 'show_deployment' do
    def perform
      command.show_deployment(deployment, options)
    end

    let(:deployment) { 'dep1' }
    let(:options)    { {details: false, dns: false, vitals: false} }

    context 'when deployment has vms' do
      before { director.stub(:fetch_vm_state).with(deployment) { [vm_state] } }

      let(:vm_state) {
        {
          'job_name' => 'job1',
          'index' => 0,
          'ips' => %w{192.168.0.1},
          'dns' => %w{index.job.network.deployment.microbosh},
          'vitals' => 'vitals',
          'job_state' => 'awesome',
          'resource_pool' => 'rp1',
          'vm_cid' => 'cid1',
          'agent_id' => 'agent1',
          'vitals' => {
            'load' => [1, 2, 3],
            'cpu' => {
              'user' => 4,
              'sys' => 5,
              'wait' => 6,
            },
            'mem' => {
              'percent' => 7,
              'kb' => 8,
            },
            'swap' => {
              'percent' => 9,
              'kb' => 10,
            },
            'disk' => {
              'system' => {'percent' => 11},
              'ephemeral' => {'percent' => 12},
              'persistent' => {'percent' => 13},
            },
          },
          'resurrection_paused' => true,
        }
      }

      context 'default' do
        it 'show basic vms information' do
          command.should_receive(:say).with("Deployment `#{deployment}'")
          command.should_receive(:say) do |s|
            expect(s.to_s).to include 'job1/0'
            expect(s.to_s).to include 'awesome'
            expect(s.to_s).to include 'rp1'
            expect(s.to_s).to include '192.168.0.1'
          end
          command.should_receive(:say).with('VMs total: 1')
          perform
        end
      end

      context 'with details' do
        before { options[:details] = true }

        it 'shows vm details' do
          command.should_receive(:say).with("Deployment `#{deployment}'")
          command.should_receive(:say) do |s|
            expect(s.to_s).to include 'job1/0'
            expect(s.to_s).to include 'awesome'
            expect(s.to_s).to include 'rp1'
            expect(s.to_s).to include '192.168.0.1'
            expect(s.to_s).to include 'cid1'
            expect(s.to_s).to include 'agent1'
            expect(s.to_s).to include 'paused'
          end
          command.should_receive(:say).with('VMs total: 1')
          perform
        end
      end

      context 'with DNS A records' do
        before { options[:dns] = true }

        it 'shows DNS A records' do
          command.should_receive(:say).with("Deployment `#{deployment}'")
          command.should_receive(:say) do |s|
            expect(s.to_s).to include 'job1/0'
            expect(s.to_s).to include 'awesome'
            expect(s.to_s).to include 'rp1'
            expect(s.to_s).to include '192.168.0.1'
            expect(s.to_s).to include 'index.job.network.deployment.microbosh'
          end
          command.should_receive(:say).with('VMs total: 1')
          perform
        end
      end

      context 'with vitals' do
        before { options[:vitals] = true }

        it 'shows the vm vitals' do
          command.should_receive(:say).with("Deployment `#{deployment}'")
          command.should_receive(:say) do |s|
            expect(s.to_s).to include 'job1/0'
            expect(s.to_s).to include 'awesome'
            expect(s.to_s).to include 'rp1'
            expect(s.to_s).to include '192.168.0.1'
            expect(s.to_s).to include '1%, 2%, 3%'
            expect(s.to_s).to include '4%'
            expect(s.to_s).to include '5%'
            expect(s.to_s).to include '6%'
            expect(s.to_s).to include '7% (8.0K)'
            expect(s.to_s).to include '9% (10.0K)'
            expect(s.to_s).to include '11%'
            expect(s.to_s).to include '12%'
            expect(s.to_s).to include '13%'
          end
          command.should_receive(:say).with('VMs total: 1')
          perform
        end

        it 'shows the vm vitals with unavailable ephemeral and persistent disks' do
          new_vm_state = vm_state
          new_vm_state['vitals']['disk'].delete('ephemeral')
          new_vm_state['vitals']['disk'].delete('persistent')
          director.stub(:fetch_vm_state).with(deployment) { [new_vm_state] }

          command.should_receive(:say).with("Deployment `#{deployment}'")
          command.should_receive(:say) do |s|
            expect(s.to_s).to_not include '12%'
            expect(s.to_s).to_not include '13%'
          end
          command.should_receive(:say).with('VMs total: 1')
          perform
        end
      end
    end

    context 'when deployment has no vms' do
      before { director.stub(:fetch_vm_state).with(deployment) { [] } }

      it 'does not raise an error and says "No VMs"' do
        command.should_receive(:say).with("No VMs")
        expect { perform }.to_not raise_error
      end
    end
  end
end
