defmodule Workflows.Activity.Parallel do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.ActivityUtil
  alias Workflows.Catcher
  alias Workflows.Event
  alias Workflows.Path
  alias Workflows.ReferencePath
  alias Workflows.PayloadTemplate
  alias Workflows.Retrier
  alias Workflows.Workflow

  @behaviour Activity

  @type t :: %__MODULE__{
          name: Activity.name(),
          branches: nonempty_list(Workflow.t()),
          transition: Activity.transition(),
          input_path: Path.t() | nil,
          output_path: Path.t() | nil,
          result_path: ReferencePath.t() | nil,
          parameters: PayloadTemplate.t() | nil,
          result_selector: PayloadTemplate.t() | nil,
          retry: list(Retrier.t()),
          catch: list(Catcher.t())
        }

  defstruct [
    :name,
    :branches,
    :transition,
    :input_path,
    :output_path,
    :result_path,
    :parameters,
    :result_selector,
    :retry,
    :catch
  ]

  @impl Activity
  def parse(state_name, definition) do
    with {:ok, branches} <- parse_branches(definition),
         {:ok, transition} <- ActivityUtil.parse_transition(definition),
         {:ok, input_path} <- ActivityUtil.parse_input_path(definition),
         {:ok, output_path} <- ActivityUtil.parse_output_path(definition),
         {:ok, result_path} <- ActivityUtil.parse_result_path(definition),
         {:ok, parameters} <- ActivityUtil.parse_parameters(definition),
         {:ok, result_selector} <- ActivityUtil.parse_result_selector(definition),
         {:ok, retry} <- ActivityUtil.parse_retry(definition),
         {:ok, catch_} <- ActivityUtil.parse_catch(definition) do
      state = %__MODULE__{
        name: state_name,
        branches: branches,
        transition: transition,
        input_path: input_path,
        output_path: output_path,
        result_path: result_path,
        parameters: parameters,
        result_selector: result_selector,
        retry: retry,
        catch: catch_
      }

      {:ok, state}
    end
  end

  @impl Activity
  def enter(activity, ctx, args) do
    with {:ok, args} <- ActivityUtil.apply_input_path(activity, args),
         {:ok, effective_args} <- ActivityUtil.apply_parameters(activity, ctx, args) do
      event = %Event.ParallelEntered{
        activity: activity.name,
        scope: [],
        args: effective_args
      }

      {:ok, event}
    end
  end

  @impl Activity
  def exit(activity, ctx, args, result) do
    with {:ok, result} <- ActivityUtil.apply_result_selector(activity, ctx, result),
         {:ok, result} <- ActivityUtil.apply_result_path(activity, ctx, result, args),
         {:ok, effective_result} <- ActivityUtil.apply_output_path(activity, result) do
      event = %Event.ParallelExited{
        activity: activity.name,
        scope: [],
        result: effective_result,
        transition: activity.transition
      }

      {:ok, event}
    end
  end

  def start_parallel(activity, _ctx, args) do
    event = %Event.ParallelStarted{
      activity: activity.name,
      scope: [],
      args: args
    }

    {:ok, event}
  end

  def complete_parallel(activity, _ctx, result) do
    event = %Event.ParallelSucceeded{
      activity: activity.name,
      scope: [],
      result: result
    }

    {:ok, event}
  end

  ## Private

  defp parse_branches(%{"Branches" => branches}) when is_list(branches) do
    collect_branches(branches, [])
  end

  defp parse_branches(_definition), do: {:error, :empty_branches}

  defp collect_branches([], acc), do: {:ok, Enum.reverse(acc)}

  defp collect_branches([branch | branches], acc) do
    with {:ok, branch} <- Workflow.parse(branch) do
      collect_branches(branches, [branch | acc])
    end
  end
end
