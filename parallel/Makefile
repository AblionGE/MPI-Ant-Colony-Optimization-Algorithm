MPICC				= mpicc
CFLAGS_MPI	= -O3 -Wall -c -Wunused-variable

LDFLAGS_MPI	= $(LDFLAGS)

EXEC_MPI		= mpi_ant_colony

all: mpi

mpi: 
	$(MPICC) $(CFLAGS_MPI) mpi_ant_colony.cpp
	$(MPICC) $(LDFLAGS_MPI) mpi_ant_colony.o -o $(EXEC_MPI)

clean:
	rm -f *.o $(EXEC_MPI)

