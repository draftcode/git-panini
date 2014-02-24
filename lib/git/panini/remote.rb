module Git
  module Panini
    class Remote
      attr_reader :name, :url, :fetch_refspecs, :push_refspecs

      def initialize(name, url, push_url, fetch_refspecs, push_refspecs)
        @name = name
        @url = url
        @push_url = push_url
        @fetch_refspecs = fetch_refspecs
        @push_refspecs = push_refspecs
      end

      def self.new_from_url(name, url)
        new(name, url, nil, ["+refs/heads/*:refs/remotes/#{name}/*"], [])
      end

      def ==(other)
        other and
          @name == other.name and
          @url == other.url and
          push_url == other.push_url and
          @fetch_refspecs == other.fetch_refspecs and
          @push_refspecs == other.push_refspecs
      end

      def push_url
        @push_url == nil ? @url : @push_url
      end
    end
  end
end
