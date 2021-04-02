defmodule Workflows.Path do
  @moduledoc """
  A Path is used to query json objects.
  """
  alias Workflows.Activity

  @opaque t :: %__MODULE__{
            inner: term()
          }

  defstruct [:inner]

  @spec create(String.t()) :: {:ok, t()} | {:error, term()}
  def create(path) do
    with {:ok, inner} <- Warpath.Expression.compile(path) do
      {:ok, %__MODULE__{inner: inner}}
    end
  end

  @spec query(t(), Activity.args()) :: {:ok, Activity.args()} | {:error, term()}
  def query(%__MODULE__{inner: inner}, data) do
    Warpath.query(data, inner)
  end
end
