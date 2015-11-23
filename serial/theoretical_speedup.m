tinit = 0.139912000000000;
tcomputation = 0.021076000000000;
tmerge = 9.000000000000000e-06;
tsend = 9.199999999999999e-08;
internal = 100;
external = 30;
nants = [1 2 4 8 16];
nodes = [1 2 4 8 16];
result = [];

for i = 1:size(nants,2)
    for j = 1:size(nodes,2)
        if (j == 1)
            result(j,i) = tinit + external * (internal * (ceil(nants(i)/nodes(j))) * tcomputation + tmerge);
        else
            result(j,i) = tinit + external * ((1000*1000/2-1000) * tsend + internal * (ceil(nants(i)/nodes(j)) * tcomputation + nodes(j) * 1000 * tsend) + tmerge);
        end
    end
end

disp(result)

base = result(1,:);

optimalSpeedup = nodes
speedup2 = base ./ result(2,:)
speedup4 = base ./ result(3,:)
speedup8 = base ./ result(4,:)
speedup16 = base ./ result(5,:)
% speedup32 = base ./ result(6,:)
% speedup64 = base ./ result(7,:)

figure
plot(nodes,optimalSpeedup,'b-x',nodes,speedup2,'r-x',nodes,speedup4,'k-o',nodes,speedup8,'g-o',nodes,speedup16)%nodes,speedup32,nodes,speedup64)
legend('optimalSpeedup', '2 ants', '4 ants', '8 ants', '16 ants', 'Location', 'northwest')
title('Theoretical Speedup for 1000 cities and 3000 iterations')
xlabel('Nb of Processors')
ylabel('Speedup')