

// . . . F O R E S T R Y . . . //

l = LCDevice();
l.connect();

/* Not used
s = Server.internal.boot;
p = DualEnvir.all;
*/

~envs = [
	Env(
		[0.001,1,0.001],
		[0.5, 0.5],
		[\exponential, \exponential]),
	Env(
		[0.001,1,0.001],
		[0.15, 0.85],
		[\exponential, \exponential]),
	Env(
		[0.001,0.7,1],
		[0.8, 0.2],
		[\exponential, \exponential])
];
~envs.plot;
~scalars = [-1,0,1];


~noises.notNil.if({
	~noises.do( _.free );
	~noises.clear;
});

~noises = PathName("/Users/fsc/Documents/_sounds/cleaned/noise").entries.collect({
	|path|
	Buffer.read(s, path.fullPath.postln);
});


(

l.knobRows[0][0].connect.cv = (~timeFadeA = CV(ControlSpec(0, 1)));
l.knobRows[0][1].connect.cv = (~envFadeA = CV(ControlSpec(0, 1)));
l.knobRows[0][2].connect.cv = (~decayA = CV(ControlSpec(0, 1)));
l.knobRows[0][3].connect.cv = (~ampA = CV(ControlSpec(0, 1)));

l.knobRows[1][0].connect.cv = (~timeFadeB = CV(ControlSpec(0, 1)));
l.knobRows[1][1].connect.cv = (~envFadeB = CV(ControlSpec(0, 1)));
l.knobRows[1][2].connect.cv = (~decayB = CV(ControlSpec(0, 1)));

l.knobRows[2][0].connect.cv = (~timeFadeC = CV(ControlSpec(0, 1)));
l.knobRows[2][1].connect.cv = (~envFadeC = CV(ControlSpec(0, 1)));
l.knobRows[2][2].connect.cv = (~decayC = CV(ControlSpec(0, 1)));

l.knobRows[3][0].connect.cv = (~timeFadeD = CV(ControlSpec(0, 1)));
l.knobRows[3][1].connect.cv = (~envFadeD = CV(ControlSpec(0, 1)));
l.knobRows[3][2].connect.cv = (~decayD = CV(ControlSpec(0, 1)));


~multiEnvGen = {
	| baseEnvelopes, timeScalars |
	var envs;
	var times, timePositions;
	var level;

	{
		| baseTime=4, timeFade=0, envFade=0 |

		timePositions = timeScalars.collect({
			| i |
			var actualTime = (2**(i-1)) * baseTime;
			LFSaw.ar( 1/actualTime )
		}).postln;

		times = baseEnvelopes.collect({
			| env |
			timePositions.collect({
				| pos |
				IEnvGen.ar(env, pos);
			})
		}).postln;

		level = SelectXFocus.ar( envFade,
			times.collect({
				| times |
				SelectXFocus.ar( timeFade, times, 1 )
			}),
			1
		);
	}
};

m = {
	| t=0, e=0, decay=0.5, amp=1|
	var baseTime, level, sig, revSig;
	t = t*3;
	e = e*3;
	decay = 0.1 + (decay * 2);
	baseTime = 4;
	level = ~multiEnvGen.(~envs, ~scalars).(baseTime, t, e);
	sig = LPF.ar( LFPulse.ar(8, 0, level), (level*12300)+80 );
	sig = DynKlank.ar(`[
		[0.1, 1, 1.05, 3, 5, 7, 7.1, 13, 17],
		[0.001 * decay] ++ (1 ! 8),
		[0.2, 1, 0.5, 0.4, 0.3, 0.2, 0.1, 0.08, 0.01]
	],
	sig,
	freqscale: (700 + (level * WhiteNoise.ar(25))),
	decayscale: decay
	) * [0.01,0.01] * 0.2;
	revSig = LPF.ar(sig, 2500);
	sig = sig * amp;
}.play();


[
	\e, ~timeFadeA,
	\t, ~envFadeA,
	\decay, ~decayA,
	\amp, ~ampA,
].connectToNode(s, m.nodeID);


n = {
	| t=0, e=0, decay=0.0 |
	var baseTime, level, sig;
	t = t*3;
	e = e*3;
	baseTime = 12;
	level = ~multiEnvGen.(~envs, ~scalars).(baseTime, t, e);
	sig = LPF.ar( LFPulse.ar(0.25, 0, level), (level*12300)+80 ) * 0.1;
	Klank.ar(`[
		[1, 1.05, 3, 5, 7, 7.1, 13],
		1 ! 7,
		[1, 0.5, 0.4, 0.3, 0.2, 0.1, 0.08] * (4 + (decay * 6))
	],
	sig,
	freqscale: (10 + (level.poll*WhiteNoise.ar(2)))
	) * [0.01,0.01];
}.play();

[
	\e, ~timeFadeB,
	\t, ~envFadeB,
	\decay, ~decayB
].connectToNode(s, n.nodeID);


o = {
	| t=0, e=0, decay=0 |
	var baseTime, level, sig;
	t = t*3;
	e = e*3;
	baseTime = 8;
	level = ~multiEnvGen.(~envs, ~scalars).(baseTime, t, e);
	sig = FreeVerb.ar(
		LFPulse.ar(8, 0, level*0.1),
		mix: 0.6,
		room: 0.6 + (decay * 0.6),
		damo: 0.2
	);
	sig = sig
	* HPF.ar(WhiteNoise.ar(level), 10000 - (level*6000))
	* [0.5,1] * 0.5 ;
}.play();

o.free

[
	\e, ~timeFadeC,
	\t, ~envFadeC,
	\decay, ~decayC
].connectToNode(s, o.nodeID);


p = {
	| t, e |
	var baseTime, level, sig;
	t = t*3;
	e = e*3;
	baseTime = 8;
	level = ~multiEnvGen.(~envs, ~scalars).(baseTime, t, e);
	sig = FreeVerb.ar(
		LFPulse.ar(8, 0, level*0.1),
		mix: 0.6,
		room: 0.8,
		damo: 0.2
	);
	sig = sig
	* HPF.ar(WhiteNoise.ar(level), 10000 - (level*6000))
	* [1,0.5] * 0.5 ;
}.play();

[
	\e, ~timeFadeD,
	\t, ~envFadeD,
	\decay, ~decayD
].connectToNode(s, p.nodeID);



l.knobRows[0][4].connect.cv = (~pulseT = CV(ControlSpec(0, 1)));
l.knobRows[0][5].connect.cv = (~pulseEnv = CV(ControlSpec(0, 1)));
l.knobRows[0][6].connect.cv = (~freqT = CV(ControlSpec(0, 1)));
l.knobRows[0][7].connect.cv = (~freqEnv = CV(ControlSpec(0, 1)));

l.knobRows[1][4].connect.cv = (~rawFreq = CV(ControlSpec(0, 1)));
l.knobRows[1][5].connect.cv = (~freqMix = CV(ControlSpec(0, 1)));
l.knobRows[1][7].connect.cv = (~noisesSelect = CV(ControlSpec(0, ~noises.size)));

DistCurve(\amp_pulse,
	Env([-0.7, -0.5, -0.8, -0.6 -0.1, 0, 0.6, 0.2, 0.4, 0.7]),
);
DistCurve(\amp_pulse2,
	Env([1, 0.8, -1]),
);

SynthDef(\smp_pulse, {
	| b=0, baseFreq=1700, pulseT=0, pulseEnv=0, freqT=0, freqEnv=0, rawFreq=0.1, freqMix=0.5 |
	var baseTime, level, sig, pulse, pos, freq, freqMap, dsig, noise;
	pulseT = pulseT*3;
	pulseEnv = pulseEnv*3;
	freqT = freqT*3;
	freqEnv = freqEnv*3;
	baseTime = 4;
	level = ~multiEnvGen.(~envs, ~scalars).(baseTime, pulseT, pulseEnv);
	freq = ~multiEnvGen.(~envs, ~scalars).(baseTime, freqT, freqEnv);
	freqMap = ControlSpec(0.5, 60, warp:\exponential);
	freq = ((40*freq) * freqMix) + (freqMap.map(rawFreq) * (1 - freqMix));
	pulse = LFPulse.ar(freq, 0, level*0.8);
	pos = Phasor.ar(1, pulse * BufRateScale.kr(b), 0, BufFrames.kr(b));
	noise = BufRd.ar(1, LFNoise2.kr(0.1, 8, 8).round(1), pos, interpolation:4);
	sig = CombC.ar(noise, 0.2, (60-24 + [0, 3, 5, 7, 24.1]).midicps.reciprocal, 1.3).sum;
	sig = FreeVerb.ar(
		sig,
		mix: 0.1,
		room: 0.8,
		damp: 0.1
	);
	sig = LeakDC.ar(sig);
	sig = HardCompress.ar(sig, 0.1, 0.1);
	sig = PanArray.ar(6, sig, LFDNoise3.ar(LFDNoise3.ar(0.4, 0.3, 0.4)), width:3);
	sig = sig.collect({
		| sig, i |
		DynKlank.ar(`[
			[1, 1.05, 3, 5, 7, 7.1, 1.02] + { 0.2.rand },
			1 ! 7,
			[1, 0.5, 0.4, 0.3, 0.2, 0.1, 0.08] * (1.1 + i)
			],
			sig,
			freqscale: (baseFreq + { 6.0.rand } + (level * LFTri.ar(12, {1.0.rand}, 12)))
		)
	}).scramble;
	sig = LeakDC.ar(sig);
	sig = Splay.ar(sig) * 0.001;
	sig = sig.tanh + (0.01 * noise);
	Out.ar(0, sig * 50);
}).add;

~pulse = Group();

[\p1, \p2, \p3, \p4].do({
	| synth, i |
	var button = l.buttons[i];
	button.connect.default.toggle_(true);
	button.buttonOnActions.clear;
	button.buttonOffActions.clear;
	button.buttonOnActions.add({
		"on".postln;
		currentEnvironment[synth] = Synth.controls(\smp_pulse, args:[
			\baseFreq, [88, 92, 97, 100][i].midicps / 100,
			\b, ~noisesSelect,
			\pulseT, ~pulseT,
			\pulseEnv, ~pulseEnv,
			\freqT, ~freqT,
			\freqEnv, ~freqEnv,
			\rawFreq, ~rawFreq,
			\freqMix, ~freqMix,
		], target:~pulse);
	});
	button.buttonOffActions.add({
		currentEnvironment[synth].free;
	});
});
~pulse.free;

)
