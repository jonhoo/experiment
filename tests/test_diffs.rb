require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'
 
class TestCheckout < ExperimentTestCase

	def test_diff
		Dir.mktmpdir("test_", ".") {|d|
			build d
			File.open File.join(d, "test.diff"), "w" do |f|
				f.write("
--- a/test.c	2016-05-06 01:27:27.026820216 -0400
+++ b/test.c	2016-05-06 01:28:05.500052368 -0400
@@ -3,6 +3,7 @@
 #include <unistd.h>
 
 int main(int argc, char** argv) {
+	argv[1] = \"1\";
 	usleep(atoi(argv[1])*1000);
 	printf(\"slept %dms\\n\", atoi(argv[1]));
 }
")
			end

			@e["preserve"] = ["test.diff"]
			@e["versions"] = {"a" => {}, "b" => {
				"diffs" => ["test.diff"],
			}}
			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"))
			validate_run_dir(File.join(d, "out", "b", "run-1"), 1)
		}
	end

end
