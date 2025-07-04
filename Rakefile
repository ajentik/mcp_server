# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/test_*.rb"]
  t.verbose = true
end

desc "Run tests"
task default: :test
