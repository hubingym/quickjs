module main

import quickjs

fn fib(n int) int {
    if n <= 0 {
        return 0
    } else if n == 1 {
        return 1
    } else {
        return fib(n - 1) + fib(n - 2)
    }
}

fn js_fib(p_ctx *C.JSContext, this_val C.JSValueConst, argc int, argv *C.JSValueConst) C.JSValue {
    n := 0
    if C.JS_ToInt32(p_ctx, &n, argv[0]) {
        return C.JS_MKVAL(C.JS_TAG_EXCEPTION, 0)
    }
    res := fib(n)
    return C.JS_NewInt32(p_ctx, res)
}

fn init_module_demo(ctx quickjs.Context) {
    mut m := ctx.add_module('demo')
    m.new_cfunction('fib', 1, &js_fib)
    m.new_jsval('global', ctx.get_global_bject())
    m.new_int32('O_WRONLY', C.O_WRONLY)
    m.new_double('pi', 3.14)
    m.new_string('platform', 'win32')

    obj1 := ctx.new_object()
    ctx.define_property_double(obj1, 'pi', 3.14)
    ctx.define_property_cfunc(obj1, 'fib', 1, &js_fib)
    m.new_jsval('obj1', obj1)
}
