class Point

  attr_reader :base_path

  # Permissions:
  # Public (default)
  # Private (whitelist, blacklist)
  # Unlisted (still public/private, just does not show up in list, but is still routable)
  # Unlisted:
  #   * URL parameter with key (all links must have the same URL key?)
  #   * URL paramater that sets a permission cookie
  #   * Password prompt that sets a cookie
  #   * Authentication with email, sets permission cookie
  # Listing a folder should compare permission cookies/URL keys, before generating the list
  # How should the generation work?

  def initialize(base_dir)
    raise ArgumentError, 'argument must be an absolute path' unless Pathname.new(base_dir).absolute?
    @base_path = base_dir
  end

  def get_absolute_path(url_path)
    File.join(@base_path, url_path.split('/'))
  end

  def calculate_size(path)
    # TODO: Add human-readable file size units, or maybe split into groups of three digits at least.
    return File.size(path) unless File.directory?(path)
    Dir.glob(File.join(path, '**', '*')).inject(0) { |total_size, current| total_size + File.size(current) }
  end

  def get_file_info(path)

    def format_time(time)
      time.utc.strftime('%Y-%m-%d %H:%M UTC')
    end

    {
      name: File.basename(path) + (File.directory?(path) ? '/' : ''),
      atime: format_time(File.atime(path)),
      mtime: format_time(File.mtime(path)),
      ctime: format_time(File.ctime(path)),
      size: calculate_size(path)
    }
  end

  def list_files(url_path)
    # TODO: Add custom sorting and filtering here. The function `sort` works for now
    Dir.glob(File.join(@base_path, url_path, '*')).sort.map { |absolute_path| get_file_info(absolute_path) }
  end

  def generate_structure(url_path)
    raise ArgumentError, 'argument must not be a file' unless File.directory?(File.join(@base_path, url_path))

    # TODO: There's probably a function in the URI module that does this already.
    split = url_path.scan(%r{[^/]+/|/})
    bread = split.each_with_index.map do |value, index|
      if index.zero?
        { url_path: value, name: value }
      else
        { url_path: split[0..(index - 1)].join + value, name: value[0..-2] }
      end
    end

    { current: url_path, files: list_files(url_path), bread: bread }
  end

end
