#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "usage $0 mapFile randomFile"
  exit 1
fi

mapFile=$1
randomFile=$2

ROOT="ant_colony"
NB_ANTS=32
NB_INTERNAL_LOOP=50
NB_EXTERNAL_LOOP=100
NB_TOTAL_LOOP=5000
ALPHA=1
BETA=1
EVAPORATION=0.9

## Serial job
SERIAL="serial_$ROOT.run"
cd serial

echo "#!/bin/bash" >> $SERIAL
echo "#SBATCH --nodes 1" >> $SERIAL
echo "#SBATCH --ntasks-per-node 1" >> $SERIAL
echo "#SBATCH --cpus-per-task 1" >> $SERIAL
echo "#SBATCH --mem 4096" >> $SERIAL
echo "#SBATCH --time 23:59:59" >> $SERIAL
echo "module purge" >> $SERIAL
echo "srun ./serial_ant_colony ../$mapFile ../$randomFile $NB_ANTS $NB_TOTAL_LOOP $ALPHA $BETA $EVAPORATION" >> $SERIAL
sbatch $SERIAL
cd ..


## Parallel jobs
for p in "parallel1" "parallel2" "parallel3"
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
    echo "#SBATCH --time 23:59:59" >> $FILE
    echo "module purge" >> $FILE
    echo "module load intel intelmpi" >> $FILE
    echo "srun ./mpi_ant_colony ../$mapFile ../$randomFile $NB_ANTS $NB_EXTERNAL_LOOP $NB_INTERNAL_LOOP $ALPHA $BETA $EVAPORATION" >> $FILE
    sbatch $FILE
  done
  cd ..
done
