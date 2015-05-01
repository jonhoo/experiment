require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'

class TestCLI < ExperimentTestCase

	def test_single
		@e["iterations"] = 10
		@e["versions"] = {"a" => {}, "b" => {}, "c" => {}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			experiment d, "--single", "a"
			validate_run_dir(File.join(d, "out", "a", "run-1"))
			assert_false(File.exist? File.join(d, "out", "a", "run-2"))
			assert_false(File.exist? File.join(d, "out", "b"))
			assert_false(File.exist? File.join(d, "out", "c"))
		}
	end

	def test_repository
		Dir.mktmpdir("test_", ".") {|d|
			build d
			@e.delete "repository"
			experiment d, "--repository", File.absolute_path(d)
			validate_run_dir(File.join(d, "out", "a", "run-1"))
		}
	end

	def test_list
		@e["versions"] = {"$letter" => {"vary" => {"letter" => "set(a, b, c)"}}}
		Dir.mktmpdir("test_", ".") {|d|
			build d
			@e.delete "repository"
			experiment d, "--list"
			assert_false(File.exist? File.join(d, "out"))

			vs = []
			File.open File.join(d, "stdout.log"), 'r' do |f|
				f.each_line do |l| vs.push l.strip end
			end
			assert_equal(3, vs.length)
			assert_include(vs, 'a')
			assert_include(vs, 'b')
			assert_include(vs, 'c')
		}
	end

end
