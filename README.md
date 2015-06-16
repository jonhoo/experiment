# experiment
[![Build Status](https://travis-ci.org/jonhoo/experiment.svg?branch=master)](https://travis-ci.org/jonhoo/experiment)

Experiment is a tool for running concurrent multi-configuration experiments.

Quite often, we need to run different versions of an application to
determine the effect of a change, or we need to run it multiple times
with different parameters for benchmarking. Furthermore, to get
statistically relevant results, we need to execute each experiment
multiple times. For posteriority, we would also like to keep track of
exactly how the application was run, how many times each version has
been run, and what the exact changes were made to the application for
each experiment.

experiment tries to solve this by integrating closely with version
control systems, allowing developers to specify exactly which versions
of the application to build, and what changes to apply (if any). It will
execute each version multiple times, possibly concurrently, and report
back when it finishes, leaving you to do other things than wait for one
experiment to finish before starting the next.

## usage

Experiment gets information about what versions it should run from an
`experiment.json` file. This file has a number of root-level fields:

Field       | Type   | Purpose
------------|--------|--------
experiment  | string | A description of the experiment being run.
repository  | string | Specifies the repository to draw source code from (optional; can use `-r` instead).
checkout    | string | Default commit, branch or tag to check out from the repository.
iterations  | number | The number of times to run each version.
parallelism | number | The number of versions to run in parallel.
build       | string | Default command used to build the application under test -- passed to system shell.
keep-stdout | bool   | If false or unset, application standard output is discarded. If true, it is kept in stdout.log.
arguments   | array  | Default command and arguments to run the application with -- **not** passed to system shell. The special string `$SRC` will be replaced with the source code directory the current version was built from.
into        | string | Copy the source tree into a subdirectory of the build directory (useful for e.g. Go packages)
versions    | hash   | Described below.

The `versions` hash is where all the versions you want experiment to
execute are defined. For each version, experiment will clone the source
repository, check out the appropriate commit, build the application, and
then run it. In the output directory (specified with `-o`; defaults to
`.`), a directory is created for each version (the version's key is used
as the directory name). Each such directory contains a `source`
directory holding the sources the version was built from, a `build.log`
file giving information about the version's build, as well as
`iterations` directories called `run-1`, `run-2`, etc. These all hold at
least two files: `experiment.log` and `stderr.log`. `experiment.log`
contains information about how the process was run, and how long it took
to execute. `stderr.log` contains the error output of the application.
If `keep-stdout` is set to `true`, a file called `stdout.log` holding
the application's regular output will also be present.

Each version may override the default `checkout`, `build`, and
`arguments` if the wish. In addition, they may specify a list of
`diffs`. Each `diff` is a patch file that will be applied to the
version's source directory before it is built.

Versions are run in random order within each iteration, but each
iteration waits for all versions in the previous iteration to be started
before any version in the next iteration is started.

To start the experiment, simply run

    $ experiment

and experiment will read the `experiment.json` file and start running
your jobs. It will show a progress report, and notify you when the job
has finished.

## templated versions

Experiment also supports *templated versions*. A templated version is
expanded to multiple versions, each with some set of parameters. To give
an example:

```javascript
{
	// ...
	"versions": {
		// ...
		"$animal-$number": {
			"vary": {
				"animal": "set(rabbit, turtle)",
				"number": "range(1, 3, 1)"
			},
			"arguments": [
				"$SRC/run",
				"$animal",
				"-n",
				"$number"
			]
		}
		// ...
	}
	// ...
}
```

this will produce four different versions: `rabbit-1`, `rabbit-2`,
`turtle-1`, and `turtle-2`, run with `$SRC/run rabbit -n 1`, `$SRC/run
rabbit -n 2`, etc. Currently, the only vary functions that are supported
are `set`, `range`, and `cmd`. `set` produces all given values, which
are comma-separated and may be quoted. `range(a, b, c)` produces every
number less than `b`, starting at `a`, in increments of `c`.

`cmd` is special in that it executes a shell command (using Ruby's
[`system`](http://ruby-doc.org/core-2.2.0/Kernel.html#method-i-system)
command), and expands into the values output by the command when run.
The command is run in the same directory as `experiment` was called from
(this is because templates are expanded before the repository has even been
cloned, and so cannot refer to anything else). There are two variants of
this function: `cmd` and `cmd_l`. These differ only in what delimiter
they use to distinguish different values in the output; `cmd` uses `\0`,
whereas `cmd_l` uses newlines. **Authors should be careful about using
`cmd_l`, as values containing newlines will be misinterpreted as
multiple values.**
