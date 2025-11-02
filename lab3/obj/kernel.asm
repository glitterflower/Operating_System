
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fcc50513          	addi	a0,a0,-52 # ffffffffc0206020 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	43460613          	addi	a2,a2,1076 # ffffffffc0206490 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	6b1010ef          	jal	ra,ffffffffc0201f1c <memset>
    dtb_init();
ffffffffc0200070:	404000ef          	jal	ra,ffffffffc0200474 <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3f2000ef          	jal	ra,ffffffffc0200466 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	eb850513          	addi	a0,a0,-328 # ffffffffc0201f30 <etext+0x2>
ffffffffc0200080:	096000ef          	jal	ra,ffffffffc0200116 <cputs>

    print_kerninfo();
ffffffffc0200084:	0e2000ef          	jal	ra,ffffffffc0200166 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7a8000ef          	jal	ra,ffffffffc0200830 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	72e010ef          	jal	ra,ffffffffc02017ba <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7a0000ef          	jal	ra,ffffffffc0200830 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	3a0000ef          	jal	ra,ffffffffc0200434 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	78c000ef          	jal	ra,ffffffffc0200824 <intr_enable>
ffffffffc020009c:	0000                	unimp
ffffffffc020009e:	0000                	unimp

    // 测试异常处理
    asm(".word 0x00000000"); 
    asm("ebreak");
ffffffffc02000a0:	9002                	ebreak

    /* do nothing */
    while (1)
ffffffffc02000a2:	a001                	j	ffffffffc02000a2 <kern_init+0x4e>

ffffffffc02000a4 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000a4:	1141                	addi	sp,sp,-16
ffffffffc02000a6:	e022                	sd	s0,0(sp)
ffffffffc02000a8:	e406                	sd	ra,8(sp)
ffffffffc02000aa:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000ac:	3bc000ef          	jal	ra,ffffffffc0200468 <cons_putc>
    (*cnt) ++;
ffffffffc02000b0:	401c                	lw	a5,0(s0)
}
ffffffffc02000b2:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000b4:	2785                	addiw	a5,a5,1
ffffffffc02000b6:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b8:	6402                	ld	s0,0(sp)
ffffffffc02000ba:	0141                	addi	sp,sp,16
ffffffffc02000bc:	8082                	ret

ffffffffc02000be <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000be:	1101                	addi	sp,sp,-32
ffffffffc02000c0:	862a                	mv	a2,a0
ffffffffc02000c2:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c4:	00000517          	auipc	a0,0x0
ffffffffc02000c8:	fe050513          	addi	a0,a0,-32 # ffffffffc02000a4 <cputch>
ffffffffc02000cc:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d0:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000d2:	135010ef          	jal	ra,ffffffffc0201a06 <vprintfmt>
    return cnt;
}
ffffffffc02000d6:	60e2                	ld	ra,24(sp)
ffffffffc02000d8:	4532                	lw	a0,12(sp)
ffffffffc02000da:	6105                	addi	sp,sp,32
ffffffffc02000dc:	8082                	ret

ffffffffc02000de <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000de:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e0:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000e4:	8e2a                	mv	t3,a0
ffffffffc02000e6:	f42e                	sd	a1,40(sp)
ffffffffc02000e8:	f832                	sd	a2,48(sp)
ffffffffc02000ea:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ec:	00000517          	auipc	a0,0x0
ffffffffc02000f0:	fb850513          	addi	a0,a0,-72 # ffffffffc02000a4 <cputch>
ffffffffc02000f4:	004c                	addi	a1,sp,4
ffffffffc02000f6:	869a                	mv	a3,t1
ffffffffc02000f8:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000fa:	ec06                	sd	ra,24(sp)
ffffffffc02000fc:	e0ba                	sd	a4,64(sp)
ffffffffc02000fe:	e4be                	sd	a5,72(sp)
ffffffffc0200100:	e8c2                	sd	a6,80(sp)
ffffffffc0200102:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200104:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200106:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200108:	0ff010ef          	jal	ra,ffffffffc0201a06 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020010c:	60e2                	ld	ra,24(sp)
ffffffffc020010e:	4512                	lw	a0,4(sp)
ffffffffc0200110:	6125                	addi	sp,sp,96
ffffffffc0200112:	8082                	ret

ffffffffc0200114 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200114:	ae91                	j	ffffffffc0200468 <cons_putc>

ffffffffc0200116 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200116:	1101                	addi	sp,sp,-32
ffffffffc0200118:	e822                	sd	s0,16(sp)
ffffffffc020011a:	ec06                	sd	ra,24(sp)
ffffffffc020011c:	e426                	sd	s1,8(sp)
ffffffffc020011e:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200120:	00054503          	lbu	a0,0(a0)
ffffffffc0200124:	c51d                	beqz	a0,ffffffffc0200152 <cputs+0x3c>
ffffffffc0200126:	0405                	addi	s0,s0,1
ffffffffc0200128:	4485                	li	s1,1
ffffffffc020012a:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020012c:	33c000ef          	jal	ra,ffffffffc0200468 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200130:	00044503          	lbu	a0,0(s0)
ffffffffc0200134:	008487bb          	addw	a5,s1,s0
ffffffffc0200138:	0405                	addi	s0,s0,1
ffffffffc020013a:	f96d                	bnez	a0,ffffffffc020012c <cputs+0x16>
    (*cnt) ++;
ffffffffc020013c:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200140:	4529                	li	a0,10
ffffffffc0200142:	326000ef          	jal	ra,ffffffffc0200468 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200146:	60e2                	ld	ra,24(sp)
ffffffffc0200148:	8522                	mv	a0,s0
ffffffffc020014a:	6442                	ld	s0,16(sp)
ffffffffc020014c:	64a2                	ld	s1,8(sp)
ffffffffc020014e:	6105                	addi	sp,sp,32
ffffffffc0200150:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200152:	4405                	li	s0,1
ffffffffc0200154:	b7f5                	j	ffffffffc0200140 <cputs+0x2a>

ffffffffc0200156 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200156:	1141                	addi	sp,sp,-16
ffffffffc0200158:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020015a:	316000ef          	jal	ra,ffffffffc0200470 <cons_getc>
ffffffffc020015e:	dd75                	beqz	a0,ffffffffc020015a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200160:	60a2                	ld	ra,8(sp)
ffffffffc0200162:	0141                	addi	sp,sp,16
ffffffffc0200164:	8082                	ret

ffffffffc0200166 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200166:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200168:	00002517          	auipc	a0,0x2
ffffffffc020016c:	de850513          	addi	a0,a0,-536 # ffffffffc0201f50 <etext+0x22>
void print_kerninfo(void) {
ffffffffc0200170:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200172:	f6dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200176:	00000597          	auipc	a1,0x0
ffffffffc020017a:	ede58593          	addi	a1,a1,-290 # ffffffffc0200054 <kern_init>
ffffffffc020017e:	00002517          	auipc	a0,0x2
ffffffffc0200182:	df250513          	addi	a0,a0,-526 # ffffffffc0201f70 <etext+0x42>
ffffffffc0200186:	f59ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020018a:	00002597          	auipc	a1,0x2
ffffffffc020018e:	da458593          	addi	a1,a1,-604 # ffffffffc0201f2e <etext>
ffffffffc0200192:	00002517          	auipc	a0,0x2
ffffffffc0200196:	dfe50513          	addi	a0,a0,-514 # ffffffffc0201f90 <etext+0x62>
ffffffffc020019a:	f45ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020019e:	00006597          	auipc	a1,0x6
ffffffffc02001a2:	e8258593          	addi	a1,a1,-382 # ffffffffc0206020 <free_area>
ffffffffc02001a6:	00002517          	auipc	a0,0x2
ffffffffc02001aa:	e0a50513          	addi	a0,a0,-502 # ffffffffc0201fb0 <etext+0x82>
ffffffffc02001ae:	f31ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001b2:	00006597          	auipc	a1,0x6
ffffffffc02001b6:	2de58593          	addi	a1,a1,734 # ffffffffc0206490 <end>
ffffffffc02001ba:	00002517          	auipc	a0,0x2
ffffffffc02001be:	e1650513          	addi	a0,a0,-490 # ffffffffc0201fd0 <etext+0xa2>
ffffffffc02001c2:	f1dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c6:	00006597          	auipc	a1,0x6
ffffffffc02001ca:	6c958593          	addi	a1,a1,1737 # ffffffffc020688f <end+0x3ff>
ffffffffc02001ce:	00000797          	auipc	a5,0x0
ffffffffc02001d2:	e8678793          	addi	a5,a5,-378 # ffffffffc0200054 <kern_init>
ffffffffc02001d6:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001de:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e0:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e4:	95be                	add	a1,a1,a5
ffffffffc02001e6:	85a9                	srai	a1,a1,0xa
ffffffffc02001e8:	00002517          	auipc	a0,0x2
ffffffffc02001ec:	e0850513          	addi	a0,a0,-504 # ffffffffc0201ff0 <etext+0xc2>
}
ffffffffc02001f0:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f2:	b5f5                	j	ffffffffc02000de <cprintf>

ffffffffc02001f4 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f4:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001f6:	00002617          	auipc	a2,0x2
ffffffffc02001fa:	e2a60613          	addi	a2,a2,-470 # ffffffffc0202020 <etext+0xf2>
ffffffffc02001fe:	04d00593          	li	a1,77
ffffffffc0200202:	00002517          	auipc	a0,0x2
ffffffffc0200206:	e3650513          	addi	a0,a0,-458 # ffffffffc0202038 <etext+0x10a>
void print_stackframe(void) {
ffffffffc020020a:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020020c:	1cc000ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc0200210 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200210:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200212:	00002617          	auipc	a2,0x2
ffffffffc0200216:	e3e60613          	addi	a2,a2,-450 # ffffffffc0202050 <etext+0x122>
ffffffffc020021a:	00002597          	auipc	a1,0x2
ffffffffc020021e:	e5658593          	addi	a1,a1,-426 # ffffffffc0202070 <etext+0x142>
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	e5650513          	addi	a0,a0,-426 # ffffffffc0202078 <etext+0x14a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020022c:	eb3ff0ef          	jal	ra,ffffffffc02000de <cprintf>
ffffffffc0200230:	00002617          	auipc	a2,0x2
ffffffffc0200234:	e5860613          	addi	a2,a2,-424 # ffffffffc0202088 <etext+0x15a>
ffffffffc0200238:	00002597          	auipc	a1,0x2
ffffffffc020023c:	e7858593          	addi	a1,a1,-392 # ffffffffc02020b0 <etext+0x182>
ffffffffc0200240:	00002517          	auipc	a0,0x2
ffffffffc0200244:	e3850513          	addi	a0,a0,-456 # ffffffffc0202078 <etext+0x14a>
ffffffffc0200248:	e97ff0ef          	jal	ra,ffffffffc02000de <cprintf>
ffffffffc020024c:	00002617          	auipc	a2,0x2
ffffffffc0200250:	e7460613          	addi	a2,a2,-396 # ffffffffc02020c0 <etext+0x192>
ffffffffc0200254:	00002597          	auipc	a1,0x2
ffffffffc0200258:	e8c58593          	addi	a1,a1,-372 # ffffffffc02020e0 <etext+0x1b2>
ffffffffc020025c:	00002517          	auipc	a0,0x2
ffffffffc0200260:	e1c50513          	addi	a0,a0,-484 # ffffffffc0202078 <etext+0x14a>
ffffffffc0200264:	e7bff0ef          	jal	ra,ffffffffc02000de <cprintf>
    }
    return 0;
}
ffffffffc0200268:	60a2                	ld	ra,8(sp)
ffffffffc020026a:	4501                	li	a0,0
ffffffffc020026c:	0141                	addi	sp,sp,16
ffffffffc020026e:	8082                	ret

ffffffffc0200270 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200270:	1141                	addi	sp,sp,-16
ffffffffc0200272:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200274:	ef3ff0ef          	jal	ra,ffffffffc0200166 <print_kerninfo>
    return 0;
}
ffffffffc0200278:	60a2                	ld	ra,8(sp)
ffffffffc020027a:	4501                	li	a0,0
ffffffffc020027c:	0141                	addi	sp,sp,16
ffffffffc020027e:	8082                	ret

ffffffffc0200280 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200280:	1141                	addi	sp,sp,-16
ffffffffc0200282:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200284:	f71ff0ef          	jal	ra,ffffffffc02001f4 <print_stackframe>
    return 0;
}
ffffffffc0200288:	60a2                	ld	ra,8(sp)
ffffffffc020028a:	4501                	li	a0,0
ffffffffc020028c:	0141                	addi	sp,sp,16
ffffffffc020028e:	8082                	ret

ffffffffc0200290 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200290:	7115                	addi	sp,sp,-224
ffffffffc0200292:	ed5e                	sd	s7,152(sp)
ffffffffc0200294:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	e5a50513          	addi	a0,a0,-422 # ffffffffc02020f0 <etext+0x1c2>
kmonitor(struct trapframe *tf) {
ffffffffc020029e:	ed86                	sd	ra,216(sp)
ffffffffc02002a0:	e9a2                	sd	s0,208(sp)
ffffffffc02002a2:	e5a6                	sd	s1,200(sp)
ffffffffc02002a4:	e1ca                	sd	s2,192(sp)
ffffffffc02002a6:	fd4e                	sd	s3,184(sp)
ffffffffc02002a8:	f952                	sd	s4,176(sp)
ffffffffc02002aa:	f556                	sd	s5,168(sp)
ffffffffc02002ac:	f15a                	sd	s6,160(sp)
ffffffffc02002ae:	e962                	sd	s8,144(sp)
ffffffffc02002b0:	e566                	sd	s9,136(sp)
ffffffffc02002b2:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b4:	e2bff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b8:	00002517          	auipc	a0,0x2
ffffffffc02002bc:	e6050513          	addi	a0,a0,-416 # ffffffffc0202118 <etext+0x1ea>
ffffffffc02002c0:	e1fff0ef          	jal	ra,ffffffffc02000de <cprintf>
    if (tf != NULL) {
ffffffffc02002c4:	000b8563          	beqz	s7,ffffffffc02002ce <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c8:	855e                	mv	a0,s7
ffffffffc02002ca:	746000ef          	jal	ra,ffffffffc0200a10 <print_trapframe>
ffffffffc02002ce:	00002c17          	auipc	s8,0x2
ffffffffc02002d2:	ebac0c13          	addi	s8,s8,-326 # ffffffffc0202188 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d6:	00002917          	auipc	s2,0x2
ffffffffc02002da:	e6a90913          	addi	s2,s2,-406 # ffffffffc0202140 <etext+0x212>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002de:	00002497          	auipc	s1,0x2
ffffffffc02002e2:	e6a48493          	addi	s1,s1,-406 # ffffffffc0202148 <etext+0x21a>
        if (argc == MAXARGS - 1) {
ffffffffc02002e6:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e8:	00002b17          	auipc	s6,0x2
ffffffffc02002ec:	e68b0b13          	addi	s6,s6,-408 # ffffffffc0202150 <etext+0x222>
        argv[argc ++] = buf;
ffffffffc02002f0:	00002a17          	auipc	s4,0x2
ffffffffc02002f4:	d80a0a13          	addi	s4,s4,-640 # ffffffffc0202070 <etext+0x142>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f8:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002fa:	854a                	mv	a0,s2
ffffffffc02002fc:	28d010ef          	jal	ra,ffffffffc0201d88 <readline>
ffffffffc0200300:	842a                	mv	s0,a0
ffffffffc0200302:	dd65                	beqz	a0,ffffffffc02002fa <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200304:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200308:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030a:	e1bd                	bnez	a1,ffffffffc0200370 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020030c:	fe0c87e3          	beqz	s9,ffffffffc02002fa <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200310:	6582                	ld	a1,0(sp)
ffffffffc0200312:	00002d17          	auipc	s10,0x2
ffffffffc0200316:	e76d0d13          	addi	s10,s10,-394 # ffffffffc0202188 <commands>
        argv[argc ++] = buf;
ffffffffc020031a:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020031c:	4401                	li	s0,0
ffffffffc020031e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200320:	3a3010ef          	jal	ra,ffffffffc0201ec2 <strcmp>
ffffffffc0200324:	c919                	beqz	a0,ffffffffc020033a <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200326:	2405                	addiw	s0,s0,1
ffffffffc0200328:	0b540063          	beq	s0,s5,ffffffffc02003c8 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032c:	000d3503          	ld	a0,0(s10)
ffffffffc0200330:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200332:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200334:	38f010ef          	jal	ra,ffffffffc0201ec2 <strcmp>
ffffffffc0200338:	f57d                	bnez	a0,ffffffffc0200326 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020033a:	00141793          	slli	a5,s0,0x1
ffffffffc020033e:	97a2                	add	a5,a5,s0
ffffffffc0200340:	078e                	slli	a5,a5,0x3
ffffffffc0200342:	97e2                	add	a5,a5,s8
ffffffffc0200344:	6b9c                	ld	a5,16(a5)
ffffffffc0200346:	865e                	mv	a2,s7
ffffffffc0200348:	002c                	addi	a1,sp,8
ffffffffc020034a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020034e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200350:	fa0555e3          	bgez	a0,ffffffffc02002fa <kmonitor+0x6a>
}
ffffffffc0200354:	60ee                	ld	ra,216(sp)
ffffffffc0200356:	644e                	ld	s0,208(sp)
ffffffffc0200358:	64ae                	ld	s1,200(sp)
ffffffffc020035a:	690e                	ld	s2,192(sp)
ffffffffc020035c:	79ea                	ld	s3,184(sp)
ffffffffc020035e:	7a4a                	ld	s4,176(sp)
ffffffffc0200360:	7aaa                	ld	s5,168(sp)
ffffffffc0200362:	7b0a                	ld	s6,160(sp)
ffffffffc0200364:	6bea                	ld	s7,152(sp)
ffffffffc0200366:	6c4a                	ld	s8,144(sp)
ffffffffc0200368:	6caa                	ld	s9,136(sp)
ffffffffc020036a:	6d0a                	ld	s10,128(sp)
ffffffffc020036c:	612d                	addi	sp,sp,224
ffffffffc020036e:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200370:	8526                	mv	a0,s1
ffffffffc0200372:	395010ef          	jal	ra,ffffffffc0201f06 <strchr>
ffffffffc0200376:	c901                	beqz	a0,ffffffffc0200386 <kmonitor+0xf6>
ffffffffc0200378:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020037c:	00040023          	sb	zero,0(s0)
ffffffffc0200380:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200382:	d5c9                	beqz	a1,ffffffffc020030c <kmonitor+0x7c>
ffffffffc0200384:	b7f5                	j	ffffffffc0200370 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200386:	00044783          	lbu	a5,0(s0)
ffffffffc020038a:	d3c9                	beqz	a5,ffffffffc020030c <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc020038c:	033c8963          	beq	s9,s3,ffffffffc02003be <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200390:	003c9793          	slli	a5,s9,0x3
ffffffffc0200394:	0118                	addi	a4,sp,128
ffffffffc0200396:	97ba                	add	a5,a5,a4
ffffffffc0200398:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039c:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003a0:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a2:	e591                	bnez	a1,ffffffffc02003ae <kmonitor+0x11e>
ffffffffc02003a4:	b7b5                	j	ffffffffc0200310 <kmonitor+0x80>
ffffffffc02003a6:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003aa:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003ac:	d1a5                	beqz	a1,ffffffffc020030c <kmonitor+0x7c>
ffffffffc02003ae:	8526                	mv	a0,s1
ffffffffc02003b0:	357010ef          	jal	ra,ffffffffc0201f06 <strchr>
ffffffffc02003b4:	d96d                	beqz	a0,ffffffffc02003a6 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b6:	00044583          	lbu	a1,0(s0)
ffffffffc02003ba:	d9a9                	beqz	a1,ffffffffc020030c <kmonitor+0x7c>
ffffffffc02003bc:	bf55                	j	ffffffffc0200370 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003be:	45c1                	li	a1,16
ffffffffc02003c0:	855a                	mv	a0,s6
ffffffffc02003c2:	d1dff0ef          	jal	ra,ffffffffc02000de <cprintf>
ffffffffc02003c6:	b7e9                	j	ffffffffc0200390 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c8:	6582                	ld	a1,0(sp)
ffffffffc02003ca:	00002517          	auipc	a0,0x2
ffffffffc02003ce:	da650513          	addi	a0,a0,-602 # ffffffffc0202170 <etext+0x242>
ffffffffc02003d2:	d0dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    return 0;
ffffffffc02003d6:	b715                	j	ffffffffc02002fa <kmonitor+0x6a>

ffffffffc02003d8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003d8:	00006317          	auipc	t1,0x6
ffffffffc02003dc:	06030313          	addi	t1,t1,96 # ffffffffc0206438 <is_panic>
ffffffffc02003e0:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003e4:	715d                	addi	sp,sp,-80
ffffffffc02003e6:	ec06                	sd	ra,24(sp)
ffffffffc02003e8:	e822                	sd	s0,16(sp)
ffffffffc02003ea:	f436                	sd	a3,40(sp)
ffffffffc02003ec:	f83a                	sd	a4,48(sp)
ffffffffc02003ee:	fc3e                	sd	a5,56(sp)
ffffffffc02003f0:	e0c2                	sd	a6,64(sp)
ffffffffc02003f2:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003f4:	020e1a63          	bnez	t3,ffffffffc0200428 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003f8:	4785                	li	a5,1
ffffffffc02003fa:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003fe:	8432                	mv	s0,a2
ffffffffc0200400:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200402:	862e                	mv	a2,a1
ffffffffc0200404:	85aa                	mv	a1,a0
ffffffffc0200406:	00002517          	auipc	a0,0x2
ffffffffc020040a:	dca50513          	addi	a0,a0,-566 # ffffffffc02021d0 <commands+0x48>
    va_start(ap, fmt);
ffffffffc020040e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200410:	ccfff0ef          	jal	ra,ffffffffc02000de <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200414:	65a2                	ld	a1,8(sp)
ffffffffc0200416:	8522                	mv	a0,s0
ffffffffc0200418:	ca7ff0ef          	jal	ra,ffffffffc02000be <vcprintf>
    cprintf("\n");
ffffffffc020041c:	00002517          	auipc	a0,0x2
ffffffffc0200420:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0202018 <etext+0xea>
ffffffffc0200424:	cbbff0ef          	jal	ra,ffffffffc02000de <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200428:	402000ef          	jal	ra,ffffffffc020082a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020042c:	4501                	li	a0,0
ffffffffc020042e:	e63ff0ef          	jal	ra,ffffffffc0200290 <kmonitor>
    while (1) {
ffffffffc0200432:	bfed                	j	ffffffffc020042c <__panic+0x54>

ffffffffc0200434 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200434:	1141                	addi	sp,sp,-16
ffffffffc0200436:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200438:	02000793          	li	a5,32
ffffffffc020043c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200440:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200444:	67e1                	lui	a5,0x18
ffffffffc0200446:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020044a:	953e                	add	a0,a0,a5
ffffffffc020044c:	20b010ef          	jal	ra,ffffffffc0201e56 <sbi_set_timer>
}
ffffffffc0200450:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200452:	00006797          	auipc	a5,0x6
ffffffffc0200456:	fe07b723          	sd	zero,-18(a5) # ffffffffc0206440 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020045a:	00002517          	auipc	a0,0x2
ffffffffc020045e:	d9650513          	addi	a0,a0,-618 # ffffffffc02021f0 <commands+0x68>
}
ffffffffc0200462:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200464:	b9ad                	j	ffffffffc02000de <cprintf>

ffffffffc0200466 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200466:	8082                	ret

ffffffffc0200468 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200468:	0ff57513          	zext.b	a0,a0
ffffffffc020046c:	1d10106f          	j	ffffffffc0201e3c <sbi_console_putchar>

ffffffffc0200470 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200470:	2010106f          	j	ffffffffc0201e70 <sbi_console_getchar>

ffffffffc0200474 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200474:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200476:	00002517          	auipc	a0,0x2
ffffffffc020047a:	d9a50513          	addi	a0,a0,-614 # ffffffffc0202210 <commands+0x88>
void dtb_init(void) {
ffffffffc020047e:	fc86                	sd	ra,120(sp)
ffffffffc0200480:	f8a2                	sd	s0,112(sp)
ffffffffc0200482:	e8d2                	sd	s4,80(sp)
ffffffffc0200484:	f4a6                	sd	s1,104(sp)
ffffffffc0200486:	f0ca                	sd	s2,96(sp)
ffffffffc0200488:	ecce                	sd	s3,88(sp)
ffffffffc020048a:	e4d6                	sd	s5,72(sp)
ffffffffc020048c:	e0da                	sd	s6,64(sp)
ffffffffc020048e:	fc5e                	sd	s7,56(sp)
ffffffffc0200490:	f862                	sd	s8,48(sp)
ffffffffc0200492:	f466                	sd	s9,40(sp)
ffffffffc0200494:	f06a                	sd	s10,32(sp)
ffffffffc0200496:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200498:	c47ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020049c:	00006597          	auipc	a1,0x6
ffffffffc02004a0:	b645b583          	ld	a1,-1180(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	d7c50513          	addi	a0,a0,-644 # ffffffffc0202220 <commands+0x98>
ffffffffc02004ac:	c33ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004b0:	00006417          	auipc	s0,0x6
ffffffffc02004b4:	b5840413          	addi	s0,s0,-1192 # ffffffffc0206008 <boot_dtb>
ffffffffc02004b8:	600c                	ld	a1,0(s0)
ffffffffc02004ba:	00002517          	auipc	a0,0x2
ffffffffc02004be:	d7650513          	addi	a0,a0,-650 # ffffffffc0202230 <commands+0xa8>
ffffffffc02004c2:	c1dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004c6:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004ca:	00002517          	auipc	a0,0x2
ffffffffc02004ce:	d7e50513          	addi	a0,a0,-642 # ffffffffc0202248 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02004d2:	120a0463          	beqz	s4,ffffffffc02005fa <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004d6:	57f5                	li	a5,-3
ffffffffc02004d8:	07fa                	slli	a5,a5,0x1e
ffffffffc02004da:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004de:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e0:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e4:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e6:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004ea:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ee:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f2:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f6:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fa:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	8ec9                	or	a3,a3,a0
ffffffffc02004fe:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200502:	1b7d                	addi	s6,s6,-1
ffffffffc0200504:	0167f7b3          	and	a5,a5,s6
ffffffffc0200508:	8dd5                	or	a1,a1,a3
ffffffffc020050a:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc020050c:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200510:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200512:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a5d>
ffffffffc0200516:	10f59163          	bne	a1,a5,ffffffffc0200618 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020051a:	471c                	lw	a5,8(a4)
ffffffffc020051c:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc020051e:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200520:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200524:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200528:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052c:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200530:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200534:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200538:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053c:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200540:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200544:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200548:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020054a:	01146433          	or	s0,s0,a7
ffffffffc020054e:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200552:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200556:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200558:	0087979b          	slliw	a5,a5,0x8
ffffffffc020055c:	8c49                	or	s0,s0,a0
ffffffffc020055e:	0166f6b3          	and	a3,a3,s6
ffffffffc0200562:	00ca6a33          	or	s4,s4,a2
ffffffffc0200566:	0167f7b3          	and	a5,a5,s6
ffffffffc020056a:	8c55                	or	s0,s0,a3
ffffffffc020056c:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200570:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200572:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200574:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200576:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057a:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020057c:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057e:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200582:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200584:	00002917          	auipc	s2,0x2
ffffffffc0200588:	d1490913          	addi	s2,s2,-748 # ffffffffc0202298 <commands+0x110>
ffffffffc020058c:	49bd                	li	s3,15
        switch (token) {
ffffffffc020058e:	4d91                	li	s11,4
ffffffffc0200590:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200592:	00002497          	auipc	s1,0x2
ffffffffc0200596:	cfe48493          	addi	s1,s1,-770 # ffffffffc0202290 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020059a:	000a2703          	lw	a4,0(s4)
ffffffffc020059e:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a2:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005a6:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005aa:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ae:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b2:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005b6:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b8:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005bc:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005c0:	8fd5                	or	a5,a5,a3
ffffffffc02005c2:	00eb7733          	and	a4,s6,a4
ffffffffc02005c6:	8fd9                	or	a5,a5,a4
ffffffffc02005c8:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005ca:	09778c63          	beq	a5,s7,ffffffffc0200662 <dtb_init+0x1ee>
ffffffffc02005ce:	00fbea63          	bltu	s7,a5,ffffffffc02005e2 <dtb_init+0x16e>
ffffffffc02005d2:	07a78663          	beq	a5,s10,ffffffffc020063e <dtb_init+0x1ca>
ffffffffc02005d6:	4709                	li	a4,2
ffffffffc02005d8:	00e79763          	bne	a5,a4,ffffffffc02005e6 <dtb_init+0x172>
ffffffffc02005dc:	4c81                	li	s9,0
ffffffffc02005de:	8a56                	mv	s4,s5
ffffffffc02005e0:	bf6d                	j	ffffffffc020059a <dtb_init+0x126>
ffffffffc02005e2:	ffb78ee3          	beq	a5,s11,ffffffffc02005de <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005e6:	00002517          	auipc	a0,0x2
ffffffffc02005ea:	d2a50513          	addi	a0,a0,-726 # ffffffffc0202310 <commands+0x188>
ffffffffc02005ee:	af1ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	d5650513          	addi	a0,a0,-682 # ffffffffc0202348 <commands+0x1c0>
}
ffffffffc02005fa:	7446                	ld	s0,112(sp)
ffffffffc02005fc:	70e6                	ld	ra,120(sp)
ffffffffc02005fe:	74a6                	ld	s1,104(sp)
ffffffffc0200600:	7906                	ld	s2,96(sp)
ffffffffc0200602:	69e6                	ld	s3,88(sp)
ffffffffc0200604:	6a46                	ld	s4,80(sp)
ffffffffc0200606:	6aa6                	ld	s5,72(sp)
ffffffffc0200608:	6b06                	ld	s6,64(sp)
ffffffffc020060a:	7be2                	ld	s7,56(sp)
ffffffffc020060c:	7c42                	ld	s8,48(sp)
ffffffffc020060e:	7ca2                	ld	s9,40(sp)
ffffffffc0200610:	7d02                	ld	s10,32(sp)
ffffffffc0200612:	6de2                	ld	s11,24(sp)
ffffffffc0200614:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200616:	b4e1                	j	ffffffffc02000de <cprintf>
}
ffffffffc0200618:	7446                	ld	s0,112(sp)
ffffffffc020061a:	70e6                	ld	ra,120(sp)
ffffffffc020061c:	74a6                	ld	s1,104(sp)
ffffffffc020061e:	7906                	ld	s2,96(sp)
ffffffffc0200620:	69e6                	ld	s3,88(sp)
ffffffffc0200622:	6a46                	ld	s4,80(sp)
ffffffffc0200624:	6aa6                	ld	s5,72(sp)
ffffffffc0200626:	6b06                	ld	s6,64(sp)
ffffffffc0200628:	7be2                	ld	s7,56(sp)
ffffffffc020062a:	7c42                	ld	s8,48(sp)
ffffffffc020062c:	7ca2                	ld	s9,40(sp)
ffffffffc020062e:	7d02                	ld	s10,32(sp)
ffffffffc0200630:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200632:	00002517          	auipc	a0,0x2
ffffffffc0200636:	c3650513          	addi	a0,a0,-970 # ffffffffc0202268 <commands+0xe0>
}
ffffffffc020063a:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020063c:	b44d                	j	ffffffffc02000de <cprintf>
                int name_len = strlen(name);
ffffffffc020063e:	8556                	mv	a0,s5
ffffffffc0200640:	04d010ef          	jal	ra,ffffffffc0201e8c <strlen>
ffffffffc0200644:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200646:	4619                	li	a2,6
ffffffffc0200648:	85a6                	mv	a1,s1
ffffffffc020064a:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc020064c:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020064e:	093010ef          	jal	ra,ffffffffc0201ee0 <strncmp>
ffffffffc0200652:	e111                	bnez	a0,ffffffffc0200656 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200654:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200656:	0a91                	addi	s5,s5,4
ffffffffc0200658:	9ad2                	add	s5,s5,s4
ffffffffc020065a:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020065e:	8a56                	mv	s4,s5
ffffffffc0200660:	bf2d                	j	ffffffffc020059a <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200662:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200666:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020066e:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200672:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200676:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020067e:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200682:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068a:	00eaeab3          	or	s5,s5,a4
ffffffffc020068e:	00fb77b3          	and	a5,s6,a5
ffffffffc0200692:	00faeab3          	or	s5,s5,a5
ffffffffc0200696:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200698:	000c9c63          	bnez	s9,ffffffffc02006b0 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020069c:	1a82                	slli	s5,s5,0x20
ffffffffc020069e:	00368793          	addi	a5,a3,3
ffffffffc02006a2:	020ada93          	srli	s5,s5,0x20
ffffffffc02006a6:	9abe                	add	s5,s5,a5
ffffffffc02006a8:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006ac:	8a56                	mv	s4,s5
ffffffffc02006ae:	b5f5                	j	ffffffffc020059a <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006b0:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006b4:	85ca                	mv	a1,s2
ffffffffc02006b6:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b8:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006bc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c0:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006c4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c8:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006cc:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ce:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006d6:	8d59                	or	a0,a0,a4
ffffffffc02006d8:	00fb77b3          	and	a5,s6,a5
ffffffffc02006dc:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006de:	1502                	slli	a0,a0,0x20
ffffffffc02006e0:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006e2:	9522                	add	a0,a0,s0
ffffffffc02006e4:	7de010ef          	jal	ra,ffffffffc0201ec2 <strcmp>
ffffffffc02006e8:	66a2                	ld	a3,8(sp)
ffffffffc02006ea:	f94d                	bnez	a0,ffffffffc020069c <dtb_init+0x228>
ffffffffc02006ec:	fb59f8e3          	bgeu	s3,s5,ffffffffc020069c <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006f0:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006f4:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006f8:	00002517          	auipc	a0,0x2
ffffffffc02006fc:	ba850513          	addi	a0,a0,-1112 # ffffffffc02022a0 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200700:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200704:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200708:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020070c:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200710:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200714:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200718:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071c:	0187d693          	srli	a3,a5,0x18
ffffffffc0200720:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200724:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200728:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072c:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200730:	010f6f33          	or	t5,t5,a6
ffffffffc0200734:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200738:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073c:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200740:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200744:	0186f6b3          	and	a3,a3,s8
ffffffffc0200748:	01859e1b          	slliw	t3,a1,0x18
ffffffffc020074c:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200750:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200754:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200758:	8361                	srli	a4,a4,0x18
ffffffffc020075a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075e:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200762:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200766:	00cb7633          	and	a2,s6,a2
ffffffffc020076a:	0088181b          	slliw	a6,a6,0x8
ffffffffc020076e:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200772:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200776:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020077a:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077e:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200782:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200786:	011b78b3          	and	a7,s6,a7
ffffffffc020078a:	005eeeb3          	or	t4,t4,t0
ffffffffc020078e:	00c6e733          	or	a4,a3,a2
ffffffffc0200792:	006c6c33          	or	s8,s8,t1
ffffffffc0200796:	010b76b3          	and	a3,s6,a6
ffffffffc020079a:	00bb7b33          	and	s6,s6,a1
ffffffffc020079e:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007a2:	016c6b33          	or	s6,s8,s6
ffffffffc02007a6:	01146433          	or	s0,s0,a7
ffffffffc02007aa:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007ac:	1702                	slli	a4,a4,0x20
ffffffffc02007ae:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007b0:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007b2:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007b4:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007b6:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007ba:	0167eb33          	or	s6,a5,s6
ffffffffc02007be:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007c0:	91fff0ef          	jal	ra,ffffffffc02000de <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007c4:	85a2                	mv	a1,s0
ffffffffc02007c6:	00002517          	auipc	a0,0x2
ffffffffc02007ca:	afa50513          	addi	a0,a0,-1286 # ffffffffc02022c0 <commands+0x138>
ffffffffc02007ce:	911ff0ef          	jal	ra,ffffffffc02000de <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007d2:	014b5613          	srli	a2,s6,0x14
ffffffffc02007d6:	85da                	mv	a1,s6
ffffffffc02007d8:	00002517          	auipc	a0,0x2
ffffffffc02007dc:	b0050513          	addi	a0,a0,-1280 # ffffffffc02022d8 <commands+0x150>
ffffffffc02007e0:	8ffff0ef          	jal	ra,ffffffffc02000de <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007e4:	008b05b3          	add	a1,s6,s0
ffffffffc02007e8:	15fd                	addi	a1,a1,-1
ffffffffc02007ea:	00002517          	auipc	a0,0x2
ffffffffc02007ee:	b0e50513          	addi	a0,a0,-1266 # ffffffffc02022f8 <commands+0x170>
ffffffffc02007f2:	8edff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02007f6:	00002517          	auipc	a0,0x2
ffffffffc02007fa:	b5250513          	addi	a0,a0,-1198 # ffffffffc0202348 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc02007fe:	00006797          	auipc	a5,0x6
ffffffffc0200802:	c487b523          	sd	s0,-950(a5) # ffffffffc0206448 <memory_base>
        memory_size = mem_size;
ffffffffc0200806:	00006797          	auipc	a5,0x6
ffffffffc020080a:	c567b523          	sd	s6,-950(a5) # ffffffffc0206450 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc020080e:	b3f5                	j	ffffffffc02005fa <dtb_init+0x186>

ffffffffc0200810 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200810:	00006517          	auipc	a0,0x6
ffffffffc0200814:	c3853503          	ld	a0,-968(a0) # ffffffffc0206448 <memory_base>
ffffffffc0200818:	8082                	ret

ffffffffc020081a <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020081a:	00006517          	auipc	a0,0x6
ffffffffc020081e:	c3653503          	ld	a0,-970(a0) # ffffffffc0206450 <memory_size>
ffffffffc0200822:	8082                	ret

ffffffffc0200824 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200824:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200828:	8082                	ret

ffffffffc020082a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020082a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020082e:	8082                	ret

ffffffffc0200830 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200830:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200834:	00000797          	auipc	a5,0x0
ffffffffc0200838:	34078793          	addi	a5,a5,832 # ffffffffc0200b74 <__alltraps>
ffffffffc020083c:	10579073          	csrw	stvec,a5
}
ffffffffc0200840:	8082                	ret

ffffffffc0200842 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200842:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200844:	1141                	addi	sp,sp,-16
ffffffffc0200846:	e022                	sd	s0,0(sp)
ffffffffc0200848:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020084a:	00002517          	auipc	a0,0x2
ffffffffc020084e:	b1650513          	addi	a0,a0,-1258 # ffffffffc0202360 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200852:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200854:	88bff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200858:	640c                	ld	a1,8(s0)
ffffffffc020085a:	00002517          	auipc	a0,0x2
ffffffffc020085e:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0202378 <commands+0x1f0>
ffffffffc0200862:	87dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200866:	680c                	ld	a1,16(s0)
ffffffffc0200868:	00002517          	auipc	a0,0x2
ffffffffc020086c:	b2850513          	addi	a0,a0,-1240 # ffffffffc0202390 <commands+0x208>
ffffffffc0200870:	86fff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200874:	6c0c                	ld	a1,24(s0)
ffffffffc0200876:	00002517          	auipc	a0,0x2
ffffffffc020087a:	b3250513          	addi	a0,a0,-1230 # ffffffffc02023a8 <commands+0x220>
ffffffffc020087e:	861ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200882:	700c                	ld	a1,32(s0)
ffffffffc0200884:	00002517          	auipc	a0,0x2
ffffffffc0200888:	b3c50513          	addi	a0,a0,-1220 # ffffffffc02023c0 <commands+0x238>
ffffffffc020088c:	853ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200890:	740c                	ld	a1,40(s0)
ffffffffc0200892:	00002517          	auipc	a0,0x2
ffffffffc0200896:	b4650513          	addi	a0,a0,-1210 # ffffffffc02023d8 <commands+0x250>
ffffffffc020089a:	845ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc020089e:	780c                	ld	a1,48(s0)
ffffffffc02008a0:	00002517          	auipc	a0,0x2
ffffffffc02008a4:	b5050513          	addi	a0,a0,-1200 # ffffffffc02023f0 <commands+0x268>
ffffffffc02008a8:	837ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008ac:	7c0c                	ld	a1,56(s0)
ffffffffc02008ae:	00002517          	auipc	a0,0x2
ffffffffc02008b2:	b5a50513          	addi	a0,a0,-1190 # ffffffffc0202408 <commands+0x280>
ffffffffc02008b6:	829ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008ba:	602c                	ld	a1,64(s0)
ffffffffc02008bc:	00002517          	auipc	a0,0x2
ffffffffc02008c0:	b6450513          	addi	a0,a0,-1180 # ffffffffc0202420 <commands+0x298>
ffffffffc02008c4:	81bff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008c8:	642c                	ld	a1,72(s0)
ffffffffc02008ca:	00002517          	auipc	a0,0x2
ffffffffc02008ce:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0202438 <commands+0x2b0>
ffffffffc02008d2:	80dff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008d6:	682c                	ld	a1,80(s0)
ffffffffc02008d8:	00002517          	auipc	a0,0x2
ffffffffc02008dc:	b7850513          	addi	a0,a0,-1160 # ffffffffc0202450 <commands+0x2c8>
ffffffffc02008e0:	ffeff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008e4:	6c2c                	ld	a1,88(s0)
ffffffffc02008e6:	00002517          	auipc	a0,0x2
ffffffffc02008ea:	b8250513          	addi	a0,a0,-1150 # ffffffffc0202468 <commands+0x2e0>
ffffffffc02008ee:	ff0ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008f2:	702c                	ld	a1,96(s0)
ffffffffc02008f4:	00002517          	auipc	a0,0x2
ffffffffc02008f8:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0202480 <commands+0x2f8>
ffffffffc02008fc:	fe2ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200900:	742c                	ld	a1,104(s0)
ffffffffc0200902:	00002517          	auipc	a0,0x2
ffffffffc0200906:	b9650513          	addi	a0,a0,-1130 # ffffffffc0202498 <commands+0x310>
ffffffffc020090a:	fd4ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020090e:	782c                	ld	a1,112(s0)
ffffffffc0200910:	00002517          	auipc	a0,0x2
ffffffffc0200914:	ba050513          	addi	a0,a0,-1120 # ffffffffc02024b0 <commands+0x328>
ffffffffc0200918:	fc6ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020091c:	7c2c                	ld	a1,120(s0)
ffffffffc020091e:	00002517          	auipc	a0,0x2
ffffffffc0200922:	baa50513          	addi	a0,a0,-1110 # ffffffffc02024c8 <commands+0x340>
ffffffffc0200926:	fb8ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020092a:	604c                	ld	a1,128(s0)
ffffffffc020092c:	00002517          	auipc	a0,0x2
ffffffffc0200930:	bb450513          	addi	a0,a0,-1100 # ffffffffc02024e0 <commands+0x358>
ffffffffc0200934:	faaff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200938:	644c                	ld	a1,136(s0)
ffffffffc020093a:	00002517          	auipc	a0,0x2
ffffffffc020093e:	bbe50513          	addi	a0,a0,-1090 # ffffffffc02024f8 <commands+0x370>
ffffffffc0200942:	f9cff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200946:	684c                	ld	a1,144(s0)
ffffffffc0200948:	00002517          	auipc	a0,0x2
ffffffffc020094c:	bc850513          	addi	a0,a0,-1080 # ffffffffc0202510 <commands+0x388>
ffffffffc0200950:	f8eff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200954:	6c4c                	ld	a1,152(s0)
ffffffffc0200956:	00002517          	auipc	a0,0x2
ffffffffc020095a:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202528 <commands+0x3a0>
ffffffffc020095e:	f80ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200962:	704c                	ld	a1,160(s0)
ffffffffc0200964:	00002517          	auipc	a0,0x2
ffffffffc0200968:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202540 <commands+0x3b8>
ffffffffc020096c:	f72ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200970:	744c                	ld	a1,168(s0)
ffffffffc0200972:	00002517          	auipc	a0,0x2
ffffffffc0200976:	be650513          	addi	a0,a0,-1050 # ffffffffc0202558 <commands+0x3d0>
ffffffffc020097a:	f64ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020097e:	784c                	ld	a1,176(s0)
ffffffffc0200980:	00002517          	auipc	a0,0x2
ffffffffc0200984:	bf050513          	addi	a0,a0,-1040 # ffffffffc0202570 <commands+0x3e8>
ffffffffc0200988:	f56ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020098c:	7c4c                	ld	a1,184(s0)
ffffffffc020098e:	00002517          	auipc	a0,0x2
ffffffffc0200992:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0202588 <commands+0x400>
ffffffffc0200996:	f48ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc020099a:	606c                	ld	a1,192(s0)
ffffffffc020099c:	00002517          	auipc	a0,0x2
ffffffffc02009a0:	c0450513          	addi	a0,a0,-1020 # ffffffffc02025a0 <commands+0x418>
ffffffffc02009a4:	f3aff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009a8:	646c                	ld	a1,200(s0)
ffffffffc02009aa:	00002517          	auipc	a0,0x2
ffffffffc02009ae:	c0e50513          	addi	a0,a0,-1010 # ffffffffc02025b8 <commands+0x430>
ffffffffc02009b2:	f2cff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009b6:	686c                	ld	a1,208(s0)
ffffffffc02009b8:	00002517          	auipc	a0,0x2
ffffffffc02009bc:	c1850513          	addi	a0,a0,-1000 # ffffffffc02025d0 <commands+0x448>
ffffffffc02009c0:	f1eff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009c4:	6c6c                	ld	a1,216(s0)
ffffffffc02009c6:	00002517          	auipc	a0,0x2
ffffffffc02009ca:	c2250513          	addi	a0,a0,-990 # ffffffffc02025e8 <commands+0x460>
ffffffffc02009ce:	f10ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009d2:	706c                	ld	a1,224(s0)
ffffffffc02009d4:	00002517          	auipc	a0,0x2
ffffffffc02009d8:	c2c50513          	addi	a0,a0,-980 # ffffffffc0202600 <commands+0x478>
ffffffffc02009dc:	f02ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009e0:	746c                	ld	a1,232(s0)
ffffffffc02009e2:	00002517          	auipc	a0,0x2
ffffffffc02009e6:	c3650513          	addi	a0,a0,-970 # ffffffffc0202618 <commands+0x490>
ffffffffc02009ea:	ef4ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009ee:	786c                	ld	a1,240(s0)
ffffffffc02009f0:	00002517          	auipc	a0,0x2
ffffffffc02009f4:	c4050513          	addi	a0,a0,-960 # ffffffffc0202630 <commands+0x4a8>
ffffffffc02009f8:	ee6ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009fc:	7c6c                	ld	a1,248(s0)
}
ffffffffc02009fe:	6402                	ld	s0,0(sp)
ffffffffc0200a00:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a02:	00002517          	auipc	a0,0x2
ffffffffc0200a06:	c4650513          	addi	a0,a0,-954 # ffffffffc0202648 <commands+0x4c0>
}
ffffffffc0200a0a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0c:	ed2ff06f          	j	ffffffffc02000de <cprintf>

ffffffffc0200a10 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a10:	1141                	addi	sp,sp,-16
ffffffffc0200a12:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a14:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a16:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a18:	00002517          	auipc	a0,0x2
ffffffffc0200a1c:	c4850513          	addi	a0,a0,-952 # ffffffffc0202660 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a20:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a22:	ebcff0ef          	jal	ra,ffffffffc02000de <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a26:	8522                	mv	a0,s0
ffffffffc0200a28:	e1bff0ef          	jal	ra,ffffffffc0200842 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a2c:	10043583          	ld	a1,256(s0)
ffffffffc0200a30:	00002517          	auipc	a0,0x2
ffffffffc0200a34:	c4850513          	addi	a0,a0,-952 # ffffffffc0202678 <commands+0x4f0>
ffffffffc0200a38:	ea6ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a3c:	10843583          	ld	a1,264(s0)
ffffffffc0200a40:	00002517          	auipc	a0,0x2
ffffffffc0200a44:	c5050513          	addi	a0,a0,-944 # ffffffffc0202690 <commands+0x508>
ffffffffc0200a48:	e96ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a4c:	11043583          	ld	a1,272(s0)
ffffffffc0200a50:	00002517          	auipc	a0,0x2
ffffffffc0200a54:	c5850513          	addi	a0,a0,-936 # ffffffffc02026a8 <commands+0x520>
ffffffffc0200a58:	e86ff0ef          	jal	ra,ffffffffc02000de <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a5c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a60:	6402                	ld	s0,0(sp)
ffffffffc0200a62:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a64:	00002517          	auipc	a0,0x2
ffffffffc0200a68:	c5c50513          	addi	a0,a0,-932 # ffffffffc02026c0 <commands+0x538>
}
ffffffffc0200a6c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a6e:	e70ff06f          	j	ffffffffc02000de <cprintf>

ffffffffc0200a72 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a72:	11853783          	ld	a5,280(a0)
ffffffffc0200a76:	472d                	li	a4,11
ffffffffc0200a78:	0786                	slli	a5,a5,0x1
ffffffffc0200a7a:	8385                	srli	a5,a5,0x1
ffffffffc0200a7c:	06f76063          	bltu	a4,a5,ffffffffc0200adc <interrupt_handler+0x6a>
ffffffffc0200a80:	00002717          	auipc	a4,0x2
ffffffffc0200a84:	d1070713          	addi	a4,a4,-752 # ffffffffc0202790 <commands+0x608>
ffffffffc0200a88:	078a                	slli	a5,a5,0x2
ffffffffc0200a8a:	97ba                	add	a5,a5,a4
ffffffffc0200a8c:	439c                	lw	a5,0(a5)
ffffffffc0200a8e:	97ba                	add	a5,a5,a4
ffffffffc0200a90:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a92:	00002517          	auipc	a0,0x2
ffffffffc0200a96:	ca650513          	addi	a0,a0,-858 # ffffffffc0202738 <commands+0x5b0>
ffffffffc0200a9a:	e44ff06f          	j	ffffffffc02000de <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200a9e:	00002517          	auipc	a0,0x2
ffffffffc0200aa2:	c7a50513          	addi	a0,a0,-902 # ffffffffc0202718 <commands+0x590>
ffffffffc0200aa6:	e38ff06f          	j	ffffffffc02000de <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200aaa:	00002517          	auipc	a0,0x2
ffffffffc0200aae:	c2e50513          	addi	a0,a0,-978 # ffffffffc02026d8 <commands+0x550>
ffffffffc0200ab2:	e2cff06f          	j	ffffffffc02000de <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ab6:	00002517          	auipc	a0,0x2
ffffffffc0200aba:	ca250513          	addi	a0,a0,-862 # ffffffffc0202758 <commands+0x5d0>
ffffffffc0200abe:	e20ff06f          	j	ffffffffc02000de <cprintf>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200ac2:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200ac4:	00002517          	auipc	a0,0x2
ffffffffc0200ac8:	cac50513          	addi	a0,a0,-852 # ffffffffc0202770 <commands+0x5e8>
ffffffffc0200acc:	e12ff06f          	j	ffffffffc02000de <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200ad0:	00002517          	auipc	a0,0x2
ffffffffc0200ad4:	c2850513          	addi	a0,a0,-984 # ffffffffc02026f8 <commands+0x570>
ffffffffc0200ad8:	e06ff06f          	j	ffffffffc02000de <cprintf>
            print_trapframe(tf);
ffffffffc0200adc:	bf15                	j	ffffffffc0200a10 <print_trapframe>

ffffffffc0200ade <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200ade:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200ae2:	1141                	addi	sp,sp,-16
ffffffffc0200ae4:	e022                	sd	s0,0(sp)
ffffffffc0200ae6:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200ae8:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200aea:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200aec:	04e78663          	beq	a5,a4,ffffffffc0200b38 <exception_handler+0x5a>
ffffffffc0200af0:	02f76c63          	bltu	a4,a5,ffffffffc0200b28 <exception_handler+0x4a>
ffffffffc0200af4:	4709                	li	a4,2
ffffffffc0200af6:	02e79563          	bne	a5,a4,ffffffffc0200b20 <exception_handler+0x42>
             /* LAB3 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200afa:	00002517          	auipc	a0,0x2
ffffffffc0200afe:	cc650513          	addi	a0,a0,-826 # ffffffffc02027c0 <commands+0x638>
ffffffffc0200b02:	ddcff0ef          	jal	ra,ffffffffc02000de <cprintf>
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200b06:	10843583          	ld	a1,264(s0)
ffffffffc0200b0a:	00002517          	auipc	a0,0x2
ffffffffc0200b0e:	cde50513          	addi	a0,a0,-802 # ffffffffc02027e8 <commands+0x660>
ffffffffc0200b12:	dccff0ef          	jal	ra,ffffffffc02000de <cprintf>
            tf->epc += 4; 
ffffffffc0200b16:	10843783          	ld	a5,264(s0)
ffffffffc0200b1a:	0791                	addi	a5,a5,4
ffffffffc0200b1c:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b20:	60a2                	ld	ra,8(sp)
ffffffffc0200b22:	6402                	ld	s0,0(sp)
ffffffffc0200b24:	0141                	addi	sp,sp,16
ffffffffc0200b26:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b28:	17f1                	addi	a5,a5,-4
ffffffffc0200b2a:	471d                	li	a4,7
ffffffffc0200b2c:	fef77ae3          	bgeu	a4,a5,ffffffffc0200b20 <exception_handler+0x42>
}
ffffffffc0200b30:	6402                	ld	s0,0(sp)
ffffffffc0200b32:	60a2                	ld	ra,8(sp)
ffffffffc0200b34:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200b36:	bde9                	j	ffffffffc0200a10 <print_trapframe>
            cprintf("Exception type: breakpoint\n");
ffffffffc0200b38:	00002517          	auipc	a0,0x2
ffffffffc0200b3c:	cd850513          	addi	a0,a0,-808 # ffffffffc0202810 <commands+0x688>
ffffffffc0200b40:	d9eff0ef          	jal	ra,ffffffffc02000de <cprintf>
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200b44:	10843583          	ld	a1,264(s0)
ffffffffc0200b48:	00002517          	auipc	a0,0x2
ffffffffc0200b4c:	ce850513          	addi	a0,a0,-792 # ffffffffc0202830 <commands+0x6a8>
ffffffffc0200b50:	d8eff0ef          	jal	ra,ffffffffc02000de <cprintf>
            tf->epc += 4;
ffffffffc0200b54:	10843783          	ld	a5,264(s0)
}
ffffffffc0200b58:	60a2                	ld	ra,8(sp)
            tf->epc += 4;
ffffffffc0200b5a:	0791                	addi	a5,a5,4
ffffffffc0200b5c:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200b60:	6402                	ld	s0,0(sp)
ffffffffc0200b62:	0141                	addi	sp,sp,16
ffffffffc0200b64:	8082                	ret

ffffffffc0200b66 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b66:	11853783          	ld	a5,280(a0)
ffffffffc0200b6a:	0007c363          	bltz	a5,ffffffffc0200b70 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200b6e:	bf85                	j	ffffffffc0200ade <exception_handler>
        interrupt_handler(tf);
ffffffffc0200b70:	b709                	j	ffffffffc0200a72 <interrupt_handler>
	...

ffffffffc0200b74 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b74:	14011073          	csrw	sscratch,sp
ffffffffc0200b78:	712d                	addi	sp,sp,-288
ffffffffc0200b7a:	e002                	sd	zero,0(sp)
ffffffffc0200b7c:	e406                	sd	ra,8(sp)
ffffffffc0200b7e:	ec0e                	sd	gp,24(sp)
ffffffffc0200b80:	f012                	sd	tp,32(sp)
ffffffffc0200b82:	f416                	sd	t0,40(sp)
ffffffffc0200b84:	f81a                	sd	t1,48(sp)
ffffffffc0200b86:	fc1e                	sd	t2,56(sp)
ffffffffc0200b88:	e0a2                	sd	s0,64(sp)
ffffffffc0200b8a:	e4a6                	sd	s1,72(sp)
ffffffffc0200b8c:	e8aa                	sd	a0,80(sp)
ffffffffc0200b8e:	ecae                	sd	a1,88(sp)
ffffffffc0200b90:	f0b2                	sd	a2,96(sp)
ffffffffc0200b92:	f4b6                	sd	a3,104(sp)
ffffffffc0200b94:	f8ba                	sd	a4,112(sp)
ffffffffc0200b96:	fcbe                	sd	a5,120(sp)
ffffffffc0200b98:	e142                	sd	a6,128(sp)
ffffffffc0200b9a:	e546                	sd	a7,136(sp)
ffffffffc0200b9c:	e94a                	sd	s2,144(sp)
ffffffffc0200b9e:	ed4e                	sd	s3,152(sp)
ffffffffc0200ba0:	f152                	sd	s4,160(sp)
ffffffffc0200ba2:	f556                	sd	s5,168(sp)
ffffffffc0200ba4:	f95a                	sd	s6,176(sp)
ffffffffc0200ba6:	fd5e                	sd	s7,184(sp)
ffffffffc0200ba8:	e1e2                	sd	s8,192(sp)
ffffffffc0200baa:	e5e6                	sd	s9,200(sp)
ffffffffc0200bac:	e9ea                	sd	s10,208(sp)
ffffffffc0200bae:	edee                	sd	s11,216(sp)
ffffffffc0200bb0:	f1f2                	sd	t3,224(sp)
ffffffffc0200bb2:	f5f6                	sd	t4,232(sp)
ffffffffc0200bb4:	f9fa                	sd	t5,240(sp)
ffffffffc0200bb6:	fdfe                	sd	t6,248(sp)
ffffffffc0200bb8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200bbc:	100024f3          	csrr	s1,sstatus
ffffffffc0200bc0:	14102973          	csrr	s2,sepc
ffffffffc0200bc4:	143029f3          	csrr	s3,stval
ffffffffc0200bc8:	14202a73          	csrr	s4,scause
ffffffffc0200bcc:	e822                	sd	s0,16(sp)
ffffffffc0200bce:	e226                	sd	s1,256(sp)
ffffffffc0200bd0:	e64a                	sd	s2,264(sp)
ffffffffc0200bd2:	ea4e                	sd	s3,272(sp)
ffffffffc0200bd4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200bd6:	850a                	mv	a0,sp
    jal trap
ffffffffc0200bd8:	f8fff0ef          	jal	ra,ffffffffc0200b66 <trap>

ffffffffc0200bdc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200bdc:	6492                	ld	s1,256(sp)
ffffffffc0200bde:	6932                	ld	s2,264(sp)
ffffffffc0200be0:	10049073          	csrw	sstatus,s1
ffffffffc0200be4:	14191073          	csrw	sepc,s2
ffffffffc0200be8:	60a2                	ld	ra,8(sp)
ffffffffc0200bea:	61e2                	ld	gp,24(sp)
ffffffffc0200bec:	7202                	ld	tp,32(sp)
ffffffffc0200bee:	72a2                	ld	t0,40(sp)
ffffffffc0200bf0:	7342                	ld	t1,48(sp)
ffffffffc0200bf2:	73e2                	ld	t2,56(sp)
ffffffffc0200bf4:	6406                	ld	s0,64(sp)
ffffffffc0200bf6:	64a6                	ld	s1,72(sp)
ffffffffc0200bf8:	6546                	ld	a0,80(sp)
ffffffffc0200bfa:	65e6                	ld	a1,88(sp)
ffffffffc0200bfc:	7606                	ld	a2,96(sp)
ffffffffc0200bfe:	76a6                	ld	a3,104(sp)
ffffffffc0200c00:	7746                	ld	a4,112(sp)
ffffffffc0200c02:	77e6                	ld	a5,120(sp)
ffffffffc0200c04:	680a                	ld	a6,128(sp)
ffffffffc0200c06:	68aa                	ld	a7,136(sp)
ffffffffc0200c08:	694a                	ld	s2,144(sp)
ffffffffc0200c0a:	69ea                	ld	s3,152(sp)
ffffffffc0200c0c:	7a0a                	ld	s4,160(sp)
ffffffffc0200c0e:	7aaa                	ld	s5,168(sp)
ffffffffc0200c10:	7b4a                	ld	s6,176(sp)
ffffffffc0200c12:	7bea                	ld	s7,184(sp)
ffffffffc0200c14:	6c0e                	ld	s8,192(sp)
ffffffffc0200c16:	6cae                	ld	s9,200(sp)
ffffffffc0200c18:	6d4e                	ld	s10,208(sp)
ffffffffc0200c1a:	6dee                	ld	s11,216(sp)
ffffffffc0200c1c:	7e0e                	ld	t3,224(sp)
ffffffffc0200c1e:	7eae                	ld	t4,232(sp)
ffffffffc0200c20:	7f4e                	ld	t5,240(sp)
ffffffffc0200c22:	7fee                	ld	t6,248(sp)
ffffffffc0200c24:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c26:	10200073          	sret

ffffffffc0200c2a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c2a:	00005797          	auipc	a5,0x5
ffffffffc0200c2e:	3f678793          	addi	a5,a5,1014 # ffffffffc0206020 <free_area>
ffffffffc0200c32:	e79c                	sd	a5,8(a5)
ffffffffc0200c34:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c36:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c3a:	8082                	ret

ffffffffc0200c3c <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c3c:	00005517          	auipc	a0,0x5
ffffffffc0200c40:	3f456503          	lwu	a0,1012(a0) # ffffffffc0206030 <free_area+0x10>
ffffffffc0200c44:	8082                	ret

ffffffffc0200c46 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200c46:	715d                	addi	sp,sp,-80
ffffffffc0200c48:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c4a:	00005417          	auipc	s0,0x5
ffffffffc0200c4e:	3d640413          	addi	s0,s0,982 # ffffffffc0206020 <free_area>
ffffffffc0200c52:	641c                	ld	a5,8(s0)
ffffffffc0200c54:	e486                	sd	ra,72(sp)
ffffffffc0200c56:	fc26                	sd	s1,56(sp)
ffffffffc0200c58:	f84a                	sd	s2,48(sp)
ffffffffc0200c5a:	f44e                	sd	s3,40(sp)
ffffffffc0200c5c:	f052                	sd	s4,32(sp)
ffffffffc0200c5e:	ec56                	sd	s5,24(sp)
ffffffffc0200c60:	e85a                	sd	s6,16(sp)
ffffffffc0200c62:	e45e                	sd	s7,8(sp)
ffffffffc0200c64:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c66:	2c878763          	beq	a5,s0,ffffffffc0200f34 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200c6a:	4481                	li	s1,0
ffffffffc0200c6c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c6e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200c72:	8b09                	andi	a4,a4,2
ffffffffc0200c74:	2c070463          	beqz	a4,ffffffffc0200f3c <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200c78:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c7c:	679c                	ld	a5,8(a5)
ffffffffc0200c7e:	2905                	addiw	s2,s2,1
ffffffffc0200c80:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c82:	fe8796e3          	bne	a5,s0,ffffffffc0200c6e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200c86:	89a6                	mv	s3,s1
ffffffffc0200c88:	2f9000ef          	jal	ra,ffffffffc0201780 <nr_free_pages>
ffffffffc0200c8c:	71351863          	bne	a0,s3,ffffffffc020139c <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c90:	4505                	li	a0,1
ffffffffc0200c92:	271000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200c96:	8a2a                	mv	s4,a0
ffffffffc0200c98:	44050263          	beqz	a0,ffffffffc02010dc <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c9c:	4505                	li	a0,1
ffffffffc0200c9e:	265000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200ca2:	89aa                	mv	s3,a0
ffffffffc0200ca4:	70050c63          	beqz	a0,ffffffffc02013bc <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ca8:	4505                	li	a0,1
ffffffffc0200caa:	259000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200cae:	8aaa                	mv	s5,a0
ffffffffc0200cb0:	4a050663          	beqz	a0,ffffffffc020115c <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200cb4:	2b3a0463          	beq	s4,s3,ffffffffc0200f5c <default_check+0x316>
ffffffffc0200cb8:	2aaa0263          	beq	s4,a0,ffffffffc0200f5c <default_check+0x316>
ffffffffc0200cbc:	2aa98063          	beq	s3,a0,ffffffffc0200f5c <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200cc0:	000a2783          	lw	a5,0(s4)
ffffffffc0200cc4:	2a079c63          	bnez	a5,ffffffffc0200f7c <default_check+0x336>
ffffffffc0200cc8:	0009a783          	lw	a5,0(s3)
ffffffffc0200ccc:	2a079863          	bnez	a5,ffffffffc0200f7c <default_check+0x336>
ffffffffc0200cd0:	411c                	lw	a5,0(a0)
ffffffffc0200cd2:	2a079563          	bnez	a5,ffffffffc0200f7c <default_check+0x336>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cd6:	00005797          	auipc	a5,0x5
ffffffffc0200cda:	78a7b783          	ld	a5,1930(a5) # ffffffffc0206460 <pages>
ffffffffc0200cde:	40fa0733          	sub	a4,s4,a5
ffffffffc0200ce2:	870d                	srai	a4,a4,0x3
ffffffffc0200ce4:	00002597          	auipc	a1,0x2
ffffffffc0200ce8:	2f45b583          	ld	a1,756(a1) # ffffffffc0202fd8 <error_string+0x38>
ffffffffc0200cec:	02b70733          	mul	a4,a4,a1
ffffffffc0200cf0:	00002617          	auipc	a2,0x2
ffffffffc0200cf4:	2f063603          	ld	a2,752(a2) # ffffffffc0202fe0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200cf8:	00005697          	auipc	a3,0x5
ffffffffc0200cfc:	7606b683          	ld	a3,1888(a3) # ffffffffc0206458 <npage>
ffffffffc0200d00:	06b2                	slli	a3,a3,0xc
ffffffffc0200d02:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d04:	0732                	slli	a4,a4,0xc
ffffffffc0200d06:	28d77b63          	bgeu	a4,a3,ffffffffc0200f9c <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d0a:	40f98733          	sub	a4,s3,a5
ffffffffc0200d0e:	870d                	srai	a4,a4,0x3
ffffffffc0200d10:	02b70733          	mul	a4,a4,a1
ffffffffc0200d14:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d16:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d18:	4cd77263          	bgeu	a4,a3,ffffffffc02011dc <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d1c:	40f507b3          	sub	a5,a0,a5
ffffffffc0200d20:	878d                	srai	a5,a5,0x3
ffffffffc0200d22:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d26:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d28:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d2a:	30d7f963          	bgeu	a5,a3,ffffffffc020103c <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200d2e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d30:	00043c03          	ld	s8,0(s0)
ffffffffc0200d34:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200d38:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200d3c:	e400                	sd	s0,8(s0)
ffffffffc0200d3e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200d40:	00005797          	auipc	a5,0x5
ffffffffc0200d44:	2e07a823          	sw	zero,752(a5) # ffffffffc0206030 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200d48:	1bb000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200d4c:	2c051863          	bnez	a0,ffffffffc020101c <default_check+0x3d6>
    free_page(p0);
ffffffffc0200d50:	4585                	li	a1,1
ffffffffc0200d52:	8552                	mv	a0,s4
ffffffffc0200d54:	1ed000ef          	jal	ra,ffffffffc0201740 <free_pages>
    free_page(p1);
ffffffffc0200d58:	4585                	li	a1,1
ffffffffc0200d5a:	854e                	mv	a0,s3
ffffffffc0200d5c:	1e5000ef          	jal	ra,ffffffffc0201740 <free_pages>
    free_page(p2);
ffffffffc0200d60:	4585                	li	a1,1
ffffffffc0200d62:	8556                	mv	a0,s5
ffffffffc0200d64:	1dd000ef          	jal	ra,ffffffffc0201740 <free_pages>
    assert(nr_free == 3);
ffffffffc0200d68:	4818                	lw	a4,16(s0)
ffffffffc0200d6a:	478d                	li	a5,3
ffffffffc0200d6c:	28f71863          	bne	a4,a5,ffffffffc0200ffc <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d70:	4505                	li	a0,1
ffffffffc0200d72:	191000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200d76:	89aa                	mv	s3,a0
ffffffffc0200d78:	26050263          	beqz	a0,ffffffffc0200fdc <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d7c:	4505                	li	a0,1
ffffffffc0200d7e:	185000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200d82:	8aaa                	mv	s5,a0
ffffffffc0200d84:	3a050c63          	beqz	a0,ffffffffc020113c <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d88:	4505                	li	a0,1
ffffffffc0200d8a:	179000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200d8e:	8a2a                	mv	s4,a0
ffffffffc0200d90:	38050663          	beqz	a0,ffffffffc020111c <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200d94:	4505                	li	a0,1
ffffffffc0200d96:	16d000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200d9a:	36051163          	bnez	a0,ffffffffc02010fc <default_check+0x4b6>
    free_page(p0);
ffffffffc0200d9e:	4585                	li	a1,1
ffffffffc0200da0:	854e                	mv	a0,s3
ffffffffc0200da2:	19f000ef          	jal	ra,ffffffffc0201740 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200da6:	641c                	ld	a5,8(s0)
ffffffffc0200da8:	20878a63          	beq	a5,s0,ffffffffc0200fbc <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200dac:	4505                	li	a0,1
ffffffffc0200dae:	155000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200db2:	30a99563          	bne	s3,a0,ffffffffc02010bc <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0200db6:	4505                	li	a0,1
ffffffffc0200db8:	14b000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200dbc:	2e051063          	bnez	a0,ffffffffc020109c <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0200dc0:	481c                	lw	a5,16(s0)
ffffffffc0200dc2:	2a079d63          	bnez	a5,ffffffffc020107c <default_check+0x436>
    free_page(p);
ffffffffc0200dc6:	854e                	mv	a0,s3
ffffffffc0200dc8:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200dca:	01843023          	sd	s8,0(s0)
ffffffffc0200dce:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200dd2:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200dd6:	16b000ef          	jal	ra,ffffffffc0201740 <free_pages>
    free_page(p1);
ffffffffc0200dda:	4585                	li	a1,1
ffffffffc0200ddc:	8556                	mv	a0,s5
ffffffffc0200dde:	163000ef          	jal	ra,ffffffffc0201740 <free_pages>
    free_page(p2);
ffffffffc0200de2:	4585                	li	a1,1
ffffffffc0200de4:	8552                	mv	a0,s4
ffffffffc0200de6:	15b000ef          	jal	ra,ffffffffc0201740 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200dea:	4515                	li	a0,5
ffffffffc0200dec:	117000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200df0:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200df2:	26050563          	beqz	a0,ffffffffc020105c <default_check+0x416>
ffffffffc0200df6:	651c                	ld	a5,8(a0)
ffffffffc0200df8:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200dfa:	8b85                	andi	a5,a5,1
ffffffffc0200dfc:	54079063          	bnez	a5,ffffffffc020133c <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200e00:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e02:	00043b03          	ld	s6,0(s0)
ffffffffc0200e06:	00843a83          	ld	s5,8(s0)
ffffffffc0200e0a:	e000                	sd	s0,0(s0)
ffffffffc0200e0c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200e0e:	0f5000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200e12:	50051563          	bnez	a0,ffffffffc020131c <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200e16:	05098a13          	addi	s4,s3,80
ffffffffc0200e1a:	8552                	mv	a0,s4
ffffffffc0200e1c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200e1e:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200e22:	00005797          	auipc	a5,0x5
ffffffffc0200e26:	2007a723          	sw	zero,526(a5) # ffffffffc0206030 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200e2a:	117000ef          	jal	ra,ffffffffc0201740 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e2e:	4511                	li	a0,4
ffffffffc0200e30:	0d3000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200e34:	4c051463          	bnez	a0,ffffffffc02012fc <default_check+0x6b6>
ffffffffc0200e38:	0589b783          	ld	a5,88(s3)
ffffffffc0200e3c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200e3e:	8b85                	andi	a5,a5,1
ffffffffc0200e40:	48078e63          	beqz	a5,ffffffffc02012dc <default_check+0x696>
ffffffffc0200e44:	0609a703          	lw	a4,96(s3)
ffffffffc0200e48:	478d                	li	a5,3
ffffffffc0200e4a:	48f71963          	bne	a4,a5,ffffffffc02012dc <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200e4e:	450d                	li	a0,3
ffffffffc0200e50:	0b3000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200e54:	8c2a                	mv	s8,a0
ffffffffc0200e56:	46050363          	beqz	a0,ffffffffc02012bc <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0200e5a:	4505                	li	a0,1
ffffffffc0200e5c:	0a7000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200e60:	42051e63          	bnez	a0,ffffffffc020129c <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0200e64:	418a1c63          	bne	s4,s8,ffffffffc020127c <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200e68:	4585                	li	a1,1
ffffffffc0200e6a:	854e                	mv	a0,s3
ffffffffc0200e6c:	0d5000ef          	jal	ra,ffffffffc0201740 <free_pages>
    free_pages(p1, 3);
ffffffffc0200e70:	458d                	li	a1,3
ffffffffc0200e72:	8552                	mv	a0,s4
ffffffffc0200e74:	0cd000ef          	jal	ra,ffffffffc0201740 <free_pages>
ffffffffc0200e78:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200e7c:	02898c13          	addi	s8,s3,40
ffffffffc0200e80:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200e82:	8b85                	andi	a5,a5,1
ffffffffc0200e84:	3c078c63          	beqz	a5,ffffffffc020125c <default_check+0x616>
ffffffffc0200e88:	0109a703          	lw	a4,16(s3)
ffffffffc0200e8c:	4785                	li	a5,1
ffffffffc0200e8e:	3cf71763          	bne	a4,a5,ffffffffc020125c <default_check+0x616>
ffffffffc0200e92:	008a3783          	ld	a5,8(s4)
ffffffffc0200e96:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200e98:	8b85                	andi	a5,a5,1
ffffffffc0200e9a:	3a078163          	beqz	a5,ffffffffc020123c <default_check+0x5f6>
ffffffffc0200e9e:	010a2703          	lw	a4,16(s4)
ffffffffc0200ea2:	478d                	li	a5,3
ffffffffc0200ea4:	38f71c63          	bne	a4,a5,ffffffffc020123c <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200ea8:	4505                	li	a0,1
ffffffffc0200eaa:	059000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200eae:	36a99763          	bne	s3,a0,ffffffffc020121c <default_check+0x5d6>
    free_page(p0);
ffffffffc0200eb2:	4585                	li	a1,1
ffffffffc0200eb4:	08d000ef          	jal	ra,ffffffffc0201740 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200eb8:	4509                	li	a0,2
ffffffffc0200eba:	049000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200ebe:	32aa1f63          	bne	s4,a0,ffffffffc02011fc <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0200ec2:	4589                	li	a1,2
ffffffffc0200ec4:	07d000ef          	jal	ra,ffffffffc0201740 <free_pages>
    free_page(p2);
ffffffffc0200ec8:	4585                	li	a1,1
ffffffffc0200eca:	8562                	mv	a0,s8
ffffffffc0200ecc:	075000ef          	jal	ra,ffffffffc0201740 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ed0:	4515                	li	a0,5
ffffffffc0200ed2:	031000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200ed6:	89aa                	mv	s3,a0
ffffffffc0200ed8:	48050263          	beqz	a0,ffffffffc020135c <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0200edc:	4505                	li	a0,1
ffffffffc0200ede:	025000ef          	jal	ra,ffffffffc0201702 <alloc_pages>
ffffffffc0200ee2:	2c051d63          	bnez	a0,ffffffffc02011bc <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0200ee6:	481c                	lw	a5,16(s0)
ffffffffc0200ee8:	2a079a63          	bnez	a5,ffffffffc020119c <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200eec:	4595                	li	a1,5
ffffffffc0200eee:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200ef0:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200ef4:	01643023          	sd	s6,0(s0)
ffffffffc0200ef8:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200efc:	045000ef          	jal	ra,ffffffffc0201740 <free_pages>
    return listelm->next;
ffffffffc0200f00:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f02:	00878963          	beq	a5,s0,ffffffffc0200f14 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200f06:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f0a:	679c                	ld	a5,8(a5)
ffffffffc0200f0c:	397d                	addiw	s2,s2,-1
ffffffffc0200f0e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f10:	fe879be3          	bne	a5,s0,ffffffffc0200f06 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0200f14:	26091463          	bnez	s2,ffffffffc020117c <default_check+0x536>
    assert(total == 0);
ffffffffc0200f18:	46049263          	bnez	s1,ffffffffc020137c <default_check+0x736>
}
ffffffffc0200f1c:	60a6                	ld	ra,72(sp)
ffffffffc0200f1e:	6406                	ld	s0,64(sp)
ffffffffc0200f20:	74e2                	ld	s1,56(sp)
ffffffffc0200f22:	7942                	ld	s2,48(sp)
ffffffffc0200f24:	79a2                	ld	s3,40(sp)
ffffffffc0200f26:	7a02                	ld	s4,32(sp)
ffffffffc0200f28:	6ae2                	ld	s5,24(sp)
ffffffffc0200f2a:	6b42                	ld	s6,16(sp)
ffffffffc0200f2c:	6ba2                	ld	s7,8(sp)
ffffffffc0200f2e:	6c02                	ld	s8,0(sp)
ffffffffc0200f30:	6161                	addi	sp,sp,80
ffffffffc0200f32:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f34:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200f36:	4481                	li	s1,0
ffffffffc0200f38:	4901                	li	s2,0
ffffffffc0200f3a:	b3b9                	j	ffffffffc0200c88 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200f3c:	00002697          	auipc	a3,0x2
ffffffffc0200f40:	91468693          	addi	a3,a3,-1772 # ffffffffc0202850 <commands+0x6c8>
ffffffffc0200f44:	00002617          	auipc	a2,0x2
ffffffffc0200f48:	91c60613          	addi	a2,a2,-1764 # ffffffffc0202860 <commands+0x6d8>
ffffffffc0200f4c:	0f000593          	li	a1,240
ffffffffc0200f50:	00002517          	auipc	a0,0x2
ffffffffc0200f54:	92850513          	addi	a0,a0,-1752 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0200f58:	c80ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f5c:	00002697          	auipc	a3,0x2
ffffffffc0200f60:	9b468693          	addi	a3,a3,-1612 # ffffffffc0202910 <commands+0x788>
ffffffffc0200f64:	00002617          	auipc	a2,0x2
ffffffffc0200f68:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0202860 <commands+0x6d8>
ffffffffc0200f6c:	0bd00593          	li	a1,189
ffffffffc0200f70:	00002517          	auipc	a0,0x2
ffffffffc0200f74:	90850513          	addi	a0,a0,-1784 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0200f78:	c60ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f7c:	00002697          	auipc	a3,0x2
ffffffffc0200f80:	9bc68693          	addi	a3,a3,-1604 # ffffffffc0202938 <commands+0x7b0>
ffffffffc0200f84:	00002617          	auipc	a2,0x2
ffffffffc0200f88:	8dc60613          	addi	a2,a2,-1828 # ffffffffc0202860 <commands+0x6d8>
ffffffffc0200f8c:	0be00593          	li	a1,190
ffffffffc0200f90:	00002517          	auipc	a0,0x2
ffffffffc0200f94:	8e850513          	addi	a0,a0,-1816 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0200f98:	c40ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f9c:	00002697          	auipc	a3,0x2
ffffffffc0200fa0:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0202978 <commands+0x7f0>
ffffffffc0200fa4:	00002617          	auipc	a2,0x2
ffffffffc0200fa8:	8bc60613          	addi	a2,a2,-1860 # ffffffffc0202860 <commands+0x6d8>
ffffffffc0200fac:	0c000593          	li	a1,192
ffffffffc0200fb0:	00002517          	auipc	a0,0x2
ffffffffc0200fb4:	8c850513          	addi	a0,a0,-1848 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0200fb8:	c20ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200fbc:	00002697          	auipc	a3,0x2
ffffffffc0200fc0:	a4468693          	addi	a3,a3,-1468 # ffffffffc0202a00 <commands+0x878>
ffffffffc0200fc4:	00002617          	auipc	a2,0x2
ffffffffc0200fc8:	89c60613          	addi	a2,a2,-1892 # ffffffffc0202860 <commands+0x6d8>
ffffffffc0200fcc:	0d900593          	li	a1,217
ffffffffc0200fd0:	00002517          	auipc	a0,0x2
ffffffffc0200fd4:	8a850513          	addi	a0,a0,-1880 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0200fd8:	c00ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fdc:	00002697          	auipc	a3,0x2
ffffffffc0200fe0:	8d468693          	addi	a3,a3,-1836 # ffffffffc02028b0 <commands+0x728>
ffffffffc0200fe4:	00002617          	auipc	a2,0x2
ffffffffc0200fe8:	87c60613          	addi	a2,a2,-1924 # ffffffffc0202860 <commands+0x6d8>
ffffffffc0200fec:	0d200593          	li	a1,210
ffffffffc0200ff0:	00002517          	auipc	a0,0x2
ffffffffc0200ff4:	88850513          	addi	a0,a0,-1912 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0200ff8:	be0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(nr_free == 3);
ffffffffc0200ffc:	00002697          	auipc	a3,0x2
ffffffffc0201000:	9f468693          	addi	a3,a3,-1548 # ffffffffc02029f0 <commands+0x868>
ffffffffc0201004:	00002617          	auipc	a2,0x2
ffffffffc0201008:	85c60613          	addi	a2,a2,-1956 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020100c:	0d000593          	li	a1,208
ffffffffc0201010:	00002517          	auipc	a0,0x2
ffffffffc0201014:	86850513          	addi	a0,a0,-1944 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201018:	bc0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020101c:	00002697          	auipc	a3,0x2
ffffffffc0201020:	9bc68693          	addi	a3,a3,-1604 # ffffffffc02029d8 <commands+0x850>
ffffffffc0201024:	00002617          	auipc	a2,0x2
ffffffffc0201028:	83c60613          	addi	a2,a2,-1988 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020102c:	0cb00593          	li	a1,203
ffffffffc0201030:	00002517          	auipc	a0,0x2
ffffffffc0201034:	84850513          	addi	a0,a0,-1976 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201038:	ba0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020103c:	00002697          	auipc	a3,0x2
ffffffffc0201040:	97c68693          	addi	a3,a3,-1668 # ffffffffc02029b8 <commands+0x830>
ffffffffc0201044:	00002617          	auipc	a2,0x2
ffffffffc0201048:	81c60613          	addi	a2,a2,-2020 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020104c:	0c200593          	li	a1,194
ffffffffc0201050:	00002517          	auipc	a0,0x2
ffffffffc0201054:	82850513          	addi	a0,a0,-2008 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201058:	b80ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(p0 != NULL);
ffffffffc020105c:	00002697          	auipc	a3,0x2
ffffffffc0201060:	9ec68693          	addi	a3,a3,-1556 # ffffffffc0202a48 <commands+0x8c0>
ffffffffc0201064:	00001617          	auipc	a2,0x1
ffffffffc0201068:	7fc60613          	addi	a2,a2,2044 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020106c:	0f800593          	li	a1,248
ffffffffc0201070:	00002517          	auipc	a0,0x2
ffffffffc0201074:	80850513          	addi	a0,a0,-2040 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201078:	b60ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(nr_free == 0);
ffffffffc020107c:	00002697          	auipc	a3,0x2
ffffffffc0201080:	9bc68693          	addi	a3,a3,-1604 # ffffffffc0202a38 <commands+0x8b0>
ffffffffc0201084:	00001617          	auipc	a2,0x1
ffffffffc0201088:	7dc60613          	addi	a2,a2,2012 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020108c:	0df00593          	li	a1,223
ffffffffc0201090:	00001517          	auipc	a0,0x1
ffffffffc0201094:	7e850513          	addi	a0,a0,2024 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201098:	b40ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020109c:	00002697          	auipc	a3,0x2
ffffffffc02010a0:	93c68693          	addi	a3,a3,-1732 # ffffffffc02029d8 <commands+0x850>
ffffffffc02010a4:	00001617          	auipc	a2,0x1
ffffffffc02010a8:	7bc60613          	addi	a2,a2,1980 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02010ac:	0dd00593          	li	a1,221
ffffffffc02010b0:	00001517          	auipc	a0,0x1
ffffffffc02010b4:	7c850513          	addi	a0,a0,1992 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02010b8:	b20ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02010bc:	00002697          	auipc	a3,0x2
ffffffffc02010c0:	95c68693          	addi	a3,a3,-1700 # ffffffffc0202a18 <commands+0x890>
ffffffffc02010c4:	00001617          	auipc	a2,0x1
ffffffffc02010c8:	79c60613          	addi	a2,a2,1948 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02010cc:	0dc00593          	li	a1,220
ffffffffc02010d0:	00001517          	auipc	a0,0x1
ffffffffc02010d4:	7a850513          	addi	a0,a0,1960 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02010d8:	b00ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010dc:	00001697          	auipc	a3,0x1
ffffffffc02010e0:	7d468693          	addi	a3,a3,2004 # ffffffffc02028b0 <commands+0x728>
ffffffffc02010e4:	00001617          	auipc	a2,0x1
ffffffffc02010e8:	77c60613          	addi	a2,a2,1916 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02010ec:	0b900593          	li	a1,185
ffffffffc02010f0:	00001517          	auipc	a0,0x1
ffffffffc02010f4:	78850513          	addi	a0,a0,1928 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02010f8:	ae0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010fc:	00002697          	auipc	a3,0x2
ffffffffc0201100:	8dc68693          	addi	a3,a3,-1828 # ffffffffc02029d8 <commands+0x850>
ffffffffc0201104:	00001617          	auipc	a2,0x1
ffffffffc0201108:	75c60613          	addi	a2,a2,1884 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020110c:	0d600593          	li	a1,214
ffffffffc0201110:	00001517          	auipc	a0,0x1
ffffffffc0201114:	76850513          	addi	a0,a0,1896 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201118:	ac0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020111c:	00001697          	auipc	a3,0x1
ffffffffc0201120:	7d468693          	addi	a3,a3,2004 # ffffffffc02028f0 <commands+0x768>
ffffffffc0201124:	00001617          	auipc	a2,0x1
ffffffffc0201128:	73c60613          	addi	a2,a2,1852 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020112c:	0d400593          	li	a1,212
ffffffffc0201130:	00001517          	auipc	a0,0x1
ffffffffc0201134:	74850513          	addi	a0,a0,1864 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201138:	aa0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020113c:	00001697          	auipc	a3,0x1
ffffffffc0201140:	79468693          	addi	a3,a3,1940 # ffffffffc02028d0 <commands+0x748>
ffffffffc0201144:	00001617          	auipc	a2,0x1
ffffffffc0201148:	71c60613          	addi	a2,a2,1820 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020114c:	0d300593          	li	a1,211
ffffffffc0201150:	00001517          	auipc	a0,0x1
ffffffffc0201154:	72850513          	addi	a0,a0,1832 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201158:	a80ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020115c:	00001697          	auipc	a3,0x1
ffffffffc0201160:	79468693          	addi	a3,a3,1940 # ffffffffc02028f0 <commands+0x768>
ffffffffc0201164:	00001617          	auipc	a2,0x1
ffffffffc0201168:	6fc60613          	addi	a2,a2,1788 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020116c:	0bb00593          	li	a1,187
ffffffffc0201170:	00001517          	auipc	a0,0x1
ffffffffc0201174:	70850513          	addi	a0,a0,1800 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201178:	a60ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(count == 0);
ffffffffc020117c:	00002697          	auipc	a3,0x2
ffffffffc0201180:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0202b98 <commands+0xa10>
ffffffffc0201184:	00001617          	auipc	a2,0x1
ffffffffc0201188:	6dc60613          	addi	a2,a2,1756 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020118c:	12500593          	li	a1,293
ffffffffc0201190:	00001517          	auipc	a0,0x1
ffffffffc0201194:	6e850513          	addi	a0,a0,1768 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201198:	a40ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(nr_free == 0);
ffffffffc020119c:	00002697          	auipc	a3,0x2
ffffffffc02011a0:	89c68693          	addi	a3,a3,-1892 # ffffffffc0202a38 <commands+0x8b0>
ffffffffc02011a4:	00001617          	auipc	a2,0x1
ffffffffc02011a8:	6bc60613          	addi	a2,a2,1724 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02011ac:	11a00593          	li	a1,282
ffffffffc02011b0:	00001517          	auipc	a0,0x1
ffffffffc02011b4:	6c850513          	addi	a0,a0,1736 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02011b8:	a20ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011bc:	00002697          	auipc	a3,0x2
ffffffffc02011c0:	81c68693          	addi	a3,a3,-2020 # ffffffffc02029d8 <commands+0x850>
ffffffffc02011c4:	00001617          	auipc	a2,0x1
ffffffffc02011c8:	69c60613          	addi	a2,a2,1692 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02011cc:	11800593          	li	a1,280
ffffffffc02011d0:	00001517          	auipc	a0,0x1
ffffffffc02011d4:	6a850513          	addi	a0,a0,1704 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02011d8:	a00ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02011dc:	00001697          	auipc	a3,0x1
ffffffffc02011e0:	7bc68693          	addi	a3,a3,1980 # ffffffffc0202998 <commands+0x810>
ffffffffc02011e4:	00001617          	auipc	a2,0x1
ffffffffc02011e8:	67c60613          	addi	a2,a2,1660 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02011ec:	0c100593          	li	a1,193
ffffffffc02011f0:	00001517          	auipc	a0,0x1
ffffffffc02011f4:	68850513          	addi	a0,a0,1672 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02011f8:	9e0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02011fc:	00002697          	auipc	a3,0x2
ffffffffc0201200:	95c68693          	addi	a3,a3,-1700 # ffffffffc0202b58 <commands+0x9d0>
ffffffffc0201204:	00001617          	auipc	a2,0x1
ffffffffc0201208:	65c60613          	addi	a2,a2,1628 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020120c:	11200593          	li	a1,274
ffffffffc0201210:	00001517          	auipc	a0,0x1
ffffffffc0201214:	66850513          	addi	a0,a0,1640 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201218:	9c0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020121c:	00002697          	auipc	a3,0x2
ffffffffc0201220:	91c68693          	addi	a3,a3,-1764 # ffffffffc0202b38 <commands+0x9b0>
ffffffffc0201224:	00001617          	auipc	a2,0x1
ffffffffc0201228:	63c60613          	addi	a2,a2,1596 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020122c:	11000593          	li	a1,272
ffffffffc0201230:	00001517          	auipc	a0,0x1
ffffffffc0201234:	64850513          	addi	a0,a0,1608 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201238:	9a0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020123c:	00002697          	auipc	a3,0x2
ffffffffc0201240:	8d468693          	addi	a3,a3,-1836 # ffffffffc0202b10 <commands+0x988>
ffffffffc0201244:	00001617          	auipc	a2,0x1
ffffffffc0201248:	61c60613          	addi	a2,a2,1564 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020124c:	10e00593          	li	a1,270
ffffffffc0201250:	00001517          	auipc	a0,0x1
ffffffffc0201254:	62850513          	addi	a0,a0,1576 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201258:	980ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020125c:	00002697          	auipc	a3,0x2
ffffffffc0201260:	88c68693          	addi	a3,a3,-1908 # ffffffffc0202ae8 <commands+0x960>
ffffffffc0201264:	00001617          	auipc	a2,0x1
ffffffffc0201268:	5fc60613          	addi	a2,a2,1532 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020126c:	10d00593          	li	a1,269
ffffffffc0201270:	00001517          	auipc	a0,0x1
ffffffffc0201274:	60850513          	addi	a0,a0,1544 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201278:	960ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(p0 + 2 == p1);
ffffffffc020127c:	00002697          	auipc	a3,0x2
ffffffffc0201280:	85c68693          	addi	a3,a3,-1956 # ffffffffc0202ad8 <commands+0x950>
ffffffffc0201284:	00001617          	auipc	a2,0x1
ffffffffc0201288:	5dc60613          	addi	a2,a2,1500 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020128c:	10800593          	li	a1,264
ffffffffc0201290:	00001517          	auipc	a0,0x1
ffffffffc0201294:	5e850513          	addi	a0,a0,1512 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201298:	940ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020129c:	00001697          	auipc	a3,0x1
ffffffffc02012a0:	73c68693          	addi	a3,a3,1852 # ffffffffc02029d8 <commands+0x850>
ffffffffc02012a4:	00001617          	auipc	a2,0x1
ffffffffc02012a8:	5bc60613          	addi	a2,a2,1468 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02012ac:	10700593          	li	a1,263
ffffffffc02012b0:	00001517          	auipc	a0,0x1
ffffffffc02012b4:	5c850513          	addi	a0,a0,1480 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02012b8:	920ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02012bc:	00001697          	auipc	a3,0x1
ffffffffc02012c0:	7fc68693          	addi	a3,a3,2044 # ffffffffc0202ab8 <commands+0x930>
ffffffffc02012c4:	00001617          	auipc	a2,0x1
ffffffffc02012c8:	59c60613          	addi	a2,a2,1436 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02012cc:	10600593          	li	a1,262
ffffffffc02012d0:	00001517          	auipc	a0,0x1
ffffffffc02012d4:	5a850513          	addi	a0,a0,1448 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02012d8:	900ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02012dc:	00001697          	auipc	a3,0x1
ffffffffc02012e0:	7ac68693          	addi	a3,a3,1964 # ffffffffc0202a88 <commands+0x900>
ffffffffc02012e4:	00001617          	auipc	a2,0x1
ffffffffc02012e8:	57c60613          	addi	a2,a2,1404 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02012ec:	10500593          	li	a1,261
ffffffffc02012f0:	00001517          	auipc	a0,0x1
ffffffffc02012f4:	58850513          	addi	a0,a0,1416 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02012f8:	8e0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02012fc:	00001697          	auipc	a3,0x1
ffffffffc0201300:	77468693          	addi	a3,a3,1908 # ffffffffc0202a70 <commands+0x8e8>
ffffffffc0201304:	00001617          	auipc	a2,0x1
ffffffffc0201308:	55c60613          	addi	a2,a2,1372 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020130c:	10400593          	li	a1,260
ffffffffc0201310:	00001517          	auipc	a0,0x1
ffffffffc0201314:	56850513          	addi	a0,a0,1384 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201318:	8c0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020131c:	00001697          	auipc	a3,0x1
ffffffffc0201320:	6bc68693          	addi	a3,a3,1724 # ffffffffc02029d8 <commands+0x850>
ffffffffc0201324:	00001617          	auipc	a2,0x1
ffffffffc0201328:	53c60613          	addi	a2,a2,1340 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020132c:	0fe00593          	li	a1,254
ffffffffc0201330:	00001517          	auipc	a0,0x1
ffffffffc0201334:	54850513          	addi	a0,a0,1352 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201338:	8a0ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(!PageProperty(p0));
ffffffffc020133c:	00001697          	auipc	a3,0x1
ffffffffc0201340:	71c68693          	addi	a3,a3,1820 # ffffffffc0202a58 <commands+0x8d0>
ffffffffc0201344:	00001617          	auipc	a2,0x1
ffffffffc0201348:	51c60613          	addi	a2,a2,1308 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020134c:	0f900593          	li	a1,249
ffffffffc0201350:	00001517          	auipc	a0,0x1
ffffffffc0201354:	52850513          	addi	a0,a0,1320 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201358:	880ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020135c:	00002697          	auipc	a3,0x2
ffffffffc0201360:	81c68693          	addi	a3,a3,-2020 # ffffffffc0202b78 <commands+0x9f0>
ffffffffc0201364:	00001617          	auipc	a2,0x1
ffffffffc0201368:	4fc60613          	addi	a2,a2,1276 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020136c:	11700593          	li	a1,279
ffffffffc0201370:	00001517          	auipc	a0,0x1
ffffffffc0201374:	50850513          	addi	a0,a0,1288 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201378:	860ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(total == 0);
ffffffffc020137c:	00002697          	auipc	a3,0x2
ffffffffc0201380:	82c68693          	addi	a3,a3,-2004 # ffffffffc0202ba8 <commands+0xa20>
ffffffffc0201384:	00001617          	auipc	a2,0x1
ffffffffc0201388:	4dc60613          	addi	a2,a2,1244 # ffffffffc0202860 <commands+0x6d8>
ffffffffc020138c:	12600593          	li	a1,294
ffffffffc0201390:	00001517          	auipc	a0,0x1
ffffffffc0201394:	4e850513          	addi	a0,a0,1256 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201398:	840ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(total == nr_free_pages());
ffffffffc020139c:	00001697          	auipc	a3,0x1
ffffffffc02013a0:	4f468693          	addi	a3,a3,1268 # ffffffffc0202890 <commands+0x708>
ffffffffc02013a4:	00001617          	auipc	a2,0x1
ffffffffc02013a8:	4bc60613          	addi	a2,a2,1212 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02013ac:	0f300593          	li	a1,243
ffffffffc02013b0:	00001517          	auipc	a0,0x1
ffffffffc02013b4:	4c850513          	addi	a0,a0,1224 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02013b8:	820ff0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013bc:	00001697          	auipc	a3,0x1
ffffffffc02013c0:	51468693          	addi	a3,a3,1300 # ffffffffc02028d0 <commands+0x748>
ffffffffc02013c4:	00001617          	auipc	a2,0x1
ffffffffc02013c8:	49c60613          	addi	a2,a2,1180 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02013cc:	0ba00593          	li	a1,186
ffffffffc02013d0:	00001517          	auipc	a0,0x1
ffffffffc02013d4:	4a850513          	addi	a0,a0,1192 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02013d8:	800ff0ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc02013dc <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02013dc:	1141                	addi	sp,sp,-16
ffffffffc02013de:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02013e0:	14058a63          	beqz	a1,ffffffffc0201534 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc02013e4:	00259693          	slli	a3,a1,0x2
ffffffffc02013e8:	96ae                	add	a3,a3,a1
ffffffffc02013ea:	068e                	slli	a3,a3,0x3
ffffffffc02013ec:	96aa                	add	a3,a3,a0
ffffffffc02013ee:	87aa                	mv	a5,a0
ffffffffc02013f0:	02d50263          	beq	a0,a3,ffffffffc0201414 <default_free_pages+0x38>
ffffffffc02013f4:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02013f6:	8b05                	andi	a4,a4,1
ffffffffc02013f8:	10071e63          	bnez	a4,ffffffffc0201514 <default_free_pages+0x138>
ffffffffc02013fc:	6798                	ld	a4,8(a5)
ffffffffc02013fe:	8b09                	andi	a4,a4,2
ffffffffc0201400:	10071a63          	bnez	a4,ffffffffc0201514 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc0201404:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201408:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020140c:	02878793          	addi	a5,a5,40
ffffffffc0201410:	fed792e3          	bne	a5,a3,ffffffffc02013f4 <default_free_pages+0x18>
    base->property = n;
ffffffffc0201414:	2581                	sext.w	a1,a1
ffffffffc0201416:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201418:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020141c:	4789                	li	a5,2
ffffffffc020141e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201422:	00005697          	auipc	a3,0x5
ffffffffc0201426:	bfe68693          	addi	a3,a3,-1026 # ffffffffc0206020 <free_area>
ffffffffc020142a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020142c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020142e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201432:	9db9                	addw	a1,a1,a4
ffffffffc0201434:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201436:	0ad78863          	beq	a5,a3,ffffffffc02014e6 <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc020143a:	fe878713          	addi	a4,a5,-24
ffffffffc020143e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201442:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201444:	00e56a63          	bltu	a0,a4,ffffffffc0201458 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc0201448:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020144a:	06d70263          	beq	a4,a3,ffffffffc02014ae <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc020144e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201450:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201454:	fee57ae3          	bgeu	a0,a4,ffffffffc0201448 <default_free_pages+0x6c>
ffffffffc0201458:	c199                	beqz	a1,ffffffffc020145e <default_free_pages+0x82>
ffffffffc020145a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020145e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201460:	e390                	sd	a2,0(a5)
ffffffffc0201462:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201464:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201466:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201468:	02d70063          	beq	a4,a3,ffffffffc0201488 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc020146c:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201470:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201474:	02081613          	slli	a2,a6,0x20
ffffffffc0201478:	9201                	srli	a2,a2,0x20
ffffffffc020147a:	00261793          	slli	a5,a2,0x2
ffffffffc020147e:	97b2                	add	a5,a5,a2
ffffffffc0201480:	078e                	slli	a5,a5,0x3
ffffffffc0201482:	97ae                	add	a5,a5,a1
ffffffffc0201484:	02f50f63          	beq	a0,a5,ffffffffc02014c2 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc0201488:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020148a:	00d70f63          	beq	a4,a3,ffffffffc02014a8 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc020148e:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201490:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201494:	02059613          	slli	a2,a1,0x20
ffffffffc0201498:	9201                	srli	a2,a2,0x20
ffffffffc020149a:	00261793          	slli	a5,a2,0x2
ffffffffc020149e:	97b2                	add	a5,a5,a2
ffffffffc02014a0:	078e                	slli	a5,a5,0x3
ffffffffc02014a2:	97aa                	add	a5,a5,a0
ffffffffc02014a4:	04f68863          	beq	a3,a5,ffffffffc02014f4 <default_free_pages+0x118>
}
ffffffffc02014a8:	60a2                	ld	ra,8(sp)
ffffffffc02014aa:	0141                	addi	sp,sp,16
ffffffffc02014ac:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02014ae:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014b0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02014b2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02014b4:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014b6:	02d70563          	beq	a4,a3,ffffffffc02014e0 <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc02014ba:	8832                	mv	a6,a2
ffffffffc02014bc:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02014be:	87ba                	mv	a5,a4
ffffffffc02014c0:	bf41                	j	ffffffffc0201450 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc02014c2:	491c                	lw	a5,16(a0)
ffffffffc02014c4:	0107883b          	addw	a6,a5,a6
ffffffffc02014c8:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014cc:	57f5                	li	a5,-3
ffffffffc02014ce:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014d2:	6d10                	ld	a2,24(a0)
ffffffffc02014d4:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02014d6:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02014d8:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02014da:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02014dc:	e390                	sd	a2,0(a5)
ffffffffc02014de:	b775                	j	ffffffffc020148a <default_free_pages+0xae>
ffffffffc02014e0:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014e2:	873e                	mv	a4,a5
ffffffffc02014e4:	b761                	j	ffffffffc020146c <default_free_pages+0x90>
}
ffffffffc02014e6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02014e8:	e390                	sd	a2,0(a5)
ffffffffc02014ea:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014ec:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014ee:	ed1c                	sd	a5,24(a0)
ffffffffc02014f0:	0141                	addi	sp,sp,16
ffffffffc02014f2:	8082                	ret
            base->property += p->property;
ffffffffc02014f4:	ff872783          	lw	a5,-8(a4)
ffffffffc02014f8:	ff070693          	addi	a3,a4,-16
ffffffffc02014fc:	9dbd                	addw	a1,a1,a5
ffffffffc02014fe:	c90c                	sw	a1,16(a0)
ffffffffc0201500:	57f5                	li	a5,-3
ffffffffc0201502:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201506:	6314                	ld	a3,0(a4)
ffffffffc0201508:	671c                	ld	a5,8(a4)
}
ffffffffc020150a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020150c:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc020150e:	e394                	sd	a3,0(a5)
ffffffffc0201510:	0141                	addi	sp,sp,16
ffffffffc0201512:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201514:	00001697          	auipc	a3,0x1
ffffffffc0201518:	6ac68693          	addi	a3,a3,1708 # ffffffffc0202bc0 <commands+0xa38>
ffffffffc020151c:	00001617          	auipc	a2,0x1
ffffffffc0201520:	34460613          	addi	a2,a2,836 # ffffffffc0202860 <commands+0x6d8>
ffffffffc0201524:	08300593          	li	a1,131
ffffffffc0201528:	00001517          	auipc	a0,0x1
ffffffffc020152c:	35050513          	addi	a0,a0,848 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201530:	ea9fe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(n > 0);
ffffffffc0201534:	00001697          	auipc	a3,0x1
ffffffffc0201538:	68468693          	addi	a3,a3,1668 # ffffffffc0202bb8 <commands+0xa30>
ffffffffc020153c:	00001617          	auipc	a2,0x1
ffffffffc0201540:	32460613          	addi	a2,a2,804 # ffffffffc0202860 <commands+0x6d8>
ffffffffc0201544:	08000593          	li	a1,128
ffffffffc0201548:	00001517          	auipc	a0,0x1
ffffffffc020154c:	33050513          	addi	a0,a0,816 # ffffffffc0202878 <commands+0x6f0>
ffffffffc0201550:	e89fe0ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc0201554 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201554:	c959                	beqz	a0,ffffffffc02015ea <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc0201556:	00005597          	auipc	a1,0x5
ffffffffc020155a:	aca58593          	addi	a1,a1,-1334 # ffffffffc0206020 <free_area>
ffffffffc020155e:	0105a803          	lw	a6,16(a1)
ffffffffc0201562:	862a                	mv	a2,a0
ffffffffc0201564:	02081793          	slli	a5,a6,0x20
ffffffffc0201568:	9381                	srli	a5,a5,0x20
ffffffffc020156a:	00a7ee63          	bltu	a5,a0,ffffffffc0201586 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020156e:	87ae                	mv	a5,a1
ffffffffc0201570:	a801                	j	ffffffffc0201580 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201572:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201576:	02071693          	slli	a3,a4,0x20
ffffffffc020157a:	9281                	srli	a3,a3,0x20
ffffffffc020157c:	00c6f763          	bgeu	a3,a2,ffffffffc020158a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201580:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201582:	feb798e3          	bne	a5,a1,ffffffffc0201572 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201586:	4501                	li	a0,0
}
ffffffffc0201588:	8082                	ret
    return listelm->prev;
ffffffffc020158a:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020158e:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201592:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201596:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc020159a:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020159e:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02015a2:	02d67b63          	bgeu	a2,a3,ffffffffc02015d8 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc02015a6:	00261693          	slli	a3,a2,0x2
ffffffffc02015aa:	96b2                	add	a3,a3,a2
ffffffffc02015ac:	068e                	slli	a3,a3,0x3
ffffffffc02015ae:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc02015b0:	41c7073b          	subw	a4,a4,t3
ffffffffc02015b4:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015b6:	00868613          	addi	a2,a3,8
ffffffffc02015ba:	4709                	li	a4,2
ffffffffc02015bc:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02015c0:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02015c4:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc02015c8:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02015cc:	e310                	sd	a2,0(a4)
ffffffffc02015ce:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02015d2:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc02015d4:	0116bc23          	sd	a7,24(a3)
ffffffffc02015d8:	41c8083b          	subw	a6,a6,t3
ffffffffc02015dc:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015e0:	5775                	li	a4,-3
ffffffffc02015e2:	17c1                	addi	a5,a5,-16
ffffffffc02015e4:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02015e8:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02015ea:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02015ec:	00001697          	auipc	a3,0x1
ffffffffc02015f0:	5cc68693          	addi	a3,a3,1484 # ffffffffc0202bb8 <commands+0xa30>
ffffffffc02015f4:	00001617          	auipc	a2,0x1
ffffffffc02015f8:	26c60613          	addi	a2,a2,620 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02015fc:	06200593          	li	a1,98
ffffffffc0201600:	00001517          	auipc	a0,0x1
ffffffffc0201604:	27850513          	addi	a0,a0,632 # ffffffffc0202878 <commands+0x6f0>
default_alloc_pages(size_t n) {
ffffffffc0201608:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020160a:	dcffe0ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc020160e <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020160e:	1141                	addi	sp,sp,-16
ffffffffc0201610:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201612:	c9e1                	beqz	a1,ffffffffc02016e2 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201614:	00259693          	slli	a3,a1,0x2
ffffffffc0201618:	96ae                	add	a3,a3,a1
ffffffffc020161a:	068e                	slli	a3,a3,0x3
ffffffffc020161c:	96aa                	add	a3,a3,a0
ffffffffc020161e:	87aa                	mv	a5,a0
ffffffffc0201620:	00d50f63          	beq	a0,a3,ffffffffc020163e <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201624:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201626:	8b05                	andi	a4,a4,1
ffffffffc0201628:	cf49                	beqz	a4,ffffffffc02016c2 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020162a:	0007a823          	sw	zero,16(a5)
ffffffffc020162e:	0007b423          	sd	zero,8(a5)
ffffffffc0201632:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201636:	02878793          	addi	a5,a5,40
ffffffffc020163a:	fed795e3          	bne	a5,a3,ffffffffc0201624 <default_init_memmap+0x16>
    base->property = n;
ffffffffc020163e:	2581                	sext.w	a1,a1
ffffffffc0201640:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201642:	4789                	li	a5,2
ffffffffc0201644:	00850713          	addi	a4,a0,8
ffffffffc0201648:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020164c:	00005697          	auipc	a3,0x5
ffffffffc0201650:	9d468693          	addi	a3,a3,-1580 # ffffffffc0206020 <free_area>
ffffffffc0201654:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201656:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201658:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020165c:	9db9                	addw	a1,a1,a4
ffffffffc020165e:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201660:	04d78a63          	beq	a5,a3,ffffffffc02016b4 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0201664:	fe878713          	addi	a4,a5,-24
ffffffffc0201668:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020166c:	4581                	li	a1,0
            if (base < page) {
ffffffffc020166e:	00e56a63          	bltu	a0,a4,ffffffffc0201682 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc0201672:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201674:	02d70263          	beq	a4,a3,ffffffffc0201698 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0201678:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020167a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020167e:	fee57ae3          	bgeu	a0,a4,ffffffffc0201672 <default_init_memmap+0x64>
ffffffffc0201682:	c199                	beqz	a1,ffffffffc0201688 <default_init_memmap+0x7a>
ffffffffc0201684:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201688:	6398                	ld	a4,0(a5)
}
ffffffffc020168a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020168c:	e390                	sd	a2,0(a5)
ffffffffc020168e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201690:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201692:	ed18                	sd	a4,24(a0)
ffffffffc0201694:	0141                	addi	sp,sp,16
ffffffffc0201696:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201698:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020169a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020169c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020169e:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016a0:	00d70663          	beq	a4,a3,ffffffffc02016ac <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc02016a4:	8832                	mv	a6,a2
ffffffffc02016a6:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02016a8:	87ba                	mv	a5,a4
ffffffffc02016aa:	bfc1                	j	ffffffffc020167a <default_init_memmap+0x6c>
}
ffffffffc02016ac:	60a2                	ld	ra,8(sp)
ffffffffc02016ae:	e290                	sd	a2,0(a3)
ffffffffc02016b0:	0141                	addi	sp,sp,16
ffffffffc02016b2:	8082                	ret
ffffffffc02016b4:	60a2                	ld	ra,8(sp)
ffffffffc02016b6:	e390                	sd	a2,0(a5)
ffffffffc02016b8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016ba:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016bc:	ed1c                	sd	a5,24(a0)
ffffffffc02016be:	0141                	addi	sp,sp,16
ffffffffc02016c0:	8082                	ret
        assert(PageReserved(p));
ffffffffc02016c2:	00001697          	auipc	a3,0x1
ffffffffc02016c6:	52668693          	addi	a3,a3,1318 # ffffffffc0202be8 <commands+0xa60>
ffffffffc02016ca:	00001617          	auipc	a2,0x1
ffffffffc02016ce:	19660613          	addi	a2,a2,406 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02016d2:	04900593          	li	a1,73
ffffffffc02016d6:	00001517          	auipc	a0,0x1
ffffffffc02016da:	1a250513          	addi	a0,a0,418 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02016de:	cfbfe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    assert(n > 0);
ffffffffc02016e2:	00001697          	auipc	a3,0x1
ffffffffc02016e6:	4d668693          	addi	a3,a3,1238 # ffffffffc0202bb8 <commands+0xa30>
ffffffffc02016ea:	00001617          	auipc	a2,0x1
ffffffffc02016ee:	17660613          	addi	a2,a2,374 # ffffffffc0202860 <commands+0x6d8>
ffffffffc02016f2:	04600593          	li	a1,70
ffffffffc02016f6:	00001517          	auipc	a0,0x1
ffffffffc02016fa:	18250513          	addi	a0,a0,386 # ffffffffc0202878 <commands+0x6f0>
ffffffffc02016fe:	cdbfe0ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc0201702 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201702:	100027f3          	csrr	a5,sstatus
ffffffffc0201706:	8b89                	andi	a5,a5,2
ffffffffc0201708:	e799                	bnez	a5,ffffffffc0201716 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020170a:	00005797          	auipc	a5,0x5
ffffffffc020170e:	d5e7b783          	ld	a5,-674(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201712:	6f9c                	ld	a5,24(a5)
ffffffffc0201714:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201716:	1141                	addi	sp,sp,-16
ffffffffc0201718:	e406                	sd	ra,8(sp)
ffffffffc020171a:	e022                	sd	s0,0(sp)
ffffffffc020171c:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020171e:	90cff0ef          	jal	ra,ffffffffc020082a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201722:	00005797          	auipc	a5,0x5
ffffffffc0201726:	d467b783          	ld	a5,-698(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc020172a:	6f9c                	ld	a5,24(a5)
ffffffffc020172c:	8522                	mv	a0,s0
ffffffffc020172e:	9782                	jalr	a5
ffffffffc0201730:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201732:	8f2ff0ef          	jal	ra,ffffffffc0200824 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201736:	60a2                	ld	ra,8(sp)
ffffffffc0201738:	8522                	mv	a0,s0
ffffffffc020173a:	6402                	ld	s0,0(sp)
ffffffffc020173c:	0141                	addi	sp,sp,16
ffffffffc020173e:	8082                	ret

ffffffffc0201740 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201740:	100027f3          	csrr	a5,sstatus
ffffffffc0201744:	8b89                	andi	a5,a5,2
ffffffffc0201746:	e799                	bnez	a5,ffffffffc0201754 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201748:	00005797          	auipc	a5,0x5
ffffffffc020174c:	d207b783          	ld	a5,-736(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201750:	739c                	ld	a5,32(a5)
ffffffffc0201752:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201754:	1101                	addi	sp,sp,-32
ffffffffc0201756:	ec06                	sd	ra,24(sp)
ffffffffc0201758:	e822                	sd	s0,16(sp)
ffffffffc020175a:	e426                	sd	s1,8(sp)
ffffffffc020175c:	842a                	mv	s0,a0
ffffffffc020175e:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201760:	8caff0ef          	jal	ra,ffffffffc020082a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201764:	00005797          	auipc	a5,0x5
ffffffffc0201768:	d047b783          	ld	a5,-764(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc020176c:	739c                	ld	a5,32(a5)
ffffffffc020176e:	85a6                	mv	a1,s1
ffffffffc0201770:	8522                	mv	a0,s0
ffffffffc0201772:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201774:	6442                	ld	s0,16(sp)
ffffffffc0201776:	60e2                	ld	ra,24(sp)
ffffffffc0201778:	64a2                	ld	s1,8(sp)
ffffffffc020177a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020177c:	8a8ff06f          	j	ffffffffc0200824 <intr_enable>

ffffffffc0201780 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201780:	100027f3          	csrr	a5,sstatus
ffffffffc0201784:	8b89                	andi	a5,a5,2
ffffffffc0201786:	e799                	bnez	a5,ffffffffc0201794 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201788:	00005797          	auipc	a5,0x5
ffffffffc020178c:	ce07b783          	ld	a5,-800(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201790:	779c                	ld	a5,40(a5)
ffffffffc0201792:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201794:	1141                	addi	sp,sp,-16
ffffffffc0201796:	e406                	sd	ra,8(sp)
ffffffffc0201798:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020179a:	890ff0ef          	jal	ra,ffffffffc020082a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020179e:	00005797          	auipc	a5,0x5
ffffffffc02017a2:	cca7b783          	ld	a5,-822(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc02017a6:	779c                	ld	a5,40(a5)
ffffffffc02017a8:	9782                	jalr	a5
ffffffffc02017aa:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02017ac:	878ff0ef          	jal	ra,ffffffffc0200824 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02017b0:	60a2                	ld	ra,8(sp)
ffffffffc02017b2:	8522                	mv	a0,s0
ffffffffc02017b4:	6402                	ld	s0,0(sp)
ffffffffc02017b6:	0141                	addi	sp,sp,16
ffffffffc02017b8:	8082                	ret

ffffffffc02017ba <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02017ba:	00001797          	auipc	a5,0x1
ffffffffc02017be:	45678793          	addi	a5,a5,1110 # ffffffffc0202c10 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017c2:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02017c4:	7179                	addi	sp,sp,-48
ffffffffc02017c6:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017c8:	00001517          	auipc	a0,0x1
ffffffffc02017cc:	48050513          	addi	a0,a0,1152 # ffffffffc0202c48 <default_pmm_manager+0x38>
    pmm_manager = &default_pmm_manager;
ffffffffc02017d0:	00005417          	auipc	s0,0x5
ffffffffc02017d4:	c9840413          	addi	s0,s0,-872 # ffffffffc0206468 <pmm_manager>
void pmm_init(void) {
ffffffffc02017d8:	f406                	sd	ra,40(sp)
ffffffffc02017da:	ec26                	sd	s1,24(sp)
ffffffffc02017dc:	e44e                	sd	s3,8(sp)
ffffffffc02017de:	e84a                	sd	s2,16(sp)
ffffffffc02017e0:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02017e2:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017e4:	8fbfe0ef          	jal	ra,ffffffffc02000de <cprintf>
    pmm_manager->init();
ffffffffc02017e8:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017ea:	00005497          	auipc	s1,0x5
ffffffffc02017ee:	c9648493          	addi	s1,s1,-874 # ffffffffc0206480 <va_pa_offset>
    pmm_manager->init();
ffffffffc02017f2:	679c                	ld	a5,8(a5)
ffffffffc02017f4:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017f6:	57f5                	li	a5,-3
ffffffffc02017f8:	07fa                	slli	a5,a5,0x1e
ffffffffc02017fa:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02017fc:	814ff0ef          	jal	ra,ffffffffc0200810 <get_memory_base>
ffffffffc0201800:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201802:	818ff0ef          	jal	ra,ffffffffc020081a <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201806:	16050163          	beqz	a0,ffffffffc0201968 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020180a:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc020180c:	00001517          	auipc	a0,0x1
ffffffffc0201810:	48450513          	addi	a0,a0,1156 # ffffffffc0202c90 <default_pmm_manager+0x80>
ffffffffc0201814:	8cbfe0ef          	jal	ra,ffffffffc02000de <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201818:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020181c:	864e                	mv	a2,s3
ffffffffc020181e:	fffa0693          	addi	a3,s4,-1
ffffffffc0201822:	85ca                	mv	a1,s2
ffffffffc0201824:	00001517          	auipc	a0,0x1
ffffffffc0201828:	48450513          	addi	a0,a0,1156 # ffffffffc0202ca8 <default_pmm_manager+0x98>
ffffffffc020182c:	8b3fe0ef          	jal	ra,ffffffffc02000de <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201830:	c80007b7          	lui	a5,0xc8000
ffffffffc0201834:	8652                	mv	a2,s4
ffffffffc0201836:	0d47e863          	bltu	a5,s4,ffffffffc0201906 <pmm_init+0x14c>
ffffffffc020183a:	00006797          	auipc	a5,0x6
ffffffffc020183e:	c5578793          	addi	a5,a5,-939 # ffffffffc020748f <end+0xfff>
ffffffffc0201842:	757d                	lui	a0,0xfffff
ffffffffc0201844:	8d7d                	and	a0,a0,a5
ffffffffc0201846:	8231                	srli	a2,a2,0xc
ffffffffc0201848:	00005597          	auipc	a1,0x5
ffffffffc020184c:	c1058593          	addi	a1,a1,-1008 # ffffffffc0206458 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201850:	00005817          	auipc	a6,0x5
ffffffffc0201854:	c1080813          	addi	a6,a6,-1008 # ffffffffc0206460 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201858:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020185a:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020185e:	000807b7          	lui	a5,0x80
ffffffffc0201862:	02f60663          	beq	a2,a5,ffffffffc020188e <pmm_init+0xd4>
ffffffffc0201866:	4701                	li	a4,0
ffffffffc0201868:	4781                	li	a5,0
ffffffffc020186a:	4305                	li	t1,1
ffffffffc020186c:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201870:	953a                	add	a0,a0,a4
ffffffffc0201872:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b78>
ffffffffc0201876:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020187a:	6190                	ld	a2,0(a1)
ffffffffc020187c:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc020187e:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201882:	011606b3          	add	a3,a2,a7
ffffffffc0201886:	02870713          	addi	a4,a4,40
ffffffffc020188a:	fed7e3e3          	bltu	a5,a3,ffffffffc0201870 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020188e:	00261693          	slli	a3,a2,0x2
ffffffffc0201892:	96b2                	add	a3,a3,a2
ffffffffc0201894:	fec007b7          	lui	a5,0xfec00
ffffffffc0201898:	97aa                	add	a5,a5,a0
ffffffffc020189a:	068e                	slli	a3,a3,0x3
ffffffffc020189c:	96be                	add	a3,a3,a5
ffffffffc020189e:	c02007b7          	lui	a5,0xc0200
ffffffffc02018a2:	0af6e763          	bltu	a3,a5,ffffffffc0201950 <pmm_init+0x196>
ffffffffc02018a6:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02018a8:	77fd                	lui	a5,0xfffff
ffffffffc02018aa:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018ae:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02018b0:	04b6ee63          	bltu	a3,a1,ffffffffc020190c <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02018b4:	601c                	ld	a5,0(s0)
ffffffffc02018b6:	7b9c                	ld	a5,48(a5)
ffffffffc02018b8:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02018ba:	00001517          	auipc	a0,0x1
ffffffffc02018be:	47650513          	addi	a0,a0,1142 # ffffffffc0202d30 <default_pmm_manager+0x120>
ffffffffc02018c2:	81dfe0ef          	jal	ra,ffffffffc02000de <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02018c6:	00003597          	auipc	a1,0x3
ffffffffc02018ca:	73a58593          	addi	a1,a1,1850 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02018ce:	00005797          	auipc	a5,0x5
ffffffffc02018d2:	bab7b523          	sd	a1,-1110(a5) # ffffffffc0206478 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02018d6:	c02007b7          	lui	a5,0xc0200
ffffffffc02018da:	0af5e363          	bltu	a1,a5,ffffffffc0201980 <pmm_init+0x1c6>
ffffffffc02018de:	6090                	ld	a2,0(s1)
}
ffffffffc02018e0:	7402                	ld	s0,32(sp)
ffffffffc02018e2:	70a2                	ld	ra,40(sp)
ffffffffc02018e4:	64e2                	ld	s1,24(sp)
ffffffffc02018e6:	6942                	ld	s2,16(sp)
ffffffffc02018e8:	69a2                	ld	s3,8(sp)
ffffffffc02018ea:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02018ec:	40c58633          	sub	a2,a1,a2
ffffffffc02018f0:	00005797          	auipc	a5,0x5
ffffffffc02018f4:	b8c7b023          	sd	a2,-1152(a5) # ffffffffc0206470 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018f8:	00001517          	auipc	a0,0x1
ffffffffc02018fc:	45850513          	addi	a0,a0,1112 # ffffffffc0202d50 <default_pmm_manager+0x140>
}
ffffffffc0201900:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201902:	fdcfe06f          	j	ffffffffc02000de <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201906:	c8000637          	lui	a2,0xc8000
ffffffffc020190a:	bf05                	j	ffffffffc020183a <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020190c:	6705                	lui	a4,0x1
ffffffffc020190e:	177d                	addi	a4,a4,-1
ffffffffc0201910:	96ba                	add	a3,a3,a4
ffffffffc0201912:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201914:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201918:	02c7f063          	bgeu	a5,a2,ffffffffc0201938 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc020191c:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020191e:	fff80737          	lui	a4,0xfff80
ffffffffc0201922:	973e                	add	a4,a4,a5
ffffffffc0201924:	00271793          	slli	a5,a4,0x2
ffffffffc0201928:	97ba                	add	a5,a5,a4
ffffffffc020192a:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020192c:	8d95                	sub	a1,a1,a3
ffffffffc020192e:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201930:	81b1                	srli	a1,a1,0xc
ffffffffc0201932:	953e                	add	a0,a0,a5
ffffffffc0201934:	9702                	jalr	a4
}
ffffffffc0201936:	bfbd                	j	ffffffffc02018b4 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc0201938:	00001617          	auipc	a2,0x1
ffffffffc020193c:	3c860613          	addi	a2,a2,968 # ffffffffc0202d00 <default_pmm_manager+0xf0>
ffffffffc0201940:	06b00593          	li	a1,107
ffffffffc0201944:	00001517          	auipc	a0,0x1
ffffffffc0201948:	3dc50513          	addi	a0,a0,988 # ffffffffc0202d20 <default_pmm_manager+0x110>
ffffffffc020194c:	a8dfe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201950:	00001617          	auipc	a2,0x1
ffffffffc0201954:	38860613          	addi	a2,a2,904 # ffffffffc0202cd8 <default_pmm_manager+0xc8>
ffffffffc0201958:	07100593          	li	a1,113
ffffffffc020195c:	00001517          	auipc	a0,0x1
ffffffffc0201960:	32450513          	addi	a0,a0,804 # ffffffffc0202c80 <default_pmm_manager+0x70>
ffffffffc0201964:	a75fe0ef          	jal	ra,ffffffffc02003d8 <__panic>
        panic("DTB memory info not available");
ffffffffc0201968:	00001617          	auipc	a2,0x1
ffffffffc020196c:	2f860613          	addi	a2,a2,760 # ffffffffc0202c60 <default_pmm_manager+0x50>
ffffffffc0201970:	05a00593          	li	a1,90
ffffffffc0201974:	00001517          	auipc	a0,0x1
ffffffffc0201978:	30c50513          	addi	a0,a0,780 # ffffffffc0202c80 <default_pmm_manager+0x70>
ffffffffc020197c:	a5dfe0ef          	jal	ra,ffffffffc02003d8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201980:	86ae                	mv	a3,a1
ffffffffc0201982:	00001617          	auipc	a2,0x1
ffffffffc0201986:	35660613          	addi	a2,a2,854 # ffffffffc0202cd8 <default_pmm_manager+0xc8>
ffffffffc020198a:	08c00593          	li	a1,140
ffffffffc020198e:	00001517          	auipc	a0,0x1
ffffffffc0201992:	2f250513          	addi	a0,a0,754 # ffffffffc0202c80 <default_pmm_manager+0x70>
ffffffffc0201996:	a43fe0ef          	jal	ra,ffffffffc02003d8 <__panic>

ffffffffc020199a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020199a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020199e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02019a0:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019a4:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019a6:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019aa:	f022                	sd	s0,32(sp)
ffffffffc02019ac:	ec26                	sd	s1,24(sp)
ffffffffc02019ae:	e84a                	sd	s2,16(sp)
ffffffffc02019b0:	f406                	sd	ra,40(sp)
ffffffffc02019b2:	e44e                	sd	s3,8(sp)
ffffffffc02019b4:	84aa                	mv	s1,a0
ffffffffc02019b6:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02019b8:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02019bc:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02019be:	03067e63          	bgeu	a2,a6,ffffffffc02019fa <printnum+0x60>
ffffffffc02019c2:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02019c4:	00805763          	blez	s0,ffffffffc02019d2 <printnum+0x38>
ffffffffc02019c8:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02019ca:	85ca                	mv	a1,s2
ffffffffc02019cc:	854e                	mv	a0,s3
ffffffffc02019ce:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02019d0:	fc65                	bnez	s0,ffffffffc02019c8 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019d2:	1a02                	slli	s4,s4,0x20
ffffffffc02019d4:	00001797          	auipc	a5,0x1
ffffffffc02019d8:	3bc78793          	addi	a5,a5,956 # ffffffffc0202d90 <default_pmm_manager+0x180>
ffffffffc02019dc:	020a5a13          	srli	s4,s4,0x20
ffffffffc02019e0:	9a3e                	add	s4,s4,a5
}
ffffffffc02019e2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019e4:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02019e8:	70a2                	ld	ra,40(sp)
ffffffffc02019ea:	69a2                	ld	s3,8(sp)
ffffffffc02019ec:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019ee:	85ca                	mv	a1,s2
ffffffffc02019f0:	87a6                	mv	a5,s1
}
ffffffffc02019f2:	6942                	ld	s2,16(sp)
ffffffffc02019f4:	64e2                	ld	s1,24(sp)
ffffffffc02019f6:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019f8:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02019fa:	03065633          	divu	a2,a2,a6
ffffffffc02019fe:	8722                	mv	a4,s0
ffffffffc0201a00:	f9bff0ef          	jal	ra,ffffffffc020199a <printnum>
ffffffffc0201a04:	b7f9                	j	ffffffffc02019d2 <printnum+0x38>

ffffffffc0201a06 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a06:	7119                	addi	sp,sp,-128
ffffffffc0201a08:	f4a6                	sd	s1,104(sp)
ffffffffc0201a0a:	f0ca                	sd	s2,96(sp)
ffffffffc0201a0c:	ecce                	sd	s3,88(sp)
ffffffffc0201a0e:	e8d2                	sd	s4,80(sp)
ffffffffc0201a10:	e4d6                	sd	s5,72(sp)
ffffffffc0201a12:	e0da                	sd	s6,64(sp)
ffffffffc0201a14:	fc5e                	sd	s7,56(sp)
ffffffffc0201a16:	f06a                	sd	s10,32(sp)
ffffffffc0201a18:	fc86                	sd	ra,120(sp)
ffffffffc0201a1a:	f8a2                	sd	s0,112(sp)
ffffffffc0201a1c:	f862                	sd	s8,48(sp)
ffffffffc0201a1e:	f466                	sd	s9,40(sp)
ffffffffc0201a20:	ec6e                	sd	s11,24(sp)
ffffffffc0201a22:	892a                	mv	s2,a0
ffffffffc0201a24:	84ae                	mv	s1,a1
ffffffffc0201a26:	8d32                	mv	s10,a2
ffffffffc0201a28:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a2a:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201a2e:	5b7d                	li	s6,-1
ffffffffc0201a30:	00001a97          	auipc	s5,0x1
ffffffffc0201a34:	394a8a93          	addi	s5,s5,916 # ffffffffc0202dc4 <default_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a38:	00001b97          	auipc	s7,0x1
ffffffffc0201a3c:	568b8b93          	addi	s7,s7,1384 # ffffffffc0202fa0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a40:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a44:	001d0413          	addi	s0,s10,1
ffffffffc0201a48:	01350a63          	beq	a0,s3,ffffffffc0201a5c <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201a4c:	c121                	beqz	a0,ffffffffc0201a8c <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201a4e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a50:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a52:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a54:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a58:	ff351ae3          	bne	a0,s3,ffffffffc0201a4c <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a5c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a60:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a64:	4c81                	li	s9,0
ffffffffc0201a66:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201a68:	5c7d                	li	s8,-1
ffffffffc0201a6a:	5dfd                	li	s11,-1
ffffffffc0201a6c:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201a70:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a72:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a76:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a7a:	00140d13          	addi	s10,s0,1
ffffffffc0201a7e:	04b56263          	bltu	a0,a1,ffffffffc0201ac2 <vprintfmt+0xbc>
ffffffffc0201a82:	058a                	slli	a1,a1,0x2
ffffffffc0201a84:	95d6                	add	a1,a1,s5
ffffffffc0201a86:	4194                	lw	a3,0(a1)
ffffffffc0201a88:	96d6                	add	a3,a3,s5
ffffffffc0201a8a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a8c:	70e6                	ld	ra,120(sp)
ffffffffc0201a8e:	7446                	ld	s0,112(sp)
ffffffffc0201a90:	74a6                	ld	s1,104(sp)
ffffffffc0201a92:	7906                	ld	s2,96(sp)
ffffffffc0201a94:	69e6                	ld	s3,88(sp)
ffffffffc0201a96:	6a46                	ld	s4,80(sp)
ffffffffc0201a98:	6aa6                	ld	s5,72(sp)
ffffffffc0201a9a:	6b06                	ld	s6,64(sp)
ffffffffc0201a9c:	7be2                	ld	s7,56(sp)
ffffffffc0201a9e:	7c42                	ld	s8,48(sp)
ffffffffc0201aa0:	7ca2                	ld	s9,40(sp)
ffffffffc0201aa2:	7d02                	ld	s10,32(sp)
ffffffffc0201aa4:	6de2                	ld	s11,24(sp)
ffffffffc0201aa6:	6109                	addi	sp,sp,128
ffffffffc0201aa8:	8082                	ret
            padc = '0';
ffffffffc0201aaa:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201aac:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ab0:	846a                	mv	s0,s10
ffffffffc0201ab2:	00140d13          	addi	s10,s0,1
ffffffffc0201ab6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201aba:	0ff5f593          	zext.b	a1,a1
ffffffffc0201abe:	fcb572e3          	bgeu	a0,a1,ffffffffc0201a82 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201ac2:	85a6                	mv	a1,s1
ffffffffc0201ac4:	02500513          	li	a0,37
ffffffffc0201ac8:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201aca:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201ace:	8d22                	mv	s10,s0
ffffffffc0201ad0:	f73788e3          	beq	a5,s3,ffffffffc0201a40 <vprintfmt+0x3a>
ffffffffc0201ad4:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201ad8:	1d7d                	addi	s10,s10,-1
ffffffffc0201ada:	ff379de3          	bne	a5,s3,ffffffffc0201ad4 <vprintfmt+0xce>
ffffffffc0201ade:	b78d                	j	ffffffffc0201a40 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201ae0:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201ae4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ae8:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201aea:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201aee:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201af2:	02d86463          	bltu	a6,a3,ffffffffc0201b1a <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201af6:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201afa:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201afe:	0186873b          	addw	a4,a3,s8
ffffffffc0201b02:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b06:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201b08:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b0c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b0e:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201b12:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b16:	fed870e3          	bgeu	a6,a3,ffffffffc0201af6 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201b1a:	f40ddce3          	bgez	s11,ffffffffc0201a72 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201b1e:	8de2                	mv	s11,s8
ffffffffc0201b20:	5c7d                	li	s8,-1
ffffffffc0201b22:	bf81                	j	ffffffffc0201a72 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201b24:	fffdc693          	not	a3,s11
ffffffffc0201b28:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b2a:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b2e:	00144603          	lbu	a2,1(s0)
ffffffffc0201b32:	2d81                	sext.w	s11,s11
ffffffffc0201b34:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b36:	bf35                	j	ffffffffc0201a72 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201b38:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b3c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201b40:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b42:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201b44:	bfd9                	j	ffffffffc0201b1a <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201b46:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b48:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b4c:	01174463          	blt	a4,a7,ffffffffc0201b54 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201b50:	1a088e63          	beqz	a7,ffffffffc0201d0c <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201b54:	000a3603          	ld	a2,0(s4)
ffffffffc0201b58:	46c1                	li	a3,16
ffffffffc0201b5a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b5c:	2781                	sext.w	a5,a5
ffffffffc0201b5e:	876e                	mv	a4,s11
ffffffffc0201b60:	85a6                	mv	a1,s1
ffffffffc0201b62:	854a                	mv	a0,s2
ffffffffc0201b64:	e37ff0ef          	jal	ra,ffffffffc020199a <printnum>
            break;
ffffffffc0201b68:	bde1                	j	ffffffffc0201a40 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b6a:	000a2503          	lw	a0,0(s4)
ffffffffc0201b6e:	85a6                	mv	a1,s1
ffffffffc0201b70:	0a21                	addi	s4,s4,8
ffffffffc0201b72:	9902                	jalr	s2
            break;
ffffffffc0201b74:	b5f1                	j	ffffffffc0201a40 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b76:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b78:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b7c:	01174463          	blt	a4,a7,ffffffffc0201b84 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201b80:	18088163          	beqz	a7,ffffffffc0201d02 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201b84:	000a3603          	ld	a2,0(s4)
ffffffffc0201b88:	46a9                	li	a3,10
ffffffffc0201b8a:	8a2e                	mv	s4,a1
ffffffffc0201b8c:	bfc1                	j	ffffffffc0201b5c <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b8e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201b92:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b94:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b96:	bdf1                	j	ffffffffc0201a72 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201b98:	85a6                	mv	a1,s1
ffffffffc0201b9a:	02500513          	li	a0,37
ffffffffc0201b9e:	9902                	jalr	s2
            break;
ffffffffc0201ba0:	b545                	j	ffffffffc0201a40 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ba2:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201ba6:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ba8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201baa:	b5e1                	j	ffffffffc0201a72 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201bac:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bae:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bb2:	01174463          	blt	a4,a7,ffffffffc0201bba <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201bb6:	14088163          	beqz	a7,ffffffffc0201cf8 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201bba:	000a3603          	ld	a2,0(s4)
ffffffffc0201bbe:	46a1                	li	a3,8
ffffffffc0201bc0:	8a2e                	mv	s4,a1
ffffffffc0201bc2:	bf69                	j	ffffffffc0201b5c <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201bc4:	03000513          	li	a0,48
ffffffffc0201bc8:	85a6                	mv	a1,s1
ffffffffc0201bca:	e03e                	sd	a5,0(sp)
ffffffffc0201bcc:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201bce:	85a6                	mv	a1,s1
ffffffffc0201bd0:	07800513          	li	a0,120
ffffffffc0201bd4:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bd6:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201bd8:	6782                	ld	a5,0(sp)
ffffffffc0201bda:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bdc:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201be0:	bfb5                	j	ffffffffc0201b5c <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201be2:	000a3403          	ld	s0,0(s4)
ffffffffc0201be6:	008a0713          	addi	a4,s4,8
ffffffffc0201bea:	e03a                	sd	a4,0(sp)
ffffffffc0201bec:	14040263          	beqz	s0,ffffffffc0201d30 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201bf0:	0fb05763          	blez	s11,ffffffffc0201cde <vprintfmt+0x2d8>
ffffffffc0201bf4:	02d00693          	li	a3,45
ffffffffc0201bf8:	0cd79163          	bne	a5,a3,ffffffffc0201cba <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bfc:	00044783          	lbu	a5,0(s0)
ffffffffc0201c00:	0007851b          	sext.w	a0,a5
ffffffffc0201c04:	cf85                	beqz	a5,ffffffffc0201c3c <vprintfmt+0x236>
ffffffffc0201c06:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c0a:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c0e:	000c4563          	bltz	s8,ffffffffc0201c18 <vprintfmt+0x212>
ffffffffc0201c12:	3c7d                	addiw	s8,s8,-1
ffffffffc0201c14:	036c0263          	beq	s8,s6,ffffffffc0201c38 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201c18:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c1a:	0e0c8e63          	beqz	s9,ffffffffc0201d16 <vprintfmt+0x310>
ffffffffc0201c1e:	3781                	addiw	a5,a5,-32
ffffffffc0201c20:	0ef47b63          	bgeu	s0,a5,ffffffffc0201d16 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201c24:	03f00513          	li	a0,63
ffffffffc0201c28:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c2a:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c2e:	3dfd                	addiw	s11,s11,-1
ffffffffc0201c30:	0a05                	addi	s4,s4,1
ffffffffc0201c32:	0007851b          	sext.w	a0,a5
ffffffffc0201c36:	ffe1                	bnez	a5,ffffffffc0201c0e <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201c38:	01b05963          	blez	s11,ffffffffc0201c4a <vprintfmt+0x244>
ffffffffc0201c3c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201c3e:	85a6                	mv	a1,s1
ffffffffc0201c40:	02000513          	li	a0,32
ffffffffc0201c44:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c46:	fe0d9be3          	bnez	s11,ffffffffc0201c3c <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c4a:	6a02                	ld	s4,0(sp)
ffffffffc0201c4c:	bbd5                	j	ffffffffc0201a40 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c4e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c50:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201c54:	01174463          	blt	a4,a7,ffffffffc0201c5c <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201c58:	08088d63          	beqz	a7,ffffffffc0201cf2 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201c5c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c60:	0a044d63          	bltz	s0,ffffffffc0201d1a <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201c64:	8622                	mv	a2,s0
ffffffffc0201c66:	8a66                	mv	s4,s9
ffffffffc0201c68:	46a9                	li	a3,10
ffffffffc0201c6a:	bdcd                	j	ffffffffc0201b5c <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201c6c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c70:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201c72:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c74:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201c78:	8fb5                	xor	a5,a5,a3
ffffffffc0201c7a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c7e:	02d74163          	blt	a4,a3,ffffffffc0201ca0 <vprintfmt+0x29a>
ffffffffc0201c82:	00369793          	slli	a5,a3,0x3
ffffffffc0201c86:	97de                	add	a5,a5,s7
ffffffffc0201c88:	639c                	ld	a5,0(a5)
ffffffffc0201c8a:	cb99                	beqz	a5,ffffffffc0201ca0 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c8c:	86be                	mv	a3,a5
ffffffffc0201c8e:	00001617          	auipc	a2,0x1
ffffffffc0201c92:	13260613          	addi	a2,a2,306 # ffffffffc0202dc0 <default_pmm_manager+0x1b0>
ffffffffc0201c96:	85a6                	mv	a1,s1
ffffffffc0201c98:	854a                	mv	a0,s2
ffffffffc0201c9a:	0ce000ef          	jal	ra,ffffffffc0201d68 <printfmt>
ffffffffc0201c9e:	b34d                	j	ffffffffc0201a40 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201ca0:	00001617          	auipc	a2,0x1
ffffffffc0201ca4:	11060613          	addi	a2,a2,272 # ffffffffc0202db0 <default_pmm_manager+0x1a0>
ffffffffc0201ca8:	85a6                	mv	a1,s1
ffffffffc0201caa:	854a                	mv	a0,s2
ffffffffc0201cac:	0bc000ef          	jal	ra,ffffffffc0201d68 <printfmt>
ffffffffc0201cb0:	bb41                	j	ffffffffc0201a40 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201cb2:	00001417          	auipc	s0,0x1
ffffffffc0201cb6:	0f640413          	addi	s0,s0,246 # ffffffffc0202da8 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cba:	85e2                	mv	a1,s8
ffffffffc0201cbc:	8522                	mv	a0,s0
ffffffffc0201cbe:	e43e                	sd	a5,8(sp)
ffffffffc0201cc0:	1e6000ef          	jal	ra,ffffffffc0201ea6 <strnlen>
ffffffffc0201cc4:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201cc8:	01b05b63          	blez	s11,ffffffffc0201cde <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201ccc:	67a2                	ld	a5,8(sp)
ffffffffc0201cce:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cd2:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201cd4:	85a6                	mv	a1,s1
ffffffffc0201cd6:	8552                	mv	a0,s4
ffffffffc0201cd8:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cda:	fe0d9ce3          	bnez	s11,ffffffffc0201cd2 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cde:	00044783          	lbu	a5,0(s0)
ffffffffc0201ce2:	00140a13          	addi	s4,s0,1
ffffffffc0201ce6:	0007851b          	sext.w	a0,a5
ffffffffc0201cea:	d3a5                	beqz	a5,ffffffffc0201c4a <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cec:	05e00413          	li	s0,94
ffffffffc0201cf0:	bf39                	j	ffffffffc0201c0e <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201cf2:	000a2403          	lw	s0,0(s4)
ffffffffc0201cf6:	b7ad                	j	ffffffffc0201c60 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201cf8:	000a6603          	lwu	a2,0(s4)
ffffffffc0201cfc:	46a1                	li	a3,8
ffffffffc0201cfe:	8a2e                	mv	s4,a1
ffffffffc0201d00:	bdb1                	j	ffffffffc0201b5c <vprintfmt+0x156>
ffffffffc0201d02:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d06:	46a9                	li	a3,10
ffffffffc0201d08:	8a2e                	mv	s4,a1
ffffffffc0201d0a:	bd89                	j	ffffffffc0201b5c <vprintfmt+0x156>
ffffffffc0201d0c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d10:	46c1                	li	a3,16
ffffffffc0201d12:	8a2e                	mv	s4,a1
ffffffffc0201d14:	b5a1                	j	ffffffffc0201b5c <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201d16:	9902                	jalr	s2
ffffffffc0201d18:	bf09                	j	ffffffffc0201c2a <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201d1a:	85a6                	mv	a1,s1
ffffffffc0201d1c:	02d00513          	li	a0,45
ffffffffc0201d20:	e03e                	sd	a5,0(sp)
ffffffffc0201d22:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d24:	6782                	ld	a5,0(sp)
ffffffffc0201d26:	8a66                	mv	s4,s9
ffffffffc0201d28:	40800633          	neg	a2,s0
ffffffffc0201d2c:	46a9                	li	a3,10
ffffffffc0201d2e:	b53d                	j	ffffffffc0201b5c <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201d30:	03b05163          	blez	s11,ffffffffc0201d52 <vprintfmt+0x34c>
ffffffffc0201d34:	02d00693          	li	a3,45
ffffffffc0201d38:	f6d79de3          	bne	a5,a3,ffffffffc0201cb2 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201d3c:	00001417          	auipc	s0,0x1
ffffffffc0201d40:	06c40413          	addi	s0,s0,108 # ffffffffc0202da8 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d44:	02800793          	li	a5,40
ffffffffc0201d48:	02800513          	li	a0,40
ffffffffc0201d4c:	00140a13          	addi	s4,s0,1
ffffffffc0201d50:	bd6d                	j	ffffffffc0201c0a <vprintfmt+0x204>
ffffffffc0201d52:	00001a17          	auipc	s4,0x1
ffffffffc0201d56:	057a0a13          	addi	s4,s4,87 # ffffffffc0202da9 <default_pmm_manager+0x199>
ffffffffc0201d5a:	02800513          	li	a0,40
ffffffffc0201d5e:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d62:	05e00413          	li	s0,94
ffffffffc0201d66:	b565                	j	ffffffffc0201c0e <vprintfmt+0x208>

ffffffffc0201d68 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d68:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d6a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d6e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d70:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d72:	ec06                	sd	ra,24(sp)
ffffffffc0201d74:	f83a                	sd	a4,48(sp)
ffffffffc0201d76:	fc3e                	sd	a5,56(sp)
ffffffffc0201d78:	e0c2                	sd	a6,64(sp)
ffffffffc0201d7a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d7c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d7e:	c89ff0ef          	jal	ra,ffffffffc0201a06 <vprintfmt>
}
ffffffffc0201d82:	60e2                	ld	ra,24(sp)
ffffffffc0201d84:	6161                	addi	sp,sp,80
ffffffffc0201d86:	8082                	ret

ffffffffc0201d88 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d88:	715d                	addi	sp,sp,-80
ffffffffc0201d8a:	e486                	sd	ra,72(sp)
ffffffffc0201d8c:	e0a6                	sd	s1,64(sp)
ffffffffc0201d8e:	fc4a                	sd	s2,56(sp)
ffffffffc0201d90:	f84e                	sd	s3,48(sp)
ffffffffc0201d92:	f452                	sd	s4,40(sp)
ffffffffc0201d94:	f056                	sd	s5,32(sp)
ffffffffc0201d96:	ec5a                	sd	s6,24(sp)
ffffffffc0201d98:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201d9a:	c901                	beqz	a0,ffffffffc0201daa <readline+0x22>
ffffffffc0201d9c:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d9e:	00001517          	auipc	a0,0x1
ffffffffc0201da2:	02250513          	addi	a0,a0,34 # ffffffffc0202dc0 <default_pmm_manager+0x1b0>
ffffffffc0201da6:	b38fe0ef          	jal	ra,ffffffffc02000de <cprintf>
readline(const char *prompt) {
ffffffffc0201daa:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dac:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201dae:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201db0:	4aa9                	li	s5,10
ffffffffc0201db2:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201db4:	00004b97          	auipc	s7,0x4
ffffffffc0201db8:	284b8b93          	addi	s7,s7,644 # ffffffffc0206038 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dbc:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201dc0:	b96fe0ef          	jal	ra,ffffffffc0200156 <getchar>
        if (c < 0) {
ffffffffc0201dc4:	00054a63          	bltz	a0,ffffffffc0201dd8 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dc8:	00a95a63          	bge	s2,a0,ffffffffc0201ddc <readline+0x54>
ffffffffc0201dcc:	029a5263          	bge	s4,s1,ffffffffc0201df0 <readline+0x68>
        c = getchar();
ffffffffc0201dd0:	b86fe0ef          	jal	ra,ffffffffc0200156 <getchar>
        if (c < 0) {
ffffffffc0201dd4:	fe055ae3          	bgez	a0,ffffffffc0201dc8 <readline+0x40>
            return NULL;
ffffffffc0201dd8:	4501                	li	a0,0
ffffffffc0201dda:	a091                	j	ffffffffc0201e1e <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201ddc:	03351463          	bne	a0,s3,ffffffffc0201e04 <readline+0x7c>
ffffffffc0201de0:	e8a9                	bnez	s1,ffffffffc0201e32 <readline+0xaa>
        c = getchar();
ffffffffc0201de2:	b74fe0ef          	jal	ra,ffffffffc0200156 <getchar>
        if (c < 0) {
ffffffffc0201de6:	fe0549e3          	bltz	a0,ffffffffc0201dd8 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dea:	fea959e3          	bge	s2,a0,ffffffffc0201ddc <readline+0x54>
ffffffffc0201dee:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201df0:	e42a                	sd	a0,8(sp)
ffffffffc0201df2:	b22fe0ef          	jal	ra,ffffffffc0200114 <cputchar>
            buf[i ++] = c;
ffffffffc0201df6:	6522                	ld	a0,8(sp)
ffffffffc0201df8:	009b87b3          	add	a5,s7,s1
ffffffffc0201dfc:	2485                	addiw	s1,s1,1
ffffffffc0201dfe:	00a78023          	sb	a0,0(a5)
ffffffffc0201e02:	bf7d                	j	ffffffffc0201dc0 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e04:	01550463          	beq	a0,s5,ffffffffc0201e0c <readline+0x84>
ffffffffc0201e08:	fb651ce3          	bne	a0,s6,ffffffffc0201dc0 <readline+0x38>
            cputchar(c);
ffffffffc0201e0c:	b08fe0ef          	jal	ra,ffffffffc0200114 <cputchar>
            buf[i] = '\0';
ffffffffc0201e10:	00004517          	auipc	a0,0x4
ffffffffc0201e14:	22850513          	addi	a0,a0,552 # ffffffffc0206038 <buf>
ffffffffc0201e18:	94aa                	add	s1,s1,a0
ffffffffc0201e1a:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201e1e:	60a6                	ld	ra,72(sp)
ffffffffc0201e20:	6486                	ld	s1,64(sp)
ffffffffc0201e22:	7962                	ld	s2,56(sp)
ffffffffc0201e24:	79c2                	ld	s3,48(sp)
ffffffffc0201e26:	7a22                	ld	s4,40(sp)
ffffffffc0201e28:	7a82                	ld	s5,32(sp)
ffffffffc0201e2a:	6b62                	ld	s6,24(sp)
ffffffffc0201e2c:	6bc2                	ld	s7,16(sp)
ffffffffc0201e2e:	6161                	addi	sp,sp,80
ffffffffc0201e30:	8082                	ret
            cputchar(c);
ffffffffc0201e32:	4521                	li	a0,8
ffffffffc0201e34:	ae0fe0ef          	jal	ra,ffffffffc0200114 <cputchar>
            i --;
ffffffffc0201e38:	34fd                	addiw	s1,s1,-1
ffffffffc0201e3a:	b759                	j	ffffffffc0201dc0 <readline+0x38>

ffffffffc0201e3c <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e3c:	4781                	li	a5,0
ffffffffc0201e3e:	00004717          	auipc	a4,0x4
ffffffffc0201e42:	1da73703          	ld	a4,474(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e46:	88ba                	mv	a7,a4
ffffffffc0201e48:	852a                	mv	a0,a0
ffffffffc0201e4a:	85be                	mv	a1,a5
ffffffffc0201e4c:	863e                	mv	a2,a5
ffffffffc0201e4e:	00000073          	ecall
ffffffffc0201e52:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e54:	8082                	ret

ffffffffc0201e56 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e56:	4781                	li	a5,0
ffffffffc0201e58:	00004717          	auipc	a4,0x4
ffffffffc0201e5c:	63073703          	ld	a4,1584(a4) # ffffffffc0206488 <SBI_SET_TIMER>
ffffffffc0201e60:	88ba                	mv	a7,a4
ffffffffc0201e62:	852a                	mv	a0,a0
ffffffffc0201e64:	85be                	mv	a1,a5
ffffffffc0201e66:	863e                	mv	a2,a5
ffffffffc0201e68:	00000073          	ecall
ffffffffc0201e6c:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e6e:	8082                	ret

ffffffffc0201e70 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e70:	4501                	li	a0,0
ffffffffc0201e72:	00004797          	auipc	a5,0x4
ffffffffc0201e76:	19e7b783          	ld	a5,414(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e7a:	88be                	mv	a7,a5
ffffffffc0201e7c:	852a                	mv	a0,a0
ffffffffc0201e7e:	85aa                	mv	a1,a0
ffffffffc0201e80:	862a                	mv	a2,a0
ffffffffc0201e82:	00000073          	ecall
ffffffffc0201e86:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e88:	2501                	sext.w	a0,a0
ffffffffc0201e8a:	8082                	ret

ffffffffc0201e8c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e8c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e90:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e92:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e94:	cb81                	beqz	a5,ffffffffc0201ea4 <strlen+0x18>
        cnt ++;
ffffffffc0201e96:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e98:	00a707b3          	add	a5,a4,a0
ffffffffc0201e9c:	0007c783          	lbu	a5,0(a5)
ffffffffc0201ea0:	fbfd                	bnez	a5,ffffffffc0201e96 <strlen+0xa>
ffffffffc0201ea2:	8082                	ret
    }
    return cnt;
}
ffffffffc0201ea4:	8082                	ret

ffffffffc0201ea6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201ea6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201ea8:	e589                	bnez	a1,ffffffffc0201eb2 <strnlen+0xc>
ffffffffc0201eaa:	a811                	j	ffffffffc0201ebe <strnlen+0x18>
        cnt ++;
ffffffffc0201eac:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201eae:	00f58863          	beq	a1,a5,ffffffffc0201ebe <strnlen+0x18>
ffffffffc0201eb2:	00f50733          	add	a4,a0,a5
ffffffffc0201eb6:	00074703          	lbu	a4,0(a4)
ffffffffc0201eba:	fb6d                	bnez	a4,ffffffffc0201eac <strnlen+0x6>
ffffffffc0201ebc:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201ebe:	852e                	mv	a0,a1
ffffffffc0201ec0:	8082                	ret

ffffffffc0201ec2 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ec2:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ec6:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201eca:	cb89                	beqz	a5,ffffffffc0201edc <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201ecc:	0505                	addi	a0,a0,1
ffffffffc0201ece:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ed0:	fee789e3          	beq	a5,a4,ffffffffc0201ec2 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ed4:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201ed8:	9d19                	subw	a0,a0,a4
ffffffffc0201eda:	8082                	ret
ffffffffc0201edc:	4501                	li	a0,0
ffffffffc0201ede:	bfed                	j	ffffffffc0201ed8 <strcmp+0x16>

ffffffffc0201ee0 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ee0:	c20d                	beqz	a2,ffffffffc0201f02 <strncmp+0x22>
ffffffffc0201ee2:	962e                	add	a2,a2,a1
ffffffffc0201ee4:	a031                	j	ffffffffc0201ef0 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201ee6:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ee8:	00e79a63          	bne	a5,a4,ffffffffc0201efc <strncmp+0x1c>
ffffffffc0201eec:	00b60b63          	beq	a2,a1,ffffffffc0201f02 <strncmp+0x22>
ffffffffc0201ef0:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201ef4:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ef6:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201efa:	f7f5                	bnez	a5,ffffffffc0201ee6 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201efc:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201f00:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f02:	4501                	li	a0,0
ffffffffc0201f04:	8082                	ret

ffffffffc0201f06 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f06:	00054783          	lbu	a5,0(a0)
ffffffffc0201f0a:	c799                	beqz	a5,ffffffffc0201f18 <strchr+0x12>
        if (*s == c) {
ffffffffc0201f0c:	00f58763          	beq	a1,a5,ffffffffc0201f1a <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201f10:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201f14:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201f16:	fbfd                	bnez	a5,ffffffffc0201f0c <strchr+0x6>
    }
    return NULL;
ffffffffc0201f18:	4501                	li	a0,0
}
ffffffffc0201f1a:	8082                	ret

ffffffffc0201f1c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f1c:	ca01                	beqz	a2,ffffffffc0201f2c <memset+0x10>
ffffffffc0201f1e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f20:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201f22:	0785                	addi	a5,a5,1
ffffffffc0201f24:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201f28:	fec79de3          	bne	a5,a2,ffffffffc0201f22 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f2c:	8082                	ret
