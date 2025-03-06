//////////paths//////////
~wavesize = 4000;
p = PathName(thisProcess.nowExecutingPath).parentPath;
p = PathName(p).parentPath;

~p1 = p ++ "wav/shamisen/shamisen.wav";

//load to buffer
~sample1 = Buffer.read(s, ~p1, startFrame: 44100*12, numFrames: ~wavesize*40);
~sample2 = Buffer.read(s, ~p1, startFrame: 44100*47, numFrames: ~wavesize*40);
~sample3 = Buffer.read(s, ~p1, startFrame: 44100*63, numFrames: ~wavesize*40);
//load to array
~sample1.loadToFloatArray(action: { |array| ~p1Array = array; "done".postln });
~sample2.loadToFloatArray(action: { |array| ~p2Array = array; "done".postln });
~sample3.loadToFloatArray(action: { |array| ~p3Array = array; "done".postln });

//clear

~sample1.free;
~sample2.free;
~sample3.free;


//play
~sample1.play
~sample2.play
~sample3.play

//////////direct buffer//////////
~wtbuf.free;
(
var clumpSize = 600;
var clump1, clump2, clump3, join, z, ejoin, buf;
//clump array
clump1 = ~p1Array.clump(clumpSize);
clump2 = ~p2Array.clump(clumpSize);
clump3 = ~p3Array.clump(clumpSize);

//vol normalize
clump1 = clump1.collect({|item| item.normalize - 0.5 });
clump2 = clump2.collect({|item| item.normalize - 0.5 });
clump3 = clump3.collect({|item| item.normalize - 0.5 });

//join
join = [clump1, clump2, clump3].lace;

//with interpolate
ejoin = [];
z = 0;
join.do({|item|
	var ease, ilengths=100;
	ilengths = (item[0] - z).abs * ilengths;
	ease = Array.interpolation(ilengths, z, item[0]);
	ejoin = ejoin.add(ease);
	ejoin = ejoin.add(item);
	z = item[item.size-1];
});

//load to buf
join = ejoin.flatten;
~wtbuf = Buffer.loadCollection(s, join);
)


0.2*1000
1/0.02
1+1

(
SynthDef(\interlaceBuf, {
	var	sn = PlayBuf.ar(1, \bufnum.kr(~wtbuf), \rate.kr(1), loop:1);
	//sn = LPF.ar(sn, 8000);
	Out.ar(0, sn.clip(-0.5, 0.5).dup);
}).add;
)
Synth(\interlaceBuf, [\bufnum, ~wtbuf, \rate, 3])


p = PathName(thisProcess.nowExecutingPath).parentPath;
p = PathName(p).parentPath;

s.record(p++"record/clump600h100rate3.wav")

