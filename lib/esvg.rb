require "fileutils"

require "esvg/version"
require "esvg/utils"
require "esvg/svgs"
require "esvg/svg"

if defined?(Rails)
  require "esvg/helpers" 
  require "esvg/railties" 
end

module Esvg
  extend self

  def new(options={})
    @svgs ||=[]
    @svgs << Svgs.new(options)
    @svgs.last
  end

  def svgs
    @svgs
  end

  def use(name, options={})
    if symbol = find_symbol(name, options)
      html_safe symbol.use options
    end
  end

  def use_tag(name, options={})
    if symbol = find_symbol(name, options)
      html_safe symbol.use_tag options
    end
  end

  def embed(names=nil)
    html_safe find_svgs(names).map{|s| s.embed_script(names) }.join
  end

  def build_paths(names=nil)
    find_svgs(names).map{|s| s.build_paths(names) }.flatten
  end

  def seed_cache(options)
    svgs = Svgs.new(options)
    puts "Optimizing SVGs" if options[:print]
    svgs.symbols.map(&:optimize)
    svgs.write_cache
  end

  def find_svgs(names=nil)
    @svgs.select {|s| s.buildable_svgs(names) }
  end

  def find_symbol(name, options={})
    if group = @svgs.find {|s| s.find_symbol(name, options[:fallback]) }
      group.find_symbol(name, options[:fallback])
    end
  end

  def rails?
    defined?(Rails) || File.exist?("./bin/rails")
  end

  def html_safe(input)
    input = input.html_safe if rails?
    input
  end

  def precompile_assets
    if defined?(Rails) && Rails.env.production? && defined?(Rake)
      ::Rake::Task['assets:precompile'].enhance do
        Svgs.new(gzip: true, print: true).build
      end
    end
  end

  # Determine if an NPM module is installed by checking paths with `npm bin`
  # Returns path to binary if installed
  def node_module(cmd)
    @modules ||={}
    return @modules[cmd] if !@modules[cmd].nil?

    local = "$(npm bin)/#{cmd}"
    global = "$(npm -g bin)/#{cmd}"

    @modules[cmd] = if Open3.capture3(local)[2].success?
      local
    elsif Open3.capture3(global)[2].success?
      global
    else
      false
    end
  end
end
