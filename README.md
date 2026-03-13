# Dockerized rep2

## [pen/docker-rep2 at px2c](https://github.com/pen/docker-rep2/tree/px2c)との違い
- PHP 8.5 (JIT有効)
- Alpine Linux 3.23
- Composer 2.9 ([composer.json](https://itest.5ch.net/egg/test/read.cgi/software/1740874866/77))
- [proxy2ch](https://codeberg.org/NanashiNoGombe/proxy2ch) Version 20260306 snapshot
- [2chproxy.pl](https://github.com/yama-natuki/2chproxy.pl)の削除
- Alpine Linux 3.20以降パッケージが無くなったH2Oをビルド

## docker-compose.yml
```yaml
services:
  rep2:
    restart: always
    image: ebith/rep2:latest
    volumes:
      - $PWD:/ext
    ports:
      - '10090:80'
    environment:
      PX2C_ACCEPT_CONNECT: 1
      PX2C_FORCE_HTTPS: 1
      PX2C_MANAGE_BBSCGI_COOKIES: 1
      PX2C_BBSCGI_FIX_TIMESTAMP: 1
      PX2C_BBSCGI_CONFIRMATION: skip
      PX2C_KEYSTORE: keystore.json
```

## 開発メモ
### [Multi-platform | Docker Docs](https://docs.docker.com/build/building/multi-platform/)
```sh
docker buildx build --platform linux/amd64,linux/arm64 -t rep2 . --load
docker save rep2:latest -o rep2.tar --platform=linux/arm64
docker load -i rep2.tar
```
