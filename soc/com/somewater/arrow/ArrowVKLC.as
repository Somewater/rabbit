package com.somewater.arrow{
import com.somewater.social.VkontakteLCSocialAdapter;

public class ArrowVKLC extends Arrow{
    public function ArrowVKLC() {
    }

    override public function createSocial():void {
        social = new VkontakteLCSocialAdapter()
    }

    /*override public function init(params:Object):void
    {
        //params['key'] = '529d006c41825455c4addca3a69046a6';
        super.init(params);
    }*/
}
}
