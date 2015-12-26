#!/bin/bash

if [ "$#" -ne 7 ]; then
  echo "usage $0 mapFileName sizeOfMap maxDistance nbOfRandomFiles nbOfAnts InternalLoops ExternalLoops"
  exit 1
fi

mapFileName=$1
sizeOfMap=$2
maxDistance=$3
loops=$4
nAnts=$5
internal=$6
external=$7

# Compile codes

module load mvapich2/2.0.1/gcc-4.4.7
cd parallel1
make clean
make
cd ..
cd parallel2
make clean
make
cd ..
cd parallel3
make clean
make
cd ..
cd serial
make clean
make
cd ..
make

if [ ! -e $mapFileName ]; then
  ./generate_map $mapFileName $sizeOfMap $maxDistance
fi

for i in $(seq $loops)
do
  RAND="random$i.txt"
  ./generate_random_numbers $RAND 10000
  ./batch.sh $mapFileName $RAND $nAnts $internal $external
  sleep 1
done

make clean
