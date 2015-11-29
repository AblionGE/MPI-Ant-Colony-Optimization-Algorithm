/* Ant Colony Optimixzation Algorithm - Marc Schaer*/
#include <mpi.h>
#include "utils.h"

int main(int argc, char* argv[]) {

  if (argc != 8) {
    printf("use : %s mapFile nbAntsPerNode nbExternalIterations nbOnNodeIterations alpha beta evaporationCoeff\n", argv[0]);
    return -1;
  }

  int prank, psize;

  MPI_Status status;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &prank);
  MPI_Comm_size(MPI_COMM_WORLD, &psize);

  int i, j, loop_counter, ant_counter, cities_counter;
  int external_loop_counter = 0;
  int *map = NULL;
  float *pheromons;
  // bestPath is a vector representing all cities in order.
  // If the value is 0, the city was not visited
  // else, the city is visited at step i
  int *bestPath;
  int *otherBestPath;
  int *currentPath;
  int bestCost = INFTY;
  float* localPheromonsPath;
  float* otherPheromonsPath;

  char* mapFile = argv[1];
  int nAnts; 
  int externalIterations; 
  int onNodeIteration; 
  float alpha; 
  float beta; 
  float evaporationCoeff; 
  int nCities = 0;

  // Start Timing
  if (prank == 0) {
    start = second();
  }

  // Root reads args
  if (prank == 0) {
    mapFile = argv[1];
    nAnts = atoi(argv[2]);;
    externalIterations = atoi(argv[3]);
    onNodeIteration = atoi(argv[4]);
    alpha = atof(argv[5]);
    beta = atof(argv[6]);
    evaporationCoeff = atof(argv[7]);
  }

  // And then it shares values with other nodes
  if (MPI_Bcast(&nAnts, 1, MPI_INT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of nAnts", prank);
    MPI_Finalize();
    return -1;
  }
  if (MPI_Bcast(&onNodeIteration, 1, MPI_INT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of onNodeIteration", prank);
    MPI_Finalize();
    return -1;
  }
  if (MPI_Bcast(&externalIterations, 1, MPI_INT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of externalIterations", prank);
    MPI_Finalize();
    return -1;
  }
  if (MPI_Bcast(&alpha, 1, MPI_FLOAT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of alpha", prank);
    MPI_Finalize();
    return -1;
  }
  if (MPI_Bcast(&beta, 1, MPI_FLOAT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of beta", prank);
    MPI_Finalize();
    return -1;
  }
  if (MPI_Bcast(&evaporationCoeff, 1, MPI_FLOAT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of evaporationCoeff", prank);
    MPI_Finalize();
    return -1;
  }

  if (prank == 0) {
    // Load the map and the number of cities
    std::ifstream in;
    in.open(mapFile);

    if (!in.is_open()) {
      printf("Cannot open file.\n");
      printf("The filepath %s is incorrect\n", mapFile);
      MPI_Finalize();
      return -1;
    }
    char out[8];
    in >> out;

    // Define number of cities
    nCities = atoi(out);

    // Allocation of local map
    map = (int*) malloc(nCities*nCities*sizeof(int));

    in.close();

    // Load the map inside map variable
    if (LoadCities(mapFile, map)) {
      printf("The filepath %s is incorrect\n", mapFile);
      MPI_Finalize();
      return -1;
    }

    // printf("Number of cities : %d\n", nCities);
  }

  // Share number of cities
  if (MPI_Bcast(&nCities, 1, MPI_INT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of nCities", prank);
    MPI_Finalize();
    return -1;
  }

  // Allocation of map for non-root nodes
  if (prank != 0) {
    map = (int*) malloc(nCities*nCities*sizeof(int));
  }


  if (MPI_Bcast(&map[0], nCities * nCities, MPI_INT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of map", prank);
    MPI_Finalize();
    return -1;
  }

  // Allocation of pheromons
  pheromons = (float*) malloc(nCities*nCities*sizeof(float));
  localPheromonsPath = (float*) malloc(nCities*sizeof(float));

  otherBestPath = (int*) malloc(nCities*sizeof(int));
  otherPheromonsPath = (float*) malloc(nCities*sizeof(float));
  for (i = 0; i < nCities; i++) {
    otherBestPath[i] = -1;
  }

  bestPath = (int*) malloc(nCities*sizeof(int));
  currentPath = (int*) malloc(nCities*sizeof(int));

  // Initialisation of pheromons and other vectors
  for (i = 0; i < nCities; i++) {
    currentPath[i] = -1;
    bestPath[i] = -1;
  }
  for (i = 0; i < nCities * nCities; i++) {
    pheromons[i] = 0.1;
  }

  while (external_loop_counter < externalIterations) {
    loop_counter = 0;
    while (loop_counter < onNodeIteration) {

      // printf("Loop nr. : %d in node %d\n", loop_counter, prank);

      // Loop over each ant
      for (ant_counter = 0; ant_counter < nAnts; ant_counter++) {
        // init currentPath 
        // -1 means not visited
        for (i = 0; i < nCities; i++) {
          currentPath[i] = -1;
        }

        // select a random start city for an ant
        int currentCity = rand() % nCities;
        // currentPath will contain the order of visited cities
        currentPath[currentCity] = 0;
        for (cities_counter = 1; cities_counter < nCities; cities_counter++) {
          // Find next city
          currentCity = computeNextCity(currentCity, currentPath, map, nCities, pheromons, alpha, beta);

          if (currentCity == -1) {
            printf("There is an error choosing the next city in interation %d for ant %d on node %d\n", loop_counter, ant_counter, prank);
            return -1;
          }

          // add next city to plan
          currentPath[currentCity] = cities_counter;
        }

        // update bestCost and bestPath
        int oldCost = bestCost;
        bestCost = updateBestPath(bestCost, bestPath, currentPath, map, nCities);

        if (oldCost > bestCost) {
          copyVectorInt(currentPath, bestPath, nCities);
        }
      }

      // Pheromon evaporation
      for (i = 0; i < nCities * nCities; i++) {
        pheromons[i] *= evaporationCoeff;
      }
      // Update pheromons
      updatePheromons(pheromons, bestPath, bestCost, nCities);

      loop_counter++;
    }

    findPheromonsPath(localPheromonsPath, bestPath, pheromons, nCities);
    for (i = 0; i < psize; i++) {
      if (prank == i) {
        copyVectorInt(bestPath, otherBestPath, nCities);
        copyVectorFloat(localPheromonsPath, otherPheromonsPath, nCities);
      }
      if (MPI_Bcast(&otherBestPath[0], nCities, MPI_INT, i, MPI_COMM_WORLD) != MPI_SUCCESS) {
        printf("Node %d : Error in Broadcast of otherBestPath", prank);
        MPI_Finalize();
        return -1;
      }
      if (MPI_Bcast(&otherPheromonsPath[0], nCities, MPI_FLOAT, i, MPI_COMM_WORLD) != MPI_SUCCESS) {
        printf("Node %d : Error in Broadcast of otherPheromonsPath", prank);
        MPI_Finalize();
        return -1;
      }

      if (prank != i) {
        for (j = 0; j < nCities - 1; j++) {
          pheromons[getMatrixIndex(otherBestPath[i],otherBestPath[i+1],nCities)] += otherPheromonsPath[i];
          pheromons[getMatrixIndex(otherBestPath[i+1],otherBestPath[i],nCities)] += otherPheromonsPath[i];
        }
        pheromons[getMatrixIndex(otherBestPath[nCities-1],otherBestPath[0],nCities)] += otherPheromonsPath[nCities - 1];
        pheromons[getMatrixIndex(otherBestPath[0],otherBestPath[nCities-1],nCities)] += otherPheromonsPath[nCities - 1];
      }
    }

    external_loop_counter++;
    // printf("Node %d : external loop - %d\n", prank, external_loop_counter);
  }

  // Merge solution into root 
  if (prank == 0) {
    for (i = 1; i < psize; i++) {
      if (MPI_Recv(&otherBestPath[0], nCities, MPI_INT, i, MPI_ANY_TAG, MPI_COMM_WORLD, &status) != MPI_SUCCESS) {
        printf("Node %d : Error in Recv of otherBestPath", prank);
        MPI_Finalize();
        return -1;
      }
      int oldCost = bestCost;
      bestCost = updateBestPath(bestCost, bestPath, otherBestPath, map, nCities);

      if (oldCost > bestCost) {
        copyVectorInt(otherBestPath, bestPath, nCities);
      }
    }
  } else {
    if (MPI_Send(&bestPath[0], nCities, MPI_INT, 0, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
      printf("Node %d : Error in Send of bestPath", prank);
      MPI_Finalize();
      return -1;
    }
  }


  if (prank == 0) {
    printPath(bestPath, nCities);
    printf("best cost : %d\n", bestCost);
  }


  // deallocate the pointers
  free(map);
  free(pheromons);
  free(localPheromonsPath);
  free(otherPheromonsPath);
  free(bestPath);
  free(otherBestPath);
  free(currentPath);

  if (prank == 0) {
    end = second();
    printf("TotalTime : %f\n", (end - start));
  }

  MPI_Finalize();

  return 0;
}

