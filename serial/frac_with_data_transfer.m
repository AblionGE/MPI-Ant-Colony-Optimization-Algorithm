nants = [1 2 4 8 16];
nodes = [1 2 4 8 16];
c = 1000
result = zeros(size(nodes,2),size(nants,2))
L = 5000

for i = 1:size(nants,2)
    for j = 1:size(nodes,2)
        result(j,i) = (2*(c*c+c*L*nodes(j)))/(2*(c*c+c*L*nodes(j) + L*c*c*(1 + (nants(i)/nodes(j)))));
    end
end

disp(result)

figure
plot(nodes,result(:,5))%nodes,speedup32,nodes,speedup64)
legend('16 ants', 'Location', 'northwest')
title('Percentages of serial code execution with data transfer')
xlabel('Nb of Nodes')
ylabel('% of serial code')