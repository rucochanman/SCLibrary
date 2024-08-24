//////////音源読み込み
p = PathName(thisProcess.nowExecutingPath).parentPath ++ "wav/";
p = p ++ "piano_02.wav";
w = Buffer.readChannel(s, p, numFrames: 44100, channels:0);
w.play
w.free

//////////fftする
~buffersize = 1024;
(
OSCdef(\send).disable;
OSCdef(\send).enable;
b.free;
c.free;
)

(
b = Buffer.alloc(s, ~buffersize, 1);
c = Bus.control(s, ~buffersize);

SynthDef(\fft, {
var in, chain, stream, windowStarts, out;
	in = PlayBuf.ar(1, w, BufRateScale.kr(w), loop:0, doneAction:2);
	chain = FFT(b, in);
	stream = UnpackFFT(chain, ~buffersize, frombin:0, tobin:~buffersize/2);
	windowStarts = chain > -1;
	out = Demand.kr(windowStarts, 0, stream);
	Out.kr(c, out);
	SendTrig.kr(windowStarts,0,1);
}).add;

~fftArray = [];
OSCdef(\send, { arg msg, time;
	~fftArray = ~fftArray.add(c.getnSynchronous(~buffersize));
},'/tr', s.addr);
)
Synth(\fft);
~fftArray.size

//////////~fft array を並び替え
(
 var temp = [];
 y = []; x = [];
 ~fftArray.size.do({ |i|
	temp = temp.add(~fftArray[i].clump(2).flop);
 });

 ~fftArray.size.do({ |i|
	y = y.add(temp[i][0]);
	x = x.add(temp[i][1]);
 });
)

//////////dictionaryに登録
d = Dictionary();
d.put(\piano_y, y);
d.put(\piano_x, x);

//////////bufferに倍音を詰める
g.size.do{ |i| g[i].free }
g = Buffer.allocConsecutive(y.size, s, ~buffersize*2, bufnum:100);
(
g.size.do({ |i|
	var freq = (0..~buffersize);
	g[i].sine3(freq, d[\piano_y][i], d[\piano_x][i], asWavetable:false);
});
)

//////////鳴らす
(
SynthDef(\addSynth, {
	var sn, bFreq;
	bFreq = (SampleRate.ir/2) / (~buffersize/2);
	//bFreq = \freq.kr(80);
	sn = VOsc.ar(
		bufpos: Line.ar(g[0].bufnum, g[g.size-1].bufnum, 4, doneAction:2),
		freq: bFreq);
    //sn = OnePole.ar(sn, 0.5);
	Out.ar(0, sn * \amp.kr(0.2));
}).add;
)

Synth(\addSynth, [\freq, 48]);
