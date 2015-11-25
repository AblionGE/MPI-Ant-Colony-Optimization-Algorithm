CC					= g++
CFLAGS			= -O3 -Wall -ftree-vectorize -c 

LDFLAGS			= -lm
LDFLAGS_MPI	= $(LDFLAGS)

EXEC_MAP		= generate_map

all: map

map:
	$(CC) $(CFLAGS) generate_map.cpp
	$(CC) $(LDFLAGS) generate_map.o -o $(EXEC_MAP)

clean:
	rm -f *.o $(EXEC_MAP)

