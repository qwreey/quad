
`#!ts :Fire(...any)`  
> 등록된 연결들을 실행하고, `Wait` 을 풀어줍니다.  

---

`#!ts :Wait()->(...any)`  
> `Fire` 가 호출될 때 까지 기다립니다. `Fire` 에 사용된 값이 반환됩니다.  

---

`#!ts :Connect((...any)->())->Connection`  
> `Fire` 가 호출 될 때 함수가 실행되도록 만듭니다. `Fire` 에 사용된 값이 호출 인자로 사용됩니다. 연결을 끊을 수 있도록 `Connection` 이 제공됩니다.  

---

`#!ts :Once((...any)->())->Connection`  
> `Connect` 와 유사하지만, `Fire` 가 한번 호출된 뒤 연결이 끊어집니다/  

---

`#!ts :CheckConnected(func)->boolean`  
> 함수가 이미 등록되어 있는지 여부를 반환합니다.  

---

`#!ts :DisconnectAll()`  
> 모든 연결을 끊습니다. `Wait` 으로 기다리고 있는 곳에는 `nil` 을 반환합니다.  

---

`#!ts :Destroy()`  
> `#!ts :DisconnectAll()` 를 수행한 후, 객체를 더이상 사용할 수 없도록 만듭니다.  
> `id` 가 등록되어 있는경우 저장소에서 파기하게 됩니다.  
