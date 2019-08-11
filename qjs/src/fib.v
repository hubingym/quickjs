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

fn init_module_fib(ctx quickjs.Context) {
    mut m := ctx.add_module('fib')
    m.add_cfunction('fib', 1, &js_fib)
}
