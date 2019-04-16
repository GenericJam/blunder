defmodule BlunderTest do
  use ExUnit.Case
  doctest Blunder

  import Blunder

  describe "&new" do
    test "new(:code)" do
      assert %Blunder{
        code: :some_code,
        summary: "Application Error",
      } = Blunder.new(:some_code)
    end

    test ~s'new("error string")' do
      assert %Blunder{
        code: :application_error,
        details: "some error string",
      } = Blunder.new("some error string")
    end

    test ~s'new(:code, "error string")' do
      assert %Blunder{
        code: :some_code,
        summary: "Application Error",
        details: "some error string"
      } = Blunder.new(:some_code, "some error string")
    end

    test "new(%Blunder{})" do
      blunder = %Blunder{summary: "some summary"}
      assert blunder == Blunder.new(blunder)
    end

    test "new(any)" do
      args = [
        %{some: :map},
        %RuntimeError{},
        {:tuple},
        [keyword: :list],
      ]
      for arg <- args do
        assert %Blunder{
          code: :application_error,
          summary: "Application Error",
          details: "",
          original_error: ^arg,
        } = Blunder.new(arg)
      end
    end

  end

  describe "exception behaviour" do

    test "&Exception.exception?/1" do
      assert Exception.exception? %Blunder{}
    end

    test "&Exception.format/1" do
      assert "** (Blunder) the_code: the summary. the details" ==
        Exception.format(:error, %Blunder{
          summary: "the summary",
          details: "the details",
          code: :the_code,
        })
    end

    test "&Exception.format/1 with no details" do
      assert "** (Blunder) the_code: the summary" ==
        Exception.format(:error, %Blunder{
          summary: "the summary",
          code: :the_code,
        })
    end
  end

  describe "&trap_exceptions/2" do
    test "does not change sucessfull results" do
      assert trap_exceptions(fn -> "foo" end) == "foo"
      assert trap_exceptions(fn -> {:ok, "foo"} end) == {:ok, "foo"}
    end

    test "does not change un-excpetional errors" do
      assert trap_exceptions(fn -> {:error, "BOOM!"} end) == {:error, "BOOM!"}
    end

    test "handles exception raising" do
      assert {:error, %Blunder{details: details, original_error: %RuntimeError{message: "foo"}}} =
        trap_exceptions(fn -> raise "foo" end)
      assert details =~ ~r/exception/
    end

    test "handles string thrown" do
      assert {:error, %Blunder{details: details, original_error: "foo"}} =
        trap_exceptions(fn -> throw "foo" end)
      assert details =~ ~r/throw/
    end

    test "handles arbitrary value thrown" do
      assert {:error, %Blunder{details: details, original_error: {:foo, :bar, []}}} =
        trap_exceptions(fn -> throw {:foo, :bar, []} end)
      assert details =~ ~r/throw/
    end

    test "handles exit" do
      assert {:error, %Blunder{details: details, original_error: "foo"}} =
        trap_exceptions(fn -> throw exit "foo" end)
      assert details =~ ~r/exit/
    end

    test "handles timeouts" do
      assert {:error, %Blunder{details: details}} = trap_exceptions(fn -> :time.sleep(1) end, timeout_ms: 0)
      assert details =~ ~r/timeout/
    end

    test "handles Process.exit(self, binary)" do
      assert {:error, %Blunder{details: details, original_error: "foo"}} =
        trap_exceptions(fn -> Process.exit(self(), "foo") end)
      assert details =~ ~r/exit/
    end

    test "handles Process.exit(self, any)" do
      assert {:error, %Blunder{details: details, original_error: {:foo, []}}} =
        trap_exceptions(fn -> Process.exit(self(), {:foo, []}) end)
      assert details =~ ~r/exit/
    end

    test "handles MatchError on Blunder error tuple" do
      assert {:error, %Blunder{details: "oops!", original_error: %MatchError{}}} =
        trap_exceptions(fn ->
          failing_func = fn -> {:error, Blunder.new("oops!")} end
          {:ok, _} = failing_func.()
        end)
    end

    test "handles error tuple with timeout error" do
      assert trap_exceptions(fn -> Process.exit(self(), {:timeout, {:foo, :bar}}) end) == {
               :error, %Blunder{
                 code: :application_error,
                 details: "Blunder trapped exit",
                 original_error: {:timeout, {:foo, :bar}},
                 severity: :error, stacktrace: nil,
                 summary: "Application Error"}
             }
    end
  end

  describe "&format/1" do
    @blunder %Blunder{
      code: :the_code,
      summary: "the summary",
      details: "the details",
      severity: :error,
      original_error: "the original error",
    }

    test "formats a Blunder struct" do
      result = Blunder.format(@blunder)
      assert result =~ "error"
      assert result =~ "the_code"
      assert result =~ "the summary"
      assert result =~ "the details"
      assert result =~ "the original error"
    end

    test "when original error is an Excpetion" do
      assert Blunder.format(%Blunder{
        original_error: %RuntimeError{message: "HALP!"}
      }) =~ "** (RuntimeError) HALP!"
    end

    test "when original_error is neither an exception nor a string" do
      assert Blunder.format(%Blunder{
        original_error: {:a, :b, :c}
      }) =~ "{:a, :b, :c}"
    end

    test "includes a stacktrace" do
      {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)
      assert Blunder.format(%Blunder{
        stacktrace: stacktrace
      }) =~ "test &format/1" # from stack trace
    end
  end
end
