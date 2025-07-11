# mcp_server

A pluggable, protocol-agnostic MCP (Model-Context-Protocol) server for
Rack-based Ruby applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mcp_server'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install mcp_server
```

## Usage

### Basic Configuration

Configure the MCP server with your authentication logic and MCP components
(tools, prompts, resources):

```ruby
require 'mcp_server'
require 'mcp'

# Define your MCP tools
class CalculatorTool < MCP::Tool
  tool_name "calculator"
  description "Performs basic arithmetic operations"
  input_schema(
    properties: {
      operation: { type: "string", enum: ["add", "subtract", "multiply", "divide"] },
      a: { type: "number" },
      b: { type: "number" }
    },
    required: ["operation", "a", "b"]
  )

  def self.call(operation:, a:, b:, server_context:)
    # Access context data in your tool
    user = server_context[:user]
    permissions = server_context[:permissions]
    
    # Your tool logic here
    result = case operation
    when "add" then a + b
    when "subtract" then a - b
    when "multiply" then a * b
    when "divide" then b != 0 ? a / b : "Error: Division by zero"
    end
    
    MCP::Tool::Response.new(
      content: [MCP::Content.text("Result: #{result}")]
    )
  end
end

# Configure the server
MCPServer.configure do |config|
  # Define how to authenticate requests (optional)
  config.authenticate_with do |request|
    # Your authentication logic here
    # Return true/false or raise an error
    request.env['HTTP_AUTHORIZATION'] == 'Bearer secret-token'
  end

  # Define how to build the server context (optional)
  config.build_context_with do |request|
    # Return a hash with any context data your tools need
    {
      user: User.find_by_token(request.env['HTTP_AUTHORIZATION']),
      organization: Organization.from_request(request),
      permissions: Permission.for_request(request),
      locale: request.env['HTTP_ACCEPT_LANGUAGE'],
      custom_data: "any other context you need"
    }
  end

  # Configure MCP components (as callables for dynamic loading)
  config.tools = -> { [CalculatorTool] }
  config.prompts = -> { [] }  # Add your MCP::Prompt classes here
  config.resources = -> { [] } # Add your MCP::Resource instances here

  # Refer to https://github.com/modelcontextprotocol/ruby-sdk?tab=readme-ov-file#resources
  # for more details on how to define resources
  config.resources_read_handler do |request_params|
    # Handle resource read requests
    resource = Resource.find_by_id(request_params['id'])
    [{
      uri: request_params[:uri],
      mimeType: 'application/json',
      text: resource.to_json
    }]
  end

  # Only when using the MCP gem's version after commit hash 382ae13
  # https://github.com/modelcontextprotocol/ruby-sdk/commit/382ae13e25ba095fbe227b186b3287c3c7eb7ff4
  config.transport = MCP::Server::Transports::StdioTransport

  # Define a response handler to modify responses (optional)
  config.response_handler do |response, request|
    # Modify response headers, status, or body
    status, headers, body = response
    headers['X-Custom-Header'] = 'Modified'

    # Disable SSE (Server-Sent Events) by removing the session ID header
    # headers.delete('Mcp-Session-Id')

    [status, headers, body]
  end
end
```

### Server-Sent Events (SSE) and Multi-Process Servers

**Important:** The current SSE implementation requires keeping stream objects in memory. This means SSE will not work correctly with multi-process servers (like Unicorn, Puma in clustered mode, or Passenger) because:

- Stream objects are stored in the process that handles the initial request
- Subsequent requests may be routed to different processes that don't have access to these streams
- This results in failed SSE connections when requests are handled by different processes

**Solutions:**
1. Use a single-process, multi-threaded server (e.g., Puma in single mode with multiple threads)
2. Disable SSE by removing the `Mcp-Session-Id` header in the response handler (see example above)

### Mounting in a Rack Application

#### In a Rails application

Add to your `config/routes.rb`:

```ruby
mount MCPServer::RackApp => '/mcp'
```

#### In a Sinatra application

```ruby
require 'sinatra'
require 'mcp_server'

# Configure MCPServer...

use MCPServer::RackApp
```

#### In a plain Rack application (config.ru)

```ruby
require 'mcp_server'

# Configure MCPServer...

run MCPServer::RackApp
```

## Development

After checking out the repo, run `bundle install` to install dependencies.

### Running Tests

```bash
# Run all tests
rake test

# Run a specific test file
ruby -Ilib:test test/test_configuration.rb
```

### Linting

This project uses StandardRB for Ruby style guidelines:

```bash
standardrb
```

### Building the Gem

```bash
gem build mcp_server.gemspec
```

## Architecture

The gem follows a modular architecture:

- **Configuration**: Central configuration object that stores:
  - Authentication callback (optional)
  - Context building callback (optional) - builds server context passed to tools
  - Callables that return arrays of MCP tools, prompts, and resources (for dynamic loading)
  - Response handler callback (optional) - for modifying responses before sending
- **RackApp**: Main Rack application that:
  - Handles HTTP requests with JSON-RPC payloads (supports all HTTP methods)
  - Performs authentication if configured
  - Creates an MCP::Server instance with configured components
  - Delegates request handling to the MCP gem or configured transport
  - Handles various response body types (nil, string, array, object)
- **MCP Integration**: Leverages the official MCP Ruby SDK for protocol compliance

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
