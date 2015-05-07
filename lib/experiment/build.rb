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
		def initialize(repo, command, checkout, diffs, config)
			@repo = repo
			@command = command
			@checkout = checkout
			@diffs = diffs || []
			@config = config
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

			puts "==> Preparing source for build of '#{@checkout}'".bold

			puts " -> Recreating source tree".blue
			Experiment::recreate_tree(@repo, commit)

			if not @diffs.empty?
				puts " -> Applying patches".cyan
				for p in @diffs do
					# git apply ...
					puts "  - #{p}".cyan
					if system("/usr/bin/patch", "-Np1", "-i", File.expand_path(p)).nil?
						Dir.chdir pwd
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

			if @config.include? "preserve" and not @config["preserve"].empty?
				puts " -> Copying preserved files".blue
				for p in @config["preserve"]
					from = File.join(@repo.workdir, p)
					to = File.join('.', p)

					if not File.exist? from
						puts "  - #{p} skipped"
						next
					end
					puts "  + #{p}".blue
					FileUtils.mkdir_p File.dirname(to)
					FileUtils.cp_r from, to
				end
			end

			puts " -> Building application".yellow
			if system(@command) != true
				Dir.chdir pwd
				raise "#{$?}"
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
end
