package com.somewater.rabbit
{
	/**
	 * Содержит анимационные стейты, используемые различными персонажами в игре
	 */
	public class States
	{
		/**
		 * Стоять. стейт, присущий любому персонажу игры
		 */
		public static const STAND:String = "stand";
		
		
		/**
		 * Идти. Стейт, присущий любому подвижному персонажу
		 */
		public static const WALK:String = "walk";
		
		/**
		 * Атакует
		 */
		public static const ATTACK:String = "attack";
		
		/**
		 * Аналогично "stand", персонаж ничего не делает, 
		 * однако анимация отличается и дает возможным переходы в другие состояния
		 */
		public static const THINK:String = "think";
		
		/**
		 * Объект находится в состоянии перехода меж сетйтами.
		 * Предыдущий стейт уже недействителен, достигаемый еще не достигнут,
		 * однако объект в подобном стейте не стоит без необходимости переводить в новый стейт
		 */
		public static const TRANSITION:String = "transition";
	}
}
