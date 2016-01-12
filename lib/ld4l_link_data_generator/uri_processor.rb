=begin
--------------------------------------------------------------------------------

Process one URI, fetching the relevant triples from the triple-store, recording
stats, and writing an N3 file.

--------------------------------------------------------------------------------
=end

require "ruby-xxhash"

module Ld4lLinkDataGenerator
  class UriProcessor
    QUERY_OUTGOING_PROPERTIES = <<-END
    CONSTRUCT {
      ?uri ?p ?o
    }
    WHERE { 
      ?uri ?p ?o . 
    }
    END

    QUERY_OUTGOING_TYPES = <<-END
    CONSTRUCT { 
      ?o a ?type . 
    }
    WHERE {
      ?uri ?p ?o .
      ?o a ?type . 
    }
    END

    QUERY_OUTGOING_LABELS = <<-END
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    CONSTRUCT { 
      ?o rdfs:label ?label . 
    }
    WHERE {
      ?uri ?p ?o .
      ?o rdfs:label ?label . 
    }
    END

    QUERY_INCOMING_PROPERTIES = <<-END
    CONSTRUCT {
      ?s ?p ?uri
    }
    WHERE { 
      ?s ?p ?uri . 
    }
    END

    QUERY_INCOMING_TYPES = <<-END
    CONSTRUCT { 
      ?s a ?type . 
    }
    WHERE {
      ?s ?p ?uri .
      ?s a ?type . 
    }
    END

    QUERY_INCOMING_LABELS = <<-END
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    CONSTRUCT { 
      ?s rdfs:label ?label . 
    }
    WHERE {
        ?s ?p ?uri .
        ?s rdfs:label ?label . 
    }
    END
    def initialize(ts, files, report, uri)
      @ts = ts
      @files = files
      @report = report
      @uri = uri
    end

    def uri_is_acceptable
      @uri.start_with?(@files.prefix)
    end

    def build_the_graph
      @graph = RDF::Graph.new
      @graph << QueryRunner.new(QUERY_OUTGOING_PROPERTIES).bind_uri('uri', @uri).construct(@ts)
      @graph << QueryRunner.new(QUERY_OUTGOING_TYPES).bind_uri('uri', @uri).construct(@ts)
      @graph << QueryRunner.new(QUERY_OUTGOING_LABELS).bind_uri('uri', @uri).construct(@ts)
      @graph << QueryRunner.new(QUERY_INCOMING_PROPERTIES).bind_uri('uri', @uri).construct(@ts)
      @graph << QueryRunner.new(QUERY_INCOMING_TYPES).bind_uri('uri', @uri).construct(@ts)
      @graph << QueryRunner.new(QUERY_INCOMING_LABELS).bind_uri('uri', @uri).construct(@ts)
    end

    def write_it_out
      hashed = hash_of(@uri)
      path = @files.path_for(hashed) + ".ttl"
      FileUtils.makedirs(File.dirname(path))
      RDF::Writer.open(path) do |writer|
        writer << @graph
      end
    end
    
    def hash_of(value)
      Digest::XXHash.new(64).digest(value).to_s(16)
    end

    def run()
      begin
        if (uri_is_acceptable)
          build_the_graph
          write_it_out
          @report.wrote_it(@uri, @graph)
        else
          @report.bad_uri(@uri)
        end
      rescue
        @report.uri_failed(@uri, $!)
      end
    end
  end
end
