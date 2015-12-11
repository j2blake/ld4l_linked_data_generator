=begin rdoc
--------------------------------------------------------------------------------

Grab some statistics from the triple-store.

--------------------------------------------------------------------------------
=end

module Ld4lLinkDataGenerator
  class Counts
    QUERY_COUNT_TRIPLES = <<-END
      SELECT (count(?s) as ?count)
      WHERE { 
        ?s ?p ?o .
      }
    END
    QUERY_COUNT_SUBJECTS = <<-END
      SELECT (count(distinct ?s) as ?count)
      WHERE { 
        ?s ?p ?o
      }
    END

    def initialize(ts)
      @ts = ts
      @name = ts.to_s
      @triples = run_query(QUERY_COUNT_TRIPLES)
      @subjects = run_query(QUERY_COUNT_SUBJECTS)
    end

    def run_query(q)
      query = QueryRunner.new(q)
      query.select(@ts).map { |row| row['count'] }[0]
    end

    def values
      {
        :name => @name,
        :triples => @triples,
        :subjects => @subjects,
      }
    end
  end
end
