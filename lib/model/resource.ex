defmodule Disssim.Model.Resource do
  @keys [:id, :min_latency, :max_latency, :fail_rate, :concurrency]
  @enforce_keys @keys
  defstruct @keys

  @max_timeout 60_000

  def new(opts) do
    struct(%__MODULE__{
      id: UUID.uuid1(),
      min_latency: 0,
      max_latency: 0,
      fail_rate: 0,
      concurrency: 0
    }, opts)
  end

  def start(opts) do
    resource = new(opts)
    pool_config = [
        name: {:local, String.to_atom(resource.id)}, #fix this
        worker_module: Disssim.Model.ResourceWorker,
        size: resource.concurrency,
        max_overflow: 0,
        strategy: :fifo
    ]
    {:ok, pool_id} = :poolboy.start(pool_config, opts)
    {:ok, resource_pid} = Agent.start(fn -> %{pool_id: pool_id, resource: resource} end)
  end

  def send(resource_pid, {:request, payload} = req) when is_binary(payload) do
    pool_name =
      resource_pid
      |> Agent.get(fn state -> state.resource.id end)
      |> String.to_atom() # fix this
    :poolboy.transaction(pool_name, fn pid -> GenServer.call(pid, req, @max_timeout) end)
  end
end
