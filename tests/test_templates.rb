require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'
 
class TestTemplates < ExperimentTestCase

	def test_vary_set
		@e["versions"] = {"$letter" => {"vary" => {"letter" => "set(a, b, c)"}}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d

			validate_run_dir(File.join(d, "out", "a", "run-1"))
			validate_run_dir(File.join(d, "out", "b", "run-1"))
			validate_run_dir(File.join(d, "out", "c", "run-1"))
		}
	end

	def test_vary_set_brackets
		@e["versions"] = {"x${letter}x" => {"vary" => {"letter" => "set(a, b, c)"}}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d
			validate_run_dir(File.join(d, "out", "xax", "run-1"))
			validate_run_dir(File.join(d, "out", "xbx", "run-1"))
			validate_run_dir(File.join(d, "out", "xcx", "run-1"))
		}
	end

	def test_vary_set_multiple
		@e["versions"] = {"x-$letter-$letter" => {"vary" => {"letter" => "set(a, b, c)"}}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d
			validate_run_dir(File.join(d, "out", "x-a-a", "run-1"))
			validate_run_dir(File.join(d, "out", "x-b-b", "run-1"))
			validate_run_dir(File.join(d, "out", "x-c-c", "run-1"))
		}
	end

	def test_vary_global_args
		@e["arguments"] = ["$SRC/test", "$time"]
		@e["versions"] = {
			"sleep-$time" => {
				"vary" => {"time" => "set(10, 20)"},
			}
		}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d
			validate_run_dir(File.join(d, "out", "sleep-10", "run-1"))
			validate_run_dir(File.join(d, "out", "sleep-20", "run-1"), 20)
		}
	end

	def test_vary_range_args
		@e["versions"] = {
			"sleep-$time" => {
				"vary" => {"time" => "range(10, 31, 10)"},
				"arguments" => ["$SRC/test", "$time"]
			}
		}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d
			validate_run_dir(File.join(d, "out", "sleep-10", "run-1"))
			validate_run_dir(File.join(d, "out", "sleep-20", "run-1"), 20)
			validate_run_dir(File.join(d, "out", "sleep-30", "run-1"), 30)
		}
	end

	def test_vary_cmd_l
		@e["versions"] = {"$letter" => {"vary" => {"letter" => "cmd_l(echo -ne \"a\nb b\nc\")"}}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d

			validate_run_dir(File.join(d, "out", "a", "run-1"))
			validate_run_dir(File.join(d, "out", "b b", "run-1"))
			validate_run_dir(File.join(d, "out", "c", "run-1"))
		}
	end

	def test_vary_cmd
		@e["versions"] = {"$letter" => {"vary" => {"letter" => "cmd(find * -type f -print0)"}}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d

			validate_run_dir(File.join(d, "out", "test.c", "run-1"))
			validate_run_dir(File.join(d, "out", "experiment.json", "run-1"))
			validate_run_dir(File.join(d, "out", "stdout.log", "run-1"))
			validate_run_dir(File.join(d, "out", "stderr.log", "run-1"))
		}
	end

	def test_version_diffs
		Dir.mktmpdir("test_", ".") {|d|
			d = File.absolute_path d

			@e["versions"] = {"a" => {}, "$letter" => {"vary" => {"letter" => "set(b,c)"}, "diffs" => [File.join(d, "$letter.patch")]}}
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

	def test_vary_dupe
		@e["versions"] = {"$letter" => {"vary" => {"letter" => "set(a)", "number" => "set(1, 2)"}}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			r = experiment_out d, false
			assert_false r

			assert_false(File.exist? File.join(d, "out"))

			ls = []
			File.open File.join(d, "stderr.log"), "r" do |f|
				f.each_line do |line|
					ls.push line
				end
			end
			assert_include ls.join(), "Found multiple definitions for version a"
		}
	end

end
