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

kubeadm init --apiserver-advertise-address 192.168.0.33 \
--pod-network-cidr=192.168.0.0/16 --cri-socket /run/containerd/containerd.sock
