#### [7.1.0.0] 네임스페이스(Namespace) : 리소스를 논리적으로 구분하는 장벽
용도에 따라 컨테이너와 그에 관련된 리소스들을 구분 지어 관리할 필요가 생김.
k8s 에서는 리소스를 논리적으로 구분하기 위해 `네임스페이스(Namespace)` 라는 오브젝트를 제공

#### [7.1.0.1] 네임스페이스 기본 개념 이해 

``` bash
# namespace 조회
kubectl get namespaces
kubectl get ns

# namespace 가 default 인 pods 조회
kubectl get po --namespace default
kubectl get po -n default

# 모든 네임스페이스의 리소스를 확인
kubectl get pods --all-namespaces
```

네임스페이스는 기본적으로 4개(`default`, `kube-node-lease`, `kube-public`, `kube-system`) 존재한다. 각 네임스페이스는 논리적인 리소스 공간이기 때문에 각 네임스페이스에는 파드, 레플리카셋, 서비스 와 같은 리소스가 따로 존재한다. (서비스, 레플리카셋을 비롯한 여러 리소스들도 각 네임스페이스에 별도로 존재한다.)

> `default` : 옵션을 명시하지 않으면 기본적으로 사용하는 namespace


> `kube-system` : k8s 클러스터 구성에 필수적인 컴포넌트들과 설정값 등이 존재하는 네임스페이스
> 
> 충분한 이해 없이는 건드리지 않는 것이 좋다.
>

k8s 의 리소스를 논리적으로 묶을 수 있는 가상 클러스터처럼 사용할 수 있다. Namespace는 대부분 모니터링, 로드 밸런싱 인그레스(Ingress) 등의 특정 목적을 위해 사용된다.

단, 논리적으로만 구분된 것일 뿐, 물리적으로 격리된 것이 아니다.

네임스페이스는 라벨보다 더욱 넓은 용도로 사용할 수 있다. 또한 k8s에서의 사용 목적에 따라 파드, 서비스 등의 리소스를 격리함으로써 편리하게 구분할 수 있다는 특징이 있다.

> 리눅스 Namespace 와는 완전히 다른 것이다.


#### [7.1.0.2] 네임스페이스 사용하기 

`production-namespace.yml` 적용
또는 `kubectl create namespace production` 

특정 네임스페이스에 리소스를 생성하는 방법은 `metadata.namespace` 에 명시하면 된다.

#### [7.1.0.3] 네임스페이스의 서비스에 접근하기
k8s 클러스터 내부에서는 서비스 이름을 통해 파드에 접근할 수 있다.

이는 `같은 네임스페이스 내의 서비스` 에 접근할 때에는 서비스 이름만으로 접근할 수 있다는 뜻이다.

즉, 다른 네임스페이스에 존재하는 서비스에는 서비스 이름만으로 접근할 수 없다.
하지만 `<서비스 이름>.<네임스페이스 이름>.svc` 처럼 서비스 이름 뒤에 네임스페이스 이름을 붙이면 다른 네임스페이스의 서비스에도 접근할 수 있다.

> 서비스의 DNS 이름에 대한 FQDN(Fully Qualified Domain Name) 은 일반적으로 다음과 같은 형식으로 구성돼 있다.
> 
> ` <서비스 이름>.<네임스페이스 이름>.svc.cluster.local `

네임스페이스의 삭제는 `kubectl delete namespace production` 으로 가능

#### [7.1.0.4] 네임스페이스에 종속되는 쿠버네티스 오브젝트와 독립적인 오브젝트
파드, 서비스, 레플리카셋, 디플로이먼트는 네임스페이스 단위로 구분할 수 있다.

예를 들어, A네임스페이스를 만들고 그안에 파드를 만들었을 때, B에서는 보이지 않는 경우가 있는데 이 경우를 `오브젝트가 네임스페이스에 속한다. (namespaced) ` 라고 표현한다.

``` bash
# 네임스페이스에 속하는 오브젝트의 종류를 조회
kubectl api-resources --namespaced=true

```

반대로 네임스페이스에 속하지 않는 오브젝트가 있다. 대표적으로 Node 가 있다.

노드처럼 네임스페이스에 속하지 않는 오브젝트들은 보통 네임스페이스에서 관리되지 않아야 하는, 클러스터 전반에 걸쳐 사용되는 경우가 많다.

> k8s의 `kubeconfig` 라는 파일을 수정함으로써 기본 네임스페이스를 `default` 에서 다른 namespace로 바꿀 수 있다.