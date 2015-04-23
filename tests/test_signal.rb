require_relative './test_base'
require 'experiment'
require 'test/unit'
require 'tmpdir'
require 'json'
 
class TestSignal < ExperimentTestCase

	def test_sig
		["TERM", "INT"].each do |s|
			@e["arguments"] = ["$SRC/test", "5000"]
			@e["iterations"] = 10
			Dir.mktmpdir("test_", ".") {|d|
				build d

				d = File.absolute_path d
				File.open File.join(d, "experiment.json"), "w" do |f|
					f.write(JSON.generate(@e))
				end

				here = File.absolute_path Dir.pwd
				bin = File.absolute_path File.join(File.dirname(__FILE__), "../bin/experiment")
				Dir.chdir d
				pid = Kernel.spawn(bin, "--trace", "--output", File.join(d, "out"), :out => "/dev/null")
				Dir.chdir here

				Kernel.sleep 1

				killat = Time.now
				Process.kill(s, pid)
				Process.waitpid pid
				took = Time.now - killat

				assert_compare(took, "<", 1)
			}
		end
	end

end
