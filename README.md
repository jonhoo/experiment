# experiment

A tool for running concurrent multi-configuration experiments. Quite often,
we need to run different versions of an application to determine the effect of a
change. Furthermore, to get statistically relevant results, we need to execute
each experiment multiple times. For posteriority, we would also like to keep
track of exactly how the application was run, how many times each version has
been run, and what the exact changes were made to the application for each
experiment.

experiment tries to solve this by integrating closely with version control
systems, allowing developers to specify exactly which versions of the
application to build, and what changes to apply (if any). It will execute each
version multiple times, possibly concurrently, and report back when it finishes,
leaving you to do other things than wait for one experiment to finish before
starting the next.

**Note that this application is not yet finished. See issues #2 and #3 in
particular.**

## usage

First, define the parameters for your experiment in a directory with a
`experiment.json` file:

````js
{
	"experiment": "Test unicorn patch",
	"repository": "~/dev/myapp",
	"checkout": "v0.1",
	"iterations": 10,
	"parallelism": 4,
	"build": "make -j8",
	"arguments": [
		"build/bin/myapp",
		"-r",
		"3",
		"~/experimental-data.dat"
	],
	"versions": {
		"vanilla": { },
		"one-unicorn": {
			"diffs": [ "~/add-unicorns.patch" ]
		},
		"ten-unicorn": {
			"diffs": [
				"~/add-unicorns.patch",
				"~/ten-unicorns.patch"
			]
		},
		"rainbows-unicorns": {
			"checkout": "v0.1-rainbows",
			"diffs": [ "~/add-unicorns.patch" ]
		}
	}
}
````

Most of the parameters here should be fairly self-explanatory, perhaps with the
exception of `parallelism`. `parallelism` dictates how many experiments you want
to be run in parallel. experiment will try to distribute the experiment time
evenly across all your versions instead of running all iterations of one, then
of the second, etc.

To start the job, simply run

    $ experiment

and experiment will read the `experiment.json` file and start running your jobs.
It will show a progress report, and notify you when the job has finished.
