# Theoretical Analysis

## Serial application

### Computational complexity

The serial *ant colony optimization algorithm* is composed by a first *initialization* part that initializes all variables, including the matrix that represents the graph and the one with pheromon values (complexity of $O(2 \cdot c^2)$ for $c$ cities).
Then, the algorithm will loop until a termination condition is reached\footnote{Either the maximum number of iterations is reached or the solution is stabilized.}.
This "big" loop will make at most $L$ iterations.
In this loop, there is another loop for simulating ants (we have $A$ ants).
In it, there is a loop to go through each city ($c$ cities) where we have to compute the probabilities to go to a specific city ($O(c)$).
Finally, we have to perform the pheromon's evaporation ($O(c^2)$) and we have to update the pheromon's matrix with the new pheromon's values from ants ($O(c)$ because we have to update only the best path).

The skeleton of the serial application is like this pseudo-code:

```java
init() // 2*c*c operations
while (termination condition) { // at most L loops
  for each ants { // A iterations
    for each city { // c iterations
      find next city to visit // O(1)
    }
  }
  pheromon evaporation // O(c*c)
  update bestPath's pheromons // O(c)
}
```
It gives us a computational complexity of $O(c^2 + L \cdot (cA + c^2 + c))$.

We can define the number of ants to the number of city (even if it is useless to have so much ants) and we can consider that the number of *external* loops is a constant, we have a complexity of $O(L \cdot c^2)$.

With this complexity, we can observe that number of ants and the size of the map are the two factors that makes the computations complex or not.

## Parallel Application
\label{theoretical_analysis}

For the parallel implementation of the *ant colony optimization algorithm*, we have to define what is parallelized and what are the content of communications.

### Basic Parallel Application
For the analysis below, let us consider we have $c$ cities, $A$ ants, $n$ nodes (including the master) and we assume that the loop has a fixed number of iterations $L$.

#### Computation to communication time

For the initialization part, the graph will be spread by the master to each node ($O(c^2)$) using broadcasting.
And, at the end of each iteration, each node will have the share its result (best path or whole pheromons' matrix) to others using broadcasting ($O(n * c)$ for sharing the best path or $O(n * c^2)$ for sharing the whole matrix).

Then, each node will compute the paths of multiple ants ($O(c \cdot \frac{A}{n})$).
We assume that each node has the same number of ants.
The computation on each node is exactly the same as in the serial application except that each node has only a subset of ants.
We can add that if we want to do several iterations before merging the results, we will simply multiply this cost by a constant, which will not change the bounded complexity.

Then, when they all have finished to compute the new map with new pheromon's values, all nodes send their local best path to the others.
The cost of sending all vectors is $O(cn)$.

Finally, each node will merge all received vectors ($O(c \cdot n)$ additions) and will perform the *pheromons evaporation* ($O(c^2)$) and decide if another iteration is needed or not.

Thus, for computation time we have a cost of $O(L \cdot (c \cdot \frac{A}{n} + c \cdot n + c^2))$ and for communication time we have a cost of $O(c^2 + L \cdot c \cdot n)$\footnote{We share only the best path from each node.} because each node has to send its best path at each *external* iteration.

The *Computation/Communication* ratio is $\frac{O(L \cdot (c \cdot \frac{A}{n} + cn + c^2))}{O(c^2 + L \cdot c \cdot n)}$ which tells us that the size of the problem will not make the communications less important. In fact, the only way to have more computations than communications is to have $\frac{A}{n} > c$.

We conclude that the communications are really costly for this algorithm.

#### Amdhal's law

The Amdhal's law gives us a theoretical speedup when we improve resource for a problem of a fixed size.
For the *ant colony optimization problem*, we can define this theoretical upper bound limitation as follows, where $n$ is the number of nodes and $f$ is a fraction of the code that cannot be parallelized :

$$
S_n \leq \frac{n}{1+(n-1)\cdot f}
$$

##### Without data transfer

If we do not account for data transfers, the fraction of the code that cannot be parallelized is when the master creates the matrix at the beginning of the program and when all nodes share their best paths.

Considering the complexities defined above, the serial part will have a complexity of $O(c^2)$ to initialize the matrix and then a complexity of $O(L \cdot c \cdot n)$ to update the matrix. 
It gives us $c \cdot (L \cdot n + c)$ operations.

For the parallel part, we have $L \cdot c \cdot \frac{A}{n} \cdot c + L \cdot c^2$ operations\footnote{We go through each city and in each city we have to compute the probabilities for each other cities and finally we update the peromons' matrix.}.

Thus, $$f = \frac{c \cdot (L \cdot n + c)}{c \cdot (L \cdot n + c) + L \cdot c^2 \cdot (1 + \frac{A}{n})} = \frac{L \cdot n+c}{L \cdot n + c + L \cdot c \cdot (1 + \frac{A}{n})}$$

Here, we observe that $A$ and $n$ are important. To have a small $f$, we need to have more ants than nodes. It is logical, because to have an efficient parellelization of this program, nodes must have something to compute (the computation time on nodes must be big compared to communications.

Table \ref{table_without_data_transfer} and figure \ref{without_data_transfer} show us the important relation between the number of ants and nodes.
They also show us that more we have nodes, more we have serial code execution.

\begin{figure}[!h]
\begin{center}
  \begin{tabular}{|p{2.5cm}|p{3cm}|}
    \hline
    \bf Nodes $\backslash$ Ants & \bf 16\\
    \hline
    \bf 1 & 0.000070583252947\%\\
    \hline
    \bf 2 & 0.000244384705961\%\\
    \hline
    \bf 4 & 0.000839294992207\%\\
    \hline
    \bf 8 & 0.002725882587594\%\\
    \hline
    \bf 16 & 0.008034917170916\%\\
    \hline
  \end{tabular}
  \caption{\it Percentages of serial code execution without considering data transfer for 16 ants, 5000 iterations and 1000 cities.}
  \label{table_without_data_transfer}
\end{center}
\end{figure}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.4]{img/without_data_transfer.png}
  \caption{\it Percentages of serial code execution without considering data transfer for 16 ants, 5000 iterations and 1000 cities.}
  \label{without_data_transfer}
\end{figure}

##### More accurate estimation

Now, if we consider the transfer of data between nodes, we must modify the value of $f$. Indeed, we have to consider the communication time in our computations.
To send a matrix from the master to each node, we have $c^2$ values sent to $n$ nodes using broadcast and we have $c \cdot n$ values returned from $n$ nodes $L$ times. Thus, we have :

$$
f = \frac{c \cdot (L \cdot n + c) + c \cdot (c + L \cdot n)}{c \cdot (L \cdot n + c) + c^2 + c \cdot L \cdot n + L \cdot c^2 \cdot (1 + \frac{A}{n})} = \frac{2 * (c^2 + c \cdot L \cdot n)}{2 * (c^2 + c \cdot L \cdot n) + L \cdot c^2 \cdot (1 + \frac{A}{n})}
$$

Again here, we observe (figure \ref{with_data_transfer} and table \ref{table_with_data_transfer}) that the number of ants compared to the number of nodes is important to have a good speedup.
We can already affirm that adding ressources for solving this problem will not be efficient if the problem is not big enough (not enough cities and ants).

\begin{figure}[!h]
\begin{center}
  \begin{tabular}{|p{2.5cm}|p{3cm}|}
    \hline
    \bf Nodes $\backslash$ Ants & \bf 16\\ 
    \hline
    \bf 1 & 0.000070583252947\%\\
    \hline
    \bf 1 & 0.000244384705961\%\\
    \hline
    \bf 1 & 0.000839294992207\%\\
    \hline
    \bf 1 & 0.002725882587594\%\\
    \hline
    \bf 1 & 0.008034917170916\%\\
    \hline
  \end{tabular}
  \caption{\it Percentages of serial code execution with considering data transfer for 16 ants, 5000 iterations and 1000 cities.}
  \label{table_with_data_transfer}
\end{center}
\end{figure}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.4]{img/with_data_transfer.png}
  \caption{\it Percentages of serial code execution with considering data transfer for 16 ants, 5000 iterations and 1000 cities.}
  \label{with_data_transfer}
\end{figure}

We can observe that the more accurate estimation has exactly the same result as the one without considering data transfer. We can explain that with the fact that the code for communications has te same importance in this analysis as the initialization of the map and the pheromons update. Thus, the fraction of serial code stays the same (even if in reality, the communication will take much longer than updating two matrices).

### Improved Parallel Application

As we can observe with the parallel implementation where we send the whole matrix at each iteration, we can reduce the communications with computing several iterations locally before sending the matrix to the master (we reduce the communications having more accurate local solutions before merging).
We also can send to the master only the best path over several iterations.

As we want to improve the performances of the parallel application we can consider both improvements together. Thus, we need to define the variable $l$ which represents the number of iterations to perform locally before merging the best path to the master. The theoretical speedup upper bound is presented below. We will do here the prediction for these improvements, but we need to be sure that the solutions provided with these improvements is still good compared to the serial implementation. This will be done in the last part of this report.

#### Computation to communication time

The initialization part stays the same as in the basic parallel application : $O(c^2)$ to initialize the matrix and $O(c^2)$ to send it to the nodes.

For the computation complexity on nodes, we have now a complexity of $O(L' \cdot (l \cdot c \cdot \frac{A}{n})$).
The update of pheromon values is done locally and is kept between local and external iterations\footnote{Thus, we have some history in each node to help it to find a solution faster.}.

Then, for the merge with other nodes, we only send the best path (which needs to be kept in a local variable and updated after each ant execution). Thus the complexity is $O(L' \cdot c \cdot n)$.

Finally, every node has to merge all other nodes results : $O(L' \cdot c \cdot n)$.

The $Computation/Communication$ ratio is $$\frac{c^2 + L' \cdot (l \cdot c \cdot \frac{A}{n} + c \cdot n)}{c^2 + L' \cdot c \cdot n} = \frac{c + L' \cdot (l \cdot \frac{A}{n} + n)}{c + L' \cdot n}$$

Here we can conclude that the larger is the problem (in term of ants, city and thus local iterations), the smaller is the impact of communication.
Nevertheless, more we have nodes, more are the communications important (this seems totally logic).

#### Amdahl's law

##### Without data transfer

Without considering the data transfer, we have to compute in a serial manner the initialization of the matrices ($c^2$) and the merge of all best paths ($L' \cdot n \cdot c$).
For the parallel part, we have the computation of the best path for each ant with several local iterations ($L' \cdot (l \cdot (c^2 \cdot \frac{A}{n}$))).

Thus, we have the following non-parallel fragment :
$$f = \frac{c^2 + L' \cdot n \cdot c}{c^2 + L' \cdot n \cdot c + \frac{L' \cdot l \cdot c^2 \cdot A}{n}} = \frac{c + L' \cdot n}{c + L' \cdot n + \frac{L' \cdot l \cdot c \cdot A}{n}}$$

We observe (table \ref{improved_table_without_data_transfer} and figure \ref{improved_without_data_transfer}) again that the number of ants and the number of local iterations is important to maximize the speedup. Thus, more we have nodes, more we need to have a bigger problem to solve to keep a reasonnable speedup.

\begin{figure}[!h]
\begin{center}
  \begin{tabular}{|p{2.5cm}|p{3cm}|}
    \hline
    \bf Nodes $\backslash$ Ants & \bf 16\\ 
    \hline
    \bf 1 & 0.012941008998707\%\\
    \hline
    \bf 2 & 0.026665955574518\%\\
    \hline
    \bf 4 & 0.055996864175606\%\\
    \hline
    \bf 8 & 0.119985601727793\%\\
    \hline
    \bf 16 & 0.259932417571431\%\\
    \hline
  \end{tabular}
  \caption{\it Percentages of serial code execution without considering data transfer for 16 ants, 100 external iterations, 50 local iterations and 1000 cities. Results must be multiplied by $10^{-3}$}
  \label{improved_table_without_data_transfer}
\end{center}
\end{figure}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.4]{img/improved_without_data_transfer.png}
  \caption{\it Percentages of serial code execution without considering data transfer for 16 ants, 100 external iterations, 50 local iterations and 1000 cities.}
  \label{improved_without_data_transfer}
\end{figure}

\newpage{}

##### More accurate estimation

For having a more accurate estimation, we consider the communication time. As we defined above, we consider the send of the whole matrix ($c^2$) to each node and the send of all best paths ($L' \cdot c \cdot n$).
Thus, we have the formula presented in figure \ref{formula1}.

\begin{figure}[!h]
  \centering
$$f = \frac{2 * (c^2 + L' \cdot n \cdot c)}{2 * (c^2 + L' \cdot n \cdot c) + \frac{L' \cdot l \cdot c^2 \cdot A}{n}} = \frac{2 * (c + L' \cdot n)}{2 * (c + L' \cdot n) + \frac{L' \cdot l \cdot c \cdot A}{n}}$$
  \caption{\it Amdhal's law for improved implementation.}
  \label{formula1}
\end{figure}

Again, we can observe (table \ref{improved_table_with_data_transfer} and figure \ref{improved_with_data_transfer}) that the number of ants and the number of local iterations is important to define the speedup, but, here, the number of cities makes the communication more dominant. It is logic, because the vectors will be bigger so the communications increase with the number of cities and the number of nodes.

\begin{figure}[!h]
\begin{center}
  \begin{tabular}{|p{2.5cm}|p{3cm}|}
    \hline
    \bf Nodes $\backslash$ Ants & \bf 16\\ 
    \hline
    \bf 1 & 0.000027499243771\%\\
    \hline
    \bf 2 & 0.000059996400216\%\\
    \hline
    \bf 4 & 0.000139980402744\%\\
    \hline
    \bf 8 & 0.000359870446639\%\\
    \hline
    \bf 16 & 0.001038919523695\%\\
    \hline
  \end{tabular}
  \caption{\it Percentages of serial code execution with considering data transfer for 16 ants, 100 external iterations, 50 local iterations and 1000 cities.}
  \label{improved_table_with_data_transfer}
\end{center}
\end{figure}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.4]{img/improved_with_data_transfer.png}
  \caption{\it Percentages of serial code execution with considering data transfer for 16 ants, 100 external iterations, 50 local iterations and 1000 cities.}
  \label{improved_with_data_transfer}
\end{figure}

### Conclusion on Amdahl's law analysis

The vision of Amdhal's law is pessimist because the communications will take a lot of time if we increase the resources without increasing the problem.
On the contrary, Gustafson's law is more optimistic because it adapts the task to the number of computation resources.
Nevertheless, Amdahl's law gives us a good idea of how many cores we need for a specific problem's size and in the *ant colony optimization problem* it is important to avoid having too much nodes compared to the size of problem, according to the theoretical analysis.

## Theoretical analysis with MPI

Now, I will establish an analysis of the speedup using the framework *Message Passing Interface (MPI)* which allows several computational nodes to work together in a distributed memory fashion.

As discussed in part \ref{theoretical_analysis}, we have the following sequence of message passing for one master and 3 nodes\footnote{Of course, in the real implementation, the master will work as a node, too.}.

For spreading the matrix into all nodes, we can use ```MPI_BCAST``` which sends to all nodes the same data. It allow us to improve a bit the communications.

### Sequence of message passing

We have a kind of *DPS flow graph* like in figure \ref{diagram} where we can observe the general scheme of the algorithm.
We also have two *MPI* operations which are when the master send the matrix to each node and when they send back their own best path.


\begin{figure}[!h]
  \centering \includegraphics[scale=0.5]{img/flow_diagram.png}
  \caption{\it General scheme of the application. The broadcast allows nodes to share their best paths together.}
  \label{diagram}
\end{figure}
The sequence of message passing is presented in figure \ref{message_passing} for one iteration, without considering the local computations.
The timeline has no meaning in term of size.
This sequence diagram is here only to show in which order are sent messages between nodes and master.

\begin{figure}[!h]
  \centering \includegraphics[scale=0.5]{img/message_passing.png}
  \caption{\it Sequence of message passing}
  \label{message_passing}
\end{figure}

### Approximative Timing Diagram

Figure \ref{timing_diagram} presents an approximative timing diagram of computations and communications between one master and 2 slave nodes.
We suppose, for keeping small this diagram, that there are only 3 cities and 3 ants (one per node).
The computation phases are made bigger than the communication ones, but in reality, with this example, the communications should take more time\footnote{I consider a huge problem where the communications are less important than computations.}.
I also consider that all similar operations take the same time to be executed.

In fact, this is true.
Indeed, all comunications are sending only one value so, without considering problems on the network, it should always take the same time to be executed.
And even if we send the whole matrix at one time, the matrix will always have the same size, and we can expect to always have the same communication time.
For computations, if all nodes have the same number of ants to manage, they will have a similar computation time (if the machines have an identical architecture and hardware) because in all cases the map has the same size, and each city has the same number of neighbours to consider.

\begin{figure}[!h]
  \centering \includegraphics[scale=0.45]{img/timing_diagram.png}
  \caption{\it Timing diagram for initialization + one iteration with 3 nodes. \textit{bp} means \textit{best path}.}
  \label{timing_diagram}
\end{figure}

To have a better idea of the different timings, we can suppose we have a network with a throughput of 125 MB/s\footnote{125MB = 131'072'000 bytes.} for data.
Knowing that each message sent by a node or the master will contain n integers (the indices of cities of the best path) and that an integer is 4 bytes, we can assume that a message takes $3.0518 \cdot 10^{-8}$ seconds to be sent\footnote{We neglect the small latency.}.

For the computation time, I ran one iteration of the algorithm with one ant on an *Intel core i5* machine with 4 CPU at 2.60 GHz for a map of 1000 cities.
It took 0.021076 seconds.
For initializing variable (especially map and pheromons matrix), it took 0.139912 seconds, even if this time can vary because the map is read from a file.
For the merging part, it took 0.000009 seconds.

With these values, we can do some computations to estimate the time for computations with multiple nodes and multiple ants for a fixed map size of 1000 cities\footnote{Of course, I will try with different map sizes when the parallel algorithm will be implemented.}. It is presented in figure \ref{computations}\footnote{The communication parts are not considered when there is only one node.}.

\begin{figure}[!h]
  \begin{center}
    \begin{tabular}{|c|c|}
      \hline
      \bf nodes $\backslash$ ants & \bf 16\\
      \hline
      \bf 1 & 1686.230113000000\\
      \hline
      \bf 2 & 843.199313000000\\
      \hline
      \bf 4 & 421.697713000000\\
      \hline
      \bf 8 & 210.974513000000\\
      \hline
      \bf 16 & 105.668113000000\\
      \hline
    \end{tabular}
  \end{center}
  \caption{\it Theoretical computations for 1000 cities and 5000 iterations (100 external iterations and 50 internal ones) based on one machine measurements. The values are computed as follows (in seconds) : $t_{init} + 1000^2 * t_{send} + 100 * (50 * (\lceil \frac{n_{ants}}{n_{nodes}}\rceil \cdot t_{computation}) + n_{nodes} \cdot 1000 \cdot t_{send} + t_{merge}) + t_{merge})$.}
  \label{computations}
\end{figure}

\begin{figure}[!h]
  \centering \includegraphics[scale=0.5]{img/theoretical_speedup.png}
  \caption{\it Theoretical speedup for 1000 cities and 3000 iterations (30 * 100) based on figure \ref{computations}.}
  \label{theoretical_speedup}
\end{figure}

We can observe in figures \ref{computations} and \ref{theoretical_speedup} that adding nodes improves the performances of the program.
Nevertheless, we can already expect that with the variance of the network speed, the practical speedup will not be as good as here.


### Critical Path and Theoretical Speedup

As we can observe on figure \ref{timing_diagram}, the critical path is the following one :
$$
init \ matrix \rightarrow send \ m(0,1) \rightarrow send \ m(0,2) \rightarrow send \ m(1,2) \rightarrow process \ algo \ node \rightarrow recv1 \ bp(0) \rightarrow recv1 \ bp(1) \rightarrow
$$
$$
recv1 \ bp(2) \rightarrow recv2 \ bp(0) \rightarrow recv2 \ bp(1) \rightarrow recv2 \ bp(2) \rightarrow merge \ bp
$$

With this critical path, we can define a theoretical speedup.
The speedup is defined as follows :
$$
S_n = \frac{t_s}{t_p}
$$

where $t_s$ is the time of the serial application and $t_p$ is the time of the parallel application.

In this theoretical speedup analysis, we will keep $t_s$ as such\footnote{We add to it the initialization phase because it is also considered in the parallel computations.}, but we will define morce precisely $t_p$.
With the critical path, we can define $t_p$ as follows :

$$
t_p = t_{init} + t_l + c^2 \cdot t_{send} + L \cdot (t_s \cdot l + t_l + n \cdot c \cdot t_{send})
$$

where $t_{init}$ is the time to initialize the matrix, $t_l$ is the minimal time to start a transmission, $c$ is the number of cities\footnote{We send only the upper part of the matrix because it is symmetric and the diagonal is null.}, $t_{send}$ is the time to send one element of the matrix, $L$ is the number of *external* iterations in the serial program, $l$ is the number of iterations to process locally in a node before sharing with other nodes and $n$ is the number of nodes.

We can reduce $t_p$ :

$$
t_p = t_{init} + (L + 1) \cdot t_l + t_{send} \cdot (c^2 + n \cdot c \cdot L) + L \cdot l \cdot t_s(n)
$$

We also can define $t_s$ as :

$$
t_s(x) = \frac{A}{x} \cdot t_{computation}
$$

where $x$ is the number of nodes and $A$ the number of ants.

Finally, the speedup is as follows :

$$
S_n = \frac{t_{init} + L \cdot l \cdot t_s(1)}{t_{init} + (L + 1) \cdot t_l + t_{send} \cdot (c^2 + n \cdot c \cdot L) + L \cdot l \cdot t_s(n)}
$$

To have good performances, we need to have $t_p$ as small as possible. Ideally, $t_{send}$ should be really small such that the problem can scale easily.

#### Remarks

We can note that, in this analysis, we always compare the serial and the parallel implementations when they have exactly the same number of iterations. It allows us to have acceptable results. Nevertheless, we will see in next section that we can have another termination condition which is a certain cost for a path that stays the same for a certain number of iterations (we assume that the result cannot be better in this case). We will observe that some techniques we use to parallelize are not very good in term of result's optimality (even if it as a really good speedup).

\newpage{}
