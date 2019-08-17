qjs:
	v -debug -show_c_cmd -o qjs src

test:
	./qjs js/hello.js
	./qjs js/hello_jsmodule.js
	./qjs js/hello_cmodule.js

test_win:
	./qjs.exe js/hello.js
	./qjs.exe js/hello_jsmodule.js
	./qjs.exe js/hello_cmodule.js

clean:
	rm -f qjs qjs.exe .qjs.c fns.txt

.PHONY: qjs test test_win clean