=begin rdoc
--------------------------------------------------------------------------------

For now, just try to figure out how many LOD files we will generate.

--------------------------------------------------------------------------------

Usage: ld4l_estimate_time_to_generate

--------------------------------------------------------------------------------
=end

module Ld4lLinkDataGenerator
  class Estimator

    BATCH_SIZE = 5000
    REPORT_INTERVAL = 20 # batches

    QUERY_URIS = <<-END
      SELECT DISTINCT ?uri
      WHERE { 
        ?uri ?p ?o . 
      }
    END

    attr_reader :found
    attr_reader :how_many
    attr_reader :offset
    def connect_triple_store
      selected = TripleStoreController::Selector.selected
      raise UserInputError.new("No triple store selected.") unless selected

      TripleStoreDrivers.select(selected)
      @ts = TripleStoreDrivers.selected

      raise IllegalStateError.new("#{@ts} is not running") unless @ts.running?
    end

    def iterate_through_uris
      @found = -1
      while found != 0
        @found = find_uris()
        report_progress() if time_to_report?
      end
    end

    def find_uris()
      query = "%s OFFSET %d LIMIT %d" % [QUERY_URIS, @offset, BATCH_SIZE]
      result = QueryRunner.new(query).select(@ts)
      @offset += BATCH_SIZE
      @found = result.size
    end

    def time_to_report?
      0 == @offset % (REPORT_INTERVAL * BATCH_SIZE)
    end

    def report_progress()
      time = Time.new.strftime('%Y-%m-%d %H:%M:%S') 
      puts("%s Find URIs:, offset: %d, found: %d" % [time, @offset, @found])
    end

    def run
      begin
        @found = 0
        @how_many = 0
        @offset = 0

        connect_triple_store
        iterate_through_uris

        report_progress()
      rescue UserInputError, IllegalStateError
        puts
        puts "ERROR: #{$!}"
        puts
      ensure
        @report.close if @report
      end
    end
  end
end
