
require 'uri'

# Support for thin partials (via include)
require 'slim/include'

# Which view folders to include (Slim)
include_dirs = [File.join(Dir.pwd, 'views', 'elements')]

# Used during local development
configure :development do

  require 'pp'
  Slim::Engine.set_options(format: :html, include_dirs: include_dirs, pretty: true, sort_attrs: false)

end

# Used in a production environment
configure :production do

  Slim::Engine.set_options(format: :html, include_dirs: include_dirs)

end

# Load mount point class, for server multiple directories at once
require_relative '../models/point'

# Load the main application
require_relative '../main'
