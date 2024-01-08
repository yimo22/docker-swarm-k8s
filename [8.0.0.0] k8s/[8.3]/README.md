## 인그레스의 세부 기능 : annotation을 이용한 설정

``` yaml
# test yaml
meatadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    kubernetes.io/ingress.class: 'nginx'
```
`kubernetes.io/ingress.class` : 해당 인그레스 규칙을 어떤 인그레스 컨트롤러에 적용할 것인지를 의미

`nginx.ingress.kubernetes.io/rewrite-target` : Nginx 인그레스 컨트롤러에서만 사용할 수 있는 기능으로, 인그레스에 정의된 경로로 들어오는 요청을 rewrite-targetㅇ에 설정된 경로로 전달한다.

rewrite-target 기능은 Nginx의 캡처 그룹(Capture groups) 와 함께 사용할 때 유용한 기능이다. 

> 캡처그룹이란, 정규 표현식의 형태로 요청 경로등의 값을 변수로서 사용할 수 있는 방법을 의미한다.

`ingress-rewrite-target-k8s-latest.yml` 파일을 통해서, Path를 regex로 필터 및 변수로 받아 동적인 라우팅이 가능하다

그 외에도 루트경로(/) 로 접근했을 떄 특정 path로 리다이렉트하는 `app-root 주석` 이나 SSL 리다이렉트를 위한 `ssl-redirect 주석` 등을 사용할 수 있다. 

Nginx 인그레스 컨트롤러에서 사용할 수 있는 주석은 ![공식사이트](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations)에서 확인할 수 있다.
(단, 이런 주석들은 Nginx 인그레스 컨트롤러에서만 사용할 수 있다.)
> 주석을 사용해도 별도의 기능을 사용할 수 있지만, 필요시 Nginx 인그레스 컨트롤러와 함께 생성된 컨피그맵을 수정해 직접  Nginx의 옵션을 설정할 수도 있다.