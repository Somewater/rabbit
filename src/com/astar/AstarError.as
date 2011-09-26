/*
Copyright (c) 2008 Jeroen Beckers

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

package com.astar 
{

	/**
	* AStarError 	class which is thrown in case of an error in processing parameters of methods in a be.dauntless.dstar.AStar instance.
	* 
	* @author Jeroen Beckers.
	*/
	public class AstarError extends Error
	{
		/**
		* Creates a new AStarError with a given message and an optional id.
		* 
		* @param	message	The message which describes what went wrong in the List.
		* @param	errorID	An optional errorID for keeping track of error messages.
		*/
		public function AstarError(message:String, errorID:int = 0)
		{
			super(message, errorID);
		}
		
		/**
		* Returns a String representation of the current AStarError instance, including the id and message.
		* 
		* @return		A string representing this AstarError instance
		*/
		public function toString() : String
		{
			return "AStarError[" + errorID + "] message: " + message;
		}
	}
}
