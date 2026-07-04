# ESurfingDialer GitHub 发布方案

## 推荐仓库结构

建议使用 3 个公开仓库：

```text
ESurfingDialer
ESurfingDialer-Docker
ESurfingDialer-Windows-Client
```

其中：

- `ESurfingDialer`：总入口页，只放介绍和跳转链接。
- `ESurfingDialer-Docker`：维护 iStoreOS / OpenWrt 软路由 Docker 离线版。
- `ESurfingDialer-Windows-Client`：维护 Windows 客户端版。

这样学生只需要打开总入口仓库，就能选择适合自己的方式。

## 总入口 README 建议

`ESurfingDialer` 仓库的 README 可以写成：

```md
# ESurfingDialer 天翼校园网认证工具

本项目整理了天翼校园网认证的两种使用方式。

## 选择你的使用方式

### 1. 软路由 / iStoreOS / OpenWrt 用户

使用 Docker 离线部署版：

[进入 ESurfingDialer-Docker](https://github.com/YOUR_NAME/ESurfingDialer-Docker)

适合：

- iStoreOS / OpenWrt x86_64 软路由
- 校园网认证前无法访问公网
- 希望上传离线包后直接部署

推荐下载 Release 里的：

```text
ESurfingDialer-Itsuwarii-Docker-Fixed-v1.21.zip
```

### 2. Windows 用户

使用 Windows 客户端版：

[进入 ESurfingDialer-Windows-Client](https://github.com/YOUR_NAME/ESurfingDialer-Windows-Client)

适合：

- Windows 电脑
- 不使用软路由
- 希望安装图形化轻量客户端

推荐下载 Release 里的 Windows 安装包。

## 说明

本项目用于学习和个人网络环境自用。请遵守学校网络使用规范。
```

把 `YOUR_NAME` 替换成你的 GitHub 用户名。

## Docker 仓库 Release 文件

`ESurfingDialer-Docker` 的 GitHub Release 建议上传：

```text
ESurfingDialer-Itsuwarii-Docker-Fixed-v1.21.zip
ESurfingDialer-Docker-v1.21部署教程.md
```

当前本地路径：

```text
C:\Users\XHX CN\Documents\Project\ESurfingDialer-Docker\00_最终部署包\ESurfingDialer-Itsuwarii-Docker-Fixed-v1.21.zip
C:\Users\XHX CN\Documents\Project\ESurfingDialer-Docker\00_最终部署包\ESurfingDialer-Docker-v1.21部署教程.md
```

## Windows 客户端仓库 Release 文件

`ESurfingDialer-Windows-Client` 的 GitHub Release 建议上传最新安装包，例如：

```text
ESurfingDialer-Lite-v*.exe
```

当前本地项目路径：

```text
C:\Users\XHX CN\Documents\Project\ESurfingDialer-Windows-Client
```

## 推送到 GitHub 的命令

GitHub 上创建空仓库后，在本机执行：

Docker 仓库：

```sh
cd "C:\Users\XHX CN\Documents\Project\ESurfingDialer-Docker"
git remote add origin https://github.com/YOUR_NAME/ESurfingDialer-Docker.git
git branch -M main
git push -u origin main
```

Windows 客户端仓库：

```sh
cd "C:\Users\XHX CN\Documents\Project\ESurfingDialer-Windows-Client"
git remote add origin https://github.com/YOUR_NAME/ESurfingDialer-Windows-Client.git
git branch -M main
git push -u origin main
```

总入口仓库：

```sh
git clone https://github.com/YOUR_NAME/ESurfingDialer.git
cd ESurfingDialer
notepad README.md
git add README.md
git commit -m "Add project navigation"
git push
```

## 当前阻塞点

当前电脑没有安装 GitHub CLI：

```text
gh: The term 'gh' is not recognized
```

并且两个本地仓库暂时没有配置 GitHub remote。

需要先在 GitHub 网页创建仓库，或安装并登录 GitHub CLI 后再由 Codex 推送。

