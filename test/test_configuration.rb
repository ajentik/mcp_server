require "test_helper"

class TestConfiguration < Minitest::Test
  def setup
    @config = McpServer::Configuration.new
  end

  def test_authenticate_with_set
    block = ->(req) { true }
    @config.authenticate_with = block
    assert_equal block, @config.authenticate_with
  end

  def test_build_context_with_set
    block = ->(req) { {user: {id: 1}, org: "test"} }
    @config.build_context_with = block
    assert_equal block, @config.build_context_with
  end

  def test_tools_set
    tool = Object.new
    @config.tools = [tool]
    assert_equal [tool], @config.tools
  end

  def test_prompts_set
    prompt = Object.new
    @config.prompts = [prompt]
    assert_equal [prompt], @config.prompts
  end

  def test_resources_set
    resource = Object.new
    @config.resources = [resource]
    assert_equal [resource], @config.resources
  end

  def test_resources_read_handler_set
    handler = ->(params) { [{uri: params[:uri], text: "test"}] }
    @config.resources_read_handler = handler
    assert_equal handler, @config.resources_read_handler
  end

  def test_transport_set
    transport_class = Class.new
    @config.transport = transport_class
    assert_equal transport_class, @config.transport
  end
end
