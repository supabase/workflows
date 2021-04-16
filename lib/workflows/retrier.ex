defmodule Workflows.Retrier do
  @moduledoc """
  Implements a state retrier.

  ## References

   * https://states-language.net/#errors
  """

  alias Workflows.Error

  @type t :: term()

  defstruct [:error_equals, :interval_seconds, :max_attempts, :backoff_rate]

  @default_interval_seconds 1
  @default_max_attempts 3
  @default_backoff_rate 2.0

  @doc """
  Create a new Retrier.
  """
  @spec create(any()) :: {:ok, t()} | {:error, term()}
  def create(%{"ErrorEquals" => errors} = attrs) do
    interval_seconds = Map.get(attrs, "IntervalSeconds", @default_interval_seconds)
    max_attempts = Map.get(attrs, "MaxAttempts", @default_max_attempts)
    backoff_rate = Map.get(attrs, "BackoffRate", @default_backoff_rate)
    do_create(errors, interval_seconds, max_attempts, backoff_rate)
  end

  def create(_attrs) do
    {:error, :missing_error_equals}
  end

  @spec matches?(t(), Error.t()) :: boolean()
  def matches?(retrier, error) do
    Enum.any?(retrier.error_equals, fn ee -> ee == "States.ALL" || ee == error.name end)
  end

  ## Private

  defp do_create([], _interval_seconds, _max_attempts, _backoff_rate),
    do: {:error, :empty_errors}

  defp do_create(_errors, interval_seconds, _max_attempts, _backoff_rate)
       when not is_integer(interval_seconds)
       when interval_seconds <= 0,
       do: {:error, :invalid_interval_seconds}

  defp do_create(_errors, _interval_seconds, max_attempts, _backoff_rate)
       when not is_integer(max_attempts)
       when max_attempts < 0,
       do: {:error, :invalid_max_attempts}

  defp do_create(_errors, _interval_seconds, _max_attempts, backoff_rate)
       when backoff_rate < 1.0,
       do: {:error, :invalid_backoff_rate}

  defp do_create(errors, interval_seconds, max_attempts, backoff_rate) do
    retrier = %__MODULE__{
      error_equals: errors,
      interval_seconds: interval_seconds,
      max_attempts: max_attempts,
      backoff_rate: backoff_rate,
    }

    {:ok, retrier}
  end
end
