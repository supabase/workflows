defmodule Workflows.Command do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Event
  alias Workflows.Execution

  @type t :: any()

  def pop_scope(command) do
    Map.get_and_update(command, :scope, fn
      [] -> {nil, []}
      [current | scope] -> {current, scope}
    end)
  end

  def finish_waiting(%Event.WaitStarted{} = event) do
    %Workflows.Command.FinishWaiting{
      activity: event.activity,
      scope: event.scope
    }
  end
end
