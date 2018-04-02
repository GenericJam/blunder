use Mix.Config

config :ex_unit, capture_log: true
config :blunder, error_handers: [Blunder.Test.ErrorHandler]
