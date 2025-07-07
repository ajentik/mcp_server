# frozen_string_literal: true

require "rake/testtask"
require "standard/rake"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/test_*.rb"]
  t.verbose = true
end

desc "Run tests"
task default: [:lint, :test]

desc "Run standardrb with auto-fix"
task :lint do
  require "standard"
  Standard::Cli.new(["--fix"]).run
end
