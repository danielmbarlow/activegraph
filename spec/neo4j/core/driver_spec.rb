require 'spec_helper'
require 'neo4j/core/driver'
require 'neo4j/driver'

def port
  URI(ENV['NEO4J_URL']).port
end

describe Neo4j::Core::Driver do
  let(:url) { ENV['NEO4J_URL'] }

  # let(:driver) { Neo4j::Core::Adaptors::Driver.new(url, logger_level: Logger::DEBUG) }
  let(:driver) { TestDriver.new(url) }

  after(:context) do
    # Neo4j::Core::DriverRegistry.instance.close_all
  end

  subject { driver }

  describe '#initialize' do
    let_context(url: 'url') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: :symbol) { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 123) { subject_should_raise ArgumentError, /Invalid URL/ }

    let_context(url: "http://localhost:#{port}") { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: "http://foo:bar@localhost:#{port}") { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: "https://localhost:#{port}") { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: "https://foo:bar@localhost:#{port}") { subject_should_raise ArgumentError, /Invalid URL/ }

    let_context(url: 'bolt://foo@localhost:') { port == '7687' ? subject_should_not_raise : subject_should_raise }
    let_context(url: "bolt://:foo@localhost:#{port}") { subject_should_not_raise }

    let_context(url: "bolt://localhost:#{port}") { subject_should_not_raise }
    let_context(url: "bolt://foo:bar@localhost:#{port}") { subject_should_not_raise }
  end
end