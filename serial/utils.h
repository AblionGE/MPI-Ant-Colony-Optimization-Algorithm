#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <float.h>
#include <sys/time.h>
#include <limits>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <fstream>

#define INFTY 999999999
#define eps 0.005

double start, end;

void printPath(int* path, int nCities) {
  int i;
  printf("Path : ");
  for (i = 0; i < nCities; i++) {
    if (i == 0) {
      printf("%d", path[i]);
    } else {
      printf(" -> %d", path[i]);
    }
  }
  printf("\n");
}

void printMap(int** map, int nCities) {
  printf("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
  printf("MAP :\n");
  int i, j;
  for (i = 0; i < nCities; i++) {
    for (j = 0; j < nCities; j++) {
      printf("%d ", map[i][j]);
    }
    printf("\n");
  }
  printf("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n");
}

void copyVector(int* in, int* out, int size) {
  int k;
  for (k = 0; k < size; k++) {
    out[k] = in[k];
  }
}


int LoadCities(char* file, int** map) {
  std::ifstream in;
  int matrixFull = 1;
  int size = 0;
  int x = 0;
  int y = 0;
  int first = 1;

  in.open (file);

  if (!in.is_open()) {
    printf("Cannot open file.\n");
    return -1;
  }
  char out[8];
  while (!in.eof() && matrixFull) {
    if (first) {
      first = 0;
      in >> out;
      size = atoi(out);
    } else {
      in >> out;
      map[x][y] = atoi(out);
      y = (y + 1) % size;
      if (y == 0) {
        x = (x + 1) % size;
        if (x == 0) {
          matrixFull = 0;
        }
      }
    }
  }

  // printMap(map, size);

  in.close();

  return 0;
}

void computeProbabilities(int currentCity, double* probabilities, int* path, int** map, int nCities, float** pheromons, float alpha, float beta) {
  int i;
  double total = 0;
  for (i = 0; i < nCities; i++) {
    if (path[i] != -1 || i == currentCity) {
      probabilities[i] = 0;
    } else {
      double p = pow((1.0 / map[currentCity][i]),alpha) * pow(pheromons[currentCity][i], beta);
      probabilities[i] = p;
      total += p;
    }
  }

  for (i = 0; i < nCities; i++) {
    probabilities[i] = probabilities[i] / total;
  }
}

int computeNextCity(int currentCity, int* path, int** map, int nCities, float** pheromons, float alpha, float beta) {
  int i = 0;
  double *probabilities;
  probabilities = (double*) malloc(nCities*sizeof(double));
  computeProbabilities(currentCity, probabilities, path, map, nCities, pheromons, alpha, beta);

  int value = rand() % 100 + 1;
  int sum = 0;

  for (i = 0; i < nCities; i++) {
    sum += ceilf(probabilities[i] * 100);
    if (sum >= value) {
      free(probabilities);
      return i;
    }
  }
  free(probabilities);
  return -1;
}

int updateBestPath(int bestCost, int* bestPath, int* currentPath, int** map, int nCities) {
  // compute currentCost
  int i;
  int currentCost = 0;
  int* orderedCities = (int*) malloc(nCities*sizeof(int));

  for (i = 0; i < nCities; i++) {
    orderedCities[currentPath[i]] = i;
  }

  for (i = 0; i < nCities - 1; i++) {
    currentCost += map[orderedCities[i]][orderedCities[i + 1]];
  }
  // add last
  currentCost += map[orderedCities[nCities - 1]][orderedCities[0]];

  if (bestCost > currentCost) {
    return currentCost;
  } else {
    return bestCost;
  }
}

// TODO : Formula for updating pheromons
void updatePheromons(float** pheromons, int* path, int cost, int nCities) {
  int i;
  int* orderedCities = (int*) malloc(nCities*sizeof(int));

  for (i = 0; i < nCities; i++) {
    int order = path[i];
    orderedCities[order] = i;
  }

  for (i = 0; i < nCities - 1; i++) {
    pheromons[orderedCities[i]][orderedCities[i + 1]] += 1/cost;
    pheromons[orderedCities[i + 1]][orderedCities[i]] += 1/cost;
  }
  // add last
  pheromons[orderedCities[nCities - 1]][0] += 1/cost;
  pheromons[orderedCities[0]][nCities - 1] += 1/cost;
}

#if __linux__ 

#include <sys/time.h>

double second() {
  struct timeval tp;
  struct timezone tzp;
  gettimeofday(&tp,&tzp);
  return ( (double) tp.tv_sec + (double) tp.tv_usec * 1.e-6 );
}
#elif _WIN32

#define M_PI 3.14159265359

double second() {
  SYSTEMTIME st;
  GetSystemTime(&st);
  return ( (double)  st.wSecond + (double) st.wMilliseconds * 1.e-6 );
}
#endif

