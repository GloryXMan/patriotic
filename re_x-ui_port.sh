#!/bin/bash

# 检查系统是否安装 sqlite3
if ! command -v sqlite3 &> /dev/null; then
    # 检查当前系统类型
    if [ -f "/etc/redhat-release" ]; then
        # CentOS 或 RHEL 系统，使用 yum 安装 sqlite3
        sudo yum install sqlite -y
    elif [ -f "/etc/debian_version" ]; then
        # Debian 或 Ubuntu 系统，使用 apt 安装 sqlite3
        sudo apt-get update
        sudo apt-get install sqlite3 -y
    else
        echo "在非 Debian / Ubuntu / CentOS 系统中运行本脚本，请先手动安装 sqlite3 ，本脚本不确保能够顺利执行。"
        exit 1
    fi
fi

# 读取 x-ui 数据库文件中的端口信息
readarray -t ids < <(sqlite3 /etc/x-ui/x-ui.db "SELECT id FROM inbounds ORDER BY id")
for id in "${ids[@]}"; do
    remark=$(sqlite3 /etc/x-ui/x-ui.db "SELECT remark FROM inbounds WHERE id='$id'")
    port=$(sqlite3 /etc/x-ui/x-ui.db "SELECT port FROM inbounds WHERE id='$id'")
    echo "ID: $id  Remark: $remark  Port: $port"
done

# 提示用户选择需要更改端口的 ID
echo "请选择你需更改端口的 ID"
read -r selected_id

# 提示用户输入修改后的端口号
echo "请输入新的端口号( Port范围：10000 - 65535 )"

# 检查新端口是否合法，如果不合法，提示用户重新输入
while true; do
    read -r new_port
    if ! [[ "$new_port" =~ ^(1[0-9]{4}|[2-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$ ]]; then
        echo "错误：端口号无效，请重新输入"
    else
        break
    fi
done

# 更新 x-ui 数据库文件中的端口信息
sqlite3 /etc/x-ui/x-ui.db "UPDATE inbounds SET port='$new_port' WHERE id='$selected_id'"
if [ $? -ne 0 ]; then
    echo "错误：更新端口失败，请重试或进入 x-ui 面板手动更新端口"
    exit 1
fi

# 显示修改后的端口信息
remark=$(sqlite3 /etc/x-ui/x-ui.db "SELECT remark FROM inbounds WHERE id='$selected_id'")
port=$(sqlite3 /etc/x-ui/x-ui.db "SELECT port FROM inbounds WHERE id='$selected_id'")
echo "ID: $selected_id  Remark: $remark  Port: $port"

# 重启 x-ui 服务
systemctl restart x-ui
echo "x-ui 面板与 xray 服务重启完成"

rm -rf re_x-ui_port.sh
