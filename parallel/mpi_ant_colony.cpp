/* Ant Colony Optimixzation Algorithm - Marc Schaer*/
#include <mpi.h>
#include "utils.h"

int main(int argc, char* argv[]) {

  if (argc != 9) {
    printf("use : %s mapFile randomNumberFile nbAnts nbExternalIterations nbOnNodeIterations alpha beta evaporationCoeff\n", argv[0]);
    return -1;
  }

  int prank, psize;

  MPI_Status status;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &prank);
  MPI_Comm_size(MPI_COMM_WORLD, &psize);

  int i, j, loop_counter, ant_counter, cities_counter;
  int random_counter = 0;
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

  long* randomNumbers;
  int nRandomNumbers = 0;

  char* mapFile;
  char* randomFile;
  int nAnts; 
  int externalIterations; 
  int onNodeIteration; 
  float alpha; 
  float beta; 
  float evaporationCoeff; 
  int nCities = 0;
  int* nAntsPerNode;

  // share random file first
  if (prank == 0) {
    std::ifstream in;
    randomFile = argv[2];
    char out[20];

    // Read random numbers file
    in.open(randomFile);

    if (!in.is_open()) {
      printf("Cannot open file.\n");
      printf("The filepath %s is incorrect\n", randomFile);
      MPI_Finalize();
      return -1;
    }

    in >> out;

    // Define number of random numbers
    nRandomNumbers = atol(out);

    // Allocation of random numbers vector
    randomNumbers = (long*) malloc(nRandomNumbers*sizeof(long));

    i = 0;
    for (i = 0; i < nRandomNumbers; i++) {
//    while(!in.eof()) {
      in >> out;
      randomNumbers[i] = atol(out);
    }

    in.close();

  }

  if (MPI_Bcast(&nRandomNumbers, 1, MPI_LONG, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of nRandomNumbers", prank);
    MPI_Finalize();
    return -1;
  }

  if (prank != 0) {
    randomNumbers = (long*) malloc(nRandomNumbers*sizeof(long));
  }

  if (MPI_Bcast(&randomNumbers[0], nRandomNumbers, MPI_LONG, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of randomNumbers", prank);
    MPI_Finalize();
    return -1;
  }

  // Start Timing
  if (prank == 0) {
    start = second();
  }

  nAntsPerNode = (int*) malloc(psize*sizeof(int));

  // Root reads args
  if (prank == 0) {
    mapFile = argv[1];
    nAnts = atoi(argv[3]);
    externalIterations = atoi(argv[4]);
    onNodeIteration = atoi(argv[5]);
    alpha = atof(argv[6]);
    beta = atof(argv[7]);
    evaporationCoeff = atof(argv[8]);

    int antsPerNode = nAnts / psize;
    int restAnts = nAnts % psize;

    for (i = 0; i < psize; i++) {
      nAntsPerNode[i] = antsPerNode;
      if (restAnts > i) {
        nAntsPerNode[i]++;
      }
    }

    printf("Iterations %d\n", externalIterations*onNodeIteration);
    printf("Ants %d\n", nAnts);
  }

  // And then it shares values with other nodes
  if (MPI_Bcast(&nAntsPerNode[0], psize, MPI_INT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    printf("Node %d : Error in Broadcast of nAntsPerNode", prank);
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
    char out[12];
    in >> out;

    // Define number of cities
    nCities = atoi(out);

    printf("Cities %d\n", nCities);

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

  nAnts = nAntsPerNode[prank];

  random_counter = (random_counter + (onNodeIteration * prank)) % nRandomNumbers;

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
        long rand = randomNumbers[random_counter];
        int currentCity = rand % nCities;
        random_counter = (random_counter + 1) % nRandomNumbers;
        // currentPath will contain the order of visited cities
        currentPath[currentCity] = 0;
        for (cities_counter = 1; cities_counter < nCities; cities_counter++) {
          // Find next city
          currentCity = computeNextCity(currentCity, currentPath, map, nCities, pheromons, alpha, beta);

          if (currentCity == -1) {
            printf("There is an error choosing the next city in iteration %d for ant %d on node %d\n", loop_counter, ant_counter, prank);
            MPI_Finalize();
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

    random_counter = (random_counter + (onNodeIteration * (psize - 1))) % nRandomNumbers;
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


  /*  if (prank == 0) {
  // printPath(bestPath, nCities);
  printf("best cost : %d\n", bestCost);
  }
  */


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

