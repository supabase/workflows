defmodule Workflows.Activity.Choice do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.ActivityUtil
  alias Workflows.Error
  alias Workflows.Event
  alias Workflows.Path
  alias Workflows.Rule

  @behaviour Activity

  @type t :: %__MODULE__{
          name: Activity.name(),
          default: Activity.name() | nil,
          choices: nonempty_list(Rule.t()),
          input_path: Path.t() | nil,
          output_path: Path.t() | nil
        }

  defstruct [:name, :default, :choices, :input_path, :output_path]

  @impl Activity
  def parse(state_name, definition) do
    with {:ok, default} <- parse_default(definition),
         {:ok, choices} <- parse_choices(definition),
         {:ok, input_path} <- ActivityUtil.parse_input_path(definition),
         {:ok, output_path} <- ActivityUtil.parse_output_path(definition) do
      state = %__MODULE__{
        name: state_name,
        default: default,
        choices: choices,
        input_path: input_path,
        output_path: output_path
      }

      {:ok, state}
    end
  end

  @impl Activity
  def enter(activity, _ctx, args) do
    event = %Event.ChoiceEntered{
      activity: activity.name,
      scope: [],
      args: args
    }

    {:ok, event}
  end

  @impl Activity
  def exit(activity, _ctx, _args, result) do
    with {:ok, transition} <- match_rule(activity, result) do
      event = %Event.ChoiceExited{
        activity: activity.name,
        scope: [],
        result: result,
        transition: transition
      }

      {:ok, event}
    end
  end

  ## Private

  defp parse_default(definition) do
    default = Map.get(definition, "Default")
    {:ok, default}
  end

  defp parse_choices(definition) do
    with {:ok, choices} <- state_choices(definition) do
      collect_state_rules(choices, [])
    end
  end

  defp state_choices(%{"Choices" => []}),
    do: state_choices(nil)

  defp state_choices(%{"Choices" => choices}) when is_list(choices) do
    {:ok, choices}
  end

  defp state_choices(_) do
    {:error, :empty_choices}
  end

  defp collect_state_rules([], acc), do: {:ok, acc}

  defp collect_state_rules([choice | choices], acc) do
    case Rule.create(choice) do
      {:ok, rule} ->
        collect_state_rules(choices, [rule | acc])

      {:error, _err} ->
        {:error, :invalid_choice_rule}
    end
  end

  defp match_rule(activity, args) do
    case Enum.find(activity.choices, fn rule -> Rule.call(rule, args) end) do
      nil ->
        default_next = activity.default

        if default_next == nil do
          error =
            Error.create("States.NoChoiceMatched", "No Choices matched and no Default specified")

          {:failure, error}
        else
          {:ok, {:next, default_next}}
        end

      rule ->
        {:ok, {:next, rule.next}}
    end
  end
end
