require 'bundler'

# Use bundler to load gems from Gemfile
Bundler.require

# Load environment settings
require_relative 'config/environment'

# Start the application
run FileServer
