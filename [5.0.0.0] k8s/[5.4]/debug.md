#### 라즈베리파이 4B 로 클러스터 설정

1. OS 설치
    - Rasbian OS Lite(64bit/Legacy-Debian bullseye)
2. 기본 프로그램 설정
    - setup.sh 파일 실행


### DEBUG
#### [Error 1]. CGROUPS_MEMORY: missing
cgroup 관련 설정이 미흡
   - `/boot/cmdline.txt` 에 `cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1` 을 붙여넣기
   - 위의 텍스트를 문서의 맨처음으로 놓을경우, 부팅이 안될 수 있으니 첫번쨰 라인의 붙여넣기로 텍스트 붙여넣기

#### [Error 2]. E: The repository 'https://download.docker.com/linux/ubuntu bullseye Release' does ~~
Os 버전과 apt의 source url 이 일치하지 않아서 발생하는 문제.
또는 해당하는 소스 url이 존재하지 않을 경우 발생하는 문제

- `/etc/apt/source.list.d` 의 파일을 vim 으로 열어, 알맞은 url 로 수정하기
  - Rasbian OS 는 debian 으로 되어있지만, 보통은 ubuntu로 설정되어 있어 오류가 나는 경우가 많았다.
  - `ubuntu`로 된 부분을 전부 `debian`으로 고친후, apt update 하면 정상작동

``` bash
# 새로운 apt 등록
sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/debian \
xenial \
stable"

# apt update 후에 docker 설치
sudo apt-get update && sudo apt-get install docker-ce
```


#### [Error 3]. [kubelet-check] It seems like the kubelet isn't running or healthy.
> [kubelet-check] It seems like the kubelet isn't running or healthy.
> [kubelet-check] The HTTP call equal to 'curl -sSL http://localhost:10248/healthz' failed with error: Get "http://localhost:10248/healthz": dial tcp [::1]:10248: connect: connection refused.

Kubelet이 master의 kubelet과 통신을 하여 연결을 할 수 없는 경우 발생하는 문제로 추정.

`journalctl -u kubelet -f` 명령어를 통해서 에러로그 디버깅 필요
- CHK1) 방화벽이 오픈되어 있는가? (master & slave)
  - `telnet [IP_ADDRESS] [PORT] ` 를 통해서 정상 작동하는지 확인
- CHK2) docker의 daemon에서 사용하는 설정을 변경
  - `sudo vim /etc/docker/daemon.json` 을 통해서 파일 열기
  - 다음의 문구로 바꾸기
    ``` json
    {
        "exec-opts": ["native.cgroupdriver=systemd"],
        "log-driver": "json-file",
        "log-opts": {
                "max-size": "100m"
        },
        "storage-driver": "overlay2"
    }
    ```
  - `sudo systemctl daemon-reload` : 데몬 재시작
  - `sudo systemctl restart docker` : 도커 재시작
  - `sudo systemctl restart kubelet` : kubelet 재시작
  - 이후 다시 slave 노드에서 join

#### [Error 4]. kubectl 관련 권한 문제 
k8s의 정보들은 admin.conf에 기본정보가 저장되어 있는데, 이 정보들에 대하여 접근을 할 수 없기 때문에 발생하는 문제

보통 master 노드에서 init을 최초로 실행하면 다음과 같은 문구를 통해 설정하도록 유도함
``` text
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/
```

위의 유도대로, <br>__1. 3줄의 명령어를 통해서 설정__ <br> __2. KUBECONFIG 환경변수 설정__ <br> 을 통해서 해결이 가능하다.

단, 1과 2 둘다 실행하면 설정이 꼬일 수 있으니 주의.


####  Kubernetes 관련 초기화
``` bash
# kubeadm 초기화
sudo kubeadm reset 
sudo rm -rf /etc/cni/net.d/*
sudo rm -rf /etc/kubernetes/*
sudo systemctl restart kubelet
```