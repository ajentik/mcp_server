module McpServer
  class Configuration
    attr_accessor :authenticate_with, :build_context_with, :tools, :prompts, :resources

    def initialize
      @authenticate_with = nil
      @build_context_with = nil
      @tools = []
      @prompts = []
      @resources = []
    end
  end
end
