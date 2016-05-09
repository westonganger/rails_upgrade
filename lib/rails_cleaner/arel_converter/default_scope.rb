module RailsCleaner
  module ArelConverter
    class DefaultScope < Base

      def grep_matches_in_file(file)
        raw_named_scopes = `grep -h -r "^\s*default_scope\s*:" #{file}`
        raw_named_scopes.split("\n")
      end

      def process_line(line)
        new_scope = RailsCleaner::ArelConverter::Translator::DefaultScope.translate(line)
        new_scope.gsub(/default_scope\((.*)\)$/, 'default_scope \1')
      end

      def verify_line(line)
        parser = RubyParser.new
        sexp   = parser.process(line)
        sexp[0] == :call && sexp[2] == :default_scope
      end

    end
  end
end
