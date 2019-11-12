defmodule Helper do
  def finger_node(node, keys, table, bits) do
    pid = Map.get(table, node)
    finger_table=[]
    mod = :math.pow(2,bits)|>round()
    finger_table=Enum.map((0..bits-1), fn y->
    next_node= (node + :math.pow(2,y))|>round()
    next_node=rem(next_node, mod)
    next=Enum.find(keys, fn x-> x >= next_node end)
    res=
      if (next == node)  do
          l = Enum.find(keys,fn x -> x==node end)
          Enum.at(keys,l-1)
      else
          if(next == nil) do
              Enum.at(keys,0)
          else
              next
          end
      end
    res
    end)
    Ring.set_finger_table(pid,finger_table)
  end
  def find_hash(dest_node, x, table,numHops) do
    pid=Map.get(table, x)
    finger_table=GenServer.call(pid,:get_fingerTable)
    next_node=GenServer.call(pid,:get_succ)
    cond do
      dest_node > x and dest_node <= next_node -> numHops+1
      next_node < x ->
      cond do
        dest_node < x and dest_node <= next_node -> numHops+1
        dest_node > x and dest_node >= next_node -> numHops+1
          true ->
            newNode=Ring.closest_preceeding(x,dest_node,finger_table)
            find_hash(dest_node,newNode,table,numHops+1)
      end
    true->
      newNode=Ring.closest_preceeding(x,dest_node,finger_table)
      find_hash(dest_node,newNode,table,numHops+1)
    end
end
  def find_avg_time(sum,count,numRequests) do
    sum_of_hops =Enum.sum(sum)
    y = sum_of_hops/(count*numRequests)
    IO.puts("The average hops per request is: #{y}")
    System.halt(1)
  end
  def create_nodes(numNodes, bits) do
    table=Enum.reduce((0.. numNodes-1), %{},fn (hash, table)->
        {pid, hashNum}=Ring.create_hashNum(numNodes, table, bits)
        table=Map.put(table, hashNum, pid)
        table
    end)
    table
  end
end
