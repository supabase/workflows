defmodule Workflows.Workflow do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Command
  alias Workflows.Event
  alias Workflows.State

  @type activities :: %{Activity.name() => Activity.t()}
  @type t :: %__MODULE__{
          start_at: Activity.name(),
          activities: activities()
        }

  @type project_result :: {:continue, State.t()} | {:succeed, Activity.args()} | {:error, term()}

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

  @spec starting_activity(t()) :: {:ok, Activity.t()} | {:error, term()}
  def starting_activity(workflow) do
    activity(workflow, workflow.start_at)
  end

  @spec activity(t(), Activity.name()) :: {:ok, Activity.t()} | {:error, term()}
  def activity(workflow, name) do
    Map.fetch(workflow.activities, name)
  end

  @spec execute(t(), State.t(), Activity.ctx()) :: State.execute_result()
  def execute(workflow, state, ctx) do
    with {:ok, current_activity} <- activity(workflow, state.activity) do
      State.execute(state, current_activity, ctx)
    end
  end

  @spec execute(t(), State.t(), Activity.ctx(), Command.t()) :: State.execute_command_result()
  def execute(workflow, state, ctx, cmd) do
    with {:ok, current_activity} <- activity(workflow, state.activity) do
      State.execute(state, current_activity, ctx, cmd)
    end
  end

  @spec project(t(), State.t() | nil, list(Event.t()) | Event.t()) :: project_result()
  def project(workflow, state, events) do
    do_project(workflow, state, events)
  end

  ## Private

  defp do_parse(%{"StartAt" => start_at, "States" => states}) do
    with {:ok, states} <- parse_states(Map.to_list(states), []) do
      {:ok, create(start_at, states)}
    end
  end

  defp do_parse(_definition), do: {:error, "Definition requires StartAt and States fields"}

  defp parse_states([], acc), do: {:ok, Enum.into(acc, %{})}

  defp parse_states([{state_name, state_def} | states], acc) do
    with {:ok, state} <- Activity.parse(state_name, state_def) do
      parse_states(states, [{state_name, state} | acc])
    end
  end

  defp do_project(_workflow, state, []) do
    {:continue, state}
  end

  defp do_project(workflow, state, [event | events]) do
    case do_project(workflow, state, event) do
      {:continue, new_state} -> do_project(workflow, new_state, events)
      {:succeed, result} -> {:succeed, result}
    end
  end

  defp do_project(workflow, state, event) do
    with {:ok, current_activity} <- activity(workflow, state.activity) do
      case State.project(state, current_activity, event) do
        {:stay, new_state} ->
          {:continue, new_state}

        {:transition, {:next, activity_name}, args} ->
          with {:ok, new_activity} <- activity(workflow, activity_name) do
            new_state = State.create(new_activity, args)
            {:continue, new_state}
          end

        {:transition, :end, result} ->
          {:succeed, result}

        {:succeed, result} ->
          {:succeed, result}
      end
    end
  end
end
