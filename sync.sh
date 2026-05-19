#!/bin/bash

# 阿里云个人版镜像仓库配置
TARGET_REGISTRY="crpi-56o55jc2ceuxe2yn.cn-beijing.personal.cr.aliyuncs.com"
NAMESPACE="my_docker_zxy"

# 统计计数
success=0
failed=0

echo "===== 开始同步Docker镜像 ====="
echo "目标仓库: ${TARGET_REGISTRY}/${NAMESPACE}"
echo "=============================="

# 读取镜像列表，跳过注释与空行
grep -v '^#' images.txt | grep -v '^$' | while read -r image;do
    echo ""
    echo "===== 正在处理镜像: ${image} ====="

    # 拉取镜像
    if docker pull "${image}";then
        echo "✅ 拉取成功: ${image}"
    else
        echo "❌ 拉取失败: ${image}"
        ((failed++))
        continue
    fi

    # 拼接推送地址
    if [[ "${image}" == */* ]];then
        target_image="${TARGET_REGISTRY}/${NAMESPACE}/$(echo ${image} | cut -d'/' -f2-)"
    else
        target_image="${TARGET_REGISTRY}/${NAMESPACE}/${image}"
    fi

    # 打标签
    docker tag "${image}" "${target_image}"

    # 推送镜像
    if docker push "${target_image}";then
        echo "✅ 推送成功: ${target_image}"
        ((success++))
    else
        echo "❌ 推送失败: ${target_image}"
        ((failed++))
    fi

    # 清理本地镜像
    docker rmi "${image}" "${target_image}" > /dev/null 2>&1
done

echo ""
echo "===== 同步任务完成 ====="
echo "✅ 成功: ${success} 个"
echo "❌ 失败: ${failed} 个"
echo "========================"

# 执行状态判断
if [ $success -gt 0 ];then
    echo "✅ 同步任务完成！"
    exit 0
else
    echo "❌ 所有镜像同步失败！"
    exit 1
fi
