#!/bin/bash

ROOT="ant_colony"
NB_ANTS=32
NB_INTERNAL_LOOP=100
NB_EXTERNAL_LOOP=40
NB_TOTAL_LOOP=4000
ALPHA=1
BETA=1
EVAPORATION=0.9

## Serial job
SERIAL="serial_$ROOT.run"

echo "#!/bin/bash" >> $SERIAL
echo "#SBATCH --nodes 1" >> $SERIAL
echo "#SBATCH --ntasks-per-node 1" >> $SERIAL
echo "#SBATCH --cpus-per-task 1" >> $SERIAL
echo "#SBATCH --mem 4096" >> $SERIAL
echo "#SBATCH --time 01:00:00" >> $SERIAL
echo "module purge" >> $SERIAL
echo "srun ./serial/serial_ant_colony ../map1000.txt $NB_ANTS $NB_TOTAL_LOOP $ALPHA $BETA $EVAPORATION" >> $SERIAL
sbatch $SERIAL


## Parallel jobs
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
  echo "#SBATCH --time 01:00:00" >> $FILE
  echo "module purge" >> $FILE
  echo "module load intel intelmpi" >> $FILE
  echo "srun ./parallel/mpi_ant_colony ../map1000.txt $NB_ANTS $NB_EXTERNAL_LOOP $NB_INTERNAL_LOOP $ALPHA $BETA $EVAPORATION" >> $FILE
  sbatch $FILE
done
