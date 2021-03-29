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
  def enter(_activity, _ctx, args), do: {:ok, [Event.create({:succeed_entered, args}, [])]}

  @impl Activity
  def exit(_activity, _ctx, _args, result),
    do: {:ok, [Event.create({:succeed_exited, result}, [])]}
end
