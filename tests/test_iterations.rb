require 'experiment'
require 'test/unit'
require 'tmpdir'
 
class TestIterations < ExperimentTestCase

	def test_iterations
		@e["iterations"] = 3
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"))
			validate_run_dir(File.join(d, "out", "a", "run-2"))
			validate_run_dir(File.join(d, "out", "a", "run-3"))
		}
	end

end
