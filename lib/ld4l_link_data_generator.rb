$LOAD_PATH.unshift File.expand_path('../../../triple_store_drivers/lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../../triple_store_controller/lib', __FILE__)
require 'triple_store_drivers'
require 'triple_store_controller'

require 'fileutils'
require 'find'
require 'rdf'
require 'rdf/raptor'

require "ld4l_link_data_generator/bookmark"
require "ld4l_link_data_generator/counts"
require "ld4l_link_data_generator/file_system"
require "ld4l_link_data_generator/linked_data_creator"
require "ld4l_link_data_generator/list_uris/list_uris"
require "ld4l_link_data_generator/list_uris/report"
require "ld4l_link_data_generator/query_runner"
require "ld4l_link_data_generator/report"
require "ld4l_link_data_generator/uri_discoverer"
require "ld4l_link_data_generator/uri_processor"
require "ld4l_link_data_generator/version"

def pattern_escape(string)
  string.gsub('/', '\\/').gsub('.', '\\.')
end

module Kernel
  def bogus(message)
    puts(">>>>>>>>>>>>>BOGUS #{message}")
  end
end

module Ld4lLinkDataGenerator
  # You screwed up the calling sequence.
  class IllegalStateError < StandardError
  end

  # What did you ask for?
  class UserInputError < StandardError
  end
end
