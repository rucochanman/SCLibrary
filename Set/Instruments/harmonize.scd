//バンドパス
(
SynthDef(\harmonize,
{
	arg bFreq=400;
	var freq, ratio, bin, sn, out, size=50;

	freq = Array.series(size, bFreq, bFreq);
	sn = PlayBuf.ar(2, b, 1, doneAction:2);
	out = Mix(Resonz.ar(sn, freq, 0.005, 0.2));
	Out.ar(0, out);

}).add;
)

Synth(\harmonize, [\bFreq, 700]);

//低い周波数成分をピッチシフターで基本周波数に集める
(
{
	var freq, ratio, bin, sn, out, size=10, bFreq=400;
	freq = Array.series(size+1, bFreq, -1*(bFreq/2/size));
	ratio = Array.series(size+1, 1, 2/2/size);

	sn = PlayBuf.ar(2, b, 1, doneAction:2);
	bin = BBandPass.ar(sn, freq, 0.05, 0.4);
	out = Mix(PitchShift.ar(bin, pitchRatio: ratio));

}.play
)
