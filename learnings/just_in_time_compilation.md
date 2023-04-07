# Just-in-time (JIT) compilation


PostgreSQL's Just-in-Time (JIT) compilation feature was introduced in version 11 to improve the performance of query execution. JIT compilation is an optimization technique that compiles parts of the query plan into native machine code at runtime, allowing for faster query execution. This can be especially beneficial for complex queries or those that involve large amounts of data.

The JIT compilation feature in PostgreSQL is based on the LLVM compiler infrastructure, which provides a framework for converting the query plan's low-level operations into native machine code.

Here's a detailed explanation of PostgreSQL's JIT compilation feature:

1. Components of JIT:

   * JIT expression evaluation: Instead of interpreting the expressions in the query plan, the JIT compiler generates native code to evaluate them, which can result in faster execution.
   * JIT tuple deforming: The process of extracting individual attributes from a tuple is called tuple deforming. JIT can optimize this operation by generating native code for tuple deforming, which can be faster than the generic deforming function.
   * JIT tuple projection: When projecting a tuple, the query executor needs to remove unneeded columns and convert the tuple to the target format. JIT can optimize this operation by generating native code for tuple projection.
2. Enabling and configuring JIT:
   By default, JIT compilation is not enabled in PostgreSQL. To enable JIT, you need to set the configuration parameter `jit` to `on`. You can do this in the `postgresql.conf` file or on a per-session basis using the `SET` command:

   <pre><div class="bg-black rounded-md mb-4"><div class="flex items-center relative text-gray-200 bg-gray-800 px-4 py-2 text-xs font-sans justify-between rounded-t-md"><span>vbnet</span><button class="flex ml-auto gap-2"><svg stroke="currentColor" fill="none" stroke-width="2" viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4" height="1em" width="1em" xmlns="http://www.w3.org/2000/svg"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path><rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect></svg>Copy code</button></div><div class="p-4 overflow-y-auto"><code class="!whitespace-pre hljs language-vbnet">SET jit = on;
   </code></div></div></pre>

   Additionally, you can fine-tune the JIT compilation behavior using other configuration parameters:

   * `jit_above_cost`: The query cost must be above this value for JIT compilation to be applied. Default is 100,000.
   * `jit_inline_above_cost`: The query cost must be above this value for the JIT compiler to inline functions. Default is 500,000.
   * `jit_optimize_above_cost`: The query cost must be above this value for the JIT compiler to apply optimizations. Default is 100,000.
3. Limitations and trade-offs:

   * Compilation overhead: JIT compilation introduces an overhead as the compilation process itself takes time. This overhead might outweigh the performance benefits for simpler queries or those executed only once. Therefore, JIT is more suited for complex, long-running queries or those executed repeatedly.
   * Memory usage: JIT compilation can increase memory usage due to the generation of native code and related data structures.
   * Maintenance: The use of LLVM as a third-party dependency adds complexity to the PostgreSQL build process and may introduce additional maintenance tasks.

In summary, PostgreSQL's JIT compilation feature uses the LLVM compiler infrastructure to generate native code for parts of the query plan, which can improve the performance of query execution. However, JIT compilation introduces overhead and may not be beneficial for all types of queries. It can be enabled and configured using several configuration parameters, and it is most suited for complex, long-running queries or those executed repeatedly.
