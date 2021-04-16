defmodule Workflows.Activity.Task do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.ActivityUtil
  alias Workflows.Catcher
  alias Workflows.Event
  alias Workflows.Path
  alias Workflows.PayloadTemplate
  alias Workflows.ReferencePath
  alias Workflows.Retrier

  @behaviour Activity

  @type t :: %__MODULE__{
          name: Activity.name(),
          resource: String.t(),
          timeout: {:value, pos_integer()} | {:reference, ReferencePath.t()} | nil,
          heartbeat: {:value, pos_integer()} | {:reference, ReferencePath.t()} | nil,
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
    :resource,
    :timeout,
    :heartbeat,
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
    with {:ok, resource} <- parse_resource(definition),
         {:ok, timeout} <- parse_timeout(definition),
         {:ok, heartbeat} <- parse_heartbeat(definition),
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
        resource: resource,
        timeout: timeout,
        heartbeat: heartbeat,
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
      event = %Event.TaskEntered{
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
      event = %Event.TaskExited{
        activity: activity.name,
        scope: [],
        result: effective_result,
        transition: activity.transition
      }

      {:ok, event}
    end
  end

  def start_task(activity, _ctx, args) do
    event = %Event.TaskStarted{
      activity: activity.name,
      scope: [],
      resource: activity.resource,
      args: args
    }

    {:ok, event}
  end

  def complete_task(activity, _ctx, result) do
    event = %Event.TaskSucceeded{
      activity: activity.name,
      scope: [],
      result: result
    }

    {:ok, event}
  end

  def retry_task(activity, _ctx, args, error, retry_count) do
    event = %Event.TaskRetried{
      activity: activity.name,
      scope: [],
      resource: activity.resource,
      args: args,
      error: error,
      retry_count: retry_count,
    }

    {:ok, event}
  end

  def fail_task(activity, _ctx, error) do
    event = %Event.TaskFailed{
      activity: activity.name,
      scope: [],
      error: error,
    }

    {:ok, event}
  end

  ## Private

  defp parse_resource(%{"Resource" => resource}) do
    if resource == nil do
      {:error, :missing_resource}
    else
      {:ok, resource}
    end
  end

  defp parse_resource(_definition), do: {:error, "Must have Resource"}

  defp parse_timeout(%{"TimeoutSeconds" => _, "TimeoutSecondsPath" => _}) do
    {:error, :multiple_timeout}
  end

  defp parse_timeout(%{"TimeoutSeconds" => seconds}) do
    if is_integer(seconds) and seconds > 0 do
      {:ok, {:value, seconds}}
    else
      {:error, :invalid_timeout}
    end
  end

  defp parse_timeout(%{"TimeoutSecondsPath" => path}) do
    with {:ok, path} <- ReferencePath.create(path) do
      {:ok, {:reference, path}}
    end
  end

  defp parse_timeout(_definition), do: {:ok, nil}

  defp parse_heartbeat(%{"HeartbeatSeconds" => _, "HeartbeatSecondsPath" => _}) do
    {:error, :multiple_heartbeat}
  end

  defp parse_heartbeat(%{"HeartbeatSeconds" => seconds}) do
    if is_integer(seconds) and seconds > 0 do
      {:ok, {:value, seconds}}
    else
      {:error, :invalid_heartbeat}
    end
  end

  defp parse_heartbeat(%{"HeartbeatSecondsPath" => path}) do
    with {:ok, path} <- ReferencePath.create(path) do
      {:ok, {:reference, path}}
    end
  end

  defp parse_heartbeat(_definition), do: {:ok, nil}
end
