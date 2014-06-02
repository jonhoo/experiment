require 'fileutils'

# We essentially want the opposite of git_blob__create_from_paths
module Experiment
	def self.recreate_tree(repo, commit)
		wd = Dir.pwd

		commit.tree.walk_trees do |root, e|
			path = wd + "/" + root + "/" + e[:name]
			FileUtils.mkdir_p path
		end

		commit.tree.walk_blobs do |root, e|
			path = wd + "/" + root + "/" + e[:name]
			blob = repo.lookup e[:oid]

			if e[:filemode] == 40960
				File.symlink blob.content, path
			else
				f = File.open path, "w"
				f.write blob.content
				f.chmod e[:filemode]
				f.close
			end
		end
	end
end
