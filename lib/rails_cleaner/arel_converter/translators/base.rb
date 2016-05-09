module RailsCleaner
  module ArelConverter
    module Translator
      class Base < Ruby2Ruby

        attr_accessor :leading_whitespace

        LINE_LENGTH = 1_000

        def self.translate(klass_or_str, method = nil)
          leading_whitespace = nil
          sexp =
            if klass_or_str.is_a?(String)
              klass_or_str =~ /^(\s+)/
              leading_whitespace = $1
              self.parse(klass_or_str)
            else
              klass_or_str
            end
          processor = self.new
          processor.leading_whitespace = leading_whitespace
          source = processor.process(sexp)
          processor.retain_leading_whitespace(processor.post_processing(source))
        end

        def self.parse(code)
          RubyParser.new.process(code)
        end

        def logger
          @logger ||= setup_logger
        end

        def post_processing(source)
          source
        end

        def retain_leading_whitespace(source)
          leading_whitespace ? source.prepend(leading_whitespace) : source
        end

        def format_for_hash(key, value)
          key =~ /\A:/ ? "#{key.sub(':','')}: #{value}" : "#{key} => #{value}"
        end

      private

        def setup_logger(log_level = :info)
          logging = Logging::Logger[self]
          #layout = Logging::Layouts::Pattern.new(:pattern => "[%d, %c, %5l] %m\n")

          stdout = Logging::Appenders.stdout
          stdout.level = log_level

          #file = Logging::Appenders::File.new("./log/converters.log")
          #file.layout = layout
          #file.level = :debug

          logging.add_appenders(stdout)
          logging
        end

      end
    end
  end
end
