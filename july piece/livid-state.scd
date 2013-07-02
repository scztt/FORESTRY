/////////////////////////////////////////////////////////////////
// LIVID STATE MACHINE

State(\test).startActions.add({
	"starting".postln;
});


State(\test).stopActions.add({
	"stopping".postln;
});

State(\test).doStart();
State(\test).doStop();


State(\test)[\name] = "asdf";
State(\test)[\name]

State(\test).clear()

m = MultiStateManager();
m.switch(State(\test));
m.switch(State(\test2));