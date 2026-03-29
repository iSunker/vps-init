#!/bin/bash
# 移除 set -e 防止意外闪退

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 确认包管理器
if command -v apt-get >/dev/null; then
    PM="apt"
elif command -v yum >/dev/null; then
    PM="yum"
else
    log_error "不支持的系统"
    exit 1
fi

echo -e "${YELLOW}==============================================${NC}"
echo -e "${YELLOW}安全配置: 创建带有 sudo 权限的新管理员并禁用 root${NC}"
echo -e "${YELLOW}==============================================${NC}"

# 1. 获取输入（直接从当前终端 /dev/tty 读取，强制要求交互，防止被截断）
read -p "请输入新的管理员用户名: " ADMIN_USER < /dev/tty
if [ -z "$ADMIN_USER" ]; then
    log_error "用户名不能为空，操作取消。"
    exit 1
fi

read -s -p "请输入此用户的密码 (输入时不可见): " ADMIN_PASS < /dev/tty
echo "" # 换行
if [ -z "$ADMIN_PASS" ]; then
    log_error "密码不能为空，操作取消。"
    exit 1
fi

# 2. 创建用户
if id "$ADMIN_USER" &>/dev/null; then
    log_warn "用户 $ADMIN_USER 已存在,跳过创建步骤。"
else
    log_info "正在创建用户 $ADMIN_USER ..."
    useradd -m -s /bin/bash "$ADMIN_USER"
    
    # 静默设置密码
    echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd
    
    # 赋予管理员权限
    if [ "${PM}" = "apt" ]; then
        usermod -aG sudo "$ADMIN_USER"
    else
        usermod -aG wheel "$ADMIN_USER"
    fi
    log_info "管理员用户 $ADMIN_USER 创建成功，并已赋予 sudo 权限。"
fi

# 3. 禁用 root 远程登录
if [ -f /etc/ssh/sshd_config ]; then
    log_info "正在禁用 root 远程登录..."
    # 备份当前配置
    cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.root_backup.$(date +%Y%m%d_%H%M%S)"
    
    # 注释掉旧的并强制添加 no
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
    if ! grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
        echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    fi
    
    # 检查语法并重启 SSH
    if sshd -t; then
        systemctl restart sshd
        log_info "✅ root 远程登录已成功禁用!"
        log_info "下次使用 SSH 登录请使用账号: ${ADMIN_USER} 和您刚才设置的密码。"
        log_warn "【重要警告】请千万不要马上关闭当前窗口！请立刻新开一个 SSH 客户端终端，尝试用新用户 ${ADMIN_USER} 登录。确认能正常登录并可以使用 sudo -i 后，再关闭当前窗口！"
    else
        log_error "SSH 配置文件出现异常，正在为您还原旧配置..."
        cp "/etc/ssh/sshd_config.root_backup."* /etc/ssh/sshd_config
        systemctl restart sshd
    fi
fi
