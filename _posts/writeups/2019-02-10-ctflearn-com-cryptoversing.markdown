---
layout: post
title: Cryptoversing
categories: writeups
tags: reversing
ctfsite: ctflearn.com
challenge_url: https://ctflearn.com/problems/667
challenge_url_comment: 需要注册登录
---

将题目中的程序下载下来，运行后提示输入密码：

```
dontpanic@Win:~$ ./xor.bin
[*] Hello! Welcome to our Program!
Enter the password to contiune:  abcd
[-] Wrong Password
```

{% include writeup_begin.html %}

使用 Cutter 载入 `xor.bin`，照例先看一下字符串：

![strings]({% asset strings.png %})

看一下 Successful Login 的交叉引用，只在 `main` 函数里使用了。往上翻一翻，看起来所有的验证逻辑都在 `main` 函数中。首先看一下函数开始的部分：

```{ .asm .numberLines }
|           0x00000815      movabs rax, 0x4463457d4f625f68 ; 'h_bO}EcD'
|           0x0000081f      movabs rdx, 0x28687529472b524f ; 'OR+G)uh('
|           0x00000829      mov  qword [local_a0h], rax
|           0x00000830      mov  qword [local_98h], rdx
|           0x00000837      mov  dword [local_90h], 0x762c6c6a ; 'jl,v'
|           0x00000841      mov  byte [local_8ch], 0x4c ; 'L'
```

这里其实是在向 `local_a0h` (即 `$rbp-0xa0`) 进行字符串赋值。将几个字符串拼起来之后就是 `h_bO}EcDOR+G)uh(jl,vL`。需要注意的是这里没有设置字符串终止的 `\0`。

再往下就是计算的主要逻辑部分：

```{ .asm .numberLines }
|           0x0000087b      mov  dword [local_b8h], 0x10
|           0x00000885      mov  dword [local_b4h], 0x18
|           0x0000088f      lea  rax, [s]
|           0x00000893      mov  rdi, rax ; const char *s
|           0x00000896      call sym.imp.strlen ; size_t strlen(const char *s)
|           0x0000089b      shr  rax, 1
|           0x0000089e      mov  dword [local_b0h], eax
|           0x000008a4      lea  rax, [s]
|           0x000008a8      mov  rdi, rax ; const char *s
|           0x000008ab      call sym.imp.strlen ; size_t strlen(const char *s)
|           0x000008b0      mov  dword [local_ach], eax
|           0x000008b6      mov  dword [local_a8h], 0
|           0x000008c0      lea  rax, [s]
|           0x000008c4      mov  rdi, rax ; const char *s
|           0x000008c7      call sym.imp.strlen ; size_t strlen(const char *s)
|           0x000008cc      shr  rax, 1
|           0x000008cf      mov  dword [local_a4h], eax
|           0x000008d5      mov  dword [local_cch], 0
|       ,=< 0x000008df      jmp  0x968
|       |   0x000008e4      mov  eax, dword [local_cch]
|       |   0x000008ea      cdqe
|       |   0x000008ec      mov  eax, dword [rbp + rax*4 - 0xa8]
|       |   0x000008f3      mov  dword [local_c8h], eax
|      ,==< 0x000008f9      jmp  0x94a
|      ||   0x000008fb      mov  eax, dword [local_c8h]
|      ||   0x00000901      cdqe
|      ||   0x00000903      movzx eax, byte [rbp + rax - 0x60]
|      ::   0x00000908      movsx eax, al
|      ::   0x0000090b      mov  dword [local_bch], eax
|      ::   0x00000911      mov  eax, dword [local_cch]
|      ::   0x00000917      cdqe
|      ::   0x00000919      mov  eax, dword [rbp + rax*4 - 0xb8]
|      ::   0x00000920      mov  edx, eax
|      ::   0x00000922      mov  eax, dword [local_bch]
|      ::   0x00000928      xor  eax, edx
|      ::   0x0000092a      mov  byte [local_cdh], al
|      ::   0x00000930      mov  eax, dword [local_c8h]
|      ::   0x00000936      cdqe
|      ::   0x00000938      movzx edx, byte [local_cdh]
|      ::   0x0000093f      mov  byte [rbp + rax - 0x80], dl
|      ::   0x00000943      add  dword [local_c8h], 1
|      ::   0x0000094a      mov  eax, dword [local_cch]
|      ::   0x00000950      cdqe
|      ::   0x00000952      mov  eax, dword [rbp + rax*4 - 0xb0]
|      ::   0x00000959      cmp  dword [local_c8h], eax
|      `==< 0x0000095f      jl   0x8fb
|       :   0x00000961      add  dword [local_cch], 1
|       :   0x00000968      cmp  dword [local_cch], 1
|       `=< 0x0000096f      jle  0x8e4
```

仔细读一下这段代码，可以看出这是一个两层的循环。写出对应的 C 语言代码如下：

```{ .c .numberLines }
char* s; // s 中存放的是输入的字符串
int local_a8[2] = { 0, strlen(s) / 2 };
int local_b8[2] = { 0x10, 0x18 };
int local_b0[2] = { strlen(s) / 2, strlength };
char local_80[0x20];
int j, flag_2;

for (int i = 0; i <= 1; i++)
{
    j = local_a8[i];
    for (; j < local_b0[i]; j++)
    {
        flag_2 = s[j];
        local_80[j] = flag_2 ^ local_b8[i];
    }
}
```

可以看出，这段代码的基本操作就是把字符串的前半段与 `0x10` 异或、后半段与 `0x18` 异或，将结果存入 `local_80` 数组中。

再向下就是检查结果了：

```{ .asm .numberLines }
|           0x00000975      mov  dword [local_c4h], 0
|       ,=< 0x0000097f      jmp  0x9bf
|       |   0x00000981      mov  eax, dword [local_c4h]
|       |   0x00000987      cdqe
|       |   0x00000989      movzx edx, byte [rbp + rax - 0x80]
|       |   0x0000098e      mov  eax, dword [local_c4h]
|       |   0x00000994      cdqe
|       |   0x00000996      movzx eax, byte [rbp + rax - 0xa0]
|       |   0x0000099e      cmp  dl, al
|      ,==< 0x000009a0      je   0x9b8
|      ||   0x000009a2      lea  rdi, str.Wrong_Password ; 0xae0 ; "[-] Wrong Password" ; const char *s
|      ||   0x000009a9      call sym.imp.puts ; int puts(const char *s)
|      ||   0x000009ae      mov  edi, 0 ; int status
|      ||   0x000009b3      call sym.imp.exit ; void exit(int status)
|      `--> 0x000009b8      add  dword [local_c4h], 1
|       `-> 0x000009bf      mov  eax, dword [local_c4h]
|           0x000009c5      movsxd rbx, eax
|       :   0x000009c8      lea  rax, [local_a0h]
|       :   0x000009cf      mov  rdi, rax ; const char *s
|       :   0x000009d2      call sym.imp.strlen ; size_t strlen(const char *s)
|       :   0x000009d7      sub  rax, 1
|       :   0x000009db      cmp  rbx, rax
|       `=< 0x000009de      jb   0x981
|           0x000009e0      lea  rdi, str.Successful_Login ; 0xaf3 ; "[+] Successful Login" ; const char *s
|           0x000009e7      call sym.imp.puts ; int puts(const char *s)
```

写出对应的 C 语言代码如下：

```{ .c .numberLines }
char* str = "h_bO}EcDOR+G)uh(jl,vL"; // 上面初始化好的字符串

// 下面的 k < strlen(str) 在汇编代码中实际上写的是 k < strlen(str) - 1
// 通过调试发现，由于在 str 时没有赋值字符串结尾的 '\0'，导致字符串的实际长度要比
// "h_bO}EcDOR+G)uh(jl,vL" 长一个字节。
for (int k = 0; k < strlen(str); k++)
{
    if (str[k] != local_80[k])
    {
        puts("WrongPassword");
        exit(0);
    }
}

puts("Successful Login");
```

只是很简单的比较。因此我们将`h_bO}EcDOR+G)uh(jl,vL`的前半段与 0x10 异或，后半段与 0x18 异或：

```python
[chr(xor(ord(c), 0x10)) for c in "h_b0}EcDOR"]
[chr(xor(ord(c), 0x18)) for c in "+G)uh(jl,vL"]
```

这样就能够得到 flag 了。

{% include writeup_end.html %}
