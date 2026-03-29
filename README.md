# VPS 一键初始化与环境部署脚本

这是一个用于全新 Linux VPS 的自动化 Shell 脚本。它能够帮助您快速完成系统更新、基础设置、网络优化、安全加固以及 Docker 环境的安装，省去繁琐的手动配置过程。

## 🌟 功能特性

本脚本采用模块化设计，运行过程中会进行交互式询问，您可以根据需求自由选择是否安装各项功能：

### 1. 基础配置
*   **更新系统组件**：自动识别包管理器并升级系统软件包 [1]。
*   **设置时区**：一键将系统时区更改为 `Asia/Shanghai` [1]。
*   **语言环境**：将系统默认语言设置为 `English (en_US.UTF-8)`，避免部分软件出现乱码 [1]。

### 2. 系统优化
*   **开启 BBR**：修改 sysctl 配置开启 BBR 拥塞控制算法，提升网络传输速度 [1]。
*   **配置 Swap 内存**：自动创建一个 2GB 的 Swap 交换文件，防止小内存机器因内存不足死机 [1]。
*   **优化 DNS 解析**：将默认 DNS 更改为 Google (8.8.8.8) 和 Cloudflare (1.1.1.1) 以加快解析速度 [1]。
*   **清理 Cloud-init**：卸载部分云厂商自带的 cloud-init 服务，加快机器开机速度 [1]。

### 3. 工具与环境安装
*   **常用工具**：自动安装 `vim`、`curl`、`git` 和 `command-not-found` [1]。
*   **Docker 环境**：调用官方一键脚本安装最新版 Docker 及 Docker Compose [1]。

### 4. 安全与终端美化
*   **防爆破**：安装并启动 `Fail2Ban`，有效防止 SSH 暴力破解 [1]。
*   **终端美化 (Zsh)**：自动安装 `zsh` 及 `oh-my-zsh` 框架，默认配置 `ys` 主题，并集成自动补全 (`zsh-autosuggestions`) 和语法高亮 (`zsh-syntax-highlighting`) 插件 [1]。
*   **修改 SSH 端口**：自定义更改默认的 22 端口，并自动配置相应的防火墙（UFW/Firewalld）放行规则以增强安全性 [1]。

---

## 💻 支持的操作系统

脚本内置了系统检测功能，目前支持以下主流 Linux 发行版：
*   Ubuntu [1]
*   Debian [1]
*   CentOS [1]
*   Fedora [1]

---

## 🚀 使用方法

登录您的 VPS (建议使用 root 用户执行或具有 sudo 权限的用户)，在终端中运行以下命令：

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/您的用户名/您的仓库名/main/vps-init.sh

# 赋予执行权限并运行
bash vps-init.sh
```
*(注：请将上述链接中的 `您的用户名/您的仓库名` 替换为您实际的 GitHub 路径)*

---

## ⚠️ 注意事项与建议

1. **执行过程中的交互**：脚本运行期间会多次暂停，显示黄色的提示信息 `请输入 [Y/n]:` [1]。您可以根据自己服务器的实际需求输入 `y` 确认或 `n` 跳过。
2. **SSH 端口修改警告**：如果您在脚本运行过程中选择了修改 SSH 端口，**请务必记住您输入的新端口号**。脚本执行完毕后，强烈建议保持当前 SSH 终端不关闭，重新打开一个新的终端窗口，使用新端口尝试连接，验证成功后再关闭原窗口 [1]。
3. **Zsh 切换**：脚本配置完 Zsh 后，可能需要您重新连接 SSH 或注销重新登录才能看到终端美化效果。
4. **清理工作**：脚本在最后会自动执行系统清理命令（如 `apt autoremove` 和 `apt clean`）以释放磁盘空间 [1]。

























# vps-init   VPS 一键初始化脚本

# 快速使用

#在新 VPS 上以root用户执行:

curl -O https://raw.githubusercontent.com/iSunker/vps-init/main/vps-init.sh && curl -O https://raw.githubusercontent.com/iSunker/vps-init/main/create_admin.sh && bash vps-init.sh && bash create_admin.sh

功能特性
✅ 系统更新
✅ 时区设置(上海)
✅ BBR 加速
✅ 2GB Swap
✅ Docker & Docker Compose
✅ Fail2Ban 防护
✅ Oh-My-Zsh
