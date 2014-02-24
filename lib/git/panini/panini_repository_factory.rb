require "yaml"

module Git
  module Panini
    module PaniniRepositoryFactory
      def self.construct(local_repositories, shared_repositories, shared_config_path)
        panini_repos = parse_config(shared_config_path)
        local_repositories.each do |repo|
          if not panini_repos[repo.panini_name]
            panini_repos[repo.panini_name] = PaniniRepository.new(repo.panini_name, {}, nil, nil)
          end
          panini_repos[repo.panini_name].local_repository = repo
        end
        shared_repositories.each do |repo|
          if not panini_repos[repo.panini_name]
            panini_repos[repo.panini_name] = PaniniRepository.new(repo.panini_name, {}, nil, nil)
          end
          panini_repos[repo.panini_name].shared_repository = repo
        end
        panini_repos
      end

      private

      def self.parse_config(config_path)
        repos = PaniniRepositories.new
        return repos unless config_path.exist?

        YAML.load_stream(config_path.open('r')).each do |document|
          if document['repositories']
            document['repositories'].each do |repo|
              remotes = parse_options(repo)
              repos[repo['name']] = PaniniRepository.new(repo['name'], remotes, nil, nil)
            end
          end
        end
        repos
      end

      def self.parse_options(repo)
        remotes = Hash.new
        repo.each do |key, value|
          if key == 'remotes'
            value.each do |name, url|
              remotes[name] = Remote.new_from_url(name, url)
            end
          end
        end
        remotes
      end
    end
  end
end
