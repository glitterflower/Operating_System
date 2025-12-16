# Lab2 和 Lab5分支任务

## 分支任务：gdb 调试页表查询过程

我们主要是通过调试来观察 `qemu` 是如何一步步将虚拟地址翻译成物理地址的，在之前我们已经有了一些理论知识：`CPU` 访问内存时，硬件会先查 `TLB` 缓存获取地址映射；如果 `TLB` 未命中，则根据 `SATP` 寄存器自动逐级查询页表，找到物理页帧后完成访问，同时将该映射加入 `TLB` 以加速后续访问。

首先准备好带调试信息的 `qemu`，并修改 `Makefile` 文件，让它使用我们新编译的调试版 `qemu`。我们将同时使用两个 `gdb` 会话，一个调试 `qemu` 源码，一个调试 `ucore` 内核。

在终端1执行 `make debug` 启动 `qemu` 模拟器，在终端2找到进程的 `PID`，然后执行 `sudo gdb` 启动 `gdb` 并附加到这个进程，执行 `handle SIGPIPE nostop noprint` 忽略 `SIGPIPE`，避免被相关信号打断调试：

```c
(gdb) attach 30366
Attaching to process 30366
(gdb) handle SIGPIPE nostop noprint
```

我们不以访存指令为观察点，这样还要在 `ucore` 中一步步执行到某条访存指令，直接观察某个一定会被访问的地址的翻译过程，在 `qemu` 的关键代码处用这个虚拟地址打上条件断点，之后 `ucore` 执行的时候自然在这里停下。注意我们要观察分页机制启动后的地址，不然不会触发页表翻译，我们观察的是 `kern_init` 的虚拟地址  `0xffffffffc02000d8`。

执行 `info functions tlb` 和 `info functions get_physical` 查找处理TLB查找和页表遍历的主要函数：

```c
File /home/tianyi/qemu-4.1.1/target/riscv/cpu_helper.c:
435:    _Bool riscv_cpu_tlb_fill(CPUState *, vaddr, int, MMUAccessType, int, _Bool, uintptr_t);

File /home/tianyi/qemu-4.1.1/target/riscv/cpu_helper.c:
155:    static int get_physical_address(CPURISCVState *, hwaddr *, int *, target_ulong, int, int);
```

`riscv_cpu_tlb_fill` 是 `TLB` 查找失败后调用的函数，他会继续调用 `get_physical_address` 进行页表遍历，具体调用流程如下：

```plaintext
cpu_exec (#7)
  -> tb_find (#6) - 查找翻译块
    -> tb_htable_lookup (#3) - 查找翻译块哈希表
      -> get_page_addr_code (#2) - 获取代码页地址（这里会查TLB）
        -> tlb_fill (#1) - TLB填充（TLB miss时调用）
          -> riscv_cpu_tlb_fill (#0) - RISC-V特定的TLB填充
```

`TLB` 查找发生在 `get_page_addr_code` 中，如果 `TLB miss`，才会调用 `tlb_fill`，根据 `qmeu` 的架构选择对应的处理函数 `riscv_cpu_tlb_fill`。

在 `get_physical_address` 函数处打上条件断点，启动执行，之后该地址被访问时就可以具体观察地址翻译的过程：

```c
(gdb) break get_physical_address
Breakpoint 1 at 0x55f1b243de13: file /home/tianyi/qemu-4.1.1/target/riscv/cpu_helper.c, line 158.
(gdb) condition 1 addr == 0xffffffffc02000d8
(gdb) c
Continuing.
```

在终端3执行 `make gdb` 调试 `ucore` 内核，直接启动执行，终端2会在断点停下：

```c
Thread 2 "qemu-system-ris" hit Breakpoint 1, get_physical_address (
    env=0x55f1b4670060, 
    physical=0x7ff4fc8971f0, 
    prot=0x7ff4fc8971e4, 
    addr=18446744072637907160, 
    access_type=2, mmu_idx=1)
    at /home/tianyi/qemu-4.1.1/target/riscv/cpu_helper.c:158
158     {
```

这时已经停在函数的入口处，下面执行 `step` 观察虚拟地址 `0xffffffffc02000d8` 是如何一步步被翻译成物理地址的：

```c
(gdb) print vm
$2 = 8
(gdb) step
191               levels = 3; ptidxbits = 9; ptesize = 8; break;
(gdb) print i
$8 = 0
(gdb) print ptshift
$9 = 18
(gdb) print/x idx
$5 = 0x1ff
(gdb) print/x pte_addr
$6 = 0x80204ff8
(gdb) print/x pte
$18 = 0x200000cf
(gdb) print/x ppn
$19 = 0x80000
(gdb) print/x *physical
$22 = 0x80200000
(gdb) print *prot
$23 = 1
(gdb) print *prot
$24 = 5
(gdb) print *prot
$25 = 7
(gdb) print/x address
$21 = 0xffffffffc02000d8
```

地址分解：

```plaintext
VPN[2] = (0xffffffffc02000d8 >> 30) & 0x1FF = 0x1FF = 511
VPN[1] = (0xffffffffc02000d8 >> 21) & 0x1FF = 0x0
VPN[0] = (0xffffffffc02000d8 >> 12) & 0x1FF = 0x0
页内偏移 = 0xffffffffc02000d8 & 0xFFF = 0xd8
```

对于虚拟地址 `0xffffffffc02000d8`，在 `SV39` 模式下，`QEMU` 只遍历了第一级页表（`i=0`）。从 `satp` 提取页表基址后，计算第一级索引 `VPN[2]=511`（`0x1FF`），得到页表项地址 `0x80204ff8`。读取页表项 `0x200000cf`（有效且为叶子页表项，包含 `R/W/X` 权限），提取物理页号 `PPN=0x80000`，组合得到页对齐的物理地址 `0x80200000`，加上页内偏移 `0xd8` 得到完整物理地址 `0x802000d8`。权限位从 1（`PAGE_READ`）逐步设置为 7（`PAGE_READ|PAGE_WRITE|PAGE_EXEC`）。由于第一级页表项直接映射了 `1GB` 大页，无需继续遍历 `L1` 和 `L0`，翻译完成。页内偏移不需要被翻译和存储到 `TLB` 中，它会由硬件自动传递。

页表遍历成功后，`riscv_cpu_tlb_fill` 调用 `tlb_set_pag`e 更新 `TLB`：

```c
if (ret == TRANSLATE_SUCCESS) {
         tlb_set_page(cs, address & TARGET_PAGE_MASK, pa & TARGET_PAGE_MASK,
                      prot, mmu_idx, TARGET_PAGE_SIZE);
         return true;
     }
```

返回后，`get_page_addr_code` 重新获取 `TLB` 表项，此时应命中:

```c
if (!VICTIM_TLB_HIT(addr_code, addr)) {
            tlb_fill(env_cpu(env), addr, 0, MMU_INST_FETCH, mmu_idx, 0);
            index = tlb_index(env, mmu_idx, addr);
            entry = tlb_entry(env, mmu_idx, addr);
        }
        assert(tlb_hit(entry->addr_code, addr));

(gdb) print tlb_hit(entry->addr_code, addr)
$26 = true
```

## 分支任务：gdb 调试系统调用以及返回

这次我们来观察系统调用的完整流程，以 `ecall` 指令和 `sret` 指令为观测点，观察从用户态进入内核态再返回的过程。调试流程与 LAb2 基本一致，我们直接开始调试：

在终端1启动 `qemu` 模拟器，在终端2启动 `gdb` 并附加到这个进程上，执行 `handle SIGPIPE nostop noprint`，之后开始执行。在终端3启动 `ucore` 调试，首先加载用户程序符号表以调试用户程序，然后在用户库函数的 `syscall` 处打上断点，执行后会自动停在 `syscall` 函数处，查看附近的汇编代码，使程序执行到 `ecall` 指令处：

```c
<-file obj/__user_exit.out            
add symbol table from file "obj/__user_exit.out"
(y or n) y
Reading symbols from obj/__user_exit.out...
(gdb) b user/libs/syscall.c:18
Breakpoint 1 at 0x8000f8: file user/libs/syscall.c, line 19.
(gdb) c
Continuing.

Breakpoint 1, syscall (num=2)
    at user/libs/syscall.c:19
19          asm volatile (
(gdb) x/8i $pc
=> 0x8000f8 <syscall+32>:
    ld  a0,8(sp)
    ······
    ld  a5,72(sp)
   0x800104 <syscall+44>:       ecall
(gdb) until *0x800104
0x0000000000800104 in syscall (num=2)
    at user/libs/syscall.c:19
19          asm volatile (
(gdb) x/5i $pc
=> 0x800104 <syscall+44>:       ecall
   ······
   0x800110 <syscall+56>:       ret
```

在终端2中按 `Ctrl+C` 中断 `qemu` 执行，执行 `info functions ecall` 和 `info functions interrupt` 查找翻译 `ecall` 指令和处理中断的主要函数：

```c
File /home/tianyi/qemu-4.1.1/target/riscv/insn_trans/trans_privileged.inc.c:
21:     static _Bool trans_ecall(DisasContext *, arg_ecall *);

File /home/tianyi/qemu-4.1.1/target/riscv/cpu_helper.c:
503:    void riscv_cpu_do_interrupt(CPUState *);
```

`trans_ecall` 是 `QEMU TCG` 对 `RISC‑V ecall` 指令的翻译器：它不再生成后续指令的普通执行代码，而是调用 `generate_exception(ctx, RISCV_EXCP_U_ECALL)` 抛出一个 `U 级 ecall 异常`，后续真正的异常类型修正和特权级切换由  `riscv_cpu_do_interrupt` 在运行时完成。

在 `riscv_cpu_do_interrupt` 函数处打上断点，在这里停下后一步步观察这个异常是如何被处理的：

```c
(gdb) b riscv_cpu_do_interrupt
Breakpoint 1 at 0x55e8cfb30c87: file /home/tianyi/qemu-4.1.1/target/riscv/cpu_helper.c, line 507.
(gdb) c
Continuing.
[Switching to Thread 0x7f7141fff6c0 (LWP 8884)]

Thread 2 "qemu-system-ris" hit Breakpoint 1, riscv_cpu_do_interrupt (
    cs=0x55e8d1816650)
    at /home/tianyi/qemu-4.1.1/target/riscv/cpu_helper.c:507
507         RISCVCPU *cpu = RISCV_CPU(cs);

(gdb) p env->priv
$2 = 0
(gdb) p/x env->pc
$5 = 0x800104
(gdb) p env->priv
$12 = 1
(gdb) p env->scause
$13 = 8
(gdb) p/x env->sepc
$14 = 0x800104
(gdb) p env->sbadaddr
$15 = 0
(gdb) p/x env->pc
$16 = 0xffffffffc0200ea4
(gdb) x/i 0xffffffffc0200ea4
   0xffffffffc0200ea4 <__alltraps>:
    csrrw       sp,sscratch,sp
```

`riscv_cpu_do_interrupt` 先识别出这是一个来自 U 态的同步异常 `ecall`，然后用当前特权级 `env->priv=0` 把它映射为 U 模式的 `ecall` 异常号，并检查委托寄存器决定由 S 态处理。接着，它更新 `mstatus` 中 S 相关位、将 `env->scause` 设为 8（U‑mode ecall）、把陷入前的 PC `0x800104` 保存到 `env->sepc`，`sbadaddr` 保持为 0，并把 `env->pc` 改成 `stvec` 对应的内核 `trap` 入口地址 `0xffffffffc0200ea4`，同时切换特权级到 S 模式，从而完成“U 态发起系统调用 → 跳转到内核 `trap` 入口”的硬件行为模拟。

在终端3使程序执行到 `sret` 指令处，在终端2中执行执行 `info functions sret` 查找翻译和处理 `sret` 指令的主要函数：

```c
(gdb) until *0x800110
0x0000000000800110 in syscall (num=2)
    at user/libs/syscall.c:31
31          return ret;

File /home/tianyi/qemu-4.1.1/target/riscv/insn_trans/trans_privileged.inc.c:
43:     static _Bool trans_sret(DisasContext *, arg_sret *);

File /home/tianyi/qemu-4.1.1/target/riscv/op_helper.c:
74:     target_ulong helper_sret(CPURISCVState *, target_ulong);
```

`trans_sret` 是 `QEMU TCG` 对 `sret` 指令的翻译器：它先把当前 TB（翻译块） 的下一条 PC 写入 `cpu_pc`，然后生成一个对 `gen_helper_sret(cpu_pc, cpu_env, cpu_pc)` 的调用，并用 `exit_tb` 和 `DISAS_NORETURN` 标记“执行到这里就离开当前 TB，由 `helper` 决定下一步跳到哪里”。

在 `helper_sret` 函数处打上断点，在这里停下后一步步观察 `sret` 指令是如何执行的：

```c
(gdb) b helper_sret
Breakpoint 1 at 0x56172b96c256: file /home/tianyi/qemu-4.1.1/target/riscv/op_helper.c, line 76.
(gdb) c
Continuing.
[Switching to Thread 0x7f8af49706c0 (LWP 13367)]

Thread 2 "qemu-system-ris" hit Breakpoint 1, helper_sret (env=0x56172e013060, 
    cpu_pc_deb=18446744072637910890)
    at /home/tianyi/qemu-4.1.1/target/riscv/op_helper.c:76
76          if (!(env->priv >= PRV_S)) {

(gdb) p env->priv
$1 = 1
(gdb) p/x env->sepc
$2 = 0x800108
(gdb) p/x env->mstatus
$3 = 0x8000000000046020
(gdb) p/x retpc
$5 = 0x800108
(gdb) p/x env->mstatus
$9 = 0x8000000000046002
(gdb) p env->priv
$14 = 0
```

`helper_sret` 在 S 态（`env->priv = 1`）被调用后，先从 `env->sepc` 取出返回地址 `retpc = 0x800108`——这正好是用户态 `ecall`（位于 `0x800104`）的下一条指令地址。随后它读取当前 `mstatus = 0x8000000000046020`，从中取出保存的上一特权级 `SPP`，用 `SPIE` 恢复 `SIE`、清零 `SPIE`，把 `SPP` 改成 U（于是 `mstatus` 变为 `0x8000000000046002`），再调用 `riscv_cpu_set_mode(env, prev_priv)` 把 `env->priv` 从 1 切回 0（S→U），最后返回 `retpc = 0x800108` 给 QEMU，CPU 随后就从这条“ecall 的下一条用户指令”继续执行，实现从内核 S 态安全返回到用户态。
