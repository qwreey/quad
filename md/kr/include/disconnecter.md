`#!ts :Add(connection:Connection|RBXScriptConnection)`  
> `connection`을 리스트에 추가합니다. 나중에 `:Disconnect`를 호출하면 추가된 연결이 파기됩니다.  

---

`#!ts :Disconnect()`  
> 추가된 모든 연결에 `Disconnect()` 를 수행합니다. 이 호출 후에 추가된 연결은 모두 사라지며. 이 요청 후에도 다시 `:Add` 를 사용할 수 있습니다  
> Disconnecter 를 완전히 사용하지 못하도록 하려면 `:Destroy` 를 호출하세요  

---

`#!ts :Destroy()`  
> `#!ts :Disconnect()` 를 수행한 후, 객체를 더이상 사용할 수 없도록 만듭니다.  
> `id` 가 등록되어 있는경우 저장소에서 파기하게 됩니다.  
