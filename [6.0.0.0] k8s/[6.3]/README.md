
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
