defmodule DbBackup.MixProject do
  use Mix.Project

  def project do
    [
      app: :db_backup,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        db_backup: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  def application do
    [
      mod: {DbBackup.Application, []},
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_aws, "~> 2.4"},
      {:ex_aws_s3, "~> 2.4"},
      {:hackney, "~> 1.18"},
      {:sweet_xml, "~> 0.7"}
    ]
  end
end
