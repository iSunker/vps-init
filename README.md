# vps-init

# VPS 一键初始化脚本

# 快速使用

#在新 VPS 上以root用户执行:

#方法1：直接执行
curl -fsSL https://raw.githubusercontent.com/iSunker/vps-init/main/vps-init.sh | bash

#方法2：先下载再执行
curl -O https://raw.githubusercontent.com/iSunker/vps-init/main/vps-init.sh

chmod +x vps-init.sh

./vps-init.sh

#方法3：使用wget
wget -qO- https://raw.githubusercontent.com/iSunker/vps-init/main/vps-init.sh | bash

功能特性
✅ 系统更新
✅ 时区设置(上海)
✅ BBR 加速
✅ 2GB Swap
✅ Docker & Docker Compose
✅ Fail2Ban 防护
✅ Oh-My-Zsh



主要改动说明：

新增 create_admin_user() 函数：
询问用户是否创建管理员用户
输入用户名并验证
创建用户并设置密码
自动添加到 sudo/wheel 组
确保 sudo 已安装
提示用户测试新用户
新增 disable_root_login() 函数：
询问用户是否禁用 root 登录
显示重要警告信息
二次确认
备份 SSH 配置文件
修改 PermitRootLogin 为 no
验证配置文件语法
重启 SSH 服务
提供回滚指令
在 run_script() 中添加调用：
在 SSH 端口修改后、系统清理前执行
先创建用户，再禁用 root 登录（逻辑顺序）
