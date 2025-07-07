module McpServer
  class Configuration
    attr_accessor :authenticate_with, :build_context_with, :tools, :prompts, :resources, :resources_read_handler, :transport, :response_handler

    def initialize
      @authenticate_with = nil
      @build_context_with = nil
      @tools = nil
      @prompts = nil
      @resources = nil
      @resources_read_handler = nil
      @transport = nil
      @response_handler = nil
    end
  end
end
