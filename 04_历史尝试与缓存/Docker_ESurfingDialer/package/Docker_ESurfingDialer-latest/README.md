# Docker_ESurfingDialer
Docker image of ESurfingDialer(A java programme for GuangDong Telecom School)
广东电信天翼校园zsm验证docker镜像,源码 @Rsplwe https://github.com/Rsplwe/ESurfingDialer ，基于大佬的jar导出的懒人docker映像，直接食用即可。
###命令行用法 （图形界面请直接导入）： 
1.
```
docker load < dialer.tar
```
 
  例： docker load < /tmp/dialer.tar

2.
```
docker run -itd --network host --name ESurfingDialer -restart=always -e DIALER_USER=这几个中文改成你的账号 -e DIALER_PASSWORD=改成你的密码
```
