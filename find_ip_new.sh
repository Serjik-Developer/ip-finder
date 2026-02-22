#!/bin/bash

# Имя ресурса в консоли Yandex Cloud
NAME="wanted-ip-zone-b"
# Маска, которую ищем
PREFIX="51.250."

echo "Поиск IP с маской $PREFIX..."

while true; do
  # 1. Пытаемся создать адрес
  # Если адрес с таким именем уже есть, yc выдаст ошибку, поэтому сначала удаляем (на всякий случай)
  yc vpc address delete $NAME > /dev/null 2>&1

  # 2. Резервируем новый статический IP
  RAW_OUT=$(yc vpc address create --name $NAME --external-ipv4 zone=ru-central1-b --format json 2>/dev/null)

  if [ $? -ne 0 ]; then
    echo "Ошибка при создании IP. Возможно, исчерпаны лимиты. Жду 10 сек..."
    sleep 10
    continue
  fi

  # 3. Достаем адрес из JSON
  CURRENT_IP=$(echo $RAW_OUT | jq -r '.external_ipv4_address.address')

  echo "Проверка: $CURRENT_IP"

  # 4. Проверяем маску
  if [[ $CURRENT_IP == $PREFIX* ]]; then
    echo "----------------------------------------------------"
    echo "УСПЕХ! Найден адрес: $CURRENT_IP"
    echo "Он оставлен в вашем облаке под именем: $NAME"
    echo "----------------------------------------------------"
    break
  else
    # 5. Если не подошел — удаляем сразу, чтобы освободить квоту
    yc vpc address delete $NAME > /dev/null 2>&1
    # Небольшая пауза, чтобы не забанили за флуд
    sleep 1
  fi
done
