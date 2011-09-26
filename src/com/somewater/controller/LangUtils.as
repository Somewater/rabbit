package com.progrestar.controller
{
	
	/**
	 * Операции со словами: нужные падежи и т.д.
	 */
	public class LangUtils
	{
		public function LangUtils()
		{
		}
		
		
		// слово "друзья" в родительном падеже
		public static function friends_genetive(value:int):String{
			if(value == 1 || (value > 20 && value < 25))
				return "соседа";

			return "соседей";
				
		}
		
		public static function endVotes(num:Number, fixed:Number = 2):String
        {
               var restring:String = "";
               
               if(num < 0)                                             restring = num.toFixed(fixed) + " голоса";
               else if(num == 0)                           restring = "0 голосов";
               else if(num == 1)                           restring = num.toFixed(fixed) + " голос";
               else if(num%100 >= 10 && num%100 <= 20)     restring = num.toFixed(fixed) + " голосов";
               else if(num%10 == 1)                         restring = num.toFixed(fixed) + " голос";
               else if(num%10 >= 2 && num%10 <= 4)         restring = num.toFixed(fixed) + " голоса";
               else if(num%10 >  5 || num%10 == 0)         restring = num.toFixed(fixed) + " голосов";
               else                                         restring = num.toFixed(fixed) + " голосов";
               
               if (num > 999999){
                    if (num>999999999999)
                         return (num/1000000000000).toFixed(1) + " трлн. голосов";
                    else if (num>999999999)
                         return (num/1000000000).toFixed(2) + " млрд. голосов";
                    else
                         return (num/1000000).toFixed(3) + " млн. голосов";
               }
               
               return restring;
        }
        
        public static function formatTime(time:Number):String
		{
			var tempStr:String = "через ";
			var tempNumber:Number;
			var tempDay:Number = time % 86400;
			tempNumber = (time - tempDay) / 86400;
			if(tempNumber > 0)
				tempStr += tempNumber + " " + (tempNumber == 1?"день":(tempNumber < 5?"дня":"дней"));
			var tempHour:Number = tempDay % 3600 ;
			tempNumber = (tempDay - tempHour) / 3600;
			if(tempNumber > 0)
				tempStr += endHour(tempNumber);
				//tempStr += " " + tempNumber + " ч";
			var tempMinute:Number = tempHour % 60;
			tempNumber = (tempHour - tempMinute) / 60;
			if(tempNumber > 0)
				tempStr += endMinute(tempNumber);
				//tempStr += "  " + tempNumber + " мин";
			if (time < 60)
				tempStr += "несколько секунд";
			if (time < 0)
				tempStr = "после перезагрузки";
			/*
			var tempSecond:Number = tempMinute % 1;
			tempNumber = tempMinute - tempSecond;
			tempStr += (tempNumber > 9?tempNumber:"0" + tempNumber);
			*/
			return tempStr;
		}
		
		public static function endHour(time:Number):String
		{
			var restring:String = "";
			
			if(time == 1)                                 restring = time + " час";
			else if(time%100 >= 10 && time%100 <= 20)     restring = time + " часов";
			else if(time%10 == 1)                         restring = time + " час";
			else if(time%10 >= 2 && time%10 <= 4)         restring = time + " часа";
			else if(time%10 >  5 || time%10 == 0)         restring = time + " часов";
			else                                          restring = time + " часов";
			
			return restring;
		}
		
		public static function shortNumber(sum:Number):String{
			if (sum < 10000)
				return String(sum.toString()).substr(0,(Math.log(sum)/Math.LN10 + 4));
			else{
				if (sum<1000000)
					return int(sum).toString();
				else
					return sum.toPrecision(sum<0x3B9ACA00?3:2);
			}
		}

		public static function endMinute(time:Number):String
		{
			var restring:String = "";
			
			if(time == 1)                                 restring = time + " минуту";
			else if(time%100 >= 10 && time%100 <= 20)     restring = time + " минут";
			else if(time%10 == 1)                         restring = time + " минуту";
			else if(time%10 >= 2 && time%10 <= 4)         restring = time + " минуты";
			else if(time%10 >  5 || time%10 == 0)         restring = time + " минут";
			else                                         restring = time + " минут";
			
			return restring;
		}
	}
}