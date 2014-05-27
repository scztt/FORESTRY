

/* Not used
	s = Server.internal.boot;
	p = Dictionary.new;
*/

 // Execute one time
(
	p[\buzz] = DualEnvir.new(s, "buzz");
	p[\buzz].push.linkDoc;
	Document.current.proxyBold;
)

b = Buffer.alloc(s, 44100);

~buzz.clear
SynthDef(\buzz, {
	| freq=310, lag=8, gate=1, filtMax=2, gain1=1.1 |
	var sig, mod, env, filtEnv;
	env = EnvGen.ar( Env.adsr(2,0.5,1,8), gate, doneAction:2 );
	filtEnv = EnvGen.ar( Env.adsr(0.1,0.5,1,14), gate, levelBias:1000, levelScale:filtMax*1000  );
	mod = SinOsc.ar(freq/[9,10,11,8,12]);
	freq = Lag2.kr( freq, 8 );
	sig = ( LFPulse.ar(freq * [1,1.01,1.022,0.995,1.333], mod, 0.1) ).sum;
	sig = MoogFF.ar( sig, filtEnv, 2 );
	sig = Mirror.ar( sig*(gain1+env) );
	sig = MoogFF.ar( sig, filtEnv, 2 );
	sig = sig * [1, 1] * env;
	Out.ar( 10, sig );
//	Out.ar( [0,1], sig );
}).add;

SynthDef( \highDelay, {
	| in |
	var inSig, sig, delayed;
	inSig = LeakDC.ar( In.ar( in, 1 ) + (LocalIn.ar(1)*0.4) );
	sig = HPF.ar( inSig, 8000 );
	inSig = LPF.ar(inSig, 60);
	delayed = MultiTap.ar(
		[0.1, 0.3, 0.4, 0.6, 0.7].collect({ |i| i+0.02.rand }),
		[0.8, 0.7, 0.5, 0.3, 0.1],
		in: sig,
		bufnum: b.bufnum );
	LocalOut.ar( delayed );
	Out.ar( [0,1], inSig );
}).add;

g = Group(s);
e = Group(g, \addAfter );

n = Synth( \highDelay, [\in, 10], target:e)

n = Synth( \buzz, [\freq, 92.midicps, \filtMax,1], target:g);
n = Synth( \buzz, [\freq, 41.midicps, \filtMax, 1], target:g)
n.set(\freq, 39.midicps)
n = Synth( \buzz, [\freq, 84.midicps, \filtMax, 3], target:g)
n = Synth( \buzz, [\freq, 48.midicps, \filtMax, 12], target:g)

g.set( \freq, 0, \lag, 60)
n.set(\gate, 0)
g.set( \filtMax, 0, \lag, 30)


g.set( \gate, 0)
g.set( \filtMax, 14)
n.free

~buzz.free
~buzz.play