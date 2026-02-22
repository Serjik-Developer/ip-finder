#!/bin/bash

NAME="wanted-ip"
PREFIX="51.250."
COUNT=0 # Добавляем счетчик

echo "Поиск IP с маской $PREFIX..."

while true; do
  ((COUNT++)) # Увеличиваем при каждой итерации
  yc vpc address delete $NAME --folder-id $FOLDER_ID > /dev/null 2>&1

  RAW_OUT=$(yc vpc address create --name $NAME --external-ipv4 zone=ru-central1-d --folder-id $FOLDER_ID --format json 2>/dev/null)

  if [ $? -ne 0 ]; then
    echo "Попытка $COUNT: Ошибка лимитов, жду..."
    sleep 10
    continue
  fi

  CURRENT_IP=$(echo $RAW_OUT | jq -r '.external_ipv4_address.address')
  echo "Попытка $COUNT: Проверка $CURRENT_IP"

  if [[ $CURRENT_IP == $PREFIX* ]]; then
    echo "----------------------------------------------------"
    echo "УСПЕХ! Найден адрес: $CURRENT_IP за $COUNT попыток."
    echo "----------------------------------------------------"
    break
  else
    yc vpc address delete $NAME --folder-id $FOLDER_ID > /dev/null 2>&1
    sleep 1
  fi
done
