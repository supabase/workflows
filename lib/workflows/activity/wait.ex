defmodule Workflows.Activity.Wait do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.ActivityUtil
  alias Workflows.Event
  alias Workflows.Path
  alias Workflows.ReferencePath

  @behaviour Activity

  @type wait ::
          {:seconds, pos_integer()}
          | {:seconds_path, Path.t()}
          | {:timestamp, DateTime.t()}
          | {:timestamp_path, Path.t()}

  @type t :: %__MODULE__{
          name: Activity.name(),
          wait: wait(),
          transition: Activity.transition(),
          input_path: Path.t() | nil,
          output_path: Path.t() | nil
        }

  @seconds "Seconds"
  @seconds_path "SecondsPath"
  @timestamp "Timestamp"
  @timestamp_path "TimestampPath"

  defstruct [:name, :wait, :transition, :input_path, :output_path]

  @impl Activity
  def parse(activity_name, definition) do
    with {:ok, wait} <- parse_wait(definition),
         {:ok, transition} <- ActivityUtil.parse_transition(definition),
         {:ok, input_path} <- ActivityUtil.parse_input_path(definition),
         {:ok, output_path} <- ActivityUtil.parse_output_path(definition) do
      state = %__MODULE__{
        name: activity_name,
        wait: wait,
        transition: transition,
        input_path: input_path,
        output_path: output_path
      }

      {:ok, state}
    end
  end

  @impl Activity
  def enter(activity, _ctx, args) do
    with {:ok, effective_args} <- ActivityUtil.apply_input_path(activity, args) do
      event = %Event.WaitEntered{
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
      event = %Event.WaitExited{
        activity: activity.name,
        scope: [],
        result: effective_result,
        transition: activity.transition
      }

      {:ok, event}
    end
  end

  def start_wait(activity, _ctx, args) do
    with {:ok, wait} <- resolve_wait(activity.wait, args) do
      event = %Event.WaitStarted{
        activity: activity.name,
        scope: [],
        wait: wait
      }

      {:ok, event}
    end
  end

  def finish_waiting(activity, _ctx) do
    event = %Event.WaitSucceeded{
      activity: activity.name,
      scope: []
    }

    {:ok, event}
  end

  ## Private

  defp parse_wait(%{"Seconds" => seconds} = state) do
    with :ok <- validate_no_extra_keys(state, [@seconds_path, @timestamp, @timestamp_path]) do
      if is_integer(seconds) and seconds > 0 do
        {:ok, {:seconds, seconds}}
      else
        {:error, :invalid_seconds}
      end
    end
  end

  defp parse_wait(%{"SecondsPath" => seconds_path} = state) do
    with :ok <- validate_no_extra_keys(state, [@seconds, @timestamp, @timestamp_path]),
         {:ok, seconds} <- ReferencePath.create(seconds_path) do
      {:ok, {:seconds_path, seconds}}
    end
  end

  defp parse_wait(%{"Timestamp" => timestamp} = state) do
    with :ok <- validate_no_extra_keys(state, [@seconds, @seconds_path, @timestamp_path]),
         {:ok, timestamp, _} <- DateTime.from_iso8601(timestamp) do
      {:ok, {:timestamp, timestamp}}
    end
  end

  defp parse_wait(%{"TimestampPath" => timestamp_path} = state) do
    with :ok <- validate_no_extra_keys(state, [@seconds, @seconds_path, @timestamp]),
         {:ok, timestamp} <- ReferencePath.create(timestamp_path) do
      {:ok, {:timestamp_path, timestamp}}
    end
  end

  defp parse_wait(_state) do
    {:error, :missing_fields}
  end

  defp validate_no_extra_keys(state, other_keys) do
    if state_has_keys(state, other_keys) do
      {:error, :invalid_fields}
    end

    :ok
  end

  defp state_has_keys(state, keys) do
    Enum.any?(keys, fn key -> Map.has_key?(state, key) end)
  end

  defp resolve_wait({:seconds_path, path}, args) do
    with {:ok, seconds} <- ReferencePath.query(path, args) do
      {:ok, {:seconds, seconds}}
    end
  end

  defp resolve_wait({:timestamp_path, path}, args) do
    with {:ok, timestamp} <- ReferencePath.query(path, args) do
      {:ok, {:timestamp, timestamp}}
    end
  end

  defp resolve_wait(wait, _args), do: {:ok, wait}
end
