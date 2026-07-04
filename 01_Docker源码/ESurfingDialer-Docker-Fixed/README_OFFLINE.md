# ESurfingDialer Docker v1.21 离线安装说明

本离线包用于 iStoreOS / OpenWrt 软路由首次校园网认证部署。默认流程不需要访问 Docker Hub、GitHub、Gradle 或 Maven。

## 一键安装

解压后进入目录，执行：

```sh
sh install.sh
```

脚本会自动：

- 检测 CPU 架构
- 检查 Docker 和 Docker Compose
- 导入本地镜像
- 交互式生成 `.env`
- 创建 `data` 目录
- 启动容器
- 输出日志和健康状态

## 手动安装

amd64 软路由：

```sh
gzip -dc images/esurfing-dialer-v1.21-amd64.tar.gz | docker load
cp .env.example .env
vi .env
docker compose up -d --no-build --pull never
```

`.env` 至少填写：

```dotenv
DIALER_USER=你的校园网账号
DIALER_PASSWORD=你的校园网密码
```

## 重要说明

- `docker-compose.yml` 是离线部署文件，不包含 `build`。
- 不要执行 `docker compose down -v`，否则可能删除持久化数据。
- 不要删除 `data/device-state.json`，它保存稳定设备身份。
- 默认 `DIALER_BACKEND=auto`，x86_64 不会强制启用 Dynarmic。
- 运行日志保存在 `data/logs/`，默认保留 3 天。

## 查看状态

```sh
docker ps
docker logs --tail 100 ESurfingDialer
cat data/health.json
ls -lh data/logs
```
