require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'
 
class TestOutput < ExperimentTestCase

	def initialize(test_method_name)
		super(test_method_name)
		@modc = <<eos
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char** argv) {
	fprintf(stdout, "stdout");
	fprintf(stderr, "stderr");
}
eos
	end

	def test_nokeepstdout
		Dir.mktmpdir("test_", ".") {|d|
			repo = build d
			mkcommit repo

			@e["keep-stdout"] = false
			experiment d

			d = File.join(d, "out", "a", "run-1")
			assert_false(File.exist? File.join(d, "stdout.log"))
			assert_true(File.exist? File.join(d, "stderr.log"))
			ls = []
			File.open File.join(d, "stderr.log"), "r" do |f|
				f.each_line do |line|
					ls.push line
				end
			end
			assert_equal("stderr", ls.join)
		}
	end

	def test_keepstdout
		Dir.mktmpdir("test_", ".") {|d|
			repo = build d
			mkcommit repo

			@e["keep-stdout"] = true
			experiment d

			d = File.join(d, "out", "a", "run-1")
			assert_true(File.exist? File.join(d, "stdout.log"))
			assert_true(File.exist? File.join(d, "stderr.log"))
			ls = []
			File.open File.join(d, "stderr.log"), "r" do |f|
				f.each_line do |line|
					ls.push line
				end
			end
			assert_equal("stderr", ls.join)
			ls = []
			File.open File.join(d, "stdout.log"), "r" do |f|
				f.each_line do |line|
					ls.push line
				end
			end
			assert_equal("stdout", ls.join)
		}
	end

end
