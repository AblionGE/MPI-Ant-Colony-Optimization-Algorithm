# Conclusion

In conclusion, we can say that this problem scales relatively well even if we must keep a lot of communications between nodes.
Indeed, if we select carefully the number of nodes and the number of ants, we can have a good speedup.

We also saw that to have an optimal result, we need to be careful with arguments given to the program.
The choice of the map size and the number of ants strongly impacts the number of iterations to do to be sure to have an optimal results.
If the number of iterations is too low, the program will not have the time to find the optimal solution.
If we give too much iterations, we will kill the speedup and loose all the gain of parallelizing this problem.
Thus, the choice of the number of iterations is delicate.

We also can notice that other arguments ($\alpha$ and $\beta$) are also important for this algorithm.
Indeed, to improve its efficiency, we can implement an algorithm where these values evolves during the execution to give more importance to distance at the start of the algorithm and to privilege pheromons at the end.
This improvement can also helps to obtain a good result easily and thus to improve the parallel implementation.

