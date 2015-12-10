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

cd parallel
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
  RAND="random$1.txt"
  ./generate_random_numbers $RAND 100000
  ./batch.sh $mapFileName $RAND
done

make clean
