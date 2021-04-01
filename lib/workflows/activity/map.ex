defmodule Workflows.Activity.Map do
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
          name: State.state_name(),
          iterator: Machine.t(),
          items_path: ReferencePath.t() | nil,
          max_concurrency: non_neg_integer(),
          transition: State.transition(),
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
    :iterator,
    :items_path,
    :max_concurrency,
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
    with {:ok, iterator} <- parse_iterator(definition),
         {:ok, items_path} <- parse_items_path(definition),
         {:ok, max_concurrency} <- parse_max_concurrency(definition),
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
        iterator: iterator,
        items_path: items_path,
        max_concurrency: max_concurrency,
        transition: transition,
        input_path: input_path,
        output_path: output_path,
        result_path: result_path,
        parameters: parameters,
        result_selector: result_selector,
        catch: catch_
      }

      {:ok, state}
    end
  end

  @impl Activity
  def enter(activity, _ctx, args) do
    event = %Event.MapEntered{
      activity: activity.name,
      scope: [],
      args: args
    }

    {:ok, event}
  end

  @impl Activity
  def exit(activity, _ctx, _args, result) do
    event = %Event.MapExited{
      activity: activity.name,
      scope: [],
      result: result,
      transition: activity.transition
    }

    {:ok, event}
  end

  def start_map(activity, _ctx, args) do
    event = %Event.MapStarted{
      activity: activity.name,
      scope: [],
      args: args
    }

    {:ok, event}
  end

  def complete_map(activity, _ctx, result) do
    event = %Event.MapSucceeded{
      activity: activity.name,
      scope: [],
      result: result
    }

    {:ok, event}
  end

  ## Private

  defp parse_iterator(%{"Iterator" => iterator}) do
    Workflow.parse(iterator)
  end

  defp parse_iterator(_definition), do: {:error, :missing_iterator}

  defp parse_items_path(%{"ItemsPath" => path}) do
    ReferencePath.create(path)
  end

  defp parse_items_path(_definition) do
    # The default value of "ItemsPath" is "$", which is to say the whole effective input.
    ReferencePath.create("$")
  end

  defp parse_max_concurrency(%{"MaxConcurrency" => concurrency}) do
    if is_integer(concurrency) and concurrency >= 0 do
      {:ok, concurrency}
    else
      {:error, :invalid_max_concurrency}
    end
  end

  defp parse_max_concurrency(_definition), do: {:ok, 0}
end
