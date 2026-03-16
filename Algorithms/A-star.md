Algorithm idea
The A* algorithm computes the shortest path between two nodes in a graph. If all shortest paths starting at some node are needed (which is what Dijkstra's Algorithm computes), the algorithm must be executed multiple times.

The A* algorithm is an informed search procedure. While Dijkstra's algorithm blindly chooses the next node available, the A* algorithm uses extra information to choose the best node leading to the target.

As additional information, the algorithm uses a heuristic that estimates the distance from any node to the target. This estimate acts as a rule of thumb for the algorithm and speeds up the computation.



Description of the algorithm
Kante vor Update
This edge is a shortcut.
We know that getting to the node on the left costs 20 units. The path from the left to the right node costs 1 unit.
Kante vor Update
Therefore, the path to the right node costs 21 units.
During the A* algorithm, each node has one of the three following states:

The node is unknown: The node has not been processed yet and no way from the start to this node is known.
The node is in the priority queue: We know some way leading to this node, but there may be a shorter way.
The node is fully processed: We know the shortest path from the starting node to it.
The algorithm first adds the starting node to the empty priority queue. Each node in the priority queue has an f-value. This value is the sum of the distance from the starting node to this node and the estimate of its distance to the target node. The node with the smallest f-value leads the priority queue and will be processed next.

The algorithm now takes the node with the minimum f-value from the priority queue until the queue is empty or a path to the target node has been found. If the node taken from the queue is the target node, then the algorithm has found the shortest path and terminates. If the priority queue becomes empty, then no path from the start to the target is possible and the algorithm terminates.

After processing a node from the priority queue, its neighbors are inspected. The algorithm distinguishes three cases:

The neighbor has already been processed:
Then the algorithm does nothing.
The neighbor is already in the prioity queue:
If the current path is a shortcut, update its f-value.
The neighbor is not in the priority queue:
Compute the f-value of the node and add it to the priority queue.
Shortest paths to all nodes that have been found by the algorithm can be constructed via the procedure described below.

What is an admissible estimate function?
Recall the definition of the f-value: It is the sum of the distance of the node to the starting node and the estimated distance of the node to the target. The distance of the node to the starting node has already been computed. The estimated distance is given by some estimate function.

One possible estimate function is the straight line distance between two nodes. Mathematically, this is the euclidean distance between the nodes. If one node has the (real-world) coordinates (x1, y1), while the other node has corrdinates (x2, y2), their euclidean distance is √((x1-x2)2+(y1-y2)2).

The algorithm works with other estimate functions as well. However, these functions must be admissible. An estimate function is admissible, if it cannot overestimate the distance between two nodes. For example, if towns A and B are 10 km away from each other, then the estimate of their distance must be at least 10 km. If the estimate function is not admissible, the algorithm might give an incorrect solution.

Graph with distances
The green path from the starting node to node b is the cheapest path. It uses 3 edges.
Construction of the shortest path
Each time when updating the cost of some node, the algorithm saves the edge that was used for the update as the predecessor of the node.

At the end of the algorithm, the shortest path to each node can be constructed by going backwards using the predecessor edges until the starting node is reached.

If a node cannot be reached from the starting node, then its cost stays infite.