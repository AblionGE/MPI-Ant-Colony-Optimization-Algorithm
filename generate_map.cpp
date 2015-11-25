#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <fstream>


int main(int argc, char* argv[]) {

  if (argc != 4) {
    printf("use : %s filename size maximalDistance\n", argv[0]);
    return -1;
  }

  std::ofstream outfile (argv[1]);
  int size = atoi(argv[2]);
  int maxDistance = atoi(argv[3]);
  int**map;
  int i, j;

  // Allocation of map
  map = (int**) malloc(size*sizeof(int*));
  for (i = 0; i < size; i++) {
    map[i] = (int*) malloc(size*sizeof(int));

  }

  for (i = 0; i < size; i++) {
    for (j = i; j < size; j++) {
      if (i == j) {
        map[i][j] = 0;
      } else {
        map[i][j] = (rand() % maxDistance) + 1;
        map[j][i] = map[i][j];
      }
    }
  }



  // Add the size as file first line
  outfile << size << std::endl;

  // Then copy all the matrix
  for (i = 0; i < size; i++) {
    for (j = 0; j < size; j++) {
      outfile << map[i][j] << " "; 
    }
    outfile << std::endl;
  }

  outfile.close();

  // deallocation of the rows
  for(i=0; i<size; i++) {
    free(map[i]);
  }

  // deallocate the pointers
  free(map);

  return 0;
}
