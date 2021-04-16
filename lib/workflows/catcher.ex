defmodule Workflows.Catcher do
  @moduledoc false

  alias Workflows.{Activity, Error}

  @opaque t :: %__MODULE__{
            errors: list(String.t()),
            next: Activity.name()
          }

  defstruct [:errors, :next]

  @spec create(map()) :: {:ok, t()} | {:error, term()}
  def create(%{"ErrorEquals" => errors, "Next" => next}) when is_list(errors) do
    catcher = %__MODULE__{
      errors: errors,
      next: next
    }

    {:ok, catcher}
  end

  def create(_definition) do
    {:error, :invalid_catcher}
  end

  @doc """
  Returns true if any of the catchers match the error.
  """
  @spec matches?(t(), Error.t()) :: boolean()
  def matches?(catcher, error) do
    Enum.any?(catcher.errors, fn e -> e == "States.ALL" || e == error.name end)
  end
end
