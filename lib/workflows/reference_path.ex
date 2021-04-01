defmodule Workflows.ReferencePath do
  @moduledoc """
  A Reference Path is a Path with the syntax limited to identify a single node.
  """

  @opaque t :: %__MODULE__{
            inner: term()
          }

  defstruct [:inner]

  @doc """
  Create a new ReferencePath.
  """
  @spec create(String.t()) :: {:ok, t()} | {:error, term()}
  def create(path) do
    {:ok, %__MODULE__{inner: path}}
  end

  @spec apply(t(), map(), map()) :: {:ok, term()} | {:error, term()}
  def apply(%__MODULE__{inner: inner}, document, _args) do
    case inner.tokens do
      [root: "$"] -> {:ok, document}
      _ -> {:error, :not_implemented}
    end
  end

  @spec query(t(), map()) :: {:ok, term()} | {:error, term()}
  def query(%__MODULE__{inner: inner}, document) do
    case Warpath.query(document, inner, result_type: :value_path_tokens) do
      {:ok, {value, _}} -> {:ok, value}
      {:ok, [_]} -> {:error, :invalid_reference_path}
      error -> error
    end
  end
end
