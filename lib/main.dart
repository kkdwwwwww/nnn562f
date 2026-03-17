import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'MoveGo'),
    );
  }
}

class CoreLogic {
  static final CoreLogic _instance = CoreLogic._internal();

  factory CoreLogic() => _instance;

  CoreLogic._internal();

  static const plat = MethodChannel("wasd");
  List<int> steps = List.filled(2, 0);
  List<double> week = List.filled(7, 0);
  List<double> month = List.filled(12, 0);
  String lastDate = "";
  Function? _onUpdate;

  void init(Function onUpdate) {
    _onUpdate = onUpdate;
    load().then((data) {
      if (data.containsKey('steps')) {
        steps = List<int>.from(data['steps']);
        lastDate = data['date'];
        week = List<double>.from(data['week']);
        month = List<double>.from(data['month']);
        checkDate();
        _onUpdate?.call();
      } else {
        lastDate = DateTime.now().toString().split(' ')[0];
        save();
      }
    });
    plat.setMethodCallHandler((handler) async {
      if (handler.method == "onsss") {
        checkDate();
        steps.last++;
        week.last++;
        month.last++;
        save();
        printAll();
        _onUpdate?.call();
      }
    });
  }

  Future<void> save() async {
    if (lastDate == "") lastDate = DateTime.now().toString().split(' ')[0];
    String js = jsonEncode({
      'steps': steps,
      'date': lastDate,
      'week': week,
      'month': month,
    });
    await plat.invokeMethod("save", {"json": js});
  }

  Future<Map<String, dynamic>> load() async {
    String? js = await plat.invokeMethod("load");
    if (js == null || js.isEmpty) return {};
    return jsonDecode(js);
  }

  void checkDate() {
    String todayStr = DateTime.now().toString().split(' ')[0];
    if (lastDate == "" || lastDate == todayStr) return;
    DateTime last = DateTime.parse(lastDate);
    DateTime today = DateTime.parse(todayStr);
    int dayoff = today.difference(last).inDays;
    if (dayoff > 0) {
      for (int i = 0; i < dayoff; i++) {
        week.removeAt(0);
        week.add(0);
      }
      steps.first += steps.last;
      steps.last = 0;
    }
    if (today.year != last.year || today.month != last.month) {
      int monOff = (today.year - last.year) * 12 + (today.month - last.month);
      for (int i = 0; i < monOff; i++) {
        month.removeAt(0);
        month.add(0);
      }
    }
    lastDate = todayStr;
    save();
  }

  void printAll() {
    print(steps);
    print(lastDate);
    print(week);
    print(month);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final core = CoreLogic();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    core.init(() =>
      setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    double program = core.steps.last / 10000;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(
        children: [
          SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: CircularProgressIndicator(
                  value: program > 1 ? 1.0 : program,
                  strokeCap: StrokeCap.round,
                  strokeWidth: 15,
                  backgroundColor: Colors.grey,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${core.steps.last}",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "步 數",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      "目標：10,000 步",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "行走距離",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "${(core.steps.last / 2).toInt()} m",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 20),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "消耗熱量",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        core.steps.last * 0.03 >= 1
                            ? "${(core.steps.last * 0.03).toInt()} kcal"
                            : "${core.steps.last * 30} cal",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: "設定今日步數",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    int? w = int.tryParse(_controller.text);
                    if (w != null) {
                      core.month.last += w - core.steps.last;
                      core.steps.last = w;
                      core.week.last = w.toDouble();
                      _controller.clear();
                      core.save();
                      core.printAll();
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: Text("設定"),
                ),
              ],
            ),
          ),
          SizedBox(height: 20,),
          Padding(padding: EdgeInsets.all(20),child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (builder)=>WP()));}, icon: Icon(Icons.bar_chart,size: 50,)),
              SizedBox(width: 10,),
              IconButton(onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (builder)=>PP())).then((_)=>core.init(()=>setState(() {})));}, icon: Icon(Icons.emoji_events,size: 50,))
            ],
          ),)
        ],
      ),
    );
  }
}

class WP extends StatefulWidget {
  const WP({super.key});

  @override
  State<WP> createState() => _WPState();
}

class _WPState extends State<WP> with SingleTickerProviderStateMixin {
  final core = CoreLogic();
  late AnimationController _controller;
  bool _isWeek = true;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this,duration: Duration(seconds: 1));
    _controller.forward();
  }
  void _toggleView(bool inWeek){
    setState(() {
      _isWeek = inWeek;
    });
    _controller.reset();
    _controller.forward();
  }
  @override
  Widget build(BuildContext context) {
    List<String> labels;
    DateTime now = DateTime.now();
    if(_isWeek){
      labels = List.generate(7, (i){
        DateTime d = now.subtract(Duration(days: 6 - i));
        return "${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}";
      });
    }else{
      labels = List.generate(12, (i){
        int d = now.month - (11-i);
        while(d<=0) d += 12;
        return "$d月";
      });
    }
    final List<double>data = _isWeek ? core.week : core.month;
    return Scaffold(
      appBar: AppBar(title: Text("紀錄頁面"),leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back)),),
      body: ListView(children: [
        Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center,children: [
            ChoiceChip(label: Text("最近7天"), selected: _isWeek,onSelected: (_) => _toggleView(true),),
            SizedBox(width: 20,),
            ChoiceChip(label: Text("最近12月"), selected: !_isWeek,onSelected: (_) => _toggleView(false),),
          ],),
          SizedBox(height: 50,),
          SizedBox(height: 200,width: 300,child: AnimatedBuilder(animation: _controller, builder: (context, _) => CustomPaint(size: Size(MediaQuery.of(context).size.width, 300),painter: LineCharPainter(data,_controller.value,labels),)),),
          SizedBox(height: 20,),
          Row(mainAxisAlignment: MainAxisAlignment.center,children: [
            Card(child: Padding(padding: EdgeInsets.all(20),child: Column(children: [
              Text(" 總 步 數 ",style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),),
              SizedBox(height: 20,),
              Text("${core.steps.first+core.steps.last} 步",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
            ],),),),
            Card(child: Padding(padding: EdgeInsets.all(20),child: Column(children: [
              Text(" 總 距 離 ",style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),),
              SizedBox(height: 20,),
              Text(core.steps.first+core.steps.last/500 >10 ? "${(core.steps.first+core.steps.last/500).toInt()} 公里" : "${(core.steps.first+core.steps.last/2).toInt()} 公尺" ,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
            ],),),),
          ],),
          Row(mainAxisAlignment: MainAxisAlignment.center,children: [
            Card(child: Padding(padding: EdgeInsets.all(20),child: Column(children: [
              Text("平均步數",style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),),
              SizedBox(height: 20,),
              Text(_isWeek ? "${(core.week.reduce((a,b)=> a+b) / 7).toStringAsFixed(2)} 步" : "${(core.month.reduce((a,b)=> a+b) / 12).toStringAsFixed(2)} 步",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
            ],),),),
            Card(child: Padding(padding: EdgeInsets.all(20),child: Column(children: [
              Text("消耗熱量",style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),),
              SizedBox(height: 20,),
              Text(core.steps.first+core.steps.last*0.03 > 10 ? "${(core.steps.first+core.steps.last*0.03).toInt()} kcal" : "${(core.steps.first+core.steps.last*30).toInt()} cal" ,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
            ],),),),
          ],)
        ],)
      ],),
    );
  }
}
class LineCharPainter extends CustomPainter {
  final List<double> data;
  final double p;
  final List<String> labels;
  LineCharPainter(this.data,this.p,this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    if(data.isEmpty) return;
    final double pb = 40;
    final double pt = 20;
    final double ch = size.height - pb - pt;
    final paint = Paint()..color=Colors.blue..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=3;
    final dotp = Paint()..color=Colors.white..style=PaintingStyle.fill;
    final dot = Paint()..strokeWidth=2..style=PaintingStyle.stroke;
    final gp = Paint()..color=Colors.grey..strokeWidth=1;
    final path = Path();
    double maxV = data.reduce(max);
    if(maxV==0)maxV = 5;
    double dx = size.width/(data.length-1);
    List<Offset> points = [];
    for(int i =0;i<=4;i++){
      double y = pt + (ch * (1-i/4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
      _drawText(canvas,"${(maxV*i/4).toInt()}",Offset(-20, y),color: Colors.grey);
    }
    for(int i=0;i<data.length;i++){
      double x = i*dx;
      double y = pt + ch - (data[i] * p / maxV * ch);
      Offset cp = Offset(x, y);
      points.add(cp);
      if(i==0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
    for(int i =0;i<points.length;i++){
      var p = points[i];
      canvas.drawCircle(p, 4, dotp);
      canvas.drawCircle(p, 4, dot);
      _drawText(canvas, labels[i], Offset(points[i].dx, size.height),fontSize: 10,color: Colors.grey);
    }
  }
  @override
  bool shouldRepaint(LineCharPainter oldDelegate) => oldDelegate.p != p || oldDelegate.data != data;

  void _drawText(Canvas canvas, String s, Offset center, {double fontSize = 10,Color color = Colors.black}) {
    final tp = TextPainter(
      text: TextSpan(text: s,style: TextStyle(color: color,fontSize: fontSize,fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr
    )..layout();
    tp.paint(canvas, Offset(center.dx -tp.width / 2, center.dy -tp.height/2));
  }
}


class PP extends StatefulWidget {
  const PP({super.key});

  @override
  State<PP> createState() => _PPState();
}

class _PPState extends State<PP> {
  final core = CoreLogic();
  @override
  void initState() {
    super.initState();
    core.init((){if(mounted)setState(() {
    });});
  }
  @override
  Widget build(BuildContext context) {
    bool inUnlock = core.steps.last >= 10000;
    bool inUnlock2 = core.steps.last+core.steps.first >= 1000000;
    return Scaffold(
      appBar: AppBar(title: Text("勳章頁面"),leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back)),),
      body: ListView(
        children: [
          Padding(padding: EdgeInsets.all(20),child: Column(
            children: [
              MW(inUnlock: inUnlock, title: inUnlock ? "解鎖(每日)" : "${core.steps.last}/10,000(每日)"),
              SizedBox(height: 50,),
              MW(inUnlock: inUnlock2, title: inUnlock2 ? "解鎖(永久)" : "${core.steps.last+core.steps.first}/1,000,000(永久)"),
            ],
          ),)
        ],
      ),
    );
  }
}

class MW extends StatefulWidget {
  final bool inUnlock;
  final String title;

  const MW({super.key, required this.inUnlock, required this.title});

  @override
  State<MW> createState() => _MWState();
}

class _MWState extends State<MW> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _Bcontroller;
  double a = 0.0;
  double b = 0.0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          lowerBound: double.negativeInfinity,
          upperBound: double.infinity,
        )..addListener(() {
          setState(() {
            a = _controller.value;
          });
        });
    _Bcontroller =
        AnimationController(
          vsync: this,
          lowerBound: double.negativeInfinity,
          upperBound: double.infinity,
        )..addListener(() {
          setState(() {
            b = _Bcontroller.value;
          });
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _Bcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.title),
        SizedBox(height: 50),
        GestureDetector(
          onPanUpdate: (d) {
            _controller.stop();
            _Bcontroller.stop();
            setState(() {
              a += d.delta.dx * 0.02;
              b += d.delta.dy * 0.02;
            });
          },
          onPanEnd: (d) {
            double va = d.velocity.pixelsPerSecond.dx / 1000;
            double vb = d.velocity.pixelsPerSecond.dy / 1000;
            Future fx = _controller.animateWith(
              FrictionSimulation(0.15, a, va),
            );
            Future fy = _Bcontroller.animateWith(
              FrictionSimulation(0.15, b, vb),
            );
            Future.wait([fx, fy]).then((_) {
              if (!mounted) return;
              double ta = (a / pi).round() * pi;
              double tb = (a / (2 * pi)).round() * (2 * pi);
              final sp = SpringDescription(
                mass: 1,
                stiffness: 120,
                damping: 15,
              );
              _controller.animateWith(SpringSimulation(sp, a, ta, 0));
              _Bcontroller.animateWith(SpringSimulation(sp, b, tb, 0));
            });
          },
          child: Transform(transform: Matrix4.identity()..rotateX(b)..rotateY(-a),alignment: Alignment.center,child: bM(widget.inUnlock),),
        ),
      ],
    );
  }

  Widget? bM(bool inUnlock) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape:BoxShape.circle,
        gradient:LinearGradient(colors: inUnlock ? [Colors.amber,Colors.orangeAccent,Colors.yellow] : [Colors.grey,Colors.blueGrey,Colors.grey.shade400],begin: Alignment.topLeft,end: Alignment.bottomRight),
        boxShadow:[BoxShadow(color:Colors.black45,blurRadius: 20,spreadRadius: 5)],
        border:Border.all(color: Colors.white,width: 5)
      ),
      child: Icon(inUnlock ? Icons.emoji_events : Icons.lock,size: 100,color: Colors.white,),
    );
  }
}
