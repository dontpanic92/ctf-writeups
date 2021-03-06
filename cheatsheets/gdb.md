---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

layout: page
title: GDB Cheatsheet
categories: cheatsheets
---

#### 运行

- `gdb -p PID`
    - Attach

- `r program`
    - 运行 `program`

- `r program < <(bash_commands)`
    - 将 `bash_commands` 的 stdout 输入至 `program` 的 stdin

- `finish`
    - 运行至返回

----

#### 断点

- `b func`
    - 在函数 `func` 入口处下断点
- `b *0xABCD`
    - 在地址 `0xABCD` 处下断点

----

#### 调用栈

- `bt`
    - 显示 backtrace

----

#### 调试
- `ni`
    - 单步 Step Over 一句汇编代码
- `si`
    - 单步 Step Into 一句汇编代码

----

#### 数据
- `x` 显示指定位置内存
    - `x/s` 字符串
    - `x/40xb` 40 字节
- `info proc map`
    - 显示各个模块映射情况
- `find 0x80048000, 0xc0000000, "/bin/sh"`
    - 搜索内容
- `set {int}0x83040 = 4`
    - 写内存

----

#### 设置
- `set disable-randomization off`
    - 启用 ASLR