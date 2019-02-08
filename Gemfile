source 'https://rubygems.org'

gem 'fastlane', "~> 2.115.0"
gem 'cocoapods'
gem "dotenv", "~> 2.6"

# Added at 2019-02-06 09:09:53 -0800 by adamtierney:
gem "circleci_artifact", "~> 0.1.0"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
