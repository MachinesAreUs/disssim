defmodule Disssim.Model.CircuitBreaker do
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
