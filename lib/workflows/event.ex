defmodule Workflows.Event do
  @moduledoc """

  ## Workflow Execution

  * ExecutionStarted
  * ExecutionFailed
  * ExecutionSucceeded

  ## Activities

  * ChoiceEntered
  * ChoiceExited

  * PassEntered
  * PassExited

  * SucceedEntered
  * SucceedExited

  * FailEntered
  * FailExited

  * ParallelEntered
  * ParallelStarted
  * ParallelFailed
  * ParallelSucceeded
  * ParallelExited

  * MapEntered
  * MapStarted
  * MapIterationStarted
  * MapIterationFailed
  * MapIterationSucceeded
  * MapFailed
  * MapSucceed
  * MapExited

  * WaitEntered
  * WaitStarted
  * WaitFailed
  * WaitSucceeded
  * WaitExited

  * TaskEntered
  * TaskStarted
  * TaskFailed
  * TaskSucceeded
  * TaskExited
  """

  alias Workflows.Activity
  alias Workflows.Execution

  @type event ::
          {:execution_started, Activity.args()}
          | {:execution_succeeded, Activity.args()}
          | {:parallel_entered, Activity.args()}
          | :parallel_started
          | {:parallel_succeeded, Activity.args()}
          | {:parallel_exited, Activity.args()}
          | {:pass_entered, Activity.args()}
          | {:pass_exited, Activity.args()}
          | {:succeed_entered, Activity.args()}
          | {:succeed_exited, Activity.args()}
          | {:wait_entered, Activity.args()}
          | {:wait_exited, Activity.args()}
          | {:wait_started, Activity.Wait.wait()}
          | :wait_succeeded

  @type t :: %__MODULE__{
          event: event(),
          scope: Execution.scope()
        }

  defstruct [:event, :scope]

  @spec create(event(), Execution.scope()) :: t()
  def create(event, scope) do
    %__MODULE__{
      event: event,
      scope: scope
    }
  end

  def with_scope(event, scope) do
    %__MODULE__{event | scope: scope}
  end

  @spec execution_started(Activity.args()) :: t()
  def execution_started(args) do
    create({:execution_started, args}, [])
  end

  @spec execution_succeeded(Activity.args()) :: t()
  def execution_succeeded(args) do
    create({:execution_succeeded, args}, [])
  end
end
