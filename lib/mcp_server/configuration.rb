module McpServer
  class Configuration
    attr_accessor :authenticate_with, :build_context_with, :tools, :prompts, :resources, :resources_read_handler, :transport

    def initialize
      @authenticate_with = nil
      @build_context_with = nil
      @tools = []
      @prompts = []
      @resources = []
      @resources_read_handler = nil
      @transport = nil
    end
  end
end
