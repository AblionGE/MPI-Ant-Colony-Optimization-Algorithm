# MPI Results

In this section, I will present the results obtained with a MPI program for the *ant colony optimization problem*.

## Implementation 

For both implementations (serial and parallel), I chose to implement a ```utils.h``` file to share common functions between all implementations. This file contains functions to help to debug the code (like ```printMap()```, ```copyVector()``` to copy a vector into another one or functions to get the current time.

For solving the problem, I implemented several functions that are useful to find a path or to get the cost of a path, but I also have implemented two functions to choose the next city when an ant is computing its path :

```C
/**
 * Compute the probability to go in each city from current city
 **/
void computeProbabilities(int currentCity, double* probabilities, int* path, int* map,
  int nCities, double* pheromons, double alpha, double beta) {

  int i;
  double total = 0;
  for (i = 0; i < nCities; i++) {
    if (path[i] != -1 || i == currentCity) {
      probabilities[i] = 0.0;
    } else {
      double p = pow(1.0 / map[getMatrixIndex(currentCity,i,nCities)],alpha) *
        pow(pheromons[getMatrixIndex(currentCity,i,nCities)], beta);
      probabilities[i] = p;
      total += p;
    }
  }

  // If all the probabilities are really small
  // We select one (not randomly to have always the same behavior)
  if (total == 0) {
    i = 0;
    for (i = 0; i < nCities; i++) {
      if (path[i] == -1 && i != currentCity) {
        probabilities[i] = 1.0;
        total++;
      }
    }
  }

  for (i = 0; i < nCities; i++) {
    probabilities[i] = probabilities[i] / total;
  }
}

/**
 * Given the current city, select the next city to go to (for an ant)
 **/
int computeNextCity(int currentCity, int* path, int* map, int nCities,
  double* pheromons, double alpha, double beta, long random) {

  int i = 0;
  double *probabilities;
  probabilities = (double*) malloc(nCities*sizeof(double));
  computeProbabilities(currentCity, probabilities, path, map, nCities, pheromons,
    alpha, beta);

  int value = (random % 100) + 1;
  int sum = 0;

  for (i = 0; i < nCities; i++) {
    sum += ceilf(probabilities[i] * 100);
    if (sum >= value) {
      free(probabilities);
      return i;
    }
  }
  free(probabilities);
  return -1;
}
```

As you can observe, the formula presented in section \ref{formula} is implemented in ```computeProbabilities()```. You can also see that, according to limitations in number precision, sometimes, we can have all probabilities to 0. In this case, I simply choose to give equal probabilities to each cities that were not visited by the ant.

In ```utils.h```, I also implement the function to update the pheromons after a local iteration :

```C
/**
 * Update the pheromons in the pheromons matrix given the current path
 *
 * The maximum pheromon value for an edge is 1.
 **/
void updatePheromons(double* pheromons, int* path, long cost, int nCities) {
  int i;
  int* orderedCities = (int*) malloc(nCities*sizeof(int));

  for (i = 0; i < nCities; i++) {
    int order = path[i];
    orderedCities[order] = i;
  }

  for (i = 0; i < nCities - 1; i++) {
    pheromons[getMatrixIndex(orderedCities[i],orderedCities[i + 1], nCities)] +=
      1.0/cost;
    pheromons[getMatrixIndex(orderedCities[i + 1],orderedCities[i], nCities)] +=
      1.0/cost;
    if (pheromons[getMatrixIndex(orderedCities[i],orderedCities[i + 1], nCities)] > 1)
    {
      pheromons[getMatrixIndex(orderedCities[i],orderedCities[i + 1], nCities)] = 1.0;
      pheromons[getMatrixIndex(orderedCities[i + 1],orderedCities[i], nCities)] = 1.0;
    }
  }
  // add last
  pheromons[getMatrixIndex(orderedCities[nCities - 1],orderedCities[0],nCities)] +=
    1.0/cost;
  pheromons[getMatrixIndex(orderedCities[0],orderedCities[nCities - 1], nCities)] +=
    1.0/cost;
  if (pheromons[getMatrixIndex(orderedCities[nCities - 1],orderedCities[0],nCities)] > 
    1.0) {

    pheromons[getMatrixIndex(orderedCities[nCities - 1],orderedCities[0],nCities)] =
      1.0;
    pheromons[getMatrixIndex(orderedCities[0],orderedCities[nCities - 1], nCities)] =
      1.0;
  }
}
```

I had to limit the maximum value of pheromons to 1 because in some cases, it can become bigger than 1 and then, if the program runs long enough, it can diverge to the infinity.

### Serial

For the serial implementation, I simply take the general algorithm of the *ant colony optimization problem* and I implement it in ```C``` with a bit of ```C++```. Here is the implementation of the algorithm with the whole loop (for details, see code). We must be careful with the "random" part of this algorithm. Indeed, to compare implementations together, we need to have the same random numbers to observe if the result has the same quality between all implementations. Thus, I load a file composed by random numbers and then, everytime I need to have a random number, I take the number from the file (in an incrementally manner).

```C
// External loop
  while (loop_counter < iterations && 
    terminationCondition < (long) ceilf(iterations * terminationConditionPercentage)) {

    // Loop over each ant
    for (ant_counter = 0; ant_counter < nAnts; ant_counter++) {
      // init currentPath 
      // -1 means not visited
      for (i = 0; i < nCities; i++) {
        currentPath[i] = -1;
      }

      // select a random start city for an ant
      long rand = randomNumbers[random_counter];
      int currentCity = rand % nCities;
      random_counter = (random_counter + 1) % nRandomNumbers;
      // currentPath will contain the order of visited cities
      currentPath[currentCity] = 0;
      for (cities_counter = 1; cities_counter < nCities; cities_counter++) {
        // Find next city
        rand = randomNumbers[random_counter];
        currentCity = computeNextCity(currentCity, currentPath, map, nCities,
          pheromons, alpha, beta, rand);
        random_counter = (random_counter + 1) % nRandomNumbers;


        if (currentCity == -1) {
          printf("There is an error choosing the next city in iteration %d
            for ant %d\n", loop_counter, ant_counter);
          return -1;
        }

        // add next city to plan
        currentPath[currentCity] = cities_counter;
      }

      // update bestCost and bestPath
      long oldCost = bestCost;
      bestCost = computeCost(bestCost, bestPath, currentPath, map, nCities);

      if (oldCost > bestCost) {
        copyVectorInt(currentPath, bestPath, nCities);
      }
    }

    if (bestCost < antsBestCost) {
      antsBestCost = bestCost;
      terminationCondition = 0;
    } else {
      terminationCondition++;
    }

    // Pheromon evaporation
    for (j = 0; j < nCities*nCities; j++) {
      pheromons[j] *= evaporationCoeff;
    }
    // Update pheromons
    updatePheromons(pheromons, bestPath, bestCost, nCities);

    loop_counter++;
  }
```

As you can see, the main part of the code is quite simple and is composed by less than 100 lines of code.

### Parallel

For the parallel implementation, I need to implement communication between nodes. Thus, it will have a lot of communications at the beginning of the execution to share all useful informations (map, number of ants for each node for example) between all nodes. As mentionned in the theoretical analysis, for all of these communications I use *broadcasting*.

For sharing ants between nodes, we can note that each node computes the distribution.
This is needed because each node has to know how much ants have the others to take the right random numbers from the file (to have a comparable result at the end of the algorithm with other implementations) :

```C
int antsPerNode = totalNAnts / psize;
int restAnts = totalNAnts - antsPerNode * psize;

for (i = 0; i < psize; i++) {
  nAntsPerNode[i] = antsPerNode;
  if (restAnts > i) {
    nAntsPerNode[i]++;
  }
}

nAnts = nAntsPerNode[prank];

// Compute number of ants in nodes before me (prank smaller than mine)
int nAntsBeforeMe = 0;
for (i = 0; i < psize; i++) {
  if (i < prank) {
    nAntsBeforeMe += nAntsPerNode[i];
  } else {
    i = psize;
  }
}
```

About the algorithm itself, the implementation is strictly the same except that I can use internal and external loops to reduce communications (it is presented in the theoretical analysis).
The algorithm looks like this one : 

```C
// Set the random counter to have right random values in each nodes
random_counter = (random_counter + (onNodeIteration * nAntsBeforeMe * nCities)) %
  nRandomNumbers;

while (external_loop_counter < externalIterations &&
  terminationCondition < (long) ceilf(externalIterations * onNodeIteration *
    terminationConditionPercentage)) {

  loop_counter = 0;
  while (loop_counter < onNodeIteration) {
    // Serial algorithm
    loop_counter++;
  }
  
  // Merging part

  external_loop_counter++;

  // Set the counter correctly for next random numbers on current node
  random_counter = (random_counter + (onNodeIteration * (totalNAnts - nAnts) *
    nCities)) % nRandomNumbers;
}
```
As not all improvements are good in term of result quality, I will present the three different ways I chose the do for merging informations between nodes. Thus, how communications are made will be presented in subsection \ref{optimality_section}.

Nevertheless, we can note here that, for sharing informations, each node needs to send to each other its best path of the iteration, but also its bestCost, its pheromons values on its best path (each node has its own local history) and the termination condition.
Then, receiving nodes have to compare best path with their own and, if the received cost is better, the node updates its own best path, its best cost and its termination condition.
The merge of pheromons depends on implementation (see subsection \ref{optimality_section}).
We still can note that for merging pheromons, we always add the received pheromons value with our own and the we compute the average for each edge.

## Optimality of results
\label{optimality_section}

### First parallel implementation
\label{parallel1}

For the first implementation, I chose to share between nodes all best paths found on each node after a certain number of local iterations. To do that, I simply need to merge pheromons values received by all other nodes :

```C
for (i = 0; i < psize; i++) {

  // Communications

  // If i am not node i, I will check if values from node i are better than mine
  if (prank != i) {
    if (otherBestCost < tempBestCost) {
      tempTerminationCondition = otherTerminationCondition;
      tempBestCost = otherBestCost;
      copyVectorInt(otherBestPath, tempBestPath,  nCities);
    } else if (otherBestCost == tempBestCost) {
      // If the best cost is the same as mine,
      // I simply update the termination condition counter
      tempTerminationCondition += otherTerminationCondition;
    }

    // Update pheromons received from other node
    for (j = 0; j < nCities - 1; j++) {
      pheromonsUpdate[getMatrixIndex(otherBestPath[j],otherBestPath[j+1],nCities)] +=
        1.0;
      pheromonsUpdate[getMatrixIndex(otherBestPath[j+1],otherBestPath[j],nCities)] +=
        1.0;
      pheromons[getMatrixIndex(otherBestPath[j],otherBestPath[j+1],nCities)] +=
        otherPheromonsPath[j];
      pheromons[getMatrixIndex(otherBestPath[j+1],otherBestPath[j],nCities)] +=
        otherPheromonsPath[j];
    }
    pheromonsUpdate[getMatrixIndex(otherBestPath[nCities-1],otherBestPath[0],nCities)]
      += 1.0;
    pheromonsUpdate[getMatrixIndex(otherBestPath[0],otherBestPath[nCities-1],nCities)]
      += 1.0;
    pheromons[getMatrixIndex(otherBestPath[nCities-1],otherBestPath[0],nCities)]
      += otherPheromonsPath[nCities - 1];
    pheromons[getMatrixIndex(otherBestPath[0],otherBestPath[nCities-1],nCities)]
      += otherPheromonsPath[nCities - 1];
  }
}
```

To test this code, I tried with one local iteration and with hundred local iterations and also with and without the termination condition (stop after we consider the result stable enough).
In all cases, I did 5 executions with 5 different sets of random numbers. The figures show the costs for the serial implementation the parallel one with 1, 2, 4, 8 and 16 nodes. Other results can be found in the *result* folder.

All executions were made with 500 cities, 30'000 iterations, $\alpha$ and $\beta$ equal to 1, 0.9 for evaporation coefficient and 32 ants\footnote{In the \textit{result} folder, you can find executions with less iterations or less ants. Indeed, I observed that if the number of iterations is not big enough compared to the problem size, the serial implementation has not enough time to converge compared to the parallel implementation using many nodes.}.


\textbf{One local iteration without termination condition} (figures \ref{onewithout1} and \ref{summary_onewithout1})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 206048 & 206048 & 138189 & 111941 & 133976 & 158574\\
    \hline
    \bf rand2 & 170317 & 170317 & 155951 & 122354 & 121297 & 142920\\
    \hline
    \bf rand3 & 162412 & 162412 & 142151 & 126308 & 128463 & 152194\\
    \hline
    \bf rand4 & 174843 & 174843 & 129743 & 136157 & 118470 & 136531\\
    \hline
    \bf rand5 & 179263 & 179263 & 138748 & 121309 & 116606 & 123602\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewithout1}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 0 & 0 & 0 & 0\\
    \hline
    \bf Parallel beats Serial & 0 & 5 & 5 & 5 & 5\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{onewithout1})}
  \label{summary_onewithout1}
\end{figure}

\FloatBarrier

\textbf{Hundred local iterations without termination condition} (figures \ref{hundredwithout1} and \ref{summary_hundredwithout1})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 175888 & 175888 & 189019 & 205045 & 220125 & 224030\\
    \hline
    \bf rand2 & 181575 & 181575 & 186233 & 238031 & 197331 & 232079\\
    \hline
    \bf rand3 & 187249 & 187249 & 217756 & 240954 & 210066 & 234327\\
    \hline
    \bf rand4 & 174060 & 174060 & 212855 & 217611 & 215536 & 232093\\
    \hline
    \bf rand5 & 170319 & 170319 & 184519 & 230064 & 230072 & 286673\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwithout1}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5 & 5 & 5 & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{hundredwithout1})}
  \label{summary_hundredwithout1}
\end{figure}

\FloatBarrier

\textbf{One local iteration with termination condition} (figures \ref{onewith1} and \ref{summary_onewith1})

I also tested to use another termination condition that is to have the same best cost after a certain number of iterations.
For the results presented here (and below), the termination condition was of 70% of the total number of loops.
We can observe that with this termination condition. the parallel algorithm converges really quickly, but the result is clearly bad and worst than the one from the serial implementation.
Thus, I gave up this improvement.

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 169560 & 169560 & 1730115 & 1730115 & 1730115 & 1730115\\
    \hline
    \bf rand2 & 172790 & 172790 & 1780674 & 1780674 & 1780674 & 1780674\\
    \hline
    \bf rand3 & 177731 & 177731 & 1779516 & 1779516 & 1779516 & 1779516\\
    \hline
    \bf rand4 & 193771 & 193771 & 1789632 & 1798642 & 1798642 & 1798642\\
    \hline
    \bf rand5 & 185177 & 185177 & 1772935 & 1765619 & 1772935 & 1772935\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewith1}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5 & 5 & 5 & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{onewith1})}
  \label{summary_onewith1}
\end{figure}

\FloatBarrier

\textbf{Hundred local iterations with termination condition} (figures \ref{hundredwith1} and \ref{summary_hundredwith1})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 180300 & 180300 & 1685680  & 1578882    & 1577008        & 1661177\\
    \hline
    \bf rand2 & 166614 & 166614 & 1581740  & 1612139    & 1679066        & 1680811\\
    \hline
    \bf rand3 & 173203 & 173203 & 1576155  & 1680125    & 1740822        & 1679923\\
    \hline
    \bf rand4 & 173117 & 173117 & 1688282  & 1672961    & 1566590        & 1656622\\
    \hline
    \bf rand5 & 172340 & 172340 & 1628961  & 1713106    & 1713106        & 1693083\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwith1}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5 & 5 & 5 & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{hundredwith1})}
  \label{summary_hundredwith1}
\end{figure}

\FloatBarrier

### Second parallel implementation

For the second implementation, I tried to share only the best path between all nodes at each external iteration. To do that, each node has still to share its best values but it keeps only the best received one (or its own if it has the best result). In term of code, the only impact is that the update of pheromons from others is done after the ```for``` loop and not in the loop (loop presented in subsection \ref{parallel1}).

\textbf{One local iteration without termination condition} (figures \ref{onewithout2} and \ref{summary_onewithout2})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 206048 & 206048 & 137135 & 133420 & 109250 & 135306\\
    \hline
    \bf rand2 & 170317 & 170317 & 159457 & 128820 & 122768 & 160282\\
    \hline
    \bf rand3 & 162412 & 162412 & 146277 & 175978 & 118603 & 149297\\
    \hline
    \bf rand4 & 174843 & 174843 & 146865 & 145787 & 140152 & 124771\\
    \hline
    \bf rand5 & 179263 & 179263 & 168949 & 147701 & 128391 & 140151\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewithout2}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 0 & 1 & 0 & 0\\
    \hline
    \bf Parallel beats Serial & 0 & 5 & 4 & 5 & 5\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{onewithout2})}
  \label{summary_onewithout2}
\end{figure}

\FloatBarrier

\textbf{Hundred local iterations without termination condition} (figures \ref{hundredwithout2} and \ref{summary_hundredwithout2})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 175888 & 175888 & 189019 & 205045 & 220125 & 224030\\
    \hline
    \bf rand2 & 181575 & 181575 & 186233 & 238031 & 197331 & 232079\\
    \hline
    \bf rand3 & 187249 & 187249 & 217756 & 240954 & 210066 & 234327\\
    \hline
    \bf rand4 & 174060 & 174060 & 212855 & 217611 & 215536 & 232093\\
    \hline
    \bf rand5 & 170319 & 170319 & 184519 & 230064 & 230072 & 286673\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwithout2}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5 & 5 & 5 & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{hundredwithout2})}
  \label{summary_hundredwithout2}
\end{figure}

\FloatBarrier

\textbf{One local iteration with termination condition} (figures \ref{onewith2} and \ref{summary_onewith2})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 169560 & 169560 & 1730115 & 1730115 & 1730115 & 1730115\\
    \hline
    \bf rand2 & 172790 & 172790 & 1780674 & 1780674 & 1780674 & 1780674\\
    \hline
    \bf rand3 & 177731 & 177731 & 1779516 & 1779516 & 1779516 & 1779516\\
    \hline
    \bf rand4 & 193771 & 193771 & 1789632 & 1798642 & 1798642 & 1798642\\
    \hline
    \bf rand5 & 185177 & 185177 & 1772935 & 1765619 & 1772935 & 1772935\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewith2}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5 & 5 & 5 & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{onewith2})}
  \label{summary_onewith2}
\end{figure}

\FloatBarrier

\textbf{Hundred local iterations with termination condition} (figures \ref{hundredwith2} and \ref{summary_hundredwith2})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 180300 & 180300 & 1685680 & 1578882 & 1577008 & 1661177\\
    \hline
    \bf rand2 & 166614 & 166614 & 1581740 & 1612139 & 1679066 & 1680811\\
    \hline
    \bf rand3 & 173203 & 173203 & 1576155 & 1680125 & 1740822 & 1679923\\
    \hline
    \bf rand4 & 173117 & 173117 & 1688282 & 1672961 & 1566590 & 1656622\\
    \hline
    \bf rand5 & 172340 & 172340 & 1628961 & 1713106 & 1713106 & 1693083\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwith2}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5 & 5 & 5 & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{hundredwith2})}
  \label{summary_hundredwith2}
\end{figure}

\FloatBarrier

### Third parallel implementation

For the third implementation, I chose to share all the pheromons matrix instead of only the values from the best path. The code becomes simple, because you just have to send the matrix in one message : 

```C
if (MPI_Bcast(&otherPheromons[0], nCities * nCities, MPI_DOUBLE, i, MPI_COMM_WORLD)
  != MPI_SUCCESS) {

  printf("Node %d : Error in Broadcast of otherPheromons", prank);
  MPI_Finalize();
  return -1;
}
```

Of course, there will be a lot of communication for nothing (the majority of the matrix will have low values close to 0.

\textbf{One local iteration without termination condition} (figures \ref{onewithout3} and \ref{summary_onewithout3})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 206048 & 206048 & 226692 & 229382 & 272316 & 299090\\
    \hline
    \bf rand2 & 170317 & 170317 & 240895 & 202389 & 270666 & 281549\\
    \hline
    \bf rand3 & 162412 & 162412 & 180564 & 197930 & 297000 & 353603\\
    \hline
    \bf rand4 & 174843 & 174843 & 240735 & 227874 & 287405 & 338268\\
    \hline
    \bf rand5 & 179263 & 179263 & 203006 & 226798 & 205372 & 301789\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewithout3}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5 & 5 & 5 & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{onewithout3})}
  \label{summary_onewithout3}
\end{figure}

\FloatBarrier

\textbf{Hundred local iterations without termination condition} (figures \ref{hundredwithout3} and \ref{summary_hundredwithout3})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 175888 & 175888 & 157072 & 235568 & 224547 & 319924\\
    \hline
    \bf rand2 & 181575 & 181575 & 190208 & 235288 & 221798 & 293365\\
    \hline
    \bf rand3 & 187249 & 187249 & 162000 & 187241 & 204388 & 262212\\
    \hline
    \bf rand4 & 174060 & 174060 & 185468 & 229670 & 269884 & 415996\\
    \hline
    \bf rand5 & 170319 & 170319 & 176118 & 243859 & 220186 & 307723\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwithout3}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 3 & 4 & 5 & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{hundredwithout3})}
  \label{summary_hundredwithout3}
\end{figure}

\FloatBarrier

\textbf{One local iteration with termination condition} (figures \ref{onewith3} and \ref{summary_onewith3})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 169560 & 169560 & 1730115 & 1730115 & 1730115 & 1730115\\
    \hline
    \bf rand2 & 172790 & 172790 & 1600713 & 1715129 & 1780674 & 1733414\\
    \hline
    \bf rand3 & 177731 & 177731 & 1699064 & 1708854 & 1722617 & 1720331\\
    \hline
    \bf rand4 & 193771 & 193771 & 1669645 & 1688394 & 1741155 & 1691904\\
    \hline
    \bf rand5 & 185177 & 185177 & 1618844 & 1686588 & 1765619 & 1690262\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewith3}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5 & 5 & 5 & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{onewith3})}
  \label{summary_onewith3}
\end{figure}

\FloatBarrier

\textbf{Hundred local iterations with termination condition} (figures \ref{hundredwith3} and \ref{summary_hundredwith3})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 180300 & 180300 & 1641854 & 1509437 & 1568793 & 1721353\\
    \hline
    \bf rand2 & 166614 & 166614 & 1632773 & 1559375 & 1598569 & 1737959\\
    \hline
    \bf rand3 & 173203 & 173203 & 1565889 & 1595390 & 1713859 & 1710915\\
    \hline
    \bf rand4 & 173117 & 173117 & 1689794 & 1712136 & 1641396 & 1770857\\
    \hline
    \bf rand5 & 172340 & 172340 & 1641177 & 1691355 & 1713106 & 1743854\\
    \hline
  \end{tabular}
  \caption{Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwith3}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5 & 5 & 5 & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0 & 0 & 0 & 0\\
    \hline
  \end{tabular}
  \caption{Summary of measurement from previous figure (\ref{hundredwith3})}
  \label{summary_hundredwith3}
\end{figure}

\FloatBarrier

## Speedups

For the different speedups, we can note that for all tests I have made, the speedup always looks like the same. Thus, I will only present one relative and one absolute speedup for one execution of my program, knowing that the others are similar.

### Relative Speedup

#### First parallel implementation
TODO : print 4 matrices in a matrix manner

#### Second parallel implementation

#### Third parallel implementation

### Absolute Speedup

#### First parallel implementation
TODO : print 4 matrices in a matrix manner

#### Second parallel implementation

#### Third parallel implementation

### Comparison with Theoretical Speedup

\newpage{}
