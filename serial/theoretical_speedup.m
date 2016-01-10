% Ant Colony Optimization Algorithm with MPI
% Schaer Marc

% Time computed from laptop
tinit = 0.139912000000000;
tcomputation = 0.021076000000000;
tmerge = 9.000000000000000e-06;
tsend = 3.0518e-08; % Time to send one integer
% iterations
internal = 1;
external = 30000;
nants = 32;
nodes = [1 2 4 8 16];
ncities = 500;
result = [];
serial = [];
for j = 1:size(nodes,2)
    result(j) = tinit + ncities * tsend + external * (internal * (ceil(nants/nodes(j)) * tcomputation) + nodes(j) * ncities * tsend + tmerge) + tmerge; 
end

for i = 1:size(nodes,2)
    serial(i) = tinit + external * internal * (nants * tcomputation + tmerge);
end

base = result(:,1);

optimalSpeedup = nodes;
speedup16 = serial' ./ result(:)

% These speedups are taken from
% OneLocalIterationWithoutTerminationCondition/
% and are results for random1.txt file
parallel1AbsoluteSpeedup = [1 1.81173 3.26993 5.47991 8.16943]
parallel1RelativeSpeedup = [1 1.89038 3.41188 5.7178 8.52407]

parallel2AbsoluteSpeedup = [1 1.81015 3.27079 5.47442 8.17668]
parallel2RelativeSpeedup = [1 1.89312 3.4207 5.72534 8.55145]

parallel3AbsoluteSpeedup = [1 1.78104 3.02669 3.99794 3.54769]
parallel3RelativeSpeedup = [1 1.86457 3.16865 4.18546 3.71408]

figure
plot(nodes,optimalSpeedup,'b-x',nodes,speedup16,'r-o',nodes,parallel1AbsoluteSpeedup,'-',nodes,parallel1RelativeSpeedup,'-.')
legend('Optimal Speedup', 'Theoretical Speedup', 'Absolute Speedup', 'Relative Speedup', 'Location', 'northwest')
title('Speedups for 500 cities and 30000 iterations and first parallel implementation')
xlabel('Nb of Nodes')
ylabel('Speedup')
axis square

pause

figure
plot(nodes,optimalSpeedup,'b-x',nodes,speedup16,'r-o',nodes,parallel2AbsoluteSpeedup,'-',nodes,parallel2RelativeSpeedup,'-.')
legend('Optimal Speedup', 'Theoretical Speedup', 'Absolute Speedup', 'Relative Speedup', 'Location', 'northwest')
title('Speedups for 500 cities and 30000 iterations and second parallel implementation')
xlabel('Nb of Nodes')
ylabel('Speedup')
axis square

pause

figure
plot(nodes,optimalSpeedup,'b-x',nodes,speedup16,'r-o',nodes,parallel3AbsoluteSpeedup,'-',nodes,parallel3RelativeSpeedup,'-.')
legend('Optimal Speedup', 'Theoretical Speedup', 'Absolute Speedup', 'Relative Speedup', 'Location', 'northwest')
title('Speedups for 500 cities and 30000 iterations and third parallel implementation')
xlabel('Nb of Nodes')
ylabel('Speedup')
axis square