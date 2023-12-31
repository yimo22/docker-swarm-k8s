# docker-swarm-k8s
Studying for Docker, Docker Swarm, k8s


#### [2.2.7.2] 도커 네트워크 기능
네트워크 종류
- Native Driver
  - Bridge
  - Host
  - None
  - Overlay
- Remote Drivers (3rd-party plugins)

네트워크 동작 방식에 따라 드라이버 분류
- Single Host
  - bridge
    - 포트를 연결해 port를 외부에 노출하는 방식
  - host
    - 도커가 제공하는 가상네트워크(veth)를 사용하는 것이 아니라 직접 host 네트워크에 붙어서 사용하는 개념
  - none
    - 해당 컨테이너가 네트워크 기능이 필요없을 때, 또는 커스텀 네트워킹을 사용해야 하는 경우가 있을 때 
- Multi Host
  - overlay



#### [2.5.4.1] 도커 데몬 디버그 모드

<h1> 도커 데몬의 로그수집 </h1>
-   많은 수의 도커 서버를 효율적으로 관리하기 위함
-   애플리케이션을 개발하다가 문제가 생겼을 때 그 원인을 찾기 위함
-   도커를 Paas 로써 제공하기 위해서 실시간 도커데몬의 상태를 체크하기 위함

#### [2.5.4.2] 명령어

##### events

도커데몬에 어떤 일이 일너ㅏ고 있는지 실간 스트림 로그로 보여줌

```
docker events

--filter 'type=[image|containerr, volume, network...]'
```

##### stats

실행 중인 모든 컨테이너의 자원 사용량을 스트림으로 출력

##### system df

도커에서 사용하고 있는 이미지, 컨테이너, 로컬 볼륨의 총 개수 및 사용 중인 개수, 크기, 삭제함으로써 확보 가능한 공간을 출력

RECLAIMABLE 항목은 사용중이지 않은 이미지를 삭제함으로써 확보할 수 있는 공간

```
docker [container|image|volume] prune
```

#### [2.5.4.3] CAdvisor

-   구글이 만든 컨테이너 모니터링 도구
-   간단히 설치, 컨테이너별 실시간 자원 사용량 및 도커 모니터링 정보등을 시각화해서 보여줌

```
docker run \
--volume=/:/rootfs:ro \
--volume=/var/run:/var/run:ro \
--volume=/sys:/sys:ro \
--volume=/var/lib/docker/:/var/lib/docker:ro \
--volume=/dev/disk/:/dev/disk:ro \
--publish=8080:8080 \
--detach=true \
--name=cadvisor \
google/cadvisor:latest
```

-   CAdvisor는 단일 도커 호스트만을 모니터링할 수 있다는 한계를 갖고 있음
    -> 보통은 K8s나 스웜모드 등과 같은 오케스트레이션 툴을 설치한 뒤에 Prometheus 등을 이용해 여러 호스트의 데이터를 수집

#### [2.5.5.0] 파이썬 Remote API 라이브러리를 이용한 도커 사용

-   Python3 버전 이상이 설치되어 있어야 한다.

```
apt-get install python3-pip -y && pip3 install docker
```

# [3.0.0.0] Docker Swarm

## [3.1.0.0] Docker Swarm 을 사용하는 이유

-   자원이 부족할 경우, 가장 좋은 솔루션은 Scale up 임.
    -- 고성능의 자원은 많은 비용을 요구하기 때문에, 병렬확장을 씀

-   병렬확장의 경우, 서버/컨테이너의 발견(Service Discovery) 와
    고가용성 보장 문제(Availability) 가 생길 수 있다.

-   이때 주로 사용하는것이 K8s와 Docker Swarm 을 사용할 수 있다.
-   Docker Swarm은 k8s를 학습하기 전, 기본개념을 잡기에 유리할 수 있다.

## [3.2.0.0] 스웜모드

```
docker info | grep Swarm // Swarm 모드 활성화 check
```

### [3.2.1.0] Docker Swarm 모드의 구조

-   스웜모드는 매니저 노드와 워커 노드로 구성되어 있음

-   매니저 노드
    -   워커 노드를 관리하기 위한 서버
    -   매니저 노드에도 컨테이너가 생성될 수 있다.
    -   매니저 노드는 1개 이상 있어야 한다.
-   워커 노드

    -   실제로 컨테이너가 생성되고 관리되는 도커 서버
    -   워커노드는 없을 수도 있다.

-   매니저 노드의 다중화를 권장

    -   매니저의 부하를 분산하고 특정 매니저 노드가 다운됐을 때 정상적인 클러스터를 유지할 수 있음
    -   매니저노드의 수를 늘린다고, 클러스터 성능이 좋아지는 것은 아님

-   스웜모드는 매니저노드의 절반 이상에 장애가 생겨 정상적으로 작동하지 못할 경우, 장애가 생긴 매니저 노드가 복구될 때까지 클러스터의 운영을 중단


### [3.2.2] 도커 스웜모드 클러스터 구축
```
docker swarm init --advertise-addr [ip-address]
```

> 스웜 매니저는 기본적으로 2377 port를 사용한다. 노드 사이의 통신에 7946/tcp, 7946/udp 포트를 사용하고, 스웜이 사용하는 네트워크인 ingress 오버레이 네트워크에 4789/tcp, 4789/udp 포트를 사용한다.

매니저 노드는 일반적인 매니저 역할을 하는 노드와 리더역할을 하는 노드로 나뉜다.

- 리더노드
  - 모든 매니저 노드에 대한 데이터 동기화와 관리
    - 항상 작동할 수 있는 상태여야 한다
  - 리더노드가 다운되면 새로운 리더를 선출하는데, 이떄 Raft Consensus 알고리즘을 사용
    - 이 알고리즘은 리더 선출 및 고가용성 보장을 위한 알고리즘

```
docker swarm join-token [manager|worker] // 클러스터에 [manager|worker]를 추가하기 위한 명령어 조회

docker swarm join-token --rotate [manager|worker] // 토큰 갱신

docker swarm leave // docker swarm 모드 해제 (Manager에서는 Down으로만 인지)

docker node ls // 클러스터 내 노드 조회

docker node rm [HOSTNAME | ID_HASH일부] // cluster에서 삭제

docker swarm leave --force // Manager 노드에 대한 삭제 (모든 클러스터 정보가 삭제됨)

docker node promote [HOST-NAME] // worker 노드를 manager로 바꿈

docker node demote [HOST-NAME] // Manager 노드를 Worker로 바꿈
```

### [3.2.3.0] 스웜모드 서비스

#### [3.2.3.1] 스웜 모드 서비스 개념
스웜모드에서 제어하는 단위는 컨테이너가 아니라 서비스 이다.
서비스는 같은 이미지에서 생성된 컨테이너의 집합이며, 서비스를 제어하면 해당 서비스 내의 컨테이너에 같은 명령이 수행된다.

서비스 내에 컨테이너는 1개 이상이 존재할 수 있고, 컨테이너들은 각 워커노드와 매니저 노드에 할당된다. 이러한 컨테이너들을 태스크(Task) 라고 한다.

- Replica
  - 함께 생성된 컨테이너를 래플리카(replica) 라고 한다.
  - 서비스에 설정된 레플리카의 수만큼의 컨테이너가 스웜 클러스터 내에 존재해야 한다.
  - 스웜은 서비스 내에 정의된 레플리카의 수만큼 컨테이너가 스웜 클러스터에 존재하지 않으면 새로운 컨테이너 레플리카를 생성
    - 다운되지 않더라도, 일부가 작동을 멈춰 정지한 상태도 포함

- 서비스는 롤링 업데이트(Rolling Update) 기능도 제공
  - > 롤링업데이트는 여러 개의 서버, 컨테이너 등으로 구성된 클러스터의 설정이나 데이터 등을 변경하기 위해 하나씩 재시작하는 것을 의미.
  롤링 업데이트를 사용하지 않고 모든 서버나 컨테이너를 한번씩 재시작하면, 서비스에 다운시간(Down Time)이 생기지만 롤링 업데이트를 이용하면 하나를 업데이트해도 다른 서버나 컨테이너는 작동 중이기 때문에 지속적인 서비스가 가능하다

#### [3.2.3.2] 서비스 생성
서비스를 제어하는 도커 명령어는 전부 매니저 노드에서만 사용할 수 있음

```
# ubuntu 이미지로 서비스 내의 컨테이너를 생성 & hello world를 출력
docker service create \
ubuntu:14.04 \
/bin/sh -c "while true; do echo hello world; sleep 1; done"
```
```
# Service 목록 조회
docker service ls

# Serivce 자세히 조회
docker service ps [SERVICE_NAME]

# 생성된 서비스 삭제 (상태와 관계없이 바로 삭제됨)
docker service rm [SERVICE_NAME]
```

> 서비스 생성을 위해 Private 저장소 또는 레지스트리에서 이미지를 받아올 경우, 
매니저 노드에서 로그인한 뒤 'docker service create' 명령어에 '--with-registry-auth' 를 추가해 사용하면 워커 노드에서 별도로 로그인을 하지 않아도 이미지를 받아올 수 있다.

<h4> Nginx 웹 서비스 배포하기</h4>
```
docker service create --name myweb \
--replicas 2 \
-p 80:80 \
nginx
```
이를 통해서 nginx가 배포되지 않은 다른 서버에 80포트로 접근을 해도 Nginx에 접근이 되는 것을 확인할 수 있다.

```
# Replica 수 조절
docker service scale [SERVICE_NAME]=[COUNT] 
```

컨테이너가 각 컨테이너들이 호스트의 80포트로 연결된 것이 아니라, 실제로는 각 노드의 80번 포트로 들어온 요청을 위 4개의 컨테이너 중 1개로 리다이렉트(redirect) 하는 구조이다.

> 스웜모드는 라운드로빈 방식으로 서비스 내에 접근할 컨테이너를 결정한다

<h4> Global 서비스 생성하기 </h4>
서비스의 모드에는 2가지(복제모드, 글로벌 모드)가 있다. 

글로벌 모드는 스웜 클러스터 내에서 사용할 수 있는 모든 노드에 컨테이너를 반드시 하나씩 생성한다. 따라서 글로벌 모드로 생성한 서비스는 레플리카 셋의 수를 별도로 지정하지 않는다.

글로벌 서비스는 스웜 클러스터를 모니터링하기 위한 에이전트 컨테이너등을 생성해야 할 때 유용하다

```
# 글로벌 모드로 생성 (지정안할시, 복제모드가 default)
docker service create --mode global 

docker service create --name global_web \
--mode global \
nginx
```

#### [3.2.3.3] 스웜 모드의 서비스 장애 복구
복제 모드로 설정된 서비스의 컨테이너가 정지 or 다운 되면 스웜 매니저는 새로운 컨테이너를 생성해 자동으로 이를 복구

node가 종료되어도, 이에 따른 자동 복구는 실행한다. 하지만, Reblancing 작업은 일어나지 않는다. 이를 위해서는 scale 명령어를 이용해 컨테이너의 수를 줄이고 다시 늘려야 한다.
```
docker service scale myweb=1
docker service scale myweb=4
```

#### [3.2.3.4] 서비스 롤링 업데이트
스웜 모드는 롤링 업데이트를 자체적으로 지원하며, 간단하게 사용할 수 있다.
```
# 테스트용 service 생성
docker service create --name myweb2 \
--replicas 3 \
nginx:1.10

# 서비스의 이미지를 업데이트
# myweb2의 서비스 이미지를 nginx:1.11로 업데이트
docker service update \
--image nginx:1.11 \
myweb2

# 롤링업데이트 주기, 업데이트 동시에 진행할 컨테이너 수, 실패시 처리 등을 설정할수 있음
# 설정하지 않으면, 주기 없이 차례대로 컨테이너를 한개씩 업데이트
docker service create \
--replicas 4 \
--name myweb3 \
--update-delay 10s \
--update-parallelism 2 \
--update-failure-action continue \
nginx:1.10 
```

```
# 서비스의 롤링 업데이트 설정 확인
docker service inspect --pretty [NAME]
```

```
# 서비스 롤링 업데이트 후, 서비스를 롤링 업데이트 전으로 되돌리는 rollback
docker service rollback [SERVICE_NAME]
```

#### [3.2.3.5] 서비스 컨테이너에 설정 정보 전달하기: config, secret
애플리케이션을 외부에 서비스하려면 환경에 맞춘 설정 파일이나 값들이 컨테이너 내부에 미리 준비되어 있어야 한다. 설정값을 이미지 내부에 정적으로 저장한 뒤 컨테이너로서 실행하도록 배포할 수도 있지만, 이미지에 내장된 설정값을 쉽게 변경할 수 없기 때문에 확장성과 유연성이 떨어진다.

<h4> Docker에서의 설정 </h4>

- "-v 옵션" : 볼륨설정을 통한 설정
- "-e 옵션" : 환경변수를 통한 설정
 
서버 클러스터(스웜모드 etc)에서 파일 공유를 위해 설정 파일을 호스트마다 마련해두는 것은 매우 비효율적인 일이다. 뿐만 아니라 민감한 정보(비밀번호 등)를 환경변수로 설정하는 것은 보안상으로도 매우 바람직하지 않다.

이를 위해 스웜모드는 secret과 config 라는 기능을 제공한다. secret은 비밀번호나 ssh 키, 인증서 같은 보안에 민감한 데이터를 전송하기 위해 사용한다. config는 암호화할 필요가 없는 설정값들을 위해서 사용한다.

> secret과 config 는 Swarm 모드에서만 지원한다.

<h4> secret </h4>

- 생성된 secret을 조회해도 실제 값을 확인할 수는 없음.
  - secret 파일은 컨테이너에 배포된 뒤에도 파일시스템이 아닌 메모리에 저장
  - 서비스 컨테이너가 삭제될 경우 secret도 함께 삭제되는 휘발성을 띠게됨


```
# Secret 생성
docker secret create [KEY_NAME] [VALUE]
# example
# echo asdf1234 | docker secret create my_mysql_password -
```
--secret 옵션을 통해 컨테이너로 공유된 값은 기본적으로 컨테이너 내부의 /run/secrets/ 디렉토리에 마운트 된다.

source에 secret의 이름을 입력, target에는 컨테이너 내부에서 보여질 secret의 이름을 입력하면 된다.

```
# Usage example
# --secret 옵션에서 target은 절대경로로 수동설정도 가능
docker service create \
--name mysql \
--replicas 1 \
--secret source=my_mysql_password, target=mysql_root_password \
--secret source=my_mysql_password, target=mysql_password \
-e MYSQL_ROOT_PASSWORD_FILE="/run/secrets/mysql_root_password" \
-e MYSQL_PASSWORD_FILE="/run/secrets/mysql_password" \
-e MYSQL_DATABASE="wordpress" \
mysql:5.7
```

(고려할점) 
- 컨테이너 내부의 애플리케이션이 특정 경로의 파일 값을 참조할 수 있도록 설계해야 함.
  - 설정 변수를 파일로부터 동적으로 읽어올 수 있도록 설계하면 secret, config 의 장점을 활용할 수 있음


<h4> config </h4>
config를 사용하는 방법은 secret과 거의 동일하다.

하지만, 'docker config inspect [CONFIG_NAME]' 으로 조회해보면 secret과는 달리 <b>Data</b> 라는 항목이 존재하는 것을 확인할 수 있다. config는 입력된 값을 base64로 인코딩한 뒤 저장하며, base64 명령어를 통해 디코딩하면 원래의 값을 확인할 수 있다.

즉, data 부분의 해시값을 base64로 디코딩하면 원문을 볼 수 있다.

```
# CONFIG 설정
# docker config create [KEY_NAME] [VALUE]
docker config create registry-config config.yml

# 사용법
docker service create --name yml_registry -p 5000:5000 \
--config source=registry-config,target=/etc/docker/registry/config.yml \
registry:2.6
```

서비스 컨테이너가 새로운 값을 사용해야 한다면 docker service update 명령어의
- --config-rm
- --config-add
- --secret-rm
- --secret-add

을 통해서 서비스가 사용하는 secret이나 config를 추가하고 삭제할 수 있다. 이를 잘 활용하면 이미지를 다시 빌드할 필요 없이도 여러 설정값의 애플리케이션을 쉽게 사용할 수 있다.

#### [3.2.3.6] 도커 스웜 네트워크
스웜모드는 도커의 네트워크와는 조금 다른 방법을 사용한다. 

스웜모드는 여러 개의 도커 엔진에 같은 컨테이너를 분산해서 할당하기 때문에 각 도커 데몬의 네트워크가 하나로 묶인, 이른바 네트워크 풀이 필요하다. 또한 서비스를 외부로 노출했을 때 어느 노드로 접근하더라도 해당 서비스의 컨테이너에 접근할 수 있게 라우팅 기능이 필요하다. 이런 기능은 스웜모드가 자체적으로 지원하는 네트워크 드라이버를 통해 사용할 수 있다.

bridge, host, none 네트워크 외에도 docker_gwbridge와 ingress 네트워크가 생성됨. docker_gwbridge 네트워크는 스웜에서 오버레이(Overlay) 네트워크를 사용할 때 사용되며, ingress 네트워크는 로드 밸런싱과 라우팅 메시(Routing Mesh)에 사용된다.

<h4> ingress 네트워크 </h4>
ingress 네트워크는 스웜 클러스터를 생성하면 자동으로 등록되는 네트워크 (스웜모드에서만 유효).
매니저 노드뿐만 아니라 스웜 클러스터에 등록된 노드라면 전부 ingress 네트워크가 생성.

> ingress 네트워크는 어떤 스웜노드에 접근하더라도 서비스 내의 컨테이너에 접근할 수 있게 설정하는 라우팅 메시를 구성하고, 서비스 내의 컨테이너에 대한 접근을 라운드로빈 방식으로 분산하는 로드 밸런싱을 담당.

> Overlay 네트워크 <br>
> ingress 네트워크는 오버레이 네트워크 드라이버를 사용. 오버레이 네트워크는 여러 개의 도커 데몬을 하나의 네트워크 풀로 만드는 네트워크 가상화 기술 <br>
> 도커에 오버레이 네트워크를 적용하며 여러 도커 데몬에 존재하는 컨테이너가 서로 통신할 수 있다. 

> docker_gwbridge 네트워크 <br>
> 오버레이 네트워크를 사용하지 않는 컨테이너는 기본적으로 존재하는 브릿지(Bridge)네트워크를 사용해 외부와 연결한다. <br>
> 그러나, ingress 를 포함한 모든 overlay 네트워크는 docker_gwbridge 네트워크와 함께 사용된다. 이는 외부로 나가는 통신 및 오버레이 네트워크의 트래픽 종단점(VTEP) 역할을 담당한다. 
> docker_gwbridge 네트워크는 컨테이너 내부의 네트워크 인터페이스 카드 중 eth1과 연결된다.

> 사용자 정의 오버레이 네트워크
> - 스웜모드는 자체 키-값 저장소를 갖고 있어 별도의 구성 없이 사용자정의 오버레이 네트워크를 생성할 수 있다. 
> - 매니저 노드에서 '--attachable' 을 추가해야 한다

#### [3.2.3.7] 서비스 디스커버리
같은 컨테이너를 여러 개 만들어 사용할 때 쟁점이 되는 부분 중 하나는 새로 생성된 <b><i>컨테이너의 발견(Service Discovery)</i></b> 이다.
- 분산 코디네이터를 외부에 두고 사용해서 해결한다 (etcd, Zookeeper 등)

하지만, Docker Swarm 에서는 서비스 디스커버리를 지원한다.

<b><i>이는 호스트 이름이 여러개의 IP를 가지는게 아니라, 서비스의 VIP(Virtual IP) 를 가지는 것이다. </i></b>


```
# --format 의 Go 템플릿을 사용하여 VirtualIP 항목만 출력
docker service inspect --format {{.Endpoint.VirtualIPs}} [SERVICE_NAME]
```
스웜 모드가 활성화된 도커 엔진의 내장 DNS 서버는 SERVICE_NAME의 호스트 이름을 Virtual IP로 변환한다. 그 뒤, 이 IP는 컨테이너의 네트워크 네임스페이스 내부에서 실제 SERVICE_NAME 서비스의 컨테이너의 IP로 포워딩 된다.

VIP 방식이 아닌 도커의 내장 DNS 서버를 기반으로 라운드 로빈을 사용할 수 있다. 하지만 이 경우 애플리케이션에 따라 <i><b>캐시 문제로 인해 서비스 절반이 정상적으로 작동하지 않을 때</b></i>가 있다
```
# VIP 방식이 아닌, docker network를 이용한 방법
# 
docker service create --name server \
--replicas 2 --network discovery \
--endpoint-mode dnsrr \
alicek106/book:hostname
```

#### [3.2.3.8] 스웜모드 볼륨
스웜모드에서도 볼륨을 사용할 수 있다. 이떄 사용하는 방법은 '--mount type=volume' 을 명시하여 사용한다.
```
# 호스트와 디렉터리를 공유하는 경우
docker run -it --name host_dir_case -v /root:/root ubuntu:14.04

# 도커 볼륨을 사용하는 경우
docker run -it --name volume_case -v myvolume:/root ubuntu:14.04

# 도커 Swarm 에서의 볼륨
# source를 명시하지 않으면 익명의 볼륨을 생성
docker service create --name ubuntu \
--mount type=volume,source=myvol,target=/root \
ubuntu:14.04 \
ping docker.com

# volume-nocopy를 통한 컨테이너의 파일들이 볼륨에 복사되지 않도록 설정
--mount type=[],source=[],target=[],volume-nocopy
```

<h4> bind 타입의 볼륨 생성 </h4>

- 바인드 타입은 호스트와 디렉터리를 공유할 때 사용된다.
- 볼륨타입과는 달리 공유될 호스트의 디렉터리를 설정해야 하므로 source 옵션을 반드시 명시
```
--mount type=bind,source=/root/host,target=/root/container
```

<h4> 스웜 모드에서 볼륨의 한계점 </h4>

- 서비스를 할당받을 수 있는 모든 노드가 볼륨 데이터를 가지고 있어야 하기 때문에 스웜에서 볼륨을 사용하기 어려움
- PaaS 같은 시스템을 구축하려 한다면 더욱 문제가 됨
  - 모든 노드에 같은 데이터의 볼륨을 구성하는 것은 좋은 방법이 아님
  - 이때, 어느 노드에서도 접근 가능한 <b><i>퍼시스턴트 스토리지(Persistent Storage)</i></b>를 사용
    > Persistent Storage 는 호스트와 컨테이너와 별개로 외부에 존재해 네트워크로 마운트할 수 있는 스토리지 이다.

Persistent Storage를 사용하면,
1. 노드에 볼륨을 생성하지 않아도 됨
2. 컨테이너가 어느 노드에 할당되든, 컨테이너에 필요한 파일을 읽고 쓸 수 있음
  
그러나 도커가 자체적으로 제공하지는 않으므로 서드파티 플러그인을 사용하거나 nfs, dfs 등을 별도로 구성해야 한다. (참조. https://docs.docker.com/engine/extend/legacy_plugins/#/volume-plugins)

또는 각 노드에 라벨(label)을 붙여서 서비스에 제한을 설정하는 방법도 있다. 하지만 이는 근본적인 해결책이 될 수 없지만, 소규모 클러스터와 테스트 환경에서는 유용하게 활용될 수 있다.

### [3.2.4] Docker Swarm 모드 노드 다루기
새로운 노드를 추가하는 것 뿐만 아니라 노드를 다루기 위한 전략도 필요. 현재 스웜모드의 스케줄러를 사용자가 수정할 수 있게 자체적으로 제공하지 않기 떄문에 별도의 스케줄링 전략을 세우는 것은 불가능하다

그러나 스웜모드가 제공하는 기본 기능만으로도 어느 정도 목적에 부합한 전략을 세울 수 있음

#### [3.2.4.1] 노드 AVAILABILITY 변경하기 
일반적으로 매니저와 같은 마스터 노드는 최대한 부하를 받지 않도록 서비스를 할당받지 않게 하는 것이 좋다. 

이를 Availability 를 통해서 조절할 수 있다
<h5> Active </h5>

Active 상태는 새로운 노드가 스웜 클러스터에 추가되면 기본적으로 설정되는 상태이다. 

```
# Active 로 업데이트
docker node update \
--availability active \
[NODE_NAME]
```

<h5> Drain </h5>
스웜 매니저의 스케줄러는 컨테이너를 해당 노드에 할당하지 않는다. Drain 상태는 일반적으로 매니저 노드에 설정하는 상태지만, 노드에 문제가 생겨 일시적으로 사용하지 않는 상태로 설저애햐 할때도 자주 사용.

```
# Drain 로 업데이트
docker node update \
--availability drain \
[NODE_NAME]
```

drain 으로 변경되면, 해당 노드에서 실행 중이던 서비스의 컨테이너는 모두 중지되고 Active 상태의 노드로 다시 할당된다.

Drain -> Active로 업데이트 한다고 해서 다시 분산할당이 되지 않으므로, scale 명령어를 사용해서 균형 재조정해야 한다.

<h5> Pause </h5>
Pause 상태는 서비스의 컨테이너를 더는 할당받지 않는다는 점에서 Drain과 유사. 하지만 실행 중인 컨테이너가 중지되지는 않는 다는 점에서 다르다

```
# Pause 로 업데이트
docker node update \
--availability pause \
[NODE_NAME]
```

#### [3.2.4.2] 노드 라벨 추가
노드에 라벨을 추가하는 것은 노드를 분류하는 것과 비슷하다. 라벨은 Key-value 를 갖고 있다.

<h5> 노드 라벨 추가하기 </h5>
'docker node update' 명령에서 --label-add 옵션을 사용해 라벨을 설정할 수 있다.
```
docker node upddate \
--label-add storage=ssd \
[NODE_NAME]
```

<h5> 서비스 제약 설정 </h5>

'docker service create' 명령어에 --contraint 옵션을 추가해 서비스의 컨테이너가 할당될 노드의 종류를 선택할 수 있다.

만약 해당 라벨을 만족하는 노드를 찾지 못하면, 서비스의 컨테이너는 생성되지 않는다.
  1. node.labels 제약조건
      ```
      # storage 키의 값이 ssd로 설정된 노드에 서비스의 컨테이너를 할당
      docker service create --name label_test \
      --constraint 'node.labels.storage == ssd' \
      --replicas=5 \
      ubuntu:14.04 \
      ping docker.com
      ```
  2. node.id 제약조건 <br>
      node.id 조건에 노드의 ID를 명시해 서비스의 컨테이너를 할당할 노드를 선택. (일부만 입력하면 인식을 못하므로, 전부 입력해야 한다.)
      ```
      docker service create --name label_test2 \
      --constraint 'node.id == [NODE_ID]' \
      --replicas=5 \
      ubuntu:14.04 \
      ping docker.com
      ```
  3. node.hostname과 node.role 제약조건 <br>
      스웜 클러스터에 등록된 호스트 이름 및 역할로 제한 조건 설정
      ```
      # 특정 노드를 선택해 서비스의 컨테이너 생성
      docker service create --name label_test3 \
      --constraint 'node.hostname == [HOST_NAME]' \
      ubuntu:14.04 \
      ping docker.com

      # 매니저 노드가 아닌 워커노드에 컨테이너 생성
      docker service create --name label_test4 \
      --constraint 'node.hostname != manager' \
      --replicas 2 \
      ubuntu:14.04 \
      ping docker.com
      ```
  4. engine.labels 제약조건 <br>
      도커 데몬 자체에 라벨을 설정해 제한 조건을 설정한다. 다만 이를 사용하려면 도커 데몬의 실행옵션을 변경해야 한다.
      > DOCKER_OPTS="... --label=mylabel=worker2 --label mylabel2=second_worker"

      ```
      # 도커 데몬의 라벨 중 mylabel 이라는 키가 worker2 라는 값으로 설정된 노드에 서비스의 컨테이너를 할당
      docker service create --name engine_label \
      --constraint 'engine.labels.mylabel == worker2' \ # 여러개의 조건도 가능
      --replicas 3 \
      ubuntu:14.04 \
      ping docker.com
      ```

      > Docker 데몬에 설정된 라벨은 docker info 명령으로 확인할 수 있다.



    


