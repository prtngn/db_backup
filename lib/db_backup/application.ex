defmodule DbBackup.Application do
  use Application

  @dialyzer {:nowarn_function, start: 2}

  @impl true
  def start(_type, _args) do
    Task.start_link(fn ->
      result = DbBackup.run()
      System.halt(if result == :ok, do: 0, else: 1)
    end)

    Supervisor.start_link([], strategy: :one_for_one, name: DbBackup.Supervisor)
  end
end
