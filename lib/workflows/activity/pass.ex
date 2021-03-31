defmodule Workflows.Activity.Pass do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.ActivityUtil
  alias Workflows.Event
  alias Workflows.Path
  alias Workflows.ReferencePath
  alias Workflows.PayloadTemplate

  @behaviour Activity

  @type t :: %__MODULE__{
          name: Activity.name(),
          result: Activity.args(),
          transition: Activity.transition(),
          input_path: Path.t() | nil,
          output_path: Path.t() | nil,
          result_path: ReferencePath.t() | nil,
          parameters: PayloadTemplate.t() | nil
        }

  defstruct [:name, :result, :transition, :input_path, :output_path, :result_path, :parameters]

  @impl Activity
  def parse(state_name, definition) do
    result = parse_result(definition)

    with {:ok, transition} <- ActivityUtil.parse_transition(definition),
         {:ok, input_path} <- ActivityUtil.parse_input_path(definition),
         {:ok, output_path} <- ActivityUtil.parse_output_path(definition),
         {:ok, result_path} <- ActivityUtil.parse_result_path(definition),
         {:ok, parameters} <- ActivityUtil.parse_parameters(definition) do
      state = %__MODULE__{
        name: state_name,
        result: result,
        transition: transition,
        input_path: input_path,
        output_path: output_path,
        result_path: result_path,
        parameters: parameters
      }

      {:ok, state}
    end
  end

  @impl Activity
  def enter(activity, _ctx, args) do
    event = %Event.PassEntered{
      activity: activity.name,
      scope: [],
      args: args
    }

    {:ok, event}
  end

  @impl Activity
  def exit(activity, _ctx, _args, result) do
    event = %Event.PassExited{
      activity: activity.name,
      scope: [],
      result: result,
      transition: activity.transition
    }

    {:ok, event}
  end

  ## Private

  defp parse_result(definition) do
    Map.get(definition, "Result", nil)
  end
end
