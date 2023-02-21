
# 버전 번경사항

## 2.22
더이상 Event.Prop 가 처음 생성시 실행되는 일이 일어나지 않습니다.

## 2.21
Linker 가 이제 클래스 안 클래스에서 사용될 수 있도록 변경되었습니다.

## 2.20
Docments 가 업데이트되었습니다. 많은양의 새로운 튜토리얼이 제공됩니다.  
Mkdocs 테마와 여러가지 설정이 변경되었습니다.  
이제 Makefile 을 통해서 rojo build 와 mkdocs build 를 사용할 수 있습니다.  

## 2.19
Linker 객체가 추가되었습니다. 이제 GetPropertyChangedSignal 와, self 에 특정 오브젝트 혹은 이벤트를 연결할 수 있습니다

## 2.18
이제 더이상 GC 에 의해 Store 의 Instance 값이 손실되지 않습니다

## 2.17
Tween 의 CallBack 등록 시 주언지는 파라메터가 변경되었습니다.  
이제 더이상 ~ 문이 사용되지 않습니다.  

## 2.15 BREAKING CHANGES
이제 Lang 에서 CurrentLocale, FailedMessage 을 변경하면 자동으로 변경사항이 업데이트됩니다. 또한 일부 필드의 네이밍이 변경되었습니다

## 2.14
Lang 모듈이 추가되었습니다. register 를 사용해 사용자 지정 다중언어 지원을 추가할 수 있습니다

## 2.13
Signal 모듈이 추가되었습니다. 이제 Class.Extend 에서 GetPropertyChangedSignal 과 EmitPropertyChangedSignal 를 사용할 수 있습니다

## 2.12
Mount 반환 객체에 Add 를 사용할 수 있도록 Mount 객체가 변경되었습니다

## 2.11
Store.GetObjects 에 이제 & 문법을 사용할 수 있습니다.

## 2.9
PreloadAsync 를 통해 이제 round.lua 에서 라운드 이미지를 미리 로드합니다.

## 2.8
반환 관련 코드가 exports 로 이주되었으며. init.lua 에서는 자동적으로 types 를 반환합니다.

## 2.7
이제 types 를 완전히 지원합니다. 직접 불러와 사용할 수 있습니다

## 2.1~2.6 BREAKING CHANGES
모든 모듈의 필드의 이름이 변경되었으며, 모든 클래스들이 기본적으로 대문자 시작 네이밍을 사용하도록 명명규칙을 변경했습니다.

## 2.0
버전 판올림, BREAKING CHANGES 를 위해 버전을 판올림 하였습니다.
