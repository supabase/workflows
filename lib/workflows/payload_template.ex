defmodule Workflows.PayloadTemplate do
  @moduledoc """
  A PayloadTemplate is used to create new Json objects by combining other objects.
  """
  alias Workflows.Activity
  alias Workflows.Intrinsic

  @opaque t :: %__MODULE__{
            template: map()
          }

  defstruct [:template]

  @doc """
  Create a payload template.
  """
  @spec create(map()) :: {:ok, t()} | {:error, term()}
  def create(template) when is_map(template) do
    # TODO: validate payload template
    {:ok, %__MODULE__{template: template}}
  end

  def create(_template) do
    {:error, :invalid_template}
  end

  @doc """
  Apply payload template to arguments, returning a new, transformed output.
  """
  @spec apply(t() | nil, Activity.ctx(), Activity.args()) ::
          {:ok, Activity.args()} | {:error, term()}
  def apply(%__MODULE__{template: template}, ctx, args) do
    do_apply(template, ctx, args, [])
  end

  def apply(nil, _ctx, args) do
    {:ok, args}
  end

  ## Private

  defp do_apply(template, ctx, args, acc) when is_map(template) do
    template
    |> Map.to_list()
    |> do_apply(ctx, args, acc)
  end

  defp do_apply([{key, value} | template], ctx, args, acc) when is_map(value) do
    with {:ok, value} <- do_apply(value, ctx, args, []) do
      do_apply(template, ctx, args, [{key, value} | acc])
    end
  end

  defp do_apply([], _ctx, _args, acc) do
    {:ok, Map.new(acc)}
  end

  defp do_apply([{key, value} | template], ctx, args, acc) do
    if String.ends_with?(key, ".$") do
      with {:ok, value} <- transform_value(value, ctx, args) do
        # remove .$
        key = String.slice(key, 0..-3)
        do_apply(template, ctx, args, [{key, value} | acc])
      end
    else
      do_apply(template, ctx, args, [{key, value} | acc])
    end
  end

  defp transform_value(value, ctx, args) do
    cond do
      String.starts_with?(value, "$$") ->
        # JsonPath applied to ctx
        # remove extra $
        value = String.slice(value, 1..-1)
        apply_path(ctx, value)

      String.starts_with?(value, "$") ->
        # JsonPath applied to args
        apply_path(args, value)

      true ->
        # Intrinsic function
        Intrinsic.apply(value, ctx, args)
    end
  end

  defp apply_path(args, path) do
    case Warpath.query(args, path, result_type: :value_path) do
      {:ok, {nil, ""}} ->
        {:error, "States.ParameterPathFailure"}

      {:ok, {value, _}} ->
        {:ok, value}

      {:ok, values} when is_list(values) ->
        has_unmatched? =
          Enum.any?(values, fn
            {_, ""} -> true
            _ -> false
          end)

        if has_unmatched? do
          {:error, "States.ParameterPathFailure"}
        else
          values = Enum.map(values, fn {value, _} -> value end)
          {:ok, values}
        end

      {:error, _} ->
        {:error, "Invalid JsonPath"}
    end
  end
end
