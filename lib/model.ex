defmodule Disssim.Model do

  defmodule Client do
    @keys [:id, :service, :request_rate]
    @enforce_keys @keys
    defstruct @keys

    def new(opts) do
      struct(%__MODULE__{
        id: UUID.uuid1(),
        service: nil,
        request_rate: 0
      }, opts)
    end
  end

  defmodule Service do
    @keys [:id, :resources, :max_capacity]
    @enforce_keys @keys
    defstruct @keys

    def new(opts) do
      struct(%__MODULE__{
        id: UUID.uuid1(),
        resources: [],
        max_capacity: 0
      }, opts)
    end
  end

  defmodule CircuitBreaker do
    @keys [:id, :resource, :timeout, :threshold, :delay]
    @enforce_keys @keys
    defstruct @keys

    def new(opts) do
      struct(%__MODULE__{
        id: UUID.uuid1(),
        resource: nil,
        timeout: 0,
        threshold: 0.0,
        delay: 0
      }, opts)
    end
  end
end
