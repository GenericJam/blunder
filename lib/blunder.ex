defmodule Blunder do
  @moduledoc """
  Blunder is a generic error struct
  """
  defexception [
    code: :application_error,
    details: "",
    summary: "Application Error",
    original_error: nil,
    severity: :error,
    stacktrace: nil,
  ]

  @type severity :: :critical | :error | :warn | :info | :debug
  @type opts :: [
    code: atom,
    details: binary,
    summary: binary,
    original_error: any,
    severity: severity,
    stacktrace: nil | Exception.stacktrace
  ]
  @type t :: %Blunder{
    code: atom,
    details: binary,
    summary: binary,
    original_error: any,
    severity: severity,
    stacktrace: nil | Exception.stacktrace
  }

  require Logger

  @doc """
  Creates a new Blunder from a details string or another error

  Examples:

      # A string will be used as details
      iex> Blunder.new("These are the error details")
      %Blunder{details: "These are the error details"}

      # Blunder structs are returned unchanged
      iex> Blunder.new(%Blunder{code: :some_code})
      %Blunder{code: :some_code}

      # Anything else will be used as the `original_error`
      iex> Blunder.new(%RuntimeError{message: "oops!"})
      %Blunder{original_error: %RuntimeError{message: "oops!"}}
  """
  @spec new(any) :: t
  def new(%Blunder{} = blunder) do
    blunder
  end

  def new(details) when is_binary(details) do
    %Blunder{details: details}
  end

  def new(code) when is_atom(code) do
    %Blunder{code: code}
  end

  def new(error) do
    %Blunder{original_error: error}
  end

  @doc """
  Creates a new Blunder with a given code and options.

  Examples:

      iex> Blunder.new(:some_code, summary: "s", details: "d")
      %Blunder{code: :some_code, summary: "s", details: "d"}

      # A string can be given in place of the keyword options to set just the details
      iex> Blunder.new(:some_code, "These are the error details")
      %Blunder{code: :some_code, details: "These are the error details"}
  """
  @spec new(code :: atom, binary | opts) :: t
  def new(code, details) when is_atom(code) and is_binary(details) do
    new(code, details: details)
  end

  def new(code, opts) when is_atom(code) and is_list(opts) do
    %Blunder{code: code}
    |> struct(opts)
  end

  @doc """
  Formats a Blunder error for printing/logging.

  This returns a verbose, multi-line string.
  """
  @spec format(Blunder.t) :: binary
  def format(%Blunder{} = blunder) do
    """
    #{blunder.code}: #{blunder.summary}. #{blunder.details}.
    original_error: #{format_error blunder.original_error}
    #{blunder.stacktrace && Exception.format_stacktrace(blunder.stacktrace)}
    """
  end

  @impl Exception
  @spec message(Blunder.t) :: binary
  def message(%Blunder{} = b) do
    msg = "#{b.code}: #{b.summary}"
    case b.details do
      details when is_binary(details) and details != "" ->
        "#{msg}. #{b.details}"
      _ -> msg
    end
  end

  @spec format_error(term) :: binary
  defp format_error(error) do
    cond do
      Exception.exception?(error) ->
        "** (" <> inspect(error.__struct__) <> ") " <> Exception.message(error)
      is_binary(error) ->
        error
      true ->
        inspect(error)
    end
  end

  @doc """
  Runs the given function in a separate process and returns the function's
  return value or `{:error, Blunder.t}` if the function raised an excpetion or
  crashed in some way (untrapped throw, process exit, etc).

  Options:
    * timeout - function execution will be terminated after this many ms and an error retruned. Defaults to 2_000.
    * blunder - The attributes of this Blunder will be used as defauls for the attribute of the Blunder returned when there is an exception.
  """
  @type fun_return_type :: any
  @spec trap_exceptions(
    fun :: (... -> fun_return_type),
    opts :: [timeout_ms: number, blunder: Blunder.t]
  ) :: fun_return_type | {:error, Blunder.t}
  def trap_exceptions(fun, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 2_000)
    blunder = Keyword.get(opts, :blunder, %Blunder{})

    case Wormhole.capture(fun, timeout_ms: timeout_ms, stacktrace: true) do
      {:error, error} ->
        {:error, struct(blunder, wormhole_error_to_blunder_attrs(error))}
      {:ok, result} ->
        result
    end
  end

  @spec wormhole_error_to_blunder_attrs(any) ::
    [details: binary, original_error: term, stacktrace: Exception.stacktrace]
  defp wormhole_error_to_blunder_attrs({:shutdown, {:throw, error, stacktrace}}) do
    [details: "Blunder trapped un-caught throw", original_error: error, stacktrace: stacktrace]
  end
  defp wormhole_error_to_blunder_attrs({:shutdown, {:exit, error, stacktrace}}) do
    [details: "Blunder trapped unexpected exit", original_error: error, stacktrace: stacktrace]
  end
  defp wormhole_error_to_blunder_attrs({:shutdown, {%MatchError{term: {:error, %Blunder{} = blunder}} = error, stacktrace}}) do
    %Blunder{blunder | original_error: error, stacktrace: stacktrace}
    |> Map.from_struct
  end
  defp wormhole_error_to_blunder_attrs({:shutdown, {error, stacktrace}}) do
    [details: "Blunder trapped exception", original_error: error, stacktrace: stacktrace]
  end
  defp wormhole_error_to_blunder_attrs({:timeout, timeout_ms}) do
    [details: "funcation passed to trap_exceptions exceeded timeout of #{timeout_ms} ms", stacktrace: Exception.format_stacktrace]
  end
  defp wormhole_error_to_blunder_attrs(error) do
    [details: "Blunder trapped exit", original_error: error]
  end

end
