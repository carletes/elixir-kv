defmodule KV.Bucket do
  def start_link do
    Agent.start_link(fn -> HashDict.new end)
  end

  def delete(bucket, key) do
    Agent.get_and_update(bucket, &HashDict.pop(&1, key))
  end
  
  def get(bucket, key) do
    Agent.get(bucket, &HashDict.get(&1, key))
  end

  def put(bucket, key, value) do
    Agent.update(bucket, &HashDict.put(&1, key, value))
  end
end

defmodule KV.Bucket.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_bucket(supervisor) do
    Supervisor.start_child(supervisor, [])
  end

  def init(:ok) do
    children = [worker(KV.Bucket, [], restart: :temporary)]
    supervise(children, strategy: :simple_one_for_one)
  end
end
