require 'commander/import'

Dir[File.join(File.dirname(__FILE__), 'rails_upgrade/*.rb')].each{|file| require file}

program :version, RailsUpgrade::VERSION
program :description, 'Find Unused code, Find unused tables & columns, Convert Ruby Hash syntax 1.8 -> 1.9 -> 2.1, Rails 3.2 -> 4.2 upgrade helpers'

module RailsUpgrade
  module FindUnused
    def self.partials(paths)
      paths.each do |x|
        RailsUpgrade::DiscoverUnusedPartials.find({root: x})
      end
    end
  end

  module Syntax
    def self.convert_hash_to_version(version, paths)
      paths.each do |x|
        puts `perl -pi -e 's/:([\w\d_]+)(\s*)=>/\1:/g' #{x}/**/*.rb #{x}/**/*.haml #{x}/**/*.slim #{x}/**/*.erb`
      end

      if version.to_f >= 2.1
      
      end
    end
  end

  module Rails3To4
    def self.convert_finders(paths, dry_run=false)
      puts "\n== Checking Finders"
      paths.each do |x|
        RailsUpgrade::ArelConverter::ActiveRecordFinder.new(x, {dry_run: dry_run}).run!
      end
    end

    def self.convert_association_conditions(paths, dry_run=false)
      puts "\n== Checking Association Conditions"
      paths.each do |x|
        RailsUpgrade::ArelConverter::Association.new(x, {dry_run: dry_run}).run!
      end
    end

    def self.convert_scopes(paths, dry_run=false)
      puts "\n== Checking Scopes"
      paths.each do |x|
        RailsUpgrade::ArelConverter::DefaultScope.new(x, {dry_run: dry_run}).run!
        RailsUpgrade::ArelConverter::Scope.new(x, {dry_run: dry_run}).run!
      end
    end

    def self.locate_action_mailer_method(paths)
      ## UNSAFE
      #`grep -rl 'deliver' apps/my_app/ | xargs sed -i 's/deliver/deliver_now/g'`
      paths.each do |x|
        `grep -rl '.deliver' #{x}`
      end
    end

    def self.locate_update_attributes_method(paths)
      ## UNSAFE
      #`grep -rl 'deliver' apps/my_app/ | xargs sed -i 's/deliver/deliver_now/g'`
      paths.each do |x|
        `grep -rl '.update_attributes' #{x}`
      end
    end

    def self.locate_missing_habtm_join_table(paths)
      paths.each do |x|
        `awk '/has_and_belongs_to_many/ && !/join_table/' #{x}/**/*.rb`
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
end

default_command :help

command :upgrade_all do |c|
  c.syntax = 'rails_cleaner all [paths]'
  c.summary = 'Apply all possible upgrades to your app'
  c.action do |args, options|
    if args.empty?
      args.push dir.pwd
    end

    RailsUpgrade::Syntax.convert_hash_to_version('2.1', args)
    RailsUpgrade::Rails3To4.convert_finders(args)
    RailsUpgrade::Rails3To4.convert_association_conditions(args)
    RailsUpgrade::Rails3To4.convert_scopes(args)

    RailsUpgrade::Rails3To4.locate_action_mailer_method(args)
    RailsUpgrade::Rails3To4.locate_update_attributes_method(args)
    RailsUpgrade::Rails3To4.locate_missing_habtm_join_table(args)
    RailsUpgrade::FindUnused.partials(args)

    `bundle exec rake rails_cleaner:find_unused_database database`
  end
end

command :rails_4 do |c|
  c.syntax = 'rails_cleaner rails_4 [paths]'
  c.summary = 'Rails 4 upgrades'
  c.option '--dry-run', "Dry run"
  c.action do |args, options|
    if args.empty?
      args.push dir.pwd
    end

    RailsUpgrade::Rails3To4.convert_finders(args)
    RailsUpgrade::Rails3To4.convert_association_conditions(args)
    RailsUpgrade::Rails3To4.convert_scopes(args)

    RailsUpgrade::Rails3To4.locate_action_mailer_method(args)
    RailsUpgrade::Rails3To4.locate_update_attributes_method(args)
    RailsUpgrade::Rails3To4.locate_missing_habtm_join_table(args)
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
      RailsUpgrade::FindUnused.partials(args)
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
    
    RailsUpgrade::Syntax.convert_hash_to_version(options[:which], args)
  end
end

