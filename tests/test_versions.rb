require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'
 
class TestVersions < ExperimentTestCase

	def test_versions
		@e["versions"] = {"a" => {}, "b" => {}, "c" => {}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"))
			validate_run_dir(File.join(d, "out", "b", "run-1"))
			validate_run_dir(File.join(d, "out", "c", "run-1"))
		}
	end

	def test_version_args
		@e["versions"] = {"a" => {}, "b" => {"arguments" => ["$SRC/test", "20"]}, "c" => {"arguments" => ["$SRC/test", "30"]}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"))
			validate_run_dir(File.join(d, "out", "b", "run-1"), 20)
			validate_run_dir(File.join(d, "out", "c", "run-1"), 30)
		}
	end

	def test_version_diffs
		Dir.mktmpdir("test_", ".") {|d|
			d = File.absolute_path d

			@e["versions"] = {"a" => {}, "b" => {"diffs" => [File.join(d, "b.patch")]}, "c" => {"diffs" => [File.join(d, "c.patch")]}}
			build d

			File.open File.join(d, "b.patch"), "w" do |f|
				f.write <<eos
diff --git a/test.c b/test.c
index 35f4693..686fb0f 100644
--- a/test.c
+++ b/test.c
@@ -3,6 +3,7 @@
 #include <unistd.h>
 
 int main(int argc, char** argv) {
+\targv[1] = "20";
 \tusleep(atoi(argv[1])*1000);
 \tprintf("slept %dms\\n", atoi(argv[1]));
 }
eos
			end
			File.open File.join(d, "c.patch"), "w" do |f|
				f.write <<eos
diff --git a/test.c b/test.c
index 35f4693..686fb0f 100644
--- a/test.c
+++ b/test.c
@@ -3,6 +3,7 @@
 #include <unistd.h>
 
 int main(int argc, char** argv) {
+\targv[1] = "30";
 \tusleep(atoi(argv[1])*1000);
 \tprintf("slept %dms\\n", atoi(argv[1]));
 }
eos
			end

			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"))
			validate_run_dir(File.join(d, "out", "b", "run-1"), 20)
			validate_run_dir(File.join(d, "out", "c", "run-1"), 30)
		}
	end

end
