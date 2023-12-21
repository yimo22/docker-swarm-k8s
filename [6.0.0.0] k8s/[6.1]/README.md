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
