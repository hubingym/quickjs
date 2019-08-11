module main

import os
import flag
import quickjs

fn help() {
    text := '
QuickJS version 2019-07-09
usage: qjs [options] [files]
-h  --help         list options
'
    println(text)
}

fn main() {
    if '-h' in os.args || '--help' in os.args {
        help()
        return
    }

    mut fp := flag.new_flag_parser(os.args)
    // dump_memory := fp.bool('dump', false, '')
    // empty_run := fp.bool('quit', false, '')
    // println('dump_memory:$dump_memory, empty_run:$empty_run')
    fp.skip_executable()
    files := fp.finalize() or {
        panic(err)
        return
    }
    // println(files)
    if files.len < 1 {
        panic('no input javascript file')
        return
    }

    // runtime
    mut rt := quickjs.new_runtime()
    // context
    mut ctx := quickjs.new_context(rt)
    // initial std library
    ctx.init_std()
    // custom modules
    init_module_demo(ctx)
    // execute file
    ctx.eval_file(files[0])
    // loop
    ctx.loop()
    // free
    ctx.free()
    // free
    rt.free()
}
