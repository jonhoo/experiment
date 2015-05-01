require "test/unit"
require 'rugged'
require 'tmpdir'
require 'json'

class ExperimentTestCase < Test::Unit::TestCase

	def initialize(test_method_name)
		super(test_method_name)
		@c = <<eos
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char** argv) {
	usleep(atoi(argv[1])*1000);
	printf(\"slept %dms\\n\", atoi(argv[1]));
}
eos
		@modc = @c

		@e = {
			"experiment"  => "Run tests",
			"checkout"    => "master",
			"iterations"  => 1,
			"repository"  => "..",
			"parallelism" => 1,
			"keep-stdout" => true,
			"build"       => "clang -o test test.c",
			"arguments"   => [ "$SRC/test", "10" ],
			"versions"    => {
				"a" => {
				},
			}
		}
	end

	def build(dir)
		dir = File.absolute_path dir
		repo = Rugged::Repository.init_at(dir)
		oid = repo.write @c, :blob
		index = repo.index
		index.add(:path => "test.c", :oid => oid, :mode => 0100644)
		File.open File.join(dir, "test.c"), "w" do |f|
			f.write(@c)
		end

		options = {}
		options[:tree] = index.write_tree(repo)

		options[:author] = { :email => "test@example.com", :name => 'Test Author', :time => Time.now }
		options[:committer] = { :email => "test@example.com", :name => 'Test Author', :time => Time.now }
		options[:message] ||= "Add test.c"
		options[:parents] = []
		options[:update_ref] = 'HEAD'
		Rugged::Commit.create(repo, options)

		return repo
	end

	def experiment_out(dir, showerr, *args)
		dir = File.absolute_path dir
		File.open File.join(dir, "experiment.json"), "w" do |f|
			f.write(JSON.generate(@e))
		end

		exp = File.absolute_path File.join(File.dirname(__FILE__), "../bin/experiment")
		here = Dir.pwd
		Dir.chdir dir
		r = Kernel.system(exp, "--trace", "--output", File.join(dir, "out"), *args, :out=>File.join(dir, "stdout.log"), :err=>File.join(dir, "stderr.log"))
		Dir.chdir here
		if !r and showerr
			File.open err, "r" do |f|
				f.each_line do |line|
					puts line
				end
			end
			puts $?
		end
		return r
	end

	def experiment(dir, *args)
		return experiment_out(dir, true, *args)
	end

	def mkcommit(repo)
		oid = repo.write @modc, :blob
		index = repo.index
		index.read_tree(repo.head.target.tree)
		index.add(:path => "test.c", :oid => oid, :mode => 0100644)
		File.open File.join(repo.workdir, "test.c"), "w" do |f|
			f.write(@modc)
		end

		options = {}
		options[:tree] = index.write_tree(repo)

		options[:author] = { :email => "test@example.com", :name => 'Test Author', :time => Time.now }
		options[:committer] = { :email => "test@example.com", :name => 'Test Author', :time => Time.now }
		options[:message] ||= "Add test.c"
options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
		options[:update_ref] = 'HEAD'
		return Rugged::Commit.create(repo, options)
	end

	def test_build
		Dir.mktmpdir("test_", ".") {|d|
			build d
			assert_true(File.exist? File.join(d, ".git"))
			assert_true(File.exist? File.join(d, "test.c"))
			assert_true(File.directory? File.join(d, ".git"))

			ls = []
			File.open File.join(d, "test.c"), "r" do |f|
				f.each_line do |line|
					ls.push line
				end
			end
			assert_equal(@c, ls.join)
		}
	end

	def validate_run_dir(d, ms=10)
		assert_true(File.directory? d)
		assert_true(File.exist? File.join(d, "experiment.log"))
		assert_true(File.exist? File.join(d, "stdout.log"))
		assert_true(File.exist? File.join(d, "stderr.log"))

		ls = []
		File.open File.join(d, "stdout.log"), "r" do |f|
			f.each_line do |line|
				ls.push line
			end
		end
		assert_equal("slept " + ms.to_s + "ms\n", ls.join)
	end

	def test_run
		Dir.mktmpdir("test_", ".") {|d|
			build d
			assert_true(experiment d)
			assert_true(File.exist? File.join(d, "experiment.json"))
			assert_true(File.directory? File.join(d, "out", "a"))
			assert_true(File.exist? File.join(d, "out", "a", "build.log"))

			assert_true(File.directory? File.join(d, "out", "a", "source"))
			assert_true(File.exist? File.join(d, "out", "a", "source", "test.c"))

			validate_run_dir(File.join(d, "out", "a", "run-1"))
		}
	end
end
