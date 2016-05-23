module RailsUpgrade
  module ArelConverter
    module Translator
      class DefaultScope < Base

        def process_call(exp)
          @options = Options.translate(exp.pop) if exp[1] == :default_scope
          super
        end

        def post_processing(new_scope)
          new_scope.gsub!(/default_scope\((.*)\)$/, 'default_scope \1')
          new_scope += format_options(@options)
        end

      protected

        def format_options(options)
          return if options.nil? || options.empty?
          " { #{options.strip} }"
        end

      end
    end
  end
end
