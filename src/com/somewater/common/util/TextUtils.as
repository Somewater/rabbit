package com.somewater.common.util
{
	import com.somewater.common.lang.Translate;
	
	/**
	 * Операции со словами: нужные падежи и т.д.
	 */
	public class TextUtils
	{
		public function TextUtils()
		{
		}
		
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
        
		/** 
		 * 
		 * @param time
		 * @return
		 */
		public static function formatContractTime(time : int) : String {
			var hrs : int = time/3600;
			var str : String = ''; 
			if(hrs > 0) {
				time = time - hrs*3600;
				str += hrs +  ' ' + Translate.translate('T_SHORT_HOUR') + ' ';
			}
			if(time > 0) {
				var mins : int = time/60;
				if(mins > 0) {
					str += mins + ' ' + Translate.translate('T_SHORT_MIN') + ' ';
					time -= mins*60;
				}
			}
			if(time>0) {
				str += time + ' ' + Translate.translate('T_SHORT_SEC') + ' ';
			}
			return str;
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
		
		public static function leadSymbol(string : String, number : int=2, symbol : String='0') : String {
			while(string.length < number) {
				string = symbol + string;
			}
			return string;
		}
		
		public static function formatTimeNumbers(time:uint, digits : int=0) : String {
			var arr:Array = [];
			
			if( time >= 86400 ) {
				arr.push( leadSymbol(String(Math.floor(time/86400))));
			} else if(digits >= 4) {
				arr.push( '00' );
			}
			time = time % 86400;
			if( time >= 3600 ) {
				arr.push( leadSymbol(String(Math.floor(time/3600))) );
			} else if(digits >= 3) {
				arr.push( '00' );
			}
			time = time % 3600;
			if( time >= 60 ) {
				arr.push( leadSymbol(String(Math.floor(time/60))) );
			} else if(digits >= 2) {
				arr.push( '00' );
			} 
			time = time % 60;
			arr.push( leadSymbol(String(time)) );
			
			return arr.join(":");
		}
		
		public static function formatTimeToString(time:uint):String
		{
			var arr:Array = [];
			
			arr.push(leadSymbol(String(Math.floor(time/3600))));
			time = time % 3600;
			
			arr.push(leadSymbol(String(Math.floor(time/60))));
			time = time % 60;
			
			arr.push(leadSymbol(String(time)));
			
			return arr.join(":");
		}
		
		/**
		 * По цифре возвращает месяц в родительном падеже (создание надписей вроде "25 декабря 1912 года")
		 * 0 - января, 1 - февраля .. 
		 * @param номер месяца, начиная с 0
		 * @return месяц в родительном падеже
		 */
		public static function getMonthGenitive(month:int):String{
			switch (month){
				case 0: return "января"; break;
				case 1: return "февраля"; break;
				case 2: return "марта"; break;
				case 3: return "апреля"; break;
				case 4: return "мая"; break;
				case 5: return "июня"; break;
				case 6: return "июля"; break;
				case 7: return "августа"; break;
				case 8: return "сентября"; break;
				case 9: return "октября"; break;
				case 10: return "ноября"; break;
				case 11: return "декабря"; break;
			}
			return "ERROR";
		}
		
		
		/**
		 * @return слово "друзья" в дательном падеже, напр 3 -> "друзьям", 1 -> "другу" 
		 */
		public static function friendsNumDative(number:uint):String
		{
			if(number == 1) return "другу";
			return "друзьям";
		}
		
		/**
		 * @return слово "друзья" в винительном (?) падеже, напр 3 -> "друга", 1 -> "друг"
		 * для фраз типа "приглашено 3 друга" 
		 */
		public static function friendsNumAccusative(number:uint):String
		{
			if(number == 1) return "друг";
			if(number != 0 && number < 5) return "друга";
			return "друзей";
		}
	}
}