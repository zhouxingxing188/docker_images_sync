#!/bin/bash

# 阿里云镜像仓库配置（已替换为你的真实命名空间）
REGISTRY="registry.cn-hangzhou.aliyuncs.com"
NAMESPACE="my_docker_zxy"

# 统计成功和失败的镜像数量
success=0
failed=0

echo "===== 开始同步Docker镜像 ====="
echo "目标仓库: $REGISTRY/$NAMESPACE"
echo "=============================="

# 读取镜像列表，过滤注释和空行（核心修复）
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
    
    # 构建目标镜像名（自动处理带组织前缀的镜像）
    if [[ "$image" == */* ]]; then
        target_image="$REGISTRY/$NAMESPACE/$(echo "$image" | cut -d'/' -f2-)"
    else
        target_image="$REGISTRY/$NAMESPACE/$image"
    fi
    
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
    
    # 清理本地镜像，节省空间
    docker rmi "$image" "$target_image" > /dev/null 2>&1
done

echo ""
echo "===== 同步任务完成 ====="
echo "✅ 成功: $success 个"
echo "❌ 失败: $failed 个"
echo "========================"

# 只要有一个镜像成功，就返回成功状态码
if [ $success -gt 0 ]; then
    echo "✅ 同步任务完成！"
    exit 0
else
    echo "❌ 所有镜像同步失败！"
    exit 1
fi
