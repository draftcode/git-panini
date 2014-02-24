require 'spec_helper'
require 'tmpdir'

module Git
  module Panini
    describe RealRepository do
      describe '#panini_name' do
        context 'with a non-bare repository' do
          subject { described_class.new(Pathname('/tmp/A')) }

          it 'constructs the name from the path' do
            expect(subject.panini_name).to eq('panini:A')
          end
        end

        context 'with a bare repository' do
          subject { described_class.new(Pathname('/tmp/A.git')) }

          it 'constructs the name from the path' do
            expect(subject.panini_name).to eq('panini:A')
          end
        end
      end
    end

    describe SharedRepositoryFactory do
      let(:syncbase) { Pathname(Dir.mktmpdir) }
      after { FileUtils.remove_entry_secure(syncbase.to_s) }

      def create_fake_repo(name)
        (syncbase + (name + '.git')).mkdir
      end

      describe '.discover' do
        before { create_fake_repo('A') }

        it 'returns a repository' do
          expect(described_class.discover(syncbase)).to eq([
            SharedRepository.new(syncbase + 'A.git'),
          ])
        end
      end
    end
  end
end
