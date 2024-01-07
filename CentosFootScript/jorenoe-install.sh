#!/bin/bash

# 检查是否存在yum
if command -v yum &> /dev/null; then
    echo "yum 已安装."
else
    echo "yum 未安装，正在安装..."
    sudo dnf install -y yum
fi

echo "欢迎使用JoreNoe 一键安装所需包"

# 提示用户选择要安装的软件
echo "请选择要安装的软件，将默认开启端口和开机启动："
echo "1. 安装 MySql（8）"
echo "2. 安装 SqlServer 2019"
echo "3. 安装 SqlServer 2017"
echo "4. 安装 Docker"
echo "5. 安装 Redis"
echo "6. 安装 nginx"
echo "7. 安装 nginx"

read -p "请输入数字 (1-7): " choice

# 处理用户选择
case $choice in
    1)
        echo "开始安装 MySql"
        echo "配置YUM 更新库"
        sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
        echo "**安装**Mysql8.x版本 yum库"
        sudo  rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-2.noarch.rpm
        echo "安装MySql"
        sudo yum -y install mysql-community-server
        echo "安装成功，启动MYSQL"
        sudo systemctl start mysqld
        echo "设置开机启动"
        sudo systemctl enable mysqld
        echo "检查运行状态"
        sudo systemctl status mysqld
        echo "开始设置密码"
        default_password=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
        read -p "请输入新的MySQL密码: " new_password
        mysql_secure_installation <<EOF

y
$default_password
$new_password
$new_password
y
y
y
y
EOF

        # 提示用户选择是否区分大小写
        echo "请选择是否区分大小写："
        echo "0. 表名大小写敏感"
        echo "1. 表名大小写不敏感"
        echo "2. 表名大小写敏感（在所有操作系统上）"

        read -p "请输入数字 (0-2): " case_sensitivity_choice

        # 处理用户选择
        case $case_sensitivity_choice in
            0)
                echo "设置 lower_case_table_names 为 0"
                sudo bash -c 'echo "lower_case_table_names=0" >> /etc/my.cnf'
                ;;
            1)
                echo "设置 lower_case_table_names 为 1"
                sudo bash -c 'echo "lower_case_table_names=1" >> /etc/my.cnf'
                ;;
            2)
                echo "设置 lower_case_table_names 为 2"
                sudo bash -c 'echo "lower_case_table_names=2" >> /etc/my.cnf'
                ;;
            *)
                echo "无效的选择. 默认设置 lower_case_table_names 为 1"
                sudo bash -c 'echo "lower_case_table_names=1" >> /etc/my.cnf'
                ;;
        esac

        echo "请选择密码强度级别："
        echo "1. 无密码策略要求"
        echo "2. 要求密码包含至少一个数字"
        echo "3. 要求密码包含至少一个小写字母"
        echo "4. 要求密码包含至少一个大写字母"
        echo "5. 要求密码包含至少一个特殊字符"
        echo "6. 要求密码长度至少为8个字符"
        read -p "请输入数字 (1-6): " strength_choice

        # 处理用户选择
        case $strength_choice in
            1)
                echo "设置密码强度为 无密码策略要求"
                sudo mysql -uroot -p"$new_password" -e "set global validate_password.policy=0;"
                ;;
            2)
                echo "设置密码强度为 要求密码包含至少一个数字"
                sudo mysql -uroot -p"$new_password" -e "set global validate_password.policy=1;"
                ;;
            3)
                echo "设置密码强度为 要求密码包含至少一个小写字母"
                sudo mysql -uroot -p"$new_password" -e "set global validate_password.policy=2;"
                ;;
            4)
                echo "设置密码强度为 要求密码包含至少一个大写字母"
                sudo mysql -uroot -p"$new_password" -e "set global validate_password.policy=3;"
                ;;
            5)
                echo "设置密码强度为 要求密码包含至少一个特殊字符"
                sudo mysql -uroot -p"$new_password" -e "set global validate_password.policy=4;"
                ;;
            6)
                echo "设置密码强度为 要求密码长度至少为8个字符"
                sudo mysql -uroot -p"$new_password" -e "set global validate_password.policy=5;"
                ;;
            *)
                echo "无效的选择. 默认密码强度设置为 无密码策略要求"
                sudo mysql -uroot -p"$new_password" -e "set global validate_password.policy=0;"
                ;;
        esac

        # 允许远程访问
        echo "允许远程访问在端口3306"
        sudo sed -i 's/bind-address.*/bind-address=0.0.0.0/' /etc/my.cnf
        sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
        sudo firewall-cmd --reload

        # 重启MySQL服务
        echo "重启MySQL服务"
        sudo systemctl restart mysqld

        echo "MySQL安装完成，并已设置密码、密码强度，允许远程访问。"

        ;;
    2)
        echo "开始安装 软件包2..."
        sudo yum install -y software_package2
        ;;
    3)
        echo "退出安装脚本."
        exit 0
        ;;
    *)
        echo "无效的选择. 退出安装脚本."
        exit 1
        ;;
esac

echo "安装完成！"
