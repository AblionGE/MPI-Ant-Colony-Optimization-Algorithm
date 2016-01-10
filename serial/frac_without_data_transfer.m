% Ant Colony Optimization Algorithm with MPI
% Schaer Marc

% Compute fraction of serial code without considering data transfer

nants = [1 2 4 8 16];
nodes = [1 2 4 8 16];
c = 1000
result = []
L = 5000

for i = 1:size(nants,2)
    for j = 1:size(nodes,2)
        result(j,i) = (L*nodes(j) + c)/(L*nodes(j) + c + L*c*(1+nants(i)/nodes(j)));
    end
end

disp(result)

figure
plot(nodes,result(:,5))%nodes,speedup32,nodes,speedup64)
legend('16 ants', 'Location', 'northwest')
title('Percentages of serial code execution without data transfer')
xlabel('Nb of Nodes')
ylabel('% of serial code')