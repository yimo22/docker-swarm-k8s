
#### [6.2.0.0] 파드(Pod): 컨테이너를 다루는 기본단위
k8s는 많은 리소스 종류와 컴포넌트가 존재한다. 그 중에서도 컨테이너 애플리케이션을 구동하기 위해서는 `Pod`, `Replica Set`, `Service`, `Deployment` 가 기초가 된다.

#### [6.2.1.0] 파드 사용하기
컨테이너 애플리케이션의 기본 단위를 파드(Pod) 라고 부른다. 파드는 1개 이상의 컨테이너로 구성된 컨테이너의 집합이다.
(도커엔진 에서는 `컨테이너`, 도커 스웜에서는 `서비스`, 쿠버네티스에서는 `파드` 가 기본단위다.)

``` yaml
# nginx-pod.yaml
apiVersion: v1
kind: Pod
metadata: 
  name: "my-nginx-pod"
spec:
  containers:
  - name: my-nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
      protocol: TCP
``` 

클러스터 내부에서만 접근이 가능하다. (Docker -p 옵션과 비슷)

- `kubectl get <오브젝트 이름>` 을 통해서 오브젝트의 목록을 확인 가능
- `kubectl describe <오브젝트 이름> <해당 이름>` 을 통해서 자세한 정보 확인 가능
- `kubectl exec ` 명령으로 파드의 컨테이너에 명령어를 전달 할 수 있음
  - `kubectl exec -it <오브젝트 이름> bash` 를 통해서 셸을 유지
- `kubectl logs ` 명령으로 파드의 로그를 확인
- `kubectl delete -f ` 명령으로 파일에 정의된 파드를 삭제

#### [6.2.2.0] Pod 와 Docker Container
쿠버네티스가 파드라는 개념을 사용하는 이유는 <u><i>__여러 리눅스 네임스페이스를 공유__</i></u> 하는 여러 컨테이너들을 추상화된 집합으로 사용하기 위해서 이다.

``` yml
# nginx-pod-with-ubuntu.yml
apiVersion: v1
kind: Pod
metadata:
  name: my-nginx-pod
spec:
  containers:
    - name: my-nginx-container
      image: nginx:latest
      ports:
        - containerPort: 80
          protocol: TCP

    - name: ubuntu-sidecar-container
      image: alicek106/rr-test:curl
      command: ["tail"]
      args: ["-f", "/dev/null"] # 컨테이너 종료되지 않도록
```

``` bash
# Pod 내의 특정 컨테이너 접근
kubectl exec -it my-nginx-pod -c "ubuntu-sidecar-container" bash

# 접근 확인
curl localhost
```

우분투 컨테이너가 Nginx 서버를 실행하고 있지 않은데도, 우분투 컨테이너의 로컬호스트에서 Nginx 서버로 접근이 가능하다. 이는 파드 내의 컨테이너들이 네트워크 네임스페이스 등과 같은 리눅스 네임스페이스를 공유해 사용하기 때문이다.

파드가 공유하는 리눅스 네임스페이스에 네트워크 환경만 있는 것은 아니다. 1개의 파드에 포함된 컨테이너들은 여러 개의 리눅스 네임스페이스를 공유


#### [6.2.3.0] 완전한 애플리케이션으로서의 파드
보통의 경우에는 1개의 컨테이너로 구성된 파드를 사용하는 경우가 많다. 즉, 하나의 파드는 하나의 완전한 애플리케이션이 된다.

하나의 기능을 중심으로, 주 컨테이너를 생성하며 부가적인 컨테이너를 생성(Sidecar Container)하여 같은 파드로 묶을 수 있다. 또한 이런 컨테이너들은 모두 같은 워커노드에서 함께 실행된다.

> 파드의 네트워크 네임스페이스는 Pause 라는 이름의 컨테이너로부터 네트워크를 공유받아 사용한다. Pause 컨테이너는 네임스페이스를 공유하기 위해 파드별로 생성되는 컨테이너이며, Pause 컨테이너는 각 파드에 대해 자동으로 생성된다.
