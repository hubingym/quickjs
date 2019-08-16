qjs:
	v -debug -show_c_cmd -o qjs src

test:
	./qjs.exe js/hello.js
	./qjs.exe js/hello_jsmodule.js
	./qjs.exe js/hello_cmodule.js

clean:
	rm -f qjs qjs.exe .qjs.c fns.txt