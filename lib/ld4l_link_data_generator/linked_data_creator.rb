=begin rdoc
--------------------------------------------------------------------------------

Generate files of Linked Open Data from the triple-store, for the LOD server.
The files are created in a PairTree directory, in N3 format. When servicing a
request, the server will read the file into a graph, add document triples, and
serialize it to the requested format.

--------------------------------------------------------------------------------

Usage: ld4l_create_lod_files <target_dir> [RESTART] <report_file> [REPLACE] <pairtree_prefix>

--------------------------------------------------------------------------------
=end

module Ld4lLinkDataGenerator
  class LinkedDataCreator
    USAGE_TEXT = 'Usage: ld4l_create_lod_files <target_dir> [RESTART] <report_file> [REPLACE] <pairtree_prefix>'
    BATCH_SIZE = 1000
    def process_arguments(args)
      @restart = args.delete('RESTART')
      replace_report = args.delete('REPLACE')

      raise UserInputError.new(USAGE_TEXT) unless args && args.size == 3

      @pair_tree_base = File.expand_path(args[0])

      raise UserInputError.new("#{args[1]} already exists -- specify REPLACE") if File.exist?(args[1]) unless replace_report
      raise UserInputError.new("Can't create #{args[1]}: no parent directory.") unless Dir.exist?(File.dirname(args[1]))
      @report = Report.new('ld4l_create_lod_files', File.expand_path(args[1]))
      @report.log_header(args)

      @pairtree_prefix = args[2]
    end

    def connect_triple_store
      selected = TripleStoreController::Selector.selected
      raise UserInputError.new("No triple store selected.") unless selected

      TripleStoreDrivers.select(selected)
      @ts = TripleStoreDrivers.selected

      raise IllegalStateError.new("#{@ts} is not running") unless @ts.running?
      @report.logit("Connected to triple-store: #{@ts}")
    end

    def connect_pairtree
      @files = Pairtree.at(@pair_tree_base, :prefix => @pairtree_prefix, :create => true)
      @report.logit("Connected to pairtree at #{@pair_tree_base}")
    end

    def initialize_bookmark
      @bookmark = Bookmark.new(@files, @restart)
    end

    def trap_control_c
      @interrupted = false
      trap("SIGINT") do
        @interrupted = true
      end
    end

    def iterate_through_uris
      uris = UriDiscoverer.new(@ts, @bookmark, BATCH_SIZE, @report)

      puts "Beginning processing. Press ^c to interrupt."
      uris.each do |uri|
        if @interrupted
          process_interruption
          break
        else
          begin
            UriProcessor.new(@ts, @files, @report, uri).run
          rescue
            process_exception
            break
          end
        end
      end
      @report.summarize(@bookmark, :complete)
      @report.logit("Complete")
    end

    def process_interruption
      @bookmark.persist
      @report.summarize(@bookmark, :interrupted)
    end

    def process_exception
      @bookmark.persist
      @report.summarize(@bookmark, :exception)
    end

    def place_void_files
      source_dir = File.expand_path('../../void',__FILE__)
      Dir.chdir(source_dir) do |dir|
        Dir.foreach('.') do |filename|
          FileUtils.cp(filename, @pair_tree_base) if filename.start_with? 'void'
        end
      end
    end

    def report
      @report.stats
    end

    def setup()
      process_arguments(ARGV)
      connect_triple_store
      connect_pairtree
      initialize_bookmark
      trap_control_c
    end

    def run
      begin
        setup
        iterate_through_uris
        place_void_files
        report
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
