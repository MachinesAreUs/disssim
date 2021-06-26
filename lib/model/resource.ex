defmodule Resource do
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

  @impl true
  def init(opts) do
    {:ok, new(opts)}
  end

  @impl true
  def handle_call({:request, payload}, _from, resource) do
    req_time = delay(resource)
    response = gen_response(payload, req_time, resource)
    {:reply, response, resource}
  end

  defp delay(res) do
    sleep_millis = res.min_latency + :rand.uniform(res.max_latency - res.min_latency)
    :timer.sleep(sleep_millis)
    sleep_millis
  end

  defp gen_response(payload, req_time, resource) do
    case :rand.uniform() do
      p when p <= resource.fail_rate ->
        rand = :rand.uniform(100) |> Integer.to_string
        {:response, payload <> "-" <> rand, req_time: req_time}
      _ ->
        {:error, "duh!"}
    end
  end
end
