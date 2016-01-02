# Conclusion

In conclusion, we can say that this problem scales relatively well if we keep a lot of communications between nodes.
Indeed, we observed that, if we try to do more computations locally before merging informations, the speedup will be very good, but the result quality will not be acceptable.

We should also be really careful with the argument we give to the program.
Indeed, as the algorithm is random, we need to give enough time (loops) to the serial implementation to have time to converge to an optimal (or at least to a really good suboptimal) solution.
The values of $\alpha$ and $\beta$ can also be tuned to change during the execution of the program to give more importance to distances at the beginning of the execution and to give more weight to pheromons at the end.
