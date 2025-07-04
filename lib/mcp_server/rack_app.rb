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

        server_context = build_server_context(request, config)

        mcp_server = MCP::Server.new(
          name: "mcp_server",
          version: "0.1.0",
          tools: config.tools || [],
          prompts: config.prompts || [],
          resources: config.resources || [],
          server_context: server_context
        )

        if config.resources_read_handler
          mcp_server.resources_read_handler(&config.resources_read_handler)
        end

        response = nil
        if config.transport
          begin
            mcp_server.transport = config.transport.new(mcp_server)
            response = mcp_server.transport.handle_request(request)
          rescue NoMethodError
            # For version 0.1.0 and earlier, mcp_server.transport is not defined
            request.body.rewind if request.body.respond_to?(:rewind)
            json_response = mcp_server.handle_json(request.body.read)
            response = [200, {"Content-Type" => "application/json"}, [json_response.to_json]]
          end
        end

        response
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
