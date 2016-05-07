require 'optparse'

module RailsCleaner
  class CLI

    class << self
      def start
        options = {}
        OptionParser.new do |opts|
          opts.on('-d', '--debug', 'Show stack traces when an error occurs.') { |v| options[:debug] = v }
          opts.on_tail("-v", "--version", "Show version") do
            puts LolDba::VERSION
            exit
          end
        end.parse!
        new(Dir.pwd, options).start
      end
    end

    def initialize(path, options)
      @path, @options = path, options
    end

    def start
      load_application
      arg = ARGV.first
      if arg =~ /find/
        OptionParser.new do |opts|
          opts.on('-p','--partials', 'Find all unused partials') do
            RailsCleaner.find_unused_partials
          end
          opts.on('-d','--database', 'Find all unused database tables and columns') do
            RailsCleaner.find_unused_database
          end
        end
      elsif arg =~ /convert/
        if arg =~ /1\.9/
          RailsCleaner.convert_to_syntax(version='1.9')
        end

        if arg =~ /2\.1/
          RailsCleaner.convert_to_syntax(version='2.1')
        end
      else
        RailsCleaner.help
      end
    rescue Exception => e
      $stderr.puts "Failed: #{e.class}: #{e.message}" if @options[:debug]
      $stderr.puts e.backtrace.map { |t| "    from #{t}" } if @options[:debug]
    end

    protected

    # Tks to https://github.com/voormedia/rails-erd/blob/master/lib/rails_erd/cli.rb
    def load_application
      require "#{@path}/config/environment"
    end
  end
end
