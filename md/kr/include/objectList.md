`#!ts :Each((item:any, index:number)->())`  
> 일반적인 반복입니다. for 를 사용하는것과 효과가 같으나 함수를 이용합니다  

---

`#!ts :EachAsync((item:any, index:number)->())`  
> 반환을 기다리지 않고 바로바로 다음 아이템으로 넘어갑니다.  
> 코루틴이 이용됩니다. `wrap()` 코루틴을 모르거나, 필요성이 없는경우 일반적으로 `#!ts :Each` 를 사용해도 됩니다  

---

`#!ts :IsEmpty()`  
> 이 ObjectList 가 비어있는지 여부를 반환합니다.  

---

`#!ts :Remove(indexOrItem:number|any)`  
> objectList 에서 해당하는 오브젝트를 제거합니다.  
> , & 를 사용한 고급 검색에서는 작동하지 않습니다  
