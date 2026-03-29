#!/bin/bash
set -e

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

detect_distribution() {
    local supported_distributions=("ubuntu" "debian" "centos" "fedora")
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "${ID}" = "ubuntu" || "${ID}" = "debian" || "${ID}" = "centos" || "${ID}" = "fedora" ]]; then
            PM="apt"
            [ "${ID}" = "centos" ] && PM="yum"
            [ "${ID}" = "fedora" ] && PM="dnf"
            log_info "检测到系统:${ID} (包管理器:${PM})"
        else
            log_error "不支持的系统类型:${ID}"
            exit 1
        fi
    else
        log_error "无法检测系统类型:/etc/os-release 文件不存在"
        exit 1
    fi
}

# 更新组件,包管理
update_system() {
    log_info "开始更新系统..."
    if [ "${PM}" = "apt" ]; then
        apt update
        apt upgrade --only-upgrade -y
    elif [ "${PM}" = "yum" ]; then
        yum update -y
    fi
    log_info "系统更新完成"
}

# 询问函数
ask_user() {
    local tool_name=$1
    local description=$2
    echo -e "${YELLOW}是否${tool_name}?${NC}"
    [ ! -z "$description" ] && echo -e "${YELLOW}描述:${description}${NC}"
    read -p "请输入 [Y/n]: " choice
    case "$choice" in
        [nN][oO] | [nN])
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

install_tool() {
    local name=$1
    local description=$2
    if command -v "${name}" &>/dev/null; then
        log_info "${name} 已安装"
        return 0
    fi
    if ask_user "安装 ${name}" "${description}"; then
        log_warn "${name} 未安装,正在安装..."
        ${PM} install -y "${name}"
        if [ $? -eq 0 ]; then
            log_info "${name} 安装成功"
        else
            log_error "${name} 安装失败"
            exit 1
        fi
    else
        log_info "跳过安装 ${name}"
    fi
}

install_tool_no_ask() {
    local name=$1
    if command -v "${name}" &>/dev/null; then
        log_info "${name} 已安装"
        return 0
    fi
    log_warn "${name} 未安装,正在安装..."
    ${PM} install -y "${name}"
    if [ $? -eq 0 ]; then
        log_info "${name} 安装成功"
    else
        log_error "${name} 安装失败"
        exit 1
    fi
}

# --- 功能函数区 ---

set_timezone() {
    if ask_user "设置时区为上海时间" "将系统时区修改为 Asia/Shanghai"; then
        log_info "正在设置时区..."
        if command -v timedatectl >/dev/null; then
            timedatectl set-timezone Asia/Shanghai
        else
            ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
        fi
        log_info "时区已设置为:$(date)"
    else
        log_info "跳过时区设置"
    fi
}

set_language() {
    if ask_user "设置系统语言为英语" "将系统语言修改为 English (en_US.UTF-8)"; then
        log_info "正在设置语言环境..."
        if [ "${PM}" = "apt" ]; then
            if ! command -v locale-gen >/dev/null; then
                apt install -y locales
            fi
            if [ -f /etc/locale.gen ]; then
                sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
                locale-gen
            else
                locale-gen en_US.UTF-8
            fi
        fi
        if command -v localectl >/dev/null; then
            localectl set-locale LANG=en_US.UTF-8
        else
            echo "LANG=en_US.UTF-8" | tee /etc/locale.conf
            echo "LC_ALL=en_US.UTF-8" | tee -a /etc/locale.conf
            if [ -f /etc/default/locale ]; then
                echo "LANG=en_US.UTF-8" | tee /etc/default/locale
            fi
        fi
        log_info "语言设置已更新"
    else
        log_info "跳过语言设置"
    fi
}

enable_bbr() {
    if ask_user "开启 BBR" "拥塞控制算法,提升网络速度"; then
        log_info "正在检查并配置 BBR..."
        local sysctl_conf="/etc/sysctl.conf"

        if grep -q "net.core.default_qdisc=fq" "$sysctl_conf" && grep -q "net.ipv4.tcp_congestion_control=bbr" "$sysctl_conf"; then
            log_info "BBR 配置已存在于 $sysctl_conf"
        else
            cp "$sysctl_conf" "${sysctl_conf}.backup.$(date +%Y%m%d_%H%M%S)"
            if ! grep -q "net.core.default_qdisc=fq" "$sysctl_conf"; then
                echo "net.core.default_qdisc=fq" >> "$sysctl_conf"
            fi
            if ! grep -q "net.ipv4.tcp_congestion_control=bbr" "$sysctl_conf"; then
                echo "net.ipv4.tcp_congestion_control=bbr" >> "$sysctl_conf"
            fi
            sysctl -p
            log_info "BBR 已开启"
        fi
    fi
}

configure_swap() {
    if ask_user "增加 2GB Swap" "虚拟内存,防止小内存机器死机"; then
        log_info "正在配置 Swap..."
        if [ ! -f /swapfile ]; then
            fallocate -l 2G /swapfile
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            if ! grep -q "/swapfile" /etc/fstab; then
                echo '/swapfile none swap sw 0 0' >> /etc/fstab
            fi
            log_info "Swap 创建成功"
            free -h
        else
            log_info "Swap 文件已存在,跳过"
            free -h
        fi
    fi
}

optimize_dns() {
    if ask_user "优化 DNS 解析" "使用 Google (8.8.8.8) 和 Cloudflare (1.1.1.1) DNS"; then
        log_info "正在优化 DNS..."
        [ -f /etc/resolv.conf ] && cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 1.1.1.1" >> /etc/resolv.conf
        log_info "DNS 已更新"
    fi
}

install_fail2ban() {
    if ask_user "安装 Fail2Ban" "防止 SSH 暴力破解"; then
        log_info "正在安装 Fail2Ban..."
        install_tool_no_ask "fail2ban"
        systemctl enable fail2ban
        systemctl start fail2ban
        log_info "Fail2Ban 安装并启动成功"
    fi
}

remove_cloud_init() {
    if ask_user "卸载 Cloud-init" "Netcup/VPS 镜像自带工具,装完系统后卸载可加快开机"; then
        log_info "正在清理 Cloud-init..."
        if [ "${PM}" = "apt" ]; then
            apt purge cloud-init -y
        elif [ "${PM}" = "yum" ] || [ "${PM}" = "dnf" ]; then
            ${PM} remove cloud-init -y
        fi
        rm -rf /etc/cloud /var/lib/cloud
        log_info "Cloud-init 清理完成"
    fi
}

# --- Docker 安装函数 ---
install_docker() {
    if command -v docker >/dev/null; then
        log_info "Docker 已安装,跳过"
        return 0
    fi

    if ask_user "安装 Docker & Docker Compose" "使用官方脚本一键安装,包含 Compose 插件"; then
        log_info "正在下载并运行 Docker 安装脚本..."

        # 确保 curl 已安装
        install_tool_no_ask "curl"

        # 使用官方脚本
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh

        # 清理脚本
        rm get-docker.sh

        # 启动 Docker
        log_info "启动 Docker 服务..."
        systemctl enable docker
        systemctl start docker

        if command -v docker >/dev/null; then
            log_info "Docker 安装成功!"
            log_info "Docker 版本:$(docker --version)"
            log_info "Compose 版本:$(docker compose version)"
        else
            log_error "Docker 安装似乎失败了,请检查网络或日志"
            exit 1
        fi
    else
        log_info "跳过 Docker 安装"
    fi
}

system_cleanup() {
    log_info "正在执行系统清理..."
    if [ "${PM}" = "apt" ]; then
        apt autoremove -y
        apt clean
    elif [ "${PM}" = "yum" ] || [ "${PM}" = "dnf" ]; then
        ${PM} autoremove -y
        ${PM} clean all
    fi
    log_info "系统清理完成"
}

config_zsh() {
    log_info "配置 zsh 主题"
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"ys\"/g" ~/.zshrc
    install_tool_no_ask "git"
    log_info "安装 oh-my-zsh 插件..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions 2>/dev/null || log_warn "插件目录可能已存在"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting 2>/dev/null || log_warn "插件目录可能已存在"
    log_info "配置 zshrc 文件"
    sed -i "s/^plugins=.*/plugins=(git z wd extract zsh-autosuggestions zsh-syntax-highlighting command-not-found)/g" ~/.zshrc
    if ! grep -q "/usr/bin/zsh" /etc/shells; then
        echo "/usr/bin/zsh" >>/etc/shells
    fi
    log_info "设置 zsh 为默认 shell"
    chsh -s $(which zsh)
    log_info "zsh 配置完成"
}

install_oh_my_zsh() {
    log_info "开始安装 oh-my-zsh..."
    if [ -d ~/.oh-my-zsh ]; then
        log_warn "检测到已存在的 oh-my-zsh 安装,正在删除..."
        rm -rf ~/.oh-my-zsh
    fi
    [ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
    config_zsh
    log_info "oh-my-zsh 安装完成"
}

change_ssh_port() {
    if [ ! -f /etc/ssh/sshd_config ]; then
        log_error "/etc/ssh/sshd_config 文件不存在"
        return
    fi
    if ask_user "修改 ssh 端口号" "修改 SSH 默认 22 端口增强安全性"; then
        read -p "请输入新的 ssh 端口号(1024-65535): " SSH_PORT
        if [[ ! "${SSH_PORT}" =~ ^[0-9]+$ ]] || [ "${SSH_PORT}" -lt 1024 ] || [ "${SSH_PORT}" -gt 65535 ]; then
            log_error "输入的端口号不在 1024-65535 范围内"
            return
        fi
        local backup_file="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "备份配置文件到 ${backup_file}"
        cp /etc/ssh/sshd_config "${backup_file}"
        log_info "修改 ssh 端口号为 ${SSH_PORT}"
        sed -i "s/^#Port.*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
        sed -i "s/^Port.*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config

        if ! sshd -t; then
            log_error "SSH 配置文件语法检查失败,正在还原配置..."
            cp "${backup_file}" /etc/ssh/sshd_config
            return
        fi

        log_info "重启 ssh 服务"
        if ! systemctl restart sshd; then
            log_error "SSH 服务重启失败,还原配置..."
            cp "${backup_file}" /etc/ssh/sshd_config
            systemctl restart sshd
            return
        fi

        log_info "SSH 端口修改成功,请确保使用新端口 ${SSH_PORT} 连接"
        log_warn "建议保持当前连接,新开一个终端验证新端口是否可用"
        configure_firewall "${SSH_PORT}"
    fi
}

configure_firewall() {
    local port=$1
    if [ -z "$port" ]; then return; fi
    log_info "正在配置防火墙放行端口 ${port}..."
    case "${ID}" in
        "ubuntu" | "debian")
            if ! command -v ufw >/dev/null; then
                log_warn "未检测到 ufw,正在安装..."
                ${PM} install -y ufw
            fi
            ufw allow "${port}"/tcp
            ;;
        "centos" | "fedora")
            if ! command -v firewall-cmd >/dev/null; then
                log_warn "未检测到 firewalld,正在安装..."
                ${PM} install -y firewalld
                systemctl enable firewalld
                systemctl start firewalld
            fi
            firewall-cmd --permanent --add-port="${port}"/tcp
            firewall-cmd --reload
            ;;
        *)
            log_warn "未知的系统类型,请手动配置防火墙规则"
            ;;
    esac
    log_info "防火墙规则配置尝试完成"
}

run_script() {
    log_info "开始运行脚本..."
    detect_distribution
    update_system

    # 基础配置
    set_timezone
    set_language

    # 系统优化
    enable_bbr
    configure_swap
    optimize_dns
    remove_cloud_init

    # 工具安装
    install_tool "vim" "强大的文本编辑器"
    install_tool "command-not-found" "命令建议工具"
    install_tool "curl" "命令行文件传输工具"
    install_tool "git" "分布式版本控制系统"

    # Docker 安装
    install_docker

    # 安全配置
    install_fail2ban

    # Shell 配置
    if install_tool "zsh" "功能强大的 shell"; then
        if ask_user "oh-my-zsh" "zsh 的配置框架,提供主题和插件支持"; then
            install_oh_my_zsh
        fi
    fi

    # 网络与安全
    change_ssh_port

    # 清理
    system_cleanup

    echo "=========================================="
    echo -e "${GREEN}🎉 所有优化及安装已完成!${NC}"
    echo "=========================================="
}

run_script
