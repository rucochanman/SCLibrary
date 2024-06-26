(
~step = 32;
f = {
//////////variables//////////
arg con;

//num of step
var block=4, n=~step*block;

//sizes
var w=512, h=100, m=10, y=m*2; //slider w/h, margin, y startpos

//container
var win;

//global variables
~counter=0; //global counter
~phead; //playhead

//////////create window//////////
win = Window("Sequencer",Rect(100, Window.screenBounds.height-550,//x,y
    w+(m*2), con.size*h+(m*6)));//w,h
win.background = Color.rand;

//////////draw playhead//////////
~phead = UserView(win,Rect(0,0,win.bounds.width,m*2));
~phead.drawFunc = {
    var len = m/2;
    var spos = ((win.bounds.width-(m*2))/n)*(~counter%n) + m;
    // Draw the triangle
    Pen.fillColor = Color.yellow;
    Pen.moveTo(spos @ (m*2));
    Pen.lineTo((spos-len) @ m);
    Pen.lineTo((spos+len) @ m);
    Pen.lineTo(spos @ (m*2));
    Pen.fill;
    // Draw the frame
    Pen.strokeColor = Color.black;
    Pen.moveTo(spos @ ((m*2)+1));
    Pen.lineTo(((spos-len)-1) @ (m-1));
    Pen.lineTo(((spos+len)+1) @ (m-1));
    Pen.lineTo(spos @ ((m*2)+1));
    Pen.stroke;
};
~phead.action = {~phead.refresh};


//////////Create contents//////////
con.do({|item, i|
    ///////slider///////
    (item[\type]==\s).if{
        var bar;
        var c = Color.rand(0.35);
        //create slider
        bar = MultiSliderView(win, Rect(m, y, w, h))
            .thumbSize_(w/n/2).drawLines_(true)
            .elasticMode_(true).showIndex_(true)
            .colors_(c, c).background_(Color.black);
        //set value
        bar.value=item[\array].linlin(item[\min],item[\max],0,1);
        //set action
        bar.action = { arg q;
            var m = ControlSpec(item[\min], item[\max], \lin);
            item[\array] = m.map(q.value); //配列に値セット
        };
        //display titles (layer0)
        StaticText(win,Rect(m*2, y-(m/2), w, h/2))
        .string_(item[\title])
        .font_(Font("ProFont for Powerline", 28))
        .stringColor = c.alpha = 0.6;
        //draw div line
        (item[\div].notNil).if{
            var num = item[\div];
            num.do({ |i|
                var view = CompositeView(win,Rect(
                    m, (h*(i+1)/(num+1)+y), w, 1));
                view.background = Color(1,1,1,0.7);
            });
        };
        //update y coord
        y = y + h + (m/2);
    };
    ///////trigger///////
    (item[\type]==\t).if{
        var th = h/2; // trigger height
        var trig;
        var zpos = nil;
        //display titles (layer1)
        StaticText(win,Rect(m*2, y-(m/2), w, h/2))
        .string_(item[\title])
        .font_(Font("ProFont for Powerline", 28))
        .stringColor = c.alpha = 0.6;
        //create trigs
        trig = UserView(win, Rect(m, y, w, th))
        .background_(Color.clear);
        //set action
        trig.drawFunc = {
            //color setting
            Pen.strokeColor = Color.black;
            Pen.fillColor = Color(1,1,0,0.5);
            //move
            item[\array].do({ |bool, i|
                (bool==1).if{
                    var barw = w/~step; //bound.width/step
                    Pen.addRect(Rect(i*(w/n), 0, //x,y
                    barw-1, trig.bounds.height-1)); //w,h
						Pen.fill;
						Pen.addRect(Rect(i*(w/n), 0, //x,y
							barw, trig.bounds.height)); //w,h
						Pen.stroke;
					};
				});
			};
			trig.action = {trig.refresh};
			//mouse actions
			trig.mouseDownAction = { |view, x|
				var val = x.linlin(0,w,0,1);
				n.do({|i|
					( (val<=((i+1)/n)) && (val>=(i/n)) ).if{
						zpos=i;
						item[\array][i]=1;
					};
				});
				trig.doAction;
   };
    //trigを動かす
    trig.mouseMoveAction =  { |view, x|
        var val = x.linlin(0,w,0,1);
				n.do({|i|
					( (val<=((i+1)/n)) && (val>=(i/n)) ).if{
						item[\array][zpos]=0;
						item[\array][i]=1;
						zpos = i;
					};
				});
				trig.doAction;
			};
			//update y coord
			y = y + th + (m/2);
		};
	});

//////////draw//////////
	win.front;
};
)

//////////実行//////////
f.value(~seqArg);


//////////パラメータ配列を作る//////////
//title, type(\t or \s), div, array, min, max
(
~deg = Dictionary.with(*[
    \title->"degree",\type->\s, \array->Array.fill(32*4,{0}),
\div->5, \min->0, \max->6
]);
~drum = Dictionary.with(*[
    \title->"drum",\type->\t, \array->Array.fill(32*4,{0}),
])
)
~seqArg = [~drum, ~deg]


/////////////playhead//////////
~bpm = 120;
~delta = 60/~bpm/~step;

(
r = Routine({ arg appClockTime;
    loop({
		c.get({|v| n = v.value});
        ~counter = n;
        ~phead.doAction;
        0.1.wait;
    })
});
)

(
c = Bus.control(s, 1);
SynthDef(\counter,{
	Out.kr(c, \trig.kr(0));
}).add;
)

//////////execute//////////

//playhead
(
Pdef(\playhead,
	Pmono(
		\counter,
		\trig, Pseq(Array.series(~step*4),inf),
		\dur, ~delta
));
)

(
AppClock.play(r);
Ppar([Pdef(\playhead)]).play
)dd









//音鳴らしてみるテスト
(
SynthDef(\drum, {
var sn, freq, env;
freq = Line.ar(350, 10, 0.1);
sn = SinOsc.ar(freq, 0, 0.1);
env = Env([0,1,0], [0.01, 0.5]).kr(2);
Out.ar(0, (sn*env).dup);
}).add;
)

Synth(\drum)


(
var m = Scale.major;
m.degreeToFreq(1, 440, 0)
)

