module quickjs

#flag -I @VMOD/quickjs/src
#include "quickjs-libc.h"
#flag @VMOD/quickjs/quickjs.o

struct C.JSRuntime {
}

struct C.JSContext {
}

struct C.JSModuleDef {
}

struct C.JSValue {
}

struct C.JSValueConst {
}

fn C.JS_NewCFunction(*C.JSContext, voidptr, byteptr, int) C.JSValue
fn C.JS_AddModuleExport(*C.JSContext, *C.JSModuleDef, byteptr) int
fn C.JS_SetModuleExport(*C.JSContext, *C.JSModuleDef, byteptr, C.JSValue) int

fn todo_remove(){}

struct Opaque {
pub: mut:
    modules []voidptr
}

struct Runtime {
pub: mut:
    p_rt *C.JSRuntime
}

pub fn new_runtime() Runtime {
    p_rt := C.JS_NewRuntime()
    if !p_rt {
        panic('quickjs: cannot allocate JS runtime')
    }
    // loader for ES6 modules
    C.SetModuleLoaderFunc(p_rt)
    return Runtime {
        p_rt: p_rt
    }
}

pub fn (rt mut Runtime) free() {
    C.js_std_free_handlers(rt.p_rt)
    C.JS_FreeRuntime(rt.p_rt)
    rt.p_rt = 0
}

struct Context {
pub: mut:
    p_ctx *C.JSContext
}

pub fn new_context(rt Runtime) Context {
    p_ctx := C.JS_NewContext(rt.p_rt)
    if !p_ctx {
        panic('quickjs: cannot allocate JS context')
    }
    ctx := Context {
        p_ctx: p_ctx
    }
    opaque := &Opaque{}
    C.JS_SetContextOpaque(p_ctx, opaque)
    return ctx
}

pub fn (ctx mut Context) free() {
    C.JS_FreeContext(ctx.p_ctx)
    ctx.p_ctx = 0
}

pub fn (ctx mut Context) init_std() {
    p_ctx := ctx.p_ctx
    // TODO: int argc, char **argv
     C.js_std_add_helpers(p_ctx, 0, 0)
    /* system modules */
    C.js_init_module_std(p_ctx, 'std')
    C.js_init_module_os(p_ctx, 'os')
}

pub fn (ctx mut Context) eval_file(filename string) {
    C.eval_file(ctx.p_ctx, filename.str, 0)
}

pub fn (ctx mut Context) loop() {
    C.js_std_loop(ctx.p_ctx)
}

pub fn (ctx Context) add_module(name string) *Module {
    p_ctx := ctx.p_ctx
    m := new_module(p_ctx, name, &module_init_func)
    mut opaque := (*Opaque)(C.JS_GetContextOpaque(p_ctx))
    opaque.modules << (*void)(m)
    return m
}

fn module_init_func(p_ctx *C.JSContext, p_m *C.JSModuleDef) {
    mut m := find_module(p_ctx, p_m)
    m.inner_init()
}

pub fn find_module(p_ctx *C.JSContext, p_m *C.JSModuleDef) *Module {
    opaque := (*Opaque)(C.JS_GetContextOpaque(p_ctx))
    for v in opaque.modules {
        m := (*Module)(v)
        if m.p_m == p_m {
            return m
        }
    }
    panic('quickjs: cannot find JS CModule')
    return &Module{}
}

struct CFuncDef {
    name string
    length int
    func voidptr
}

pub fn new_cfunc_def(name string, length int, func voidptr) CFuncDef {
    return CFuncDef {
        name: name
        length: length
        func: func
    }
}

struct Module {
    p_ctx *C.JSContext
    p_m *C.JSModuleDef
    funcs []CFuncDef
}

fn new_module(p_ctx *C.JSContext, name string, init_func voidptr) *Module {
    p_m := C.JS_NewCModule(p_ctx, name.str, init_func)
    if !p_m {
        panic('quickjs: cannot allocate JS CModule')
    }
    m := &Module {
        p_ctx: p_ctx
        p_m: p_m
    }
    return m
}

fn (m mut Module) add_export_item(name string) int {
    res := C.JS_AddModuleExport(m.p_ctx, m.p_m, name.str)
    if res != 0 {
        panic('quickjs: add_export_item failed')
    }
    return res
}

fn (m mut Module) add_export_list(names []string) int {
    for name in names {
        if m.add_export_item(name) != 0 {
            return -1
        }
    }
    return 0
}

fn (m mut Module) set_export_item(name string, val C.JSValue) {
    res := C.JS_SetModuleExport(m.p_ctx, m.p_m, name.str, val)
    if res != 0 {
        panic('quickjs: set_export_item failed')
    }
}

fn (m mut Module) new_cfunction(def CFuncDef) {
    val := C.JS_NewCFunction(m.p_ctx, def.func, def.name.str, def.length)
    m.set_export_item(def.name, val)
}

fn (m mut Module) inner_init() {
    for func in m.funcs {
        m.new_cfunction(func)
    }
}

pub fn (m mut Module) add_cfunction(name string, length int, func voidptr) {
    m.add_export_item(name)
    def := new_cfunc_def(name, length, func)
    m.funcs << def
}
