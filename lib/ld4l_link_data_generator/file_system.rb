=begin
Give it a root directory on initialization. If the directory doesn't exist, it will be created.

Find the path for a URI:
  If it starts with the magic prefix, remove it.
  get a hash of the remainder that is 4 hex digits.
    require 'zlib'
    Zlib.crc32 "hello world"
    => 222957957
  translate the remainder into a safe filename:
    ENCODE_REGEX = Regexp.compile("[\"*+,<=>?\\\\^|]|[^\x21-\x7e]", nil, 'u')
    def self.encode id
      id.gsub(ENCODE_REGEX) { |c| char2hex(c) }.tr('/:.', '=+,')
    end
    The path is root_path / hash12 / hash34 / safe_filename

Store a file
  mkdirs for path
  write to file.

Retrieve a file
  If file exists, read from file
=end
=begin
--------------------------------------------------------------------------------

Process one URI, fetching the relevant triples from the triple-store, recording
stats, and writing an N3 file.

--------------------------------------------------------------------------------
=end
require "zlib"

module Ld4lLinkDataGenerator
  class FileSystem
    def initialize(root_dir, prefix)
      @root_dir = root_dir
      Dir.mkdir(@root_dir) unless Dir.exist?(@root_dir)

      @prefix = prefix
    end

    def path()
      @root_dir
    end

    def acceptable?(uri)
      uri.start_with?(@prefix)
    end

    def exist?(uri)
      begin
        File.exist?(path_for(uri))
      rescue
        bogus "Failed a check for existence of '#{uri}': #{$!}\n    #{$!.backtrace.join('\n    ')}"
        false
      end
    end

    def path_for(uri)
      begin
        name = remove_prefix(uri)
        hash1, hash2 = hash_it(name)
        safe_name = encode(name)
        File.join(@root_dir, hash1, hash2, safe_name)
      rescue
        bogus "Failed to build a path for '#{uri}': #{$!}\n    #{$!.backtrace.join('\n    ')}"
      end
    end

    def remove_prefix(uri)
      if uri.start_with?(@prefix)
        uri[@prefix.size..-1]
      else
        uri
      end
    end

    def hash_it(name)
      hash = Zlib.crc32(name).to_s(16)
      [hash[-4, 2], hash[-2, 2]]
    end

    ENCODE_REGEX = Regexp.compile("[\"*+,<=>?\\\\^|]|[^\x21-\x7e]", nil)

    def encode(name)
      name.gsub(ENCODE_REGEX) { |c| char2hex(c) }.tr('/:.', '=+,')
    end
  end
end
