## [7.2] 컨피그맵(Configmap), 시크릿(Secret) - 파드에 설정값 전달
App 개발의 대부분은 설정값을 갖고 있다. 이러한 설정값을 설정하는 방법은 다음 중 하나일 것이다.
1. 내부(도커 이미지)에 설정 파일을 정적으로 저장
2. YML 파일에 환경 변수를 직접 적어두는 하드코딩 방식

이런 경우, 상황에 따라서 환경변수의 값만 다른 동일한 YML 파일이 존재할 수 있다는 단점을 갖고 있다. (운영환경과 개발환경에서 각각 디플로이먼트를 생성해야 하는 경우, 환경 변수가 다르게 설정된 두가지 버전의 YML 파일이 따로 존재해야 한다.)

k8s 는 YML 파일과 설정값을 분리할 수 있는 `컨피그맵(Configmap)` 과 `시크릿(secret)` 이라는 오브젝트를 제공한다.

컨피그맵을 활용하면 1개의 파드 YML파일만을 사용하되 환경에 따라 다른 컨피그맵을 생성해 사용하면 된다. 즉, 환경변수나 설정값까지 k8s 오브젝트에서 관리할 수 있으며 이러한 설정값 또한 YML파일로 파드와 함께 배포할 수도 있다.


### [7.2.1.0] 컨피그맵

#### [7.2.1.1] 컨피그맵 사용방법 익히기
컨피그맵은 일반적인 설정값을 담아 저장할 수 있는 k8s 오브젝트이며, 네임스페이스에 속하기 때문에 네임스페이스별로 컨피그맵이 존재한다.

컨피그맵은 `kubectl create configmap` 명령어를 사용하여 생성할 수 있다.

``` bash
# ConfigMap 생성
kubectl create configmap <컨피그맵이름> <각종설정들>
kubectl create cm <컨피그맵이름> <각종설정들>

# 여러 개의 K-V 값을 사용한 설정
kubectl create configmap <컨피그맵이름> --from-literal <Key=Value>
```

컨피그맵을 파드에서 사용하는 방법은 크게 2가지로 나눌 수 있다.
1. ConfigMap 의 값을 컨테이너의 환경 변수로 사용

    ConfigMap에 저장된 Key-Value 데이터가 컨테이너의 환경 변수의 K-V 값으로 그대로 사용된다. 
    따라서 `echo $ENV_VAR` 와 같은 방식으로 값을 확인할 수 있다.

    Application이 시스템 환경 변수로부터 설정값을 가져온다면 이 방법을 선택하는 것이 좋다.

2. ConfigMap 의 값을 파드 내부의 파일로 마운트해 사용

    ConfigMap의 값을 파드 컨테이너 내부의 특정 파일로 마운트한다. 
    예를 들어, `LOG_LEVEL=INFO` 라는 값을 가지는 컨피그맵을 `/etc/config/log_level` 이라는 파일로 마운트하면 log_level 파일에 INFO 라는 값이 저장된다. 
    이때 파일이 위치할 경로는 별도로 지정할 수 있다.

    Nginx의 `nginx.conf` 와 같은 파일을 통해 설정한다면 이 방법을 사용하는 것이 좋다.


> 실제 운영환경에서는 Deploy 를 자주 사용하여 적용한다. 또한 파드에서 ConfigMap을 사용하는 설정은 Deployment 를 비롯한 대부분의 오브젝트에서 동일하게 사용할 수 있다.

`all-env-from-configmap.yml` 에서 `envFrom` 항목은 하나의 컨피그맵에 여러 개의 Key-Value 쌍이 존재하더라도 모두 환경 변수로  가져오도록 설정한다.

``` bash
# 해당되는 환경변수 조회
kubectl exec container-env-example env
```

> 조회를 통해서 여러 개의 환경 변수가 미리 설정된 것을 확인할 수 있다. k8s가 자동으로 서비스에 대한 접근 정보를 컨테이너의 환경 변수로 설정하기 때문이다.
>
> `KUBERNETES_` 로 시작하는 환경 변수는 default 네임스페이스에 존재하는 kubernetes라는 서비스에 대한 것이다.

생성된 컨피그맵을 파드에서 사용하려면 Deployment 등의 YML 파일에서 파드 템플릿 항목에 컨피그맵을 사용하도록 정의하면 된다.
``` yml
spec:
  containers:
  - name: my-webserver
    env:
    - name: ENV_KEYNAME_1
      valueFrom:
        configMapKeyRef:
          name: log-level-configmap
          key: LOG_LEVEL

```
`valueFrom` 과 `configMapKeyRef` 를 사용하면 K-V 쌍이 들어있는 컨피그맵에서 특정 데이터만을 선택해 환경 변수로 가져올 수 있다.

- `spec.containers.env.name` : 컨테이너에 새롭게 등록될 환경 변수 이름
- `spec.containers.env.valueFrom.configMapKeyRef.name` : 가져올 ConfigMap 의 대상
- `spec.containers.env.valueFrom.configMapKeyRef.key` : 가져올 데이터 값의 키

즉, ConfigMap 으로부터 설정을 가져오는 것은 2가지로 YML에 정의할 수 있다.
1. `envFrom` : 컨피그맵에 존재하는 모든 K-V 쌍을 가져온다.
2. `valueFrom` + `configMapKeyRef` : 컨피그맵에 존재하는 K-V 쌍 중에서 원하는 데이터만 선택적으로 가져온다.

#### [7.2.1.2] ConfigMap 의 내용을 파일로 파드 내부에 마운트하기
`volume-mount-configmap.yml` 에서는 `volumeMounts` 와 `Volumes`를 사용했다.

> `spec.volumes` : YML 파일에서 사용할 볼륨의 목록을 정의
> `spec.containers.volumeMounts` : volumes 항목에서 정의된 볼륨을 컨테이너 내부의 어떤 디렉터리에 마운트할 것인지 명시

컨피그맵의 모든 K-V 쌍 데이터가 마운트됐으며, 파일 이름은 키의 이름과 같다.
> ConfigMap 과 같은 K8s 리소스의 데이터를 파드 내부 디렉터리에 위치시키는 것을 k8s 공식 문서에서는 투사(Projection) 이라고 한다.

`selective-volume-configmap.yml` 에서 원하는 K-V 데이터만 선택해서 파드에 파일로 가져올 수도 있다.

`items` : ConfigMap 에서 가져올 K-V의 목록을 의미
`path` : 최종적으로 디렉터리에 위치할 파일의 이름을 입력하는 항목

#### [7.2.1.3] 파일로부터 ConfigMap 생성하기
컨피그맵을 볼륨으로 파드에 제공할 때는 대부분 설정 파일 그 자체를 컨피그맵으로 사용하는 경우가 많다. 이러한 경우를 위해 k8s 에서는 컨피그맵을 파일로부터 생성하는 기능을 제공한다.

단순 문자열 값을 이용해 컨피그맵을 생성할 때는 `kubectl create configmap --from-literal ` 했지만, 파일로부터 컨피그맵을 생성하려면 `--from-file` 옵션을 사용하면 된다.

`--from-file` 옵션에서 별도의 키를 지정하지 않으면 파일 이름이 Key 이고, 파일의 내용이 Value로 저장된다.
별도의 키로 지정할 때는 `--from-file ${KEY}=index.html` 과 같이 사용한다.

`--from-env-file` 옵션을 통해서 여러 개의 K-V 형태의 내용으로 구성된 설정 파일을 한꺼번에 컨피그맵으로 가져올 수 있다.

일단 컨피그맵으로 생성되고 나면, 컨피그맵의 내용이 파일이든지 문자열이든지 상관없이 사용 방법 자체는 똑같다.

> 정적파일을 파드에 제공하려면 `--from-file` 을 사용하는것이 편리할 수 있고, 여러 개의 환경 변수를 파드로 가져와야 한다면 `--from-env-file` 옵션을 사용하는 것이 편리할 수 있다.

#### [7.2.1.4] YML 파일로 컨피그맵 정의하기
컨피그맵을 반드시 명령어를 통해 생성해야 하는 것은 아니다.

``` bash
# 필요한 yml 출력
kubectl create configmap my-configmap \
--from-literal mykey=myvalue \
--dry-run -o yaml

# 필요 yml파일 생성
kubectl creaate configmap my-configmap \
--from-literal mykey=mvalue --dry-run -o yaml > my-config.yml

# 적용
kubectl apply -f my-configmap.yml
```

> dry run 이란 특정 작업의 실행 가능 여부를 검토하는 명령어 또는 API를 의미한다. 각 명령어에 `--dry-run` 옵션을 추가하면 실행 가능 여부를 확인할 수 있으며 실제로 k8s 리소스를 생성하지는 않는다.

ConfigMap 에서 K-V 데이터가 너무 많아지면 YML 파일의 길이가 불필요하게 커질 수 있다. 이를 위해서 k8s에서는 kubectl 1.14 버전부터 사용할 수 있는 `kustomize` 기능을 제공하며, 이를 사용하면 편하게 컨피그맵을 생성할 수 있다.

### [7.2.2] 시크릿 (Secret)

#### [7.2.2.1] 시크릿 사용방법 익히기
시크릿은 SSH 키, 비밀번호 등과 같이 민감한 정보를 저장하기 위한 용도로 사용되며, 네임스페이스에 종속되는 k8s 오브젝트이다. 

ConfigMap과 유사하기 때문에, `--from-literal` 대신 `--from-file` or `--from-env-file` 옵션을 이용해 파일로부터 값을 읽어와 사용해도 된다.

``` bash
kubectl create secret generic \
my-password --from-literal password=1q2w3e4r
```

``` bash
# file을 이용한 적용
echo mypassword > pw1 && echo yourpassword > pw2 &&
kubectl create secret generic \
our-password --from-file pw1 --from-file pw2
```

`kubectl describe secret` 을 통해서 자세히 조사하면, K-V 에서 값에 해당하는 부분이 이상한 값으로 변형되어 있다. 이는 시크릿에 값을 저장할 때, k8s가 기본적으로 base64 로 값을 인코딩하기 때문이다.

`echo ${password} | base64 -d` 를 통해서, data부분의 값을 base64로 디코딩하면 다시 복호화를 할 수 있다.

YML 파일로부터 시크릿을 생성할 때도 데이터의 값에 base64로 인코딩이 된 문자열을 사용해야 한다.
