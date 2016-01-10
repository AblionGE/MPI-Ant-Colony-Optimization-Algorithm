# Third parallel Implementation

This implementation of the parallel algorithm uses two termination conditions :
  - Maxmimum number of loops
  - 40% of loops with the same best cost

It shares the whole pheromons matrices of each node after local iterations and merge them into local pheromons matrix (with taking the average for each edge (to not give to much importance to best paths).

## Files

* utils.h - Contains help functions for the algorithm
* mpi_ant_colony.cpp - First parallel implementation
* localMakefile - Makefile for compiling locally
* clusterMakefile - Makefile for compiling on cluster

## Remarks

The given implementation is not using the termination condition in the ```while``` loop (there are warnings during compilation about that).
To use it, you just need to uncomment the condition in ```mpi_ant_colony.cpp```.
