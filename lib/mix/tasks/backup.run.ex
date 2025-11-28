defmodule Mix.Tasks.Backup.Run do
  use Mix.Task

  @shortdoc "Дамп, шифрование и загрузка всех баз"
  def run(_args) do
    Mix.Task.run("app.start")
    DbBackup.run()
  end
end
