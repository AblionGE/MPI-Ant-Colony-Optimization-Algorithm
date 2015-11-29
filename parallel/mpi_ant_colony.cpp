#include <mpi.h>
#include "utils.h"

#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif

int main(int argc, char* argv[]) {

  if (argc != 8) {
    printf("use : %s mapFile nbAntsPerNode nbExternalIterations nbOnNodeIterations alpha beta evaporationCoeff\n", argv[0]);
    return -1;
  }

  MPI_Status status;

  int prank, psize;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &prank);
  MPI_Comm_size(MPI_COMM_WORLD, &psize);

  int i, j, loop_counter, ant_counter, cities_counter;
  int **map = NULL;
  float **pheromons;
  float **globalPheromons;
  // bestPath is a vector representing all cities in order.
  // If the value is 0, the city was not visited
  // else, the city is visited at step i
  int *bestPath;
  int *otherBestPath;
  int *currentPath;
  int bestCost = INFTY;

  char* mapFile = argv[1];
  int nAnts; 
  int externalIterations; 
  int onNodeIteration; 
  float alpha; 
  float beta; 
  float evaporationCoeff; 
  int nCities = 0;
  int finish = 1;

  if (prank == 0) {
    mapFile = argv[1];
    nAnts = atoi(argv[2]);;
    externalIterations = atoi(argv[3]);
    onNodeIteration = atoi(argv[4]);
    alpha = atof(argv[5]);
    beta = atof(argv[6]);
    evaporationCoeff = atof(argv[7]);
  }
  if (MPI_Bcast(&nAnts, 1, MPI_INT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    return -1;
  }
  if (MPI_Bcast(&onNodeIteration, 1, MPI_INT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    return -1;
  }
  if (MPI_Bcast(&alpha, 1, MPI_FLOAT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    return -1;
  }
  if (MPI_Bcast(&beta, 1, MPI_FLOAT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    return -1;
  }
  if (MPI_Bcast(&evaporationCoeff, 1, MPI_FLOAT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    return -1;
  }

  if (prank == 0) {
    // Load the map and the number of cities
    std::ifstream in;
    in.open(mapFile);

    if (!in.is_open()) {
      printf("Cannot open file.\n");
      printf("The filepath %s is incorrect\n", mapFile);
      return -1;
    }
    char out[8];
    in >> out;

    // Define number of cities
    // // FIXME : +1 is correct ?
    nCities = atoi(out) + 1;

    // Allocation of local map and globalPheromons matrices and otherBestPath vector
    otherBestPath = (int*) malloc(nCities*sizeof(int));
    map = (int**) malloc(nCities*sizeof(int*));
    globalPheromons = (float**) malloc(nCities*sizeof(float*));
    for (i = 0; i < nCities; i++) {
      map[i] = (int*) malloc(nCities*sizeof(int));
      globalPheromons[i] = (float*) malloc(nCities*sizeof(float));
      otherBestPath[i] = -1;
    }

    for (i = 0; i < nCities; i++) {
      for (j = i; j < nCities; j++) {
        globalPheromons[i][j] = 0.1;
        globalPheromons[j][i] = 0.1;
      }
    }

    in.close();

    // Load the map inside map variable
    if (LoadCities(mapFile, map)) {
      printf("The filepath %s is incorrect\n", mapFile);
      return -1;
    }

    printf("Number of cities : %d\n", nCities);
  }

  // Share number of cities
  if (MPI_Bcast(&nCities, 1, MPI_INT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    return -1;
  }

  printf("%d received %d cities\n", prank, nCities);

  // Allocation of map for non-root nodes
  if (prank != 0) {
    map = (int**) malloc(nCities*sizeof(int*));
    for (i = 0; i < nCities; i++) {
      map[i] = (int*) malloc(nCities*sizeof(int));
    }
  }

  // FIXME
  if (MPI_Bcast(&map[0][0], nCities * nCities, MPI_INT, 0, MPI_COMM_WORLD) != MPI_SUCCESS) {
    return -1;
  }

  if (prank == 0) {
    printf("Rank %d\n", prank);
    //printMap(map, nCities);
  }

  // Allocation of pheromons
  pheromons = (float**) malloc(nCities*sizeof(float*));

  for (i = 0; i < nCities; i++) {
    pheromons[i] = (float*) malloc(nCities*sizeof(float));
  }
  bestPath = (int*) malloc(nCities*sizeof(int));
  currentPath = (int*) malloc(nCities*sizeof(int));

  // Initialisation of pheromons and other vectors
  for (i = 0; i < nCities; i++) {
    currentPath[i] = -1;
    bestPath[i] = -1;
    for (j = i; j < nCities; j++) {
      pheromons[i][j] = 0.1;
      pheromons[j][i] = 0.1;
    }
  }

  /*

     while (finish) {
     loop_counter = 0;
     while (loop_counter < onNodeIteration) {

     printf("Loop nr. : %d in node %d\n", loop_counter, prank);

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
  copyVector(currentPath, bestPath, nCities);
  }
  }
  //
  // Pheromon evaporation
  for (i = 0; i < nCities; i++) {
  for (j = i + 1; j < nCities; j++) {
  pheromons[i][j] *= evaporationCoeff;
  pheromons[j][i] *= evaporationCoeff;
  }
  }
  // Update pheromons
  updatePheromons(pheromons, bestPath, bestCost, nCities);

  loop_counter++;
  printf("best cost on node %d : %d\n", prank, bestCost);
  }

    // TODO : 
    // Merge part
    if (prank != 0) {
  // Send its bestPath's pheromons values
  // MPI_Send()
  }
  if (prank == 0) {
    // Recv pheromons values and merge them into globalPheromons
    // MPI_Recv()
    for (i = 0; i < nCities - 1; i++) {
    globalPheromons[otherBestPath[i]][otherBestPath[i+1]] = 1;
    }
    globalPheromons[otherBestPath[nCities-1]][otherBestPath[0]] = 1;

    }

  // Send back to each node the complete matrix of pheromons
  // MPI_Bcast()

  // Merge updates pheromon's values into local pheromon matrix

  }

  if (prank == 0) {
    printPath(bestPath, nCities);
    printf("best cost : %d\n", bestCost);
  }

  if (prank == 0) {
    // TODO :
    // Free globalPheromones
    // Free otherBestPath
  }
  */

    // deallocation of the rows
    printf("Caca\n");
  for(i=0; i<nCities ;i++) {
    free(map[i]);
    free(pheromons[i]);
  }

  // deallocate the pointers
  printf("Caca\n");
  free(map);
  printf("Caca\n");
  free(pheromons);
  printf("Cacaaaaa\n");
  free(bestPath);
  printf("Cacabbbb\n");
  free(currentPath);
  printf("Cacacccc\n");

  MPI_Finalize();
  printf("Cacadddd\n");

  return 0;
}


