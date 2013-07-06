MultiStateManager : Singleton {
	var <states, <currentState;

	init {
	}

	switch {
		arg state ...args;
		if (currentState != state) {
			if (currentState.notNil) {
				currentState.doStop(*args);
			};
			currentState = nil;

			if (state.notNil) {
				state.doStart(*args);
			};
			currentState = state;
		}
	}
}

State : Singleton {
	var <initialized=false, <running = false;
	var <initActions, <startActions, <stopActions, <freeActions, <resources;
	var envir, <name;

	init {
		arg inName;
		initActions = SparseArray();
		startActions = SparseArray();
		stopActions = SparseArray();
		freeActions = SparseArray();
		resources = SparseArray();
		envir = Environment();
		envir[\name] = inName;
		name = inName;

		this.clear();
	}

	onError {
		|e|
		"%: Error running action %.".format(this.name()).error;
		e.postln;
	}

	at {
		arg selector;
		^envir.at(selector);
	}

	put {
		arg key, value;
		^envir.put(key, value);
	}

	clear {
		initActions.clear(8);
		startActions.clear(8);
		stopActions.clear(8);
		freeActions.clear(8);
		resources.clear(8);

		envir.clear();
		envir[\name] = name;
	}

	use {
		arg func;
		envir.use(func);
	}

	doInit {
		arg ...args;
		initActions.do({
			arg action;
			try {
				envir.use({
					action.value(*args)
				});
			} {
				|e|
				this.onError(e)
			};
		});
		initialized = true;
		this.update(\initialized, true);
	}

	doStart {
		arg ...args;
		if (running.not) {
			startActions.do({
				arg action;
				try {
					envir.use({
						action.value(*args)
					});
				} {
					|e|
					this.onError(e)
				};
			});
			running = true;
			this.update(\running, true);
		} {
			"State already started.".warn;
		};
	}

	doStop {
		arg ...args;
		if (running) {
			stopActions.do({
				arg action;
				try {
					envir.use({
						action.value(*args)
					});
				} {
					|e|
					this.onError(e)
				};
			});
			running = false;
			this.update(\running, false);
		} {
			"State not running.".warn;
		};
	}

	doFree {
		arg ...args;
		freeActions.do({
			arg action;
			try {
				envir.use({
					action.value(*args)
				});
			} {
				|e|
				this.onError(e)
			};
		});
		resources.do({
			arg resource;
			resource.free();
		});
		initialized = false;
	}
}