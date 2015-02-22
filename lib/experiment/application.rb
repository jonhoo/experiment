require "digest"
require "colorize"
require "fileutils"

module Experiment
	# Substitute variables into s in the manner of environment variables. If
	# var => val in variables, then $var and ${var} will be replaced by val in
	# s. $key will be unaffected if key is not in variables, unlike shell
	# environment variable substitution.
	def self.substitute(s, variables)
		s.gsub(/\$([a-zA-Z_]+[a-zA-Z0-9_]*)|\$\{(.+?)\}/) {
			key = $1 || $2
			variables.fetch(key, $&)
		}
	end

	class Build
		attr_reader :command
		attr_reader :checkout
		attr_reader :diffs
		def initialize(repo, command, checkout, diffs)
			@repo = repo
			@command = command
			@checkout = checkout
			@diffs = diffs || []
		end

		def build(wd)
			commit = @repo.rev_parse(@checkout)

			pwd = Dir.pwd
			Dir.chdir wd

			# Record a build log with information about the commit being built
			log = File.open "build.log", "w"
			log.write "Commit: #{commit.oid}\n"
			log.write "Parent commits: #{commit.parent_oids}\n"
			log.write "Committed at: #{commit.time}\n"

			# Add the text of the diffs to the build log
			for p in @diffs do
				log.write "\n"
				f = File.open File.expand_path p
				log.write f.read
				f.close
			end
			log.close

			Dir.mkdir "source"
			Dir.chdir "source"

			puts "==> Preparing source for build of '#{@checkout}'".bold

			puts " -> Recreating source tree".blue
			Experiment::recreate_tree(@repo, commit)

			if not @diffs.empty?
				puts " -> Applying patches".cyan
				for p in @diffs do
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
			if system(@command).nil?
				raise "Build failed"
			end

			Dir.chdir pwd
		end


		def ==(o)
			o.class == self.class and
				o.state == self.state
		end

		alias_method :eql?, :==
		def hash
			state.hash
		end

		def to_s
			"Build #{@command} at #{@checkout} patched with #{@diffs}"
		end

		protected
		def state
			[@command, @checkout, @diffs]
		end
	end

	class Application
		@wd
		@config
		@version
		@repo
		@args
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
			log.close

			Dir.mkdir "run-#{number}"
			Dir.chdir "run-#{number}"

			system(*@args,
				:out => @config["keep-stdout"] ? "stdout.log" : "/dev/null",
				:err => "stderr.log")
		end
	end
end
