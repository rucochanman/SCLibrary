~path = PathName(thisProcess.nowExecutingPath).parentPath;
~path = ~path ++ "wav/***.wav";
~wav = Buffer.readChannel(s, ~path, startFrame:44100*30, numFrames:44100*10, channels:0);
~wav.play
~wav.free

//arrayにwavデータを格納
~wav.loadToFloatArray(action: { |array| ~array = array; "done".postln });

// n/sizeに縮める
(
var size = 50, clump, z;
~temp = [];
~array.size.do({ |i|
	if((i%size) == 0, {~temp=~temp.add(~array[i]);});
});


//with interpolate
e = [];
z = 0;
~temp.do({|item|
	var ease;
	ease = Array.interpolation(20,z,item);
	ease.do({|item2| e = e.add(item2)});
	e = e.add(item);
	z = item;
});
~temp = e;
)

//load to buffer
~buf.free;
~buf = Buffer.loadCollection(s, e);


(
SynthDef(\playbuf, {
	var	sn = PlayBuf.ar(1, \bufnum.kr(~buf), \rate.kr(1), loop:1) * 0.5;
	Out.ar(0, sn.clip(-0.5, 0.5).dup);
}).add;
)

Synth(\playbuf)
