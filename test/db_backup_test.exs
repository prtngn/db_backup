defmodule DbBackupTest do
  use ExUnit.Case
  doctest DbBackup

  test "greets the world" do
    assert DbBackup.hello() == :world
  end
end
