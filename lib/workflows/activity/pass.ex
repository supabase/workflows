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
  def enter(activity, ctx, args) do
    with {:ok, args} <- ActivityUtil.apply_input_path(activity, args),
         {:ok, effective_args} <- ActivityUtil.apply_parameters(activity, ctx, args) do
      event = %Event.PassEntered{
        activity: activity.name,
        scope: [],
        args: effective_args
      }

      {:ok, event}
    end
  end

  @impl Activity
  def exit(activity, ctx, args, result) do
    with {:ok, result} <- ActivityUtil.apply_result_path(activity, ctx, result, args),
         {:ok, effective_result} <- ActivityUtil.apply_output_path(activity, result) do
      event = %Event.PassExited{
        activity: activity.name,
        scope: [],
        result: effective_result,
        transition: activity.transition
      }

      {:ok, event}
    end
  end

  ## Private

  defp parse_result(definition) do
    Map.get(definition, "Result", nil)
  end
end
