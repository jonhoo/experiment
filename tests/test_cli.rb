require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'

class TestCLI < ExperimentTestCase

	def test_version
		@e["iterations"] = 10
		@e["versions"] = {"a" => {}, "b" => {}, "c" => {}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d, "--single", "a"
			validate_run_dir(File.join(d, "out", "a", "run-1"))
			assert_false(File.exist? File.join(d, "out", "a", "run-2"))
			assert_false(File.exist? File.join(d, "out", "b"))
			assert_false(File.exist? File.join(d, "out", "c"))
		}
	end

	def test_repository
		Dir.mktmpdir("test_", ".") {|d|
			build d
			@e.delete "repository"
			experiment d, "--repository", File.absolute_path(d)
			validate_run_dir(File.join(d, "out", "a", "run-1"))
		}
	end

end
