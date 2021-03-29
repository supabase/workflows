defmodule Workflows.State do
  @moduledoc false

  alias Workflows.Activity

  @type status ::
          {:transition_to, Activity.name()} # Activity finished and ready to transition
          | {:completed, Activity.name()} # Activity completed, need to exit
          | {:running, Activity.name()} # Activity is running
          | :succeeded # Activity succeeded, terminal
          | :failed # Activity failed, terminal

  @type t :: %__MODULE__{
               status: status(),
               args: Activity.args(),
             }

  defstruct [:status, :args]

  @spec create(status(), Activity.args()) :: t()
  def create(status, args) do
    %__MODULE__{
      status: status,
      args: args,
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
    create({:running, name}, args)
  end

  @spec succeeded(Activity.args()) :: t()
  def succeeded(args) do
    create(:succeeded, args)
  end

end
