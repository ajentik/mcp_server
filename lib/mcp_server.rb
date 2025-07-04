require_relative "mcp_server/configuration"
require_relative "mcp_server/rack_app"

module McpServer
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end
  end
end
