
class FileServer < Sinatra::Base

  # TODO: Read more about different types of logging
  # This logger must be used to work with the thin web server, for some reason
  use Rack::CommonLogger

  # Enable session cookies, set to expire after 30 days
  use Rack::Session::Cookie, expire_after: 2592000, secret: 'cookies are better than cake'

  configure do
    # TODO: Add a way to vew total size of the mount point
    # TODO: Create a mount system (with public/private directories)
    set :mount, Point.new(File.join('', 'mnt', 'felix', 'syncthing', 'server-files'))

    # TODO: Add a better authentication scheme
    # Access codes, used to log in
    set :access_codes, %w(password)
  end

  before do
    headers['Content-Security-Policy'] = "default-src 'self'"
    headers['Referrer-Policy'] = 'no-referrer'
  end

=begin
  # Write a decent blog post about the bug that surrounds this
  error 400..409 do
    status = response.status
    messages = {
        400 => 'Client error, bad request.',
        401 => 'Client error, unauthorized. Invalid authentication credentials.', # Fuck this shit.
        403 => 'Client error, forbidden. Invalid authorization.', # Skip handling here, the submit bug report?
        404 => 'Client error, target resource not found.',
        409 => 'Client error, conflict with the current state of the target resource.'
    }

    slim :error, locals: { status: status, message: messages[status] }
  end
=end

  get '/auth' do
    slim :authenticate
  end

  post '/auth' do
    access_code = params[:access_code]
    halt 400 unless access_code.instance_of?(String)

    session[:success] = true if settings.access_codes.include?(access_code)
    redirect back
  end

  get '/upload' do
    slim :upload, locals: { token: params[:token] }
  end

  post '/upload' do
    # 400 to indicate bad request when no file
    halt 400 unless params[:file].instance_of?(Hash)

    # TODO: Add some kind of a module to autmatically error when users are not logged in (separate helper function?)
    # 403 to indicate refusal of request when user isn't logged in
    halt 403 unless session[:success] # Needs to work with ShareX too. Add token support anyways

    # TODO: Mounting system should support default mount points
    # Find where to save the file on disk. How would this work with multiple mount points? Add a default mount point?
    file_path = File.join(settings.mount.base_path, params[:file][:filename])

    # TODO: Check for permission failure, and hard drive space. Basically add rescue blocks
    # 409 to indicate conflict with the target resource
    halt 409 if File.exist?(file_path)

    File.open(file_path, 'w+') { |file| file.write(params[:file][:tempfile].read) }

    # TODO: Remove hardcoding of HTTPS scheme. Detect when behind a reverse proxy??
    # Handle change of scheme when behind a reverse proxy with SSL?
    file_url = URI.escape("#{request.base_url}/#{params[:file][:filename]}")

    status 201
    headers['Location'] = file_url
  end

  # Check disk first (ex. if exist), then check url (for ex. rewrite)
  # 'test.txt' can be file or dir: '/test.txt', '/test.txt/'
  get '*' do |url_path|

    file_path = settings.mount.get_absolute_path(url_path)
    halt 404 unless File.exist?(file_path)

    if File.directory?(file_path)
      # Correct: Display login with 401 when no cookie
      # Ask for user authentication before ???? redirect back? Where is back? Referer?
      #pp session[:success]

      unless !session[:success].nil? && session[:success]
        #halt 401, slim(:authenticate)

        status 401
        halt slim :authenticate
      end

      # Redirect to add trailing slash for directories
      redirect url_path + '/' unless url_path.end_with?('/')

      @structure = settings.mount.generate_structure(url_path)

      #pp @structure

      halt slim :list_folder
    end

    # Redirect to remove trailing slash for files
    redirect url_path.chomp('/') if url_path.end_with?('/')

    view_mode = params[:view]

    send_file file_path if view_mode == 'direct' || view_mode.nil?

    #pp url_path

    slim :file_view, locals: { url_path: url_path }
  end

end
