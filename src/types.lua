-------------------
-- module_class
-------------------
export type extend = {
	Getter: {[string]: ()->(any?)?};
	Setter: {[string]: (value:any)->()?};
	New: (prop:DOM_constructor)->DOM|any;
	Init: (self:extend,props:store)->();
	Render: (self:extend,props:store)->(DOM|any);
	AfterRender: (self:extend,item:DOM|any,props:store)->();
	GetPropertyChangedSignal: (self:extend,propertyName:string)->signal;
	EmitPropertyChangedSignal: (self:extend,propertyName:string,...any)->();
	Update: (self:extend)->();
	Destroy: (self:extend)->();
	UpdateTriggers: {[string]:boolean?};
}
export type DOM = {
	[string]: any;
	Destroy: (self:DOM)->();
	GetPropertyChangedSignal: (self:DOM,propertyName:string)->(RBXScriptSignal|signal);
	Update: (self:DOM)->();
}
export type DOM_constructor = {
	[event]:
		(DOM,...any)->()
		&{self: any,func: (...any)->(...any)};
} & { [number]: DOM|style; }
&   { [string]: any|register; }
export type DOM_creator = (DOM_constructor,...DOM_constructor)->DOM
export type imported =
	{[string]:any}
	&(ids:ObjectIdList)->DOM_creator
	&DOM_creator
export type import = (ClassName:string|ModuleScript|extend|()->()|{any},defaultProperties:DOM_constructor?)->imported
export type module_class = {
	Extend: ()->extend;
	Import: import;
	GetProperty: (item:extend|any,index:string,ClassName:string?)->any;
	SetProperty: (item:extend|any,index:string,value:any,ClassName:string?)->();
	Make: (ClassName:string|(...any)->any|extend,...{any})->any;
} & import

-------------------
-- module_event
-------------------
export type event = string
export type module_event = {
	Prop: (propName:string)->event;
	CreatedAsync: event;
	Created: event;
	Bind: (this:DOM|any,key:event|string,func:(...any)->(),typefunc:string?)->();
} & (eventName:string)->event;

-------------------
-- module_signal
-------------------
export type signal = {}
export type disconnecter = {
	Add: (self:disconnecter,connection:RBXScriptConnection)->();
	Destroy: (self:disconnecter)->();
	Disconnect: (self:disconnecter)->();
	New: (id:string?)->disconnecter;
}
export type module_signal = {
	Disconnecter: disconnecter;
}

-------------------
-- module_register
-------------------
export type register = {
	Register: (self:register,()->())->();
	With: <R>(self:R&register,handler:{any}|(store:store,value:any,key:any,item:DOM)->any)->R&register;
	Default: <R>(self:R&register,value:any)->R&register;
	Add: <R>(self:R&register,value:any)->R&register;
	Tween: <R>(self:R&register,tween:TweenOptions)->R&register;
}
export type store = {}
export type objectList = {
	Each: (self:objectList,(item:DOM,index:number)->())->();
	EachSync: (self:objectList,(item:DOM,index:number)->())->();
	Remove: (self:objectList,index:number|DOM)->(DOM?,number?);
	IsEmpty: (self:objectList)->boolean;
}
export type ObjectIdList = string
export type module_store = {
	GetObjects: (ids:ObjectIdList)->objectList;
	SetObject: (id:string)->DOM?;
	AddObject: (ids:ObjectIdList)->();
}

-------------------
-- module_style
-------------------
export type style = {}
export type module_style = {
	New: (props:{[string]:any})->style;
} & (props:{[string]:any})->style

-------------------
-- module_mount
-------------------
export type mount = {
	Unmount: (self:mount)->();
}
export type mounts = mount
export type module_mount = {
	Mount: (to:DOM|any,object:DOM|any,holder:DOM|any?)->mount;
	GetHolder: (item:DOM|any)->any?;
} & (to:DOM|any,object:DOM|any,holder:DOM|any?)->mounts

-------------------
-- module_tween
-------------------
export type TweenOnStepped = (Item:DOM|any,Alpha:number,AbsolutePercent:number)->()
export type TweenEnded = (Item:DOM|any)->()
export type TweenSetter = (Item:DOM|any,Property:string,Value:Lerpable)->()
export type TweenGetter = (Item:DOM|any,Property:string)->()
export type TweenOptions = {
	Easing: "Linear"
			|"Quint"
			|"Quart"
			|"Cubic"
			|"Quad"
			|"Sin"
			|"Circle"
			|"Expo"
			|"Elastic"
			|"Bounce"
			|"Exp2"
			|"Exp4"
			|EasingFunction?;
	Direction: "Out"|"InOut"|"In"|EasingDirection?;
	CallBack: {[number|"*"|string]:(Item:DOM|any,Alpha:number,AbsolutePercent:number)->()}?;
	OnStepped: TweenOnStepped?; -- Same as CallBack{["*"]:()->()} But faster then CallBack due to table loop
	Ended: TweenEnded?;
	Getter: TweenGetter?;
	Setter: TweenSetter?;
}
export type EasingFunction = {run:(number)->number,[any]:any}
export type EasingFunctions = {
	Linear: EasingFunction; ---직선, Linear. i=x, x=0 ~ 1
	Quint: EasingFunction; ---5제곱, Quint. (^5) i=1-(1-x)^5, x=0 ~ 1
	Quart: EasingFunction; ---4제곱, Quart. (^4) i=1-(1-x)^4, x=0 ~ 1
	Cubic: EasingFunction; ---3제곱, Cubic. (^3) i=1-(1-x)^3, x=0 ~ 1
	Quad: EasingFunction; ---2제곱, Quad. (^2) i=1-(1-x)^2, x=0 ~ 1
	Sin: EasingFunction; ---사인파, Sin. i=sin(x*pi/2), x=0 ~ 1
	Circle: EasingFunction; ---사분원, Circle. i=sqrt(1-(1-x)^2), x=0 ~ 1
	Expo: EasingFunction; ---지수함수, Expo. i=1-2^(-10*x), x=0~1
	Elastic: EasingFunction; ---튀어오름, Elastic.
	Bounce: EasingFunction; ---통통거림, Bounce

	-- Old things
	Exp2: EasingFunction; ---덜 가파른 지수. i=math.exp(x), x=-4 ~ 2
	Exp4: EasingFunction; ---더 가파른 지수. i=math.exp(x), x=-4 ~ 4
}
export type EasingDirection = string
export type EasingDirections = {
	Out: EasingDirection&"Out";
	In: EasingDirection&"In";
	InOut: EasingDirection&"InOut";
}
export type Lerpable = Color3|UDim|UDim2|number|Vector2|Vector3|CFrame
export type TweenHandler = ()->();
export type module_tween = {
	EasingFunctions:EasingFunctions;
	EasingDirections:EasingDirections;
	LerpProperties: <item>(item:item&(DOM|any),old:{[string]:Lerpable},new:{[string]:Lerpable},alpha:number,setter:(item:item&(DOM|any),property:string,value:Lerpable)->()?)->();
	RunTween: (Item:DOM|any,Option:TweenOptions,Properties:{[string]:Lerpable},Ended:TweenEnded?,OnStepped:TweenOnStepped?,Setter:TweenSetter?,Getter:TweenGetter?)->TweenHandler;
	RunTweens: (Items:{[number]:DOM|any},Option:TweenOptions,Properties:{[string]:Lerpable},Ended:TweenEnded?,OnStepped:TweenOnStepped?,Setter:TweenSetter?,Getter:TweenGetter?)->();
	StopTween: (ItemOrStep:TweenHandler|DOM|any)->();
	StopPropertyTween: (Item:DOM|any,PropertyName:string)->();
	IsTweening: (ItemOrStep:TweenHandler|DOM|any)->boolean;
	IsPropertyTweening: (Item:DOM|any,PropertyName:string)->boolean;
}

-------------------
-- module_signal
-------------------
export type round = {
	SetRound: (ImageFrame:ImageLabel|ImageButton,RoundSize:number)->(ImageLabel|ImageButton);
	SetOutline: (ImageFrame:ImageLabel|ImageButton,RoundSize:number)->(ImageLabel|ImageButton);
	GetRound: (ImageFrame:ImageLabel|ImageButton)->number;
	GetOutline: (ImageFrame:ImageLabel|ImageButton)->number;
}

-------------------
-- module
-------------------
export type module_exported = {
	Round: round;
	Tween: module_tween;
	Style: module_style;
	Event: module_event;
	Store: module_store;
	Mount: module_mount;
	Class: module_class;
	Signal: module_signal;
	Lang: module_lang;
}
export type module = {
	Uninit: (id:string)->();
	Init: (id:string?)->module_exported;
}

return {}
