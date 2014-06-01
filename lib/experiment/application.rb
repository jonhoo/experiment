require "digest"

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
			commit = @repo.rev_parse(@version["checkout"] || @config["checkout"])

			pwd = Dir.pwd
			Dir.chdir @wd

			log = File.open "experiment.log", "w"
			log.write "Commit: #{commit.oid}\n"
			log.write "Parent commits: #{commit.parent_oids}\n"
			log.write "Committed at: #{commit.time}\n"

			arghashes = []
			(@version["arguments"] || @config["arguments"]).each_with_index do |a, i|
				if File.exists? a
					arghashes << "\targ[#{i}] = #{a} has hash #{Digest::SHA2.file(a).hexdigest}\n"
				end
			end
			if not arghashes.empty?
				log.write "\nFile argument hashes:\n"
				arghashes.each { |e| log.write e }
			end

			if not @version["diffs"].nil?
				for p in @version["diffs"] do
					log.write "\n"
					f = File.open p.gsub("~", Dir.home)
					log.write f.read
					f.close
				end
			end
			log.close

			Dir.mkdir "source"
			Dir.chdir "source"
			Experiment::recreate_tree(@repo, commit)

			if not @version["diffs"].nil?
				for p in @version["diffs"] do
					# git apply ...
					if system("/usr/bin/patch", "-Np1", "-i", p.gsub("~", Dir.home)).nil?
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
