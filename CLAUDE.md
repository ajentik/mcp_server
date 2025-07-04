# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview
This is a Ruby gem called `mcp_server` that provides a configurable Rack-based MCP (Model-Context-Protocol) server. It's designed to be pluggable and protocol-agnostic, allowing developers to integrate MCP functionality into their Rack-based applications.

## Common Commands

### Testing
```bash
# Run all tests
bundle exec rake test
# or simply
bundle exec rake

# Run a specific test file
ruby -Ilib:test test/test_configuration.rb
```

### Linting
```bash
# Run StandardRB for Ruby style checking
standardrb
```

### Building the Gem
```bash
# Build the gem
gem build mcp_server.gemspec

# Install locally for testing
gem install ./mcp_server-0.1.0.gem
```

## Architecture

### Core Components
1. **MCP Server Configuration** (`lib/mcp_server/configuration.rb`): Central configuration object that stores callbacks for authentication, user resolution, and tool resolution. Uses a DSL pattern for easy setup.

2. **Rack Application** (`lib/mcp_server/rack_app.rb`): The main entry point for HTTP requests. Implements the request/response cycle:
   - Authenticates requests using the configured callback
   - Resolves users and tools
   - Returns JSON responses


### Key Design Patterns
- **Callback-based Configuration**: The gem uses callbacks (procs) for authentication and resolution logic, allowing users to plug in their own implementations
- **Rack Middleware Pattern**: Built as a Rack application, making it compatible with any Ruby web framework
- **Dependency Injection**: Callbacks are injected through configuration

### Integration Points
When integrating this gem:
1. Configure authentication logic via `MCPServer.configure { |c| c.authenticate_with { |request| ... } }`
2. Set up user and tool resolution callbacks
3. Mount the Rack app in your application (e.g., in Rails routes or config.ru)

## Testing Approach
The gem uses Minitest with `rack/mock` for simulating HTTP requests. Tests are organized by component and focus on configuration behavior.

## Code Style Guidelines
When writing code, do not add unnecessary comments.
