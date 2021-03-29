defmodule Workflows.Catcher do
  @moduledoc false

  @opaque t :: term()

  @spec create(any()) :: {:ok, t()} | {:error, term()}
  def create(_attrs) do
    # TODO: implement this
    {:ok, nil}
  end
end
