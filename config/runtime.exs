import Config

s3_endpoint = URI.parse(System.get_env("S3_ENDPOINT"))

config :db_backup, DbBackup,
  docker_container: System.get_env("PG_DOCKER_CONTAINER", "pg-container"),
  pg_user: System.get_env("PG_USER", "postgres"),
  pg_port: System.get_env("PG_PORT", "5432"),
  tmp_dir: System.get_env("BACKUP_TMP_DIR", "/tmp/db_backups"),
  gpg_encrypt_key_id: System.get_env("GPG_ENCRYPT_KEY_ID", "KEYID"),
  gpg_sign_key_id: System.get_env("GPG_SIGN_KEY_ID", "KEYID"),
  gpg_sign_key_passphrase: System.get_env("GPG_SIGN_KEY_PASSPHRASE", ""),
  s3_bucket: System.get_env("S3_BUCKET"),
  s3_path_prefix: System.get_env("S3_BACKUPS_PATH_PREFIX", "pg-backups")

config :ex_aws,
  access_key_id: System.get_env("S3_ACCESS_KEY"),
  secret_access_key: System.get_env("S3_SECRET_KEY"),
  region: System.get_env("S3_REGION", "eu-central-1"),
  s3: [
    scheme: "#{s3_endpoint.scheme}://",
    host: s3_endpoint.host,
    port: s3_endpoint.port,
    bucket: System.get_env("S3_BUCKET"),
    region: System.get_env("S3_REGION"),
    content_hash_algorithm: :sha256
  ]
