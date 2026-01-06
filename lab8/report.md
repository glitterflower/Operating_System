# Lab8

## 练习1

`sfs_io_nolock` 函数的核心目标是实现从文件中读取指定 `offset` 和 `len` 的数据。由于 SFS 文件系统是基于数据块（block）进行管理的，直接处理任意位置和长度的读写请求会比较复杂。因此我们将整个读操作分解为最多三个部分来处理：未对齐的起始部分、完全对齐的中间部分和未对齐的结束部分。

```c
// calculate block offset within the block
blkoff = offset % SFS_BLKSIZE;

// (1) handle the first block if offset is not aligned
if (blkoff != 0 && blkno < sfs->super.blocks) {
    size = (nblks != 0) ? (SFS_BLKSIZE - blkoff) : (endpos - offset);
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    if ((ret = sfs_buf_op(sfs, buf, size, ino, blkoff)) != 0) {
        goto out;
    }
    alen += size;
    buf += size;
    blkno++;
    nblks--;
}

// (2) handle aligned blocks
if (nblks > 0) {
    for (uint32_t i = 0; i < nblks; i++) {
        uint32_t current_blkno = blkno + i;
        if ((ret = sfs_bmap_load_nolock(sfs, sin, current_blkno, &ino)) != 0) {
            goto out;
        }
        if ((ret = sfs_block_op(sfs, buf + i * SFS_BLKSIZE, ino, 1)) != 0) {
            goto out;
        }
    }
    size = nblks * SFS_BLKSIZE;
    alen += size;
    buf += size;
    blkno += nblks;
    nblks = 0;
}

// (3) handle the last block if endpos is not aligned
if ((blkoff = endpos % SFS_BLKSIZE) != 0 && blkno < sfs->super.blocks) {
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    if ((ret = sfs_buf_op(sfs, buf, blkoff, ino, 0)) != 0) {
        goto out;
    }
    alen += blkoff;
}
```

在开始读取前，会先根据传入的 `offset` 和 `len` 计算出操作涉及的起始逻辑块号 `blkno` 、结束位置 `endpos` 和总共需要读取的块数 `nblks` 等参数。

当读操作的起始 `offset` 不是一个块（SFS_BLKSIZE）的整数倍时，意味着我们需要从第一个相关块的中间某个位置开始读取：计算出块内的偏移，先用 `sfs_bmap_load_nolock` 找到第一个逻辑块对应的物理块，再调用 `sfs_buf_op` 只读这一块从偏移到块尾的数据。

在处理完起始的未对齐部分后，后续的读操作就都从块的起始位置开始了，这部分是连续的、完整的块：对中间完全对齐的整块循环处理，每次用 `sfs_bmap_load_nolock` 得到物理块号后用 `sfs_block_op` 直接整块搬运。

当要读取的总长度 `len` 使得结束位置 `endpos` 没有落在块的末尾时，最后一个块也只需要读取一部分：和头部处理类似，计算出最后一个块需要读取的字节数，并再次调用 `sfs_buf_op` 从该块的起始位置读取这最后一段零头数据。

## 练习2

为了让 uCore 能真正地从文件系统加载并执行程序，需要修改两个关键环节：程序的加载流程 `load_icode` 和进程的创建流程 `do_fork`。

对 `load_icode` 的改写，是将其数据源从原先的内存区域，彻底切换为从一个文件描述符 `fd` 中读取。具体的改动是：在函数内部，我们不再访问固定的内存地址，而是通过一个辅助函数 `load_icode_read` 按需从 `fd` 对应的文件中读取ELF头部和各个程序段（segment）。我们解析这些段信息，为它们在进程的新地址空间中创建虚拟内存区域（VMA），分配物理页，然后将从文件中读出的数据填充进去。

`do_fork` 函数的作用是创建一个子进程，它必须尽可能地与父进程保持一致。在有了文件系统后，“一致”就必须包括对已打开文件的继承。因此，我们对 `do_fork` 的改写是在其执行流程中增加了一个 `copy_files` 的调用。这个函数的作用是复制父进程的文件描述符表给子进程。它并非重新打开文件，而是让子进程的描述符表项指向和父进程相同的 `struct file` 实体，并增加文件的引用计数。这样，子进程就自然地继承了父进程所有打开的文件、共享文件偏移量。

```c
if (copy_files(clone_flags, proc) != 0)
{ // for LAB8
    goto bad_fork_cleanup_fs;
}

bad_fork_cleanup_fs: // for LAB8
    put_files(proc);
```

## 扩展练习1

为在 uCore 中实现管道，核心是定义一个新的 `pipe_state` 结构体，用于维护管道的共享状态。此结构将通过一个内存中的 `inode` 对象与现有的 `struct file` 关联起来。

```c
// 管道核心状态结构，由读写两端共享
struct pipe_state {
    // 环形缓冲区
    uint8_t buffer[PIPE_SIZE];
    size_t read_pos;
    size_t write_pos;
    size_t data_count;

    // 写端文件描述符的引用计数
    int writer_count;

    // 用于同步和互斥的监视器 (monitor)
    monitor_t *monitor;
};
```

`int file_pipe(int fd[2])`: 创建一个管道。内核为此分配一个 `pipe_state` 对象和一个内存 `inode`，并创建两个 `file` 结构（一个只读，一个只写）指向该 `inode`，最后返回两个文件描述符 `fd[0]`（读）和 `fd[1]`（写）。

管道读操作 `pipe_read(...)`: 从管道缓冲区读取数据。若缓冲区为空，则睡眠等待；若此时所有写端都已关闭，则返回 0 (EOF)。

管道写操作 `pipe_write(...)`: 向管道缓冲区写入数据。若缓冲区已满，则睡眠等待；若所有读端都已关闭，则返回错误 (-EPIPE)。

管道关闭操作 `pipe_close(...)`: 关闭一个管道端点。递减相应端的引用计数。当写端计数归零时，唤醒所有等待的读者；当读写两端计数都归零时，释放管道资源。

设计方案是将管道抽象为一种特殊的内存文件。通过 `file_pipe` 创建一个 `pipe_state` 实例和一个内存 `inode`，其中 `inode` 的私有指针指向 `pipe_state`。生成的两个文件描述符，分别对应只读和只写的 `file` 结构，但它们共享同一个 `inode`。读写操作通过 VFS 层分发到为管道定制的 `pipe_read` 和 `pipe_write` 函数，从而操作共享的 `pipe_state` 缓冲区，实现了管道功能与现有文件系统的整合。

同步互斥由 `pipe_state` 结构中的 `monitor_t`（监视器）来处理。任何对 `pipe_state` 内部成员（如缓冲区指针、计数器）的访问，都必须先获取监视器的锁。当进程需要因缓冲区空或满而阻塞时，它会在监视器内部的条件变量上安全地等待，并在操作完成后由其他进程唤醒。这种机制可以有效防止数据竞争和“丢失唤醒”等并发问题。

## 扩展练习2

首先解释软/硬连接的定义：硬连接就是对同一个inode，采用多个dentry进行分别连接；而软连接就是对已有连接到inode的文件名，存储它的路径信息作为新文件，用新inode连接它并创建新dentry。

对于硬连接而言，inode层需要进行引用计数的记录，以方便在0时销毁；而dentry层面完全不需要管，因为它只用于单向找inode，自身没有需要记录的额外信息。

在指导书原有框架中，sfs层dickinode已有硬连接计数字段nlinks，vfs层也有ref_count用来维护这个信息；此时补充一个用于新建硬连接的接口即可；并且需要在各个接口原有实现上加入新增引用时加次数、减少时减次数并判断销毁的功能。

```c
struct sfs_disk_inode {
    uint32_t size;                              //如果inode表示常规文件，则size是文件大小
    uint16_t type;                              //inode的文件类型
    uint16_t nlinks;                            //此inode的硬链接数
    uint32_t blocks;                            //此inode的数据块数的个数
    uint32_t direct[SFS_NDIRECT];               //此inode的直接数据块索引值（有SFS_NDIRECT个）
    uint32_t indirect;                          //此inode的一级间接数据块索引值
};
```

对于软连接而言，需要新增一种inode type，用于标识其属于“软连接索引inode”；而后加入一个创建软连接的接口；最后在lookup处补充识别“软连接类型inode”的解析字符串逻辑。此外为了防止引用出现a->b->a死循环，需要加入 `struct lookup_state {int symlink_depth;};` 类似逻辑来限制解析层数。

在可能出现的同步互斥上，硬连接在不同进程访问同一个inode时需要上一个nlinks字段的互斥锁，并且令inode生命周期为opencount和引用数共同控制，避免use-after-free。

软连接本质上其实是普通文件（只是解析对象不同），所以沿用普通inode的互斥机制简单上锁就行。
