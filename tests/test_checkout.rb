require 'experiment'
require 'test/unit'
require 'tmpdir'
 
class TestCheckout < ExperimentTestCase

	def initialize(test_method_name)
		super(test_method_name)
		@modc = <<eos
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char** argv) {
	argv[1] = "1";
	usleep(atoi(argv[1])*1000);
	printf(\"slept %dms\\n\", atoi(argv[1]));
}
eos
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

	def test_checkout_commit
		Dir.mktmpdir("test_", ".") {|d|
			repo = build d

			ref = repo.references["refs/heads/master"]
			mkcommit repo

			@e["checkout"] = ref.target_id
			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"))
		}
		Dir.mktmpdir("test_", ".") {|d|
			repo = build d

			@e["checkout"] = mkcommit repo
			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"), 1)
		}
	end

	def test_checkout_branch
		Dir.mktmpdir("test_", ".") {|d|
			repo = build d

			repo.branches.create("testbranch", "HEAD")
			mkcommit repo

			@e["checkout"] = "testbranch"
			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"))
		}
		Dir.mktmpdir("test_", ".") {|d|
			repo = build d

			repo.branches.create("testbranch", "HEAD")
			mkcommit repo

			@e["checkout"] = "master"
			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"), 1)
		}
	end

	def test_version_checkout
		Dir.mktmpdir("test_", ".") {|d|
			repo = build d

			ref = repo.references["refs/heads/master"]
			mkcommit repo

			@e["versions"] = {"a" => {}, "b" => {"checkout" => ref.target_id}}
			experiment d
			validate_run_dir(File.join(d, "out", "a", "run-1"), 1)
			validate_run_dir(File.join(d, "out", "b", "run-1"))
		}
	end

end
