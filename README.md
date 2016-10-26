# MS Thesis Experiments

These experiments run inside of a container specified by a Dockerfile,
which means you'll need a way to build and run Docker images.

You have two options to download the experiments. Either
clone [the repository][1] from GitHub or download [the release][2]
(also hosted at GitHub).

If you cloned the experiment's repository, you need to perform two
more tasks. First, download the [Racket 6.6 x86-64 Linux][3] installer
and place it in the repository's working directory. Next, set up the
repository's submodules by running two commands: `git submodule init`
followed by `git submodule update`.

If you downloaded the release, simply unpack it and run the following
commands from the `ms-thesis-experiments` directory.

# Running the experiments

To run the experiments, you first need to build the environment that
contains the experiments. From the project's directory, run `docker
build -t btlachance/ms-thesis-experiments .`. This builds an image
according to the current directory's Dockerfile and names the image
`btlachance/ms-thesis-experiments`. If the image only stays on your
machine, you're free to name it whatever you'd like; just be sure to
use a consistent name when running the commands in this section.

To perform the experiments and place the results in the absolute path
DIR, run `docker run -v DIR:/data btlachance/ms-thesis-experiments`.
This runs the untyped and typed benchmark programs with contracts. The
results of running those programs is in the `.rktd` files and the
first row of data contains the untyped timings and the second row of
data contains the typed timings. Unfortunately, obtaining the timings
without contracts and the information from the contract profiler
requires manual intervention.

If you'd prefer to play in a Racket REPL with typed contracts, run
`docker run -it btlachance/ms-thesis-experiments racket -l
typed/racket -i`.

[1]: https://github.com/btlachance/ms-thesis-experiments.git
[2]: https://github.com/btlachance/ms-thesis-experiments/releases/download/1.0/ms-thesis-experiments.tar.gz
[3]: https://mirror.racket-lang.org/installers/6.6/racket-6.6-x86_64-linux.sh
