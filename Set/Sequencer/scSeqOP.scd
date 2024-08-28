//settings (execute this first)
(
~bpm = 120;
~step = 32;
~block = 4;
~blockSize = ~step*~block;
~counter = 0; //global counter
)

//////////set parameter//////////
//title, type(\t or \s), array ←mandatory!!
//min, max, div
(
~deg = Dictionary.with(*[
	\title->"degree",
	\type->\s,
	\array->Array.fill(~blockSize,{0}),
	\div->5,
	\min->0,
	\max->6
]);
~drum = Dictionary.with(*[
    \title->"trig",
	\type->\t,
	\array->Array.fill(~blockSize,{0}),
]);
)
~seqArg = [~deg, ~drum];

//////////set array to buffer//////////
Buffer.freeAll //clear
(
~deg1Buf = Buffer.alloc(s, ~blockSize);
~deg1Buf.setn(0, ~deg[\array]);

~dr1Buf = Buffer.alloc(s, ~blockSize);
~dr1Buf.setn(0, ~drum[\array]);
)

//////////execute sequencer//////////
~seq.value(~seqArg);

//////////start counter & playhead//////////
(
Synth(\counter);
AppClock.play(~routine);
)

//////////buffer vale update//////////
(
~bufUpdate = {
	~deg1Buf.setn(0, ~deg[\array]);
};
)

//////////synthDefs//////////

//monosynth
(
SynthDef(\testBuf,{
	var bufnum = \bufnum.kr(0);
	var freq = BufRd.kr(1, bufnum, In.kr(~cBus,1));
	var sn = Saw.ar((freq * 100)+100, 0.1);
	Out.ar(0, sn);
}).add;
)

Synth(\testBuf, [\bufnum, ~deg1Buf])

//trigsynth
(
SynthDef(\testTrig, {
	var gate = BufRd.kr(1, \bufnum.kr(0), In.kr(~cBus,1));
	var sn = WhiteNoise.ar(0.1);
	var env = EnvGen.kr(Env.perc, gate);
	Out.ar(0, sn*env);
}).add;
)





//波形表示ブロックを作成？


var de = (Env([0,0.2,0.28,0.99],[0.3,0.4,0.9]).discretize(16*4)).asArray;
var pe = (Env([1,1.2,0.9,1],[0.3,0.4,0.9]).discretize(16*4)).asArray;


//////////export array to csv//////////
~deg[\array].plot
(
// write a test file:
f = File(PathName(thisProcess.nowExecutingPath).parentPath ++ "/arrays/deg.sc", "w");
f.write("1,2,3,4,5");
f.close;
)

(
p = PathName(thisProcess.nowExecutingPath).parentPath ++ "/arrays/deg.sc";
x = CSVFileReader.readInterpret(p).postcs;
)
x[0]


//////////import array frim csv//////////











//wavetable作成
~wt1Buf = Buffer.alloc(s, 1024*2);

//更新
~wt1Buf.loadCollection(Env(~wt1[\array],1).asSignal(1024).asWavetable);
(
~wt1 = Dictionary.with(*[
	\title->"wt1",
	\type->\s,
	\array->Array.fill(~step*4,{0}),
	\div->1,
	\min->(-1),
	\max->1
]);
)
~wt1Buf.plot

~seqArg = [~wt1]
f.value(~seqArg);

(
SynthDef(\wt, {
	var sn = Osc.ar(\buf.kr(0), 300, 0, 0.2);
	Out.ar(0, sn);
}).add;
)

Synth(\wt, [\buf, ~wt1Buf.bufnum])



