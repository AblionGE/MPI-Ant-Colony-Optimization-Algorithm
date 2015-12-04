CC					= g++
CFLAGS			= -O3 -Wall -ftree-vectorize -c 

LDFLAGS			= -lm
LDFLAGS_MPI	= $(LDFLAGS)

EXEC_MAP		= generate_map
EXEC_RAND		= generate_random_numbers

all: map random

map:
	$(CC) $(CFLAGS) generate_map.cpp
	$(CC) $(LDFLAGS) generate_map.o -o $(EXEC_MAP)

random:
	$(CC) $(CFLAGS) generate_random_numbers.cpp
	$(CC) $(LDFLAGS) generate_random_numbers.o -o $(EXEC_RAND)

clean:
	rm -f *.o $(EXEC_MAP)
	rm -f *.o $(EXEC_RAND)

