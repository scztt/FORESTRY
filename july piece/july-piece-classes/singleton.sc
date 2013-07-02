Singleton {
	classvar <>all, know=false, creatingNew=false;

	var logString, <postWindow, <>postActions;

	*initClass { all = IdentityDictionary(); }

	*new {
		arg name = \default;
    		^all.atFail(name, {
			var newSingleton = this.createNew().init();
			all[name] = newSingleton;
			newSingleton;
		});
	}

	*createNew {
		arg ...args;
		^super.new(*args);
	}

	*doesNotUnderstand { arg selector ... args;
		var item;
		if (know && creatingNew.not) {
			creatingNew = true;		// avoid reentrant situations
			try {
				if (selector.isSetter) {
					"Cannot set singleton items.".error;
				};

				item = this.new(selector);
			};
			creatingNew = false;
			^item;
		};
		^this.superPerformList(\doesNotUnderstand, selector, args);
	}

	init {}

}