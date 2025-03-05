#!/bin/bash

# Функция для вывода справки
usage() {
  echo "Использование: $0 [-h] SOURCE_DIR DESTINATION_DIR DEMON_NAME"
  echo
  echo "  Копирует содержимое папки SOURCE_DIR в папку DESTINATION_DIR,"
  echo "  при этом останавливает и запускает демон DEMON_NAME."
  echo
  echo "Обязательные аргументы:"
  echo "  SOURCE_DIR      Путь к исходной папке, которую нужно скопировать."
  echo "  DESTINATION_DIR Путь к целевой папке (будет создана, если не существует)."
  echo "  DEMON_NAME      Имя демона, который нужно остановить и запустить."
  echo
  echo "Опции:"
  echo "  -h              Вывести эту справку и выйти."
  exit 1
}

# Обработка аргументов командной строки
while getopts "h" opt; do
  case "$opt" in
    h)
      usage
      ;;
    \?)
      echo "Недопустимая опция: -$OPTARG" >&2
      usage
      ;;
  esac
done
shift $((OPTIND-1))

# Проверка количества аргументов
if [ $# -ne 3 ]; then
  echo "Ошибка: Требуется указать все три аргумента: SOURCE_DIR, DESTINATION_DIR, DEMON_NAME."
  usage
fi

# Присваиваем аргументы переменным
SOURCE_DIR="$1"
DESTINATION_DIR="$2"
DEMON_NAME="$3"

# Проверка существования исходной папки
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Ошибка: Исходная папка '$SOURCE_DIR' не существует."
  exit 1
fi

# Проверка существования destination_dir, если нет - создать её.
if [ ! -d "$DESTINATION_DIR" ]; then
  mkdir -p "$DESTINATION_DIR"
  if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось создать папку '$DESTINATION_DIR'."
    exit 1
  fi
  echo "Создана папка '$DESTINATION_DIR'."
fi

# Функция для остановки демона
stop_demon() {
  echo "Останавливаю демон '$DEMON_NAME'..."

  # Используем systemctl для остановки демона (предполагается, что это systemd)
  sudo systemctl stop "$DEMON_NAME"

  # Проверяем, успешно ли остановлен демон
  if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось остановить демон '$DEMON_NAME'."
    exit 1
  fi

  echo "Демон '$DEMON_NAME' остановлен."
}

# Функция для запуска демона
start_demon() {
  echo "Запускаю демон '$DEMON_NAME'..."

  # Используем systemctl для запуска демона (предполагается, что это systemd)
  sudo systemctl start "$DEMON_NAME"

  # Проверяем, успешно ли запущен демон
  if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось запустить демон '$DEMON_NAME'."
    exit 1
  fi

  echo "Демон '$DEMON_NAME' запущен."
}

# 1. Останавливаем демон
stop_demon

# 2. Копируем содержимое папки
echo "Копирую содержимое папки '$SOURCE_DIR' в '$DESTINATION_DIR'..."
cp -r "$SOURCE_DIR"/* "$DESTINATION_DIR"/
if [ $? -ne 0 ]; then
  echo "Ошибка: Не удалось скопировать файлы."
  # Если копирование не удалось, нужно запустить демон обратно
  start_demon
  exit 1
fi
echo "Копирование завершено."

# 3. Запускаем демон
start_demon

echo "Скрипт завершен успешно."

exit 0