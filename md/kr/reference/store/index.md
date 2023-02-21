
# Store

`#!ts Store.GetStore(id:string?)->store`  
> 값들을 저장하고 레지스터를 생성할 수 있는 값 저장소를 반환합니다.

---

`#!ts Store.GetObject(id:string)->Object?`  
> 해당 id 를 가진 생성된 오브젝트를 반환합니다.  

---

`#!ts Store.GetObjects(id:string)->objectList?`  
> 해당 id 를 가진 생성된 오브젝트들을 반환합니다. 반환은 [objectList](./objectList.md) 타입을 가지고 있습니다.  
> 고급 ID 를 사용할 수 있습니다. 자세한 사항은 [튜토리얼 문서](../../tutorial/3_getObject.md#id)를 확인하세요.  
