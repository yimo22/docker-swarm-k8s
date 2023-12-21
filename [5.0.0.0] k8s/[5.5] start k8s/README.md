#### [6.1.0.0] k8s 시작전.
쿠버네티스만이 가지는 고유한 특징
- 모든 리소스는 오브젝트 형태로 관리된다.
  - Docker swarm 의 서비스도 컨테이너 리소스의 집합을 정의한 것이기 때문에 일종의 오브젝트라고 볼 수 있다.
  ``` bash
  # k8s 에서 사용할 수 있는 오브젝트 조회
  kubectl api-resources

  # 특정 오프젝트의 간단한 설명
  kubectl explain pod
  ```
- k8s 는 명령어로도 사용할 수 있지만, yml 파일을 더 많이 사용 <br>
  k8s 에서 yaml 파일의 용도는 컨테이너뿐만 아니라 거의 모든 리소스 오브젝트들에 사용될 수 있다는 것이 큰 특징이다.
- 여러개의 컴포넌트로 구성돼 있다. <br>
    쿠버네티스는 `마스터` 와 `워커` 노드로 나뉘어져 있다. 
    - 마스터 노드는 쿠버네티스가 제대로 동작할 수 있게 클러스터를 관리하는 역할을 담당
    - 워커 노드에는 애플리케이션 컨테이너가 생성

    쿠버네티스는 도커를 포함한 매우 많은 컴포넌트들이 실행된다.
    > 마스터 노드에서는, `API서버(kube-apiserver)` , `컨트롤러 매니저(kube-controller-manager)` , `스케줄러(kube-scheduler)` , `DNS서버(coreDNS)` , `프락시(kube-proxy)` , `네트워크 플러그인(calico, flannel)`
    > 
    > 확인은 `sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps` 로 확인 가능
    >
    > Kubelet 컴포넌트는 모든 노드에서 기본적으로 실행, 마스터 노드에는 API 서버등이 컨테이너로 실행된다.

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

#### [6.3.0.0] Replica Set : 일정 개수의 파드를 유지하는 컨트롤러

쿠버네티스의 기본 단위인 파드는 여러 개의 컨테이너를 추상화해 하나의 애플리케이션으로 동작하도록 만드는 훌륭한 컨테이너 묶음이다.

`kubectl delte -f [POD_DEFINE].yml` 로 삭제하면 그 파드의 컨테이너 또한 삭제된 뒤 쿠버네티스에서 영원히 사라지게 된다. 이 경우, 해당 파드는 오직 쿠버네티스 사용자에 의해 관리된다.
하지만 실제로 외부 사용자의 요청을 처리해야 하는 마이크로 서비스 구조의 파드라면 이러한 방식을 사용하기 어렵다.

-> MSA 에서는 여러개의 동일한 컨테이너를 생성한 뒤 외부 요청이 각 컨테이너에 적절히 분배될 수 있도록 해야한다.

쿠버네티스에서는 이런 처리를 여러개의 파드로 생성해서 처리를 한다.

``` yml
apiVersion: v1
kind: Pod
metadata:
  name: my-nginx-pod-a
spec:
  containers:
  - name: my-nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
      protocol: TCP

---

apiVersion: v1
kind: Pod
metadata:
  name: my-nginx-pod-b
spec:
  containers:
  - name: my-nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
      protocol: TCP

```
> yml 파일은 `---` 를 구분자로 사용해 여러 개의 리소스를 정의할 수 있다.

이런 방법으로, 여러 개의 파드를 직접 생성하는 방법은 적절치 않다. 
1. 동일한 파드의 개수가 많아질수록 이처럼 일일이 정의하는 것은 매우 비효율적인 작업이다.
2. 어떠한 이유로든지 파드가 삭제 or 접근하지 못할 경우, 직접 파드를 삭제하고 다시 생성하지 않는 한 해당 파드는 다시 복구되지 않는다.

이처럼 파드만 yml 파일에 정의해 사용하는 방식은 여러가지 한계점이 있다. 따라서 k8s 에서 이런 한계점을 해결해 주는 것이 __<b><i>레플리카셋(replicaSet)</i></b>__ 라는 오브젝트를 함께 사용한다.

- 레플리카셋은 정해진 수의 동일한 파드가 항상 실행되도록 관리한다.
- 노드 장애 등의 이유로 파드를 사용할 수 없다면, 다른 노드에서 파드를 다시 생성한다.

#### [6.3.2.0] 레플리카셋 사용하기

``` yml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: replicaset-nginx
spec:
  replicas: 4
  selector:
    matchLabels:
      app: my-nginx-pods-label
  template:
    metadata:
      name: my-nginx-pod
      labels: 
        app: my-nginx-pods-label
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

> `spec.replicas`: 동일한 파드를 몇 개 유지할 지 설정.
> 
> `spec.template`: 파드를 생성할 때 사용할 템플릿을 정의. 이를 보통 __파드 스펙__ 또는 __파드 템플릿__ 이라고 한다.

기존의 replicas 를 더 늘려서 똑같이 실행할 경우, `configured` 라는 문구를 통해서 수정된 것을 확인할 수 있다.

마찬가지로, `kubectl delete -f [YML_NAME].yml` 을 통해서 삭제할 수 있다.


#### [6.3.3.0] 레플리카셋의 동작 원리
레플리카셋은 파드와 연결되어 있지 않다.

오히려 느슨한 연결(loosely coupled)을 유지하고 있으며, 이러한 느슨한 연결은 파드와 레플리카셋의 정의 중 `라벨 셀렉터(Label Selector)` 를 이용해 이뤄진다.

`metadata` 항목에서는 리소스의 부가적인 정보를 설정할 수 있다. 그 정보 중에는 리소스의 고유한 이름뿐만 아니라 주석, 라벨 등도 포함된다. 라벨은 파드 등의 쿠버네티스 리소스를 분류할 때 유용하게 사용할 수 있는 메타데이터 이다.
또한 서로 다른 오브젝트가 서로 찾아야 할 떄 사용되기도 한다. (레플리카셋은 spec.selector.matchLabel에 정의된 라벨을 통해 생성해야 할 파드를 찾는다.)

<h5> 기존의 파드에 Replica Set을 새로 정의하여 만드는 경우 </h5>

``` yml
# nginx-pod-without-rs.yml
apiVersion: v1
kind: Pod
metadata:
  name: my-nginx-pod
  labels:
    app: my-nginx-pods-label
spec:
  containers:
  - name: my-nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
```

``` bash
# 조회
# 1.
kubectl get po --show-labels
# 2.
kubectl get po -l app
# 3.
kubectl get po -l app=my-nginx-pods-label

# 레플리카셋 생성
kubectl apply -f replicaset-nginx.yml
```

`selector.matchLabel` 에 정의된 라벨을 가지는 파드가 이미 1개 존재하기 때문에 그 차이만큼만 새로 생성한다.

case1) 이때 기존에 존재하는 파드를 하나 지우면, 새로운 파드를 하나 생성한다. (Replica Set으로 묶여 있기 때문)
``` bash
# 파드들 중 하나 삭제
kubectl delete pods my-nginx-pod
```

> 레플리카셋과 파드의 라벨은 고유한 K-V 쌍이여야 한다. 따라서 레플리카셋과 동일한 라벨을 갖는 파드를 직접 생성하는 것은 바람직하지 않다.

case2) 레플리카 파드 중 하나의 라벨을 삭제
``` bash
# edit 으로 직접 수정
kubectl edit [POD_NAME]

# 이후, Label 부분과 Label.app 부분을 삭제
```

이후에 조회를 해보면, 새로운 파드가 생성되는 것을 확인할 수 있다. 즉, selector.matchLabel 항목의 값과 더 이상 일치하지 않으므로 레플리카셋에 의해 관리되지 않으며, 직접 수동으로 생성한 파드와 동일한 상태가 된다. 

따라서 레플리카셋을 삭제해도 이 파드는 삭제되지 않을 것이다. (직접 수동으로 삭제해야 할 것이다.)

case3) replicaset 이였다가 edit으로 벗어난 Pod가 있을때, 레플리카를 삭제하면 삭제가 되는 지 확인

``` bash
kubectl delete rs replicaset-nginx
```

삭제를 진행하면, label을 수동으로 변경하여 관리대상에서 제외된 파드만 제외하고 삭제가 된다.

- 레플리카셋의 목적은 '파드를 생성하는 것' 이 아닌, '일정한 개수의 파드를 유지하는 것' 이다.
  - replicas 정의된 것보다 많은경우, 파드를 줄일려고 하며
  - 정의된 것보다 적을 경우, 늘리려고 할 것이다.

#### [6.3.4.0] 레플리케이션 컨트롤러 vs 레플리카셋
이전 버전의 쿠버네티스에서는 `레플리카셋`이 아닌 `레플리케이션 컨트롤러(Replication Controller)` 라는 오브젝트를 통해서 파드의 개수를 유지했었다.
- 그러나 버전이 올라가면서, deprecated 되었다.


레플리카셋이 레플리케이션 컨트롤러와 다른 점 중 하는 `표현식(matchExpression)` 기반의 라벨 셀럭터를 사용할 수 있다는 것이다.
``` yml
...
# Key가 app 인 것들 중에서 values 항목을 체크하여 존재(In)하는 파드들을 대상으로 하겠다는 의미
selector:
  matchExpressions:
    - key: app
      values: 
        - my-nginx-pods-label
        - your-nginx-pods-label
      operator: In
template:
...
```

따라서 위의 예시에서, `app: my-nginx-pods-label` 라벨을 가지는 파드뿐만 아니라 `app: your-nginx-pods-label` 을 가지는 파드도 레플리카셋의 관리하에 놓인다.

#### [6.4.0.0] 디플로이먼트(Deployment) : 레플리카셋, 파드의 배포를 관리

#### [6.4.1.0] 디플로이먼트 사용하기

대부분은 레플리카셋과 파드의 정보를 정의하는 Deployment라는 오브젝트를 yml 파일에 정의해서 사용한다. (Deployment 가 레플리카셋의 상위 오브젝트이다.)

``` yml
# deployment-nginx.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-nginx
  template:
    metadata:
      name: my-nginx-pod
      labels:
        app: my-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.10
        ports:
        - containerPort: 80
```


#### [6.4.2.0] Deployment 를 사용하는 이유

레플리카셋의 상위 개념인 디플로이먼트를 사용하는 핵심적인 이유 중 하나는 애플리케이션의 업데이트와 배포를 더욱 편하게 만들기 위해서 이다.
- App 을 업데이트할 때 레플리카셋의 변경 사항을 저장하는 Revision 을 남겨 롤백을 가능하게 해주고, 무중단 서비스를 위해 파드의 롤링 업데이트의 전략을 지정할 수 있음

``` bash
# --record 특수 옵션 추가
kubectl apply -f deployment-nginx.yml --record

# nginx 의 버전을 1.11 로 업데이트
kubectl set image deployment my-nginx-deployment nginx=nginx:1.11 --record
```
> kubectl set image 명령어 대신 yml 파일에서 직접 image 항목을 변경한 다음에 적용해도 동일하게 적용된다.
>
> 또는 kubectl edit 명령어를 사용해도 된다.

이때 `kubectl get rs` 명령어를 통해서 서로 다른 두개의 rs (replica set)을 확인할 수 있다.

레플리카셋은 이미지를 업데이트함으로써 새로운 레플리카셋과 파드를 생성했음에도 불구하고 이전 버전의 레플리카셋을 삭제하지 않고 남겨두고 있다. 즉, 이전 버전의 정보를 리비전으로서 보존한다.

``` bash
# 리비전 정보 자세히 조회
kubectl rollout history deployment my-nginx-deployment
```

`--recore=true` 로 deploy 를 변경하면 이와 같이 기록을 하면서 레플리카셋을 보존한다. 

``` bash
kubectl rollout undo deployment my-nginx-deployment --to-revision=1
```

> 파드 템플릿으로부터 계산된 해시값은 각 레플리카셋의 라벨 셀럭터(matchLabels) 에서 pod-template-hash 라는 이름의 라벨값으로서 자동으로 설정된다. 그 결과 여러개의 레플리카셋은 겹치지 않는 라벨을 통해 파드를 생성한다.

``` bash
kubectl describe deploy my-nginx-deployment
```

즉, Deployment는 다수의 레플리카셋을 관리하는 상위 오브젝트이다. 레플리카셋의 리비전 관리뿐만 아니라 다양한 파드의 롤링 업데이트 정책을 사용할 수 있다는 장점이 있다.

``` bash
# 리소스 정리
kubectl delete deploy, po, rs --all
```

#### [6.5.0.0] 서비스(Service) : 파드를 연결하고 외부에 노출
파드의 IP는 영속적이지 않아 항상 변할 수 있다는 점을 유의해야 한다. 여러 개의 Deployment 를 하나의 완벽한 애플리케이션으로 연동하려면 파드 IP가 아닌, 서로를 발견 (Discovery) 할 수 있는 다른 방법이 필요하다.

deployment 에서 파드의 노출은 `containerPort` 항목을 통해서 노출한다. 하지만 이를 정의했다고 해서 이 파드가 바로 외부로 노출되는 것은 아니다.

다른 Deployment 의 파드들이 내부적으로 접근하려면 `서비스(Service)` 라고 부르는 별도의 쿠버네티스 오브젝트를 생성해야 한다. 서비스는 파드에 대한 접근하기 위한 규칙을 정의하며, 다음과 같은 특징을 갖는다.
- 여러 개의 파드에 쉽게 접근할 수 있도록 고유한 도메인 이름을 부여
- 여러 개의 파드에 접근할 때, 요청을 분산하는 로드 밸런서 기능을 수행
- 클라우드 플랫폼의 로드밸런서, 클러스터 노드의 포트 등을 통해 파드를 외부로 노출

> k8s 를 설치할 때 calico, flannel 등 네트워크 플러그인을 사용하도록 설정한다. (자동으로 overlay network를 통해서 각 파드끼리 통신할 수 있다.) 단, 어떤 네트워크 플러그인을 사용하느냐에 따라서 네트워킹 기능 및 성능에 차이가 있을 수 있다.

#### [6.5.1.0] 서비스의 종류
k8s 의 서비스는 파드에 어떻게 접근할 것이냐에 따라 종류가 여러 개로 세분화돼 있다. 따라서 목적에 맞는 적절한 서비스의 종류를 선택해야 한다.

- Cluster IP 타입
  - 쿠버네티스 내부에서만 파드들에 접근할 때 사용
  - 외부로 파드를 노출하지 않기 때문에 쿠버네티스 클러스터 내부에서만 사용되는 파드에 적합
- NodePort 타입
  - 파드에 접근할 수 있는 포트를 클러스터의 모든 노드에 동일하게 개방
  - 접근할 수 있는 포트는 랜덤으로 정해지지만, 특정 포트로 접근하도록 설정할 수도 있다.
- LoadBalancer 타입
  - 클라우드 플랫폼에서 제공하는 로드 밸런서를 동적으로 프로비저닝해 파드에 연결
  - Node Port 타입과 마찬가지로 외부에서 파드에 접근 가능
  - AWS, GCP 등과 같은 클라우드 플랫폼 환경에서만 사용할 수 있음

#### [6.5.2.0] ClusterIP 타입의 서비스 - 쿠버네티스 내부에서만 파드에 접근하기

`hostname-svc-clusterip.yml` 적용
 
> `spec.selector` 항목은 이 서비스에서 어떤 라벨을 가지는 파드에 접근할 수 있게 만들 것인지 결정
> 
> `spec.ports.port` k8s 내부에 할당받은 고유IP에 대하여 접근할 때 사용할 포트를 설정
>
> `spec.ports.targetPort` selector 항목에서 정의한 라벨에 의해 접근 대상이 된 파드들이 내부적으로 사용하고 있는 포트를 입력. 즉, 파드 템플릿에 정의된 containerPort와 같은 값으로 설정해야 한다
>
> `spec.type` 는 이 서비스가 어떤 타입인지 나타낸다.

> k8s 에서의 라벨은 단순히 리소스의 부가적인 정보를 표시하는 것 이상의 기능을 가질 수 있다.

> service를 생성하지 않아도, 기본적으로 `kubernetes` 라는 서비스가 생성되어 있다.

이후에 해당 IP+PORT 또는 SERVICE_NAME 으로 접근할 경우 접근이 가능하다. 또한 서비스를 생성할 때 별도의 설정을 하지 않아도 서비스는 연결된 파드에 대해 로드 밸런싱을 수행한다.


<u><b><i>Cluster IP 타입의 서비스를 생성해 파드에 접근하는 과정</i></b></u>
1. 특정 라벨을 가지는 파드를 서비스와 연결하기 위해 서비스의 yml 파일에 selector 항목을 정의
2. 파드에 접근할 때 사용하는 포트를 yml 파일의 targetPort 항목에 정의
3. 서비스를 생성할 때, yml 파일의 port 항목에 8080을 명시해 서비스의 Cluster IP 와 8080 포트로 접근할 수 있도록 설정
4. kubectl apply 로 ClusterIP 타입의 서비스 적용
5. k8s 클러스터에서 서비스의 내부 IP 또는 서비스 이름으로 접근 가능

이는 ClusterIP 타입이기 때문에 외부에서 접근이 불가능하다. 외부에 노출해야 한다면 NodePort나 LoadBalancer 타입의 서비스를 생성해야 한다.

> 서비스의 Label Selector 와 파드의 라벨이 매칭돼 연결되면, k8s는 자동으로 `엔드포인트` 라고 부르는 오브젝트를 별도로 생성. 이때 이름은 서비스와 동일하다
>
> `kubectl get endpoints` 로 확인 가능

#### [6.5.3.0] NodePort 타입의 서비스 - 서비스를 이용해 파드를 외부에 노출하기

`hostname-svc-nodeport.yml` 적용

해당 파일을 적용 후, `kubectl get no -o wide` 를 통해서 `INTERNAL-IP` 와 `EXTERNAL-IP`를 확인할 수 있다.

> 각 노드에서 개방되는 포트는 기본적으로 30000~32768 포트 중에 랜덤으로 선택되지만, yml 파일에 nodePort 항목을 통해서 원하는 포트를 설정할 수 있다.
> ``` yml
> spec:
>   ports:
>   - name: web-port
>     port: 8080
>     targetPort: 80
>     nodePort: 31000
> ```
> 또한 `--service-node-port-range=1234~5678` 을 통해서 포트범위 설정도 가능하다. (30000 이상의 포트 설정 권장)


- NodePort 타입의 서비스가 ClusterIP 의 기능을 포함하고 있다.
  - CLUSTER-IP 항목에 내부 IP가 할당된다.
  - k8s 내/외부 에서 접근이 가능하다

- 실제 운영환경에서는 NortPort 를 외부에 제공하는 경우는 많지 않다.
  - SSL or 라우팅 등의 복잡한 설정을 서비스에 적용하기가 힘들다.
  - 직접 제공보다는 인그레스(Ingress) 라는 k8s의 오브젝트에서 간접적으로 사용되는 경우가 많다.

> 특정 클라이언트가 같은 파드로부터만 처리되게 하려면 서비스의 yml 파일에서 sessionAffinity 항목을 ClientIP로 설정한다.
> ``` yml
> spec:
>   sessionAffinity: ClientIP
> ```

#### [6.5.4.0] 클라우드 플랫폼의 로드 밸런서와 연동하기 - LoadBalancer 타입의 서비스
LoadBalancer 타입의 서비스는 클라우드 플랫폼으로부터 도메인 이름과 IP를 할당받기 때문에 더 쉽게 파드에 접근가능. 

하지만 LoadBalancer 타입의 서비스는 로드 밸런서를 동적으로 생성하는 기능을 제공하는 환경(GCP, AWS등)에서만 사용할 수 있다.
> MetalLB, LBaaS 등과 같은 온프레미스 환경에서도 LoadBalancer 타입의 서비스를 사용할 수 있다.

`hostname-svc-lb.yml` 을 적용

마찬가지로 INTERNAL/EXTERNAL IP를 할당받는다. 이때 EXTERNAL-IP 항목은 클라우드 플랫폼으로부터 자동으로 할당받은 것이며, 이 주소와 80포트(yml파일의 ports.port)를 통해 파드에 접근할 수 있다.

1. LoadBalancer 타입의 서비스가 생성됨과 동시에 모든 워커 노드는 파드에 접근할 수 있는 랜덤한 포트를 개방한다. 
2. 클라우드 플랫폼에서 생성된 로드 밸런서로 요청이 들어오면 이 요청은 k8s 워커노드 중 하나로 전될며, 이때 사용되는 포트는 1번에서 개방된 포트이다.
3. 워커노드로 전달된 요청은 파드 중 하나로 전달되어 처리된다.

LoadBalancer 타입을 명시해 서비스를 생성했지만, Nodeport 의 간접적인 기능 또한 자동으로 사용할 수 있다.

k8s v1.18.0 기준으로 서비스의 yml 에 아무런 설정을 하지 않으면 AWS의 클래식 로드 밸런서를 생성한다. (원한다면 NLB:Network Load Balancer)를 생성할 수 있다. 


> `hostname-svc-nlb.yml` 적용하면 NLB를 설정할 수 있다.
>
> 이처럼 특정 용도로 사용할 수 있게 k8s에 미리 정의된 몇가지 주석(Annotations)가 있다. 

#### [6.5.4.1] 온프레미스 환경에서 LoadBalancer 타입의 서비스 사용
온프레미스 환경에서도 LoadBalancer 타입을 사용할 수 있다. MetalLB나 오픈스택과 같은 특수한 환경을 직접 구축해야만 한다.

하지만, 이는 k8s에서 정식적으로 지원하는 것이 아니기 때문에 유지보수가 지속적이지 않을 수 있다는 점에 유의해야 한다.

#### [6.5.5.0] 트래픽의 분배를 결정하는 서비스 속성 : externalTrafficPolicy
NordPort 또는 LoadBalancer 타입을 사용하는 경우, 들어온 요청에 따라서 불필요한 밸런싱이 될 수 있다. 즉 이는 다음과 같은 단점을 갖는다.

- 불필요한 네트워크 홉(hop)이 한 단계 더 발생하게 된다.
- 노드 간의 리다이렉트가 발생하게 되어 트래픽의 출발지 주소가 바뀌는 SNAT가 발생한다.
  - 이로인해 Client IP 주소 또한 보존되지 않는다.

이를 위해 k8s 의 서비스에는 `externalTrafficPolicy` 항목이 정의되어 있다.

- `spec.externalTrafficPolicy: Cluster`
  - 클러스터의 모든 노드에 랜덤한 포트를 개방
  - NodePort 와 LoadBalancer 가 기본적으로 동작하는 방식이다.
  - 단, 노드 간에 요청이 리다이렉트 되어 NAT가 발생하므로 Client IP를 보존할 수 없다.
- `spec.externalTrafficPolicy: local`
  - 파드가 생성된 노드에서만 접근할 수 있다.
  - 로드 밸런서는 파드가 위치한 노드로만 요청을 전달, 해당 노드 내의 파드에서만 요청이 분산
  - 추가적인 네트워크 홉이 발생하지 않으며, 전달되는 요청의 Client IP는 보존된다.

그렇지만 `spec.externalTrafficPolicy: local` 을 설정하는 것이 무조건 좋은 것은 아니다. 각 노드에 파드가 고르지 않게 스케줄링됐을 때, 요청이 고르게 분산되지 않을 수도 있기 때문이다.
- 로드밸런서가 N개의 노드에 트래픽을 분배해도, 각 파드가 실제로 받는 부하의 양은 동일하지 않을 수 있기 때문이다.
  
> k8s 의 `PodAntiAffinity` 를 통해 최대한 클러스터 노드에 고르게 배포할 수 있다.

#### [6.5.6.0] 요청을 외부로 리다이렉트하는 서비스 : ExternalName
k8s를 외부 시스템과 연동해야 할 때는 `ExternalName` 타입의 서비스를 사용할 수 있다.

이를 사용하여 서비스를 생성하면 서비스가 외부 도메인을 가리키도록 설정할 수 있다.

`external-svc.yml` 적용하면, externalname-svc라는 이름으로 요청을 보낼 경우, k8s의 DNS는 my.database.com 으로 접근할 수 있도록 CNAME 레코드를 반환한다. 
즉, external-svc로 요청을 보내면 my.database.com 에 접근하게 된다.

> DNS 레코드 종류 중 `CNAME 레코드` 는 Canonical Name의 줄임말로, 도메인을 가리키는 다른 이름을 뜻한다. 비슷한 레코드로는 `A레코드` 가 있다. 이는 도메인이름이 직접 IP로 변환되는 경우를 말한다.
>
> | 사용하는 도메인 이름 | 변환되는 주소|
> |---|---|
> | externalname-svc (CNAME 레코드) | my.database.com |
> | hostname-svc-nodeport | 10.110.9.251 |
