# vps-init

# VPS 一键初始化脚本

# 快速使用

#在新 VPS 上以root用户执行:

#正确的执行方法
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
