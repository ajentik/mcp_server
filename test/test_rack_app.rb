require "test_helper"
require "rack/mock"
require "mcp"

class TestRackApp < Minitest::Test
  def setup
    McpServer.configuration = McpServer::Configuration.new
  end

  def app
    McpServer::RackApp
  end

  def test_requires_post_method
    request = Rack::MockRequest.new(app)
    response = request.get("/")

    assert_equal 405, response.status
    body = JSON.parse(response.body)
    assert_equal "Method not allowed", body["error"]
  end

  def test_authentication_failure
    McpServer.configure do |config|
      config.authenticate_with = lambda { |_request| false }
    end

    request = Rack::MockRequest.new(McpServer::RackApp)

    mcp_request = {
      jsonrpc: "2.0",
      method: "ping",
      params: {},
      id: 1
    }.to_json

    response = request.post("/",
      :input => mcp_request,
      "CONTENT_TYPE" => "application/json")

    assert_equal 401, response.status
    body = JSON.parse(response.body)
    assert_equal "Unauthorized", body["error"]
  end

  def test_mcp_initialization_request
    request = Rack::MockRequest.new(app)

    mcp_request = {
      jsonrpc: "2.0",
      method: "initialize",
      params: {
        protocolVersion: "0.1.0",
        capabilities: {}
      },
      id: 1
    }

    response = request.post("/",
      :input => mcp_request.to_json,
      "CONTENT_TYPE" => "application/json")

    assert_equal 200, response.status
    body = JSON.parse(response.body)

    assert_equal "2.0", body["jsonrpc"]
    assert_equal 1, body["id"]
    assert body["result"]
    assert_equal "mcp_server", body["result"]["serverInfo"]["name"]
    assert_equal "0.1.0", body["result"]["serverInfo"]["version"]
  end

  def test_mcp_ping_request
    request = Rack::MockRequest.new(app)

    mcp_request = {
      jsonrpc: "2.0",
      method: "ping",
      params: {},
      id: 2
    }

    response = request.post("/",
      :input => mcp_request.to_json,
      "CONTENT_TYPE" => "application/json")

    assert_equal 200, response.status
    body = JSON.parse(response.body)

    assert_equal "2.0", body["jsonrpc"]
    assert_equal 2, body["id"]
    assert_equal({}, body["result"])
  end

  def test_with_custom_tool
    test_tool_class = Class.new(MCP::Tool) do
      tool_name "test_tool"
      description "A test tool"
      input_schema(
        properties: {
          message: {type: "string"}
        },
        required: ["message"]
      )

      def self.call(message:)
        MCP::Tool::Response.new(
          content: [
            MCP::Content.text("Echo: #{message}")
          ]
        )
      end
    end

    McpServer.configure do |config|
      config.tools = [test_tool_class]
    end

    request = Rack::MockRequest.new(McpServer::RackApp)

    list_request = {
      jsonrpc: "2.0",
      method: "tools/list",
      params: {},
      id: 3
    }

    response = request.post("/",
      :input => list_request.to_json,
      "CONTENT_TYPE" => "application/json")

    assert_equal 200, response.status
    body = JSON.parse(response.body)

    assert body["result"], "Expected 'result' in response"
    assert body["result"]["tools"], "Expected 'tools' in result"
    assert_equal 1, body["result"]["tools"].length
    assert_equal "test_tool", body["result"]["tools"][0]["name"]
  end

  def test_server_context_with_custom_context
    test_user = Struct.new(:id, :name).new(123, "Test User")
    context_received = nil

    test_tool_class = Class.new(MCP::Tool) do
      tool_name "context_test"
      description "Test tool to verify context"

      define_singleton_method(:call) do |server_context:|
        context_received = server_context
        MCP::Tool::Response.new(
          content: [MCP::Content.text("Context received")]
        )
      end
    end

    McpServer.configure do |config|
      config.build_context_with = lambda { |_request|
        {
          user: test_user,
          organization: {id: 456, name: "Test Org"},
          permissions: ["read", "write"],
          custom_data: "test"
        }
      }
      config.tools = [test_tool_class]
    end

    request = Rack::MockRequest.new(McpServer::RackApp)

    tool_call = {
      jsonrpc: "2.0",
      method: "tools/call",
      params: {
        name: "context_test",
        arguments: {}
      },
      id: 4
    }

    response = request.post("/",
      :input => tool_call.to_json,
      "CONTENT_TYPE" => "application/json")

    assert_equal 200, response.status

    assert context_received[:request], "Context should include request"
    assert_equal test_user, context_received[:user]
    assert_equal({id: 456, name: "Test Org"}, context_received[:organization])
    assert_equal(["read", "write"], context_received[:permissions])
    assert_equal "test", context_received[:custom_data]
  end

  def test_with_custom_prompt
    test_prompt_class = Class.new(MCP::Prompt) do
      def self.name_value
        "test_prompt"
      end

      def self.description_value
        "A test prompt"
      end

      def self.arguments_value
        [
          MCP::Prompt::Argument.new(
            name: "topic",
            description: "The topic to generate a prompt for",
            required: true
          )
        ]
      end

      def self.template(args, server_context:)
        MCP::Prompt::Result.new(
          messages: [
            MCP::Prompt::Message.new(
              role: "user",
              content: MCP::Content.text("Tell me about #{args[:topic]}")
            )
          ]
        )
      end
    end

    McpServer.configure do |config|
      config.prompts = [test_prompt_class]
    end

    request = Rack::MockRequest.new(McpServer::RackApp)

    list_request = {
      jsonrpc: "2.0",
      method: "prompts/list",
      params: {},
      id: 5
    }

    response = request.post("/",
      :input => list_request.to_json,
      "CONTENT_TYPE" => "application/json")

    assert_equal 200, response.status
    body = JSON.parse(response.body)

    assert body["result"], "Expected 'result' in response"
    assert body["result"]["prompts"], "Expected 'prompts' in result"
    assert_equal 1, body["result"]["prompts"].length
    assert_equal "test_prompt", body["result"]["prompts"][0]["name"]
  end

  def test_with_custom_resource
    test_resource = MCP::Resource.new(
      uri: "test://resource1",
      name: "Test Resource",
      description: "A test resource",
      mime_type: "text/plain"
    )

    McpServer.configure do |config|
      config.resources = [test_resource]
    end

    request = Rack::MockRequest.new(McpServer::RackApp)

    list_request = {
      jsonrpc: "2.0",
      method: "resources/list",
      params: {},
      id: 6
    }

    response = request.post("/",
      :input => list_request.to_json,
      "CONTENT_TYPE" => "application/json")

    assert_equal 200, response.status
    body = JSON.parse(response.body)

    assert body["result"], "Expected 'result' in response"
    assert body["result"]["resources"], "Expected 'resources' in result"
    assert_equal 1, body["result"]["resources"].length
    assert_equal "test://resource1", body["result"]["resources"][0]["uri"]
    assert_equal "Test Resource", body["result"]["resources"][0]["name"]
  end

  def test_with_resources_read_handler
    test_resource = MCP::Resource.new(
      uri: "test://resource1",
      name: "Test Resource",
      description: "A test resource",
      mime_type: "text/plain"
    )

    read_handler = lambda do |params|
      [{
        uri: params[:uri],
        mimeType: "text/plain",
        text: "Resource content for #{params[:uri]}"
      }]
    end

    McpServer.configure do |config|
      config.resources = [test_resource]
      config.resources_read_handler = read_handler
    end

    request = Rack::MockRequest.new(McpServer::RackApp)

    read_request = {
      jsonrpc: "2.0",
      method: "resources/read",
      params: {
        uri: "test://resource1"
      },
      id: 8
    }

    response = request.post("/",
      :input => read_request.to_json,
      "CONTENT_TYPE" => "application/json")

    assert_equal 200, response.status
    body = JSON.parse(response.body)
    assert_equal "2.0", body["jsonrpc"]
    assert_equal 8, body["id"]
    assert body["result"]["contents"]
    assert_equal 1, body["result"]["contents"].length
    assert_equal "test://resource1", body["result"]["contents"][0]["uri"]
    assert_equal "Resource content for test://resource1", body["result"]["contents"][0]["text"]
  end

  def test_with_transport_configuration
    transport_class = Class.new do
      attr_reader :server

      def initialize(server)
        @server = server
      end
    end

    McpServer.configure do |config|
      config.transport = transport_class
    end

    request = Rack::MockRequest.new(McpServer::RackApp)

    mcp_request = {
      jsonrpc: "2.0",
      method: "initialize",
      params: {},
      id: 7
    }

    response = request.post("/",
      :input => mcp_request.to_json,
      "CONTENT_TYPE" => "application/json")

    assert_equal 200, response.status
    body = JSON.parse(response.body)
    assert_equal "2.0", body["jsonrpc"]
    assert_equal 7, body["id"]
  end

  def test_error_handling
    request = Rack::MockRequest.new(app)

    response = request.post("/",
      :input => "invalid json",
      "CONTENT_TYPE" => "application/json")

    assert_equal 200, response.status
    body = JSON.parse(response.body)
    assert body["error"]
  end
end
