CC					= g++
CFLAGS			= -O3 -Wall -ftree-vectorize -c 

LDFLAGS			= -lm
LDFLAGS_MPI	= $(LDFLAGS)

EXEC_SERIAL	= serial_ant_colony

all: serial

serial: 
	$(CC) $(CFLAGS) serial_ant_colony.cpp
	$(CC) $(LDFLAGS) serial_ant_colony.o -o $(EXEC_SERIAL)

clean:
	rm -f *.o $(EXEC_SERIAL)

