require 'spec_helper'
require 'stringio'

module Git
  module Panini
    describe LocalConfig do
      describe '.from_file' do
        it 'fills local_configuration' do
          subject = described_class.from_file(StringIO.new(<<EOT
---
syncbase: ~/Dropbox/repositories
repositories:
  - ~/src/A
  - ~/src/A
  - ~/src/B
  - ~/src/C
ignore:
  - ~/src/D
EOT
                                                          ))

          expect(subject.syncbase).to eq(Pathname("~/Dropbox/repositories"))
          expect(subject.repositories.map(&:path)).to eq([
            Pathname("~/src/A"),
            Pathname("~/src/B"),
            Pathname("~/src/C"),
          ])
          expect(subject.ignores).to eq([Pathname("~/src/D")])
        end
      end
    end
  end
end
