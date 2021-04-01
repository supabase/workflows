defmodule Workflows.Path do
  @moduledoc """
  A Path is used to query json objects.
  """

  @opaque t :: %__MODULE__{
            inner: term()
          }

  defstruct [:inner]

  @spec create(String.t()) :: {:ok, t()} | {:error, term()}
  def create(path) do
    # TODO: parse path
    {:ok, %__MODULE__{inner: path}}
  end
end
