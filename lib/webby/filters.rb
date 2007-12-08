
module Webby
  
  module Filters
   
    class << self
      
      # Register a handler for a filter
      def register(filter, &block)
        handlers[filter.to_s] = block
      end
      
      # Process input through filters
      def process(renderer, page, input)
        # Start a new cursor for this page
        Cursor.new(renderer, page).start_for(input)
      end
      
      # Access a filter handler
      def [](name)
        handlers[name]
      end
        
      #######
      private
      #######

      # The registered filter handlers
      def handlers
        @handlers ||= {}
      end
      
      # Instances of this class handle processing a set of filters
      # for a given renderer and page.
      # Note: The instance is passed as the second argument to filters
      #       that require two parameters and can be used to access 
      #       information on the renderer, page, or filters being
      #       processed.
      class Cursor
        
        attr_reader :renderer, :page, :filters, :log
        def initialize(renderer, page)
          @renderer, @page = renderer, page
          @filters = Array(page.filter)
          @log = Logging::Logger[self]
          @processed = 0
        end
        
        def start_for(input)
          filters.inject(input) do |result, filter|
            handler = Filters[filter]
            args = [result, self][0, handler.arity]
            handle(filter, handler, *args)
          end
        end
        
        # The list of filters yet to be processed
        def remaining_filters
          filters[@processed..-1]
        end
        
        # The name of the current filter
        def current_filter
          filters[@processed]
        end
        
        #######
        private
        #######

        # Process arguments through a single filter
        def handle(filter, handler, *args)
          result = handler.call(*args)
          @processed += 1
          result
        rescue NameError => e
          log.fatal "Name error in filter `#{filter}' (missing dependency?): #{e.message}"
          exit 1
        rescue => e
          log.fatal "Error in filter `#{filter}': #{e.message}"
          exit 1
        end
        
      end
      
    end
    
  end
  
end