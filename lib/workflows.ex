defmodule Workflows do
  @external_resource readme = Path.join([__DIR__, "../README.md"])

  @moduledoc readme
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  alias Workflows.{Activity, Command, Execution, State, Workflow}

  @doc """
  Parses a workflow definition.

  A workflow is defined by a map-like structure that conforms to the
  [Amazon States Language](https://states-language.net/) specification.

  ## Examples

      iex> {:ok, wf} = Workflows.parse(%{
      ...>   "Comment" => "A simple example",
      ...>   "StartAt" => "Hello World",
      ...>   "States" => %{
      ...>     "Hello World" => %{
      ...>       "Type" => "Task",
      ...>       "Resource" => "do-something",
      ...>       "End" => true
      ...>     }
      ...>   }
      ...> })
      iex> wf.start_at
      "Hello World"

  """
  @spec parse(map()) :: {:ok, Workflow.t()} | {:error, term()}
  def parse(definition), do: Workflow.parse(definition)

  @doc """
  Starts a `workflow` execution with the given `ctx` and `args`.
  """
  @spec start(Workflow.t(), Activity.ctx(), Activity.args()) ::
          Execution.execution_result() | {:error, term()}
  def start(workflow, ctx, args), do: Execution.start(workflow, ctx, args)

  @doc """
  Resumes a `workflow` waiting for `cmd` to continue.
  """
  @spec resume(Workflow.t(), State.t(), Activity.ctx(), Command.t()) ::
          Execution.execution_result() | {:error, term()}
  def resume(workflow, state, ctx, cmd), do: Execution.resume(workflow, state, ctx, cmd)
end
