#!/bin/bash

# 设置 OpenAI API Key
API_KEY="sk-"  # 请替换为你的 API 密钥

# 设置模型名称
MODEL="gpt-4o-mini"  # 使用的模型

# 设置截图存放路径
SCREENSHOT_DIR="/storage/emulated/0/Pictures/Screenshots"  # 截图存放路径

# 记录最新文件的时间戳
LAST_MODIFIED=""
LAST_REPLY=""  # 用于存储上一次的回复

while true; do
    # 获取最新的截图文件
    IMAGE_PATH=$(ls -t "$SCREENSHOT_DIR" | head -n 1)

    # 检查是否找到截图文件
    if [ -z "$IMAGE_PATH" ]; then
        echo "未找到截图文件，请确保目录 $SCREENSHOT_DIR 中有图像文件。"
        sleep 10
        continue
    fi

    # 将完整路径添加到 IMAGE_PATH
    IMAGE_PATH="$SCREENSHOT_DIR/$IMAGE_PATH"

    # 获取当前文件的修改时间
    CURRENT_MODIFIED=$(stat -c %Y "$IMAGE_PATH")

    # 检查文件是否已更改
    if [ "$CURRENT_MODIFIED" != "$LAST_MODIFIED" ]; then
        LAST_MODIFIED="$CURRENT_MODIFIED"  # 更新为当前文件时间戳

        # 将图像文件转换为 Base64 编码并写入临时文件
        BASE64_TEMP_FILE=$(mktemp)
        base64 -w 0 "$IMAGE_PATH" > "$BASE64_TEMP_FILE"

        # 构建 JSON 请求体并写入临时文件
        JSON_TEMP_FILE=$(mktemp)
        cat <<EOF > "$JSON_TEMP_FILE"
{
  "model": "$MODEL",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,$(cat "$BASE64_TEMP_FILE")"
          }
        }
      ]
    }
  ],
  "max_tokens": 300
}
EOF

        # 使用 curl 发起 ChatGPT POST 请求
        CHATGPT_RESPONSE=$(curl -s -X POST "https://free.v36.cm/v1/chat/completions" \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json" \
            -d @"$JSON_TEMP_FILE")

        # 提取 ChatGPT 响应内容
        CHATGPT_REPLY=$(echo "$CHATGPT_RESPONSE" | jq -r '.choices[0].message.content')

        # 输出 ChatGPT 的回答
        echo "ChatGPT 回应: $CHATGPT_REPLY"
        LAST_REPLY="$CHATGPT_REPLY"  # 更新上一次的回复

        # 使用 Termux Toast 显示 ChatGPT 的回答
        termux-toast "回应: $CHATGPT_REPLY"

        # 清理临时文件
        rm -f "$BASE64_TEMP_FILE" "$JSON_TEMP_FILE"
    else
        # 如果没有新的截图，重复上一次的内容
        if [ -n "$LAST_REPLY" ]; then
            echo "ChatGPT 上一次回应: $LAST_REPLY"
            termux-toast "回应: $LAST_REPLY"
        fi
    fi

    # 等待 5 秒后继续循环
    sleep 5
done
