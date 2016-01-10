# MPI Results

In this section, I will present the results obtained with a MPI program for the *ant colony optimization problem*.
All following results were obtained from the *Bellatrix* cluster from *SCITAS*.
Informations about *Bellatrix* can be found on its official website\footnote{http://scitas.epfl.ch/hardware/bellatrix-hardware}.

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

I had to limit the maximum value of pheromons to 1 because in some cases, it can become bigger than 1 and then, if the program runs long enough, it can diverge to infinity.

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

For the parallel implementation, I need to implement communication between nodes.
Thus, it will have a lot of communications at the beginning of the execution to share all useful informations (map, number of ants for each node for example) between all nodes.
As mentionned in the theoretical analysis, for all of these communications I use *broadcasting*.

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

It is also important to know that the ```terminationCondition``` is commented in the provided code to be able to run the algorithm without it.

## Optimality of results
\label{optimality_section}

To test the optimality of results, I implemented 3 different parallel algorithm and I tested them with and without the termination condition (stop after having the same result a certain number of iterations).

### First parallel implementation
\label{parallel1}

For the first implementation, I chose to share between nodes all best paths found on each node after a certain number of local iterations. To do that, I simply need to merge pheromons values received by all other nodes :

```C
for (i = 0; i < psize; i++) {

  // Communications

  // If I am not node i, I will check if values from node i are better than mine
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
    \bf rand1 & 154496 & 154496 & 148475  & 142521    & 159332        & 143109\\
    \hline
    \bf rand2 & 143087 & 143087 & 139158  & 106823    & 110784        & 127501\\
    \hline
    \bf rand3 & 166698 & 166698 & 137681  & 134531    & 138969        & 137076\\
    \hline
    \bf rand4 & 191951 & 191951 & 144172  & 115838    & 150429        & 147284\\
    \hline
    \bf rand5 & 197345 & 197345 & 122878  & 152242    & 145672        & 145474\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewithout1}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 0  & 0    & 1        & 0\\
    \hline
    \bf Parallel beats Serial & 0 & 5  & 5    & 4        & 5\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{onewithout1})}
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
    \bf rand1 & 177592 & 177592 & 187736  & 247970    & 257124        & 244105\\
    \hline
    \bf rand2 & 162085 & 162085 & 183043  & 233283    & 214107        & 278220\\
    \hline
    \bf rand3 & 186004 & 186004 & 184833  & 195020    & 226533        & 231918\\
    \hline
    \bf rand4 & 185873 & 185873 & 199568  & 176070    & 233620        & 241308\\
    \hline
    \bf rand5 & 177384 & 177384 & 180036  & 203247    & 260322        & 282898\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwithout1}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 4  & 4    & 5        & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 1  & 1    & 0        & 0\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{hundredwithout1})}
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
    \bf rand1 & 178031 & 178031 & 1743417  & 1743417    & 1743417        & 1743417\\
    \hline
    \bf rand2 & 180789 & 180789 & 1775744  & 1775744    & 1775744        & 1775744\\
    \hline
    \bf rand3 & 152812 & 152812 & 1728234  & 1728234    & 1728234        & 1728234\\
    \hline
    \bf rand4 & 188825 & 188825 & 1730664  & 1730664    & 1730664        & 1730664\\
    \hline
    \bf rand5 & 161276 & 161276 & 1748895  & 1748895    & 1748895        & 1748895\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewith1}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5  & 5    & 5        & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0  & 0    & 0        & 0\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{onewith1})}
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
    \bf rand1 & 181171 & 181171 & 1649680  & 1634016    & 1728163        & 1721699\\
    \hline
    \bf rand2 & 179519 & 179519 & 1623298  & 1635800    & 1728501        & 1748994\\
    \hline
    \bf rand3 & 190283 & 190283 & 1632833  & 1548522    & 1687993        & 1753994\\
    \hline
    \bf rand4 & 146264 & 146264 & 1688079  & 1707766    & 1647953        & 1695028\\
    \hline
    \bf rand5 & 192344 & 192344 & 1695841  & 1635615    & 1590794        & 1716914\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwith1}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5  & 5    & 5        & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0  & 0    & 0        & 0\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{hundredwith1})}
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
    \bf rand1 & 154496 & 154496 & 154576  & 125320    & 137840        & 145875\\
    \hline
    \bf rand2 & 143087 & 143087 & 134842  & 165693    & 140243        & 126733\\
    \hline
    \bf rand3 & 166698 & 166698 & 149265  & 149338    & 123710        & 166576\\
    \hline
    \bf rand4 & 191951 & 191951 & 155158  & 140697    & 164721        & 161000\\
    \hline
    \bf rand5 & 197345 & 197345 & 145260  & 173973    & 112334        & 147570\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewithout2}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 1  & 1    & 0        & 0\\
    \hline
    \bf Parallel beats Serial & 0 & 4  & 4    & 5        & 5\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{onewithout2})}
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
    \bf rand1 & 177592 & 177592 & 187736  & 247970    & 257124        & 244105\\
    \hline
    \bf rand2 & 162085 & 162085 & 183043  & 233283    & 214107        & 278220\\
    \hline
    \bf rand3 & 186004 & 186004 & 184833  & 195020    & 226533        & 231918\\
    \hline
    \bf rand4 & 185873 & 185873 & 199568  & 176070    & 233620        & 241308\\
    \hline
    \bf rand5 & 177384 & 177384 & 180036  & 203247    & 260322        & 282898\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwithout2}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 4  & 4    & 5        & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 1  & 1    & 0        & 0\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{hundredwithout2})}
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
    \bf rand1 & 178031 & 178031 & 1743417  & 1743417    & 1743417        & 1743417\\
    \hline
    \bf rand2 & 180789 & 180789 & 1775744  & 1775744    & 1775744        & 1775744\\
    \hline
    \bf rand3 & 152812 & 152812 & 1728234  & 1728234    & 1728234        & 1728234\\
    \hline
    \bf rand4 & 188825 & 188825 & 1730664  & 1730664    & 1730664        & 1730664\\
    \hline
    \bf rand5 & 161276 & 161276 & 1748895  & 1748895    & 1748895        & 1748895\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewith2}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5  & 5    & 5        & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0  & 0    & 0        & 0\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{onewith2})}
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
    \bf rand1 & 181171 & 181171 & 1649680  & 1634016    & 1728163        & 1721699\\
    \hline
    \bf rand2 & 179519 & 179519 & 1623298  & 1635800    & 1728501        & 1748994\\
    \hline
    \bf rand3 & 190283 & 190283 & 1632833  & 1548522    & 1687993        & 1753994\\
    \hline
    \bf rand4 & 146264 & 146264 & 1688079  & 1707766    & 1647953        & 1695028\\
    \hline
    \bf rand5 & 192344 & 192344 & 1695841  & 1635615    & 1590794        & 1716914\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwith2}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5  & 5    & 5        & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0  & 0    & 0        & 0\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{hundredwith2})}
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

Of course, there will be a lot of communications for nothing (the majority of the matrix will have low values close to 0).

\textbf{One local iteration without termination condition} (figures \ref{onewithout3} and \ref{summary_onewithout3})

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
    \hline
    \bf Best Cost & \bf Serial & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf rand1 & 154496 & 154496 & 176922  & 147007    & 164259        & 159278\\
    \hline
    \bf rand2 & 143087 & 143087 & 140698  & 157945    & 150729        & 160835\\
    \hline
    \bf rand3 & 166698 & 166698 & 149420  & 186936    & 167434        & 162441\\
    \hline
    \bf rand4 & 191951 & 191951 & 177700  & 156597    & 142280        & 160030\\
    \hline
    \bf rand5 & 197345 & 197345 & 199938  & 139334    & 166256        & 162379\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewithout3}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 2  & 2    & 3        & 2\\
    \hline
    \bf Parallel beats Serial & 0 & 3  & 3    & 2        & 3\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{onewithout3})}
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
    \bf rand1 & 177592 & 177592 & 187736  & 247970    & 257124        & 244105\\
    \hline
    \bf rand2 & 162085 & 162085 & 183043  & 233283    & 214107        & 278220\\
    \hline
    \bf rand3 & 186004 & 186004 & 184833  & 195020    & 226533        & 231918\\
    \hline
    \bf rand4 & 185873 & 185873 & 199568  & 176070    & 233620        & 241308\\
    \hline
    \bf rand5 & 177384 & 177384 & 180036  & 203247    & 260322        & 282898\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwithout3}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 4  & 4    & 5        & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 1  & 1    & 0        & 0\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{hundredwithout3})}
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
    \bf rand1 & 178031 & 178031 & 1743417  & 1743417    & 1743417        & 1743417\\
    \hline
    \bf rand2 & 180789 & 180789 & 1775744  & 1775744    & 1775744        & 1775744\\
    \hline
    \bf rand3 & 152812 & 152812 & 1728234  & 1728234    & 1728234        & 1728234\\
    \hline
    \bf rand4 & 188825 & 188825 & 1730664  & 1730664    & 1730664        & 1730664\\
    \hline
    \bf rand5 & 161276 & 161276 & 1748895  & 1748895    & 1748895        & 1748895\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{onewith3}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5  & 5    & 5        & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0  & 0    & 0        & 0\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{onewith3})}
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
    \bf rand1 & 181171 & 181171 & 1649680  & 1634016    & 1728163        & 1721699\\
    \hline
    \bf rand2 & 179519 & 179519 & 1623298  & 1635800    & 1728501        & 1748994\\
    \hline
    \bf rand3 & 190283 & 190283 & 1632833  & 1548522    & 1687993        & 1753994\\
    \hline
    \bf rand4 & 146264 & 146264 & 1688079  & 1707766    & 1647953        & 1695028\\
    \hline
    \bf rand5 & 192344 & 192344 & 1695841  & 1635615    & 1590794        & 1716914\\
    \hline
  \end{tabular}
  \caption{\it Measurements for 5 executions with one local iteration, 30'000 external iterations, 500 cities, $\alpha$ and $\beta$ equal to 1, evaporation coefficient to 0.9 and 32 ants.}
  \label{hundredwith3}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
    \hline
    \bf Summary & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
    \hline
    \bf Serial beats Parallel & 0 & 5  & 5    & 5        & 5\\
    \hline
    \bf Parallel beats Serial & 0 & 0  & 0    & 0        & 0\\
    \hline
  \end{tabular}
  \caption{\it Summary of measurements from previous figure (\ref{hundredwith3})}
  \label{summary_hundredwith3}
\end{figure}

\FloatBarrier

### Comments

Watching these results, we first observe that the additional termination condition is clearly not a good idea. Indeed, in all executions with this condition, the parallel implementation converges too quickly and stays stuck in a bad solution.

The other improvement (local iterations) is also not a good idea. Indeed, we can observe that the results are in general not so far from the serial execution but they are generally beaten by it.

Finally, the execution with one local iteration seems to be the good solution to solve this problem. Indeed, we can conclude that sharing informations after each iterations makes the parallel algorithm good in term of optimality, but of course, it increases communications and the parallelization is not as good as expected initially.

About the different parallel implementations, the only interesting thing is that the third implementation (sharing whole pheromon matrix) is not as good as first and second implementation.
Indeed, for the first and second implementations, the solution is often better than the serial algorithm while the third implementation (when everything is shared) is as good as the serial implementation.
Thus, I am sure that third algorithm is a good one.
For the first and second, when you observe the costs for the best paths, they are not so much better than the serial one.
I conclude that having less informations (nodes do not share all the pheromon's matrix) makes them giving less importance to already not important paths.

Thus, these two parallel implementations are giving good results. I guess that they do not stay stucked in a local minimum because of the maximum values of pheromons paths.
Indeed, when you observe results with the termination condition, parallel algorithms are always worst because they are quickly stucked in a local minimum.
Limiting the maximum value of pheromons will leave time to better paths to have higher pheromon's values on them and therefore to go out of the suboptimal solution.

## Speedups

For the different speedups, we can note that for all tests I have made, the speedup always looks like the same. Thus, I will only present one relative and one absolute speedup for one execution of my program, knowing that the others are similar.

We can note that I will not show here the speedups for execution with the additional termination condition because the results were clearly not optimal and also not the speedups for hundred iterations, for the same reason.
Nevertheless, they can be found directly in the ```results``` directory.

The following speedups are the ones from file *rand1* from figure \ref{onewithout1}.

### Relative Speedup

\textbf{First parallel implementation (figure \ref{relative1})}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.8]{img/RelativeSpeeduprandom1_1.pdf}
  \caption{\it Parallel algorithm 1 - Relative speedup for random file 1 from results in figure \ref{onewithout1}}
  \label{relative1}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
  \hline
  & \bf Serial Time & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
  \hline
  \bf Execution Time & 11020.097182 & 11498.497093 & 6082.637220  & 3370.134546    & 2011.000059        & 1348.943900\\
  \hline
  \bf Relative Speedup & & 1.000000& 1.890380& 3.411880& 5.717800& 8.524073\\
  \hline
  \end{tabular}
  \caption{\it Parallel Algorithm 2 - Times for each execution in ms and speedups.}
\end{figure}

\FloatBarrier

\textbf{Second parallel implementation (figure \ref{relative2})}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.8]{img/RelativeSpeeduprandom1_2.pdf}
  \caption{\it Parallel algorithm 2 - Relative speedup for random file 1 from results in figure \ref{onewithout1}}
  \label{relative2}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
  \hline
  & \bf Serial Time & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
  \hline
  \bf Execution Time & 11020.097182 & 11525.187912 & 6087.934365  & 3369.249516    & 2013.014723        & 1347.747293\\
  \hline
  \bf Relative Speedup & & 1.000000& 1.893119& 3.420698& 5.725337& 8.551445\\
  \hline
  \end{tabular}
  \caption{\it Parallel Algorithm 2 - Times for each execution in ms and speedups.}
\end{figure}

\FloatBarrier

\textbf{Third parallel implementation (figure \ref{relative3})}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.8]{img/RelativeSpeeduprandom1_3.pdf}
  \caption{\it Parallel algorithm 3 - Relative speedup for random file 1 from results in figure \ref{onewithout1}}
  \label{relative3}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
  \hline
  & \bf Serial Time & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
  \hline
  \bf Execution Time & 11020.097182 & 11536.970434 & 6187.463539  & 3640.974301    & 2756.442646        & 3106.276513\\
  \hline
  \bf Relative Speedup & & 1.000000& 1.864571& 3.168649& 4.185456& 3.714083\\
  \hline
  \end{tabular}
  \caption{\it Parallel Algorithm 3 - Times for each execution in ms and speedups.}
\end{figure}

### Absolute Speedup

\textbf{First parallel implementation (figure \ref{absolute1})}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.8]{img/AbsoluteSpeeduprandom1_1.pdf}
  \caption{\it Parallel algorithm 1 - Absolute speedup for random file 1 from results in figure \ref{onewithout1}}
  \label{absolute1}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
  \hline
  & \bf Serial Time & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
  \hline
  \bf Execution Time & 11020.097182 & 11498.497093 & 6082.637220  & 3370.134546    & 2011.000059        & 1348.943900\\
  \hline
  \bf Absolute Speedup & & 0.958394 & 1.811730 & 3.269927 & 5.479908 & 8.169425\\
  \hline
  \end{tabular}
  \caption{\it Parallel Algorithm 1 - Times for each execution in ms and speedups.}
\end{figure}

\FloatBarrier

\textbf{Second parallel implementation (figure \ref{absolute2})}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.8]{img/AbsoluteSpeeduprandom1_2.pdf}
  \caption{\it Parallel algorithm 2 - Absolute speedup for random file 1 from results in figure \ref{onewithout1}}
  \label{absolute2}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
  \hline
  & \bf Serial Time & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
  \hline
  \bf Execution Time & 11020.097182 & 11525.187912 & 6087.934365  & 3369.249516    & 2013.014723        & 1347.747293\\
  \hline
  \bf Absolute Speedup & & 0.956175 & 1.810153 & 3.270786 & 5.474424 & 8.176679\\
  \hline
  \end{tabular}
  \caption{\it Parallel Algorithm 2 - Times for each execution in ms and speedups.}
\end{figure}

\FloatBarrier

\textbf{Third parallel implementation (figure \ref{absolute3})}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.8]{img/AbsoluteSpeeduprandom1_3.pdf}
  \caption{\it Parallel algorithm 3 - Absolute speedup for random file 1 from results in figure \ref{onewithout1}}
  \label{absolute3}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|c|}
  \hline
  & \bf Serial Time & \bf 1 & \bf 2 & \bf 4 & \bf 8 & \bf 16\\
  \hline
  \bf Execution Time & 11020.097182 & 11536.970434 & 6187.463539  & 3640.974301    & 2756.442646        & 3106.276513\\
  \hline
  \bf Absolute Speedup & & 0.955198 & 1.781036 & 3.026689 & 3.997941 & 3.547687\\
  \hline
  \end{tabular}
  \caption{\it Parallel Algorithm 3 - Times for each execution in ms and speedups.}
\end{figure}

### Comparison with Theoretical Speedup

Figure \ref{comparison_theoretical} shows for each parallel implementation the absolute, the relative and the theoretical speedup graph.

\begin{figure}[!h]
  \centering
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.32]{img/first_speedups.png}
    \caption{\it Speedups for first parallel implementation.}
  \end{subfigure}%
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.32]{img/second_speedups.png}
    \caption{\it Speedups for second parallel implementation.}
  \end{subfigure}
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.32]{img/third_speedups.png}
    \caption{\it Speedups for third parallel implementation.}
  \end{subfigure}
  \caption{\it All speedups in one graph for each parallel implementation.}
  \label{comparison_theoretical}
\end{figure}

\FloatBarrier

### Comments

We can observe in these graphs that, as expected, the theoretical speedup is clearly too much optimistic.
Indeed, the main reasons why the speedups are not so good is that communications take more time than expected and we must send more than only the best path to be able to process the algorithm correctly.

Between the parallel algorithms themselves, we observe that the third implementation as clearly the worst speedup of all implementations.
This is totally normal as we send all the pheromon's matrix in this implementation.
Therefore, there are more communications to do and thus they take more time when there are many nodes.

We also can observe that, with 16 nodes, the third implementation has a worst speedup than with only 8 nodes.
It indicates us this algorithm does not scale well.

About solutions that are not optimal\footnote{You can find them attached to this report.}, we can observe that speedups are really good thanks to improvements (local iterations, termination condition).
Indeed, I tried to reduce communications and it works.
Speedups are really good (even better than good with the additional termination condition), but as the optimality of the result is not guaranteed, these solutions are not interesting.

### Other measurements

Below, you can find different experiments with different problem sizes.
Values used to create these graphs can be found on the DVD attached to this report.

All these experiments were made with only one iteration locally and without the termination condition.
The changed arguments are the size of the city, the number of ants and the maximum number of iterations.

\textbf{250 cities with 32 ants and 15'000 iterations (first algorithm)}

\begin{figure}[!h]
  \centering
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.6]{img/RelativeSpeeduprandom1_250_1.pdf}
    \caption{\it Relative Speedup}
  \end{subfigure}%
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.6]{img/AbsoluteSpeeduprandom1_250_1.pdf}
    \caption{\it Absolute Speedup}
  \end{subfigure}
  \caption{\it First parallel implementation - Speedups for 250 cities, 32 ants and 15'000 iterations.}
  \label{250cities}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
  \hline
  \bf Serial beats Parallel & 0 & 0  & 0    & 1        & 0\\
  \hline
  \bf Parallel beats Serial & 0 & 5  & 5    & 4        & 5\\
  \hline
  \end{tabular}
  \caption{\it Summary of measurements comparison between serial and parallel implementation for 250 cities, 32 ants and 15'000 iterations.}
  \label{table_250cities}
\end{figure}

\FloatBarrier

\textbf{100 cities with 32 ants and 15'000 iterations (first algorithm)}

\begin{figure}[!h]
  \centering
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.6]{img/RelativeSpeeduprandom1_100_1.pdf}
    \caption{\it Relative Speedup}
  \end{subfigure}%
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.6]{img/AbsoluteSpeeduprandom1_100_1.pdf}
    \caption{\it Absolute Speedup}
  \end{subfigure}
  \caption{\it First parallel implementation - Speedups for 250 cities, 32 ants and 15'000 iterations.}
  \label{100cities}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
  \hline
  \bf Serial beats Parallel & 0 & 1  & 1    & 2        & 2\\
  \hline
  \bf Parallel beats Serial & 0 & 4  & 4    & 3        & 3\\
  \hline
  \end{tabular}
  \caption{\it Summary of measurements comparison between serial and parallel implementation for 100 cities, 32 ants and 15'000 iterations.}
  \label{table_100cities}
\end{figure}

\FloatBarrier

\textbf{100 cities with 16 ants and 15'000 iterations (first algorithm)}

\begin{figure}[!h]
  \centering
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.6]{img/RelativeSpeeduprandom1_100_16_1.pdf}
    \caption{\it Relative Speedup}
  \end{subfigure}%
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.6]{img/AbsoluteSpeeduprandom1_100_16_1.pdf}
    \caption{\it Absolute Speedup}
  \end{subfigure}
  \caption{\it First parallel implementation - Speedups for 100 cities, 16 ants and 15'000 iterations.}
  \label{100cities_16}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
  \hline
  \bf Serial beats Parallel & 0 & 3  & 2    & 3        & 2\\
  \hline
  \bf Parallel beats Serial & 0 & 2  & 3    & 2        & 3\\
  \hline
  \end{tabular}
  \caption{\it Summary of measurements comparison between serial and parallel implementation for 100 cities, 16 ants and 15'000 iterations.}
  \label{table_100cities_16}
\end{figure}

\FloatBarrier

\textbf{100 cities with 64 ants and 15'000 iterations (first algorithm)}

\begin{figure}[!h]
  \centering
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.6]{img/RelativeSpeeduprandom1_100_64_1.pdf}
    \caption{\it Relative Speedup}
  \end{subfigure}%
  \begin{subfigure}{.5\textwidth}
    \centering
    \includegraphics[scale=0.6]{img/AbsoluteSpeeduprandom1_100_64_1.pdf}
    \caption{\it Absolute Speedup}
  \end{subfigure}
  \caption{\it First parallel implementation - Speedups for 100 cities, 64 ants and 15'000 iterations.}
  \label{100cities_64}
\end{figure}

\begin{figure}[!h]
  \centering
  \begin{tabular}{|c|c|c|c|c|c|}
  \hline
  \bf Serial beats Parallel & 0 & 2  & 1    & 2        & 2\\
  \hline
  \bf Parallel beats Serial & 0 & 3  & 4    & 3        & 3\\
  \hline
  \end{tabular}
  \caption{\it Summary of measurements comparison between serial and parallel implementation for 100 cities, 64 ants and 15'000 iterations.}
  \label{table_100cities_64}
\end{figure}

\FloatBarrier

#### Comments

With these results, we can observe several things.
Indeed, in terms of optimality, the experiments made in section \ref{optimality_section} have shown that first and second implementation of the parallel algorithm have always beaten serial implementation.
Here, with smaller problems, we observe that the first algorithm is as good as the serial one (figure \ref{table_100cities_16} for example). Thus, in section \ref{optimality_section}, the serial implementation did not have the time to obtain a really good result.

To avoid this problem, we simply need to do more iterations, but as we observed in this report, the parallel implementation converges faster to an optimum.
The termination condition could be here something good to really improve the performances of the parallel algorithm.
Nevertheless, this termination condition should be carefully chosen because we observed that there is a huge risk that the parallel implementation stays stucked in a suboptimal solution (as observed in this report).

We also see that the number of ants is important to have a good speedup, as claimed in section \ref{theoretical_analysis}.
Indeed, with 16 ants (figure \ref{100cities_16}), the speedup is worst than with 64 (figure \ref{100cities_64}).

Thus, we can conclude that, to have a good speedup, the problem has to be huge and we need to have a lot of ants compared to the number of nodes.



\newpage{}
