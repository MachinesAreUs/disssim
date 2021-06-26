defmodule Disssim.Model.ResourceWorker do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    {:ok, Disssim.Model.Resource.new(opts)}
  end

  @impl true
  def handle_call({:request, payload}, _from, resource) do
    req_time = delay(resource)
    response = gen_response(payload, req_time, resource)
    Logger.debug "Handling res request form #{inspect(self())}"
    {:reply, response, resource}
  end

  defp delay(res) do
    sleep_millis = res.min_latency + :rand.uniform(res.max_latency - res.min_latency)
    :timer.sleep(sleep_millis)
    sleep_millis
  end

  defp gen_response(payload, req_time, resource) do
    case :rand.uniform() do
      p when p >= resource.fail_rate ->
        rand = :rand.uniform(100) |> Integer.to_string
        {:response, payload <> "-" <> rand, req_time: req_time}
      _ ->
        {:error, "duh!"}
    end
  end
end
