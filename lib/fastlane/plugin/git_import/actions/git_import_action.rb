require 'fastlane/action'
require_relative '../helper/git_import_helper'

module Fastlane
  module Actions
    class GitImportAction < Action
      def self.run(params)
        require 'tmpdir'

        url = params[:url]
        branch = params[:branch] || 'HEAD'
        version = params[:version]
        import = params[:import]

        # puts "CURRENT DIRECTORY: #{Dir.pwd}"

        UI.user_error!("Please pass a url to the `git_import` action") if url.to_s.length == 0
        UI.user_error!("Please pass a import callback to the `git_import` action") if import == nil

        # Checkout the repo
        repo_name = url.split("/").last
        checkout_param = branch

        Dir.mktmpdir("fl_clone") do |tmp_path|
          clone_folder = File.join(tmp_path, repo_name)
    
          branch_option = "--branch #{branch}" if branch != 'HEAD'
    
          UI.message("Cloning remote git repo...")
          Helper.with_env_values('GIT_TERMINAL_PROMPT' => '0') do
            Actions.sh("git clone #{url.shellescape} #{clone_folder.shellescape} --depth 1 -n #{branch_option}")
          end
    
          unless version.nil?
            req = Gem::Requirement.new(version)
            all_tags = fetch_remote_tags(folder: clone_folder)
            checkout_param = all_tags.select { |t| req =~ FastlaneCore::TagVersion.new(t) }.last
            UI.user_error!("No tag found matching #{version.inspect}") if checkout_param.nil?
          end
    
          common_checkout = "cd #{clone_folder.shellescape} && git checkout #{checkout_param.shellescape} *.rb"
          Actions.sh(common_checkout)
    
          containing = "."
    
          optional_folders = ['actions', 'helper'].map { |folder| File.join(containing, folder) }
          optional_folders.each do |optional_folder|
            begin
              Actions.sh("cd #{clone_folder.shellescape} && git checkout #{checkout_param.shellescape} #{optional_folder.shellescape}")
            rescue
              # We don't care about a failure here, as local additional files are optional
            end
          end
    
          clone_folder_paths = Dir.glob('*.rb', base: clone_folder)
          return_value = clone_folder_paths.map { |file_path| import.call(File.join(clone_folder, file_path)) }
    
          begin
            folder = "#{clone_folder}/helper/"
            file_paths = Dir.glob('*.rb', base: folder)
            return_value += file_paths.map { |file_path| import.call(File.join(folder, file_path))}
          rescue
            # We don't care about a failure here, as helper files are optional
          end
    
          return return_value
        end
      end

      def self.description
        "Import all required fastlane dependencies from the git repository and keep your Fastfile simple!"
      end

      def self.authors
        ['👤 GitHub: @DmitryFrishbuter / Email: dmitry.frishbuter@gmail.com']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Import all required fastlane dependencies from the git repository and keep your Fastfile simple!"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :url,
                                       description: "The URL of the repository to import the Fastfile from",
                                       default_value: nil),
          FastlaneCore::ConfigItem.new(key: :branch,
                                       description: "The branch or tag to check-out on the repository",
                                       default_value: 'HEAD',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :version,
                                       description: "The version to checkout on the repository. Optimistic match operator or multiple conditions can be used to select the latest version within constraints",
                                       default_value: nil,
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :import,
                                       description: "Callback from Fastfile to perform import for every git dependency",
                                       default_value: nil,
                                       is_string: false,
                                       optional: false)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end

      def self.example_code
        [
          'git_import(
            url: "git@github.com:fastlane/fastlane.git", # The URL of the repository to import the Fastfile from.
            branch: "HEAD", # The branch to checkout on the repository.
            version: "~> 1.0.0" # The version to checkout on the repository. Optimistic match operator can be used to select the latest version within constraints.
          )'
        ]
      end
    end
  end
end
