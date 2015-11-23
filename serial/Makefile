CC					= g++
MPICC				= mpicc
CFLAGS			= -O3 -Wall -ftree-vectorize -c 
CFLAGS_MPI	= -O3 -Wall -c -Wunused-variable

LDFLAGS			= -lm
LDFLAGS_MPI	= $(LDFLAGS)

EXEC_SERIAL	= serial_ant_colony
EXEC_MPI		= mpi_ant_colony
EXEC_MAP		= generate_map

all: serial map

serial: 

	$(CC) $(CFLAGS) ant_colony.cpp
	$(CC) $(LDFLAGS) ant_colony.o -o $(EXEC_SERIAL)

map:
	$(CC) $(CFLAGS) generate_map.cpp
	$(CC) $(LDFLAGS) generate_map.o -o $(EXEC_MAP)

mpi: 
	$(MPICC) $(CFLAGS_MPI) mpi_ant_colony.c
	$(MPICC) $(LDFLAGS_MPI) mpi_ant_colony.o -o $(EXEC_MPI)

clean:
	rm -f *.o $(EXEC_SERIAL) $(EXEC_MPI) $(EXEC_MAP)

