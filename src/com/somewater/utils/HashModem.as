package com.somewater.utils
{

	/**
	 * Термины, используемые в классе:
	 * 		hash - хэш, даные в перекодированном виде, состоящие только из [a..z0..9]
	 * 		data - символьные данные, содержащие тольео разрешенные символы
	 * 		fragment - 7 символов из hash (сответствуют 5-ти символам из data, т.е. word)
	 * 		word - 5 символов из data, которые кодируются в 7 символов hash
	 * 		fragmentChar - символ из fragment
	 * 		wortChar - символ из word
	 * 		key - цифровой код символа (число 0..140 для wordChar, либо число 0..35 для fragmentChar)
	 *				соответственно: fragmentCharKey, wordCharKey
	 * 				wordChar = wordCharKey 0..140 = 0..35 + 0..3 * 35 = exact + high * 35 = f(fragmentChar, 2 byte) = 1.4 fragmentChar 
	 * 		byte - байт, используемый в алгритме. 2 byte и 1 fragmentChar кодируют 1 wordChar. 
	 * 				Соответственно fragment состоит из 2-х символов, кодирующих 10 byte (0..35 > 0..32 = 0..2^5)
	 * 				и 5-ти символов, кодирующих точную часть соответствующего word-символа
	 * 				Набор из 10-ти байт представляет из себя число 0..1024 (0..2^10), где каждый разряд соответствует байту
	 */
	public class HashModem
	{
		// символ, которым будут заполняться данные до 180 символов
		public static const FILLER:String = "_";
		
		// разрешенные символы (символы не входящие в данный набор будут ошибочно кодироваться). Всего 141
		public static const PERMITTED_SYMBOLS:String =  FILLER + " 0123456789АаБбВвГгДдЕеЖжЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЬьЫыЪъЭэЮюЯяAaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz!@():,./-?_" + "\n" + '"';

		// символы, разрешенные для полей ввода (символ подчеркивание "_" запрещен)
		public static const PERMITED_INPUT_SYMBOLS:String = " 0123456789АаБбВвГгДдЕеЖжЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЬьЫыЪъЭэЮюЯяAaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz!@():,./-?" + "\n" + '"';
		
		// длина поля данных
		public static const DATA_LENGTH:int = 180;// при наборе из 141 допустимых символов
		
		// длина хэша
		public static const HASH_LENGTH:int = 252;
		
		public function HashModem()
		{
		}
		
		/**
		 * Получив hash длиной 252 символов генерирует из них данные
		 * Из полученных данных вырезаются концевые FILLER
		 * @return data
		 */
		public static function demodulate(hash:String):String{
			if (hash == null) throw new Error("Hash is null");
			if (hash.length % 7 != 0) throw new Error("Error hash length. Hash has length = "+hash.length);
			var data:String = "";
			var i:int;
			var hashLength:int = int(hash.length / 7);
			for (i = 0;i<hashLength;i++)
				data += fragmentToWord(hash.substr(i * 7, 7));
			// обрезаем символы-заполнители
			while(data.charAt(data.length - 1) == FILLER){
				data = data.substr(0, data.length - 1);
			}
			return data;
				
		}
		
		/**
		 * Получив данные длиной до 180 символов, генерирует hash длиной 252 символа
		 * Если данных менее 180, они заполняются FILLER (т.е. данные нельзя завершать этим символом)
		 * @return hash
		 */
		public static function modulate(data:String):String{
			if (data == null) throw new Error("Data is null");
			if (data.charAt(data.length - 1) == FILLER) throw new Error("Data close sybmol must not be FILLER = ["+FILLER+"]");
			if (data.length > 180)
				throw new Error("Very long data. Data length = "+data.length);
			// дополняем данные символами-заполнителями
			while(data.length % 5 != 0)
				data += FILLER;
			var hash:String = "";
			var i:int;
			var dataLength:int = int(data.length / 5);
			for(i = 0;i<dataLength;i++)
				hash += wordToFragment(data.substr(i * 5, 5));
			return hash;
		}
		
		/**
		 * Проверяет данные на вхождение неразрешенных символов.
		 * Возвращает 0 если данные пригодны для кодирования.
		 * Иначе выдает код ошибки:
		 * 			1 - дата содержит недопустимые символы
		 * 			2 - data имеет слишком большую длину
		 * 			3 - data == null || data == ""
		 * 			
		 */
		public static function validateData(data:String):int{
			if (data == null) return 3;
			var length:int = data.length;
			if (length == 0) return 3;
			if (length > DATA_LENGTH) return 2;
			for (var i:int = 0;i<length;i++){
				var key:int = data.charAt(i).charCodeAt();
				if (key > 1039 && key < 1104)// русские буквы
					continue;
				else if(key > 62 && key < 123 && key != 91 && key != 92 && key != 93 && key != 94 && key != 96)// английские и _
					continue;
				else if(key == 32)// пробел
					continue;
				else if(key > 38 && key < 59 && key != 42 && key != 43)// цифры или ,-./:'()
					continue;
				else if(key == 10 || key == 33 || key == 34)// пробел !"
					continue;
				else
					return 1;
			}
			return 0;
		}
		
		
		/**
		 * Вырезает неподдерживаемые символы
		 */
		public static function softReplacement(input:String):String{
			var counter:int = 0;
			input = input.replace(/ё/g,"е");
			input = input.replace(/Ё/g,"Е");
			while(counter < input.length){
				var char:String = input.charAt(counter);
				if(PERMITTED_SYMBOLS.indexOf(input.charAt(counter)) == -1)
				{
					trace("Unsupported symbol [" + char + "] deleted in \"" + input + "\"");
					input = input.substring(0, counter) + input.substr(counter + 1);
				}	
				else
					counter++;
			}
			return input;
		}
		
		
		//////////////////////////////////////////////////////////////////////////////
		//																			//
		//							PRIVATE FUNCTIONS								//
		//																			//
		//////////////////////////////////////////////////////////////////////////////
		
		private static function fragmentToWord(fragment:String):String{
			var bytes:int = fragmentCharToKey(fragment.charAt(0)) * 35 + fragmentCharToKey(fragment.charAt(1));
			var i:int;
			var word:String = "";
			for(i = 0;i<5;i++){
				var high:int = (int(Boolean(bytes & (1 << (i*2 + 1))))) * 2 + int(Boolean(bytes & (1 << (i*2))));
				word += wordKeyToChar(fragmentCharToKey(fragment.charAt(2 + i))  +  high * 35);
			}
			return word;
		}
		
		private static function wordToFragment(word:String):String{
			var fragment:String = "";
			var bytes:int = 0;
			var i:int;
			for(i = 0;i<5;i++){
 				var wordCharKey:int = wordCharToKey(word.charAt(i));
 				if (wordCharKey == 140){
 					// обработка особого случая (буква "я")
 					fragment += fragmentKeyToChar(35);// получилось бы 0 вместо 35
					bytes += ((int(3))  <<  i*2);// получилось бы 4 вместо 3
 				}else{
 					fragment += fragmentKeyToChar(wordCharKey % 35);
					bytes += ((int(wordCharKey/35))  <<  i*2);
 				}
			}
			fragment = fragmentKeyToChar(int(bytes/35)) + fragmentKeyToChar(bytes % 35)   +    fragment;
			return fragment;
		}
		
		
		
		private static function fragmentCharToKey(char:String):int{
			var key:int = char.charCodeAt();
			return key - (key>57?87:48);
		}
		
		private static function fragmentKeyToChar(key:int):String{
			return String.fromCharCode(key + (key>9?87:48));
		}
		
		private static function wordCharToKey(char:String):int{
			var key:int = char.charCodeAt();
			if (key > 1039)// русские буквы
				return key - 963;
			else if(key > 96)// английские строчные
				return key - 46;
			else if(key == 95)// подчеркивание _
				return 50;
			else if(key == 32)// пробел
				return 1;
			else if(key > 62)// английские заглавные или ?@
				return key - 41;
			else if(key > 43)// цифры или ,-./:
				return key - 37;
			else if (key == 10)// \n
				return 0;
			else if(key < 35)// !"  (также это мог быть пробел, но пробел отсеевается ранее)
				return key - 31;
			else if(key < 42)// '()
				return key - 35;
			else
				throw new Error("Unexpected char ["+char+"] in word");
		}
		
		private static function wordKeyToChar(key:int):String{
			if (key > 76)// русские буквы
				key += 963;
			else if(key > 50)// английские строчные
				key += 46;
			else if(key == 50)// подчеркивание _
				key = 95;
			else if(key == 1)// пробел
				key = 32;
			else if(key > 21)// английские заглавные или ?@
				key += 41;
			else if(key > 6)// цифры или ,-./:
				key += 37;
			else if (key == 0)// \n
				key = 10;
			else if(key < 4)// !"  (также это мог быть пробел, но пробел отсеевается ранее)
				key += 31;
			else if(key < 7)// '()
				key += 35;
			else
				throw new Error("Unexpected key ["+key+"] in word. It`s mean ["+String.fromCharCode(key)+"] symbol");
			return String.fromCharCode(key);
		}
		
	   /**
	    *						" ТАБЛИЦА СИМВОЛОВ "
	    * 
	    * 
		*		1040	А		1072	а		65	A		97	a		10	/n (строка)
		*		1041	Б		1073	б		66	B		98	b		32	пробел
		*		1042	В		1074	в		67	C		99	c		33	!
		*		1043	Г		1075	г		68	D		100	d		34	"
		*		1044	Д		1076	д		69	E		101	e			
		*		1045	Е		1077	е		70	F		102	f		39	'
		*		1046	Ж		1078	ж		71	G		103	g		40	(
		*		1047	З		1079	з		72	H		104	h		41	)
		*		1048	И		1080	и		73	I		105	i			
		*		1049	Й		1081	й		74	J		106	j		44	,
		*		1050	К		1082	к		75	K		107	k		45	-
		*		1051	Л		1083	л		76	L		108	l		46	.
		*		1052	М		1084	м		77	M		109	m		47	/
		*		1053	Н		1085	н		78	N		110	n		48	0
		*		1054	О		1086	о		79	O		111	o		49	1
		*		1055	П		1087	п		80	P		112	p		50	2
		*		1056	Р		1088	р		81	Q		113	q		51	3
		*		1057	С		1089	с		82	R		114	r		52	4
		*		1058	Т		1090	т		83	S		115	s		53	5
		*		1059	У		1091	у		84	T		116	t		54	6
		*		1060	Ф		1092	ф		85	U		117	u		55	7
		*		1061	Х		1093	х		86	V		118	v		56	8
		*		1062	Ц		1094	ц		87	W		119	w		57	9
		*		1063	Ч		1095	ч		88	X		120	x		58	:
		*		1064	Ш		1096	ш		89	Y		121	y			
		*		1065	Щ		1097	щ		90	Z		122	z		63	?
		*		1066	Ъ		1098	ъ								64	@
		*		1067	Ы		1099	ы									
		*		1068	Ь		1100	ь		95	_	------------------->>
		*		1069	Э		1101	э									
		*		1070	Ю		1102	ю									
		*		1071	Я		1103	я		
		*/
	}
}