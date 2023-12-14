module ActiveGraph
  module Node
    module QueryMethods
      def exists?(node_condition = nil)
        unless [String, Hash, NilClass].any? { |c| node_condition.is_a?(c) }
          fail(ActiveGraph::InvalidParameterError, ':exists? only accepts ids or conditions')
        end
        query_start = exists_query_start(node_condition)
        start_q = query_start.respond_to?(:query_as) ? query_start.query_as(:n) : query_start
        result = start_q.return('elementId(n) AS proof_of_life LIMIT 1').first
        !!result
      end

      # Returns the first node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def first
        self.query_as(:n).limit(1).order(n: primary_key).pluck(:n).first
      end

      # Returns the last node of this class, sorted by ID. Note that this may not be the first node created since Neo4j recycles IDs.
      def last
        self.query_as(:n).limit(1).order(n: { primary_key => :desc }).pluck(:n).first
      end

      # @return [Integer] number of nodes of this class
      def count(distinct = nil)
        fail(ActiveGraph::InvalidParameterError, ':count accepts the `:distinct` symbol or nil as a parameter') unless distinct.nil? || distinct == :distinct
        q = distinct.nil? ? 'n' : 'DISTINCT n'
        self.query_as(:n).return("count(#{q}) AS count").first[:count]
      end

      alias size count
      alias length count

      def empty?
        !self.all.exists?
      end

      alias blank? empty?

      def find_in_batches(options = {})
        self.query_as(:n).return(:n).find_in_batches(:n, primary_key, options) do |batch|
          yield batch.map { |record| record[:n] }
        end
      end

      def find_each(options = {})
        self.query_as(:n).return(:n).find_each(:n, primary_key, options) do |batch|
          yield batch[:n]
        end
      end

      private

      def exists_query_start(condition)
        return exists_query_start(primary_key => condition) if condition&.is_a?(String)

        if condition&.key?(:neo_id)
          query_as(:n).where('elementId(n)' => condition[:neo_id])
        else
          where(**condition)
        end
      end
    end
  end
end
