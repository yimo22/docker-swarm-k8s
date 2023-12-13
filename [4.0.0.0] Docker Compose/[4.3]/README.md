#### [4.3] 도커 컴포즈 사용

#### [4.3.1.0] 도커 컴포즈 기본 사용법

도커 컴포즈는 설정이 정의된 YAML 파일을 읽어 도커 엔진을 통해 컨테이너를 생성

``` bash
docker-compose up -d
```

#### [4.3.1.1] docker-compose.yml 작성과 활용
``` yaml
version: '3.0' # [1, 2, 2.1, 3.0] 등의 버전이 있다.
services: # 생성될 컨테이너들을 묶어놓은 단위
  web:    # 생성될 서비스의 이름
    image: alicek106/composetest:web
    ports:
      - "80:80"
    links:
      - mysql:db
        command: apachectl -DFOREGROUND
    mysql:
        image: alicek106/composetest:mysql
        command: mysqld
```

> YAML 파일에서 들여쓰기할 때 탭(Tab)은 도커 컴포즈가 인식하지 못하므로, 2개의 공백(space)를 사용해서 하위 항목을 구분


어떤 설정을 하지 않으면 도커 컴포즈는 현재 디렉터리의 docker-compose.yml 파일을 읽어 로컬의 도커 엔진에게 컨테이너 생성을 요청.

``` bash
# 조회
docker-compose ps 
```
#### [4.3.1.2] 도커 컴포즈의 프로젝트, 서비스, 컨테이너

도커 컴포즈는 컨테이너를 프로젝트 및 서비스 단위로 구분

``` text
[프로젝트이름]_[서비스이름]_[서비스내컨테이너의번호]
```

스웜모드에서의 서비스와 마찬가지로, 하나의 서비스에는 여러개의 컨테이너가 존재할 수 있다. 그리고 차례대로 증가하는 컨테이너의 번호를 붙여 서비스내의 컨테이너를 구별한다.

``` bash
# 여러개의 컨테이너 생성
docker-compose scale mysql=2

# 특정 서비스의 컨테이너만 생성
docker-compose up -d mysql

# run 명령어로 컨테이너 생성
# web 컨테이너 생성
docker-compose run web /bin/bash
```

#### [4.3.2.0] 도커 컴포즈의 활용

#### [4.3.2.1] YAML 파일 작성

YAML 파일은 크게 4가지로 구성된다.
- 버전 정의
- 서비스 정의
- 볼륨 정의
- 네트워크 정의

> 도커 컴포즈는 기본적으로 현재 디렉터리 또는 상위 디렉터리에서 docker-compose.yml 이라는 yaml파일을 찾아서 컨테이너를 생성한다. <br>
> -f 옵션을 통해서 yaml 파일의 위치와 이름을 지정할 수 있음 <br>
> -p 옵션을 통해서 프로젝트의 이름을 명시할 수 있음

1. 버전 정의 <br>
YAML 파일 포맷에는 버전 1, 2, 2.1, 3이 있다. 버전 별 호환이 되는 버전을 사용하는 것이 좋다.
2. 서비스 정의 <br>
도커 컴포즈로 생성할 컨테이너 옵션을 정의. 이 항목들은 하나의 프로젝트로서 도커 컴포즈에 의해 관리된다.
    ``` text
    - image: 컨테이너 생성할 때 쓰일 이미지 이름
    - links: 다른 서비스에 서비스명만으로 접근할 수 있도록 설정, 생성/실행 순서도 결정
    - environment: 컨테이너 내부에서 사용할 환경변수
    - command: 컨테이너가 실행될 때 수행할 명령어 설정
    - depends_on: 특정 컨테이너에 대한 의존관계
    - ports: 포트 설정, `docker-compose scale` 명령어로 서비스의 컨테이너의 수를 늘릴 수 없음.

    - build: build 항목에 정의된 Dockerfile에서 이미지를 빌드해 서비스의 컨테이너를 생성
    build 항목에서는 Dockerfile 에 사용될 컨텍스트나 Dockerfile의 이름, Dockerfile에서 사용될 인자값을 설정할 수 있음
    ex)
    services:
      web:
        build: 
        context:
        dockerfile:
        args:
          arg1: value1
    
    - 'docker-compose up --no-deps [SERVICE_NAME]' : 특정 서비스의 컨테이너만 생성하되 의존성이 없는 컨테이너 생성

    - extends: 다른 YML 파일이나 현재 YML 파일에서 서비스 속성을 상속, 이는 잘 동작하지 않을 수 있어 버전확인이 필요
    ```

    > links, depends_on 은 실행순서만 결정할 뿐 컨테이너 내부의 준비상태를 확인하지 않는다.

    > build 항목을 yaml 파일에 정의해 프로젝트를 생성하고 난 뒤 Dockerfile을 변경하고 다시 프로젝트를 생성해도 이미지를 새로 빌드하지 않는다. 이때 __`--build`__ 옵션을 추가하거나 __docker-compose build__ 명령어를 사용.
3. 네트워크 정의 <br>
    - driver <br>
        도커 컴포즈는 생성된 컨테이너를 위해 기본적으로 브릿지 타입의 네트워크를 생성. 그러나 driver 항목을 정의해서 이를 바꿀 수 있음
        ``` yml
        version: '3.0'
        services:
          myservice:
            image: nginx
            networks:
              - mynetwork
        
        networks: 
          mynetwork:
            driver: overlay
            driver_opts:
              IPAdress: "10.0.0.2 "
              subnet: "255.255.255.0"
        ```
    - ipam <br>
    IPAM(IP Address Manager)를 위해 사용할 수 있는 옵션으로서 subnet, ip 범위 등을 설정할 수 있다. driver 항목에는 IPAM을 지원하는 드라이버의 이름을 입력한다.
        ``` yml
        networks: 
          ipam:
            driver: mydriver
            config:
              subnet: "172.20.0.0/16"
              ip_range: "172.20.5.0/24"
              gateway: "172.20.5.1"
        ```

    - external <br>
    YAML 파일을 통해 프로젝트를 생성할 때마다 네트워크를 생성하는 것이 아닌, 기존의 네트워크를 사용하도록 설정. 이를 설정하려면 사용하려는 외부 네트워크의 이름을 하위 항목으로 입력한 뒤 external의 값을 true로 설정한다.
        ``` yml
        networks:
          alicek106_network:
            external: true
        ```
    
4. 볼륨 정의
   - driver <br>
   볼륨을 생성할 때 사용될 드라이버를 설정. (default : local) driver_opts를 통해 인자로 설정할 수 있음.
        ``` yaml
        volumes:
          driver: flocker
            driver_opts:
              opt: "1"
              opt2: 2
        ```
   - external <br>
   외부의 볼륨을 사용
        ``` yaml
        volumes:
          myvolume:
            external: true
        ```

5. YAML 파일 검증
   ``` bash
   # 파일 검증
   docker-compose -f [YML파일경로] config
   ```
#### [4.3.2.2] 도커 컴포즈 네트워크
YML파일에 네트워크 항목을 정의하지 않으면 도커 컴포즈는 프로젝트별로 브리지 타입의 네트워크를 생성한다. 

생성된 네트워크의 이름은 '[프로젝트이름]_default' 로 설정되며, `docker-compose up`으로 생성되고 `docker-compose down` 으로 삭제된다.

docker-compose scale 명령어로 생성되는 컨테이너 전부가 이 브리지 타입의 네트워크를 사용. 서비스 내의 컨테이너는 `--net-alias` 가 서비스의 이름을 갖도록 자동으로 설정되므로, 이 네트워크에 속한 컨테이너는 서비스의 이름으로 서비스 내의 컨테이너에 접근할 수 있음.