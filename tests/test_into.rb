require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'
 
class TestInto < ExperimentTestCase

	def test_into
		Dir.mktmpdir("test_", ".") {|d|
			build d
			@e["into"] = "src/test"
			@e["build"] = "clang -o src/test/test src/test/test.c"
			@e["arguments"] = ["$SRC/src/test/test", "10"]
			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"))
			assert_false(File.exist? File.join(d, "out", "a", "source", "test"))
			assert_true(File.exist? File.join(d, "out", "a", "source", "src", "test", "test"))
		}
	end

end
