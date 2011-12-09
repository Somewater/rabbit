package com.somewater.arrow{
import com.somewater.social.VkontakteSocialAdapter;

public class ArrowVK extends Arrow{
    public function ArrowVK() {
    }

    override public function createSocial():void {
        social = new VkontakteSocialAdapter()
    }

    /*override public function init(params:Object):void
    {
        //params['key'] = '529d006c41825455c4addca3a69046a6';
        super.init(params);
    }*/
}
}
