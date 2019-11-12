[numNodes, numRequests] = System.argv()
num_nodes = numNodes |> String.to_integer
num_requests = numRequests |> String.to_integer
Ring.main(num_nodes, num_requests)
