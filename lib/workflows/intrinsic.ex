defmodule Workflows.Intrinsic do
  @moduledoc """
  Intrinsic functions used to process payload template data.
  """
  alias Workflows.Activity

  @opaque t :: %__MODULE__{
            name: String.t(),
            args: any()
          }

  defstruct [:name, :args]

  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(_definition) do
    {:error, :not_implemented}
  end

  @spec apply(String.t(), Activity.ctx(), Activity.args()) ::
          {:ok, Activity.args()} | {:error, term()}
  def apply(_definition, _ctx, _args) do
    {:error, :not_implemented}
  end
end
