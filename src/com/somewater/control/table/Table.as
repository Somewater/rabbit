package com.somewater.control.table
{
	import com.somewater.control.IClear;
	import com.somewater.display.CorrectSizeDefinerSprite;
	import com.progrestar.storage.Const;
	import com.somewater.text.TruncatedTextField;
	
	import fl.containers.ScrollPane;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class Table extends Sprite implements IClear
	{
		public var WIDTH:int;
		public var ROW_HEIGHT:int;
		
		public var header:Array;// массив названия для столбцов (сколько элементов в нем, стольпо потом будет столбцов таблицы, независимо от data)
		public var headerColor:int;
		public var headerLineColor:int;
		public var headerHeight:int;
		public var headerWidths:Array;// массив "широт" для столбцов. Если не задан, то всё относительно пеерменной WIDTH, поровну
				
		public var renderers:Array; // каждый из рендеров применяется в ячейкам соответствующего столбца 
		//public var defaultRenderer:ICellRenderer;// (если рендеров меньше, чем данных, используется defaultRenderer)
		
		public var color:int;
		
		// хранит ссылки на все ICellRenderer, которые описывают ячейки [1][6] - 1-я строка, 6-й столбец
		public var cells:Array;
		
		private var holder:CorrectSizeDefinerSprite;// на чём собственно и будет лежать весь контент
		private var headerHolder:Sprite;// на чем будут лежатьь заголовки
		private var scroll:ScrollPane;
		
		public function clear():void{
			cells = null;
		}
		
		public function Table(data:Array = null, WIDTH:int = 480,ROW_HEIGHT:int = 20 , color:int = 0xF8A525, renderers:Array = null, header:Array = null,headerColor:int = 0xFFFFFF,headerLineColor:int = 0xC45020,headerHeight:int = 20, headerWidths:Array = null)
		{
			super();
			
			scroll = new ScrollPane();
			addChild(scroll);
			
			headerHolder = new Sprite();
			addChild(headerHolder);
			
			this.WIDTH = WIDTH;
			this.ROW_HEIGHT = ROW_HEIGHT;
			this.color = color;
			this.renderers = renderers;
			this.header = header;
			this.headerColor = headerColor;
			this.headerLineColor = headerLineColor;
			this.headerHeight = headerHeight;
			this.headerWidths = headerWidths;
			
			holder = new CorrectSizeDefinerSprite(0,3);// на 3 пиксела больше. чтоб отображаласб нижняя граница таблицы
			scroll.source = holder;
			
			//defaultRenderer = new TextField();
			
			if (data != null)
				this.data = data;
		}
		
		public function setSize(w:Number, h:Number):void{
			scroll.setSize(w, h - scroll.y);			
		}
		
		// тип данных _data  - двумерный массив, первый массив содержит строки, внутренние массивы - элементы ячеек в пределах строки
		private var _data:Array;
		public function set data(value:Array):void{
			_data = value;
			generate();
		}
		public function get data():Array{
			return _data;
		}
		
		public function resize():void{
			generate();
			scroll.update();
		}
		
		/**
		 * Создать таблицу.
		 * К моменту вызова данной функции уже должны быть установлены все свойства
		 */
		private function generate():void{
			Const.flushHolder(holder);
			Const.flushHolder(headerHolder);
			holder.graphics.clear();
			cells = [];
			
			var i:int,j:int;
			var colNumber:int = (header != null?header.length: _data[0].length);
			//if ((headerHeight*(header == null?0:1) + data.length*ROW_HEIGHT) > height) WIDTH = width - 26;// уменьшение ширины на таблицу за счёт появления скролла
			// массив ширин столбцов
			var col:Array = [];
			if (headerWidths != null){
				col = headerWidths;
				// если в массиве headerWidth элементов меньше, чем данных в data или header
				if (col.length < colNumber)
					for (i=col.length;i<colNumber;i++)
						col[i] = WIDTH/colNumber;
				// пересчитываем WIDTH
				WIDTH = 0;		
				for (i=0;i<col.length;i++)
					WIDTH += col[i];
			}				
			else
				for (i=0;i<colNumber;i++)
					col[i] = WIDTH/colNumber;	
			
			
			var nextX:int = 0;
			var nextY:int = 0;
			scroll.y = 0;
			
			// создать заголовок таблицы. если нужно
			if (header != null){
				for (i=0;i<header.length;i++){
					var label:TruncatedTextField = new TruncatedTextField(null,headerColor,10);
					label.height = headerHeight; 
					label.text = header[i];
					label.y = (headerHeight - label.textHeight) * 0.5;
					label.x = nextX + (col[i] - label.textWidth) * 0.5;
					nextX += col[i];
					headerHolder.addChild(label);
				}
				scroll.y = headerHeight;
			}
			
			var topLineY:int = nextY;
			// нарисовать самую верхнюю черту
			if (holder != null) 
				headerHolder.graphics.lineStyle(1,headerLineColor);
			headerHolder.graphics.moveTo(0,headerHeight);
			headerHolder.graphics.lineTo(WIDTH,headerHeight);	
			holder.graphics.lineStyle(1,color);// переставляем на стиль основногго контента
			
			// ссоздать контент таблицы	
			for (i = 0;i<data.length;i++){// цикл пробега по всем строкам
				// создаем строку
				nextX = 0;	
				cells.push([]);
				var maxCellHeight:Number = ROW_HEIGHT;
				for (j=0;j<colNumber;j++){// цикл пробега по всем столбцам
					var bufClass:Class = (renderers != null?((j<renderers.length)?(renderers[j] != null?renderers[j]:TextFieldCellRenderer): TextFieldCellRenderer):TextFieldCellRenderer);
					var render:ICellRenderer = new bufClass();
					render.width = col[j];
					render.height = ROW_HEIGHT;					
					render.x = nextX;
					render.y = nextY;					
					holder.addChild(render as DisplayObject);
					render.data = data[i][j];
					
					nextX += col[j];
					/*if (j != (colNumber-1)){// если не последняя ячейка, рисуем черту
						holder.graphics.moveTo(nextX,nextY);
						holder.graphics.lineTo(nextX,nextY + ROW_HEIGHT);
					}*/
					cells[i].push(render);
					if (maxCellHeight < render.height) 
						maxCellHeight = render.height;
				}
				// нарисуем вертикальные черточки
				nextX = 0;
				for (j=0;j<(colNumber - 1);j++){
					nextX += col[j];
					holder.graphics.moveTo(nextX,nextY);
					holder.graphics.lineTo(nextX,nextY + maxCellHeight);
				}				
				nextY += maxCellHeight;
				holder.graphics.moveTo(0,nextY);
				holder.graphics.lineTo(WIDTH,nextY);
			}
			
			scroll.setSize(WIDTH + 24,scroll.height);
			scroll.update();
			
		}
	}
}