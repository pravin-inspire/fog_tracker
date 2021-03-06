module FogTracker
  module Query
    # A class for filtering the Fog resources for a set of {AccountTracker}s,
    # based on a regular-expression-based query
    class QueryProcessor

      # The Regular Expression which all resource queries must match
      QUERY_PATTERN = %r{(.*)::(.*)::(.*)::(.*)}

      # Creates an object for filtering Resources from a set of AccountTrackers
      # @param [Hash] trackers a Hash of AccountTrackers, indexed by account name
      # @param [Hash] options optional additional parameters:
      #  - :logger - a Ruby Logger-compatible object
      def initialize(trackers, options={})
        @trackers = trackers
        @log      = options[:logger] || FogTracker.default_logger
      end

      # Uses the query string to filter all polled resources
      # for a desired subset
      # @param [String] query a string used to filter for matching resources
      # @return [Array <Fog::Model>] an Array of Resources, filtered by query
      def execute(query)
        acct_pattern, svc_pattern, prov_pattern, col_pattern = parse_query(query)
        filter_by_collection(
          filter_by_provider(
            filter_by_service(
              attach_query_methods(get_results_by_account(acct_pattern)),
              svc_pattern),
            prov_pattern),
          col_pattern)
      end

      private

      # Returns an Array of 4 RegEx objeccts based on the +query_string+
      # for matching [account name, service, provider, collection]
      def parse_query(query_string)
        #@log.debug "Parsing Query #{query_string}"
        tokenize(query_string).map {|token| regex_from_token(token)}
      end

      # Returns an array of 4 String tokens by splitting +query_string+
      def tokenize(query_string)
        query_string.strip!
        if match = query_string.match(QUERY_PATTERN)
          match.captures
        else
          raise "Bad query: '#{query_string}'"
        end
      end

      # Converts a String token into a RegEx for matching query values
      def regex_from_token(token)
        token = '.*' if token == '*'  # a single wildcard is a special case
        %r{^\s*#{token}\s*$}i         # otherwise, interpret as a RegEx
      end

      # Returns a subset of all Resources, filtered only by acct_name_pattern
      def get_results_by_account(acct_name_pattern)
        results = Array.new
        @trackers.each do |account_name, account_tracker|
          if account_name.match acct_name_pattern
            results += account_tracker.all_resources
          end
        end
        results
      end

      # filters an Array of Fog Resources by Service
      def filter_by_service(resources, service_pattern)
        resources.select do |resource|
          service_name = resource.class.name.match(/Fog::(\w+)::/)[1]
          service_name.match service_pattern
        end
      end

      # filters an Array of Fog Resources by Provider
      def filter_by_provider(resources, provider_pattern)
        resources.select do |resource|
          provider_name = resource.class.name.match(/Fog::\w+::(\w+)::/)[1]
          provider_name.match provider_pattern
        end
      end

      # filters an Array of Fog Resources by collection name (Resource Type)
      def filter_by_collection(resources, collection_pattern)
        resources.select do |resource|
          collection_class = resource.collection.class.name.match(/::(\w+)$/)[1]
          collection_class.to_underscore.match collection_pattern
        end
      end

      # adds the _tracker_query_parser attribute to all resources
      def attach_query_methods(resources)
        resources.each {|resource| resource._query_processor = self}
        resources
      end

    end
  end
end
