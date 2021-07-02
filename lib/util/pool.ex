defmodule Disssim.Util.Pool do
  @max_timeout 60_000

  @pool_opts [
    max_overflow: 0,
    strategy: :fifo
  ]

  def create(worker_module, resource, worker_opts) do
    pool_opts =
      [
        name: {:local, pool_name(resource)},
        worker_module: worker_module,
        size: resource.concurrency
      ]
      |> Keyword.merge(@pool_opts)

    start_pool(pool_opts, worker_opts)
  end

  def call(pool_id, msg) do
    # fix this
    pool_name = String.to_atom(pool_id)

    :poolboy.transaction(pool_name, fn pid ->
      GenServer.call(pid, msg, @max_timeout)
    end)
  end

  defp pool_name(resource) do
    # fix this
    String.to_atom(resource.id)
  end

  defp start_pool(pool_opts, worker_opts) do
    :poolboy.start(pool_opts, worker_opts)
  end
end
