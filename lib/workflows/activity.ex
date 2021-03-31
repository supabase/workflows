defmodule Workflows.Activity do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Event

  @type ctx :: any()
  @type args :: any()
  @type name :: String.t()
  @type transition :: {:next, name()} | :end

  @type t :: any()

  @callback parse(name(), map()) :: {:ok, t()} | {:error, term()}
  @callback enter(t(), ctx(), args()) :: {:ok, Event.t()} | {:error, term()}
  @callback exit(t(), ctx(), args(), args()) :: {:ok, Event.t()} | {:error, term()}

  @spec parse(name(), map()) :: {:ok, t()} | {:error, term()}
  def parse(name, state), do: do_parse(name, state)

  @spec enter(t(), ctx(), args()) :: {:ok, Event.t()} | {:error, term()}
  def enter(activity, ctx, args), do: do_enter(activity, ctx, args)

  @spec exit(t(), ctx(), args(), args()) :: {:ok, Event.t()} | {:error, term()}
  def exit(activity, ctx, args, result), do: do_exit(activity, ctx, args, result)

  ## Private

  defp do_parse(name, %{"Type" => "Choice"} = state),
    do: Activity.Choice.parse(name, state)

  defp do_parse(name, %{"Type" => "Parallel"} = state),
    do: Activity.Parallel.parse(name, state)

  defp do_parse(name, %{"Type" => "Pass"} = state),
    do: Activity.Pass.parse(name, state)

  defp do_parse(name, %{"Type" => "Succeed"} = state),
    do: Activity.Succeed.parse(name, state)

  defp do_parse(name, %{"Type" => "Task"} = state),
    do: Activity.Task.parse(name, state)

  defp do_parse(name, %{"Type" => "Wait"} = state),
    do: Activity.Wait.parse(name, state)

  defp do_parse(name, state) do
    {:error, :parse, name, state}
  end

  defp do_enter(%Activity.Choice{} = activity, ctx, args) do
    Activity.Choice.enter(activity, ctx, args)
  end

  defp do_exit(%Activity.Choice{} = activity, ctx, args, result) do
    Activity.Choice.exit(activity, ctx, args, result)
  end

  defp do_enter(%Activity.Pass{} = activity, ctx, args) do
    Activity.Pass.enter(activity, ctx, args)
  end

  defp do_exit(%Activity.Pass{} = activity, ctx, args, result) do
    Activity.Pass.exit(activity, ctx, args, result)
  end

  defp do_enter(%Activity.Parallel{} = activity, ctx, args) do
    Activity.Parallel.enter(activity, ctx, args)
  end

  defp do_exit(%Activity.Parallel{} = activity, ctx, args, result) do
    Activity.Parallel.exit(activity, ctx, args, result)
  end

  defp do_enter(%Activity.Succeed{} = activity, ctx, args) do
    Activity.Succeed.enter(activity, ctx, args)
  end

  defp do_exit(%Activity.Succeed{} = activity, ctx, args, result) do
    Activity.Succeed.exit(activity, ctx, args, result)
  end

  defp do_enter(%Activity.Task{} = activity, ctx, args) do
    Activity.Task.enter(activity, ctx, args)
  end

  defp do_exit(%Activity.Task{} = activity, ctx, args, result) do
    Activity.Task.exit(activity, ctx, args, result)
  end

  defp do_enter(%Activity.Wait{} = activity, ctx, args) do
    Activity.Wait.enter(activity, ctx, args)
  end

  defp do_exit(%Activity.Wait{} = activity, ctx, args, result) do
    Activity.Wait.exit(activity, ctx, args, result)
  end
end
