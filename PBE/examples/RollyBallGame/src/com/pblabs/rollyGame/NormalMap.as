/*******************************************************************************
 * PushButton Engine
 * Copyright (C) 2009 PushButton Labs, LLC
 * For more information see http://www.pushbuttonengine.com
 * 
 * This file is property of PushButton Labs, LLC and NOT under the MIT license.
 ******************************************************************************/
package com.pblabs.rollyGame
{
    import com.pblabs.engine.entity.*;
    import com.pblabs.rendering2D.*;
    import com.pblabs.rendering2D.spritesheet.SpriteContainerComponent;
    
    import flash.display.*;
    import flash.geom.*;
    
    /**
     * Store normal and height information for a RollyBallGame level.
     */
    public class NormalMap extends EntityComponent
    {
        /**
         * The image we will be sampling normals from.
         */
        public var NormalSheet:SpriteContainerComponent;
        
        /**
         * The image for heightmap information.
         */
        public var HeightSheet:SpriteContainerComponent;
        
        /**
         * Determine the normal and height for a location on the normal map.
         * 
         * @param x X location on the normal map, in pixels.
         * @param y Y location on the normal map, in pixels.
         * @param outNormal Point that is set with the normal for this location in -1..1 range.
         * @return Height as 0..1 value.
         */
        public function getNormalAndHeight(x:int, y:int, outNormal:Point):Number
        {
            if(!NormalSheet)
                throw new Error("No NormalSheet!");
            
            if(!HeightSheet)
                throw new Error("No HeightSheet!");
            
            // Get the bitmapdata for normal.
            var bd:BitmapData = NormalSheet.getFrame(0);
            if(!bd)
                return 0.5;
            
            // Get and decode normal map for this position.
            var pixelValue:uint = bd.getPixel32(x, y);
            if(pixelValue == 0)
                pixelValue = 0x7F7F7F00;
            
            var red:uint        = pixelValue >> 16 & 0xFF;
            var green:uint      = pixelValue >> 8 & 0xFF;
            
            // Get x and y from the normal.
            var ax:uint = red;
            var ay:uint = 255 - green;
            
            // Return the direction as a -1..1 value.
            if(outNormal)
            {
                outNormal.x = (ax - 127) / 128.0;
                outNormal.y = (ay - 127) / 128.0;
            }
            
            return getHeight(x, y);
        }
        
        /**
         * Return the height at a location. 
         * @param x X pixel location.
         * @param y Y pixel location.
         * @return Height.
         */
        public function getHeight(x:int, y:int):Number
        {
            // Get the height bitmapdata.
            var heightBd:BitmapData = HeightSheet.getFrame(0);
            if(!heightBd)
                return 0.5;
            
            // Get heightmap.
            var heightValue:uint = heightBd.getPixel32(x, y) >> 16 & 0xFF;
            
            // Height as 0..1 value.
            return heightValue / 255.0;		   
        }
    }
}