-------------------
-- module_class
-------------------
export type extend = {
	Getter: {[string]: ()->(any?)?};
	Setter: {[string]: (value:any)->()?};
	New: (prop:DOM_constructor)->DOM|any;
	Init: (self:extend,props:valueStore)->();
	Render: (self:extend,props:valueStore)->(DOM|any);
	AfterRender: (self:extend,item:DOM|any,props:valueStore)->();
	GetPropertyChangedSignal: (self:extend,propertyName:string)->signal;
	EmitPropertyChangedSignal: (self:extend,propertyName:string,...any)->();
	Update: (self:extend)->();
	Destroy: (self:extend)->();
	UpdateTriggers: {[string]:boolean?};
	Unload: (self:extend,object:DOM|any)->();
	GetChildren: (self:extend)->({DOM|any});
	ChildAdded: signal;
}
export type DOM = {
	[string]: any;
	Destroy: (self:DOM)->();
	GetPropertyChangedSignal: (self:DOM,propertyName:string)->(RBXScriptSignal|signal);
	Update: (self:DOM)->();
}|extend;
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
export type connection = {
	Disconnect: (self:connection)->();
	Destroy: (self:connection)->();
	New: (signal,(...any)->())->();
}
export type signal = {
	Fire: (self:signal,...any)->();
	Wait: (self:signal)->();
	CheckConnected: (self:signal,(...any)->())->boolean;
	Connect: (self:signal,(...any)->())->connection;
	Once: (self:signal,(...any)->())->connection;
	Destroy: (self:signal)->();
	New: (id:string?)->signal;
}
export type disconnecter = {
	Add: (self:disconnecter,connection:RBXScriptConnection)->();
	Destroy: (self:disconnecter)->();
	Disconnect: (self:disconnecter)->();
	New: (id:string?)->disconnecter;
}
export type module_signal = {
	Disconnecter: disconnecter;
	Bindable: signal;
}

-------------------
-- module_register
-------------------
export type register = {
	Register: (self:register,()->())->();
	With: <R>(self:R&register,handler:{any}|(store:valueStore,value:any,key:any,item:DOM)->any)->R&register;
	Default: <R>(self:R&register,value:any)->R&register;
	Add: <R>(self:R&register,value:any)->R&register;
	Tween: <R>(self:R&register,tween:TweenOptions)->R&register;
}
export type valueStore = {[any]:any}&(key:string)->register
export type objectList = {
	Each: (self:objectList,(item:DOM|any,index:number)->())->();
	EachSync: (self:objectList,(item:DOM|any,index:number)->())->();
	Remove: (self:objectList,index:number|DOM)->(DOM?,number?);
	IsEmpty: (self:objectList)->boolean;
}
export type ObjectIdList = string
export type module_store = {
	GetObjects: (ids:ObjectIdList)->objectList;
	GetObject: (id:string)->DOM?;
	AddObject: (ids:ObjectIdList,item:Dom|any)->();
	GetStore: (id:string?)->valueStore;
} & (id:string?)->valueStore

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
export type mounts = mount & {
	Add: (self:mount,...DOM|any)->();
}
export type module_mount = {
	MountOne: (to:DOM|any,object:DOM|any,holder:DOM|any?,noReturn:boolean?)->mount;
	GetHolder: (item:DOM|any)->any?;
} & (to:DOM|any,object:DOM|any,holder:DOM|any?)->mounts

-------------------
-- module_tween
-------------------
export type TweenOnStepped = (Item:DOM|any,Alpha:number,AbsolutePercent:number)->()
export type TweenEnded = (Item:DOM|any)->()
export type TweenSetter = (Item:DOM|any,Property:string,Value:Lerpable)->()
export type TweenGetter = (Item:DOM|any,Property:string)->any
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
			|"Back"
			|"Exp2"
			|"Exp4"
			|EasingFunction?;
	Direction: "Out"|"InOut"|"In"|EasingDirection?;
	CallBack: {[number|"*"|string]:(Item:DOM|any,Alpha:number,AbsolutePercent:number)->()}?;
	OnStepped: TweenOnStepped?; -- Same as CallBack{["*"]:()->()} But faster then CallBack due to table loop
	Ended: TweenEnded?;
	Getter: TweenGetter?;
	Setter: TweenSetter?;
	Time: number?;
}
export type EasingFunction = {run:(number)->number,[any]:any}
export type EasingFunctions = {
	Linear: EasingFunction; ---직선, Linear. i=x, x=0 to 1
	Quint: EasingFunction; ---5제곱, Quint. (^5) i=1-(1-x)^5, x=0 to 1
	Quart: EasingFunction; ---4제곱, Quart. (^4) i=1-(1-x)^4, x=0 to 1
	Cubic: EasingFunction; ---3제곱, Cubic. (^3) i=1-(1-x)^3, x=0 to 1
	Quad: EasingFunction; ---2제곱, Quad. (^2) i=1-(1-x)^2, x=0 to 1
	Sin: EasingFunction; ---사인파, Sin. i=sin(x*pi/2), x=0 to 1
	Circle: EasingFunction; ---사분원, Circle. i=sqrt(1-(1-x)^2), x=0 to 1
	Expo: EasingFunction; ---지수함수, Expo. i=1-2^(-10*x), x=0 to 1
	Elastic: EasingFunction; ---탄성, Elastic.
	Bounce: EasingFunction; ---튀어오름, Bounce
	Back: EasingFunction; ---뒤로 움직임, Back

	-- Old things
	Exp2: EasingFunction; ---덜 가파른 지수. i=exp(x)/max, x=-4 to 2
	Exp4: EasingFunction; ---더 가파른 지수. i=exp(x)/max, x=-4 to 4
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
	Easings:EasingFunctions;
	EasingDirections:EasingDirections;
	Directions:EasingDirections;
	LerpProperties: <item>(item:item&(DOM|any),old:{[string]:Lerpable},new:{[string]:Lerpable},alpha:number,setter:(item:item&(DOM|any),property:string,value:Lerpable)->()?)->();
	RunTween: (Item:DOM|any,Option:TweenOptions,Properties:{[string]:Lerpable},Ended:TweenEnded?,OnStepped:TweenOnStepped?,Setter:TweenSetter?,Getter:TweenGetter?)->TweenHandler;
	RunTweens: (Items:{[number]:DOM|any},Option:TweenOptions,Properties:{[string]:Lerpable},Ended:TweenEnded?,OnStepped:TweenOnStepped?,Setter:TweenSetter?,Getter:TweenGetter?)->();
	StopTween: (ItemOrStep:TweenHandler|DOM|any)->();
	StopPropertyTween: (Item:DOM|any,PropertyName:string)->();
	IsTweening: (ItemOrStep:TweenHandler|DOM|any)->boolean;
	IsPropertyTweening: (Item:DOM|any,PropertyName:string)->boolean;
}

-------------------
-- module_round
-------------------
export type module_round = {
	SetRound: (ImageFrame:ImageLabel|ImageButton,RoundSize:number)->(ImageLabel|ImageButton);
	SetOutline: (ImageFrame:ImageLabel|ImageButton,RoundSize:number)->(ImageLabel|ImageButton);
	GetRound: (ImageFrame:ImageLabel|ImageButton)->number;
	GetOutline: (ImageFrame:ImageLabel|ImageButton)->number;
}

-------------------
-- module_signal
-------------------
export type langOptions = {
	[string]: register|string|number|any;
}
export type langHandler = {
	[string]: string|(langOptions:langOptions)->string;
}
export type Locale = string
export type module_lang = {
	New: (id:string,handlers:{
		["default"]: langHandler;
		["en-us"]: langHandler;
		["es-es"]: langHandler;
		["fr-fr"]: langHandler;
		["id-id"]: langHandler;
		["it-it"]: langHandler;
		["ja-jp"]: langHandler;
		["ko-kr"]: langHandler;
		["ru-ru"]: langHandler;
		["th-th"]: langHandler;
		["tr-tr"]: langHandler;
		["vi-vn"]: langHandler;
		["pt-br"]: langHandler;
		["de-de"]: langHandler;
		["zh-cn"]: langHandler;
		["zh-tw"]: langHandler;
		["bg-bg"]: langHandler;
		["bn-bd"]: langHandler;
		["cs-cz"]: langHandler;
		["da-dk"]: langHandler;
		["el-gr"]: langHandler;
		["et-ee"]: langHandler;
		["fi-fi"]: langHandler;
		["hi-in"]: langHandler;
		["hr-hr"]: langHandler;
		["hu-hu"]: langHandler;
		["ka-ge"]: langHandler;
		["kk-kz"]: langHandler;
		["km-kh"]: langHandler;
		["lt-lt"]: langHandler;
		["lv-lv"]: langHandler;
		["ms-my"]: langHandler;
		["my-mm"]: langHandler;
		["nb-no"]: langHandler;
		["nl-nl"]: langHandler;
		["fil-ph"]: langHandler;
		["pl-pl"]: langHandler;
		["ro-ro"]: langHandler;
		["uk-ua"]: langHandler;
		["si-lk"]: langHandler;
		["sk-sk"]: langHandler;
		["sl-sl"]: langHandler;
		["sq-al"]: langHandler;
		["bs-ba"]: langHandler;
		["sr-rs"]: langHandler;
		["sv-se"]: langHandler;
		["ar-001"]: langHandler;
	})->();
	Locales: {
		Default: "default";
		English: Locale & "en-us";
		Spanish: Locale & "es-es";
		French: Locale & "fr-fr";
		Indonesian: Locale & "id-id";
		Italian: Locale & "it-it";
		Japanese: Locale & "ja-jp";
		Korean: Locale & "ko-kr";
		Russian: Locale & "ru-ru";
		Thai: Locale & "th-th";
		Turkish: Locale & "tr-tr";
		Vietnamese: Locale & "vi-vn";
		Portuguese: Locale & "pt-br";
		German: Locale & "de-de";
		ChineseSimplified: Locale & "zh-cn";
		ChineseTraditional: Locale & "zh-tw";
		Bulgarian: Locale & "bg-bg";
		Bengali: Locale & "bn-bd";
		Czech: Locale & "cs-cz";
		Danish: Locale & "da-dk";
		Greek: Locale & "el-gr";
		Estonian: Locale & "et-ee";
		Finnish: Locale & "fi-fi";
		Hindi: Locale & "hi-in";
		Croatian: Locale & "hr-hr";
		Hungarian: Locale & "hu-hu";
		Georgian: Locale & "ka-ge";
		Kazakh: Locale & "kk-kz";
		Khmer: Locale & "km-kh";
		Lithuanian: Locale & "lt-lt";
		Latvian: Locale & "lv-lv";
		Malay: Locale & "ms-my";
		Burmese: Locale & "my-mm";
		Bokmal: Locale & "nb-no";
		Dutch: Locale & "nl-nl";
		Filipino: Locale & "fil-ph";
		Polish: Locale & "pl-pl";
		Romanian: Locale & "ro-ro";
		Ukrainian: Locale & "uk-ua";
		Sinhala: Locale & "si-lk";
		Slovak: Locale & "sk-sk";
		Slovenian: Locale & "sl-sl";
		Albanian: Locale & "sq-al";
		Bosnian: Locale & "bs-ba";
		Serbian: Locale & "sr-rs";
		Swedish: Locale & "sv-se";
		Arabic: Locale & "ar-001";
	};
	CurrentLocale: Locale;
	FailedMessage: string;
} & (id:string)->(langOptions)->register;

-------------------
-- module
-------------------
export type module_exported = {
	Signal: module_signal;
	Round: module_round;
	Tween: module_tween;
	Style: module_style;
	Event: module_event;
	Store: module_store;
	Mount: module_mount;
	Class: module_class;
	Lang: module_lang;
}
export type module = {
	Uninit: (QuadId:string)->();
	Init: (QuadId:string?)->module_exported;
}

return {}
