#!/bin/bash

# 執行指令：chmod +x update_tokens.sh && ./update_tokens.sh

# 1. 載入現有的 .env 變數
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "錯誤: 找不到 .env 檔案"
    exit 1
fi

echo "🚀 正在請求新的 Tokens..."

# 2. 執行 cURL 並取得回應
# 使用 -s 隱藏進度條，並擷取回應內容
RESPONSE=$(curl -s --location "$TOKEN_LOCATION" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --header 'Cookie: KEYCLOAK_LOCALE=zh-TW' \
    --data-urlencode "username=$USERNAME" \
    --data-urlencode "password=$PASSWORD" \
    --data-urlencode "grant_type=password" \
    --data-urlencode "scope=openid" \
    --data-urlencode "client_id=$CLIENT_ID" \
    --data-urlencode "client_secret=$CLIENT_SECRET")

# 3. 解析 JSON (使用 grep 和 sed 避免安裝 jq)
NEW_ACCESS_TOKEN=$(echo $RESPONSE | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$')
NEW_ID_TOKEN=$(echo $RESPONSE | grep -o '"id_token":"[^"]*' | grep -o '[^"]*$')

if [ -z "$NEW_ACCESS_TOKEN" ]; then
    echo "❌ 取得 Token 失敗，請檢查 API 回應："
    echo $RESPONSE
    exit 1
fi

# 4. 更新 .env 檔案
# 使用 sed 替換整行內容
sed -i '' "s|^AUTH_TOKEN=.*|AUTH_TOKEN=$NEW_ACCESS_TOKEN|" .env
sed -i '' "s|^AUTH_ID_TOKEN=.*|AUTH_ID_TOKEN=$NEW_ID_TOKEN|" .env

echo "✅ .env 已更新！"
echo "🔑 AUTH_TOKEN 更新成功"
echo "🆔 AUTH_ID_TOKEN 更新成功"