defmodule Disssim.Model.Client do
  @keys [:id, :resource, :request_rate]
  @enforce_keys @keys
  defstruct @keys

  alias Disssim.Model.Service
  require Logger

  @millis_in_second 1_000

  def new(opts) do
    struct(%__MODULE__{
      id: UUID.uuid1(),
      resource: nil,
      request_rate: 0 # reqs/sec
    }, opts)
  end

  def start(opts) do
    client = new(opts)
    Agent.start(fn -> client end)
  end

  def state(pid), do: Agent.get(pid, &(&1))

  def call(pid, {:request, payload} = req) when is_binary(payload) do
    client = Agent.get(pid, fn client -> client end)
    Service.call(client.resource, req)
  end

  def call_n_times(pid, {:request, payload} = req, n) when is_binary(payload) do
    client = Agent.get(pid, fn client -> client end)
    Enum.each(1..n, &call_and_wait(&1, pid, client, req))
  end

  defp call_and_wait(n, pid, client, req) do
    Logger.debug(
      "Calling service #{inspect(client.resource)} from client #{inspect(pid)} n: #{n}")

    task = Task.async(fn -> Service.call(client.resource, req) end)
    delay = Integer.floor_div(@millis_in_second, client.request_rate)

    Logger.debug("Client #{inspect(pid)} waiting for #{delay} ms")
    :timer.sleep(delay)
  end
end
