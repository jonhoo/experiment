require "digest"
require "colorize"
require "fileutils"

module Experiment
	@@proceed = true
	def self.stop
		@@proceed = false
	end
	def self.stopped
		@@proceed == false
	end

	class Application
		attr_reader :build

		def initialize(options = {})
			@wd = options[:wd]
			@config = options[:config]
			@version = options[:version]
			@repo = options[:repo]
			@args = @version["arguments"]
			@args[0].sub!(/^~/, Dir.home)
			@args.map! {|arg|
				Experiment.substitute(
					arg,
					{"SRC" => File.join(@wd, "source")}
				)
			}
			@build = Build.new(@repo, @version["build"], @version["checkout"], @version["diffs"])
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


			t = Thread.new() do
				while not Experiment.stopped
					Kernel.sleep 1
				end
				Process.kill("TERM", pid)
			end
			_, res = Process.waitpid2 pid
			t.terminate

			finish = Time.now

			ok = res.success?
			if res.stopsig.to_i == 15 or res.exitstatus.to_i == 143
				# SIGTERM is ok given that we sent it
				ok = true
			end

			if ok
				log.write finish.strftime("Finished at %s (%FT%T%:z)\n")
			else
				log.write sprintf(finish.strftime("Failed with %%s at %s (%FT%T%:z)\n"), res)
			end

			duration = finish - start
			log.write "Took #{duration}s\n"
			log.close

			if not ok
				raise "process failed with #{res}"
			end
		end
	end
end
