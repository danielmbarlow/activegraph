module ActiveGraph
  module Core
    module Instrumentable
      extend ActiveSupport::Concern

      EMPTY = ''
      NEWLINE_W_SPACES = "\n  "

      class_methods do
        def subscribe_to_request
          ActiveSupport::Notifications.subscribe('neo4j.core.bolt.request') do |_, start, finish, _id, _payload|
            ms = (finish - start) * 1000
            yield " #{ANSI::BLUE}BOLT:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR}"
          end
        end

        def subscribe_to_query
          ActiveSupport::Notifications.subscribe('neo4j.core.cypher_query') do |_, _start, _finish, _id, payload|
            query = payload[:query]
            params_string = (query.parameters && !query.parameters.empty? ? "| #{query.parameters.inspect}" : EMPTY)
            cypher = query.pretty_cypher ? (NEWLINE_W_SPACES if query.pretty_cypher.include?("\n")).to_s + query.pretty_cypher.gsub(/\n/, NEWLINE_W_SPACES) : query.cypher

            source_line, line_number = Logging.first_external_path_and_line(caller_locations)

            yield " #{ANSI::CYAN}#{query.context || 'CYPHER'}#{ANSI::CLEAR} #{cypher} #{params_string}" +
              ("\n   ↳ #{source_line}:#{line_number}" if ActiveGraph::Config.fetch(:verbose_query_logs, false) && source_line).to_s
          end
        end
      end
    end
  end
end
