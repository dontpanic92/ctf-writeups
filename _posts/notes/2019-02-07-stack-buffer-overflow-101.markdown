---
layout: post
title: 栈缓冲区溢出 101
categories: notes
tags: binary
---

由于函数调用的自然特性，同时为了支持函数的递归调用，我们通常使用栈来保存函数局部信息的数据结构。例如，对于下面的 C 语言程序：

```{  .c .numberLines }
int func2()
{
    int c = 2;
    return c;
}

int func1(int val)
{
    int b = func2();
    return b + val;
}

int main(int argc, char* argv[])
{
    int a = func1(42);
    printf("%d\n", a);
    return 0;
}
```

{% graphviz %}
digraph g {
graph [rankdir = "LR"]
main [
    label = "<f0> int a = func1(42); | <f1> printf(\"%d\\n\", a); | <f2> return 0;"
    shape = "record"
    xlabel = "main 函数"
]
func1 [
    label = "<f0> int b = func2();| <f1> return b + val;"
    shape = "record"
    xlabel = "func1 函数"
]
func2 [
    label = "<f0> int c = 2;|<f1> return c;"
    shape = "record"
    xlabel = "func2 函数"
]
printf [
    label = "<f0> ... | <f1> ..."
    shape = "record"
    xlabel = "printf 函数"
]
main:f0 -> func1:f0
func1:f0 -> func2:f0 [ label=" " ]
func2:f1 -> func1:f1 [ label=" " ]
func1:f1 -> main:f1
main:f1 -> printf:f0
printf:f1 -> main:f2
}
{% endgraphviz %}

当 `main` 调用 `func1` 时，我们需要一块内存来存放 `func1` 的局部变量和参数等信息；当 `func1` 调用 `func2` 时，还需要一块内存来存放 `func2` 的局部信息；而 `func2` 返回时，`func2` 的局部信息就不再使用可以丢弃了；而当 `func1` 返回时，用来存放 `func1` 的内存也不再需要了。这是一种典型的先进后出的情况，比较适合使用栈来描述：

![stack1]({% asset stack1.gif %})

#### 栈帧

上图中，每一个函数的局部信息所占据的栈空间就是一个栈帧（Stack Frame）。具体来说，一个栈帧的内容包括传递给函数的参数、函数的局部变量、调用函数后需需要跳转的地址、以及其他需要暂存的信息（例如寄存器的值）。以上面的程序为例，在 x86 平台上，进入 `func2` 函数后，一种可能的情况如下：

![func2_stackframes]({% asset func2_stackframes.png %})

通常来说，函数的执行中可能会不断地压入、弹出数据，栈顶指针（sp）就会不断地变化，因此栈帧的信息通常使用栈基址指针（bp）寄存器进行索引。从图中可以看出，bp 所指向的并不是栈帧的底部。bp 下方存放的是返回地址和函数的参数；bp 上方存放的是局部变量和其它临时信息。返回地址指明了函数返回后继续执行的位置，通常都是函数调用的下一条指令。

{% include sidenote_begin.html %}
一个函数的栈帧数据也有可能会使用 sp 进行索引，从而无需修改 bp 的值，也不需要将上层函数栈帧的基地址保存在栈中。
{% include sidenote_end.html %}

bp 寄存器中存储的为当前栈帧的基地址。当一个函数被调用时，就将上一个函数栈帧的基地址（即bp）压入内存，再把 bp 的值设置为自己的栈帧的基地址；当它返回时，就把 bp 的内容恢复为上一个函数的栈帧基地址。如此一来，bp 所指向的地址中的内容即为上一个栈帧的基地址；而上一个栈帧的基地址处存放的内容是更上一个栈帧的基地址……

#### 栈缓冲区溢出

当我们在栈上开辟了一段空间（例如一个局部变量数组）用作缓冲区时，如果没有对放入缓冲区的数据长度进行限制，就有有可能会发生缓冲区溢出。溢出后的直接后果就是将当前局部变量下方的内存内容进行了覆盖——例如覆盖了其他的局部变量、覆盖了上一个栈帧的基地址、或是覆盖了当前函数的返回地址，从而导致程序的执行出现问题或是崩溃。如果缓冲区的内容是被攻击者精心设计过的，程序就可能会去执行不该执行的逻辑，甚至会执行由攻击者提供的指令。

想要改变程序的执行流程，就需要改变那些能够影响程序执行的数据。返回地址是最典型的会影响执行流程的数据之一。如果我们将返回地址覆盖为其它地址，当函数返回时，程序就会跳转至我们设定好的地址上。例如，这段程序：

```{ .c .numberLines }
int func()
{
    char s[8];
    gets(s);
}
```

下图分别展示了输入“abcdefg”和输入“abcdefghijklmnopqrs”时的情况。可以看到，返回地址被其中几个字符`mnop`所覆盖。只要把这几个字符换成我们需要跳转的地址，即可让函数返回时跳转过去。

![stack-buffer-overflow]({% asset stack-buffer-overflow.png %})

除了返回地址，我们还可以：

- 覆盖 C++ 对象的虚表指针，让对象的虚表指针指向一个我们设计好的虚表上去。这样当这个 C++ 对象被多态地调用时，就会去查找我们设定好的虚表，进而执行我们需要的指令。
- 覆盖 Windows SEH 异常处理指针，当函数中发生异常时，就可以跳转到我们设定好的处理函数中去。

#### 跳转至缓冲区

由于我们可以让函数返回时跳转至任意地址，因此也可以在缓冲区中填放任意指令，再使函数返回至缓冲区内继续执行。这样就可以执行我们所需要的任意指令了。

#### 栈缓冲溢出防护措施

当指定了`/GS`编译选项，Visual C++ 的编译器会在每个栈帧的栈基址上方放入一个 Security Cookie。GCC 也有类似的机制并默认打开。在函数返回之前，编译器会插入一段检查逻辑；如果栈中的 Security Cookie 与另一个 Cookie 备份不一致的话，就中止程序的执行。

此外，大多数现代系统都有可执行空间保护，即取消栈所在内存的可执行属性，这样攻击者就难以注入自己的指令。

关于 SEH 异常处理函数，Windows 会拒绝跳转至栈中的地址。
