defmodule Workflows.StateUtil do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.State

  def create(activity, args) do
    do_create(activity, args)
  end

  def execute(state, activity, ctx) do
    do_execute(state, activity, ctx)
  end

  def execute(state, activity, ctx, cmd) do
    do_execute_command(state, activity, ctx, cmd)
  end

  def project(state, activity, event) do
    do_project(state, activity, event)
  end

  ## Private

  defp do_create(%Activity.Choice{} = activity, ctx) do
    State.Choice.create(activity, ctx)
  end

  defp do_execute(%State.Choice{} = state, activity, ctx) do
    State.Choice.execute(state, activity, ctx)
  end

  defp do_project(%State.Choice{} = state, activity, event) do
    State.Choice.project(state, activity, event)
  end

  defp do_create(%Activity.Fail{} = activity, ctx) do
    State.Fail.create(activity, ctx)
  end

  defp do_execute(%State.Fail{} = state, activity, ctx) do
    State.Fail.execute(state, activity, ctx)
  end

  defp do_project(%State.Fail{} = state, activity, event) do
    State.Fail.project(state, activity, event)
  end

  defp do_create(%Activity.Pass{} = activity, ctx) do
    State.Pass.create(activity, ctx)
  end

  defp do_execute(%State.Pass{} = state, activity, ctx) do
    State.Pass.execute(state, activity, ctx)
  end

  defp do_project(%State.Pass{} = state, activity, event) do
    State.Pass.project(state, activity, event)
  end

  defp do_create(%Activity.Parallel{} = activity, ctx) do
    State.Parallel.create(activity, ctx)
  end

  defp do_execute(%State.Parallel{} = state, activity, ctx) do
    State.Parallel.execute(state, activity, ctx)
  end

  defp do_project(%State.Parallel{} = state, activity, event) do
    State.Parallel.project(state, activity, event)
  end

  defp do_create(%Activity.Succeed{} = activity, ctx) do
    State.Succeed.create(activity, ctx)
  end

  defp do_execute(%State.Succeed{} = state, activity, ctx) do
    State.Succeed.execute(state, activity, ctx)
  end

  defp do_project(%State.Succeed{} = state, activity, event) do
    State.Succeed.project(state, activity, event)
  end

  defp do_create(%Activity.Task{} = activity, ctx) do
    State.Task.create(activity, ctx)
  end

  defp do_execute(%State.Task{} = state, activity, ctx) do
    State.Task.execute(state, activity, ctx)
  end

  defp do_project(%State.Task{} = state, activity, event) do
    State.Task.project(state, activity, event)
  end

  defp do_create(%Activity.Wait{} = activity, ctx) do
    State.Wait.create(activity, ctx)
  end

  defp do_execute(%State.Wait{} = state, activity, ctx) do
    State.Wait.execute(state, activity, ctx)
  end

  defp do_project(%State.Wait{} = state, activity, event) do
    State.Wait.project(state, activity, event)
  end

  defp do_execute_command(%State.Parallel{} = state, activity, ctx, cmd) do
    State.Parallel.execute(state, activity, ctx, cmd)
  end

  defp do_execute_command(%State.Task{} = state, activity, ctx, cmd) do
    State.Task.execute(state, activity, ctx, cmd)
  end

  defp do_execute_command(%State.Wait{} = state, activity, ctx, cmd) do
    State.Wait.execute(state, activity, ctx, cmd)
  end

  defp do_execute_command(_state, _activity, _ctx, cmd) do
    {:error, :invalid_command, cmd}
  end
end
