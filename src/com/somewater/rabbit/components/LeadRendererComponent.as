package com.somewater.rabbit.components
{
	import com.pblabs.engine.components.AnimatedComponent;
	import com.pblabs.engine.entity.IEntity;
	import com.pblabs.engine.entity.PropertyReference;
	import com.pblabs.rendering2D.DisplayObjectRenderer;
	import com.somewater.rabbit.iso.IsoRenderer;
	import com.somewater.rabbit.storage.Config;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;

	/**
	 * Рисует поводок между "улиткой" и "раковиной"
	 * в displayObject-е "раковины"
	 * 
	 * Раковина должна быть неанимированна
	 */
	public class LeadRendererComponent extends DisplayObjectRenderer
	{
		
		private var shellDisplayObjectRef:Sprite;
		private var helixDisplayObjectRef:DisplayObject;
		private var leadLength:int;// длина поводка в тайлах, берется из @Helix.leadLength
		
		/**
		 * Этот слой внедряется в displayObject "раковины"
		 * на нем происходит рисование поводка
		 */
		private var drawingLayer:Shape;
		
		/**
		 * Флаг означает, что у displayObject-а "раковины"
		 * неверный тип (например не Sprite), поэтому не стоит пытаться
		 * анимировать поводок для данного персонажа
		 */
		private var wrongShellType:Boolean = false;
		
		/**
		 * Означает, что в иерархии DisplayObject-ов поводок находится перед раковиной (перекрывает ее)
		 * Иначе поводок перекрывается раковиной
		 */
		private var bringToFront:Boolean = true;
		
		private const POINTS_NUM:int = 100;
		private var points:Array;
		private var lastCalculatedHelixX:Number = -1;
		private var lastCalculatedHelixY:Number = -1;
		
		public function LeadRendererComponent()
		{
			super();
			
			drawingLayer = new Shape();
			displayObject = drawingLayer;
		}
		
		override protected function onRemove():void
		{
			super.onRemove();
			// удалить ссылки
			shellDisplayObjectRef = null;
			helixDisplayObjectRef = null;
			wrongShellType = false;
			registerForUpdates = false;
			drawingLayer = null;
		}
		
		// для оптимизации вычисления контролькой точки кривой поводка
		private var age:int;
		private var controlX:int;
		private var controlY:int;
		private var normal:int;
		
		override public function onFrame(deltaTime:Number):void
		{	
			var shellX:int;
			var shellY:int;
			
			var helixX:int;
			var helixY:int;
			
			if (_transformDirty)
                updateTransform();
			
			if(wrongShellType)
				return;
			
			if(shellDisplayObjectRef == null)
			{
				var shellEntity:IEntity = owner.getProperty(new PropertyReference("@Helix.shell"));
				if(shellEntity)
				{
					var shellDO:DisplayObject = shellEntity.getProperty(new PropertyReference("@Render.displayObject"));
					if(shellDO && !(shellDO is Sprite))
						setWrongShellType();
					else
						shellDisplayObjectRef = shellDO as Sprite;
				}
			}else if(helixDisplayObjectRef == null)
			{
				helixDisplayObjectRef = owner.getProperty(new PropertyReference("@Render.displayObject"));
				leadLength = owner.getProperty(new PropertyReference("@Helix.leadLength"));
				
				_position.x = shellDisplayObjectRef.x;
				_position.y = shellDisplayObjectRef.y;
				_transformDirty = true;
			}else{
				
				// прорисовка поводка

				shellX = 0;//shellDisplayObjectRef.x;
				shellY = 0;//shellDisplayObjectRef.y;
				
				helixX = helixDisplayObjectRef.x - shellDisplayObjectRef.x;
				helixY = helixDisplayObjectRef.y - shellDisplayObjectRef.y;
				
				// HARDCODE для собаки
				var direction:int = IsoRenderer(owner.lookupComponentByName("Render")).direction;
				switch(direction)
				{
					case 1: helixX += 30; helixY -= 15; 	break
					case 2: helixX -= 25; helixY -= 15; break;
					case 3: helixY -= 17; break;
					case 4: helixY -= 40; break;
				}

				var dx:Number = lastCalculatedHelixX - helixX;
				var dy:Number = lastCalculatedHelixY - helixY;
				
				if(dx * dx + dy * dy > 0)
				{
					oldMethod(helixX, helixY);
					//calculatePoints(helixX, helixY);
					//renderPoints(helixX, helixY);
					
//					if(helixY > 0 && bringToFront == false)
//					{
//						shellDisplayObjectRef.setChildIndex(drawingLayer, shellDisplayObjectRef.numChildren - 1);
//						bringToFront = true;
//					}
//						
//					if(helixY < 0 && bringToFront)
//					{
//						shellDisplayObjectRef.setChildIndex(drawingLayer, 0);
//						bringToFront = false;
//					}
					
					lastCalculatedHelixX = helixX;
					lastCalculatedHelixY = helixY;
				}
			}
		}
		
		
		private function setWrongShellType():void
		{
			wrongShellType = true;
			registerForUpdates = false;
			if(drawingLayer && drawingLayer.parent)
				drawingLayer.parent.removeChild(drawingLayer);
			drawingLayer = null;
		}
		
		private function calculatePoints(helixX:int, helixY:int):void
		{
			var i:int;
			var p:Object;
			var lp:Object;// last point
			var np:Object;// next point
			var R:Number = leadLength * (Config.TILE_WIDTH + Config.TILE_HEIGHT) * 0.5 / POINTS_NUM;
			
			var x1:Number;
			var x2:Number;			
			var y1:Number;
			var y2:Number;
			
			var K:Number;
			var d2:Number;
			
			var dx1:Number;
			var dy1:Number;
			var dx2:Number;
			var dy2:Number;
			
			if(!points)
			{
				points = [];
				for(i = 0; i<POINTS_NUM; i++)
					points.push({"x":0.0, "y":0.0, "vx":0.0, "vy":0.0});
			}
			for(i = 0; i<POINTS_NUM; i++)
			{
				lp = p;
				p = points[i];
				if(i == 0)
				{
					p.x = helixX;
					p.y = helixY;
				}
				else if(i == POINTS_NUM - 1)
				{
					
				}
				else
				{
					// 	http://2000clicks.com/mathhelp/GeometryConicSectionCircleIntersection.aspx				
					//  x = (1/2)(xB+xA) + (1/2)(xB-xA)(rA2-rB2)/d2 ± 2(yB-yA)K/d2 
					//  y = (1/2)(yB+yA) + (1/2)(yB-yA)(rA2-rB2)/d2 ± -2(xB-xA)K/d2  
					//					K = (1/4)sqrt(((rA+rB)2-d2)(d2-(rA-rB)2))
					//					d2 = (xB-xA)2 + (yB-yA)2  
					//  A=lp    B=np
					np = points[i + 1];
					
					var dx:Number = lp.x - np.x;
					var dy:Number = lp.y - np.y;
					
					if(dx * dx + dy * dy > 2 * R * R)
					{
						// move chain
						if(dx == 0)
						{
							p.x = lp.x;
							p.y = lp.y + R * (dy > 0 ? -1 : 1);
						}else if(dy == 0)
						{
							p.y = lp.y;
							p.x = lp.x + R * (dx > 0 ? -1 : 1);
						}
						else
						{
							K = dy / dx;
							d2 = Math.sqrt(R * R / (1 + K * K));
							
							x1 = d2;
							x2 = -d2;
							
							y1 = K * x1;
							y2 = K * x2;
							
							x1 += lp.x;
							x2 += lp.x;
							y1 += lp.y;
							y2 += lp.y;
							
							if((lp.x > np.x ? lp.x : np.x) < x1 || (lp.x < np.x ? lp.x : np.x) > x1)
							{
								p.x = x2;
								p.y = y2;
							}
							else
							{
								p.x = x1;
								p.y = y1;
							}
						}
					}
					else
					{
						dx = np.x-lp.x;
						dy = np.y-lp.y;
						d2 = dx * dx + dy * dy;
						K = 0.25 * Math.sqrt((4 * R * R-d2) * d2)
						
						x1 = 0.5 * (np.x+lp.x) + 2    * dy * K / d2;
						x2 = 0.5 * (np.x+lp.x) - 2    * dy * K / d2;
						
						y1 = 0.5 * (np.y+lp.y) - 2 * dx * K / d2;
						y2 = 0.5 * (np.y+lp.y) + 2 * dx * K / d2;
						
						dx1 = p.x - x1;
						dy1 = p.y - y1;
						dx2 = p.x - x2;
						dy2 = p.y - y2;
						
						if(dx1 * dx1 + dy1 * dy1 <= dx2 * dx2 + dy2 * dy2)
						{
							p.x = x1;
							p.y = y1;
						}
						else
						{
							p.x = x2;
							p.y = y2;
						}
					}
				}
			}
			
//			trace("===========================");
//			for(i = 0; i<POINTS_NUM; i++)
//			{
//				p = points[i];
//				trace(i + "	) " + Number(p.x).toFixed(3) + "	" + Number(p.y).toFixed(3));
//			}
		}
		
		private function renderPoints(helixX:int, helixY:int):void
		{
			var R2:Number = leadLength * (Config.TILE_WIDTH + Config.TILE_HEIGHT) * 0.5 / POINTS_NUM;
			R2 = R2 * R2;
			var g:Graphics = drawingLayer.graphics;
			g.clear();
			g.lineStyle(normal > 10?2:1, 0);			
			
			for(var i:int = 0;i<POINTS_NUM;i++)
			{
				var p:Object = points[i];		
				if(p.x * p.x + p.y * p.y - R2 < 100)
				{
					g.lineTo(0,0);
					break;// закончили рисование
				}
				
				if(i == 0)
					g.moveTo(p.x, p.y);
				else
					g.lineTo(p.x, p.y);
			}
		}
		
		
		private function oldMethod(helixX:int, helixY:int):void
		{
			if(age++ % 3 == 0)// пересчитать control point
			{
				// "сопричастный" угол от (угол поворота поводка)
				var leadAngle:Number = Math.PI - Math.atan2(helixY, helixX);
				
				// расстояние от поводка, до  изгиба, будь поводок треугольным
				var helixXtile:Number = helixX / Config.TILE_WIDTH;
				var helixYtile:Number = helixY / Config.TILE_HEIGHT;
				const MAX_NORMAL:int = 30;
				normal = MAX_NORMAL * Math.pow(leadLength - Math.sqrt(helixXtile * helixXtile + helixYtile * helixYtile), 4);
				
				if(normal > MAX_NORMAL) normal = MAX_NORMAL;
				if(normal < -MAX_NORMAL) normal = -MAX_NORMAL;
				
				controlX = helixX * 0.5 + normal * Math.sin(leadAngle);
				controlY = helixY * 0.5 + normal * Math.cos(leadAngle);
			}
			var g:Graphics = drawingLayer.graphics;
			g.clear();
			g.lineStyle(normal > 10?2:2, 0x005081);
			
			g.moveTo(0, 0);// shell coords == {0,0}
			g.curveTo(controlX, controlY, helixX, helixY);
		}
	}
}