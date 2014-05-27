
/* Not used
	s = Server.internal.boot;
	p = Dictionary.new;
*/

 // Execute one time
(
p[\throw] = DualEnvir.new(s, "throw");
p[\throw].push.linkDoc;
//p[\throw].clear;
Document.current.proxyBold;



~p_simple = Pseq([100,200,300], inf).asStream;
~p_complex = Pseq([
	Prand([0.2,0.3,0.4],10),
	Prand([0.2,0.2,0.4, 1],5),
	Prand([1,1.333, 2, 1.5, 1.75, 1.25, 1.7 ],12),
	Prand([5,0.2,0.2,0.3,1,0.35,0.2],10),
	Prand([1,2,1.333,2.333,2.5,3,1.5],10)
], inf).asStream;

SynthDef(\noter, {
	arg out=0, in=0, amp=0.0, attack=0.1, freq=300, dur=10.0, noise=0;
	var sig, inSig, feedAmt, highFeed, lowFeed, delay, pan, ampEnv;
	pan = Latch.kr( MouseX.kr( -1,1), 1);
	inSig = InFeedback.ar( in )
	* EnvGen.kr( Env.new([0.0, 1, 0.6, 0.0], [0.2, noise, 0.6], 'linear'), 1, timeScale: dur/6 );

	#highFeed, lowFeed = LeakDC.ar(LocalIn.ar( 2 ));

	delay = ( LFNoise2.ar( 540, noise*10, freq) + ( LPF.ar( inSig, 115 )*Line.kr( 640*noise,4, dur) ) ).reciprocal - (64/44100);

	feedAmt = EnvGen.kr( Env.new([0.98, 1.0, 1.0, 0.999, 0.6, 0.0001], [0.1, 0.3, 0.3, 0.1, 0.2]), 1, timeScale: dur, doneAction: 2 );
	ampEnv = EnvGen.kr( Env.new([0.98, 1.0, 1.0, 0.999, 0.2, 0.0001], [0.1, 0.3, 0.3, 0.1, 0.4].normalizeSum, \exp), 1, timeScale: dur);

	inSig = CombC.ar( inSig, 0.1, 0.5/freq, 0.04) + (0.4*(
		LPF.ar( LFPulse.ar( LFNoise2.ar( 10, 10, 20) , 0, LFNoise2.ar( 15, 0.1, 0.9 ) ).max(0.8), 800) *
		DelayL.ar( lowFeed, 0.2, 1/(LFNoise2.kr( 0.1, 4, 8)*LFNoise2.kr( 4.8, 1, 2 ).round(1)) )
	));

	feedAmt = feedAmt * ( 1+ ( (Amplitude.kr( highFeed )-0.11).min(0)).neg );
	sig = LPF.ar( LFPulse.ar( LFNoise2.ar(4, 4, freq/2), 0, LFNoise2.ar( 6, 0.05, 1.0-(noise*0.1) )), freq*2).max(0.5) *
	(inSig + DelayC.ar( LPF.ar( highFeed*feedAmt, freq*10), 0.1, delay ));
	LocalOut.ar( [ sig, inSig] );

	Out.ar( out, Pan2.ar( sig+inSig, pan, amp*ampEnv) );
}).inspect;

SynthDef

o = OSCresponder(s.addr,'/tr',{ arg time,responder,msg;

	var qn;
	p[\throw].use({
		qn = ~p_simple.next * ~p_complex.next; qn.postln;
		~noter.spawn([\in, ~in.index, \freq, qn, \amp, 0.09, \dur, 30, \noise, 0.7]);
	});
}).add;

~in = { LPF.ar( WhiteNoise.ar(  0.3 ), 400 ) };
~in.scope;

(
\instrument: \noter,
\freq: 440,
\dur: 6,
\attack: 0.3,
\amp: 0.15,
\noise: 0.01
).play;

)

(
~throw = { |on=0| on };

~x = Bus.control( s, 1);
~y = Bus.control( s, 1);

~vel = {
	var x, y, d=0.05;
	x = ~x.kr; y = ~y.kr;
	(
		( ( x - DelayL.kr(x,d,d) ).abs**2 ) +
		( ( y - DelayL.kr(y,d,d) ).abs**2 ) )**0.5;
};

~accel = {
	var d=0.05;
	(~vel.kr - DelayL.kr(~vel.kr,d,d) );
};

~a2 = {
	var d=0.05;
	(~accel.kr - DelayL.kr(~accel.kr,d,d) )*3;
};

~ping = {
	| out, throw=1 |
	var trig, acc, thresh, threshDecay=0.5;
	acc = ~a2.kr;
	thresh = Slew.kr( acc, threshDecay, 100 );
	trig = throw*Trig.kr( acc>thresh, 0.5 );
	SendTrig.kr( trig, 2, 1);
};


~noter.clear;
~noter = \noter;
~noter.play;



//~in = { p[\pasque][\out].ar(1); }

)




	~p_complex = Pseq([
		Prand([0.2,0.4, 0.6],10),
	], inf).asStream;





(
	var oldx=0, oldy=0;
	w = SCWindow( "throw test", Rect( 100, 800, 310, 600 ) );

	w.view.decorator = FlowLayout(w.view.bounds);
	t = SCTabletView(w,Rect(40,40,300,300));
	w.view.decorator.nextLine;

	~c_controls = Array.new(6);


	~c_controls.add( EZSlider( w, 280@30, "x", ControlSpec( 0.0, 1.0 ), labelWidth: 80, numberWidth:40) );
	~c_controls[0].action_({ |v| p[\throw][\x].source.set( v.value ) }) ;
	w.view.decorator.nextLine;


	~c_controls.add( 	EZSlider( w, 280@30, "y", ControlSpec( 0.0, 1.0 ), labelWidth: 80, numberWidth:40) );


	~c_controls[1].action_({ |v| p[\throw][\y].source.set( v.value ) }) ;
	w.view.decorator.nextLine;


	~c_controls.add( 	EZSlider( w, 280@30, "pres", ControlSpec( 0.001, 1.00 ), labelWidth: 80, numberWidth:40) );


	w.view.decorator.nextLine;
	~c_controls.add( 	EZSlider( w, 280@30, "tiltx", ControlSpec( -1.0, 1.0 ), labelWidth: 80, numberWidth:40) );
	w.view.decorator.nextLine;

	~c_controls.add( 	EZSlider( w, 280@30, "tilty", ControlSpec( -1.0, 1.0 ), labelWidth: 80, numberWidth:40) );


	w.view.decorator.nextLine;

	~c_controls.add( 	EZSlider( w, 280@30, "device", ControlSpec( 0, 5 ), labelWidth: 80, numberWidth:40) );




	t.background = Color.white;
	w.front;

	f = { arg  view,x,y,pressure,tiltx,tilty,deviceID, buttonNumber,clickCount,absoluteZ,rotation;
		p[\throw].use({

			( (pressure>0.1) && ( ((oldx-x).abs + (oldy-y).abs) > 0.1) ).if({
				".".postln;
				~noter.spawn([\in, ~in.index, \freq, ~p_simple.next * ~p_complex.next;, \amp, 0.10, \dur, 20, \noise, 0.3]);
			});

			~c_controls[0].value = x/300.0 ;
			~c_controls[1].value = y/300.0 ;
			~c_controls[2].value = pressure ;
			~c_controls[3].value = tiltx;
			~c_controls[4].value = tilty;
			~c_controls[5].value = deviceID;
			oldy = y; oldx = x;
		});
	};
	t.action = f;
	t.mouseDownAction = f;


)

~p_1 = PbindProxy.new;
~p_1.set( \instrument, \noter);
~p_1.set( \in, ~in.index );
~p_1.set( \dur, Prand( [30], inf) );
~p_1.set( \legato, 2 );
~p_1.set( \noise, 0.3 );
~p_1.set( \freq, Prand( [70, 140, 71, 35, 300]*10, inf ) );
~p_1.set( \amp, 0.2);

~p = Ppar( [~p_1, ~p_1, ~p_1, ~p_1, ~p_1, ~p_1], 5 );
~p.clear;

~out = { [~p.ar, ~p.ar ] }
~out.play