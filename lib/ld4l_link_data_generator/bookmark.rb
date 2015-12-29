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
        @filename, @offset = load
      else
        @filename = ''
        @offset = 0
        persist
      end

      @start = map_it
    end

    def load()
      File.open(@path) do |f|
        map = JSON.load(f, nil, :symbolize_names => true)
        return map.values_at(:filename, :offset)
      end
    end

    def persist()
      File.open(@path, 'w') do |f|
        JSON.dump(map_it, f)
      end
    end

    def map_it
      {:filename => @filename, :offset => @offset}
    end

    def next_file(filename)
      @offset = 0
      @filename = filename
      persist
    end
    
    def set_offset(offset)
      @offset = offset
      persist
    end

    def clear()
      File.delete(@path)
    end
  end
end