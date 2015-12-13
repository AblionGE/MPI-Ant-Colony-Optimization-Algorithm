tinit = 0.139912000000000;
tcomputation = 0.021076000000000;
tmerge = 9.000000000000000e-06;
tsend = 3.0518e-08; % Time to send one integer
internal = 50;
external = 100;
nants = [1 2 4 8 16];
nodes = [1 2 4 8 16];
ncities = 1000;
result = [];
serial = [];

% for i = 5:size(nants,2)
i = 5
    for j = 1:size(nodes,2)
        result(j,i) = tinit + ncities * tsend + external * (internal * (ceil(nants(i)/nodes(j)) * tcomputation) + nodes(j) * ncities * tsend + tmerge) + tmerge; 
    end
% end

for i = 1:size(nodes,2)
    serial(i) = tinit + external * internal * (nants(5) * tcomputation + tmerge) %result(1,5) / nodes(i)
end

disp(result)

base = result(:,1);

optimalSpeedup = nodes
% speedup2 = base ./ result(:,2)
% speedup4 = base ./ result(:,3)
% speedup8 = base ./ result(:,4)
speedup16 = serial' ./ result(:,5)
% speedup32 = base ./ result(6,:)
% speedup64 = base ./ result(7,:)

figure
plot(nodes,optimalSpeedup,'b-x',nodes,speedup16,'r-o')%nodes,speedup32,nodes,speedup64)
legend('optimalSpeedup', '16 ants', 'Location', 'northwest')
title('Theoretical Speedup for 1000 cities and 5000 iterations')
xlabel('Nb of Nodes')
ylabel('Speedup')