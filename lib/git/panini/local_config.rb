require "yaml"
require "pathname"

module Git
  module Panini
    class LocalConfig
      attr_reader :syncbase, :repositories, :ignores

      def initialize(syncbase, repositories, ignores)
        @syncbase = syncbase.expand_path
        @repositories = repositories.freeze
        @ignores = ignores.freeze
      end

      def self.from_file(stream)
        syncbase = nil
        repositories = []
        ignores = []
        YAML.load_stream(stream).each do |document|
          syncbase ||= document['syncbase']
          repositories += document['repositories'] if document['repositories']
          ignores += document['ignore'] if document['ignore']
        end
        syncbase = Pathname(syncbase) if syncbase
        repositories = repositories.map { |path| LocalRepository.new(Pathname(path)) }.uniq
        ignores = ignores.map { |path| Pathname(path) }.uniq
        new(syncbase, repositories, ignores)
      end
    end
  end
end
