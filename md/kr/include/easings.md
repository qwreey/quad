
=== "미리보기"
    <div align=center markdown>
    <video autoplay muted loop src="/kr/assets/easingVideo.mp4"></video>
    </div>

=== "그래프 개형"
    <div align=center markdown>
    ![함수 개형](/kr/assets/EasingStyles.jpg)  
    </div>

[모든 Easing 은 여기에서 직접적으로 확인할 수 있습니다.](https://easings.net/)  

`Linear`  
> 아무런 가감속이 없는 1차형 함수입니다  
> `#!ts i=x, x=0 to 1`  

---

`Quint`  
> 5 제곱을 이용한 가감속 함수입니다. Quart 보다 가파른 개형을 가졌습니다  
> `#!ts (^5) i=1-(1-x)^5, x=0 to 1`  

---

`Quart`  
> 네제곱을 이용한 가감속 함수입니다. Cubic 보다 가파른 개형을 가졌습니다  
> `#!ts (^4) i=1-(1-x)^4, x=0 to 1`  

---

`Cubic`  
> 세제곱을 이용한 가감속 함수입니다. Quad 보다 가파른 개형을 가졌습니다  
> `#!ts (^3) i=1-(1-x)^3, x=0 to 1`  

---

`Quad`  
> 제곱을 이용한 가감속 함수입니다.  
> `#!ts (^2) i=1-(1-x)^2, x=0 to 1`  

---

`Expo`  
> 지수형 가감속 함수입니다. 매우 가파른 개형을 가졌습니다.  
> `#!ts i=1-2^(-10*x), x=0 to 1`  

---

`Sin`  
> 사인 파형 가감속 함수입니다.  
> `#!ts i=sin(x*pi/2), x=0 to 1`  

---

`Circle`  
> 사분원 가감속 함수입니다.  
> `#!ts i=sqrt(1-(1-x)^2), x=0 to 1`  

---

`Back`  
> 시작시 뒤로 이동이 있는 가감속 함수입니다.  

---

`Elastic`  
> 탄성을 가지는 가감속 함수입니다.  

---

`Bounce`  
> 튀어오름을 가지는 가감속 함수입니다.  

TODO: 애니메이션 미리보기 영상 추가
