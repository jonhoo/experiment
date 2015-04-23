require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'
 
class TestErrors < ExperimentTestCase

	def initialize(test_method_name)
		super(test_method_name)
	end

	def test_allbadbuilds
		Dir.mktmpdir("test_", ".") {|d|
			build d
			@e["build"] = "exit 1"
			r = experiment d
			assert_false r

			ls = []
			File.open File.join(d, "stderr.log"), "r" do |f|
				f.each_line do |line|
					ls.push line
				end
			end
			assert_include ls.join(), "ERROR: no buildable version found"
		}
	end

	def test_onebadbuild
		@modc = <<eos
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char** argv) {
	I'm a bad file
}
eos
		Dir.mktmpdir("test_", ".") {|d|
			repo = build d

			ref = repo.references["refs/heads/master"]
			nref = mkcommit repo

			@e["versions"] = {"a" => {"checkout" => nref}, "b" => {"checkout" => ref.target_id}}
			r = experiment d
			assert_true r

			ls = []
			File.open File.join(d, "stderr.log"), "r" do |f|
				f.each_line do |line|
					ls.push line
				end
			end
			ls = ls.join

			assert_not_include ls, "ERROR: no buildable version found"
			assert_not_include ls, sprintf("Build clang -o test test.c at %s patched with [] failed", ref)
			assert_include ls, sprintf("Build clang -o test test.c at %s patched with [] failed", nref)
		}
	end

	def test_badrun
		@modc = <<eos
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char** argv) {
	exit(1);
}
eos
		Dir.mktmpdir("test_", ".") {|d|
			repo = build d
			ref = repo.references["refs/heads/master"]
			nref = mkcommit repo

			@e["versions"] = {"a" => {"checkout" => nref}, "b" => {"checkout" => ref.target_id}}
			r = experiment d
			assert_true r

			ls = []
			File.open File.join(d, "stderr.log"), "r" do |f|
				f.each_line do |line|
					ls.push line
				end
			end
			ls = ls.join
			assert_include ls, "Failed to run version a: process failed with "
			assert_not_include ls, "Failed to run version b:"
		}
	end

end
