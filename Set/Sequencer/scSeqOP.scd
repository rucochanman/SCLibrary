//////////boot server//////////
s.boot;

//////////load seqMain//////////
(
//absolute path to scSequecer.scd
var path = "***/SCTools/SCLibrary/Set/Sequencer/scSeqencer.scd";
load(path);
)

//////////song setting//////////
(
~bpm = 120;
~step = 32;
~bar = 4;
~blockSize = ~step*~bar;
~counter = 0;
)

//////////make new parameter//////////
~block = Dictionary();

//template
//title, type(\t or \s), array ←mandatory!!
//min, max, div

(
~block.put(
	\degree,
	Dictionary.with(*[
		\title->"degree",
		\type->\s,
		\array->Array.fill(~blockSize,{0}),
		\buf->Buffer.alloc(s, ~blockSize),
		\div->5,
		\min->0,
		\max->6,
	]);
);

~block.put(
	\trig,
	Dictionary.with(*[
		\title->"trig",
		\type->\t,
		\array->Array.fill(~blockSize,{0}),
		\buf->Buffer.alloc(s, ~blockSize)
	]);
);
)

//////////execute sequencer//////////

//set param to seq
~seqArg = [~block[\degree], ~block[\trig]];
~seq.value(~seqArg);

//////////start counter & playhead//////////
(
Synth(\counter);
AppClock.play(~routine);
)

//////////buffer vale update//////////


Buffer.freeAll //clear

(
~bufUpdate = {
	~deg1Buf.setn(0, ~deg[\array]);
};
)

~block[\degree][\buf].setn(0, ~block[\degree][\array]);
~block[\degree][\buf].plot

~block[\trig][\buf].setn(0, ~block[\trig][\array]);
~block[\trig][\buf].plot

//////////synthDefs//////////

//synthDess template
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

//export all files
(
~block.keys.do({ |item, i|
	//file setteings
	var filename = ~block[item][\title];
	var path = PathName(thisProcess.nowExecutingPath).parentPath +/+ "data";
	var file = File(path +/+ filename ++ ".sc", "w");

	//write params
	//title
	file.write(filename ++ "\n");
	//type
	file.write(~block[item][\type] ++ "\n");
	//array
	~block[item][\array].do({|i|
		file.write(i.asString ++ ",");
	});
	file.write("\n");
	//min
	file.write(~block[item][\min].asString ++ "\n");
	//max
	file.write(~block[item][\max].asString ++ "\n");
	//div
	file.write(~block[item][\div].asString ++ "\n");
	file.close;
});
)




(
p = PathName(thisProcess.nowExecutingPath).parentPath ++ "data/degree.sc";
//x = CSVFileReader.readInterpret(p).postcs;
x = CSVFileReader.read(p)[1].postcs;
)



//////////import array frim csv//////////
//0:title, 1:type, 2:array, 3:min, 4:max, 5:div

(
var myPath, file;
myPath = PathName(thisProcess.nowExecutingPath).parentPath ++ "data";
myPath = PathName(myPath);
file = myPath.entries[0].fullPath;
x = CSVFileReader.read(file)[5][0].postcs;
//p.entries[0]
//p.entries[0].fileName.postln
)










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
