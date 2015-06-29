defmodule KV.Registry do
  use GenServer

  # Client API
  
  def start_link(event_manager, buckets, opts \\ []) do
    GenServer.start_link(__MODULE__, {event_manager, buckets}, opts)
  end

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  def stop(server) do
    GenServer.call(server, :stop)
  end
  
  # Server API

  def init({events, buckets}) do
    names = HashDict.new
    refs = HashDict.new
    {:ok, %{names: names, refs: refs, events: events, buckets: buckets}}
  end

  def handle_call({:lookup, name}, _from, state) do
    {:reply, HashDict.fetch(state.names, name), state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end
  
  def handle_cast({:create, name}, state) do
    if HashDict.get(state.names, name) do
      {:noreply, state}
    else
      {:ok, bucket} = KV.Bucket.Supervisor.start_bucket(state.buckets)
      ref = Process.monitor(bucket)
      refs = HashDict.put(state.refs, ref, name)
      names = HashDict.put(state.names, name, bucket)
      GenEvent.sync_notify(state.events, {:create, name, bucket})
      {:noreply, %{state | names: names, refs: refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {name, refs} = HashDict.pop(state.refs, ref)
    names = HashDict.delete(state.names, name)
    GenEvent.sync_notify(state.events, {:exit, name, pid})
    {:noreply, %{state | names: names, refs: refs}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
