namespace :rails_cleaner do

  desc "Find all unused tables/columns"
  task :find_unused_db, [:which] => :environment do |task, args|
    args.with_defaults(which: 'database')
    if !['tables','columns','database'].include?(which)
      which = 'database'
    end

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

end
