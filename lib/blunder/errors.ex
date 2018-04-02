defmodule Blunder.Errors do
  @moduledoc """
  Provides a macro for creating your own %Blunder{} generating helper functions
  """

  @doc """
  Generates a funtion that returns a blunder error with the given code and attributes
  The code will be the same as the name of the function undless overriden in the `opts`
  """
  @spec deferror(atom, Blunder.opts) :: no_return
  defmacro deferror(code, opts \\ []) do
    quote do
      @spec unquote(code)(opts :: Blunder.opts) :: Blunder.t
      def unquote(code)(override_opts \\ []) do
        Blunder.new(unquote(code), unquote(opts) ++ override_opts)
      end
    end
  end
end
