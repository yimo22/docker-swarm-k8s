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




