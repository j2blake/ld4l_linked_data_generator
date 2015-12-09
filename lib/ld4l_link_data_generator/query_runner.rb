=begin

Provide a way to bind variables in a query, and to execute the query.
Execution is through either select() or construct().

For a SELECT query, the triple-store must return a JSON-formatted response. The
select() method will parse that and return an array of hashes.

Example:
[
  {'p' => 'http://first/predicate', 'o' => 'http://first/object' },
  {'p' => 'http://second/predicate', 'o' => 'http://second/object' }
]

For a CONSTRUCT query, the triple-store must return NTriples. The construct()
method will return an RDF:Graph containing the results.

=end

module Ld4lLinkDataGenerator
  class QueryRunner
    def initialize(query)
      @initial_query = String.new(query)
      @query = String.new(query)
    end

    def bind_uri(varname, value)
      @query.gsub!(Regexp.new("\\?#{varname}\\b"), "<#{value}>")
      self
    end

    def bind_literal(varname, value)
    end

    def select(ts)
      result = nil
      ts.sparql_query(@query) do |resp|
        result = parse_response(resp)
      end
      result
    end

    def parse_response(resp)
      JSON.parse(resp.body)['results']['bindings'].map do |row|
        parse_row(row)
      end
    end

    def parse_row(row)
      Hash[row.map { |k, v| [k, v['value']] }]
    end

    def construct(ts)
      result = nil
      ts.sparql_query(@query, 'text/plain') do |resp|
        result = RDF::Graph.new << RDF::Reader.for(:ntriples).new(resp.body)
      end
      result
    end
  end
end
