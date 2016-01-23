=begin rdoc
--------------------------------------------------------------------------------

Generate files of Linked Open Data from the triple-store, for the LOD server. 
The files are created in a nested directory structure, in TTL format. When 
servicing a request, the server will read the file into a graph, add document 
triples, and serialize it to the requested format.

--------------------------------------------------------------------------------

Usage: ld4l_create_lod_files <source_dir> <target_dir> [RESTART] <report_file> [REPLACE] <uri_prefix>

--------------------------------------------------------------------------------
=end

module Ld4lLinkDataGenerator
  class LinkedDataCreator
    USAGE_TEXT = 'Usage: ld4l_create_lod_files <source_dir> <target_dir> [RESTART] <report_file> [REPLACE] <uri_prefix>'
    def process_arguments()
      args = Array.new(ARGV)
      @restart = args.delete('RESTART')
      replace_report = args.delete('REPLACE')

      raise UserInputError.new(USAGE_TEXT) unless args && args.size == 4

      raise UserInputError.new("#{args[0]} doesn't exist.") unless File.exist?(args[0])
      @source_dir = File.expand_path(args[0])

      @file_system_base = File.expand_path(args[1])

      raise UserInputError.new("#{args[2]} already exists -- specify REPLACE") if File.exist?(args[2]) unless replace_report
      raise UserInputError.new("Can't create #{args[2]}: no parent directory.") unless Dir.exist?(File.dirname(args[2]))
      @report = Report.new('ld4l_create_lod_files', File.expand_path(args[2]))
      @report.log_header(ARGV)

      @uri_prefix = args[3]
    end

    def connect_triple_store
      selected = TripleStoreController::Selector.selected
      raise UserInputError.new("No triple store selected.") unless selected

      TripleStoreDrivers.select(selected)
      @ts = TripleStoreDrivers.selected

      raise IllegalStateError.new("#{@ts} is not running") unless @ts.running?
      @report.logit("Connected to triple-store: #{@ts}")
    end

    def connect_file_system
      @files = FileSystem.new(@file_system_base, @uri_prefix)
      @report.logit("Connected to file system at #{@file_system_base}")
    end

    def initialize_bookmark
      @bookmark = Bookmark.new(File.basename(@source_dir), @files, @restart)
      @report.log_bookmark(@bookmark)
    end

    def trap_control_c
      @interrupted = false
      trap("SIGINT") do
        @interrupted = true
      end
    end

    def iterate_through_uris
      puts "Beginning processing. Press ^c to interrupt."
      @uris = UriDiscoverer.new(@ts, @source_dir, @bookmark, @report)
      @uris.each do |uri|
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
          FileUtils.cp(filename, @file_system_base) if filename.start_with? 'void'
        end
      end
    end

    def report
      @report.stats
    end

    def setup()
      process_arguments
      connect_triple_store
      connect_file_system
      initialize_bookmark
      trap_control_c
#
#      @report.record_counts(Counts.new(@ts))
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
