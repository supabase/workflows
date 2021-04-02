defmodule Workflows.Activity.Succeed do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Event
  alias Workflows.Path
  alias Workflows.ActivityUtil

  @behaviour Activity

  @type t :: %__MODULE__{
          name: Activity.name(),
          input_path: Path.t() | nil,
          output_path: Path.t() | nil
        }

  defstruct [:name, :input_path, :output_path]

  @impl Activity
  def parse(state_name, definition) do
    with {:ok, input_path} <- ActivityUtil.parse_input_path(definition),
         {:ok, output_path} <- ActivityUtil.parse_output_path(definition) do
      state = %__MODULE__{
        name: state_name,
        input_path: input_path,
        output_path: output_path
      }

      {:ok, state}
    end
  end

  @impl Activity
  def enter(activity, _ctx, args) do
    with {:ok, effective_args} <- ActivityUtil.apply_input_path(activity, args) do
      event = %Event.SucceedEntered{
        activity: activity.name,
        scope: [],
        args: effective_args
      }

      {:ok, event}
    end
  end

  @impl Activity
  def exit(activity, _ctx, _args, result) do
    with {:ok, effective_result} <- ActivityUtil.apply_output_path(activity, result) do
      event = %Event.SucceedExited{
        activity: activity.name,
        scope: [],
        result: effective_result
      }

      {:ok, event}
    end
  end
end
