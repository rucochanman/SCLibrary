//////////boot server//////////
s.boot;

//////////load seqMain//////////
(
//absolute path to scSequecer.scd
var path = "Users/***/Desktop/SCTools/Set/Sequencer/scSeqencer.scd";
load(path);
)

//////////song setting//////////
~bpm = 120;

//////////make new parameter//////////

(
~param = { arg
	//////////set param//////////
	name = \name_size,
	type = \s, // \s(slider) or \t(trig)
	bar = 4,  //bar size
	//////////optional//////////
	div = 0,
	min = 0.0,
	max = 1.0;

	//////////make dict//////////
	var block;
	block = Dictionary.with(*[
		\name -> name,
		\type -> type,
		\bar -> bar,
		\array -> Array.fill(~step*bar, {0}),
		\buf -> Buffer.alloc(s, ~step*bar),
		\div -> div,
		\min -> min,
		\max -> max,
	]);

	//////////add to block array
	~block.put(name, block);
};
)

//add blank block
~param.value(\test_4bar, \s, 4, 0, 0, 1);

//save to file
~save.value;


//////////execute sequencer//////////
(
//set param to seq
~setBlock = [~block[\test_4bar]];

//size setting
~bar = 4;
~blockSize = ~step*~bar;

//execute
~seq.value(~setBlock);
)


//////////start counter & playhead//////////
(
Synth(\counter);
AppClock.play(~routine);
)

//////////buffer update while running//////////

(
~bufUpdate = {
	~setBlock.do({ |item|
		item[\buf].setn(0, item[\array]);
	});
};
)

~block[\test_4bar][\buf].setn(0, ~block[\test_4bar][\array]);
~block[\test_4bar][\buf].plot

//////////buffer update once//////////

(
~bufUpdate1 = { |item|
	item[\buf].setn(0, item[\array]);
};
)


Buffer.freeAll //clear

//////////synthDefs//////////

//synthDess template
//monosynth
(
SynthDef(\testBuf,{
	var bufnum = \bufnum.kr(0);
	//setting block size mod
	var freq = BufRd.kr(1, bufnum, In.kr(~cBus,1));
	var sn = Saw.ar((freq * 100)+100, 0.1);
	Out.ar(0, sn);
}).add;
)

Synth(\testBuf, [\bufnum, ~deg1Buf])

//trigsynth
(
SynthDef(\testTrig, {
	//setting block size mod
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

//save all blocks
//name, type, step, bar, div, min, max, array
(
~save = {
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
		//bar
		file.write(~block[item][\bar].asString ++ "\n");
		//div
		file.write(~block[item][\div].asString ++ "\n");
		//min
		file.write(~block[item][\min].asString ++ "\n");
		//max
		file.write(~block[item][\max].asString ++ "\n");
		//array
		~block[item][\array].do({|i|
			file.write(i.asString ++ ",");
		});
		file.write("\n");

		//file close
		file.close;
	});
};
)

~save.value;


//////////import array frim csv//////////
//name, type, step, bar, div, min, max, array

(
var path, file;
path = PathName(thisProcess.nowExecutingPath).parentPath ++ "data";
path = PathName(path);
path.entries.do({|item|
	var title = CSVFileReader.read(item.fullPath)[0][0].asString;
	var type = CSVFileReader.read(item.fullPath)[1][0].asString;
	var step = CSVFileReader.read(item.fullPath)[2][0].asInteger;
	var bar = CSVFileReader.read(item.fullPath)[3][0].asInteger;
	var div = CSVFileReader.read(item.fullPath)[4][0].asInteger;
	var min = CSVFileReader.read(item.fullPath)[5][0].asInteger;
	var max = CSVFileReader.read(item.fullPath)[6][0].asInteger;
	var array = CSVFileReader.read(item.fullPath)[7];
	~param.value(title, type, step, bar, div, min, max, array);
});
)

~block[\piano]
~param.value("piano", "s", 32, 4);

(
var path, file;
path = PathName(thisProcess.nowExecutingPath).parentPath ++ "data";
path = PathName(path);
p = path.entries[0];
//x = CSVFileReader.readInterpret(p.fullPath)[6];
x = CSVFileReader.read(p.fullPath)[2][0].asInteger;
)











//////////wavetable作成
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
