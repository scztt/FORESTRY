/////////////////////////////////////////////////////////////////
// LIVID STATE MACHINE

l = LCDevice();
m = MultiStateManager();
l.knobs.do({
	|k|
	k.cv = nil;
	k.lightWhenActive = true;
});

~states = (5..12).collect({
	arg b;
	var state;

	state = State(("state" ++ (b - 4)).asSymbol);
	state.clear();

	l.buttons[b].cv = SV([\off, \on]);
	l.buttons[b].cv.action_({
		|cv|
		cv.item.postln;
	});

	l.buttons[b].buttonOnActions.add({
		m.switch(state);
	});`

	state.startActions.add({
		l.buttons[b].lit = true;
		if (~knobs.isNil, {
			~knobs = 4.collect({
				l.knobs.choose().lightWhenActive_(true)
			});
		});
		if (~cvs.isNil, {
			~cvs = 4.collect({ CV(ControlSpec(0, 100, default:100.rand)) });
		});
		[~knobs, ~cvs].flop.do({
			|item|
			item[0].cv = item[1];
		});

		"started %".format(state.name).postln;
	});
	state.stopActions.add({
		l.buttons[b].lit = false;
		~knobs.do({
			|k|
			k.cv = nil;
		});
		"stopped %".format(state.name).postln;
	});
	state;
});


k = l.knobs.choose();
k.lightWhenActive = true;
k.cv = CV();
k.button.lit = true