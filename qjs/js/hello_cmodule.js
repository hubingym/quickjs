/* example of JS module importing a C module */

import * as demo from "demo";

console.log("Hello World");
console.log(JSON.stringify(demo));
console.log("demo.fib(10)=", demo.fib(10));
console.log("demo.obj1.fib(5)=", demo.obj1.fib(5));
