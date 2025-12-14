# Lab5

## 练习1

## 练习2

创建子进程时会拷贝当前进程（父进程）的地址空间到新进程（子进程）中，补充 `copy_range` 函数中对此的实现：

```c
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share)
{
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    do
    {
        pte_t *ptep = get_pte(from, start, 0), *nptep;
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        if (*ptep & PTE_V)
        {
            if ((nptep = get_pte(to, start, 1)) == NULL)
            {
                return -E_NO_MEM;
            }
            uint32_t perm = (*ptep & PTE_USER);
            struct Page *page = pte2page(*ptep);
            struct Page *npage = alloc_page();
            assert(page != NULL);
            assert(npage != NULL);
            int ret = 0;
            // (1) 获取源页面的内核虚拟地址
            void *src_kvaddr = page2kva(page);
            // (2) 获取目标页面的内核虚拟地址  
            void *dst_kvaddr = page2kva(npage);
            // (3) 复制整个页面
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
            // (4) 建立子进程的页表映射
            ret = page_insert(to, npage, start, perm);
            assert(ret == 0);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}
```

`do_fork` 函数创建子进程时，会调用 `copy_mm` 复制内存管理结构，`dup_mmap` 复制虚拟内存映射，`copy_range` 复制页面内容。

`copy_range` 负责将父进程（进程A）的一段地址空间 `[start, end)` 的内容复制到子进程（进程B）的对应地址空间。首先检查 `start` 和 `end` 是否页对齐，检查 `[start, end)` 是否在用户空间范围内，确保复制的地址是用户空间地址，不是内核空间。然后按页为单位复制内容（从起始地址开始，每次循环增加一页大小）：调用 `get_pte` 函数根据地址 `start` 查找父进程的 `PTE`（页表项），`*ptep` 指向父进程页表项，`*nptep` 指向子进程页表项；返回页表项为空说明父进程在这个地址没有页表映射，将地址对齐到下一个 `2MB` 边界，跳过这部分未映射的地址空间；同样调用 `get_pte` 函数获取子进程的页表项，如果页表项不存在直接创建新页表；提取父进程页面的权限位，获取父进程的物理页面，为子进程分配新页面。

之后是实验需要完成的四个步骤：找到源页面和目标页面的内核虚拟地址，因为内核可以直接读写物理页面内容，将父进程页面的全部内容复制到子进程的新页面，在子进程页表中建立 `start->npage` 的映射关系。

我们目前实现的是直接复制，创建子进程时立即复制所有页面内容，而写时复制 `Copy on Write` 开始只需要获得一个指针来共享页面，进行写操作时才会复制页面内容获得自己的私有页面。

下面简要设计一下如何实现 `Copy on Write` 机制：在 `fork` 时，父子进程共享可写页面的物理页，并将父进程和子进程的页表项都标记为只读+`COW`；只读页面（如代码段）直接共享，不标记 `COW`。当某个进程对 `COW` 页面执行写操作时，触发 `STORE_PAGE_FAULT`，`do_pgfault` 检测到 `COW` 标记后：若引用计数 > 1，分配新页并复制内容，更新当前进程的页表项指向新页并恢复写权限；若引用计数 = 1，直接移除 `COW` 标记并恢复写权限。通过页面引用计数管理共享，仅在真正写入时才复制，减少内存占用并提升 `fork` 效率。

## 练习3

### 1. 用户态与内核态分工

**fork操作**：用户态仅负责调用 `fork()` 函数和接收返回值，而内核态承担了进程控制块分配、内存空间复制、上下文设置、进程关系建立等核心工作。

**exec操作**：用户态负责准备可执行文件路径、命令行参数和环境变量等参数，内核态则进行文件权限验证、ELF格式解析、内存空间重建、执行上下文重置等复杂操作。

**wait操作**：用户态指定等待选项和状态存储位置，内核态执行进程状态检查、进程阻塞与唤醒、资源回收、状态信息复制等工作。

**exit操作**：用户态传递退出状态码，内核态执行全面的资源清理，包括内存释放、文件关闭、状态转换、进程关系调整等。

### 2. 内核态与用户态交错执行机制

内核态与用户态的交错执行主要通过中断和系统调用机制实现。当用户程序需要内核服务时，通过执行 `int 0x80` 指令触发软中断，`CPU` 自动保存当前上下文并切换到内核态。内核的trap处理函数接管控制权，根据系统调用号分发到相应的处理函数。内核完成服务后，通过修改当前进程中断帧的寄存器值设置返回结果，最后执行 `iret` 指令恢复用户态上下文继续执行。

在进程管理场景中，这种交错表现出特定模式：例如在 `wait` 调用中，用户进程在内核中主动进入睡眠状态，此时内核调度其他进程执行，形成用户态→内核态（阻塞）→其他用户态的切换；在 `fork` 调用中，内核创建新进程后将其加入就绪队列，后续由调度器决定何时切换到子进程执行，形成父子进程在用户态的交替执行。整个交错过程由内核严格管控，确保每次状态切换的原子性和上下文完整性。

### 3. 内核执行结果返回机制

内核执行结果主要通过三种方式返回给用户程序：

第一，通过寄存器返回值，这是最基本且高效的方式。内核在处理系统调用结束时，将返回值设置到当前进程中断帧的 `eax` 寄存器中，当执行 `iret` 指令返回用户态时，该值自然成为用户程序的函数返回值。例如fork系统调用中，父进程获取子进程 `PID`，子进程获取0值。

第二，通过用户空间指针传递数据，适用于需要返回大量数据的场景。内核通过 `copy_to_user()` 等安全函数将数据复制到用户程序提供的缓冲区中，如 `wait` 系统调用中将子进程退出状态复制到用户指定的存储位置。这种方式需要内核严格验证用户指针的有效性和安全性。

第三，通过执行流重定向，这是 `exec` 系统调用的特殊机制。内核不按原路返回，而是修改中断帧的程序计数器指向新程序的入口地址，使 `iret` 返回到全新的执行流中。这种方式实现了程序执行的彻底切换，原程序的上下文被完全替换。

这些返回机制共同构成了用户程序与内核交互的完整通道，既保证了执行效率，又确保了系统的安全性和稳定性。

一个用户态进程的执行状态生命周期图如下：

```plaintext
                            [创建]
                              │
                              │ alloc_proc()
                              ▼
                    ┌─────────────────┐
                    │  PROC_UNINIT    │ ← 初始状态
                    └────────┬────────┘
                             │
                             │ wakeup_proc()
                             ▼
                    ┌─────────────────┐
                    │ PROC_RUNNABLE   │ ← 就绪状态
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        │ schedule()选择执行  │                    │ do_wait()/do_sleep()
        │                    │                    │
        ▼                    │                    ▼
┌───────────────┐           │           ┌─────────────────┐
│ PROC_RUNNING  │           │           │ PROC_SLEEPING   │ ← 阻塞状态
│  (执行状态)   │           │           └────────┬────────┘
└───────┬───────┘           │                    │
        │                   │                    │
        │ 时间片用完        │                    │ 资源就绪/事件完成
        │ 或被抢占          │                    │ wakeup_proc()
        │                   │                    │
        ▼                   │                    ▼
┌───────────────┐◄──────────┘           ┌─────────────────┐
│ PROC_RUNNABLE │                       │ PROC_RUNNABLE   │
└───────┬───────┘                       └─────────────────┘
        │
        │ do_exit()
        │ 或程序结束
        ▼
┌───────────────┐
│ PROC_ZOMBIE   │ ← 僵尸状态
└───────┬───────┘
        │
        │ 父进程执行 do_wait()回收
        ▼
    [进程终止]
```

## 扩展练习1

通过 `share` 标志决定使用写时复制（`share=1`）还是直接复制（`share=0`）。添加一个 `COW` 的标志位来标记写时需要复制的页面：

```c
#define PTE_COW  0x100 // Copy-on-Write flag
```

在 `copy_range` 函数中处理如下：

```c
// COW: share page, mark as read-only + COW
if (perm & PTE_W) {
    // Writable page: apply COW
    page_ref_inc(page);
    // Parent: remove write, keep read/exec, add COW
    *ptep = (*ptep & ~PTE_W) | PTE_COW;
    tlb_invalidate(from, start);
    // Child: same page, read-only + COW (keep R/X/U/V)
    uint32_t cow_perm = (perm & ~PTE_W) | PTE_COW;
    ret = page_insert(to, page, start, cow_perm);
} else {
    // Read-only page: just share (no COW needed)
    page_ref_inc(page);
    ret = page_insert(to, npage, start, perm);
    }
```

对于可写页面：父子共享同一物理页，父进程和子进程的 `PTE` 都标记为只读+`COW`，增加引用计数;而只读页面直接共享就可以。

遇到 `CAUSE_FETCH_PAGE_FAULT`、
`CAUSE_LOAD_PAGE_FAULT` 和 `CAUSE_STORE_PAGE_FAULT` 三种缺页异常时，调用 `do_pgfault` 函数进行处理：

```c
if (current != NULL && current->mm != NULL)
{
    if (do_pgfault(current->mm, tf->cause, tf->tval) != 0)
    {
        do_exit(-E_KILLED);
    }
}
```

实现缺页异常处理函数 `do_pgfault`：

```c
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    // Check···
    
    // Case 1: Page exists
    if (*ptep & PTE_V)
    {
        // COW: only handle write fault on COW pages
        if ((*ptep & PTE_COW) && (error_code == CAUSE_STORE_PAGE_FAULT))
        {
            struct Page *page = pte2page(*ptep);
            int ref = page_ref(page);
            
            if (ref > 1)
            {
                // Multiple references: copy the page
                struct Page *new_page = alloc_page();
                if (new_page == NULL)
                {
                    return -E_NO_MEM;
                }
                
                memcpy(page2kva(new_page), page2kva(page), PGSIZE);
                page_ref_dec(page);
                
                uint32_t perm = (*ptep & PTE_USER) & ~PTE_COW;
                page_remove_pte(mm->pgdir, addr, ptep);
                page_insert(mm->pgdir, new_page, addr, perm | PTE_W);
                return 0;
            }
            else
            {
                // Only one reference: just remove COW and restore write
                *ptep = (*ptep & ~PTE_COW) | PTE_W;
                tlb_invalidate(mm->pgdir, addr);
                return 0;
            }
        }
        
        // Page exists but not COW write fault
        // For FETCH/LOAD faults, check if page has correct permissions
        if (error_code == CAUSE_FETCH_PAGE_FAULT)
        {
            // Instruction fetch: need execute permission
            if (*ptep & PTE_X)
            {
                // Has execute permission but faulted - TLB issue
                tlb_invalidate(mm->pgdir, addr);
                return 0;
            }
            return -E_INVAL;
        }
        else if (error_code == CAUSE_LOAD_PAGE_FAULT)
        {
            // Data load: need read permission
            if (*ptep & PTE_R)
            {
                // Has read permission but faulted - TLB issue
                tlb_invalidate(mm->pgdir, addr);
                return 0;
            }
            return -E_INVAL;
        }
        else if (error_code == CAUSE_STORE_PAGE_FAULT)
        {
            // Data store: need write permission
            if (*ptep & PTE_W)
            {
                // Has write permission but faulted - TLB issue
                tlb_invalidate(mm->pgdir, addr);
                return 0;
            }
            return -E_INVAL;
        }
        
        return -E_INVAL;
    }
    
    // Case 2: Page doesn't exist - allocate new page
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) perm |= PTE_W;
    if (vma->vm_flags & VM_READ) perm |= PTE_R;
    if (vma->vm_flags & VM_EXEC) perm |= PTE_X;
    
    struct Page *page = pgdir_alloc_page(mm->pgdir, addr, perm);
    if (page == NULL)
    {
        return -E_NO_MEM;
    }
    
    return 0;
}
```

检测到 `COW` 页面的写操作（`STORE_PAGE_FAULT`）时，若 `ref > 1`，则分配新页、复制内容、更新当前进程的 `PTE` 指向新页并恢复写权限；若 `ref = 1`，直接移除 `COW` 标记并恢复写权限。

状态转换图如下：

```plaintext
状态集合：{SHARED_READONLY, SHARED_COW, PRIVATE_WRITABLE, FREED}

转换流程：
1. SHARED_READONLY (原始可写页面)
   └─[fork()]→ SHARED_COW (标记COW，ref加1)

2. SHARED_COW
   ├─[read]→ SHARED_COW (无变化)
   ├─[write, ref>1]→ PRIVATE_WRITABLE (复制页面，ref减1)
   └─[write, ref=1]→ PRIVATE_WRITABLE (直接修改权限，无需复制)

3. PRIVATE_WRITABLE
   └─[page_ref_dec, ref=0]→ FREED (释放页面)
```

## 扩展练习2

在 `ucore` 中，用户程序在编译时被嵌入到内核镜像中，并在内核启动时与内核代码一起加载到内存。具体来说，通过 `Makefile` 的链接脚本，用户程序的二进制文件被编译进内核镜像，存储在内存的特定区域。当调用 `do_execve` 执行用户程序时，`load_icode` 函数会立即为程序的各个段（`TEXT`、`DATA`、`BSS`）分配物理页面，并将二进制内容从内核空间复制到用户进程的物理内存中。这是一种预先加载机制，所有页面在进程创建时即被完全加载。

常用操作系统（如 `Linux`）采用按需分页：在 `exec` 时只建立虚拟地址到文件的页表映射，不立即加载内容；当进程首次访问某个页面时触发 `page fault`，再从磁盘加载该页面。

实验环境尚未实现文件系统，无法从磁盘加载可执行文件。因此，用户程序被直接嵌入到内核镜像中，并在内核启动时一并加载到内存的指定区域。这种方式简化了实现，但限制了灵活性（程序只能在内核启动时加载，无法动态加载不同的程序），且会占用更多内存（加载可能不会使用的页面）。
