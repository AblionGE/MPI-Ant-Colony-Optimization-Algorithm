# Introduction

In the context of the *Program Parallelization on PC Clusters* course, we have to analyze and implement a parallel application to observe the improvements brought by the parallelization of a serial application.
The goal of this project is to anticipate the performance of the parallelized application and to confirm or invalidate the claimed theory.

For this project, I chose to implement an *ant colony optimization algorithm* which gives a solution to the *Traveling Salesman Problem*.

In this report, I will first present a description of the algorithm with a generic pseudo-code, my choices to implement it, the possible problems and solutions and an example of representation of the map.
Then, I will make a theoretical analysis of the serial and parallel implementations of the algorithm.
Afterwards, I will present results obtained with a MPI implementation, including speedups and comments on the results.
Finally, I will make a small conclusion.

## Algorithm

### Description

We want to solve the *Traveling salesman problem* with ants.
The idea is to have several ants that are spread randomly on the map.
Each ant will go through the map and find a path between all cities without visiting twice the same city.
At each step, the ant will select the next city with some probability depending on distance and pheromon value.
When all ants are done, the pheromons on all the map are reduced by a factor such that edges that are less used have a smaller value.
Finally, it updates the visited edges of the best path\footnote{It is a choice to keep only the best path between all ants.} with pheromons to give more importance to this path for the next iterations. Then, it starts from the beginning until a termination condition is met.

The final goal is to find the shortest path that starts in a city and that arrives in this city going only once through each other city.

The standard termination condition is defined as a maximum number of iterations and/or the same shortest solution after a certain number of iterations.

### Pseudo-code

The general algorithm of the *ant colony optimization algorithm* is the following\footnote{This algorithm is based on the \textit{Ant Colony optimization algorithms} found on wikipedia (in french) : https://fr.wikipedia.org/wiki/Algorithme\_de\_colonies\_de\_fourmis} :

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

### Possible problems and solutions

There are several problems that can happen with this algorithm :

* The ant can be stucked in a city if the graph is not fully connected.
    * A possible solution is to kill ants that are in this situation;
    * Another possibility is to transform the graph in a fully connected one with unreasonnable edges for non existing paths\footnote{I chose this solution.}.
* A suboptimal solution can be found
    * To solve this, it is sufficient to run the algorithm several times\footnote{With some improvements for the parallel implementation, the optimal solution will possibly not be reached often.}.
* An isolated city with only one connection to the rest of the graph will make the resolution of the *TSP* impossible.
    * The solution is to assume that each city has at least two connected edges.
* To parallelize this problem, the exchange of pheromon values can be a bottleneck (lot of communications).
    * A possible solution is to run several iterations locally before sharing the result;
    * Another possibility is to send only the updated values and not all the matrix.
    * The exchange of informations can be done using broadcasting between all nodes instead of giving all results to the master that will redestribute them to each node.


### Edge selection

\label{formula}

An ant will select a path according to some probabilities that includes edge's length and pheromon values :

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

Finally, I also define $\rho \tau_{ij}(t)$ which represents the pheromon evaporation that is computed at each iteration.

### Pheromon update

At the end of each *external* loop, the pheromon values are updated according to the best path of the current iteration.
To spread pheromons such that shortest paths between several iterations will have more pheromons than longer ones, I define formula presented in figure \ref{pheromon_update}.

\begin{figure}[!h]
$$
\Delta \tau_{ij}^k(t) = \left\{ \begin{array}{ccl}
\frac{Q}{L^k(t)} & if & (i,j) \in T^k(t)\\
0 & if & (i,j) \not \in T^k(t)\\
\end{array}\right.
$$
\caption{\it Update pheromons definition. $T^k(t)$ is the best path of ant $k$ at iteration $t$, $L^k(t)$ is the length of the path and $Q$i (I chose $Q=1$) is a parameter to be defined.}
\label{pheromon_update}
\end{figure}

### Representation

To represent this algorithm in a computer, we have to model a map with a graph.
Each vertex will represent a city and edges will represent connections between cities.
Each edge has a weight representing the distance between all cities.
As we want to have a fully connected graph, edges that connect unlinked cities will have a maximal weight (which will be defined in the implementation of the algorithm).
Figures \ref{map} and \ref{matrix} show how to represent the map.

\begin{figure}[!h]
  \begin{subfigure}{.5\textwidth}
    \centering \includegraphics[scale=0.5]{img/example_graph.png}
    \caption{\it A map composed by cities and paths}
    \label{map}
  \end{subfigure}%
  \begin{subfigure}{.5\textwidth}
$$ 
\left( \begin{array}{cccccc}
  0 & 5 & 1 & 2 & \infty & \infty \\
  5 & 0 & \infty & 3 & \infty & \infty \\
  1 & \infty & 0 & 2 & \infty & \infty \\
  2 & 3 & 2 & 0 & 4 & 3 \\
  \infty & \infty & \infty & 4 & 0 & 1 \\
  \infty & \infty & \infty & 3 & 1 & 0 \\
\end{array} \right)
$$
    \caption{\it The matrix representing figure \ref{map}.}
    \label{matrix}
  \end{subfigure}
  \caption{\it Representation of a map in a computer.}
\end{figure}

Each ant will simply be represented by finding a path on the map from different starting points.
To find a path, the solution is to select a path from the current city (select an element in a column) being careful to not select an already visited city and selecting a city following the formula in section \ref{formula}.

We can note that the pheromon values need to be stored in a matrix, too. This matrix will have the same construction as the one in figure \ref{matrix}.

\newpage{}
