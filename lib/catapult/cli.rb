require 'pathname'
require 'fileutils'
require 'listen'
require 'rack'
require 'thor'

module Catapult
  class CLI < Thor
    include Thor::Actions

    def self.source_root
      File.expand_path('../../..', __FILE__)
    end

    desc 'build [asset1 asset2..]', 'Build project'

    method_option :target, :aliases => '-t', :desc => 'Directory to compile assets to'
    method_option :compile, :type => :boolean, :aliases => '-c', :desc => 'Compile and minify assets'

    def build(*assets)
      target = Pathname(options[:target] || './public/assets')

      if options[:compile]
        Catapult.environment.js_compressor  = Compressor::JS.new
        Catapult.environment.css_compressor = Compressor::CSS.new
      end

      say "Building: #{Catapult.root}"
      Catapult.environment.each_file do |filename|
        Catapult.manifest.compile(filename)
        say "Compiled #{filename}"
      end
    end

    desc 'server', 'Serve up project'

    method_option :port, :aliases => '-p', :desc => 'Port'

    def server
      Rack::Server.start(
        :Port => options[:port] || 9292,
        :app  => Catapult.app
      )
    end

    desc 'watch [asset1 asset2..]', 'Build project whenever it changes'

    method_option :target, :aliases => '-t', :desc => 'Directory to compile assets to'

    def watch(*assets)
      say "Watching: #{Catapult.root}"

      build(*assets)

      paths = Catapult.environment.paths
      paths = paths.select {|p| File.exists?(p) }

      Listen.to(*paths) { build }
    end

    desc 'new', 'Create a new project'

    def new(name)
      directory('templates/app', name)
    end
  end
end
