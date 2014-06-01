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

		def build
			commit = @repo.lookup(@version["checkout"] || @config["checkout"])

			pwd = Dir.pwd
			Dir.chdir @wd
			Dir.mkdir "source"
			Dir.chdir "source"
			Experiment::recreate_tree(@repo, commit)

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
		end

		def run(number)
			Dir.chdir @wd
			Dir.mkdir "run-#{number}"
			Dir.chdir "run-#{number}"
			args = @version["arguments"] || @config["arguments"]

			fork do
				args[0] = @wd + "/source/" + args[0]
				exec args[0], *args
			end

			Process.wait
		end
	end
end
