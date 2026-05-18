#!/bin/bash
set -e

# 直接使用环境变量，不需要传参数
IMAGES_FILE="images.txt"
TARGET_REGISTRY="${DOCKER_REGISTRY}"
TARGET_NAMESPACE="${DOCKER_NS}"

# 检查文件是否存在
if [ ! -f "$IMAGES_FILE" ]; then
    echo "错误：文件 $IMAGES_FILE 不存在"
    exit 1
fi

failed_count=0
failed_images=""

while IFS= read -r image; do
    # 跳过空行
    if [ -z "$image" ]; then
        continue
    fi

    echo "===== 正在处理镜像: $image ====="

    # 拉取镜像
    set +e
    docker pull "$image"
    pull_status=$?
    set -e

    if [ $pull_status -ne 0 ]; then
        echo "Error: Failed to pull image $image, continuing..."
        failed_count=$((failed_count + 1))
        failed_images="$failed_images $image"
        continue
    fi

    # 解析镜像名称和标签
    name=$(echo "$image" | cut -d '/' -f2)
    tag=$(echo "$name" | cut -d ':' -f2)
    targetFullName="${TARGET_REGISTRY}/${TARGET_NAMESPACE}/${name}"

    # 打标签
    docker tag "$image" "$targetFullName"

    # 推送到阿里云
    set +e
    docker push "$targetFullName"
    push_status=$?
    set -e

    if [ $push_status -ne 0 ]; then
        echo "Error: Failed to push image $targetFullName, continuing..."
        failed_count=$((failed_count + 1))
        failed_images="$failed_images $image"
        continue
    fi

    echo "✅ 镜像 $image 同步完成！"
done < "$IMAGES_FILE"

if [ $failed_count -gt 0 ]; then
    echo "Error: Failed to sync $failed_count images: $failed_images"
    exit 1
fi

echo "🎉 所有镜像同步任务已成功完成！"
