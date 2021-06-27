defmodule Disssim.Model.ServiceWorker do
  use GenServer
  require Logger

  alias Disssim.Model.Resource

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    {:ok, Disssim.Model.Service.new(opts)}
  end

  @impl true
  def handle_call({:request, payload}, _from, resource) do
    Logger.debug "Handling svc request form #{inspect(self())}"

    req_time = delay(resource)
    response = gen_response(payload, req_time, resource)
    {:reply, response, resource}
  end

  defp delay(_), do: 0

  defp gen_response(_payload, _req_time, resource) do
    responses =
      resource.resources
      |> Enum.map(&Resource.call(&1, {:request, "call from #{inspect(self())}"}))

    succeeded =
      responses
      |> Enum.all?(&Kernel.match?({:response, _, _}, &1))

    gen_response(succeeded, responses)
  end

  defp gen_response(true, responses) do
    resp_payload =
      responses
      |> Enum.map(fn {:response, payload, _} -> payload end)
      |> Enum.join(" || ")

    req_time =
      responses
      |> Enum.map(fn {:response, _, req_time: delay} -> delay end)
      |> Enum.sum

    {:response, resp_payload, req_time:  req_time}
  end

  defp gen_response(false, _) do
    {:error, "duh!"}
  end
end
