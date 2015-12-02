#!/bin/bash

FILE="test.run"

## Parallel jobs
for i in 1 2 4
do
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
  echo "srun ./mpi_ant_colony ../map1000.txt 1 10 10 1 1 0.9" >> $FILE
  sbatch $FILE
  cat $FILE
done


