# ESurfingDialer Docker v1.22 离线部署教程

适用环境：iStoreOS / OpenWrt x86_64 软路由，已安装 Docker 和 Docker Compose 插件。

v1.22 是针对“长时间运行后校园网掉认证、随后反复 LOGIN_SUCCESS / SESSION_RESET”的修复版。离线包内置 Docker 镜像，首次部署不需要访问 Docker Hub、GitHub、Gradle 或 Maven。

## 文件

上传这个压缩包到软路由：

```text
ESurfingDialer-Itsuwarii-Docker-Fixed-v1.22.zip
```

解压后会得到同名目录：

```text
ESurfingDialer-Itsuwarii-Docker-Fixed-v1.22/
```

主要文件：

```text
docker-compose.yml
install.sh
.env.example
SHA256SUMS
images/esurfing-dialer-v1.22-amd64.tar.gz
```

## 一键安装

```sh
unzip ESurfingDialer-Itsuwarii-Docker-Fixed-v1.22.zip
cd ESurfingDialer-Itsuwarii-Docker-Fixed-v1.22
sh install.sh
```

脚本会自动检测 CPU 架构、检查 Docker Compose、导入本地镜像、生成 `.env`、创建 `data` 目录并启动容器。

## 手动安装

```sh
gzip -dc images/esurfing-dialer-v1.22-amd64.tar.gz | docker load
cp .env.example .env
vi .env
docker compose up -d --no-build --pull never
```

`.env` 至少填写：

```dotenv
DIALER_USER=你的校园网账号
DIALER_PASSWORD=你的校园网密码
```

## v1.22 关键默认值

```dotenv
HEARTBEAT_INTERVAL_MAX_SECONDS=240
PORTAL_DETECTION_THRESHOLD=12
NETWORK_CHECK_INTERVAL_SECONDS=5
PORTAL_AUTH_FRESH_SECONDS=900
PORTAL_REAUTH_COOLDOWN_SECONDS=300
HEALTH_AUTH_MAX_AGE_SECONDS=900
LOG_RETENTION_DAYS=3
```

说明：

- `NETWORK_CHECK_INTERVAL_SECONDS=5`：网络探测仍然是 5 秒一次，不是 8 分钟一次。
- `HEARTBEAT_INTERVAL_MAX_SECONDS=240`：即使认证服务器返回 480 秒心跳间隔，本地也最多 240 秒发一次心跳。
- `PORTAL_AUTH_FRESH_SECONDS=900`：登录或心跳刚成功后的 15 分钟内，门户页探测不会立刻打断当前认证状态。
- `PORTAL_REAUTH_COOLDOWN_SECONDS=300`：避免掉认证恢复时反复重登。

## 升级注意

升级时保留：

```text
.env
data/device-state.json
```

不要执行：

```sh
docker compose down -v
docker system prune -a
```

不要删除 `data/device-state.json`。它保存稳定设备身份，删除后校园网可能把软路由识别为新设备。

## 查看状态

```sh
docker ps
docker logs --tail 120 ESurfingDialer
cat data/health.json
ls -lh data/logs
```

正常情况下日志里应能看到：

```text
LOGIN_SUCCESS
HEARTBEAT_SUCCESS
```

如果学校侧强制重新认证，v1.22 应避免进入高频 `LOGIN_SUCCESS -> SESSION_RESET` 风暴，并优先通过心跳失败和冷却后的重认证恢复。