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

  # Configure MCP components
  config.tools = [CalculatorTool]
  config.prompts = []  # Add your MCP::Prompt classes here
  config.resources = [] # Add your MCP::Resource instances here
end
```

### Mounting in a Rack Application

#### In a Rails application

Add to your `config/routes.rb`:

```ruby
mount MCPServer::RackApp.new => '/mcp'
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

run MCPServer::RackApp.new
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
  - Arrays of MCP tools, prompts, and resources
- **RackApp**: Main Rack application that:
  - Handles HTTP POST requests with JSON-RPC payloads
  - Performs authentication if configured
  - Creates an MCP::Server instance with configured components
  - Delegates request handling to the MCP gem
- **MCP Integration**: Leverages the official MCP Ruby SDK for protocol compliance

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
