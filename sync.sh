#!/bin/bash
set -e

# 阿里云镜像仓库配置（替换成你自己的）
REGISTRY="registry.cn-hangzhou.aliyuncs.com"
NAMESPACE="your-namespace"

# 统计成功和失败的镜像数量
success=0
failed=0

echo "===== 开始同步Docker镜像 ====="
echo "目标仓库: $REGISTRY/$NAMESPACE"
echo "=============================="

# 读取镜像列表，过滤注释和空行
grep -v '^#' images.txt | grep -v '^$' | while read -r image; do
    echo ""
    echo "===== 正在处理镜像: $image ====="
    
    # 拉取源镜像
    if docker pull "$image"; then
        echo "✅ 拉取成功: $image"
    else
        echo "❌ 拉取失败: $image"
        ((failed++))
        continue
    fi
    
    # 构建目标镜像名
    target_image="$REGISTRY/$NAMESPACE/$(echo "$image" | cut -d'/' -f2-)"
    
    # 打标签
    docker tag "$image" "$target_image"
    
    # 推送到目标仓库
    if docker push "$target_image"; then
        echo "✅ 推送成功: $target_image"
        ((success++))
    else
        echo "❌ 推送失败: $target_image"
        ((failed++))
    fi
    
    # 清理本地镜像（可选，节省空间）
    docker rmi "$image" "$target_image" > /dev/null 2>&1
done

echo ""
echo "===== 同步完成 ====="
echo "成功: $success 个"
echo "失败: $failed 个"
echo "===================="

# 只有当所有镜像都失败时才返回非零退出码
if [ $success -eq 0 ] && [ $failed -gt 0 ]; then
    echo "❌ 所有镜像同步失败！"
    exit 1
else
    echo "✅ 同步任务完成！"
    exit 0
fi
