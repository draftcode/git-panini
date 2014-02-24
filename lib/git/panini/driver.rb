require "pathname"
require "erb"
require 'ostruct'

module Git
  module Panini
    class ERBRenderer < OpenStruct
      TEMPLATE_BASE = Pathname(File.expand_path("../templates", __FILE__))

      def self.render(template_name, locals)
        new(locals).render(TEMPLATE_BASE + template_name)
      end

      def render(template_path)
        ERB.new(template_path.read, nil, '<>').result(binding)
      end
    end

    class Driver
      DEFAULT_CONFIG_PATH = Pathname(File.expand_path("~/.git-panini"))

      def self.default
        @driver ||= Driver.from_file(DEFAULT_CONFIG_PATH)
      end

      def self.from_file(local_config_path)
        local_config = LocalConfig.from_file(local_config_path.open('r'))
        if local_config.syncbase
          shared_config_path = local_config.syncbase + "panini-info"
          shared_repositories = SharedRepositoryFactory.discover(local_config.syncbase)
        else
          shared_config_path = nil
          shared_repositories = []
        end
        panini_repos = PaniniRepositoryFactory.construct(
          local_config.repositories, shared_repositories, shared_config_path
        )
        new(local_config.syncbase, local_config.ignores, panini_repos)
      end

      def initialize(syncbase, ignores, panini_repos)
        @syncbase = syncbase
        @ignores = ignores
        @repos = panini_repos
      end

      def status
        ERBRenderer.render('status.erb', repos: @repos.with_local_repository)
      end

      def branch
        ERBRenderer.render('branch.erb', repos: @repos.with_local_repository)
      end

      def world(verbose)
        ERBRenderer.render('world.erb', repos: @repos.with_local_repository, verbose: verbose)
      end

      def path(name)
        repo = @repos.find_by_name(name)[name]
        if repo
          if repo.local_repository
            repo.local_repository.path.to_s
          else
            fail_exit("Repository is not cloned")
          end
        else
          fail_exit("Repository is not found")
        end
      end

      def non_panini(path)
        # TODO
      end

      def non_shared
        ERBRenderer.render('non_shared.erb', repos: @repos.without_shared_repository)
      end

      def fetch
        @repos.with_local_repository.each do |repo|
          repo.local_repository.fetch
        end
      end

      def apply
        @repos.with_local_repository.each do |repo|
          if not repo.local_repository.path.exist?
            if repo.clone_local_repository
              puts "Clone #{repo.panini_name} (#{repo.local_repository.path})"
            else
              puts "Cannot clone #{repo.panini_name}"
            end
          end
        end

        each_remotes do |repo, name, expect, actual|
          if expect != actual
            puts "#{repo.panini_name} (#{name})"
            show_difference(expect, actual)

            if actual == nil
              repo.local_repository.add_remote(expect)
            else
              puts "  Do not touch anything."
            end
          end
        end
      end

      def noop
        @repos.with_local_repository.each do |repo|
          if not repo.local_repository.path.exist?
            puts "Clone #{repo.panini_name} (#{repo.local_repository.path})"
          end
        end

        each_remotes do |repo, name, expect, actual|
          if expect != actual
            puts "#{repo.panini_name} (#{name})"
            show_difference(expect, actual)
          end
        end
      end

      def share(path)
        repo = repo_in(path)
        fail_exit("Repository not found") if not repo
        fail_exit("Shared repository already exists") if repo.shared_repository
        repo.create_shared_repository(@syncbase)
      end

      private

      def fail_exit(message)
        $stderr.puts(message)
        exit(1)
      end

      def show_difference(expect, actual)
        [:url, :push_url, :fetch_refspecs, :push_refspecs].each do |prop|
          if not expect or not actual or expect.send(prop) != actual.send(prop)
            puts "  #{prop}"
            if not expect
              puts "    Expect:"
            else
              puts "    Expect: #{expect.send(prop)}"
            end
            if not actual
              puts "    Actual:"
            else
              puts "    Actual: #{actual.send(prop)}"
            end
          end
        end
      end

      def each_remotes(&block)
        @repos.with_local_repository.each do |repo|
          expect_remotes = repo.remotes
          local_remotes = repo.local_repository.remotes
          (expect_remotes.keys + local_remotes.keys).uniq.sort.each do |name|
            block.call(repo, name, expect_remotes[name], local_remotes[name])
          end
        end
      end

      def repo_in(path)
        path = Pathname(File.expand_path(path))
        @repos.with_local_repository.each do |repo|
          if path.is_child_of?(repo.local_repository.path)
            return repo
          end
        end
        nil
      end
    end
  end
end
