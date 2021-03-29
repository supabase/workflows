defmodule Workflows.ReferencePath do
  @moduledoc """
  A Reference Path is a Path with the syntax limited to identify a single node.
  """

  @opaque t :: term()

  defstruct [:inner]

  @doc """
  Create a new ReferencePath.
  """
  @spec create(String.t()) :: {:ok, t()} | {:error, term()}
  def create(path) do
    {:ok, %__MODULE__{inner: path}}
  end
end
