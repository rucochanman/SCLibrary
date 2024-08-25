(
var win, uv, zpoint, menu, bttn, m=10, w=513, h=300;
var py = [-0.8, 0, 0.8];
var px = [0, 256, 513];
var t = [1];
~attk; ~rel; ~hiFreq; ~loFreq; ~dur;
e = Env(py, t, \sin).asSignal(513).asArray;
win = Window("shape", Rect(50,50,w+(m*2),h+(m*2)+50))
    .background_(Color.black);

//////////menu//////////
menu = UserView(win, Rect(0,0,w+(m*2),50))
    .background_(Color.white);
//attack
StaticText(menu,Rect(15,5,50,10)).string_("attack");
~attk = TextField(menu, Rect(15,15,50,25));
~attk.value = 0.01;
//rel
StaticText(menu,Rect(80,5,50,10)).string_("release");
~rel = TextField(menu, Rect(80,15,50,25));
~rel.value = 1;
//hiFreq
StaticText(menu,Rect(145,5,50,10)).string_("hiFreq");
~hiFreq = TextField(menu, Rect(145,15,50,25));
~hiFreq.value = 200;
//loFreq
StaticText(menu,Rect(210,5,50,10)).string_("loFreq");
~loFreq = TextField(menu, Rect(210,15,50,25));
~loFreq.value = 20;
//dur
StaticText(menu,Rect(275,5,50,10)).string_("dur");
~dur = TextField(menu, Rect(275,15,50,25));
~dur.value = 0.1;
//buton
bttn = Button(menu, Rect(335, 15, 50, 25)).string_("syn")
    .action_{ ~exe.value };

//////////plotter//////////
uv = UserView(win, Rect(m,m+50,w,h))
    .frameRate_(10)
    .background_(Color.white)
    .mouseDownAction_{|v,x,y,m,n,d|
	    py.postln;
	    //add point
	    (d==2).if{
		    (px.size-1).do{ |i|
			    ((px[i]<x) && (x<px[i+1])).if{
				    var cp = y.linlin(0,h,1,-1);
				    py = py.insert(i+1, cp);
				    px = px.insert(i+1, x);
			    };
		    };
		    //add dur
		    t = [];
		    (px.size-1).do{ |i|
			    t = t.add((px[i+1]-px[i])/w);
		    };
	    };
	    e = Env(py, t, \sin).asSignal(513).asArray;
	    uv.refresh;
    }
    .mouseMoveAction_{ |v,x,y|
	    //move point
	    var cp = y.linlin(0,h,1,-1);
	    px.do{ |item, i|
		    ( (x<(item+10)) && (x>(item-10)) &&
			    (cp<(py[i]+10)) && (cp>(py[i]-10)) ).if{
			    var cp = y.linlin(0,h,1,-1);
			    py[i] = cp;
			    px[i] = x;
		    };
	    };
	    //remove dup
	    (px.size-1).do{ |i|
		    (px[i]==px[i+1]).if{
			    py.removeAt(i);
			    px.removeAt(i);
		    }
	    };
		//timing
		t = [];
		(px.size-1).do{ |i|
			t = t.add((px[i+1]-px[i])/w);
		};
	    e = Env(py, t, \sin).asSignal(513).asArray;
	    uv.refresh;
    }
    .drawFunc_{
	    var size = w/e.size;
	    zpoint = (0@e[0]);
	    //plot
	    e.do{ |item, index|
		    var x = size*index;
		    var y = item.linlin(-1,1,300,0);
		    var point = (x@y);
		    Pen.color = Color.black;
		    Pen.line(zpoint, point);
		    Pen.stroke;
		    zpoint = point;
	    };
	    //circle
		py.size.do{ |i|
		    var y = py[i].linlin(-1,1,300,0);
		    Pen.color = Color.red;
		    Pen.addArc(px[i]@y, 10, 0, 2pi);
		    Pen.stroke;
		};
    };
win.front;
)



(
SynthDef(\skick,{
	var in, freq, sn, env;
	env = Env.perc(\attk.kr(0.01), \rel.kr(0.5),
		1, \eCur.kr(-4)).kr(2);
	freq = Env([\fHi.kr(200), \fLo.kr(20)],
		\fDur.kr(0.1), \fCur.kr(-4)).kr;
	in = SinOsc.ar(freq, 0, \amp.kr(0.8));
    sn = Shaper.ar(b, in) * env;
	sn = LeakDC.ar(sn);
	Out.ar(0, sn.clip(-0.5, 0.5).dup);
}).add;
)


(
a = [
    { b.free; },
    { 0.1.wait; f = e.asWavetableNoWrap; },
    { 0.1.wait; b = Buffer.loadCollection(s, f); },
	{ 0.3.wait; Synth(\skick, [
		\attk, ~attk.value, \rel, ~rel.value,
		\fHi, ~hiFreq.value, \fLo, ~loFreq.value, \fDur, ~dur.value
	])}
];
)

a.fork
Synth(\skick, [\attk, ~attk.value])



(
~exe = {
r = Routine({ arg appClockTime;
	b.free;
    0.1.yield;
	f = e.asWavetableNoWrap;
	0.1.yield;
	b = Buffer.loadCollection(s, f);
	0.3.yield;
	Synth(\skick, [
		\attk, ~attk.value, \rel, ~rel.value,
		\fHi, ~hiFreq.value, \fLo, ~loFreq.value, \fDur, ~dur.value
	]);
});
AppClock.play(r);
};
)


