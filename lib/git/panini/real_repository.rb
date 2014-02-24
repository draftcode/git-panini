require 'rugged'

module Git
  module Panini
    class RealRepository
      attr_reader :path
      def initialize(path)
        @path = path.expand_path
      end

      def panini_name
        "panini:#{path.basename('.git')}"
      end

      def ==(other)
        path == other.path
      end
      alias :eql? :==

      def hash
        path.hash
      end

      private

      def repo
        @repo ||= Rugged::Repository.new(path.to_s)
      end

      def flag_to_str(flags)
        index = worktree = ' '
        flags.each do |flag|
          case flag
          when :index_new
            index = 'A'
          when :index_modified
            index = 'M'
          when :index_deleted
            index = 'D'
          when :worktree_new
            index = worktree = '?'
          when :worktree_modified
            worktree = 'M'
          when :worktree_deleted
            worktree = 'D'
          end
        end
        index + worktree
      end
    end

    module SharedRepositoryFactory
      def self.discover(path)
        repos = []
        path.entries.each do |subpath|
          if subpath.extname == '.git'
            repos << SharedRepository.new(path + subpath)
          end
        end
        repos
      end
    end

    class LocalRepository < RealRepository
      def status
        lines = []
        repo.status do |path, flags|
          unless flags.empty?
            lines << flag_to_str(flags) + " " + path
          end
        end
        lines
      end

      def branch_status
        local_branches = []
        remote_branches = Hash.new { |h,k| h[k] = Hash.new }
        repo.branches.each do |branch|
          case branch.canonical_name
          when %r{\Arefs/heads/(.*)}
            local_branches << branch
          when %r{\Arefs/remotes/([^/]*)/(.*)}
            remote_branches[$1][$2] = branch
          else
            raise "Unknown branch: " + branch.canonical_name
          end
        end

        lines = []
        local_branches.each do |branch|
          line = branch.name
          repo.remotes.each do |remote|
            remote_branch = remote_branches[remote.name][branch.name]
            if remote_branch
              line += " [#{remote.name} #{show_distance(repo.lookup(branch.target), repo.lookup(remote_branch.target))}]"
            else
              line += " [#{remote.name} NO BRANCH]"
            end
          end
          lines << line
        end
        lines
      end

      def fetch
        repo.remotes.each do |remote|
          begin
            remote.connect(:fetch) do |r|
              r.download
            end
            puts "Success: #{remote.url}"
          rescue Rugged::NetworkError
            puts "NetworkError: #{remote.url}"
          rescue Rugged::OSError
            puts "OSError: #{remote.url}"
          end
        end
      end

      def remotes
        h = Hash.new
        repo.remotes.each do |remote|
          h[remote.name] = Remote.new(
            remote.name,
            remote.url,
            remote.push_url,
            remote.fetch_refspecs,
            remote.push_refspecs,
          )
        end
        h
      end

      def add_remote(remote)
        Rugged::Remote.add(repo, remote.name, remote.url)
        nil
      end

      private

      def show_distance(from_commit, to_commit)
        return '+0 -0' if from_commit == to_commit
        from_visited = {from_commit.oid => 0}
        to_visited = {to_commit.oid => 0}
        queue = [[from_commit, :from], [to_commit, :to]]
        until queue.empty?
          commit, tag = queue.shift
          if tag == :from
            if to_visited[commit.oid]
              return "+#{to_visited[commit.oid]} -#{from_visited[commit.oid]}"
            else
              distance = from_visited[commit.oid]
              commit.parents.each do |parent|
                from_visited[parent.oid] = distance + 1
                queue.push([parent, tag])
              end
            end
          elsif tag == :to
            if from_visited[commit.oid]
              return "+#{to_visited[commit.oid]} -#{from_visited[commit.oid]}"
            else
              distance = to_visited[commit.oid]
              commit.parents.each do |parent|
                to_visited[parent.oid] = distance + 1
                queue.push([parent, tag])
              end
            end
          end
        end
      end
    end

    class SharedRepository < RealRepository
      def to_remote
        Remote.new_from_url('panini', path.to_s)
      end
    end
  end
end
