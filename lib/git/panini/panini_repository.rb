require 'forwardable'

module Git
  module Panini
    class PaniniRepository
      attr_reader :panini_name, :orig_remotes
      attr_accessor :local_repository, :shared_repository

      def initialize(panini_name, remotes, local_repository, shared_repository)
        @panini_name = panini_name
        @orig_remotes = remotes
        @local_repository = local_repository
        @shared_repository = shared_repository
      end

      def ==(other)
        @panini_name == other.panini_name and
          @orig_remotes == other.orig_remotes and
          @local_repository == other.local_repository and
          @shared_repository == other.shared_repository
      end

      def remotes
        h = @orig_remotes.dup
        h['panini'] = @shared_repository.to_remote if @shared_repository
        h
      end

      def create_shared_repository(basepath)
        path = basepath + "#{non_panini_name}.git"
        Rugged::Repository.clone_at(
          local_repository.path.to_s, path.to_s, bare: true
        )
      end

      def clone_local_repository
        ['origin', 'panini'].each do |name|
          if remotes[name]
            Rugged::Repository.clone_at(
              remotes[name].url, local_repository.path.to_s,
            )
            return true
          end
        end
        false
      end

      protected

      attr_reader :orig_remotes

      def non_panini_name
        panini_name.gsub(/\Apanini:/, '')
      end
    end

    class PaniniRepositories
      extend Forwardable
      def_delegators :@h, :[], :[]=, :size

      def initialize(h=nil)
        @h = h || Hash.new
      end

      def ==(other)
        @h == other.h
      end

      def each(&block)
        enum = Enumerator.new do |y|
          @h.keys.sort.each do |key|
            y << @h[key]
          end
        end
        block ? enum.each(&block) : enum
      end

      protected

      attr_accessor :h

      public

      def find_by_name(name)
        if name
          if @h[name]
            PaniniRepositories.new({name => @h[name]})
          else
            raise ArgumentError
          end
        else
          self
        end
      end

      def with_local_repository
        PaniniRepositories.new(@h.select do |key, repo|
          !!repo.local_repository
        end)
      end

      def without_shared_repository
        PaniniRepositories.new(@h.select do |key, repo|
          !repo.shared_repository
        end)
      end
    end
  end
end
