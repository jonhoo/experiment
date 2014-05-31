module Experiment
	class Application
		@wd
		@config
		@version
		@repo

		def initialize(options = {})
			@wd = options[:wd]
			@config = options[:config]
			@version = options[:version]
			@repo = options[:repo]
		end

		def run(number)
			pwd = Dir.pwd
			Dir.chdir @config["repository"]
			@repo.reset(@version["checkout"] || @config["checkout"], :hard)

			if not @version["diffs"].nil?
				for p in @version["diffs"] do
					# git apply ...
					if system("/usr/bin/patch", "-Np1", p).nil?
						raise "Patch " + p + " could not be applied"
					end
				end
			end

			if system(@version["build"] || @config["build"]).nil?
				raise "Build failed"
			end
			Dir.chdir pwd

			fork do
				Dir.chdir @wd
				Dir.mkdir "run-#{number}"
				Dir.chdir "run-#{number}"
				args = @version["arguments"] || @config["arguments"]
				args[0] = @config["repository"] + "/" + args[0]

				if fork.nil?
					exec args[0], *args
				end
				Process.wait

				puts "#{@wd}##{number} completed"
				# TODO: Tell someone we've finished
			end
		end
	end
end
