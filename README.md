# DbBackup

## Настройка на новом сервере

### 1. GPG Ключи

#### На сервере (Создание ключа для подписи)
1. Генерируем ключ (приватный ключ остаётся на сервере):
   ```bash
   gpg --full-generate-key
   ```
2. Экспортируем публичный ключ, чтобы импортировать его на машине, где будут проверяться бекапы:
   ```bash
   gpg --armor --export <KEY_ID> > server_sign_public.asc
   ```
3. **На машине для проверки**: импортируйте этот ключ:
   ```bash
   gpg --import server_sign_public.asc
   ```

#### На сервере (Импорт ключа для шифрования)
1. **С локальной машины**: экспортируйте публичный ключ, которым нужно шифровать бекапы, и передайте файл `.asc` на сервер.
2. На сервере импортируйте ключ:
   ```bash
   gpg --import encryption_public.asc
   ```
3. (Опционально) Установите доверие ключу, если требуется:
   ```bash
   gpg --edit-key <KEY_ID>
   # trust -> 5 -> save
   ```

### 2. Сборка и Запуск

#### Сборка
Используйте инструкции выше для сборки релиза. Образ соберет релиз в папку `_build/prod/rel/db_backup/`.

#### Запуск
1. Перейдите в папку с релизом:
   ```bash
   cd _build/prod/rel/db_backup/
   ```
2. Создайте в этой папке файл `.env` с необходимыми переменными окружения:
   ```env
   PG_DOCKER_CONTAINER=postgres_container_name
   PG_USER=postgres
   PG_PORT=5432
   GPG_ENCRYPT_KEY_ID=XXXXXXXXXXXXXXXX
   GPG_SIGN_KEY_ID=YYYYYYYYYYYYYYYY
   GPG_SIGN_KEY_PASSPHRASE=your_passphrase
   S3_ACCESS_KEY=your_access_key
   S3_SECRET_KEY=your_secret_key
   S3_REGION=us-east-1
   S3_ENDPOINT=https://s3.example.com
   S3_BUCKET=your-bucket
   S3_BACKUPS_PATH_PREFIX=db_backups
   ```
3. Запустите сервис:
   ```bash
   bin/db_backup start
   ```
