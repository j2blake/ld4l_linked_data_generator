=begin rdoc
--------------------------------------------------------------------------------

Generate a group of files that contain all of the URIs that we want to serve as
LOD.

Start with a directory-tree of N-Triples files. Do each institution separately.
Assume that there are no URIs in common.

First: process each file, trimming each line to just the subject URI. Remove
any non-local URIs, sort and remove duplicates.

Next: do a successive operation merging batches of files until only one large
file remains.

Finally, split the big file into smaller segments.

--------------------------------------------------------------------------------

Usage: ld4l_list_uris <source_dir> <output_dir> [RESTART] <report_file> [REPLACE]

--------------------------------------------------------------------------------
=end

module Ld4lLinkDataGenerator
  module ListUris
    class ListUris
      USAGE_TEXT = 'Usage: ld4l_list_uris <source_dir> <output_dir> [OVERWRITE] <report_file> [REPLACE]'
      LOCAL_URI_PREFIX = 'http://ld4l.library.cornell.edu/'
#      LOCAL_URI_PREFIX = 'http://draft.ld4l.org/'
      MERGE_BATCH_SIZE = 100
      FINAL_FILE_SIZE = 1000000
      def process_arguments()
        args = ARGV
        @overwrite = args.delete('OVERWRITE')
        replace_report = args.delete('REPLACE')

        raise UserInputError.new(USAGE_TEXT) unless args && args.size == 3

        @source_dir = File.expand_path(args[0])
        raise UserInputError.new("#{args[0]} does not exist.") unless File.exist?(args[0])

        @output_dir = File.expand_path(args[1])
        raise UserInputError.new("#{args[1]} already exists -- specify OVERWRITE.") if File.exist?(args[1]) unless @overwrite
        raise UserInputError.new("Can't create #{args[1]}: no parent directory.") unless Dir.exist?(File.dirname(args[1]))

        raise UserInputError.new("#{args[2]} already exists -- specify REPLACE.") if File.exist?(args[2]) unless replace_report
        raise UserInputError.new("Can't create #{args[2]}: no parent directory.") unless Dir.exist?(File.dirname(args[2]))
        @report = Ld4lLinkDataGenerator::ListUris::Report.new('ld4l_list_uris', File.expand_path(args[2]))
        @report.log_header(args)
      end

      def prepare_target
        FileUtils.rm_r(@output_dir) if Dir.exist?(@output_dir)
        Dir.mkdir(@output_dir)
      end

      def first_pass
        @report.first_pass_start
        Find.find(@source_dir) do |path|
          if File.file?(path) && path.end_with?('.nt')
            process_first_pass_file(path)
          end
        end
        @report.first_pass_stop
      end

      def process_first_pass_file(path)
        @first_pass_dir = File.join(@output_dir, 'first_pass') 
        Dir.mkdir(@first_pass_dir) unless File.exist?(@first_pass_dir)
        new_filename = path[@source_dir.size..-1].gsub('/', '__')
        output_file = File.join(@first_pass_dir, new_filename)
        `awk '/^\\S*#{pattern_escape(LOCAL_URI_PREFIX)}/ { gsub(/[<>]/, "", $1); print $1}' #{path} | sort -u > #{output_file}`
        @report.first_pass_file(new_filename)
      end
      
      def merge_pass
=begin
        starting from the first_pass directory, merge up to 40 files at once, into the merge1 directory
        then from merge1, merge up to 40 files at once into the merge2 directory.
        when we only have one remaining file, note the path
=end
        logit ("BOGUS merge_pass")
      end
      
      def split
=begin
        create the sorted_split directory, split the files into it.
=end
        logit ("BOGUS split")
      end
      
      def report
        logit ("BOGUS REPORT")
      end
      
      def pattern_escape(string)
        string.gsub('/', '\\/').gsub('.', '\\.')
      end

      def run
        begin
          process_arguments
          prepare_target
          first_pass
          merge_pass
          split
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
end
