This implementation of the parallel algorithm uses two termination conditions :
  - Maxmimum number of loops
  - 40% of loops with the same best cost

It shares only the best path between all nodes after local iterations and merge them into local pheromons matrix (with taking the average for each edge (to not give to much importance to best paths).
