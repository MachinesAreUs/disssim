defmodule Disssim.Model.Client do
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
