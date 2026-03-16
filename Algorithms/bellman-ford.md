Shortest Paths
In many applications one wants to obtain the shortest path from a to b. Depending on the context, the length of the path does not necessarily have to be the length in meter: One can as well look at the cost of a path – both if we have to pay for using it – or if we receive some.

In general we speak of cost. Therefore one assigns cost to each part of the path – also called "edge".

Dijkstra's Algorithm computes shortest – or cheapest paths, if all cost are positive numbers. However, if one allows negative numbers, the algorithm will fail.

The Bellman-Ford Algorithm by contrast can also deal with negative cost.

These can for example occur when a taxi driver receives more money for a tour than he spends on fuel. If he does not transport somebody, his cost are positive.

Idea of the Algorithm
Edge before update.
This edge is a short-cut:
We know that we have to pay 20 in order to go from the starting node to the left node. The path from the left to the right node has cost 1.
Therefore one can go from the starting node to the node on the right with a total cost of 21.

Edge before update.
The Bellman-Ford Algorithm computes the cost of the cheapest paths from a starting node to all other nodes in the graph. Thus, he can also construct the paths afterwards.

The algorithm proceeds in an interactive manner, by beginning with a bad estimate of the cost and then improving it until the correct value is found.

The first estimate is:

The starting node has cost 0, as his distance to itself is obviously 0.
All other node have cost infinity, which is the worst estimate possible.
Afterwards, the algorithm checks every edge for the following condition: Are the cost of the source of the edge plus the cost for using the edge smaller than the cost of the edge's target?

If this is the case, we have found a short-cut: It is more profitable to use the edge which was just checked, than using the path used so far. Therefore the cost of the edge's target get updated: They are set to the cost of the source plus the cost for using the edge (compare example on the right).

Looking at all edges of the graph and updating the cost of the nodes is called a phase. Unfortunately, it is not sufficient to look at all edges only once. After the first phase, the cost of all nodes for which the shortest path only uses one edge have been calculated correctly. After two phases all paths that use at most two edges have been computed correctly, and so on.

Graph with distances.
The green path from the starting node is the cheapest path. It uses 3 edges.

How many phases ware necessary? To answer this question, the observation that a shortest path has to use less edges than there are nodes in the graph. Thus, we need at most one phase less than the number of nodes in the graph. A shortest path that uses more edges than the number of nodes would visit some node twice and thus build a circle.

Construction of the shortest path
Each time when updating the cost of some node, the algorithm saves the edge that was used for the update as the predecessor of the node.

At the end of the algorithm, the shortest path to each node can be constructed by going backwards using the predecessor edges until the starting node is reached.

Circles with negative weight
Graph with negative circle.
A cheapest path had to use this circle infinitely often. The cost would be reduced in each iteration.

If the graph contains a circle with a negative sum of edge weights – a Negative Circle, the algorithm probably will not find a cheapest path.

As can be seen in the example on the right, paths in this case can be infinitely cheap – one keeps on going through the circle.

This problem occurs if the negative circle can be reached from the starting node. Luckily, the algorithm can detect whether a negative circle exists. This is checked in the last step of the algorithm.

A negative circle can be reached if and only if after iterating all phases, one can still find a short-cut. Therefore, at the end the algorithm checks one more time for all edges whether the cost of the source node plus the cost of the edge are less than the cost of the target node. If this is the case for an edge, the message "Negative Circle found" is returned.

One can even find the negative circle with the help of the predecessor edges: One just goes back until one traversed a circle (that had negative weight).