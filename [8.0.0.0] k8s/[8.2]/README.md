## [8.2] 인그레스의 구조
인그레스는 k8s에서 `kubectl get ingress` 명령어로 목록을 확인할 수 있다.

``` bash
# 조회
kubectl get ingress
kubectl get ing
```

`ingress-example-k8s-latest.yml` 를 통해서 인그레스를 생성할 수 있다.
``` yml
# ingress-example-k8s-latest.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-example
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    kubernetes.io/ingress.class: "nginx"

spec:
  rules:
  - host: test.example.com       # 해당 도메인 이름으로 접근하는 요청에 대해서 처리 규칙을 적용
    http:
      paths:
      - path: /echo-hostname          # 경로에 대한 요청 라우팅 
        pathType: Prefix
        backend:
          service:
            name: hostname-service    # path로 들어온 요청이 전달될 서비스와 포트이다.
            port:
              number: 80

```
- `host` : 해당 도메인 이름으로 접근하는 요청에 대한 처리 규칙(여러개의 host를 정의해 사용가능)
- `path` : 해당 경로로 들어온 요청을 어느 서비스로 전달할 것인지 명시
- `name, port` : path로 들어온 요청이 전달될 서비스와 포트
> ingress를 정의하는 YML 파일 중에서 annotation 항목을 통해 인그레스의 추가적인 기능을 사용할 수 있다.

ingress는 단지 요청을 처리하는 규칙을 정의하는 선언적인 오브젝트일 뿐, 외부 요청을 받아들일 수 있는 실제 서버가 아니다. ingress 는 ingress controller 라고 하는 특수한 서버에 적용해야만 그 규칙을 사용할 수 있다. 

즉, 실제로 외부 요청을 받아들이는 것은 `Ingress Controller` 서버이며, 이 서버가 인그레스 규칙을 로드해 사용한다.

Ingress Controller는 여러 종류가 있으며, 필요에 따라 선택해 사용한다.
- Nginx 웹서버 인그레스 컨트롤러
- Kong API GATEWAY
- GKE 인그레스 컨트롤러

``` bash
# nginx 는 k8s에서 공식적으로 개발하고 있다.
# 따라서 다음의 명령어로 직접 내려받을 수 있다.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.0/deploy/static/provider/aws/deploy.yaml

# 필요한 namespace, 디플로이먼트, 컨피그맵 등을 생성한다.
# 조회
kubectl get po,deploy -n ingress-nginx
```
Nginx ingress controller 설치하면 자동으로 생성되는 서비스는 LoadBalancer 타입이다.
LoadBalancer 타입에 DNS이름을 할당함으로써 Nginx 인그레스 컨트롤러에 접근하는 것이 일반적이다.

하지만 가상 머신처럼 클라우드가 아닌 환경에서 인그레스를 테스트하고 싶다면 `LoadBalancer` 대신 `Nodeport` 타입의 서비스를 생성해 사용해도 된다. 이 경우에는 각 노드의 랜덤한 포트로 Nginx 인그레스 컨트롤러에 접근할 수 있다. 

`ingress-nginx-svc-nodeport.yaml` 을 통해서 해당하는 Service를 생성할 수 있다. 또한 별도의 deployment 와 service를 만들어 작동을 확인할 수 있다.

> 인그레스 컨트롤러에 의해 요청이 최종적으로 도착할 디플로이먼트의 서비스는 어떤 타입이든지 상관은 없다.
>
> 다만, 외부에 서비스를 노출할 필요가 없다면 ClusterIP타입을 사용하는게 좋다. 

> 추가 동작확인
> 
> 1. `kubectl get po,svc -n ingress-nginx` 를 통해서 해당하는 정보들을 조회한다.
> 
>     조회를 하면, pod들과 3가지의 service 를 확인할 수 있다. 각 service의 타입은 [LoadBalacner | ClusterIP | NodePort] 이다. 이때 Cloud를 사용하지 않을 경우, LoadBalancer 타입의 svc는 <pending> 으로 표시된다.
>
> 2. `curl <CLUSTER-IP>/echo-hostname` 명령어를 통해 조회
>
>     나는 On-premise 환경에서 k8s 클러스터를 구축했기 때문에, `NodePort` 에 있는 ClusterIP를 적용했다. 
>
>     이렇게 적용하고 조회를 하면, 404 NOTFOUND 로 구성된 HTML 페이지를 응답받는다. 이는 인그레스를 생성할 때 Nginx 인그레스 컨트롤러에 `도메인이름` 으로 접근했을 떄만 응답을 처리하도록 설정했기 때문이다. 따라서 해당 도메인이 아닌 다른 도메인 이름으로 접근할 때는 Nginx 인그레스 컨트롤러가 해당 요청을 처리하지 않는다.
>
>     이를 위해 `/etc/hosts` 에서 해당되는 `<CLUSTER_IP> <HOST_NAME>` 형식으로 도메인을 추가하여 테스트를 계속 진행한다.
>
> 3. ` curl --resolve <HOST-NAME>:31000:<노드 중 IP> <HOST-NAME>/echo-hostname` 으로 정상작동 조회

