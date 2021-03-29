defmodule Workflows.PayloadTemplate do
  @moduledoc """
  A PayloadTemplate is used to create new Json objects by combining other objects.
  """

  @opaque t :: term()

  defstruct [:template]

  @doc """
  Create a payload template.
  """
  @spec create(map()) :: {:ok, t()} | {:error, term()}
  def create(template) do
    # TODO: validate payload template
    {:ok, %__MODULE__{template: template}}
  end
end
