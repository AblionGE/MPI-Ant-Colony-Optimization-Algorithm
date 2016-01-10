# Ant Colony Optimization Algorithm - MPI - Marc Schaer

## Directory structure

* generate_map.cpp - Code to generate a fully connected map
    * ```./generate_map filename size maximalDistance```
        * ```maximalDistance``` is the maximal distance between two cities
* generate_random_numbers.cpp - Code to generate a file with random numbers
    * ```./generate_random_numbers fileName numberOfNumbers```
* Makefile - Used to compiled both files above
* serial/ - Folder with the serial implementation
* doc/ - Folder with the report and the slides
* parallel1/ - Folder with the first parallel implementation (see report for details)
* parallel2/ - Folder with the second parallel implementation (see report for details)
* parallel3/ - Folder with the third parallel implementation (see report for details)
* batch.sh - Script to launch jobs on the cluster
    * ```batch.sh mapFile randomFile nbOfAnts nbOfInternalLoops nbOfExternalLoops```
    * ```mapFile``` and ```randomFile``` are files created by codes listed above
* launch_batch.sh - Script to launch many batches
    * ```./launch_batch mapFileName sizeOfMap maxDistance nbOfRandomFiles nbOfAnts InternalLoops ExternalLoops```
    * This is the main script to launch to run jobs on the server. It will create the map and random files and then launch jobs for each random files
    * /!\ This script needs working Makefile in subdirectories /!\
* compare_results - Script to compare optimality of results
    * Needs all results launched by ```launch_batch.sh``` on the cluster
    * Create file for each parallel implementation and print in it the best costs and a summary
* compare_timings.sh - Script to compare timings and compute speedups
    * Needs all results launched by ```launch_batch.sh``` on the cluster
    * Create files for each parallel implementation and print in it the times and the speedup vales
* plotSpeedups.sh - Script to plot speedups
    * Needs all results launched by ```launch_batch.sh``` on the cluster

## How to compile

To compile locally, you need to have installed ```g++``` and for MPI ```mpic++```.
For parallel implementations, you need to rename ```localMakefile``` in ```Makefile```.

On the cluster, for parallel implementations, you need to rename ```clusterMakfile``` in ```Makefile```.

If you want to compile manually on the cluster (```batch.sh``` does the work if you use it), you need to import the intelmpi module (```module load intel intelmpi```).

## How to run the code

To run serial implementation and generation of map and random numbers, you simply need to run the compiled files as scripts. For MPI code, you can use ```mpirun``` (```mpirun -np NumberOfNodes compiledFiled mapFile randomFile NumberOfAnts externalIterations localIterations alpha beta evaporationCoefficient```)

## Remarks

### Subdirectories

README files can be found in subdirectories

### Termination Condition 

The given implementations are not using the termination condition in the ```while``` loop (there are warnings during compilation about that).
To use it, you just need to uncomment the condition in each file.
