require 'json'

module Experiment
	def self.read_config(dir)
		fn = dir + '/experiment.json'
		if not File.exist? fn
			raise "Experiment config experiment.json does not exist"
		end

		return JSON.parse(File.read(fn))
	end
end
