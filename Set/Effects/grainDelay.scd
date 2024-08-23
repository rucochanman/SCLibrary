~recBuf = Buffer.alloc(s, 44100 * 1.0, 1);
(
SynthDef(\grainDelay, {
	var source, rec, grains, wet=0.5, dry=0.5, delayn=4;
	var buf = \buf.kr(0);
	var trig = [\trig1.kr(1), \trig2.kr(2), \trig3.kr(3)];
	var dur = [\dur1.kr(0.05), \dur2.kr(0.07), \dur3.kr(0.06)];
	var rate = [\rate1.kr(1), \rate2.kr(1), \rate3.kr(1)];
	var pos = [\pos1.kr(0.1), \pos2.kr(0.5), \pos3.kr(0.9)];
	var delayt = \delayt.kr(0.1);

	//souce to buf
	source = PlayBuf.ar(1, buf, BufRateScale.kr(buf), loop:1);
	rec = RecordBuf.ar(source, ~recBuf, loop:1);

	//grain
	grains = GrainBuf.ar(1, Impulse.kr(trig), dur, ~recBuf, rate, pos);

	delayn.do({|i|
		grains = DelayN.ar(grains,delayt*delayn,delayt*(i+1),0.5,grains);
	});
	grains = grains.sum;

	dry = \dry.kr(0.5);
	wet = \wet.kr(0.5);

	Out.ar(0, ( (source*dry) + (grains*wet) ).dup);
}).add;
)
Synth(\grainDelay)