defmodule Blunder.ErrorsTest do
  use ExUnit.Case, async: true
  doctest Blunder.Errors

  Blunder.Errors.deferror :test_error,
    summary: "The Summary",
    details: "The Details"

  test "using the function created by deferror" do
    assert %Blunder{
      code: :test_error,
      summary: "The Summary",
      details: "The Details"
    } = test_error()
  end

  test "passing in override arguments" do
    assert %Blunder{
      code: :test_error,
      summary: "New Summary",
      details: "The Details"
    } = test_error(summary: "New Summary")
  end
end
