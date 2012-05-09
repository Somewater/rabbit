package com.somewater.arrow {
	public class ArrowPermission {
		public static const USER_PROFILE:uint = 2;

		public static const FRIENDS_PROFILES:uint = 4;

		public static const NOTIFY:uint = 8;

		public static const WALL_POST:uint = 16;// пост на стену любого юзера

		public static const STREAM_POST:uint = 32;// пост на собственную стену (в собственную новостную ленту)

		public static const PAYMENT:uint = 64;

		public static const DEFAULT:uint = USER_PROFILE | FRIENDS_PROFILES | NOTIFY;
	}
}
