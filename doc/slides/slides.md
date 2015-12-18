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

# Assumptions and Parallelization Strategies

* The graph is fully connected

. . .

* A suboptimal solution can be found

. . .

* Distribute Ants among all nodes
    * All nodes have the same map and the same number of iterations

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

## Iteration Time
$$
t_{iter}(x) = \frac{A}{x} \cdot t_{computation}
$$

where $x$ is the number of node, $A$ the number of ants and $t_{computation}$ the time to do one iteration with one ant.

. . .

## Parallel
$$
t_p = t_{init} + (L + 1) \cdot t_l + t_{send} \cdot (c^2 + n \cdot c \cdot L) + L \cdot l \cdot t_{iter}(n)
$$

where $n$ are the number of nodes, $L$ the number of external iterations, $l$ the number of internal iterations, $t_l$ the network latency, $t_{init}$ the time to initialize the problem and $t_{send}$ the time to send a byte.

. . .

## Speedup
$$
S_n = \frac{t_{init} + L \cdot l \cdot t_{iter}(1)}{t_{init} + (L + 1) \cdot t_l + t_{send} \cdot (c^2 + n \cdot c \cdot L) + L \cdot l \cdot t_{iter}(n)}
$$

# MPI - Theoretical Speedup

\begin{figure}[!h]
  \centering \includegraphics[scale=0.36]{img/theoretical_speedup.png}
  \caption{\it Theoretical speedup for 32 ants, 1000 cities and 5000 iterations (50 internals * 100 externals).}
\end{figure}

# MPI - Experimentation Speedups

\begin{figure}[!h]
  \centering \includegraphics[scale=0.75]{img/mpi_absolute_speedup_random7.pdf}
  \caption{\it Absolute speedup for 32 ants, 1000 cities and 5000 iterations (50 internals * 100 externals).}
\end{figure}

# MPI - Good Speedup, but good results ?

\begin{figure}[!h]
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Rand1 & 1233369 & 1233369 & 3469656 & 3159149 & 2738298 & 4004101\\
    \hline
    \bf Rand2 & 1121100 & 1121100 & 2990821 & 2877721 & 3928670 & 3928670\\
    \hline
    \bf Rand3 & 1247895 & 1247895 & 3118389 & 2903353 & 2776783 & 3999514\\
    \hline
    \bf Rand4 & 981889 & 981889 & 3238522 & 3538185 & 2742370 & 3958821\\
    \hline
    \bf Rand5 & 808166 & 808166 & 3043537 & 3899536 & 2873090 & 3998822\\
    \hline
    \bf Rand6 & 787995 & 787995 & 3238042 & 3166487 & 3985601 & 3985601\\
    \hline
    \bf Rand7 & 976544 & 976544 & 3892884 & 2971335 & 3993333 & 4002138\\
    \hline
    \bf Rand8 & 826622 & 826622 & 3144011 & 2956238 & 3946642 & 4006634\\
    \hline
    \bf Rand9 & 854722 & 854722 & 3188041 & 3042242 & 3892735 & 3924025\\
    \hline
    \bf Rand10 & 972916 & 972916 & 3020228 & 3022016 & 3961876 & 3961876\\
    \hline
  \end{tabular}
  \caption{Cost of best path for 10 random numbers files for 32 ants, 1000 cities and 5000 iterations (50 internals * 100 externals)}
\end{figure}

# MPI - Result Summary

\begin{figure}[!h]
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Nb of Nodes & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 10 & 10 & 10 & 10\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Number of wins in term of cost of best path for 10 tests}
\end{figure}

# MPI - Conclusion

* Really good in theory
* Really good speedups but non optimal solutions
* Difficult parallelization for this problem

. . .

## TODO

* Do more tests
* Check theoretical analysis
* Conclude if a good solution for parallel implementation exists
* Test with sharing only the best path and keep no history locally

# Implementation with DPS

* Communication using Round robin routing of packets

. . .

* Best path is selected on main thread and sent to all others

. . .

* All communication is handled by master

. . .

* Termination condition and variables of interest are monitored by master

# Flowgraph

\begin{figure}
  \includegraphics[scale=0.5]{img/Flowgraph.png}
\end{figure}

# DPS Theoretical Analysis

## Parallel without Flow Control

$$
t_p = t_{init P} + t_{send} \cdot (n \cdot c \cdot i) + i \cdot t_s(n)
$$
Where $t_{init P} = t_{send} \cdot n \cdot c^2 + t_{init}$

. . . 

## Parallel with Flow Control

$$
t_p = t_{init P} + i \cdot t_s(n)
$$
Flow control allows next iteration to start while packets are being sent and new best path is being processed thus covering up the communication time.

. . .

## Speedup

$$
S_n = \frac{t_{init} + i \cdot t_s(1)}{t_{send} \cdot n \cdot c^2 + t_{init} + i \cdot t_s(n)}
$$

# DPS Conclusion

* Lack of broadcast in DPS implies big time loss for initialization
* Flow control is good to absorb communication time

## TODO

* Working implementation needs to be completed
* Test variants of the algorithm for pheromone updates

# Questions

\begin{figure}
  \includegraphics[scale=0.8]{img/questions.jpg}
\end{figure}
