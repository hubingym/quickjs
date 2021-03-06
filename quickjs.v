module quickjs

#include <fcntl.h>
#flag -I @VMOD/quickjs/src
#include "quickjs-libc.h"
#flag @VMOD/quickjs/quickjs.o

pub struct C.JSRuntime {
}

pub struct C.JSContext {
}

pub struct C.JSModuleDef {
}

pub struct C.JSClassDef {
    class_name byteptr
    finalizer voidptr
    gc_mark voidptr
    call voidptr
    exotic voidptr
}

pub struct C.JSValue {
}

fn C.js_malloc(ctx &C.JSContext, size u32) voidptr
fn C.js_free(ctx &C.JSContext, ptr voidptr)
fn C.JS_GetRuntime(ctx &C.JSContext) &C.JSRuntime
fn C.JS_AddModuleExport(ctx &C.JSContext, m &C.JSModuleDef, name byteptr) int
fn C.JS_SetModuleExport(ctx &C.JSContext, m &C.JSModuleDef, name byteptr, val C.JSValue) int

fn C.JS_NewClassID(pclass_id &u32) u32
fn C.JS_NewClass(rt &C.JSRuntime, class_id u32, class_def &C.JSClassDef) int
fn C.JS_SetClassProto(ctx &C.JSContext, class_id u32, val C.JSValue)
fn C.JS_GetClassProto(ctx &C.JSContext, class_id u32) C.JSValue

fn C.JS_SetPropertyStr(ctx &C.JSContext, this_obj C.JSValue, prop byteptr, val C.JSValue) int
fn C.JS_GetPropertyStr(ctx &C.JSContext, this_obj C.JSValue, prop byteptr) C.JSValue

// fn C.JS_SetOpaque(val C.JSValue, opaque voidptr)
// fn C.JS_GetOpaque(val C.JSValue, class_id u32) voidptr

fn C.JS_GetGlobalObject(ctx &C.JSContext) C.JSValue
fn C.JS_DupValue(ctx &C.JSContext, val C.JSValue) C.JSValue
fn C.JS_FreeValue(ctx &C.JSContext, val C.JSValue)
fn C.JS_NewObjectClass(ctx &C.JSContext, class_id u32) C.JSValue
fn C.JS_NewObject(ctx &C.JSContext) C.JSValue
fn C.JS_NewArray(ctx &C.JSContext) C.JSValue
fn C.JS_NewCFunction(ctx &C.JSContext, func voidptr, name byteptr, length int) C.JSValue
fn C.JS_NewCFunction2(ctx &C.JSContext, func voidptr, name byteptr, length int, cproto int, magic int) C.JSValue
fn C.JS_NewBool(ctx &C.JSContext, val int) C.JSValue
fn C.JS_NewInt32(ctx &C.JSContext, val int) C.JSValue
fn C.JS_NewFloat64(xtx &C.JSContext, val f64) C.JSValue
fn C.JS_NewString(ctx &C.JSContext, str byteptr) C.JSValue

fn C.JS_ToBool(ctx &C.JSContext, val C.JSValue) int /* return -1 for JS_EXCEPTION */
fn C.JS_ToInt32(ctx &C.JSContext, pres &u32, val C.JSValue) int
fn C.JS_ToFloat64(ctx &C.JSContext, pres &f64, val C.JSValue) int
fn C.JS_ToCString(xtx &C.JSContext, val C.JSValue) byteptr
fn C.JS_FreeCString(ctx &C.JSContext, ptr byteptr)

pub fn new_class_id() u32 {
    class_id := u32(0)
    return C.JS_NewClassID(&class_id)
}

pub struct Runtime {
mut:
    p_rt &C.JSRuntime
}

pub fn new_runtime() Runtime {
    p_rt := C.JS_NewRuntime()
    if isnil(p_rt) {
        panic('quickjs: cannot allocate JS runtime')
    }
    // loader for ES6 modules
    C.SetModuleLoaderFunc(p_rt)
    return Runtime {
        p_rt: p_rt
    }
}

pub fn make_runtime(p_rt &C.JSRuntime) Runtime {
    rt := Runtime {
        p_rt: p_rt
    }
    return rt
}

pub fn (rt Runtime) free() {
    C.js_std_free_handlers(rt.p_rt)
    C.JS_FreeRuntime(rt.p_rt)
}

pub fn (rt Runtime) run_gc() {
    C.JS_RunGC(rt.p_rt)
}

pub struct Context {
mut:
    p_ctx &C.JSContext
}

pub fn new_context(rt Runtime) Context {
    p_ctx := C.JS_NewContext(rt.p_rt)
    if isnil(p_ctx) {
        panic('quickjs: cannot allocate JS context')
    }
    ctx := Context {
        p_ctx: p_ctx
    }
    return ctx
}

pub fn make_context(p_ctx &C.JSContext) Context {
    ctx := Context {
        p_ctx: p_ctx
    }
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

pub fn (ctx Context) set_property_cfunc(this_obj C.JSValue, prop string, length int, func voidptr) int {
    val := C.JS_NewCFunction(ctx.p_ctx, func, prop.str, length)
    return C.JS_SetPropertyStr(ctx.p_ctx, this_obj, prop.str, val)
}

pub fn (ctx Context) set_property_bool(this_obj C.JSValue, prop string, value bool) int {
    val := C.JS_NewBool(ctx.p_ctx, value)
    return C.JS_SetPropertyStr(ctx.p_ctx, this_obj, prop.str, val)
}

pub fn (ctx Context) get_property_bool(this_obj C.JSValue, prop string) bool {
    val := C.JS_GetPropertyStr(ctx.p_ctx, this_obj, prop.str)
    n := C.JS_ToBool(ctx.p_ctx, val)
    return n == 1
}

pub fn (ctx Context) set_property_int32(this_obj C.JSValue, prop string, value int) int {
    val := C.JS_NewInt32(ctx.p_ctx, value)
    return C.JS_SetPropertyStr(ctx.p_ctx, this_obj, prop.str, val)
}

pub fn (ctx Context) get_property_int32(this_obj C.JSValue, prop string) int {
    val := C.JS_GetPropertyStr(ctx.p_ctx, this_obj, prop.str)
    n := 0
    C.JS_ToInt32(ctx.p_ctx, &n, val)
    return n
}

pub fn (ctx Context) set_property_double(this_obj C.JSValue, prop string, value f64) int {
    val := C.JS_NewFloat64(ctx.p_ctx, value)
    return C.JS_SetPropertyStr(ctx.p_ctx, this_obj, prop.str, val)
}

pub fn (ctx Context) get_property_double(this_obj C.JSValue, prop string) f64 {
    val := C.JS_GetPropertyStr(ctx.p_ctx, this_obj, prop.str)
    d := f64(0)
    C.JS_ToFloat64(ctx.p_ctx, &d, val)
    return d
}

pub fn (ctx Context) set_property_string(this_obj C.JSValue, prop string, value string) int {
    val := C.JS_NewString(ctx.p_ctx, value.str)
    return C.JS_SetPropertyStr(ctx.p_ctx, this_obj, prop.str, val)
}

pub fn (ctx Context) get_property_string(this_obj C.JSValue, prop string) string {
    val := C.JS_GetPropertyStr(ctx.p_ctx, this_obj, prop.str)
    pstr := C.JS_ToCString(ctx.p_ctx, val)
    res := tos_clone(pstr)
    C.JS_FreeCString(ctx.p_ctx, pstr)
    return res
}

pub fn (ctx Context) dup_value(val C.JSValue) C.JSValue {
    return C.JS_DupValue(ctx.p_ctx, val)
}

pub fn (ctx Context) free_value(val C.JSValue) {
    C.JS_FreeValue(ctx.p_ctx, val)
}

pub fn (ctx Context) set_opaque(obj C.JSValue, opaque voidptr) {
    C.JS_SetOpaque(obj, opaque)
}

pub fn (ctx Context) get_opaque(obj C.JSValue, class_id u32) voidptr {
    return C.JS_GetOpaque(obj, class_id)
}

pub fn (ctx Context) get_global_object() C.JSValue {
    return C.JS_GetGlobalObject(ctx.p_ctx)
}

pub fn (ctx Context) new_object() C.JSValue {
    return C.JS_NewObject(ctx.p_ctx)
}

pub fn (ctx Context) new_object_class(class_id u32) C.JSValue {
    obj := C.JS_NewObjectClass(ctx.p_ctx, class_id)
    return obj
}

pub fn (ctx Context) new_array() C.JSValue {
    return C.JS_NewArray(ctx.p_ctx)
}

pub fn (ctx Context) add_module(name string, init_func voidptr) Module {
    p_ctx := ctx.p_ctx
    m := new_module(p_ctx, name, init_func)
    return m
}

pub struct Module {
    p_ctx &C.JSContext
    p_m &C.JSModuleDef
}

fn new_module(p_ctx &C.JSContext, name string, init_func voidptr) Module {
    p_m := C.JS_NewCModule(p_ctx, name.str, init_func)
    if isnil(p_m) {
        panic('quickjs: cannot allocate JS CModule')
    }
    m := Module {
        p_ctx: p_ctx
        p_m: p_m
    }
    return m
}

pub fn make_module(p_ctx &C.JSContext, p_m &C.JSModuleDef) Module {
    m := Module {
        p_ctx: p_ctx
        p_m: p_m
    }
    return m
}

pub fn (m Module) add_export_item(name string) int {
    res := C.JS_AddModuleExport(m.p_ctx, m.p_m, name.str)
    if res != 0 {
        panic('quickjs: add_export_item failed')
    }
    return res
}

pub fn (m Module) add_export_list(names []string) int {
    for name in names {
        if m.add_export_item(name) != 0 {
            return -1
        }
    }
    return 0
}

pub fn (m Module) set_export_item(name string, val C.JSValue) {
    res := C.JS_SetModuleExport(m.p_ctx, m.p_m, name.str, val)
    if res != 0 {
        panic('quickjs: set_export_item failed, please make sure that \'$name\' is added to export list')
    }
}

pub fn (m Module) new_cfunction(name string, length int, func voidptr) {
    val := C.JS_NewCFunction(m.p_ctx, func, name.str, length)
    m.set_export_item(name, val)
}

pub fn (m Module) new_constructor(name string, length int, func voidptr) {
    val := C.JS_NewCFunction2(m.p_ctx, func, name.str, length, C.JS_CFUNC_constructor, 0)
    m.set_export_item(name, val)
}

pub fn (m Module) new_jsval(name string, val C.JSValue) {
    m.set_export_item(name, val)
}

pub fn (m Module) new_bool(name string, value bool) {
    val := C.JS_NewBool(m.p_ctx, value)
    m.set_export_item(name, val)
}

pub fn (m Module) new_int32(name string, value int) {
    val := C.JS_NewInt32(m.p_ctx, value)
    m.set_export_item(name, val)
}

pub fn (m Module) new_double(name string, value f64) {
    val := C.JS_NewFloat64(m.p_ctx, value)
    m.set_export_item(name, val)
}

pub fn (m Module) new_string(name string, value string) {
    val := C.JS_NewString(m.p_ctx, value.str)
    m.set_export_item(name, val)
}

pub fn (m Module) new_class(class_id u32, class_def &C.JSClassDef, proto C.JSValue) {
    p_ctx := m.p_ctx
    p_rt := C.JS_GetRuntime(p_ctx)
    C.JS_NewClass(p_rt, class_id, class_def)
    C.JS_SetClassProto(p_ctx, class_id, proto)
}
