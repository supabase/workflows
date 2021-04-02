defmodule Workflows.Error do
  @moduledoc """
  Represent an execution error. Errors have a name and a human-readable cause.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          cause: String.t()
        }

  defstruct [:name, :cause]

  @doc """
  Create a new error.
  """
  @spec create(String.t(), String.t()) :: t()
  def create(name, cause) do
    %__MODULE__{
      name: name,
      cause: cause
    }
  end
end
