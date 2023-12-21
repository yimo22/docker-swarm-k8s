
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
