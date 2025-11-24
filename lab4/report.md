# Lab4

## 练习1

`alloc_proc` 函数分配并初始化一个进程控制块，初始化进程控制块 `proc_struct` 的代码如下：

```c
proc->state = PROC_UNINIT; // 进程状态：未初始化
proc->pid = -1; // 进程ID：无效值
proc->runs = 0; // 运行次数：0
proc->kstack = 0; // 内核栈：尚未分配
proc->need_resched = 0; // 不需要重新调度
proc->parent = NULL; // 无父进程
proc->mm = NULL; // 内存管理：空
memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
proc->tf = NULL; // 中断帧：空
proc->pgdir = boot_pgdir_pa; // 使用内核页目录表的基址
proc->flags = 0; // 进程标志位：0
memset(proc->name, 0, PROC_NAME_LEN); // 进程名：空字符串
```

`struct context context` 保存了进程执行的上下文，在 `proc.h` 中定义，包含了`ra`，`sp`，`s0~s11`共14个被调用者保存寄存器，用于在进程切换中还原之前进程的运行状态，在本实验中主要用于 `switch_to` 函数：

```c
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
    STORE sp, 1*REGBYTES(a0)
    STORE s0, 2*REGBYTES(a0)
    STORE s1, 3*REGBYTES(a0)
    ······
    STORE s11, 13*REGBYTES(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
    LOAD sp, 1*REGBYTES(a1)
    LOAD s0, 2*REGBYTES(a1)
    ······
    LOAD s11, 13*REGBYTES(a1)

    ret
```

`switch_to` 函数保存当前进程的上下文，恢复新进程的上下文。函数参数分别是当前进程的执行现场 `proc_struct* from`（存储在 `a0` 中） 和 新进程的执行现场 `proc_struct* to`（存储在 `a1` 中），函数执行完之后就可以切换到新进程的环境继续运行。

`struct trapframe *tf` 指向该进程内核栈顶部保存的一整块中断异常现场，在 `trap.h` 中定义，包含了32个通用寄存器和异常相关寄存器，当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中，但在本实验中需要手动创建内核线程，没有 `trap` 时自动保存的 `trapframe`，所以我们需要自己创建中断帧。

`tf` 在本实验中主要用于 `kernel_thread` 和 `copy_thread` 函数。`kernel_thread` 函数为新的内核线程创建一个初始化好的中断帧，之后将中断帧的指针传递给 `do_fork` 函数，而 `do_fork` 函数会调用 `copy_thread` 函数来在新创建的进程内核栈上专门给进程的中断帧分配一块空间，进程在第一次调度时会调用 `forkret` 函数将 `trapframe` 中的数据写入寄存器中，最后返回到 `epc` 中的地址 `kernel_thread_entry` 开始执行。

## 练习2

`do_fork` 函数为新创建的内核线程分配资源，处理过程的代码如下：

```c
// 1.分配并初始化进程控制块（alloc_proc函数）
if ((proc = alloc_proc()) == NULL) {
    goto fork_out;
}
// 2.分配并初始化内核栈（setup_stack函数）
if (setup_kstack(proc) != 0) {
    goto bad_fork_cleanup_proc;
}
// 3.根据clone_flags决定是复制还是共享内存管理系统（copy_mm函数）
if (copy_mm(clone_flags, proc) != 0) {
    goto bad_fork_cleanup_kstack;
}
// 4.设置进程的中断帧和上下文（copy_thread函数）
copy_thread(proc, stack, tf);
// 5.把设置好的进程加入链表
proc->pid = get_pid();
hash_proc(proc);
list_add(&proc_list, &(proc->list_link));
nr_process++;
// 6.将新建的进程设为就绪态
wakeup_proc(proc);
// 7.将返回值设为线程id
ret = proc->pid;
```

如果前3步执行没有成功，则需要做对应的出错处理，把相关已经占用的内存释放掉：

```c
fork_out:
    return ret;
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
```

`alloc_proc` 失败后由于还没有分配内存直接返回，`setup_stack` 失败后清理 `proc` 结构体并返回，`copy_mm` 失败后释放内核栈，然后清理 `proc` 结构体并返回。

`ucore` 能够给每个新 `fork` 的线程分配唯一的 `id`，因为 `get_pid` 函数中实现了不重复的 `PID` 分配算法：

```c
if (++last_pid >= MAX_PID) {
    last_pid = 1;
    goto inside;
}
if (last_pid >= next_safe) {
inside:
    next_safe = MAX_PID;
repeat:
    le = list;
    while ((le = list_next(le)) != list) {
        proc = le2proc(le, list_link);
        if (proc->pid == last_pid) {
            if (++last_pid >= next_safe) {
                if (last_pid >= MAX_PID) {
                    last_pid = 1;
                }
                next_safe = MAX_PID;
                goto repeat;
            }
        }
        else if (proc->pid > last_pid && next_safe > proc->pid) {
            next_safe = proc->pid;
        }
    }
}
```

`last_pid` 记录上次分配的 `PID`，`next_safe` 记录安全分配的上限， `[last_pid, next_safe)` 是安全范围，里面都是没有用过的 `PID`。每次尝试从 `++last_pid` 开始分配，如果在安全范围内直接返回；超过 `MAX_PID` 后重置为1，从头开始分配；超过  `next_safe` 后更新安全范围，扫描所有进程，如果 `last_pid` 与其他进程的 `PID` 重复，则尝试分配 `++last_pid`，如果仍不在安全范围或超过 `MAX_PID` ，重复之前的处理过程；如果没有重复则直接更新安全范围并返回 `last_pid`。`get_pid` 的检查机制确保了每个线程的 `ID` 是唯一的。

## 练习3

`proc_run` 函数将指定的进程切换到 `CPU` 上运行，函数代码如下：

```c
void proc_run(struct proc_struct *proc)
{
    if (proc != current)
    {
        bool intr_flag; 
        struct proc_struct *curr = current;

        local_intr_save(intr_flag); // 禁用中断
        {
            current = proc;
            lsatp(proc->pgdir);
            switch_to(&(curr->context), &(proc->context));
        }
        local_intr_restore(intr_flag); // 允许中断
    }
}
```

如果要切换的进程 `proc` 不是当前正在运行的进程 `current`，使用 `*curr` 保存当前进程，关闭中断防止进程切换过程被中断打扰，更新当前进程为要切换的进程，切换页表让 `CPU` 使用新进程的地址空间，调用 `switch_to` 函数切换上下文，最后打开中断。

在本实验的执行过程中，创建且运行了2个内核线程：`idleproc` 和`initproc`。`idleproc` 是空闲线程，在 `proc_init()` 中直接通过 `alloc_proc()` 创建并初始化，执行时若 `need_resched` 为1，就调用 `schedule` 函数要求调度器切换其他进程执行，当没有其他线程可运行时，`CPU` 才会执行此线程。`initproc` 是初始化线程，在 `proc_init()` 中通过 `kernel_thread(init_main, "Hello world!!", 0)` 创建，执行 `init_main` 函数，打印提示信息。

完成代码编写后，执行 `make qemu` 编译并运行代码，输出结果如下：

```c
check_alloc_page() succeeded!
check_pgdir() succeeded!
check_boot_pgdir() succeeded!
use SLOB allocator
kmalloc_init() succeeded!
check_vma_struct() succeeded!
check_vmm() succeeded.
alloc_proc() correct!
++ setup timer interrupts
this initproc, pid = 1, name = "init"
To U: "Hello world!!".
To U: "en.., Bye, Bye. :)"
kernel panic at kern/process/proc.c:378:
    process exit!!.

Welcome to the kernel debug monitor!!
Type 'help' for a list of commands.
```

## Challenge 1

`local_intr_save(intr_flag); … local_intr_restore(intr_flag);` 利用 `sync.h` 中的两个内联函数实现“保存当前中断状态 → 关闭中断 → 按需恢复中断”：

`local_intr_save(flag)` 展开后调用 `__intr_save()`：读取 `sstatus` 寄存器，若检测到全局中断使能位 `SSTATUS_SIE` 置 1，则调用 `intr_disable()` 关中断，并返回 1；否则返回 0。这样 `flag` 就记住了“进入临界区前中断是否开启”。

退出临界区时执行 `local_intr_restore(flag)`，展开为 `__intr_restore(flag)`：只有当 `flag` 为 1（即之前确实关过中断）时才调用 `intr_enable()`，把中断状态恢复为进入前的样子；若原本就是关闭状态，就保持不变。

## Challenge 2

`sv32、sv39、sv48` 都是基于多层页表实现的虚拟地址映射方式，分别对应2、3、4级页表。`get_pte()` 中的实现是 `sv39` 的三级页表特例。这两段代码相似的原因是其都在访问某一层页表并试图向下搜索所需地址页。

目前 `get_pte()` 函数将页表项的查找和页表项的分配合并在一个函数里，我认为是好的写法。因为在调用时无需关心其存在性；并且由于页表项的分配也依托于遍历，所以如此写可以避免代码冗余。
