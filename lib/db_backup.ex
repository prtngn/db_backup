defmodule DbBackup do
  require Logger

  alias ExAws.S3

  # S3 multipart upload requires minimum 5 MB per part (except last)
  @min_chunk_size 5 * 1024 * 1024

  @spec run() :: :ok | {:error, term()}
  def run do
    config = Application.get_env(:db_backup, __MODULE__, [])
    ts = DateTime.utc_now() |> Calendar.strftime("%Y%m%d-%H%M%S")

    with {:ok, dbs} <- list_databases(config),
         :ok <- process_all_databases(dbs, ts, config) do
      Logger.info("Backup finished successfully")
      :ok
    else
      {:error, reason} ->
        Logger.error("Backup failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp process_all_databases(dbs, ts, config) do
    results =
      Enum.map(dbs, fn db ->
        process_database(db, ts, config)
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp process_database(db, ts, config) do
    key = Path.join(config[:s3_path_prefix], ["#{ts}/#{db}.dump.gpg"])
    Logger.info("Starting backup for database: #{db}")

    cmd = build_pipeline_cmd(db, config)

    try do
      cmd
      |> port_stream()
      |> chunk_stream(@min_chunk_size)
      |> S3.upload(config[:s3_bucket], key, timeout: 600_000)
      |> ExAws.request()
      |> case do
        {:ok, _} ->
          Logger.info("Database #{db} backed up successfully")
          :ok

        {:error, reason} ->
          {:error, {:s3_upload_failed, reason}}
      end
    catch
      :error, %RuntimeError{message: msg} -> {:error, {:pipeline_failed, msg}}
    end
  end

  defp build_pipeline_cmd(db, config) do
    container = config[:docker_container]
    user = config[:pg_user]
    port = config[:pg_port]
    encrypt_key = config[:gpg_encrypt_key_id]
    sign_key = config[:gpg_sign_key_id]
    sign_key_passphrase = config[:gpg_sign_key_passphrase]

    "docker exec -e PGPORT=#{port} #{container} pg_dump -U #{user} -Fc #{db} | " <>
      "gpg --batch --yes --pinentry-mode loopback --passphrase #{sign_key_passphrase} " <>
      "--trust-model always --local-user #{sign_key} --sign --recipient #{encrypt_key} --encrypt"
  end

  defp port_stream(cmd) do
    Stream.resource(
      fn -> open_port(cmd) end,
      &receive_data/1,
      &close_port/1
    )
  end

  defp chunk_stream(stream, min_size) do
    chunk_fun = fn data, buffer ->
      new_buffer = buffer <> data

      if byte_size(new_buffer) >= min_size do
        {:cont, new_buffer, <<>>}
      else
        {:cont, new_buffer}
      end
    end

    after_fun = fn
      <<>> -> {:cont, []}
      buffer -> {:cont, buffer, []}
    end

    Stream.chunk_while(stream, <<>>, chunk_fun, after_fun)
  end

  defp open_port(cmd) do
    Port.open({:spawn, "sh -c '#{cmd}'"}, [:binary, :stream, :exit_status])
  end

  defp receive_data({:done, _port} = state), do: {:halt, state}

  defp receive_data(port) do
    receive do
      {^port, {:data, data}} ->
        {[data], port}

      {^port, {:exit_status, 0}} ->
        {:halt, {:done, port}}

      {^port, {:exit_status, status}} ->
        raise "Pipeline failed with exit status #{status}"
    after
      300_000 ->
        raise "Timeout waiting for data from pipeline"
    end
  end

  defp close_port({:done, port}), do: safe_close(port)
  defp close_port(port), do: safe_close(port)

  defp safe_close(port) do
    if Port.info(port), do: Port.close(port)
  end

  defp list_databases(config) do
    query = "SELECT datname FROM pg_database WHERE datistemplate = false;"

    args = [
      "exec",
      config[:docker_container],
      "psql",
      "-U",
      config[:pg_user],
      "-tAc",
      query
    ]

    case System.cmd("docker", args, env: [{"PGPORT", config[:pg_port]}], stderr_to_stdout: true) do
      {result, 0} ->
        dbs =
          result
          |> String.split("\n", trim: true)
          |> Enum.reject(&(&1 == "postgres"))

        {:ok, dbs}

      {error_msg, status} ->
        {:error, {:psql_list_failed, status, error_msg}}
    end
  end
end
