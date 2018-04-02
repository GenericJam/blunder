# Blunder

A common error struct for elixir apps

## Usage

Blunder structs give you a common, expressive error type to rase in exceptions return in `{:error, %Blunder{}}` tuples. This gives you a lot more expressiveness than `{:error, "error string"}`. The `%Blunder{}` struct has the following properties you can set.

* `code` - An atom describing the error in a machine-readable way. Defaults to `:application_error`
* `summary` - A short description of the error, suitable for display to users
* `details` - A more detailed description of the error, suitable for logging or alerting.
* `severity` - An atom indicating of the severity of the error, can be used to determine what to log, for example.
* `stacktrace` - Allows you to attach a stacktrace to the error, `nil` by default
* `original_error` - The original error if this Blunder error is wrapping a lower-level exception

In order to simplify the creation of these error structs you're encouraged to create an `Errors` module in your app that exports functions for creating Blunder errors. This serves as a conveniance as well as a central place to document error types. Blunder provides the `deferror` macro in `Blunder.Errors` to make this easier.

```elixir
defmodule MyApp.Errors do
  import Blunder.Errors

  deferror :flagrant_system_error, 
    message: "MUCH ERRORZ!",
    severity: :critical

  deferror :boring_error, message: "whatevs"
end

defmodule MyApp.DoTheWork do
  import MyApp.Errors

  def add(x, y) do
    case get_system_status do
      :server_is_on_fire -> {:error, flagrant_system_error()},
      :server_is_le_tired -> {:error, boring_error()},
      :server_ready_to_work -> {:ok, x + y},
    end
  end
end
```
