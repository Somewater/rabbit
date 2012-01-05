package com.somewater.utils
{
   
//   import com.pblabs.engine.PBE;
//   import com.pblabs.engine.core.InputKey;
//   import com.progrestar.city.CommonConfig;
   
   import flash.display.DisplayObjectContainer;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.ui.Keyboard;
   import flash.utils.getTimer;

   /**
    * Удобный профайлер из pushbuttonengine. Использование:
	* <listing>
	*  // инициализация (вызвать в главном классе игры, например в конструкторе или в run-е)
	*  Profiler.init(this);
	*  //для профайлинга
	*  Profiler.enter("some code");
	*  // some code
	*  Profiler.exit("some code");
	* </listing>
    * Simple, static hierarchical block profiler.
    *
    * Currently it is hardwired to start measuring when you press P, and dump
    * results to the log when you let go of P. Eventually something more
    * intelligent will be appropriate.
    *
    * Use it by calling Profiler.enter("CodeSectionName"); before the code you
    * wish to measure, and Profiler.exit("CodeSectionName"); afterwards. Note
    * that Enter/Exit calls must be matched - and if there are any branches, like
    * an early return; statement, you will need to add a call to Profiler.exit()
    * before the return.
    *
    * Min/Max/Average times are reported in milliseconds, while total and non-sub
    * times (times including children and excluding children respectively) are
    * reported in percentages of total observed time.
    */
   public class Profiler
   {
      public static var enabled:Boolean = true;
      public static var nameFieldWidth:int = 100;
      public static var indentAmount:int = 3;
	  
	  /**
	  	*  Профайлер работает
	  	*/
	  private static var on:Boolean = false;
	  
	  public static function init(mainStage:DisplayObjectContainer, hotkey:uint = Keyboard.SPACE):void{
		  if(mainStage.stage)
			  addListener(mainStage.stage)
		  else
			  mainStage.addEventListener(Event.ADDED_TO_STAGE, function(ev:Event):void{
			 	 ev.currentTarget.removeEventListener(ev.type, arguments.callee);
				 addListener(ev.currentTarget.stage);
		 	 });
		  function addListener(main:DisplayObjectContainer):void{
			  main.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void{
				  if(e.keyCode == Keyboard.SPACE)
					  Profiler.on = !Profiler.on;
			  });
		  }
	  }


      /**
       * Indicate we are entering a named execution block.
       */
      public static function enter(blockName:String):void
      {
      	 //return;
         if(!_currentNode)
         {
            _rootNode = new ProfileInfo("Root")
            _currentNode = _rootNode;
         }
         
         // If we're at the root then we can update our internal enabled state.
         if(_stackDepth == 0)
         {
            // Hack - if they press, then release insert, start/stop and dump
            // the profiler.
            if(on)
            {
               if(!enabled)
               {
                  _wantWipe = true;
                  enabled = true;
               }
            }
            else
            {
               if(enabled)
               {
                  _wantReport = true;
                  enabled = false;
               }
            }
            
            _reallyEnabled = enabled;
            
            if(_wantWipe)
               doWipe();
            
            if(_wantReport)
               doReport();
         }
         
         // Update stack depth and early out.
         _stackDepth++;
         //var e:Error = new Error(); trace(blockName + "	>>> " + _stackDepth.toString()+"	"+e.getStackTrace());
         if(!_reallyEnabled)
            return;
            
         // Look for child; create if absent.
         var newNode:ProfileInfo = _currentNode.children[blockName];
         if(!newNode)
         {
            newNode = new ProfileInfo(blockName, _currentNode);
            _currentNode.children[blockName] = newNode;
         }
         
         // Push onto stack.
         _currentNode = newNode;
         
         // Start timing the child node. Too bad you can't QPC from Flash. ;)
         _currentNode.startTime = flash.utils.getTimer();
      }
      
      /**
       * Indicate we are exiting a named exection block.
       */
      public static function exit(blockName:String):void
      {
      	//return;
         // Update stack depth and early out.
         _stackDepth--;
         
         //var e:Error = new Error();  trace(blockName + "	< " + _stackDepth.toString()+"	"+e.getStackTrace());
		
         if(!_reallyEnabled)
            return;
         
         if(blockName != _currentNode.name)
            throw new Error("Mismatched Profiler.enter/Profiler.exit calls, got '" + _currentNode.name + "' but was expecting '" + blockName + "'");
         
         // Update stats for this node.
         var elapsedTime:int = flash.utils.getTimer() - _currentNode.startTime;
         _currentNode.activations++;
         _currentNode.totalTime += elapsedTime;
         if(elapsedTime > _currentNode.maxTime) _currentNode.maxTime = elapsedTime;
         if(elapsedTime < _currentNode.minTime) _currentNode.minTime = elapsedTime;

         // Pop the stack.
         _currentNode = _currentNode.parent;
      }
      
      /**
       * Dumps statistics to the log next time we reach bottom of stack.
       */
      public static function report():void
      {
         if(_stackDepth)
         {
            _wantReport = true;
            return;
         }
         
         doReport();
      }
      
      /**
       * Reset all statistics to zero.
       */
      public static function wipe():void
      {
         if(_stackDepth)
         {
            _wantWipe = true;
            return;
         }
         
         doWipe();
      }
      
      /**
       * Call this outside of all Enter/Exit calls to make sure that things
       * have not gotten unbalanced. If all enter'ed blocks haven't been
       * exit'ed when this function has been called, it will give an error.
       *
       * Useful for ensuring that profiler statements aren't mismatched.
       */
      public static function ensureAtRoot():void
      {
      	 //trace("Not at root!");
      	 //return;
         if(_stackDepth)
            throw new Error("Not at root!");
      }
	  
	  /**
	   * FIX 05/01/2012 - очистить очередь профайлинга, 
	   * тем самым разрешив игре работать после эксепшна
	   */
	  public static function clear():void
	  {
		  _stackDepth = 0;
		  _currentNode = null;
	  }
      
      private static function doReport():void
      {
         _wantReport = false;
         
         var header:String = sprintf( "%-" + nameFieldWidth + "s%-8s%-8s%-8s%-8s%-8s%-8s", "name", "Calls", "Total%", "NonSub%", "AvgMs", "MinMs", "MaxMs" );
		 print(header)
         report_R(_rootNode, 0);
      }
      
      private static function report_R(pi:ProfileInfo, indent:int):void
      {
         // Figure our display values.
         var selfTime:Number = pi.totalTime;

         var hasKids:Boolean = false;
         var totalTime:Number = 0;
         for each(var childPi:ProfileInfo in pi.children)
         {
            hasKids = true;
            selfTime -= childPi.totalTime;
            totalTime += childPi.totalTime;
         }
         
         // Fake it if we're root.
         if(pi.name == "Root")
            pi.totalTime = totalTime;
         
         var displayTime:Number = -1;
         if(pi.parent)
            displayTime = Number(pi.totalTime) / Number(_rootNode.totalTime) * 100;
            
         var displayNonSubTime:Number = -1;
         if(pi.parent)
            displayNonSubTime = selfTime / Number(_rootNode.totalTime) * 100;
         
         // Print us.
         var entry:String = null;
         if(indent == 0)
         {
             entry = "+Root";
         }
         else
         {
             entry = sprintf( "%-" + (indent * indentAmount) + "s%-" + (nameFieldWidth - indent * indentAmount) + "s%-8s%-8s%-8s%-8s%-8s%-8s", "",
                 (hasKids ? "+" : "-") + pi.name, pi.activations, displayTime.toFixed(2), displayNonSubTime.toFixed(2), (Number(pi.totalTime) / Number(pi.activations)).toFixed(1), pi.minTime, pi.maxTime);             
         }
		 print(entry);
         
         // Sort and draw our kids.
         var tmpArray:Array = new Array();
         for each(childPi in pi.children)
            tmpArray.push(childPi);
         tmpArray.sortOn("totalTime", Array.NUMERIC | Array.DESCENDING);
         for each(childPi in tmpArray)
            report_R(childPi, indent + 1);
      }
	  
	  private static function print(msg:String):void{
		  trace("> " + msg);
	  }

      private static function doWipe(pi:ProfileInfo = null):void
      {
         _wantWipe = false;
         
         if(!pi)
         {
            doWipe(_rootNode);
            return;
         }
         
         pi.wipe();
         for each(var childPi:ProfileInfo in pi.children)
            doWipe(childPi);
      }
      
      /**
       * Because we have to keep the stack balanced, we can only enabled/disable
       * when we return to the root node. So we keep an internal flag.
       */
      private static var _reallyEnabled:Boolean = true;
      private static var _wantReport:Boolean = false, _wantWipe:Boolean = false;
      private static var _stackDepth:int = 0;
      
      private static var _rootNode:ProfileInfo;
      private static var _currentNode:ProfileInfo;
	  
	  private static function sprintf(format:String, ... args):String
	  {
		  var result:String = "";
		  
		  var length:int = format.length;
		  for (var i:int = 0; i < length; i++)
		  {
			  var c:String = format.charAt(i);
			  
			  if (c == "%")
			  {
				  var next: *;
				  var str: String;
				  var pastFieldWidth:Boolean = false;
				  var pastFlags:Boolean = false;
				  
				  var flagAlternateForm:Boolean = false;
				  var flagZeroPad:Boolean = false;
				  var flagLeftJustify:Boolean = false;
				  var flagSpace:Boolean = false;
				  var flagSign:Boolean = false;
				  
				  var fieldWidth:String = "";
				  var precision:String = "";
				  
				  c = format.charAt(++i);
				  
				  while (c != "d"
					  && c != "i"
					  && c != "o"
					  && c != "u"
					  && c != "x"
					  && c != "X"
					  && c != "f"
					  && c != "F"
					  && c != "c"
					  && c != "s"
					  && c != "%")
				  {
					  if (!pastFlags)
					  {
						  if (!flagAlternateForm && c == "#")
							  flagAlternateForm = true;
						  else if (!flagZeroPad && c == "0")
							  flagZeroPad = true;
						  else if (!flagLeftJustify && c == "-")
							  flagLeftJustify = true;
						  else if (!flagSpace && c == " ")
							  flagSpace = true;
						  else if (!flagSign && c == "+")
							  flagSign = true;
						  else
							  pastFlags = true;
					  }
					  
					  if (!pastFieldWidth && c == ".")
					  {
						  pastFlags = true;
						  pastFieldWidth = true;
						  
						  c = format.charAt(++i);
						  continue;
					  }
					  
					  if (pastFlags)
					  {
						  if (!pastFieldWidth)
							  fieldWidth += c;
						  else
							  precision += c;
					  }
					  
					  c = format.charAt(++i);
				  }
				  
				  switch (c)
				  {
					  case "d":
					  case "i":
						  next = args.shift();
						  str = String(Math.abs(int(next)));
						  
						  if (precision != "")
							  str = leftPad(str, int(precision), "0");
						  
						  if (int(next) < 0)
							  str = "-" + str;
						  else if (flagSign && int(next) >= 0)
							  str = "+" + str;
						  
						  if (fieldWidth != "")
						  {
							  if (flagLeftJustify)
								  str = rightPad(str, int(fieldWidth));
							  else if (flagZeroPad && precision == "")
								  str = leftPad(str, int(fieldWidth), "0");
							  else
								  str = leftPad(str, int(fieldWidth));
						  }
						  
						  result += str;
						  break;
					  
					  case "o":
						  next = args.shift();
						  str = uint(next).toString(8);
						  
						  if (flagAlternateForm && str != "0")
							  str = "0" + str;
						  
						  if (precision != "")
							  str = leftPad(str, int(precision), "0");
						  
						  if (fieldWidth != "")
						  {
							  if (flagLeftJustify)
								  str = rightPad(str, int(fieldWidth));
							  else if (flagZeroPad && precision == "")
								  str = leftPad(str, int(fieldWidth), "0");
							  else
								  str = leftPad(str, int(fieldWidth));
						  }
						  
						  result += str;
						  break;
					  
					  case "u":
						  next = args.shift();
						  str = uint(next).toString(10);
						  
						  if (precision != "")
							  str = leftPad(str, int(precision), "0");
						  
						  if (fieldWidth != "")
						  {
							  if (flagLeftJustify)
								  str = rightPad(str, int(fieldWidth));
							  else if (flagZeroPad && precision == "")
								  str = leftPad(str, int(fieldWidth), "0");
							  else
								  str = leftPad(str, int(fieldWidth));
						  }
						  
						  result += str;
						  break;
					  
					  case "X":
						  var capitalise:Boolean = true;
					  case "x":
						  next = args.shift();
						  str = uint(next).toString(16);
						  
						  if (precision != "")
							  str = leftPad(str, int(precision), "0");
						  
						  var prepend:Boolean = flagAlternateForm && uint(next) != 0;
						  
						  if (fieldWidth != "" && !flagLeftJustify
							  && flagZeroPad && precision == "")
							  str = leftPad(str, prepend
								  ? int(fieldWidth) - 2 : int(fieldWidth), "0");
						  
						  if (prepend)
							  str = "0x" + str;
						  
						  if (fieldWidth != "")
						  {
							  if (flagLeftJustify)
								  str = rightPad(str, int(fieldWidth));
							  else
								  str = leftPad(str, int(fieldWidth));
						  }
						  
						  if (capitalise)
							  str = str.toUpperCase();
						  
						  result += str;
						  break;
					  
					  case "f":
					  case "F":
						  next = args.shift();
						  str = Math.abs(Number(next)).toFixed( precision != "" ?  int(precision) : 6 );
						  
						  if (int(next) < 0)
							  str = "-" + str;
						  else if (flagSign && int(next) >= 0)
							  str = "+" + str;
						  
						  if (flagAlternateForm && str.indexOf(".") == -1)
							  str += ".";
						  
						  if (fieldWidth != "")
						  {
							  if (flagLeftJustify)
								  str = rightPad(str, int(fieldWidth));
							  else if (flagZeroPad && precision == "")
								  str = leftPad(str, int(fieldWidth), "0");
							  else
								  str = leftPad(str, int(fieldWidth));
						  }
						  
						  result += str;
						  break;
					  
					  case "c":
						  next = args.shift();
						  str = String.fromCharCode(int(next));
						  
						  if (fieldWidth != "")
						  {
							  if (flagLeftJustify)
								  str = rightPad(str, int(fieldWidth));
							  else
								  str = leftPad(str, int(fieldWidth));
						  }
						  
						  result += str;
						  break;
					  
					  case "s":
						  next = args.shift();
						  str = String(next);
						  
						  if (precision != "")
							  str = str.substring(0, int(precision));
						  
						  if (fieldWidth != "")
						  {
							  if (flagLeftJustify)
								  str = rightPad(str, int(fieldWidth));
							  else
								  str = leftPad(str, int(fieldWidth));
						  }
						  
						  result += str;
						  break;
					  
					  case "%":
						  result += "%";
				  }
			  }
			  else
			  {
				  result += c;
			  }
		  }
		  
		  return result;
	  }
   
   // Private functions
   
   private static function leftPad(source:String, targetLength:int, padChar:String = " "):String
   {
	   if (source.length < targetLength)
	   {
		   var padding:String = "";
		   
		   while (padding.length + source.length < targetLength)
			   padding += padChar;
		   
		   return padding + source;
	   }
	   
	   return source;
   }
   
   private static function rightPad(source:String, targetLength:int, padChar:String = " "):String
   {
	   while (source.length < targetLength)
		   source += padChar;
	   
	   return source;
   }
   }
}

final class ProfileInfo
{
   public var name:String;
   public var children:Object = {};
   public var parent:ProfileInfo;
   
   public var startTime:int, totalTime:int, activations:int;
   public var maxTime:int = int.MIN_VALUE;
   public var minTime:int = int.MAX_VALUE;
   
   final public function ProfileInfo(n:String, p:ProfileInfo = null)
   {
      name = n;
      parent = p;
   }
   
   final public function wipe():void
   {
      startTime = totalTime = activations = 0;
      maxTime = int.MIN_VALUE;
      minTime = int.MAX_VALUE;
   }
}