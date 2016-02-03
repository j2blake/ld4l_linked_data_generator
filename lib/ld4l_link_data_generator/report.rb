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
    attr_reader :failed_uri_count
    attr_reader :good_uri_count
    attr_reader :triples_count
    class MultiIO
      def initialize(*targets)
        @targets = targets
      end

      def write(*args)
        @targets.each {|t| t.write(*args)}
      end

      def flush()
        @targets.each(&:flush)
      end

      def close
        @targets.each(&:close)
      end
    end

    def initialize(main_routine, path)
      @main_routine = main_routine
      
      @file = File.open(path, 'w')
      @file.sync = true
      $stdout = MultiIO.new($stdout, @file)
      $stderr = MultiIO.new($stderr, @file)

      @bad_uri_count = 0
      @failed_uri_count = 0
      @good_uri_count = 0
      @triples_count = 0
      @largest_graph = 0
      @smallest_graph = 0
      @uri_of_largest_graph = "NO URIs"
      @uri_of_smallest_graph = "NO URIs"

      @current_filename = 'NO FILE'
      @current_line_number = 0
      
      reset_consistent_failure_count
    end

    def logit(message)
      puts "#{Time.new.strftime('%Y-%m-%d %H:%M:%S')} #{message}"
    end

    def log_header(args)
      logit "#{@main_routine} #{args.join(' ')}"
    end

    def log_bookmark(bookmark)
      if bookmark.filename.empty? && !bookmark.complete?
        logit "No bookmark: starting from the beginning."
      elsif bookmark.complete?
        logit "Bookmark says we already completed this process."
      else
        logit "Starting from the bookmark: filename=%s, offset=%d" % [bookmark.filename, bookmark.offset]
      end
    end

    def next_file(filename)
      logit("Opening file: " + filename)
      @current_filename = filename
      @current_line_number = 0
    end
    
    def start_at_bookmark(filename, line)
      logit("Starting at line #{line} in #{filename}")
    end

    def record_uri(uri, line_number, filename)
      @current_line_number = line_number
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
      reset_consistent_failure_count
      announce_progress
    end

    def bad_uri(uri)
      @bad_uri_count += 1
      check_for_consistent_failure
      announce_progress
    end

    def uri_failed(uri, e)
      @failed_uri_count += 1
      logit("URI failed: '#{uri}' #{e}")
      check_for_consistent_failure
      announce_progress
    end

    def reset_consistent_failure_count
      @consistent_failure_count = 0
    end
    
    def check_for_consistent_failure
      @consistent_failure_count += 0
      raise "Too many consistent failures" if @consistent_failure_count >= 5
    end
    
    def announce_progress
      count = @bad_uri_count + @failed_uri_count + @good_uri_count
      logit("Processed #{count} URIs.") if 0 == count % 1000
    end

    def nothing_to_do
      logit("The bookmark says that processing is complete.")
    end

    def summarize(bookmark, status)
      first = bookmark.start[:filename]
      first = 'FIRST' if first.empty?
      last = bookmark.filename
      how_many = @bad_uri_count + @failed_uri_count + @good_uri_count
      if status == :complete
        logit("Generated for URIs from %s to %s: processed %d URIs." % [first, last, how_many])
      elsif status == :interrupted
        logit("Interrupted in file %s -- started at %s: processed %d URIs." % [last, first, how_many])
      else
        logit("Error in file %s -- started at %s: processed %d URIs.  \n%s  \n%s" % [last, first, how_many, $!.inspect, $!.backtrace.join("\n")])
      end
    end

    def stats()
      message = "Valid URIs: %d, Invalid URIs %d, Failed URIs %d, Triples: %d" % [@good_uri_count, @bad_uri_count, @failed_uri_count, @triples_count]
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
