defmodule Disssim.Model.Resource do
  @keys [:id, :min_latency, :max_latency, :fail_rate, :concurrency]
  @enforce_keys @keys
  defstruct @keys

  alias Disssim.Util.Pool

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
    {:ok, pool_pid} = Pool.create(:resource, resource, opts)
    {:ok, resource_pid} = Agent.start(fn -> %{pool_pid: pool_pid, resource: resource} end)
  end

  def send(resource_pid, {:request, payload} = req) when is_binary(payload) do
    pool_id = Agent.get(resource_pid, fn state -> state.resource.id end)
    Pool.call(pool_id, req)
  end
end
