require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'

class TestCLI < ExperimentTestCase

	def test_repository
		Dir.mktmpdir("test_", ".") {|d|
			build d
			@e.delete "repository"
			experiment d, "--repository", File.absolute_path(d)
			validate_run_dir(File.join(d, "out", "a", "run-1"))
		}
	end

end
