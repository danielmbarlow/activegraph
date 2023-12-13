module ActiveGraph::Relationship
  module Query
    extend ActiveSupport::Concern

    class RecordNotFound < ActiveGraph::RecordNotFound; end

    module ClassMethods
      # Returns the object with the specified neo4j id.
      # @param [String] id of node to find
      def find(id)
        fail "Unknown argument #{id.class} in find method (expected String)" unless id.is_a?(String)
        find_by_id(id)
      end

      # Loads the relationship using its neo_id.
      def find_by_id(key)
        query = ActiveGraph::Base.new_query
        result = query.match('()-[r]-()').where('elementId(r)' => key).limit(1).return(:r).first
        fail RecordNotFound.new("Couldn't find #{name} with 'id'=#{key.inspect}", name, key) if result.blank?
        result[:r]
      end

      # Performs a very basic match on the relationship.
      # This is not executed lazily, it will immediately return matching objects.
      # To use a string, prefix the property with "r1"
      # @example Match with a string
      #   MyRelClass.where('r1.grade > r1')
      def where(args = {})
        where_query.where(where_string(args)).pluck(:r1)
      end

      def find_by(args)
        where(args).first
      end

      # Performs a basic match on the relationship, returning all results.
      # This is not executed lazily, it will immediately return matching objects.
      def all
        all_query.pluck(:r1)
      end

      def first
        all_query.limit(1).order('r1.created_at').pluck(:r1).first
      end

      def last
        all_query.limit(1).order('r1.created_at DESC').pluck(:r1).first
      end

      private

      def deprecation_warning!
        ActiveSupport::Deprecation.warn 'The ActiveGraph::Relationship::Query module has been deprecated and will be removed in a future version of the gem.', caller
      end

      def where_query
        deprecation_warning!
        ActiveGraph::Base.new_query.match("#{cypher_string(:outbound)}-[r1:`#{type}`]->#{cypher_string(:inbound)}")
      end

      def all_query
        deprecation_warning!
        ActiveGraph::Base.new_query.match("#{cypher_string}-[r1:`#{type}`]->#{cypher_string(:inbound)}")
      end

      def cypher_string(dir = :outbound)
        case dir
        when :outbound
          identifier = '(n1'
          identifier + (_from_class == :any ? ')' : cypher_label(:outbound))
        when :inbound
          identifier = '(n2'
          identifier + (_to_class == :any ? ')' : cypher_label(:inbound))
        end
      end

      def cypher_label(dir = :outbound)
        target_class = dir == :outbound ? as_constant(_from_class) : as_constant(_to_class)
        ":`#{target_class.mapped_label_name}`)"
      end

      def as_constant(given_class)
        case given_class
        when String, Symbol
          given_class.to_s.constantize
        when Array
          fail "Relationship query methods are being deprecated and do not support Array (from|to)_class options. Current value: #{given_class}"
        else
          given_class
        end
      end

      def where_string(args)
        case args
        when Hash
          args.transform_keys { |key| key == :neo_id ? 'elementId(r1)' : "r1.#{key}" }
              .transform_values { |v| v.is_a?(Integer) ? v : "'#{v}'" }
              .map { |k, v| "#{k} = #{v}" }.join(', ')
        else
          args
        end
      end
    end
  end
end
