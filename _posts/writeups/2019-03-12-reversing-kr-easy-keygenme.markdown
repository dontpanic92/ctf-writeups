---
layout: post
title: Easy KeygenMe
categories: writeups
tags: reversing
ctfsite: reversing.kr
challenge_url: http://reversing.kr/challenge.php
---

题目要求 Find the Name when the Serial is 5B134977135E7D13：

![output]({% asset output.jpg %})

{% include writeup_begin.html %}

用 r2 载入看一下 “Input:” 的字符串的交叉引用，只有一个函数引用了。翻看一下，基本确定逻辑都在这个函数中。在输入了 `Name` 之后，程序会做一些计算：

```asm
|           0x0040105e      lea  edi, [local_18h] ; 0x18 ; 24
|           0x00401065      xor  eax, eax
|           0x00401067      add  esp, 8
|           0x0040106a      xor  ebp, ebp
|           0x0040106c      xor  esi, esi
|           0x0040106e      repne scasb al, byte es:[edi]
|           0x00401070      not  ecx
|           0x00401072      dec  ecx
|           0x00401073      test ecx, ecx
|       ,=< 0x00401075      jle  0x4010b6
|      .--> 0x00401077      cmp  esi, 3 ; 3
|     ,===< 0x0040107a      jl   0x40107e
|     |:|   0x0040107c      xor  esi, esi
|     `---> 0x0040107e      movsx ecx, byte [esp + esi + 0xc] ; [0xc:1]=255 ; 12
|      :|   0x00401083      movsx edx, byte [esp + ebp + 0x10] ; [0x10:1]=255 ; 16
|      :|   0x00401088      xor  ecx, edx
|      :|   0x0040108a      lea  eax, [local_74h] ; 0x74 ; 't' ; 116
|      :|   0x0040108e      push ecx
|      :|   0x0040108f      push eax
|      :|   0x00401090      lea  ecx, [local_7ch] ; 0x7c ; '|' ; 124
|      :|   0x00401094      push str.s_02X ; 0x408054 ; "%s%02X"
|      :|   0x00401099      push ecx
|      :|   0x0040109a      call fcn.00401150
|      :|   0x0040109f      add  esp, 0x10
|      :|   0x004010a2      inc  ebp
|      :|   0x004010a3      lea  edi, [local_10h] ; 0x10 ; 16
|      :|   0x004010a7      or   ecx, 0xffffffff
|      :|   0x004010aa      xor  eax, eax
|      :|   0x004010ac      inc  esi
|      :|   0x004010ad      repne scasb al, byte es:[edi]
|      :|   0x004010af      not  ecx
|      :|   0x004010b1      dec  ecx
|      :|   0x004010b2      cmp  ebp, ecx
|      `==< 0x004010b4      jl   0x401077
```

需要注意的是由于这个函数是 `esp` 寻址，有时 r2 给出的变量名是不对的。上面这段代码就是一段循环，写出伪代码如下：

```c

result = "";
esi = 0;

while(input[i] != 0)
{
    i++;

    if (esi == 3)
    {
        esi = 0;
    }
    c = {0x10, 0x20, 0x30}

    ecx = c[esi]
    edx = input[ebp]

    ecx = ecx ^ edx

    sprintf(result, "%s02X", result, ecx)

    ebp++
    esi++
}
```

计算好之后，程序直接将 SerialNumber 与计算结果进行字符串比较，相等就认为正确。因此用 python 算一下：

```python
>>> from operator import xor
>>> a = "\x5B\x13\x49\x77\x13\x5E\x7D\x13"
>>> b = [0x10, 0x20, 0x30]
>>> c = [chr(xor(b[i % 3], ord(a[i]))) for i in range(len(a))]
>>> c
```

就能够得到 flag 为 <flag>K3yg3nm3</flag>

{% include writeup_end.html %}
