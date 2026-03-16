Shortest Paths
Here's an example problem: Consider 10 cities that are connected using various highways. The goal is to find the shortest distances between all cities in order to minimize transportation costs.

Consider a graph. If it doesn't contain any negative cycles, all shortest or cheapest paths between any pair of nodes can be calculated using the algorith of Floyd-Warshall. In graph theory a cycle is a path that starts and ends in the same vertex. A cycle is called negative if the sum of its edge weights is less than 0.

This problem can be solved using the Floyd-Warshall algorithm. The entire network in the problem statement can be modeled as a graph, where the nodes represent the cities and the edges represent the highways. Each edge will have an associated cost or weight that is equal to the distance of neighboring cities in kilometers. The goal then is to find the shortest paths between all cities.

Idea of the Algorith
Einfacher Graph mit 4 Knoten.
The path (a, d) has been improved.

The Floyd-Warshall algorithm relies on the principle of dynamic pogramming. This means that all possible paths between pairs of nodes are being compared step by step, while only saving the best values found so far.

The algorithm begins with the following observation: If the shortest path from u to v passes through w, then the partial paths from u to w and w to v must be minimal as well. Correctness of this statement can be shown by induction. The algorithm of Floy-Warshall works in an interative way.

Let G be a graph with numbered vertices 1 to N. In the kth step, let shortestPath(i,j,k) be a function that yields the shortest path from i to j that only uses nodes from the set {1, 2, ..., k}. In the next step, the algorithm will then have to find the shortest paths between all pairs i, j using only the vertices from {1, 2, ..., k, k + 1}.

For all pairs of vertices it holds that the shortest path must either only contain vertices in the set {1, ..., k}, or otherwise must be a path that goes from i to j via k + 1. This implies that in the (k+1)th step, the shortest path from i to j either remains shortestPath(i,j,k) or is being improved to shortestPath(i,k+1,k) + shortestPath(k+1, j, k), depending on which of these paths is shorter. Therefore, each shortest path remains the same, or contains the node k + 1 whenever it is improved.

This is the idea of dynamic programming. In each iteration, all pairs of nodes are assigned the cost for the shortest path found so far:

shortestPath(i, j, k) = min(shortestPath(i, j, k), shortestPath(i, k + 1, k) + shortestPath(k + 1, j, k))

When the Floyd-Warshall algorithm terminates, each path may contain any possible transit node. However, only the shortest path found for each pair of nodes is saved by the algorithm. All these values are optimal since in each step, the algorithm updates the values whenever the new cost is smaller than the previous.

Finding Shortest Paths
Distanzmatrix
The path between vertices a and d has been improved.
In order to find all shortest paths simultaneously, the algorithm needs to save a matrix that contains the current cost for all pairs of nodes. Row and column indices of this matrix represent the nodes and each entry contains the corresponding current cost.

Assume the graph is specified by its weight matrix W. Then the matrix entry W[i,j] is the weight of the edge (i,j), if this edge exists. If not edge from i to j exists then W[i,j] will be infinity.

The Floyd-Warshall algorithm uses the concept of dynamic programming (see above). First of all, the algorithm is being initialized:

Initialize the matrix D of shortest distances with the same entries as the weight matrix W.
The algorithm executes the main loop with k ranging from 1 to n. In each iteration of this loop the algorithm tries to improve all (i,j) paths by the paths (i, k) and (k, j).
To do so consider the distances between all pairs of nodes (i,j) in each iteration. The algorithm checks whether (i,k) concatenated with (k,j) is shorter than the current distance of (i,j)
If the combined distances between i, k and k, j are in fact shorter than the current distance, then the distance between i and j will be updated.
Graphs with negative cycles
Negativer Kreis
The path between a and e can be arbritarily small (negative).
A negative cycle is a cycle such that the sum of its edge weights is negative. If the graph contains one ore more negative cycles, then no shortest path exists for vertices that form a part of the negative cycle. The path between these nodes can then be arbitrarily small (negative). Therefore, in order for the Floyd-Warshall algorithm to produce correct results, the graph must be free of negative cycles.

The graph can also be used to discover negative cycles in graphs: Let the algorithm consider all pairs of nodes (i,j) (including those, where i = j). If, after termination of the algorithm, any cost (i, j) in the distance matrix is negative, then the graph contains at least one negative cycle.

The example in the figure contains the negative cycle (b, c, d). This means the cycle can be traversed an infinite amount of times and the distance between any nodes in the cycle will become shorter and shorter each and every time. Furthermore, the path between the vertices a and e in the example can be arbitrarily short as well, as a path between them may contain the negative cycle.