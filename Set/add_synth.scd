//音源読み込み
p = "/***.wav";
w = Buffer.read(s, p, 0, 2048*16);

//fftする
~buffersize = 1024;
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

//////////////
//~fft array を並び替え
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

//////////////

//dictionaryに登録
d = Dictionary();
d.put(\a_y, y);
d.put(\a_x, x);

//bufferに倍音を詰める
g.free;
g = Buffer.alloc(s, ~buffersize/2, 1);
g.sine3((0..(~buffersize/2))/4, d.at(\a_y)[10], d.at(\a_x)[10]);

//鳴らす
(
SynthDef(\addSynth, {
	var sn, vib;
	vib = FSinOsc.ar(\vFreq.kr(4), 0, \vAmp.kr(2));
	sn = Osc.ar(g, \freq.kr(440)+vib, 0, \amp.kr(0.5));
    sn = OnePole.ar(sn, 0.5);
	Out.ar(0, sn);
}).add;
)

x = Synth(\addSynth);

//oscでパラメータ受信
(
OSCdef(\param1, { arg msg;
	var index = msg[1].round.asInteger;
	y = d.at(\a_y)[index];
        x = d.at(\a_x)[index];
},'/2/a');
)
g.sine3((0..(~buffersize/2))/4, y, x);

//消去する時
//clear
(
OSCdef(\send).disable;
OSCdef(\send).enable;
b.free;
c.free;
)