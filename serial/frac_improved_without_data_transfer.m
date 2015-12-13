nants = [1 2 4 8 16];
nodes = [1 2 4 8 16];
c = 1000
result = []
L = 100
l = 50

for i = 1:size(nants,2)
    for j = 1:size(nodes,2)
        result(j,i) = (L*nodes(j) + c)/(L*nodes(j) + c + L*l*c*(1+nants(i)/nodes(j)));
    end
end

disp(result)

figure
plot(nodes,result(:,5))%nodes,speedup32,nodes,speedup64)
legend('16 ants', 'Location', 'northwest')
title('Percentages of improved serial code execution without data transfer')
xlabel('Nb of Nodes')
ylabel('% of serial code')