(
//////////global//////////
(~bpm.isNil).if{~bpm = 120};
(~step.isNil).if{~step = 64};
(~bar.isNil).if{~bar = 4};
~blockSize = ~step*~bar;
~counter = 0;

~seq = {
	//////////variables//////////
	arg con;
	//sizes
	var w=512, h=100, m=10, y=m*2;
	//container
	var win;
	//blocksize
	var n=~blockSize;

	//////////create window//////////
	win = Window("Sequencer",Rect(0, 0, //x,y
		w+(m*2), con.size*h+(m*6))); //w,h
	win.background = Color.rand;

	//////////draw playhead//////////
	~phead = UserView(win,Rect(0, 0, win.bounds.width, m*2));
	~phead.drawFunc = {
		var len = m/2;
		var spos = ((win.bounds.width-(m*2))/n)*(~counter%n) + m;
		// triangle
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
			//display titles
			StaticText(win,Rect(m*2, y-(m/2), w, h/2))
			.string_(item[\name])
			.font_(Font("ProFont for Powerline", 28))
			.stringColor = c.alpha = 0.6;
			//draw div line
			(item[\div].notNil).if{
				var num = item[\div];
				num.do({ |i|
					var view = CompositeView(win,
						Rect(m, (h*(i+1)/(num+1)+y), w, 1));
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
			//draw frame
			var frame = UserView(win, Rect(m, y, w, th))
			.background_(Color(1,1,1,0.2));
			//display titles
			StaticText(win,Rect(m*2, y-(m/2), w, h/2))
			.string_(item[\name])
			.font_(Font("ProFont for Powerline", 28))
			.stringColor = c;
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

//////////global counter//////////
(~cBus.isNil).if{~cBus = Bus.control(s, 1)};
SynthDef(\counter,{
	var trig = Impulse.kr((~bpm/60)*~step);
	var count = Stepper.kr(trig, 0, 0, ~blockSize-1);
	Out.kr(~cBus, count);
}).add;

//////////playhead//////////
~routine = Routine({ arg appClockTime;
    loop({
		~cBus.get({|v| ~counter = v.value});
        ~phead.doAction;
		~bufUpdate.value;
        0.1.wait;
    })
});

//////////make block array//////////
(~block.isNil).if{~block = Dictionary()};

//////////make new parameter//////////
~param = { arg
	//////////set param//////////
	name = \name_size,
	type = \s, // \s(slider) or \t(trig)
	bar = 4,  //bar size
	//////////optional//////////
	div = 0,
	min = 0.0,
	max = 1.0,
	array = Array.fill(~step*bar, {0});

	//////////make dict//////////
	var block;
	block = Dictionary.with(*[
		\name -> name,
		\type -> type,
		\bar -> bar,
		\div -> div,
		\min -> min,
		\max -> max,
		\array -> array,
		\buf -> Buffer.alloc(s, ~step*bar)
	]);

	//////////add to block array
	~block.put(name, block);
};

//////////buffer update while running//////////
~bufUpdate = {
	~setBlock.do({ |item|
		item[\buf].setn(0, item[\array]);
	});
};

//////////buffer update once//////////
~bufUpdate1 = { |item|
	item[\buf].setn(0, item[\array]);
};

//////////export array to csv//////////
~save = { |block|
	block.keys.do({ |item|
		//file setteings
		var filename = ~block[item][\name];
		var path = PathName(thisProcess.nowExecutingPath).parentPath +/+ "data";
		var file = File(path +/+ filename ++ ".sc", "w");

		//write params
		file.write(filename ++ "\n"); //title
		file.write(block[item][\type] ++ "\n"); //type
		file.write(block[item][\bar].asString ++ "\n"); //bar
		file.write(block[item][\div].asString ++ "\n"); //div
		file.write(block[item][\min].asString ++ "\n"); //min
		file.write(block[item][\max].asString ++ "\n"); //max
		//array
		block[item][\array].do({|n, i|
			file.write(n.asString);
			(i < (block[item][\array].size-1)).if{
				file.write(",");
			};
		});
		file.write("\n");

		//file close
		file.close;
	});
};

)
