#!/bin/bash

source secrets.sh

curl \
  --request POST \
  --url https://api.telegram.org/bot$TELEGRAM_TOKEN/setWebhook \
  --header 'content-type: application/json' \
  --data '{"url": "https://d5dpccvtt47vs51i9eb7.y5sm01em.apigw.yandexcloud.net/doc-assist"}'