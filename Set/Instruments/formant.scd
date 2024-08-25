(
SynthDef(\voice, {
	arg freq = 440,
	f = #[ 400, 750, 2400, 2600, 2900 ],
	a = #[ 1, 0.3, 0.1, 0.1, 0.01 ],
	q = #[ 0.1, 0.1, 0.04, 0.04, 0.04 ];
	var voice, breath, vib, fm, pitch, dif, sn1, sn2;
	breath = WhiteNoise.ar(0.05);
	vib = SinOsc.kr(6, mul:4) + SinOsc.kr(2, mul:3);
	fm = SinOsc.ar(freq * 2, 0, freq * 2);
	voice = Mix(Saw.ar(440 + vib, SinOsc.kr([2.5,5.8], 0, 0.04, [0.7,0.4])));
	sn1 = Mix(BBandPass.ar(voice+breath, f, q, a));
	dif = LFNoise2.kr(180);
	sn2 = Mix(BBandPass.ar(voice+breath, f+(dif*10), q+(dif*0.05), a+(dif*0.1)));
	Out.ar(0, (sn1+sn2).dup*0.2);
}).add;
)

x = Synth(\voice);
x.free

(
e.free;
e = OSCFunc({ arg msg;
	var value =
	    (msg[1] * FormantTable.get(\sopranoA))
	    +(msg[2] * FormantTable.get(\sopranoI))
	    +(msg[3] * FormantTable.get(\sopranoU))
	    +(msg[4] * FormantTable.get(\sopranoE))
	    +(msg[5] * FormantTable.get(\sopranoO));
	#f, a, q = value;
	x.setn(\f, f, \a, a, \q, q);
}, '/ps');
)

FormantTable.get(\sopranoA)
