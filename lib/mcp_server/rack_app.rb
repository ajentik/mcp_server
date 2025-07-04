require "json"
require "rack"
require "mcp"

module McpServer
  class RackApp
    class << self
      def call(env)
        request = Rack::Request.new(env)
        config = McpServer.configuration

        if config.authenticate_with && !config.authenticate_with.call(request)
          return [401, {"Content-Type" => "application/json"}, [{error: "Unauthorized"}.to_json]]
        end

        unless request.post?
          return [405, {"Content-Type" => "application/json"}, [{error: "Method not allowed"}.to_json]]
        end

        server_context = build_server_context(request, config)

        mcp_server = MCP::Server.new(
          name: "mcp_server",
          version: "0.1.0",
          tools: config.tools || [],
          prompts: config.prompts || [],
          resources: config.resources || [],
          server_context: server_context
        )

        response = mcp_server.handle_json(request.body.read)

        [200, {"Content-Type" => "application/json"}, [response]]
      rescue => e
        [500, {"Content-Type" => "application/json"}, [{error: e.message}.to_json]]
      end

      private

      def build_server_context(request, config)
        context = {request: request}

        if config.build_context_with
          custom_context = config.build_context_with.call(request)
          context.merge!(custom_context) if custom_context.is_a?(Hash)
        end

        context
      end
    end
  end
end
