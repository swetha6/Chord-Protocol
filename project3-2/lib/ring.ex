defmodule Ring do
 use GenServer
 def create_table(nodes) do
    ids = Enum.map(nodes, fn(x) ->
      {a,b,c,d,e} = get_state(x)
      [b,x]
    end)
    new_map = ids |> Enum.map(fn [b,a] -> {b,a} end) |> Map.new
  end
  def get_state(node) do
    GenServer.call(node, {:getstate})
  end
  def handle_call({:getstate}, __from, state) do
    {a,b,c,d,e} = state
    {:reply, {a,b,c,d,e}, state}
  end
 def init(id) do
   {:ok,{id,0,0,0,0}}
 end
 def handle_call({:set_pred,x}, __from, state) do
   {id,finger_table, pred, succ,hash}=state
   {:reply, id, {id, finger_table, x, succ,hash}}
 end
 def handle_call({:set_succ,x}, __from, state) do
   {id,finger_table, pred, succ,hash}=state
   {:reply, id, {id, finger_table, pred, x,hash}}
 end

 def handle_call({:set_id,x}, __from, state) do
   {id,finger_table, pred, succ,hash}=state
   {:reply, x, {x, finger_table, pred, succ,hash}}
 end

 def handle_call(:get_id, _from, state) do
    {id,finger_table, pred, succ,hash}=state
   {:reply, id,state}
 end
 def print_table(nodes) do
    Enum.each(nodes, fn(x) ->
      {a,b,c,d,e} = get_state(x)
      # IO.inspect d
    end)
  end
 def handle_call(:get_pred, _from, state) do
   {id,finger_table, pred, succ,hash}=state
   {:reply, pred,state}
 end

 def handle_call(:get_succ, _from,state) do
   {_,_,_,succ,hash}=state
   {:reply, succ, state}
 end

 def create_hash(pid, pid_str, bits) do
    pid_str=inspect(pid)
    hash=:crypto.hash(:sha, pid_str) |> Base.encode16
    hash_value=String.slice(hash,0..bits-1)
    g = Integer.parse(hash_value,16)
    {hash_num, _} = g
    hash_num
 end
 def start_node() do
    {:ok, pid} = GenServer.start_link(__MODULE__, 0)
    pid
  end
 def create_hashNum(numNodes, table, bits) do
   pid =  start_node()
   pid_str = inspect(pid)
   hashNum = create_hash(pid,pid_str,bits)
    update_pid(pid,hashNum)
    {pid, hashNum}
 end

 def update_pid(pid,hashNum) do
   GenServer.call(pid,{:set_id, hashNum})
 end

 def handle_call({:set_fingerTable,table},__from,state) do
    {x,_,pred,succ,hash}=state
    {:reply,x, {x, table, pred,succ,hash}}
  end

  def handle_call(:get_state,_from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_fingerTable, _from, state) do
     {id,finger_table, pred, succ,hash}=state
    {:reply, finger_table, state}
  end

 def set_succ(keys, table) do
    Enum.each(0..(length(keys)-1), fn(x) ->
       currNode = Map.get(table, (Enum.at(keys,x)))
       nextNodeNum = Enum.at(keys, rem(x+1,length(keys)))
       GenServer.call(currNode,{:set_succ, nextNodeNum})
    end)
  end
  def set_pred(keys, table) do
    Enum.each((0..(length(keys)-1)), fn(x) ->
        currNode = Map.get(table, (Enum.at(keys,x)))
        currNodeNum = Enum.at(keys,x)
        GenServer.call(currNode,{:set_pred, currNodeNum})
     end)
    end

   def set_finger_table(pid,finger_table) do
    GenServer.call(pid,{:set_fingerTable,finger_table})
   end

   def req_per_node(x, table, numRequests, bits) do
       hop_time=[]
       mod=:math.pow(2,bits)|>round()
       hop_time=Enum.map((1..numRequests), fn (req)->
           dest_node=:rand.uniform(mod)-1
           m = Helper.find_hash(dest_node,x, table , 0)
       end)
   end

def closest_preceeding(node, dest_node,finger_table) do
    closest_table = Enum.reverse(finger_table)
    cond do
        node < dest_node->
            closest=Enum.find(closest_table,fn(x) -> x < dest_node and x >node end)
        node >= dest_node ->
            closest=Enum.find(closest_table,fn(x) -> x < dest_node end)
            if (closest != nil) do
                closest
            else
                closest=Enum.find(closest_table,fn(x) -> x > dest_node and x > node end)
            end
        true->
            closest = Enum.at(finger_table,(Enum.count(finger_table)-1))
    end
end

def recursive(keys, table, numRequests, bits) do
    num_nodes=length(keys)
    numHops= Enum.map((keys), fn r->
            hope_node=req_per_node(r,table, numRequests, bits)
            end)
    new_hops = Enum.map(numHops, fn x->
    sum = Enum.sum(x)
    end)
    Helper.find_avg_time(new_hops,num_nodes,numRequests)
end
def create_finger_table(keys,table,bits) do
    Enum.map((keys), fn (x)->
        Helper.finger_node(x, keys,table, bits)
        end)
end
def main(numNodes, numRequests) do
    m=:math.log(numNodes)/:math.log(2)
    bits= (m/2)|> Float.ceil() |>round()
    k = 4 * (bits+1)
    table=Helper.create_nodes(numNodes, bits)
    table_keys=Map.keys(table)
    keys=Enum.sort(table_keys)
    set_succ(keys, table)
    set_pred(keys, table)
    create_finger_table(keys,table,k)
    recursive(keys, table, numRequests, k)
    end
end
