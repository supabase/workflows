defmodule Workflows.Workflow do
  @moduledoc false

  alias Workflows.Activity

  @type activities :: %{Activity.name() => Activity.t()}
  @type t :: %__MODULE__{
               start_at: Activity.name(),
               activities: activities()
             }

  defstruct [:activities, :start_at]

  @spec parse(map()) :: {:ok, t()} | {:error, term()}
  def parse(definition) do
    do_parse(definition)
  end

  @spec create(Activity.name(), activities()) :: t()
  def create(start_at, activities) do
    %__MODULE__{
      start_at: start_at,
      activities: activities
    }
  end

  ## Private

  defp do_parse(%{"StartAt" => start_at, "States" => states}) do
    with {:ok, states} = parse_states(Map.to_list(states), []) do
      {:ok, create(start_at, states)}
    end
  end

  defp do_parse(_definition), do: {:error, "Definition requires StartAt and States fields"}

  defp parse_states([], acc), do: {:ok, Enum.into(acc, %{})}

  defp parse_states([{state_name, state_def} | states], acc) do
    with {:ok, state} = Activity.parse(state_name, state_def) do
      parse_states(states, [{state_name, state} | acc])
    end
  end

end
