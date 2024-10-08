//bufferを配列に
~path = PathName(thisProcess.nowExecutingPath).parentPath ++ "wav/";
b = Buffer.read(s, ~path ++ "***.wav");
b.loadToFloatArray(action: { arg array; ~temp = array; "done".postln });

//100frameずつに区分け
~size = 100;
~temp1 = Array.newFrom(~temp[386000..800000]); //処理落ちするのでサイズダウン
~temp1 = ~temp1.clump(~size);

//5の倍数でindexを組み換える
(
~temp2 = [];
~temp1.size.do({|i|
    ~temp2 = ~temp2.add(~temp1.wrapAt(i*5));
});
)
//またはランダムにする
~temp2 = ~temp1.scramble;

//ノイズ軽減env処理
~temp3 = ~temp2 * (Array.interpolation(~size/2, 0.0, 1.0) ++ Array.interpolation(~size/2, 1.0, 0.0)).dup(~temp2.size);
~temp3 = ~temp3.stutter(2);
~temp3 = ~temp3.flatten;

//配列をバッファに格納
(
c.free;
c = Buffer.loadCollection(s, ~temp3);
)

//再生
(
SynthDef(\array,{
var sn;
sn = PlayBuf.ar(1, c, \rate.kr(1), doneAction:2) * \gain.kr(1);
sn = LPF.ar(sn, \lfreq.kr(4000));
sn = sn.clip(-1.0, 1.0);
Out.ar(0, sn.dup * \amp.kr(0.1));
}).add;
)