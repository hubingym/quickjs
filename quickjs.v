module quickjs

#flag -I @VMOD/quickjs/src
#include "quickjs-libc.h"
#flag @VMOD/quickjs/quickjs.o

import const (
    JS_PROP_CONFIGURABLE
    JS_PROP_WRITABLE
    JS_PROP_ENUMERABLE
    JS_PROP_C_W_E
)

struct C.JSRuntime {
}

struct C.JSContext {
}

struct C.JSModuleDef {
}

struct C.JSClassDef {
}

struct C.JSValue {
}

struct C.JSValueConst {
}

fn C.JS_GetRuntime(*C.JSContext) *C.JSRuntime
fn C.JS_NewClassID(*u32) u32
fn C.JS_NewClass(*C.JSRuntime, u32, *C.JSClassDef) int
fn C.JS_SetClassProto(*C.JSContext, u32, C.JSValue)
fn C.JS_DefinePropertyValueStr(*C.JSContext, C.JSValueConst, byteptr, C.JSValue, int) int
fn C.JS_NewObject(*C.JSContext) C.JSValue
fn C.JS_GetGlobalObject(*C.JSContext) C.JSValue
fn C.JS_NewCFunction(*C.JSContext, voidptr, byteptr, int) C.JSValue
fn C.JS_NewBool(*C.JSContext, int) C.JSValue
fn C.JS_NewInt32(*C.JSContext, i32) C.JSValue
fn C.JS_NewFloat64(*C.JSContext, f64) C.JSValue
fn C.__JS_NewFloat64(*C.JSContext, f64) C.JSValue
fn C.JS_NewString(*C.JSContext, byteptr) C.JSValue
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

pub fn (ctx Context) init_std() {
    p_ctx := ctx.p_ctx
    // TODO: int argc, char **argv
     C.js_std_add_helpers(p_ctx, 0, 0)
    /* system modules */
    C.js_init_module_std(p_ctx, 'std')
    C.js_init_module_os(p_ctx, 'os')
}

pub fn (ctx Context) eval_file(filename string) {
    C.eval_file(ctx.p_ctx, filename.str, 0)
}

pub fn (ctx Context) loop() {
    C.js_std_loop(ctx.p_ctx)
}

pub fn (ctx Context) define_property_value_str(this_obj C.JSValue, prop string, val C.JSValue) int {
    return C.JS_DefinePropertyValueStr(ctx.p_ctx, this_obj, prop.str, val, JS_PROP_C_W_E)
}

pub fn (ctx Context) define_property_cfunc(this_obj C.JSValue, prop string, length int, func voidptr) int {
    val := C.JS_NewCFunction(ctx.p_ctx, func, prop.str, length)
    return ctx.define_property_value_str(this_obj, prop, val)
}

pub fn (ctx Context) define_property_bool(this_obj C.JSValue, prop string, value bool) int {
    val := C.JS_NewBool(ctx.p_ctx, value)
    return ctx.define_property_value_str(this_obj, prop, val)
}

pub fn (ctx Context) define_property_int32(this_obj C.JSValue, prop string, value int) int {
    val := C.JS_NewInt32(ctx.p_ctx, value)
    return ctx.define_property_value_str(this_obj, prop, val)
}

pub fn (ctx Context) define_property_double(this_obj C.JSValue, prop string, value f64) int {
    val := C.JS_NewFloat64(ctx.p_ctx, value)
    return ctx.define_property_value_str(this_obj, prop, val)
}

pub fn (ctx Context) define_property_string(this_obj C.JSValue, prop string, value string) int {
    val := C.JS_NewString(ctx.p_ctx, value.str)
    return ctx.define_property_value_str(this_obj, prop, val)
}

pub fn (ctx Context) get_global_bject() C.JSValue {
    return C.JS_GetGlobalObject(ctx.p_ctx)
}

pub fn (ctx Context) new_object() C.JSValue {
    return C.JS_NewObject(ctx.p_ctx)
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

struct JsValueDef {
    name string
    val C.JSValue
}

pub fn new_jsvalue_def(name string, val C.JSValue) JsValueDef {
    return JsValueDef {
        name: name
        val: val
    }
}

struct Module {
    p_ctx *C.JSContext
    p_m *C.JSModuleDef
    funcs []CFuncDef
    vals []JsValueDef
    bool_map map[string]bool
    i32_map map[string]int
    f64_map map[string]f64
    str_map map[string]string
}

fn new_module(p_ctx *C.JSContext, name string, init_func voidptr) *Module {
    p_m := C.JS_NewCModule(p_ctx, name.str, init_func)
    if !p_m {
        panic('quickjs: cannot allocate JS CModule')
    }
    m := &Module {
        p_ctx: p_ctx
        p_m: p_m
        bool_map: map[string]bool{}
        i32_map: map[string]int{}
        f64_map: map[string]f64{}
        str_map: map[string]string{}
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

fn (m mut Module) inner_init() {
    for def in m.funcs {
        val := C.JS_NewCFunction(m.p_ctx, def.func, def.name.str, def.length)
        m.set_export_item(def.name, val)
    }

    for def in m.vals {
        m.set_export_item(def.name, def.val)
    }

    for name, value in m.bool_map {
        val := C.JS_NewBool(m.p_ctx, value)
        m.set_export_item(name, val)
    }

    for name, value in m.i32_map {
        val := C.JS_NewInt32(m.p_ctx, value)
        m.set_export_item(name, val)
    }

    for name, value in m.f64_map {
        val := C.__JS_NewFloat64(m.p_ctx, value)
        m.set_export_item(name, val)
    }

    for name, value in m.str_map {
        val := C.JS_NewString(m.p_ctx, value.str)
        m.set_export_item(name, val)
    }
}

pub fn (m mut Module) new_cfunction(name string, length int, func voidptr) {
    m.add_export_item(name)
    def := new_cfunc_def(name, length, func)
    m.funcs << def
}

pub fn (m mut Module) new_jsval(name string, val C.JSValue) {
    m.add_export_item(name)
    def := new_jsvalue_def(name, val)
    m.vals << def
}

pub fn (m mut Module) new_bool(name string, value bool) {
    m.add_export_item(name)
    m.bool_map[name] = value
}

pub fn (m mut Module) new_int32(name string, value int) {
    m.add_export_item(name)
    m.i32_map[name] = value
}

pub fn (m mut Module) new_double(name string, value f64) {
    m.add_export_item(name)
    m.f64_map[name] = value
}

pub fn (m2 mut Module) new_string(name string, value string) {
    m2.add_export_item(name)
    m2.str_map[name] = value
}
