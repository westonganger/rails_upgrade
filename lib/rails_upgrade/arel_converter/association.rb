module RailsUpgrade
  module ArelConverter
    class Association < Base
      def grep_matches_in_file(file)
        #raw_named_scopes = `grep -hr "^\s*has_many\\|belongs_to\\|has_and_belongs_to_many\\|has_one" #{file}`
        raw_named_scopes = ''
        ['has_many', 'belongs_to', 'has_and_belongs_to_many', 'has_one'].each do |x|
          raw_named_scopes += `grep -hr "^\s*#{x}" #{file}`
        end

        raw_named_scopes.split("\n")
      end

      def process_line(line)
        RailsUpgrade::ArelConverter::Translator::Association.translate(line)
      end

      def verify_line(line)
        parser = RubyParser.new
        sexp   = parser.process(line)
        sexp.shift == :call
      end
    end
  end
end
