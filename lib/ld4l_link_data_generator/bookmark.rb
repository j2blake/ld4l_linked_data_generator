=begin rdoc
--------------------------------------------------------------------------------

Maintain a bookmark file at the root of the PairTree structure.

--------------------------------------------------------------------------------
=end

module Ld4lLinkDataGenerator
  class Bookmark
    FILE_NAME = "bookmark_linked_data_creator.json"

    attr_reader :offset
    attr_reader :start_offset
    def initialize(pairtree, restart)
      @path = File.expand_path(FILE_NAME, pairtree.path)

      if File.exist?(@path) && !restart
        @offset = load
      else
        @offset = 0
        persist
      end

      @start_offset = @offset
    end

    def load()
      File.open(@path) do |f|
        map = JSON.load(f, nil, :symbolize_names => true)
        map[:offset]
      end
    end

    def persist()
      File.open(@path, 'w') do |f|
        map = {:offset => @offset}
        JSON.dump(map, f)
      end
    end
    
    def increment()
      @offset += 1
    end
    
    def clear()
      File.delete(@path)
    end
  end
end