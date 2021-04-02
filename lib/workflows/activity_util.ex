defmodule Workflows.ActivityUtil do
  @moduledoc false

  alias Workflows.Catcher
  alias Workflows.Path
  alias Workflows.PayloadTemplate
  alias Workflows.ReferencePath
  alias Workflows.Retrier

  ## Parse helpers

  def parse_transition(%{"Next" => _, "End" => _}) do
    {:error, :multiple_transition}
  end

  def parse_transition(%{"Next" => next}) do
    {:ok, {:next, next}}
  end

  def parse_transition(%{"End" => true}) do
    {:ok, :end}
  end

  def parse_transition(_state) do
    {:error, :missing_transition}
  end

  def parse_input_path(%{"InputPath" => path}) do
    if path == nil do
      {:ok, nil}
    else
      Path.create(path)
    end
  end

  def parse_input_path(_state) do
    Path.create("$")
  end

  def parse_parameters(%{"Parameters" => params}) do
    PayloadTemplate.create(params)
  end

  def parse_parameters(_state), do: {:ok, nil}

  def parse_result_selector(%{"ResultSelector" => params}) do
    PayloadTemplate.create(params)
  end

  def parse_result_selector(_state), do: {:ok, nil}

  def parse_result_path(%{"ResultPath" => path}) do
    if path == nil do
      {:ok, nil}
    else
      ReferencePath.create(path)
    end
  end

  def parse_result_path(_state) do
    ReferencePath.create("$")
  end

  def parse_output_path(%{"OutputPath" => path}) do
    if path == nil do
      {:ok, nil}
    else
      Path.create(path)
    end
  end

  def parse_output_path(_state) do
    Path.create("$")
  end

  def parse_retry(%{"Retry" => retries}), do: do_parse_retry(retries, [])

  def parse_retry(_retry), do: {:ok, []}

  def parse_catch(%{"Catch" => catchers}), do: do_parse_catch(catchers, [])

  def parse_catch(_retry), do: {:ok, []}

  ## Apply input/output transforms

  def apply_input_path(activity, args) do
    apply_path(activity.input_path, args)
  end

  def apply_output_path(activity, args) do
    apply_path(activity.output_path, args)
  end

  def apply_parameters(activity, ctx, args) do
    PayloadTemplate.apply(activity.parameters, ctx, args)
  end

  def apply_result_selector(activity, ctx, args) do
    PayloadTemplate.apply(activity.result_selector, ctx, args)
  end

  def apply_result_path(activity, _ctx, args, state_args) do
    if activity.result_path == nil do
      {:ok, state_args}
    else
      ReferencePath.apply(activity.result_path, args, state_args)
    end
  end

  ## Private

  defp do_parse_retry([retrier | retriers], acc) do
    with {:ok, retrier} <- Retrier.create(retrier) do
      do_parse_retry(retriers, [retrier | acc])
    end
  end

  defp do_parse_retry([], acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp do_parse_catch([catcher | catchers], acc) do
    with {:ok, catcher} <- Catcher.create(catcher) do
      do_parse_catch(catchers, [catcher | acc])
    end
  end

  defp do_parse_catch([], acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp apply_path(nil, _args) do
    # If the value of InputPath is null, that means that the raw input is discarded, and the effective input for
    # the state is an empty JSON object, {}. Note that having a value of null is different from the
    # "InputPath" field being absent.

    # If the value of OutputPath is null, that means the input and result are discarded, and the effective output
    # from the state is an empty JSON object, {}.
    {:ok, %{}}
  end

  defp apply_path(path, args) do
    Path.query(path, args)
  end
end
