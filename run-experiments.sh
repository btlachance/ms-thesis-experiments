#!/bin/bash

for benchmark in {gregor,tetris,snake,acquire}; do
    ./run.sh benchmarks/$benchmark
    cp benchmarks/$benchmark.log $DATADIR
    cp $benchmark-*.rktd $DATADIR
done
