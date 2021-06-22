defmodule Util.TypedStruct do
  defmacro __using__(_env) do
    quote do
      import TypedStruct
    end
  end

  defmacro new_struct(name, attrs \\ []) do
    keys = Keyword.keys(attrs)

    quote do
      defmodule unquote(name) do
        @enforce_keys unquote(keys)
        defstruct unquote(keys)
        @type t :: %__MODULE__{
          unquote_splicing(attrs)
        }
      end
    end
  end
end
