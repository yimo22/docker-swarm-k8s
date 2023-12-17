#### [5.4.0.0] 여러 서버로 구성된 쿠버네티스 클러스터 설치
쿠버네티스의 각종 기능을 제대로 사용하려면 최소한 3대 이상의 서버를 준비하는 것이 좋다.

> 설치전 check 할 항목들
> - 모든 서버의 시간이 ntp를 통해 동기화돼 있는지 확인
> - 모든 서버의 맥(MAC) 주소가 다른지 확인
> - 모든 서버가 2GB RAM, 2CPU 이상의 충분한 자원을 갖고 있는지 확인
> - `swapoff -a` 명령어를 통해 모든 서버에서 메모리 스왑(Swap)을 비활성화

#### [5.4.1.0] kubeadm 으로 k8s 설치
k8s에서 `kubeadm` 이라는 관리 도구를 제공

`kubeadm` 은 On-premise, 클라우드 상관없이 일반적인 리눅스 서버라면 모두 사용할 수 있음

<h5> 1. 쿠버네티스 저장소 추가 </h5>

``` bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
```
<h5> containerd 및 kubeadm 설치 </h5>
k8s는 컨테이너 런타임 인터페이스(CRI)를 지원하는 구현체를 통해 컨테이너를 사용. (containerd, cri-o)

``` bash
# 도커 설치
wget -q0- get.docker.com | sh

# containerd 기본 설정값으로 덮어씌운 뒤 containerd 재시작
containerd config default > /etc/containerd/config.toml
service containerd restart
```

- 컨테이너 런타임 인터페이스는 k8s 가 컨테이너를 제어할 때 사용하는 일종의 프로토콜 이다.
  - 인터페이스로서 정의한 표준화된 규격을 컨테이너 런타임 인터페이스라고 한다.
> 도커를 설치하면 자동으로 containerd를 사용하도록 설정된다. 이는 도커만 사용하는 사용자의 입장에서는 containerd 및 컨테이너 런타임 인터페이스의 존재를 몰라도 도커를 사용하는 데는 큰 지장이 없다.
>
> 하지만, k8s 는 컨테이너 런타임 인터페이스를 사용하므로 containerd나 cri-o 같은 도구를 통해 컨테이너를 제어하도록 설정해야 한다. 

<h5> 3. 쿠버네티스 클러스터 초기화 </h5>

``` bash
kubeadm init --apiserver-advertise-address [IP] \
--pod-network-cidr=[IP] --cri-socket /run/containerd/containerd.sock
```

k8s 1.20 버전부터, docker를 CRI로 사용할 수 없도록 바뀌었다. 따라서 `--cri-socket`  을 통해서 별도 지정이 필요

<h5> 4. 컨테이너 네트워크 애드온 설치 </h5>
쿠버네티스의 컨테이너 간 통신을 위해서 calico, flannel, weavyNet 등 여러 오버레이 네트워크를 사용할 수 있다.

``` bash
# Calico 설치
kubectl apply -f https://docs.projectcalico.org/v3.22/manifests/calico.yaml
```


> Calico 의 경우, 기본 `--pod-network-cidr` 을 `192.168.0.0/16` 으로 설정한다. 이외에 별도로 설정한 경우, 추가 설정이 필요하다
> Calico.yaml 을 다운받아, CALICO_IPV4POOL_CIDR 환경변수의 각주를 해제한 후 적절한 IP 대역 입력

이후 다음의 명령어를 통해서 설치가 정상적으로 완료됐는지 확인 및 핵심 컴포턴트들의 실행목록을 확인
- `kubectl get pods --namespace kube-system`

``` bash
# 쿠버네티스 삭제 및 초기화
sudo kubeadm reset

# /etc/kubernetes 의 폴더에 기존 정보들이 남아있음, 따라서 백업|삭제 필요
sudo rm -rf /etc/kubernetes/*
```


#### [5.4.2.0] kops 로 AWS 설치하기 

kops 는 클라우드 플랫폼에서 k8s 를 쉽게 설치할 수 있도록 도와주는 도구이다.

kubeadm 은 쿠버네티스를 설치할 서버 인프라를 직접 마련해야 하지만, kops 는 서버 인스턴스와 네트워크 리소스 등을 클라우드에서 자동으로 생성해 쿠버네티스를 설치한다.

- 쉽게 서버 인프라를 프로비저닝해 k8s를 설치할 수 있다는 것이 특징이다.

(생략)

#### [5.4.3.0] 구글 클라우드 플랫폼의 GKE로 쿠버네티스 사용하기

kubeadm 이나 kops 로 쿠버네티스를 설치하는 것이 어렵다면, 설치부터 관리까지 전부 클라우드 서비스로 제공하는 EKS, GKE 등의 매니지드 서비스를 사용하는 것도 좋다.

(생략)