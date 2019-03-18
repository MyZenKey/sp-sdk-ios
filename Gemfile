source 'https://rubygems.org'

gem 'fastlane', "~> 2.116.1"
gem 'cocoapods', "~> 1.6"
gem "dotenv", "~> 2.6"
gem "circleci_artifact", "~> 0.1.0"
gem "jazzy", "~> 0.9.4"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
