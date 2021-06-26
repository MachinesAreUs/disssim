defmodule Disssim.Model.Resource do
  @keys [:id, :min_latency, :max_latency, :fail_rate]
  @enforce_keys @keys
  defstruct @keys

  use GenServer

  def new(opts) do
    struct(%__MODULE__{
      id: UUID.uuid1(),
      min_latency: 0,
      max_latency: 0,
      fail_rate: 0
    }, opts)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def send(pid, {:request, payload} = req) when is_binary(payload) do
    GenServer.call(pid, req)
  end

end
