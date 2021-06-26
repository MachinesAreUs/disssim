defmodule Disssim.Util.Pool do

  @max_timeout 60_000

  def create(:resource, resource, worker_opts) do
    pool_config = [
        name: {:local, String.to_atom(resource.id)}, #fix this
        worker_module: Disssim.Model.ResourceWorker,
        size: resource.concurrency,
        max_overflow: 0,
        strategy: :fifo
    ]
    {:ok, pool_id} = :poolboy.start(pool_config, worker_opts)
  end

  def create(:service, resource, worker_opts) do
    pool_config = [
        name: {:local, String.to_atom(resource.id)}, #fix this
        worker_module: Disssim.Model.ServiceWorker,
        size: resource.concurrency,
        max_overflow: 0,
        strategy: :fifo
    ]
    {:ok, pool_id} = :poolboy.start(pool_config, worker_opts)
  end

  def call(pool_id, msg) do
    pool_name = String.to_atom(pool_id) # fix this
    :poolboy.transaction(pool_name, fn pid -> GenServer.call(pid, msg, @max_timeout) end)
  end
end
