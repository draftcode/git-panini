require 'spec_helper'
require 'tmpdir'

module Git
  module Panini
    describe PaniniRepositoryFactory do
      let(:syncbase) { Pathname(Dir.mktmpdir) }
      let(:config_path) { syncbase + "panini-info" }
      after { FileUtils.remove_entry_secure(syncbase.to_s) }

      let(:local_repository) { LocalRepository.new(Pathname("/tmp/A")) }
      let(:shared_repository) { SharedRepository.new(Pathname("/tmp/shared/A.git")) }

      describe '.construct' do
        context 'without a config file' do
          it 'constructs a panini repository' do
            expect(described_class.construct([local_repository], [shared_repository], config_path)).to eq(
              PaniniRepositories.new(
                'panini:A' => PaniniRepository.new('panini:A', {}, local_repository, shared_repository),
              )
            )
          end
        end

        context 'with a config file' do
          before do
            config_path.open('w') do |f|
              f.write(<<EOT
---
repositories:
  - name: 'panini:A'
    remotes:
      origin: 'git@github.com:example/A.git'
  - name: 'panini:B'
    remotes:
      origin: 'git@github.com:example/B.git'
EOT
                      )
            end
          end

          let(:expect_remote_A) { {'origin' => Remote.new_from_url('origin', 'git@github.com:example/A.git')} }
          let(:expect_remote_B) { {'origin' => Remote.new_from_url('origin', 'git@github.com:example/B.git')} }
          it 'constructs two panini repository' do
            expect(described_class.construct([local_repository], [shared_repository], config_path)).to eq(PaniniRepositories.new({
              'panini:A' => PaniniRepository.new('panini:A', expect_remote_A, local_repository, shared_repository),
              'panini:B' => PaniniRepository.new('panini:B', expect_remote_B, nil, nil),
            }))
          end
        end
      end
    end
  end
end
