# docker-swarm-k8s
Studying for Docker, Docker Swarm, k8s




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
nginx:1.10 
```

```
# 서비스의 롤링 업데이트 설정 확인
docker service inspect --pretty [NAME]
```