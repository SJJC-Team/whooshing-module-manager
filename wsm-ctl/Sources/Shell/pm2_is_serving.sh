# service_name

set -e
echo $service_name
# 解析 pm2 jlist 的 JSON 输出，检查服务是否存在且状态为 online
pm2 jlist | jq -e ".[] | select(.name==\"$service_name\" and .pm2_env.status==\"online\")" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    exit 0  # 服务在运行
else
    exit 1  # 服务未运行
fi