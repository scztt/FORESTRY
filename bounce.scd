Server.default = s = Server.internal;
s.boot;

~buf = Buffer.alloc(s, s.sampleRate * 10, 2);

~recorder = NodeProxy(s, \audio, 2);
~recorder.source = {
	var sig, input;
	input = SoundIn.ar([0, 1]);
	RecordBuf.ar(input, ~buf.bufnum,
		recLevel: -1.dbamp,
		preLevel: -6.dbamp
	);

	sig = PlayBuf.ar(2, ~buf.bufnum, loop:1);
	sig;
};

~mod = NodeProxy(s, \audio, 2);
~mod.source = {
	var input, mod;

	input = ~recorder.ar(2);

	mod = Impulse.ar(3/4);
	mod = Decay2.ar(mod, 0.01, 0.8);

	// Delay
	mod = CombC.ar(mod, 1, 0.5, 5);

	// input
	input = BLowPass.ar(input, MouseX.kr(30, 3000, \exponential), 1);

	mod * input * 10;
};

~mod.play;

s.meter