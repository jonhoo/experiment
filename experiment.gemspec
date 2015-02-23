$:.push File.expand_path("../lib", __FILE__)
require "experiment/version"

Gem::Specification.new do |s|
  s.name        = 'experiment'
  s.version     = Experiment::VERSION
  s.licenses    = ['MIT']
  s.summary     = "A tool for running concurrent multi-configuration experiments"
  s.description = "A tool for running concurrent multi-configuration experiments. Quite often, we need to run different versions of an application to determine the effect of a change. Furthermore, to get statistically relevant results, we need to execute each experiment multiple times. For posteriority, we would also like to keep track of exactly how the application was run, how many times each version has been run, and what the exact changes were made to the application for each experiment.\nexperiment tries to solve this by integrating closely with version control systems, allowing developers to specify exactly which versions of the application to build, and what changes to apply (if any). It will execute each version multiple times, possibly concurrently, and report back when it finishes, leaving you to do other things than wait for one experiment to finish before starting the next."
  s.authors     = ["Jon Gjengset"]
  s.email       = 'jon@thesquareplanet.com'
  s.homepage    = 'https://github.com/jonhoo/experiment'

  s.executables   = `ls bin`.split("\n").map{ |f| File.basename(f) }

  s.add_runtime_dependency 'commander', '~> 4.2'
  s.add_runtime_dependency 'ruby-progressbar', '~> 1.5'
  s.add_runtime_dependency 'rugged', '~> 0.19'
  s.add_runtime_dependency 'colorize', '~> 0.7'
end
