%Ant Colony Optimization Algorithm
%Marc Schär and Lucien Troillet
%December 17th

# Ant Colony Optimization Algorithm Principles

* A map

. . . 

* Some Ants

. . .

* Some Pheromons

. . .

* And...

. . .

* A Traveling Salesman Problem solution !

# Algorithm

## Pseudo-Code

```java
while (termination condition) {
  for each ant :
    has to visit all cities once
    chooses next city based on distance and pheromon value
  endfor
  
  reduce the global pheromon values
  update pheromons based on the best path
}
```

# Edge Selection

## Select the path

\begin{figure}[!h]
$$
p^k_{ij}(t) = \left\{ \begin{array}{ccl}
\frac{\tau_{ij}(t)^{\alpha} \cdot \eta_{ij}^{\beta}}{\sum_{l \in J_i^k} \tau_{il}(t)^{\alpha} \cdot \eta_{il}^{\beta}} & if & j \in J_i^k\\
0 & if & j \not \in J_i^k\\
\end{array}\right.
$$
\label{proba}
\end{figure}

where $J_i^k$ is the list of possible moves for an ant $k$ in the city $i$, $\eta_{ij}$ is the *visibility*, which is the inverse of the distance between two cities $i$ and $j$ and $\tau_{ij}$ the intensity of a path (the pheromon values).
$\alpha$ and $\beta$ are parameters to control the algorithm.

# Pheromons Update

## Update Pheromons

\begin{figure}[!h]
$$
\Delta \tau_{ij}^k(t) = \left\{ \begin{array}{ccl}
\frac{Q}{L^k(t)} & if & (i,j) \in T^k(t)\\
0 & if & (i,j) \not \in T^k(t)\\
\end{array}\right.
$$
\label{pheromon_update}
\end{figure}

where $T^k(t)$ is the best path of ant $k$ at iteration $t$, $L^k(t)$ is the length of the path and $Q$\footnote{We chose $Q=1$.} is a parameter to be defined.

# Assumptions and Parallelization technics

* The graph is fully connected

. . .

* A suboptimal solution can be found

. . .

* Communications are a bottleneck :
    * Several iterations locally
    * Share only the best path
    * Use broadcasting

* BUT...

. . .

* A suboptimal solution can be found with these improvements !

# Implementation with MPI

* Communications using broadcasting

. . .

* Everyone shares its best path to others

. . .

* No merge into master, everything is shared to everyone

. . .

* Termination condition variables are locally but indirectly updated through best paths sharing

# Flow Diagram

\begin{figure}
  \includegraphics[scale=0.4]{img/flow_diagram.png}
\end{figure}

# Timing Diagram
\begin{figure}
  \includegraphics[scale=0.33]{img/timing_diagram.png}
\end{figure}

# MPI - Theoretical Analysis

## Serial
$$
t_s(x) = \frac{A}{x} \cdot t_{computation}
$$

where $x$ is the number of node, $A$ the number of ants and $t_computation$ the time to do one iteration with one ant.

. . .

## Parallel
$$
t_p = t_{init} + (L + 1) \cdot t_l + t_{send} \cdot (c^2 + n \cdot c \cdot L) + L \cdot l \cdot t_s(n)
$$

where $n$ are the number of nodes, $L$ the number of external iterations, $l$ the number of internal iterations, $t_l$ the network latency, $t_{init}$ the time to initialize the problem and $t_{send}$ the time to send a byte.

. . .

## Speedup
$$
S_n = \frac{t_{init} + L \cdot l \cdot t_s(1)}{t_{init} + (L + 1) \cdot t_l + t_{send} \cdot (c^2 + n \cdot c \cdot L) + L \cdot l \cdot t_s(n)}
$$

# MPI - Speedup

\begin{figure}[!h]
  \centering \includegraphics[scale=0.25]{img/theoretical_speedup.png}
  \caption{\it Theoretical speedup for 16 ants, 1000 cities and 5000 iterations (50 internals * 100 externals).}
\end{figure}

# MPI - Experimentation Speedups

TO OBTAIN

# MPI - Conclusion

* Really good in theory
* Really good speedups but non optimal solutions
* Difficult parallelization for this problem

. . .

## TODO

* Do more tests
* Check theoretical analysis
* Conclude if a good solution for parallel implementation exists

# Implementation with DPS

## Flowgraph

## Complexity
A remplir comme tu veux

