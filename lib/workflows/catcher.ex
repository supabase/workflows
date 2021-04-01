defmodule Workflows.Catcher do
  @moduledoc false

  alias Workflows.Activity

  @opaque t :: %__MODULE__{
            errors: list(String.t()),
            next: Activity.name()
          }

  defstruct [:errors, :next]

  @spec create(map()) :: {:ok, t()} | {:error, term()}
  def create(%{"ErrorEquals" => errors, "Next" => next}) when is_list(errors) do
    # TODO: implement this
    catcher = %__MODULE__{
      errors: errors,
      next: next
    }

    {:ok, catcher}
  end

  def create(_definition) do
    {:error, :invalid_catcher}
  end
end
