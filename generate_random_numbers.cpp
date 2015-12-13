#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <fstream>
#include <limits.h>


int main(int argc, char* argv[]) {

  if (argc != 3) {
    printf("use : %s fileName numberOfNumbers\n", argv[0]);
    return -1;
  }

  std::ofstream outfile (argv[1]);
  int size = atoi(argv[2]);
  int* array;
  int i;

  srand(time(NULL));

  // Allocation of map
  array = (int*) malloc(size*sizeof(int));

  for (i = 0; i < size; i++) {
    array[i] = (rand() % INT_MAX);
  }

  // Add the size as file first line
  outfile << size << std::endl;

  // Then copy all the matrix
  for (i = 0; i < size; i++) {
    outfile << array[i] << " ";
  }
  outfile << std::endl;

  outfile.close();

  // deallocate the pointers
  free(array);

  return 0;
}
