package com.somewater.controller
{
	import com.somewater.text.EmbededTextField;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	
	/**
	 * Своими методами обеспечивает выравнивание заданных компонентов по заданным законам
	 * (при помощи переопределения их координат x, y (и, возможно, width, height))
	 */
	public class LocationManager extends EventDispatcher implements IController
	{
		public function LocationManager()
		{
			init();
		}

		public function init():void
		{
		}
		
		public static function returnInstance():LocationManager{
			return new LocationManager();
		}
		
		/**
		 * 
		 * @param controls - вложенный массив контролов [ [строка1], [строка2], ... ]
		 * @param rules - правила размещения (массив, длиной равный длине самой большой строки)
		 * 		int - ширина, которая дается компоненту (выравнивание по левому краю)
		 * 		{} - объект, содержащий командные параметры выравнивания
		 * 				w:int - ширина под компонент
		 * 				forceW:int - аналогично w, также присвоить компоненту данную ширину
		 * 				forceH:int - присвоить компоненту данную высоту
		 * 				align:String <["left"], "center","right", "l","c","r"> - выравнивание по ширине
		 * 				valign:String <["top"], "middle", "bottom","t","m","b"> - выравнивание по высоте
		 * @param pad - отсутпы по ширине меж компонентами
		 * @param vpad - отступы по высоте меж компонентами
		 * @param commands:Object - содержит дополнительные команды. ищзменяющие стандартное поведение
		 * 			nextX - отсутп по x
		 * 			nextY - отсутп по y
		 * 			initX - начальное значение x (необходимо, если компонент не новый и уже имеет ненулевые координаты)
		 * 			initY - начальное значение по y
		 * 
		 //* @param width - сколько форма может занять ширины
		 //* @param height - сколько форма может занять высоты
		 * 
		 */
		public function form(controls:Array,rules:Array, pad:int = 0, vpad:int = 30, commands:Object = null):Rectangle{
			var i:int; // итератор строк
			var j:int; // итератор компонентов в пределах строки
			if (commands == null) 
				commands = {nextX:0, nextY:0};
			else{
				if (commands.nextX == null) commands.nextX = 0;
				if (commands.nextY == null) commands.nextY = 0;
			}
			var nextY:int = commands.nextY;
			var nextX:int;
			var rect:Rectangle = new Rectangle(commands.nextX,commands.nextY);
			for (i = 0;i<controls.length;i++){
				var row:Array = controls[i];
				if (rect.width<(nextX - pad)) rect.width = nextX - pad;
				nextX = commands.nextX;
				for (j = 0;j<row.length;j++){
					var rule:Object;
					if (rules[j] != null)
						if (rules[j] is Number)
							rule.w = rules[j];
						else
							if (rules[j] is Function)
								throw new Error("Wrong rule for Function rule type");
							else
								rule = rules[j];
					else
						rule = {w:100};
					
					if (row[j] == null){
						nextX += pad + rule.w;
						continue;
					}
					
					var obj:DisplayObject;
					if (row[j] is DisplayObject){ 
						obj = row[j];
						if (rule.initX != null)
							obj.x = rule.initX;
						if (rule.initY != null)
							obj.y = rule.initY;
					}
					if (row[j] is String){
						if (row[j] == "star"){
							obj = new EmbededTextField(null,"r",11,false,true,false,false,"left",true);
							rule.align = "left";
							obj.y = -2;
							EmbededTextField(obj).text = "*";
						}else{
							var title:EmbededTextField = new EmbededTextField(null,"b",11,false,true,false,false,"right",true);
							title.wordWrap = true;
							title.text = row[j];
							//title.autoSize = TextFieldAutoSize.NONE;
							rule.align = "right";
							obj = title;
						}
						row[j] = obj;						
					}

					
						
					if (rule.forceW != null){
						obj.width = rule.forceW;
						if (rule.w == null)
							rule.w = rule.forceW;
					}
						
					if (rule.forceH != null)
						obj.height = rule.forceH;
					
					var w:Number = /*(obj is TextField)?TextField(obj).textWidth:*/obj.width;
					var h:Number = /*(obj is TextField)?TextField(obj).textHeight:*/obj.height;
					
					//if (w>rule.w) obj.width = rule.w;
					
					if (rule.align == null) rule.align = "left";
					
					if (rule.align == "left" || rule.align == "l")
						obj.x += nextX;
					if (rule.align == "center" || rule.align == "c")
						obj.x += nextX + (rule.w - w) * 0.5;
					if (rule.align == "right" || rule.align == "r")
						obj.x += nextX + (rule.w - w);
					
					if (rule.valign != null){
						if (rule.h == null)
							rule.h = vpad;
						if (rule.valign == "top" || rule.valign == "t")
							obj.y += nextY;
						if (rule.valign == "middle" || rule.valign == "m")
							obj.y += nextY + (rule.h - h) * 0.5;
						if (rule.valign == "bottom" || rule.valign == "b")
							obj.y += nextY + (rule.h - h);
					}
					else
						obj.y += nextY;
					
					nextX += rule.w + pad;
				}
				nextY += vpad;
			}	
			rect.height = nextY;
			return rect;			
		}
		
		public static function form(controls:Array,rules:Array, pad:int = 0, vpad:int = 30, commands:Object = null):Rectangle{
			return returnInstance().form(controls,rules,pad,vpad,commands);
		}
		
		/**
		 * Добавляет на указанный holder детей из массива list
		 * list может быть многомерным массивом
		 */
		public function addChildsList(list:Array,holder:DisplayObjectContainer):void{
			for (var i:int = 0;i<list.length;i++)
				if (list[i] is Array)
					addChildsList(list[i],holder);
				else{
					if (list[i] != null){
						trace("child "+String(list[i])+ " text=" + " x="+list[i].x + " w="+list[i].width)
						holder.addChild(list[i]);	
					}					
				}
		}
		
		public static function addChildsList(list:Array,holder:DisplayObjectContainer):void{
			returnInstance().addChildsList(list,holder);;
		}
		
		/**
		 * центрировать все введенные элементы относительно вертикальной оси
		 */
		public function centre(controls:Array,rules:Array = null, pad:int = 0, vpad:int = 30, commands:Object = null):Rectangle{
			var i:int; // итератор строк
			var j:int; // итератор компонентов в пределах строки
			if (commands == null) 
				commands = {nextX:0, nextY:0};
			else{
				if (commands.nextX == null) commands.nextX = 0;
				if (commands.nextY == null) commands.nextY = 0;
			}
			var nextY:int = commands.nextY;
			var nextX:int;
			var sumWidth:int;
			var rect:Rectangle = new Rectangle(commands.nextX,commands.nextY);
			for (i = 0;i<controls.length;i++)
			{
				var row:Array = controls[i];
				nextX = commands.nextX;
				// считаем общую ширину компонетнов
				sumWidth = 0;
				for (j = 0;j<row.length;j++)
					sumWidth += row[j].width;
				nextX -= ((j-1)*pad +  sumWidth) * 0.5;
				for (j = 0;j<row.length;j++)
				{
					row[j].x += nextX;
					row[j].y += nextY;
					nextX += row[j].width + pad;
				}
				if (rect.width<(nextX - pad)) rect.width = (nextX - pad);
				nextY += vpad;
			}
			rect.height = nextY;
			return rect;
		}
		
		public static function centre(controls:Array,rules:Array = null, pad:int = 0, vpad:int = 30, commands:Object = null):Rectangle{
			return returnInstance().centre(controls,rules, pad, vpad, commands);
		}
	}
}