~wavesize = 2000;
//import wav
p = PathName(thisProcess.nowExecutingPath).parentPath ++ "wav/";
p = p ++ "***.wav";
~wav1 = Buffer.read(s, p, numFrames: ~wavesize*40);
~wav2 = Buffer.read(s, p, numFrames: ~wavesize*40);

//load to array
~wave1.loadToFloatArray(action: { |array| ~p1Array = array; "done".postln });
~wave2.loadToFloatArray(action: { |array| ~p2Array = array; "done".postln });

//alloc buffer
~buffersize = 2048*2; //should bigger than wavesize*2
(
var size = ~p1Array.clump(~wavesize).size * 2;
~buf.size.do({|i| ~buf[i].free});
~buf = Buffer.allocConsecutive(size, s, ~buffersize, bufnum: 100);
)

//interlace wt
(
var clump1, clump2, join;
clump1 = ~p1Array.clump(~wavesize);
clump2 = ~p2Array.clump(~wavesize);
join = [clump1, clump2].lace;

join.do({|item, i|
	var wt = Env(item, 1, \sin).asSignal(~buffersize/2);
	~buf[i].loadCollection(wt.asWavetable);
});
)

(
SynthDef(\wt,{
	var sn;
	sn = VOsc.ar(
		bufpos: Line.ar(~buf[0].bufnum, ~buf[~buf.size-1].bufnum,
			\dur.kr(4), doneAction:2),
		//bufpos: \pos.kr(0),
		//phase: FSinOsc.ar(1,0),
		freq: \freq.kr(80),
		mul: 0.4);
	//sn = OnePole.ar(sn, 0.8);
	Out.ar(0, sn.dup);
}).add;
)

Synth(\wt, [\freq, 43])



