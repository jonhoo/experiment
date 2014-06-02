require "digest"
require "colorize"
require "fileutils"

module Experiment
	class Application
		@wd
		@config
		@version
		@repo
		@args

		def initialize(options = {})
			@wd = options[:wd]
			@config = options[:config]
			@version = options[:version]
			@repo = options[:repo]
			@args = (@version["arguments"] || @config["arguments"])
			@args.each_with_index do |a, i|
				if a.match(/^~\//)
					@args[i] = Dir.home + a.gsub(/^~/, '')
				end
			end
		end

		def build(vname)
			commit = @repo.rev_parse(@version["checkout"] || @config["checkout"])

			pwd = Dir.pwd
			Dir.chdir @wd

			log = File.open "experiment.log", "w"
			log.write "Commit: #{commit.oid}\n"
			log.write "Parent commits: #{commit.parent_oids}\n"
			log.write "Committed at: #{commit.time}\n"

			arghashes = []
			@args.each_with_index do |a, i|
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
					f = File.open File.expand_path p
					log.write f.read
					f.close
				end
			end
			log.close

			Dir.mkdir "source"
			Dir.chdir "source"

			puts "==> Preparing source for version '#{vname}'".bold

			puts " -> Recreating source tree".blue
			Experiment::recreate_tree(@repo, commit)

			if not @version["diffs"].nil?
				puts " -> Applying patches".cyan
				for p in @version["diffs"] do
					# git apply ...
					puts "  - #{p}".cyan
					if system("/usr/bin/patch", "-Np1", "-i", File.expand_path(p)).nil?
						raise "Patch " + p + " could not be applied"
					end
				end
			end

			if File.exists? ".gitmodules"
				puts " -> Initializing submodules".magenta
				Rugged::Repository.init_at Dir.pwd

				File.open(".gitmodules", 'rb').each do |line|
					if line.match "path ="
						p = line.gsub(/^\s*path = (.*)\s*$/, '\1')
						next
					end
					if line.match "url ="
						u = line.gsub(/^\s*url = (.*)\s*$/, '\1')
						system("/usr/bin/git", "submodule", "add", u, p)
					end
				end
				FileUtils.rmtree [".git", ".gitmodules"]
			end

			puts " -> Building application".yellow
			if system(@version["build"] || @config["build"]).nil?
				raise "Build failed"
			end

			puts " -> Application version ready".green

			Dir.chdir pwd
		end

		def run(number)
			Dir.chdir @wd
			Dir.mkdir "run-#{number}"
			Dir.chdir "run-#{number}"

			fork do
				@args[0] = @wd + "/source/" + @args[0]
				exec @args[0], *@args,
					:out => @config["keep-stdout"] ? "stdout.log" : "/dev/null",
					:err => "stderr.log"
			end

			Process.wait
		end
	end
end
