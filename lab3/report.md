# Lab3

## 练习1-黄尚扬（2313911）
首先需要include一个sbi.h，而后主体代码部分如下：

```
clock_set_next_event();
            static int num = 0;
            ticks++;
            if (ticks == TICK_NUM) {
                print_ticks();
                ticks = 0;
                num++;
                if (num == 10) {
                    sbi_shutdown();
                }
            }
            break;

```

实现过程：num记录输出次数，并且采用clock_set_next_event()设置下次时钟中断时间；ticks自增定时，每100tick就输出一次；当num==10就关机。


当硬件定时器触发中断时，CPU 自动跳转至陷阱入口，保存当前寄存器现场后进入 trap() 函数。系统读取 scause 来判断为定时器中断后，调用 clock_set_next_event() 设置下一次中断时间，并更新系统时钟或触发调度操作。中断处理结束后恢复寄存器状态，通过 sret 返回原程序继续执行，从而实现了周期性的定时器中断响应。

## 扩展练习1-王湜蔚（2313804）

`mov a0, sp` 的目的：将栈指针（指向保存所有寄存器的 `trapframe`）作为第一个参数传递给 `C` 处理函数 `trap`。

`SAVE_ALL` 保存位置确定：通过 `addi sp, sp, -36 * REGBYTES` 在栈上分配空间。按预定义的 `trapframe` 结构体布局，通过固定偏移量保存每个寄存器。

是否需要保存所有寄存器：是的。这样是为了保证处理程序的通用性、上下文完整性和可重入性。

## 扩展练习2-王湜蔚（2313804）

`csrw sscratch, sp` 将当前栈指针暂存至 `sscratch` 寄存器， `csrrw s0, sscratch, x0` 将其转存到 `s0` 并清空 `sscratch`，为可能的嵌套异常提供判断依据。这两条指令共同完成了栈指针的安全保存和异常来源标识。

`stval、scause` 等寄存器记录的是触发当前异常的具体原因和附加信息，属于瞬时状态而非线程的持久上下文。保存它们是为了供异常处理程序分析使用，但由于这些值仅对当前异常有效，异常返回时无需恢复，新的异常会自然更新这些寄存器。

意义在于确保了异常处理的完整性，又避免了不必要的状态恢复开销。

## 扩展练习3-李天一（2313743）

完善非法指令异常处理和断点异常处理的代码：

```c
case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB3 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type: Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
            tf->epc += 4; 
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB3 CHALLLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存
             器
            */
            cprintf("Exception type: breakpoint\n");
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
            tf->epc += 4;
            break;
```

写两条指令来测试我们的异常处理逻辑：

```c
asm(".word 0x00000000"); // 非法指令 
asm("ebreak"); // 中断指令
```

`idt_init()` 函数设置 `stvec` 寄存器的值为 `__alltraps` （异常处理入口地址），触发异常时告诉 `CPU` 应该跳转到哪里去处理异常，所以异常指令至少要加在 `idt_init()` 函数之后。

执行 `make qemu` 指令后正确输出异常类型和异常指令触发地址：

```c
Exception type: Illegal instruction
Illegal instruction caught at 0xc020009c
Exception type: breakpoint
ebreak caught at 0xc02000a0
```
