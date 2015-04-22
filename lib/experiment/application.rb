require "digest"
require "colorize"
require "fileutils"

module Experiment
	class Application
		attr_reader :build

		def initialize(options = {})
			@wd = options[:wd]
			@config = options[:config]
			@version = options[:version]
			@repo = options[:repo]
			@args = (@version["arguments"] || @config["arguments"]).dup
			@args[0].sub!(/^~/, Dir.home)
			@args.map! {|arg|
				Experiment.substitute(
					arg,
					{"SRC" => File.join(@wd, "source")}
				)
			}
			@build = Build.new(@repo,
							   @version["build"] || @config["build"],
							   @version["checkout"] || @config["checkout"],
							   @version["diffs"])
		end

		def copy_build(vname, dir)
			if File.exist? @wd
				raise "Version #{vname} directory already exists"
			end
			FileUtils.cp_r dir, @wd
			puts "--> Source for version '#{vname}' ready".green
		end

		def run(number)
			Dir.chdir @wd
			Dir.mkdir "run-#{number}"
			Dir.chdir "run-#{number}"

			# Record an experiment log with the hashes of any input files
			# passed on the command line.
			log = File.open "experiment.log", "w"
			log.write "Running #{@args}\n"
			arghashes = []
			@args.each_with_index do |a, i|
				if File.file? a
					arghashes << "\targ[#{i}] = #{a} has hash #{Digest::SHA2.file(a).hexdigest}\n"
				end
			end
			if not arghashes.empty?
				log.write "File argument hashes:\n"
				arghashes.each { |e| log.write e }
			end

			start = Time.now
			log.write start.strftime("Started at %s (%FT%T%:z)\n")
			pid = spawn(*@args,
				:out => @config["keep-stdout"] ? "stdout.log" : "/dev/null",
				:err => "stderr.log")

			Fiber.new {
				while Thread.current.thread_variable_get(:proceed)
					Kernel.sleep 1
				end
				Process.kill("TERM", pid)
			}
			Process.waitpid pid
			Thread.current.thread_variable_set(:proceed, false)

			finish = Time.now
			log.write finish.strftime("Finished at %s (%FT%T%:z)\n")
			duration = finish - start
			log.write "Took #{duration}s\n"
			log.close
		end
	end
end
