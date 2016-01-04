=begin rdoc
--------------------------------------------------------------------------------

Maintain a bookmark file at the root of the PairTree structure.

--------------------------------------------------------------------------------
=end

module Ld4lLinkDataGenerator
  class Bookmark
    attr_reader :filename
    attr_reader :offset
    attr_reader :start
    def initialize(process_id, pairtree, restart)
      bookmark_path = "bookmark_linked_data_generator_#{process_id}.json"
      @path = File.expand_path(bookmark_path, pairtree.path)

      if File.exist?(@path) && !restart
        load
      else
        reset
        persist
      end

      @start = map_it
    end

    def load()
      File.open(@path) do |f|
        map = JSON.load(f, nil, :symbolize_names => true)
        @filename = map[:filename] || ''
        @offset = map[:offset] || 0
        @complete = map[:complete] || false
      end
    end

    def reset
      @filename = ''
      @offset = 0
      @complete = false
    end

    def persist()
      File.open(@path, 'w') do |f|
        JSON.dump(map_it, f)
      end
    end

    def map_it
      {:filename => @filename, :offset => @offset, :complete => @complete}
    end

    def update(filename, offset)
      @offset = offset
      @filename = filename
      persist
    end

    def set_offset(offset)
      @offset = offset
      persist
    end

    def complete()
      @complete = true
      persist
    end

    def complete?
      @complete
    end

    def clear()
      File.delete(@path)
    end
  end
end