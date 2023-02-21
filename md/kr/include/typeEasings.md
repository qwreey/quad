```ts
type Easing =
	"Linear" // 아무런 가감속이 없는 1차형
	|"Quint" // 5 제곱
	|"Quart" // 네제곱
	|"Cubic" // 세제곱
	|"Quad" // 제곱
	|"Sin" // 사인 파형
	|"Circle" // 사분원
	|"Expo" // 지수형
	|"Elastic" // 탄성
	|"Bounce" // 튀어오름
	|"Back" // 뒤로 가감속
	|"Exp2" // 덜 가파른 지수 i=exp(x)/max, x=-4 to 2
	|"Exp4" // 더 가파른 지수 i=exp(x)/max, x=-4 ~ 4
	|EasingFunction?;
```