//import wav
p = PathName(thisProcess.nowExecutingPath).parentPath ++ "wav/";
p = p ++ "***.wav";
b = Buffer.read(s, p, numFrames: 44100*4);
b.numFrames
b.play
b.free

//load to array a
b.loadToFloatArray(action: { arg array; a = array; { a.plot }.defer; "done".postln });

//wave table settings
~wavesize = 2000;
~buffersize = 2048; //should bigger than wavesize
k.size.do({|i| k[i].free});
k = Buffer.allocConsecutive(a.clump(~wavesize).size, s, ~buffersize, bufnum: 100);

//wave table buffer
(
var clump;
clump = a.clump(~wavesize);
//clump = clump.scramble;
clump.do({|item, i|
	var wt = Env(item, 1, \sin).asSignal(~buffersize/2);

	//add noise
	var seed = Array.rand(~wavesize/100, -0.5, 0.5);
	var noise = Env(seed, 1, \sin).asSignal(~buffersize/2);
	var join = (wt+noise).clip(-1,1).asWavetable;

	k[i].loadCollection(join);
});
)

k[0].plot


(
SynthDef(\spedDown,{
	var sn;
	sn = VOsc.ar(
		bufpos: Line.ar(k[0].bufnum, k[k.size-1].bufnum,
			\dur.kr(10), doneAction:2),
		//bufpos: \pos.kr(0),
		//phase: FSinOsc.ar(1,0),
		freq: \freq.kr(100),
		mul: 0.4);
	//sn = OnePole.ar(sn, 0.8);
	Out.ar(0, sn.dup);
}).add;
)

Synth(\spedDown, [\freq, 188])
