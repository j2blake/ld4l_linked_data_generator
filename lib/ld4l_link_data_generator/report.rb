=begin
--------------------------------------------------------------------------------

Write the report to a file, and to the console.
Repeatedly get bunches of URIs for Agents, Instances, and Works. Dispense them
one at a time.

The query should return the uris in ?uri, and should not contain an OFFSET or
LIMIT, since they will be added here.

Increments the offset in the bookmark, and periodically writes it to disk.
Clears it at the end.

--------------------------------------------------------------------------------
=end

module Ld4lLinkDataGenerator
  class Report
    attr_reader :bad_uri_count
    attr_reader :good_uri_count
    attr_reader :triples_count

    def initialize(main_routine, path)
      @main_routine = main_routine
      @file = File.open(path, 'w')
      
      @bad_uri_count = 0
      @good_uri_count = 0
      @triples_count = 0
      @largest_graph = 0
      @smallest_graph = 0
      @uri_of_largest_graph = "NO URIs"
      @uri_of_smallest_graph = "NO URIs"
    end

    def logit(message)
      m = "#{Time.new.strftime('%Y-%m-%d %H:%M:%S')} #{message}"
      puts m
      @file.puts m
    end

    def log_header(args)
      logit "#{@main_routine} #{args.join(' ')}"
    end

    def record_counts(counts)
      logit "%{name}: %{triples} triples, %{subjects} subjects." % counts.values
    end

    def wrote_it(uri, graph)
      #  Something that the URI processor will do.
      @good_uri_count += 1
      @triples_count += graph.count
      if graph.count > @largest_graph
        @largest_graph = graph.count
        @uri_of_largest_graph = uri
      end
      if graph.count < @smallest_graph || @good_uri_count == 1
        @smallest_graph = graph.count
        @uri_of_smallest_graph = uri
      end
    end

    def bad_uri(uri)
      @bad_uri_count += 1
    end

    def summarize(bookmark, status)
      first = bookmark.start_offset
      last = bookmark.offset
      how_many = last - first
      if status == :complete
        logit("Generated for URIs from offset %d to %d: processed %d URIs." % [first, last, how_many])
      elsif status == :interrupted
        logit("Interrupted with offset %d -- started at %d: processed %d URIs." % [last, first, how_many])
      else
        logit("Error with offset %d -- started at %d: processed %d URIs.  \n%s  \n%s" % [last, first, how_many, $!.inspect, $!.backtrace.join("\n")])
      end
    end

    def stats()
      message = "Valid URIs: %d, Invalid URIs %d, Triples: %d" % [@good_uri_count, @bad_uri_count, @triples_count]
      if (@good_uri_count > 0)
        average_size = @triples_count / @good_uri_count
        message << "\nAverage graph size: %d, " % [average_size]
        message << "\n   smallest: %d (%s), " % [@smallest_graph, @uri_of_smallest_graph]
        message << "\n    largest: %d (%s)" % [@largest_graph, @uri_of_largest_graph]
      end
      logit(message)
    end

    def close()
      @file.close if @file
    end
  end
end
