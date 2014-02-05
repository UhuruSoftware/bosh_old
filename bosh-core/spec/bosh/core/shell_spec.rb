require 'spec_helper'
require 'bosh/core/shell'

module Bosh::Core
  describe Shell do
    let(:stdout) { StringIO.new }

    subject do
      Shell.new(stdout)
    end

    describe '#run' do
      it 'shells out, prints and returns the output of the command' do
        expect(subject.run('echo hello; echo world')).to eq("hello\nworld")
        expect(stdout.string).to eq("hello\nworld\n")
      end

      context 'when "output_command" is specified' do
        it 'outputs the command' do
          cmd = 'echo 1;echo 2;echo 3;echo 4;echo 5'
          subject.run(cmd, output_command: true)

          expect(stdout.string).to include('echo 1;echo 2;echo 3;echo 4;echo 5')
        end
      end

      context 'when "last_number" is specified' do
        it 'tails "last_number" lines of output' do
          cmd = 'echo 1;echo 2;echo 3;echo 4;echo 5'
          expect(subject.run(cmd, last_number: 3)).to eq("3\n4\n5")
          expect(stdout.string).to eq("1\n2\n3\n4\n5\n")
        end

        it 'outputs the entire output if more lines are requested than generated' do
          cmd = 'echo 1;echo 2;echo 3;echo 4;echo 5'
          expect(subject.run(cmd, last_number: 6)).to eq("1\n2\n3\n4\n5")
          expect(stdout.string).to eq("1\n2\n3\n4\n5\n")
        end
      end

      context 'when the command fails' do
        it 'raises an error' do
          expect {
            subject.run('false')
          }.to raise_error /Failed: 'false' from /
        end

        context 'because the working directory has gone missing' do
          it 'fails gracefully with a slightly helpful error message' do
            Dir.stub(:pwd).and_raise(Errno::ENOENT, 'No such file or directory - getcwd')
            expect {
              subject.run('false')
            }.to raise_error /from a deleted directory/
          end
        end

        context 'and ignoring failures' do
          it 'raises an error' do
            subject.run('false', ignore_failures: true)
            expect(stdout.string).to match(/continuing anyway/)
          end
        end
      end
    end
  end
end
