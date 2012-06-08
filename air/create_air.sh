#/home/pav/bin/sdks/4.5.0/bin/adt -package -storetype pkcs12 -keystore hello.pfx -storepass pav664 -target air Hello.air rabbit.xml .
#/home/pav/bin/sdks/4.5.0/bin/adt -package -target apk-emulator -storetype pkcs12 -keystore hello.pfx -storepass pav664 Hopper.apk rabbit.xml -C output icons AIRSWFRabbitLoader.swf
/home/pav/bin/sdks/4.5.0/bin/adt -package -target apk-emulator -storetype pkcs12 -keystore hello.pfx -storepass pav664 Hopper.apk rabbit.xml -C output icons AIRSWFRabbitLoader.swf
#/home/pav/bin/sdks/4.5.0/bin/adt -package -target apk-captive-runtime -storetype pkcs12 -keystore hello.pfx -storepass pav664 Hopper.apk rabbit.xml -C output icons AIRSWFRabbitLoader.swf
