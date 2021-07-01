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
    Agent.start(fn -> client end)
  end

  def state(pid), do: Agent.get(pid, &(&1))

  def update_status(pid, status) when status in @states do
    Agent.update(pid, &(%{&1 | status: status}))
  end

  def play(pid) do
    client = state(pid)
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
    client = state(pid)
    case client.status do
      :running ->
        update_status(pid, :paused)
        {:ok, :paused}
      :paused ->
        {:error, "#{inspect(pid)} is already paused."}
    end
  end

  defp call_indefinitely(pid) do
    client = state(pid)
    case client.status do
      :running ->
        call_and_wait(pid, client, {:request, "msg from client!"})
        call_indefinitely(pid)
      :paused ->
        :paused
    end
  end

  def call(pid, {:request, payload} = req) when is_binary(payload) do
    client = Agent.get(pid, fn client -> client end)
    Service.call(client.resource, req)
  end

  defp call_and_wait(pid, client, req) do
    Logger.debug(
      "Calling #{inspect(client.resource)} from client #{inspect(pid)}")

    Task.async(fn -> Service.call(client.resource, req) end)
    delay = trunc(@millis_in_second / client.request_rate)

    Logger.debug("Client #{inspect(pid)} waiting for #{delay} ms")
    :timer.sleep(delay)
  end
end
