//////////boot server//////////
s.boot;

//////////load seqMain//////////
(
//absolute path to scSequecer.scd
var path = "C:/Users/***/SCTools/SCLibrary/Set/Sequencer/scSeqencer.scd";
load(path);
)

//////////song setting//////////
~bpm = 120;

//////////add blank block//////////
//name, type, bar, div, min, max
~param.value(\blank_4bar, \s, 4, 0, 0, 1);

//save to file
~save.value(~block);

//////////import array from csv//////////
(
var path, file;
path = PathName(thisProcess.nowExecutingPath).parentPath ++ "data";
path = PathName(path);
path.entries.do({|item|
	var name = CSVFileReader.read(item.fullPath)[0][0].asSymbol;
	var type = CSVFileReader.read(item.fullPath)[1][0].asSymbol;
	var bar = CSVFileReader.read(item.fullPath)[2][0].asInteger;
	var div = CSVFileReader.read(item.fullPath)[3][0].asInteger;
	var min = CSVFileReader.read(item.fullPath)[4][0].asFloat;
	var max = CSVFileReader.read(item.fullPath)[5][0].asFloat;
	var array = CSVFileReader.readInterpret(
		item.fullPath,true,true,startRow:6)[0];
	~param.value(name, type, bar, div, min, max, array);
});

//update buf
~block.do({|item| ~bufUpdate1.value(item)});
)

//////////execute sequencer//////////
(
//set param to seq
~setBlock = [~block[\blank_4bar]];

//size setting
~bar = 4;
~blockSize = ~step*~bar;

//execute
~seq.value(~setBlock);
)

//////////start counter & playhead//////////
(
~counter = 0;
Synth(\counter);
AppClock.play(~routine);
)

//////////synthDefs//////////

//monosynth
(
SynthDef(\testSlider,{
	var buf, blockSize, freq, sn;
	buf = \bufnum.kr(0);
	blockSize = \bufsize.kr(256);
	freq = BufRd.kr(1, buf, In.kr(~cBus,1).mod(blockSize));
	freq = (freq+60).midicps;
	sn = Saw.ar(freq, 0.1);
	Out.ar(0, sn);
}).add;
)

(
Synth(\testSlider, [
	\bufnum, ~block[\blank_4bar][\buf],
	\blockSize, ~block[\blank_4bar][\buf].numFrames])
)

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
