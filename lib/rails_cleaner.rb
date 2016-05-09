Dir[File.join(File.dirname(__FILE__), 'lib/rails_cleaner/**/*.rb')].each{|file| require file}

require 'commander/import'
require 'ruby2ruby'
require 'ruby_parser'
require 'logging'

program :version, RailsCleaner::VERSION
program :description, 'Find Unused code, Find unused tables & columns, Convert Ruby Hash syntax 1.8 -> 1.9 -> 2.1, Rails 3.2 -> 4.2 upgrade helpers'

module RailsCleaner
  module FindUnused
    def partials(paths)
      paths.each do |x|
        DiscoverUnusedPartials.find(x)
      end
    end
  end

  module SyntaxUpgrades
    def convert_hash_to_version(version, paths)
      paths.each do |x|
        puts `perl -pi -e 's/:([\w\d_]+)(\s*)=>/\1:/g' #{x}/**/*.rb #{x}/**/*.haml #{x}/**/*.slim #{x}/**/*.erb`
      end

      if version >= 2.1
      
      end
    end
  end

  module Rails3To4
    def convert_finders(paths, dry_run=false)
      puts "\n== Checking Finders"
      paths.each do |x|
        RailsCleaner::ArelConverter::ActiveRecordFinder.new(x, {dry_run: dry_run}).run!
      end
    end

    def convert_association_conditions(paths, dry_run=false)
      puts "\n== Checking Association Conditions"
      paths.each do |x|
        RailsCleaner::ArelConverter::Association.new(x, {dry_run: dry_run}).run!
      end
    end

    def convert_scopes(paths, dry_run=false)
      puts "\n== Checking Scopes"
      paths.each do |x|
        RailsCleaner::ArelConverter::DefaultScope.new(x, {dry_run: dry_run}).run!
        RailsCleaner::ArelConverter::Scope.new(x, {dry_run: dry_run}).run!
      end
    end

    def locate_action_mailer_method(paths)
      ## UNSAFE
      #`grep -rl 'deliver' apps/my_app/ | xargs sed -i 's/deliver/deliver_now/g'`
      paths.each do |x|
        `grep -rl '.deliver' #{x}`
      end
    end

    def locate_missing_habtm_join_table_options
      paths.each do |x|
        `awk '/has_and_belongs_to_many/ && !/join_table/' #{x}`
      end
    end
  end

  if defined? Rails
    require 'rails'
    class Railtie < Rails::Railtie
      rake_tasks do
        load "tasks/rails_cleaner.rake"
      end
    end
  end

  #module ArelConverter
  #end
end

command :upgrade_all do |c|
  c.syntax = 'rails_cleaner all [paths]'
  c.summary = 'Apply all possible upgrades to your app'
  c.action do |args, options|
    if args.empty?
      args.push dir.pwd
    end

    RailsCleaner::SyntaxUpgrades.convert_hash_to_version('2.1', args)
    RailsCleaner::Rails3To4.convert_finders(args)
    RailsCleaner::Rails3To4.convert_association_conditions(args)
    RailsCleaner::Rails3To4.convert_finders(args)

    #RailsCleaner::Rails3To4.convert_action_mailer_method
    RailsCleaner::Rails3To4.locate_missing_habtm_join_table_options(args)
    RailsCleaner::FindUnused.partials(args)

    `bundle exec rake rails_cleaner:find_unused_database database`
  end
end

command :rails_4 do |c|
  c.syntax = 'rails_cleaner all [paths]'
  c.summary = 'Apply all possible upgrades to your app'
  c.action do |args, options|
    if args.empty?
      args.push dir.pwd
    end

    RailsCleaner::Rails3To4.convert_finders(args)
    RailsCleaner::Rails3To4.convert_association_conditions(args)
    RailsCleaner::Rails3To4.convert_finders(args)

    RailsCleaner::Rails3To4.locate_action_mailer_method(args)
    RailsCleaner::Rails3To4.locate_missing_habtm_join_table_options(args)
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
      RailsCleaner::FindUnused.partials(args)
    end

    if options.tables || options.columns || options.database
      if options.database || (options.tables && options.columns)
        `bundle exec rake rails_cleaner:find_unused_database database`
      elsif options.tables
        `bundle exec rake rails_cleaner:find_unused_database tables`
      elsif options.columns
        `bundle exec rake rails_cleaner:find_unused_database columns`
      end
    end
  end
end

command :convert_hash_syntax do |c|
  c.syntax = 'rails_cleaner convert_hash_syntax [options] [paths]'
  c.option '--which', String, '1.9 syntax or 2.1 (default) syntax'
  c.action do |args, options|
    if args.empty?
      args.push dir.pwd
    end

    options.default which: '2.1'
    
    RailsCleaner::SyntaxUpgrades.convert_hash_to_version(options[:which], args)
  end
end

