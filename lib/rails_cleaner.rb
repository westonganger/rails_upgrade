require 'commander/import'
require './lib/version'

program :version, RailsCleaner::VERSION
program :description, 'Find Unused code, Find unused tables & columns, Convert Ruby Hash syntax 1.8 -> 1.9 -> 2.1, Rails 3.2 -> 4.2 upgrade helpers'

module RailsCleaner
  module FindUnused
    def database(which)
      connection = ActiveRecord::Base.connection
      connection.tables.collect do |t|
        
        if ['tables','database'].include?(which)
          count = connection.select_all("SELECT count(1) as count FROM #{t}", "Count").first['count']
          puts "TABLE UNUSED #{t}" if count.to_i == 0
        end

        if ['columns','database'].include?(which)
          columns = connection.columns(t).collect(&:name).reject {|x| x == 'id' }
          columns.each do |column|
            values = connection.select_all("SELECT DISTINCT(#{t}.#{column}) AS val FROM #{t} LIMIT 2", "Distinct Check")
            if values.size == 1
              if values.first['val'].nil?
                puts "COLUMN UNUSED #{t}:#{column}"
              else
                puts "COLUMN SINGLE VALUE #{t}:#{column} -- #{values.first['val']}"
              end
            end
          end
        end

      end
    end

    def partials
      DiscoverUnusedPartials.find
    end
  end

  module SyntaxUpgrades
    def convert_hash_to_version(version)
      if version >= 2.1
        `ruby -e`
      else

      end
    end
  end

  module Rails3To4
    def convert_finders
      # arel_converter
    end

    def convert_association_conditions
      # custom for default_scopes

      # arel_converter for other scopes
    end

    def convert_scopes
      # custom for default_scopes

      # arel_converter for other scopes
    end

    def convert_action_mailer_method
      ## UNSAFE
      `grep -rl 'deliver' apps/my_app/ | xargs sed -i 's/deliver/deliver_now/g'`
    end

    def locate_missing_habtm_join_table_options

    end
  end
end

command :upgrade_all do |c|
  c.syntax = 'rails_cleaner all [paths]'
  c.summary = 'Apply all possible upgrades to your app'
  c.action do |args, options|
    RailsCleaner::SyntaxUpgrades.convert_hash_to_version('2.1')
    RailsCleaner::Rails3To4.convert_finders
    RailsCleaner::Rails3To4.convert_association_conditions
    RailsCleaner::Rails3To4.convert_finders

    #RailsCleaner::Rails3To4.convert_action_mailer_method
    RailsCleaner::Rails3To4.locate_missing_habtm_join_table_options
    RailsCleaner::FindUnused.partials
    RailsCleaner::FindUnused.database
  end
end

command :find_unused do |c|
  c.syntax = 'rails_cleaner find_unused [options] [paths]'
  c.option '--all', 'Default - Find unused partials, database tables, and database columns'
  c.option '--partials', 'Find unused partials'
  c.option '--tables', 'Find unused database tables'
  c.option '--columns', 'Find unused database columns'
  c.option '--database', 'Find unused database tables & column'
  #c.option '--ignore_manifest', String, 'Ignore file with list of ignored files'
  c.action do |args, options|
    if args.empty?
      args.push dir.pwd
    end

    if !(options.partials || options.tables || options.columns || options.database)
      options.default partials: true, database: true
    end

    if options.partials
      RailsCleaner::FindUnused.partials
    end

    if options.tables || options.columns || options.database
      if options.database || (options.tables && options.columns)
        RailsCleaner::FindUnused.database('database')
      elsif options.tables
        RailsCleaner::FindUnused.database('tables')
      elsif options.columns
        RailsCleaner::FindUnused.database('columns')
      end
    end
  end
end

command :upgrade_ruby_syntax do |c|
  c.syntax = 'rails_cleaner find_unused [options] [paths]'
  c.option '--all', 'Default - Find unused partials, database tables, and database columns'
  c.option '--partials', 'Find unused partials'
  c.option '--tables', 'Find unused database tables'
  c.option '--columns', 'Find unused database columns'
  c.option '--database', 'Find unused database tables & column'
  #c.option '--ignore_manifest', String, 'Ignore file with list of ignored files'
  c.action do |args, options|
    if args.empty?
      args.push dir.pwd
    end

    if !(options.partials || options.tables || options.columns || options.database)
      options.default partials: true, database: true
    end

    if options.partials
      RailsCleaner::FindUnused.partials
    end

    if options.tables || options.columns || options.database
      if options.database || (options.tables && options.columns)
        RailsCleaner::FindUnused.database('database')
      elsif options.tables
        RailsCleaner::FindUnused.database('tables')
      elsif options.columns
        RailsCleaner::FindUnused.database('columns')
      end
    end
  end
end

module DiscoverUnusedPartials

  def find(options={})
    worker = PartialWorker.new options
    tree, dynamic = Dir.chdir(options[:root]){ worker.used_partials("app") }

    tree.each do |idx, level|
      indent = " " * idx*2
      h_indent = idx == 1 ? "" : "\n" + " "*(idx-1)*2

      if idx == 1
        puts "#{h_indent}The following partials are not referenced directly by any code:"
      else
        puts "#{h_indent}The following partials are only referenced directly by the partials above:"
      end
      level[:unused].sort.each do |partial|
        puts "#{indent}#{partial}"
      end
    end

    unless dynamic.empty?
      puts "\n\nSome of the partials above (at any level) might be referenced dynamically by the following lines of code:"
      dynamic.sort.map do |file, lines|
        lines.each do |line|
          puts "  #{file}:#{line}"
        end
      end
    end
  end

  class PartialWorker
    @@filename = /[a-zA-Z\d_\/]+?/
    @@extension = /\.\w+/
    @@partial = /:partial\s*=>\s*|partial:\s*/
    @@render = /\brender\s*(?:\(\s*)?/

    def initialize options
      @options = options
    end

    def existent_partials root
      partials = []
      each_file(root) do |file|
        if file =~ /^.*\/_.*$/
          partials << file.strip
        end
      end

      partials
    end

    def used_partials root
      raise "#{Dir.pwd} does not have '#{root}' directory" unless File.directory? root
      files = []
      each_file(root) do |file|
        files << file
      end
      tree = {}
      level = 1
      existent = existent_partials(root)
      top_dynamic = nil
      loop do
        used, dynamic = process_partials(files)
        break if level > 1 && used.size == tree[level-1][:used].size
        tree[level] = {
          used: used,
        }
        if level == 1
          top_dynamic = dynamic
          tree[level][:unused] = existent - used
        else
          tree[level][:unused] = tree[level-1][:used] - used
        end
        break unless (files - tree[level][:unused]).size < files.size
        files -= tree[level][:unused]
        level += 1
      end
      [tree, top_dynamic]
    end

    def process_partials(files)
      partials = @options['keep'] || []
      dynamic = {}
      files.each do |file|
        File.open(file) do |f|
          f.each do |line|
            line.strip!
            if line =~ %r[(?:#@@partial|#@@render)(['"])/?(#@@filename)#@@extension*\1]
              match = $2
              if match.index("/")

                path = match.split('/')[0...-1].join('/')
                file_name = "_#{match.split('/')[-1]}"

                full_path = "app/views/#{path}/#{file_name}"
              else
                if file =~ /app\/controllers\/(.*)_controller.rb/
                  full_path = "app/views/#{$1}/_#{match}"
                else
                  full_path = "#{file.split('/')[0...-1].join('/')}/_#{match}"
                end
              end
              partials << check_extension_path(full_path)
            elsif line =~ /#@@partial|#@@render["']/
              if @options["dynamic"] && @options["dynamic"][file]
                partials += @options["dynamic"][file]
              else
                dynamic[file] ||= []
                dynamic[file] << line
              end
            end
          end
        end
      end
      partials.uniq!
      [partials, dynamic]
    end

    EXT = %w(.html.erb .text.erb .erb .html.haml .text.haml .haml .rhtml .html.slim slim)
    def check_extension_path(file)
      "#{file}#{EXT.find{ |e| File.exists? file + e }}"
    end

    def each_file(root, &block)
      files = Dir.glob("#{root}/*")
      files.each do |file|
        if File.directory? file
          next if file =~ %r[^app/assets]
          each_file(file) {|f| yield f}
        else
          yield file
        end
      end
    end
  end
end
