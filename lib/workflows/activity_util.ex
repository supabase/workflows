defmodule Workflows.ActivityUtil do
  @moduledoc false

  alias Workflows.Catcher
  alias Workflows.Path
  alias Workflows.PayloadTemplate
  alias Workflows.ReferencePath
  alias Workflows.Retrier

  ## Parse helpers

  def parse_transition(%{"Next" => _, "End" => _}) do
    {:error, "Only one of Next or End can be present"}
  end

  def parse_transition(%{"Next" => next}) do
    {:ok, {:next, next}}
  end

  def parse_transition(%{"End" => true}) do
    {:ok, :end}
  end

  def parse_transition(_state) do
    {:error, "One of Next or End can be present"}
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
end
