//音源読み込み
p = PathName(thisProcess.nowExecutingPath).parentPath ++ "wav/";
b = Buffer.readChannel(s, p ++ "***.wav", channels: 0);

(
Ndef(\lofi, {
	var in, sn, sr, hTrig, bufTrig, noise;
    //playbuf
	bufTrig = Impulse.kr(130/60/8);
	in = PlayBuf.ar(1, b, BufRateScale.kr(b), bufTrig);

	//sample&hold
    sr = \shrate.kr(22050).lag(1);
	noise = LFDNoise3.ar(sr).range(sr * (1 - \jitter.kr(0.1)), sr);
	hTrig = Impulse.ar(noise);
	sn = Latch.ar(in, hTrig);

	//slew
	sn = Slew.ar(sn,\slew.kr(4000),\slew.kr); //20 - samplerate/2

	//lpf
    4.collect{
		sn = LPF.ar(sn, \lpf.kr(4500));
	};

	//out
	sn.dup.clip(-0.8, 0.8);
}).play;
)
Ndef(\lofi).play

(
Ndef(\lofi).addSpec(
	\shrate, [110,22050, \exp],
	\lpf, [110,5000, \lin],
	\jitter, [0.01, 0.99, \lin],
	\slew, [20, 20000]
).gui
)
