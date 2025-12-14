
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000a6517          	auipc	a0,0xa6
ffffffffc020004e:	25650513          	addi	a0,a0,598 # ffffffffc02a62a0 <buf>
ffffffffc0200052:	000aa617          	auipc	a2,0xaa
ffffffffc0200056:	6f260613          	addi	a2,a2,1778 # ffffffffc02aa744 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	7f8050ef          	jal	ra,ffffffffc020585a <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	81a58593          	addi	a1,a1,-2022 # ffffffffc0205888 <etext+0x4>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	83250513          	addi	a0,a0,-1998 # ffffffffc02058a8 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	616020ef          	jal	ra,ffffffffc020269c <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	367030ef          	jal	ra,ffffffffc0203bf8 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	717040ef          	jal	ra,ffffffffc0204fac <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	0a2050ef          	jal	ra,ffffffffc0205144 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00005517          	auipc	a0,0x5
ffffffffc02000c0:	7f450513          	addi	a0,a0,2036 # ffffffffc02058b0 <etext+0x2c>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000a6b97          	auipc	s7,0xa6
ffffffffc02000d6:	1ceb8b93          	addi	s7,s7,462 # ffffffffc02a62a0 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000a6517          	auipc	a0,0xa6
ffffffffc0200132:	17250513          	addi	a0,a0,370 # ffffffffc02a62a0 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	2ae050ef          	jal	ra,ffffffffc0205436 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	278050ef          	jal	ra,ffffffffc0205436 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	69a50513          	addi	a0,a0,1690 # ffffffffc02058b8 <etext+0x34>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	6a450513          	addi	a0,a0,1700 # ffffffffc02058d8 <etext+0x54>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	64458593          	addi	a1,a1,1604 # ffffffffc0205884 <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	6b050513          	addi	a0,a0,1712 # ffffffffc02058f8 <etext+0x74>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	04c58593          	addi	a1,a1,76 # ffffffffc02a62a0 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	6bc50513          	addi	a0,a0,1724 # ffffffffc0205918 <etext+0x94>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	4dc58593          	addi	a1,a1,1244 # ffffffffc02aa744 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	6c850513          	addi	a0,a0,1736 # ffffffffc0205938 <etext+0xb4>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	8c758593          	addi	a1,a1,-1849 # ffffffffc02aab43 <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	6ba50513          	addi	a0,a0,1722 # ffffffffc0205958 <etext+0xd4>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	6dc60613          	addi	a2,a2,1756 # ffffffffc0205988 <etext+0x104>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	6e850513          	addi	a0,a0,1768 # ffffffffc02059a0 <etext+0x11c>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	6f060613          	addi	a2,a2,1776 # ffffffffc02059b8 <etext+0x134>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	70858593          	addi	a1,a1,1800 # ffffffffc02059d8 <etext+0x154>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	70850513          	addi	a0,a0,1800 # ffffffffc02059e0 <etext+0x15c>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	70a60613          	addi	a2,a2,1802 # ffffffffc02059f0 <etext+0x16c>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	72a58593          	addi	a1,a1,1834 # ffffffffc0205a18 <etext+0x194>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	6ea50513          	addi	a0,a0,1770 # ffffffffc02059e0 <etext+0x15c>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	72660613          	addi	a2,a2,1830 # ffffffffc0205a28 <etext+0x1a4>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	73e58593          	addi	a1,a1,1854 # ffffffffc0205a48 <etext+0x1c4>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	6ce50513          	addi	a0,a0,1742 # ffffffffc02059e0 <etext+0x15c>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00005517          	auipc	a0,0x5
ffffffffc0200350:	70c50513          	addi	a0,a0,1804 # ffffffffc0205a58 <etext+0x1d4>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00005517          	auipc	a0,0x5
ffffffffc0200372:	71250513          	addi	a0,a0,1810 # ffffffffc0205a80 <etext+0x1fc>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	76cc0c13          	addi	s8,s8,1900 # ffffffffc0205af0 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	71c90913          	addi	s2,s2,1820 # ffffffffc0205aa8 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	71c48493          	addi	s1,s1,1820 # ffffffffc0205ab0 <etext+0x22c>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	71ab0b13          	addi	s6,s6,1818 # ffffffffc0205ab8 <etext+0x234>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	632a0a13          	addi	s4,s4,1586 # ffffffffc02059d8 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00005d17          	auipc	s10,0x5
ffffffffc02003cc:	728d0d13          	addi	s10,s10,1832 # ffffffffc0205af0 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	42a050ef          	jal	ra,ffffffffc0205800 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	416050ef          	jal	ra,ffffffffc0205800 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	41c050ef          	jal	ra,ffffffffc0205844 <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	3de050ef          	jal	ra,ffffffffc0205844 <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	65850513          	addi	a0,a0,1624 # ffffffffc0205ad8 <etext+0x254>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000aa317          	auipc	t1,0xaa
ffffffffc0200492:	23a30313          	addi	t1,t1,570 # ffffffffc02aa6c8 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	67c50513          	addi	a0,a0,1660 # ffffffffc0205b38 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00006517          	auipc	a0,0x6
ffffffffc02004d6:	76e50513          	addi	a0,a0,1902 # ffffffffc0206c40 <default_pmm_manager+0x578>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	65250513          	addi	a0,a0,1618 # ffffffffc0205b58 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00006517          	auipc	a0,0x6
ffffffffc020052a:	71a50513          	addi	a0,a0,1818 # ffffffffc0206c40 <default_pmm_manager+0x578>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd580>
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	18f73c23          	sd	a5,408(a4) # ffffffffc02aa6d8 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	61850513          	addi	a0,a0,1560 # ffffffffc0205b78 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	1607b423          	sd	zero,360(a5) # ffffffffc02aa6d0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	1627b783          	ld	a5,354(a5) # ffffffffc02aa6d8 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	59850513          	addi	a0,a0,1432 # ffffffffc0205b98 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	57a50513          	addi	a0,a0,1402 # ffffffffc0205ba8 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	57450513          	addi	a0,a0,1396 # ffffffffc0205bb8 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	57c50513          	addi	a0,a0,1404 # ffffffffc0205bd0 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe357a9>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	51290913          	addi	s2,s2,1298 # ffffffffc0205c20 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	4fc48493          	addi	s1,s1,1276 # ffffffffc0205c18 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	52850513          	addi	a0,a0,1320 # ffffffffc0205c98 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	55450513          	addi	a0,a0,1364 # ffffffffc0205cd0 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	43450513          	addi	a0,a0,1076 # ffffffffc0205bf0 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	7ef040ef          	jal	ra,ffffffffc02057b8 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	046050ef          	jal	ra,ffffffffc020581e <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	793040ef          	jal	ra,ffffffffc0205800 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	3a650513          	addi	a0,a0,934 # ffffffffc0205c28 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	2f850513          	addi	a0,a0,760 # ffffffffc0205c48 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	2fe50513          	addi	a0,a0,766 # ffffffffc0205c60 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	30c50513          	addi	a0,a0,780 # ffffffffc0205c80 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	35050513          	addi	a0,a0,848 # ffffffffc0205cd0 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	d487bc23          	sd	s0,-680(a5) # ffffffffc02aa6e0 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	d567bc23          	sd	s6,-680(a5) # ffffffffc02aa6e8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	d4653503          	ld	a0,-698(a0) # ffffffffc02aa6e0 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	d4453503          	ld	a0,-700(a0) # ffffffffc02aa6e8 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	4e478793          	addi	a5,a5,1252 # ffffffffc0200ea4 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	30a50513          	addi	a0,a0,778 # ffffffffc0205ce8 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	31250513          	addi	a0,a0,786 # ffffffffc0205d00 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	31c50513          	addi	a0,a0,796 # ffffffffc0205d18 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	32650513          	addi	a0,a0,806 # ffffffffc0205d30 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	33050513          	addi	a0,a0,816 # ffffffffc0205d48 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	33a50513          	addi	a0,a0,826 # ffffffffc0205d60 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	34450513          	addi	a0,a0,836 # ffffffffc0205d78 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	34e50513          	addi	a0,a0,846 # ffffffffc0205d90 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	35850513          	addi	a0,a0,856 # ffffffffc0205da8 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	36250513          	addi	a0,a0,866 # ffffffffc0205dc0 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	36c50513          	addi	a0,a0,876 # ffffffffc0205dd8 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	37650513          	addi	a0,a0,886 # ffffffffc0205df0 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	38050513          	addi	a0,a0,896 # ffffffffc0205e08 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	38a50513          	addi	a0,a0,906 # ffffffffc0205e20 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	39450513          	addi	a0,a0,916 # ffffffffc0205e38 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	39e50513          	addi	a0,a0,926 # ffffffffc0205e50 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	3a850513          	addi	a0,a0,936 # ffffffffc0205e68 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	3b250513          	addi	a0,a0,946 # ffffffffc0205e80 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	3bc50513          	addi	a0,a0,956 # ffffffffc0205e98 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	3c650513          	addi	a0,a0,966 # ffffffffc0205eb0 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	3d050513          	addi	a0,a0,976 # ffffffffc0205ec8 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	3da50513          	addi	a0,a0,986 # ffffffffc0205ee0 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	3e450513          	addi	a0,a0,996 # ffffffffc0205ef8 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	3ee50513          	addi	a0,a0,1006 # ffffffffc0205f10 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	3f850513          	addi	a0,a0,1016 # ffffffffc0205f28 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	40250513          	addi	a0,a0,1026 # ffffffffc0205f40 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	40c50513          	addi	a0,a0,1036 # ffffffffc0205f58 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	41650513          	addi	a0,a0,1046 # ffffffffc0205f70 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	42050513          	addi	a0,a0,1056 # ffffffffc0205f88 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	42a50513          	addi	a0,a0,1066 # ffffffffc0205fa0 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	43450513          	addi	a0,a0,1076 # ffffffffc0205fb8 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	43a50513          	addi	a0,a0,1082 # ffffffffc0205fd0 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	43c50513          	addi	a0,a0,1084 # ffffffffc0205fe8 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	43c50513          	addi	a0,a0,1084 # ffffffffc0206000 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	44450513          	addi	a0,a0,1092 # ffffffffc0206018 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	44c50513          	addi	a0,a0,1100 # ffffffffc0206030 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	44850513          	addi	a0,a0,1096 # ffffffffc0206040 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	06f76d63          	bltu	a4,a5,ffffffffc0200c8a <interrupt_handler+0x84>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	4f470713          	addi	a4,a4,1268 # ffffffffc0206108 <commands+0x618>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	49250513          	addi	a0,a0,1170 # ffffffffc02060b8 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	46650513          	addi	a0,a0,1126 # ffffffffc0206098 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	41a50513          	addi	a0,a0,1050 # ffffffffc0206058 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	42e50513          	addi	a0,a0,1070 # ffffffffc0206078 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        ticks++;
ffffffffc0200c5e:	000aa797          	auipc	a5,0xaa
ffffffffc0200c62:	a7278793          	addi	a5,a5,-1422 # ffffffffc02aa6d0 <ticks>
ffffffffc0200c66:	6398                	ld	a4,0(a5)
ffffffffc0200c68:	0705                	addi	a4,a4,1
ffffffffc0200c6a:	e398                	sd	a4,0(a5)
        if (ticks % TICK_NUM == 0)
ffffffffc0200c6c:	639c                	ld	a5,0(a5)
ffffffffc0200c6e:	06400713          	li	a4,100
ffffffffc0200c72:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c76:	cb99                	beqz	a5,ffffffffc0200c8c <interrupt_handler+0x86>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c78:	60a2                	ld	ra,8(sp)
ffffffffc0200c7a:	0141                	addi	sp,sp,16
ffffffffc0200c7c:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c7e:	00005517          	auipc	a0,0x5
ffffffffc0200c82:	46a50513          	addi	a0,a0,1130 # ffffffffc02060e8 <commands+0x5f8>
ffffffffc0200c86:	d0eff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c8a:	bf29                	j	ffffffffc0200ba4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c8c:	06400593          	li	a1,100
ffffffffc0200c90:	00005517          	auipc	a0,0x5
ffffffffc0200c94:	44850513          	addi	a0,a0,1096 # ffffffffc02060d8 <commands+0x5e8>
ffffffffc0200c98:	cfcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            if (current != NULL && current->state == PROC_RUNNABLE)
ffffffffc0200c9c:	000aa797          	auipc	a5,0xaa
ffffffffc0200ca0:	a8c7b783          	ld	a5,-1396(a5) # ffffffffc02aa728 <current>
ffffffffc0200ca4:	dbf1                	beqz	a5,ffffffffc0200c78 <interrupt_handler+0x72>
ffffffffc0200ca6:	4394                	lw	a3,0(a5)
ffffffffc0200ca8:	4709                	li	a4,2
ffffffffc0200caa:	fce697e3          	bne	a3,a4,ffffffffc0200c78 <interrupt_handler+0x72>
                current->need_resched = 1;
ffffffffc0200cae:	4705                	li	a4,1
ffffffffc0200cb0:	ef98                	sd	a4,24(a5)
ffffffffc0200cb2:	b7d9                	j	ffffffffc0200c78 <interrupt_handler+0x72>

ffffffffc0200cb4 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200cb4:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cb8:	1141                	addi	sp,sp,-16
ffffffffc0200cba:	e022                	sd	s0,0(sp)
ffffffffc0200cbc:	e406                	sd	ra,8(sp)
ffffffffc0200cbe:	473d                	li	a4,15
ffffffffc0200cc0:	842a                	mv	s0,a0
ffffffffc0200cc2:	10f76763          	bltu	a4,a5,ffffffffc0200dd0 <exception_handler+0x11c>
ffffffffc0200cc6:	00005717          	auipc	a4,0x5
ffffffffc0200cca:	60270713          	addi	a4,a4,1538 # ffffffffc02062c8 <commands+0x7d8>
ffffffffc0200cce:	078a                	slli	a5,a5,0x2
ffffffffc0200cd0:	97ba                	add	a5,a5,a4
ffffffffc0200cd2:	439c                	lw	a5,0(a5)
ffffffffc0200cd4:	97ba                	add	a5,a5,a4
ffffffffc0200cd6:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cd8:	00005517          	auipc	a0,0x5
ffffffffc0200cdc:	54850513          	addi	a0,a0,1352 # ffffffffc0206220 <commands+0x730>
ffffffffc0200ce0:	cb4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200ce4:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200ce8:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200cea:	0791                	addi	a5,a5,4
ffffffffc0200cec:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200cf0:	6402                	ld	s0,0(sp)
ffffffffc0200cf2:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200cf4:	6400406f          	j	ffffffffc0205334 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cf8:	00005517          	auipc	a0,0x5
ffffffffc0200cfc:	54850513          	addi	a0,a0,1352 # ffffffffc0206240 <commands+0x750>
}
ffffffffc0200d00:	6402                	ld	s0,0(sp)
ffffffffc0200d02:	60a2                	ld	ra,8(sp)
ffffffffc0200d04:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d06:	c8eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d0a:	00005517          	auipc	a0,0x5
ffffffffc0200d0e:	55650513          	addi	a0,a0,1366 # ffffffffc0206260 <commands+0x770>
ffffffffc0200d12:	b7fd                	j	ffffffffc0200d00 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d14:	00005517          	auipc	a0,0x5
ffffffffc0200d18:	56c50513          	addi	a0,a0,1388 # ffffffffc0206280 <commands+0x790>
ffffffffc0200d1c:	c78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (current != NULL && current->mm != NULL)
ffffffffc0200d20:	000aa797          	auipc	a5,0xaa
ffffffffc0200d24:	a087b783          	ld	a5,-1528(a5) # ffffffffc02aa728 <current>
ffffffffc0200d28:	c3c9                	beqz	a5,ffffffffc0200daa <exception_handler+0xf6>
ffffffffc0200d2a:	7788                	ld	a0,40(a5)
ffffffffc0200d2c:	cd3d                	beqz	a0,ffffffffc0200daa <exception_handler+0xf6>
            if (do_pgfault(current->mm, tf->cause, tf->tval) != 0)
ffffffffc0200d2e:	11043603          	ld	a2,272(s0)
ffffffffc0200d32:	11842583          	lw	a1,280(s0)
ffffffffc0200d36:	4d9020ef          	jal	ra,ffffffffc0203a0e <do_pgfault>
ffffffffc0200d3a:	c925                	beqz	a0,ffffffffc0200daa <exception_handler+0xf6>
}
ffffffffc0200d3c:	6402                	ld	s0,0(sp)
ffffffffc0200d3e:	60a2                	ld	ra,8(sp)
                do_exit(-E_KILLED);
ffffffffc0200d40:	555d                	li	a0,-9
}
ffffffffc0200d42:	0141                	addi	sp,sp,16
                do_exit(-E_KILLED);
ffffffffc0200d44:	04b0306f          	j	ffffffffc020458e <do_exit>
        cprintf("Load page fault\n");
ffffffffc0200d48:	00005517          	auipc	a0,0x5
ffffffffc0200d4c:	55050513          	addi	a0,a0,1360 # ffffffffc0206298 <commands+0x7a8>
ffffffffc0200d50:	c44ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (current != NULL && current->mm != NULL)
ffffffffc0200d54:	000aa797          	auipc	a5,0xaa
ffffffffc0200d58:	9d47b783          	ld	a5,-1580(a5) # ffffffffc02aa728 <current>
ffffffffc0200d5c:	f7f9                	bnez	a5,ffffffffc0200d2a <exception_handler+0x76>
ffffffffc0200d5e:	a0b1                	j	ffffffffc0200daa <exception_handler+0xf6>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d60:	00005517          	auipc	a0,0x5
ffffffffc0200d64:	55050513          	addi	a0,a0,1360 # ffffffffc02062b0 <commands+0x7c0>
ffffffffc0200d68:	c2cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (current != NULL && current->mm != NULL)
ffffffffc0200d6c:	000aa797          	auipc	a5,0xaa
ffffffffc0200d70:	9bc7b783          	ld	a5,-1604(a5) # ffffffffc02aa728 <current>
ffffffffc0200d74:	fbdd                	bnez	a5,ffffffffc0200d2a <exception_handler+0x76>
ffffffffc0200d76:	a815                	j	ffffffffc0200daa <exception_handler+0xf6>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d78:	00005517          	auipc	a0,0x5
ffffffffc0200d7c:	3c050513          	addi	a0,a0,960 # ffffffffc0206138 <commands+0x648>
ffffffffc0200d80:	b741                	j	ffffffffc0200d00 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d82:	00005517          	auipc	a0,0x5
ffffffffc0200d86:	3d650513          	addi	a0,a0,982 # ffffffffc0206158 <commands+0x668>
ffffffffc0200d8a:	bf9d                	j	ffffffffc0200d00 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d8c:	00005517          	auipc	a0,0x5
ffffffffc0200d90:	3ec50513          	addi	a0,a0,1004 # ffffffffc0206178 <commands+0x688>
ffffffffc0200d94:	b7b5                	j	ffffffffc0200d00 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d96:	00005517          	auipc	a0,0x5
ffffffffc0200d9a:	3fa50513          	addi	a0,a0,1018 # ffffffffc0206190 <commands+0x6a0>
ffffffffc0200d9e:	bf6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200da2:	6458                	ld	a4,136(s0)
ffffffffc0200da4:	47a9                	li	a5,10
ffffffffc0200da6:	04f70663          	beq	a4,a5,ffffffffc0200df2 <exception_handler+0x13e>
}
ffffffffc0200daa:	60a2                	ld	ra,8(sp)
ffffffffc0200dac:	6402                	ld	s0,0(sp)
ffffffffc0200dae:	0141                	addi	sp,sp,16
ffffffffc0200db0:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200db2:	00005517          	auipc	a0,0x5
ffffffffc0200db6:	3ee50513          	addi	a0,a0,1006 # ffffffffc02061a0 <commands+0x6b0>
ffffffffc0200dba:	b799                	j	ffffffffc0200d00 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200dbc:	00005517          	auipc	a0,0x5
ffffffffc0200dc0:	40450513          	addi	a0,a0,1028 # ffffffffc02061c0 <commands+0x6d0>
ffffffffc0200dc4:	bf35                	j	ffffffffc0200d00 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200dc6:	00005517          	auipc	a0,0x5
ffffffffc0200dca:	44250513          	addi	a0,a0,1090 # ffffffffc0206208 <commands+0x718>
ffffffffc0200dce:	bf0d                	j	ffffffffc0200d00 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200dd0:	8522                	mv	a0,s0
}
ffffffffc0200dd2:	6402                	ld	s0,0(sp)
ffffffffc0200dd4:	60a2                	ld	ra,8(sp)
ffffffffc0200dd6:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200dd8:	b3f1                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200dda:	00005617          	auipc	a2,0x5
ffffffffc0200dde:	3fe60613          	addi	a2,a2,1022 # ffffffffc02061d8 <commands+0x6e8>
ffffffffc0200de2:	0c300593          	li	a1,195
ffffffffc0200de6:	00005517          	auipc	a0,0x5
ffffffffc0200dea:	40a50513          	addi	a0,a0,1034 # ffffffffc02061f0 <commands+0x700>
ffffffffc0200dee:	ea0ff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0200df2:	10843783          	ld	a5,264(s0)
ffffffffc0200df6:	0791                	addi	a5,a5,4
ffffffffc0200df8:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200dfc:	538040ef          	jal	ra,ffffffffc0205334 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e00:	000aa797          	auipc	a5,0xaa
ffffffffc0200e04:	9287b783          	ld	a5,-1752(a5) # ffffffffc02aa728 <current>
ffffffffc0200e08:	6b9c                	ld	a5,16(a5)
ffffffffc0200e0a:	8522                	mv	a0,s0
}
ffffffffc0200e0c:	6402                	ld	s0,0(sp)
ffffffffc0200e0e:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e10:	6589                	lui	a1,0x2
ffffffffc0200e12:	95be                	add	a1,a1,a5
}
ffffffffc0200e14:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e16:	aab1                	j	ffffffffc0200f72 <kernel_execve_ret>

ffffffffc0200e18 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200e18:	1101                	addi	sp,sp,-32
ffffffffc0200e1a:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e1c:	000aa417          	auipc	s0,0xaa
ffffffffc0200e20:	90c40413          	addi	s0,s0,-1780 # ffffffffc02aa728 <current>
ffffffffc0200e24:	6018                	ld	a4,0(s0)
{
ffffffffc0200e26:	ec06                	sd	ra,24(sp)
ffffffffc0200e28:	e426                	sd	s1,8(sp)
ffffffffc0200e2a:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e2c:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200e30:	cf1d                	beqz	a4,ffffffffc0200e6e <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e32:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200e36:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200e3a:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e3c:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e40:	0206c463          	bltz	a3,ffffffffc0200e68 <trap+0x50>
        exception_handler(tf);
ffffffffc0200e44:	e71ff0ef          	jal	ra,ffffffffc0200cb4 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e48:	601c                	ld	a5,0(s0)
ffffffffc0200e4a:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200e4e:	e499                	bnez	s1,ffffffffc0200e5c <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e50:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e54:	8b05                	andi	a4,a4,1
ffffffffc0200e56:	e329                	bnez	a4,ffffffffc0200e98 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e58:	6f9c                	ld	a5,24(a5)
ffffffffc0200e5a:	eb85                	bnez	a5,ffffffffc0200e8a <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e5c:	60e2                	ld	ra,24(sp)
ffffffffc0200e5e:	6442                	ld	s0,16(sp)
ffffffffc0200e60:	64a2                	ld	s1,8(sp)
ffffffffc0200e62:	6902                	ld	s2,0(sp)
ffffffffc0200e64:	6105                	addi	sp,sp,32
ffffffffc0200e66:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e68:	d9fff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200e6c:	bff1                	j	ffffffffc0200e48 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e6e:	0006c863          	bltz	a3,ffffffffc0200e7e <trap+0x66>
}
ffffffffc0200e72:	6442                	ld	s0,16(sp)
ffffffffc0200e74:	60e2                	ld	ra,24(sp)
ffffffffc0200e76:	64a2                	ld	s1,8(sp)
ffffffffc0200e78:	6902                	ld	s2,0(sp)
ffffffffc0200e7a:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e7c:	bd25                	j	ffffffffc0200cb4 <exception_handler>
}
ffffffffc0200e7e:	6442                	ld	s0,16(sp)
ffffffffc0200e80:	60e2                	ld	ra,24(sp)
ffffffffc0200e82:	64a2                	ld	s1,8(sp)
ffffffffc0200e84:	6902                	ld	s2,0(sp)
ffffffffc0200e86:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e88:	bbbd                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200e8a:	6442                	ld	s0,16(sp)
ffffffffc0200e8c:	60e2                	ld	ra,24(sp)
ffffffffc0200e8e:	64a2                	ld	s1,8(sp)
ffffffffc0200e90:	6902                	ld	s2,0(sp)
ffffffffc0200e92:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e94:	3b40406f          	j	ffffffffc0205248 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e98:	555d                	li	a0,-9
ffffffffc0200e9a:	6f4030ef          	jal	ra,ffffffffc020458e <do_exit>
            if (current->need_resched)
ffffffffc0200e9e:	601c                	ld	a5,0(s0)
ffffffffc0200ea0:	bf65                	j	ffffffffc0200e58 <trap+0x40>
	...

ffffffffc0200ea4 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ea4:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200ea8:	00011463          	bnez	sp,ffffffffc0200eb0 <__alltraps+0xc>
ffffffffc0200eac:	14002173          	csrr	sp,sscratch
ffffffffc0200eb0:	712d                	addi	sp,sp,-288
ffffffffc0200eb2:	e002                	sd	zero,0(sp)
ffffffffc0200eb4:	e406                	sd	ra,8(sp)
ffffffffc0200eb6:	ec0e                	sd	gp,24(sp)
ffffffffc0200eb8:	f012                	sd	tp,32(sp)
ffffffffc0200eba:	f416                	sd	t0,40(sp)
ffffffffc0200ebc:	f81a                	sd	t1,48(sp)
ffffffffc0200ebe:	fc1e                	sd	t2,56(sp)
ffffffffc0200ec0:	e0a2                	sd	s0,64(sp)
ffffffffc0200ec2:	e4a6                	sd	s1,72(sp)
ffffffffc0200ec4:	e8aa                	sd	a0,80(sp)
ffffffffc0200ec6:	ecae                	sd	a1,88(sp)
ffffffffc0200ec8:	f0b2                	sd	a2,96(sp)
ffffffffc0200eca:	f4b6                	sd	a3,104(sp)
ffffffffc0200ecc:	f8ba                	sd	a4,112(sp)
ffffffffc0200ece:	fcbe                	sd	a5,120(sp)
ffffffffc0200ed0:	e142                	sd	a6,128(sp)
ffffffffc0200ed2:	e546                	sd	a7,136(sp)
ffffffffc0200ed4:	e94a                	sd	s2,144(sp)
ffffffffc0200ed6:	ed4e                	sd	s3,152(sp)
ffffffffc0200ed8:	f152                	sd	s4,160(sp)
ffffffffc0200eda:	f556                	sd	s5,168(sp)
ffffffffc0200edc:	f95a                	sd	s6,176(sp)
ffffffffc0200ede:	fd5e                	sd	s7,184(sp)
ffffffffc0200ee0:	e1e2                	sd	s8,192(sp)
ffffffffc0200ee2:	e5e6                	sd	s9,200(sp)
ffffffffc0200ee4:	e9ea                	sd	s10,208(sp)
ffffffffc0200ee6:	edee                	sd	s11,216(sp)
ffffffffc0200ee8:	f1f2                	sd	t3,224(sp)
ffffffffc0200eea:	f5f6                	sd	t4,232(sp)
ffffffffc0200eec:	f9fa                	sd	t5,240(sp)
ffffffffc0200eee:	fdfe                	sd	t6,248(sp)
ffffffffc0200ef0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ef4:	100024f3          	csrr	s1,sstatus
ffffffffc0200ef8:	14102973          	csrr	s2,sepc
ffffffffc0200efc:	143029f3          	csrr	s3,stval
ffffffffc0200f00:	14202a73          	csrr	s4,scause
ffffffffc0200f04:	e822                	sd	s0,16(sp)
ffffffffc0200f06:	e226                	sd	s1,256(sp)
ffffffffc0200f08:	e64a                	sd	s2,264(sp)
ffffffffc0200f0a:	ea4e                	sd	s3,272(sp)
ffffffffc0200f0c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f0e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f10:	f09ff0ef          	jal	ra,ffffffffc0200e18 <trap>

ffffffffc0200f14 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f14:	6492                	ld	s1,256(sp)
ffffffffc0200f16:	6932                	ld	s2,264(sp)
ffffffffc0200f18:	1004f413          	andi	s0,s1,256
ffffffffc0200f1c:	e401                	bnez	s0,ffffffffc0200f24 <__trapret+0x10>
ffffffffc0200f1e:	1200                	addi	s0,sp,288
ffffffffc0200f20:	14041073          	csrw	sscratch,s0
ffffffffc0200f24:	10049073          	csrw	sstatus,s1
ffffffffc0200f28:	14191073          	csrw	sepc,s2
ffffffffc0200f2c:	60a2                	ld	ra,8(sp)
ffffffffc0200f2e:	61e2                	ld	gp,24(sp)
ffffffffc0200f30:	7202                	ld	tp,32(sp)
ffffffffc0200f32:	72a2                	ld	t0,40(sp)
ffffffffc0200f34:	7342                	ld	t1,48(sp)
ffffffffc0200f36:	73e2                	ld	t2,56(sp)
ffffffffc0200f38:	6406                	ld	s0,64(sp)
ffffffffc0200f3a:	64a6                	ld	s1,72(sp)
ffffffffc0200f3c:	6546                	ld	a0,80(sp)
ffffffffc0200f3e:	65e6                	ld	a1,88(sp)
ffffffffc0200f40:	7606                	ld	a2,96(sp)
ffffffffc0200f42:	76a6                	ld	a3,104(sp)
ffffffffc0200f44:	7746                	ld	a4,112(sp)
ffffffffc0200f46:	77e6                	ld	a5,120(sp)
ffffffffc0200f48:	680a                	ld	a6,128(sp)
ffffffffc0200f4a:	68aa                	ld	a7,136(sp)
ffffffffc0200f4c:	694a                	ld	s2,144(sp)
ffffffffc0200f4e:	69ea                	ld	s3,152(sp)
ffffffffc0200f50:	7a0a                	ld	s4,160(sp)
ffffffffc0200f52:	7aaa                	ld	s5,168(sp)
ffffffffc0200f54:	7b4a                	ld	s6,176(sp)
ffffffffc0200f56:	7bea                	ld	s7,184(sp)
ffffffffc0200f58:	6c0e                	ld	s8,192(sp)
ffffffffc0200f5a:	6cae                	ld	s9,200(sp)
ffffffffc0200f5c:	6d4e                	ld	s10,208(sp)
ffffffffc0200f5e:	6dee                	ld	s11,216(sp)
ffffffffc0200f60:	7e0e                	ld	t3,224(sp)
ffffffffc0200f62:	7eae                	ld	t4,232(sp)
ffffffffc0200f64:	7f4e                	ld	t5,240(sp)
ffffffffc0200f66:	7fee                	ld	t6,248(sp)
ffffffffc0200f68:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f6a:	10200073          	sret

ffffffffc0200f6e <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f6e:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200f70:	b755                	j	ffffffffc0200f14 <__trapret>

ffffffffc0200f72 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200f72:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200f76:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200f7a:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f7e:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f82:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f86:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f8a:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f8e:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f92:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200f96:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200f98:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200f9a:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200f9c:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200f9e:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200fa0:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200fa2:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200fa4:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200fa6:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200fa8:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200faa:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200fac:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200fae:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200fb0:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200fb2:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200fb4:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200fb6:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200fb8:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200fba:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200fbc:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200fbe:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200fc0:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200fc2:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200fc4:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200fc6:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200fc8:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200fca:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200fcc:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200fce:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200fd0:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200fd2:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200fd4:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200fd6:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200fd8:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200fda:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200fdc:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200fde:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200fe0:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200fe2:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200fe4:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200fe6:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200fe8:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200fea:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200fec:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200fee:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200ff0:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200ff2:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200ff4:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200ff6:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200ff8:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200ffa:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200ffc:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200ffe:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0201000:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0201002:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201004:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0201006:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0201008:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc020100a:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc020100c:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc020100e:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201010:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0201012:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201014:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0201016:	812e                	mv	sp,a1
ffffffffc0201018:	bdf5                	j	ffffffffc0200f14 <__trapret>

ffffffffc020101a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020101a:	000a5797          	auipc	a5,0xa5
ffffffffc020101e:	68678793          	addi	a5,a5,1670 # ffffffffc02a66a0 <free_area>
ffffffffc0201022:	e79c                	sd	a5,8(a5)
ffffffffc0201024:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0201026:	0007a823          	sw	zero,16(a5)
}
ffffffffc020102a:	8082                	ret

ffffffffc020102c <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc020102c:	000a5517          	auipc	a0,0xa5
ffffffffc0201030:	68456503          	lwu	a0,1668(a0) # ffffffffc02a66b0 <free_area+0x10>
ffffffffc0201034:	8082                	ret

ffffffffc0201036 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0201036:	715d                	addi	sp,sp,-80
ffffffffc0201038:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020103a:	000a5417          	auipc	s0,0xa5
ffffffffc020103e:	66640413          	addi	s0,s0,1638 # ffffffffc02a66a0 <free_area>
ffffffffc0201042:	641c                	ld	a5,8(s0)
ffffffffc0201044:	e486                	sd	ra,72(sp)
ffffffffc0201046:	fc26                	sd	s1,56(sp)
ffffffffc0201048:	f84a                	sd	s2,48(sp)
ffffffffc020104a:	f44e                	sd	s3,40(sp)
ffffffffc020104c:	f052                	sd	s4,32(sp)
ffffffffc020104e:	ec56                	sd	s5,24(sp)
ffffffffc0201050:	e85a                	sd	s6,16(sp)
ffffffffc0201052:	e45e                	sd	s7,8(sp)
ffffffffc0201054:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201056:	2a878d63          	beq	a5,s0,ffffffffc0201310 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc020105a:	4481                	li	s1,0
ffffffffc020105c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020105e:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201062:	8b09                	andi	a4,a4,2
ffffffffc0201064:	2a070a63          	beqz	a4,ffffffffc0201318 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0201068:	ff87a703          	lw	a4,-8(a5)
ffffffffc020106c:	679c                	ld	a5,8(a5)
ffffffffc020106e:	2905                	addiw	s2,s2,1
ffffffffc0201070:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201072:	fe8796e3          	bne	a5,s0,ffffffffc020105e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0201076:	89a6                	mv	s3,s1
ffffffffc0201078:	6df000ef          	jal	ra,ffffffffc0201f56 <nr_free_pages>
ffffffffc020107c:	6f351e63          	bne	a0,s3,ffffffffc0201778 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201080:	4505                	li	a0,1
ffffffffc0201082:	657000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc0201086:	8aaa                	mv	s5,a0
ffffffffc0201088:	42050863          	beqz	a0,ffffffffc02014b8 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020108c:	4505                	li	a0,1
ffffffffc020108e:	64b000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc0201092:	89aa                	mv	s3,a0
ffffffffc0201094:	70050263          	beqz	a0,ffffffffc0201798 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201098:	4505                	li	a0,1
ffffffffc020109a:	63f000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc020109e:	8a2a                	mv	s4,a0
ffffffffc02010a0:	48050c63          	beqz	a0,ffffffffc0201538 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010a4:	293a8a63          	beq	s5,s3,ffffffffc0201338 <default_check+0x302>
ffffffffc02010a8:	28aa8863          	beq	s5,a0,ffffffffc0201338 <default_check+0x302>
ffffffffc02010ac:	28a98663          	beq	s3,a0,ffffffffc0201338 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02010b0:	000aa783          	lw	a5,0(s5)
ffffffffc02010b4:	2a079263          	bnez	a5,ffffffffc0201358 <default_check+0x322>
ffffffffc02010b8:	0009a783          	lw	a5,0(s3)
ffffffffc02010bc:	28079e63          	bnez	a5,ffffffffc0201358 <default_check+0x322>
ffffffffc02010c0:	411c                	lw	a5,0(a0)
ffffffffc02010c2:	28079b63          	bnez	a5,ffffffffc0201358 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc02010c6:	000a9797          	auipc	a5,0xa9
ffffffffc02010ca:	64a7b783          	ld	a5,1610(a5) # ffffffffc02aa710 <pages>
ffffffffc02010ce:	40fa8733          	sub	a4,s5,a5
ffffffffc02010d2:	00007617          	auipc	a2,0x7
ffffffffc02010d6:	8fe63603          	ld	a2,-1794(a2) # ffffffffc02079d0 <nbase>
ffffffffc02010da:	8719                	srai	a4,a4,0x6
ffffffffc02010dc:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010de:	000a9697          	auipc	a3,0xa9
ffffffffc02010e2:	62a6b683          	ld	a3,1578(a3) # ffffffffc02aa708 <npage>
ffffffffc02010e6:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc02010e8:	0732                	slli	a4,a4,0xc
ffffffffc02010ea:	28d77763          	bgeu	a4,a3,ffffffffc0201378 <default_check+0x342>
    return page - pages + nbase;
ffffffffc02010ee:	40f98733          	sub	a4,s3,a5
ffffffffc02010f2:	8719                	srai	a4,a4,0x6
ffffffffc02010f4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010f6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010f8:	4cd77063          	bgeu	a4,a3,ffffffffc02015b8 <default_check+0x582>
    return page - pages + nbase;
ffffffffc02010fc:	40f507b3          	sub	a5,a0,a5
ffffffffc0201100:	8799                	srai	a5,a5,0x6
ffffffffc0201102:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201104:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201106:	30d7f963          	bgeu	a5,a3,ffffffffc0201418 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc020110a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020110c:	00043c03          	ld	s8,0(s0)
ffffffffc0201110:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201114:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201118:	e400                	sd	s0,8(s0)
ffffffffc020111a:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020111c:	000a5797          	auipc	a5,0xa5
ffffffffc0201120:	5807aa23          	sw	zero,1428(a5) # ffffffffc02a66b0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201124:	5b5000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc0201128:	2c051863          	bnez	a0,ffffffffc02013f8 <default_check+0x3c2>
    free_page(p0);
ffffffffc020112c:	4585                	li	a1,1
ffffffffc020112e:	8556                	mv	a0,s5
ffffffffc0201130:	5e7000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    free_page(p1);
ffffffffc0201134:	4585                	li	a1,1
ffffffffc0201136:	854e                	mv	a0,s3
ffffffffc0201138:	5df000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    free_page(p2);
ffffffffc020113c:	4585                	li	a1,1
ffffffffc020113e:	8552                	mv	a0,s4
ffffffffc0201140:	5d7000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    assert(nr_free == 3);
ffffffffc0201144:	4818                	lw	a4,16(s0)
ffffffffc0201146:	478d                	li	a5,3
ffffffffc0201148:	28f71863          	bne	a4,a5,ffffffffc02013d8 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020114c:	4505                	li	a0,1
ffffffffc020114e:	58b000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc0201152:	89aa                	mv	s3,a0
ffffffffc0201154:	26050263          	beqz	a0,ffffffffc02013b8 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201158:	4505                	li	a0,1
ffffffffc020115a:	57f000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc020115e:	8aaa                	mv	s5,a0
ffffffffc0201160:	3a050c63          	beqz	a0,ffffffffc0201518 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201164:	4505                	li	a0,1
ffffffffc0201166:	573000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc020116a:	8a2a                	mv	s4,a0
ffffffffc020116c:	38050663          	beqz	a0,ffffffffc02014f8 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201170:	4505                	li	a0,1
ffffffffc0201172:	567000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc0201176:	36051163          	bnez	a0,ffffffffc02014d8 <default_check+0x4a2>
    free_page(p0);
ffffffffc020117a:	4585                	li	a1,1
ffffffffc020117c:	854e                	mv	a0,s3
ffffffffc020117e:	599000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201182:	641c                	ld	a5,8(s0)
ffffffffc0201184:	20878a63          	beq	a5,s0,ffffffffc0201398 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201188:	4505                	li	a0,1
ffffffffc020118a:	54f000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc020118e:	30a99563          	bne	s3,a0,ffffffffc0201498 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201192:	4505                	li	a0,1
ffffffffc0201194:	545000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc0201198:	2e051063          	bnez	a0,ffffffffc0201478 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc020119c:	481c                	lw	a5,16(s0)
ffffffffc020119e:	2a079d63          	bnez	a5,ffffffffc0201458 <default_check+0x422>
    free_page(p);
ffffffffc02011a2:	854e                	mv	a0,s3
ffffffffc02011a4:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02011a6:	01843023          	sd	s8,0(s0)
ffffffffc02011aa:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02011ae:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02011b2:	565000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    free_page(p1);
ffffffffc02011b6:	4585                	li	a1,1
ffffffffc02011b8:	8556                	mv	a0,s5
ffffffffc02011ba:	55d000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    free_page(p2);
ffffffffc02011be:	4585                	li	a1,1
ffffffffc02011c0:	8552                	mv	a0,s4
ffffffffc02011c2:	555000ef          	jal	ra,ffffffffc0201f16 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02011c6:	4515                	li	a0,5
ffffffffc02011c8:	511000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc02011cc:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02011ce:	26050563          	beqz	a0,ffffffffc0201438 <default_check+0x402>
ffffffffc02011d2:	651c                	ld	a5,8(a0)
ffffffffc02011d4:	8385                	srli	a5,a5,0x1
ffffffffc02011d6:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc02011d8:	54079063          	bnez	a5,ffffffffc0201718 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02011dc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02011de:	00043b03          	ld	s6,0(s0)
ffffffffc02011e2:	00843a83          	ld	s5,8(s0)
ffffffffc02011e6:	e000                	sd	s0,0(s0)
ffffffffc02011e8:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02011ea:	4ef000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc02011ee:	50051563          	bnez	a0,ffffffffc02016f8 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02011f2:	08098a13          	addi	s4,s3,128
ffffffffc02011f6:	8552                	mv	a0,s4
ffffffffc02011f8:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02011fa:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02011fe:	000a5797          	auipc	a5,0xa5
ffffffffc0201202:	4a07a923          	sw	zero,1202(a5) # ffffffffc02a66b0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201206:	511000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020120a:	4511                	li	a0,4
ffffffffc020120c:	4cd000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc0201210:	4c051463          	bnez	a0,ffffffffc02016d8 <default_check+0x6a2>
ffffffffc0201214:	0889b783          	ld	a5,136(s3)
ffffffffc0201218:	8385                	srli	a5,a5,0x1
ffffffffc020121a:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020121c:	48078e63          	beqz	a5,ffffffffc02016b8 <default_check+0x682>
ffffffffc0201220:	0909a703          	lw	a4,144(s3)
ffffffffc0201224:	478d                	li	a5,3
ffffffffc0201226:	48f71963          	bne	a4,a5,ffffffffc02016b8 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020122a:	450d                	li	a0,3
ffffffffc020122c:	4ad000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc0201230:	8c2a                	mv	s8,a0
ffffffffc0201232:	46050363          	beqz	a0,ffffffffc0201698 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0201236:	4505                	li	a0,1
ffffffffc0201238:	4a1000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc020123c:	42051e63          	bnez	a0,ffffffffc0201678 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201240:	418a1c63          	bne	s4,s8,ffffffffc0201658 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201244:	4585                	li	a1,1
ffffffffc0201246:	854e                	mv	a0,s3
ffffffffc0201248:	4cf000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    free_pages(p1, 3);
ffffffffc020124c:	458d                	li	a1,3
ffffffffc020124e:	8552                	mv	a0,s4
ffffffffc0201250:	4c7000ef          	jal	ra,ffffffffc0201f16 <free_pages>
ffffffffc0201254:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201258:	04098c13          	addi	s8,s3,64
ffffffffc020125c:	8385                	srli	a5,a5,0x1
ffffffffc020125e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201260:	3c078c63          	beqz	a5,ffffffffc0201638 <default_check+0x602>
ffffffffc0201264:	0109a703          	lw	a4,16(s3)
ffffffffc0201268:	4785                	li	a5,1
ffffffffc020126a:	3cf71763          	bne	a4,a5,ffffffffc0201638 <default_check+0x602>
ffffffffc020126e:	008a3783          	ld	a5,8(s4)
ffffffffc0201272:	8385                	srli	a5,a5,0x1
ffffffffc0201274:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201276:	3a078163          	beqz	a5,ffffffffc0201618 <default_check+0x5e2>
ffffffffc020127a:	010a2703          	lw	a4,16(s4)
ffffffffc020127e:	478d                	li	a5,3
ffffffffc0201280:	38f71c63          	bne	a4,a5,ffffffffc0201618 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201284:	4505                	li	a0,1
ffffffffc0201286:	453000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc020128a:	36a99763          	bne	s3,a0,ffffffffc02015f8 <default_check+0x5c2>
    free_page(p0);
ffffffffc020128e:	4585                	li	a1,1
ffffffffc0201290:	487000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201294:	4509                	li	a0,2
ffffffffc0201296:	443000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc020129a:	32aa1f63          	bne	s4,a0,ffffffffc02015d8 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020129e:	4589                	li	a1,2
ffffffffc02012a0:	477000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    free_page(p2);
ffffffffc02012a4:	4585                	li	a1,1
ffffffffc02012a6:	8562                	mv	a0,s8
ffffffffc02012a8:	46f000ef          	jal	ra,ffffffffc0201f16 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012ac:	4515                	li	a0,5
ffffffffc02012ae:	42b000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc02012b2:	89aa                	mv	s3,a0
ffffffffc02012b4:	48050263          	beqz	a0,ffffffffc0201738 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02012b8:	4505                	li	a0,1
ffffffffc02012ba:	41f000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc02012be:	2c051d63          	bnez	a0,ffffffffc0201598 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02012c2:	481c                	lw	a5,16(s0)
ffffffffc02012c4:	2a079a63          	bnez	a5,ffffffffc0201578 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02012c8:	4595                	li	a1,5
ffffffffc02012ca:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02012cc:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02012d0:	01643023          	sd	s6,0(s0)
ffffffffc02012d4:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02012d8:	43f000ef          	jal	ra,ffffffffc0201f16 <free_pages>
    return listelm->next;
ffffffffc02012dc:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02012de:	00878963          	beq	a5,s0,ffffffffc02012f0 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02012e2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012e6:	679c                	ld	a5,8(a5)
ffffffffc02012e8:	397d                	addiw	s2,s2,-1
ffffffffc02012ea:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012ec:	fe879be3          	bne	a5,s0,ffffffffc02012e2 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02012f0:	26091463          	bnez	s2,ffffffffc0201558 <default_check+0x522>
    assert(total == 0);
ffffffffc02012f4:	46049263          	bnez	s1,ffffffffc0201758 <default_check+0x722>
}
ffffffffc02012f8:	60a6                	ld	ra,72(sp)
ffffffffc02012fa:	6406                	ld	s0,64(sp)
ffffffffc02012fc:	74e2                	ld	s1,56(sp)
ffffffffc02012fe:	7942                	ld	s2,48(sp)
ffffffffc0201300:	79a2                	ld	s3,40(sp)
ffffffffc0201302:	7a02                	ld	s4,32(sp)
ffffffffc0201304:	6ae2                	ld	s5,24(sp)
ffffffffc0201306:	6b42                	ld	s6,16(sp)
ffffffffc0201308:	6ba2                	ld	s7,8(sp)
ffffffffc020130a:	6c02                	ld	s8,0(sp)
ffffffffc020130c:	6161                	addi	sp,sp,80
ffffffffc020130e:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201310:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201312:	4481                	li	s1,0
ffffffffc0201314:	4901                	li	s2,0
ffffffffc0201316:	b38d                	j	ffffffffc0201078 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201318:	00005697          	auipc	a3,0x5
ffffffffc020131c:	ff068693          	addi	a3,a3,-16 # ffffffffc0206308 <commands+0x818>
ffffffffc0201320:	00005617          	auipc	a2,0x5
ffffffffc0201324:	ff860613          	addi	a2,a2,-8 # ffffffffc0206318 <commands+0x828>
ffffffffc0201328:	11000593          	li	a1,272
ffffffffc020132c:	00005517          	auipc	a0,0x5
ffffffffc0201330:	00450513          	addi	a0,a0,4 # ffffffffc0206330 <commands+0x840>
ffffffffc0201334:	95aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201338:	00005697          	auipc	a3,0x5
ffffffffc020133c:	09068693          	addi	a3,a3,144 # ffffffffc02063c8 <commands+0x8d8>
ffffffffc0201340:	00005617          	auipc	a2,0x5
ffffffffc0201344:	fd860613          	addi	a2,a2,-40 # ffffffffc0206318 <commands+0x828>
ffffffffc0201348:	0db00593          	li	a1,219
ffffffffc020134c:	00005517          	auipc	a0,0x5
ffffffffc0201350:	fe450513          	addi	a0,a0,-28 # ffffffffc0206330 <commands+0x840>
ffffffffc0201354:	93aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201358:	00005697          	auipc	a3,0x5
ffffffffc020135c:	09868693          	addi	a3,a3,152 # ffffffffc02063f0 <commands+0x900>
ffffffffc0201360:	00005617          	auipc	a2,0x5
ffffffffc0201364:	fb860613          	addi	a2,a2,-72 # ffffffffc0206318 <commands+0x828>
ffffffffc0201368:	0dc00593          	li	a1,220
ffffffffc020136c:	00005517          	auipc	a0,0x5
ffffffffc0201370:	fc450513          	addi	a0,a0,-60 # ffffffffc0206330 <commands+0x840>
ffffffffc0201374:	91aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201378:	00005697          	auipc	a3,0x5
ffffffffc020137c:	0b868693          	addi	a3,a3,184 # ffffffffc0206430 <commands+0x940>
ffffffffc0201380:	00005617          	auipc	a2,0x5
ffffffffc0201384:	f9860613          	addi	a2,a2,-104 # ffffffffc0206318 <commands+0x828>
ffffffffc0201388:	0de00593          	li	a1,222
ffffffffc020138c:	00005517          	auipc	a0,0x5
ffffffffc0201390:	fa450513          	addi	a0,a0,-92 # ffffffffc0206330 <commands+0x840>
ffffffffc0201394:	8faff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201398:	00005697          	auipc	a3,0x5
ffffffffc020139c:	12068693          	addi	a3,a3,288 # ffffffffc02064b8 <commands+0x9c8>
ffffffffc02013a0:	00005617          	auipc	a2,0x5
ffffffffc02013a4:	f7860613          	addi	a2,a2,-136 # ffffffffc0206318 <commands+0x828>
ffffffffc02013a8:	0f700593          	li	a1,247
ffffffffc02013ac:	00005517          	auipc	a0,0x5
ffffffffc02013b0:	f8450513          	addi	a0,a0,-124 # ffffffffc0206330 <commands+0x840>
ffffffffc02013b4:	8daff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013b8:	00005697          	auipc	a3,0x5
ffffffffc02013bc:	fb068693          	addi	a3,a3,-80 # ffffffffc0206368 <commands+0x878>
ffffffffc02013c0:	00005617          	auipc	a2,0x5
ffffffffc02013c4:	f5860613          	addi	a2,a2,-168 # ffffffffc0206318 <commands+0x828>
ffffffffc02013c8:	0f000593          	li	a1,240
ffffffffc02013cc:	00005517          	auipc	a0,0x5
ffffffffc02013d0:	f6450513          	addi	a0,a0,-156 # ffffffffc0206330 <commands+0x840>
ffffffffc02013d4:	8baff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc02013d8:	00005697          	auipc	a3,0x5
ffffffffc02013dc:	0d068693          	addi	a3,a3,208 # ffffffffc02064a8 <commands+0x9b8>
ffffffffc02013e0:	00005617          	auipc	a2,0x5
ffffffffc02013e4:	f3860613          	addi	a2,a2,-200 # ffffffffc0206318 <commands+0x828>
ffffffffc02013e8:	0ee00593          	li	a1,238
ffffffffc02013ec:	00005517          	auipc	a0,0x5
ffffffffc02013f0:	f4450513          	addi	a0,a0,-188 # ffffffffc0206330 <commands+0x840>
ffffffffc02013f4:	89aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013f8:	00005697          	auipc	a3,0x5
ffffffffc02013fc:	09868693          	addi	a3,a3,152 # ffffffffc0206490 <commands+0x9a0>
ffffffffc0201400:	00005617          	auipc	a2,0x5
ffffffffc0201404:	f1860613          	addi	a2,a2,-232 # ffffffffc0206318 <commands+0x828>
ffffffffc0201408:	0e900593          	li	a1,233
ffffffffc020140c:	00005517          	auipc	a0,0x5
ffffffffc0201410:	f2450513          	addi	a0,a0,-220 # ffffffffc0206330 <commands+0x840>
ffffffffc0201414:	87aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201418:	00005697          	auipc	a3,0x5
ffffffffc020141c:	05868693          	addi	a3,a3,88 # ffffffffc0206470 <commands+0x980>
ffffffffc0201420:	00005617          	auipc	a2,0x5
ffffffffc0201424:	ef860613          	addi	a2,a2,-264 # ffffffffc0206318 <commands+0x828>
ffffffffc0201428:	0e000593          	li	a1,224
ffffffffc020142c:	00005517          	auipc	a0,0x5
ffffffffc0201430:	f0450513          	addi	a0,a0,-252 # ffffffffc0206330 <commands+0x840>
ffffffffc0201434:	85aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc0201438:	00005697          	auipc	a3,0x5
ffffffffc020143c:	0c868693          	addi	a3,a3,200 # ffffffffc0206500 <commands+0xa10>
ffffffffc0201440:	00005617          	auipc	a2,0x5
ffffffffc0201444:	ed860613          	addi	a2,a2,-296 # ffffffffc0206318 <commands+0x828>
ffffffffc0201448:	11800593          	li	a1,280
ffffffffc020144c:	00005517          	auipc	a0,0x5
ffffffffc0201450:	ee450513          	addi	a0,a0,-284 # ffffffffc0206330 <commands+0x840>
ffffffffc0201454:	83aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201458:	00005697          	auipc	a3,0x5
ffffffffc020145c:	09868693          	addi	a3,a3,152 # ffffffffc02064f0 <commands+0xa00>
ffffffffc0201460:	00005617          	auipc	a2,0x5
ffffffffc0201464:	eb860613          	addi	a2,a2,-328 # ffffffffc0206318 <commands+0x828>
ffffffffc0201468:	0fd00593          	li	a1,253
ffffffffc020146c:	00005517          	auipc	a0,0x5
ffffffffc0201470:	ec450513          	addi	a0,a0,-316 # ffffffffc0206330 <commands+0x840>
ffffffffc0201474:	81aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201478:	00005697          	auipc	a3,0x5
ffffffffc020147c:	01868693          	addi	a3,a3,24 # ffffffffc0206490 <commands+0x9a0>
ffffffffc0201480:	00005617          	auipc	a2,0x5
ffffffffc0201484:	e9860613          	addi	a2,a2,-360 # ffffffffc0206318 <commands+0x828>
ffffffffc0201488:	0fb00593          	li	a1,251
ffffffffc020148c:	00005517          	auipc	a0,0x5
ffffffffc0201490:	ea450513          	addi	a0,a0,-348 # ffffffffc0206330 <commands+0x840>
ffffffffc0201494:	ffbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201498:	00005697          	auipc	a3,0x5
ffffffffc020149c:	03868693          	addi	a3,a3,56 # ffffffffc02064d0 <commands+0x9e0>
ffffffffc02014a0:	00005617          	auipc	a2,0x5
ffffffffc02014a4:	e7860613          	addi	a2,a2,-392 # ffffffffc0206318 <commands+0x828>
ffffffffc02014a8:	0fa00593          	li	a1,250
ffffffffc02014ac:	00005517          	auipc	a0,0x5
ffffffffc02014b0:	e8450513          	addi	a0,a0,-380 # ffffffffc0206330 <commands+0x840>
ffffffffc02014b4:	fdbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02014b8:	00005697          	auipc	a3,0x5
ffffffffc02014bc:	eb068693          	addi	a3,a3,-336 # ffffffffc0206368 <commands+0x878>
ffffffffc02014c0:	00005617          	auipc	a2,0x5
ffffffffc02014c4:	e5860613          	addi	a2,a2,-424 # ffffffffc0206318 <commands+0x828>
ffffffffc02014c8:	0d700593          	li	a1,215
ffffffffc02014cc:	00005517          	auipc	a0,0x5
ffffffffc02014d0:	e6450513          	addi	a0,a0,-412 # ffffffffc0206330 <commands+0x840>
ffffffffc02014d4:	fbbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014d8:	00005697          	auipc	a3,0x5
ffffffffc02014dc:	fb868693          	addi	a3,a3,-72 # ffffffffc0206490 <commands+0x9a0>
ffffffffc02014e0:	00005617          	auipc	a2,0x5
ffffffffc02014e4:	e3860613          	addi	a2,a2,-456 # ffffffffc0206318 <commands+0x828>
ffffffffc02014e8:	0f400593          	li	a1,244
ffffffffc02014ec:	00005517          	auipc	a0,0x5
ffffffffc02014f0:	e4450513          	addi	a0,a0,-444 # ffffffffc0206330 <commands+0x840>
ffffffffc02014f4:	f9bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014f8:	00005697          	auipc	a3,0x5
ffffffffc02014fc:	eb068693          	addi	a3,a3,-336 # ffffffffc02063a8 <commands+0x8b8>
ffffffffc0201500:	00005617          	auipc	a2,0x5
ffffffffc0201504:	e1860613          	addi	a2,a2,-488 # ffffffffc0206318 <commands+0x828>
ffffffffc0201508:	0f200593          	li	a1,242
ffffffffc020150c:	00005517          	auipc	a0,0x5
ffffffffc0201510:	e2450513          	addi	a0,a0,-476 # ffffffffc0206330 <commands+0x840>
ffffffffc0201514:	f7bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201518:	00005697          	auipc	a3,0x5
ffffffffc020151c:	e7068693          	addi	a3,a3,-400 # ffffffffc0206388 <commands+0x898>
ffffffffc0201520:	00005617          	auipc	a2,0x5
ffffffffc0201524:	df860613          	addi	a2,a2,-520 # ffffffffc0206318 <commands+0x828>
ffffffffc0201528:	0f100593          	li	a1,241
ffffffffc020152c:	00005517          	auipc	a0,0x5
ffffffffc0201530:	e0450513          	addi	a0,a0,-508 # ffffffffc0206330 <commands+0x840>
ffffffffc0201534:	f5bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201538:	00005697          	auipc	a3,0x5
ffffffffc020153c:	e7068693          	addi	a3,a3,-400 # ffffffffc02063a8 <commands+0x8b8>
ffffffffc0201540:	00005617          	auipc	a2,0x5
ffffffffc0201544:	dd860613          	addi	a2,a2,-552 # ffffffffc0206318 <commands+0x828>
ffffffffc0201548:	0d900593          	li	a1,217
ffffffffc020154c:	00005517          	auipc	a0,0x5
ffffffffc0201550:	de450513          	addi	a0,a0,-540 # ffffffffc0206330 <commands+0x840>
ffffffffc0201554:	f3bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc0201558:	00005697          	auipc	a3,0x5
ffffffffc020155c:	0f868693          	addi	a3,a3,248 # ffffffffc0206650 <commands+0xb60>
ffffffffc0201560:	00005617          	auipc	a2,0x5
ffffffffc0201564:	db860613          	addi	a2,a2,-584 # ffffffffc0206318 <commands+0x828>
ffffffffc0201568:	14600593          	li	a1,326
ffffffffc020156c:	00005517          	auipc	a0,0x5
ffffffffc0201570:	dc450513          	addi	a0,a0,-572 # ffffffffc0206330 <commands+0x840>
ffffffffc0201574:	f1bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201578:	00005697          	auipc	a3,0x5
ffffffffc020157c:	f7868693          	addi	a3,a3,-136 # ffffffffc02064f0 <commands+0xa00>
ffffffffc0201580:	00005617          	auipc	a2,0x5
ffffffffc0201584:	d9860613          	addi	a2,a2,-616 # ffffffffc0206318 <commands+0x828>
ffffffffc0201588:	13a00593          	li	a1,314
ffffffffc020158c:	00005517          	auipc	a0,0x5
ffffffffc0201590:	da450513          	addi	a0,a0,-604 # ffffffffc0206330 <commands+0x840>
ffffffffc0201594:	efbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201598:	00005697          	auipc	a3,0x5
ffffffffc020159c:	ef868693          	addi	a3,a3,-264 # ffffffffc0206490 <commands+0x9a0>
ffffffffc02015a0:	00005617          	auipc	a2,0x5
ffffffffc02015a4:	d7860613          	addi	a2,a2,-648 # ffffffffc0206318 <commands+0x828>
ffffffffc02015a8:	13800593          	li	a1,312
ffffffffc02015ac:	00005517          	auipc	a0,0x5
ffffffffc02015b0:	d8450513          	addi	a0,a0,-636 # ffffffffc0206330 <commands+0x840>
ffffffffc02015b4:	edbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02015b8:	00005697          	auipc	a3,0x5
ffffffffc02015bc:	e9868693          	addi	a3,a3,-360 # ffffffffc0206450 <commands+0x960>
ffffffffc02015c0:	00005617          	auipc	a2,0x5
ffffffffc02015c4:	d5860613          	addi	a2,a2,-680 # ffffffffc0206318 <commands+0x828>
ffffffffc02015c8:	0df00593          	li	a1,223
ffffffffc02015cc:	00005517          	auipc	a0,0x5
ffffffffc02015d0:	d6450513          	addi	a0,a0,-668 # ffffffffc0206330 <commands+0x840>
ffffffffc02015d4:	ebbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02015d8:	00005697          	auipc	a3,0x5
ffffffffc02015dc:	03868693          	addi	a3,a3,56 # ffffffffc0206610 <commands+0xb20>
ffffffffc02015e0:	00005617          	auipc	a2,0x5
ffffffffc02015e4:	d3860613          	addi	a2,a2,-712 # ffffffffc0206318 <commands+0x828>
ffffffffc02015e8:	13200593          	li	a1,306
ffffffffc02015ec:	00005517          	auipc	a0,0x5
ffffffffc02015f0:	d4450513          	addi	a0,a0,-700 # ffffffffc0206330 <commands+0x840>
ffffffffc02015f4:	e9bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02015f8:	00005697          	auipc	a3,0x5
ffffffffc02015fc:	ff868693          	addi	a3,a3,-8 # ffffffffc02065f0 <commands+0xb00>
ffffffffc0201600:	00005617          	auipc	a2,0x5
ffffffffc0201604:	d1860613          	addi	a2,a2,-744 # ffffffffc0206318 <commands+0x828>
ffffffffc0201608:	13000593          	li	a1,304
ffffffffc020160c:	00005517          	auipc	a0,0x5
ffffffffc0201610:	d2450513          	addi	a0,a0,-732 # ffffffffc0206330 <commands+0x840>
ffffffffc0201614:	e7bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201618:	00005697          	auipc	a3,0x5
ffffffffc020161c:	fb068693          	addi	a3,a3,-80 # ffffffffc02065c8 <commands+0xad8>
ffffffffc0201620:	00005617          	auipc	a2,0x5
ffffffffc0201624:	cf860613          	addi	a2,a2,-776 # ffffffffc0206318 <commands+0x828>
ffffffffc0201628:	12e00593          	li	a1,302
ffffffffc020162c:	00005517          	auipc	a0,0x5
ffffffffc0201630:	d0450513          	addi	a0,a0,-764 # ffffffffc0206330 <commands+0x840>
ffffffffc0201634:	e5bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201638:	00005697          	auipc	a3,0x5
ffffffffc020163c:	f6868693          	addi	a3,a3,-152 # ffffffffc02065a0 <commands+0xab0>
ffffffffc0201640:	00005617          	auipc	a2,0x5
ffffffffc0201644:	cd860613          	addi	a2,a2,-808 # ffffffffc0206318 <commands+0x828>
ffffffffc0201648:	12d00593          	li	a1,301
ffffffffc020164c:	00005517          	auipc	a0,0x5
ffffffffc0201650:	ce450513          	addi	a0,a0,-796 # ffffffffc0206330 <commands+0x840>
ffffffffc0201654:	e3bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201658:	00005697          	auipc	a3,0x5
ffffffffc020165c:	f3868693          	addi	a3,a3,-200 # ffffffffc0206590 <commands+0xaa0>
ffffffffc0201660:	00005617          	auipc	a2,0x5
ffffffffc0201664:	cb860613          	addi	a2,a2,-840 # ffffffffc0206318 <commands+0x828>
ffffffffc0201668:	12800593          	li	a1,296
ffffffffc020166c:	00005517          	auipc	a0,0x5
ffffffffc0201670:	cc450513          	addi	a0,a0,-828 # ffffffffc0206330 <commands+0x840>
ffffffffc0201674:	e1bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201678:	00005697          	auipc	a3,0x5
ffffffffc020167c:	e1868693          	addi	a3,a3,-488 # ffffffffc0206490 <commands+0x9a0>
ffffffffc0201680:	00005617          	auipc	a2,0x5
ffffffffc0201684:	c9860613          	addi	a2,a2,-872 # ffffffffc0206318 <commands+0x828>
ffffffffc0201688:	12700593          	li	a1,295
ffffffffc020168c:	00005517          	auipc	a0,0x5
ffffffffc0201690:	ca450513          	addi	a0,a0,-860 # ffffffffc0206330 <commands+0x840>
ffffffffc0201694:	dfbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201698:	00005697          	auipc	a3,0x5
ffffffffc020169c:	ed868693          	addi	a3,a3,-296 # ffffffffc0206570 <commands+0xa80>
ffffffffc02016a0:	00005617          	auipc	a2,0x5
ffffffffc02016a4:	c7860613          	addi	a2,a2,-904 # ffffffffc0206318 <commands+0x828>
ffffffffc02016a8:	12600593          	li	a1,294
ffffffffc02016ac:	00005517          	auipc	a0,0x5
ffffffffc02016b0:	c8450513          	addi	a0,a0,-892 # ffffffffc0206330 <commands+0x840>
ffffffffc02016b4:	ddbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02016b8:	00005697          	auipc	a3,0x5
ffffffffc02016bc:	e8868693          	addi	a3,a3,-376 # ffffffffc0206540 <commands+0xa50>
ffffffffc02016c0:	00005617          	auipc	a2,0x5
ffffffffc02016c4:	c5860613          	addi	a2,a2,-936 # ffffffffc0206318 <commands+0x828>
ffffffffc02016c8:	12500593          	li	a1,293
ffffffffc02016cc:	00005517          	auipc	a0,0x5
ffffffffc02016d0:	c6450513          	addi	a0,a0,-924 # ffffffffc0206330 <commands+0x840>
ffffffffc02016d4:	dbbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02016d8:	00005697          	auipc	a3,0x5
ffffffffc02016dc:	e5068693          	addi	a3,a3,-432 # ffffffffc0206528 <commands+0xa38>
ffffffffc02016e0:	00005617          	auipc	a2,0x5
ffffffffc02016e4:	c3860613          	addi	a2,a2,-968 # ffffffffc0206318 <commands+0x828>
ffffffffc02016e8:	12400593          	li	a1,292
ffffffffc02016ec:	00005517          	auipc	a0,0x5
ffffffffc02016f0:	c4450513          	addi	a0,a0,-956 # ffffffffc0206330 <commands+0x840>
ffffffffc02016f4:	d9bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016f8:	00005697          	auipc	a3,0x5
ffffffffc02016fc:	d9868693          	addi	a3,a3,-616 # ffffffffc0206490 <commands+0x9a0>
ffffffffc0201700:	00005617          	auipc	a2,0x5
ffffffffc0201704:	c1860613          	addi	a2,a2,-1000 # ffffffffc0206318 <commands+0x828>
ffffffffc0201708:	11e00593          	li	a1,286
ffffffffc020170c:	00005517          	auipc	a0,0x5
ffffffffc0201710:	c2450513          	addi	a0,a0,-988 # ffffffffc0206330 <commands+0x840>
ffffffffc0201714:	d7bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc0201718:	00005697          	auipc	a3,0x5
ffffffffc020171c:	df868693          	addi	a3,a3,-520 # ffffffffc0206510 <commands+0xa20>
ffffffffc0201720:	00005617          	auipc	a2,0x5
ffffffffc0201724:	bf860613          	addi	a2,a2,-1032 # ffffffffc0206318 <commands+0x828>
ffffffffc0201728:	11900593          	li	a1,281
ffffffffc020172c:	00005517          	auipc	a0,0x5
ffffffffc0201730:	c0450513          	addi	a0,a0,-1020 # ffffffffc0206330 <commands+0x840>
ffffffffc0201734:	d5bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201738:	00005697          	auipc	a3,0x5
ffffffffc020173c:	ef868693          	addi	a3,a3,-264 # ffffffffc0206630 <commands+0xb40>
ffffffffc0201740:	00005617          	auipc	a2,0x5
ffffffffc0201744:	bd860613          	addi	a2,a2,-1064 # ffffffffc0206318 <commands+0x828>
ffffffffc0201748:	13700593          	li	a1,311
ffffffffc020174c:	00005517          	auipc	a0,0x5
ffffffffc0201750:	be450513          	addi	a0,a0,-1052 # ffffffffc0206330 <commands+0x840>
ffffffffc0201754:	d3bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc0201758:	00005697          	auipc	a3,0x5
ffffffffc020175c:	f0868693          	addi	a3,a3,-248 # ffffffffc0206660 <commands+0xb70>
ffffffffc0201760:	00005617          	auipc	a2,0x5
ffffffffc0201764:	bb860613          	addi	a2,a2,-1096 # ffffffffc0206318 <commands+0x828>
ffffffffc0201768:	14700593          	li	a1,327
ffffffffc020176c:	00005517          	auipc	a0,0x5
ffffffffc0201770:	bc450513          	addi	a0,a0,-1084 # ffffffffc0206330 <commands+0x840>
ffffffffc0201774:	d1bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc0201778:	00005697          	auipc	a3,0x5
ffffffffc020177c:	bd068693          	addi	a3,a3,-1072 # ffffffffc0206348 <commands+0x858>
ffffffffc0201780:	00005617          	auipc	a2,0x5
ffffffffc0201784:	b9860613          	addi	a2,a2,-1128 # ffffffffc0206318 <commands+0x828>
ffffffffc0201788:	11300593          	li	a1,275
ffffffffc020178c:	00005517          	auipc	a0,0x5
ffffffffc0201790:	ba450513          	addi	a0,a0,-1116 # ffffffffc0206330 <commands+0x840>
ffffffffc0201794:	cfbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201798:	00005697          	auipc	a3,0x5
ffffffffc020179c:	bf068693          	addi	a3,a3,-1040 # ffffffffc0206388 <commands+0x898>
ffffffffc02017a0:	00005617          	auipc	a2,0x5
ffffffffc02017a4:	b7860613          	addi	a2,a2,-1160 # ffffffffc0206318 <commands+0x828>
ffffffffc02017a8:	0d800593          	li	a1,216
ffffffffc02017ac:	00005517          	auipc	a0,0x5
ffffffffc02017b0:	b8450513          	addi	a0,a0,-1148 # ffffffffc0206330 <commands+0x840>
ffffffffc02017b4:	cdbfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02017b8 <default_free_pages>:
{
ffffffffc02017b8:	1141                	addi	sp,sp,-16
ffffffffc02017ba:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017bc:	14058463          	beqz	a1,ffffffffc0201904 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc02017c0:	00659693          	slli	a3,a1,0x6
ffffffffc02017c4:	96aa                	add	a3,a3,a0
ffffffffc02017c6:	87aa                	mv	a5,a0
ffffffffc02017c8:	02d50263          	beq	a0,a3,ffffffffc02017ec <default_free_pages+0x34>
ffffffffc02017cc:	6798                	ld	a4,8(a5)
ffffffffc02017ce:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017d0:	10071a63          	bnez	a4,ffffffffc02018e4 <default_free_pages+0x12c>
ffffffffc02017d4:	6798                	ld	a4,8(a5)
ffffffffc02017d6:	8b09                	andi	a4,a4,2
ffffffffc02017d8:	10071663          	bnez	a4,ffffffffc02018e4 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02017dc:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02017e0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02017e4:	04078793          	addi	a5,a5,64
ffffffffc02017e8:	fed792e3          	bne	a5,a3,ffffffffc02017cc <default_free_pages+0x14>
    base->property = n;
ffffffffc02017ec:	2581                	sext.w	a1,a1
ffffffffc02017ee:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02017f0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017f4:	4789                	li	a5,2
ffffffffc02017f6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02017fa:	000a5697          	auipc	a3,0xa5
ffffffffc02017fe:	ea668693          	addi	a3,a3,-346 # ffffffffc02a66a0 <free_area>
ffffffffc0201802:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201804:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201806:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020180a:	9db9                	addw	a1,a1,a4
ffffffffc020180c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc020180e:	0ad78463          	beq	a5,a3,ffffffffc02018b6 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201812:	fe878713          	addi	a4,a5,-24
ffffffffc0201816:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020181a:	4581                	li	a1,0
            if (base < page)
ffffffffc020181c:	00e56a63          	bltu	a0,a4,ffffffffc0201830 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201820:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201822:	04d70c63          	beq	a4,a3,ffffffffc020187a <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc0201826:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201828:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc020182c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201820 <default_free_pages+0x68>
ffffffffc0201830:	c199                	beqz	a1,ffffffffc0201836 <default_free_pages+0x7e>
ffffffffc0201832:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201836:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201838:	e390                	sd	a2,0(a5)
ffffffffc020183a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020183c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020183e:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201840:	00d70d63          	beq	a4,a3,ffffffffc020185a <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201844:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201848:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc020184c:	02059813          	slli	a6,a1,0x20
ffffffffc0201850:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201854:	97b2                	add	a5,a5,a2
ffffffffc0201856:	02f50c63          	beq	a0,a5,ffffffffc020188e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020185a:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc020185c:	00d78c63          	beq	a5,a3,ffffffffc0201874 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201860:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201862:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201866:	02061593          	slli	a1,a2,0x20
ffffffffc020186a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020186e:	972a                	add	a4,a4,a0
ffffffffc0201870:	04e68a63          	beq	a3,a4,ffffffffc02018c4 <default_free_pages+0x10c>
}
ffffffffc0201874:	60a2                	ld	ra,8(sp)
ffffffffc0201876:	0141                	addi	sp,sp,16
ffffffffc0201878:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020187a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020187c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020187e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201880:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201882:	02d70763          	beq	a4,a3,ffffffffc02018b0 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201886:	8832                	mv	a6,a2
ffffffffc0201888:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020188a:	87ba                	mv	a5,a4
ffffffffc020188c:	bf71                	j	ffffffffc0201828 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020188e:	491c                	lw	a5,16(a0)
ffffffffc0201890:	9dbd                	addw	a1,a1,a5
ffffffffc0201892:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201896:	57f5                	li	a5,-3
ffffffffc0201898:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020189c:	01853803          	ld	a6,24(a0)
ffffffffc02018a0:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02018a2:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02018a4:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc02018a8:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02018aa:	0105b023          	sd	a6,0(a1)
ffffffffc02018ae:	b77d                	j	ffffffffc020185c <default_free_pages+0xa4>
ffffffffc02018b0:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018b2:	873e                	mv	a4,a5
ffffffffc02018b4:	bf41                	j	ffffffffc0201844 <default_free_pages+0x8c>
}
ffffffffc02018b6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018b8:	e390                	sd	a2,0(a5)
ffffffffc02018ba:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018bc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018be:	ed1c                	sd	a5,24(a0)
ffffffffc02018c0:	0141                	addi	sp,sp,16
ffffffffc02018c2:	8082                	ret
            base->property += p->property;
ffffffffc02018c4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02018c8:	ff078693          	addi	a3,a5,-16
ffffffffc02018cc:	9e39                	addw	a2,a2,a4
ffffffffc02018ce:	c910                	sw	a2,16(a0)
ffffffffc02018d0:	5775                	li	a4,-3
ffffffffc02018d2:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018d6:	6398                	ld	a4,0(a5)
ffffffffc02018d8:	679c                	ld	a5,8(a5)
}
ffffffffc02018da:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02018dc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02018de:	e398                	sd	a4,0(a5)
ffffffffc02018e0:	0141                	addi	sp,sp,16
ffffffffc02018e2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02018e4:	00005697          	auipc	a3,0x5
ffffffffc02018e8:	d9468693          	addi	a3,a3,-620 # ffffffffc0206678 <commands+0xb88>
ffffffffc02018ec:	00005617          	auipc	a2,0x5
ffffffffc02018f0:	a2c60613          	addi	a2,a2,-1492 # ffffffffc0206318 <commands+0x828>
ffffffffc02018f4:	09400593          	li	a1,148
ffffffffc02018f8:	00005517          	auipc	a0,0x5
ffffffffc02018fc:	a3850513          	addi	a0,a0,-1480 # ffffffffc0206330 <commands+0x840>
ffffffffc0201900:	b8ffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201904:	00005697          	auipc	a3,0x5
ffffffffc0201908:	d6c68693          	addi	a3,a3,-660 # ffffffffc0206670 <commands+0xb80>
ffffffffc020190c:	00005617          	auipc	a2,0x5
ffffffffc0201910:	a0c60613          	addi	a2,a2,-1524 # ffffffffc0206318 <commands+0x828>
ffffffffc0201914:	09000593          	li	a1,144
ffffffffc0201918:	00005517          	auipc	a0,0x5
ffffffffc020191c:	a1850513          	addi	a0,a0,-1512 # ffffffffc0206330 <commands+0x840>
ffffffffc0201920:	b6ffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201924 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201924:	c941                	beqz	a0,ffffffffc02019b4 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201926:	000a5597          	auipc	a1,0xa5
ffffffffc020192a:	d7a58593          	addi	a1,a1,-646 # ffffffffc02a66a0 <free_area>
ffffffffc020192e:	0105a803          	lw	a6,16(a1)
ffffffffc0201932:	872a                	mv	a4,a0
ffffffffc0201934:	02081793          	slli	a5,a6,0x20
ffffffffc0201938:	9381                	srli	a5,a5,0x20
ffffffffc020193a:	00a7ee63          	bltu	a5,a0,ffffffffc0201956 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020193e:	87ae                	mv	a5,a1
ffffffffc0201940:	a801                	j	ffffffffc0201950 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201942:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201946:	02069613          	slli	a2,a3,0x20
ffffffffc020194a:	9201                	srli	a2,a2,0x20
ffffffffc020194c:	00e67763          	bgeu	a2,a4,ffffffffc020195a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201950:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201952:	feb798e3          	bne	a5,a1,ffffffffc0201942 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201956:	4501                	li	a0,0
}
ffffffffc0201958:	8082                	ret
    return listelm->prev;
ffffffffc020195a:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020195e:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201962:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201966:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020196a:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020196e:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201972:	02c77863          	bgeu	a4,a2,ffffffffc02019a2 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201976:	071a                	slli	a4,a4,0x6
ffffffffc0201978:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020197a:	41c686bb          	subw	a3,a3,t3
ffffffffc020197e:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201980:	00870613          	addi	a2,a4,8
ffffffffc0201984:	4689                	li	a3,2
ffffffffc0201986:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020198a:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020198e:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201992:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201996:	e290                	sd	a2,0(a3)
ffffffffc0201998:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020199c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020199e:	01173c23          	sd	a7,24(a4)
ffffffffc02019a2:	41c8083b          	subw	a6,a6,t3
ffffffffc02019a6:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02019aa:	5775                	li	a4,-3
ffffffffc02019ac:	17c1                	addi	a5,a5,-16
ffffffffc02019ae:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02019b2:	8082                	ret
{
ffffffffc02019b4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02019b6:	00005697          	auipc	a3,0x5
ffffffffc02019ba:	cba68693          	addi	a3,a3,-838 # ffffffffc0206670 <commands+0xb80>
ffffffffc02019be:	00005617          	auipc	a2,0x5
ffffffffc02019c2:	95a60613          	addi	a2,a2,-1702 # ffffffffc0206318 <commands+0x828>
ffffffffc02019c6:	06c00593          	li	a1,108
ffffffffc02019ca:	00005517          	auipc	a0,0x5
ffffffffc02019ce:	96650513          	addi	a0,a0,-1690 # ffffffffc0206330 <commands+0x840>
{
ffffffffc02019d2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019d4:	abbfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02019d8 <default_init_memmap>:
{
ffffffffc02019d8:	1141                	addi	sp,sp,-16
ffffffffc02019da:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019dc:	c5f1                	beqz	a1,ffffffffc0201aa8 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc02019de:	00659693          	slli	a3,a1,0x6
ffffffffc02019e2:	96aa                	add	a3,a3,a0
ffffffffc02019e4:	87aa                	mv	a5,a0
ffffffffc02019e6:	00d50f63          	beq	a0,a3,ffffffffc0201a04 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02019ea:	6798                	ld	a4,8(a5)
ffffffffc02019ec:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02019ee:	cf49                	beqz	a4,ffffffffc0201a88 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02019f0:	0007a823          	sw	zero,16(a5)
ffffffffc02019f4:	0007b423          	sd	zero,8(a5)
ffffffffc02019f8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02019fc:	04078793          	addi	a5,a5,64
ffffffffc0201a00:	fed795e3          	bne	a5,a3,ffffffffc02019ea <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201a04:	2581                	sext.w	a1,a1
ffffffffc0201a06:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a08:	4789                	li	a5,2
ffffffffc0201a0a:	00850713          	addi	a4,a0,8
ffffffffc0201a0e:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201a12:	000a5697          	auipc	a3,0xa5
ffffffffc0201a16:	c8e68693          	addi	a3,a3,-882 # ffffffffc02a66a0 <free_area>
ffffffffc0201a1a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a1c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a1e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a22:	9db9                	addw	a1,a1,a4
ffffffffc0201a24:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a26:	04d78a63          	beq	a5,a3,ffffffffc0201a7a <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a2a:	fe878713          	addi	a4,a5,-24
ffffffffc0201a2e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201a32:	4581                	li	a1,0
            if (base < page)
ffffffffc0201a34:	00e56a63          	bltu	a0,a4,ffffffffc0201a48 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201a38:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a3a:	02d70263          	beq	a4,a3,ffffffffc0201a5e <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201a3e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a40:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a44:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a38 <default_init_memmap+0x60>
ffffffffc0201a48:	c199                	beqz	a1,ffffffffc0201a4e <default_init_memmap+0x76>
ffffffffc0201a4a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a4e:	6398                	ld	a4,0(a5)
}
ffffffffc0201a50:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a52:	e390                	sd	a2,0(a5)
ffffffffc0201a54:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201a56:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a58:	ed18                	sd	a4,24(a0)
ffffffffc0201a5a:	0141                	addi	sp,sp,16
ffffffffc0201a5c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a5e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a60:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a62:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a64:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a66:	00d70663          	beq	a4,a3,ffffffffc0201a72 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201a6a:	8832                	mv	a6,a2
ffffffffc0201a6c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201a6e:	87ba                	mv	a5,a4
ffffffffc0201a70:	bfc1                	j	ffffffffc0201a40 <default_init_memmap+0x68>
}
ffffffffc0201a72:	60a2                	ld	ra,8(sp)
ffffffffc0201a74:	e290                	sd	a2,0(a3)
ffffffffc0201a76:	0141                	addi	sp,sp,16
ffffffffc0201a78:	8082                	ret
ffffffffc0201a7a:	60a2                	ld	ra,8(sp)
ffffffffc0201a7c:	e390                	sd	a2,0(a5)
ffffffffc0201a7e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a80:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a82:	ed1c                	sd	a5,24(a0)
ffffffffc0201a84:	0141                	addi	sp,sp,16
ffffffffc0201a86:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a88:	00005697          	auipc	a3,0x5
ffffffffc0201a8c:	c1868693          	addi	a3,a3,-1000 # ffffffffc02066a0 <commands+0xbb0>
ffffffffc0201a90:	00005617          	auipc	a2,0x5
ffffffffc0201a94:	88860613          	addi	a2,a2,-1912 # ffffffffc0206318 <commands+0x828>
ffffffffc0201a98:	04b00593          	li	a1,75
ffffffffc0201a9c:	00005517          	auipc	a0,0x5
ffffffffc0201aa0:	89450513          	addi	a0,a0,-1900 # ffffffffc0206330 <commands+0x840>
ffffffffc0201aa4:	9ebfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201aa8:	00005697          	auipc	a3,0x5
ffffffffc0201aac:	bc868693          	addi	a3,a3,-1080 # ffffffffc0206670 <commands+0xb80>
ffffffffc0201ab0:	00005617          	auipc	a2,0x5
ffffffffc0201ab4:	86860613          	addi	a2,a2,-1944 # ffffffffc0206318 <commands+0x828>
ffffffffc0201ab8:	04700593          	li	a1,71
ffffffffc0201abc:	00005517          	auipc	a0,0x5
ffffffffc0201ac0:	87450513          	addi	a0,a0,-1932 # ffffffffc0206330 <commands+0x840>
ffffffffc0201ac4:	9cbfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ac8 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201ac8:	c94d                	beqz	a0,ffffffffc0201b7a <slob_free+0xb2>
{
ffffffffc0201aca:	1141                	addi	sp,sp,-16
ffffffffc0201acc:	e022                	sd	s0,0(sp)
ffffffffc0201ace:	e406                	sd	ra,8(sp)
ffffffffc0201ad0:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201ad2:	e9c1                	bnez	a1,ffffffffc0201b62 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ad4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ad8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ada:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201adc:	ebd9                	bnez	a5,ffffffffc0201b72 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ade:	000a4617          	auipc	a2,0xa4
ffffffffc0201ae2:	7b260613          	addi	a2,a2,1970 # ffffffffc02a6290 <slobfree>
ffffffffc0201ae6:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ae8:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201aea:	679c                	ld	a5,8(a5)
ffffffffc0201aec:	02877a63          	bgeu	a4,s0,ffffffffc0201b20 <slob_free+0x58>
ffffffffc0201af0:	00f46463          	bltu	s0,a5,ffffffffc0201af8 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201af4:	fef76ae3          	bltu	a4,a5,ffffffffc0201ae8 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201af8:	400c                	lw	a1,0(s0)
ffffffffc0201afa:	00459693          	slli	a3,a1,0x4
ffffffffc0201afe:	96a2                	add	a3,a3,s0
ffffffffc0201b00:	02d78a63          	beq	a5,a3,ffffffffc0201b34 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201b04:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201b06:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b08:	00469793          	slli	a5,a3,0x4
ffffffffc0201b0c:	97ba                	add	a5,a5,a4
ffffffffc0201b0e:	02f40e63          	beq	s0,a5,ffffffffc0201b4a <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201b12:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201b14:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201b16:	e129                	bnez	a0,ffffffffc0201b58 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b18:	60a2                	ld	ra,8(sp)
ffffffffc0201b1a:	6402                	ld	s0,0(sp)
ffffffffc0201b1c:	0141                	addi	sp,sp,16
ffffffffc0201b1e:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b20:	fcf764e3          	bltu	a4,a5,ffffffffc0201ae8 <slob_free+0x20>
ffffffffc0201b24:	fcf472e3          	bgeu	s0,a5,ffffffffc0201ae8 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201b28:	400c                	lw	a1,0(s0)
ffffffffc0201b2a:	00459693          	slli	a3,a1,0x4
ffffffffc0201b2e:	96a2                	add	a3,a3,s0
ffffffffc0201b30:	fcd79ae3          	bne	a5,a3,ffffffffc0201b04 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201b34:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b36:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b38:	9db5                	addw	a1,a1,a3
ffffffffc0201b3a:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201b3c:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201b3e:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b40:	00469793          	slli	a5,a3,0x4
ffffffffc0201b44:	97ba                	add	a5,a5,a4
ffffffffc0201b46:	fcf416e3          	bne	s0,a5,ffffffffc0201b12 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201b4a:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201b4c:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201b4e:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201b50:	9ebd                	addw	a3,a3,a5
ffffffffc0201b52:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201b54:	e70c                	sd	a1,8(a4)
ffffffffc0201b56:	d169                	beqz	a0,ffffffffc0201b18 <slob_free+0x50>
}
ffffffffc0201b58:	6402                	ld	s0,0(sp)
ffffffffc0201b5a:	60a2                	ld	ra,8(sp)
ffffffffc0201b5c:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201b5e:	e51fe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201b62:	25bd                	addiw	a1,a1,15
ffffffffc0201b64:	8191                	srli	a1,a1,0x4
ffffffffc0201b66:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b68:	100027f3          	csrr	a5,sstatus
ffffffffc0201b6c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b6e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b70:	d7bd                	beqz	a5,ffffffffc0201ade <slob_free+0x16>
        intr_disable();
ffffffffc0201b72:	e43fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201b76:	4505                	li	a0,1
ffffffffc0201b78:	b79d                	j	ffffffffc0201ade <slob_free+0x16>
ffffffffc0201b7a:	8082                	ret

ffffffffc0201b7c <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b7c:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b7e:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b80:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b84:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b86:	352000ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
	if (!page)
ffffffffc0201b8a:	c91d                	beqz	a0,ffffffffc0201bc0 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b8c:	000a9697          	auipc	a3,0xa9
ffffffffc0201b90:	b846b683          	ld	a3,-1148(a3) # ffffffffc02aa710 <pages>
ffffffffc0201b94:	8d15                	sub	a0,a0,a3
ffffffffc0201b96:	8519                	srai	a0,a0,0x6
ffffffffc0201b98:	00006697          	auipc	a3,0x6
ffffffffc0201b9c:	e386b683          	ld	a3,-456(a3) # ffffffffc02079d0 <nbase>
ffffffffc0201ba0:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201ba2:	00c51793          	slli	a5,a0,0xc
ffffffffc0201ba6:	83b1                	srli	a5,a5,0xc
ffffffffc0201ba8:	000a9717          	auipc	a4,0xa9
ffffffffc0201bac:	b6073703          	ld	a4,-1184(a4) # ffffffffc02aa708 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201bb0:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201bb2:	00e7fa63          	bgeu	a5,a4,ffffffffc0201bc6 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201bb6:	000a9697          	auipc	a3,0xa9
ffffffffc0201bba:	b6a6b683          	ld	a3,-1174(a3) # ffffffffc02aa720 <va_pa_offset>
ffffffffc0201bbe:	9536                	add	a0,a0,a3
}
ffffffffc0201bc0:	60a2                	ld	ra,8(sp)
ffffffffc0201bc2:	0141                	addi	sp,sp,16
ffffffffc0201bc4:	8082                	ret
ffffffffc0201bc6:	86aa                	mv	a3,a0
ffffffffc0201bc8:	00005617          	auipc	a2,0x5
ffffffffc0201bcc:	b3860613          	addi	a2,a2,-1224 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc0201bd0:	07200593          	li	a1,114
ffffffffc0201bd4:	00005517          	auipc	a0,0x5
ffffffffc0201bd8:	b5450513          	addi	a0,a0,-1196 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0201bdc:	8b3fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201be0 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201be0:	1101                	addi	sp,sp,-32
ffffffffc0201be2:	ec06                	sd	ra,24(sp)
ffffffffc0201be4:	e822                	sd	s0,16(sp)
ffffffffc0201be6:	e426                	sd	s1,8(sp)
ffffffffc0201be8:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bea:	01050713          	addi	a4,a0,16
ffffffffc0201bee:	6785                	lui	a5,0x1
ffffffffc0201bf0:	0cf77363          	bgeu	a4,a5,ffffffffc0201cb6 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201bf4:	00f50493          	addi	s1,a0,15
ffffffffc0201bf8:	8091                	srli	s1,s1,0x4
ffffffffc0201bfa:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bfc:	10002673          	csrr	a2,sstatus
ffffffffc0201c00:	8a09                	andi	a2,a2,2
ffffffffc0201c02:	e25d                	bnez	a2,ffffffffc0201ca8 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201c04:	000a4917          	auipc	s2,0xa4
ffffffffc0201c08:	68c90913          	addi	s2,s2,1676 # ffffffffc02a6290 <slobfree>
ffffffffc0201c0c:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c10:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201c12:	4398                	lw	a4,0(a5)
ffffffffc0201c14:	08975e63          	bge	a4,s1,ffffffffc0201cb0 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201c18:	00f68b63          	beq	a3,a5,ffffffffc0201c2e <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c1c:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c1e:	4018                	lw	a4,0(s0)
ffffffffc0201c20:	02975a63          	bge	a4,s1,ffffffffc0201c54 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201c24:	00093683          	ld	a3,0(s2)
ffffffffc0201c28:	87a2                	mv	a5,s0
ffffffffc0201c2a:	fef699e3          	bne	a3,a5,ffffffffc0201c1c <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201c2e:	ee31                	bnez	a2,ffffffffc0201c8a <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c30:	4501                	li	a0,0
ffffffffc0201c32:	f4bff0ef          	jal	ra,ffffffffc0201b7c <__slob_get_free_pages.constprop.0>
ffffffffc0201c36:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201c38:	cd05                	beqz	a0,ffffffffc0201c70 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c3a:	6585                	lui	a1,0x1
ffffffffc0201c3c:	e8dff0ef          	jal	ra,ffffffffc0201ac8 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c40:	10002673          	csrr	a2,sstatus
ffffffffc0201c44:	8a09                	andi	a2,a2,2
ffffffffc0201c46:	ee05                	bnez	a2,ffffffffc0201c7e <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201c48:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c4c:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c4e:	4018                	lw	a4,0(s0)
ffffffffc0201c50:	fc974ae3          	blt	a4,s1,ffffffffc0201c24 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c54:	04e48763          	beq	s1,a4,ffffffffc0201ca2 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201c58:	00449693          	slli	a3,s1,0x4
ffffffffc0201c5c:	96a2                	add	a3,a3,s0
ffffffffc0201c5e:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201c60:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201c62:	9f05                	subw	a4,a4,s1
ffffffffc0201c64:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201c66:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201c68:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201c6a:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201c6e:	e20d                	bnez	a2,ffffffffc0201c90 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201c70:	60e2                	ld	ra,24(sp)
ffffffffc0201c72:	8522                	mv	a0,s0
ffffffffc0201c74:	6442                	ld	s0,16(sp)
ffffffffc0201c76:	64a2                	ld	s1,8(sp)
ffffffffc0201c78:	6902                	ld	s2,0(sp)
ffffffffc0201c7a:	6105                	addi	sp,sp,32
ffffffffc0201c7c:	8082                	ret
        intr_disable();
ffffffffc0201c7e:	d37fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201c82:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201c86:	4605                	li	a2,1
ffffffffc0201c88:	b7d1                	j	ffffffffc0201c4c <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201c8a:	d25fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201c8e:	b74d                	j	ffffffffc0201c30 <slob_alloc.constprop.0+0x50>
ffffffffc0201c90:	d1ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201c94:	60e2                	ld	ra,24(sp)
ffffffffc0201c96:	8522                	mv	a0,s0
ffffffffc0201c98:	6442                	ld	s0,16(sp)
ffffffffc0201c9a:	64a2                	ld	s1,8(sp)
ffffffffc0201c9c:	6902                	ld	s2,0(sp)
ffffffffc0201c9e:	6105                	addi	sp,sp,32
ffffffffc0201ca0:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201ca2:	6418                	ld	a4,8(s0)
ffffffffc0201ca4:	e798                	sd	a4,8(a5)
ffffffffc0201ca6:	b7d1                	j	ffffffffc0201c6a <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201ca8:	d0dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201cac:	4605                	li	a2,1
ffffffffc0201cae:	bf99                	j	ffffffffc0201c04 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201cb0:	843e                	mv	s0,a5
ffffffffc0201cb2:	87b6                	mv	a5,a3
ffffffffc0201cb4:	b745                	j	ffffffffc0201c54 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201cb6:	00005697          	auipc	a3,0x5
ffffffffc0201cba:	a8268693          	addi	a3,a3,-1406 # ffffffffc0206738 <default_pmm_manager+0x70>
ffffffffc0201cbe:	00004617          	auipc	a2,0x4
ffffffffc0201cc2:	65a60613          	addi	a2,a2,1626 # ffffffffc0206318 <commands+0x828>
ffffffffc0201cc6:	06300593          	li	a1,99
ffffffffc0201cca:	00005517          	auipc	a0,0x5
ffffffffc0201cce:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0206758 <default_pmm_manager+0x90>
ffffffffc0201cd2:	fbcfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201cd6 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201cd6:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201cd8:	00005517          	auipc	a0,0x5
ffffffffc0201cdc:	a9850513          	addi	a0,a0,-1384 # ffffffffc0206770 <default_pmm_manager+0xa8>
{
ffffffffc0201ce0:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201ce2:	cb2fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201ce6:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ce8:	00005517          	auipc	a0,0x5
ffffffffc0201cec:	aa050513          	addi	a0,a0,-1376 # ffffffffc0206788 <default_pmm_manager+0xc0>
}
ffffffffc0201cf0:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cf2:	ca2fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201cf6 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201cf6:	4501                	li	a0,0
ffffffffc0201cf8:	8082                	ret

ffffffffc0201cfa <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cfa:	1101                	addi	sp,sp,-32
ffffffffc0201cfc:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cfe:	6905                	lui	s2,0x1
{
ffffffffc0201d00:	e822                	sd	s0,16(sp)
ffffffffc0201d02:	ec06                	sd	ra,24(sp)
ffffffffc0201d04:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d06:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bb9>
{
ffffffffc0201d0a:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d0c:	04a7f963          	bgeu	a5,a0,ffffffffc0201d5e <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d10:	4561                	li	a0,24
ffffffffc0201d12:	ecfff0ef          	jal	ra,ffffffffc0201be0 <slob_alloc.constprop.0>
ffffffffc0201d16:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201d18:	c929                	beqz	a0,ffffffffc0201d6a <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201d1a:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201d1e:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d20:	00f95763          	bge	s2,a5,ffffffffc0201d2e <kmalloc+0x34>
ffffffffc0201d24:	6705                	lui	a4,0x1
ffffffffc0201d26:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201d28:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d2a:	fef74ee3          	blt	a4,a5,ffffffffc0201d26 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201d2e:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d30:	e4dff0ef          	jal	ra,ffffffffc0201b7c <__slob_get_free_pages.constprop.0>
ffffffffc0201d34:	e488                	sd	a0,8(s1)
ffffffffc0201d36:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201d38:	c525                	beqz	a0,ffffffffc0201da0 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d3a:	100027f3          	csrr	a5,sstatus
ffffffffc0201d3e:	8b89                	andi	a5,a5,2
ffffffffc0201d40:	ef8d                	bnez	a5,ffffffffc0201d7a <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201d42:	000a9797          	auipc	a5,0xa9
ffffffffc0201d46:	9ae78793          	addi	a5,a5,-1618 # ffffffffc02aa6f0 <bigblocks>
ffffffffc0201d4a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d4c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d4e:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201d50:	60e2                	ld	ra,24(sp)
ffffffffc0201d52:	8522                	mv	a0,s0
ffffffffc0201d54:	6442                	ld	s0,16(sp)
ffffffffc0201d56:	64a2                	ld	s1,8(sp)
ffffffffc0201d58:	6902                	ld	s2,0(sp)
ffffffffc0201d5a:	6105                	addi	sp,sp,32
ffffffffc0201d5c:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d5e:	0541                	addi	a0,a0,16
ffffffffc0201d60:	e81ff0ef          	jal	ra,ffffffffc0201be0 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d64:	01050413          	addi	s0,a0,16
ffffffffc0201d68:	f565                	bnez	a0,ffffffffc0201d50 <kmalloc+0x56>
ffffffffc0201d6a:	4401                	li	s0,0
}
ffffffffc0201d6c:	60e2                	ld	ra,24(sp)
ffffffffc0201d6e:	8522                	mv	a0,s0
ffffffffc0201d70:	6442                	ld	s0,16(sp)
ffffffffc0201d72:	64a2                	ld	s1,8(sp)
ffffffffc0201d74:	6902                	ld	s2,0(sp)
ffffffffc0201d76:	6105                	addi	sp,sp,32
ffffffffc0201d78:	8082                	ret
        intr_disable();
ffffffffc0201d7a:	c3bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d7e:	000a9797          	auipc	a5,0xa9
ffffffffc0201d82:	97278793          	addi	a5,a5,-1678 # ffffffffc02aa6f0 <bigblocks>
ffffffffc0201d86:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d88:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d8a:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201d8c:	c23fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201d90:	6480                	ld	s0,8(s1)
}
ffffffffc0201d92:	60e2                	ld	ra,24(sp)
ffffffffc0201d94:	64a2                	ld	s1,8(sp)
ffffffffc0201d96:	8522                	mv	a0,s0
ffffffffc0201d98:	6442                	ld	s0,16(sp)
ffffffffc0201d9a:	6902                	ld	s2,0(sp)
ffffffffc0201d9c:	6105                	addi	sp,sp,32
ffffffffc0201d9e:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201da0:	45e1                	li	a1,24
ffffffffc0201da2:	8526                	mv	a0,s1
ffffffffc0201da4:	d25ff0ef          	jal	ra,ffffffffc0201ac8 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201da8:	b765                	j	ffffffffc0201d50 <kmalloc+0x56>

ffffffffc0201daa <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201daa:	c169                	beqz	a0,ffffffffc0201e6c <kfree+0xc2>
{
ffffffffc0201dac:	1101                	addi	sp,sp,-32
ffffffffc0201dae:	e822                	sd	s0,16(sp)
ffffffffc0201db0:	ec06                	sd	ra,24(sp)
ffffffffc0201db2:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201db4:	03451793          	slli	a5,a0,0x34
ffffffffc0201db8:	842a                	mv	s0,a0
ffffffffc0201dba:	e3d9                	bnez	a5,ffffffffc0201e40 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dbc:	100027f3          	csrr	a5,sstatus
ffffffffc0201dc0:	8b89                	andi	a5,a5,2
ffffffffc0201dc2:	e7d9                	bnez	a5,ffffffffc0201e50 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dc4:	000a9797          	auipc	a5,0xa9
ffffffffc0201dc8:	92c7b783          	ld	a5,-1748(a5) # ffffffffc02aa6f0 <bigblocks>
    return 0;
ffffffffc0201dcc:	4601                	li	a2,0
ffffffffc0201dce:	cbad                	beqz	a5,ffffffffc0201e40 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201dd0:	000a9697          	auipc	a3,0xa9
ffffffffc0201dd4:	92068693          	addi	a3,a3,-1760 # ffffffffc02aa6f0 <bigblocks>
ffffffffc0201dd8:	a021                	j	ffffffffc0201de0 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dda:	01048693          	addi	a3,s1,16
ffffffffc0201dde:	c3a5                	beqz	a5,ffffffffc0201e3e <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201de0:	6798                	ld	a4,8(a5)
ffffffffc0201de2:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201de4:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201de6:	fe871ae3          	bne	a4,s0,ffffffffc0201dda <kfree+0x30>
				*last = bb->next;
ffffffffc0201dea:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201dec:	ee2d                	bnez	a2,ffffffffc0201e66 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201dee:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201df2:	4098                	lw	a4,0(s1)
ffffffffc0201df4:	08f46963          	bltu	s0,a5,ffffffffc0201e86 <kfree+0xdc>
ffffffffc0201df8:	000a9697          	auipc	a3,0xa9
ffffffffc0201dfc:	9286b683          	ld	a3,-1752(a3) # ffffffffc02aa720 <va_pa_offset>
ffffffffc0201e00:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201e02:	8031                	srli	s0,s0,0xc
ffffffffc0201e04:	000a9797          	auipc	a5,0xa9
ffffffffc0201e08:	9047b783          	ld	a5,-1788(a5) # ffffffffc02aa708 <npage>
ffffffffc0201e0c:	06f47163          	bgeu	s0,a5,ffffffffc0201e6e <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e10:	00006517          	auipc	a0,0x6
ffffffffc0201e14:	bc053503          	ld	a0,-1088(a0) # ffffffffc02079d0 <nbase>
ffffffffc0201e18:	8c09                	sub	s0,s0,a0
ffffffffc0201e1a:	041a                	slli	s0,s0,0x6
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201e1c:	000a9517          	auipc	a0,0xa9
ffffffffc0201e20:	8f453503          	ld	a0,-1804(a0) # ffffffffc02aa710 <pages>
ffffffffc0201e24:	4585                	li	a1,1
ffffffffc0201e26:	9522                	add	a0,a0,s0
ffffffffc0201e28:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201e2c:	0ea000ef          	jal	ra,ffffffffc0201f16 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e30:	6442                	ld	s0,16(sp)
ffffffffc0201e32:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e34:	8526                	mv	a0,s1
}
ffffffffc0201e36:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e38:	45e1                	li	a1,24
}
ffffffffc0201e3a:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e3c:	b171                	j	ffffffffc0201ac8 <slob_free>
ffffffffc0201e3e:	e20d                	bnez	a2,ffffffffc0201e60 <kfree+0xb6>
ffffffffc0201e40:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201e44:	6442                	ld	s0,16(sp)
ffffffffc0201e46:	60e2                	ld	ra,24(sp)
ffffffffc0201e48:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e4a:	4581                	li	a1,0
}
ffffffffc0201e4c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e4e:	b9ad                	j	ffffffffc0201ac8 <slob_free>
        intr_disable();
ffffffffc0201e50:	b65fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e54:	000a9797          	auipc	a5,0xa9
ffffffffc0201e58:	89c7b783          	ld	a5,-1892(a5) # ffffffffc02aa6f0 <bigblocks>
        return 1;
ffffffffc0201e5c:	4605                	li	a2,1
ffffffffc0201e5e:	fbad                	bnez	a5,ffffffffc0201dd0 <kfree+0x26>
        intr_enable();
ffffffffc0201e60:	b4ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e64:	bff1                	j	ffffffffc0201e40 <kfree+0x96>
ffffffffc0201e66:	b49fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e6a:	b751                	j	ffffffffc0201dee <kfree+0x44>
ffffffffc0201e6c:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e6e:	00005617          	auipc	a2,0x5
ffffffffc0201e72:	96260613          	addi	a2,a2,-1694 # ffffffffc02067d0 <default_pmm_manager+0x108>
ffffffffc0201e76:	06a00593          	li	a1,106
ffffffffc0201e7a:	00005517          	auipc	a0,0x5
ffffffffc0201e7e:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0201e82:	e0cfe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e86:	86a2                	mv	a3,s0
ffffffffc0201e88:	00005617          	auipc	a2,0x5
ffffffffc0201e8c:	92060613          	addi	a2,a2,-1760 # ffffffffc02067a8 <default_pmm_manager+0xe0>
ffffffffc0201e90:	07800593          	li	a1,120
ffffffffc0201e94:	00005517          	auipc	a0,0x5
ffffffffc0201e98:	89450513          	addi	a0,a0,-1900 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0201e9c:	df2fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ea0 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201ea0:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201ea2:	00005617          	auipc	a2,0x5
ffffffffc0201ea6:	92e60613          	addi	a2,a2,-1746 # ffffffffc02067d0 <default_pmm_manager+0x108>
ffffffffc0201eaa:	06a00593          	li	a1,106
ffffffffc0201eae:	00005517          	auipc	a0,0x5
ffffffffc0201eb2:	87a50513          	addi	a0,a0,-1926 # ffffffffc0206728 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201eb6:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201eb8:	dd6fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ebc <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201ebc:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201ebe:	00005617          	auipc	a2,0x5
ffffffffc0201ec2:	93260613          	addi	a2,a2,-1742 # ffffffffc02067f0 <default_pmm_manager+0x128>
ffffffffc0201ec6:	08000593          	li	a1,128
ffffffffc0201eca:	00005517          	auipc	a0,0x5
ffffffffc0201ece:	85e50513          	addi	a0,a0,-1954 # ffffffffc0206728 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201ed2:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201ed4:	dbafe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ed8 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ed8:	100027f3          	csrr	a5,sstatus
ffffffffc0201edc:	8b89                	andi	a5,a5,2
ffffffffc0201ede:	e799                	bnez	a5,ffffffffc0201eec <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ee0:	000a9797          	auipc	a5,0xa9
ffffffffc0201ee4:	8387b783          	ld	a5,-1992(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0201ee8:	6f9c                	ld	a5,24(a5)
ffffffffc0201eea:	8782                	jr	a5
{
ffffffffc0201eec:	1141                	addi	sp,sp,-16
ffffffffc0201eee:	e406                	sd	ra,8(sp)
ffffffffc0201ef0:	e022                	sd	s0,0(sp)
ffffffffc0201ef2:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201ef4:	ac1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ef8:	000a9797          	auipc	a5,0xa9
ffffffffc0201efc:	8207b783          	ld	a5,-2016(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0201f00:	6f9c                	ld	a5,24(a5)
ffffffffc0201f02:	8522                	mv	a0,s0
ffffffffc0201f04:	9782                	jalr	a5
ffffffffc0201f06:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f08:	aa7fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f0c:	60a2                	ld	ra,8(sp)
ffffffffc0201f0e:	8522                	mv	a0,s0
ffffffffc0201f10:	6402                	ld	s0,0(sp)
ffffffffc0201f12:	0141                	addi	sp,sp,16
ffffffffc0201f14:	8082                	ret

ffffffffc0201f16 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f16:	100027f3          	csrr	a5,sstatus
ffffffffc0201f1a:	8b89                	andi	a5,a5,2
ffffffffc0201f1c:	e799                	bnez	a5,ffffffffc0201f2a <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f1e:	000a8797          	auipc	a5,0xa8
ffffffffc0201f22:	7fa7b783          	ld	a5,2042(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0201f26:	739c                	ld	a5,32(a5)
ffffffffc0201f28:	8782                	jr	a5
{
ffffffffc0201f2a:	1101                	addi	sp,sp,-32
ffffffffc0201f2c:	ec06                	sd	ra,24(sp)
ffffffffc0201f2e:	e822                	sd	s0,16(sp)
ffffffffc0201f30:	e426                	sd	s1,8(sp)
ffffffffc0201f32:	842a                	mv	s0,a0
ffffffffc0201f34:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201f36:	a7ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f3a:	000a8797          	auipc	a5,0xa8
ffffffffc0201f3e:	7de7b783          	ld	a5,2014(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0201f42:	739c                	ld	a5,32(a5)
ffffffffc0201f44:	85a6                	mv	a1,s1
ffffffffc0201f46:	8522                	mv	a0,s0
ffffffffc0201f48:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f4a:	6442                	ld	s0,16(sp)
ffffffffc0201f4c:	60e2                	ld	ra,24(sp)
ffffffffc0201f4e:	64a2                	ld	s1,8(sp)
ffffffffc0201f50:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f52:	a5dfe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201f56 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f56:	100027f3          	csrr	a5,sstatus
ffffffffc0201f5a:	8b89                	andi	a5,a5,2
ffffffffc0201f5c:	e799                	bnez	a5,ffffffffc0201f6a <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f5e:	000a8797          	auipc	a5,0xa8
ffffffffc0201f62:	7ba7b783          	ld	a5,1978(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0201f66:	779c                	ld	a5,40(a5)
ffffffffc0201f68:	8782                	jr	a5
{
ffffffffc0201f6a:	1141                	addi	sp,sp,-16
ffffffffc0201f6c:	e406                	sd	ra,8(sp)
ffffffffc0201f6e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f70:	a45fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f74:	000a8797          	auipc	a5,0xa8
ffffffffc0201f78:	7a47b783          	ld	a5,1956(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0201f7c:	779c                	ld	a5,40(a5)
ffffffffc0201f7e:	9782                	jalr	a5
ffffffffc0201f80:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f82:	a2dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f86:	60a2                	ld	ra,8(sp)
ffffffffc0201f88:	8522                	mv	a0,s0
ffffffffc0201f8a:	6402                	ld	s0,0(sp)
ffffffffc0201f8c:	0141                	addi	sp,sp,16
ffffffffc0201f8e:	8082                	ret

ffffffffc0201f90 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f90:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f94:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201f98:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f9a:	078e                	slli	a5,a5,0x3
{
ffffffffc0201f9c:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f9e:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201fa2:	6094                	ld	a3,0(s1)
{
ffffffffc0201fa4:	f04a                	sd	s2,32(sp)
ffffffffc0201fa6:	ec4e                	sd	s3,24(sp)
ffffffffc0201fa8:	e852                	sd	s4,16(sp)
ffffffffc0201faa:	fc06                	sd	ra,56(sp)
ffffffffc0201fac:	f822                	sd	s0,48(sp)
ffffffffc0201fae:	e456                	sd	s5,8(sp)
ffffffffc0201fb0:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201fb2:	0016f793          	andi	a5,a3,1
{
ffffffffc0201fb6:	892e                	mv	s2,a1
ffffffffc0201fb8:	8a32                	mv	s4,a2
ffffffffc0201fba:	000a8997          	auipc	s3,0xa8
ffffffffc0201fbe:	74e98993          	addi	s3,s3,1870 # ffffffffc02aa708 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201fc2:	efbd                	bnez	a5,ffffffffc0202040 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fc4:	14060c63          	beqz	a2,ffffffffc020211c <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fc8:	100027f3          	csrr	a5,sstatus
ffffffffc0201fcc:	8b89                	andi	a5,a5,2
ffffffffc0201fce:	14079963          	bnez	a5,ffffffffc0202120 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fd2:	000a8797          	auipc	a5,0xa8
ffffffffc0201fd6:	7467b783          	ld	a5,1862(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0201fda:	6f9c                	ld	a5,24(a5)
ffffffffc0201fdc:	4505                	li	a0,1
ffffffffc0201fde:	9782                	jalr	a5
ffffffffc0201fe0:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fe2:	12040d63          	beqz	s0,ffffffffc020211c <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201fe6:	000a8b17          	auipc	s6,0xa8
ffffffffc0201fea:	72ab0b13          	addi	s6,s6,1834 # ffffffffc02aa710 <pages>
ffffffffc0201fee:	000b3503          	ld	a0,0(s6)
ffffffffc0201ff2:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ff6:	000a8997          	auipc	s3,0xa8
ffffffffc0201ffa:	71298993          	addi	s3,s3,1810 # ffffffffc02aa708 <npage>
ffffffffc0201ffe:	40a40533          	sub	a0,s0,a0
ffffffffc0202002:	8519                	srai	a0,a0,0x6
ffffffffc0202004:	9556                	add	a0,a0,s5
ffffffffc0202006:	0009b703          	ld	a4,0(s3)
ffffffffc020200a:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc020200e:	4685                	li	a3,1
ffffffffc0202010:	c014                	sw	a3,0(s0)
ffffffffc0202012:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202014:	0532                	slli	a0,a0,0xc
ffffffffc0202016:	16e7f763          	bgeu	a5,a4,ffffffffc0202184 <get_pte+0x1f4>
ffffffffc020201a:	000a8797          	auipc	a5,0xa8
ffffffffc020201e:	7067b783          	ld	a5,1798(a5) # ffffffffc02aa720 <va_pa_offset>
ffffffffc0202022:	6605                	lui	a2,0x1
ffffffffc0202024:	4581                	li	a1,0
ffffffffc0202026:	953e                	add	a0,a0,a5
ffffffffc0202028:	033030ef          	jal	ra,ffffffffc020585a <memset>
    return page - pages + nbase;
ffffffffc020202c:	000b3683          	ld	a3,0(s6)
ffffffffc0202030:	40d406b3          	sub	a3,s0,a3
ffffffffc0202034:	8699                	srai	a3,a3,0x6
ffffffffc0202036:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202038:	06aa                	slli	a3,a3,0xa
ffffffffc020203a:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020203e:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202040:	77fd                	lui	a5,0xfffff
ffffffffc0202042:	068a                	slli	a3,a3,0x2
ffffffffc0202044:	0009b703          	ld	a4,0(s3)
ffffffffc0202048:	8efd                	and	a3,a3,a5
ffffffffc020204a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020204e:	10e7ff63          	bgeu	a5,a4,ffffffffc020216c <get_pte+0x1dc>
ffffffffc0202052:	000a8a97          	auipc	s5,0xa8
ffffffffc0202056:	6cea8a93          	addi	s5,s5,1742 # ffffffffc02aa720 <va_pa_offset>
ffffffffc020205a:	000ab403          	ld	s0,0(s5)
ffffffffc020205e:	01595793          	srli	a5,s2,0x15
ffffffffc0202062:	1ff7f793          	andi	a5,a5,511
ffffffffc0202066:	96a2                	add	a3,a3,s0
ffffffffc0202068:	00379413          	slli	s0,a5,0x3
ffffffffc020206c:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc020206e:	6014                	ld	a3,0(s0)
ffffffffc0202070:	0016f793          	andi	a5,a3,1
ffffffffc0202074:	ebad                	bnez	a5,ffffffffc02020e6 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202076:	0a0a0363          	beqz	s4,ffffffffc020211c <get_pte+0x18c>
ffffffffc020207a:	100027f3          	csrr	a5,sstatus
ffffffffc020207e:	8b89                	andi	a5,a5,2
ffffffffc0202080:	efcd                	bnez	a5,ffffffffc020213a <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202082:	000a8797          	auipc	a5,0xa8
ffffffffc0202086:	6967b783          	ld	a5,1686(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc020208a:	6f9c                	ld	a5,24(a5)
ffffffffc020208c:	4505                	li	a0,1
ffffffffc020208e:	9782                	jalr	a5
ffffffffc0202090:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202092:	c4c9                	beqz	s1,ffffffffc020211c <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202094:	000a8b17          	auipc	s6,0xa8
ffffffffc0202098:	67cb0b13          	addi	s6,s6,1660 # ffffffffc02aa710 <pages>
ffffffffc020209c:	000b3503          	ld	a0,0(s6)
ffffffffc02020a0:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020a4:	0009b703          	ld	a4,0(s3)
ffffffffc02020a8:	40a48533          	sub	a0,s1,a0
ffffffffc02020ac:	8519                	srai	a0,a0,0x6
ffffffffc02020ae:	9552                	add	a0,a0,s4
ffffffffc02020b0:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02020b4:	4685                	li	a3,1
ffffffffc02020b6:	c094                	sw	a3,0(s1)
ffffffffc02020b8:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02020ba:	0532                	slli	a0,a0,0xc
ffffffffc02020bc:	0ee7f163          	bgeu	a5,a4,ffffffffc020219e <get_pte+0x20e>
ffffffffc02020c0:	000ab783          	ld	a5,0(s5)
ffffffffc02020c4:	6605                	lui	a2,0x1
ffffffffc02020c6:	4581                	li	a1,0
ffffffffc02020c8:	953e                	add	a0,a0,a5
ffffffffc02020ca:	790030ef          	jal	ra,ffffffffc020585a <memset>
    return page - pages + nbase;
ffffffffc02020ce:	000b3683          	ld	a3,0(s6)
ffffffffc02020d2:	40d486b3          	sub	a3,s1,a3
ffffffffc02020d6:	8699                	srai	a3,a3,0x6
ffffffffc02020d8:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020da:	06aa                	slli	a3,a3,0xa
ffffffffc02020dc:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020e0:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020e2:	0009b703          	ld	a4,0(s3)
ffffffffc02020e6:	068a                	slli	a3,a3,0x2
ffffffffc02020e8:	757d                	lui	a0,0xfffff
ffffffffc02020ea:	8ee9                	and	a3,a3,a0
ffffffffc02020ec:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020f0:	06e7f263          	bgeu	a5,a4,ffffffffc0202154 <get_pte+0x1c4>
ffffffffc02020f4:	000ab503          	ld	a0,0(s5)
ffffffffc02020f8:	00c95913          	srli	s2,s2,0xc
ffffffffc02020fc:	1ff97913          	andi	s2,s2,511
ffffffffc0202100:	96aa                	add	a3,a3,a0
ffffffffc0202102:	00391513          	slli	a0,s2,0x3
ffffffffc0202106:	9536                	add	a0,a0,a3
}
ffffffffc0202108:	70e2                	ld	ra,56(sp)
ffffffffc020210a:	7442                	ld	s0,48(sp)
ffffffffc020210c:	74a2                	ld	s1,40(sp)
ffffffffc020210e:	7902                	ld	s2,32(sp)
ffffffffc0202110:	69e2                	ld	s3,24(sp)
ffffffffc0202112:	6a42                	ld	s4,16(sp)
ffffffffc0202114:	6aa2                	ld	s5,8(sp)
ffffffffc0202116:	6b02                	ld	s6,0(sp)
ffffffffc0202118:	6121                	addi	sp,sp,64
ffffffffc020211a:	8082                	ret
            return NULL;
ffffffffc020211c:	4501                	li	a0,0
ffffffffc020211e:	b7ed                	j	ffffffffc0202108 <get_pte+0x178>
        intr_disable();
ffffffffc0202120:	895fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202124:	000a8797          	auipc	a5,0xa8
ffffffffc0202128:	5f47b783          	ld	a5,1524(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc020212c:	6f9c                	ld	a5,24(a5)
ffffffffc020212e:	4505                	li	a0,1
ffffffffc0202130:	9782                	jalr	a5
ffffffffc0202132:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202134:	87bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202138:	b56d                	j	ffffffffc0201fe2 <get_pte+0x52>
        intr_disable();
ffffffffc020213a:	87bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020213e:	000a8797          	auipc	a5,0xa8
ffffffffc0202142:	5da7b783          	ld	a5,1498(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0202146:	6f9c                	ld	a5,24(a5)
ffffffffc0202148:	4505                	li	a0,1
ffffffffc020214a:	9782                	jalr	a5
ffffffffc020214c:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc020214e:	861fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202152:	b781                	j	ffffffffc0202092 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202154:	00004617          	auipc	a2,0x4
ffffffffc0202158:	5ac60613          	addi	a2,a2,1452 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc020215c:	0fa00593          	li	a1,250
ffffffffc0202160:	00004517          	auipc	a0,0x4
ffffffffc0202164:	6b850513          	addi	a0,a0,1720 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202168:	b26fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020216c:	00004617          	auipc	a2,0x4
ffffffffc0202170:	59460613          	addi	a2,a2,1428 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc0202174:	0ed00593          	li	a1,237
ffffffffc0202178:	00004517          	auipc	a0,0x4
ffffffffc020217c:	6a050513          	addi	a0,a0,1696 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202180:	b0efe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202184:	86aa                	mv	a3,a0
ffffffffc0202186:	00004617          	auipc	a2,0x4
ffffffffc020218a:	57a60613          	addi	a2,a2,1402 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc020218e:	0e900593          	li	a1,233
ffffffffc0202192:	00004517          	auipc	a0,0x4
ffffffffc0202196:	68650513          	addi	a0,a0,1670 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc020219a:	af4fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020219e:	86aa                	mv	a3,a0
ffffffffc02021a0:	00004617          	auipc	a2,0x4
ffffffffc02021a4:	56060613          	addi	a2,a2,1376 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc02021a8:	0f700593          	li	a1,247
ffffffffc02021ac:	00004517          	auipc	a0,0x4
ffffffffc02021b0:	66c50513          	addi	a0,a0,1644 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02021b4:	adafe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02021b8 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02021b8:	1141                	addi	sp,sp,-16
ffffffffc02021ba:	e022                	sd	s0,0(sp)
ffffffffc02021bc:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021be:	4601                	li	a2,0
{
ffffffffc02021c0:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021c2:	dcfff0ef          	jal	ra,ffffffffc0201f90 <get_pte>
    if (ptep_store != NULL)
ffffffffc02021c6:	c011                	beqz	s0,ffffffffc02021ca <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02021c8:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021ca:	c511                	beqz	a0,ffffffffc02021d6 <get_page+0x1e>
ffffffffc02021cc:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02021ce:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021d0:	0017f713          	andi	a4,a5,1
ffffffffc02021d4:	e709                	bnez	a4,ffffffffc02021de <get_page+0x26>
}
ffffffffc02021d6:	60a2                	ld	ra,8(sp)
ffffffffc02021d8:	6402                	ld	s0,0(sp)
ffffffffc02021da:	0141                	addi	sp,sp,16
ffffffffc02021dc:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02021de:	078a                	slli	a5,a5,0x2
ffffffffc02021e0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021e2:	000a8717          	auipc	a4,0xa8
ffffffffc02021e6:	52673703          	ld	a4,1318(a4) # ffffffffc02aa708 <npage>
ffffffffc02021ea:	00e7ff63          	bgeu	a5,a4,ffffffffc0202208 <get_page+0x50>
ffffffffc02021ee:	60a2                	ld	ra,8(sp)
ffffffffc02021f0:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02021f2:	fff80537          	lui	a0,0xfff80
ffffffffc02021f6:	97aa                	add	a5,a5,a0
ffffffffc02021f8:	079a                	slli	a5,a5,0x6
ffffffffc02021fa:	000a8517          	auipc	a0,0xa8
ffffffffc02021fe:	51653503          	ld	a0,1302(a0) # ffffffffc02aa710 <pages>
ffffffffc0202202:	953e                	add	a0,a0,a5
ffffffffc0202204:	0141                	addi	sp,sp,16
ffffffffc0202206:	8082                	ret
ffffffffc0202208:	c99ff0ef          	jal	ra,ffffffffc0201ea0 <pa2page.part.0>

ffffffffc020220c <page_remove_pte>:
// page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
// note: PT is changed, so the TLB need to be invalidate
void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep)
{
    if (*ptep & PTE_V)
ffffffffc020220c:	621c                	ld	a5,0(a2)
ffffffffc020220e:	0017f713          	andi	a4,a5,1
ffffffffc0202212:	e311                	bnez	a4,ffffffffc0202216 <page_remove_pte+0xa>
ffffffffc0202214:	8082                	ret
{
ffffffffc0202216:	1101                	addi	sp,sp,-32
    return pa2page(PTE_ADDR(pte));
ffffffffc0202218:	078a                	slli	a5,a5,0x2
ffffffffc020221a:	ec06                	sd	ra,24(sp)
ffffffffc020221c:	e826                	sd	s1,16(sp)
ffffffffc020221e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202220:	000a8717          	auipc	a4,0xa8
ffffffffc0202224:	4e873703          	ld	a4,1256(a4) # ffffffffc02aa708 <npage>
ffffffffc0202228:	06e7f763          	bgeu	a5,a4,ffffffffc0202296 <page_remove_pte+0x8a>
    return &pages[PPN(pa) - nbase];
ffffffffc020222c:	fff80537          	lui	a0,0xfff80
ffffffffc0202230:	97aa                	add	a5,a5,a0
ffffffffc0202232:	079a                	slli	a5,a5,0x6
ffffffffc0202234:	000a8517          	auipc	a0,0xa8
ffffffffc0202238:	4dc53503          	ld	a0,1244(a0) # ffffffffc02aa710 <pages>
ffffffffc020223c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020223e:	411c                	lw	a5,0(a0)
ffffffffc0202240:	84ae                	mv	s1,a1
ffffffffc0202242:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202246:	c118                	sw	a4,0(a0)
    {
        struct Page *page = pte2page(*ptep);
        page_ref_dec(page);
        if (page_ref(page) == 0)
ffffffffc0202248:	cb09                	beqz	a4,ffffffffc020225a <page_remove_pte+0x4e>
        {
            free_page(page);
        }
        *ptep = 0;
ffffffffc020224a:	00063023          	sd	zero,0(a2)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020224e:	12048073          	sfence.vma	s1
}
ffffffffc0202252:	60e2                	ld	ra,24(sp)
ffffffffc0202254:	64c2                	ld	s1,16(sp)
ffffffffc0202256:	6105                	addi	sp,sp,32
ffffffffc0202258:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020225a:	100027f3          	csrr	a5,sstatus
ffffffffc020225e:	8b89                	andi	a5,a5,2
ffffffffc0202260:	eb99                	bnez	a5,ffffffffc0202276 <page_remove_pte+0x6a>
        pmm_manager->free_pages(base, n);
ffffffffc0202262:	000a8797          	auipc	a5,0xa8
ffffffffc0202266:	4b67b783          	ld	a5,1206(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc020226a:	739c                	ld	a5,32(a5)
ffffffffc020226c:	4585                	li	a1,1
ffffffffc020226e:	e032                	sd	a2,0(sp)
ffffffffc0202270:	9782                	jalr	a5
    if (flag)
ffffffffc0202272:	6602                	ld	a2,0(sp)
ffffffffc0202274:	bfd9                	j	ffffffffc020224a <page_remove_pte+0x3e>
        intr_disable();
ffffffffc0202276:	e432                	sd	a2,8(sp)
ffffffffc0202278:	e02a                	sd	a0,0(sp)
ffffffffc020227a:	f3afe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020227e:	000a8797          	auipc	a5,0xa8
ffffffffc0202282:	49a7b783          	ld	a5,1178(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0202286:	739c                	ld	a5,32(a5)
ffffffffc0202288:	6502                	ld	a0,0(sp)
ffffffffc020228a:	4585                	li	a1,1
ffffffffc020228c:	9782                	jalr	a5
        intr_enable();
ffffffffc020228e:	f20fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202292:	6622                	ld	a2,8(sp)
ffffffffc0202294:	bf5d                	j	ffffffffc020224a <page_remove_pte+0x3e>
ffffffffc0202296:	c0bff0ef          	jal	ra,ffffffffc0201ea0 <pa2page.part.0>

ffffffffc020229a <unmap_range>:
{
ffffffffc020229a:	7139                	addi	sp,sp,-64
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020229c:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02022a0:	fc06                	sd	ra,56(sp)
ffffffffc02022a2:	f822                	sd	s0,48(sp)
ffffffffc02022a4:	f426                	sd	s1,40(sp)
ffffffffc02022a6:	f04a                	sd	s2,32(sp)
ffffffffc02022a8:	ec4e                	sd	s3,24(sp)
ffffffffc02022aa:	e852                	sd	s4,16(sp)
ffffffffc02022ac:	e456                	sd	s5,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022ae:	17d2                	slli	a5,a5,0x34
ffffffffc02022b0:	e7ad                	bnez	a5,ffffffffc020231a <unmap_range+0x80>
    assert(USER_ACCESS(start, end));
ffffffffc02022b2:	002007b7          	lui	a5,0x200
ffffffffc02022b6:	842e                	mv	s0,a1
ffffffffc02022b8:	08f5e163          	bltu	a1,a5,ffffffffc020233a <unmap_range+0xa0>
ffffffffc02022bc:	8932                	mv	s2,a2
ffffffffc02022be:	06c5fe63          	bgeu	a1,a2,ffffffffc020233a <unmap_range+0xa0>
ffffffffc02022c2:	4785                	li	a5,1
ffffffffc02022c4:	07fe                	slli	a5,a5,0x1f
ffffffffc02022c6:	06c7ea63          	bltu	a5,a2,ffffffffc020233a <unmap_range+0xa0>
ffffffffc02022ca:	84aa                	mv	s1,a0
        start += PGSIZE;
ffffffffc02022cc:	6985                	lui	s3,0x1
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022ce:	00200ab7          	lui	s5,0x200
ffffffffc02022d2:	ffe00a37          	lui	s4,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02022d6:	4601                	li	a2,0
ffffffffc02022d8:	85a2                	mv	a1,s0
ffffffffc02022da:	8526                	mv	a0,s1
ffffffffc02022dc:	cb5ff0ef          	jal	ra,ffffffffc0201f90 <get_pte>
        if (ptep == NULL)
ffffffffc02022e0:	c515                	beqz	a0,ffffffffc020230c <unmap_range+0x72>
        if (*ptep != 0)
ffffffffc02022e2:	611c                	ld	a5,0(a0)
ffffffffc02022e4:	ef89                	bnez	a5,ffffffffc02022fe <unmap_range+0x64>
        start += PGSIZE;
ffffffffc02022e6:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc02022e8:	ff2467e3          	bltu	s0,s2,ffffffffc02022d6 <unmap_range+0x3c>
}
ffffffffc02022ec:	70e2                	ld	ra,56(sp)
ffffffffc02022ee:	7442                	ld	s0,48(sp)
ffffffffc02022f0:	74a2                	ld	s1,40(sp)
ffffffffc02022f2:	7902                	ld	s2,32(sp)
ffffffffc02022f4:	69e2                	ld	s3,24(sp)
ffffffffc02022f6:	6a42                	ld	s4,16(sp)
ffffffffc02022f8:	6aa2                	ld	s5,8(sp)
ffffffffc02022fa:	6121                	addi	sp,sp,64
ffffffffc02022fc:	8082                	ret
            page_remove_pte(pgdir, start, ptep);
ffffffffc02022fe:	862a                	mv	a2,a0
ffffffffc0202300:	85a2                	mv	a1,s0
ffffffffc0202302:	8526                	mv	a0,s1
ffffffffc0202304:	f09ff0ef          	jal	ra,ffffffffc020220c <page_remove_pte>
        start += PGSIZE;
ffffffffc0202308:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc020230a:	bff9                	j	ffffffffc02022e8 <unmap_range+0x4e>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020230c:	9456                	add	s0,s0,s5
ffffffffc020230e:	01447433          	and	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202312:	dc69                	beqz	s0,ffffffffc02022ec <unmap_range+0x52>
ffffffffc0202314:	fd2461e3          	bltu	s0,s2,ffffffffc02022d6 <unmap_range+0x3c>
ffffffffc0202318:	bfd1                	j	ffffffffc02022ec <unmap_range+0x52>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020231a:	00004697          	auipc	a3,0x4
ffffffffc020231e:	50e68693          	addi	a3,a3,1294 # ffffffffc0206828 <default_pmm_manager+0x160>
ffffffffc0202322:	00004617          	auipc	a2,0x4
ffffffffc0202326:	ff660613          	addi	a2,a2,-10 # ffffffffc0206318 <commands+0x828>
ffffffffc020232a:	12000593          	li	a1,288
ffffffffc020232e:	00004517          	auipc	a0,0x4
ffffffffc0202332:	4ea50513          	addi	a0,a0,1258 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202336:	958fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020233a:	00004697          	auipc	a3,0x4
ffffffffc020233e:	51e68693          	addi	a3,a3,1310 # ffffffffc0206858 <default_pmm_manager+0x190>
ffffffffc0202342:	00004617          	auipc	a2,0x4
ffffffffc0202346:	fd660613          	addi	a2,a2,-42 # ffffffffc0206318 <commands+0x828>
ffffffffc020234a:	12100593          	li	a1,289
ffffffffc020234e:	00004517          	auipc	a0,0x4
ffffffffc0202352:	4ca50513          	addi	a0,a0,1226 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202356:	938fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020235a <exit_range>:
{
ffffffffc020235a:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020235c:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202360:	fc86                	sd	ra,120(sp)
ffffffffc0202362:	f8a2                	sd	s0,112(sp)
ffffffffc0202364:	f4a6                	sd	s1,104(sp)
ffffffffc0202366:	f0ca                	sd	s2,96(sp)
ffffffffc0202368:	ecce                	sd	s3,88(sp)
ffffffffc020236a:	e8d2                	sd	s4,80(sp)
ffffffffc020236c:	e4d6                	sd	s5,72(sp)
ffffffffc020236e:	e0da                	sd	s6,64(sp)
ffffffffc0202370:	fc5e                	sd	s7,56(sp)
ffffffffc0202372:	f862                	sd	s8,48(sp)
ffffffffc0202374:	f466                	sd	s9,40(sp)
ffffffffc0202376:	f06a                	sd	s10,32(sp)
ffffffffc0202378:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020237a:	17d2                	slli	a5,a5,0x34
ffffffffc020237c:	20079a63          	bnez	a5,ffffffffc0202590 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0202380:	002007b7          	lui	a5,0x200
ffffffffc0202384:	24f5e463          	bltu	a1,a5,ffffffffc02025cc <exit_range+0x272>
ffffffffc0202388:	8ab2                	mv	s5,a2
ffffffffc020238a:	24c5f163          	bgeu	a1,a2,ffffffffc02025cc <exit_range+0x272>
ffffffffc020238e:	4785                	li	a5,1
ffffffffc0202390:	07fe                	slli	a5,a5,0x1f
ffffffffc0202392:	22c7ed63          	bltu	a5,a2,ffffffffc02025cc <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202396:	c00009b7          	lui	s3,0xc0000
ffffffffc020239a:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020239e:	ffe00937          	lui	s2,0xffe00
ffffffffc02023a2:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc02023a6:	5cfd                	li	s9,-1
ffffffffc02023a8:	8c2a                	mv	s8,a0
ffffffffc02023aa:	0125f933          	and	s2,a1,s2
ffffffffc02023ae:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc02023b0:	000a8d17          	auipc	s10,0xa8
ffffffffc02023b4:	358d0d13          	addi	s10,s10,856 # ffffffffc02aa708 <npage>
    return KADDR(page2pa(page));
ffffffffc02023b8:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023bc:	000a8717          	auipc	a4,0xa8
ffffffffc02023c0:	35470713          	addi	a4,a4,852 # ffffffffc02aa710 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02023c4:	000a8d97          	auipc	s11,0xa8
ffffffffc02023c8:	354d8d93          	addi	s11,s11,852 # ffffffffc02aa718 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02023cc:	c0000437          	lui	s0,0xc0000
ffffffffc02023d0:	944e                	add	s0,s0,s3
ffffffffc02023d2:	8079                	srli	s0,s0,0x1e
ffffffffc02023d4:	1ff47413          	andi	s0,s0,511
ffffffffc02023d8:	040e                	slli	s0,s0,0x3
ffffffffc02023da:	9462                	add	s0,s0,s8
ffffffffc02023dc:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee0>
        if (pde1 & PTE_V)
ffffffffc02023e0:	001a7793          	andi	a5,s4,1
ffffffffc02023e4:	eb99                	bnez	a5,ffffffffc02023fa <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc02023e6:	12098463          	beqz	s3,ffffffffc020250e <exit_range+0x1b4>
ffffffffc02023ea:	400007b7          	lui	a5,0x40000
ffffffffc02023ee:	97ce                	add	a5,a5,s3
ffffffffc02023f0:	894e                	mv	s2,s3
ffffffffc02023f2:	1159fe63          	bgeu	s3,s5,ffffffffc020250e <exit_range+0x1b4>
ffffffffc02023f6:	89be                	mv	s3,a5
ffffffffc02023f8:	bfd1                	j	ffffffffc02023cc <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02023fa:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023fe:	0a0a                	slli	s4,s4,0x2
ffffffffc0202400:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202404:	1cfa7263          	bgeu	s4,a5,ffffffffc02025c8 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202408:	fff80637          	lui	a2,0xfff80
ffffffffc020240c:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020240e:	000806b7          	lui	a3,0x80
ffffffffc0202412:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202414:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202418:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020241a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020241c:	18f5fa63          	bgeu	a1,a5,ffffffffc02025b0 <exit_range+0x256>
ffffffffc0202420:	000a8817          	auipc	a6,0xa8
ffffffffc0202424:	30080813          	addi	a6,a6,768 # ffffffffc02aa720 <va_pa_offset>
ffffffffc0202428:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc020242c:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020242e:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc0202432:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202434:	00080337          	lui	t1,0x80
ffffffffc0202438:	6885                	lui	a7,0x1
ffffffffc020243a:	a819                	j	ffffffffc0202450 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc020243c:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020243e:	002007b7          	lui	a5,0x200
ffffffffc0202442:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202444:	08090c63          	beqz	s2,ffffffffc02024dc <exit_range+0x182>
ffffffffc0202448:	09397a63          	bgeu	s2,s3,ffffffffc02024dc <exit_range+0x182>
ffffffffc020244c:	0f597063          	bgeu	s2,s5,ffffffffc020252c <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202450:	01595493          	srli	s1,s2,0x15
ffffffffc0202454:	1ff4f493          	andi	s1,s1,511
ffffffffc0202458:	048e                	slli	s1,s1,0x3
ffffffffc020245a:	94da                	add	s1,s1,s6
ffffffffc020245c:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc020245e:	0017f693          	andi	a3,a5,1
ffffffffc0202462:	dee9                	beqz	a3,ffffffffc020243c <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202464:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202468:	078a                	slli	a5,a5,0x2
ffffffffc020246a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020246c:	14b7fe63          	bgeu	a5,a1,ffffffffc02025c8 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202470:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc0202472:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202476:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc020247a:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020247e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202480:	12bef863          	bgeu	t4,a1,ffffffffc02025b0 <exit_range+0x256>
ffffffffc0202484:	00083783          	ld	a5,0(a6)
ffffffffc0202488:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020248a:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020248e:	629c                	ld	a5,0(a3)
ffffffffc0202490:	8b85                	andi	a5,a5,1
ffffffffc0202492:	f7d5                	bnez	a5,ffffffffc020243e <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202494:	06a1                	addi	a3,a3,8
ffffffffc0202496:	fed59ce3          	bne	a1,a3,ffffffffc020248e <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc020249a:	631c                	ld	a5,0(a4)
ffffffffc020249c:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020249e:	100027f3          	csrr	a5,sstatus
ffffffffc02024a2:	8b89                	andi	a5,a5,2
ffffffffc02024a4:	e7d9                	bnez	a5,ffffffffc0202532 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc02024a6:	000db783          	ld	a5,0(s11)
ffffffffc02024aa:	4585                	li	a1,1
ffffffffc02024ac:	e032                	sd	a2,0(sp)
ffffffffc02024ae:	739c                	ld	a5,32(a5)
ffffffffc02024b0:	9782                	jalr	a5
    if (flag)
ffffffffc02024b2:	6602                	ld	a2,0(sp)
ffffffffc02024b4:	000a8817          	auipc	a6,0xa8
ffffffffc02024b8:	26c80813          	addi	a6,a6,620 # ffffffffc02aa720 <va_pa_offset>
ffffffffc02024bc:	fff80e37          	lui	t3,0xfff80
ffffffffc02024c0:	00080337          	lui	t1,0x80
ffffffffc02024c4:	6885                	lui	a7,0x1
ffffffffc02024c6:	000a8717          	auipc	a4,0xa8
ffffffffc02024ca:	24a70713          	addi	a4,a4,586 # ffffffffc02aa710 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024ce:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc02024d2:	002007b7          	lui	a5,0x200
ffffffffc02024d6:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02024d8:	f60918e3          	bnez	s2,ffffffffc0202448 <exit_range+0xee>
            if (free_pd0)
ffffffffc02024dc:	f00b85e3          	beqz	s7,ffffffffc02023e6 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc02024e0:	000d3783          	ld	a5,0(s10)
ffffffffc02024e4:	0efa7263          	bgeu	s4,a5,ffffffffc02025c8 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024e8:	6308                	ld	a0,0(a4)
ffffffffc02024ea:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024ec:	100027f3          	csrr	a5,sstatus
ffffffffc02024f0:	8b89                	andi	a5,a5,2
ffffffffc02024f2:	efad                	bnez	a5,ffffffffc020256c <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02024f4:	000db783          	ld	a5,0(s11)
ffffffffc02024f8:	4585                	li	a1,1
ffffffffc02024fa:	739c                	ld	a5,32(a5)
ffffffffc02024fc:	9782                	jalr	a5
ffffffffc02024fe:	000a8717          	auipc	a4,0xa8
ffffffffc0202502:	21270713          	addi	a4,a4,530 # ffffffffc02aa710 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202506:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc020250a:	ee0990e3          	bnez	s3,ffffffffc02023ea <exit_range+0x90>
}
ffffffffc020250e:	70e6                	ld	ra,120(sp)
ffffffffc0202510:	7446                	ld	s0,112(sp)
ffffffffc0202512:	74a6                	ld	s1,104(sp)
ffffffffc0202514:	7906                	ld	s2,96(sp)
ffffffffc0202516:	69e6                	ld	s3,88(sp)
ffffffffc0202518:	6a46                	ld	s4,80(sp)
ffffffffc020251a:	6aa6                	ld	s5,72(sp)
ffffffffc020251c:	6b06                	ld	s6,64(sp)
ffffffffc020251e:	7be2                	ld	s7,56(sp)
ffffffffc0202520:	7c42                	ld	s8,48(sp)
ffffffffc0202522:	7ca2                	ld	s9,40(sp)
ffffffffc0202524:	7d02                	ld	s10,32(sp)
ffffffffc0202526:	6de2                	ld	s11,24(sp)
ffffffffc0202528:	6109                	addi	sp,sp,128
ffffffffc020252a:	8082                	ret
            if (free_pd0)
ffffffffc020252c:	ea0b8fe3          	beqz	s7,ffffffffc02023ea <exit_range+0x90>
ffffffffc0202530:	bf45                	j	ffffffffc02024e0 <exit_range+0x186>
ffffffffc0202532:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202534:	e42a                	sd	a0,8(sp)
ffffffffc0202536:	c7efe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020253a:	000db783          	ld	a5,0(s11)
ffffffffc020253e:	6522                	ld	a0,8(sp)
ffffffffc0202540:	4585                	li	a1,1
ffffffffc0202542:	739c                	ld	a5,32(a5)
ffffffffc0202544:	9782                	jalr	a5
        intr_enable();
ffffffffc0202546:	c68fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020254a:	6602                	ld	a2,0(sp)
ffffffffc020254c:	000a8717          	auipc	a4,0xa8
ffffffffc0202550:	1c470713          	addi	a4,a4,452 # ffffffffc02aa710 <pages>
ffffffffc0202554:	6885                	lui	a7,0x1
ffffffffc0202556:	00080337          	lui	t1,0x80
ffffffffc020255a:	fff80e37          	lui	t3,0xfff80
ffffffffc020255e:	000a8817          	auipc	a6,0xa8
ffffffffc0202562:	1c280813          	addi	a6,a6,450 # ffffffffc02aa720 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202566:	0004b023          	sd	zero,0(s1)
ffffffffc020256a:	b7a5                	j	ffffffffc02024d2 <exit_range+0x178>
ffffffffc020256c:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020256e:	c46fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202572:	000db783          	ld	a5,0(s11)
ffffffffc0202576:	6502                	ld	a0,0(sp)
ffffffffc0202578:	4585                	li	a1,1
ffffffffc020257a:	739c                	ld	a5,32(a5)
ffffffffc020257c:	9782                	jalr	a5
        intr_enable();
ffffffffc020257e:	c30fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202582:	000a8717          	auipc	a4,0xa8
ffffffffc0202586:	18e70713          	addi	a4,a4,398 # ffffffffc02aa710 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020258a:	00043023          	sd	zero,0(s0)
ffffffffc020258e:	bfb5                	j	ffffffffc020250a <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202590:	00004697          	auipc	a3,0x4
ffffffffc0202594:	29868693          	addi	a3,a3,664 # ffffffffc0206828 <default_pmm_manager+0x160>
ffffffffc0202598:	00004617          	auipc	a2,0x4
ffffffffc020259c:	d8060613          	addi	a2,a2,-640 # ffffffffc0206318 <commands+0x828>
ffffffffc02025a0:	13500593          	li	a1,309
ffffffffc02025a4:	00004517          	auipc	a0,0x4
ffffffffc02025a8:	27450513          	addi	a0,a0,628 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02025ac:	ee3fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02025b0:	00004617          	auipc	a2,0x4
ffffffffc02025b4:	15060613          	addi	a2,a2,336 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc02025b8:	07200593          	li	a1,114
ffffffffc02025bc:	00004517          	auipc	a0,0x4
ffffffffc02025c0:	16c50513          	addi	a0,a0,364 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc02025c4:	ecbfd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02025c8:	8d9ff0ef          	jal	ra,ffffffffc0201ea0 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02025cc:	00004697          	auipc	a3,0x4
ffffffffc02025d0:	28c68693          	addi	a3,a3,652 # ffffffffc0206858 <default_pmm_manager+0x190>
ffffffffc02025d4:	00004617          	auipc	a2,0x4
ffffffffc02025d8:	d4460613          	addi	a2,a2,-700 # ffffffffc0206318 <commands+0x828>
ffffffffc02025dc:	13600593          	li	a1,310
ffffffffc02025e0:	00004517          	auipc	a0,0x4
ffffffffc02025e4:	23850513          	addi	a0,a0,568 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02025e8:	ea7fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02025ec <page_insert>:
{
ffffffffc02025ec:	7139                	addi	sp,sp,-64
ffffffffc02025ee:	e852                	sd	s4,16(sp)
ffffffffc02025f0:	8a32                	mv	s4,a2
ffffffffc02025f2:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02025f4:	4605                	li	a2,1
{
ffffffffc02025f6:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02025f8:	85d2                	mv	a1,s4
{
ffffffffc02025fa:	f426                	sd	s1,40(sp)
ffffffffc02025fc:	ec4e                	sd	s3,24(sp)
ffffffffc02025fe:	fc06                	sd	ra,56(sp)
ffffffffc0202600:	f04a                	sd	s2,32(sp)
ffffffffc0202602:	e456                	sd	s5,8(sp)
ffffffffc0202604:	89aa                	mv	s3,a0
ffffffffc0202606:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202608:	989ff0ef          	jal	ra,ffffffffc0201f90 <get_pte>
    if (ptep == NULL)
ffffffffc020260c:	c541                	beqz	a0,ffffffffc0202694 <page_insert+0xa8>
    page->ref += 1;
ffffffffc020260e:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202610:	611c                	ld	a5,0(a0)
ffffffffc0202612:	892a                	mv	s2,a0
ffffffffc0202614:	0016871b          	addiw	a4,a3,1
ffffffffc0202618:	c018                	sw	a4,0(s0)
ffffffffc020261a:	0017f713          	andi	a4,a5,1
ffffffffc020261e:	ef05                	bnez	a4,ffffffffc0202656 <page_insert+0x6a>
    return page - pages + nbase;
ffffffffc0202620:	000a8717          	auipc	a4,0xa8
ffffffffc0202624:	0f073703          	ld	a4,240(a4) # ffffffffc02aa710 <pages>
ffffffffc0202628:	8c19                	sub	s0,s0,a4
ffffffffc020262a:	000807b7          	lui	a5,0x80
ffffffffc020262e:	8419                	srai	s0,s0,0x6
ffffffffc0202630:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202632:	042a                	slli	s0,s0,0xa
ffffffffc0202634:	8cc1                	or	s1,s1,s0
ffffffffc0202636:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020263a:	00993023          	sd	s1,0(s2) # ffffffffffe00000 <end+0x3fb558bc>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020263e:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202642:	4501                	li	a0,0
}
ffffffffc0202644:	70e2                	ld	ra,56(sp)
ffffffffc0202646:	7442                	ld	s0,48(sp)
ffffffffc0202648:	74a2                	ld	s1,40(sp)
ffffffffc020264a:	7902                	ld	s2,32(sp)
ffffffffc020264c:	69e2                	ld	s3,24(sp)
ffffffffc020264e:	6a42                	ld	s4,16(sp)
ffffffffc0202650:	6aa2                	ld	s5,8(sp)
ffffffffc0202652:	6121                	addi	sp,sp,64
ffffffffc0202654:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202656:	078a                	slli	a5,a5,0x2
ffffffffc0202658:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020265a:	000a8717          	auipc	a4,0xa8
ffffffffc020265e:	0ae73703          	ld	a4,174(a4) # ffffffffc02aa708 <npage>
ffffffffc0202662:	02e7fb63          	bgeu	a5,a4,ffffffffc0202698 <page_insert+0xac>
    return &pages[PPN(pa) - nbase];
ffffffffc0202666:	000a8a97          	auipc	s5,0xa8
ffffffffc020266a:	0aaa8a93          	addi	s5,s5,170 # ffffffffc02aa710 <pages>
ffffffffc020266e:	000ab703          	ld	a4,0(s5)
ffffffffc0202672:	fff80637          	lui	a2,0xfff80
ffffffffc0202676:	97b2                	add	a5,a5,a2
ffffffffc0202678:	079a                	slli	a5,a5,0x6
ffffffffc020267a:	97ba                	add	a5,a5,a4
        if (p == page)
ffffffffc020267c:	00f40a63          	beq	s0,a5,ffffffffc0202690 <page_insert+0xa4>
            page_remove_pte(pgdir, la, ptep);
ffffffffc0202680:	862a                	mv	a2,a0
ffffffffc0202682:	85d2                	mv	a1,s4
ffffffffc0202684:	854e                	mv	a0,s3
ffffffffc0202686:	b87ff0ef          	jal	ra,ffffffffc020220c <page_remove_pte>
    return page - pages + nbase;
ffffffffc020268a:	000ab703          	ld	a4,0(s5)
ffffffffc020268e:	bf69                	j	ffffffffc0202628 <page_insert+0x3c>
    page->ref -= 1;
ffffffffc0202690:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202692:	bf59                	j	ffffffffc0202628 <page_insert+0x3c>
        return -E_NO_MEM;
ffffffffc0202694:	5571                	li	a0,-4
ffffffffc0202696:	b77d                	j	ffffffffc0202644 <page_insert+0x58>
ffffffffc0202698:	809ff0ef          	jal	ra,ffffffffc0201ea0 <pa2page.part.0>

ffffffffc020269c <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020269c:	00004797          	auipc	a5,0x4
ffffffffc02026a0:	02c78793          	addi	a5,a5,44 # ffffffffc02066c8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02026a4:	638c                	ld	a1,0(a5)
{
ffffffffc02026a6:	711d                	addi	sp,sp,-96
ffffffffc02026a8:	f05a                	sd	s6,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02026aa:	00004517          	auipc	a0,0x4
ffffffffc02026ae:	1c650513          	addi	a0,a0,454 # ffffffffc0206870 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc02026b2:	000a8b17          	auipc	s6,0xa8
ffffffffc02026b6:	066b0b13          	addi	s6,s6,102 # ffffffffc02aa718 <pmm_manager>
{
ffffffffc02026ba:	ec86                	sd	ra,88(sp)
ffffffffc02026bc:	e0ca                	sd	s2,64(sp)
ffffffffc02026be:	fc4e                	sd	s3,56(sp)
ffffffffc02026c0:	e8a2                	sd	s0,80(sp)
ffffffffc02026c2:	e4a6                	sd	s1,72(sp)
ffffffffc02026c4:	f852                	sd	s4,48(sp)
ffffffffc02026c6:	f456                	sd	s5,40(sp)
ffffffffc02026c8:	ec5e                	sd	s7,24(sp)
ffffffffc02026ca:	e862                	sd	s8,16(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02026cc:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02026d0:	ac5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02026d4:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02026d8:	000a8997          	auipc	s3,0xa8
ffffffffc02026dc:	04898993          	addi	s3,s3,72 # ffffffffc02aa720 <va_pa_offset>
    pmm_manager->init();
ffffffffc02026e0:	679c                	ld	a5,8(a5)
ffffffffc02026e2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02026e4:	57f5                	li	a5,-3
ffffffffc02026e6:	07fa                	slli	a5,a5,0x1e
ffffffffc02026e8:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02026ec:	aaefe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc02026f0:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02026f2:	ab2fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02026f6:	220507e3          	beqz	a0,ffffffffc0203124 <pmm_init+0xa88>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02026fa:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02026fc:	00004517          	auipc	a0,0x4
ffffffffc0202700:	1ac50513          	addi	a0,a0,428 # ffffffffc02068a8 <default_pmm_manager+0x1e0>
ffffffffc0202704:	a91fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202708:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020270c:	fff40693          	addi	a3,s0,-1
ffffffffc0202710:	864a                	mv	a2,s2
ffffffffc0202712:	85a6                	mv	a1,s1
ffffffffc0202714:	00004517          	auipc	a0,0x4
ffffffffc0202718:	1ac50513          	addi	a0,a0,428 # ffffffffc02068c0 <default_pmm_manager+0x1f8>
ffffffffc020271c:	a79fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202720:	c8000737          	lui	a4,0xc8000
ffffffffc0202724:	87a2                	mv	a5,s0
ffffffffc0202726:	56876363          	bltu	a4,s0,ffffffffc0202c8c <pmm_init+0x5f0>
ffffffffc020272a:	757d                	lui	a0,0xfffff
ffffffffc020272c:	000a9617          	auipc	a2,0xa9
ffffffffc0202730:	01760613          	addi	a2,a2,23 # ffffffffc02ab743 <end+0xfff>
ffffffffc0202734:	8e69                	and	a2,a2,a0
ffffffffc0202736:	000a8497          	auipc	s1,0xa8
ffffffffc020273a:	fd248493          	addi	s1,s1,-46 # ffffffffc02aa708 <npage>
ffffffffc020273e:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202742:	000a8b97          	auipc	s7,0xa8
ffffffffc0202746:	fceb8b93          	addi	s7,s7,-50 # ffffffffc02aa710 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020274a:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020274c:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202750:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202754:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202756:	02f50863          	beq	a0,a5,ffffffffc0202786 <pmm_init+0xea>
ffffffffc020275a:	4781                	li	a5,0
ffffffffc020275c:	4585                	li	a1,1
ffffffffc020275e:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202762:	00679513          	slli	a0,a5,0x6
ffffffffc0202766:	9532                	add	a0,a0,a2
ffffffffc0202768:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd548c4>
ffffffffc020276c:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202770:	6088                	ld	a0,0(s1)
ffffffffc0202772:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202774:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202778:	00d50733          	add	a4,a0,a3
ffffffffc020277c:	fee7e3e3          	bltu	a5,a4,ffffffffc0202762 <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202780:	071a                	slli	a4,a4,0x6
ffffffffc0202782:	00e606b3          	add	a3,a2,a4
ffffffffc0202786:	c02007b7          	lui	a5,0xc0200
ffffffffc020278a:	30f6eee3          	bltu	a3,a5,ffffffffc02032a6 <pmm_init+0xc0a>
ffffffffc020278e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202792:	77fd                	lui	a5,0xfffff
ffffffffc0202794:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202796:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202798:	5286ed63          	bltu	a3,s0,ffffffffc0202cd2 <pmm_init+0x636>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020279c:	00004517          	auipc	a0,0x4
ffffffffc02027a0:	14c50513          	addi	a0,a0,332 # ffffffffc02068e8 <default_pmm_manager+0x220>
ffffffffc02027a4:	9f1fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02027a8:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02027ac:	000a8917          	auipc	s2,0xa8
ffffffffc02027b0:	f5490913          	addi	s2,s2,-172 # ffffffffc02aa700 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02027b4:	7b9c                	ld	a5,48(a5)
ffffffffc02027b6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02027b8:	00004517          	auipc	a0,0x4
ffffffffc02027bc:	14850513          	addi	a0,a0,328 # ffffffffc0206900 <default_pmm_manager+0x238>
ffffffffc02027c0:	9d5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02027c4:	00008697          	auipc	a3,0x8
ffffffffc02027c8:	83c68693          	addi	a3,a3,-1988 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc02027cc:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02027d0:	c02007b7          	lui	a5,0xc0200
ffffffffc02027d4:	2af6ede3          	bltu	a3,a5,ffffffffc020328e <pmm_init+0xbf2>
ffffffffc02027d8:	0009b783          	ld	a5,0(s3)
ffffffffc02027dc:	8e9d                	sub	a3,a3,a5
ffffffffc02027de:	000a8797          	auipc	a5,0xa8
ffffffffc02027e2:	f0d7bd23          	sd	a3,-230(a5) # ffffffffc02aa6f8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02027e6:	100027f3          	csrr	a5,sstatus
ffffffffc02027ea:	8b89                	andi	a5,a5,2
ffffffffc02027ec:	4c079963          	bnez	a5,ffffffffc0202cbe <pmm_init+0x622>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027f0:	000b3783          	ld	a5,0(s6)
ffffffffc02027f4:	779c                	ld	a5,40(a5)
ffffffffc02027f6:	9782                	jalr	a5
ffffffffc02027f8:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027fa:	6098                	ld	a4,0(s1)
ffffffffc02027fc:	c80007b7          	lui	a5,0xc8000
ffffffffc0202800:	83b1                	srli	a5,a5,0xc
ffffffffc0202802:	68e7e563          	bltu	a5,a4,ffffffffc0202e8c <pmm_init+0x7f0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202806:	00093503          	ld	a0,0(s2)
ffffffffc020280a:	66050163          	beqz	a0,ffffffffc0202e6c <pmm_init+0x7d0>
ffffffffc020280e:	03451793          	slli	a5,a0,0x34
ffffffffc0202812:	64079d63          	bnez	a5,ffffffffc0202e6c <pmm_init+0x7d0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202816:	4601                	li	a2,0
ffffffffc0202818:	4581                	li	a1,0
ffffffffc020281a:	99fff0ef          	jal	ra,ffffffffc02021b8 <get_page>
ffffffffc020281e:	62051763          	bnez	a0,ffffffffc0202e4c <pmm_init+0x7b0>
ffffffffc0202822:	100027f3          	csrr	a5,sstatus
ffffffffc0202826:	8b89                	andi	a5,a5,2
ffffffffc0202828:	48079063          	bnez	a5,ffffffffc0202ca8 <pmm_init+0x60c>
        page = pmm_manager->alloc_pages(n);
ffffffffc020282c:	000b3783          	ld	a5,0(s6)
ffffffffc0202830:	4505                	li	a0,1
ffffffffc0202832:	6f9c                	ld	a5,24(a5)
ffffffffc0202834:	9782                	jalr	a5
ffffffffc0202836:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202838:	00093503          	ld	a0,0(s2)
ffffffffc020283c:	4681                	li	a3,0
ffffffffc020283e:	4601                	li	a2,0
ffffffffc0202840:	85d2                	mv	a1,s4
ffffffffc0202842:	dabff0ef          	jal	ra,ffffffffc02025ec <page_insert>
ffffffffc0202846:	28051ce3          	bnez	a0,ffffffffc02032de <pmm_init+0xc42>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020284a:	00093503          	ld	a0,0(s2)
ffffffffc020284e:	4601                	li	a2,0
ffffffffc0202850:	4581                	li	a1,0
ffffffffc0202852:	f3eff0ef          	jal	ra,ffffffffc0201f90 <get_pte>
ffffffffc0202856:	260504e3          	beqz	a0,ffffffffc02032be <pmm_init+0xc22>
    assert(pte2page(*ptep) == p1);
ffffffffc020285a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc020285c:	0017f713          	andi	a4,a5,1
ffffffffc0202860:	5c070463          	beqz	a4,ffffffffc0202e28 <pmm_init+0x78c>
    if (PPN(pa) >= npage)
ffffffffc0202864:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202866:	078a                	slli	a5,a5,0x2
ffffffffc0202868:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020286a:	5ae7fd63          	bgeu	a5,a4,ffffffffc0202e24 <pmm_init+0x788>
    return &pages[PPN(pa) - nbase];
ffffffffc020286e:	000bb683          	ld	a3,0(s7)
ffffffffc0202872:	fff80637          	lui	a2,0xfff80
ffffffffc0202876:	97b2                	add	a5,a5,a2
ffffffffc0202878:	079a                	slli	a5,a5,0x6
ffffffffc020287a:	97b6                	add	a5,a5,a3
ffffffffc020287c:	16fa19e3          	bne	s4,a5,ffffffffc02031ee <pmm_init+0xb52>
    assert(page_ref(p1) == 1);
ffffffffc0202880:	000a2683          	lw	a3,0(s4) # ffffffffffe00000 <end+0x3fb558bc>
ffffffffc0202884:	4785                	li	a5,1
ffffffffc0202886:	14f694e3          	bne	a3,a5,ffffffffc02031ce <pmm_init+0xb32>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020288a:	00093503          	ld	a0,0(s2)
ffffffffc020288e:	77fd                	lui	a5,0xfffff
ffffffffc0202890:	6114                	ld	a3,0(a0)
ffffffffc0202892:	068a                	slli	a3,a3,0x2
ffffffffc0202894:	8efd                	and	a3,a3,a5
ffffffffc0202896:	00c6d613          	srli	a2,a3,0xc
ffffffffc020289a:	10e67ee3          	bgeu	a2,a4,ffffffffc02031b6 <pmm_init+0xb1a>
ffffffffc020289e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02028a2:	96e2                	add	a3,a3,s8
ffffffffc02028a4:	0006ba83          	ld	s5,0(a3)
ffffffffc02028a8:	0a8a                	slli	s5,s5,0x2
ffffffffc02028aa:	00fafab3          	and	s5,s5,a5
ffffffffc02028ae:	00cad793          	srli	a5,s5,0xc
ffffffffc02028b2:	0ee7f5e3          	bgeu	a5,a4,ffffffffc020319c <pmm_init+0xb00>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028b6:	4601                	li	a2,0
ffffffffc02028b8:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02028ba:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028bc:	ed4ff0ef          	jal	ra,ffffffffc0201f90 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02028c0:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028c2:	57551563          	bne	a0,s5,ffffffffc0202e2c <pmm_init+0x790>
ffffffffc02028c6:	100027f3          	csrr	a5,sstatus
ffffffffc02028ca:	8b89                	andi	a5,a5,2
ffffffffc02028cc:	3c079363          	bnez	a5,ffffffffc0202c92 <pmm_init+0x5f6>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028d0:	000b3783          	ld	a5,0(s6)
ffffffffc02028d4:	4505                	li	a0,1
ffffffffc02028d6:	6f9c                	ld	a5,24(a5)
ffffffffc02028d8:	9782                	jalr	a5
ffffffffc02028da:	8aaa                	mv	s5,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02028dc:	00093503          	ld	a0,0(s2)
ffffffffc02028e0:	46d1                	li	a3,20
ffffffffc02028e2:	6605                	lui	a2,0x1
ffffffffc02028e4:	85d6                	mv	a1,s5
ffffffffc02028e6:	d07ff0ef          	jal	ra,ffffffffc02025ec <page_insert>
ffffffffc02028ea:	080519e3          	bnez	a0,ffffffffc020317c <pmm_init+0xae0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02028ee:	00093503          	ld	a0,0(s2)
ffffffffc02028f2:	4601                	li	a2,0
ffffffffc02028f4:	6585                	lui	a1,0x1
ffffffffc02028f6:	e9aff0ef          	jal	ra,ffffffffc0201f90 <get_pte>
ffffffffc02028fa:	060501e3          	beqz	a0,ffffffffc020315c <pmm_init+0xac0>
    assert(*ptep & PTE_U);
ffffffffc02028fe:	611c                	ld	a5,0(a0)
ffffffffc0202900:	0107f713          	andi	a4,a5,16
ffffffffc0202904:	000700e3          	beqz	a4,ffffffffc0203104 <pmm_init+0xa68>
    assert(*ptep & PTE_W);
ffffffffc0202908:	8b91                	andi	a5,a5,4
ffffffffc020290a:	7c078d63          	beqz	a5,ffffffffc02030e4 <pmm_init+0xa48>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020290e:	00093503          	ld	a0,0(s2)
ffffffffc0202912:	611c                	ld	a5,0(a0)
ffffffffc0202914:	8bc1                	andi	a5,a5,16
ffffffffc0202916:	7a078763          	beqz	a5,ffffffffc02030c4 <pmm_init+0xa28>
    assert(page_ref(p2) == 1);
ffffffffc020291a:	000aa703          	lw	a4,0(s5)
ffffffffc020291e:	4785                	li	a5,1
ffffffffc0202920:	78f71263          	bne	a4,a5,ffffffffc02030a4 <pmm_init+0xa08>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202924:	4681                	li	a3,0
ffffffffc0202926:	6605                	lui	a2,0x1
ffffffffc0202928:	85d2                	mv	a1,s4
ffffffffc020292a:	cc3ff0ef          	jal	ra,ffffffffc02025ec <page_insert>
ffffffffc020292e:	74051b63          	bnez	a0,ffffffffc0203084 <pmm_init+0x9e8>
    assert(page_ref(p1) == 2);
ffffffffc0202932:	000a2703          	lw	a4,0(s4)
ffffffffc0202936:	4789                	li	a5,2
ffffffffc0202938:	72f71663          	bne	a4,a5,ffffffffc0203064 <pmm_init+0x9c8>
    assert(page_ref(p2) == 0);
ffffffffc020293c:	000aa783          	lw	a5,0(s5)
ffffffffc0202940:	70079263          	bnez	a5,ffffffffc0203044 <pmm_init+0x9a8>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202944:	00093503          	ld	a0,0(s2)
ffffffffc0202948:	4601                	li	a2,0
ffffffffc020294a:	6585                	lui	a1,0x1
ffffffffc020294c:	e44ff0ef          	jal	ra,ffffffffc0201f90 <get_pte>
ffffffffc0202950:	6c050a63          	beqz	a0,ffffffffc0203024 <pmm_init+0x988>
    assert(pte2page(*ptep) == p1);
ffffffffc0202954:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202956:	00177793          	andi	a5,a4,1
ffffffffc020295a:	4c078763          	beqz	a5,ffffffffc0202e28 <pmm_init+0x78c>
    if (PPN(pa) >= npage)
ffffffffc020295e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202960:	00271793          	slli	a5,a4,0x2
ffffffffc0202964:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202966:	4ad7ff63          	bgeu	a5,a3,ffffffffc0202e24 <pmm_init+0x788>
    return &pages[PPN(pa) - nbase];
ffffffffc020296a:	000bb683          	ld	a3,0(s7)
ffffffffc020296e:	fff80637          	lui	a2,0xfff80
ffffffffc0202972:	97b2                	add	a5,a5,a2
ffffffffc0202974:	079a                	slli	a5,a5,0x6
ffffffffc0202976:	97b6                	add	a5,a5,a3
ffffffffc0202978:	68fa1663          	bne	s4,a5,ffffffffc0203004 <pmm_init+0x968>
    assert((*ptep & PTE_U) == 0);
ffffffffc020297c:	8b41                	andi	a4,a4,16
ffffffffc020297e:	66071363          	bnez	a4,ffffffffc0202fe4 <pmm_init+0x948>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202982:	00093c03          	ld	s8,0(s2)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202986:	4601                	li	a2,0
ffffffffc0202988:	4581                	li	a1,0
ffffffffc020298a:	8562                	mv	a0,s8
ffffffffc020298c:	e04ff0ef          	jal	ra,ffffffffc0201f90 <get_pte>
ffffffffc0202990:	862a                	mv	a2,a0
    if (ptep != NULL)
ffffffffc0202992:	c509                	beqz	a0,ffffffffc020299c <pmm_init+0x300>
        page_remove_pte(pgdir, la, ptep);
ffffffffc0202994:	4581                	li	a1,0
ffffffffc0202996:	8562                	mv	a0,s8
ffffffffc0202998:	875ff0ef          	jal	ra,ffffffffc020220c <page_remove_pte>
    assert(page_ref(p1) == 1);
ffffffffc020299c:	000a2703          	lw	a4,0(s4)
ffffffffc02029a0:	4785                	li	a5,1
ffffffffc02029a2:	62f71163          	bne	a4,a5,ffffffffc0202fc4 <pmm_init+0x928>
    assert(page_ref(p2) == 0);
ffffffffc02029a6:	000aa783          	lw	a5,0(s5)
ffffffffc02029aa:	5e079d63          	bnez	a5,ffffffffc0202fa4 <pmm_init+0x908>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc02029ae:	00093c03          	ld	s8,0(s2)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02029b2:	4601                	li	a2,0
ffffffffc02029b4:	6585                	lui	a1,0x1
ffffffffc02029b6:	8562                	mv	a0,s8
ffffffffc02029b8:	dd8ff0ef          	jal	ra,ffffffffc0201f90 <get_pte>
ffffffffc02029bc:	862a                	mv	a2,a0
    if (ptep != NULL)
ffffffffc02029be:	c509                	beqz	a0,ffffffffc02029c8 <pmm_init+0x32c>
        page_remove_pte(pgdir, la, ptep);
ffffffffc02029c0:	6585                	lui	a1,0x1
ffffffffc02029c2:	8562                	mv	a0,s8
ffffffffc02029c4:	849ff0ef          	jal	ra,ffffffffc020220c <page_remove_pte>
    assert(page_ref(p1) == 0);
ffffffffc02029c8:	000a2783          	lw	a5,0(s4)
ffffffffc02029cc:	52079c63          	bnez	a5,ffffffffc0202f04 <pmm_init+0x868>
    assert(page_ref(p2) == 0);
ffffffffc02029d0:	000aa783          	lw	a5,0(s5)
ffffffffc02029d4:	50079863          	bnez	a5,ffffffffc0202ee4 <pmm_init+0x848>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc02029d8:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02029dc:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02029de:	000a3683          	ld	a3,0(s4)
ffffffffc02029e2:	068a                	slli	a3,a3,0x2
ffffffffc02029e4:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02029e6:	42b6ff63          	bgeu	a3,a1,ffffffffc0202e24 <pmm_init+0x788>
    return &pages[PPN(pa) - nbase];
ffffffffc02029ea:	fff807b7          	lui	a5,0xfff80
ffffffffc02029ee:	000bb503          	ld	a0,0(s7)
ffffffffc02029f2:	96be                	add	a3,a3,a5
ffffffffc02029f4:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc02029f6:	00d507b3          	add	a5,a0,a3
ffffffffc02029fa:	4398                	lw	a4,0(a5)
ffffffffc02029fc:	4785                	li	a5,1
ffffffffc02029fe:	4cf71363          	bne	a4,a5,ffffffffc0202ec4 <pmm_init+0x828>
    return page - pages + nbase;
ffffffffc0202a02:	8699                	srai	a3,a3,0x6
ffffffffc0202a04:	00080637          	lui	a2,0x80
ffffffffc0202a08:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202a0a:	00c69713          	slli	a4,a3,0xc
ffffffffc0202a0e:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a10:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a12:	48b77d63          	bgeu	a4,a1,ffffffffc0202eac <pmm_init+0x810>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202a16:	0009b703          	ld	a4,0(s3)
ffffffffc0202a1a:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a1c:	629c                	ld	a5,0(a3)
ffffffffc0202a1e:	078a                	slli	a5,a5,0x2
ffffffffc0202a20:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a22:	40b7f163          	bgeu	a5,a1,ffffffffc0202e24 <pmm_init+0x788>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a26:	8f91                	sub	a5,a5,a2
ffffffffc0202a28:	079a                	slli	a5,a5,0x6
ffffffffc0202a2a:	953e                	add	a0,a0,a5
ffffffffc0202a2c:	100027f3          	csrr	a5,sstatus
ffffffffc0202a30:	8b89                	andi	a5,a5,2
ffffffffc0202a32:	30079863          	bnez	a5,ffffffffc0202d42 <pmm_init+0x6a6>
        pmm_manager->free_pages(base, n);
ffffffffc0202a36:	000b3783          	ld	a5,0(s6)
ffffffffc0202a3a:	4585                	li	a1,1
ffffffffc0202a3c:	739c                	ld	a5,32(a5)
ffffffffc0202a3e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a40:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202a44:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a46:	078a                	slli	a5,a5,0x2
ffffffffc0202a48:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a4a:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202e24 <pmm_init+0x788>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a4e:	000bb503          	ld	a0,0(s7)
ffffffffc0202a52:	fff80737          	lui	a4,0xfff80
ffffffffc0202a56:	97ba                	add	a5,a5,a4
ffffffffc0202a58:	079a                	slli	a5,a5,0x6
ffffffffc0202a5a:	953e                	add	a0,a0,a5
ffffffffc0202a5c:	100027f3          	csrr	a5,sstatus
ffffffffc0202a60:	8b89                	andi	a5,a5,2
ffffffffc0202a62:	2c079463          	bnez	a5,ffffffffc0202d2a <pmm_init+0x68e>
ffffffffc0202a66:	000b3783          	ld	a5,0(s6)
ffffffffc0202a6a:	4585                	li	a1,1
ffffffffc0202a6c:	739c                	ld	a5,32(a5)
ffffffffc0202a6e:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202a70:	00093783          	ld	a5,0(s2)
ffffffffc0202a74:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fcd58bc>
    asm volatile("sfence.vma");
ffffffffc0202a78:	12000073          	sfence.vma
ffffffffc0202a7c:	100027f3          	csrr	a5,sstatus
ffffffffc0202a80:	8b89                	andi	a5,a5,2
ffffffffc0202a82:	28079a63          	bnez	a5,ffffffffc0202d16 <pmm_init+0x67a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a86:	000b3783          	ld	a5,0(s6)
ffffffffc0202a8a:	779c                	ld	a5,40(a5)
ffffffffc0202a8c:	9782                	jalr	a5
ffffffffc0202a8e:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202a90:	4b441a63          	bne	s0,s4,ffffffffc0202f44 <pmm_init+0x8a8>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202a94:	00004517          	auipc	a0,0x4
ffffffffc0202a98:	19450513          	addi	a0,a0,404 # ffffffffc0206c28 <default_pmm_manager+0x560>
ffffffffc0202a9c:	ef8fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202aa0:	100027f3          	csrr	a5,sstatus
ffffffffc0202aa4:	8b89                	andi	a5,a5,2
ffffffffc0202aa6:	24079e63          	bnez	a5,ffffffffc0202d02 <pmm_init+0x666>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202aaa:	000b3783          	ld	a5,0(s6)
ffffffffc0202aae:	779c                	ld	a5,40(a5)
ffffffffc0202ab0:	9782                	jalr	a5
ffffffffc0202ab2:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202ab4:	6098                	ld	a4,0(s1)
ffffffffc0202ab6:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202aba:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202abc:	00c71793          	slli	a5,a4,0xc
ffffffffc0202ac0:	6a05                	lui	s4,0x1
ffffffffc0202ac2:	02f47c63          	bgeu	s0,a5,ffffffffc0202afa <pmm_init+0x45e>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ac6:	00c45793          	srli	a5,s0,0xc
ffffffffc0202aca:	00093503          	ld	a0,0(s2)
ffffffffc0202ace:	2ee7fe63          	bgeu	a5,a4,ffffffffc0202dca <pmm_init+0x72e>
ffffffffc0202ad2:	0009b583          	ld	a1,0(s3)
ffffffffc0202ad6:	4601                	li	a2,0
ffffffffc0202ad8:	95a2                	add	a1,a1,s0
ffffffffc0202ada:	cb6ff0ef          	jal	ra,ffffffffc0201f90 <get_pte>
ffffffffc0202ade:	32050363          	beqz	a0,ffffffffc0202e04 <pmm_init+0x768>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ae2:	611c                	ld	a5,0(a0)
ffffffffc0202ae4:	078a                	slli	a5,a5,0x2
ffffffffc0202ae6:	0157f7b3          	and	a5,a5,s5
ffffffffc0202aea:	2e879d63          	bne	a5,s0,ffffffffc0202de4 <pmm_init+0x748>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202aee:	6098                	ld	a4,0(s1)
ffffffffc0202af0:	9452                	add	s0,s0,s4
ffffffffc0202af2:	00c71793          	slli	a5,a4,0xc
ffffffffc0202af6:	fcf468e3          	bltu	s0,a5,ffffffffc0202ac6 <pmm_init+0x42a>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202afa:	00093783          	ld	a5,0(s2)
ffffffffc0202afe:	639c                	ld	a5,0(a5)
ffffffffc0202b00:	42079263          	bnez	a5,ffffffffc0202f24 <pmm_init+0x888>
ffffffffc0202b04:	100027f3          	csrr	a5,sstatus
ffffffffc0202b08:	8b89                	andi	a5,a5,2
ffffffffc0202b0a:	24079863          	bnez	a5,ffffffffc0202d5a <pmm_init+0x6be>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b0e:	000b3783          	ld	a5,0(s6)
ffffffffc0202b12:	4505                	li	a0,1
ffffffffc0202b14:	6f9c                	ld	a5,24(a5)
ffffffffc0202b16:	9782                	jalr	a5
ffffffffc0202b18:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202b1a:	00093503          	ld	a0,0(s2)
ffffffffc0202b1e:	4699                	li	a3,6
ffffffffc0202b20:	10000613          	li	a2,256
ffffffffc0202b24:	85d2                	mv	a1,s4
ffffffffc0202b26:	ac7ff0ef          	jal	ra,ffffffffc02025ec <page_insert>
ffffffffc0202b2a:	44051d63          	bnez	a0,ffffffffc0202f84 <pmm_init+0x8e8>
    assert(page_ref(p) == 1);
ffffffffc0202b2e:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc0202b32:	4785                	li	a5,1
ffffffffc0202b34:	42f71863          	bne	a4,a5,ffffffffc0202f64 <pmm_init+0x8c8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202b38:	00093503          	ld	a0,0(s2)
ffffffffc0202b3c:	6405                	lui	s0,0x1
ffffffffc0202b3e:	4699                	li	a3,6
ffffffffc0202b40:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8aa8>
ffffffffc0202b44:	85d2                	mv	a1,s4
ffffffffc0202b46:	aa7ff0ef          	jal	ra,ffffffffc02025ec <page_insert>
ffffffffc0202b4a:	72051263          	bnez	a0,ffffffffc020326e <pmm_init+0xbd2>
    assert(page_ref(p) == 2);
ffffffffc0202b4e:	000a2703          	lw	a4,0(s4)
ffffffffc0202b52:	4789                	li	a5,2
ffffffffc0202b54:	6ef71d63          	bne	a4,a5,ffffffffc020324e <pmm_init+0xbb2>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202b58:	00004597          	auipc	a1,0x4
ffffffffc0202b5c:	21858593          	addi	a1,a1,536 # ffffffffc0206d70 <default_pmm_manager+0x6a8>
ffffffffc0202b60:	10000513          	li	a0,256
ffffffffc0202b64:	48b020ef          	jal	ra,ffffffffc02057ee <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202b68:	10040593          	addi	a1,s0,256
ffffffffc0202b6c:	10000513          	li	a0,256
ffffffffc0202b70:	491020ef          	jal	ra,ffffffffc0205800 <strcmp>
ffffffffc0202b74:	6a051d63          	bnez	a0,ffffffffc020322e <pmm_init+0xb92>
    return page - pages + nbase;
ffffffffc0202b78:	000bb683          	ld	a3,0(s7)
ffffffffc0202b7c:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202b80:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202b82:	40da06b3          	sub	a3,s4,a3
ffffffffc0202b86:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202b88:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202b8a:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202b8c:	8031                	srli	s0,s0,0xc
ffffffffc0202b8e:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b92:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b94:	30f77c63          	bgeu	a4,a5,ffffffffc0202eac <pmm_init+0x810>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202b98:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202b9c:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202ba0:	96be                	add	a3,a3,a5
ffffffffc0202ba2:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ba6:	413020ef          	jal	ra,ffffffffc02057b8 <strlen>
ffffffffc0202baa:	66051263          	bnez	a0,ffffffffc020320e <pmm_init+0xb72>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202bae:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202bb2:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bb4:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd548bc>
ffffffffc0202bb8:	068a                	slli	a3,a3,0x2
ffffffffc0202bba:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bbc:	26f6f463          	bgeu	a3,a5,ffffffffc0202e24 <pmm_init+0x788>
    return KADDR(page2pa(page));
ffffffffc0202bc0:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bc2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bc4:	2ef47463          	bgeu	s0,a5,ffffffffc0202eac <pmm_init+0x810>
ffffffffc0202bc8:	0009b403          	ld	s0,0(s3)
ffffffffc0202bcc:	9436                	add	s0,s0,a3
ffffffffc0202bce:	100027f3          	csrr	a5,sstatus
ffffffffc0202bd2:	8b89                	andi	a5,a5,2
ffffffffc0202bd4:	1e079063          	bnez	a5,ffffffffc0202db4 <pmm_init+0x718>
        pmm_manager->free_pages(base, n);
ffffffffc0202bd8:	000b3783          	ld	a5,0(s6)
ffffffffc0202bdc:	4585                	li	a1,1
ffffffffc0202bde:	8552                	mv	a0,s4
ffffffffc0202be0:	739c                	ld	a5,32(a5)
ffffffffc0202be2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202be4:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202be6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202be8:	078a                	slli	a5,a5,0x2
ffffffffc0202bea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bec:	22e7fc63          	bgeu	a5,a4,ffffffffc0202e24 <pmm_init+0x788>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bf0:	000bb503          	ld	a0,0(s7)
ffffffffc0202bf4:	fff80737          	lui	a4,0xfff80
ffffffffc0202bf8:	97ba                	add	a5,a5,a4
ffffffffc0202bfa:	079a                	slli	a5,a5,0x6
ffffffffc0202bfc:	953e                	add	a0,a0,a5
ffffffffc0202bfe:	100027f3          	csrr	a5,sstatus
ffffffffc0202c02:	8b89                	andi	a5,a5,2
ffffffffc0202c04:	18079c63          	bnez	a5,ffffffffc0202d9c <pmm_init+0x700>
ffffffffc0202c08:	000b3783          	ld	a5,0(s6)
ffffffffc0202c0c:	4585                	li	a1,1
ffffffffc0202c0e:	739c                	ld	a5,32(a5)
ffffffffc0202c10:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c12:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202c16:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c18:	078a                	slli	a5,a5,0x2
ffffffffc0202c1a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c1c:	20e7f463          	bgeu	a5,a4,ffffffffc0202e24 <pmm_init+0x788>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c20:	000bb503          	ld	a0,0(s7)
ffffffffc0202c24:	fff80737          	lui	a4,0xfff80
ffffffffc0202c28:	97ba                	add	a5,a5,a4
ffffffffc0202c2a:	079a                	slli	a5,a5,0x6
ffffffffc0202c2c:	953e                	add	a0,a0,a5
ffffffffc0202c2e:	100027f3          	csrr	a5,sstatus
ffffffffc0202c32:	8b89                	andi	a5,a5,2
ffffffffc0202c34:	14079863          	bnez	a5,ffffffffc0202d84 <pmm_init+0x6e8>
ffffffffc0202c38:	000b3783          	ld	a5,0(s6)
ffffffffc0202c3c:	4585                	li	a1,1
ffffffffc0202c3e:	739c                	ld	a5,32(a5)
ffffffffc0202c40:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202c42:	00093783          	ld	a5,0(s2)
ffffffffc0202c46:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202c4a:	12000073          	sfence.vma
ffffffffc0202c4e:	100027f3          	csrr	a5,sstatus
ffffffffc0202c52:	8b89                	andi	a5,a5,2
ffffffffc0202c54:	10079e63          	bnez	a5,ffffffffc0202d70 <pmm_init+0x6d4>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c58:	000b3783          	ld	a5,0(s6)
ffffffffc0202c5c:	779c                	ld	a5,40(a5)
ffffffffc0202c5e:	9782                	jalr	a5
ffffffffc0202c60:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202c62:	4c8c1d63          	bne	s8,s0,ffffffffc020313c <pmm_init+0xaa0>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202c66:	00004517          	auipc	a0,0x4
ffffffffc0202c6a:	18250513          	addi	a0,a0,386 # ffffffffc0206de8 <default_pmm_manager+0x720>
ffffffffc0202c6e:	d26fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202c72:	6446                	ld	s0,80(sp)
ffffffffc0202c74:	60e6                	ld	ra,88(sp)
ffffffffc0202c76:	64a6                	ld	s1,72(sp)
ffffffffc0202c78:	6906                	ld	s2,64(sp)
ffffffffc0202c7a:	79e2                	ld	s3,56(sp)
ffffffffc0202c7c:	7a42                	ld	s4,48(sp)
ffffffffc0202c7e:	7aa2                	ld	s5,40(sp)
ffffffffc0202c80:	7b02                	ld	s6,32(sp)
ffffffffc0202c82:	6be2                	ld	s7,24(sp)
ffffffffc0202c84:	6c42                	ld	s8,16(sp)
ffffffffc0202c86:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc0202c88:	84eff06f          	j	ffffffffc0201cd6 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202c8c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202c90:	bc69                	j	ffffffffc020272a <pmm_init+0x8e>
        intr_disable();
ffffffffc0202c92:	d23fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c96:	000b3783          	ld	a5,0(s6)
ffffffffc0202c9a:	4505                	li	a0,1
ffffffffc0202c9c:	6f9c                	ld	a5,24(a5)
ffffffffc0202c9e:	9782                	jalr	a5
ffffffffc0202ca0:	8aaa                	mv	s5,a0
        intr_enable();
ffffffffc0202ca2:	d0dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ca6:	b91d                	j	ffffffffc02028dc <pmm_init+0x240>
        intr_disable();
ffffffffc0202ca8:	d0dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202cac:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb0:	4505                	li	a0,1
ffffffffc0202cb2:	6f9c                	ld	a5,24(a5)
ffffffffc0202cb4:	9782                	jalr	a5
ffffffffc0202cb6:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202cb8:	cf7fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202cbc:	beb5                	j	ffffffffc0202838 <pmm_init+0x19c>
        intr_disable();
ffffffffc0202cbe:	cf7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cc2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cc6:	779c                	ld	a5,40(a5)
ffffffffc0202cc8:	9782                	jalr	a5
ffffffffc0202cca:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202ccc:	ce3fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202cd0:	b62d                	j	ffffffffc02027fa <pmm_init+0x15e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202cd2:	6705                	lui	a4,0x1
ffffffffc0202cd4:	177d                	addi	a4,a4,-1
ffffffffc0202cd6:	96ba                	add	a3,a3,a4
ffffffffc0202cd8:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202cda:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202cde:	14a77363          	bgeu	a4,a0,ffffffffc0202e24 <pmm_init+0x788>
    pmm_manager->init_memmap(base, n);
ffffffffc0202ce2:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202ce6:	fff80537          	lui	a0,0xfff80
ffffffffc0202cea:	972a                	add	a4,a4,a0
ffffffffc0202cec:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202cee:	8c1d                	sub	s0,s0,a5
ffffffffc0202cf0:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202cf4:	00c45593          	srli	a1,s0,0xc
ffffffffc0202cf8:	9532                	add	a0,a0,a2
ffffffffc0202cfa:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202cfc:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d00:	bc71                	j	ffffffffc020279c <pmm_init+0x100>
        intr_disable();
ffffffffc0202d02:	cb3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d06:	000b3783          	ld	a5,0(s6)
ffffffffc0202d0a:	779c                	ld	a5,40(a5)
ffffffffc0202d0c:	9782                	jalr	a5
ffffffffc0202d0e:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d10:	c9ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d14:	b345                	j	ffffffffc0202ab4 <pmm_init+0x418>
        intr_disable();
ffffffffc0202d16:	c9ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d1a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d1e:	779c                	ld	a5,40(a5)
ffffffffc0202d20:	9782                	jalr	a5
ffffffffc0202d22:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d24:	c8bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d28:	b3a5                	j	ffffffffc0202a90 <pmm_init+0x3f4>
ffffffffc0202d2a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d2c:	c89fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d30:	000b3783          	ld	a5,0(s6)
ffffffffc0202d34:	6522                	ld	a0,8(sp)
ffffffffc0202d36:	4585                	li	a1,1
ffffffffc0202d38:	739c                	ld	a5,32(a5)
ffffffffc0202d3a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d3c:	c73fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d40:	bb05                	j	ffffffffc0202a70 <pmm_init+0x3d4>
ffffffffc0202d42:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d44:	c71fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d48:	000b3783          	ld	a5,0(s6)
ffffffffc0202d4c:	6522                	ld	a0,8(sp)
ffffffffc0202d4e:	4585                	li	a1,1
ffffffffc0202d50:	739c                	ld	a5,32(a5)
ffffffffc0202d52:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d54:	c5bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d58:	b1e5                	j	ffffffffc0202a40 <pmm_init+0x3a4>
        intr_disable();
ffffffffc0202d5a:	c5bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d5e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d62:	4505                	li	a0,1
ffffffffc0202d64:	6f9c                	ld	a5,24(a5)
ffffffffc0202d66:	9782                	jalr	a5
ffffffffc0202d68:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d6a:	c45fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d6e:	b375                	j	ffffffffc0202b1a <pmm_init+0x47e>
        intr_disable();
ffffffffc0202d70:	c45fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d74:	000b3783          	ld	a5,0(s6)
ffffffffc0202d78:	779c                	ld	a5,40(a5)
ffffffffc0202d7a:	9782                	jalr	a5
ffffffffc0202d7c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d7e:	c31fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d82:	b5c5                	j	ffffffffc0202c62 <pmm_init+0x5c6>
ffffffffc0202d84:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d86:	c2ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d8a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d8e:	6522                	ld	a0,8(sp)
ffffffffc0202d90:	4585                	li	a1,1
ffffffffc0202d92:	739c                	ld	a5,32(a5)
ffffffffc0202d94:	9782                	jalr	a5
        intr_enable();
ffffffffc0202d96:	c19fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d9a:	b565                	j	ffffffffc0202c42 <pmm_init+0x5a6>
ffffffffc0202d9c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d9e:	c17fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202da2:	000b3783          	ld	a5,0(s6)
ffffffffc0202da6:	6522                	ld	a0,8(sp)
ffffffffc0202da8:	4585                	li	a1,1
ffffffffc0202daa:	739c                	ld	a5,32(a5)
ffffffffc0202dac:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dae:	c01fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202db2:	b585                	j	ffffffffc0202c12 <pmm_init+0x576>
        intr_disable();
ffffffffc0202db4:	c01fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202db8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dbc:	4585                	li	a1,1
ffffffffc0202dbe:	8552                	mv	a0,s4
ffffffffc0202dc0:	739c                	ld	a5,32(a5)
ffffffffc0202dc2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dc4:	bebfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dc8:	bd31                	j	ffffffffc0202be4 <pmm_init+0x548>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202dca:	86a2                	mv	a3,s0
ffffffffc0202dcc:	00004617          	auipc	a2,0x4
ffffffffc0202dd0:	93460613          	addi	a2,a2,-1740 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc0202dd4:	26600593          	li	a1,614
ffffffffc0202dd8:	00004517          	auipc	a0,0x4
ffffffffc0202ddc:	a4050513          	addi	a0,a0,-1472 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202de0:	eaefd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202de4:	00004697          	auipc	a3,0x4
ffffffffc0202de8:	ea468693          	addi	a3,a3,-348 # ffffffffc0206c88 <default_pmm_manager+0x5c0>
ffffffffc0202dec:	00003617          	auipc	a2,0x3
ffffffffc0202df0:	52c60613          	addi	a2,a2,1324 # ffffffffc0206318 <commands+0x828>
ffffffffc0202df4:	26700593          	li	a1,615
ffffffffc0202df8:	00004517          	auipc	a0,0x4
ffffffffc0202dfc:	a2050513          	addi	a0,a0,-1504 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202e00:	e8efd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e04:	00004697          	auipc	a3,0x4
ffffffffc0202e08:	e4468693          	addi	a3,a3,-444 # ffffffffc0206c48 <default_pmm_manager+0x580>
ffffffffc0202e0c:	00003617          	auipc	a2,0x3
ffffffffc0202e10:	50c60613          	addi	a2,a2,1292 # ffffffffc0206318 <commands+0x828>
ffffffffc0202e14:	26600593          	li	a1,614
ffffffffc0202e18:	00004517          	auipc	a0,0x4
ffffffffc0202e1c:	a0050513          	addi	a0,a0,-1536 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202e20:	e6efd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202e24:	87cff0ef          	jal	ra,ffffffffc0201ea0 <pa2page.part.0>
ffffffffc0202e28:	894ff0ef          	jal	ra,ffffffffc0201ebc <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202e2c:	00004697          	auipc	a3,0x4
ffffffffc0202e30:	c1468693          	addi	a3,a3,-1004 # ffffffffc0206a40 <default_pmm_manager+0x378>
ffffffffc0202e34:	00003617          	auipc	a2,0x3
ffffffffc0202e38:	4e460613          	addi	a2,a2,1252 # ffffffffc0206318 <commands+0x828>
ffffffffc0202e3c:	23600593          	li	a1,566
ffffffffc0202e40:	00004517          	auipc	a0,0x4
ffffffffc0202e44:	9d850513          	addi	a0,a0,-1576 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202e48:	e46fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202e4c:	00004697          	auipc	a3,0x4
ffffffffc0202e50:	b3468693          	addi	a3,a3,-1228 # ffffffffc0206980 <default_pmm_manager+0x2b8>
ffffffffc0202e54:	00003617          	auipc	a2,0x3
ffffffffc0202e58:	4c460613          	addi	a2,a2,1220 # ffffffffc0206318 <commands+0x828>
ffffffffc0202e5c:	22900593          	li	a1,553
ffffffffc0202e60:	00004517          	auipc	a0,0x4
ffffffffc0202e64:	9b850513          	addi	a0,a0,-1608 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202e68:	e26fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202e6c:	00004697          	auipc	a3,0x4
ffffffffc0202e70:	ad468693          	addi	a3,a3,-1324 # ffffffffc0206940 <default_pmm_manager+0x278>
ffffffffc0202e74:	00003617          	auipc	a2,0x3
ffffffffc0202e78:	4a460613          	addi	a2,a2,1188 # ffffffffc0206318 <commands+0x828>
ffffffffc0202e7c:	22800593          	li	a1,552
ffffffffc0202e80:	00004517          	auipc	a0,0x4
ffffffffc0202e84:	99850513          	addi	a0,a0,-1640 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202e88:	e06fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202e8c:	00004697          	auipc	a3,0x4
ffffffffc0202e90:	a9468693          	addi	a3,a3,-1388 # ffffffffc0206920 <default_pmm_manager+0x258>
ffffffffc0202e94:	00003617          	auipc	a2,0x3
ffffffffc0202e98:	48460613          	addi	a2,a2,1156 # ffffffffc0206318 <commands+0x828>
ffffffffc0202e9c:	22700593          	li	a1,551
ffffffffc0202ea0:	00004517          	auipc	a0,0x4
ffffffffc0202ea4:	97850513          	addi	a0,a0,-1672 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202ea8:	de6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202eac:	00004617          	auipc	a2,0x4
ffffffffc0202eb0:	85460613          	addi	a2,a2,-1964 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc0202eb4:	07200593          	li	a1,114
ffffffffc0202eb8:	00004517          	auipc	a0,0x4
ffffffffc0202ebc:	87050513          	addi	a0,a0,-1936 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0202ec0:	dcefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202ec4:	00004697          	auipc	a3,0x4
ffffffffc0202ec8:	d0c68693          	addi	a3,a3,-756 # ffffffffc0206bd0 <default_pmm_manager+0x508>
ffffffffc0202ecc:	00003617          	auipc	a2,0x3
ffffffffc0202ed0:	44c60613          	addi	a2,a2,1100 # ffffffffc0206318 <commands+0x828>
ffffffffc0202ed4:	24f00593          	li	a1,591
ffffffffc0202ed8:	00004517          	auipc	a0,0x4
ffffffffc0202edc:	94050513          	addi	a0,a0,-1728 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202ee0:	daefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ee4:	00004697          	auipc	a3,0x4
ffffffffc0202ee8:	ca468693          	addi	a3,a3,-860 # ffffffffc0206b88 <default_pmm_manager+0x4c0>
ffffffffc0202eec:	00003617          	auipc	a2,0x3
ffffffffc0202ef0:	42c60613          	addi	a2,a2,1068 # ffffffffc0206318 <commands+0x828>
ffffffffc0202ef4:	24d00593          	li	a1,589
ffffffffc0202ef8:	00004517          	auipc	a0,0x4
ffffffffc0202efc:	92050513          	addi	a0,a0,-1760 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202f00:	d8efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f04:	00004697          	auipc	a3,0x4
ffffffffc0202f08:	cb468693          	addi	a3,a3,-844 # ffffffffc0206bb8 <default_pmm_manager+0x4f0>
ffffffffc0202f0c:	00003617          	auipc	a2,0x3
ffffffffc0202f10:	40c60613          	addi	a2,a2,1036 # ffffffffc0206318 <commands+0x828>
ffffffffc0202f14:	24c00593          	li	a1,588
ffffffffc0202f18:	00004517          	auipc	a0,0x4
ffffffffc0202f1c:	90050513          	addi	a0,a0,-1792 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202f20:	d6efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f24:	00004697          	auipc	a3,0x4
ffffffffc0202f28:	d7c68693          	addi	a3,a3,-644 # ffffffffc0206ca0 <default_pmm_manager+0x5d8>
ffffffffc0202f2c:	00003617          	auipc	a2,0x3
ffffffffc0202f30:	3ec60613          	addi	a2,a2,1004 # ffffffffc0206318 <commands+0x828>
ffffffffc0202f34:	26a00593          	li	a1,618
ffffffffc0202f38:	00004517          	auipc	a0,0x4
ffffffffc0202f3c:	8e050513          	addi	a0,a0,-1824 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202f40:	d4efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f44:	00004697          	auipc	a3,0x4
ffffffffc0202f48:	cbc68693          	addi	a3,a3,-836 # ffffffffc0206c00 <default_pmm_manager+0x538>
ffffffffc0202f4c:	00003617          	auipc	a2,0x3
ffffffffc0202f50:	3cc60613          	addi	a2,a2,972 # ffffffffc0206318 <commands+0x828>
ffffffffc0202f54:	25700593          	li	a1,599
ffffffffc0202f58:	00004517          	auipc	a0,0x4
ffffffffc0202f5c:	8c050513          	addi	a0,a0,-1856 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202f60:	d2efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202f64:	00004697          	auipc	a3,0x4
ffffffffc0202f68:	d9468693          	addi	a3,a3,-620 # ffffffffc0206cf8 <default_pmm_manager+0x630>
ffffffffc0202f6c:	00003617          	auipc	a2,0x3
ffffffffc0202f70:	3ac60613          	addi	a2,a2,940 # ffffffffc0206318 <commands+0x828>
ffffffffc0202f74:	26f00593          	li	a1,623
ffffffffc0202f78:	00004517          	auipc	a0,0x4
ffffffffc0202f7c:	8a050513          	addi	a0,a0,-1888 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202f80:	d0efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202f84:	00004697          	auipc	a3,0x4
ffffffffc0202f88:	d3468693          	addi	a3,a3,-716 # ffffffffc0206cb8 <default_pmm_manager+0x5f0>
ffffffffc0202f8c:	00003617          	auipc	a2,0x3
ffffffffc0202f90:	38c60613          	addi	a2,a2,908 # ffffffffc0206318 <commands+0x828>
ffffffffc0202f94:	26e00593          	li	a1,622
ffffffffc0202f98:	00004517          	auipc	a0,0x4
ffffffffc0202f9c:	88050513          	addi	a0,a0,-1920 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202fa0:	ceefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fa4:	00004697          	auipc	a3,0x4
ffffffffc0202fa8:	be468693          	addi	a3,a3,-1052 # ffffffffc0206b88 <default_pmm_manager+0x4c0>
ffffffffc0202fac:	00003617          	auipc	a2,0x3
ffffffffc0202fb0:	36c60613          	addi	a2,a2,876 # ffffffffc0206318 <commands+0x828>
ffffffffc0202fb4:	24900593          	li	a1,585
ffffffffc0202fb8:	00004517          	auipc	a0,0x4
ffffffffc0202fbc:	86050513          	addi	a0,a0,-1952 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202fc0:	ccefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202fc4:	00004697          	auipc	a3,0x4
ffffffffc0202fc8:	a6468693          	addi	a3,a3,-1436 # ffffffffc0206a28 <default_pmm_manager+0x360>
ffffffffc0202fcc:	00003617          	auipc	a2,0x3
ffffffffc0202fd0:	34c60613          	addi	a2,a2,844 # ffffffffc0206318 <commands+0x828>
ffffffffc0202fd4:	24800593          	li	a1,584
ffffffffc0202fd8:	00004517          	auipc	a0,0x4
ffffffffc0202fdc:	84050513          	addi	a0,a0,-1984 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0202fe0:	caefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202fe4:	00004697          	auipc	a3,0x4
ffffffffc0202fe8:	bbc68693          	addi	a3,a3,-1092 # ffffffffc0206ba0 <default_pmm_manager+0x4d8>
ffffffffc0202fec:	00003617          	auipc	a2,0x3
ffffffffc0202ff0:	32c60613          	addi	a2,a2,812 # ffffffffc0206318 <commands+0x828>
ffffffffc0202ff4:	24500593          	li	a1,581
ffffffffc0202ff8:	00004517          	auipc	a0,0x4
ffffffffc0202ffc:	82050513          	addi	a0,a0,-2016 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203000:	c8efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203004:	00004697          	auipc	a3,0x4
ffffffffc0203008:	a0c68693          	addi	a3,a3,-1524 # ffffffffc0206a10 <default_pmm_manager+0x348>
ffffffffc020300c:	00003617          	auipc	a2,0x3
ffffffffc0203010:	30c60613          	addi	a2,a2,780 # ffffffffc0206318 <commands+0x828>
ffffffffc0203014:	24400593          	li	a1,580
ffffffffc0203018:	00004517          	auipc	a0,0x4
ffffffffc020301c:	80050513          	addi	a0,a0,-2048 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203020:	c6efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203024:	00004697          	auipc	a3,0x4
ffffffffc0203028:	a8c68693          	addi	a3,a3,-1396 # ffffffffc0206ab0 <default_pmm_manager+0x3e8>
ffffffffc020302c:	00003617          	auipc	a2,0x3
ffffffffc0203030:	2ec60613          	addi	a2,a2,748 # ffffffffc0206318 <commands+0x828>
ffffffffc0203034:	24300593          	li	a1,579
ffffffffc0203038:	00003517          	auipc	a0,0x3
ffffffffc020303c:	7e050513          	addi	a0,a0,2016 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203040:	c4efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203044:	00004697          	auipc	a3,0x4
ffffffffc0203048:	b4468693          	addi	a3,a3,-1212 # ffffffffc0206b88 <default_pmm_manager+0x4c0>
ffffffffc020304c:	00003617          	auipc	a2,0x3
ffffffffc0203050:	2cc60613          	addi	a2,a2,716 # ffffffffc0206318 <commands+0x828>
ffffffffc0203054:	24200593          	li	a1,578
ffffffffc0203058:	00003517          	auipc	a0,0x3
ffffffffc020305c:	7c050513          	addi	a0,a0,1984 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203060:	c2efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203064:	00004697          	auipc	a3,0x4
ffffffffc0203068:	b0c68693          	addi	a3,a3,-1268 # ffffffffc0206b70 <default_pmm_manager+0x4a8>
ffffffffc020306c:	00003617          	auipc	a2,0x3
ffffffffc0203070:	2ac60613          	addi	a2,a2,684 # ffffffffc0206318 <commands+0x828>
ffffffffc0203074:	24100593          	li	a1,577
ffffffffc0203078:	00003517          	auipc	a0,0x3
ffffffffc020307c:	7a050513          	addi	a0,a0,1952 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203080:	c0efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203084:	00004697          	auipc	a3,0x4
ffffffffc0203088:	abc68693          	addi	a3,a3,-1348 # ffffffffc0206b40 <default_pmm_manager+0x478>
ffffffffc020308c:	00003617          	auipc	a2,0x3
ffffffffc0203090:	28c60613          	addi	a2,a2,652 # ffffffffc0206318 <commands+0x828>
ffffffffc0203094:	24000593          	li	a1,576
ffffffffc0203098:	00003517          	auipc	a0,0x3
ffffffffc020309c:	78050513          	addi	a0,a0,1920 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02030a0:	beefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02030a4:	00004697          	auipc	a3,0x4
ffffffffc02030a8:	a8468693          	addi	a3,a3,-1404 # ffffffffc0206b28 <default_pmm_manager+0x460>
ffffffffc02030ac:	00003617          	auipc	a2,0x3
ffffffffc02030b0:	26c60613          	addi	a2,a2,620 # ffffffffc0206318 <commands+0x828>
ffffffffc02030b4:	23e00593          	li	a1,574
ffffffffc02030b8:	00003517          	auipc	a0,0x3
ffffffffc02030bc:	76050513          	addi	a0,a0,1888 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02030c0:	bcefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02030c4:	00004697          	auipc	a3,0x4
ffffffffc02030c8:	a4468693          	addi	a3,a3,-1468 # ffffffffc0206b08 <default_pmm_manager+0x440>
ffffffffc02030cc:	00003617          	auipc	a2,0x3
ffffffffc02030d0:	24c60613          	addi	a2,a2,588 # ffffffffc0206318 <commands+0x828>
ffffffffc02030d4:	23d00593          	li	a1,573
ffffffffc02030d8:	00003517          	auipc	a0,0x3
ffffffffc02030dc:	74050513          	addi	a0,a0,1856 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02030e0:	baefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc02030e4:	00004697          	auipc	a3,0x4
ffffffffc02030e8:	a1468693          	addi	a3,a3,-1516 # ffffffffc0206af8 <default_pmm_manager+0x430>
ffffffffc02030ec:	00003617          	auipc	a2,0x3
ffffffffc02030f0:	22c60613          	addi	a2,a2,556 # ffffffffc0206318 <commands+0x828>
ffffffffc02030f4:	23c00593          	li	a1,572
ffffffffc02030f8:	00003517          	auipc	a0,0x3
ffffffffc02030fc:	72050513          	addi	a0,a0,1824 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203100:	b8efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203104:	00004697          	auipc	a3,0x4
ffffffffc0203108:	9e468693          	addi	a3,a3,-1564 # ffffffffc0206ae8 <default_pmm_manager+0x420>
ffffffffc020310c:	00003617          	auipc	a2,0x3
ffffffffc0203110:	20c60613          	addi	a2,a2,524 # ffffffffc0206318 <commands+0x828>
ffffffffc0203114:	23b00593          	li	a1,571
ffffffffc0203118:	00003517          	auipc	a0,0x3
ffffffffc020311c:	70050513          	addi	a0,a0,1792 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203120:	b6efd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203124:	00003617          	auipc	a2,0x3
ffffffffc0203128:	76460613          	addi	a2,a2,1892 # ffffffffc0206888 <default_pmm_manager+0x1c0>
ffffffffc020312c:	06500593          	li	a1,101
ffffffffc0203130:	00003517          	auipc	a0,0x3
ffffffffc0203134:	6e850513          	addi	a0,a0,1768 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203138:	b56fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020313c:	00004697          	auipc	a3,0x4
ffffffffc0203140:	ac468693          	addi	a3,a3,-1340 # ffffffffc0206c00 <default_pmm_manager+0x538>
ffffffffc0203144:	00003617          	auipc	a2,0x3
ffffffffc0203148:	1d460613          	addi	a2,a2,468 # ffffffffc0206318 <commands+0x828>
ffffffffc020314c:	28100593          	li	a1,641
ffffffffc0203150:	00003517          	auipc	a0,0x3
ffffffffc0203154:	6c850513          	addi	a0,a0,1736 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203158:	b36fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020315c:	00004697          	auipc	a3,0x4
ffffffffc0203160:	95468693          	addi	a3,a3,-1708 # ffffffffc0206ab0 <default_pmm_manager+0x3e8>
ffffffffc0203164:	00003617          	auipc	a2,0x3
ffffffffc0203168:	1b460613          	addi	a2,a2,436 # ffffffffc0206318 <commands+0x828>
ffffffffc020316c:	23a00593          	li	a1,570
ffffffffc0203170:	00003517          	auipc	a0,0x3
ffffffffc0203174:	6a850513          	addi	a0,a0,1704 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203178:	b16fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020317c:	00004697          	auipc	a3,0x4
ffffffffc0203180:	8f468693          	addi	a3,a3,-1804 # ffffffffc0206a70 <default_pmm_manager+0x3a8>
ffffffffc0203184:	00003617          	auipc	a2,0x3
ffffffffc0203188:	19460613          	addi	a2,a2,404 # ffffffffc0206318 <commands+0x828>
ffffffffc020318c:	23900593          	li	a1,569
ffffffffc0203190:	00003517          	auipc	a0,0x3
ffffffffc0203194:	68850513          	addi	a0,a0,1672 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203198:	af6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020319c:	86d6                	mv	a3,s5
ffffffffc020319e:	00003617          	auipc	a2,0x3
ffffffffc02031a2:	56260613          	addi	a2,a2,1378 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc02031a6:	23500593          	li	a1,565
ffffffffc02031aa:	00003517          	auipc	a0,0x3
ffffffffc02031ae:	66e50513          	addi	a0,a0,1646 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02031b2:	adcfd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02031b6:	00003617          	auipc	a2,0x3
ffffffffc02031ba:	54a60613          	addi	a2,a2,1354 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc02031be:	23400593          	li	a1,564
ffffffffc02031c2:	00003517          	auipc	a0,0x3
ffffffffc02031c6:	65650513          	addi	a0,a0,1622 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02031ca:	ac4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02031ce:	00004697          	auipc	a3,0x4
ffffffffc02031d2:	85a68693          	addi	a3,a3,-1958 # ffffffffc0206a28 <default_pmm_manager+0x360>
ffffffffc02031d6:	00003617          	auipc	a2,0x3
ffffffffc02031da:	14260613          	addi	a2,a2,322 # ffffffffc0206318 <commands+0x828>
ffffffffc02031de:	23200593          	li	a1,562
ffffffffc02031e2:	00003517          	auipc	a0,0x3
ffffffffc02031e6:	63650513          	addi	a0,a0,1590 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02031ea:	aa4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02031ee:	00004697          	auipc	a3,0x4
ffffffffc02031f2:	82268693          	addi	a3,a3,-2014 # ffffffffc0206a10 <default_pmm_manager+0x348>
ffffffffc02031f6:	00003617          	auipc	a2,0x3
ffffffffc02031fa:	12260613          	addi	a2,a2,290 # ffffffffc0206318 <commands+0x828>
ffffffffc02031fe:	23100593          	li	a1,561
ffffffffc0203202:	00003517          	auipc	a0,0x3
ffffffffc0203206:	61650513          	addi	a0,a0,1558 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc020320a:	a84fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020320e:	00004697          	auipc	a3,0x4
ffffffffc0203212:	bb268693          	addi	a3,a3,-1102 # ffffffffc0206dc0 <default_pmm_manager+0x6f8>
ffffffffc0203216:	00003617          	auipc	a2,0x3
ffffffffc020321a:	10260613          	addi	a2,a2,258 # ffffffffc0206318 <commands+0x828>
ffffffffc020321e:	27800593          	li	a1,632
ffffffffc0203222:	00003517          	auipc	a0,0x3
ffffffffc0203226:	5f650513          	addi	a0,a0,1526 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc020322a:	a64fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020322e:	00004697          	auipc	a3,0x4
ffffffffc0203232:	b5a68693          	addi	a3,a3,-1190 # ffffffffc0206d88 <default_pmm_manager+0x6c0>
ffffffffc0203236:	00003617          	auipc	a2,0x3
ffffffffc020323a:	0e260613          	addi	a2,a2,226 # ffffffffc0206318 <commands+0x828>
ffffffffc020323e:	27500593          	li	a1,629
ffffffffc0203242:	00003517          	auipc	a0,0x3
ffffffffc0203246:	5d650513          	addi	a0,a0,1494 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc020324a:	a44fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc020324e:	00004697          	auipc	a3,0x4
ffffffffc0203252:	b0a68693          	addi	a3,a3,-1270 # ffffffffc0206d58 <default_pmm_manager+0x690>
ffffffffc0203256:	00003617          	auipc	a2,0x3
ffffffffc020325a:	0c260613          	addi	a2,a2,194 # ffffffffc0206318 <commands+0x828>
ffffffffc020325e:	27100593          	li	a1,625
ffffffffc0203262:	00003517          	auipc	a0,0x3
ffffffffc0203266:	5b650513          	addi	a0,a0,1462 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc020326a:	a24fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020326e:	00004697          	auipc	a3,0x4
ffffffffc0203272:	aa268693          	addi	a3,a3,-1374 # ffffffffc0206d10 <default_pmm_manager+0x648>
ffffffffc0203276:	00003617          	auipc	a2,0x3
ffffffffc020327a:	0a260613          	addi	a2,a2,162 # ffffffffc0206318 <commands+0x828>
ffffffffc020327e:	27000593          	li	a1,624
ffffffffc0203282:	00003517          	auipc	a0,0x3
ffffffffc0203286:	59650513          	addi	a0,a0,1430 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc020328a:	a04fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020328e:	00003617          	auipc	a2,0x3
ffffffffc0203292:	51a60613          	addi	a2,a2,1306 # ffffffffc02067a8 <default_pmm_manager+0xe0>
ffffffffc0203296:	0c900593          	li	a1,201
ffffffffc020329a:	00003517          	auipc	a0,0x3
ffffffffc020329e:	57e50513          	addi	a0,a0,1406 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02032a2:	9ecfd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02032a6:	00003617          	auipc	a2,0x3
ffffffffc02032aa:	50260613          	addi	a2,a2,1282 # ffffffffc02067a8 <default_pmm_manager+0xe0>
ffffffffc02032ae:	08100593          	li	a1,129
ffffffffc02032b2:	00003517          	auipc	a0,0x3
ffffffffc02032b6:	56650513          	addi	a0,a0,1382 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02032ba:	9d4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02032be:	00003697          	auipc	a3,0x3
ffffffffc02032c2:	72268693          	addi	a3,a3,1826 # ffffffffc02069e0 <default_pmm_manager+0x318>
ffffffffc02032c6:	00003617          	auipc	a2,0x3
ffffffffc02032ca:	05260613          	addi	a2,a2,82 # ffffffffc0206318 <commands+0x828>
ffffffffc02032ce:	23000593          	li	a1,560
ffffffffc02032d2:	00003517          	auipc	a0,0x3
ffffffffc02032d6:	54650513          	addi	a0,a0,1350 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02032da:	9b4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02032de:	00003697          	auipc	a3,0x3
ffffffffc02032e2:	6d268693          	addi	a3,a3,1746 # ffffffffc02069b0 <default_pmm_manager+0x2e8>
ffffffffc02032e6:	00003617          	auipc	a2,0x3
ffffffffc02032ea:	03260613          	addi	a2,a2,50 # ffffffffc0206318 <commands+0x828>
ffffffffc02032ee:	22d00593          	li	a1,557
ffffffffc02032f2:	00003517          	auipc	a0,0x3
ffffffffc02032f6:	52650513          	addi	a0,a0,1318 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02032fa:	994fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02032fe <copy_range>:
{
ffffffffc02032fe:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203300:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203304:	fc86                	sd	ra,120(sp)
ffffffffc0203306:	f8a2                	sd	s0,112(sp)
ffffffffc0203308:	f4a6                	sd	s1,104(sp)
ffffffffc020330a:	f0ca                	sd	s2,96(sp)
ffffffffc020330c:	ecce                	sd	s3,88(sp)
ffffffffc020330e:	e8d2                	sd	s4,80(sp)
ffffffffc0203310:	e4d6                	sd	s5,72(sp)
ffffffffc0203312:	e0da                	sd	s6,64(sp)
ffffffffc0203314:	fc5e                	sd	s7,56(sp)
ffffffffc0203316:	f862                	sd	s8,48(sp)
ffffffffc0203318:	f466                	sd	s9,40(sp)
ffffffffc020331a:	f06a                	sd	s10,32(sp)
ffffffffc020331c:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020331e:	17d2                	slli	a5,a5,0x34
ffffffffc0203320:	26079b63          	bnez	a5,ffffffffc0203596 <copy_range+0x298>
    assert(USER_ACCESS(start, end));
ffffffffc0203324:	002007b7          	lui	a5,0x200
ffffffffc0203328:	8432                	mv	s0,a2
ffffffffc020332a:	1cf66d63          	bltu	a2,a5,ffffffffc0203504 <copy_range+0x206>
ffffffffc020332e:	84b6                	mv	s1,a3
ffffffffc0203330:	1cd67a63          	bgeu	a2,a3,ffffffffc0203504 <copy_range+0x206>
ffffffffc0203334:	4785                	li	a5,1
ffffffffc0203336:	07fe                	slli	a5,a5,0x1f
ffffffffc0203338:	1cd7e663          	bltu	a5,a3,ffffffffc0203504 <copy_range+0x206>
ffffffffc020333c:	5cfd                	li	s9,-1
ffffffffc020333e:	00ccd793          	srli	a5,s9,0xc
ffffffffc0203342:	8a2a                	mv	s4,a0
ffffffffc0203344:	892e                	mv	s2,a1
ffffffffc0203346:	8aba                	mv	s5,a4
        start += PGSIZE;
ffffffffc0203348:	6985                	lui	s3,0x1
    if (PPN(pa) >= npage)
ffffffffc020334a:	000a7b97          	auipc	s7,0xa7
ffffffffc020334e:	3beb8b93          	addi	s7,s7,958 # ffffffffc02aa708 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203352:	000a7b17          	auipc	s6,0xa7
ffffffffc0203356:	3beb0b13          	addi	s6,s6,958 # ffffffffc02aa710 <pages>
ffffffffc020335a:	fff80c37          	lui	s8,0xfff80
    return KADDR(page2pa(page));
ffffffffc020335e:	e03e                	sd	a5,0(sp)
        page = pmm_manager->alloc_pages(n);
ffffffffc0203360:	000a7d17          	auipc	s10,0xa7
ffffffffc0203364:	3b8d0d13          	addi	s10,s10,952 # ffffffffc02aa718 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203368:	4601                	li	a2,0
ffffffffc020336a:	85a2                	mv	a1,s0
ffffffffc020336c:	854a                	mv	a0,s2
ffffffffc020336e:	c23fe0ef          	jal	ra,ffffffffc0201f90 <get_pte>
ffffffffc0203372:	8daa                	mv	s11,a0
        if (ptep == NULL)
ffffffffc0203374:	cd59                	beqz	a0,ffffffffc0203412 <copy_range+0x114>
        if (*ptep & PTE_V)
ffffffffc0203376:	6118                	ld	a4,0(a0)
ffffffffc0203378:	8b05                	andi	a4,a4,1
ffffffffc020337a:	e705                	bnez	a4,ffffffffc02033a2 <copy_range+0xa4>
        start += PGSIZE;
ffffffffc020337c:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc020337e:	fe9465e3          	bltu	s0,s1,ffffffffc0203368 <copy_range+0x6a>
    return 0;
ffffffffc0203382:	4501                	li	a0,0
}
ffffffffc0203384:	70e6                	ld	ra,120(sp)
ffffffffc0203386:	7446                	ld	s0,112(sp)
ffffffffc0203388:	74a6                	ld	s1,104(sp)
ffffffffc020338a:	7906                	ld	s2,96(sp)
ffffffffc020338c:	69e6                	ld	s3,88(sp)
ffffffffc020338e:	6a46                	ld	s4,80(sp)
ffffffffc0203390:	6aa6                	ld	s5,72(sp)
ffffffffc0203392:	6b06                	ld	s6,64(sp)
ffffffffc0203394:	7be2                	ld	s7,56(sp)
ffffffffc0203396:	7c42                	ld	s8,48(sp)
ffffffffc0203398:	7ca2                	ld	s9,40(sp)
ffffffffc020339a:	7d02                	ld	s10,32(sp)
ffffffffc020339c:	6de2                	ld	s11,24(sp)
ffffffffc020339e:	6109                	addi	sp,sp,128
ffffffffc02033a0:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02033a2:	4605                	li	a2,1
ffffffffc02033a4:	85a2                	mv	a1,s0
ffffffffc02033a6:	8552                	mv	a0,s4
ffffffffc02033a8:	be9fe0ef          	jal	ra,ffffffffc0201f90 <get_pte>
ffffffffc02033ac:	12050e63          	beqz	a0,ffffffffc02034e8 <copy_range+0x1ea>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02033b0:	000db603          	ld	a2,0(s11)
    if (!(pte & PTE_V))
ffffffffc02033b4:	00167713          	andi	a4,a2,1
ffffffffc02033b8:	0006051b          	sext.w	a0,a2
ffffffffc02033bc:	01f67c93          	andi	s9,a2,31
ffffffffc02033c0:	12070663          	beqz	a4,ffffffffc02034ec <copy_range+0x1ee>
    if (PPN(pa) >= npage)
ffffffffc02033c4:	000bb583          	ld	a1,0(s7)
    return pa2page(PTE_ADDR(pte));
ffffffffc02033c8:	00261713          	slli	a4,a2,0x2
ffffffffc02033cc:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc02033ce:	14b77b63          	bgeu	a4,a1,ffffffffc0203524 <copy_range+0x226>
    return &pages[PPN(pa) - nbase];
ffffffffc02033d2:	000b3583          	ld	a1,0(s6)
ffffffffc02033d6:	9762                	add	a4,a4,s8
ffffffffc02033d8:	071a                	slli	a4,a4,0x6
ffffffffc02033da:	95ba                	add	a1,a1,a4
            if (share) {
ffffffffc02033dc:	040a8d63          	beqz	s5,ffffffffc0203436 <copy_range+0x138>
    page->ref += 1;
ffffffffc02033e0:	4198                	lw	a4,0(a1)
                if (perm & PTE_W) {
ffffffffc02033e2:	00457813          	andi	a6,a0,4
ffffffffc02033e6:	2705                	addiw	a4,a4,1
ffffffffc02033e8:	02080f63          	beqz	a6,ffffffffc0203426 <copy_range+0x128>
                    *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc02033ec:	efb67613          	andi	a2,a2,-261
ffffffffc02033f0:	c198                	sw	a4,0(a1)
ffffffffc02033f2:	10066613          	ori	a2,a2,256
ffffffffc02033f6:	00cdb023          	sd	a2,0(s11)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02033fa:	12040073          	sfence.vma	s0
                    uint32_t cow_perm = (perm & ~PTE_W) | PTE_COW;
ffffffffc02033fe:	01b57693          	andi	a3,a0,27
                    page_insert(to, page, start, cow_perm);
ffffffffc0203402:	8622                	mv	a2,s0
ffffffffc0203404:	1006e693          	ori	a3,a3,256
ffffffffc0203408:	8552                	mv	a0,s4
ffffffffc020340a:	9e2ff0ef          	jal	ra,ffffffffc02025ec <page_insert>
        start += PGSIZE;
ffffffffc020340e:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0203410:	b7bd                	j	ffffffffc020337e <copy_range+0x80>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203412:	00200637          	lui	a2,0x200
ffffffffc0203416:	9432                	add	s0,s0,a2
ffffffffc0203418:	ffe00637          	lui	a2,0xffe00
ffffffffc020341c:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc020341e:	d035                	beqz	s0,ffffffffc0203382 <copy_range+0x84>
ffffffffc0203420:	f49464e3          	bltu	s0,s1,ffffffffc0203368 <copy_range+0x6a>
ffffffffc0203424:	bfb9                	j	ffffffffc0203382 <copy_range+0x84>
                    page_insert(to, page, start, perm);
ffffffffc0203426:	8622                	mv	a2,s0
ffffffffc0203428:	c198                	sw	a4,0(a1)
ffffffffc020342a:	86e6                	mv	a3,s9
ffffffffc020342c:	8552                	mv	a0,s4
ffffffffc020342e:	9beff0ef          	jal	ra,ffffffffc02025ec <page_insert>
        start += PGSIZE;
ffffffffc0203432:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc0203434:	b7a9                	j	ffffffffc020337e <copy_range+0x80>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203436:	100027f3          	csrr	a5,sstatus
ffffffffc020343a:	8b89                	andi	a5,a5,2
ffffffffc020343c:	e42e                	sd	a1,8(sp)
ffffffffc020343e:	ebc9                	bnez	a5,ffffffffc02034d0 <copy_range+0x1d2>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203440:	000d3783          	ld	a5,0(s10)
ffffffffc0203444:	4505                	li	a0,1
ffffffffc0203446:	6f9c                	ld	a5,24(a5)
ffffffffc0203448:	9782                	jalr	a5
ffffffffc020344a:	65a2                	ld	a1,8(sp)
ffffffffc020344c:	8daa                	mv	s11,a0
                assert(page != NULL);
ffffffffc020344e:	12058463          	beqz	a1,ffffffffc0203576 <copy_range+0x278>
                assert(npage != NULL);
ffffffffc0203452:	0e0d8563          	beqz	s11,ffffffffc020353c <copy_range+0x23e>
    return page - pages + nbase;
ffffffffc0203456:	000b3703          	ld	a4,0(s6)
    return KADDR(page2pa(page));
ffffffffc020345a:	6682                	ld	a3,0(sp)
    return page - pages + nbase;
ffffffffc020345c:	000808b7          	lui	a7,0x80
ffffffffc0203460:	40e587b3          	sub	a5,a1,a4
ffffffffc0203464:	8799                	srai	a5,a5,0x6
    return KADDR(page2pa(page));
ffffffffc0203466:	000bb603          	ld	a2,0(s7)
    return page - pages + nbase;
ffffffffc020346a:	97c6                	add	a5,a5,a7
    return KADDR(page2pa(page));
ffffffffc020346c:	00d7f5b3          	and	a1,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203470:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203472:	0ec5f563          	bgeu	a1,a2,ffffffffc020355c <copy_range+0x25e>
ffffffffc0203476:	000a7697          	auipc	a3,0xa7
ffffffffc020347a:	2aa68693          	addi	a3,a3,682 # ffffffffc02aa720 <va_pa_offset>
ffffffffc020347e:	6288                	ld	a0,0(a3)
    return page - pages + nbase;
ffffffffc0203480:	40ed8733          	sub	a4,s11,a4
    return KADDR(page2pa(page));
ffffffffc0203484:	6682                	ld	a3,0(sp)
    return page - pages + nbase;
ffffffffc0203486:	8719                	srai	a4,a4,0x6
ffffffffc0203488:	9746                	add	a4,a4,a7
    return KADDR(page2pa(page));
ffffffffc020348a:	00d778b3          	and	a7,a4,a3
ffffffffc020348e:	00a785b3          	add	a1,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203492:	0732                	slli	a4,a4,0xc
    return KADDR(page2pa(page));
ffffffffc0203494:	12c8f163          	bgeu	a7,a2,ffffffffc02035b6 <copy_range+0x2b8>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0203498:	6605                	lui	a2,0x1
ffffffffc020349a:	953a                	add	a0,a0,a4
ffffffffc020349c:	3d0020ef          	jal	ra,ffffffffc020586c <memcpy>
                ret = page_insert(to, npage, start, perm);
ffffffffc02034a0:	86e6                	mv	a3,s9
ffffffffc02034a2:	8622                	mv	a2,s0
ffffffffc02034a4:	85ee                	mv	a1,s11
ffffffffc02034a6:	8552                	mv	a0,s4
ffffffffc02034a8:	944ff0ef          	jal	ra,ffffffffc02025ec <page_insert>
                assert(ret == 0);
ffffffffc02034ac:	ec0508e3          	beqz	a0,ffffffffc020337c <copy_range+0x7e>
ffffffffc02034b0:	00004697          	auipc	a3,0x4
ffffffffc02034b4:	97868693          	addi	a3,a3,-1672 # ffffffffc0206e28 <default_pmm_manager+0x760>
ffffffffc02034b8:	00003617          	auipc	a2,0x3
ffffffffc02034bc:	e6060613          	addi	a2,a2,-416 # ffffffffc0206318 <commands+0x828>
ffffffffc02034c0:	1c400593          	li	a1,452
ffffffffc02034c4:	00003517          	auipc	a0,0x3
ffffffffc02034c8:	35450513          	addi	a0,a0,852 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02034cc:	fc3fc0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02034d0:	ce4fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034d4:	000d3783          	ld	a5,0(s10)
ffffffffc02034d8:	4505                	li	a0,1
ffffffffc02034da:	6f9c                	ld	a5,24(a5)
ffffffffc02034dc:	9782                	jalr	a5
ffffffffc02034de:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc02034e0:	ccefd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02034e4:	65a2                	ld	a1,8(sp)
ffffffffc02034e6:	b7a5                	j	ffffffffc020344e <copy_range+0x150>
                return -E_NO_MEM;
ffffffffc02034e8:	5571                	li	a0,-4
ffffffffc02034ea:	bd69                	j	ffffffffc0203384 <copy_range+0x86>
        panic("pte2page called with invalid pte");
ffffffffc02034ec:	00003617          	auipc	a2,0x3
ffffffffc02034f0:	30460613          	addi	a2,a2,772 # ffffffffc02067f0 <default_pmm_manager+0x128>
ffffffffc02034f4:	08000593          	li	a1,128
ffffffffc02034f8:	00003517          	auipc	a0,0x3
ffffffffc02034fc:	23050513          	addi	a0,a0,560 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0203500:	f8ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203504:	00003697          	auipc	a3,0x3
ffffffffc0203508:	35468693          	addi	a3,a3,852 # ffffffffc0206858 <default_pmm_manager+0x190>
ffffffffc020350c:	00003617          	auipc	a2,0x3
ffffffffc0203510:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206318 <commands+0x828>
ffffffffc0203514:	17c00593          	li	a1,380
ffffffffc0203518:	00003517          	auipc	a0,0x3
ffffffffc020351c:	30050513          	addi	a0,a0,768 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203520:	f6ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203524:	00003617          	auipc	a2,0x3
ffffffffc0203528:	2ac60613          	addi	a2,a2,684 # ffffffffc02067d0 <default_pmm_manager+0x108>
ffffffffc020352c:	06a00593          	li	a1,106
ffffffffc0203530:	00003517          	auipc	a0,0x3
ffffffffc0203534:	1f850513          	addi	a0,a0,504 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0203538:	f57fc0ef          	jal	ra,ffffffffc020048e <__panic>
                assert(npage != NULL);
ffffffffc020353c:	00004697          	auipc	a3,0x4
ffffffffc0203540:	8dc68693          	addi	a3,a3,-1828 # ffffffffc0206e18 <default_pmm_manager+0x750>
ffffffffc0203544:	00003617          	auipc	a2,0x3
ffffffffc0203548:	dd460613          	addi	a2,a2,-556 # ffffffffc0206318 <commands+0x828>
ffffffffc020354c:	1a800593          	li	a1,424
ffffffffc0203550:	00003517          	auipc	a0,0x3
ffffffffc0203554:	2c850513          	addi	a0,a0,712 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203558:	f37fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020355c:	86be                	mv	a3,a5
ffffffffc020355e:	00003617          	auipc	a2,0x3
ffffffffc0203562:	1a260613          	addi	a2,a2,418 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc0203566:	07200593          	li	a1,114
ffffffffc020356a:	00003517          	auipc	a0,0x3
ffffffffc020356e:	1be50513          	addi	a0,a0,446 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0203572:	f1dfc0ef          	jal	ra,ffffffffc020048e <__panic>
                assert(page != NULL);
ffffffffc0203576:	00004697          	auipc	a3,0x4
ffffffffc020357a:	89268693          	addi	a3,a3,-1902 # ffffffffc0206e08 <default_pmm_manager+0x740>
ffffffffc020357e:	00003617          	auipc	a2,0x3
ffffffffc0203582:	d9a60613          	addi	a2,a2,-614 # ffffffffc0206318 <commands+0x828>
ffffffffc0203586:	1a700593          	li	a1,423
ffffffffc020358a:	00003517          	auipc	a0,0x3
ffffffffc020358e:	28e50513          	addi	a0,a0,654 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203592:	efdfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203596:	00003697          	auipc	a3,0x3
ffffffffc020359a:	29268693          	addi	a3,a3,658 # ffffffffc0206828 <default_pmm_manager+0x160>
ffffffffc020359e:	00003617          	auipc	a2,0x3
ffffffffc02035a2:	d7a60613          	addi	a2,a2,-646 # ffffffffc0206318 <commands+0x828>
ffffffffc02035a6:	17b00593          	li	a1,379
ffffffffc02035aa:	00003517          	auipc	a0,0x3
ffffffffc02035ae:	26e50513          	addi	a0,a0,622 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc02035b2:	eddfc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02035b6:	86ba                	mv	a3,a4
ffffffffc02035b8:	00003617          	auipc	a2,0x3
ffffffffc02035bc:	14860613          	addi	a2,a2,328 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc02035c0:	07200593          	li	a1,114
ffffffffc02035c4:	00003517          	auipc	a0,0x3
ffffffffc02035c8:	16450513          	addi	a0,a0,356 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc02035cc:	ec3fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02035d0 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02035d0:	12058073          	sfence.vma	a1
}
ffffffffc02035d4:	8082                	ret

ffffffffc02035d6 <pgdir_alloc_page>:
{
ffffffffc02035d6:	7179                	addi	sp,sp,-48
ffffffffc02035d8:	ec26                	sd	s1,24(sp)
ffffffffc02035da:	e84a                	sd	s2,16(sp)
ffffffffc02035dc:	e052                	sd	s4,0(sp)
ffffffffc02035de:	f406                	sd	ra,40(sp)
ffffffffc02035e0:	f022                	sd	s0,32(sp)
ffffffffc02035e2:	e44e                	sd	s3,8(sp)
ffffffffc02035e4:	8a2a                	mv	s4,a0
ffffffffc02035e6:	84ae                	mv	s1,a1
ffffffffc02035e8:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035ea:	100027f3          	csrr	a5,sstatus
ffffffffc02035ee:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02035f0:	000a7997          	auipc	s3,0xa7
ffffffffc02035f4:	12898993          	addi	s3,s3,296 # ffffffffc02aa718 <pmm_manager>
ffffffffc02035f8:	ef8d                	bnez	a5,ffffffffc0203632 <pgdir_alloc_page+0x5c>
ffffffffc02035fa:	0009b783          	ld	a5,0(s3)
ffffffffc02035fe:	4505                	li	a0,1
ffffffffc0203600:	6f9c                	ld	a5,24(a5)
ffffffffc0203602:	9782                	jalr	a5
ffffffffc0203604:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203606:	cc09                	beqz	s0,ffffffffc0203620 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203608:	86ca                	mv	a3,s2
ffffffffc020360a:	8626                	mv	a2,s1
ffffffffc020360c:	85a2                	mv	a1,s0
ffffffffc020360e:	8552                	mv	a0,s4
ffffffffc0203610:	fddfe0ef          	jal	ra,ffffffffc02025ec <page_insert>
ffffffffc0203614:	e915                	bnez	a0,ffffffffc0203648 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203616:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203618:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc020361a:	4785                	li	a5,1
ffffffffc020361c:	04f71e63          	bne	a4,a5,ffffffffc0203678 <pgdir_alloc_page+0xa2>
}
ffffffffc0203620:	70a2                	ld	ra,40(sp)
ffffffffc0203622:	8522                	mv	a0,s0
ffffffffc0203624:	7402                	ld	s0,32(sp)
ffffffffc0203626:	64e2                	ld	s1,24(sp)
ffffffffc0203628:	6942                	ld	s2,16(sp)
ffffffffc020362a:	69a2                	ld	s3,8(sp)
ffffffffc020362c:	6a02                	ld	s4,0(sp)
ffffffffc020362e:	6145                	addi	sp,sp,48
ffffffffc0203630:	8082                	ret
        intr_disable();
ffffffffc0203632:	b82fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203636:	0009b783          	ld	a5,0(s3)
ffffffffc020363a:	4505                	li	a0,1
ffffffffc020363c:	6f9c                	ld	a5,24(a5)
ffffffffc020363e:	9782                	jalr	a5
ffffffffc0203640:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203642:	b6cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203646:	b7c1                	j	ffffffffc0203606 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203648:	100027f3          	csrr	a5,sstatus
ffffffffc020364c:	8b89                	andi	a5,a5,2
ffffffffc020364e:	eb89                	bnez	a5,ffffffffc0203660 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203650:	0009b783          	ld	a5,0(s3)
ffffffffc0203654:	8522                	mv	a0,s0
ffffffffc0203656:	4585                	li	a1,1
ffffffffc0203658:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020365a:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020365c:	9782                	jalr	a5
    if (flag)
ffffffffc020365e:	b7c9                	j	ffffffffc0203620 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203660:	b54fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203664:	0009b783          	ld	a5,0(s3)
ffffffffc0203668:	8522                	mv	a0,s0
ffffffffc020366a:	4585                	li	a1,1
ffffffffc020366c:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020366e:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203670:	9782                	jalr	a5
        intr_enable();
ffffffffc0203672:	b3cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203676:	b76d                	j	ffffffffc0203620 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203678:	00003697          	auipc	a3,0x3
ffffffffc020367c:	7c068693          	addi	a3,a3,1984 # ffffffffc0206e38 <default_pmm_manager+0x770>
ffffffffc0203680:	00003617          	auipc	a2,0x3
ffffffffc0203684:	c9860613          	addi	a2,a2,-872 # ffffffffc0206318 <commands+0x828>
ffffffffc0203688:	20e00593          	li	a1,526
ffffffffc020368c:	00003517          	auipc	a0,0x3
ffffffffc0203690:	18c50513          	addi	a0,a0,396 # ffffffffc0206818 <default_pmm_manager+0x150>
ffffffffc0203694:	dfbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203698 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203698:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020369a:	00003697          	auipc	a3,0x3
ffffffffc020369e:	7b668693          	addi	a3,a3,1974 # ffffffffc0206e50 <default_pmm_manager+0x788>
ffffffffc02036a2:	00003617          	auipc	a2,0x3
ffffffffc02036a6:	c7660613          	addi	a2,a2,-906 # ffffffffc0206318 <commands+0x828>
ffffffffc02036aa:	07400593          	li	a1,116
ffffffffc02036ae:	00003517          	auipc	a0,0x3
ffffffffc02036b2:	7c250513          	addi	a0,a0,1986 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036b6:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02036b8:	dd7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036bc <mm_create>:
{
ffffffffc02036bc:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036be:	04000513          	li	a0,64
{
ffffffffc02036c2:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036c4:	e36fe0ef          	jal	ra,ffffffffc0201cfa <kmalloc>
    if (mm != NULL)
ffffffffc02036c8:	cd19                	beqz	a0,ffffffffc02036e6 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02036ca:	e508                	sd	a0,8(a0)
ffffffffc02036cc:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02036ce:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02036d2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02036d6:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02036da:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02036de:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02036e2:	02053c23          	sd	zero,56(a0)
}
ffffffffc02036e6:	60a2                	ld	ra,8(sp)
ffffffffc02036e8:	0141                	addi	sp,sp,16
ffffffffc02036ea:	8082                	ret

ffffffffc02036ec <find_vma>:
{
ffffffffc02036ec:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02036ee:	c505                	beqz	a0,ffffffffc0203716 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02036f0:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02036f2:	c501                	beqz	a0,ffffffffc02036fa <find_vma+0xe>
ffffffffc02036f4:	651c                	ld	a5,8(a0)
ffffffffc02036f6:	02f5f263          	bgeu	a1,a5,ffffffffc020371a <find_vma+0x2e>
    return listelm->next;
ffffffffc02036fa:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02036fc:	00f68d63          	beq	a3,a5,ffffffffc0203716 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203700:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f4ec8>
ffffffffc0203704:	00e5e663          	bltu	a1,a4,ffffffffc0203710 <find_vma+0x24>
ffffffffc0203708:	ff07b703          	ld	a4,-16(a5)
ffffffffc020370c:	00e5ec63          	bltu	a1,a4,ffffffffc0203724 <find_vma+0x38>
ffffffffc0203710:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203712:	fef697e3          	bne	a3,a5,ffffffffc0203700 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203716:	4501                	li	a0,0
}
ffffffffc0203718:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020371a:	691c                	ld	a5,16(a0)
ffffffffc020371c:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02036fa <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203720:	ea88                	sd	a0,16(a3)
ffffffffc0203722:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203724:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203728:	ea88                	sd	a0,16(a3)
ffffffffc020372a:	8082                	ret

ffffffffc020372c <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020372c:	6590                	ld	a2,8(a1)
ffffffffc020372e:	0105b803          	ld	a6,16(a1)
{
ffffffffc0203732:	1141                	addi	sp,sp,-16
ffffffffc0203734:	e406                	sd	ra,8(sp)
ffffffffc0203736:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203738:	01066763          	bltu	a2,a6,ffffffffc0203746 <insert_vma_struct+0x1a>
ffffffffc020373c:	a085                	j	ffffffffc020379c <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020373e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203742:	04e66863          	bltu	a2,a4,ffffffffc0203792 <insert_vma_struct+0x66>
ffffffffc0203746:	86be                	mv	a3,a5
ffffffffc0203748:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020374a:	fef51ae3          	bne	a0,a5,ffffffffc020373e <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020374e:	02a68463          	beq	a3,a0,ffffffffc0203776 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203752:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203756:	fe86b883          	ld	a7,-24(a3)
ffffffffc020375a:	08e8f163          	bgeu	a7,a4,ffffffffc02037dc <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020375e:	04e66f63          	bltu	a2,a4,ffffffffc02037bc <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203762:	00f50a63          	beq	a0,a5,ffffffffc0203776 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203766:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020376a:	05076963          	bltu	a4,a6,ffffffffc02037bc <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020376e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203772:	02c77363          	bgeu	a4,a2,ffffffffc0203798 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203776:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203778:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020377a:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020377e:	e390                	sd	a2,0(a5)
ffffffffc0203780:	e690                	sd	a2,8(a3)
}
ffffffffc0203782:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203784:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203786:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203788:	0017079b          	addiw	a5,a4,1
ffffffffc020378c:	d11c                	sw	a5,32(a0)
}
ffffffffc020378e:	0141                	addi	sp,sp,16
ffffffffc0203790:	8082                	ret
    if (le_prev != list)
ffffffffc0203792:	fca690e3          	bne	a3,a0,ffffffffc0203752 <insert_vma_struct+0x26>
ffffffffc0203796:	bfd1                	j	ffffffffc020376a <insert_vma_struct+0x3e>
ffffffffc0203798:	f01ff0ef          	jal	ra,ffffffffc0203698 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020379c:	00003697          	auipc	a3,0x3
ffffffffc02037a0:	6e468693          	addi	a3,a3,1764 # ffffffffc0206e80 <default_pmm_manager+0x7b8>
ffffffffc02037a4:	00003617          	auipc	a2,0x3
ffffffffc02037a8:	b7460613          	addi	a2,a2,-1164 # ffffffffc0206318 <commands+0x828>
ffffffffc02037ac:	07a00593          	li	a1,122
ffffffffc02037b0:	00003517          	auipc	a0,0x3
ffffffffc02037b4:	6c050513          	addi	a0,a0,1728 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc02037b8:	cd7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037bc:	00003697          	auipc	a3,0x3
ffffffffc02037c0:	70468693          	addi	a3,a3,1796 # ffffffffc0206ec0 <default_pmm_manager+0x7f8>
ffffffffc02037c4:	00003617          	auipc	a2,0x3
ffffffffc02037c8:	b5460613          	addi	a2,a2,-1196 # ffffffffc0206318 <commands+0x828>
ffffffffc02037cc:	07300593          	li	a1,115
ffffffffc02037d0:	00003517          	auipc	a0,0x3
ffffffffc02037d4:	6a050513          	addi	a0,a0,1696 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc02037d8:	cb7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037dc:	00003697          	auipc	a3,0x3
ffffffffc02037e0:	6c468693          	addi	a3,a3,1732 # ffffffffc0206ea0 <default_pmm_manager+0x7d8>
ffffffffc02037e4:	00003617          	auipc	a2,0x3
ffffffffc02037e8:	b3460613          	addi	a2,a2,-1228 # ffffffffc0206318 <commands+0x828>
ffffffffc02037ec:	07200593          	li	a1,114
ffffffffc02037f0:	00003517          	auipc	a0,0x3
ffffffffc02037f4:	68050513          	addi	a0,a0,1664 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc02037f8:	c97fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02037fc <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02037fc:	591c                	lw	a5,48(a0)
{
ffffffffc02037fe:	1141                	addi	sp,sp,-16
ffffffffc0203800:	e406                	sd	ra,8(sp)
ffffffffc0203802:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203804:	e78d                	bnez	a5,ffffffffc020382e <mm_destroy+0x32>
ffffffffc0203806:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203808:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc020380a:	00a40c63          	beq	s0,a0,ffffffffc0203822 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020380e:	6118                	ld	a4,0(a0)
ffffffffc0203810:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203812:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203814:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203816:	e398                	sd	a4,0(a5)
ffffffffc0203818:	d92fe0ef          	jal	ra,ffffffffc0201daa <kfree>
    return listelm->next;
ffffffffc020381c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc020381e:	fea418e3          	bne	s0,a0,ffffffffc020380e <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203822:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203824:	6402                	ld	s0,0(sp)
ffffffffc0203826:	60a2                	ld	ra,8(sp)
ffffffffc0203828:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc020382a:	d80fe06f          	j	ffffffffc0201daa <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020382e:	00003697          	auipc	a3,0x3
ffffffffc0203832:	6b268693          	addi	a3,a3,1714 # ffffffffc0206ee0 <default_pmm_manager+0x818>
ffffffffc0203836:	00003617          	auipc	a2,0x3
ffffffffc020383a:	ae260613          	addi	a2,a2,-1310 # ffffffffc0206318 <commands+0x828>
ffffffffc020383e:	09e00593          	li	a1,158
ffffffffc0203842:	00003517          	auipc	a0,0x3
ffffffffc0203846:	62e50513          	addi	a0,a0,1582 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc020384a:	c45fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020384e <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc020384e:	7139                	addi	sp,sp,-64
ffffffffc0203850:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203852:	6405                	lui	s0,0x1
ffffffffc0203854:	147d                	addi	s0,s0,-1
ffffffffc0203856:	77fd                	lui	a5,0xfffff
ffffffffc0203858:	9622                	add	a2,a2,s0
ffffffffc020385a:	962e                	add	a2,a2,a1
{
ffffffffc020385c:	f426                	sd	s1,40(sp)
ffffffffc020385e:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203860:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203864:	f04a                	sd	s2,32(sp)
ffffffffc0203866:	ec4e                	sd	s3,24(sp)
ffffffffc0203868:	e852                	sd	s4,16(sp)
ffffffffc020386a:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020386c:	002005b7          	lui	a1,0x200
ffffffffc0203870:	00f67433          	and	s0,a2,a5
ffffffffc0203874:	06b4e363          	bltu	s1,a1,ffffffffc02038da <mm_map+0x8c>
ffffffffc0203878:	0684f163          	bgeu	s1,s0,ffffffffc02038da <mm_map+0x8c>
ffffffffc020387c:	4785                	li	a5,1
ffffffffc020387e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203880:	0487ed63          	bltu	a5,s0,ffffffffc02038da <mm_map+0x8c>
ffffffffc0203884:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203886:	cd21                	beqz	a0,ffffffffc02038de <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203888:	85a6                	mv	a1,s1
ffffffffc020388a:	8ab6                	mv	s5,a3
ffffffffc020388c:	8a3a                	mv	s4,a4
ffffffffc020388e:	e5fff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203892:	c501                	beqz	a0,ffffffffc020389a <mm_map+0x4c>
ffffffffc0203894:	651c                	ld	a5,8(a0)
ffffffffc0203896:	0487e263          	bltu	a5,s0,ffffffffc02038da <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020389a:	03000513          	li	a0,48
ffffffffc020389e:	c5cfe0ef          	jal	ra,ffffffffc0201cfa <kmalloc>
ffffffffc02038a2:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02038a4:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02038a6:	02090163          	beqz	s2,ffffffffc02038c8 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02038aa:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02038ac:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02038b0:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02038b4:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02038b8:	85ca                	mv	a1,s2
ffffffffc02038ba:	e73ff0ef          	jal	ra,ffffffffc020372c <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02038be:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02038c0:	000a0463          	beqz	s4,ffffffffc02038c8 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02038c4:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc02038c8:	70e2                	ld	ra,56(sp)
ffffffffc02038ca:	7442                	ld	s0,48(sp)
ffffffffc02038cc:	74a2                	ld	s1,40(sp)
ffffffffc02038ce:	7902                	ld	s2,32(sp)
ffffffffc02038d0:	69e2                	ld	s3,24(sp)
ffffffffc02038d2:	6a42                	ld	s4,16(sp)
ffffffffc02038d4:	6aa2                	ld	s5,8(sp)
ffffffffc02038d6:	6121                	addi	sp,sp,64
ffffffffc02038d8:	8082                	ret
        return -E_INVAL;
ffffffffc02038da:	5575                	li	a0,-3
ffffffffc02038dc:	b7f5                	j	ffffffffc02038c8 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02038de:	00003697          	auipc	a3,0x3
ffffffffc02038e2:	61a68693          	addi	a3,a3,1562 # ffffffffc0206ef8 <default_pmm_manager+0x830>
ffffffffc02038e6:	00003617          	auipc	a2,0x3
ffffffffc02038ea:	a3260613          	addi	a2,a2,-1486 # ffffffffc0206318 <commands+0x828>
ffffffffc02038ee:	0b300593          	li	a1,179
ffffffffc02038f2:	00003517          	auipc	a0,0x3
ffffffffc02038f6:	57e50513          	addi	a0,a0,1406 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc02038fa:	b95fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038fe <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02038fe:	7139                	addi	sp,sp,-64
ffffffffc0203900:	fc06                	sd	ra,56(sp)
ffffffffc0203902:	f822                	sd	s0,48(sp)
ffffffffc0203904:	f426                	sd	s1,40(sp)
ffffffffc0203906:	f04a                	sd	s2,32(sp)
ffffffffc0203908:	ec4e                	sd	s3,24(sp)
ffffffffc020390a:	e852                	sd	s4,16(sp)
ffffffffc020390c:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc020390e:	c52d                	beqz	a0,ffffffffc0203978 <dup_mmap+0x7a>
ffffffffc0203910:	892a                	mv	s2,a0
ffffffffc0203912:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203914:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203916:	e595                	bnez	a1,ffffffffc0203942 <dup_mmap+0x44>
ffffffffc0203918:	a085                	j	ffffffffc0203978 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020391a:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc020391c:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ee8>
        vma->vm_end = vm_end;
ffffffffc0203920:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203924:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203928:	e05ff0ef          	jal	ra,ffffffffc020372c <insert_vma_struct>

        bool share = 1;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc020392c:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0203930:	fe843603          	ld	a2,-24(s0)
ffffffffc0203934:	6c8c                	ld	a1,24(s1)
ffffffffc0203936:	01893503          	ld	a0,24(s2)
ffffffffc020393a:	4705                	li	a4,1
ffffffffc020393c:	9c3ff0ef          	jal	ra,ffffffffc02032fe <copy_range>
ffffffffc0203940:	e105                	bnez	a0,ffffffffc0203960 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203942:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203944:	02848863          	beq	s1,s0,ffffffffc0203974 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203948:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc020394c:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203950:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203954:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203958:	ba2fe0ef          	jal	ra,ffffffffc0201cfa <kmalloc>
ffffffffc020395c:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc020395e:	fd55                	bnez	a0,ffffffffc020391a <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203960:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203962:	70e2                	ld	ra,56(sp)
ffffffffc0203964:	7442                	ld	s0,48(sp)
ffffffffc0203966:	74a2                	ld	s1,40(sp)
ffffffffc0203968:	7902                	ld	s2,32(sp)
ffffffffc020396a:	69e2                	ld	s3,24(sp)
ffffffffc020396c:	6a42                	ld	s4,16(sp)
ffffffffc020396e:	6aa2                	ld	s5,8(sp)
ffffffffc0203970:	6121                	addi	sp,sp,64
ffffffffc0203972:	8082                	ret
    return 0;
ffffffffc0203974:	4501                	li	a0,0
ffffffffc0203976:	b7f5                	j	ffffffffc0203962 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203978:	00003697          	auipc	a3,0x3
ffffffffc020397c:	59068693          	addi	a3,a3,1424 # ffffffffc0206f08 <default_pmm_manager+0x840>
ffffffffc0203980:	00003617          	auipc	a2,0x3
ffffffffc0203984:	99860613          	addi	a2,a2,-1640 # ffffffffc0206318 <commands+0x828>
ffffffffc0203988:	0cf00593          	li	a1,207
ffffffffc020398c:	00003517          	auipc	a0,0x3
ffffffffc0203990:	4e450513          	addi	a0,a0,1252 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203994:	afbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203998 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203998:	1101                	addi	sp,sp,-32
ffffffffc020399a:	ec06                	sd	ra,24(sp)
ffffffffc020399c:	e822                	sd	s0,16(sp)
ffffffffc020399e:	e426                	sd	s1,8(sp)
ffffffffc02039a0:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039a2:	c531                	beqz	a0,ffffffffc02039ee <exit_mmap+0x56>
ffffffffc02039a4:	591c                	lw	a5,48(a0)
ffffffffc02039a6:	84aa                	mv	s1,a0
ffffffffc02039a8:	e3b9                	bnez	a5,ffffffffc02039ee <exit_mmap+0x56>
    return listelm->next;
ffffffffc02039aa:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02039ac:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02039b0:	02850663          	beq	a0,s0,ffffffffc02039dc <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039b4:	ff043603          	ld	a2,-16(s0)
ffffffffc02039b8:	fe843583          	ld	a1,-24(s0)
ffffffffc02039bc:	854a                	mv	a0,s2
ffffffffc02039be:	8ddfe0ef          	jal	ra,ffffffffc020229a <unmap_range>
ffffffffc02039c2:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039c4:	fe8498e3          	bne	s1,s0,ffffffffc02039b4 <exit_mmap+0x1c>
ffffffffc02039c8:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02039ca:	00848c63          	beq	s1,s0,ffffffffc02039e2 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039ce:	ff043603          	ld	a2,-16(s0)
ffffffffc02039d2:	fe843583          	ld	a1,-24(s0)
ffffffffc02039d6:	854a                	mv	a0,s2
ffffffffc02039d8:	983fe0ef          	jal	ra,ffffffffc020235a <exit_range>
ffffffffc02039dc:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039de:	fe8498e3          	bne	s1,s0,ffffffffc02039ce <exit_mmap+0x36>
    }
}
ffffffffc02039e2:	60e2                	ld	ra,24(sp)
ffffffffc02039e4:	6442                	ld	s0,16(sp)
ffffffffc02039e6:	64a2                	ld	s1,8(sp)
ffffffffc02039e8:	6902                	ld	s2,0(sp)
ffffffffc02039ea:	6105                	addi	sp,sp,32
ffffffffc02039ec:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039ee:	00003697          	auipc	a3,0x3
ffffffffc02039f2:	53a68693          	addi	a3,a3,1338 # ffffffffc0206f28 <default_pmm_manager+0x860>
ffffffffc02039f6:	00003617          	auipc	a2,0x3
ffffffffc02039fa:	92260613          	addi	a2,a2,-1758 # ffffffffc0206318 <commands+0x828>
ffffffffc02039fe:	0e800593          	li	a1,232
ffffffffc0203a02:	00003517          	auipc	a0,0x3
ffffffffc0203a06:	46e50513          	addi	a0,a0,1134 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203a0a:	a85fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a0e <do_pgfault>:
// @mm: the memory manager
// @error_code: the error code from trap
// @addr: the fault address
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    if (mm == NULL)
ffffffffc0203a0e:	18050e63          	beqz	a0,ffffffffc0203baa <do_pgfault+0x19c>
{
ffffffffc0203a12:	715d                	addi	sp,sp,-80
ffffffffc0203a14:	f052                	sd	s4,32(sp)
ffffffffc0203a16:	8a2e                	mv	s4,a1
    {
        return -E_INVAL;
    }
    
    // Check if address is in valid range
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203a18:	85b2                	mv	a1,a2
{
ffffffffc0203a1a:	e0a2                	sd	s0,64(sp)
ffffffffc0203a1c:	fc26                	sd	s1,56(sp)
ffffffffc0203a1e:	f84a                	sd	s2,48(sp)
ffffffffc0203a20:	e486                	sd	ra,72(sp)
ffffffffc0203a22:	f44e                	sd	s3,40(sp)
ffffffffc0203a24:	ec56                	sd	s5,24(sp)
ffffffffc0203a26:	e85a                	sd	s6,16(sp)
ffffffffc0203a28:	e45e                	sd	s7,8(sp)
ffffffffc0203a2a:	84aa                	mv	s1,a0
ffffffffc0203a2c:	8432                	mv	s0,a2
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203a2e:	cbfff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203a32:	892a                	mv	s2,a0
    if (vma == NULL || addr < vma->vm_start)
ffffffffc0203a34:	cd41                	beqz	a0,ffffffffc0203acc <do_pgfault+0xbe>
ffffffffc0203a36:	651c                	ld	a5,8(a0)
ffffffffc0203a38:	08f46a63          	bltu	s0,a5,ffffffffc0203acc <do_pgfault+0xbe>
    {
        return -E_INVAL;
    }
    
    // Get page table entry
    pte_t *ptep = get_pte(mm->pgdir, addr, 1);
ffffffffc0203a3c:	6c88                	ld	a0,24(s1)
ffffffffc0203a3e:	4605                	li	a2,1
ffffffffc0203a40:	85a2                	mv	a1,s0
ffffffffc0203a42:	d4efe0ef          	jal	ra,ffffffffc0201f90 <get_pte>
ffffffffc0203a46:	89aa                	mv	s3,a0
    if (ptep == NULL)
ffffffffc0203a48:	14050f63          	beqz	a0,ffffffffc0203ba6 <do_pgfault+0x198>
    {
        return -E_NO_MEM;
    }
    
    // Case 1: Page exists
    if (*ptep & PTE_V)
ffffffffc0203a4c:	611c                	ld	a5,0(a0)
ffffffffc0203a4e:	0017f713          	andi	a4,a5,1
ffffffffc0203a52:	e721                	bnez	a4,ffffffffc0203a9a <do_pgfault+0x8c>
        return -E_INVAL;
    }
    
    // Case 2: Page doesn't exist - allocate new page
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) perm |= PTE_W;
ffffffffc0203a54:	01892783          	lw	a5,24(s2)
    uint32_t perm = PTE_U;
ffffffffc0203a58:	4641                	li	a2,16
    if (vma->vm_flags & VM_WRITE) perm |= PTE_W;
ffffffffc0203a5a:	0027f713          	andi	a4,a5,2
ffffffffc0203a5e:	c311                	beqz	a4,ffffffffc0203a62 <do_pgfault+0x54>
ffffffffc0203a60:	4651                	li	a2,20
    if (vma->vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0203a62:	0017f713          	andi	a4,a5,1
ffffffffc0203a66:	c319                	beqz	a4,ffffffffc0203a6c <do_pgfault+0x5e>
ffffffffc0203a68:	00266613          	ori	a2,a2,2
    if (vma->vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc0203a6c:	8b91                	andi	a5,a5,4
ffffffffc0203a6e:	c399                	beqz	a5,ffffffffc0203a74 <do_pgfault+0x66>
ffffffffc0203a70:	00866613          	ori	a2,a2,8
    
    struct Page *page = pgdir_alloc_page(mm->pgdir, addr, perm);
ffffffffc0203a74:	6c88                	ld	a0,24(s1)
ffffffffc0203a76:	85a2                	mv	a1,s0
ffffffffc0203a78:	b5fff0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc0203a7c:	87aa                	mv	a5,a0
    if (page == NULL)
    {
        return -E_NO_MEM;
    }
    
    return 0;
ffffffffc0203a7e:	4501                	li	a0,0
    if (page == NULL)
ffffffffc0203a80:	12078363          	beqz	a5,ffffffffc0203ba6 <do_pgfault+0x198>
}
ffffffffc0203a84:	60a6                	ld	ra,72(sp)
ffffffffc0203a86:	6406                	ld	s0,64(sp)
ffffffffc0203a88:	74e2                	ld	s1,56(sp)
ffffffffc0203a8a:	7942                	ld	s2,48(sp)
ffffffffc0203a8c:	79a2                	ld	s3,40(sp)
ffffffffc0203a8e:	7a02                	ld	s4,32(sp)
ffffffffc0203a90:	6ae2                	ld	s5,24(sp)
ffffffffc0203a92:	6b42                	ld	s6,16(sp)
ffffffffc0203a94:	6ba2                	ld	s7,8(sp)
ffffffffc0203a96:	6161                	addi	sp,sp,80
ffffffffc0203a98:	8082                	ret
        if ((*ptep & PTE_COW) && (error_code == CAUSE_STORE_PAGE_FAULT))
ffffffffc0203a9a:	1007f713          	andi	a4,a5,256
ffffffffc0203a9e:	c701                	beqz	a4,ffffffffc0203aa6 <do_pgfault+0x98>
ffffffffc0203aa0:	473d                	li	a4,15
ffffffffc0203aa2:	02ea0b63          	beq	s4,a4,ffffffffc0203ad8 <do_pgfault+0xca>
        if (error_code == CAUSE_FETCH_PAGE_FAULT)
ffffffffc0203aa6:	4731                	li	a4,12
ffffffffc0203aa8:	02ea0463          	beq	s4,a4,ffffffffc0203ad0 <do_pgfault+0xc2>
        else if (error_code == CAUSE_LOAD_PAGE_FAULT)
ffffffffc0203aac:	4735                	li	a4,13
ffffffffc0203aae:	00ea0d63          	beq	s4,a4,ffffffffc0203ac8 <do_pgfault+0xba>
        else if (error_code == CAUSE_STORE_PAGE_FAULT)
ffffffffc0203ab2:	473d                	li	a4,15
ffffffffc0203ab4:	00ea1c63          	bne	s4,a4,ffffffffc0203acc <do_pgfault+0xbe>
            if (*ptep & PTE_W)
ffffffffc0203ab8:	8b91                	andi	a5,a5,4
ffffffffc0203aba:	cb89                	beqz	a5,ffffffffc0203acc <do_pgfault+0xbe>
                tlb_invalidate(mm->pgdir, addr);
ffffffffc0203abc:	6c88                	ld	a0,24(s1)
ffffffffc0203abe:	85a2                	mv	a1,s0
ffffffffc0203ac0:	b11ff0ef          	jal	ra,ffffffffc02035d0 <tlb_invalidate>
                return 0;
ffffffffc0203ac4:	4501                	li	a0,0
ffffffffc0203ac6:	bf7d                	j	ffffffffc0203a84 <do_pgfault+0x76>
            if (*ptep & PTE_R)
ffffffffc0203ac8:	8b89                	andi	a5,a5,2
ffffffffc0203aca:	fbed                	bnez	a5,ffffffffc0203abc <do_pgfault+0xae>
        return -E_INVAL;
ffffffffc0203acc:	5575                	li	a0,-3
ffffffffc0203ace:	bf5d                	j	ffffffffc0203a84 <do_pgfault+0x76>
            if (*ptep & PTE_X)
ffffffffc0203ad0:	8ba1                	andi	a5,a5,8
ffffffffc0203ad2:	f7ed                	bnez	a5,ffffffffc0203abc <do_pgfault+0xae>
        return -E_INVAL;
ffffffffc0203ad4:	5575                	li	a0,-3
ffffffffc0203ad6:	b77d                	j	ffffffffc0203a84 <do_pgfault+0x76>
    if (PPN(pa) >= npage)
ffffffffc0203ad8:	000a7b17          	auipc	s6,0xa7
ffffffffc0203adc:	c30b0b13          	addi	s6,s6,-976 # ffffffffc02aa708 <npage>
ffffffffc0203ae0:	000b3683          	ld	a3,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203ae4:	00279713          	slli	a4,a5,0x2
ffffffffc0203ae8:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0203aea:	0cd77263          	bgeu	a4,a3,ffffffffc0203bae <do_pgfault+0x1a0>
    return &pages[PPN(pa) - nbase];
ffffffffc0203aee:	000a7b97          	auipc	s7,0xa7
ffffffffc0203af2:	c22b8b93          	addi	s7,s7,-990 # ffffffffc02aa710 <pages>
ffffffffc0203af6:	000bb903          	ld	s2,0(s7)
ffffffffc0203afa:	00004a97          	auipc	s5,0x4
ffffffffc0203afe:	ed6aba83          	ld	s5,-298(s5) # ffffffffc02079d0 <nbase>
ffffffffc0203b02:	41570733          	sub	a4,a4,s5
ffffffffc0203b06:	071a                	slli	a4,a4,0x6
ffffffffc0203b08:	993a                	add	s2,s2,a4
            if (ref > 1)
ffffffffc0203b0a:	00092683          	lw	a3,0(s2)
ffffffffc0203b0e:	4705                	li	a4,1
ffffffffc0203b10:	06d75f63          	bge	a4,a3,ffffffffc0203b8e <do_pgfault+0x180>
                struct Page *new_page = alloc_page();
ffffffffc0203b14:	4505                	li	a0,1
ffffffffc0203b16:	bc2fe0ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc0203b1a:	8a2a                	mv	s4,a0
                if (new_page == NULL)
ffffffffc0203b1c:	c549                	beqz	a0,ffffffffc0203ba6 <do_pgfault+0x198>
    return page - pages + nbase;
ffffffffc0203b1e:	000bb603          	ld	a2,0(s7)
    return KADDR(page2pa(page));
ffffffffc0203b22:	577d                	li	a4,-1
ffffffffc0203b24:	000b3803          	ld	a6,0(s6)
    return page - pages + nbase;
ffffffffc0203b28:	40c506b3          	sub	a3,a0,a2
ffffffffc0203b2c:	8699                	srai	a3,a3,0x6
ffffffffc0203b2e:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0203b30:	8331                	srli	a4,a4,0xc
ffffffffc0203b32:	00e6f7b3          	and	a5,a3,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0203b36:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203b38:	0b07f463          	bgeu	a5,a6,ffffffffc0203be0 <do_pgfault+0x1d2>
    return page - pages + nbase;
ffffffffc0203b3c:	40c907b3          	sub	a5,s2,a2
ffffffffc0203b40:	8799                	srai	a5,a5,0x6
ffffffffc0203b42:	97d6                	add	a5,a5,s5
    return KADDR(page2pa(page));
ffffffffc0203b44:	000a7597          	auipc	a1,0xa7
ffffffffc0203b48:	bdc5b583          	ld	a1,-1060(a1) # ffffffffc02aa720 <va_pa_offset>
ffffffffc0203b4c:	8f7d                	and	a4,a4,a5
ffffffffc0203b4e:	00b68533          	add	a0,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0203b52:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203b54:	07077963          	bgeu	a4,a6,ffffffffc0203bc6 <do_pgfault+0x1b8>
                memcpy(page2kva(new_page), page2kva(page), PGSIZE);
ffffffffc0203b58:	95be                	add	a1,a1,a5
ffffffffc0203b5a:	6605                	lui	a2,0x1
ffffffffc0203b5c:	511010ef          	jal	ra,ffffffffc020586c <memcpy>
    page->ref -= 1;
ffffffffc0203b60:	00092783          	lw	a5,0(s2)
                uint32_t perm = (*ptep & PTE_USER) & ~PTE_COW;
ffffffffc0203b64:	0009b683          	ld	a3,0(s3)
                page_remove_pte(mm->pgdir, addr, ptep);
ffffffffc0203b68:	6c88                	ld	a0,24(s1)
ffffffffc0203b6a:	37fd                	addiw	a5,a5,-1
ffffffffc0203b6c:	00f92023          	sw	a5,0(s2)
ffffffffc0203b70:	864e                	mv	a2,s3
ffffffffc0203b72:	85a2                	mv	a1,s0
                uint32_t perm = (*ptep & PTE_USER) & ~PTE_COW;
ffffffffc0203b74:	01f6f913          	andi	s2,a3,31
                page_remove_pte(mm->pgdir, addr, ptep);
ffffffffc0203b78:	e94fe0ef          	jal	ra,ffffffffc020220c <page_remove_pte>
                page_insert(mm->pgdir, new_page, addr, perm | PTE_W);
ffffffffc0203b7c:	6c88                	ld	a0,24(s1)
ffffffffc0203b7e:	00496693          	ori	a3,s2,4
ffffffffc0203b82:	8622                	mv	a2,s0
ffffffffc0203b84:	85d2                	mv	a1,s4
ffffffffc0203b86:	a67fe0ef          	jal	ra,ffffffffc02025ec <page_insert>
                return 0;
ffffffffc0203b8a:	4501                	li	a0,0
ffffffffc0203b8c:	bde5                	j	ffffffffc0203a84 <do_pgfault+0x76>
                tlb_invalidate(mm->pgdir, addr);
ffffffffc0203b8e:	6c88                	ld	a0,24(s1)
                *ptep = (*ptep & ~PTE_COW) | PTE_W;
ffffffffc0203b90:	efb7f793          	andi	a5,a5,-261
ffffffffc0203b94:	0047e793          	ori	a5,a5,4
ffffffffc0203b98:	00f9b023          	sd	a5,0(s3)
                tlb_invalidate(mm->pgdir, addr);
ffffffffc0203b9c:	85a2                	mv	a1,s0
ffffffffc0203b9e:	a33ff0ef          	jal	ra,ffffffffc02035d0 <tlb_invalidate>
                return 0;
ffffffffc0203ba2:	4501                	li	a0,0
ffffffffc0203ba4:	b5c5                	j	ffffffffc0203a84 <do_pgfault+0x76>
        return -E_NO_MEM;
ffffffffc0203ba6:	5571                	li	a0,-4
ffffffffc0203ba8:	bdf1                	j	ffffffffc0203a84 <do_pgfault+0x76>
        return -E_INVAL;
ffffffffc0203baa:	5575                	li	a0,-3
}
ffffffffc0203bac:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0203bae:	00003617          	auipc	a2,0x3
ffffffffc0203bb2:	c2260613          	addi	a2,a2,-990 # ffffffffc02067d0 <default_pmm_manager+0x108>
ffffffffc0203bb6:	06a00593          	li	a1,106
ffffffffc0203bba:	00003517          	auipc	a0,0x3
ffffffffc0203bbe:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0203bc2:	8cdfc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0203bc6:	86be                	mv	a3,a5
ffffffffc0203bc8:	00003617          	auipc	a2,0x3
ffffffffc0203bcc:	b3860613          	addi	a2,a2,-1224 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc0203bd0:	07200593          	li	a1,114
ffffffffc0203bd4:	00003517          	auipc	a0,0x3
ffffffffc0203bd8:	b5450513          	addi	a0,a0,-1196 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0203bdc:	8b3fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203be0:	00003617          	auipc	a2,0x3
ffffffffc0203be4:	b2060613          	addi	a2,a2,-1248 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc0203be8:	07200593          	li	a1,114
ffffffffc0203bec:	00003517          	auipc	a0,0x3
ffffffffc0203bf0:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0203bf4:	89bfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203bf8 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203bf8:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203bfa:	04000513          	li	a0,64
{
ffffffffc0203bfe:	fc06                	sd	ra,56(sp)
ffffffffc0203c00:	f822                	sd	s0,48(sp)
ffffffffc0203c02:	f426                	sd	s1,40(sp)
ffffffffc0203c04:	f04a                	sd	s2,32(sp)
ffffffffc0203c06:	ec4e                	sd	s3,24(sp)
ffffffffc0203c08:	e852                	sd	s4,16(sp)
ffffffffc0203c0a:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203c0c:	8eefe0ef          	jal	ra,ffffffffc0201cfa <kmalloc>
    if (mm != NULL)
ffffffffc0203c10:	2e050663          	beqz	a0,ffffffffc0203efc <vmm_init+0x304>
ffffffffc0203c14:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203c16:	e508                	sd	a0,8(a0)
ffffffffc0203c18:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203c1a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203c1e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203c22:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203c26:	02053423          	sd	zero,40(a0)
ffffffffc0203c2a:	02052823          	sw	zero,48(a0)
ffffffffc0203c2e:	02053c23          	sd	zero,56(a0)
ffffffffc0203c32:	03200413          	li	s0,50
ffffffffc0203c36:	a811                	j	ffffffffc0203c4a <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203c38:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203c3a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203c3c:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203c40:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203c42:	8526                	mv	a0,s1
ffffffffc0203c44:	ae9ff0ef          	jal	ra,ffffffffc020372c <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203c48:	c80d                	beqz	s0,ffffffffc0203c7a <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c4a:	03000513          	li	a0,48
ffffffffc0203c4e:	8acfe0ef          	jal	ra,ffffffffc0201cfa <kmalloc>
ffffffffc0203c52:	85aa                	mv	a1,a0
ffffffffc0203c54:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203c58:	f165                	bnez	a0,ffffffffc0203c38 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203c5a:	00003697          	auipc	a3,0x3
ffffffffc0203c5e:	46668693          	addi	a3,a3,1126 # ffffffffc02070c0 <default_pmm_manager+0x9f8>
ffffffffc0203c62:	00002617          	auipc	a2,0x2
ffffffffc0203c66:	6b660613          	addi	a2,a2,1718 # ffffffffc0206318 <commands+0x828>
ffffffffc0203c6a:	19f00593          	li	a1,415
ffffffffc0203c6e:	00003517          	auipc	a0,0x3
ffffffffc0203c72:	20250513          	addi	a0,a0,514 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203c76:	819fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203c7a:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c7e:	1f900913          	li	s2,505
ffffffffc0203c82:	a819                	j	ffffffffc0203c98 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203c84:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203c86:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203c88:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c8c:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203c8e:	8526                	mv	a0,s1
ffffffffc0203c90:	a9dff0ef          	jal	ra,ffffffffc020372c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c94:	03240a63          	beq	s0,s2,ffffffffc0203cc8 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c98:	03000513          	li	a0,48
ffffffffc0203c9c:	85efe0ef          	jal	ra,ffffffffc0201cfa <kmalloc>
ffffffffc0203ca0:	85aa                	mv	a1,a0
ffffffffc0203ca2:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203ca6:	fd79                	bnez	a0,ffffffffc0203c84 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203ca8:	00003697          	auipc	a3,0x3
ffffffffc0203cac:	41868693          	addi	a3,a3,1048 # ffffffffc02070c0 <default_pmm_manager+0x9f8>
ffffffffc0203cb0:	00002617          	auipc	a2,0x2
ffffffffc0203cb4:	66860613          	addi	a2,a2,1640 # ffffffffc0206318 <commands+0x828>
ffffffffc0203cb8:	1a600593          	li	a1,422
ffffffffc0203cbc:	00003517          	auipc	a0,0x3
ffffffffc0203cc0:	1b450513          	addi	a0,a0,436 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203cc4:	fcafc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203cc8:	649c                	ld	a5,8(s1)
ffffffffc0203cca:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203ccc:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203cd0:	16f48663          	beq	s1,a5,ffffffffc0203e3c <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203cd4:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd548a4>
ffffffffc0203cd8:	ffe70693          	addi	a3,a4,-2 # ffe <_binary_obj___user_faultread_out_size-0x8baa>
ffffffffc0203cdc:	10d61063          	bne	a2,a3,ffffffffc0203ddc <vmm_init+0x1e4>
ffffffffc0203ce0:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203ce4:	0ed71c63          	bne	a4,a3,ffffffffc0203ddc <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203ce8:	0715                	addi	a4,a4,5
ffffffffc0203cea:	679c                	ld	a5,8(a5)
ffffffffc0203cec:	feb712e3          	bne	a4,a1,ffffffffc0203cd0 <vmm_init+0xd8>
ffffffffc0203cf0:	4a1d                	li	s4,7
ffffffffc0203cf2:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203cf4:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203cf8:	85a2                	mv	a1,s0
ffffffffc0203cfa:	8526                	mv	a0,s1
ffffffffc0203cfc:	9f1ff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203d00:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203d02:	16050d63          	beqz	a0,ffffffffc0203e7c <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203d06:	00140593          	addi	a1,s0,1
ffffffffc0203d0a:	8526                	mv	a0,s1
ffffffffc0203d0c:	9e1ff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203d10:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203d12:	14050563          	beqz	a0,ffffffffc0203e5c <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203d16:	85d2                	mv	a1,s4
ffffffffc0203d18:	8526                	mv	a0,s1
ffffffffc0203d1a:	9d3ff0ef          	jal	ra,ffffffffc02036ec <find_vma>
        assert(vma3 == NULL);
ffffffffc0203d1e:	16051f63          	bnez	a0,ffffffffc0203e9c <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203d22:	00340593          	addi	a1,s0,3
ffffffffc0203d26:	8526                	mv	a0,s1
ffffffffc0203d28:	9c5ff0ef          	jal	ra,ffffffffc02036ec <find_vma>
        assert(vma4 == NULL);
ffffffffc0203d2c:	1a051863          	bnez	a0,ffffffffc0203edc <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203d30:	00440593          	addi	a1,s0,4
ffffffffc0203d34:	8526                	mv	a0,s1
ffffffffc0203d36:	9b7ff0ef          	jal	ra,ffffffffc02036ec <find_vma>
        assert(vma5 == NULL);
ffffffffc0203d3a:	18051163          	bnez	a0,ffffffffc0203ebc <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203d3e:	00893783          	ld	a5,8(s2)
ffffffffc0203d42:	0a879d63          	bne	a5,s0,ffffffffc0203dfc <vmm_init+0x204>
ffffffffc0203d46:	01093783          	ld	a5,16(s2)
ffffffffc0203d4a:	0b479963          	bne	a5,s4,ffffffffc0203dfc <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203d4e:	0089b783          	ld	a5,8(s3)
ffffffffc0203d52:	0c879563          	bne	a5,s0,ffffffffc0203e1c <vmm_init+0x224>
ffffffffc0203d56:	0109b783          	ld	a5,16(s3)
ffffffffc0203d5a:	0d479163          	bne	a5,s4,ffffffffc0203e1c <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203d5e:	0415                	addi	s0,s0,5
ffffffffc0203d60:	0a15                	addi	s4,s4,5
ffffffffc0203d62:	f9541be3          	bne	s0,s5,ffffffffc0203cf8 <vmm_init+0x100>
ffffffffc0203d66:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203d68:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203d6a:	85a2                	mv	a1,s0
ffffffffc0203d6c:	8526                	mv	a0,s1
ffffffffc0203d6e:	97fff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203d72:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203d76:	c90d                	beqz	a0,ffffffffc0203da8 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d78:	6914                	ld	a3,16(a0)
ffffffffc0203d7a:	6510                	ld	a2,8(a0)
ffffffffc0203d7c:	00003517          	auipc	a0,0x3
ffffffffc0203d80:	2cc50513          	addi	a0,a0,716 # ffffffffc0207048 <default_pmm_manager+0x980>
ffffffffc0203d84:	c10fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203d88:	00003697          	auipc	a3,0x3
ffffffffc0203d8c:	2e868693          	addi	a3,a3,744 # ffffffffc0207070 <default_pmm_manager+0x9a8>
ffffffffc0203d90:	00002617          	auipc	a2,0x2
ffffffffc0203d94:	58860613          	addi	a2,a2,1416 # ffffffffc0206318 <commands+0x828>
ffffffffc0203d98:	1cc00593          	li	a1,460
ffffffffc0203d9c:	00003517          	auipc	a0,0x3
ffffffffc0203da0:	0d450513          	addi	a0,a0,212 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203da4:	eeafc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203da8:	147d                	addi	s0,s0,-1
ffffffffc0203daa:	fd2410e3          	bne	s0,s2,ffffffffc0203d6a <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203dae:	8526                	mv	a0,s1
ffffffffc0203db0:	a4dff0ef          	jal	ra,ffffffffc02037fc <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203db4:	00003517          	auipc	a0,0x3
ffffffffc0203db8:	2d450513          	addi	a0,a0,724 # ffffffffc0207088 <default_pmm_manager+0x9c0>
ffffffffc0203dbc:	bd8fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203dc0:	7442                	ld	s0,48(sp)
ffffffffc0203dc2:	70e2                	ld	ra,56(sp)
ffffffffc0203dc4:	74a2                	ld	s1,40(sp)
ffffffffc0203dc6:	7902                	ld	s2,32(sp)
ffffffffc0203dc8:	69e2                	ld	s3,24(sp)
ffffffffc0203dca:	6a42                	ld	s4,16(sp)
ffffffffc0203dcc:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203dce:	00003517          	auipc	a0,0x3
ffffffffc0203dd2:	2da50513          	addi	a0,a0,730 # ffffffffc02070a8 <default_pmm_manager+0x9e0>
}
ffffffffc0203dd6:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203dd8:	bbcfc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ddc:	00003697          	auipc	a3,0x3
ffffffffc0203de0:	18468693          	addi	a3,a3,388 # ffffffffc0206f60 <default_pmm_manager+0x898>
ffffffffc0203de4:	00002617          	auipc	a2,0x2
ffffffffc0203de8:	53460613          	addi	a2,a2,1332 # ffffffffc0206318 <commands+0x828>
ffffffffc0203dec:	1b000593          	li	a1,432
ffffffffc0203df0:	00003517          	auipc	a0,0x3
ffffffffc0203df4:	08050513          	addi	a0,a0,128 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203df8:	e96fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203dfc:	00003697          	auipc	a3,0x3
ffffffffc0203e00:	1ec68693          	addi	a3,a3,492 # ffffffffc0206fe8 <default_pmm_manager+0x920>
ffffffffc0203e04:	00002617          	auipc	a2,0x2
ffffffffc0203e08:	51460613          	addi	a2,a2,1300 # ffffffffc0206318 <commands+0x828>
ffffffffc0203e0c:	1c100593          	li	a1,449
ffffffffc0203e10:	00003517          	auipc	a0,0x3
ffffffffc0203e14:	06050513          	addi	a0,a0,96 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203e18:	e76fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203e1c:	00003697          	auipc	a3,0x3
ffffffffc0203e20:	1fc68693          	addi	a3,a3,508 # ffffffffc0207018 <default_pmm_manager+0x950>
ffffffffc0203e24:	00002617          	auipc	a2,0x2
ffffffffc0203e28:	4f460613          	addi	a2,a2,1268 # ffffffffc0206318 <commands+0x828>
ffffffffc0203e2c:	1c200593          	li	a1,450
ffffffffc0203e30:	00003517          	auipc	a0,0x3
ffffffffc0203e34:	04050513          	addi	a0,a0,64 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203e38:	e56fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203e3c:	00003697          	auipc	a3,0x3
ffffffffc0203e40:	10c68693          	addi	a3,a3,268 # ffffffffc0206f48 <default_pmm_manager+0x880>
ffffffffc0203e44:	00002617          	auipc	a2,0x2
ffffffffc0203e48:	4d460613          	addi	a2,a2,1236 # ffffffffc0206318 <commands+0x828>
ffffffffc0203e4c:	1ae00593          	li	a1,430
ffffffffc0203e50:	00003517          	auipc	a0,0x3
ffffffffc0203e54:	02050513          	addi	a0,a0,32 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203e58:	e36fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203e5c:	00003697          	auipc	a3,0x3
ffffffffc0203e60:	14c68693          	addi	a3,a3,332 # ffffffffc0206fa8 <default_pmm_manager+0x8e0>
ffffffffc0203e64:	00002617          	auipc	a2,0x2
ffffffffc0203e68:	4b460613          	addi	a2,a2,1204 # ffffffffc0206318 <commands+0x828>
ffffffffc0203e6c:	1b900593          	li	a1,441
ffffffffc0203e70:	00003517          	auipc	a0,0x3
ffffffffc0203e74:	00050513          	mv	a0,a0
ffffffffc0203e78:	e16fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203e7c:	00003697          	auipc	a3,0x3
ffffffffc0203e80:	11c68693          	addi	a3,a3,284 # ffffffffc0206f98 <default_pmm_manager+0x8d0>
ffffffffc0203e84:	00002617          	auipc	a2,0x2
ffffffffc0203e88:	49460613          	addi	a2,a2,1172 # ffffffffc0206318 <commands+0x828>
ffffffffc0203e8c:	1b700593          	li	a1,439
ffffffffc0203e90:	00003517          	auipc	a0,0x3
ffffffffc0203e94:	fe050513          	addi	a0,a0,-32 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203e98:	df6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203e9c:	00003697          	auipc	a3,0x3
ffffffffc0203ea0:	11c68693          	addi	a3,a3,284 # ffffffffc0206fb8 <default_pmm_manager+0x8f0>
ffffffffc0203ea4:	00002617          	auipc	a2,0x2
ffffffffc0203ea8:	47460613          	addi	a2,a2,1140 # ffffffffc0206318 <commands+0x828>
ffffffffc0203eac:	1bb00593          	li	a1,443
ffffffffc0203eb0:	00003517          	auipc	a0,0x3
ffffffffc0203eb4:	fc050513          	addi	a0,a0,-64 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203eb8:	dd6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203ebc:	00003697          	auipc	a3,0x3
ffffffffc0203ec0:	11c68693          	addi	a3,a3,284 # ffffffffc0206fd8 <default_pmm_manager+0x910>
ffffffffc0203ec4:	00002617          	auipc	a2,0x2
ffffffffc0203ec8:	45460613          	addi	a2,a2,1108 # ffffffffc0206318 <commands+0x828>
ffffffffc0203ecc:	1bf00593          	li	a1,447
ffffffffc0203ed0:	00003517          	auipc	a0,0x3
ffffffffc0203ed4:	fa050513          	addi	a0,a0,-96 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203ed8:	db6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203edc:	00003697          	auipc	a3,0x3
ffffffffc0203ee0:	0ec68693          	addi	a3,a3,236 # ffffffffc0206fc8 <default_pmm_manager+0x900>
ffffffffc0203ee4:	00002617          	auipc	a2,0x2
ffffffffc0203ee8:	43460613          	addi	a2,a2,1076 # ffffffffc0206318 <commands+0x828>
ffffffffc0203eec:	1bd00593          	li	a1,445
ffffffffc0203ef0:	00003517          	auipc	a0,0x3
ffffffffc0203ef4:	f8050513          	addi	a0,a0,-128 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203ef8:	d96fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203efc:	00003697          	auipc	a3,0x3
ffffffffc0203f00:	ffc68693          	addi	a3,a3,-4 # ffffffffc0206ef8 <default_pmm_manager+0x830>
ffffffffc0203f04:	00002617          	auipc	a2,0x2
ffffffffc0203f08:	41460613          	addi	a2,a2,1044 # ffffffffc0206318 <commands+0x828>
ffffffffc0203f0c:	19700593          	li	a1,407
ffffffffc0203f10:	00003517          	auipc	a0,0x3
ffffffffc0203f14:	f6050513          	addi	a0,a0,-160 # ffffffffc0206e70 <default_pmm_manager+0x7a8>
ffffffffc0203f18:	d76fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203f1c <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203f1c:	7179                	addi	sp,sp,-48
ffffffffc0203f1e:	f022                	sd	s0,32(sp)
ffffffffc0203f20:	f406                	sd	ra,40(sp)
ffffffffc0203f22:	ec26                	sd	s1,24(sp)
ffffffffc0203f24:	e84a                	sd	s2,16(sp)
ffffffffc0203f26:	e44e                	sd	s3,8(sp)
ffffffffc0203f28:	e052                	sd	s4,0(sp)
ffffffffc0203f2a:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203f2c:	c135                	beqz	a0,ffffffffc0203f90 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203f2e:	002007b7          	lui	a5,0x200
ffffffffc0203f32:	04f5e663          	bltu	a1,a5,ffffffffc0203f7e <user_mem_check+0x62>
ffffffffc0203f36:	00c584b3          	add	s1,a1,a2
ffffffffc0203f3a:	0495f263          	bgeu	a1,s1,ffffffffc0203f7e <user_mem_check+0x62>
ffffffffc0203f3e:	4785                	li	a5,1
ffffffffc0203f40:	07fe                	slli	a5,a5,0x1f
ffffffffc0203f42:	0297ee63          	bltu	a5,s1,ffffffffc0203f7e <user_mem_check+0x62>
ffffffffc0203f46:	892a                	mv	s2,a0
ffffffffc0203f48:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f4a:	6a05                	lui	s4,0x1
ffffffffc0203f4c:	a821                	j	ffffffffc0203f64 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f4e:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f52:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f54:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f56:	c685                	beqz	a3,ffffffffc0203f7e <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f58:	c399                	beqz	a5,ffffffffc0203f5e <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f5a:	02e46263          	bltu	s0,a4,ffffffffc0203f7e <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203f5e:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203f60:	04947663          	bgeu	s0,s1,ffffffffc0203fac <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203f64:	85a2                	mv	a1,s0
ffffffffc0203f66:	854a                	mv	a0,s2
ffffffffc0203f68:	f84ff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203f6c:	c909                	beqz	a0,ffffffffc0203f7e <user_mem_check+0x62>
ffffffffc0203f6e:	6518                	ld	a4,8(a0)
ffffffffc0203f70:	00e46763          	bltu	s0,a4,ffffffffc0203f7e <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f74:	4d1c                	lw	a5,24(a0)
ffffffffc0203f76:	fc099ce3          	bnez	s3,ffffffffc0203f4e <user_mem_check+0x32>
ffffffffc0203f7a:	8b85                	andi	a5,a5,1
ffffffffc0203f7c:	f3ed                	bnez	a5,ffffffffc0203f5e <user_mem_check+0x42>
            return 0;
ffffffffc0203f7e:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f80:	70a2                	ld	ra,40(sp)
ffffffffc0203f82:	7402                	ld	s0,32(sp)
ffffffffc0203f84:	64e2                	ld	s1,24(sp)
ffffffffc0203f86:	6942                	ld	s2,16(sp)
ffffffffc0203f88:	69a2                	ld	s3,8(sp)
ffffffffc0203f8a:	6a02                	ld	s4,0(sp)
ffffffffc0203f8c:	6145                	addi	sp,sp,48
ffffffffc0203f8e:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f90:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f94:	4501                	li	a0,0
ffffffffc0203f96:	fef5e5e3          	bltu	a1,a5,ffffffffc0203f80 <user_mem_check+0x64>
ffffffffc0203f9a:	962e                	add	a2,a2,a1
ffffffffc0203f9c:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203f80 <user_mem_check+0x64>
ffffffffc0203fa0:	c8000537          	lui	a0,0xc8000
ffffffffc0203fa4:	0505                	addi	a0,a0,1
ffffffffc0203fa6:	00a63533          	sltu	a0,a2,a0
ffffffffc0203faa:	bfd9                	j	ffffffffc0203f80 <user_mem_check+0x64>
        return 1;
ffffffffc0203fac:	4505                	li	a0,1
ffffffffc0203fae:	bfc9                	j	ffffffffc0203f80 <user_mem_check+0x64>

ffffffffc0203fb0 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203fb0:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203fb2:	9402                	jalr	s0

	jal do_exit
ffffffffc0203fb4:	5da000ef          	jal	ra,ffffffffc020458e <do_exit>

ffffffffc0203fb8 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203fb8:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203fba:	10800513          	li	a0,264
{
ffffffffc0203fbe:	e022                	sd	s0,0(sp)
ffffffffc0203fc0:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203fc2:	d39fd0ef          	jal	ra,ffffffffc0201cfa <kmalloc>
ffffffffc0203fc6:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203fc8:	cd21                	beqz	a0,ffffffffc0204020 <alloc_proc+0x68>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;
ffffffffc0203fca:	57fd                	li	a5,-1
ffffffffc0203fcc:	1782                	slli	a5,a5,0x20
ffffffffc0203fce:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203fd0:	07000613          	li	a2,112
ffffffffc0203fd4:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc0203fd6:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d558c4>
        proc->kstack = 0;
ffffffffc0203fda:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203fde:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203fe2:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203fe6:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203fea:	03050513          	addi	a0,a0,48
ffffffffc0203fee:	06d010ef          	jal	ra,ffffffffc020585a <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203ff2:	000a6797          	auipc	a5,0xa6
ffffffffc0203ff6:	7067b783          	ld	a5,1798(a5) # ffffffffc02aa6f8 <boot_pgdir_pa>
        proc->tf = NULL;
ffffffffc0203ffa:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203ffe:	f45c                	sd	a5,168(s0)
        proc->flags = 0;
ffffffffc0204000:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN);
ffffffffc0204004:	463d                	li	a2,15
ffffffffc0204006:	4581                	li	a1,0
ffffffffc0204008:	0b440513          	addi	a0,s0,180
ffffffffc020400c:	04f010ef          	jal	ra,ffffffffc020585a <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->wait_state = 0;
ffffffffc0204010:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;
ffffffffc0204014:	0e043823          	sd	zero,240(s0)
        proc->yptr = NULL;
ffffffffc0204018:	0e043c23          	sd	zero,248(s0)
        proc->optr = NULL;
ffffffffc020401c:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0204020:	60a2                	ld	ra,8(sp)
ffffffffc0204022:	8522                	mv	a0,s0
ffffffffc0204024:	6402                	ld	s0,0(sp)
ffffffffc0204026:	0141                	addi	sp,sp,16
ffffffffc0204028:	8082                	ret

ffffffffc020402a <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc020402a:	000a6797          	auipc	a5,0xa6
ffffffffc020402e:	6fe7b783          	ld	a5,1790(a5) # ffffffffc02aa728 <current>
ffffffffc0204032:	73c8                	ld	a0,160(a5)
ffffffffc0204034:	f3bfc06f          	j	ffffffffc0200f6e <forkrets>

ffffffffc0204038 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204038:	000a6797          	auipc	a5,0xa6
ffffffffc020403c:	6f07b783          	ld	a5,1776(a5) # ffffffffc02aa728 <current>
ffffffffc0204040:	43cc                	lw	a1,4(a5)
{
ffffffffc0204042:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204044:	00003617          	auipc	a2,0x3
ffffffffc0204048:	08c60613          	addi	a2,a2,140 # ffffffffc02070d0 <default_pmm_manager+0xa08>
ffffffffc020404c:	00003517          	auipc	a0,0x3
ffffffffc0204050:	09450513          	addi	a0,a0,148 # ffffffffc02070e0 <default_pmm_manager+0xa18>
{
ffffffffc0204054:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204056:	93efc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020405a:	3fe07797          	auipc	a5,0x3fe07
ffffffffc020405e:	90e78793          	addi	a5,a5,-1778 # a968 <_binary_obj___user_forktest_out_size>
ffffffffc0204062:	e43e                	sd	a5,8(sp)
ffffffffc0204064:	00003517          	auipc	a0,0x3
ffffffffc0204068:	06c50513          	addi	a0,a0,108 # ffffffffc02070d0 <default_pmm_manager+0xa08>
ffffffffc020406c:	00045797          	auipc	a5,0x45
ffffffffc0204070:	68478793          	addi	a5,a5,1668 # ffffffffc02496f0 <_binary_obj___user_forktest_out_start>
ffffffffc0204074:	f03e                	sd	a5,32(sp)
ffffffffc0204076:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0204078:	e802                	sd	zero,16(sp)
ffffffffc020407a:	73e010ef          	jal	ra,ffffffffc02057b8 <strlen>
ffffffffc020407e:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204080:	4511                	li	a0,4
ffffffffc0204082:	55a2                	lw	a1,40(sp)
ffffffffc0204084:	4662                	lw	a2,24(sp)
ffffffffc0204086:	5682                	lw	a3,32(sp)
ffffffffc0204088:	4722                	lw	a4,8(sp)
ffffffffc020408a:	48a9                	li	a7,10
ffffffffc020408c:	9002                	ebreak
ffffffffc020408e:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204090:	65c2                	ld	a1,16(sp)
ffffffffc0204092:	00003517          	auipc	a0,0x3
ffffffffc0204096:	07650513          	addi	a0,a0,118 # ffffffffc0207108 <default_pmm_manager+0xa40>
ffffffffc020409a:	8fafc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc020409e:	00003617          	auipc	a2,0x3
ffffffffc02040a2:	07a60613          	addi	a2,a2,122 # ffffffffc0207118 <default_pmm_manager+0xa50>
ffffffffc02040a6:	3ad00593          	li	a1,941
ffffffffc02040aa:	00003517          	auipc	a0,0x3
ffffffffc02040ae:	08e50513          	addi	a0,a0,142 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc02040b2:	bdcfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02040b6 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc02040b6:	6d14                	ld	a3,24(a0)
{
ffffffffc02040b8:	1141                	addi	sp,sp,-16
ffffffffc02040ba:	e406                	sd	ra,8(sp)
ffffffffc02040bc:	c02007b7          	lui	a5,0xc0200
ffffffffc02040c0:	02f6ee63          	bltu	a3,a5,ffffffffc02040fc <put_pgdir+0x46>
ffffffffc02040c4:	000a6517          	auipc	a0,0xa6
ffffffffc02040c8:	65c53503          	ld	a0,1628(a0) # ffffffffc02aa720 <va_pa_offset>
ffffffffc02040cc:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc02040ce:	82b1                	srli	a3,a3,0xc
ffffffffc02040d0:	000a6797          	auipc	a5,0xa6
ffffffffc02040d4:	6387b783          	ld	a5,1592(a5) # ffffffffc02aa708 <npage>
ffffffffc02040d8:	02f6fe63          	bgeu	a3,a5,ffffffffc0204114 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc02040dc:	00004517          	auipc	a0,0x4
ffffffffc02040e0:	8f453503          	ld	a0,-1804(a0) # ffffffffc02079d0 <nbase>
}
ffffffffc02040e4:	60a2                	ld	ra,8(sp)
ffffffffc02040e6:	8e89                	sub	a3,a3,a0
ffffffffc02040e8:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc02040ea:	000a6517          	auipc	a0,0xa6
ffffffffc02040ee:	62653503          	ld	a0,1574(a0) # ffffffffc02aa710 <pages>
ffffffffc02040f2:	4585                	li	a1,1
ffffffffc02040f4:	9536                	add	a0,a0,a3
}
ffffffffc02040f6:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc02040f8:	e1ffd06f          	j	ffffffffc0201f16 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc02040fc:	00002617          	auipc	a2,0x2
ffffffffc0204100:	6ac60613          	addi	a2,a2,1708 # ffffffffc02067a8 <default_pmm_manager+0xe0>
ffffffffc0204104:	07800593          	li	a1,120
ffffffffc0204108:	00002517          	auipc	a0,0x2
ffffffffc020410c:	62050513          	addi	a0,a0,1568 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0204110:	b7efc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204114:	00002617          	auipc	a2,0x2
ffffffffc0204118:	6bc60613          	addi	a2,a2,1724 # ffffffffc02067d0 <default_pmm_manager+0x108>
ffffffffc020411c:	06a00593          	li	a1,106
ffffffffc0204120:	00002517          	auipc	a0,0x2
ffffffffc0204124:	60850513          	addi	a0,a0,1544 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0204128:	b66fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020412c <proc_run>:
{
ffffffffc020412c:	7179                	addi	sp,sp,-48
ffffffffc020412e:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0204130:	000a6917          	auipc	s2,0xa6
ffffffffc0204134:	5f890913          	addi	s2,s2,1528 # ffffffffc02aa728 <current>
{
ffffffffc0204138:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc020413a:	00093483          	ld	s1,0(s2)
{
ffffffffc020413e:	f406                	sd	ra,40(sp)
ffffffffc0204140:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0204142:	02a48863          	beq	s1,a0,ffffffffc0204172 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204146:	100027f3          	csrr	a5,sstatus
ffffffffc020414a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020414c:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020414e:	ef9d                	bnez	a5,ffffffffc020418c <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0204150:	755c                	ld	a5,168(a0)
ffffffffc0204152:	577d                	li	a4,-1
ffffffffc0204154:	177e                	slli	a4,a4,0x3f
ffffffffc0204156:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204158:	00a93023          	sd	a0,0(s2)
ffffffffc020415c:	8fd9                	or	a5,a5,a4
ffffffffc020415e:	18079073          	csrw	satp,a5
            switch_to(&(curr->context), &(proc->context));
ffffffffc0204162:	03050593          	addi	a1,a0,48
ffffffffc0204166:	03048513          	addi	a0,s1,48
ffffffffc020416a:	7f5000ef          	jal	ra,ffffffffc020515e <switch_to>
    if (flag)
ffffffffc020416e:	00099863          	bnez	s3,ffffffffc020417e <proc_run+0x52>
}
ffffffffc0204172:	70a2                	ld	ra,40(sp)
ffffffffc0204174:	7482                	ld	s1,32(sp)
ffffffffc0204176:	6962                	ld	s2,24(sp)
ffffffffc0204178:	69c2                	ld	s3,16(sp)
ffffffffc020417a:	6145                	addi	sp,sp,48
ffffffffc020417c:	8082                	ret
ffffffffc020417e:	70a2                	ld	ra,40(sp)
ffffffffc0204180:	7482                	ld	s1,32(sp)
ffffffffc0204182:	6962                	ld	s2,24(sp)
ffffffffc0204184:	69c2                	ld	s3,16(sp)
ffffffffc0204186:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204188:	827fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc020418c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020418e:	827fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204192:	6522                	ld	a0,8(sp)
ffffffffc0204194:	4985                	li	s3,1
ffffffffc0204196:	bf6d                	j	ffffffffc0204150 <proc_run+0x24>

ffffffffc0204198 <do_fork>:
{
ffffffffc0204198:	7119                	addi	sp,sp,-128
ffffffffc020419a:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020419c:	000a6917          	auipc	s2,0xa6
ffffffffc02041a0:	5a490913          	addi	s2,s2,1444 # ffffffffc02aa740 <nr_process>
ffffffffc02041a4:	00092703          	lw	a4,0(s2)
{
ffffffffc02041a8:	fc86                	sd	ra,120(sp)
ffffffffc02041aa:	f8a2                	sd	s0,112(sp)
ffffffffc02041ac:	f4a6                	sd	s1,104(sp)
ffffffffc02041ae:	ecce                	sd	s3,88(sp)
ffffffffc02041b0:	e8d2                	sd	s4,80(sp)
ffffffffc02041b2:	e4d6                	sd	s5,72(sp)
ffffffffc02041b4:	e0da                	sd	s6,64(sp)
ffffffffc02041b6:	fc5e                	sd	s7,56(sp)
ffffffffc02041b8:	f862                	sd	s8,48(sp)
ffffffffc02041ba:	f466                	sd	s9,40(sp)
ffffffffc02041bc:	f06a                	sd	s10,32(sp)
ffffffffc02041be:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02041c0:	6785                	lui	a5,0x1
ffffffffc02041c2:	2ef75c63          	bge	a4,a5,ffffffffc02044ba <do_fork+0x322>
ffffffffc02041c6:	8a2a                	mv	s4,a0
ffffffffc02041c8:	89ae                	mv	s3,a1
ffffffffc02041ca:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc02041cc:	dedff0ef          	jal	ra,ffffffffc0203fb8 <alloc_proc>
ffffffffc02041d0:	84aa                	mv	s1,a0
ffffffffc02041d2:	2c050863          	beqz	a0,ffffffffc02044a2 <do_fork+0x30a>
    proc->parent = current;
ffffffffc02041d6:	000a6c17          	auipc	s8,0xa6
ffffffffc02041da:	552c0c13          	addi	s8,s8,1362 # ffffffffc02aa728 <current>
ffffffffc02041de:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02041e2:	4509                	li	a0,2
    proc->parent = current;
ffffffffc02041e4:	f09c                	sd	a5,32(s1)
    current->wait_state = 0;
ffffffffc02041e6:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8abc>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02041ea:	ceffd0ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
    if (page != NULL)
ffffffffc02041ee:	2a050763          	beqz	a0,ffffffffc020449c <do_fork+0x304>
    return page - pages + nbase;
ffffffffc02041f2:	000a6a97          	auipc	s5,0xa6
ffffffffc02041f6:	51ea8a93          	addi	s5,s5,1310 # ffffffffc02aa710 <pages>
ffffffffc02041fa:	000ab683          	ld	a3,0(s5)
ffffffffc02041fe:	00003b17          	auipc	s6,0x3
ffffffffc0204202:	7d2b0b13          	addi	s6,s6,2002 # ffffffffc02079d0 <nbase>
ffffffffc0204206:	000b3783          	ld	a5,0(s6)
ffffffffc020420a:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc020420e:	000a6b97          	auipc	s7,0xa6
ffffffffc0204212:	4fab8b93          	addi	s7,s7,1274 # ffffffffc02aa708 <npage>
    return page - pages + nbase;
ffffffffc0204216:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204218:	5dfd                	li	s11,-1
ffffffffc020421a:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc020421e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204220:	00cddd93          	srli	s11,s11,0xc
ffffffffc0204224:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204228:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020422a:	2ce67563          	bgeu	a2,a4,ffffffffc02044f4 <do_fork+0x35c>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc020422e:	000c3603          	ld	a2,0(s8)
ffffffffc0204232:	000a6c17          	auipc	s8,0xa6
ffffffffc0204236:	4eec0c13          	addi	s8,s8,1262 # ffffffffc02aa720 <va_pa_offset>
ffffffffc020423a:	000c3703          	ld	a4,0(s8)
ffffffffc020423e:	02863d03          	ld	s10,40(a2)
ffffffffc0204242:	e43e                	sd	a5,8(sp)
ffffffffc0204244:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204246:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0204248:	020d0863          	beqz	s10,ffffffffc0204278 <do_fork+0xe0>
    if (clone_flags & CLONE_VM)
ffffffffc020424c:	100a7a13          	andi	s4,s4,256
ffffffffc0204250:	180a0863          	beqz	s4,ffffffffc02043e0 <do_fork+0x248>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0204254:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204258:	018d3783          	ld	a5,24(s10)
ffffffffc020425c:	c02006b7          	lui	a3,0xc0200
ffffffffc0204260:	2705                	addiw	a4,a4,1
ffffffffc0204262:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0204266:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020426a:	2ad7e163          	bltu	a5,a3,ffffffffc020450c <do_fork+0x374>
ffffffffc020426e:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204272:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204274:	8f99                	sub	a5,a5,a4
ffffffffc0204276:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204278:	6789                	lui	a5,0x2
ffffffffc020427a:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>
ffffffffc020427e:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204280:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204282:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204284:	87b6                	mv	a5,a3
ffffffffc0204286:	12040893          	addi	a7,s0,288
ffffffffc020428a:	00063803          	ld	a6,0(a2)
ffffffffc020428e:	6608                	ld	a0,8(a2)
ffffffffc0204290:	6a0c                	ld	a1,16(a2)
ffffffffc0204292:	6e18                	ld	a4,24(a2)
ffffffffc0204294:	0107b023          	sd	a6,0(a5)
ffffffffc0204298:	e788                	sd	a0,8(a5)
ffffffffc020429a:	eb8c                	sd	a1,16(a5)
ffffffffc020429c:	ef98                	sd	a4,24(a5)
ffffffffc020429e:	02060613          	addi	a2,a2,32
ffffffffc02042a2:	02078793          	addi	a5,a5,32
ffffffffc02042a6:	ff1612e3          	bne	a2,a7,ffffffffc020428a <do_fork+0xf2>
    proc->tf->gpr.a0 = 0;
ffffffffc02042aa:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02042ae:	12098763          	beqz	s3,ffffffffc02043dc <do_fork+0x244>
    if (++last_pid >= MAX_PID)
ffffffffc02042b2:	000a2817          	auipc	a6,0xa2
ffffffffc02042b6:	fe680813          	addi	a6,a6,-26 # ffffffffc02a6298 <last_pid.1>
ffffffffc02042ba:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02042be:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02042c2:	00000717          	auipc	a4,0x0
ffffffffc02042c6:	d6870713          	addi	a4,a4,-664 # ffffffffc020402a <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc02042ca:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02042ce:	f898                	sd	a4,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02042d0:	fc94                	sd	a3,56(s1)
    if (++last_pid >= MAX_PID)
ffffffffc02042d2:	00a82023          	sw	a0,0(a6)
ffffffffc02042d6:	6789                	lui	a5,0x2
ffffffffc02042d8:	08f55b63          	bge	a0,a5,ffffffffc020436e <do_fork+0x1d6>
    if (last_pid >= next_safe)
ffffffffc02042dc:	000a2317          	auipc	t1,0xa2
ffffffffc02042e0:	fc030313          	addi	t1,t1,-64 # ffffffffc02a629c <next_safe.0>
ffffffffc02042e4:	00032783          	lw	a5,0(t1)
ffffffffc02042e8:	000a6417          	auipc	s0,0xa6
ffffffffc02042ec:	3d040413          	addi	s0,s0,976 # ffffffffc02aa6b8 <proc_list>
ffffffffc02042f0:	08f55763          	bge	a0,a5,ffffffffc020437e <do_fork+0x1e6>
    proc->pid = get_pid();
ffffffffc02042f4:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02042f6:	45a9                	li	a1,10
ffffffffc02042f8:	2501                	sext.w	a0,a0
ffffffffc02042fa:	0ba010ef          	jal	ra,ffffffffc02053b4 <hash32>
ffffffffc02042fe:	02051793          	slli	a5,a0,0x20
ffffffffc0204302:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204306:	000a2797          	auipc	a5,0xa2
ffffffffc020430a:	3b278793          	addi	a5,a5,946 # ffffffffc02a66b8 <hash_list>
ffffffffc020430e:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204310:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204312:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204314:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0204318:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020431a:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc020431c:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020431e:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204320:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0204324:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0204326:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0204328:	e21c                	sd	a5,0(a2)
ffffffffc020432a:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc020432c:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc020432e:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204330:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204334:	10e4b023          	sd	a4,256(s1)
ffffffffc0204338:	c311                	beqz	a4,ffffffffc020433c <do_fork+0x1a4>
        proc->optr->yptr = proc;
ffffffffc020433a:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc020433c:	00092783          	lw	a5,0(s2)
    wakeup_proc(proc);
ffffffffc0204340:	8526                	mv	a0,s1
    proc->parent->cptr = proc;
ffffffffc0204342:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204344:	2785                	addiw	a5,a5,1
ffffffffc0204346:	00f92023          	sw	a5,0(s2)
    wakeup_proc(proc);
ffffffffc020434a:	67f000ef          	jal	ra,ffffffffc02051c8 <wakeup_proc>
    ret = proc->pid;
ffffffffc020434e:	40c8                	lw	a0,4(s1)
}
ffffffffc0204350:	70e6                	ld	ra,120(sp)
ffffffffc0204352:	7446                	ld	s0,112(sp)
ffffffffc0204354:	74a6                	ld	s1,104(sp)
ffffffffc0204356:	7906                	ld	s2,96(sp)
ffffffffc0204358:	69e6                	ld	s3,88(sp)
ffffffffc020435a:	6a46                	ld	s4,80(sp)
ffffffffc020435c:	6aa6                	ld	s5,72(sp)
ffffffffc020435e:	6b06                	ld	s6,64(sp)
ffffffffc0204360:	7be2                	ld	s7,56(sp)
ffffffffc0204362:	7c42                	ld	s8,48(sp)
ffffffffc0204364:	7ca2                	ld	s9,40(sp)
ffffffffc0204366:	7d02                	ld	s10,32(sp)
ffffffffc0204368:	6de2                	ld	s11,24(sp)
ffffffffc020436a:	6109                	addi	sp,sp,128
ffffffffc020436c:	8082                	ret
        last_pid = 1;
ffffffffc020436e:	4785                	li	a5,1
ffffffffc0204370:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0204374:	4505                	li	a0,1
ffffffffc0204376:	000a2317          	auipc	t1,0xa2
ffffffffc020437a:	f2630313          	addi	t1,t1,-218 # ffffffffc02a629c <next_safe.0>
    return listelm->next;
ffffffffc020437e:	000a6417          	auipc	s0,0xa6
ffffffffc0204382:	33a40413          	addi	s0,s0,826 # ffffffffc02aa6b8 <proc_list>
ffffffffc0204386:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc020438a:	6789                	lui	a5,0x2
ffffffffc020438c:	00f32023          	sw	a5,0(t1)
ffffffffc0204390:	86aa                	mv	a3,a0
ffffffffc0204392:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204394:	6e89                	lui	t4,0x2
ffffffffc0204396:	108e0d63          	beq	t3,s0,ffffffffc02044b0 <do_fork+0x318>
ffffffffc020439a:	88ae                	mv	a7,a1
ffffffffc020439c:	87f2                	mv	a5,t3
ffffffffc020439e:	6609                	lui	a2,0x2
ffffffffc02043a0:	a811                	j	ffffffffc02043b4 <do_fork+0x21c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02043a2:	00e6d663          	bge	a3,a4,ffffffffc02043ae <do_fork+0x216>
ffffffffc02043a6:	00c75463          	bge	a4,a2,ffffffffc02043ae <do_fork+0x216>
ffffffffc02043aa:	863a                	mv	a2,a4
ffffffffc02043ac:	4885                	li	a7,1
ffffffffc02043ae:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02043b0:	00878d63          	beq	a5,s0,ffffffffc02043ca <do_fork+0x232>
            if (proc->pid == last_pid)
ffffffffc02043b4:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c6c>
ffffffffc02043b8:	fed715e3          	bne	a4,a3,ffffffffc02043a2 <do_fork+0x20a>
                if (++last_pid >= next_safe)
ffffffffc02043bc:	2685                	addiw	a3,a3,1
ffffffffc02043be:	0ec6d463          	bge	a3,a2,ffffffffc02044a6 <do_fork+0x30e>
ffffffffc02043c2:	679c                	ld	a5,8(a5)
ffffffffc02043c4:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02043c6:	fe8797e3          	bne	a5,s0,ffffffffc02043b4 <do_fork+0x21c>
ffffffffc02043ca:	c581                	beqz	a1,ffffffffc02043d2 <do_fork+0x23a>
ffffffffc02043cc:	00d82023          	sw	a3,0(a6)
ffffffffc02043d0:	8536                	mv	a0,a3
ffffffffc02043d2:	f20881e3          	beqz	a7,ffffffffc02042f4 <do_fork+0x15c>
ffffffffc02043d6:	00c32023          	sw	a2,0(t1)
ffffffffc02043da:	bf29                	j	ffffffffc02042f4 <do_fork+0x15c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02043dc:	89b6                	mv	s3,a3
ffffffffc02043de:	bdd1                	j	ffffffffc02042b2 <do_fork+0x11a>
    if ((mm = mm_create()) == NULL)
ffffffffc02043e0:	adcff0ef          	jal	ra,ffffffffc02036bc <mm_create>
ffffffffc02043e4:	8caa                	mv	s9,a0
ffffffffc02043e6:	c159                	beqz	a0,ffffffffc020446c <do_fork+0x2d4>
    if ((page = alloc_page()) == NULL)
ffffffffc02043e8:	4505                	li	a0,1
ffffffffc02043ea:	aeffd0ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc02043ee:	cd25                	beqz	a0,ffffffffc0204466 <do_fork+0x2ce>
    return page - pages + nbase;
ffffffffc02043f0:	000ab683          	ld	a3,0(s5)
ffffffffc02043f4:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc02043f6:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02043fa:	40d506b3          	sub	a3,a0,a3
ffffffffc02043fe:	8699                	srai	a3,a3,0x6
ffffffffc0204400:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204402:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204406:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204408:	0eedf663          	bgeu	s11,a4,ffffffffc02044f4 <do_fork+0x35c>
ffffffffc020440c:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204410:	6605                	lui	a2,0x1
ffffffffc0204412:	000a6597          	auipc	a1,0xa6
ffffffffc0204416:	2ee5b583          	ld	a1,750(a1) # ffffffffc02aa700 <boot_pgdir_va>
ffffffffc020441a:	9a36                	add	s4,s4,a3
ffffffffc020441c:	8552                	mv	a0,s4
ffffffffc020441e:	44e010ef          	jal	ra,ffffffffc020586c <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204422:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc0204426:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020442a:	4785                	li	a5,1
ffffffffc020442c:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204430:	8b85                	andi	a5,a5,1
ffffffffc0204432:	4a05                	li	s4,1
ffffffffc0204434:	c799                	beqz	a5,ffffffffc0204442 <do_fork+0x2aa>
    {
        schedule();
ffffffffc0204436:	613000ef          	jal	ra,ffffffffc0205248 <schedule>
ffffffffc020443a:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc020443e:	8b85                	andi	a5,a5,1
ffffffffc0204440:	fbfd                	bnez	a5,ffffffffc0204436 <do_fork+0x29e>
        ret = dup_mmap(mm, oldmm);
ffffffffc0204442:	85ea                	mv	a1,s10
ffffffffc0204444:	8566                	mv	a0,s9
ffffffffc0204446:	cb8ff0ef          	jal	ra,ffffffffc02038fe <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020444a:	57f9                	li	a5,-2
ffffffffc020444c:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0204450:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204452:	cbad                	beqz	a5,ffffffffc02044c4 <do_fork+0x32c>
good_mm:
ffffffffc0204454:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204456:	de050fe3          	beqz	a0,ffffffffc0204254 <do_fork+0xbc>
    exit_mmap(mm);
ffffffffc020445a:	8566                	mv	a0,s9
ffffffffc020445c:	d3cff0ef          	jal	ra,ffffffffc0203998 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204460:	8566                	mv	a0,s9
ffffffffc0204462:	c55ff0ef          	jal	ra,ffffffffc02040b6 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204466:	8566                	mv	a0,s9
ffffffffc0204468:	b94ff0ef          	jal	ra,ffffffffc02037fc <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020446c:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020446e:	c02007b7          	lui	a5,0xc0200
ffffffffc0204472:	0af6ea63          	bltu	a3,a5,ffffffffc0204526 <do_fork+0x38e>
ffffffffc0204476:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc020447a:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc020447e:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204482:	83b1                	srli	a5,a5,0xc
ffffffffc0204484:	04e7fc63          	bgeu	a5,a4,ffffffffc02044dc <do_fork+0x344>
    return &pages[PPN(pa) - nbase];
ffffffffc0204488:	000b3703          	ld	a4,0(s6)
ffffffffc020448c:	000ab503          	ld	a0,0(s5)
ffffffffc0204490:	4589                	li	a1,2
ffffffffc0204492:	8f99                	sub	a5,a5,a4
ffffffffc0204494:	079a                	slli	a5,a5,0x6
ffffffffc0204496:	953e                	add	a0,a0,a5
ffffffffc0204498:	a7ffd0ef          	jal	ra,ffffffffc0201f16 <free_pages>
    kfree(proc);
ffffffffc020449c:	8526                	mv	a0,s1
ffffffffc020449e:	90dfd0ef          	jal	ra,ffffffffc0201daa <kfree>
    ret = -E_NO_MEM;
ffffffffc02044a2:	5571                	li	a0,-4
    return ret;
ffffffffc02044a4:	b575                	j	ffffffffc0204350 <do_fork+0x1b8>
                    if (last_pid >= MAX_PID)
ffffffffc02044a6:	01d6c363          	blt	a3,t4,ffffffffc02044ac <do_fork+0x314>
                        last_pid = 1;
ffffffffc02044aa:	4685                	li	a3,1
                    goto repeat;
ffffffffc02044ac:	4585                	li	a1,1
ffffffffc02044ae:	b5e5                	j	ffffffffc0204396 <do_fork+0x1fe>
ffffffffc02044b0:	c599                	beqz	a1,ffffffffc02044be <do_fork+0x326>
ffffffffc02044b2:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02044b6:	8536                	mv	a0,a3
ffffffffc02044b8:	bd35                	j	ffffffffc02042f4 <do_fork+0x15c>
    int ret = -E_NO_FREE_PROC;
ffffffffc02044ba:	556d                	li	a0,-5
ffffffffc02044bc:	bd51                	j	ffffffffc0204350 <do_fork+0x1b8>
    return last_pid;
ffffffffc02044be:	00082503          	lw	a0,0(a6)
ffffffffc02044c2:	bd0d                	j	ffffffffc02042f4 <do_fork+0x15c>
    {
        panic("Unlock failed.\n");
ffffffffc02044c4:	00003617          	auipc	a2,0x3
ffffffffc02044c8:	c8c60613          	addi	a2,a2,-884 # ffffffffc0207150 <default_pmm_manager+0xa88>
ffffffffc02044cc:	03f00593          	li	a1,63
ffffffffc02044d0:	00003517          	auipc	a0,0x3
ffffffffc02044d4:	c9050513          	addi	a0,a0,-880 # ffffffffc0207160 <default_pmm_manager+0xa98>
ffffffffc02044d8:	fb7fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02044dc:	00002617          	auipc	a2,0x2
ffffffffc02044e0:	2f460613          	addi	a2,a2,756 # ffffffffc02067d0 <default_pmm_manager+0x108>
ffffffffc02044e4:	06a00593          	li	a1,106
ffffffffc02044e8:	00002517          	auipc	a0,0x2
ffffffffc02044ec:	24050513          	addi	a0,a0,576 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc02044f0:	f9ffb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02044f4:	00002617          	auipc	a2,0x2
ffffffffc02044f8:	20c60613          	addi	a2,a2,524 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc02044fc:	07200593          	li	a1,114
ffffffffc0204500:	00002517          	auipc	a0,0x2
ffffffffc0204504:	22850513          	addi	a0,a0,552 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0204508:	f87fb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020450c:	86be                	mv	a3,a5
ffffffffc020450e:	00002617          	auipc	a2,0x2
ffffffffc0204512:	29a60613          	addi	a2,a2,666 # ffffffffc02067a8 <default_pmm_manager+0xe0>
ffffffffc0204516:	18b00593          	li	a1,395
ffffffffc020451a:	00003517          	auipc	a0,0x3
ffffffffc020451e:	c1e50513          	addi	a0,a0,-994 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0204522:	f6dfb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204526:	00002617          	auipc	a2,0x2
ffffffffc020452a:	28260613          	addi	a2,a2,642 # ffffffffc02067a8 <default_pmm_manager+0xe0>
ffffffffc020452e:	07800593          	li	a1,120
ffffffffc0204532:	00002517          	auipc	a0,0x2
ffffffffc0204536:	1f650513          	addi	a0,a0,502 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc020453a:	f55fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020453e <kernel_thread>:
{
ffffffffc020453e:	7129                	addi	sp,sp,-320
ffffffffc0204540:	fa22                	sd	s0,304(sp)
ffffffffc0204542:	f626                	sd	s1,296(sp)
ffffffffc0204544:	f24a                	sd	s2,288(sp)
ffffffffc0204546:	84ae                	mv	s1,a1
ffffffffc0204548:	892a                	mv	s2,a0
ffffffffc020454a:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020454c:	4581                	li	a1,0
ffffffffc020454e:	12000613          	li	a2,288
ffffffffc0204552:	850a                	mv	a0,sp
{
ffffffffc0204554:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204556:	304010ef          	jal	ra,ffffffffc020585a <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020455a:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020455c:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020455e:	100027f3          	csrr	a5,sstatus
ffffffffc0204562:	edd7f793          	andi	a5,a5,-291
ffffffffc0204566:	1207e793          	ori	a5,a5,288
ffffffffc020456a:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020456c:	860a                	mv	a2,sp
ffffffffc020456e:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204572:	00000797          	auipc	a5,0x0
ffffffffc0204576:	a3e78793          	addi	a5,a5,-1474 # ffffffffc0203fb0 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020457a:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020457c:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020457e:	c1bff0ef          	jal	ra,ffffffffc0204198 <do_fork>
}
ffffffffc0204582:	70f2                	ld	ra,312(sp)
ffffffffc0204584:	7452                	ld	s0,304(sp)
ffffffffc0204586:	74b2                	ld	s1,296(sp)
ffffffffc0204588:	7912                	ld	s2,288(sp)
ffffffffc020458a:	6131                	addi	sp,sp,320
ffffffffc020458c:	8082                	ret

ffffffffc020458e <do_exit>:
{
ffffffffc020458e:	7179                	addi	sp,sp,-48
ffffffffc0204590:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204592:	000a6417          	auipc	s0,0xa6
ffffffffc0204596:	19640413          	addi	s0,s0,406 # ffffffffc02aa728 <current>
ffffffffc020459a:	601c                	ld	a5,0(s0)
{
ffffffffc020459c:	f406                	sd	ra,40(sp)
ffffffffc020459e:	ec26                	sd	s1,24(sp)
ffffffffc02045a0:	e84a                	sd	s2,16(sp)
ffffffffc02045a2:	e44e                	sd	s3,8(sp)
ffffffffc02045a4:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02045a6:	000a6717          	auipc	a4,0xa6
ffffffffc02045aa:	18a73703          	ld	a4,394(a4) # ffffffffc02aa730 <idleproc>
ffffffffc02045ae:	0ce78c63          	beq	a5,a4,ffffffffc0204686 <do_exit+0xf8>
    if (current == initproc)
ffffffffc02045b2:	000a6497          	auipc	s1,0xa6
ffffffffc02045b6:	18648493          	addi	s1,s1,390 # ffffffffc02aa738 <initproc>
ffffffffc02045ba:	6098                	ld	a4,0(s1)
ffffffffc02045bc:	0ee78b63          	beq	a5,a4,ffffffffc02046b2 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02045c0:	0287b983          	ld	s3,40(a5)
ffffffffc02045c4:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02045c6:	02098663          	beqz	s3,ffffffffc02045f2 <do_exit+0x64>
ffffffffc02045ca:	000a6797          	auipc	a5,0xa6
ffffffffc02045ce:	12e7b783          	ld	a5,302(a5) # ffffffffc02aa6f8 <boot_pgdir_pa>
ffffffffc02045d2:	577d                	li	a4,-1
ffffffffc02045d4:	177e                	slli	a4,a4,0x3f
ffffffffc02045d6:	83b1                	srli	a5,a5,0xc
ffffffffc02045d8:	8fd9                	or	a5,a5,a4
ffffffffc02045da:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02045de:	0309a783          	lw	a5,48(s3)
ffffffffc02045e2:	fff7871b          	addiw	a4,a5,-1
ffffffffc02045e6:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02045ea:	cb55                	beqz	a4,ffffffffc020469e <do_exit+0x110>
        current->mm = NULL;
ffffffffc02045ec:	601c                	ld	a5,0(s0)
ffffffffc02045ee:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02045f2:	601c                	ld	a5,0(s0)
ffffffffc02045f4:	470d                	li	a4,3
ffffffffc02045f6:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02045f8:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045fc:	100027f3          	csrr	a5,sstatus
ffffffffc0204600:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204602:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204604:	e3f9                	bnez	a5,ffffffffc02046ca <do_exit+0x13c>
        proc = current->parent;
ffffffffc0204606:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204608:	800007b7          	lui	a5,0x80000
ffffffffc020460c:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc020460e:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204610:	0ec52703          	lw	a4,236(a0)
ffffffffc0204614:	0af70f63          	beq	a4,a5,ffffffffc02046d2 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc0204618:	6018                	ld	a4,0(s0)
ffffffffc020461a:	7b7c                	ld	a5,240(a4)
ffffffffc020461c:	c3a1                	beqz	a5,ffffffffc020465c <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020461e:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204622:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204624:	0985                	addi	s3,s3,1
ffffffffc0204626:	a021                	j	ffffffffc020462e <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204628:	6018                	ld	a4,0(s0)
ffffffffc020462a:	7b7c                	ld	a5,240(a4)
ffffffffc020462c:	cb85                	beqz	a5,ffffffffc020465c <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc020462e:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fe0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204632:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204634:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204636:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204638:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020463c:	10e7b023          	sd	a4,256(a5)
ffffffffc0204640:	c311                	beqz	a4,ffffffffc0204644 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204642:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204644:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204646:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204648:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020464a:	fd271fe3          	bne	a4,s2,ffffffffc0204628 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020464e:	0ec52783          	lw	a5,236(a0)
ffffffffc0204652:	fd379be3          	bne	a5,s3,ffffffffc0204628 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204656:	373000ef          	jal	ra,ffffffffc02051c8 <wakeup_proc>
ffffffffc020465a:	b7f9                	j	ffffffffc0204628 <do_exit+0x9a>
    if (flag)
ffffffffc020465c:	020a1263          	bnez	s4,ffffffffc0204680 <do_exit+0xf2>
    schedule();
ffffffffc0204660:	3e9000ef          	jal	ra,ffffffffc0205248 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204664:	601c                	ld	a5,0(s0)
ffffffffc0204666:	00003617          	auipc	a2,0x3
ffffffffc020466a:	b3260613          	addi	a2,a2,-1230 # ffffffffc0207198 <default_pmm_manager+0xad0>
ffffffffc020466e:	23500593          	li	a1,565
ffffffffc0204672:	43d4                	lw	a3,4(a5)
ffffffffc0204674:	00003517          	auipc	a0,0x3
ffffffffc0204678:	ac450513          	addi	a0,a0,-1340 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc020467c:	e13fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc0204680:	b2efc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204684:	bff1                	j	ffffffffc0204660 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204686:	00003617          	auipc	a2,0x3
ffffffffc020468a:	af260613          	addi	a2,a2,-1294 # ffffffffc0207178 <default_pmm_manager+0xab0>
ffffffffc020468e:	20100593          	li	a1,513
ffffffffc0204692:	00003517          	auipc	a0,0x3
ffffffffc0204696:	aa650513          	addi	a0,a0,-1370 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc020469a:	df5fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc020469e:	854e                	mv	a0,s3
ffffffffc02046a0:	af8ff0ef          	jal	ra,ffffffffc0203998 <exit_mmap>
            put_pgdir(mm);
ffffffffc02046a4:	854e                	mv	a0,s3
ffffffffc02046a6:	a11ff0ef          	jal	ra,ffffffffc02040b6 <put_pgdir>
            mm_destroy(mm);
ffffffffc02046aa:	854e                	mv	a0,s3
ffffffffc02046ac:	950ff0ef          	jal	ra,ffffffffc02037fc <mm_destroy>
ffffffffc02046b0:	bf35                	j	ffffffffc02045ec <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02046b2:	00003617          	auipc	a2,0x3
ffffffffc02046b6:	ad660613          	addi	a2,a2,-1322 # ffffffffc0207188 <default_pmm_manager+0xac0>
ffffffffc02046ba:	20500593          	li	a1,517
ffffffffc02046be:	00003517          	auipc	a0,0x3
ffffffffc02046c2:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc02046c6:	dc9fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02046ca:	aeafc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02046ce:	4a05                	li	s4,1
ffffffffc02046d0:	bf1d                	j	ffffffffc0204606 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02046d2:	2f7000ef          	jal	ra,ffffffffc02051c8 <wakeup_proc>
ffffffffc02046d6:	b789                	j	ffffffffc0204618 <do_exit+0x8a>

ffffffffc02046d8 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02046d8:	715d                	addi	sp,sp,-80
ffffffffc02046da:	f84a                	sd	s2,48(sp)
ffffffffc02046dc:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc02046de:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc02046e2:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02046e4:	fc26                	sd	s1,56(sp)
ffffffffc02046e6:	f052                	sd	s4,32(sp)
ffffffffc02046e8:	ec56                	sd	s5,24(sp)
ffffffffc02046ea:	e85a                	sd	s6,16(sp)
ffffffffc02046ec:	e45e                	sd	s7,8(sp)
ffffffffc02046ee:	e486                	sd	ra,72(sp)
ffffffffc02046f0:	e0a2                	sd	s0,64(sp)
ffffffffc02046f2:	84aa                	mv	s1,a0
ffffffffc02046f4:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc02046f6:	000a6b97          	auipc	s7,0xa6
ffffffffc02046fa:	032b8b93          	addi	s7,s7,50 # ffffffffc02aa728 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc02046fe:	00050b1b          	sext.w	s6,a0
ffffffffc0204702:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204706:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204708:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc020470a:	ccbd                	beqz	s1,ffffffffc0204788 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc020470c:	0359e863          	bltu	s3,s5,ffffffffc020473c <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204710:	45a9                	li	a1,10
ffffffffc0204712:	855a                	mv	a0,s6
ffffffffc0204714:	4a1000ef          	jal	ra,ffffffffc02053b4 <hash32>
ffffffffc0204718:	02051793          	slli	a5,a0,0x20
ffffffffc020471c:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204720:	000a2797          	auipc	a5,0xa2
ffffffffc0204724:	f9878793          	addi	a5,a5,-104 # ffffffffc02a66b8 <hash_list>
ffffffffc0204728:	953e                	add	a0,a0,a5
ffffffffc020472a:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc020472c:	a029                	j	ffffffffc0204736 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc020472e:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204732:	02978163          	beq	a5,s1,ffffffffc0204754 <do_wait.part.0+0x7c>
ffffffffc0204736:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204738:	fe851be3          	bne	a0,s0,ffffffffc020472e <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc020473c:	5579                	li	a0,-2
}
ffffffffc020473e:	60a6                	ld	ra,72(sp)
ffffffffc0204740:	6406                	ld	s0,64(sp)
ffffffffc0204742:	74e2                	ld	s1,56(sp)
ffffffffc0204744:	7942                	ld	s2,48(sp)
ffffffffc0204746:	79a2                	ld	s3,40(sp)
ffffffffc0204748:	7a02                	ld	s4,32(sp)
ffffffffc020474a:	6ae2                	ld	s5,24(sp)
ffffffffc020474c:	6b42                	ld	s6,16(sp)
ffffffffc020474e:	6ba2                	ld	s7,8(sp)
ffffffffc0204750:	6161                	addi	sp,sp,80
ffffffffc0204752:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204754:	000bb683          	ld	a3,0(s7)
ffffffffc0204758:	f4843783          	ld	a5,-184(s0)
ffffffffc020475c:	fed790e3          	bne	a5,a3,ffffffffc020473c <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204760:	f2842703          	lw	a4,-216(s0)
ffffffffc0204764:	478d                	li	a5,3
ffffffffc0204766:	0ef70b63          	beq	a4,a5,ffffffffc020485c <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc020476a:	4785                	li	a5,1
ffffffffc020476c:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc020476e:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204772:	2d7000ef          	jal	ra,ffffffffc0205248 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204776:	000bb783          	ld	a5,0(s7)
ffffffffc020477a:	0b07a783          	lw	a5,176(a5)
ffffffffc020477e:	8b85                	andi	a5,a5,1
ffffffffc0204780:	d7c9                	beqz	a5,ffffffffc020470a <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204782:	555d                	li	a0,-9
ffffffffc0204784:	e0bff0ef          	jal	ra,ffffffffc020458e <do_exit>
        proc = current->cptr;
ffffffffc0204788:	000bb683          	ld	a3,0(s7)
ffffffffc020478c:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc020478e:	d45d                	beqz	s0,ffffffffc020473c <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204790:	470d                	li	a4,3
ffffffffc0204792:	a021                	j	ffffffffc020479a <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204794:	10043403          	ld	s0,256(s0)
ffffffffc0204798:	d869                	beqz	s0,ffffffffc020476a <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020479a:	401c                	lw	a5,0(s0)
ffffffffc020479c:	fee79ce3          	bne	a5,a4,ffffffffc0204794 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02047a0:	000a6797          	auipc	a5,0xa6
ffffffffc02047a4:	f907b783          	ld	a5,-112(a5) # ffffffffc02aa730 <idleproc>
ffffffffc02047a8:	0c878963          	beq	a5,s0,ffffffffc020487a <do_wait.part.0+0x1a2>
ffffffffc02047ac:	000a6797          	auipc	a5,0xa6
ffffffffc02047b0:	f8c7b783          	ld	a5,-116(a5) # ffffffffc02aa738 <initproc>
ffffffffc02047b4:	0cf40363          	beq	s0,a5,ffffffffc020487a <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02047b8:	000a0663          	beqz	s4,ffffffffc02047c4 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02047bc:	0e842783          	lw	a5,232(s0)
ffffffffc02047c0:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047c4:	100027f3          	csrr	a5,sstatus
ffffffffc02047c8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02047ca:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047cc:	e7c1                	bnez	a5,ffffffffc0204854 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02047ce:	6c70                	ld	a2,216(s0)
ffffffffc02047d0:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02047d2:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02047d6:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02047d8:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02047da:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02047dc:	6470                	ld	a2,200(s0)
ffffffffc02047de:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02047e0:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02047e2:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02047e4:	c319                	beqz	a4,ffffffffc02047ea <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02047e6:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02047e8:	7c7c                	ld	a5,248(s0)
ffffffffc02047ea:	c3b5                	beqz	a5,ffffffffc020484e <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02047ec:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02047f0:	000a6717          	auipc	a4,0xa6
ffffffffc02047f4:	f5070713          	addi	a4,a4,-176 # ffffffffc02aa740 <nr_process>
ffffffffc02047f8:	431c                	lw	a5,0(a4)
ffffffffc02047fa:	37fd                	addiw	a5,a5,-1
ffffffffc02047fc:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc02047fe:	e5a9                	bnez	a1,ffffffffc0204848 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204800:	6814                	ld	a3,16(s0)
ffffffffc0204802:	c02007b7          	lui	a5,0xc0200
ffffffffc0204806:	04f6ee63          	bltu	a3,a5,ffffffffc0204862 <do_wait.part.0+0x18a>
ffffffffc020480a:	000a6797          	auipc	a5,0xa6
ffffffffc020480e:	f167b783          	ld	a5,-234(a5) # ffffffffc02aa720 <va_pa_offset>
ffffffffc0204812:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204814:	82b1                	srli	a3,a3,0xc
ffffffffc0204816:	000a6797          	auipc	a5,0xa6
ffffffffc020481a:	ef27b783          	ld	a5,-270(a5) # ffffffffc02aa708 <npage>
ffffffffc020481e:	06f6fa63          	bgeu	a3,a5,ffffffffc0204892 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204822:	00003517          	auipc	a0,0x3
ffffffffc0204826:	1ae53503          	ld	a0,430(a0) # ffffffffc02079d0 <nbase>
ffffffffc020482a:	8e89                	sub	a3,a3,a0
ffffffffc020482c:	069a                	slli	a3,a3,0x6
ffffffffc020482e:	000a6517          	auipc	a0,0xa6
ffffffffc0204832:	ee253503          	ld	a0,-286(a0) # ffffffffc02aa710 <pages>
ffffffffc0204836:	9536                	add	a0,a0,a3
ffffffffc0204838:	4589                	li	a1,2
ffffffffc020483a:	edcfd0ef          	jal	ra,ffffffffc0201f16 <free_pages>
    kfree(proc);
ffffffffc020483e:	8522                	mv	a0,s0
ffffffffc0204840:	d6afd0ef          	jal	ra,ffffffffc0201daa <kfree>
    return 0;
ffffffffc0204844:	4501                	li	a0,0
ffffffffc0204846:	bde5                	j	ffffffffc020473e <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204848:	966fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020484c:	bf55                	j	ffffffffc0204800 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc020484e:	701c                	ld	a5,32(s0)
ffffffffc0204850:	fbf8                	sd	a4,240(a5)
ffffffffc0204852:	bf79                	j	ffffffffc02047f0 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204854:	960fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204858:	4585                	li	a1,1
ffffffffc020485a:	bf95                	j	ffffffffc02047ce <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020485c:	f2840413          	addi	s0,s0,-216
ffffffffc0204860:	b781                	j	ffffffffc02047a0 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204862:	00002617          	auipc	a2,0x2
ffffffffc0204866:	f4660613          	addi	a2,a2,-186 # ffffffffc02067a8 <default_pmm_manager+0xe0>
ffffffffc020486a:	07800593          	li	a1,120
ffffffffc020486e:	00002517          	auipc	a0,0x2
ffffffffc0204872:	eba50513          	addi	a0,a0,-326 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0204876:	c19fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc020487a:	00003617          	auipc	a2,0x3
ffffffffc020487e:	93e60613          	addi	a2,a2,-1730 # ffffffffc02071b8 <default_pmm_manager+0xaf0>
ffffffffc0204882:	35500593          	li	a1,853
ffffffffc0204886:	00003517          	auipc	a0,0x3
ffffffffc020488a:	8b250513          	addi	a0,a0,-1870 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc020488e:	c01fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204892:	00002617          	auipc	a2,0x2
ffffffffc0204896:	f3e60613          	addi	a2,a2,-194 # ffffffffc02067d0 <default_pmm_manager+0x108>
ffffffffc020489a:	06a00593          	li	a1,106
ffffffffc020489e:	00002517          	auipc	a0,0x2
ffffffffc02048a2:	e8a50513          	addi	a0,a0,-374 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc02048a6:	be9fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02048aa <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02048aa:	1141                	addi	sp,sp,-16
ffffffffc02048ac:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02048ae:	ea8fd0ef          	jal	ra,ffffffffc0201f56 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02048b2:	c44fd0ef          	jal	ra,ffffffffc0201cf6 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02048b6:	4601                	li	a2,0
ffffffffc02048b8:	4581                	li	a1,0
ffffffffc02048ba:	fffff517          	auipc	a0,0xfffff
ffffffffc02048be:	77e50513          	addi	a0,a0,1918 # ffffffffc0204038 <user_main>
ffffffffc02048c2:	c7dff0ef          	jal	ra,ffffffffc020453e <kernel_thread>
    if (pid <= 0)
ffffffffc02048c6:	00a04563          	bgtz	a0,ffffffffc02048d0 <init_main+0x26>
ffffffffc02048ca:	a071                	j	ffffffffc0204956 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02048cc:	17d000ef          	jal	ra,ffffffffc0205248 <schedule>
    if (code_store != NULL)
ffffffffc02048d0:	4581                	li	a1,0
ffffffffc02048d2:	4501                	li	a0,0
ffffffffc02048d4:	e05ff0ef          	jal	ra,ffffffffc02046d8 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02048d8:	d975                	beqz	a0,ffffffffc02048cc <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02048da:	00003517          	auipc	a0,0x3
ffffffffc02048de:	91e50513          	addi	a0,a0,-1762 # ffffffffc02071f8 <default_pmm_manager+0xb30>
ffffffffc02048e2:	8b3fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02048e6:	000a6797          	auipc	a5,0xa6
ffffffffc02048ea:	e527b783          	ld	a5,-430(a5) # ffffffffc02aa738 <initproc>
ffffffffc02048ee:	7bf8                	ld	a4,240(a5)
ffffffffc02048f0:	e339                	bnez	a4,ffffffffc0204936 <init_main+0x8c>
ffffffffc02048f2:	7ff8                	ld	a4,248(a5)
ffffffffc02048f4:	e329                	bnez	a4,ffffffffc0204936 <init_main+0x8c>
ffffffffc02048f6:	1007b703          	ld	a4,256(a5)
ffffffffc02048fa:	ef15                	bnez	a4,ffffffffc0204936 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02048fc:	000a6697          	auipc	a3,0xa6
ffffffffc0204900:	e446a683          	lw	a3,-444(a3) # ffffffffc02aa740 <nr_process>
ffffffffc0204904:	4709                	li	a4,2
ffffffffc0204906:	0ae69463          	bne	a3,a4,ffffffffc02049ae <init_main+0x104>
    return listelm->next;
ffffffffc020490a:	000a6697          	auipc	a3,0xa6
ffffffffc020490e:	dae68693          	addi	a3,a3,-594 # ffffffffc02aa6b8 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204912:	6698                	ld	a4,8(a3)
ffffffffc0204914:	0c878793          	addi	a5,a5,200
ffffffffc0204918:	06f71b63          	bne	a4,a5,ffffffffc020498e <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020491c:	629c                	ld	a5,0(a3)
ffffffffc020491e:	04f71863          	bne	a4,a5,ffffffffc020496e <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204922:	00003517          	auipc	a0,0x3
ffffffffc0204926:	9be50513          	addi	a0,a0,-1602 # ffffffffc02072e0 <default_pmm_manager+0xc18>
ffffffffc020492a:	86bfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc020492e:	60a2                	ld	ra,8(sp)
ffffffffc0204930:	4501                	li	a0,0
ffffffffc0204932:	0141                	addi	sp,sp,16
ffffffffc0204934:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204936:	00003697          	auipc	a3,0x3
ffffffffc020493a:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0207220 <default_pmm_manager+0xb58>
ffffffffc020493e:	00002617          	auipc	a2,0x2
ffffffffc0204942:	9da60613          	addi	a2,a2,-1574 # ffffffffc0206318 <commands+0x828>
ffffffffc0204946:	3c300593          	li	a1,963
ffffffffc020494a:	00002517          	auipc	a0,0x2
ffffffffc020494e:	7ee50513          	addi	a0,a0,2030 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0204952:	b3dfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204956:	00003617          	auipc	a2,0x3
ffffffffc020495a:	88260613          	addi	a2,a2,-1918 # ffffffffc02071d8 <default_pmm_manager+0xb10>
ffffffffc020495e:	3ba00593          	li	a1,954
ffffffffc0204962:	00002517          	auipc	a0,0x2
ffffffffc0204966:	7d650513          	addi	a0,a0,2006 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc020496a:	b25fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020496e:	00003697          	auipc	a3,0x3
ffffffffc0204972:	94268693          	addi	a3,a3,-1726 # ffffffffc02072b0 <default_pmm_manager+0xbe8>
ffffffffc0204976:	00002617          	auipc	a2,0x2
ffffffffc020497a:	9a260613          	addi	a2,a2,-1630 # ffffffffc0206318 <commands+0x828>
ffffffffc020497e:	3c600593          	li	a1,966
ffffffffc0204982:	00002517          	auipc	a0,0x2
ffffffffc0204986:	7b650513          	addi	a0,a0,1974 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc020498a:	b05fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020498e:	00003697          	auipc	a3,0x3
ffffffffc0204992:	8f268693          	addi	a3,a3,-1806 # ffffffffc0207280 <default_pmm_manager+0xbb8>
ffffffffc0204996:	00002617          	auipc	a2,0x2
ffffffffc020499a:	98260613          	addi	a2,a2,-1662 # ffffffffc0206318 <commands+0x828>
ffffffffc020499e:	3c500593          	li	a1,965
ffffffffc02049a2:	00002517          	auipc	a0,0x2
ffffffffc02049a6:	79650513          	addi	a0,a0,1942 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc02049aa:	ae5fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc02049ae:	00003697          	auipc	a3,0x3
ffffffffc02049b2:	8c268693          	addi	a3,a3,-1854 # ffffffffc0207270 <default_pmm_manager+0xba8>
ffffffffc02049b6:	00002617          	auipc	a2,0x2
ffffffffc02049ba:	96260613          	addi	a2,a2,-1694 # ffffffffc0206318 <commands+0x828>
ffffffffc02049be:	3c400593          	li	a1,964
ffffffffc02049c2:	00002517          	auipc	a0,0x2
ffffffffc02049c6:	77650513          	addi	a0,a0,1910 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc02049ca:	ac5fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02049ce <do_execve>:
{
ffffffffc02049ce:	7171                	addi	sp,sp,-176
ffffffffc02049d0:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02049d2:	000a6d97          	auipc	s11,0xa6
ffffffffc02049d6:	d56d8d93          	addi	s11,s11,-682 # ffffffffc02aa728 <current>
ffffffffc02049da:	000db783          	ld	a5,0(s11)
{
ffffffffc02049de:	e94a                	sd	s2,144(sp)
ffffffffc02049e0:	f122                	sd	s0,160(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02049e2:	0287b903          	ld	s2,40(a5)
{
ffffffffc02049e6:	ed26                	sd	s1,152(sp)
ffffffffc02049e8:	f8da                	sd	s6,112(sp)
ffffffffc02049ea:	84aa                	mv	s1,a0
ffffffffc02049ec:	8b32                	mv	s6,a2
ffffffffc02049ee:	842e                	mv	s0,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02049f0:	862e                	mv	a2,a1
ffffffffc02049f2:	4681                	li	a3,0
ffffffffc02049f4:	85aa                	mv	a1,a0
ffffffffc02049f6:	854a                	mv	a0,s2
{
ffffffffc02049f8:	f506                	sd	ra,168(sp)
ffffffffc02049fa:	e54e                	sd	s3,136(sp)
ffffffffc02049fc:	e152                	sd	s4,128(sp)
ffffffffc02049fe:	fcd6                	sd	s5,120(sp)
ffffffffc0204a00:	f4de                	sd	s7,104(sp)
ffffffffc0204a02:	f0e2                	sd	s8,96(sp)
ffffffffc0204a04:	ece6                	sd	s9,88(sp)
ffffffffc0204a06:	e8ea                	sd	s10,80(sp)
ffffffffc0204a08:	f05a                	sd	s6,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204a0a:	d12ff0ef          	jal	ra,ffffffffc0203f1c <user_mem_check>
ffffffffc0204a0e:	40050a63          	beqz	a0,ffffffffc0204e22 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204a12:	4641                	li	a2,16
ffffffffc0204a14:	4581                	li	a1,0
ffffffffc0204a16:	1808                	addi	a0,sp,48
ffffffffc0204a18:	643000ef          	jal	ra,ffffffffc020585a <memset>
    memcpy(local_name, name, len);
ffffffffc0204a1c:	47bd                	li	a5,15
ffffffffc0204a1e:	8622                	mv	a2,s0
ffffffffc0204a20:	1e87e263          	bltu	a5,s0,ffffffffc0204c04 <do_execve+0x236>
ffffffffc0204a24:	85a6                	mv	a1,s1
ffffffffc0204a26:	1808                	addi	a0,sp,48
ffffffffc0204a28:	645000ef          	jal	ra,ffffffffc020586c <memcpy>
    if (mm != NULL)
ffffffffc0204a2c:	1e090363          	beqz	s2,ffffffffc0204c12 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204a30:	00002517          	auipc	a0,0x2
ffffffffc0204a34:	4c850513          	addi	a0,a0,1224 # ffffffffc0206ef8 <default_pmm_manager+0x830>
ffffffffc0204a38:	f94fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204a3c:	000a6797          	auipc	a5,0xa6
ffffffffc0204a40:	cbc7b783          	ld	a5,-836(a5) # ffffffffc02aa6f8 <boot_pgdir_pa>
ffffffffc0204a44:	577d                	li	a4,-1
ffffffffc0204a46:	177e                	slli	a4,a4,0x3f
ffffffffc0204a48:	83b1                	srli	a5,a5,0xc
ffffffffc0204a4a:	8fd9                	or	a5,a5,a4
ffffffffc0204a4c:	18079073          	csrw	satp,a5
ffffffffc0204a50:	03092783          	lw	a5,48(s2) # ffffffff80000030 <_binary_obj___user_exit_out_size+0xffffffff7fff4f10>
ffffffffc0204a54:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204a58:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204a5c:	2c070463          	beqz	a4,ffffffffc0204d24 <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204a60:	000db783          	ld	a5,0(s11)
ffffffffc0204a64:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204a68:	c55fe0ef          	jal	ra,ffffffffc02036bc <mm_create>
ffffffffc0204a6c:	842a                	mv	s0,a0
ffffffffc0204a6e:	1c050d63          	beqz	a0,ffffffffc0204c48 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204a72:	4505                	li	a0,1
ffffffffc0204a74:	c64fd0ef          	jal	ra,ffffffffc0201ed8 <alloc_pages>
ffffffffc0204a78:	3a050963          	beqz	a0,ffffffffc0204e2a <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204a7c:	000a6c97          	auipc	s9,0xa6
ffffffffc0204a80:	c94c8c93          	addi	s9,s9,-876 # ffffffffc02aa710 <pages>
ffffffffc0204a84:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204a88:	000a6c17          	auipc	s8,0xa6
ffffffffc0204a8c:	c80c0c13          	addi	s8,s8,-896 # ffffffffc02aa708 <npage>
    return page - pages + nbase;
ffffffffc0204a90:	00003717          	auipc	a4,0x3
ffffffffc0204a94:	f4073703          	ld	a4,-192(a4) # ffffffffc02079d0 <nbase>
ffffffffc0204a98:	40d506b3          	sub	a3,a0,a3
ffffffffc0204a9c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204a9e:	5a7d                	li	s4,-1
ffffffffc0204aa0:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204aa4:	96ba                	add	a3,a3,a4
ffffffffc0204aa6:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204aa8:	00ca5713          	srli	a4,s4,0xc
ffffffffc0204aac:	ec3a                	sd	a4,24(sp)
ffffffffc0204aae:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ab0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ab2:	38f77063          	bgeu	a4,a5,ffffffffc0204e32 <do_execve+0x464>
ffffffffc0204ab6:	000a6a97          	auipc	s5,0xa6
ffffffffc0204aba:	c6aa8a93          	addi	s5,s5,-918 # ffffffffc02aa720 <va_pa_offset>
ffffffffc0204abe:	000ab483          	ld	s1,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204ac2:	6605                	lui	a2,0x1
ffffffffc0204ac4:	000a6597          	auipc	a1,0xa6
ffffffffc0204ac8:	c3c5b583          	ld	a1,-964(a1) # ffffffffc02aa700 <boot_pgdir_va>
ffffffffc0204acc:	94b6                	add	s1,s1,a3
ffffffffc0204ace:	8526                	mv	a0,s1
ffffffffc0204ad0:	59d000ef          	jal	ra,ffffffffc020586c <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204ad4:	7782                	ld	a5,32(sp)
ffffffffc0204ad6:	4398                	lw	a4,0(a5)
ffffffffc0204ad8:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204adc:	ec04                	sd	s1,24(s0)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204ade:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b945f>
ffffffffc0204ae2:	14f71963          	bne	a4,a5,ffffffffc0204c34 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ae6:	7682                	ld	a3,32(sp)
    struct Page *page = NULL;
ffffffffc0204ae8:	4b81                	li	s7,0
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204aea:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204aee:	0206b903          	ld	s2,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204af2:	00371793          	slli	a5,a4,0x3
ffffffffc0204af6:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204af8:	9936                	add	s2,s2,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204afa:	078e                	slli	a5,a5,0x3
ffffffffc0204afc:	97ca                	add	a5,a5,s2
ffffffffc0204afe:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204b00:	00f97c63          	bgeu	s2,a5,ffffffffc0204b18 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204b04:	00092783          	lw	a5,0(s2)
ffffffffc0204b08:	4705                	li	a4,1
ffffffffc0204b0a:	14e78163          	beq	a5,a4,ffffffffc0204c4c <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204b0e:	77a2                	ld	a5,40(sp)
ffffffffc0204b10:	03890913          	addi	s2,s2,56
ffffffffc0204b14:	fef968e3          	bltu	s2,a5,ffffffffc0204b04 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204b18:	4701                	li	a4,0
ffffffffc0204b1a:	46ad                	li	a3,11
ffffffffc0204b1c:	00100637          	lui	a2,0x100
ffffffffc0204b20:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204b24:	8522                	mv	a0,s0
ffffffffc0204b26:	d29fe0ef          	jal	ra,ffffffffc020384e <mm_map>
ffffffffc0204b2a:	89aa                	mv	s3,a0
ffffffffc0204b2c:	1e051263          	bnez	a0,ffffffffc0204d10 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204b30:	6c08                	ld	a0,24(s0)
ffffffffc0204b32:	467d                	li	a2,31
ffffffffc0204b34:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204b38:	a9ffe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc0204b3c:	38050363          	beqz	a0,ffffffffc0204ec2 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b40:	6c08                	ld	a0,24(s0)
ffffffffc0204b42:	467d                	li	a2,31
ffffffffc0204b44:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204b48:	a8ffe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc0204b4c:	34050b63          	beqz	a0,ffffffffc0204ea2 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b50:	6c08                	ld	a0,24(s0)
ffffffffc0204b52:	467d                	li	a2,31
ffffffffc0204b54:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204b58:	a7ffe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc0204b5c:	32050363          	beqz	a0,ffffffffc0204e82 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b60:	6c08                	ld	a0,24(s0)
ffffffffc0204b62:	467d                	li	a2,31
ffffffffc0204b64:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b68:	a6ffe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc0204b6c:	2e050b63          	beqz	a0,ffffffffc0204e62 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204b70:	581c                	lw	a5,48(s0)
    current->mm = mm;
ffffffffc0204b72:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b76:	6c14                	ld	a3,24(s0)
ffffffffc0204b78:	2785                	addiw	a5,a5,1
ffffffffc0204b7a:	d81c                	sw	a5,48(s0)
    current->mm = mm;
ffffffffc0204b7c:	f600                	sd	s0,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b7e:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b82:	2cf6e463          	bltu	a3,a5,ffffffffc0204e4a <do_execve+0x47c>
ffffffffc0204b86:	000ab783          	ld	a5,0(s5)
ffffffffc0204b8a:	577d                	li	a4,-1
ffffffffc0204b8c:	177e                	slli	a4,a4,0x3f
ffffffffc0204b8e:	8e9d                	sub	a3,a3,a5
ffffffffc0204b90:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b94:	f654                	sd	a3,168(a2)
ffffffffc0204b96:	8fd9                	or	a5,a5,a4
ffffffffc0204b98:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204b9c:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b9e:	4581                	li	a1,0
ffffffffc0204ba0:	12000613          	li	a2,288
ffffffffc0204ba4:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204ba6:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204baa:	4b1000ef          	jal	ra,ffffffffc020585a <memset>
    tf->epc = elf->e_entry;
ffffffffc0204bae:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bb0:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204bb4:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc0204bb8:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204bba:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bbc:	0b490913          	addi	s2,s2,180
    tf->gpr.sp = USTACKTOP;
ffffffffc0204bc0:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204bc2:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bc6:	4641                	li	a2,16
ffffffffc0204bc8:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204bca:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204bcc:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204bd0:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bd4:	854a                	mv	a0,s2
ffffffffc0204bd6:	485000ef          	jal	ra,ffffffffc020585a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204bda:	463d                	li	a2,15
ffffffffc0204bdc:	180c                	addi	a1,sp,48
ffffffffc0204bde:	854a                	mv	a0,s2
ffffffffc0204be0:	48d000ef          	jal	ra,ffffffffc020586c <memcpy>
}
ffffffffc0204be4:	70aa                	ld	ra,168(sp)
ffffffffc0204be6:	740a                	ld	s0,160(sp)
ffffffffc0204be8:	64ea                	ld	s1,152(sp)
ffffffffc0204bea:	694a                	ld	s2,144(sp)
ffffffffc0204bec:	6a0a                	ld	s4,128(sp)
ffffffffc0204bee:	7ae6                	ld	s5,120(sp)
ffffffffc0204bf0:	7b46                	ld	s6,112(sp)
ffffffffc0204bf2:	7ba6                	ld	s7,104(sp)
ffffffffc0204bf4:	7c06                	ld	s8,96(sp)
ffffffffc0204bf6:	6ce6                	ld	s9,88(sp)
ffffffffc0204bf8:	6d46                	ld	s10,80(sp)
ffffffffc0204bfa:	6da6                	ld	s11,72(sp)
ffffffffc0204bfc:	854e                	mv	a0,s3
ffffffffc0204bfe:	69aa                	ld	s3,136(sp)
ffffffffc0204c00:	614d                	addi	sp,sp,176
ffffffffc0204c02:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204c04:	463d                	li	a2,15
ffffffffc0204c06:	85a6                	mv	a1,s1
ffffffffc0204c08:	1808                	addi	a0,sp,48
ffffffffc0204c0a:	463000ef          	jal	ra,ffffffffc020586c <memcpy>
    if (mm != NULL)
ffffffffc0204c0e:	e20911e3          	bnez	s2,ffffffffc0204a30 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204c12:	000db783          	ld	a5,0(s11)
ffffffffc0204c16:	779c                	ld	a5,40(a5)
ffffffffc0204c18:	e40788e3          	beqz	a5,ffffffffc0204a68 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204c1c:	00002617          	auipc	a2,0x2
ffffffffc0204c20:	6e460613          	addi	a2,a2,1764 # ffffffffc0207300 <default_pmm_manager+0xc38>
ffffffffc0204c24:	24100593          	li	a1,577
ffffffffc0204c28:	00002517          	auipc	a0,0x2
ffffffffc0204c2c:	51050513          	addi	a0,a0,1296 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0204c30:	85ffb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204c34:	8522                	mv	a0,s0
ffffffffc0204c36:	c80ff0ef          	jal	ra,ffffffffc02040b6 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204c3a:	8522                	mv	a0,s0
ffffffffc0204c3c:	bc1fe0ef          	jal	ra,ffffffffc02037fc <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204c40:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc0204c42:	854e                	mv	a0,s3
ffffffffc0204c44:	94bff0ef          	jal	ra,ffffffffc020458e <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204c48:	59f1                	li	s3,-4
ffffffffc0204c4a:	bfe5                	j	ffffffffc0204c42 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204c4c:	02893603          	ld	a2,40(s2)
ffffffffc0204c50:	02093783          	ld	a5,32(s2)
ffffffffc0204c54:	1cf66d63          	bltu	a2,a5,ffffffffc0204e2e <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204c58:	00492783          	lw	a5,4(s2)
ffffffffc0204c5c:	0017f693          	andi	a3,a5,1
ffffffffc0204c60:	c291                	beqz	a3,ffffffffc0204c64 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204c62:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c64:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c68:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c6a:	e779                	bnez	a4,ffffffffc0204d38 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204c6c:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c6e:	c781                	beqz	a5,ffffffffc0204c76 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204c70:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204c74:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204c76:	0026f793          	andi	a5,a3,2
ffffffffc0204c7a:	e3f1                	bnez	a5,ffffffffc0204d3e <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204c7c:	0046f793          	andi	a5,a3,4
ffffffffc0204c80:	c399                	beqz	a5,ffffffffc0204c86 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204c82:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204c86:	01093583          	ld	a1,16(s2)
ffffffffc0204c8a:	4701                	li	a4,0
ffffffffc0204c8c:	8522                	mv	a0,s0
ffffffffc0204c8e:	bc1fe0ef          	jal	ra,ffffffffc020384e <mm_map>
ffffffffc0204c92:	89aa                	mv	s3,a0
ffffffffc0204c94:	ed35                	bnez	a0,ffffffffc0204d10 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c96:	01093b03          	ld	s6,16(s2)
ffffffffc0204c9a:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204c9c:	02093983          	ld	s3,32(s2)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204ca0:	00893483          	ld	s1,8(s2)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204ca4:	00fb7a33          	and	s4,s6,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204ca8:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204caa:	99da                	add	s3,s3,s6
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204cac:	94be                	add	s1,s1,a5
        while (start < end)
ffffffffc0204cae:	053b6963          	bltu	s6,s3,ffffffffc0204d00 <do_execve+0x332>
ffffffffc0204cb2:	aa95                	j	ffffffffc0204e26 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204cb4:	6785                	lui	a5,0x1
ffffffffc0204cb6:	414b0533          	sub	a0,s6,s4
ffffffffc0204cba:	9a3e                	add	s4,s4,a5
ffffffffc0204cbc:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204cc0:	0149f463          	bgeu	s3,s4,ffffffffc0204cc8 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204cc4:	41698633          	sub	a2,s3,s6
    return page - pages + nbase;
ffffffffc0204cc8:	000cb683          	ld	a3,0(s9)
ffffffffc0204ccc:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204cce:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204cd2:	40db86b3          	sub	a3,s7,a3
ffffffffc0204cd6:	8699                	srai	a3,a3,0x6
ffffffffc0204cd8:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204cda:	67e2                	ld	a5,24(sp)
ffffffffc0204cdc:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ce0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ce2:	14b8f863          	bgeu	a7,a1,ffffffffc0204e32 <do_execve+0x464>
ffffffffc0204ce6:	000ab883          	ld	a7,0(s5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cea:	85a6                	mv	a1,s1
            start += size, from += size;
ffffffffc0204cec:	9b32                	add	s6,s6,a2
ffffffffc0204cee:	96c6                	add	a3,a3,a7
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cf0:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204cf2:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cf4:	379000ef          	jal	ra,ffffffffc020586c <memcpy>
            start += size, from += size;
ffffffffc0204cf8:	6622                	ld	a2,8(sp)
ffffffffc0204cfa:	94b2                	add	s1,s1,a2
        while (start < end)
ffffffffc0204cfc:	053b7363          	bgeu	s6,s3,ffffffffc0204d42 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d00:	6c08                	ld	a0,24(s0)
ffffffffc0204d02:	866a                	mv	a2,s10
ffffffffc0204d04:	85d2                	mv	a1,s4
ffffffffc0204d06:	8d1fe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc0204d0a:	8baa                	mv	s7,a0
ffffffffc0204d0c:	f545                	bnez	a0,ffffffffc0204cb4 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204d0e:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0204d10:	8522                	mv	a0,s0
ffffffffc0204d12:	c87fe0ef          	jal	ra,ffffffffc0203998 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204d16:	8522                	mv	a0,s0
ffffffffc0204d18:	b9eff0ef          	jal	ra,ffffffffc02040b6 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204d1c:	8522                	mv	a0,s0
ffffffffc0204d1e:	adffe0ef          	jal	ra,ffffffffc02037fc <mm_destroy>
    return ret;
ffffffffc0204d22:	b705                	j	ffffffffc0204c42 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204d24:	854a                	mv	a0,s2
ffffffffc0204d26:	c73fe0ef          	jal	ra,ffffffffc0203998 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204d2a:	854a                	mv	a0,s2
ffffffffc0204d2c:	b8aff0ef          	jal	ra,ffffffffc02040b6 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204d30:	854a                	mv	a0,s2
ffffffffc0204d32:	acbfe0ef          	jal	ra,ffffffffc02037fc <mm_destroy>
ffffffffc0204d36:	b32d                	j	ffffffffc0204a60 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204d38:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d3c:	fb95                	bnez	a5,ffffffffc0204c70 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d3e:	4d5d                	li	s10,23
ffffffffc0204d40:	bf35                	j	ffffffffc0204c7c <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204d42:	01093483          	ld	s1,16(s2)
ffffffffc0204d46:	02893683          	ld	a3,40(s2)
ffffffffc0204d4a:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204d4c:	074b7d63          	bgeu	s6,s4,ffffffffc0204dc6 <do_execve+0x3f8>
            if (start == end)
ffffffffc0204d50:	db648fe3          	beq	s1,s6,ffffffffc0204b0e <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d54:	6785                	lui	a5,0x1
ffffffffc0204d56:	00fb0533          	add	a0,s6,a5
ffffffffc0204d5a:	41450533          	sub	a0,a0,s4
                size -= la - end;
ffffffffc0204d5e:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204d62:	0b44fd63          	bgeu	s1,s4,ffffffffc0204e1c <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204d66:	000cb683          	ld	a3,0(s9)
ffffffffc0204d6a:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d6c:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204d70:	40db86b3          	sub	a3,s7,a3
ffffffffc0204d74:	8699                	srai	a3,a3,0x6
ffffffffc0204d76:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204d78:	67e2                	ld	a5,24(sp)
ffffffffc0204d7a:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d7e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d80:	0ac5f963          	bgeu	a1,a2,ffffffffc0204e32 <do_execve+0x464>
ffffffffc0204d84:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d88:	864e                	mv	a2,s3
ffffffffc0204d8a:	4581                	li	a1,0
ffffffffc0204d8c:	96c6                	add	a3,a3,a7
ffffffffc0204d8e:	9536                	add	a0,a0,a3
ffffffffc0204d90:	2cb000ef          	jal	ra,ffffffffc020585a <memset>
            start += size;
ffffffffc0204d94:	01698733          	add	a4,s3,s6
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204d98:	0344f463          	bgeu	s1,s4,ffffffffc0204dc0 <do_execve+0x3f2>
ffffffffc0204d9c:	d6e489e3          	beq	s1,a4,ffffffffc0204b0e <do_execve+0x140>
ffffffffc0204da0:	00002697          	auipc	a3,0x2
ffffffffc0204da4:	58868693          	addi	a3,a3,1416 # ffffffffc0207328 <default_pmm_manager+0xc60>
ffffffffc0204da8:	00001617          	auipc	a2,0x1
ffffffffc0204dac:	57060613          	addi	a2,a2,1392 # ffffffffc0206318 <commands+0x828>
ffffffffc0204db0:	2aa00593          	li	a1,682
ffffffffc0204db4:	00002517          	auipc	a0,0x2
ffffffffc0204db8:	38450513          	addi	a0,a0,900 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0204dbc:	ed2fb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204dc0:	ff4710e3          	bne	a4,s4,ffffffffc0204da0 <do_execve+0x3d2>
ffffffffc0204dc4:	8b52                	mv	s6,s4
        while (start < end)
ffffffffc0204dc6:	d49b74e3          	bgeu	s6,s1,ffffffffc0204b0e <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204dca:	6c08                	ld	a0,24(s0)
ffffffffc0204dcc:	866a                	mv	a2,s10
ffffffffc0204dce:	85d2                	mv	a1,s4
ffffffffc0204dd0:	807fe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc0204dd4:	8baa                	mv	s7,a0
ffffffffc0204dd6:	dd05                	beqz	a0,ffffffffc0204d0e <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204dd8:	6785                	lui	a5,0x1
ffffffffc0204dda:	414b0533          	sub	a0,s6,s4
ffffffffc0204dde:	9a3e                	add	s4,s4,a5
ffffffffc0204de0:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204de4:	0144f463          	bgeu	s1,s4,ffffffffc0204dec <do_execve+0x41e>
                size -= la - end;
ffffffffc0204de8:	41648633          	sub	a2,s1,s6
    return page - pages + nbase;
ffffffffc0204dec:	000cb683          	ld	a3,0(s9)
ffffffffc0204df0:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204df2:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204df6:	40db86b3          	sub	a3,s7,a3
ffffffffc0204dfa:	8699                	srai	a3,a3,0x6
ffffffffc0204dfc:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204dfe:	67e2                	ld	a5,24(sp)
ffffffffc0204e00:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e04:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e06:	02b8f663          	bgeu	a7,a1,ffffffffc0204e32 <do_execve+0x464>
ffffffffc0204e0a:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e0e:	4581                	li	a1,0
            start += size;
ffffffffc0204e10:	9b32                	add	s6,s6,a2
ffffffffc0204e12:	96c6                	add	a3,a3,a7
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e14:	9536                	add	a0,a0,a3
ffffffffc0204e16:	245000ef          	jal	ra,ffffffffc020585a <memset>
ffffffffc0204e1a:	b775                	j	ffffffffc0204dc6 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204e1c:	416a09b3          	sub	s3,s4,s6
ffffffffc0204e20:	b799                	j	ffffffffc0204d66 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204e22:	59f5                	li	s3,-3
ffffffffc0204e24:	b3c1                	j	ffffffffc0204be4 <do_execve+0x216>
        while (start < end)
ffffffffc0204e26:	84da                	mv	s1,s6
ffffffffc0204e28:	bf39                	j	ffffffffc0204d46 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204e2a:	59f1                	li	s3,-4
ffffffffc0204e2c:	bdc5                	j	ffffffffc0204d1c <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204e2e:	59e1                	li	s3,-8
ffffffffc0204e30:	b5c5                	j	ffffffffc0204d10 <do_execve+0x342>
ffffffffc0204e32:	00002617          	auipc	a2,0x2
ffffffffc0204e36:	8ce60613          	addi	a2,a2,-1842 # ffffffffc0206700 <default_pmm_manager+0x38>
ffffffffc0204e3a:	07200593          	li	a1,114
ffffffffc0204e3e:	00002517          	auipc	a0,0x2
ffffffffc0204e42:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0206728 <default_pmm_manager+0x60>
ffffffffc0204e46:	e48fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204e4a:	00002617          	auipc	a2,0x2
ffffffffc0204e4e:	95e60613          	addi	a2,a2,-1698 # ffffffffc02067a8 <default_pmm_manager+0xe0>
ffffffffc0204e52:	2c900593          	li	a1,713
ffffffffc0204e56:	00002517          	auipc	a0,0x2
ffffffffc0204e5a:	2e250513          	addi	a0,a0,738 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0204e5e:	e30fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e62:	00002697          	auipc	a3,0x2
ffffffffc0204e66:	5de68693          	addi	a3,a3,1502 # ffffffffc0207440 <default_pmm_manager+0xd78>
ffffffffc0204e6a:	00001617          	auipc	a2,0x1
ffffffffc0204e6e:	4ae60613          	addi	a2,a2,1198 # ffffffffc0206318 <commands+0x828>
ffffffffc0204e72:	2c400593          	li	a1,708
ffffffffc0204e76:	00002517          	auipc	a0,0x2
ffffffffc0204e7a:	2c250513          	addi	a0,a0,706 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0204e7e:	e10fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e82:	00002697          	auipc	a3,0x2
ffffffffc0204e86:	57668693          	addi	a3,a3,1398 # ffffffffc02073f8 <default_pmm_manager+0xd30>
ffffffffc0204e8a:	00001617          	auipc	a2,0x1
ffffffffc0204e8e:	48e60613          	addi	a2,a2,1166 # ffffffffc0206318 <commands+0x828>
ffffffffc0204e92:	2c300593          	li	a1,707
ffffffffc0204e96:	00002517          	auipc	a0,0x2
ffffffffc0204e9a:	2a250513          	addi	a0,a0,674 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0204e9e:	df0fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ea2:	00002697          	auipc	a3,0x2
ffffffffc0204ea6:	50e68693          	addi	a3,a3,1294 # ffffffffc02073b0 <default_pmm_manager+0xce8>
ffffffffc0204eaa:	00001617          	auipc	a2,0x1
ffffffffc0204eae:	46e60613          	addi	a2,a2,1134 # ffffffffc0206318 <commands+0x828>
ffffffffc0204eb2:	2c200593          	li	a1,706
ffffffffc0204eb6:	00002517          	auipc	a0,0x2
ffffffffc0204eba:	28250513          	addi	a0,a0,642 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0204ebe:	dd0fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ec2:	00002697          	auipc	a3,0x2
ffffffffc0204ec6:	4a668693          	addi	a3,a3,1190 # ffffffffc0207368 <default_pmm_manager+0xca0>
ffffffffc0204eca:	00001617          	auipc	a2,0x1
ffffffffc0204ece:	44e60613          	addi	a2,a2,1102 # ffffffffc0206318 <commands+0x828>
ffffffffc0204ed2:	2c100593          	li	a1,705
ffffffffc0204ed6:	00002517          	auipc	a0,0x2
ffffffffc0204eda:	26250513          	addi	a0,a0,610 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0204ede:	db0fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204ee2 <do_yield>:
    current->need_resched = 1;
ffffffffc0204ee2:	000a6797          	auipc	a5,0xa6
ffffffffc0204ee6:	8467b783          	ld	a5,-1978(a5) # ffffffffc02aa728 <current>
ffffffffc0204eea:	4705                	li	a4,1
ffffffffc0204eec:	ef98                	sd	a4,24(a5)
}
ffffffffc0204eee:	4501                	li	a0,0
ffffffffc0204ef0:	8082                	ret

ffffffffc0204ef2 <do_wait>:
{
ffffffffc0204ef2:	1101                	addi	sp,sp,-32
ffffffffc0204ef4:	e822                	sd	s0,16(sp)
ffffffffc0204ef6:	e426                	sd	s1,8(sp)
ffffffffc0204ef8:	ec06                	sd	ra,24(sp)
ffffffffc0204efa:	842e                	mv	s0,a1
ffffffffc0204efc:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204efe:	c999                	beqz	a1,ffffffffc0204f14 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204f00:	000a6797          	auipc	a5,0xa6
ffffffffc0204f04:	8287b783          	ld	a5,-2008(a5) # ffffffffc02aa728 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204f08:	7788                	ld	a0,40(a5)
ffffffffc0204f0a:	4685                	li	a3,1
ffffffffc0204f0c:	4611                	li	a2,4
ffffffffc0204f0e:	80eff0ef          	jal	ra,ffffffffc0203f1c <user_mem_check>
ffffffffc0204f12:	c909                	beqz	a0,ffffffffc0204f24 <do_wait+0x32>
ffffffffc0204f14:	85a2                	mv	a1,s0
}
ffffffffc0204f16:	6442                	ld	s0,16(sp)
ffffffffc0204f18:	60e2                	ld	ra,24(sp)
ffffffffc0204f1a:	8526                	mv	a0,s1
ffffffffc0204f1c:	64a2                	ld	s1,8(sp)
ffffffffc0204f1e:	6105                	addi	sp,sp,32
ffffffffc0204f20:	fb8ff06f          	j	ffffffffc02046d8 <do_wait.part.0>
ffffffffc0204f24:	60e2                	ld	ra,24(sp)
ffffffffc0204f26:	6442                	ld	s0,16(sp)
ffffffffc0204f28:	64a2                	ld	s1,8(sp)
ffffffffc0204f2a:	5575                	li	a0,-3
ffffffffc0204f2c:	6105                	addi	sp,sp,32
ffffffffc0204f2e:	8082                	ret

ffffffffc0204f30 <do_kill>:
{
ffffffffc0204f30:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f32:	6789                	lui	a5,0x2
{
ffffffffc0204f34:	e406                	sd	ra,8(sp)
ffffffffc0204f36:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f38:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f3c:	17f9                	addi	a5,a5,-2
ffffffffc0204f3e:	02e7e963          	bltu	a5,a4,ffffffffc0204f70 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f42:	842a                	mv	s0,a0
ffffffffc0204f44:	45a9                	li	a1,10
ffffffffc0204f46:	2501                	sext.w	a0,a0
ffffffffc0204f48:	46c000ef          	jal	ra,ffffffffc02053b4 <hash32>
ffffffffc0204f4c:	02051793          	slli	a5,a0,0x20
ffffffffc0204f50:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204f54:	000a1797          	auipc	a5,0xa1
ffffffffc0204f58:	76478793          	addi	a5,a5,1892 # ffffffffc02a66b8 <hash_list>
ffffffffc0204f5c:	953e                	add	a0,a0,a5
ffffffffc0204f5e:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204f60:	a029                	j	ffffffffc0204f6a <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204f62:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204f66:	00870b63          	beq	a4,s0,ffffffffc0204f7c <do_kill+0x4c>
ffffffffc0204f6a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204f6c:	fef51be3          	bne	a0,a5,ffffffffc0204f62 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204f70:	5475                	li	s0,-3
}
ffffffffc0204f72:	60a2                	ld	ra,8(sp)
ffffffffc0204f74:	8522                	mv	a0,s0
ffffffffc0204f76:	6402                	ld	s0,0(sp)
ffffffffc0204f78:	0141                	addi	sp,sp,16
ffffffffc0204f7a:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204f7c:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204f80:	00177693          	andi	a3,a4,1
ffffffffc0204f84:	e295                	bnez	a3,ffffffffc0204fa8 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f86:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204f88:	00176713          	ori	a4,a4,1
ffffffffc0204f8c:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204f90:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f92:	fe06d0e3          	bgez	a3,ffffffffc0204f72 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204f96:	f2878513          	addi	a0,a5,-216
ffffffffc0204f9a:	22e000ef          	jal	ra,ffffffffc02051c8 <wakeup_proc>
}
ffffffffc0204f9e:	60a2                	ld	ra,8(sp)
ffffffffc0204fa0:	8522                	mv	a0,s0
ffffffffc0204fa2:	6402                	ld	s0,0(sp)
ffffffffc0204fa4:	0141                	addi	sp,sp,16
ffffffffc0204fa6:	8082                	ret
        return -E_KILLED;
ffffffffc0204fa8:	545d                	li	s0,-9
ffffffffc0204faa:	b7e1                	j	ffffffffc0204f72 <do_kill+0x42>

ffffffffc0204fac <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204fac:	1101                	addi	sp,sp,-32
ffffffffc0204fae:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204fb0:	000a5797          	auipc	a5,0xa5
ffffffffc0204fb4:	70878793          	addi	a5,a5,1800 # ffffffffc02aa6b8 <proc_list>
ffffffffc0204fb8:	ec06                	sd	ra,24(sp)
ffffffffc0204fba:	e822                	sd	s0,16(sp)
ffffffffc0204fbc:	e04a                	sd	s2,0(sp)
ffffffffc0204fbe:	000a1497          	auipc	s1,0xa1
ffffffffc0204fc2:	6fa48493          	addi	s1,s1,1786 # ffffffffc02a66b8 <hash_list>
ffffffffc0204fc6:	e79c                	sd	a5,8(a5)
ffffffffc0204fc8:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204fca:	000a5717          	auipc	a4,0xa5
ffffffffc0204fce:	6ee70713          	addi	a4,a4,1774 # ffffffffc02aa6b8 <proc_list>
ffffffffc0204fd2:	87a6                	mv	a5,s1
ffffffffc0204fd4:	e79c                	sd	a5,8(a5)
ffffffffc0204fd6:	e39c                	sd	a5,0(a5)
ffffffffc0204fd8:	07c1                	addi	a5,a5,16
ffffffffc0204fda:	fef71de3          	bne	a4,a5,ffffffffc0204fd4 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204fde:	fdbfe0ef          	jal	ra,ffffffffc0203fb8 <alloc_proc>
ffffffffc0204fe2:	000a5917          	auipc	s2,0xa5
ffffffffc0204fe6:	74e90913          	addi	s2,s2,1870 # ffffffffc02aa730 <idleproc>
ffffffffc0204fea:	00a93023          	sd	a0,0(s2)
ffffffffc0204fee:	0e050f63          	beqz	a0,ffffffffc02050ec <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204ff2:	4789                	li	a5,2
ffffffffc0204ff4:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204ff6:	00003797          	auipc	a5,0x3
ffffffffc0204ffa:	00a78793          	addi	a5,a5,10 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ffe:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205002:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205004:	4785                	li	a5,1
ffffffffc0205006:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205008:	4641                	li	a2,16
ffffffffc020500a:	4581                	li	a1,0
ffffffffc020500c:	8522                	mv	a0,s0
ffffffffc020500e:	04d000ef          	jal	ra,ffffffffc020585a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205012:	463d                	li	a2,15
ffffffffc0205014:	00002597          	auipc	a1,0x2
ffffffffc0205018:	48c58593          	addi	a1,a1,1164 # ffffffffc02074a0 <default_pmm_manager+0xdd8>
ffffffffc020501c:	8522                	mv	a0,s0
ffffffffc020501e:	04f000ef          	jal	ra,ffffffffc020586c <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205022:	000a5717          	auipc	a4,0xa5
ffffffffc0205026:	71e70713          	addi	a4,a4,1822 # ffffffffc02aa740 <nr_process>
ffffffffc020502a:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc020502c:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205030:	4601                	li	a2,0
    nr_process++;
ffffffffc0205032:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205034:	4581                	li	a1,0
ffffffffc0205036:	00000517          	auipc	a0,0x0
ffffffffc020503a:	87450513          	addi	a0,a0,-1932 # ffffffffc02048aa <init_main>
    nr_process++;
ffffffffc020503e:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205040:	000a5797          	auipc	a5,0xa5
ffffffffc0205044:	6ed7b423          	sd	a3,1768(a5) # ffffffffc02aa728 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205048:	cf6ff0ef          	jal	ra,ffffffffc020453e <kernel_thread>
ffffffffc020504c:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc020504e:	08a05363          	blez	a0,ffffffffc02050d4 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205052:	6789                	lui	a5,0x2
ffffffffc0205054:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205058:	17f9                	addi	a5,a5,-2
ffffffffc020505a:	2501                	sext.w	a0,a0
ffffffffc020505c:	02e7e363          	bltu	a5,a4,ffffffffc0205082 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205060:	45a9                	li	a1,10
ffffffffc0205062:	352000ef          	jal	ra,ffffffffc02053b4 <hash32>
ffffffffc0205066:	02051793          	slli	a5,a0,0x20
ffffffffc020506a:	01c7d693          	srli	a3,a5,0x1c
ffffffffc020506e:	96a6                	add	a3,a3,s1
ffffffffc0205070:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0205072:	a029                	j	ffffffffc020507c <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0205074:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc0205078:	04870b63          	beq	a4,s0,ffffffffc02050ce <proc_init+0x122>
    return listelm->next;
ffffffffc020507c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020507e:	fef69be3          	bne	a3,a5,ffffffffc0205074 <proc_init+0xc8>
    return NULL;
ffffffffc0205082:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205084:	0b478493          	addi	s1,a5,180
ffffffffc0205088:	4641                	li	a2,16
ffffffffc020508a:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc020508c:	000a5417          	auipc	s0,0xa5
ffffffffc0205090:	6ac40413          	addi	s0,s0,1708 # ffffffffc02aa738 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205094:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205096:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205098:	7c2000ef          	jal	ra,ffffffffc020585a <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020509c:	463d                	li	a2,15
ffffffffc020509e:	00002597          	auipc	a1,0x2
ffffffffc02050a2:	42a58593          	addi	a1,a1,1066 # ffffffffc02074c8 <default_pmm_manager+0xe00>
ffffffffc02050a6:	8526                	mv	a0,s1
ffffffffc02050a8:	7c4000ef          	jal	ra,ffffffffc020586c <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050ac:	00093783          	ld	a5,0(s2)
ffffffffc02050b0:	cbb5                	beqz	a5,ffffffffc0205124 <proc_init+0x178>
ffffffffc02050b2:	43dc                	lw	a5,4(a5)
ffffffffc02050b4:	eba5                	bnez	a5,ffffffffc0205124 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050b6:	601c                	ld	a5,0(s0)
ffffffffc02050b8:	c7b1                	beqz	a5,ffffffffc0205104 <proc_init+0x158>
ffffffffc02050ba:	43d8                	lw	a4,4(a5)
ffffffffc02050bc:	4785                	li	a5,1
ffffffffc02050be:	04f71363          	bne	a4,a5,ffffffffc0205104 <proc_init+0x158>
}
ffffffffc02050c2:	60e2                	ld	ra,24(sp)
ffffffffc02050c4:	6442                	ld	s0,16(sp)
ffffffffc02050c6:	64a2                	ld	s1,8(sp)
ffffffffc02050c8:	6902                	ld	s2,0(sp)
ffffffffc02050ca:	6105                	addi	sp,sp,32
ffffffffc02050cc:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02050ce:	f2878793          	addi	a5,a5,-216
ffffffffc02050d2:	bf4d                	j	ffffffffc0205084 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc02050d4:	00002617          	auipc	a2,0x2
ffffffffc02050d8:	3d460613          	addi	a2,a2,980 # ffffffffc02074a8 <default_pmm_manager+0xde0>
ffffffffc02050dc:	3e900593          	li	a1,1001
ffffffffc02050e0:	00002517          	auipc	a0,0x2
ffffffffc02050e4:	05850513          	addi	a0,a0,88 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc02050e8:	ba6fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc02050ec:	00002617          	auipc	a2,0x2
ffffffffc02050f0:	39c60613          	addi	a2,a2,924 # ffffffffc0207488 <default_pmm_manager+0xdc0>
ffffffffc02050f4:	3da00593          	li	a1,986
ffffffffc02050f8:	00002517          	auipc	a0,0x2
ffffffffc02050fc:	04050513          	addi	a0,a0,64 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0205100:	b8efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205104:	00002697          	auipc	a3,0x2
ffffffffc0205108:	3f468693          	addi	a3,a3,1012 # ffffffffc02074f8 <default_pmm_manager+0xe30>
ffffffffc020510c:	00001617          	auipc	a2,0x1
ffffffffc0205110:	20c60613          	addi	a2,a2,524 # ffffffffc0206318 <commands+0x828>
ffffffffc0205114:	3f000593          	li	a1,1008
ffffffffc0205118:	00002517          	auipc	a0,0x2
ffffffffc020511c:	02050513          	addi	a0,a0,32 # ffffffffc0207138 <default_pmm_manager+0xa70>
ffffffffc0205120:	b6efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205124:	00002697          	auipc	a3,0x2
ffffffffc0205128:	3ac68693          	addi	a3,a3,940 # ffffffffc02074d0 <default_pmm_manager+0xe08>
ffffffffc020512c:	00001617          	auipc	a2,0x1
ffffffffc0205130:	1ec60613          	addi	a2,a2,492 # ffffffffc0206318 <commands+0x828>
ffffffffc0205134:	3ef00593          	li	a1,1007
ffffffffc0205138:	00002517          	auipc	a0,0x2
ffffffffc020513c:	00050513          	mv	a0,a0
ffffffffc0205140:	b4efb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205144 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205144:	1141                	addi	sp,sp,-16
ffffffffc0205146:	e022                	sd	s0,0(sp)
ffffffffc0205148:	e406                	sd	ra,8(sp)
ffffffffc020514a:	000a5417          	auipc	s0,0xa5
ffffffffc020514e:	5de40413          	addi	s0,s0,1502 # ffffffffc02aa728 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205152:	6018                	ld	a4,0(s0)
ffffffffc0205154:	6f1c                	ld	a5,24(a4)
ffffffffc0205156:	dffd                	beqz	a5,ffffffffc0205154 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205158:	0f0000ef          	jal	ra,ffffffffc0205248 <schedule>
ffffffffc020515c:	bfdd                	j	ffffffffc0205152 <cpu_idle+0xe>

ffffffffc020515e <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020515e:	00153023          	sd	ra,0(a0) # ffffffffc0207138 <default_pmm_manager+0xa70>
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205162:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205166:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205168:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020516a:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020516e:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205172:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205176:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020517a:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020517e:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205182:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205186:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020518a:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020518e:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205192:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205196:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020519a:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020519c:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc020519e:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02051a2:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02051a6:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02051aa:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02051ae:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02051b2:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02051b6:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02051ba:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02051be:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02051c2:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02051c6:	8082                	ret

ffffffffc02051c8 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051c8:	4118                	lw	a4,0(a0)
{
ffffffffc02051ca:	1101                	addi	sp,sp,-32
ffffffffc02051cc:	ec06                	sd	ra,24(sp)
ffffffffc02051ce:	e822                	sd	s0,16(sp)
ffffffffc02051d0:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051d2:	478d                	li	a5,3
ffffffffc02051d4:	04f70b63          	beq	a4,a5,ffffffffc020522a <wakeup_proc+0x62>
ffffffffc02051d8:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051da:	100027f3          	csrr	a5,sstatus
ffffffffc02051de:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02051e0:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051e2:	ef9d                	bnez	a5,ffffffffc0205220 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051e4:	4789                	li	a5,2
ffffffffc02051e6:	02f70163          	beq	a4,a5,ffffffffc0205208 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02051ea:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02051ec:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc02051f0:	e491                	bnez	s1,ffffffffc02051fc <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02051f2:	60e2                	ld	ra,24(sp)
ffffffffc02051f4:	6442                	ld	s0,16(sp)
ffffffffc02051f6:	64a2                	ld	s1,8(sp)
ffffffffc02051f8:	6105                	addi	sp,sp,32
ffffffffc02051fa:	8082                	ret
ffffffffc02051fc:	6442                	ld	s0,16(sp)
ffffffffc02051fe:	60e2                	ld	ra,24(sp)
ffffffffc0205200:	64a2                	ld	s1,8(sp)
ffffffffc0205202:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205204:	faafb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205208:	00002617          	auipc	a2,0x2
ffffffffc020520c:	35060613          	addi	a2,a2,848 # ffffffffc0207558 <default_pmm_manager+0xe90>
ffffffffc0205210:	45d1                	li	a1,20
ffffffffc0205212:	00002517          	auipc	a0,0x2
ffffffffc0205216:	32e50513          	addi	a0,a0,814 # ffffffffc0207540 <default_pmm_manager+0xe78>
ffffffffc020521a:	adcfb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc020521e:	bfc9                	j	ffffffffc02051f0 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205220:	f94fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205224:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205226:	4485                	li	s1,1
ffffffffc0205228:	bf75                	j	ffffffffc02051e4 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020522a:	00002697          	auipc	a3,0x2
ffffffffc020522e:	2f668693          	addi	a3,a3,758 # ffffffffc0207520 <default_pmm_manager+0xe58>
ffffffffc0205232:	00001617          	auipc	a2,0x1
ffffffffc0205236:	0e660613          	addi	a2,a2,230 # ffffffffc0206318 <commands+0x828>
ffffffffc020523a:	45a5                	li	a1,9
ffffffffc020523c:	00002517          	auipc	a0,0x2
ffffffffc0205240:	30450513          	addi	a0,a0,772 # ffffffffc0207540 <default_pmm_manager+0xe78>
ffffffffc0205244:	a4afb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205248 <schedule>:

void schedule(void)
{
ffffffffc0205248:	1141                	addi	sp,sp,-16
ffffffffc020524a:	e406                	sd	ra,8(sp)
ffffffffc020524c:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020524e:	100027f3          	csrr	a5,sstatus
ffffffffc0205252:	8b89                	andi	a5,a5,2
ffffffffc0205254:	4401                	li	s0,0
ffffffffc0205256:	efbd                	bnez	a5,ffffffffc02052d4 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205258:	000a5897          	auipc	a7,0xa5
ffffffffc020525c:	4d08b883          	ld	a7,1232(a7) # ffffffffc02aa728 <current>
ffffffffc0205260:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205264:	000a5517          	auipc	a0,0xa5
ffffffffc0205268:	4cc53503          	ld	a0,1228(a0) # ffffffffc02aa730 <idleproc>
ffffffffc020526c:	04a88e63          	beq	a7,a0,ffffffffc02052c8 <schedule+0x80>
ffffffffc0205270:	0c888693          	addi	a3,a7,200
ffffffffc0205274:	000a5617          	auipc	a2,0xa5
ffffffffc0205278:	44460613          	addi	a2,a2,1092 # ffffffffc02aa6b8 <proc_list>
        le = last;
ffffffffc020527c:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020527e:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205280:	4809                	li	a6,2
ffffffffc0205282:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc0205284:	00c78863          	beq	a5,a2,ffffffffc0205294 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc0205288:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020528c:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205290:	03070163          	beq	a4,a6,ffffffffc02052b2 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc0205294:	fef697e3          	bne	a3,a5,ffffffffc0205282 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205298:	ed89                	bnez	a1,ffffffffc02052b2 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020529a:	451c                	lw	a5,8(a0)
ffffffffc020529c:	2785                	addiw	a5,a5,1
ffffffffc020529e:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02052a0:	00a88463          	beq	a7,a0,ffffffffc02052a8 <schedule+0x60>
        {
            proc_run(next);
ffffffffc02052a4:	e89fe0ef          	jal	ra,ffffffffc020412c <proc_run>
    if (flag)
ffffffffc02052a8:	e819                	bnez	s0,ffffffffc02052be <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02052aa:	60a2                	ld	ra,8(sp)
ffffffffc02052ac:	6402                	ld	s0,0(sp)
ffffffffc02052ae:	0141                	addi	sp,sp,16
ffffffffc02052b0:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02052b2:	4198                	lw	a4,0(a1)
ffffffffc02052b4:	4789                	li	a5,2
ffffffffc02052b6:	fef712e3          	bne	a4,a5,ffffffffc020529a <schedule+0x52>
ffffffffc02052ba:	852e                	mv	a0,a1
ffffffffc02052bc:	bff9                	j	ffffffffc020529a <schedule+0x52>
}
ffffffffc02052be:	6402                	ld	s0,0(sp)
ffffffffc02052c0:	60a2                	ld	ra,8(sp)
ffffffffc02052c2:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02052c4:	eeafb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02052c8:	000a5617          	auipc	a2,0xa5
ffffffffc02052cc:	3f060613          	addi	a2,a2,1008 # ffffffffc02aa6b8 <proc_list>
ffffffffc02052d0:	86b2                	mv	a3,a2
ffffffffc02052d2:	b76d                	j	ffffffffc020527c <schedule+0x34>
        intr_disable();
ffffffffc02052d4:	ee0fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02052d8:	4405                	li	s0,1
ffffffffc02052da:	bfbd                	j	ffffffffc0205258 <schedule+0x10>

ffffffffc02052dc <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02052dc:	000a5797          	auipc	a5,0xa5
ffffffffc02052e0:	44c7b783          	ld	a5,1100(a5) # ffffffffc02aa728 <current>
}
ffffffffc02052e4:	43c8                	lw	a0,4(a5)
ffffffffc02052e6:	8082                	ret

ffffffffc02052e8 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02052e8:	4501                	li	a0,0
ffffffffc02052ea:	8082                	ret

ffffffffc02052ec <sys_putc>:
    cputchar(c);
ffffffffc02052ec:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02052ee:	1141                	addi	sp,sp,-16
ffffffffc02052f0:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02052f2:	ed9fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc02052f6:	60a2                	ld	ra,8(sp)
ffffffffc02052f8:	4501                	li	a0,0
ffffffffc02052fa:	0141                	addi	sp,sp,16
ffffffffc02052fc:	8082                	ret

ffffffffc02052fe <sys_kill>:
    return do_kill(pid);
ffffffffc02052fe:	4108                	lw	a0,0(a0)
ffffffffc0205300:	c31ff06f          	j	ffffffffc0204f30 <do_kill>

ffffffffc0205304 <sys_yield>:
    return do_yield();
ffffffffc0205304:	bdfff06f          	j	ffffffffc0204ee2 <do_yield>

ffffffffc0205308 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205308:	6d14                	ld	a3,24(a0)
ffffffffc020530a:	6910                	ld	a2,16(a0)
ffffffffc020530c:	650c                	ld	a1,8(a0)
ffffffffc020530e:	6108                	ld	a0,0(a0)
ffffffffc0205310:	ebeff06f          	j	ffffffffc02049ce <do_execve>

ffffffffc0205314 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205314:	650c                	ld	a1,8(a0)
ffffffffc0205316:	4108                	lw	a0,0(a0)
ffffffffc0205318:	bdbff06f          	j	ffffffffc0204ef2 <do_wait>

ffffffffc020531c <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc020531c:	000a5797          	auipc	a5,0xa5
ffffffffc0205320:	40c7b783          	ld	a5,1036(a5) # ffffffffc02aa728 <current>
ffffffffc0205324:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205326:	4501                	li	a0,0
ffffffffc0205328:	6a0c                	ld	a1,16(a2)
ffffffffc020532a:	e6ffe06f          	j	ffffffffc0204198 <do_fork>

ffffffffc020532e <sys_exit>:
    return do_exit(error_code);
ffffffffc020532e:	4108                	lw	a0,0(a0)
ffffffffc0205330:	a5eff06f          	j	ffffffffc020458e <do_exit>

ffffffffc0205334 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205334:	715d                	addi	sp,sp,-80
ffffffffc0205336:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205338:	000a5497          	auipc	s1,0xa5
ffffffffc020533c:	3f048493          	addi	s1,s1,1008 # ffffffffc02aa728 <current>
ffffffffc0205340:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205342:	e0a2                	sd	s0,64(sp)
ffffffffc0205344:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205346:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205348:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020534a:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc020534c:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205350:	0327ee63          	bltu	a5,s2,ffffffffc020538c <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205354:	00391713          	slli	a4,s2,0x3
ffffffffc0205358:	00002797          	auipc	a5,0x2
ffffffffc020535c:	26878793          	addi	a5,a5,616 # ffffffffc02075c0 <syscalls>
ffffffffc0205360:	97ba                	add	a5,a5,a4
ffffffffc0205362:	639c                	ld	a5,0(a5)
ffffffffc0205364:	c785                	beqz	a5,ffffffffc020538c <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0205366:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205368:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc020536a:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc020536c:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc020536e:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205370:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205372:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205374:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205376:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205378:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020537a:	0028                	addi	a0,sp,8
ffffffffc020537c:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020537e:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205380:	e828                	sd	a0,80(s0)
}
ffffffffc0205382:	6406                	ld	s0,64(sp)
ffffffffc0205384:	74e2                	ld	s1,56(sp)
ffffffffc0205386:	7942                	ld	s2,48(sp)
ffffffffc0205388:	6161                	addi	sp,sp,80
ffffffffc020538a:	8082                	ret
    print_trapframe(tf);
ffffffffc020538c:	8522                	mv	a0,s0
ffffffffc020538e:	817fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205392:	609c                	ld	a5,0(s1)
ffffffffc0205394:	86ca                	mv	a3,s2
ffffffffc0205396:	00002617          	auipc	a2,0x2
ffffffffc020539a:	1e260613          	addi	a2,a2,482 # ffffffffc0207578 <default_pmm_manager+0xeb0>
ffffffffc020539e:	43d8                	lw	a4,4(a5)
ffffffffc02053a0:	06200593          	li	a1,98
ffffffffc02053a4:	0b478793          	addi	a5,a5,180
ffffffffc02053a8:	00002517          	auipc	a0,0x2
ffffffffc02053ac:	20050513          	addi	a0,a0,512 # ffffffffc02075a8 <default_pmm_manager+0xee0>
ffffffffc02053b0:	8defb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02053b4 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02053b4:	9e3707b7          	lui	a5,0x9e370
ffffffffc02053b8:	2785                	addiw	a5,a5,1
ffffffffc02053ba:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02053be:	02000793          	li	a5,32
ffffffffc02053c2:	9f8d                	subw	a5,a5,a1
}
ffffffffc02053c4:	00f5553b          	srlw	a0,a0,a5
ffffffffc02053c8:	8082                	ret

ffffffffc02053ca <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02053ca:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053ce:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02053d0:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053d4:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02053d6:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053da:	f022                	sd	s0,32(sp)
ffffffffc02053dc:	ec26                	sd	s1,24(sp)
ffffffffc02053de:	e84a                	sd	s2,16(sp)
ffffffffc02053e0:	f406                	sd	ra,40(sp)
ffffffffc02053e2:	e44e                	sd	s3,8(sp)
ffffffffc02053e4:	84aa                	mv	s1,a0
ffffffffc02053e6:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02053e8:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02053ec:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02053ee:	03067e63          	bgeu	a2,a6,ffffffffc020542a <printnum+0x60>
ffffffffc02053f2:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02053f4:	00805763          	blez	s0,ffffffffc0205402 <printnum+0x38>
ffffffffc02053f8:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02053fa:	85ca                	mv	a1,s2
ffffffffc02053fc:	854e                	mv	a0,s3
ffffffffc02053fe:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205400:	fc65                	bnez	s0,ffffffffc02053f8 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205402:	1a02                	slli	s4,s4,0x20
ffffffffc0205404:	00002797          	auipc	a5,0x2
ffffffffc0205408:	2bc78793          	addi	a5,a5,700 # ffffffffc02076c0 <syscalls+0x100>
ffffffffc020540c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205410:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205412:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205414:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205418:	70a2                	ld	ra,40(sp)
ffffffffc020541a:	69a2                	ld	s3,8(sp)
ffffffffc020541c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020541e:	85ca                	mv	a1,s2
ffffffffc0205420:	87a6                	mv	a5,s1
}
ffffffffc0205422:	6942                	ld	s2,16(sp)
ffffffffc0205424:	64e2                	ld	s1,24(sp)
ffffffffc0205426:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205428:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020542a:	03065633          	divu	a2,a2,a6
ffffffffc020542e:	8722                	mv	a4,s0
ffffffffc0205430:	f9bff0ef          	jal	ra,ffffffffc02053ca <printnum>
ffffffffc0205434:	b7f9                	j	ffffffffc0205402 <printnum+0x38>

ffffffffc0205436 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205436:	7119                	addi	sp,sp,-128
ffffffffc0205438:	f4a6                	sd	s1,104(sp)
ffffffffc020543a:	f0ca                	sd	s2,96(sp)
ffffffffc020543c:	ecce                	sd	s3,88(sp)
ffffffffc020543e:	e8d2                	sd	s4,80(sp)
ffffffffc0205440:	e4d6                	sd	s5,72(sp)
ffffffffc0205442:	e0da                	sd	s6,64(sp)
ffffffffc0205444:	fc5e                	sd	s7,56(sp)
ffffffffc0205446:	f06a                	sd	s10,32(sp)
ffffffffc0205448:	fc86                	sd	ra,120(sp)
ffffffffc020544a:	f8a2                	sd	s0,112(sp)
ffffffffc020544c:	f862                	sd	s8,48(sp)
ffffffffc020544e:	f466                	sd	s9,40(sp)
ffffffffc0205450:	ec6e                	sd	s11,24(sp)
ffffffffc0205452:	892a                	mv	s2,a0
ffffffffc0205454:	84ae                	mv	s1,a1
ffffffffc0205456:	8d32                	mv	s10,a2
ffffffffc0205458:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020545a:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020545e:	5b7d                	li	s6,-1
ffffffffc0205460:	00002a97          	auipc	s5,0x2
ffffffffc0205464:	28ca8a93          	addi	s5,s5,652 # ffffffffc02076ec <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205468:	00002b97          	auipc	s7,0x2
ffffffffc020546c:	4a0b8b93          	addi	s7,s7,1184 # ffffffffc0207908 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205470:	000d4503          	lbu	a0,0(s10)
ffffffffc0205474:	001d0413          	addi	s0,s10,1
ffffffffc0205478:	01350a63          	beq	a0,s3,ffffffffc020548c <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020547c:	c121                	beqz	a0,ffffffffc02054bc <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020547e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205480:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205482:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205484:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205488:	ff351ae3          	bne	a0,s3,ffffffffc020547c <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020548c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205490:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205494:	4c81                	li	s9,0
ffffffffc0205496:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205498:	5c7d                	li	s8,-1
ffffffffc020549a:	5dfd                	li	s11,-1
ffffffffc020549c:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02054a0:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054a2:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054a6:	0ff5f593          	zext.b	a1,a1
ffffffffc02054aa:	00140d13          	addi	s10,s0,1
ffffffffc02054ae:	04b56263          	bltu	a0,a1,ffffffffc02054f2 <vprintfmt+0xbc>
ffffffffc02054b2:	058a                	slli	a1,a1,0x2
ffffffffc02054b4:	95d6                	add	a1,a1,s5
ffffffffc02054b6:	4194                	lw	a3,0(a1)
ffffffffc02054b8:	96d6                	add	a3,a3,s5
ffffffffc02054ba:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02054bc:	70e6                	ld	ra,120(sp)
ffffffffc02054be:	7446                	ld	s0,112(sp)
ffffffffc02054c0:	74a6                	ld	s1,104(sp)
ffffffffc02054c2:	7906                	ld	s2,96(sp)
ffffffffc02054c4:	69e6                	ld	s3,88(sp)
ffffffffc02054c6:	6a46                	ld	s4,80(sp)
ffffffffc02054c8:	6aa6                	ld	s5,72(sp)
ffffffffc02054ca:	6b06                	ld	s6,64(sp)
ffffffffc02054cc:	7be2                	ld	s7,56(sp)
ffffffffc02054ce:	7c42                	ld	s8,48(sp)
ffffffffc02054d0:	7ca2                	ld	s9,40(sp)
ffffffffc02054d2:	7d02                	ld	s10,32(sp)
ffffffffc02054d4:	6de2                	ld	s11,24(sp)
ffffffffc02054d6:	6109                	addi	sp,sp,128
ffffffffc02054d8:	8082                	ret
            padc = '0';
ffffffffc02054da:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02054dc:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054e0:	846a                	mv	s0,s10
ffffffffc02054e2:	00140d13          	addi	s10,s0,1
ffffffffc02054e6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054ea:	0ff5f593          	zext.b	a1,a1
ffffffffc02054ee:	fcb572e3          	bgeu	a0,a1,ffffffffc02054b2 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02054f2:	85a6                	mv	a1,s1
ffffffffc02054f4:	02500513          	li	a0,37
ffffffffc02054f8:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02054fa:	fff44783          	lbu	a5,-1(s0)
ffffffffc02054fe:	8d22                	mv	s10,s0
ffffffffc0205500:	f73788e3          	beq	a5,s3,ffffffffc0205470 <vprintfmt+0x3a>
ffffffffc0205504:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205508:	1d7d                	addi	s10,s10,-1
ffffffffc020550a:	ff379de3          	bne	a5,s3,ffffffffc0205504 <vprintfmt+0xce>
ffffffffc020550e:	b78d                	j	ffffffffc0205470 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205510:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205514:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205518:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020551a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020551e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205522:	02d86463          	bltu	a6,a3,ffffffffc020554a <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205526:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020552a:	002c169b          	slliw	a3,s8,0x2
ffffffffc020552e:	0186873b          	addw	a4,a3,s8
ffffffffc0205532:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205536:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205538:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020553c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020553e:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205542:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205546:	fed870e3          	bgeu	a6,a3,ffffffffc0205526 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020554a:	f40ddce3          	bgez	s11,ffffffffc02054a2 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020554e:	8de2                	mv	s11,s8
ffffffffc0205550:	5c7d                	li	s8,-1
ffffffffc0205552:	bf81                	j	ffffffffc02054a2 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205554:	fffdc693          	not	a3,s11
ffffffffc0205558:	96fd                	srai	a3,a3,0x3f
ffffffffc020555a:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020555e:	00144603          	lbu	a2,1(s0)
ffffffffc0205562:	2d81                	sext.w	s11,s11
ffffffffc0205564:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205566:	bf35                	j	ffffffffc02054a2 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205568:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020556c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205570:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205572:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205574:	bfd9                	j	ffffffffc020554a <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205576:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205578:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020557c:	01174463          	blt	a4,a7,ffffffffc0205584 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205580:	1a088e63          	beqz	a7,ffffffffc020573c <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205584:	000a3603          	ld	a2,0(s4)
ffffffffc0205588:	46c1                	li	a3,16
ffffffffc020558a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020558c:	2781                	sext.w	a5,a5
ffffffffc020558e:	876e                	mv	a4,s11
ffffffffc0205590:	85a6                	mv	a1,s1
ffffffffc0205592:	854a                	mv	a0,s2
ffffffffc0205594:	e37ff0ef          	jal	ra,ffffffffc02053ca <printnum>
            break;
ffffffffc0205598:	bde1                	j	ffffffffc0205470 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020559a:	000a2503          	lw	a0,0(s4)
ffffffffc020559e:	85a6                	mv	a1,s1
ffffffffc02055a0:	0a21                	addi	s4,s4,8
ffffffffc02055a2:	9902                	jalr	s2
            break;
ffffffffc02055a4:	b5f1                	j	ffffffffc0205470 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02055a6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055a8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055ac:	01174463          	blt	a4,a7,ffffffffc02055b4 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02055b0:	18088163          	beqz	a7,ffffffffc0205732 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02055b4:	000a3603          	ld	a2,0(s4)
ffffffffc02055b8:	46a9                	li	a3,10
ffffffffc02055ba:	8a2e                	mv	s4,a1
ffffffffc02055bc:	bfc1                	j	ffffffffc020558c <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055be:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02055c2:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055c4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055c6:	bdf1                	j	ffffffffc02054a2 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02055c8:	85a6                	mv	a1,s1
ffffffffc02055ca:	02500513          	li	a0,37
ffffffffc02055ce:	9902                	jalr	s2
            break;
ffffffffc02055d0:	b545                	j	ffffffffc0205470 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055d2:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02055d6:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055d8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055da:	b5e1                	j	ffffffffc02054a2 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02055dc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055de:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055e2:	01174463          	blt	a4,a7,ffffffffc02055ea <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02055e6:	14088163          	beqz	a7,ffffffffc0205728 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02055ea:	000a3603          	ld	a2,0(s4)
ffffffffc02055ee:	46a1                	li	a3,8
ffffffffc02055f0:	8a2e                	mv	s4,a1
ffffffffc02055f2:	bf69                	j	ffffffffc020558c <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02055f4:	03000513          	li	a0,48
ffffffffc02055f8:	85a6                	mv	a1,s1
ffffffffc02055fa:	e03e                	sd	a5,0(sp)
ffffffffc02055fc:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02055fe:	85a6                	mv	a1,s1
ffffffffc0205600:	07800513          	li	a0,120
ffffffffc0205604:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205606:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205608:	6782                	ld	a5,0(sp)
ffffffffc020560a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020560c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205610:	bfb5                	j	ffffffffc020558c <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205612:	000a3403          	ld	s0,0(s4)
ffffffffc0205616:	008a0713          	addi	a4,s4,8
ffffffffc020561a:	e03a                	sd	a4,0(sp)
ffffffffc020561c:	14040263          	beqz	s0,ffffffffc0205760 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205620:	0fb05763          	blez	s11,ffffffffc020570e <vprintfmt+0x2d8>
ffffffffc0205624:	02d00693          	li	a3,45
ffffffffc0205628:	0cd79163          	bne	a5,a3,ffffffffc02056ea <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020562c:	00044783          	lbu	a5,0(s0)
ffffffffc0205630:	0007851b          	sext.w	a0,a5
ffffffffc0205634:	cf85                	beqz	a5,ffffffffc020566c <vprintfmt+0x236>
ffffffffc0205636:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020563a:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020563e:	000c4563          	bltz	s8,ffffffffc0205648 <vprintfmt+0x212>
ffffffffc0205642:	3c7d                	addiw	s8,s8,-1
ffffffffc0205644:	036c0263          	beq	s8,s6,ffffffffc0205668 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205648:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020564a:	0e0c8e63          	beqz	s9,ffffffffc0205746 <vprintfmt+0x310>
ffffffffc020564e:	3781                	addiw	a5,a5,-32
ffffffffc0205650:	0ef47b63          	bgeu	s0,a5,ffffffffc0205746 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205654:	03f00513          	li	a0,63
ffffffffc0205658:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020565a:	000a4783          	lbu	a5,0(s4)
ffffffffc020565e:	3dfd                	addiw	s11,s11,-1
ffffffffc0205660:	0a05                	addi	s4,s4,1
ffffffffc0205662:	0007851b          	sext.w	a0,a5
ffffffffc0205666:	ffe1                	bnez	a5,ffffffffc020563e <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205668:	01b05963          	blez	s11,ffffffffc020567a <vprintfmt+0x244>
ffffffffc020566c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020566e:	85a6                	mv	a1,s1
ffffffffc0205670:	02000513          	li	a0,32
ffffffffc0205674:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205676:	fe0d9be3          	bnez	s11,ffffffffc020566c <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020567a:	6a02                	ld	s4,0(sp)
ffffffffc020567c:	bbd5                	j	ffffffffc0205470 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020567e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205680:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205684:	01174463          	blt	a4,a7,ffffffffc020568c <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205688:	08088d63          	beqz	a7,ffffffffc0205722 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020568c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205690:	0a044d63          	bltz	s0,ffffffffc020574a <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205694:	8622                	mv	a2,s0
ffffffffc0205696:	8a66                	mv	s4,s9
ffffffffc0205698:	46a9                	li	a3,10
ffffffffc020569a:	bdcd                	j	ffffffffc020558c <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020569c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056a0:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02056a2:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02056a4:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02056a8:	8fb5                	xor	a5,a5,a3
ffffffffc02056aa:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056ae:	02d74163          	blt	a4,a3,ffffffffc02056d0 <vprintfmt+0x29a>
ffffffffc02056b2:	00369793          	slli	a5,a3,0x3
ffffffffc02056b6:	97de                	add	a5,a5,s7
ffffffffc02056b8:	639c                	ld	a5,0(a5)
ffffffffc02056ba:	cb99                	beqz	a5,ffffffffc02056d0 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02056bc:	86be                	mv	a3,a5
ffffffffc02056be:	00000617          	auipc	a2,0x0
ffffffffc02056c2:	1f260613          	addi	a2,a2,498 # ffffffffc02058b0 <etext+0x2c>
ffffffffc02056c6:	85a6                	mv	a1,s1
ffffffffc02056c8:	854a                	mv	a0,s2
ffffffffc02056ca:	0ce000ef          	jal	ra,ffffffffc0205798 <printfmt>
ffffffffc02056ce:	b34d                	j	ffffffffc0205470 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02056d0:	00002617          	auipc	a2,0x2
ffffffffc02056d4:	01060613          	addi	a2,a2,16 # ffffffffc02076e0 <syscalls+0x120>
ffffffffc02056d8:	85a6                	mv	a1,s1
ffffffffc02056da:	854a                	mv	a0,s2
ffffffffc02056dc:	0bc000ef          	jal	ra,ffffffffc0205798 <printfmt>
ffffffffc02056e0:	bb41                	j	ffffffffc0205470 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02056e2:	00002417          	auipc	s0,0x2
ffffffffc02056e6:	ff640413          	addi	s0,s0,-10 # ffffffffc02076d8 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056ea:	85e2                	mv	a1,s8
ffffffffc02056ec:	8522                	mv	a0,s0
ffffffffc02056ee:	e43e                	sd	a5,8(sp)
ffffffffc02056f0:	0e2000ef          	jal	ra,ffffffffc02057d2 <strnlen>
ffffffffc02056f4:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02056f8:	01b05b63          	blez	s11,ffffffffc020570e <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02056fc:	67a2                	ld	a5,8(sp)
ffffffffc02056fe:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205702:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205704:	85a6                	mv	a1,s1
ffffffffc0205706:	8552                	mv	a0,s4
ffffffffc0205708:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020570a:	fe0d9ce3          	bnez	s11,ffffffffc0205702 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020570e:	00044783          	lbu	a5,0(s0)
ffffffffc0205712:	00140a13          	addi	s4,s0,1
ffffffffc0205716:	0007851b          	sext.w	a0,a5
ffffffffc020571a:	d3a5                	beqz	a5,ffffffffc020567a <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020571c:	05e00413          	li	s0,94
ffffffffc0205720:	bf39                	j	ffffffffc020563e <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205722:	000a2403          	lw	s0,0(s4)
ffffffffc0205726:	b7ad                	j	ffffffffc0205690 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205728:	000a6603          	lwu	a2,0(s4)
ffffffffc020572c:	46a1                	li	a3,8
ffffffffc020572e:	8a2e                	mv	s4,a1
ffffffffc0205730:	bdb1                	j	ffffffffc020558c <vprintfmt+0x156>
ffffffffc0205732:	000a6603          	lwu	a2,0(s4)
ffffffffc0205736:	46a9                	li	a3,10
ffffffffc0205738:	8a2e                	mv	s4,a1
ffffffffc020573a:	bd89                	j	ffffffffc020558c <vprintfmt+0x156>
ffffffffc020573c:	000a6603          	lwu	a2,0(s4)
ffffffffc0205740:	46c1                	li	a3,16
ffffffffc0205742:	8a2e                	mv	s4,a1
ffffffffc0205744:	b5a1                	j	ffffffffc020558c <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205746:	9902                	jalr	s2
ffffffffc0205748:	bf09                	j	ffffffffc020565a <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020574a:	85a6                	mv	a1,s1
ffffffffc020574c:	02d00513          	li	a0,45
ffffffffc0205750:	e03e                	sd	a5,0(sp)
ffffffffc0205752:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205754:	6782                	ld	a5,0(sp)
ffffffffc0205756:	8a66                	mv	s4,s9
ffffffffc0205758:	40800633          	neg	a2,s0
ffffffffc020575c:	46a9                	li	a3,10
ffffffffc020575e:	b53d                	j	ffffffffc020558c <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205760:	03b05163          	blez	s11,ffffffffc0205782 <vprintfmt+0x34c>
ffffffffc0205764:	02d00693          	li	a3,45
ffffffffc0205768:	f6d79de3          	bne	a5,a3,ffffffffc02056e2 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020576c:	00002417          	auipc	s0,0x2
ffffffffc0205770:	f6c40413          	addi	s0,s0,-148 # ffffffffc02076d8 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205774:	02800793          	li	a5,40
ffffffffc0205778:	02800513          	li	a0,40
ffffffffc020577c:	00140a13          	addi	s4,s0,1
ffffffffc0205780:	bd6d                	j	ffffffffc020563a <vprintfmt+0x204>
ffffffffc0205782:	00002a17          	auipc	s4,0x2
ffffffffc0205786:	f57a0a13          	addi	s4,s4,-169 # ffffffffc02076d9 <syscalls+0x119>
ffffffffc020578a:	02800513          	li	a0,40
ffffffffc020578e:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205792:	05e00413          	li	s0,94
ffffffffc0205796:	b565                	j	ffffffffc020563e <vprintfmt+0x208>

ffffffffc0205798 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205798:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020579a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020579e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057a0:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057a2:	ec06                	sd	ra,24(sp)
ffffffffc02057a4:	f83a                	sd	a4,48(sp)
ffffffffc02057a6:	fc3e                	sd	a5,56(sp)
ffffffffc02057a8:	e0c2                	sd	a6,64(sp)
ffffffffc02057aa:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02057ac:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057ae:	c89ff0ef          	jal	ra,ffffffffc0205436 <vprintfmt>
}
ffffffffc02057b2:	60e2                	ld	ra,24(sp)
ffffffffc02057b4:	6161                	addi	sp,sp,80
ffffffffc02057b6:	8082                	ret

ffffffffc02057b8 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02057b8:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02057bc:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02057be:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02057c0:	cb81                	beqz	a5,ffffffffc02057d0 <strlen+0x18>
        cnt ++;
ffffffffc02057c2:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02057c4:	00a707b3          	add	a5,a4,a0
ffffffffc02057c8:	0007c783          	lbu	a5,0(a5)
ffffffffc02057cc:	fbfd                	bnez	a5,ffffffffc02057c2 <strlen+0xa>
ffffffffc02057ce:	8082                	ret
    }
    return cnt;
}
ffffffffc02057d0:	8082                	ret

ffffffffc02057d2 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02057d2:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057d4:	e589                	bnez	a1,ffffffffc02057de <strnlen+0xc>
ffffffffc02057d6:	a811                	j	ffffffffc02057ea <strnlen+0x18>
        cnt ++;
ffffffffc02057d8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057da:	00f58863          	beq	a1,a5,ffffffffc02057ea <strnlen+0x18>
ffffffffc02057de:	00f50733          	add	a4,a0,a5
ffffffffc02057e2:	00074703          	lbu	a4,0(a4)
ffffffffc02057e6:	fb6d                	bnez	a4,ffffffffc02057d8 <strnlen+0x6>
ffffffffc02057e8:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02057ea:	852e                	mv	a0,a1
ffffffffc02057ec:	8082                	ret

ffffffffc02057ee <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02057ee:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02057f0:	0005c703          	lbu	a4,0(a1)
ffffffffc02057f4:	0785                	addi	a5,a5,1
ffffffffc02057f6:	0585                	addi	a1,a1,1
ffffffffc02057f8:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02057fc:	fb75                	bnez	a4,ffffffffc02057f0 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02057fe:	8082                	ret

ffffffffc0205800 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205800:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205804:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205808:	cb89                	beqz	a5,ffffffffc020581a <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020580a:	0505                	addi	a0,a0,1
ffffffffc020580c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020580e:	fee789e3          	beq	a5,a4,ffffffffc0205800 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205812:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205816:	9d19                	subw	a0,a0,a4
ffffffffc0205818:	8082                	ret
ffffffffc020581a:	4501                	li	a0,0
ffffffffc020581c:	bfed                	j	ffffffffc0205816 <strcmp+0x16>

ffffffffc020581e <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020581e:	c20d                	beqz	a2,ffffffffc0205840 <strncmp+0x22>
ffffffffc0205820:	962e                	add	a2,a2,a1
ffffffffc0205822:	a031                	j	ffffffffc020582e <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205824:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205826:	00e79a63          	bne	a5,a4,ffffffffc020583a <strncmp+0x1c>
ffffffffc020582a:	00b60b63          	beq	a2,a1,ffffffffc0205840 <strncmp+0x22>
ffffffffc020582e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205832:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205834:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205838:	f7f5                	bnez	a5,ffffffffc0205824 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020583a:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020583e:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205840:	4501                	li	a0,0
ffffffffc0205842:	8082                	ret

ffffffffc0205844 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205844:	00054783          	lbu	a5,0(a0)
ffffffffc0205848:	c799                	beqz	a5,ffffffffc0205856 <strchr+0x12>
        if (*s == c) {
ffffffffc020584a:	00f58763          	beq	a1,a5,ffffffffc0205858 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020584e:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205852:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205854:	fbfd                	bnez	a5,ffffffffc020584a <strchr+0x6>
    }
    return NULL;
ffffffffc0205856:	4501                	li	a0,0
}
ffffffffc0205858:	8082                	ret

ffffffffc020585a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020585a:	ca01                	beqz	a2,ffffffffc020586a <memset+0x10>
ffffffffc020585c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020585e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205860:	0785                	addi	a5,a5,1
ffffffffc0205862:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205866:	fec79de3          	bne	a5,a2,ffffffffc0205860 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020586a:	8082                	ret

ffffffffc020586c <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020586c:	ca19                	beqz	a2,ffffffffc0205882 <memcpy+0x16>
ffffffffc020586e:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205870:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205872:	0005c703          	lbu	a4,0(a1)
ffffffffc0205876:	0585                	addi	a1,a1,1
ffffffffc0205878:	0785                	addi	a5,a5,1
ffffffffc020587a:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020587e:	fec59ae3          	bne	a1,a2,ffffffffc0205872 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205882:	8082                	ret
