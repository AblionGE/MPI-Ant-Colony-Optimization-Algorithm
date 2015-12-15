#!/bin/bash

if [ "$#" -ne 4 ]; then
  echo "usage $0 mapFileName sizeOfMap maxDistance nbOfRandomFiles"
  exit 1
fi

mapFileName=$1
sizeOfMap=$2
maxDistance=$3
loops=$4

# Compile codes

module load intel intelmpi
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
  ./generate_random_numbers $RAND 100000
  ./batch.sh $mapFileName $RAND
  sleep 1
done

make clean
