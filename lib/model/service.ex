defmodule Disssim.Model.Service do
  @keys [:id, :resources, :concurrency]
  @enforce_keys @keys
  defstruct @keys

  alias Disssim.Util.Pool

  def new(opts) do
    struct(%__MODULE__{
      id: UUID.uuid1(),
      resources: [],
      concurrency: 0
    }, opts)
  end

  def start(opts) do
    resource = new(opts)
    {:ok, pool_pid} = Pool.create(Disssim.Model.ServiceWorker, resource, opts)
    Agent.start(fn -> %{pool_pid: pool_pid, resource: resource} end)
  end

  def call(resource_pid, {:request, payload} = req) when is_binary(payload) do
    pool_id = Agent.get(resource_pid, fn state -> state.resource.id end)
    Pool.call(pool_id, req)
  end
end
