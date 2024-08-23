//input settings
Server.default.options.outDevice_("Windows DirectSound : スピーカー (Pebble V3)");
Server.default.options.inDevice_("Windows DirectSound : CABLE Output (VB-Audio Virtual Cable)");

//read wav
p = PathName(thisProcess.nowExecutingPath).parentPath;
p = p ++ "wav/DnB2.wav";
b = Buffer.readChannel(s, p, channels:0);
Buffer.freeAll
b.play

//classic type vocoder
(
SynthDef(\classic_vocoder, {
	var num=30, filter_bank, mod, car, envs, out;
	var bpfhz = (1..num).linexp(1, num, 25, 16000), q = \q.kr(20);
	var mBuf = \mbuf.kr(0);
	var cBuf = \cbuf.kr(0);

	mod = PlayBuf.ar(1, mBuf, BufRateScale.kr(mBuf), loop:1);
	car = PlayBuf.ar(1, cBuf, BufRateScale.kr(cBuf), loop:1);
	// or noise as carrier
	//car = CombL.ar(WhiteNoise.ar(1), 1/20, 1/(\freq.kr(50)), 3);

	mod = BPF.ar(mod, bpfhz, 1/q, q.sqrt);
	envs = Amplitude.ar(mod).lag(0.3);
	car = BPF.ar(car, bpfhz, 1/q, q.sqrt) * envs;
	Out.ar(0,(car*0.5).sum);
}).add;
)

//filterbank type
(1..10).linexp(1, 10, 20, 16000);
(1..10).linlin(1, 10, 20, 16000);
(1..10).curvelin(1, 10, 20, 16000);
Array.fill(10, {|i| ((16000-20)/10/2)*(i+1)});


//pulse vocoder
~outbus = Bus.audio(s, 1);
(
SynthDef(\pulse_vocoder, {
	var in, mod, car, pitch, width, num = 40;
	var mBuf = \bufnum.kr(0), q = \q.kr(30);
	var carlow, carmid, carhi;
	var dry, wet;
	var bpfhz;

	//source sound -> bpf
	bpfhz = (1..num).linexp(1, num, \min.kr(20), \max.kr(16000));
	in = PlayBuf.ar(1, mBuf, BufRateScale.kr(mBuf), loop:1);
	mod = BPF.ar(in, bpfhz, 1/q, q.sqrt);

	//modulate
	//pitch = LFNoise1.kr(\pFreq.kr(10), \pMul.kr(200));
	pitch = \pitch.kr(0);
	width = LFNoise1.kr(\wFreq.kr(10), 0.45, 0.5);

	car = Array.fill(num,{0});
	num.do({ |i|
		var freq, holdFreq, hasFreq, envs;
		# freq, hasFreq = Pitch.kr(mod[i]);
		//holdFreq = Latch.ar(freq, hasFreq);
		envs = Amplitude.kr(mod[i]);
		car[i] = Pulse.ar(freq+pitch, width, Decay.kr(envs*hasFreq, 0.2));
	});
	car = car.sum * 1/num;

	Out.ar(\outbus.kr(0), (car*\amp.kr(1)));
}).add;
)

Synth(\vocoder_pitch, [\bufnum, b])


//pulse vocoder with fixed pitch
(
SynthDef(\fixedPitch_vocoder, {
	var in, mod, car, pitch, width, num = 40;
	var mBuf = \bufnum.kr(0), q = \q.kr(30);
	var carlow, carmid, carhi;
	var dry, wet;
	var bpfhz;
	var qmod;

	//source sound -> bpf
	qmod = LFNoise1.kr(11, 10);
	bpfhz = (1..num).linexp(1, num, \min.kr(20), \max.kr(16000));
	in = PlayBuf.ar(1, mBuf, BufRateScale.kr(mBuf), loop:1);
	mod = BPF.ar(in, bpfhz, 1/(q+qmod), (q+qmod).sqrt);

	//modulate
	pitch = LFNoise1.kr(\pFreq.kr(9), \pMul.kr(200));
	//pitch = \pitch.kr(0);
	width = LFNoise1.kr(\wFreq.kr(10), 0.45, 0.5);

	car = Array.fill(num,{0});
	num.do({ |i|
		var freq, hasFreq, envs;
		//# freq, hasFreq = Pitch.kr(mod[i]);
		envs = Amplitude.kr(mod[i]);
		car[i] = Pulse.ar(bpfhz[i]+pitch, width, Decay.kr(envs, 0.1));
	});
	car = car.sum * 1/num;

	Out.ar(\outbus.kr(0), (car*\amp.kr(1)));
}).add;
)



