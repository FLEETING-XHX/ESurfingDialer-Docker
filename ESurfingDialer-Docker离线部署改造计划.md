# ESurfingDialer Docker 离线部署改造计划

## 1. 背景

当前 ESurfingDialer Docker 包在校园网首次部署场景下存在明显问题：用户重装软路由后，校园网认证前通常无法访问公网，但当前部署包仍依赖在线构建流程，会在 Docker 构建阶段尝试下载 Gradle、Maven 依赖、基础镜像或其他构建资源。

这个包的目标用户是 iStoreOS / OpenWrt 软路由环境中的普通用户，不能假设用户具备 Docker、Gradle、JDK、代理和网络排障能力。因此默认部署流程必须完全离线可用。

最终目标：

```text
上传离线包 -> 解压 -> 输入账号密码 -> 自动导入镜像 -> 启动容器 -> 完成校园网认证
```

首次部署过程不得要求用户临时安装代理、访问 Docker Hub、访问 GitHub、源码编译或手工修补镜像。

## 2. 参考项目

- https://github.com/liu23zhi/ESurfingDialerDocker
- https://github.com/Zhiuannnn/Docker_ESurfingDialer
- https://github.com/Itsuwarii/ESurfingDialer

重点参考旧版 Docker_ESurfingDialer 的离线镜像导入方式：

```sh
docker load < dialer.tar
```

## 3. 实际部署环境

- iStoreOS / OpenWrt x86_64 软路由
- 校园网认证前通常无法访问公网
- 用户可能只有 Web 管理界面和基础 SSH 能力
- 用户不应被要求安装 JDK、Gradle、Maven 或配置代理
- 用户不应被要求理解 Docker build 失败原因

## 4. 当前主要问题

### 4.1 部署包不是严格离线包

当前 `docker-compose.yml` 包含 `build:`：

```yaml
build:
  context: .
```

这会导致部署时执行源码构建。Dockerfile 中又包含：

```dockerfile
FROM gradle:8-jdk17 AS builder
RUN gradle clean shadowJar --no-daemon
```

在校园网未认证前，这一步无法可靠访问 Docker Hub、Gradle Distribution、Maven Central、JitPack 等网络资源。

### 4.2 在线版和离线版混在一起

当前同一个 compose 文件既承担用户部署，又承担开发构建，导致普通用户很容易在无网络环境触发 `docker build`。

### 4.3 x86_64 环境强制启用 Dynarmic

当前 `docker/entrypoint.sh` 固定传入 `-d`：

```sh
java ... -jar /app/client.jar ... -d
```

这会强制启用 Dynarmic。在 x86_64 软路由上可能触发 `UnsatisfiedLinkError` 或原生库不兼容问题。默认策略应改为自动选择后端，Dynarmic 不应作为 x86_64 默认后端。

### 4.4 脚本权限可能丢失

ZIP 解压、Windows 编辑或重新打包后，`entrypoint.sh`、`healthcheck.sh` 等脚本可能失去可执行权限，导致容器启动时报 `permission denied`。

### 4.5 缺少小白一键安装脚本

当前用户需要手工执行多步命令：

- 解压
- 创建 `.env`
- 填写账号密码
- 构建或导入镜像
- 启动 compose
- 查看日志

这些步骤对普通用户不友好，也不适合校园网无网络首次部署。

### 4.6 健康检查错误提示不够明确

健康检查失败时不能只返回 `Exit=1`。需要说明失败原因，例如账号密码缺失、`health.json` 不存在、尚未认证成功、心跳过期、原生库不兼容等。

### 4.7 JDK 版本说明不一致风险

当前修改版实际使用 JDK 17：

- Dockerfile: `gradle:8-jdk17`
- Runtime: `eclipse-temurin:17-jre-alpine`
- Gradle toolchain: `jvmToolchain(17)`

如果上游或文档提到 JDK 21，需要确认是否有意降级，并统一 Dockerfile、Gradle toolchain 和 README。

## 5. 改造目标

### 5.1 必须提供真正的离线部署包

发布物必须包含预构建 Docker 镜像：

```text
esurfing-dialer-vX.Y-amd64.tar.gz
esurfing-dialer-vX.Y-arm64.tar.gz
```

用户首次部署只需要：

```sh
docker load
docker compose up -d --no-build --pull never
```

默认部署流程不能依赖：

- Docker Hub
- GitHub
- Gradle
- Maven Central
- JitPack
- 在线基础镜像拉取

### 5.2 在线构建版与离线部署版分开

需要拆分为两个 Compose 文件：

```text
docker-compose.yml
docker-compose.build.yml
```

`docker-compose.yml` 只用于普通用户部署，必须只使用预构建镜像，不包含 `build:`。

`docker-compose.build.yml` 仅供开发者源码构建。

### 5.3 默认不启用 Dynarmic

默认后端策略：

- x86_64: 默认 Unicorn2
- arm64 / aarch64: 可以尝试 Dynarmic
- Dynarmic 初始化失败时自动回退 Unicorn2
- 用户可通过环境变量手动指定后端

建议环境变量：

```dotenv
DIALER_BACKEND=auto
```

可选值：

```text
auto
unicorn2
dynarmic
```

### 5.4 提供小白安装脚本

理想安装命令：

```sh
sh install.sh
```

脚本负责：

- 检测 CPU 架构
- 检测 Docker
- 检测 Docker Compose
- 检测磁盘空间
- 交互式输入账号密码
- 生成 `.env`
- 导入本地镜像
- 创建 `data` 目录
- 启动容器
- 检查健康状态和日志

### 5.5 保留设备身份和配置

升级时必须保留：

```text
.env
data/device-state.json
```

安装脚本和文档必须明确：

- 不默认删除 `data`
- 不执行 `docker compose down -v`
- 不执行 `docker system prune -a`
- 不默认删除 `device-state.json`

### 5.6 改进健康检查和错误提示

健康检查失败时输出明确原因：

```text
UNHEALTHY: /data/health.json not found
UNHEALTHY: authentication has not succeeded yet
UNHEALTHY: last heartbeat is older than 300 seconds
UNHEALTHY: DIALER_USER or DIALER_PASSWORD missing
UNHEALTHY: WAN address or portal redirect was not detected
UNHEALTHY: native backend failed, try DIALER_BACKEND=unicorn2
```

`health.json` 建议增加字段：

```json
{
  "status": "authenticated",
  "reason": "ok",
  "backend": "unicorn2",
  "arch": "x86_64",
  "lastLoginSuccessAt": 0,
  "lastHeartbeatSuccessAt": 0
}
```

## 6. 目标发布物结构

GitHub Release 建议同时发布：

```text
esurfing-dialer-vX.Y-amd64.tar.gz
esurfing-dialer-vX.Y-arm64.tar.gz
offline-install-amd64.zip
offline-install-arm64.zip
SHA256SUMS
source-code.zip
```

其中 `offline-install-amd64.zip` 建议结构：

```text
ESurfingDialer-Docker/
  install.sh
  docker-compose.yml
  .env.example
  README.md
  images/
    esurfing-dialer-vX.Y-amd64.tar.gz
```

`offline-install-arm64.zip` 同理，只替换镜像文件。

## 7. 具体实施计划

### 阶段 1：拆分 Compose 文件

修改 `docker-compose.yml` 为离线部署专用文件：

```yaml
services:
  esurfing-dialer:
    image: esurfing-dialer:X.Y
    container_name: ESurfingDialer
    network_mode: host
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - ./data:/data
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

新增 `docker-compose.build.yml`：

```yaml
services:
  esurfing-dialer:
    build:
      context: .
    image: esurfing-dialer:X.Y
```

普通用户启动命令固定为：

```sh
docker compose up -d --no-build --pull never
```

### 阶段 2：生成离线镜像

有网构建环境中分别构建 amd64 和 arm64。

amd64：

```sh
docker buildx build --platform linux/amd64 -t esurfing-dialer:X.Y-amd64 --load .
docker save esurfing-dialer:X.Y-amd64 | gzip > esurfing-dialer-vX.Y-amd64.tar.gz
```

arm64：

```sh
docker buildx build --platform linux/arm64 -t esurfing-dialer:X.Y-arm64 --load .
docker save esurfing-dialer:X.Y-arm64 | gzip > esurfing-dialer-vX.Y-arm64.tar.gz
```

后续可通过 GitHub Actions 自动生成并上传 Release。

### 阶段 3：修复 Dynarmic 后端选择

修改 `entrypoint.sh`：

- 删除固定 `-d`
- 根据 `DIALER_BACKEND` 和 `uname -m` 选择参数
- 默认 `DIALER_BACKEND=auto`
- x86_64 默认不加 `-d`
- arm64 / aarch64 可尝试 `-d`

修改 Kotlin 初始化逻辑：

- Dynarmic 初始化失败时捕获异常
- 记录错误原因
- 自动回退 Unicorn2
- 将实际后端写入 `health.json`

### 阶段 4：修复脚本权限

Dockerfile 改为：

```dockerfile
COPY --chmod=755 docker/entrypoint.sh /app/entrypoint.sh
COPY --chmod=755 docker/healthcheck.sh /app/healthcheck.sh
```

如果安装脚本也进入镜像或发布包，应确保：

```sh
chmod +x install.sh
```

并在 ZIP 打包流程中保留权限。

### 阶段 5：新增 install.sh

`install.sh` 逻辑：

1. 检测架构：

```sh
arch="$(uname -m)"
```

映射规则：

```text
x86_64 -> amd64
aarch64 -> arm64
arm64 -> arm64
```

2. 检测 Docker：

```sh
docker version
```

3. 检测 Compose：

```sh
docker compose version
```

4. 检测磁盘空间：

至少建议预留 1GB。

5. 检测本地镜像包：

```text
images/esurfing-dialer-vX.Y-amd64.tar.gz
images/esurfing-dialer-vX.Y-arm64.tar.gz
```

6. 交互式生成 `.env`：

```dotenv
DIALER_USER=...
DIALER_PASSWORD=...
DIALER_BACKEND=auto
```

7. 保留已有配置：

- `.env` 已存在时询问是否覆盖
- `data/device-state.json` 已存在时提示保留

8. 导入镜像：

```sh
gzip -dc images/esurfing-dialer-vX.Y-amd64.tar.gz | docker load
```

9. 启动容器：

```sh
docker compose up -d --no-build --pull never
```

10. 输出诊断：

```sh
docker ps
docker logs --tail 100 ESurfingDialer
cat data/health.json
```

### 阶段 6：健康检查增强

修改 `healthcheck.sh`：

- 每个失败分支输出明确原因到 stderr
- 检查 `health.json` 是否存在
- 检查 `authenticated`
- 检查最近心跳时间
- 检查后端初始化错误
- 检查账号密码缺失

修改 `HealthStatus.kt`：

- 增加 `status`
- 增加 `reason`
- 增加 `backend`
- 增加 `arch`
- 增加 `lastFatalError`

### 阶段 7：统一 JDK 版本

确认当前 fork 是否继续使用 JDK 17。

如果继续使用 JDK 17，则统一：

```text
Dockerfile
build.gradle.kts
README.md
CHANGELOG.md
Release notes
```

明确说明：

```text
This Docker fork intentionally builds and runs on JDK 17.
```

如果需要回到 JDK 21，则统一升级：

```text
gradle:8-jdk21
eclipse-temurin:21-jre-alpine
jvmToolchain(21)
```

不要让文档和实际构建版本不一致。

### 阶段 8：自动化发布

新增发布脚本或 GitHub Actions：

```text
build amd64 image
build arm64 image
docker save + gzip
assemble offline-install-amd64.zip
assemble offline-install-arm64.zip
generate SHA256SUMS
upload release artifacts
```

可选同时发布 Docker Hub 镜像，但 Docker Hub 不能作为校园网首次部署的唯一方式。

## 8. 验收标准

### 8.1 无公网部署验收

在无法访问公网的 iStoreOS / OpenWrt 环境中：

```sh
unzip offline-install-amd64.zip
cd ESurfingDialer-Docker
sh install.sh
```

应能完成：

- 导入本地镜像
- 创建 `.env`
- 创建 `data`
- 启动容器
- 完成认证

整个过程不得访问 Docker Hub、GitHub、Gradle、Maven。

### 8.2 x86_64 后端验收

x86_64 环境默认不应启用 Dynarmic。

日志中应能看出实际后端，例如：

```text
BACKEND_SELECTED backend=unicorn2 arch=x86_64
```

不得出现因 Dynarmic native 库导致的主线程崩溃。

### 8.3 配置保留验收

升级前已有：

```text
.env
data/device-state.json
```

升级后必须仍然存在，且安装脚本不得默认覆盖或删除。

### 8.4 健康检查验收

异常状态下，`docker inspect` 或手工执行 healthcheck 能看到明确失败原因，而不是只有 `Exit=1`。

### 8.5 发布物验收

Release 必须包含：

```text
esurfing-dialer-vX.Y-amd64.tar.gz
esurfing-dialer-vX.Y-arm64.tar.gz
offline-install-amd64.zip
offline-install-arm64.zip
SHA256SUMS
```

## 9. 优先级

### P0

- 拆分 `docker-compose.yml` 和 `docker-compose.build.yml`
- 默认部署禁用 build / pull
- 生成 amd64 离线镜像 tar.gz
- 新增 `install.sh`
- 去掉 entrypoint 默认 `-d`

### P1

- 生成 arm64 离线镜像 tar.gz
- Dynarmic 失败自动回退 Unicorn2
- 健康检查输出明确错误原因
- 保留 `.env` 和 `data/device-state.json`

### P2

- GitHub Actions 自动发布
- SHA256SUMS
- Docker Hub 可选发布
- README 和 Release notes 完整整理

## 10. 风险与注意事项

- 不要把源码构建流程作为默认部署路径。
- 不要在用户环境执行 `docker compose down -v`。
- 不要默认删除 `data`。
- 不要默认删除 `device-state.json`。
- 不要让安装脚本依赖 Bash 特性，OpenWrt 上优先使用 POSIX `sh`。
- 不要假设有 `curl`、`wget`、`jq`、`python`。
- 不要假设用户可以访问 Docker Hub。
- 不要假设用户可以访问 GitHub。
- 不要假设用户能理解 Gradle 或 Maven 报错。

