# Lab1
李天一（2313743） 王湜蔚（2313804） 黄尚扬（2313911）

## 练习1
1. la sp, bootstacktop **操作**：把bootstacktop的地址加载到sp寄存器 **目的**：为内核建立栈空间，使后续函数调用能够正常执行。
2. tail kern_init **操作**：尾调用跳转，直接跳转到内核函数kern_init 而不保存返回地址 **目的**：将控制权移交内核，减少一次内存写入，节省栈空间，避免写入返回地址会改变sp的问题。

## 练习2
### 调试过程：
首先同时运行make debug和make gdb指令，然后输入x/5i $pc查看最初的5条指令：
```assembly
0x1000:      auipc   t0,0x0     # t0 = 0x1000
0x1004:      addi    a1,t0,32   # a1 = 0x1020
0x1008:      csrr    a0,mhartid # a0 = 0x0
0x100c:      ld      t0,24(t0)  # t0 = [0x1018] = 0x80000000
0x1010:      jr      t0         # PC = 0x80000000
```
使用si从地址0x1000开始单步执行汇编代码，发现寄存器的变化和我们的计算结果相同。

pc跳转后，继续查看之后的指令，发现跳转到0x80200000之前有大量的代码。使用b* kern_entry在内核的入口地址打上断点，输入c执行到断点，输出结果如下，说明OpenSBI已经完成初始化，下面将执行内核代码。
```
OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
```

此时pc为0x80200000，输入x/5i $pc查看附近的指令：
```assembly
0x80200000 <kern_entry>:     auipc   sp,0x3 # sp = 0x80203000
0x80200004 <kern_entry+4>:   mv      sp,sp  # addi sp,sp,0
0x80200008 <kern_entry+8>:   j       0x8020000a <kern_init>
```
auipc   sp,0x3和mv      sp,sp对应la sp, bootstacktop，因为RISC-V 不能一次性装绝对地址（32位），所以分为两步（20位+12位）：先通过auipc获取高20位0x80203，然后通过addi加上低12位偏移量0，把栈顶地址0x80203000装入sp寄存器。

j       0x8020000a <kern_init>对应tail kern_init，无返回跳转到 kern_init函数的代码。

之后将继续执行kern_init函数：清空bss段，打印启动信息：(THU.CST) os is loading ...，进入主循环。

### 回答：
RISC-V 硬件加电后最初执行的几条指令和地址如下：
```assembly
0x1000:      auipc   t0,0x0     
0x1004:      addi    a1,t0,32   
0x1008:      csrr    a0,mhartid 
0x100c:      ld      t0,24(t0)   
0x1010:      jr      t0         
```

auipc   t0,0x0 将t0的值设为当前pc的值，为后续的内存访问提供基址。
addi    a1,t0,32 将a1的值设为t0+32,即将设备树地址赋值给a1。
csrr    a0,mhartid 将a0的值设为0,即将当前核心的id赋值给a0。
ld      t0,24(t0)  将OpenSBI的入口地址放到t0。
jr      t0 跳转到OpenSBI 的入口，开始固件阶段的初始化。
这几条指令完成了硬件初始化和固件启动，完成最基本的环境准备，并将控制权交给OpenSBI。