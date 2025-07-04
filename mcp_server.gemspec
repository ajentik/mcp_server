Gem::Specification.new do |spec|
  spec.name = "mcp_server"
  spec.version = "0.1.0"
  spec.summary = "Pluggable, protocol-agnostic MCP server for Rack-based apps"
  spec.authors = ["Your Name"]
  spec.email = ["you@example.com"]
  spec.files = Dir["lib/**/*.rb"]
  spec.required_ruby_version = ">= 3.2.0"
  spec.homepage = "http://your-gem-homepage"
  spec.license = "MIT"

  spec.add_dependency "rack", "~> 2.0"
  spec.add_dependency "mcp", "~> 0.1"
end
