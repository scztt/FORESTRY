///////////////////////////////////////////////////////////////
// Bell state

///////////////////////////////////////////////////////////////
// SynthDef


(
~taylorTones = [292.8, 586.1, 693.0, 882.1, 1171.4, 1560.4, 1764.2, 1949.7, 2158.6, 2441.4, 2619.2, 3184.6] / 1171.4;
SynthDef(\lichenSurface, {
	arg in, out, t_dust = 0;
	var sig, inSig, inFeed, noise, noiseMod, dust, dustEnv;

	dustEnv = EnvGen.kr(Env.perc(0.01, 12), gate: t_dust);
	dust = Dust.ar(dustEnv * 10 + 118) * dustEnv;
	dust = dust + CombC.ar(Decay.ar(Dust.ar(6), 0.001), 0.1, 1/7, 0.2);

	noiseMod = LFNoise2.ar(50);
	noiseMod = noiseMod + (
		sin([1.2, 3, 8, 9] * noiseMod * pi)
	).sum * 0.2;

	inFeed = LocalIn.ar(2) * 0.1;
	inFeed = APF.ar(inFeed, 25, 0.99);
	inFeed = LPF.ar(inFeed, 6000);
	inFeed = BRF.ar(inFeed, 3500);
	inFeed = LeakDC.ar(inFeed);

	inSig = In.ar(in, 2) * noiseMod.range(0.95, 1.0);
	inSig = inSig + inFeed + (dust * 0.01);

	sig = GVerb.ar(inSig, 20.1, 8);
	sig = HPF.ar(sig, 10);


	noise = (WhiteNoise.ar(0.2) + (BrownNoise.ar() * BrownNoise.ar()) * 0.3) * noiseMod.range(0.75, 1.0);
	noise = noise + dust;
	noise = APF.ar(noise, 101.4, 0.8);
	//sig = (sig * (0.5 + (noise * 0.2)));

	noise = HPF.ar(noise, 6000) * (1 + sig);
	noise = noise + HPF.ar(WhiteNoise.ar(0.005), 10000);
	sig = sig + (noise * 0.2);
	sig = sig + (0.5 * HardCompress.ar(sig, 0.1, 0.05));

	LocalOut.ar(sig * 0.6);
	Out.ar(out, (sig * 0.01) + inSig);
}).add;
);

(
~cymbal = {
	arg drive;
	var lodriver, locutoffenv, hidriver, hicutoffenv, freqs, res, thwack, gdrive;

	drive = drive.abs;
	gdrive = Gate.ar(drive, drive);

	locutoffenv = EnvGen.ar(Env.perc(gdrive, 5), gate:drive, levelScale:gdrive) * 20000 + 10;
	lodriver = LPF.ar(WhiteNoise.ar(0.1), locutoffenv);

	hicutoffenv = 10001 - (EnvGen.ar(Env.perc(1, 3), gate:drive, levelScale:gdrive) * 10000);
	hidriver = HPF.ar(WhiteNoise.ar(0.1), hicutoffenv);
	hidriver = hidriver * EnvGen.ar(Env.perc(1, 2, 0.25), gate:drive, levelScale:gdrive);

	thwack = EnvGen.ar(Env.perc(0.001,0.001,1), gate:drive, levelScale:gdrive);

	thisThread.randSeed = 6345;
	freqs  = {exprand(300, 20000)}.dup(30);
	res    = Ringz.ar(lodriver + hidriver + thwack, freqs).mean;

	((res * 1) + (lodriver * 2) + thwack);
};

~protect = {
	arg ugen;
	var ugens, finalizedUgens, newUgens, removeUgens, finished = false, i = 0, ugenBlewUp, sendReply;
	ugens = IdentitySet();
	finalizedUgens = IdentitySet();
	ugens.add(ugen);
	"initial ugen: %".format(ugen).postln;

	while {finished.not && (i < 100)} {
		finished = true;
		newUgens = List();
		removeUgens = List();
		ugens.do({
			|u|
			case
			{ u.isKindOf(Array) } {
				removeUgens.add(u);
				newUgens.addAll(u);
				finished = false;
			}
			{ u.isKindOf(OutputProxy) } {
				removeUgens.add(u);
				newUgens.add(u.source);
				finished = false;
			}
			{ u.isKindOf(BasicOpUGen) || u.isKindOf(MulAdd) || u.isKindOf(Sum3) || u.isKindOf(Sum4) } {
				removeUgens.add(u);
				newUgens.addAll(u.inputs);
				finished = false;
			}
			{ u.isNumber() } {
				removeUgens.add(u);
				finished = false;
			}
			{ u.isKindOf(UGen) } {
				removeUgens.add(u);
				newUgens.addAll(u.inputs);
				finalizedUgens.add(u);
				finished = false;
			};
		});
		"new ugens: %".format(newUgens).postln;
		"removed ugens: %".format(removeUgens).postln;
		ugens.removeAll(removeUgens);
		ugens.addAll(newUgens);
		i = i + 1;
		"ugens list[%]: %".format(ugens.size, ugens).postln;
	};
	"\n\n\n".postln;
	"finalized ugens [%]: %".format(finalizedUgens.size, finalizedUgens).postln;
	finalizedUgens.do({
		|u|
		"%.%: %, %".format(u.class, u.rate, u.synthIndex, u.specialIndex);
	});
	finalizedUgens = finalizedUgens.asArray.sort({ |a, b| a.synthIndex >= b.synthIndex });
	ugenBlewUp = CheckBadValues.ar(ugen);
	sendReply = PulseCount.ar(ugenBlewUp) > 0;

	SendReply.ar(sendReply, '/synthstate', [-1] ++ UGen.buildSynthDef.controls);
	finalizedUgens.do({
		|u|
		SendReply.ar(sendReply, '/synthstate', [u.class.classIndex, u.synthIndex, u] ++ u.inputs);
	});
};


SynthDef(\lichen1, {
	arg out = 0, freq = 100, combDelay = 0.2, combDecay = 1, klankDecay = 1, pan = 0,
	impulseFreq = 0, impulseDecay = 0.5, ring = 0, amp=0, impulseFilt=50, bend=0.3
	;
	var sig, panned, klank, impulse, cymbal,
	env, harm, comb, saw, bendEnv, debug
	;

	env = Env([0, 0.8, 0.01, 0], [0.001, 20, 0.01], [-5, -5, -5]);

	harm = ~taylorTones;
	amp = ~taylorTones.size.collect({
		|i|
		i = i / ~taylorTones.size;
		1 - i.pow(2.pow(amp));
	});
	ring = ~taylorTones.size.collect({
		|i|
		i = i / ~taylorTones.size;
		1 - (0.9 * i.pow(2.pow(ring)));
	});

	impulseFreq = LFNoise2.kr(8, impulseFreq * 0.05, impulseFreq);
	impulseDecay = LFNoise2.kr(8, impulseDecay * 0.9, impulseDecay);

	impulse = Impulse.ar(impulseFreq)
	* LFNoise2.kr(35).range(0.05, 1);
	cymbal = ~cymbal.(impulse).postln;

	impulse = Decay.ar(impulse, impulseDecay.max(0), 0.015);
	impulse = LPF.ar(impulse, impulseFilt) + HPF.ar(impulse * WhiteNoise.ar() * GrayNoise.ar() * 0.1, 12000);
	impulse = (impulse * 0.3) + (cymbal * 0.0001);

	bendEnv = EnvGen.ar(Env.perc(0.01, klankDecay / 6, 1, bend.range(-16, 0))) * bend;
	klank = DynKlank.ar(`[harm, amp, ring],
		input: impulse,
		freqscale: freq,
		freqoffset: LFDNoise3.ar(0.5 * bendEnv.pow(2), bendEnv.range(6, 10)),
		decayscale: (klankDecay * EnvGen.kr(env)).max(0)
	);
	saw = LPF.ar(Saw.ar(freq, 0.8 * EnvGen.kr(env)), 10000 - (EnvGen.kr(env) * 2000));
	klank = klank * EnvGen.kr(env);
	comb = klank + APF.ar(klank, 0.2, combDelay, combDecay);
	panned = Pan2.ar(comb, pan);


	DetectSilence.ar(comb, time:0.4, doneAction:2);
	Out.ar(out, panned);
	//debug = ~protect.(panned);
}).add;
);

l = LCDevice();
m = MultiStateManager();
State(\bell1).clear();

l.knobs.do(_.ringStyle_(\fill));

State(\bell1).use({
	var notes = 8.collect(Scale.partch_o3().degreeToFreq(_, 96.midicps, 0));
	notes = 8.collect(Scale.bartok().degreeToFreq(_, 90.midicps, 0));
	~notes = notes;
	~bellSynth = \lichen1;

	~controls = [
		~harmRingCV = CV(ControlSpec(-10, 10)),
		~harmAmpCV = CV(ControlSpec(-10, 10)),
		~impulseFreqCV = CV(ControlSpec(0.001, 68)),
		~impulseFiltCV = CV(ControlSpec(50, 4000, \exp, default: 500)),
		~bendCV = CV(ControlSpec(0, 1, default: 0.2)),
	];

	~triggers = ~notes.collect({
		|note, i|
		{
			Synth.controls(\lichen1, [
				\out, State(\bell1)[\bellBus].index,
				\freq, State(\bell1)[\notes][i],
				\combDelay, 0.4,
				\combDecay, 5,
				\klankDecay, 20,
				\impulseFreq, State(\bell1)[\impulseFreqCV],
				\impulseDecay, 10,
				\ring, State(\bell1)[\harmRingCV],
				\amp, State(\bell1)[\harmAmpCV],
				\impulseFilt, State(\bell1)[\impulseFiltCV],
			])
		};
	});

	~lastNote = 0;
});

State(\bell1).startActions.add({
	var lastNote, triggers;
	"Bell1 on".postln;

	~bellBus = Bus.audio(s, 2);
	~surfaceSynth = Synth(\lichenSurface, [
		\out, 0,
		\in, ~bellBus
	], addAction: \addAfter);

	~triggers.do({
		|trig, i|
		l.knobs.postln;
		l.knobs[i * 4].button.buttonOnActions.add(trig);
	});

	l.knobs[31].button.buttonOnActions.add({
		State(\bell1)[\surfaceSynth].set(\t_dust, 1);
	});

	~controls.do({
		|cv, i|
		l.knobs[3 + (i * 4)].lightWhenActive_(true).cv = cv;
	});
});

State(\bell1).stopActions.add({
	"Bell1 off".postln;
	~triggers.do({
		|trig, i|
		l.knobs[i * 4].button.buttonOnActions.remove(trig);
	});
	l.knobs[39].button.buttonOnActions.clear();
	~controls.do({
		|cv, i|
		l.knobs[7 + (i * 4)].cv = nil;
	});
	~bellBus.free;
	~surfaceSynth.free;
});

m.switch(nil);
m.switch(State(\bell1));

(
Pdef(\b_base, Pbind(
	\instrument, \lichen1,
	\dur, Pseq([1], inf),
	\out, State(\bell1)[\bellBus].index,
//	\scale, Scale.partch_o2(),
	\scale, Scale.bartok(),
	\root, 0,
	\octave, 8,
	\degree, 0,
	\impulseFreq, 0,
	\impulseDecay, 10,
	\combDelay, 0.4,
	\combDecay, 5,
	\klankDecay, 20,
	\ring, State(\bell1)[\harmRingCV],
	\amp, State(\bell1)[\harmAmpCV],
	\impulseFilt, State(\bell1)[\impulseFiltCV],
	\bend, State(\bell1)[\bendCV],
));

Pdef(\b_notes1, Pbind(
	\degree, Pseq([[-12, 0, 8], 0, 0, [0, 3], 0, 0, 0, [0, 6], [1, 5], 1, 1, [2, 7, 11]], inf)
));

Pdef(\b_imp1, Pbind(
	\impulseFreq, Prand([4], inf),
	\impulseDecay, Prand([0.1], inf),
	\klankDecay, Prand([1], inf)
));

Pdef(\b_imp2, Pbind(
	\impulseFreq, Prand([0, 0, 0, 0, 4, 6], inf),
	\impulseDecay, Prand([2, 3, 3, 3, 5, 5, 10, 1] / 10, inf),
	\klankDecay, Prand([5], inf)
));

Pdef(\b_imp3, Pbind(
	\impulseFreq, Prand([0, 0, 0, 0, 4, 6], inf),
	\impulseDecay, Prand([0.5], inf),
	\klankDecay, Prand([5], inf)
));

Pdef(\slow, Pbind(
	\dur, 12,
	\degree, Pseq([0, 0, 6, 9 ,3], inf),
	\impulseFreq, 10
));

Pdef(\durpat1, Pbind(
	\impulseFreq, Prand([0, 0, 16, 1, 4, 6], inf),
	\dur, Pseq([4, 4, 0.5, 0.5, 0.5, 8, 4, 4, 4, 4, 0.1, 0.1, 0.1, 8], inf),
	\impulseDecay, Prand([2, 3, 3, 3, 5, 5, 10, 1] * 3, inf),
));

);

//Pdef(\b_base).play
Pdef(\one, Pdef(\b_imp2) <> Pdef(\b_notes1) <> Pdef(\b_base));
Pdef(\one, Pdef(\durpat1) <> Pdef(\b_imp3) <> Pdef(\b_notes1) <> Pdef(\b_base));
Pdef(\one).play;
//Pdef(\one).stop;

//Pdef(\one, Pdef(\slow) <> Pdef(\b_base));
OSCdef(\ugenstate, {
	|msg|
	var node, ugen, ugenIndex, value, inputs, isInvalid;
	isInvalid = {
		|value|
		((value == inf) || (value == -inf) || value.isNaN);
	};
	node = msg[1];
	ugen = msg[3];
	if (ugen == -1) {
		"Controls for node %: (%)".format(node, msg[3..]).postln;
	} {
		ugen = Class.allClasses.detect({ |c| c.classIndex == ugen }).name;
		ugenIndex = msg[4];
		value = msg[5];
		inputs = msg[6..];

		if (isInvalid.(value)) {
			if (inputs.detect({ |v| isInvalid.(v) }).isNil) {
				"******".post;
			};
			"Ugen State for node %: %[%] = % (%)".format(node, ugen, ugenIndex, value, inputs.join(",")).postln;
		}
	}
}, '/synthstate');

