MultiStateManager {
	var <states, <currentState;

}

State : Singleton {
	var <initialized=false, <running = false;
	var <initActions, <startActions, <stopActions, <freeActions, <resources;
	var envir;

	init {
		initActions = SparseArray();
		startActions = SparseArray();
		stopActions = SparseArray();
		freeActions = SparseArray();
		resources = SparseArray();

		this.clear();
	}

	at {
		arg selector;
		^envir.at(selector);
	}

	clear {
		initActions.clear(8);
		startActions.clear(8);
		stopActions.clear(8);
		freeActions.clear(8);
		resources.clear(8);
	}

	doInit {
		arg ...args;
		initActions.do({
			arg action;
			try {
				action.value(*args);
			} {
				"Error running action %".format(action).error;
			}
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
					action.value(*args);
				} {
					"Error running action %".format(action).error;
				}
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
					action.value(*args);
				} {
					"Error running action %".format(action).error;
				}
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
				action.value(*args);
			} {
				"Error running action %".format(action).error;
			}
		});
		resources.do({
			arg resource;
			resource.free();
		});
		initialized = false;
	}
}