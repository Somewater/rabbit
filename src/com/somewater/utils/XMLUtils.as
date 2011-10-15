package com.somewater.utils
{

	/**
	 * A set of useful XML utilities
	 *
	 */
	public class XMLUtils
	{

		/**
		 * Sort an XML based on an attibute
		 *
		 * @param	xml			XML to sort (it is modified)
		 * @param	cmp 		compare function
		 * @return	The resulting XML object.
		 */
		 public static function sortXMLByAttribute(xml:XML, cmp:Function):XML
		 {
			//store in array to sort on
			var xmlArray:Array	= new Array();

			var item:XML;
			for each(item in xml.children())
			{
				xmlArray.push(item);
			}
			xmlArray.sort(cmp)

			var sortedXmlList:XMLList = new XMLList();
			var xmlObject:Object;
			for each(xmlObject in xmlArray )
			{
				sortedXmlList += xmlObject;
			}

			return	xml.copy().setChildren(sortedXmlList);
		 }

	}
}