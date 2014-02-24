require 'thor'

module Git
  module Panini
    class CLI < Thor
      desc "status", "show statuses of local repositories"
      def status
        puts Driver.default.status
      end

      desc "branch", "show branch statuses of local repositories"
      def branch
        puts Driver.default.branch
      end

      desc "world", "show all panini settings of local repositories"
      option :verbose, type: :boolean
      def world
        puts Driver.default.world(options[:verbose])
      end

      desc "path NAME", "show the filepath to the local clone"
      def path(name)
        puts Driver.default.path(name)
      end

      desc "non-panini", "find the repositories not controlled by git-panini"
      def non_panini(path=nil)
        path ||= Dir.pwd
        path = File.expand_path(path)
        puts Driver.default.non_panini(path)
      end

      desc "non-shared", "find the repositories that do not have shared repositories"
      def non_shared
        puts Driver.default.non_shared
      end

      desc "fetch", "fetch from all remotes of local repositories"
      def fetch
        Driver.default.fetch
      end

      desc "apply", "apply panini settings to the local repositories"
      def apply
        Driver.default.apply
      end

      desc "noop", "apply panini settings to the local repositories (noop)"
      def noop
        Driver.default.noop
      end

      desc "share", "make a shared repository"
      def share
        Driver.default.share(Dir.pwd)
      end
    end
  end
end
