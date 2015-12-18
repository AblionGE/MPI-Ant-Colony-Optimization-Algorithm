#!/bin/bash

if [ "$#" -ne 5 ]; then
  echo "usage $0 mapFile randomFile nbOfAnts nbOfInternalLoops nbOfExternalLoops"
  exit 1
fi

mapFile=$1
randomFile=$2

ROOT="ant_colony"
NB_ANTS=$3
NB_INTERNAL_LOOP=$4
NB_EXTERNAL_LOOP=$5
NB_TOTAL_LOOP=$(echo "$4*$5" | bc)
ALPHA=1
BETA=1
EVAPORATION=0.9

## Serial job
SERIAL="serial_$ROOT.run"
cd serial

if [ -e $SERIAL ]; then
  rm $SERIAL
fi

echo "#!/bin/bash" >> $SERIAL
echo "#SBATCH --nodes 1" >> $SERIAL
echo "#SBATCH --ntasks-per-node 1" >> $SERIAL
echo "#SBATCH --cpus-per-task 1" >> $SERIAL
echo "#SBATCH --mem 4096" >> $SERIAL
echo "#SBATCH --time 03:00:00" >> $SERIAL
echo "module purge" >> $SERIAL
echo "srun ./serial_ant_colony ../$mapFile ../$randomFile $NB_ANTS $NB_TOTAL_LOOP $ALPHA $BETA $EVAPORATION" >> $SERIAL
sbatch $SERIAL
cd ..


## Parallel jobs
for p in "parallel1" "parallel2" "parallel3" "parallel4"
do
  cd $p
  for i in 1 2 4 8 16
  do
    FILE="mpi_$ROOT$i.run"
    if [ -e $FILE ]; then
      rm $FILE
    fi
    touch $FILE
    echo "#!/bin/bash" >> $FILE
    echo "#SBATCH --nodes $i" >> $FILE
    echo "#SBATCH --ntasks-per-node 1" >> $FILE
    echo "#SBATCH --cpus-per-task 1" >> $FILE
    echo "#SBATCH --mem 4096" >> $FILE
    echo "#SBATCH --time 03:00:00" >> $FILE
    echo "module purge" >> $FILE
    echo "module load intel intelmpi" >> $FILE
    echo "srun ./mpi_ant_colony ../$mapFile ../$randomFile $NB_ANTS $NB_EXTERNAL_LOOP $NB_INTERNAL_LOOP $ALPHA $BETA $EVAPORATION" >> $FILE
    sbatch $FILE
  done
  cd ..
done
