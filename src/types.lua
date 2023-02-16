-------------------
-- module_class
-------------------
export type extend = {
    getter: {[string]: ()->any|any?};
    setter: {[string]: ()->()?};
}
export type DOM = {
    [string]: any;
}
export type DOM_constructor = {
    [event]:
        (DOM,...any)->()
        &{self: any,func: ()->()};
} & { [number]: DOM|style; }
&   { [string]: any|register; }
export type DOM_creator = (DOM_constructor,...DOM_constructor)->DOM
export type imported =
    {[string]:any}
    &(ids:ObjectIdList)->DOM_creator
    &DOM_creator
export type import = (ClassName:string|ModuleScript|extend|()->()|{any},defaultProperties:DOM_constructor?)->imported
export type module_class = {
    extend: ()->extend;
    import: import;
    getProperty: (item:extend|any,index:string,ClassName:string?)->any;
    setProperty: (item:extend|any,index:string,value:any,ClassName:string?)->();
    make: (ClassName:string|(...any)->any|extend,...{any})->any;
} & import

-------------------
-- module_event
-------------------
export type event = string
export type disconnecter = {
    add: (self:disconnecter,connection:RBXScriptConnection)->();
    destroy: (self:disconnecter)->();
    disconnect: (self:disconnecter)->();
}
export type module_event = {
    prop: (propName:string)->event;
    createdAsync: event;
    created: event;
    bind: (this:DOM|any,key:event|string,func:(...any)->(),typefunc:string?)->();
    disconnecter: (id:string?)->disconnecter;
} & (eventName:string)->event;

-------------------
-- module_signal
-------------------
export type module_signal = {}

-------------------
-- module_register
-------------------
export type register = {
    register: (self:register,()->())->();
    with: <R>(self:R&register,handler:{any}|(store:store,value:any,key:any,item:DOM)->any)->R&register;
    default: <R>(self:R&register,value:any)->R&register;
    add: <R>(self:R&register,value:any)->R&register;
    tween: <R>(self:R&register,tween:TweenOptions)->R&register;
}
export type store = {}
export type objectList = {
    each: (self:objectList,(item:DOM,index:number)->())->();
    eachSync: (self:objectList,(item:DOM,index:number)->())->();
    remove: (self:objectList,index:number|DOM)->(DOM?,number?);
    isEmpty: (self:objectList)->boolean;
}
export type ObjectIdList = string
export type module_store = {
    getObjects: (ids:ObjectIdList)->objectList;
    getObject: (id:string)->DOM?;
    addObject: (ids:ObjectIdList)->();

}

-------------------
-- module_signal
-------------------
export type style = {}
export type module_style = {}

-------------------
-- module_signal
-------------------
export type module_mount = {}

-------------------
-- module_signal
-------------------

export type TweenOnStepped = (Item:DOM|any,Alpha:number,AbsolutePercent:number)->()
export type TweenEnded = (Item:DOM|any)->()
export type TweenSetter = (Item:DOM|any,Property:string,Value:Lerpable)->()
export type TweenGetter = (Item:DOM|any,Property:string)->()
export type TweenOptions = {
	Easing: EasingFunction?;
	Direction: EasingDirection?;
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
	Exp2Max4: EasingFunction; ---@deprecated
}
export type EasingDirection = string
export type EasingDirections = {
	Out: EasingDirection&"Out";
	In: EasingDirection&"In";
}
export type Lerpable = Color3|UDim|UDim2|number|Vector2|Vector3|CFrame
export type TweenHandler = ()->();
export type AdvancedTween = {
	EasingFunctions:EasingFunctions;
	EasingDirections:EasingDirections;
	LerpProperties: <item>(item:item&(DOM|any),old:{[string]:Lerpable},new:{[string]:Lerpable},alpha:number,setter:(item:item&(DOM|any),property:string,value:Lerpable)->()?)->();
	RunTween: (Item:DOM|any,Option:TweenOptions,Properties:{[string]:Lerpable},Ended:TweenEnded?,OnStepped:TweenOnStepped?,Setter:TweenSetter?,Getter:TweenGetter?)->TweenHandler;
}

-------------------
-- module_signal
-------------------
export type round = {
    setRound: (ImageFrame:ImageLabel|ImageButton,RoundSize:number)->(ImageLabel|ImageButton);
    setOutline: (ImageFrame:ImageLabel|ImageButton,RoundSize:number)->(ImageLabel|ImageButton);
    getRound: (ImageFrame:ImageLabel|ImageButton)->number;
    getOutline: (ImageFrame:ImageLabel|ImageButton)->number;
}

-------------------
-- module
-------------------
export type module_exported = {
    round: round;
    tween: AdvancedTween;
    style: module_style;
    event: module_event;
    store: module_store;
    mount: module_mount;
    class: module_class;
}
export type module = {
    uninit: (id:string)->();
    init: (id:string)->module_exported;
}

return {}
