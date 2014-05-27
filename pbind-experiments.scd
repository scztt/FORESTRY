~buffers = ();
~letters = (97 + (0..25)).asAscii;

~folder = PathName("/Users/scott/Documents/_sounds/drum cr-78");
~folder.files.do({
	| file, i |
	var name, buffer;
	file.postln;
	name = file.fileNameWithoutExtension.asSymbol;
	~buffers[~letters[i].asSymbol] = Buffer.read(s, file.absolutePath).bufnum;
});



~buses = 40.collect({
	Bus.audio(s, 1);
});


SynthDef(\strike, {
	var sig;

	sig = PlayBuf.ar(1, \bufnum.ir, \rate.ir(1));
	sig = LPF.ar(sig, \lowpass.ir(20000));
	sig = sig * \amp.ir(-6.dbamp);

	sig = sig * EnvGen.kr(
		Env([1, 0], [\decayTime.ir(3)]),
		gate:\gate.ir(1),
		doneAction:2
	);

	Out.ar(\out.ir(0), sig ! 2);
}).add;

SynthDef(\delay, {
	var sig, freqs, delaytime, lpf;
	sig = In.ar(\in.ir, 2);

	freqs = \freq.ir(300) * [1, 3, 4, 7, 8, 12].collect({ |n| n + rrand(-0.01, 0.01) });
	sig = LeakDC.ar(sig);
	delaytime = \delayTime.ir(0.25);
	delaytime = delaytime * EnvGen.ar(Env([0.2, 1], [5], 'exp'));
	sig = sig + CombC.ar(sig, 2, delaytime, \decayTime.ir(3));
	sig = sig.tanh;

	lpf = \lpf.kr(120.5) * EnvGen.kr(Env([0.1, 6], [3]));
	sig = LPF.ar(sig, lpf) * 5;
	sig = sig + (BPF.ar(sig * WhiteNoise.ar(0.01), freqs, 3/freqs).sum * 10);

	DetectSilence.ar(sig, doneAction:2);
	Out.ar(\out.ir, sig ! 2);
}).add;

SynthDef(\delay2, {
	var sig;
	sig = In.ar(\in.ir, 2);
	sig = sig + AllpassC.ar(sig, 2, \delayTime.ir(0.25), \decayTime.ir(1.3));
	DetectSilence.ar(sig, doneAction:2);
	Out.ar(\out.ir, sig ! 2);
}).add;

SynthDef(\delay3, {
	var sig;
	sig = In.ar(\in.ir, 2);
	sig = sig + AllpassC.ar(sig, 2, \delayTime.ir(0.05), \decayTime.ir(1.3));
	DetectSilence.ar(sig, doneAction:2);
	Out.ar(\out.ir, sig ! 2);
}).add;


b = Pdefn(\busNum, Pseq(~buses.collect(_.index), inf));

p = Pbind(
	\play, {
		var group, instr, effect;
		currentEnvironment.postln;
		if (~fxInstrument.notNil && (~fxInstrument != \nil), {
			instr = currentEnvironment;
			effect = currentEnvironment.copy();

			instr[\out] = ~fxBus ? 0;
			instr.parent[\play].value;

			effect[\instrument] = ~fxInstrument;
			instr.postln;
			effect[\target] = instr[\id][0];
			effect[\addAction] = \addToTail;
			effect[\in] = ~fxBus;
			effect[\out] = ~fxOut ? 0;
			effect[\play] = nil;

			effect.play;
		}, {
			instr = currentEnvironment;
			instr[\out] = ~fxOut ? 0;
			instr.parent[\play].value;
		});
	}
);

q = Pbindf(p,
	\instrument, \strike,
	\bufnum, Pdict(~buffers, Pseq(
		[\g, \g, \g, \g], inf)),
	\dur, Pseq(
		[1,  	1,  	1, 		1], inf),
//	\fxInstrument, Ppatlace([Prand([\delay, \delay2, \delay3], inf), \nil, \nil, \nil, \nil, \nil], inf),
	\fxInstrument, \delay,
	\lpf, Prand([50, 60, 450, 575], inf),
	\stretch, 3,
	\delayTime, Prand([0.1, 0.4, 0.1], inf),
	\fxBus, b
);


r = Pbindf(q,
	\degree, Pseq([
		Pseq([5, 5, 4, 4]),
		[ Pseq([5, 5, 4, 4]), Pseq([2, 2, 6, 6]) ],
		[ Pseq([5, 5, 4, 4]), Pseq([3, 2, 6, 7]) ]
	], inf)
);
r.play;
