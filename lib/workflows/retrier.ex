defmodule Workflows.Retrier do
  @moduledoc """
  Implements a state retrier.

  ## References

   * https://states-language.net/#errors
  """

  @type t :: term()

  defstruct [:error_equals, :interval_seconds, :max_attempts, :backoff_rate, :attempt]

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

  def next(%__MODULE__{attempt: attempt, max_attempts: max_attempts} = retrier)
      when attempt < max_attempts do
    wait = retrier.interval_seconds + retrier.backoff_rate * attempt
    {:wait, wait, %__MODULE__{retrier | attempt: attempt + 1}}
  end

  def next(retrier), do: {:max_attempts, retrier}

  defp do_create([], _interval_seconds, _max_attempts, _backoff_rate),
    do: {:error, "ErrorEquals must be non empty"}

  defp do_create(_errors, interval_seconds, _max_attempts, _backoff_rate)
       when not is_integer(interval_seconds)
       when interval_seconds <= 0,
       do: {:error, "IntervalSeconds must be a positive integer"}

  defp do_create(_errors, _interval_seconds, max_attempts, _backoff_rate)
       when not is_integer(max_attempts)
       when max_attempts < 0,
       do: {:error, "MaxAttempts must be a non-negative integer"}

  defp do_create(_errors, _interval_seconds, _max_attempts, backoff_rate)
       when backoff_rate < 1.0,
       do: {:error, "BackoffRate must be a greater than or equal to 1.0"}

  defp do_create(errors, interval_seconds, max_attempts, backoff_rate) do
    retrier = %__MODULE__{
      error_equals: errors,
      interval_seconds: interval_seconds,
      max_attempts: max_attempts,
      backoff_rate: backoff_rate,
      attempt: 0
    }

    {:ok, retrier}
  end
end
