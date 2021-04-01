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

  alias Workflows.Execution

  @type event :: any()

  @type t :: struct()

  @type maybe :: :no_event | t()

  defstruct [:event, :scope]

  @spec create(event(), Execution.scope()) :: t()
  def create(event, scope) do
    %__MODULE__{
      event: event,
      scope: scope
    }
  end

  def push_scope(event, scope) do
    Map.update(event, :scope, [], fn existing_scope -> [scope | existing_scope] end)
  end

  def pop_scope(event) do
    Map.get_and_update(event, :scope, fn
      [] -> {nil, []}
      [current | scope] -> {current, scope}
    end)
  end
end
