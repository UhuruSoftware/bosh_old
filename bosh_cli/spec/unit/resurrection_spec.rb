require 'spec_helper'

module Bosh::Cli
  describe Resurrection do
    subject(:resurrection) { Resurrection.new(state) }

    share_examples_for 'enabled resurrection' do
      it { should be_enabled }
      it { should_not be_disabled }
      it { should_not be_paused }
    end

    share_examples_for 'disabled resurrection' do
      it { should_not be_enabled }
      it { should be_disabled }
      it { should be_paused }
    end

    context 'when its state is "on"', shared: true do
      let(:state) { 'on' }

      include_examples 'enabled resurrection'
    end

    context 'when its state is "off"', shared: true do
      let(:state) { 'off' }

      include_examples 'disabled resurrection'
    end

    context 'when its state is "true"' do
      let(:state) { 'true' }

      include_examples 'enabled resurrection'
    end

    context 'when its state is "false"' do
      let(:state) { 'false' }

      include_examples 'disabled resurrection'
    end

    context 'when its state is "yes"' do
      let(:state) { 'yes' }

      include_examples 'enabled resurrection'
    end

    context 'when its state is "no"' do
      let(:state) { 'no' }

      include_examples 'disabled resurrection'
    end

    context 'when its state is "enable"' do
      let(:state) { 'enable' }

      include_examples 'enabled resurrection'
    end

    context 'when its state is "disable"' do
      let(:state) { 'disable' }

      include_examples 'disabled resurrection'
    end

    context 'when its state is invalid' do
      let(:state) { 'foobar' }

      it 'blows up' do
        expect {
          resurrection
        }.to raise_error /Resurrection paused state should be/
      end
    end
  end
end
