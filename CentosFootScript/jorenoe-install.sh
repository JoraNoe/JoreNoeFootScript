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
echo "8. 完全删除 mysql"

read -p "请输入数字 (1-8): " choice

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

        # 设置密码 和 强度  
        echo "开始设置密码"
        default_password=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
        # 提示用户选择密码强度级别
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
                policy=0
                ;;
            2)
                policy=1
                ;;
            3)
                policy=2
                ;;
            4)
                policy=3
                ;;
            5)
                policy=4
                ;;
            6)
                policy=5
                ;;
            *)
                echo "无效的选择. 默认密码强度设置为 无密码策略要求"
                policy=0
                ;;
        esac

        read -p "选择密码长度 (6-32): " strength_choice

        # 处理用户选择
        case $strength_choice in
            6)
                size=6
                ;;
            8)
                size=8
                ;;
            32)
                size=32
                ;;
            *)
                echo "无效的选择. 默认密码强度设置为 6 "
                size=6
                ;;
        esac

        # 设置密码强度
        echo "设置密码长度为 $size"

        sudo mysql --connect-expired-password -uroot -p"$default_password" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'JoreNoe123$%^';SET GLOBAL validate_password.policy=$policy;set global validate_password.length=$size;flush privileges;"
        
        # 开启建表权限
        echo "开启建表权限"
        mysql -uroot -p"JoreNoe123$%^" -e "create user 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'JoreNoe123$%^';FLUSH PRIVILEGES;GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
        echo "建表权限已开启"

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

        
        # 设置新密码
        read -p "请输入新的MySQL密码: " new_password
        mysql -uroot -p"JoreNoe123$%^" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$new_password';"


        # 允许远程访问
        echo "允许远程访问在端口3306"
        sudo sed -i 's/bind-address.*/bind-address=0.0.0.0/' /etc/my.cnf
        sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
        sudo firewall-cmd --reload

        # 重启MySQL服务
        echo "重启MySQL服务"
        sudo systemctl restart mysqld

        echo "检查运行状态"
        sudo systemctl status mysqld

        echo "MySQL安装完成，并已设置密码、密码强度，允许远程访问。"
        echo "默认密码为：JoreNoe123$%^"

        ;;
    4)
        echo "开始安装 docker "
        sudo yum update
        sudo yum install -y docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo systemctl status docker
        echo "docker 安装成功并且开机启动"
        ;;
    2)
    echo "开始安装 sqlserver 2019  "
        sudo curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/7/mssql-server-2019.repo
        sudo yum install -y mssql-server
        sudo /opt/mssql/bin/mssql-conf setup
        systemctl status mssql-server
        sudo firewall-cmd --zone=public --add-port=1433/tcp --permanent
        sudo firewall-cmd --reload
        systemctl enable mssql-server.service
        ;;
    8)
        # 停止 MySQL 服务
        sudo systemctl stop mysqld

        # 卸载 MySQL 软件包
        sudo yum -y remove mysql-server mysql

        # 删除 MySQL 相关的文件和目录
        sudo rm -rf /var/lib/mysql
        sudo rm -rf /etc/my.cnf
        sudo rm -rf /etc/my.cnf.d
        sudo rm -rf /var/log/mysql

        # 删除 MySQL 用户和组
        sudo userdel mysql
        sudo groupdel mysql

        # 重新加载系统的 daemon
        sudo systemctl daemon-reload

        # 清理 yum 缓存
        sudo yum clean all

        sudo sed -i '/temporary password/d' /var/log/mysqld.log


        echo "MySQL 已经成功删除并清理。"

        ;;
    
    *)
        echo "无效的选择. 退出安装脚本."
        exit 1
        ;;
esac

echo "操作成功！"
