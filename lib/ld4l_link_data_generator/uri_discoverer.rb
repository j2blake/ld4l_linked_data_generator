=begin
--------------------------------------------------------------------------------

Repeatedly get bunches of URIs from the list files. Dispense them one at a time.

As each new file is opened, persist the bookmark.

--------------------------------------------------------------------------------
=end

module Ld4lLinkDataGenerator
  class UriDiscoverer
    def initialize(ts, source_dir, bookmark, report)
      @ts = ts
      @source_dir = source_dir
      @bookmark = bookmark
      @report = report
    end

    def each()
      Dir.chdir(@source_dir) do |d|
        Dir.entries(d).sort.each do |fn|
          next if skipping_to_bookmark(fn)
          next if invalid_file(fn)
          @bookmark.next_file(fn)
          @report.next_file(fn)

          File.foreach(fn) do |line|
            line_number = $.
            uri = line.split(' ')[0]
            yield uri
            @report.record_uri(uri, line_number, fn)
          end
        end
      end
      @bookmark.clear
    end

    def skipping_to_bookmark(fn)
      if @bookmark.filename.empty?
        false
      else
        @bookmark.filename > fn
      end
    end
    
    def invalid_file(fn)
      fn.start_with?('.') || File.directory?(fn)
    end
  end
end