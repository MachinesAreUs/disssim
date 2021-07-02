defmodule Disssim.Model.Resource do
  @keys [:id, :min_latency, :max_latency, :fail_rate, :concurrency]
  @enforce_keys @keys
  defstruct @keys

  alias Disssim.Util.Pool
  require Logger

  def new(opts) do
    struct(
      %__MODULE__{
        id: UUID.uuid1(),
        min_latency: 0,
        max_latency: 0,
        fail_rate: 0,
        concurrency: 0
      },
      opts
    )
  end

  def start(opts) do
    resource = new(opts)
    {:ok, pool_pid} = Pool.create(Disssim.Model.ResourceWorker, resource, opts)

    Agent.start(fn ->
      %{
        pool_pid: pool_pid,
        resource: resource,
        stats: %{
          total_reqs: 0,
          curr_reqs: 0,
          fail_reqs: 0,
          fail_rate: 0.0
        }
      }
    end)
  end

  def state(pid), do: Agent.get(pid, & &1)

  def call(pid, {:request, payload} = req) when is_binary(payload) do
    state = update_stats(:request, pid)

    try do
      response = Pool.call(state.resource.id, req)
      update_stats(:response, pid, response)
      response
    catch
      :exit, {:timeout, _} ->
        Logger.warning("Request to res #{inspect(pid)} failed: Connection timeout")
        response = {:error, :timeout}
        update_stats(:response, pid, response)
        response
    end
  end

  defp update_stats(:request, pid) do
    Agent.get_and_update(pid, fn state ->
      new_stats = %{
        state.stats
        | total_reqs: state.stats.total_reqs + 1,
          curr_reqs: state.stats.curr_reqs + 1
      }

      new_state = %{state | stats: new_stats}
      {new_state, new_state}
    end)
  end

  defp update_stats(:response, pid, response) do
    Agent.get_and_update(pid, fn state ->
      new_stats = %{
        state.stats
        | curr_reqs: state.stats.curr_reqs - 1,
          fail_reqs: fail_reqs(state.stats, response),
          fail_rate: fail_rate(state.stats, response)
      }

      new_state = %{state | stats: new_stats}
      {new_state, new_state}
    end)
  end

  defp fail_reqs(stats, {:response, _, _}), do: stats.fail_reqs

  defp fail_reqs(stats, {:error, _}), do: stats.fail_reqs + 1

  defp fail_rate(stats, {:response, _, _}), do: stats.fail_reqs / stats.total_reqs

  defp fail_rate(stats, {:error, _}), do: (stats.fail_reqs + 1) / stats.total_reqs
end
