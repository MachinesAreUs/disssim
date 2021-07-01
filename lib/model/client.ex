defmodule Disssim.Model.Client do
  @keys [:id, :resource, :request_rate, :status]
  @enforce_keys @keys
  defstruct @keys

  alias Disssim.Model.Service
  require Logger

  @millis_in_second 1_000
  @states [:running, :paused]

  def new(opts) do
    struct(%__MODULE__{
      id: UUID.uuid1(),
      resource: nil,
      request_rate: 0, # reqs/sec
      status: :paused
    }, opts)
  end

  def start(opts) do
    client = new(opts)
    Agent.start(fn ->
      %{
        client: client,
        stats: %{
          total_reqs: 0,
          fail_reqs: 0,
          timeout_reqs: 0,
          fail_rate: 0,
          avg_latency: 0.0
        }
      }
    end)
  end

  def state(pid), do: Agent.get(pid, &(&1))

  defp update_status(pid, status) when status in @states do
    Agent.update(pid, fn state ->
      new_client = %{state.client | status: status}
      %{state | client: new_client}
    end)
  end

  def play(pid) do
    state = state(pid)
    client = state.client
    case client.status do
      :running ->
        {:error, "#{inspect(pid)} is already running."}
      :paused ->
        update_status(pid, :running)
        Task.start(fn ->
          call_indefinitely(pid)
        end)
        {:ok, :running}
    end
  end

  def pause(pid) do
    state = state(pid)
    client = state.client
    case client.status do
      :running ->
        update_status(pid, :paused)
        {:ok, :paused}
      :paused ->
        {:error, "#{inspect(pid)} is already paused."}
    end
  end

  defp call_indefinitely(pid) do
    state = state(pid)
    client = state.client
    case client.status do
      :running ->
        call_and_wait(pid, client, {:request, "msg from client!"})
        call_indefinitely(pid)
      :paused ->
        :paused
    end
  end

  defp call_and_wait(pid, client, req) do
    Logger.debug(
      "Calling #{inspect(client.resource)} from client #{inspect(pid)}")

    Task.async(fn -> call(pid, client.resource, req) end)
    delay = trunc(@millis_in_second / client.request_rate)

    Logger.debug("Client #{inspect(pid)} waiting for #{delay} ms")
    :timer.sleep(delay)
  end

  defp call(pid, resource, {:request, payload} = req) when is_binary(payload) do
    ts_start = DateTime.utc_now
    response = Service.call(resource, req)
    ts_end = DateTime.utc_now
    update_stats(pid, response, ts_start, ts_end)
  end

  defp update_stats(pid, {:response, _, _}, ts_start, ts_end) do
    Agent.update(pid, fn state ->
      new_stats = %{state.stats |
        total_reqs: state.stats.total_reqs + 1,
      }
      %{state | stats: new_stats}
    end)
  end

  defp update_stats(pid, {:error, reason}, ts_start, ts_end) do
    Agent.update(pid, fn state ->
      timeout_reqs_incr = if reason == :timeout, do: 1, else: 0
      new_stats = %{state.stats |
        total_reqs: state.stats.total_reqs + 1,
        fail_reqs: state.stats.fail_reqs + 1,
        timeout_reqs: state.stats.timeout_reqs + timeout_reqs_incr,
        fail_rate: (state.stats.fail_reqs + 1) / (state.stats.total_reqs + 1),
      }
      %{state | stats: new_stats}
    end)
  end
end
