defmodule Workflows.State do
  @moduledoc false

  alias Workflows.Activity

  # Activity finished and ready to transition
  @type status ::
          {:transition_to, Activity.name()}
          # Activity completed, need to exit
          | {:completed, Activity.name()}
          # Activity is running
          | {:running, Activity.name(), children :: list(status())}
          # Activity succeeded, terminal
          | :succeeded
          # Activity failed, terminal
          | :failed

  @type t :: %__MODULE__{
          status: status(),
          args: Activity.args()
        }

  defstruct [:status, :args]

  @spec create(status(), Activity.args()) :: t()
  def create(status, args) do
    %__MODULE__{
      status: status,
      args: args
    }
  end

  @spec transition_to(Activity.name(), Activity.args()) :: t()
  def transition_to(name, args) do
    create({:transition_to, name}, args)
  end

  @spec completed(Activity.name(), Activity.args()) :: t()
  def completed(name, args) do
    create({:completed, name}, args)
  end

  @spec running(Activity.name(), Activity.args()) :: t()
  def running(name, args) do
    running(name, [], args)
  end

  @spec running(Activity.name(), list(status()), Activity.args()) :: t()
  def running(name, children, args) do
    create({:running, name, children}, args)
  end

  @spec succeeded(Activity.args()) :: t()
  def succeeded(args) do
    create(:succeeded, args)
  end
end
