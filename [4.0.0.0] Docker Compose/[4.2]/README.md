#### [4.2.0.0] 도커 컴포즈 설치
리눅스에서는 다음 명령어로 도커 컴포즈를 설치할 수 있음.
```
# docker compose 1.11 버전
curl -L https://github.com/docker/compose/releases/download/1.11.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose

# 권한 변경
chmod +x /usr/local/bin/docker-compose

# 버전 확인
docker-compose -v
```




