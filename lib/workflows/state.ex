defmodule Workflows.State do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Event
  alias Workflows.StateUtil

  @opaque t :: any()

  @callback project(state :: t(), event :: Event.t()) ::
              {:stay, state :: t()} | {:transition, Activity.name(), Activity.args()}

  def create(activity, args) do
    StateUtil.create(activity, args)
  end

  def execute(state, activity, ctx) do
    StateUtil.execute(state, activity, ctx)
  end

  def execute(state, activity, ctx, cmd) do
    StateUtil.execute(state, activity, ctx, cmd)
  end

  def project(state, activity, event) do
    StateUtil.project(state, activity, event)
  end

  defmacro __using__(_opts) do
    quote location: :keep do
      defstruct [:activity, :inner]

      alias Workflows.State

      @behaviour State

      def create(activity, state_args) do
        %__MODULE__{
          activity: activity.name,
          inner: {:before_enter, state_args}
        }
      end
    end
  end
end
