---
layout: post
title: 栈缓冲区溢出之三 Security Cookie / Canary
categories: notes
tags: binary
---

当栈溢出发生时，如果能够检测到栈溢出已经发生，就可以及时中止程序的执行，从而能够避免继续走攻击者安排好的路。Windows 上的 Security Cookie 就是这样一种机制。在 Linux 上，Canary 这个名字更常用。不论是 Security Cookie 还是 Canary，它们的原理都是相同的。

当栈溢出发生时，常见的获取控制流的手段就是覆盖函数的返回地址：

![stack-buffer-overflow]({% asset stack-buffer-overflow.png stack-buffer-overflow-101 %})

那么如何才能够检测到返回地址是否被覆盖了呢？从上图我们可以看到，如果需要覆盖返回地址，攻击者必须覆盖掉从缓冲区开始一直到返回地址之间的所有内容，包括其他的局部变量和 BP。Security Cookie 的思想是，在 BP 之上压入一个随机产生的数，如果缓冲区溢出后覆盖了返回地址，那么则一定会覆盖掉 Security Cookie：

![canary]({% asset canary.png %})

与此同时，在栈空间之外，还保存有一份 Security Cookie。在函数返回之前，只需要检查栈上的 Cookie 跟全局的 Cookie 是否一致即可，如果不一致则说明已经发生了溢出。

不过，做这些额外的工作会对程序性能产生影响。因此，默认情况下 MSVC 和 GCC 不会对所有的函数栈帧进行保护，而是选择那些明显存在安全隐患的函数进行保护。

## GCC 的 `-fstack-protector` 编译选项

`-fstack-protector` 选项并不会对所有的函数加以保护。它只会为：

- 调用了 [`alloca`](https://linux.die.net/man/3/alloca) 的函数
- 存在超过 8 个字节的缓冲区的函数

添加栈溢出保护。与之类似的还有两个选项：`-fstack-protector-strong` 和 `-fstack-protector-all`。`-fstack-protector-strong` 属于加强版本，它除了上面两类函数，它还会为：

- 定义了局部数组的函数
- 持有局部栈地址的函数

添加保护。`-fstack-protector-all` 一眼便知，它会为所有函数都添加栈溢出保护。

另外还有一个编译选项 `-fstack-protector-explicit`，它则表示这项功能默认关闭，只对那些显式声明了 `stack_protect` 属性的函数添加保护。

## MSVC 的 `/GS` 编译选项

`/GS` 同样不会保护所有的函数，它只保护包含有“GS Buffer”的函数。所谓“GS Buffer”是指：

- 大于 4 个字节的数组，并且数组的元素个数超过 2 个，同时元素的类型不是指针类型。或者，
- 大于 8 个字节的数据结构，其中没有指针类型。或者，
- 由 `_alloca` 申请的缓冲区。或者，
- 任何包含 GS Buffer 的类或结构体。

## 绕过 Security Cookie

Security Cookie 通常难以绕过。但在某些特殊情况下，还是有绕过的可能：

- 函数编写的不够谨慎，使得 `printf` 能够泄露出 Security Cookie 的值
- 如果能够重复地溢出同一个进程（例如函数调用了 `fork`，使得原来的进程不会崩溃退出），则可以尝试暴力破解
