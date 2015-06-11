all:
	valac --library=GSoc --vapi=gsoc.vapi -H gsoc.h src/*.vala -X -fPIC -X -shared -o libgsoc.so
    

clean:
	rm -rf libgsoc.so gsoc.vapi gsoc.h

install:
	cp -f libgsoc.so /usr/lib/
	cp -f gsoc.vapi /usr/share/vala/vapi/
	cp -f gsoc.h /usr/include/
	cp -f gsoc.pc /usr/lib/pkgconfig/	

uninstall:
	rm -rf /usr/lib/libgsoc.so
	rm -rf /usr/share/vala/gsoc.vapi
	rm -rf /usr/include/gsoc.h    
	rm -rf /usr/lib/pkgconfig/gsoc.pc
