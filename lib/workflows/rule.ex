defmodule Workflows.Rule do
  @moduledoc """
  Choice state rule.
  """

  @type t :: %__MODULE__{
          next: String.t(),
          rule: (map() -> boolean())
        }

  defstruct [:next, :rule]

  @doc """
  Create a rule that can be matched on an input.
  """
  def create(%{"Next" => next} = rule) do
    case do_create(rule) do
      {:ok, rule} ->
        {:ok, %__MODULE__{next: next, rule: rule}}

      err ->
        err
    end
  end

  def create(_rule) do
    {:error, :missing_next}
  end

  def call(%__MODULE__{rule: rule}, args) do
    rule.(args)
  end

  ## Private

  defp do_create(%{"Not" => inner_case}) do
    with {:ok, inner_rule} <- do_create(inner_case) do
      rule = fn args ->
        not inner_rule.(args)
      end

      {:ok, rule}
    end
  end

  defp do_create(%{"Or" => cases}) do
    with {:ok, inner_rules} <- do_create_cases(cases) do
      rule = fn args ->
        Enum.any?(inner_rules, fn rule -> rule.(args) end)
      end

      {:ok, rule}
    end
  end

  defp do_create(%{"And" => cases}) do
    with {:ok, inner_rules} <- do_create_cases(cases) do
      rule = fn args ->
        Enum.all?(inner_rules, fn rule -> rule.(args) end)
      end

      {:ok, rule}
    end
  end

  defp do_create(%{"StringEquals" => value, "Variable" => variable}),
    do: compare_with_value(&==/2, &is_binary/1, variable, value)

  defp do_create(%{"StringEqualsPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&==/2, &is_binary/1, variable, value)

  defp do_create(%{"StringLessThan" => value, "Variable" => variable}),
    do: compare_with_value(&</2, &is_binary/1, variable, value)

  defp do_create(%{"StringLessThanPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&</2, &is_binary/1, variable, value)

  defp do_create(%{"StringGreaterThan" => value, "Variable" => variable}),
    do: compare_with_value(&>/2, &is_binary/1, variable, value)

  defp do_create(%{"StringGreaterThanPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&>/2, &is_binary/1, variable, value)

  defp do_create(%{"StringLessThanEquals" => value, "Variable" => variable}),
    do: compare_with_value(&<=/2, &is_binary/1, variable, value)

  defp do_create(%{"StringLessThanEqualsPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&<=/2, &is_binary/1, variable, value)

  defp do_create(%{"StringGreaterThanEquals" => value, "Variable" => variable}),
    do: compare_with_value(&>=/2, &is_binary/1, variable, value)

  defp do_create(%{"StringGreaterThanEqualsPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&>=/2, &is_binary/1, variable, value)

  defp do_create(%{"StringMatches" => _value, "Variable" => _variable}),
    do: {:error, "Not implemented"}

  defp do_create(%{"NumericEquals" => value, "Variable" => variable}),
    do: compare_with_value(&==/2, &is_number/1, variable, value)

  defp do_create(%{"NumericEqualsPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&==/2, &is_number/1, variable, value)

  defp do_create(%{"NumericLessThan" => value, "Variable" => variable}),
    do: compare_with_value(&</2, &is_number/1, variable, value)

  defp do_create(%{"NumericLessThanPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&</2, &is_number/1, variable, value)

  defp do_create(%{"NumericGreaterThan" => value, "Variable" => variable}),
    do: compare_with_value(&>/2, &is_number/1, variable, value)

  defp do_create(%{"NumericGreaterThanPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&>/2, &is_number/1, variable, value)

  defp do_create(%{"NumericLessThanEquals" => value, "Variable" => variable}),
    do: compare_with_value(&<=/2, &is_number/1, variable, value)

  defp do_create(%{"NumericLessThanEqualsPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&<=/2, &is_number/1, variable, value)

  defp do_create(%{"NumericGreaterThanEquals" => value, "Variable" => variable}),
    do: compare_with_value(&>=/2, &is_number/1, variable, value)

  defp do_create(%{"NumericGreaterThanEqualsPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&>=/2, &is_number/1, variable, value)

  defp do_create(%{"BooleanEquals" => value, "Variable" => variable}),
    do: compare_with_value(&==/2, &is_boolean/1, variable, value)

  defp do_create(%{"BooleanEqualsPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&==/2, &is_boolean/1, variable, value)

  defp do_create(%{"TimestampEquals" => value, "Variable" => variable}),
    do: compare_with_value(&timestamp_eq/2, &is_timestamp/1, variable, value)

  defp do_create(%{"TimestampEqualsPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&timestamp_eq/2, &is_timestamp/1, variable, value)

  defp do_create(%{"TimestampLessThan" => value, "Variable" => variable}),
    do: compare_with_value(&timestamp_lt/2, &is_timestamp/1, variable, value)

  defp do_create(%{"TimestampLessThanPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&timestamp_lt/2, &is_timestamp/1, variable, value)

  defp do_create(%{"TimestampGreaterThan" => value, "Variable" => variable}),
    do: compare_with_value(&timestamp_gt/2, &is_timestamp/1, variable, value)

  defp do_create(%{"TimestampGreaterThanPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&timestamp_gt/2, &is_timestamp/1, variable, value)

  defp do_create(%{"TimestampLessThanEquals" => value, "Variable" => variable}),
    do: compare_with_value(&timestamp_lte/2, &is_timestamp/1, variable, value)

  defp do_create(%{"TimestampLessThanEqualsPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&timestamp_lte/2, &is_timestamp/1, variable, value)

  defp do_create(%{"TimestampGreaterThanEquals" => value, "Variable" => variable}),
    do: compare_with_value(&timestamp_gte/2, &is_timestamp/1, variable, value)

  defp do_create(%{"TimestampGreaterThanEqualsPath" => value, "Variable" => variable}),
    do: compare_with_path_value(&timestamp_gte/2, &is_timestamp/1, variable, value)

  defp do_create(%{"IsNull" => true, "Variable" => variable}) do
    with {:ok, variable_fn} <- path_value(variable, result_type: :value_path) do
      rule = fn args ->
        case variable_fn.(args) do
          # returned nil because the value is not present
          {nil, ""} -> false
          # returned nil because the value is null
          {nil, _} -> true
          # value not null
          {_, _} -> false
        end
      end

      {:ok, rule}
    end
  end

  defp do_create(%{"IsPresent" => true, "Variable" => variable}) do
    with {:ok, variable_fn} <- path_value(variable, result_type: :path) do
      rule = fn args ->
        case variable_fn.(args) do
          "" -> false
          _ -> true
        end
      end

      {:ok, rule}
    end
  end

  defp do_create(%{"IsNumeric" => true, "Variable" => variable}),
    do: is_type(&is_number/1, variable)

  defp do_create(%{"IsString" => true, "Variable" => variable}),
    do: is_type(&is_binary/1, variable)

  defp do_create(%{"IsBoolean" => true, "Variable" => variable}),
    do: is_type(&is_boolean/1, variable)

  defp do_create(%{"IsTimestamp" => true, "Variable" => variable}),
    do: is_type(&is_timestamp/1, variable)

  defp do_create(_rule) do
    {:error, :invalid_rule}
  end

  defp do_create_cases(cases) when is_list(cases) do
    do_create_cases(cases, [])
  end

  defp do_create_cases(_cases) do
    {:error, :invalid_rule_cases}
  end

  defp do_create_cases([], acc), do: {:ok, acc}

  defp do_create_cases([rule | cases], acc) do
    case do_create(rule) do
      {:ok, rule} -> do_create_cases(cases, [rule | acc])
      err -> err
    end
  end

  defp compare_with_value(compare, check_type, variable, value) do
    with {:ok, variable_fn} <- path_value(variable) do
      rule = fn args ->
        variable_value = variable_fn.(args)

        check_type.(variable_value) and
          check_type.(value) and
          compare.(variable_value, value)
      end

      {:ok, rule}
    end
  end

  defp compare_with_path_value(compare, check_type, variable, value) do
    with {:ok, variable_fn} <- path_value(variable),
         {:ok, value_fn} <- path_value(value) do
      rule = fn args ->
        variable_value = variable_fn.(args)
        value_value = value_fn.(args)

        check_type.(variable_value) and
          check_type.(value_value) and
          compare.(variable_value, value_value)
      end

      {:ok, rule}
    end
  end

  defp is_type(check_type, variable) do
    with {:ok, variable_fn} <- path_value(variable) do
      rule = fn args ->
        variable_value = variable_fn.(args)
        check_type.(variable_value)
      end

      {:ok, rule}
    end
  end

  defp path_value(path, opts \\ []) do
    with {:ok, expr} <- Warpath.Expression.compile(path) do
      value_fn = fn args -> Warpath.query!(args, expr, opts) end
      {:ok, value_fn}
    end
  end

  defp timestamp_eq(ts1, ts2),
    do: timestamp_compare(ts1, ts2) == :eq

  defp timestamp_lt(ts1, ts2),
    do: timestamp_compare(ts1, ts2) == :lt

  defp timestamp_gt(ts1, ts2),
    do: timestamp_compare(ts1, ts2) == :gt

  defp timestamp_lte(ts1, ts2) do
    cmp = timestamp_compare(ts1, ts2)
    cmp == :lt || cmp == :eq
  end

  defp timestamp_gte(ts1, ts2) do
    cmp = timestamp_compare(ts1, ts2)
    cmp == :gt || cmp == :eq
  end

  defp timestamp_compare(ts1, ts2) do
    with {:ok, ts1, _} <- DateTime.from_iso8601(ts1),
         {:ok, ts2, _} <- DateTime.from_iso8601(ts2) do
      DateTime.compare(ts1, ts2)
    else
      _ -> :error
    end
  end

  defp is_timestamp(value) do
    case DateTime.from_iso8601(value) do
      {:ok, _, _} -> true
      _ -> false
    end
  end
end
