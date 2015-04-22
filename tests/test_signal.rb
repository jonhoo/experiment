require 'experiment'
require 'test/unit'
require 'tmpdir'
require 'json'
 
class TestSignal < ExperimentTestCase

	def test_sigterm
		@e["arguments"] = ["$SRC/test", "5"]
		Dir.mktmpdir("test_", ".") {|d|
			build d

			d = File.absolute_path d
			File.open File.join(d, "experiment.json"), "w" do |f|
				f.write(JSON.generate(@e))
			end

			here = Dir.pwd
			Dir.chdir d
			pid = Kernel.spawn(File.join(File.dirname(__FILE__), "../bin/experiment"), "--output", File.join(d, "out"), :out=>"/dev/null")
			Dir.chdir here

			Kernel.sleep 1

			killat = Time.now
			Process.kill("TERM", pid)
			Process.waitpid pid
			took = Time.now - killat

			assert_compare(took, "<", 1)
		}
	end

	def test_sigint
		@e["arguments"] = ["$SRC/test", "5"]
		Dir.mktmpdir("test_", ".") {|d|
			build d

			d = File.absolute_path d
			File.open File.join(d, "experiment.json"), "w" do |f|
				f.write(JSON.generate(@e))
			end

			here = Dir.pwd
			Dir.chdir d
			pid = Kernel.spawn(File.join(File.dirname(__FILE__), "../bin/experiment"), "--output", File.join(d, "out"), :out=>"/dev/null")
			Dir.chdir here

			Kernel.sleep 1

			killat = Time.now
			Process.kill("INT", pid)
			Process.waitpid pid
			took = Time.now - killat

			assert_compare(took, "<", 1)
		}
	end

end
