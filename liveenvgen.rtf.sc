s.boot;
s.waitForBoot({
	b = Buffer.loadCollection(s, ([1, 5, 1, 0, 0, 0, 0, 0, 0, 0] ++ 
		[ 0, 0 ] ++
		100.collect({
			| i |
			[ i, (i/10).sin ]
		}).flatten).postln
	);

	~bus = Bus(\control, 0, 1);

	{
		var line, env;
		line = MouseX.kr(0,60);
		env = LiveEnvGen.kr(b.bufnum, line) ! 100;
		Out.kr(0, env);
	}.play;	

	~bus.debugScope;
})
		

