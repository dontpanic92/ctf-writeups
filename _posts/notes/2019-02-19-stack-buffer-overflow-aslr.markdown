---
layout: post
title: 栈缓冲区溢出之二 ASLR
categories: notes
tags: binary
---

[上文]({% url_by_slug stack-buffer-overflow-101 %})介绍了栈缓冲区溢出的基本情况与利用方法。栈缓冲区溢出之后，如果没有任何防护措施，攻击者可以非常容易地改变程序执行逻辑，甚至可以执行注入的代码。为了降低栈缓冲区溢出漏洞发生后的风险，很多技术应运而生，ASLR（Address Space Layout Randomization，地址空间布局随机化）就是其中之一。

由于缓冲区溢出后，攻击者通常需要需要跳转到某些特定的系统函数、或是跳转到堆栈上执行，ASLR 的基本思想就是随机化动态库和堆栈空间的地址。这样就使得每次程序启动时，它们的地址都会发生变化，使得攻击者难以确定需要跳转到的目标地址。

### 查看系统是否开启 ASLR

#### Windows

Windows 自从 Vista 后全面支持了 ASLR 保护。在新版 Windows 10 中，可以在安全中心设置是否开启这一功能：

![windows-aslr-settings]({% asset windows-aslr-settings.jpg %})

设置中的 "Mandatory ASLR" 是指，如果一个程序没有使用 `/DYNAMICBASE` 选项编译时，是否仍然要随机地址空间。由于兼容性问题存在，这项设置默认关闭。

#### Linux

Linux 系统中，我们可以通过 `/proc/sys/kernel/randomize_va_space` 来查看或开启/关闭 ASLR：

```bash
dontpanic@Ubuntu:~$ cat /proc/sys/kernel/randomize_va_space
2
```

2 表示 ASLR 完全开启。设置为 0 时即为关闭。

### 为程序启用 ASLR

由于启用了 ASLR 后，程序的加载位置会随机变化，因此这还需要编译器的支持。GCC 可以通过使用 `-pie` 选项（默认开启）来生成位置无关的代码，从而使得程序能够支持 ASLR。使用 `-no-pie` 不会生成位置无关代码。这两种方式生成的可执行文件的信息是不同的：

```bash
dontpanic@Ubuntu:~$ gcc -no-pie test.c
dontpanic@Ubuntu:~$ file a.out
a.out: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=b6a30608d5278aba091e7f52f2a7fd25e7c745a9, not stripped
dontpanic@Ubuntu:~$
dontpanic@Ubuntu:~$
dontpanic@Ubuntu:~$ gcc -pie test.c
dontpanic@Ubuntu:~$ file a.out
a.out: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=75017e995c8e398060095542ea11b2bb1445a965, not stripped
dontpanic@Ubuntu:~$
```

在系统启用了 ASLR 时，通过 `/proc/PID/maps` 将可以看到，每次执行时程序所需要的动态库和堆栈空间的加载位置都不同。如果程序启用了 `-pie`，将会看到可执行文件自身的加载地址也会发生变化。

在 Windows 上，MSVC 的编译选项 `/DYNAMICBASE` 具有类似的效果。

{% include sidenote_begin.html %}
新版 GDB 在调试时会默认关闭被调试程序的 ASLR。可以通过命令 `set disable-randomization off` 重新启用。
{% include sidenote_end.html %}

### 绕过 ASLR

在某些情况下，我们可以绕过 ASLR 的防护。例如，

1. 如果缓冲区足够大，当希望跳转至缓冲区中执行指令时，可以尝试通过大量填充 `NOP` 使得跳转成功的机率增加。
1. 某个寄存器中的值刚好指向了我们需要的地址。
1. 通过某些方式泄露出动态库的加载地址。 {% related_challenge picoctf-2013-rop-3 %}
1. 2016 年的[一篇论文](http://www.cs.ucr.edu/~nael/pubs/micro16.pdf)指出，可以利用分支指令通过旁路探测出模块加载的地址。

### 内核地址空间随机化

内核同样可以开启 ASLR，这项技术在 Linux 中被称作 KASLR。但由于 [2018 年 Intel CPU 所暴露出的漏洞](https://www.zhihu.com/question/265012502/answer/288407097)，KASLR 不再安全。目前 KASLR 已被 KPTI（内核页表隔离）所取代。
