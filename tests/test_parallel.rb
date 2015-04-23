require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'
 
class TestParallel < ExperimentTestCase

	def test_iterations
		@e["parallelism"] = 2
		@e["arguments"] = ["$SRC/test", "3000"]
		@e["versions"] = {"a" => {}, "b" => {}}
		Dir.mktmpdir("test_", ".") {|d|
			build d

			start = Time.now
			experiment d

			dur = Time.now - start
			assert_compare(dur, "<", 6)

			a = File.stat File.join(d, "out", "a", "run-1", "experiment.log")
			b = File.stat File.join(d, "out", "b", "run-1", "experiment.log")
			assert_in_delta(a.mtime.to_f, b.mtime.to_f, 1)
		}
	end

end
