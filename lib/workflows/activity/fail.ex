defmodule Workflows.Activity.Fail do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Event
  alias Workflows.Error
  alias Workflows.Path
  alias Workflows.ActivityUtil

  @type t :: %__MODULE__{
               name: State.state_name(),
               error: String.t(),
               cause: String.t(),
             }

  defstruct [:name, :error, :cause]

  @impl Activity
  def parse(state_name, definition) do
    with {:ok, error} <- parse_error(definition),
         {:ok, cause} <- parse_cause(definition) do
      state = %__MODULE__{
        name: state_name,
        error: error,
        cause: cause,
      }
      {:ok, state}
    end
  end

  @impl Activity
  def enter(activity, _ctx, args) do
    event = %Event.FailEntered{
      activity: activity.name,
      scope: [],
      args: args
    }

    {:ok, event}
  end

  @impl Activity
  def exit(activity, _ctx, _args, result) do
    error = Error.create(activity.error, activity.cause)
    event = %Event.FailExited{
      activity: activity.name,
      scope: [],
      error: error,
    }

    {:ok, event}
  end

  ## Private

  defp parse_error(%{"Error" => error}), do: {:ok, error}
  defp parse_error(_definition), do: {:error, :missing_error}

  defp parse_cause(%{"Cause" => cause}), do: {:ok, cause}
  defp parse_cause(_definition), do: {:error, :missing_cause}

end
