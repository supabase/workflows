defmodule Workflows.State do
  @moduledoc false

  alias Workflows.{Activity, Command, Error, Event, State, StateUtil}

  @type t ::
          State.Choice.t()
          | State.Fail.t()
          | State.Map.t()
          | State.Parallel.t()
          | State.Pass.t()
          | State.Succeed.t()
          | State.Task.t()
          | State.Wait.t()

  @callback project(state :: t(), activity :: Activity.t(), event :: Event.t()) ::
              {:stay, state :: t()} | {:transition, Activity.name(), Activity.args()}

  @type execute_result :: {:ok, Event.maybe()} | {:error, term()}
  @type execute_command_result :: {:ok, Event.t()} | {:error, term()}

  @type project_result ::
          {:stay, t()}
          | {:transition, Activity.transition(), Activity.args()}
          | {:succeed, Activity.args()}
	  | {:fail, Error.t()}

  @spec create(Activity.t(), Activity.args()) :: t()
  def create(activity, args) do
    StateUtil.create(activity, args)
  end

  @spec execute(t(), Activity.t(), Activity.ctx()) :: execute_result()
  def execute(state, activity, ctx) do
    StateUtil.execute(state, activity, ctx)
  end

  @spec execute(t(), Activity.t(), Activity.ctx(), Command.t()) :: execute_command_result()
  def execute(state, activity, ctx, cmd) do
    StateUtil.execute(state, activity, ctx, cmd)
  end

  @spec project(t(), Activity.t(), Event.t()) :: project_result()
  def project(state, activity, event) do
    StateUtil.project(state, activity, event)
  end

  defmacro __using__(_opts) do
    quote location: :keep do
      defstruct [:activity, :inner]

      alias Workflows.Activity
      alias Workflows.State

      @behaviour State

      @type t :: %__MODULE__{
              activity: String.t(),
              inner: term()
            }

      @spec create(Activity.t(), Activity.args()) :: t()
      def create(activity, state_args) do
        %__MODULE__{
          activity: activity.name,
          inner: {:before_enter, state_args}
        }
      end
    end
  end
end
