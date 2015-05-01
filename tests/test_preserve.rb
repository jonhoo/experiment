require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'
 
class TestPreserve < ExperimentTestCase

	def test_no_preserve
		Dir.mktmpdir("test_", ".") {|d|
			Dir.mkdir File.join(d, "static")
			File.open File.join(d, "static", "test.dat"), 'w' do |f|
				f.write("n=20;")
			end

			build d
			experiment d
			assert_false(File.exist? File.join(d, "out", "a", "source", "static", "test.dat"))
		}
	end

	def test_preserve
		Dir.mktmpdir("test_", ".") {|d|
			Dir.mkdir File.join(d, "static")
			File.open File.join(d, "static", "test.dat"), 'w' do |f|
				f.write("n=20;")
			end

			build d
			@e["preserve"] = ["static/test.dat"]
			experiment d

			assert_true(File.exist? File.join(d, "out", "a", "source", "static", "test.dat"))
		}
	end

end
