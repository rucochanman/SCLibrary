b = Buffer.alloc( s, 512, 1 );
b.free
(
{
	var in, karnel, trig, convTrig, out;
	in = LPF.ar( Dust2.ar( 100 ), 1000 );
	karnel = Saw.ar( 300, 0.3 );
	trig = Impulse.kr( 1 );
	RecordBuf.ar( karnel, b, loop: 0 , trigger: trig );
	convTrig = TDelay.kr( trig, BufDur.ir( b ));
	//convTrigs = PulseDivider.kr( convTrig, 2, [ 1, 0 ]);
	out = Convolution2.ar(in, b.bufnum, convTrig, 512, 0.5 );
}.play
)

(
{
	var in, karnel, trig, convTrig, out;
	trig = Impulse.kr( 1 );
	in = LPF.ar( Dust2.ar( 100 ), 1000 );
	karnel = RLPF.ar( WhiteNoise.ar, 4000 - Sweep.kr( trig, 3500 ) );
	RecordBuf.ar( karnel, b, loop: 0 , trigger: trig );
	convTrig = TDelay.kr( trig, BufDur.ir( b ) );
	//convTrigs = PulseDivider.kr( convTrig, 2, [ 1, 0 ]);
	out = Convolution2.ar(in, b.bufnum, convTrig, 512, 0.5 );
}.play
)



//dust+allpass
(
{
    var input, delay;
	input = LPF.ar( Dust2.ar( 100 ), 1000, 3 );
	//5.do({ input = AllpassL.ar( input, delaytime: 0.1.rand ) });
	delay = input;
	5.do( { delay = AllpassL.ar( delay, delaytime: 0.1.rand, mul: 1.1 ) } );
	[input, delay]
}.play
)



b = Buffer.alloc( s, 2048*4, 1 );
b.free


(
{
	var input, karnel, convTrig;
	input = Impulse.ar( 1 );
	karnel = Saw.ar( 880, 0.7 );
	Convolution.ar( input, karnel, 2048, 0.5 );
}.play
)


(
{
	var input, karnel, convTrig;
	input = Impulse.ar( 1 );
	Convolution2.ar( input, b, 0, 2048, 2 );
}.play
)

//partconv

(
	var bufsize;
    ~fftsize = 2048;
    b = Buffer.read(s, "/Users/ruco/Downloads/REX50_ReverseGate L.wav".standardizePath);
    bufsize = PartConv.calcBufSize( ~fftsize, b );
	~irspectrum = Buffer.alloc( s, bufsize, 1 ) ;
	~irspectrum.preparePartConv( b, ~fftsize );
    b.free;
)

(
{
	var input;
	input = LPF.ar( Dust.ar( 100 ), 1000 );
	PartConv.ar( input, ~fftsize, ~irspectrum.bufnum, 0.5 )
}.play
)




