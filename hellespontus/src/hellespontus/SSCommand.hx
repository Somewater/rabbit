package hellespontus;


class SSCommand 
{
	/**
	 * ответить, какие доступны комнаты
	 * bytes null
	 */
	public static inline var SS_CMD_INDEX:Int = 10; 
	
	/**
	 * ответ насчет доступных комнат
	 * bytes {active:Int, max:Int}
	 */
	public static inline var SS_CMD_INDEX_RESPONSE:Int = 11; 

	/**
	 * присоединиться к комнате
	 * bytes[0] 	номер комнаты
	 * bytes[1] 	номер сети
	 * bytes[2..]   id юзера
	 */
	public static inline var SS_CMD_CONNECT:Int = 20;
	
	/**
	 * соединение с комнатой успешно установлено
	 * bytes null
	 */
	public static inline var SS_CMD_CONNECTED_SUCCESS:Int = 21;

	/**
	 * широковещательное сообщение для комнаты
	 * bytes ANY!=null
	 */
	public static inline var SS_CMD_BROADCAST:Int = 30;

	/**
	 * сообщение для хозяина комнаты
	 * bytes ANY!=null
	 */
	public static inline var SS_CMD_DISPATCH:Int = 31;	

	/**
	 * новый участник в комнате
	 * bytes ANY (профайл юзера?)
	 */
	public static inline var SS_CMD_ADDED:Int = 50;

	/**
	 * комнату покинул зарегистрированный участник
	 * bytes ANY (профайл юзера?)
	 */
	public static inline var SS_CMD_REMOVED:Int = 51;

	/**
	 * разъединиться с комнатой
	 * bytes null
	 */
	public static inline var SS_CMD_SUICIDE:Int = 52;

	/**
	 * разрушить комнату
	 * bytes null
	 */
	public static inline var SS_CMD_DESTROY_ALL:Int = 53;
	
	/**
	 * Комната удалена
	 * bytes null
	 */
	public static inline var SS_CMD_DESTROY_ALL_NOTIFY:Int = 54;

	//////////////////////////////////
	//                              //
	// 			коды ошибок			//
	//                              //
	//////////////////////////////////

	/**
	 * Logic error в процессе выполнения запроса
	 * bytes string
	 */
	public static inline var SS_CMD_LOGIC_ERROR:Int = 40;
}