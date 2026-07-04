# ESurfingDialer Docker v1.21 离线部署教程

适用环境：

- iStoreOS / OpenWrt x86_64 软路由
- 已安装 Docker
- 已安装 Docker Compose 插件
- 校园网认证前无法访问公网的环境

本版本离线包已经内置 Docker 镜像，部署时不需要访问 Docker Hub、GitHub、Gradle 或 Maven。

## 1. 上传文件

把下面这个压缩包上传到软路由，例如上传到 `/tmp` 或 `/root`：

```text
ESurfingDialer-Itsuwarii-Docker-Fixed-v1.21.zip
```

## 2. 解压

进入你想放置程序的目录，例如：
```sh
mkdir -p /root/esurfing-dialer
cd /root/esurfing-dialer
unzip /tmp(root)/ESurfingDialer-Itsuwarii-Docker-Fixed-v1.21.zip
```

解压后目录里应该能看到：

```text
docker-compose.yml
install.sh
README.md
SHA256SUMS
images/esurfing-dialer-v1.21-amd64.tar.gz
```

## 3. 检查 Docker 和 Compose

检查 Docker：

```sh
docker version
```

检查 Docker Compose 插件：

```sh
docker compose version
```

如果 `docker compose version` 能输出版本号，就可以继续。

如果提示：

```text
docker: 'compose' is not a docker command
```

说明当前系统没有 Docker Compose 插件，需要先在 iStoreOS / OpenWrt 里安装 Compose 插件，或后续改用兼容 `docker run` 的部署方式。

## 4. 一键安装

在解压目录执行：

```sh
sh install.sh
```

脚本会自动完成：

- 检测 CPU 架构
- 检查 Docker 和 Docker Compose
- 导入本地离线镜像
- 交互式输入校园网账号和密码
- 生成 `.env`
- 创建 `data` 目录
- 启动容器
- 输出日志和健康状态

## 5. 手动安装方式

如果不想用 `install.sh`，可以手动执行。

导入离线镜像：

```sh
gzip -dc images/esurfing-dialer-v1.21-amd64.tar.gz | docker load
```

复制配置文件：

```sh
cp .env.example .env
vi .env
```

至少填写：

```dotenv
DIALER_USER=你的校园网账号
DIALER_PASSWORD=你的校园网密码
```

启动容器：

```sh
docker compose up -d --no-build --pull never
```

这里的参数含义：

- `--no-build`：不构建镜像，不运行 Gradle
- `--pull never`：不从 Docker Hub 拉取镜像
- 只使用本地已经导入的离线镜像

## 6. 查看运行状态

查看容器：

```sh
docker ps
```

查看日志：

```sh
docker logs --tail 100 ESurfingDialer
```

查看健康状态：

```sh
cat data/health.json
```

正常认证后，`health.json` 里应该能看到：

```json
"authenticated": true
```

## 7. 日志保存位置

v1.21 会把运行日志保存到：

```text
data/logs/
```

默认保留 3 天日志，超过 3 天的 `dialer-*.log` 会自动删除。

查看日志文件：

```sh
ls -lh data/logs
```

## 8. 升级注意事项

升级时必须保留：

```text
.env
data/device-state.json
```

不要执行：

```sh
docker compose down -v
docker system prune -a
```

不要删除：

```text
data/device-state.json
```

这个文件保存稳定设备身份。删除后，校园网认证系统可能把设备识别为新设备。

## 9. 常见问题

### 9.1 提示 DIALER_USER is required

说明 `.env` 没有正确填写账号。

检查：

```sh
cat .env
```

确认存在：

```dotenv
DIALER_USER=你的账号
DIALER_PASSWORD=你的密码
```

### 9.2 容器一直 unhealthy

查看日志：

```sh
docker logs --tail 200 ESurfingDialer
cat data/health.json
```

重点看是否有：

```text
LOGIN_SUCCESS
HEARTBEAT_SUCCESS
```

### 9.3 x86_64 软路由不要强制 Dynarmic

v1.21 默认：

```dotenv
DIALER_BACKEND=auto
```

x86_64 下不会强制启用 Dynarmic。

如果需要明确禁用 Dynarmic，可以在 `.env` 里设置：

```dotenv
DIALER_BACKEND=unicorn2
```

修改后重启：

```sh
docker compose up -d --no-build --pull never
```

