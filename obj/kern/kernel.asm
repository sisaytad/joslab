
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

00400000 <_start-0xc>:
.globl		_start
_start = entry

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
  400000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
  400006:	00 00                	add    %al,(%eax)
  400008:	fe 4f 52             	decb   0x52(%edi)
  40000b:	e4                   	.byte 0xe4

0040000c <_start>:
  40000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
  400013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(entry_pgdir), %eax
  400015:	b8 00 60 41 00       	mov    $0x416000,%eax
	movl	%eax, %cr3
  40001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
  40001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
  400020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
  400025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
  400028:	b8 2f 00 40 00       	mov    $0x40002f,%eax
	jmp	*%eax
  40002d:	ff e0                	jmp    *%eax

0040002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
  40002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
  400034:	bc 00 20 41 00       	mov    $0x412000,%esp

	# now to C code
	call	i386_init
  400039:	e8 31 01 00 00       	call   40016f <i386_init>

0040003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
  40003e:	eb fe                	jmp    40003e <spin>

00400040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
  400040:	55                   	push   %ebp
  400041:	89 e5                	mov    %esp,%ebp
  400043:	57                   	push   %edi
  400044:	56                   	push   %esi
  400045:	53                   	push   %ebx
  400046:	83 ec 0c             	sub    $0xc,%esp
  400049:	e8 12 02 00 00       	call   400260 <__x86.get_pc_thunk.bx>
  40004e:	81 c3 e6 52 01 00    	add    $0x152e6,%ebx
  400054:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
  400057:	c7 c0 c0 7f 41 00    	mov    $0x417fc0,%eax
  40005d:	83 38 00             	cmpl   $0x0,(%eax)
  400060:	74 0e                	je     400070 <_panic+0x30>
}

static inline void
outw(int port, uint16_t data)
{
	asm volatile("outw %0,%w1" : : "a" (data), "d" (port));
  400062:	b8 00 20 00 00       	mov    $0x2000,%eax
  400067:	ba 04 06 00 00       	mov    $0x604,%edx
  40006c:	66 ef                	out    %ax,(%dx)
  40006e:	eb fe                	jmp    40006e <_panic+0x2e>
		goto dead;
	panicstr = fmt;
  400070:	89 38                	mov    %edi,(%eax)

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
  400072:	fa                   	cli    
  400073:	fc                   	cld    

	va_start(ap, fmt);
  400074:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
  400077:	83 ec 04             	sub    $0x4,%esp
  40007a:	ff 75 0c             	pushl  0xc(%ebp)
  40007d:	ff 75 08             	pushl  0x8(%ebp)
  400080:	8d 83 8c cd fe ff    	lea    -0x13274(%ebx),%eax
  400086:	50                   	push   %eax
  400087:	e8 6c 08 00 00       	call   4008f8 <cprintf>
	vcprintf(fmt, ap);
  40008c:	83 c4 08             	add    $0x8,%esp
  40008f:	56                   	push   %esi
  400090:	57                   	push   %edi
  400091:	e8 2b 08 00 00       	call   4008c1 <vcprintf>
	cprintf("\n");
  400096:	8d 83 cf cd fe ff    	lea    -0x13231(%ebx),%eax
  40009c:	89 04 24             	mov    %eax,(%esp)
  40009f:	e8 54 08 00 00       	call   4008f8 <cprintf>
  4000a4:	83 c4 10             	add    $0x10,%esp
  4000a7:	eb b9                	jmp    400062 <_panic+0x22>

004000a9 <load_code>:
{
  4000a9:	55                   	push   %ebp
  4000aa:	89 e5                	mov    %esp,%ebp
  4000ac:	57                   	push   %edi
  4000ad:	56                   	push   %esi
  4000ae:	53                   	push   %ebx
  4000af:	83 ec 1c             	sub    $0x1c,%esp
  4000b2:	e8 a9 01 00 00       	call   400260 <__x86.get_pc_thunk.bx>
  4000b7:	81 c3 7d 52 01 00    	add    $0x1527d,%ebx
	if(header->e_magic != ELF_MAGIC) {
  4000bd:	8b 45 08             	mov    0x8(%ebp),%eax
  4000c0:	81 38 7f 45 4c 46    	cmpl   $0x464c457f,(%eax)
  4000c6:	75 11                	jne    4000d9 <load_code+0x30>
  4000c8:	8b 45 08             	mov    0x8(%ebp),%eax
  4000cb:	89 c6                	mov    %eax,%esi
  4000cd:	03 70 1c             	add    0x1c(%eax),%esi
	for(int i = 0; i < header->e_phnum; i++) {
  4000d0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  4000d7:	eb 37                	jmp    400110 <load_code+0x67>
		panic("not a an elf header");
  4000d9:	83 ec 04             	sub    $0x4,%esp
  4000dc:	8d 83 a4 cd fe ff    	lea    -0x1325c(%ebx),%eax
  4000e2:	50                   	push   %eax
  4000e3:	6a 47                	push   $0x47
  4000e5:	8d 83 b8 cd fe ff    	lea    -0x13248(%ebx),%eax
  4000eb:	50                   	push   %eax
  4000ec:	e8 4f ff ff ff       	call   400040 <_panic>
			panic("trying to load memory region outside correct region!\n");
  4000f1:	83 ec 04             	sub    $0x4,%esp
  4000f4:	8d 83 04 ce fe ff    	lea    -0x131fc(%ebx),%eax
  4000fa:	50                   	push   %eax
  4000fb:	6a 4e                	push   $0x4e
  4000fd:	8d 83 b8 cd fe ff    	lea    -0x13248(%ebx),%eax
  400103:	50                   	push   %eax
  400104:	e8 37 ff ff ff       	call   400040 <_panic>
	for(int i = 0; i < header->e_phnum; i++) {
  400109:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  40010d:	83 c6 20             	add    $0x20,%esi
  400110:	8b 45 08             	mov    0x8(%ebp),%eax
  400113:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  400117:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  40011a:	7e 45                	jle    400161 <load_code+0xb8>
		if(ph[i].p_type != ELF_PROG_LOAD) continue;
  40011c:	83 3e 01             	cmpl   $0x1,(%esi)
  40011f:	75 e8                	jne    400109 <load_code+0x60>
		if(ph[i].p_va < 0x800000  ||  ph[i].p_va > USTACKTOP) {
  400121:	8b 46 08             	mov    0x8(%esi),%eax
  400124:	8d 90 00 00 80 ff    	lea    -0x800000(%eax),%edx
  40012a:	81 fa 00 e0 2f 00    	cmp    $0x2fe000,%edx
  400130:	77 bf                	ja     4000f1 <load_code+0x48>
		memcpy((void *) ph[i].p_va,(void *) (binary+ph[i].p_offset),ph[i].p_filesz);
  400132:	83 ec 04             	sub    $0x4,%esp
  400135:	ff 76 10             	pushl  0x10(%esi)
  400138:	8b 55 08             	mov    0x8(%ebp),%edx
  40013b:	03 56 04             	add    0x4(%esi),%edx
  40013e:	52                   	push   %edx
  40013f:	50                   	push   %eax
  400140:	e8 d8 1b 00 00       	call   401d1d <memcpy>
		memset((void *) (ph[i].p_va + ph[i].p_filesz),0,(ph[i].p_memsz-ph[i].p_filesz));
  400145:	8b 46 10             	mov    0x10(%esi),%eax
  400148:	83 c4 0c             	add    $0xc,%esp
  40014b:	8b 56 14             	mov    0x14(%esi),%edx
  40014e:	29 c2                	sub    %eax,%edx
  400150:	52                   	push   %edx
  400151:	6a 00                	push   $0x0
  400153:	03 46 08             	add    0x8(%esi),%eax
  400156:	50                   	push   %eax
  400157:	e8 0c 1b 00 00       	call   401c68 <memset>
  40015c:	83 c4 10             	add    $0x10,%esp
  40015f:	eb a8                	jmp    400109 <load_code+0x60>
	return (void (*)()) header->e_entry;
  400161:	8b 45 08             	mov    0x8(%ebp),%eax
  400164:	8b 40 18             	mov    0x18(%eax),%eax
}
  400167:	8d 65 f4             	lea    -0xc(%ebp),%esp
  40016a:	5b                   	pop    %ebx
  40016b:	5e                   	pop    %esi
  40016c:	5f                   	pop    %edi
  40016d:	5d                   	pop    %ebp
  40016e:	c3                   	ret    

0040016f <i386_init>:
{
  40016f:	55                   	push   %ebp
  400170:	89 e5                	mov    %esp,%ebp
  400172:	56                   	push   %esi
  400173:	53                   	push   %ebx
  400174:	e8 e7 00 00 00       	call   400260 <__x86.get_pc_thunk.bx>
  400179:	81 c3 bb 51 01 00    	add    $0x151bb,%ebx
	memset(edata, 0, end - edata);
  40017f:	83 ec 04             	sub    $0x4,%esp
  400182:	c7 c2 c0 70 41 00    	mov    $0x4170c0,%edx
  400188:	c7 c0 a0 7f 41 00    	mov    $0x417fa0,%eax
  40018e:	29 d0                	sub    %edx,%eax
  400190:	50                   	push   %eax
  400191:	6a 00                	push   $0x0
  400193:	52                   	push   %edx
  400194:	e8 cf 1a 00 00       	call   401c68 <memset>
	cons_init();
  400199:	e8 17 05 00 00       	call   4006b5 <cons_init>
	cprintf(OS_START);
  40019e:	8d 83 c4 cd fe ff    	lea    -0x1323c(%ebx),%eax
  4001a4:	89 04 24             	mov    %eax,(%esp)
  4001a7:	e8 4c 07 00 00       	call   4008f8 <cprintf>
	env_init();
  4001ac:	e8 55 06 00 00       	call   400806 <env_init>
	trap_init();
  4001b1:	e8 f5 07 00 00       	call   4009ab <trap_init>
	ide_read(2000,binary_to_load,MAX_RW);
  4001b6:	83 c4 0c             	add    $0xc,%esp
  4001b9:	68 ff 00 00 00       	push   $0xff
  4001be:	c7 c6 e0 7f 41 00    	mov    $0x417fe0,%esi
  4001c4:	56                   	push   %esi
  4001c5:	68 d0 07 00 00       	push   $0x7d0
  4001ca:	e8 b3 10 00 00       	call   401282 <ide_read>
	if(header->e_magic == ELF_MAGIC) {
  4001cf:	83 c4 10             	add    $0x10,%esp
  4001d2:	81 3e 7f 45 4c 46    	cmpl   $0x464c457f,(%esi)
  4001d8:	74 26                	je     400200 <i386_init+0x91>
	void (*loaded_start_func)()  = load_code(binary_to_load);
  4001da:	83 ec 0c             	sub    $0xc,%esp
  4001dd:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
  4001e3:	e8 c1 fe ff ff       	call   4000a9 <load_code>
	initialize_new_trapframe(&env_tf,loaded_start_func);
  4001e8:	83 c4 08             	add    $0x8,%esp
  4001eb:	50                   	push   %eax
  4001ec:	c7 c6 e0 7d 43 00    	mov    $0x437de0,%esi
  4001f2:	56                   	push   %esi
  4001f3:	e8 49 06 00 00       	call   400841 <initialize_new_trapframe>
	run_trapframe(&env_tf);
  4001f8:	89 34 24             	mov    %esi,(%esp)
  4001fb:	e8 6e 06 00 00       	call   40086e <run_trapframe>
		cprintf("I found the ELF header!");
  400200:	83 ec 0c             	sub    $0xc,%esp
  400203:	8d 83 d1 cd fe ff    	lea    -0x1322f(%ebx),%eax
  400209:	50                   	push   %eax
  40020a:	e8 e9 06 00 00       	call   4008f8 <cprintf>
  40020f:	83 c4 10             	add    $0x10,%esp
  400212:	eb c6                	jmp    4001da <i386_init+0x6b>

00400214 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
  400214:	55                   	push   %ebp
  400215:	89 e5                	mov    %esp,%ebp
  400217:	56                   	push   %esi
  400218:	53                   	push   %ebx
  400219:	e8 42 00 00 00       	call   400260 <__x86.get_pc_thunk.bx>
  40021e:	81 c3 16 51 01 00    	add    $0x15116,%ebx
	va_list ap;

	va_start(ap, fmt);
  400224:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
  400227:	83 ec 04             	sub    $0x4,%esp
  40022a:	ff 75 0c             	pushl  0xc(%ebp)
  40022d:	ff 75 08             	pushl  0x8(%ebp)
  400230:	8d 83 e9 cd fe ff    	lea    -0x13217(%ebx),%eax
  400236:	50                   	push   %eax
  400237:	e8 bc 06 00 00       	call   4008f8 <cprintf>
	vcprintf(fmt, ap);
  40023c:	83 c4 08             	add    $0x8,%esp
  40023f:	56                   	push   %esi
  400240:	ff 75 10             	pushl  0x10(%ebp)
  400243:	e8 79 06 00 00       	call   4008c1 <vcprintf>
	cprintf("\n");
  400248:	8d 83 cf cd fe ff    	lea    -0x13231(%ebx),%eax
  40024e:	89 04 24             	mov    %eax,(%esp)
  400251:	e8 a2 06 00 00       	call   4008f8 <cprintf>
	va_end(ap);
}
  400256:	83 c4 10             	add    $0x10,%esp
  400259:	8d 65 f8             	lea    -0x8(%ebp),%esp
  40025c:	5b                   	pop    %ebx
  40025d:	5e                   	pop    %esi
  40025e:	5d                   	pop    %ebp
  40025f:	c3                   	ret    

00400260 <__x86.get_pc_thunk.bx>:
  400260:	8b 1c 24             	mov    (%esp),%ebx
  400263:	c3                   	ret    

00400264 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
  400264:	55                   	push   %ebp
  400265:	89 e5                	mov    %esp,%ebp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  400267:	ba fd 03 00 00       	mov    $0x3fd,%edx
  40026c:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  40026d:	a8 01                	test   $0x1,%al
  40026f:	74 0b                	je     40027c <serial_proc_data+0x18>
  400271:	ba f8 03 00 00       	mov    $0x3f8,%edx
  400276:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
  400277:	0f b6 c0             	movzbl %al,%eax
}
  40027a:	5d                   	pop    %ebp
  40027b:	c3                   	ret    
		return -1;
  40027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  400281:	eb f7                	jmp    40027a <serial_proc_data+0x16>

00400283 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
  400283:	55                   	push   %ebp
  400284:	89 e5                	mov    %esp,%ebp
  400286:	56                   	push   %esi
  400287:	53                   	push   %ebx
  400288:	e8 d3 ff ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  40028d:	81 c3 a7 50 01 00    	add    $0x150a7,%ebx
  400293:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
  400295:	ff d6                	call   *%esi
  400297:	83 f8 ff             	cmp    $0xffffffff,%eax
  40029a:	74 2e                	je     4002ca <cons_intr+0x47>
		if (c == 0)
  40029c:	85 c0                	test   %eax,%eax
  40029e:	74 f5                	je     400295 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
  4002a0:	8b 8b b0 1f 00 00    	mov    0x1fb0(%ebx),%ecx
  4002a6:	8d 51 01             	lea    0x1(%ecx),%edx
  4002a9:	89 93 b0 1f 00 00    	mov    %edx,0x1fb0(%ebx)
  4002af:	88 84 0b ac 1d 00 00 	mov    %al,0x1dac(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
  4002b6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
  4002bc:	75 d7                	jne    400295 <cons_intr+0x12>
			cons.wpos = 0;
  4002be:	c7 83 b0 1f 00 00 00 	movl   $0x0,0x1fb0(%ebx)
  4002c5:	00 00 00 
  4002c8:	eb cb                	jmp    400295 <cons_intr+0x12>
	}
}
  4002ca:	5b                   	pop    %ebx
  4002cb:	5e                   	pop    %esi
  4002cc:	5d                   	pop    %ebp
  4002cd:	c3                   	ret    

004002ce <kbd_proc_data>:
{
  4002ce:	55                   	push   %ebp
  4002cf:	89 e5                	mov    %esp,%ebp
  4002d1:	56                   	push   %esi
  4002d2:	53                   	push   %ebx
  4002d3:	e8 88 ff ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  4002d8:	81 c3 5c 50 01 00    	add    $0x1505c,%ebx
  4002de:	ba 64 00 00 00       	mov    $0x64,%edx
  4002e3:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
  4002e4:	a8 01                	test   $0x1,%al
  4002e6:	0f 84 06 01 00 00    	je     4003f2 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
  4002ec:	a8 20                	test   $0x20,%al
  4002ee:	0f 85 05 01 00 00    	jne    4003f9 <kbd_proc_data+0x12b>
  4002f4:	ba 60 00 00 00       	mov    $0x60,%edx
  4002f9:	ec                   	in     (%dx),%al
  4002fa:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
  4002fc:	3c e0                	cmp    $0xe0,%al
  4002fe:	0f 84 93 00 00 00    	je     400397 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
  400304:	84 c0                	test   %al,%al
  400306:	0f 88 a0 00 00 00    	js     4003ac <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
  40030c:	8b 8b 8c 1d 00 00    	mov    0x1d8c(%ebx),%ecx
  400312:	f6 c1 40             	test   $0x40,%cl
  400315:	74 0e                	je     400325 <kbd_proc_data+0x57>
		data |= 0x80;
  400317:	83 c8 80             	or     $0xffffff80,%eax
  40031a:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
  40031c:	83 e1 bf             	and    $0xffffffbf,%ecx
  40031f:	89 8b 8c 1d 00 00    	mov    %ecx,0x1d8c(%ebx)
	shift |= shiftcode[data];
  400325:	0f b6 d2             	movzbl %dl,%edx
  400328:	0f b6 84 13 6c cf fe 	movzbl -0x13094(%ebx,%edx,1),%eax
  40032f:	ff 
  400330:	0b 83 8c 1d 00 00    	or     0x1d8c(%ebx),%eax
	shift ^= togglecode[data];
  400336:	0f b6 8c 13 6c ce fe 	movzbl -0x13194(%ebx,%edx,1),%ecx
  40033d:	ff 
  40033e:	31 c8                	xor    %ecx,%eax
  400340:	89 83 8c 1d 00 00    	mov    %eax,0x1d8c(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
  400346:	89 c1                	mov    %eax,%ecx
  400348:	83 e1 03             	and    $0x3,%ecx
  40034b:	8b 8c 8b ec 1c 00 00 	mov    0x1cec(%ebx,%ecx,4),%ecx
  400352:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
  400356:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
  400359:	a8 08                	test   $0x8,%al
  40035b:	74 0d                	je     40036a <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
  40035d:	89 f2                	mov    %esi,%edx
  40035f:	8d 4e 9f             	lea    -0x61(%esi),%ecx
  400362:	83 f9 19             	cmp    $0x19,%ecx
  400365:	77 7a                	ja     4003e1 <kbd_proc_data+0x113>
			c += 'A' - 'a';
  400367:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  40036a:	f7 d0                	not    %eax
  40036c:	a8 06                	test   $0x6,%al
  40036e:	75 33                	jne    4003a3 <kbd_proc_data+0xd5>
  400370:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
  400376:	75 2b                	jne    4003a3 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
  400378:	83 ec 0c             	sub    $0xc,%esp
  40037b:	8d 83 3a ce fe ff    	lea    -0x131c6(%ebx),%eax
  400381:	50                   	push   %eax
  400382:	e8 71 05 00 00       	call   4008f8 <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
  400387:	b8 03 00 00 00       	mov    $0x3,%eax
  40038c:	ba 92 00 00 00       	mov    $0x92,%edx
  400391:	ee                   	out    %al,(%dx)
  400392:	83 c4 10             	add    $0x10,%esp
  400395:	eb 0c                	jmp    4003a3 <kbd_proc_data+0xd5>
		shift |= E0ESC;
  400397:	83 8b 8c 1d 00 00 40 	orl    $0x40,0x1d8c(%ebx)
		return 0;
  40039e:	be 00 00 00 00       	mov    $0x0,%esi
}
  4003a3:	89 f0                	mov    %esi,%eax
  4003a5:	8d 65 f8             	lea    -0x8(%ebp),%esp
  4003a8:	5b                   	pop    %ebx
  4003a9:	5e                   	pop    %esi
  4003aa:	5d                   	pop    %ebp
  4003ab:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
  4003ac:	8b 8b 8c 1d 00 00    	mov    0x1d8c(%ebx),%ecx
  4003b2:	89 ce                	mov    %ecx,%esi
  4003b4:	83 e6 40             	and    $0x40,%esi
  4003b7:	83 e0 7f             	and    $0x7f,%eax
  4003ba:	85 f6                	test   %esi,%esi
  4003bc:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
  4003bf:	0f b6 d2             	movzbl %dl,%edx
  4003c2:	0f b6 84 13 6c cf fe 	movzbl -0x13094(%ebx,%edx,1),%eax
  4003c9:	ff 
  4003ca:	83 c8 40             	or     $0x40,%eax
  4003cd:	0f b6 c0             	movzbl %al,%eax
  4003d0:	f7 d0                	not    %eax
  4003d2:	21 c8                	and    %ecx,%eax
  4003d4:	89 83 8c 1d 00 00    	mov    %eax,0x1d8c(%ebx)
		return 0;
  4003da:	be 00 00 00 00       	mov    $0x0,%esi
  4003df:	eb c2                	jmp    4003a3 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
  4003e1:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
  4003e4:	8d 4e 20             	lea    0x20(%esi),%ecx
  4003e7:	83 fa 1a             	cmp    $0x1a,%edx
  4003ea:	0f 42 f1             	cmovb  %ecx,%esi
  4003ed:	e9 78 ff ff ff       	jmp    40036a <kbd_proc_data+0x9c>
		return -1;
  4003f2:	be ff ff ff ff       	mov    $0xffffffff,%esi
  4003f7:	eb aa                	jmp    4003a3 <kbd_proc_data+0xd5>
		return -1;
  4003f9:	be ff ff ff ff       	mov    $0xffffffff,%esi
  4003fe:	eb a3                	jmp    4003a3 <kbd_proc_data+0xd5>

00400400 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
  400400:	55                   	push   %ebp
  400401:	89 e5                	mov    %esp,%ebp
  400403:	57                   	push   %edi
  400404:	56                   	push   %esi
  400405:	53                   	push   %ebx
  400406:	83 ec 1c             	sub    $0x1c,%esp
  400409:	e8 52 fe ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  40040e:	81 c3 26 4f 01 00    	add    $0x14f26,%ebx
  400414:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
  400417:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  40041c:	bf fd 03 00 00       	mov    $0x3fd,%edi
  400421:	b9 84 00 00 00       	mov    $0x84,%ecx
  400426:	eb 09                	jmp    400431 <cons_putc+0x31>
  400428:	89 ca                	mov    %ecx,%edx
  40042a:	ec                   	in     (%dx),%al
  40042b:	ec                   	in     (%dx),%al
  40042c:	ec                   	in     (%dx),%al
  40042d:	ec                   	in     (%dx),%al
	     i++)
  40042e:	83 c6 01             	add    $0x1,%esi
  400431:	89 fa                	mov    %edi,%edx
  400433:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  400434:	a8 20                	test   $0x20,%al
  400436:	75 08                	jne    400440 <cons_putc+0x40>
  400438:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
  40043e:	7e e8                	jle    400428 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
  400440:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  400443:	89 f8                	mov    %edi,%eax
  400445:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
  400448:	ba f8 03 00 00       	mov    $0x3f8,%edx
  40044d:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
  40044e:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  400453:	bf 79 03 00 00       	mov    $0x379,%edi
  400458:	b9 84 00 00 00       	mov    $0x84,%ecx
  40045d:	eb 09                	jmp    400468 <cons_putc+0x68>
  40045f:	89 ca                	mov    %ecx,%edx
  400461:	ec                   	in     (%dx),%al
  400462:	ec                   	in     (%dx),%al
  400463:	ec                   	in     (%dx),%al
  400464:	ec                   	in     (%dx),%al
  400465:	83 c6 01             	add    $0x1,%esi
  400468:	89 fa                	mov    %edi,%edx
  40046a:	ec                   	in     (%dx),%al
  40046b:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
  400471:	7f 04                	jg     400477 <cons_putc+0x77>
  400473:	84 c0                	test   %al,%al
  400475:	79 e8                	jns    40045f <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
  400477:	ba 78 03 00 00       	mov    $0x378,%edx
  40047c:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  400480:	ee                   	out    %al,(%dx)
  400481:	ba 7a 03 00 00       	mov    $0x37a,%edx
  400486:	b8 0d 00 00 00       	mov    $0xd,%eax
  40048b:	ee                   	out    %al,(%dx)
  40048c:	b8 08 00 00 00       	mov    $0x8,%eax
  400491:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
  400492:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  400495:	89 fa                	mov    %edi,%edx
  400497:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
  40049d:	89 f8                	mov    %edi,%eax
  40049f:	80 cc 07             	or     $0x7,%ah
  4004a2:	85 d2                	test   %edx,%edx
  4004a4:	0f 45 c7             	cmovne %edi,%eax
  4004a7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
  4004aa:	0f b6 c0             	movzbl %al,%eax
  4004ad:	83 f8 09             	cmp    $0x9,%eax
  4004b0:	0f 84 b9 00 00 00    	je     40056f <cons_putc+0x16f>
  4004b6:	83 f8 09             	cmp    $0x9,%eax
  4004b9:	7e 74                	jle    40052f <cons_putc+0x12f>
  4004bb:	83 f8 0a             	cmp    $0xa,%eax
  4004be:	0f 84 9e 00 00 00    	je     400562 <cons_putc+0x162>
  4004c4:	83 f8 0d             	cmp    $0xd,%eax
  4004c7:	0f 85 d9 00 00 00    	jne    4005a6 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
  4004cd:	0f b7 83 b4 1f 00 00 	movzwl 0x1fb4(%ebx),%eax
  4004d4:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  4004da:	c1 e8 16             	shr    $0x16,%eax
  4004dd:	8d 04 80             	lea    (%eax,%eax,4),%eax
  4004e0:	c1 e0 04             	shl    $0x4,%eax
  4004e3:	66 89 83 b4 1f 00 00 	mov    %ax,0x1fb4(%ebx)
	if (crt_pos >= CRT_SIZE) {
  4004ea:	66 81 bb b4 1f 00 00 	cmpw   $0x7cf,0x1fb4(%ebx)
  4004f1:	cf 07 
  4004f3:	0f 87 d4 00 00 00    	ja     4005cd <cons_putc+0x1cd>
	outb(addr_6845, 14);
  4004f9:	8b 8b bc 1f 00 00    	mov    0x1fbc(%ebx),%ecx
  4004ff:	b8 0e 00 00 00       	mov    $0xe,%eax
  400504:	89 ca                	mov    %ecx,%edx
  400506:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  400507:	0f b7 9b b4 1f 00 00 	movzwl 0x1fb4(%ebx),%ebx
  40050e:	8d 71 01             	lea    0x1(%ecx),%esi
  400511:	89 d8                	mov    %ebx,%eax
  400513:	66 c1 e8 08          	shr    $0x8,%ax
  400517:	89 f2                	mov    %esi,%edx
  400519:	ee                   	out    %al,(%dx)
  40051a:	b8 0f 00 00 00       	mov    $0xf,%eax
  40051f:	89 ca                	mov    %ecx,%edx
  400521:	ee                   	out    %al,(%dx)
  400522:	89 d8                	mov    %ebx,%eax
  400524:	89 f2                	mov    %esi,%edx
  400526:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
  400527:	8d 65 f4             	lea    -0xc(%ebp),%esp
  40052a:	5b                   	pop    %ebx
  40052b:	5e                   	pop    %esi
  40052c:	5f                   	pop    %edi
  40052d:	5d                   	pop    %ebp
  40052e:	c3                   	ret    
	switch (c & 0xff) {
  40052f:	83 f8 08             	cmp    $0x8,%eax
  400532:	75 72                	jne    4005a6 <cons_putc+0x1a6>
		if (crt_pos > 0) {
  400534:	0f b7 83 b4 1f 00 00 	movzwl 0x1fb4(%ebx),%eax
  40053b:	66 85 c0             	test   %ax,%ax
  40053e:	74 b9                	je     4004f9 <cons_putc+0xf9>
			crt_pos--;
  400540:	83 e8 01             	sub    $0x1,%eax
  400543:	66 89 83 b4 1f 00 00 	mov    %ax,0x1fb4(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  40054a:	0f b7 c0             	movzwl %ax,%eax
  40054d:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
  400551:	b2 00                	mov    $0x0,%dl
  400553:	83 ca 20             	or     $0x20,%edx
  400556:	8b 8b b8 1f 00 00    	mov    0x1fb8(%ebx),%ecx
  40055c:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
  400560:	eb 88                	jmp    4004ea <cons_putc+0xea>
		crt_pos += CRT_COLS;
  400562:	66 83 83 b4 1f 00 00 	addw   $0x50,0x1fb4(%ebx)
  400569:	50 
  40056a:	e9 5e ff ff ff       	jmp    4004cd <cons_putc+0xcd>
		cons_putc(' ');
  40056f:	b8 20 00 00 00       	mov    $0x20,%eax
  400574:	e8 87 fe ff ff       	call   400400 <cons_putc>
		cons_putc(' ');
  400579:	b8 20 00 00 00       	mov    $0x20,%eax
  40057e:	e8 7d fe ff ff       	call   400400 <cons_putc>
		cons_putc(' ');
  400583:	b8 20 00 00 00       	mov    $0x20,%eax
  400588:	e8 73 fe ff ff       	call   400400 <cons_putc>
		cons_putc(' ');
  40058d:	b8 20 00 00 00       	mov    $0x20,%eax
  400592:	e8 69 fe ff ff       	call   400400 <cons_putc>
		cons_putc(' ');
  400597:	b8 20 00 00 00       	mov    $0x20,%eax
  40059c:	e8 5f fe ff ff       	call   400400 <cons_putc>
  4005a1:	e9 44 ff ff ff       	jmp    4004ea <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
  4005a6:	0f b7 83 b4 1f 00 00 	movzwl 0x1fb4(%ebx),%eax
  4005ad:	8d 50 01             	lea    0x1(%eax),%edx
  4005b0:	66 89 93 b4 1f 00 00 	mov    %dx,0x1fb4(%ebx)
  4005b7:	0f b7 c0             	movzwl %ax,%eax
  4005ba:	8b 93 b8 1f 00 00    	mov    0x1fb8(%ebx),%edx
  4005c0:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
  4005c4:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
  4005c8:	e9 1d ff ff ff       	jmp    4004ea <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
  4005cd:	8b 83 b8 1f 00 00    	mov    0x1fb8(%ebx),%eax
  4005d3:	83 ec 04             	sub    $0x4,%esp
  4005d6:	68 00 0f 00 00       	push   $0xf00
  4005db:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  4005e1:	52                   	push   %edx
  4005e2:	50                   	push   %eax
  4005e3:	e8 cd 16 00 00       	call   401cb5 <memmove>
			crt_buf[i] = 0x0700 | ' ';
  4005e8:	8b 93 b8 1f 00 00    	mov    0x1fb8(%ebx),%edx
  4005ee:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
  4005f4:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
  4005fa:	83 c4 10             	add    $0x10,%esp
  4005fd:	66 c7 00 20 07       	movw   $0x720,(%eax)
  400602:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  400605:	39 d0                	cmp    %edx,%eax
  400607:	75 f4                	jne    4005fd <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
  400609:	66 83 ab b4 1f 00 00 	subw   $0x50,0x1fb4(%ebx)
  400610:	50 
  400611:	e9 e3 fe ff ff       	jmp    4004f9 <cons_putc+0xf9>

00400616 <serial_intr>:
{
  400616:	e8 e7 01 00 00       	call   400802 <__x86.get_pc_thunk.ax>
  40061b:	05 19 4d 01 00       	add    $0x14d19,%eax
	if (serial_exists)
  400620:	80 b8 c0 1f 00 00 00 	cmpb   $0x0,0x1fc0(%eax)
  400627:	75 02                	jne    40062b <serial_intr+0x15>
  400629:	f3 c3                	repz ret 
{
  40062b:	55                   	push   %ebp
  40062c:	89 e5                	mov    %esp,%ebp
  40062e:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
  400631:	8d 80 30 af fe ff    	lea    -0x150d0(%eax),%eax
  400637:	e8 47 fc ff ff       	call   400283 <cons_intr>
}
  40063c:	c9                   	leave  
  40063d:	c3                   	ret    

0040063e <kbd_intr>:
{
  40063e:	55                   	push   %ebp
  40063f:	89 e5                	mov    %esp,%ebp
  400641:	83 ec 08             	sub    $0x8,%esp
  400644:	e8 b9 01 00 00       	call   400802 <__x86.get_pc_thunk.ax>
  400649:	05 eb 4c 01 00       	add    $0x14ceb,%eax
	cons_intr(kbd_proc_data);
  40064e:	8d 80 9a af fe ff    	lea    -0x15066(%eax),%eax
  400654:	e8 2a fc ff ff       	call   400283 <cons_intr>
}
  400659:	c9                   	leave  
  40065a:	c3                   	ret    

0040065b <cons_getc>:
{
  40065b:	55                   	push   %ebp
  40065c:	89 e5                	mov    %esp,%ebp
  40065e:	53                   	push   %ebx
  40065f:	83 ec 04             	sub    $0x4,%esp
  400662:	e8 f9 fb ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  400667:	81 c3 cd 4c 01 00    	add    $0x14ccd,%ebx
	serial_intr();
  40066d:	e8 a4 ff ff ff       	call   400616 <serial_intr>
	kbd_intr();
  400672:	e8 c7 ff ff ff       	call   40063e <kbd_intr>
	if (cons.rpos != cons.wpos) {
  400677:	8b 93 ac 1f 00 00    	mov    0x1fac(%ebx),%edx
	return 0;
  40067d:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
  400682:	3b 93 b0 1f 00 00    	cmp    0x1fb0(%ebx),%edx
  400688:	74 19                	je     4006a3 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
  40068a:	8d 4a 01             	lea    0x1(%edx),%ecx
  40068d:	89 8b ac 1f 00 00    	mov    %ecx,0x1fac(%ebx)
  400693:	0f b6 84 13 ac 1d 00 	movzbl 0x1dac(%ebx,%edx,1),%eax
  40069a:	00 
		if (cons.rpos == CONSBUFSIZE)
  40069b:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
  4006a1:	74 06                	je     4006a9 <cons_getc+0x4e>
}
  4006a3:	83 c4 04             	add    $0x4,%esp
  4006a6:	5b                   	pop    %ebx
  4006a7:	5d                   	pop    %ebp
  4006a8:	c3                   	ret    
			cons.rpos = 0;
  4006a9:	c7 83 ac 1f 00 00 00 	movl   $0x0,0x1fac(%ebx)
  4006b0:	00 00 00 
  4006b3:	eb ee                	jmp    4006a3 <cons_getc+0x48>

004006b5 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  4006b5:	55                   	push   %ebp
  4006b6:	89 e5                	mov    %esp,%ebp
  4006b8:	57                   	push   %edi
  4006b9:	56                   	push   %esi
  4006ba:	53                   	push   %ebx
  4006bb:	83 ec 1c             	sub    $0x1c,%esp
  4006be:	e8 9d fb ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  4006c3:	81 c3 71 4c 01 00    	add    $0x14c71,%ebx
	was = *cp;
  4006c9:	0f b7 15 00 80 0b 00 	movzwl 0xb8000,%edx
	*cp = (uint16_t) 0xA55A;
  4006d0:	66 c7 05 00 80 0b 00 	movw   $0xa55a,0xb8000
  4006d7:	5a a5 
	if (*cp != 0xA55A) {
  4006d9:	0f b7 05 00 80 0b 00 	movzwl 0xb8000,%eax
  4006e0:	66 3d 5a a5          	cmp    $0xa55a,%ax
  4006e4:	0f 84 bc 00 00 00    	je     4007a6 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
  4006ea:	c7 83 bc 1f 00 00 b4 	movl   $0x3b4,0x1fbc(%ebx)
  4006f1:	03 00 00 
		cp = (uint16_t*) MONO_BUF;
  4006f4:	c7 45 e4 00 00 0b 00 	movl   $0xb0000,-0x1c(%ebp)
	outb(addr_6845, 14);
  4006fb:	8b bb bc 1f 00 00    	mov    0x1fbc(%ebx),%edi
  400701:	b8 0e 00 00 00       	mov    $0xe,%eax
  400706:	89 fa                	mov    %edi,%edx
  400708:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  400709:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  40070c:	89 ca                	mov    %ecx,%edx
  40070e:	ec                   	in     (%dx),%al
  40070f:	0f b6 f0             	movzbl %al,%esi
  400712:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
  400715:	b8 0f 00 00 00       	mov    $0xf,%eax
  40071a:	89 fa                	mov    %edi,%edx
  40071c:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  40071d:	89 ca                	mov    %ecx,%edx
  40071f:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
  400720:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  400723:	89 bb b8 1f 00 00    	mov    %edi,0x1fb8(%ebx)
	pos |= inb(addr_6845 + 1);
  400729:	0f b6 c0             	movzbl %al,%eax
  40072c:	09 c6                	or     %eax,%esi
	crt_pos = pos;
  40072e:	66 89 b3 b4 1f 00 00 	mov    %si,0x1fb4(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
  400735:	b9 00 00 00 00       	mov    $0x0,%ecx
  40073a:	89 c8                	mov    %ecx,%eax
  40073c:	ba fa 03 00 00       	mov    $0x3fa,%edx
  400741:	ee                   	out    %al,(%dx)
  400742:	bf fb 03 00 00       	mov    $0x3fb,%edi
  400747:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
  40074c:	89 fa                	mov    %edi,%edx
  40074e:	ee                   	out    %al,(%dx)
  40074f:	b8 0c 00 00 00       	mov    $0xc,%eax
  400754:	ba f8 03 00 00       	mov    $0x3f8,%edx
  400759:	ee                   	out    %al,(%dx)
  40075a:	be f9 03 00 00       	mov    $0x3f9,%esi
  40075f:	89 c8                	mov    %ecx,%eax
  400761:	89 f2                	mov    %esi,%edx
  400763:	ee                   	out    %al,(%dx)
  400764:	b8 03 00 00 00       	mov    $0x3,%eax
  400769:	89 fa                	mov    %edi,%edx
  40076b:	ee                   	out    %al,(%dx)
  40076c:	ba fc 03 00 00       	mov    $0x3fc,%edx
  400771:	89 c8                	mov    %ecx,%eax
  400773:	ee                   	out    %al,(%dx)
  400774:	b8 01 00 00 00       	mov    $0x1,%eax
  400779:	89 f2                	mov    %esi,%edx
  40077b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  40077c:	ba fd 03 00 00       	mov    $0x3fd,%edx
  400781:	ec                   	in     (%dx),%al
  400782:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  400784:	3c ff                	cmp    $0xff,%al
  400786:	0f 95 83 c0 1f 00 00 	setne  0x1fc0(%ebx)
  40078d:	ba fa 03 00 00       	mov    $0x3fa,%edx
  400792:	ec                   	in     (%dx),%al
  400793:	ba f8 03 00 00       	mov    $0x3f8,%edx
  400798:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
  400799:	80 f9 ff             	cmp    $0xff,%cl
  40079c:	74 25                	je     4007c3 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
  40079e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  4007a1:	5b                   	pop    %ebx
  4007a2:	5e                   	pop    %esi
  4007a3:	5f                   	pop    %edi
  4007a4:	5d                   	pop    %ebp
  4007a5:	c3                   	ret    
		*cp = was;
  4007a6:	66 89 15 00 80 0b 00 	mov    %dx,0xb8000
		addr_6845 = CGA_BASE;
  4007ad:	c7 83 bc 1f 00 00 d4 	movl   $0x3d4,0x1fbc(%ebx)
  4007b4:	03 00 00 
	cp = (uint16_t*) CGA_BUF;
  4007b7:	c7 45 e4 00 80 0b 00 	movl   $0xb8000,-0x1c(%ebp)
  4007be:	e9 38 ff ff ff       	jmp    4006fb <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
  4007c3:	83 ec 0c             	sub    $0xc,%esp
  4007c6:	8d 83 46 ce fe ff    	lea    -0x131ba(%ebx),%eax
  4007cc:	50                   	push   %eax
  4007cd:	e8 26 01 00 00       	call   4008f8 <cprintf>
  4007d2:	83 c4 10             	add    $0x10,%esp
}
  4007d5:	eb c7                	jmp    40079e <cons_init+0xe9>

004007d7 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
  4007d7:	55                   	push   %ebp
  4007d8:	89 e5                	mov    %esp,%ebp
  4007da:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
  4007dd:	8b 45 08             	mov    0x8(%ebp),%eax
  4007e0:	e8 1b fc ff ff       	call   400400 <cons_putc>
}
  4007e5:	c9                   	leave  
  4007e6:	c3                   	ret    

004007e7 <getchar>:

int
getchar(void)
{
  4007e7:	55                   	push   %ebp
  4007e8:	89 e5                	mov    %esp,%ebp
  4007ea:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
  4007ed:	e8 69 fe ff ff       	call   40065b <cons_getc>
  4007f2:	85 c0                	test   %eax,%eax
  4007f4:	74 f7                	je     4007ed <getchar+0x6>
		/* do nothing */;
	return c;
}
  4007f6:	c9                   	leave  
  4007f7:	c3                   	ret    

004007f8 <iscons>:

int
iscons(int fdnum)
{
  4007f8:	55                   	push   %ebp
  4007f9:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
  4007fb:	b8 01 00 00 00       	mov    $0x1,%eax
  400800:	5d                   	pop    %ebp
  400801:	c3                   	ret    

00400802 <__x86.get_pc_thunk.ax>:
  400802:	8b 04 24             	mov    (%esp),%eax
  400805:	c3                   	ret    

00400806 <env_init>:
};


void
env_init(void)
{
  400806:	55                   	push   %ebp
  400807:	89 e5                	mov    %esp,%ebp
  400809:	e8 f4 ff ff ff       	call   400802 <__x86.get_pc_thunk.ax>
  40080e:	05 26 4b 01 00       	add    $0x14b26,%eax
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
  400813:	8d 80 cc 1c 00 00    	lea    0x1ccc(%eax),%eax
  400819:	0f 01 10             	lgdtl  (%eax)
	
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
  40081c:	b8 23 00 00 00       	mov    $0x23,%eax
  400821:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
  400823:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
  400825:	b8 10 00 00 00       	mov    $0x10,%eax
  40082a:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
  40082c:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
  40082e:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
  400830:	ea 37 08 40 00 08 00 	ljmp   $0x8,$0x400837
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
  400837:	b8 00 00 00 00       	mov    $0x0,%eax
  40083c:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
  40083f:	5d                   	pop    %ebp
  400840:	c3                   	ret    

00400841 <initialize_new_trapframe>:


void initialize_new_trapframe(struct Trapframe *tf, void (*entry_point)()) {
  400841:	55                   	push   %ebp
  400842:	89 e5                	mov    %esp,%ebp
  400844:	8b 45 08             	mov    0x8(%ebp),%eax

	// set the stack to the universal stack top
	tf->tf_esp = USTACKTOP;
  400847:	c7 40 3c 00 e0 af 00 	movl   $0xafe000,0x3c(%eax)
	
	// Set all the segment registers so that this code runs in
	// user rather than kernel mode
	tf->tf_ds = GD_UD | 3;
  40084e:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	tf->tf_es = GD_UD | 3;
  400854:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	tf->tf_ss = GD_UD | 3;
  40085a:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	tf->tf_cs = GD_UT | 3;
  400860:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)

	// Set the instruction pointer to the entry point
	tf->tf_eip = (uintptr_t) entry_point;
  400866:	8b 55 0c             	mov    0xc(%ebp),%edx
  400869:	89 50 30             	mov    %edx,0x30(%eax)
}
  40086c:	5d                   	pop    %ebp
  40086d:	c3                   	ret    

0040086e <run_trapframe>:
//
// This function does not return.
//
void
run_trapframe(struct Trapframe *tf)
{
  40086e:	55                   	push   %ebp
  40086f:	89 e5                	mov    %esp,%ebp
  400871:	53                   	push   %ebx
  400872:	83 ec 08             	sub    $0x8,%esp
  400875:	e8 e6 f9 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  40087a:	81 c3 ba 4a 01 00    	add    $0x14aba,%ebx
	asm volatile(
  400880:	8b 65 08             	mov    0x8(%ebp),%esp
  400883:	61                   	popa   
  400884:	07                   	pop    %es
  400885:	1f                   	pop    %ds
  400886:	83 c4 08             	add    $0x8,%esp
  400889:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
  40088a:	8d 83 6c d0 fe ff    	lea    -0x12f94(%ebx),%eax
  400890:	50                   	push   %eax
  400891:	6a 71                	push   $0x71
  400893:	8d 83 78 d0 fe ff    	lea    -0x12f88(%ebx),%eax
  400899:	50                   	push   %eax
  40089a:	e8 a1 f7 ff ff       	call   400040 <_panic>

0040089f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
  40089f:	55                   	push   %ebp
  4008a0:	89 e5                	mov    %esp,%ebp
  4008a2:	53                   	push   %ebx
  4008a3:	83 ec 10             	sub    $0x10,%esp
  4008a6:	e8 b5 f9 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  4008ab:	81 c3 89 4a 01 00    	add    $0x14a89,%ebx
	cputchar(ch);
  4008b1:	ff 75 08             	pushl  0x8(%ebp)
  4008b4:	e8 1e ff ff ff       	call   4007d7 <cputchar>
	*cnt++;
}
  4008b9:	83 c4 10             	add    $0x10,%esp
  4008bc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  4008bf:	c9                   	leave  
  4008c0:	c3                   	ret    

004008c1 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  4008c1:	55                   	push   %ebp
  4008c2:	89 e5                	mov    %esp,%ebp
  4008c4:	53                   	push   %ebx
  4008c5:	83 ec 14             	sub    $0x14,%esp
  4008c8:	e8 93 f9 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  4008cd:	81 c3 67 4a 01 00    	add    $0x14a67,%ebx
	int cnt = 0;
  4008d3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
  4008da:	ff 75 0c             	pushl  0xc(%ebp)
  4008dd:	ff 75 08             	pushl  0x8(%ebp)
  4008e0:	8d 45 f4             	lea    -0xc(%ebp),%eax
  4008e3:	50                   	push   %eax
  4008e4:	8d 83 6b b5 fe ff    	lea    -0x14a95(%ebx),%eax
  4008ea:	50                   	push   %eax
  4008eb:	e8 28 0c 00 00       	call   401518 <vprintfmt>
	return cnt;
}
  4008f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  4008f3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  4008f6:	c9                   	leave  
  4008f7:	c3                   	ret    

004008f8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  4008f8:	55                   	push   %ebp
  4008f9:	89 e5                	mov    %esp,%ebp
  4008fb:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  4008fe:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  400901:	50                   	push   %eax
  400902:	ff 75 08             	pushl  0x8(%ebp)
  400905:	e8 b7 ff ff ff       	call   4008c1 <vcprintf>
	va_end(ap);

	return cnt;
}
  40090a:	c9                   	leave  
  40090b:	c3                   	ret    

0040090c <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
  40090c:	55                   	push   %ebp
  40090d:	89 e5                	mov    %esp,%ebp
  40090f:	57                   	push   %edi
  400910:	56                   	push   %esi
  400911:	53                   	push   %ebx
  400912:	83 ec 04             	sub    $0x4,%esp
  400915:	e8 46 f9 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  40091a:	81 c3 1a 4a 01 00    	add    $0x14a1a,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
  400920:	c7 83 f0 27 00 00 00 	movl   $0x400000,0x27f0(%ebx)
  400927:	00 40 00 
	ts.ts_ss0 = GD_KD;
  40092a:	66 c7 83 f4 27 00 00 	movw   $0x10,0x27f4(%ebx)
  400931:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
  400933:	66 c7 83 52 28 00 00 	movw   $0x68,0x2852(%ebx)
  40093a:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
  40093c:	c7 c0 00 53 41 00    	mov    $0x415300,%eax
  400942:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
  400948:	8d b3 ec 27 00 00    	lea    0x27ec(%ebx),%esi
  40094e:	66 89 70 2a          	mov    %si,0x2a(%eax)
  400952:	89 f2                	mov    %esi,%edx
  400954:	c1 ea 10             	shr    $0x10,%edx
  400957:	88 50 2c             	mov    %dl,0x2c(%eax)
  40095a:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
  40095e:	83 e2 f0             	and    $0xfffffff0,%edx
  400961:	83 ca 09             	or     $0x9,%edx
  400964:	83 e2 9f             	and    $0xffffff9f,%edx
  400967:	83 ca 80             	or     $0xffffff80,%edx
  40096a:	88 55 f3             	mov    %dl,-0xd(%ebp)
  40096d:	88 50 2d             	mov    %dl,0x2d(%eax)
  400970:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
  400974:	83 e1 c0             	and    $0xffffffc0,%ecx
  400977:	83 c9 40             	or     $0x40,%ecx
  40097a:	83 e1 7f             	and    $0x7f,%ecx
  40097d:	88 48 2e             	mov    %cl,0x2e(%eax)
  400980:	c1 ee 18             	shr    $0x18,%esi
  400983:	89 f1                	mov    %esi,%ecx
  400985:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
  400988:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
  40098c:	83 e2 ef             	and    $0xffffffef,%edx
  40098f:	88 50 2d             	mov    %dl,0x2d(%eax)
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
  400992:	b8 28 00 00 00       	mov    $0x28,%eax
  400997:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
  40099a:	8d 83 d4 1c 00 00    	lea    0x1cd4(%ebx),%eax
  4009a0:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
  4009a3:	83 c4 04             	add    $0x4,%esp
  4009a6:	5b                   	pop    %ebx
  4009a7:	5e                   	pop    %esi
  4009a8:	5f                   	pop    %edi
  4009a9:	5d                   	pop    %ebp
  4009aa:	c3                   	ret    

004009ab <trap_init>:
{
  4009ab:	55                   	push   %ebp
  4009ac:	89 e5                	mov    %esp,%ebp
  4009ae:	56                   	push   %esi
  4009af:	53                   	push   %ebx
  4009b0:	e8 88 07 00 00       	call   40113d <__x86.get_pc_thunk.dx>
  4009b5:	81 c2 7f 49 01 00    	add    $0x1497f,%edx
		SETGATE(idt[i], 0, GD_KT, unktraphandler, 0);
  4009bb:	c7 c3 42 11 40 00    	mov    $0x401142,%ebx
  4009c1:	c1 eb 10             	shr    $0x10,%ebx
	for(int i = 0; i <= 255; i++) {
  4009c4:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i], 0, GD_KT, unktraphandler, 0);
  4009c9:	c7 c6 42 11 40 00    	mov    $0x401142,%esi
  4009cf:	66 89 b4 c2 cc 1f 00 	mov    %si,0x1fcc(%edx,%eax,8)
  4009d6:	00 
  4009d7:	8d 8c c2 cc 1f 00 00 	lea    0x1fcc(%edx,%eax,8),%ecx
  4009de:	66 c7 41 02 08 00    	movw   $0x8,0x2(%ecx)
  4009e4:	c6 84 c2 d0 1f 00 00 	movb   $0x0,0x1fd0(%edx,%eax,8)
  4009eb:	00 
  4009ec:	c6 84 c2 d1 1f 00 00 	movb   $0x8e,0x1fd1(%edx,%eax,8)
  4009f3:	8e 
  4009f4:	66 89 59 06          	mov    %bx,0x6(%ecx)
	for(int i = 0; i <= 255; i++) {
  4009f8:	83 c0 01             	add    $0x1,%eax
  4009fb:	3d 00 01 00 00       	cmp    $0x100,%eax
  400a00:	75 cd                	jne    4009cf <trap_init+0x24>
	SETGATE(idt[0], 0, GD_KT, th0, 0);
  400a02:	c7 c0 48 11 40 00    	mov    $0x401148,%eax
  400a08:	66 89 82 cc 1f 00 00 	mov    %ax,0x1fcc(%edx)
  400a0f:	66 c7 82 ce 1f 00 00 	movw   $0x8,0x1fce(%edx)
  400a16:	08 00 
  400a18:	c6 82 d0 1f 00 00 00 	movb   $0x0,0x1fd0(%edx)
  400a1f:	c6 82 d1 1f 00 00 8e 	movb   $0x8e,0x1fd1(%edx)
  400a26:	c1 e8 10             	shr    $0x10,%eax
  400a29:	66 89 82 d2 1f 00 00 	mov    %ax,0x1fd2(%edx)
	SETGATE(idt[1], 0, GD_KT, th1, 0);
  400a30:	c7 c0 4e 11 40 00    	mov    $0x40114e,%eax
  400a36:	66 89 82 d4 1f 00 00 	mov    %ax,0x1fd4(%edx)
  400a3d:	66 c7 82 d6 1f 00 00 	movw   $0x8,0x1fd6(%edx)
  400a44:	08 00 
  400a46:	c6 82 d8 1f 00 00 00 	movb   $0x0,0x1fd8(%edx)
  400a4d:	c6 82 d9 1f 00 00 8e 	movb   $0x8e,0x1fd9(%edx)
  400a54:	c1 e8 10             	shr    $0x10,%eax
  400a57:	66 89 82 da 1f 00 00 	mov    %ax,0x1fda(%edx)
	SETGATE(idt[2], 0, GD_KT, th2, 0);
  400a5e:	c7 c0 54 11 40 00    	mov    $0x401154,%eax
  400a64:	66 89 82 dc 1f 00 00 	mov    %ax,0x1fdc(%edx)
  400a6b:	66 c7 82 de 1f 00 00 	movw   $0x8,0x1fde(%edx)
  400a72:	08 00 
  400a74:	c6 82 e0 1f 00 00 00 	movb   $0x0,0x1fe0(%edx)
  400a7b:	c6 82 e1 1f 00 00 8e 	movb   $0x8e,0x1fe1(%edx)
  400a82:	c1 e8 10             	shr    $0x10,%eax
  400a85:	66 89 82 e2 1f 00 00 	mov    %ax,0x1fe2(%edx)
	SETGATE(idt[3], 1, GD_KT, th3, 3);
  400a8c:	c7 c0 58 11 40 00    	mov    $0x401158,%eax
  400a92:	66 89 82 e4 1f 00 00 	mov    %ax,0x1fe4(%edx)
  400a99:	66 c7 82 e6 1f 00 00 	movw   $0x8,0x1fe6(%edx)
  400aa0:	08 00 
  400aa2:	c6 82 e8 1f 00 00 00 	movb   $0x0,0x1fe8(%edx)
  400aa9:	c6 82 e9 1f 00 00 ef 	movb   $0xef,0x1fe9(%edx)
  400ab0:	c1 e8 10             	shr    $0x10,%eax
  400ab3:	66 89 82 ea 1f 00 00 	mov    %ax,0x1fea(%edx)
	SETGATE(idt[4], 0, GD_KT, th4, 0);
  400aba:	c7 c0 5e 11 40 00    	mov    $0x40115e,%eax
  400ac0:	66 89 82 ec 1f 00 00 	mov    %ax,0x1fec(%edx)
  400ac7:	66 c7 82 ee 1f 00 00 	movw   $0x8,0x1fee(%edx)
  400ace:	08 00 
  400ad0:	c6 82 f0 1f 00 00 00 	movb   $0x0,0x1ff0(%edx)
  400ad7:	c6 82 f1 1f 00 00 8e 	movb   $0x8e,0x1ff1(%edx)
  400ade:	c1 e8 10             	shr    $0x10,%eax
  400ae1:	66 89 82 f2 1f 00 00 	mov    %ax,0x1ff2(%edx)
	SETGATE(idt[5], 0, GD_KT, th5, 0);
  400ae8:	c7 c0 62 11 40 00    	mov    $0x401162,%eax
  400aee:	66 89 82 f4 1f 00 00 	mov    %ax,0x1ff4(%edx)
  400af5:	66 c7 82 f6 1f 00 00 	movw   $0x8,0x1ff6(%edx)
  400afc:	08 00 
  400afe:	c6 82 f8 1f 00 00 00 	movb   $0x0,0x1ff8(%edx)
  400b05:	c6 82 f9 1f 00 00 8e 	movb   $0x8e,0x1ff9(%edx)
  400b0c:	c1 e8 10             	shr    $0x10,%eax
  400b0f:	66 89 82 fa 1f 00 00 	mov    %ax,0x1ffa(%edx)
	SETGATE(idt[6], 0, GD_KT, th6, 0);
  400b16:	c7 c0 66 11 40 00    	mov    $0x401166,%eax
  400b1c:	66 89 82 fc 1f 00 00 	mov    %ax,0x1ffc(%edx)
  400b23:	66 c7 82 fe 1f 00 00 	movw   $0x8,0x1ffe(%edx)
  400b2a:	08 00 
  400b2c:	c6 82 00 20 00 00 00 	movb   $0x0,0x2000(%edx)
  400b33:	c6 82 01 20 00 00 8e 	movb   $0x8e,0x2001(%edx)
  400b3a:	c1 e8 10             	shr    $0x10,%eax
  400b3d:	66 89 82 02 20 00 00 	mov    %ax,0x2002(%edx)
	SETGATE(idt[7], 0, GD_KT, th7, 0);
  400b44:	c7 c0 6a 11 40 00    	mov    $0x40116a,%eax
  400b4a:	66 89 82 04 20 00 00 	mov    %ax,0x2004(%edx)
  400b51:	66 c7 82 06 20 00 00 	movw   $0x8,0x2006(%edx)
  400b58:	08 00 
  400b5a:	c6 82 08 20 00 00 00 	movb   $0x0,0x2008(%edx)
  400b61:	c6 82 09 20 00 00 8e 	movb   $0x8e,0x2009(%edx)
  400b68:	c1 e8 10             	shr    $0x10,%eax
  400b6b:	66 89 82 0a 20 00 00 	mov    %ax,0x200a(%edx)
	SETGATE(idt[8], 0, GD_KT, th8, 0);
  400b72:	c7 c0 6e 11 40 00    	mov    $0x40116e,%eax
  400b78:	66 89 82 0c 20 00 00 	mov    %ax,0x200c(%edx)
  400b7f:	66 c7 82 0e 20 00 00 	movw   $0x8,0x200e(%edx)
  400b86:	08 00 
  400b88:	c6 82 10 20 00 00 00 	movb   $0x0,0x2010(%edx)
  400b8f:	c6 82 11 20 00 00 8e 	movb   $0x8e,0x2011(%edx)
  400b96:	c1 e8 10             	shr    $0x10,%eax
  400b99:	66 89 82 12 20 00 00 	mov    %ax,0x2012(%edx)
	SETGATE(idt[10], 0, GD_KT, th10, 0);
  400ba0:	c7 c0 72 11 40 00    	mov    $0x401172,%eax
  400ba6:	66 89 82 1c 20 00 00 	mov    %ax,0x201c(%edx)
  400bad:	66 c7 82 1e 20 00 00 	movw   $0x8,0x201e(%edx)
  400bb4:	08 00 
  400bb6:	c6 82 20 20 00 00 00 	movb   $0x0,0x2020(%edx)
  400bbd:	c6 82 21 20 00 00 8e 	movb   $0x8e,0x2021(%edx)
  400bc4:	c1 e8 10             	shr    $0x10,%eax
  400bc7:	66 89 82 22 20 00 00 	mov    %ax,0x2022(%edx)
	SETGATE(idt[11], 0, GD_KT, th11, 0);
  400bce:	c7 c0 76 11 40 00    	mov    $0x401176,%eax
  400bd4:	66 89 82 24 20 00 00 	mov    %ax,0x2024(%edx)
  400bdb:	66 c7 82 26 20 00 00 	movw   $0x8,0x2026(%edx)
  400be2:	08 00 
  400be4:	c6 82 28 20 00 00 00 	movb   $0x0,0x2028(%edx)
  400beb:	c6 82 29 20 00 00 8e 	movb   $0x8e,0x2029(%edx)
  400bf2:	c1 e8 10             	shr    $0x10,%eax
  400bf5:	66 89 82 2a 20 00 00 	mov    %ax,0x202a(%edx)
	SETGATE(idt[12], 0, GD_KT, th12, 0);
  400bfc:	c7 c0 7a 11 40 00    	mov    $0x40117a,%eax
  400c02:	66 89 82 2c 20 00 00 	mov    %ax,0x202c(%edx)
  400c09:	66 c7 82 2e 20 00 00 	movw   $0x8,0x202e(%edx)
  400c10:	08 00 
  400c12:	c6 82 30 20 00 00 00 	movb   $0x0,0x2030(%edx)
  400c19:	c6 82 31 20 00 00 8e 	movb   $0x8e,0x2031(%edx)
  400c20:	c1 e8 10             	shr    $0x10,%eax
  400c23:	66 89 82 32 20 00 00 	mov    %ax,0x2032(%edx)
	SETGATE(idt[13], 0, GD_KT, th13, 0);
  400c2a:	c7 c0 7e 11 40 00    	mov    $0x40117e,%eax
  400c30:	66 89 82 34 20 00 00 	mov    %ax,0x2034(%edx)
  400c37:	66 c7 82 36 20 00 00 	movw   $0x8,0x2036(%edx)
  400c3e:	08 00 
  400c40:	c6 82 38 20 00 00 00 	movb   $0x0,0x2038(%edx)
  400c47:	c6 82 39 20 00 00 8e 	movb   $0x8e,0x2039(%edx)
  400c4e:	c1 e8 10             	shr    $0x10,%eax
  400c51:	66 89 82 3a 20 00 00 	mov    %ax,0x203a(%edx)
	SETGATE(idt[14], 0, GD_KT, th14, 0);
  400c58:	c7 c0 82 11 40 00    	mov    $0x401182,%eax
  400c5e:	66 89 82 3c 20 00 00 	mov    %ax,0x203c(%edx)
  400c65:	66 c7 82 3e 20 00 00 	movw   $0x8,0x203e(%edx)
  400c6c:	08 00 
  400c6e:	c6 82 40 20 00 00 00 	movb   $0x0,0x2040(%edx)
  400c75:	c6 82 41 20 00 00 8e 	movb   $0x8e,0x2041(%edx)
  400c7c:	c1 e8 10             	shr    $0x10,%eax
  400c7f:	66 89 82 42 20 00 00 	mov    %ax,0x2042(%edx)
	SETGATE(idt[16], 0, GD_KT, th16, 0);
  400c86:	c7 c0 86 11 40 00    	mov    $0x401186,%eax
  400c8c:	66 89 82 4c 20 00 00 	mov    %ax,0x204c(%edx)
  400c93:	66 c7 82 4e 20 00 00 	movw   $0x8,0x204e(%edx)
  400c9a:	08 00 
  400c9c:	c6 82 50 20 00 00 00 	movb   $0x0,0x2050(%edx)
  400ca3:	c6 82 51 20 00 00 8e 	movb   $0x8e,0x2051(%edx)
  400caa:	c1 e8 10             	shr    $0x10,%eax
  400cad:	66 89 82 52 20 00 00 	mov    %ax,0x2052(%edx)
	SETGATE(idt[17], 0, GD_KT, th17, 0);
  400cb4:	c7 c0 8a 11 40 00    	mov    $0x40118a,%eax
  400cba:	66 89 82 54 20 00 00 	mov    %ax,0x2054(%edx)
  400cc1:	66 c7 82 56 20 00 00 	movw   $0x8,0x2056(%edx)
  400cc8:	08 00 
  400cca:	c6 82 58 20 00 00 00 	movb   $0x0,0x2058(%edx)
  400cd1:	c6 82 59 20 00 00 8e 	movb   $0x8e,0x2059(%edx)
  400cd8:	c1 e8 10             	shr    $0x10,%eax
  400cdb:	66 89 82 5a 20 00 00 	mov    %ax,0x205a(%edx)
	SETGATE(idt[18], 0, GD_KT, th18, 0);
  400ce2:	c7 c0 8e 11 40 00    	mov    $0x40118e,%eax
  400ce8:	66 89 82 5c 20 00 00 	mov    %ax,0x205c(%edx)
  400cef:	66 c7 82 5e 20 00 00 	movw   $0x8,0x205e(%edx)
  400cf6:	08 00 
  400cf8:	c6 82 60 20 00 00 00 	movb   $0x0,0x2060(%edx)
  400cff:	c6 82 61 20 00 00 8e 	movb   $0x8e,0x2061(%edx)
  400d06:	c1 e8 10             	shr    $0x10,%eax
  400d09:	66 89 82 62 20 00 00 	mov    %ax,0x2062(%edx)
	SETGATE(idt[19], 0, GD_KT, th19, 0);
  400d10:	c7 c0 92 11 40 00    	mov    $0x401192,%eax
  400d16:	66 89 82 64 20 00 00 	mov    %ax,0x2064(%edx)
  400d1d:	66 c7 82 66 20 00 00 	movw   $0x8,0x2066(%edx)
  400d24:	08 00 
  400d26:	c6 82 68 20 00 00 00 	movb   $0x0,0x2068(%edx)
  400d2d:	c6 82 69 20 00 00 8e 	movb   $0x8e,0x2069(%edx)
  400d34:	c1 e8 10             	shr    $0x10,%eax
  400d37:	66 89 82 6a 20 00 00 	mov    %ax,0x206a(%edx)
	SETGATE(idt[48], 0, GD_KT, th48, 3);
  400d3e:	c7 c0 96 11 40 00    	mov    $0x401196,%eax
  400d44:	66 89 82 4c 21 00 00 	mov    %ax,0x214c(%edx)
  400d4b:	66 c7 82 4e 21 00 00 	movw   $0x8,0x214e(%edx)
  400d52:	08 00 
  400d54:	c6 82 50 21 00 00 00 	movb   $0x0,0x2150(%edx)
  400d5b:	c6 82 51 21 00 00 ee 	movb   $0xee,0x2151(%edx)
  400d62:	c1 e8 10             	shr    $0x10,%eax
  400d65:	66 89 82 52 21 00 00 	mov    %ax,0x2152(%edx)
	trap_init_percpu();
  400d6c:	e8 9b fb ff ff       	call   40090c <trap_init_percpu>
}
  400d71:	5b                   	pop    %ebx
  400d72:	5e                   	pop    %esi
  400d73:	5d                   	pop    %ebp
  400d74:	c3                   	ret    

00400d75 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
  400d75:	55                   	push   %ebp
  400d76:	89 e5                	mov    %esp,%ebp
  400d78:	56                   	push   %esi
  400d79:	53                   	push   %ebx
  400d7a:	e8 e1 f4 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  400d7f:	81 c3 b5 45 01 00    	add    $0x145b5,%ebx
  400d85:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
  400d88:	83 ec 08             	sub    $0x8,%esp
  400d8b:	ff 36                	pushl  (%esi)
  400d8d:	8d 83 83 d0 fe ff    	lea    -0x12f7d(%ebx),%eax
  400d93:	50                   	push   %eax
  400d94:	e8 5f fb ff ff       	call   4008f8 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
  400d99:	83 c4 08             	add    $0x8,%esp
  400d9c:	ff 76 04             	pushl  0x4(%esi)
  400d9f:	8d 83 92 d0 fe ff    	lea    -0x12f6e(%ebx),%eax
  400da5:	50                   	push   %eax
  400da6:	e8 4d fb ff ff       	call   4008f8 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
  400dab:	83 c4 08             	add    $0x8,%esp
  400dae:	ff 76 08             	pushl  0x8(%esi)
  400db1:	8d 83 a1 d0 fe ff    	lea    -0x12f5f(%ebx),%eax
  400db7:	50                   	push   %eax
  400db8:	e8 3b fb ff ff       	call   4008f8 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
  400dbd:	83 c4 08             	add    $0x8,%esp
  400dc0:	ff 76 0c             	pushl  0xc(%esi)
  400dc3:	8d 83 b0 d0 fe ff    	lea    -0x12f50(%ebx),%eax
  400dc9:	50                   	push   %eax
  400dca:	e8 29 fb ff ff       	call   4008f8 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
  400dcf:	83 c4 08             	add    $0x8,%esp
  400dd2:	ff 76 10             	pushl  0x10(%esi)
  400dd5:	8d 83 bf d0 fe ff    	lea    -0x12f41(%ebx),%eax
  400ddb:	50                   	push   %eax
  400ddc:	e8 17 fb ff ff       	call   4008f8 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
  400de1:	83 c4 08             	add    $0x8,%esp
  400de4:	ff 76 14             	pushl  0x14(%esi)
  400de7:	8d 83 ce d0 fe ff    	lea    -0x12f32(%ebx),%eax
  400ded:	50                   	push   %eax
  400dee:	e8 05 fb ff ff       	call   4008f8 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
  400df3:	83 c4 08             	add    $0x8,%esp
  400df6:	ff 76 18             	pushl  0x18(%esi)
  400df9:	8d 83 dd d0 fe ff    	lea    -0x12f23(%ebx),%eax
  400dff:	50                   	push   %eax
  400e00:	e8 f3 fa ff ff       	call   4008f8 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
  400e05:	83 c4 08             	add    $0x8,%esp
  400e08:	ff 76 1c             	pushl  0x1c(%esi)
  400e0b:	8d 83 ec d0 fe ff    	lea    -0x12f14(%ebx),%eax
  400e11:	50                   	push   %eax
  400e12:	e8 e1 fa ff ff       	call   4008f8 <cprintf>
}
  400e17:	83 c4 10             	add    $0x10,%esp
  400e1a:	8d 65 f8             	lea    -0x8(%ebp),%esp
  400e1d:	5b                   	pop    %ebx
  400e1e:	5e                   	pop    %esi
  400e1f:	5d                   	pop    %ebp
  400e20:	c3                   	ret    

00400e21 <print_trapframe>:
{
  400e21:	55                   	push   %ebp
  400e22:	89 e5                	mov    %esp,%ebp
  400e24:	57                   	push   %edi
  400e25:	56                   	push   %esi
  400e26:	53                   	push   %ebx
  400e27:	83 ec 14             	sub    $0x14,%esp
  400e2a:	e8 31 f4 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  400e2f:	81 c3 05 45 01 00    	add    $0x14505,%ebx
  400e35:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
  400e38:	56                   	push   %esi
  400e39:	8d 83 74 d2 fe ff    	lea    -0x12d8c(%ebx),%eax
  400e3f:	50                   	push   %eax
  400e40:	e8 b3 fa ff ff       	call   4008f8 <cprintf>
	print_regs(&tf->tf_regs);
  400e45:	89 34 24             	mov    %esi,(%esp)
  400e48:	e8 28 ff ff ff       	call   400d75 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
  400e4d:	83 c4 08             	add    $0x8,%esp
  400e50:	0f b7 46 20          	movzwl 0x20(%esi),%eax
  400e54:	50                   	push   %eax
  400e55:	8d 83 3d d1 fe ff    	lea    -0x12ec3(%ebx),%eax
  400e5b:	50                   	push   %eax
  400e5c:	e8 97 fa ff ff       	call   4008f8 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
  400e61:	83 c4 08             	add    $0x8,%esp
  400e64:	0f b7 46 24          	movzwl 0x24(%esi),%eax
  400e68:	50                   	push   %eax
  400e69:	8d 83 50 d1 fe ff    	lea    -0x12eb0(%ebx),%eax
  400e6f:	50                   	push   %eax
  400e70:	e8 83 fa ff ff       	call   4008f8 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
  400e75:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
  400e78:	83 c4 10             	add    $0x10,%esp
  400e7b:	83 fa 13             	cmp    $0x13,%edx
  400e7e:	0f 86 e9 00 00 00    	jbe    400f6d <print_trapframe+0x14c>
	return "(unknown trap)";
  400e84:	83 fa 30             	cmp    $0x30,%edx
  400e87:	8d 83 fb d0 fe ff    	lea    -0x12f05(%ebx),%eax
  400e8d:	8d 8b 07 d1 fe ff    	lea    -0x12ef9(%ebx),%ecx
  400e93:	0f 45 c1             	cmovne %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
  400e96:	83 ec 04             	sub    $0x4,%esp
  400e99:	50                   	push   %eax
  400e9a:	52                   	push   %edx
  400e9b:	8d 83 63 d1 fe ff    	lea    -0x12e9d(%ebx),%eax
  400ea1:	50                   	push   %eax
  400ea2:	e8 51 fa ff ff       	call   4008f8 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
  400ea7:	83 c4 10             	add    $0x10,%esp
  400eaa:	39 b3 cc 27 00 00    	cmp    %esi,0x27cc(%ebx)
  400eb0:	0f 84 c3 00 00 00    	je     400f79 <print_trapframe+0x158>
	cprintf("  err  0x%08x", tf->tf_err);
  400eb6:	83 ec 08             	sub    $0x8,%esp
  400eb9:	ff 76 2c             	pushl  0x2c(%esi)
  400ebc:	8d 83 84 d1 fe ff    	lea    -0x12e7c(%ebx),%eax
  400ec2:	50                   	push   %eax
  400ec3:	e8 30 fa ff ff       	call   4008f8 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
  400ec8:	83 c4 10             	add    $0x10,%esp
  400ecb:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
  400ecf:	0f 85 c9 00 00 00    	jne    400f9e <print_trapframe+0x17d>
			tf->tf_err & 1 ? "protection" : "not-present");
  400ed5:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
  400ed8:	89 c2                	mov    %eax,%edx
  400eda:	83 e2 01             	and    $0x1,%edx
  400edd:	8d 8b 16 d1 fe ff    	lea    -0x12eea(%ebx),%ecx
  400ee3:	8d 93 21 d1 fe ff    	lea    -0x12edf(%ebx),%edx
  400ee9:	0f 44 ca             	cmove  %edx,%ecx
  400eec:	89 c2                	mov    %eax,%edx
  400eee:	83 e2 02             	and    $0x2,%edx
  400ef1:	8d 93 2d d1 fe ff    	lea    -0x12ed3(%ebx),%edx
  400ef7:	8d bb 33 d1 fe ff    	lea    -0x12ecd(%ebx),%edi
  400efd:	0f 44 d7             	cmove  %edi,%edx
  400f00:	83 e0 04             	and    $0x4,%eax
  400f03:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
  400f09:	8d bb 98 d2 fe ff    	lea    -0x12d68(%ebx),%edi
  400f0f:	0f 44 c7             	cmove  %edi,%eax
  400f12:	51                   	push   %ecx
  400f13:	52                   	push   %edx
  400f14:	50                   	push   %eax
  400f15:	8d 83 92 d1 fe ff    	lea    -0x12e6e(%ebx),%eax
  400f1b:	50                   	push   %eax
  400f1c:	e8 d7 f9 ff ff       	call   4008f8 <cprintf>
  400f21:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
  400f24:	83 ec 08             	sub    $0x8,%esp
  400f27:	ff 76 30             	pushl  0x30(%esi)
  400f2a:	8d 83 a1 d1 fe ff    	lea    -0x12e5f(%ebx),%eax
  400f30:	50                   	push   %eax
  400f31:	e8 c2 f9 ff ff       	call   4008f8 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
  400f36:	83 c4 08             	add    $0x8,%esp
  400f39:	0f b7 46 34          	movzwl 0x34(%esi),%eax
  400f3d:	50                   	push   %eax
  400f3e:	8d 83 b0 d1 fe ff    	lea    -0x12e50(%ebx),%eax
  400f44:	50                   	push   %eax
  400f45:	e8 ae f9 ff ff       	call   4008f8 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
  400f4a:	83 c4 08             	add    $0x8,%esp
  400f4d:	ff 76 38             	pushl  0x38(%esi)
  400f50:	8d 83 c3 d1 fe ff    	lea    -0x12e3d(%ebx),%eax
  400f56:	50                   	push   %eax
  400f57:	e8 9c f9 ff ff       	call   4008f8 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
  400f5c:	83 c4 10             	add    $0x10,%esp
  400f5f:	f6 46 34 03          	testb  $0x3,0x34(%esi)
  400f63:	75 50                	jne    400fb5 <print_trapframe+0x194>
}
  400f65:	8d 65 f4             	lea    -0xc(%ebp),%esp
  400f68:	5b                   	pop    %ebx
  400f69:	5e                   	pop    %esi
  400f6a:	5f                   	pop    %edi
  400f6b:	5d                   	pop    %ebp
  400f6c:	c3                   	ret    
		return excnames[trapno];
  400f6d:	8b 84 93 0c 1d 00 00 	mov    0x1d0c(%ebx,%edx,4),%eax
  400f74:	e9 1d ff ff ff       	jmp    400e96 <print_trapframe+0x75>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
  400f79:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
  400f7d:	0f 85 33 ff ff ff    	jne    400eb6 <print_trapframe+0x95>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
  400f83:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
  400f86:	83 ec 08             	sub    $0x8,%esp
  400f89:	50                   	push   %eax
  400f8a:	8d 83 75 d1 fe ff    	lea    -0x12e8b(%ebx),%eax
  400f90:	50                   	push   %eax
  400f91:	e8 62 f9 ff ff       	call   4008f8 <cprintf>
  400f96:	83 c4 10             	add    $0x10,%esp
  400f99:	e9 18 ff ff ff       	jmp    400eb6 <print_trapframe+0x95>
		cprintf("\n");
  400f9e:	83 ec 0c             	sub    $0xc,%esp
  400fa1:	8d 83 cf cd fe ff    	lea    -0x13231(%ebx),%eax
  400fa7:	50                   	push   %eax
  400fa8:	e8 4b f9 ff ff       	call   4008f8 <cprintf>
  400fad:	83 c4 10             	add    $0x10,%esp
  400fb0:	e9 6f ff ff ff       	jmp    400f24 <print_trapframe+0x103>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
  400fb5:	83 ec 08             	sub    $0x8,%esp
  400fb8:	ff 76 3c             	pushl  0x3c(%esi)
  400fbb:	8d 83 d2 d1 fe ff    	lea    -0x12e2e(%ebx),%eax
  400fc1:	50                   	push   %eax
  400fc2:	e8 31 f9 ff ff       	call   4008f8 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
  400fc7:	83 c4 08             	add    $0x8,%esp
  400fca:	0f b7 46 40          	movzwl 0x40(%esi),%eax
  400fce:	50                   	push   %eax
  400fcf:	8d 83 e1 d1 fe ff    	lea    -0x12e1f(%ebx),%eax
  400fd5:	50                   	push   %eax
  400fd6:	e8 1d f9 ff ff       	call   4008f8 <cprintf>
  400fdb:	83 c4 10             	add    $0x10,%esp
}
  400fde:	eb 85                	jmp    400f65 <print_trapframe+0x144>

00400fe0 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
  400fe0:	55                   	push   %ebp
  400fe1:	89 e5                	mov    %esp,%ebp
  400fe3:	56                   	push   %esi
  400fe4:	53                   	push   %ebx
  400fe5:	e8 76 f2 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  400fea:	81 c3 4a 43 01 00    	add    $0x1434a,%ebx
  400ff0:	8b 75 08             	mov    0x8(%ebp),%esi
  400ff3:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("user fault va %08x ip %08x\n",
  400ff6:	83 ec 04             	sub    $0x4,%esp
  400ff9:	ff 76 30             	pushl  0x30(%esi)
  400ffc:	50                   	push   %eax
  400ffd:	8d 83 f4 d1 fe ff    	lea    -0x12e0c(%ebx),%eax
  401003:	50                   	push   %eax
  401004:	e8 ef f8 ff ff       	call   4008f8 <cprintf>
		fault_va, tf->tf_eip);
	print_trapframe(tf);
  401009:	89 34 24             	mov    %esi,(%esp)
  40100c:	e8 10 fe ff ff       	call   400e21 <print_trapframe>
	cprintf(PAGE_FAULT);
  401011:	8d 83 10 d2 fe ff    	lea    -0x12df0(%ebx),%eax
  401017:	89 04 24             	mov    %eax,(%esp)
  40101a:	e8 d9 f8 ff ff       	call   4008f8 <cprintf>
	panic("unhanlded page fault");
  40101f:	83 c4 0c             	add    $0xc,%esp
  401022:	8d 83 1c d2 fe ff    	lea    -0x12de4(%ebx),%eax
  401028:	50                   	push   %eax
  401029:	68 1e 01 00 00       	push   $0x11e
  40102e:	8d 83 31 d2 fe ff    	lea    -0x12dcf(%ebx),%eax
  401034:	50                   	push   %eax
  401035:	e8 06 f0 ff ff       	call   400040 <_panic>

0040103a <trap>:
{
  40103a:	55                   	push   %ebp
  40103b:	89 e5                	mov    %esp,%ebp
  40103d:	57                   	push   %edi
  40103e:	56                   	push   %esi
  40103f:	53                   	push   %ebx
  401040:	83 ec 0c             	sub    $0xc,%esp
  401043:	e8 18 f2 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  401048:	81 c3 ec 42 01 00    	add    $0x142ec,%ebx
  40104e:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
  401051:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
  401052:	9c                   	pushf  
  401053:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
  401054:	f6 c4 02             	test   $0x2,%ah
  401057:	74 1f                	je     401078 <trap+0x3e>
  401059:	8d 83 3d d2 fe ff    	lea    -0x12dc3(%ebx),%eax
  40105f:	50                   	push   %eax
  401060:	8d 83 56 d2 fe ff    	lea    -0x12daa(%ebx),%eax
  401066:	50                   	push   %eax
  401067:	68 f1 00 00 00       	push   $0xf1
  40106c:	8d 83 31 d2 fe ff    	lea    -0x12dcf(%ebx),%eax
  401072:	50                   	push   %eax
  401073:	e8 c8 ef ff ff       	call   400040 <_panic>
	cprintf("Incoming TRAP frame at %p\n", tf);
  401078:	83 ec 08             	sub    $0x8,%esp
  40107b:	56                   	push   %esi
  40107c:	8d 83 6b d2 fe ff    	lea    -0x12d95(%ebx),%eax
  401082:	50                   	push   %eax
  401083:	e8 70 f8 ff ff       	call   4008f8 <cprintf>
	if ((tf->tf_cs & 3) == 3) {
  401088:	0f b7 46 34          	movzwl 0x34(%esi),%eax
  40108c:	83 e0 03             	and    $0x3,%eax
  40108f:	83 c4 10             	add    $0x10,%esp
  401092:	66 83 f8 03          	cmp    $0x3,%ax
  401096:	74 41                	je     4010d9 <trap+0x9f>
	last_tf = tf;
  401098:	89 b3 cc 27 00 00    	mov    %esi,0x27cc(%ebx)
	switch(tf->tf_trapno) {
  40109e:	8b 46 28             	mov    0x28(%esi),%eax
  4010a1:	83 f8 0e             	cmp    $0xe,%eax
  4010a4:	74 46                	je     4010ec <trap+0xb2>
  4010a6:	83 f8 30             	cmp    $0x30,%eax
  4010a9:	74 4a                	je     4010f5 <trap+0xbb>
	print_trapframe(tf);
  4010ab:	83 ec 0c             	sub    $0xc,%esp
  4010ae:	56                   	push   %esi
  4010af:	e8 6d fd ff ff       	call   400e21 <print_trapframe>
	if (tf->tf_cs == GD_KT)
  4010b4:	83 c4 10             	add    $0x10,%esp
  4010b7:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
  4010bc:	74 64                	je     401122 <trap+0xe8>
		panic("unhandled trap in user code");
  4010be:	83 ec 04             	sub    $0x4,%esp
  4010c1:	8d 83 9f d2 fe ff    	lea    -0x12d61(%ebx),%eax
  4010c7:	50                   	push   %eax
  4010c8:	68 e3 00 00 00       	push   $0xe3
  4010cd:	8d 83 31 d2 fe ff    	lea    -0x12dcf(%ebx),%eax
  4010d3:	50                   	push   %eax
  4010d4:	e8 67 ef ff ff       	call   400040 <_panic>
		env_tf = *tf;
  4010d9:	c7 c0 e0 7d 43 00    	mov    $0x437de0,%eax
  4010df:	b9 11 00 00 00       	mov    $0x11,%ecx
  4010e4:	89 c7                	mov    %eax,%edi
  4010e6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &env_tf;
  4010e8:	89 c6                	mov    %eax,%esi
  4010ea:	eb ac                	jmp    401098 <trap+0x5e>
		page_fault_handler(tf);
  4010ec:	83 ec 0c             	sub    $0xc,%esp
  4010ef:	56                   	push   %esi
  4010f0:	e8 eb fe ff ff       	call   400fe0 <page_fault_handler>
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
  4010f5:	83 ec 08             	sub    $0x8,%esp
  4010f8:	ff 76 04             	pushl  0x4(%esi)
  4010fb:	ff 36                	pushl  (%esi)
  4010fd:	ff 76 10             	pushl  0x10(%esi)
  401100:	ff 76 18             	pushl  0x18(%esi)
  401103:	ff 76 14             	pushl  0x14(%esi)
  401106:	ff 76 1c             	pushl  0x1c(%esi)
  401109:	e8 9d 00 00 00       	call   4011ab <syscall>
  40110e:	89 46 1c             	mov    %eax,0x1c(%esi)
		if(tf->tf_regs.reg_eax != -E_INVAL) {
  401111:	83 c4 20             	add    $0x20,%esp
  401114:	83 f8 fd             	cmp    $0xfffffffd,%eax
  401117:	74 92                	je     4010ab <trap+0x71>
	run_trapframe(tf);
  401119:	83 ec 0c             	sub    $0xc,%esp
  40111c:	56                   	push   %esi
  40111d:	e8 4c f7 ff ff       	call   40086e <run_trapframe>
		panic("unhandled trap in kernel");
  401122:	83 ec 04             	sub    $0x4,%esp
  401125:	8d 83 86 d2 fe ff    	lea    -0x12d7a(%ebx),%eax
  40112b:	50                   	push   %eax
  40112c:	68 e1 00 00 00       	push   $0xe1
  401131:	8d 83 31 d2 fe ff    	lea    -0x12dcf(%ebx),%eax
  401137:	50                   	push   %eax
  401138:	e8 03 ef ff ff       	call   400040 <_panic>

0040113d <__x86.get_pc_thunk.dx>:
  40113d:	8b 14 24             	mov    (%esp),%edx
  401140:	c3                   	ret    
  401141:	90                   	nop

00401142 <unktraphandler>:

.globl unktraphandler;
.type unktraphandler, @function;
	.align 2;		
unktraphandler:			
	pushl $0;
  401142:	6a 00                	push   $0x0
	pushl $9;
  401144:	6a 09                	push   $0x9
	jmp _alltraps;
  401146:	eb 54                	jmp    40119c <_alltraps>

00401148 <th0>:
	TRAPHANDLER(div0handler, T_DEBUG)	
	TRAPHANDLER(nmihandler, T_NMI)
	TRAPHANDLER(nmihandler, T_NMI)
	TRAPHANDLER(syscallhandler, T_SYSCALL) */

	TRAPHANDLER_NOEC(th0, 0)
  401148:	6a 00                	push   $0x0
  40114a:	6a 00                	push   $0x0
  40114c:	eb 4e                	jmp    40119c <_alltraps>

0040114e <th1>:
	TRAPHANDLER_NOEC(th1, 1)
  40114e:	6a 00                	push   $0x0
  401150:	6a 01                	push   $0x1
  401152:	eb 48                	jmp    40119c <_alltraps>

00401154 <th2>:
	TRAPHANDLER(th2, 2)
  401154:	6a 02                	push   $0x2
  401156:	eb 44                	jmp    40119c <_alltraps>

00401158 <th3>:
	TRAPHANDLER_NOEC(th3, 3)
  401158:	6a 00                	push   $0x0
  40115a:	6a 03                	push   $0x3
  40115c:	eb 3e                	jmp    40119c <_alltraps>

0040115e <th4>:
	TRAPHANDLER(th4, 4)
  40115e:	6a 04                	push   $0x4
  401160:	eb 3a                	jmp    40119c <_alltraps>

00401162 <th5>:
	TRAPHANDLER(th5, 5)
  401162:	6a 05                	push   $0x5
  401164:	eb 36                	jmp    40119c <_alltraps>

00401166 <th6>:
	TRAPHANDLER(th6, 6)
  401166:	6a 06                	push   $0x6
  401168:	eb 32                	jmp    40119c <_alltraps>

0040116a <th7>:
	TRAPHANDLER(th7, 7)
  40116a:	6a 07                	push   $0x7
  40116c:	eb 2e                	jmp    40119c <_alltraps>

0040116e <th8>:
	TRAPHANDLER(th8, 8)
  40116e:	6a 08                	push   $0x8
  401170:	eb 2a                	jmp    40119c <_alltraps>

00401172 <th10>:
	//TRAPHANDLER(th9, 9)
	TRAPHANDLER(th10, 10)
  401172:	6a 0a                	push   $0xa
  401174:	eb 26                	jmp    40119c <_alltraps>

00401176 <th11>:
	TRAPHANDLER(th11, 11)
  401176:	6a 0b                	push   $0xb
  401178:	eb 22                	jmp    40119c <_alltraps>

0040117a <th12>:
	TRAPHANDLER(th12, 12)
  40117a:	6a 0c                	push   $0xc
  40117c:	eb 1e                	jmp    40119c <_alltraps>

0040117e <th13>:
	TRAPHANDLER(th13, 13)
  40117e:	6a 0d                	push   $0xd
  401180:	eb 1a                	jmp    40119c <_alltraps>

00401182 <th14>:
	TRAPHANDLER(th14, 14)
  401182:	6a 0e                	push   $0xe
  401184:	eb 16                	jmp    40119c <_alltraps>

00401186 <th16>:
	//TRAPHANDLER(th15, 15)
	TRAPHANDLER(th16, 16)
  401186:	6a 10                	push   $0x10
  401188:	eb 12                	jmp    40119c <_alltraps>

0040118a <th17>:
	TRAPHANDLER(th17, 17)
  40118a:	6a 11                	push   $0x11
  40118c:	eb 0e                	jmp    40119c <_alltraps>

0040118e <th18>:
	TRAPHANDLER(th18, 18)
  40118e:	6a 12                	push   $0x12
  401190:	eb 0a                	jmp    40119c <_alltraps>

00401192 <th19>:
	TRAPHANDLER(th19, 19)
  401192:	6a 13                	push   $0x13
  401194:	eb 06                	jmp    40119c <_alltraps>

00401196 <th48>:
	TRAPHANDLER_NOEC(th48, 48)
  401196:	6a 00                	push   $0x0
  401198:	6a 30                	push   $0x30
  40119a:	eb 00                	jmp    40119c <_alltraps>

0040119c <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */


_alltraps:
	pushl %ds;
  40119c:	1e                   	push   %ds
	pushl %es;
  40119d:	06                   	push   %es
	pushal;
  40119e:	60                   	pusha  
	pushl $GD_KD;
  40119f:	6a 10                	push   $0x10
	popl %ds;
  4011a1:	1f                   	pop    %ds
	pushl $GD_KD;
  4011a2:	6a 10                	push   $0x10
	popl %es;
  4011a4:	07                   	pop    %es
	pushl %esp;
  4011a5:	54                   	push   %esp
	call trap;
  4011a6:	e8 8f fe ff ff       	call   40103a <trap>

004011ab <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  4011ab:	55                   	push   %ebp
  4011ac:	89 e5                	mov    %esp,%ebp
  4011ae:	53                   	push   %ebx
  4011af:	83 ec 04             	sub    $0x4,%esp
  4011b2:	e8 a9 f0 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  4011b7:	81 c3 7d 41 01 00    	add    $0x1417d,%ebx
  4011bd:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	
	switch (syscallno) {
  4011c0:	83 f8 03             	cmp    $0x3,%eax
  4011c3:	74 67                	je     40122c <syscall+0x81>
  4011c5:	83 f8 04             	cmp    $0x4,%eax
  4011c8:	74 70                	je     40123a <syscall+0x8f>
  4011ca:	85 c0                	test   %eax,%eax
  4011cc:	74 1a                	je     4011e8 <syscall+0x3d>
	case SYS_test:
		sys_test();
		return 0;

	}
	cprintf("Kernel got unexpected system call %d\n", syscallno);
  4011ce:	83 ec 08             	sub    $0x8,%esp
  4011d1:	50                   	push   %eax
  4011d2:	8d 83 24 d4 fe ff    	lea    -0x12bdc(%ebx),%eax
  4011d8:	50                   	push   %eax
  4011d9:	e8 1a f7 ff ff       	call   4008f8 <cprintf>
	return -E_INVAL;
  4011de:	83 c4 10             	add    $0x10,%esp
  4011e1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  4011e6:	eb 69                	jmp    401251 <syscall+0xa6>
	if ((int)s>=0x800000 && ((int)s+len)<=0xB00000){
  4011e8:	81 7d 0c ff ff 7f 00 	cmpl   $0x7fffff,0xc(%ebp)
  4011ef:	7e 0d                	jle    4011fe <syscall+0x53>
  4011f1:	8b 45 0c             	mov    0xc(%ebp),%eax
  4011f4:	03 45 10             	add    0x10(%ebp),%eax
  4011f7:	3d 00 00 b0 00       	cmp    $0xb00000,%eax
  4011fc:	76 19                	jbe    401217 <syscall+0x6c>
		cprintf(INVALID_POINTER);
  4011fe:	83 ec 0c             	sub    $0xc,%esp
  401201:	8d 83 fe d3 fe ff    	lea    -0x12c02(%ebx),%eax
  401207:	50                   	push   %eax
  401208:	e8 eb f6 ff ff       	call   4008f8 <cprintf>
  40120d:	83 c4 10             	add    $0x10,%esp
		return 0;	
  401210:	b8 00 00 00 00       	mov    $0x0,%eax
  401215:	eb 3a                	jmp    401251 <syscall+0xa6>
		cprintf(s);
  401217:	83 ec 0c             	sub    $0xc,%esp
  40121a:	ff 75 0c             	pushl  0xc(%ebp)
  40121d:	e8 d6 f6 ff ff       	call   4008f8 <cprintf>
  401222:	83 c4 10             	add    $0x10,%esp
		return 0;	
  401225:	b8 00 00 00 00       	mov    $0x0,%eax
  40122a:	eb 25                	jmp    401251 <syscall+0xa6>
	asm volatile("outw %0,%w1" : : "a" (data), "d" (port));
  40122c:	b8 00 20 00 00       	mov    $0x2000,%eax
  401231:	ba 04 06 00 00       	mov    $0x604,%edx
  401236:	66 ef                	out    %ax,(%dx)
  401238:	eb fe                	jmp    401238 <syscall+0x8d>
	cprintf(SYS_TEST);
  40123a:	83 ec 0c             	sub    $0xc,%esp
  40123d:	8d 83 0f d4 fe ff    	lea    -0x12bf1(%ebx),%eax
  401243:	50                   	push   %eax
  401244:	e8 af f6 ff ff       	call   4008f8 <cprintf>
  401249:	83 c4 10             	add    $0x10,%esp
		return 0;
  40124c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  401251:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  401254:	c9                   	leave  
  401255:	c3                   	ret    

00401256 <ide_wait_ready>:

static int diskno = 0; // we only use one disk

static int
ide_wait_ready(bool check_error)
{
  401256:	55                   	push   %ebp
  401257:	89 e5                	mov    %esp,%ebp
  401259:	53                   	push   %ebx
  40125a:	89 c1                	mov    %eax,%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  40125c:	ba f7 01 00 00       	mov    $0x1f7,%edx
  401261:	ec                   	in     (%dx),%al
  401262:	89 c3                	mov    %eax,%ebx
	int r;

	while (((r = inb(0x1F7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
  401264:	83 e0 c0             	and    $0xffffffc0,%eax
  401267:	3c 40                	cmp    $0x40,%al
  401269:	75 f6                	jne    401261 <ide_wait_ready+0xb>
		/* do nothing */;

	if (check_error && (r & (IDE_DF|IDE_ERR)) != 0)
		return -1;
	return 0;
  40126b:	b8 00 00 00 00       	mov    $0x0,%eax
	if (check_error && (r & (IDE_DF|IDE_ERR)) != 0)
  401270:	84 c9                	test   %cl,%cl
  401272:	74 0b                	je     40127f <ide_wait_ready+0x29>
  401274:	f6 c3 21             	test   $0x21,%bl
  401277:	0f 95 c0             	setne  %al
  40127a:	0f b6 c0             	movzbl %al,%eax
  40127d:	f7 d8                	neg    %eax
}
  40127f:	5b                   	pop    %ebx
  401280:	5d                   	pop    %ebp
  401281:	c3                   	ret    

00401282 <ide_read>:

int
ide_read(uint32_t secno, void *dst, size_t nsecs)
{
  401282:	55                   	push   %ebp
  401283:	89 e5                	mov    %esp,%ebp
  401285:	57                   	push   %edi
  401286:	56                   	push   %esi
  401287:	53                   	push   %ebx
  401288:	83 ec 0c             	sub    $0xc,%esp
  40128b:	e8 72 f5 ff ff       	call   400802 <__x86.get_pc_thunk.ax>
  401290:	05 a4 40 01 00       	add    $0x140a4,%eax
  401295:	8b 7d 08             	mov    0x8(%ebp),%edi
  401298:	8b 75 0c             	mov    0xc(%ebp),%esi
  40129b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int r;

	assert(nsecs <= 256);
  40129e:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
  4012a4:	77 7a                	ja     401320 <ide_read+0x9e>

	ide_wait_ready(0);
  4012a6:	b8 00 00 00 00       	mov    $0x0,%eax
  4012ab:	e8 a6 ff ff ff       	call   401256 <ide_wait_ready>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
  4012b0:	ba f2 01 00 00       	mov    $0x1f2,%edx
  4012b5:	89 d8                	mov    %ebx,%eax
  4012b7:	ee                   	out    %al,(%dx)
  4012b8:	ba f3 01 00 00       	mov    $0x1f3,%edx
  4012bd:	89 f8                	mov    %edi,%eax
  4012bf:	ee                   	out    %al,(%dx)

	outb(0x1F2, nsecs);
	outb(0x1F3, secno & 0xFF);
	outb(0x1F4, (secno >> 8) & 0xFF);
  4012c0:	89 f8                	mov    %edi,%eax
  4012c2:	c1 e8 08             	shr    $0x8,%eax
  4012c5:	ba f4 01 00 00       	mov    $0x1f4,%edx
  4012ca:	ee                   	out    %al,(%dx)
	outb(0x1F5, (secno >> 16) & 0xFF);
  4012cb:	89 f8                	mov    %edi,%eax
  4012cd:	c1 e8 10             	shr    $0x10,%eax
  4012d0:	ba f5 01 00 00       	mov    $0x1f5,%edx
  4012d5:	ee                   	out    %al,(%dx)
	outb(0x1F6, 0xE0 | ((diskno&1)<<4) | ((secno>>24)&0x0F));
  4012d6:	89 f8                	mov    %edi,%eax
  4012d8:	c1 e8 18             	shr    $0x18,%eax
  4012db:	83 e0 0f             	and    $0xf,%eax
  4012de:	83 c8 e0             	or     $0xffffffe0,%eax
  4012e1:	ba f6 01 00 00       	mov    $0x1f6,%edx
  4012e6:	ee                   	out    %al,(%dx)
  4012e7:	b8 20 00 00 00       	mov    $0x20,%eax
  4012ec:	ba f7 01 00 00       	mov    $0x1f7,%edx
  4012f1:	ee                   	out    %al,(%dx)
  4012f2:	c1 e3 09             	shl    $0x9,%ebx
  4012f5:	01 f3                	add    %esi,%ebx
	outb(0x1F7, 0x20);	// CMD 0x20 means read sector

	for (; nsecs > 0; nsecs--, dst += SECTSIZE) {
  4012f7:	39 f3                	cmp    %esi,%ebx
  4012f9:	74 43                	je     40133e <ide_read+0xbc>
		if ((r = ide_wait_ready(1)) < 0)
  4012fb:	b8 01 00 00 00       	mov    $0x1,%eax
  401300:	e8 51 ff ff ff       	call   401256 <ide_wait_ready>
  401305:	85 c0                	test   %eax,%eax
  401307:	78 3a                	js     401343 <ide_read+0xc1>
	asm volatile("cld\n\trepne\n\tinsl"
  401309:	89 f7                	mov    %esi,%edi
  40130b:	b9 80 00 00 00       	mov    $0x80,%ecx
  401310:	ba f0 01 00 00       	mov    $0x1f0,%edx
  401315:	fc                   	cld    
  401316:	f2 6d                	repnz insl (%dx),%es:(%edi)
	for (; nsecs > 0; nsecs--, dst += SECTSIZE) {
  401318:	81 c6 00 02 00 00    	add    $0x200,%esi
  40131e:	eb d7                	jmp    4012f7 <ide_read+0x75>
	assert(nsecs <= 256);
  401320:	8d 90 4c d4 fe ff    	lea    -0x12bb4(%eax),%edx
  401326:	52                   	push   %edx
  401327:	8d 90 56 d2 fe ff    	lea    -0x12daa(%eax),%edx
  40132d:	52                   	push   %edx
  40132e:	6a 23                	push   $0x23
  401330:	8d 90 59 d4 fe ff    	lea    -0x12ba7(%eax),%edx
  401336:	52                   	push   %edx
  401337:	89 c3                	mov    %eax,%ebx
  401339:	e8 02 ed ff ff       	call   400040 <_panic>
			return r;
		insl(0x1F0, dst, SECTSIZE/4);
	}

	return 0;
  40133e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  401343:	8d 65 f4             	lea    -0xc(%ebp),%esp
  401346:	5b                   	pop    %ebx
  401347:	5e                   	pop    %esi
  401348:	5f                   	pop    %edi
  401349:	5d                   	pop    %ebp
  40134a:	c3                   	ret    

0040134b <ide_write>:

int
ide_write(uint32_t secno, const void *src, size_t nsecs)
{
  40134b:	55                   	push   %ebp
  40134c:	89 e5                	mov    %esp,%ebp
  40134e:	57                   	push   %edi
  40134f:	56                   	push   %esi
  401350:	53                   	push   %ebx
  401351:	83 ec 0c             	sub    $0xc,%esp
  401354:	e8 a9 f4 ff ff       	call   400802 <__x86.get_pc_thunk.ax>
  401359:	05 db 3f 01 00       	add    $0x13fdb,%eax
  40135e:	8b 75 08             	mov    0x8(%ebp),%esi
  401361:	8b 7d 0c             	mov    0xc(%ebp),%edi
  401364:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int r;

	assert(nsecs <= 256);
  401367:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
  40136d:	77 7a                	ja     4013e9 <ide_write+0x9e>

	ide_wait_ready(0);
  40136f:	b8 00 00 00 00       	mov    $0x0,%eax
  401374:	e8 dd fe ff ff       	call   401256 <ide_wait_ready>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
  401379:	ba f2 01 00 00       	mov    $0x1f2,%edx
  40137e:	89 d8                	mov    %ebx,%eax
  401380:	ee                   	out    %al,(%dx)
  401381:	ba f3 01 00 00       	mov    $0x1f3,%edx
  401386:	89 f0                	mov    %esi,%eax
  401388:	ee                   	out    %al,(%dx)

	outb(0x1F2, nsecs);
	outb(0x1F3, secno & 0xFF);
	outb(0x1F4, (secno >> 8) & 0xFF);
  401389:	89 f0                	mov    %esi,%eax
  40138b:	c1 e8 08             	shr    $0x8,%eax
  40138e:	ba f4 01 00 00       	mov    $0x1f4,%edx
  401393:	ee                   	out    %al,(%dx)
	outb(0x1F5, (secno >> 16) & 0xFF);
  401394:	89 f0                	mov    %esi,%eax
  401396:	c1 e8 10             	shr    $0x10,%eax
  401399:	ba f5 01 00 00       	mov    $0x1f5,%edx
  40139e:	ee                   	out    %al,(%dx)
	outb(0x1F6, 0xE0 | ((diskno&1)<<4) | ((secno>>24)&0x0F));
  40139f:	89 f0                	mov    %esi,%eax
  4013a1:	c1 e8 18             	shr    $0x18,%eax
  4013a4:	83 e0 0f             	and    $0xf,%eax
  4013a7:	83 c8 e0             	or     $0xffffffe0,%eax
  4013aa:	ba f6 01 00 00       	mov    $0x1f6,%edx
  4013af:	ee                   	out    %al,(%dx)
  4013b0:	b8 30 00 00 00       	mov    $0x30,%eax
  4013b5:	ba f7 01 00 00       	mov    $0x1f7,%edx
  4013ba:	ee                   	out    %al,(%dx)
  4013bb:	c1 e3 09             	shl    $0x9,%ebx
  4013be:	01 fb                	add    %edi,%ebx
	outb(0x1F7, 0x30);	// CMD 0x30 means write sector

	for (; nsecs > 0; nsecs--, src += SECTSIZE) {
  4013c0:	39 fb                	cmp    %edi,%ebx
  4013c2:	74 43                	je     401407 <ide_write+0xbc>
		if ((r = ide_wait_ready(1)) < 0)
  4013c4:	b8 01 00 00 00       	mov    $0x1,%eax
  4013c9:	e8 88 fe ff ff       	call   401256 <ide_wait_ready>
  4013ce:	85 c0                	test   %eax,%eax
  4013d0:	78 3a                	js     40140c <ide_write+0xc1>
	asm volatile("cld\n\trepne\n\toutsl"
  4013d2:	89 fe                	mov    %edi,%esi
  4013d4:	b9 80 00 00 00       	mov    $0x80,%ecx
  4013d9:	ba f0 01 00 00       	mov    $0x1f0,%edx
  4013de:	fc                   	cld    
  4013df:	f2 6f                	repnz outsl %ds:(%esi),(%dx)
	for (; nsecs > 0; nsecs--, src += SECTSIZE) {
  4013e1:	81 c7 00 02 00 00    	add    $0x200,%edi
  4013e7:	eb d7                	jmp    4013c0 <ide_write+0x75>
	assert(nsecs <= 256);
  4013e9:	8d 90 4c d4 fe ff    	lea    -0x12bb4(%eax),%edx
  4013ef:	52                   	push   %edx
  4013f0:	8d 90 56 d2 fe ff    	lea    -0x12daa(%eax),%edx
  4013f6:	52                   	push   %edx
  4013f7:	6a 3c                	push   $0x3c
  4013f9:	8d 90 59 d4 fe ff    	lea    -0x12ba7(%eax),%edx
  4013ff:	52                   	push   %edx
  401400:	89 c3                	mov    %eax,%ebx
  401402:	e8 39 ec ff ff       	call   400040 <_panic>
			return r;
		outsl(0x1F0, src, SECTSIZE/4);
	}

	return 0;
  401407:	b8 00 00 00 00       	mov    $0x0,%eax
}
  40140c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  40140f:	5b                   	pop    %ebx
  401410:	5e                   	pop    %esi
  401411:	5f                   	pop    %edi
  401412:	5d                   	pop    %ebp
  401413:	c3                   	ret    

00401414 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  401414:	55                   	push   %ebp
  401415:	89 e5                	mov    %esp,%ebp
  401417:	57                   	push   %edi
  401418:	56                   	push   %esi
  401419:	53                   	push   %ebx
  40141a:	83 ec 2c             	sub    $0x2c,%esp
  40141d:	e8 cd 05 00 00       	call   4019ef <__x86.get_pc_thunk.cx>
  401422:	81 c1 12 3f 01 00    	add    $0x13f12,%ecx
  401428:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  40142b:	89 c7                	mov    %eax,%edi
  40142d:	89 d6                	mov    %edx,%esi
  40142f:	8b 45 08             	mov    0x8(%ebp),%eax
  401432:	8b 55 0c             	mov    0xc(%ebp),%edx
  401435:	89 45 d0             	mov    %eax,-0x30(%ebp)
  401438:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  40143b:	8b 4d 10             	mov    0x10(%ebp),%ecx
  40143e:	bb 00 00 00 00       	mov    $0x0,%ebx
  401443:	89 4d d8             	mov    %ecx,-0x28(%ebp)
  401446:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  401449:	39 d3                	cmp    %edx,%ebx
  40144b:	72 09                	jb     401456 <printnum+0x42>
  40144d:	39 45 10             	cmp    %eax,0x10(%ebp)
  401450:	0f 87 83 00 00 00    	ja     4014d9 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  401456:	83 ec 0c             	sub    $0xc,%esp
  401459:	ff 75 18             	pushl  0x18(%ebp)
  40145c:	8b 45 14             	mov    0x14(%ebp),%eax
  40145f:	8d 58 ff             	lea    -0x1(%eax),%ebx
  401462:	53                   	push   %ebx
  401463:	ff 75 10             	pushl  0x10(%ebp)
  401466:	83 ec 08             	sub    $0x8,%esp
  401469:	ff 75 dc             	pushl  -0x24(%ebp)
  40146c:	ff 75 d8             	pushl  -0x28(%ebp)
  40146f:	ff 75 d4             	pushl  -0x2c(%ebp)
  401472:	ff 75 d0             	pushl  -0x30(%ebp)
  401475:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  401478:	e8 f3 09 00 00       	call   401e70 <__udivdi3>
  40147d:	83 c4 18             	add    $0x18,%esp
  401480:	52                   	push   %edx
  401481:	50                   	push   %eax
  401482:	89 f2                	mov    %esi,%edx
  401484:	89 f8                	mov    %edi,%eax
  401486:	e8 89 ff ff ff       	call   401414 <printnum>
  40148b:	83 c4 20             	add    $0x20,%esp
  40148e:	eb 13                	jmp    4014a3 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  401490:	83 ec 08             	sub    $0x8,%esp
  401493:	56                   	push   %esi
  401494:	ff 75 18             	pushl  0x18(%ebp)
  401497:	ff d7                	call   *%edi
  401499:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
  40149c:	83 eb 01             	sub    $0x1,%ebx
  40149f:	85 db                	test   %ebx,%ebx
  4014a1:	7f ed                	jg     401490 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  4014a3:	83 ec 08             	sub    $0x8,%esp
  4014a6:	56                   	push   %esi
  4014a7:	83 ec 04             	sub    $0x4,%esp
  4014aa:	ff 75 dc             	pushl  -0x24(%ebp)
  4014ad:	ff 75 d8             	pushl  -0x28(%ebp)
  4014b0:	ff 75 d4             	pushl  -0x2c(%ebp)
  4014b3:	ff 75 d0             	pushl  -0x30(%ebp)
  4014b6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  4014b9:	89 f3                	mov    %esi,%ebx
  4014bb:	e8 d0 0a 00 00       	call   401f90 <__umoddi3>
  4014c0:	83 c4 14             	add    $0x14,%esp
  4014c3:	0f be 84 06 64 d4 fe 	movsbl -0x12b9c(%esi,%eax,1),%eax
  4014ca:	ff 
  4014cb:	50                   	push   %eax
  4014cc:	ff d7                	call   *%edi
}
  4014ce:	83 c4 10             	add    $0x10,%esp
  4014d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  4014d4:	5b                   	pop    %ebx
  4014d5:	5e                   	pop    %esi
  4014d6:	5f                   	pop    %edi
  4014d7:	5d                   	pop    %ebp
  4014d8:	c3                   	ret    
  4014d9:	8b 5d 14             	mov    0x14(%ebp),%ebx
  4014dc:	eb be                	jmp    40149c <printnum+0x88>

004014de <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  4014de:	55                   	push   %ebp
  4014df:	89 e5                	mov    %esp,%ebp
  4014e1:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  4014e4:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  4014e8:	8b 10                	mov    (%eax),%edx
  4014ea:	3b 50 04             	cmp    0x4(%eax),%edx
  4014ed:	73 0a                	jae    4014f9 <sprintputch+0x1b>
		*b->buf++ = ch;
  4014ef:	8d 4a 01             	lea    0x1(%edx),%ecx
  4014f2:	89 08                	mov    %ecx,(%eax)
  4014f4:	8b 45 08             	mov    0x8(%ebp),%eax
  4014f7:	88 02                	mov    %al,(%edx)
}
  4014f9:	5d                   	pop    %ebp
  4014fa:	c3                   	ret    

004014fb <printfmt>:
{
  4014fb:	55                   	push   %ebp
  4014fc:	89 e5                	mov    %esp,%ebp
  4014fe:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
  401501:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  401504:	50                   	push   %eax
  401505:	ff 75 10             	pushl  0x10(%ebp)
  401508:	ff 75 0c             	pushl  0xc(%ebp)
  40150b:	ff 75 08             	pushl  0x8(%ebp)
  40150e:	e8 05 00 00 00       	call   401518 <vprintfmt>
}
  401513:	83 c4 10             	add    $0x10,%esp
  401516:	c9                   	leave  
  401517:	c3                   	ret    

00401518 <vprintfmt>:
{
  401518:	55                   	push   %ebp
  401519:	89 e5                	mov    %esp,%ebp
  40151b:	57                   	push   %edi
  40151c:	56                   	push   %esi
  40151d:	53                   	push   %ebx
  40151e:	83 ec 2c             	sub    $0x2c,%esp
  401521:	e8 3a ed ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  401526:	81 c3 0e 3e 01 00    	add    $0x13e0e,%ebx
  40152c:	8b 75 0c             	mov    0xc(%ebp),%esi
  40152f:	8b 7d 10             	mov    0x10(%ebp),%edi
  401532:	e9 8e 03 00 00       	jmp    4018c5 <.L35+0x48>
		padc = ' ';
  401537:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
  40153b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
  401542:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
  401549:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
  401550:	b9 00 00 00 00       	mov    $0x0,%ecx
  401555:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  401558:	8d 47 01             	lea    0x1(%edi),%eax
  40155b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  40155e:	0f b6 17             	movzbl (%edi),%edx
  401561:	8d 42 dd             	lea    -0x23(%edx),%eax
  401564:	3c 55                	cmp    $0x55,%al
  401566:	0f 87 e1 03 00 00    	ja     40194d <.L22>
  40156c:	0f b6 c0             	movzbl %al,%eax
  40156f:	89 d9                	mov    %ebx,%ecx
  401571:	03 8c 83 f0 d4 fe ff 	add    -0x12b10(%ebx,%eax,4),%ecx
  401578:	ff e1                	jmp    *%ecx

0040157a <.L67>:
  40157a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
  40157d:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
  401581:	eb d5                	jmp    401558 <vprintfmt+0x40>

00401583 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
  401583:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
  401586:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  40158a:	eb cc                	jmp    401558 <vprintfmt+0x40>

0040158c <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
  40158c:	0f b6 d2             	movzbl %dl,%edx
  40158f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
  401592:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
  401597:	8d 04 80             	lea    (%eax,%eax,4),%eax
  40159a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  40159e:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  4015a1:	8d 4a d0             	lea    -0x30(%edx),%ecx
  4015a4:	83 f9 09             	cmp    $0x9,%ecx
  4015a7:	77 55                	ja     4015fe <.L23+0xf>
			for (precision = 0; ; ++fmt) {
  4015a9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
  4015ac:	eb e9                	jmp    401597 <.L29+0xb>

004015ae <.L26>:
			precision = va_arg(ap, int);
  4015ae:	8b 45 14             	mov    0x14(%ebp),%eax
  4015b1:	8b 00                	mov    (%eax),%eax
  4015b3:	89 45 d0             	mov    %eax,-0x30(%ebp)
  4015b6:	8b 45 14             	mov    0x14(%ebp),%eax
  4015b9:	8d 40 04             	lea    0x4(%eax),%eax
  4015bc:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  4015bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
  4015c2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  4015c6:	79 90                	jns    401558 <vprintfmt+0x40>
				width = precision, precision = -1;
  4015c8:	8b 45 d0             	mov    -0x30(%ebp),%eax
  4015cb:	89 45 e0             	mov    %eax,-0x20(%ebp)
  4015ce:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  4015d5:	eb 81                	jmp    401558 <vprintfmt+0x40>

004015d7 <.L27>:
  4015d7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  4015da:	85 c0                	test   %eax,%eax
  4015dc:	ba 00 00 00 00       	mov    $0x0,%edx
  4015e1:	0f 49 d0             	cmovns %eax,%edx
  4015e4:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  4015e7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  4015ea:	e9 69 ff ff ff       	jmp    401558 <vprintfmt+0x40>

004015ef <.L23>:
  4015ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
  4015f2:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  4015f9:	e9 5a ff ff ff       	jmp    401558 <vprintfmt+0x40>
  4015fe:	89 45 d0             	mov    %eax,-0x30(%ebp)
  401601:	eb bf                	jmp    4015c2 <.L26+0x14>

00401603 <.L33>:
			lflag++;
  401603:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
  401607:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
  40160a:	e9 49 ff ff ff       	jmp    401558 <vprintfmt+0x40>

0040160f <.L30>:
			putch(va_arg(ap, int), putdat);
  40160f:	8b 45 14             	mov    0x14(%ebp),%eax
  401612:	8d 78 04             	lea    0x4(%eax),%edi
  401615:	83 ec 08             	sub    $0x8,%esp
  401618:	56                   	push   %esi
  401619:	ff 30                	pushl  (%eax)
  40161b:	ff 55 08             	call   *0x8(%ebp)
			break;
  40161e:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
  401621:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
  401624:	e9 99 02 00 00       	jmp    4018c2 <.L35+0x45>

00401629 <.L32>:
			err = va_arg(ap, int);
  401629:	8b 45 14             	mov    0x14(%ebp),%eax
  40162c:	8d 78 04             	lea    0x4(%eax),%edi
  40162f:	8b 00                	mov    (%eax),%eax
  401631:	99                   	cltd   
  401632:	31 d0                	xor    %edx,%eax
  401634:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  401636:	83 f8 06             	cmp    $0x6,%eax
  401639:	7f 27                	jg     401662 <.L32+0x39>
  40163b:	8b 94 83 5c 1d 00 00 	mov    0x1d5c(%ebx,%eax,4),%edx
  401642:	85 d2                	test   %edx,%edx
  401644:	74 1c                	je     401662 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
  401646:	52                   	push   %edx
  401647:	8d 83 68 d2 fe ff    	lea    -0x12d98(%ebx),%eax
  40164d:	50                   	push   %eax
  40164e:	56                   	push   %esi
  40164f:	ff 75 08             	pushl  0x8(%ebp)
  401652:	e8 a4 fe ff ff       	call   4014fb <printfmt>
  401657:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
  40165a:	89 7d 14             	mov    %edi,0x14(%ebp)
  40165d:	e9 60 02 00 00       	jmp    4018c2 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
  401662:	50                   	push   %eax
  401663:	8d 83 7c d4 fe ff    	lea    -0x12b84(%ebx),%eax
  401669:	50                   	push   %eax
  40166a:	56                   	push   %esi
  40166b:	ff 75 08             	pushl  0x8(%ebp)
  40166e:	e8 88 fe ff ff       	call   4014fb <printfmt>
  401673:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
  401676:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
  401679:	e9 44 02 00 00       	jmp    4018c2 <.L35+0x45>

0040167e <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
  40167e:	8b 45 14             	mov    0x14(%ebp),%eax
  401681:	83 c0 04             	add    $0x4,%eax
  401684:	89 45 cc             	mov    %eax,-0x34(%ebp)
  401687:	8b 45 14             	mov    0x14(%ebp),%eax
  40168a:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  40168c:	85 ff                	test   %edi,%edi
  40168e:	8d 83 75 d4 fe ff    	lea    -0x12b8b(%ebx),%eax
  401694:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  401697:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  40169b:	0f 8e b5 00 00 00    	jle    401756 <.L36+0xd8>
  4016a1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  4016a5:	75 08                	jne    4016af <.L36+0x31>
  4016a7:	89 75 0c             	mov    %esi,0xc(%ebp)
  4016aa:	8b 75 d0             	mov    -0x30(%ebp),%esi
  4016ad:	eb 6d                	jmp    40171c <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
  4016af:	83 ec 08             	sub    $0x8,%esp
  4016b2:	ff 75 d0             	pushl  -0x30(%ebp)
  4016b5:	57                   	push   %edi
  4016b6:	e8 4d 04 00 00       	call   401b08 <strnlen>
  4016bb:	8b 55 e0             	mov    -0x20(%ebp),%edx
  4016be:	29 c2                	sub    %eax,%edx
  4016c0:	89 55 c8             	mov    %edx,-0x38(%ebp)
  4016c3:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  4016c6:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  4016ca:	89 45 e0             	mov    %eax,-0x20(%ebp)
  4016cd:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  4016d0:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
  4016d2:	eb 10                	jmp    4016e4 <.L36+0x66>
					putch(padc, putdat);
  4016d4:	83 ec 08             	sub    $0x8,%esp
  4016d7:	56                   	push   %esi
  4016d8:	ff 75 e0             	pushl  -0x20(%ebp)
  4016db:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
  4016de:	83 ef 01             	sub    $0x1,%edi
  4016e1:	83 c4 10             	add    $0x10,%esp
  4016e4:	85 ff                	test   %edi,%edi
  4016e6:	7f ec                	jg     4016d4 <.L36+0x56>
  4016e8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  4016eb:	8b 55 c8             	mov    -0x38(%ebp),%edx
  4016ee:	85 d2                	test   %edx,%edx
  4016f0:	b8 00 00 00 00       	mov    $0x0,%eax
  4016f5:	0f 49 c2             	cmovns %edx,%eax
  4016f8:	29 c2                	sub    %eax,%edx
  4016fa:	89 55 e0             	mov    %edx,-0x20(%ebp)
  4016fd:	89 75 0c             	mov    %esi,0xc(%ebp)
  401700:	8b 75 d0             	mov    -0x30(%ebp),%esi
  401703:	eb 17                	jmp    40171c <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
  401705:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  401709:	75 30                	jne    40173b <.L36+0xbd>
					putch(ch, putdat);
  40170b:	83 ec 08             	sub    $0x8,%esp
  40170e:	ff 75 0c             	pushl  0xc(%ebp)
  401711:	50                   	push   %eax
  401712:	ff 55 08             	call   *0x8(%ebp)
  401715:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  401718:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
  40171c:	83 c7 01             	add    $0x1,%edi
  40171f:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
  401723:	0f be c2             	movsbl %dl,%eax
  401726:	85 c0                	test   %eax,%eax
  401728:	74 52                	je     40177c <.L36+0xfe>
  40172a:	85 f6                	test   %esi,%esi
  40172c:	78 d7                	js     401705 <.L36+0x87>
  40172e:	83 ee 01             	sub    $0x1,%esi
  401731:	79 d2                	jns    401705 <.L36+0x87>
  401733:	8b 75 0c             	mov    0xc(%ebp),%esi
  401736:	8b 7d e0             	mov    -0x20(%ebp),%edi
  401739:	eb 32                	jmp    40176d <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
  40173b:	0f be d2             	movsbl %dl,%edx
  40173e:	83 ea 20             	sub    $0x20,%edx
  401741:	83 fa 5e             	cmp    $0x5e,%edx
  401744:	76 c5                	jbe    40170b <.L36+0x8d>
					putch('?', putdat);
  401746:	83 ec 08             	sub    $0x8,%esp
  401749:	ff 75 0c             	pushl  0xc(%ebp)
  40174c:	6a 3f                	push   $0x3f
  40174e:	ff 55 08             	call   *0x8(%ebp)
  401751:	83 c4 10             	add    $0x10,%esp
  401754:	eb c2                	jmp    401718 <.L36+0x9a>
  401756:	89 75 0c             	mov    %esi,0xc(%ebp)
  401759:	8b 75 d0             	mov    -0x30(%ebp),%esi
  40175c:	eb be                	jmp    40171c <.L36+0x9e>
				putch(' ', putdat);
  40175e:	83 ec 08             	sub    $0x8,%esp
  401761:	56                   	push   %esi
  401762:	6a 20                	push   $0x20
  401764:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
  401767:	83 ef 01             	sub    $0x1,%edi
  40176a:	83 c4 10             	add    $0x10,%esp
  40176d:	85 ff                	test   %edi,%edi
  40176f:	7f ed                	jg     40175e <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
  401771:	8b 45 cc             	mov    -0x34(%ebp),%eax
  401774:	89 45 14             	mov    %eax,0x14(%ebp)
  401777:	e9 46 01 00 00       	jmp    4018c2 <.L35+0x45>
  40177c:	8b 7d e0             	mov    -0x20(%ebp),%edi
  40177f:	8b 75 0c             	mov    0xc(%ebp),%esi
  401782:	eb e9                	jmp    40176d <.L36+0xef>

00401784 <.L31>:
  401784:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
  401787:	83 f9 01             	cmp    $0x1,%ecx
  40178a:	7e 40                	jle    4017cc <.L31+0x48>
		return va_arg(*ap, long long);
  40178c:	8b 45 14             	mov    0x14(%ebp),%eax
  40178f:	8b 50 04             	mov    0x4(%eax),%edx
  401792:	8b 00                	mov    (%eax),%eax
  401794:	89 45 d8             	mov    %eax,-0x28(%ebp)
  401797:	89 55 dc             	mov    %edx,-0x24(%ebp)
  40179a:	8b 45 14             	mov    0x14(%ebp),%eax
  40179d:	8d 40 08             	lea    0x8(%eax),%eax
  4017a0:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
  4017a3:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  4017a7:	79 55                	jns    4017fe <.L31+0x7a>
				putch('-', putdat);
  4017a9:	83 ec 08             	sub    $0x8,%esp
  4017ac:	56                   	push   %esi
  4017ad:	6a 2d                	push   $0x2d
  4017af:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  4017b2:	8b 55 d8             	mov    -0x28(%ebp),%edx
  4017b5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  4017b8:	f7 da                	neg    %edx
  4017ba:	83 d1 00             	adc    $0x0,%ecx
  4017bd:	f7 d9                	neg    %ecx
  4017bf:	83 c4 10             	add    $0x10,%esp
			base = 10;
  4017c2:	b8 0a 00 00 00       	mov    $0xa,%eax
  4017c7:	e9 db 00 00 00       	jmp    4018a7 <.L35+0x2a>
	else if (lflag)
  4017cc:	85 c9                	test   %ecx,%ecx
  4017ce:	75 17                	jne    4017e7 <.L31+0x63>
		return va_arg(*ap, int);
  4017d0:	8b 45 14             	mov    0x14(%ebp),%eax
  4017d3:	8b 00                	mov    (%eax),%eax
  4017d5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  4017d8:	99                   	cltd   
  4017d9:	89 55 dc             	mov    %edx,-0x24(%ebp)
  4017dc:	8b 45 14             	mov    0x14(%ebp),%eax
  4017df:	8d 40 04             	lea    0x4(%eax),%eax
  4017e2:	89 45 14             	mov    %eax,0x14(%ebp)
  4017e5:	eb bc                	jmp    4017a3 <.L31+0x1f>
		return va_arg(*ap, long);
  4017e7:	8b 45 14             	mov    0x14(%ebp),%eax
  4017ea:	8b 00                	mov    (%eax),%eax
  4017ec:	89 45 d8             	mov    %eax,-0x28(%ebp)
  4017ef:	99                   	cltd   
  4017f0:	89 55 dc             	mov    %edx,-0x24(%ebp)
  4017f3:	8b 45 14             	mov    0x14(%ebp),%eax
  4017f6:	8d 40 04             	lea    0x4(%eax),%eax
  4017f9:	89 45 14             	mov    %eax,0x14(%ebp)
  4017fc:	eb a5                	jmp    4017a3 <.L31+0x1f>
			num = getint(&ap, lflag);
  4017fe:	8b 55 d8             	mov    -0x28(%ebp),%edx
  401801:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
  401804:	b8 0a 00 00 00       	mov    $0xa,%eax
  401809:	e9 99 00 00 00       	jmp    4018a7 <.L35+0x2a>

0040180e <.L37>:
  40180e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
  401811:	83 f9 01             	cmp    $0x1,%ecx
  401814:	7e 15                	jle    40182b <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
  401816:	8b 45 14             	mov    0x14(%ebp),%eax
  401819:	8b 10                	mov    (%eax),%edx
  40181b:	8b 48 04             	mov    0x4(%eax),%ecx
  40181e:	8d 40 08             	lea    0x8(%eax),%eax
  401821:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  401824:	b8 0a 00 00 00       	mov    $0xa,%eax
  401829:	eb 7c                	jmp    4018a7 <.L35+0x2a>
	else if (lflag)
  40182b:	85 c9                	test   %ecx,%ecx
  40182d:	75 17                	jne    401846 <.L37+0x38>
		return va_arg(*ap, unsigned int);
  40182f:	8b 45 14             	mov    0x14(%ebp),%eax
  401832:	8b 10                	mov    (%eax),%edx
  401834:	b9 00 00 00 00       	mov    $0x0,%ecx
  401839:	8d 40 04             	lea    0x4(%eax),%eax
  40183c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  40183f:	b8 0a 00 00 00       	mov    $0xa,%eax
  401844:	eb 61                	jmp    4018a7 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
  401846:	8b 45 14             	mov    0x14(%ebp),%eax
  401849:	8b 10                	mov    (%eax),%edx
  40184b:	b9 00 00 00 00       	mov    $0x0,%ecx
  401850:	8d 40 04             	lea    0x4(%eax),%eax
  401853:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
  401856:	b8 0a 00 00 00       	mov    $0xa,%eax
  40185b:	eb 4a                	jmp    4018a7 <.L35+0x2a>

0040185d <.L34>:
			putch('X', putdat);
  40185d:	83 ec 08             	sub    $0x8,%esp
  401860:	56                   	push   %esi
  401861:	6a 58                	push   $0x58
  401863:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
  401866:	83 c4 08             	add    $0x8,%esp
  401869:	56                   	push   %esi
  40186a:	6a 58                	push   $0x58
  40186c:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
  40186f:	83 c4 08             	add    $0x8,%esp
  401872:	56                   	push   %esi
  401873:	6a 58                	push   $0x58
  401875:	ff 55 08             	call   *0x8(%ebp)
			break;
  401878:	83 c4 10             	add    $0x10,%esp
  40187b:	eb 45                	jmp    4018c2 <.L35+0x45>

0040187d <.L35>:
			putch('0', putdat);
  40187d:	83 ec 08             	sub    $0x8,%esp
  401880:	56                   	push   %esi
  401881:	6a 30                	push   $0x30
  401883:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  401886:	83 c4 08             	add    $0x8,%esp
  401889:	56                   	push   %esi
  40188a:	6a 78                	push   $0x78
  40188c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
  40188f:	8b 45 14             	mov    0x14(%ebp),%eax
  401892:	8b 10                	mov    (%eax),%edx
  401894:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
  401899:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
  40189c:	8d 40 04             	lea    0x4(%eax),%eax
  40189f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  4018a2:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
  4018a7:	83 ec 0c             	sub    $0xc,%esp
  4018aa:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  4018ae:	57                   	push   %edi
  4018af:	ff 75 e0             	pushl  -0x20(%ebp)
  4018b2:	50                   	push   %eax
  4018b3:	51                   	push   %ecx
  4018b4:	52                   	push   %edx
  4018b5:	89 f2                	mov    %esi,%edx
  4018b7:	8b 45 08             	mov    0x8(%ebp),%eax
  4018ba:	e8 55 fb ff ff       	call   401414 <printnum>
			break;
  4018bf:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
  4018c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
  4018c5:	83 c7 01             	add    $0x1,%edi
  4018c8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  4018cc:	83 f8 25             	cmp    $0x25,%eax
  4018cf:	0f 84 62 fc ff ff    	je     401537 <vprintfmt+0x1f>
			if (ch == '\0')
  4018d5:	85 c0                	test   %eax,%eax
  4018d7:	0f 84 91 00 00 00    	je     40196e <.L22+0x21>
			putch(ch, putdat);
  4018dd:	83 ec 08             	sub    $0x8,%esp
  4018e0:	56                   	push   %esi
  4018e1:	50                   	push   %eax
  4018e2:	ff 55 08             	call   *0x8(%ebp)
  4018e5:	83 c4 10             	add    $0x10,%esp
  4018e8:	eb db                	jmp    4018c5 <.L35+0x48>

004018ea <.L38>:
  4018ea:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
  4018ed:	83 f9 01             	cmp    $0x1,%ecx
  4018f0:	7e 15                	jle    401907 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
  4018f2:	8b 45 14             	mov    0x14(%ebp),%eax
  4018f5:	8b 10                	mov    (%eax),%edx
  4018f7:	8b 48 04             	mov    0x4(%eax),%ecx
  4018fa:	8d 40 08             	lea    0x8(%eax),%eax
  4018fd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  401900:	b8 10 00 00 00       	mov    $0x10,%eax
  401905:	eb a0                	jmp    4018a7 <.L35+0x2a>
	else if (lflag)
  401907:	85 c9                	test   %ecx,%ecx
  401909:	75 17                	jne    401922 <.L38+0x38>
		return va_arg(*ap, unsigned int);
  40190b:	8b 45 14             	mov    0x14(%ebp),%eax
  40190e:	8b 10                	mov    (%eax),%edx
  401910:	b9 00 00 00 00       	mov    $0x0,%ecx
  401915:	8d 40 04             	lea    0x4(%eax),%eax
  401918:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  40191b:	b8 10 00 00 00       	mov    $0x10,%eax
  401920:	eb 85                	jmp    4018a7 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
  401922:	8b 45 14             	mov    0x14(%ebp),%eax
  401925:	8b 10                	mov    (%eax),%edx
  401927:	b9 00 00 00 00       	mov    $0x0,%ecx
  40192c:	8d 40 04             	lea    0x4(%eax),%eax
  40192f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  401932:	b8 10 00 00 00       	mov    $0x10,%eax
  401937:	e9 6b ff ff ff       	jmp    4018a7 <.L35+0x2a>

0040193c <.L25>:
			putch(ch, putdat);
  40193c:	83 ec 08             	sub    $0x8,%esp
  40193f:	56                   	push   %esi
  401940:	6a 25                	push   $0x25
  401942:	ff 55 08             	call   *0x8(%ebp)
			break;
  401945:	83 c4 10             	add    $0x10,%esp
  401948:	e9 75 ff ff ff       	jmp    4018c2 <.L35+0x45>

0040194d <.L22>:
			putch('%', putdat);
  40194d:	83 ec 08             	sub    $0x8,%esp
  401950:	56                   	push   %esi
  401951:	6a 25                	push   $0x25
  401953:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  401956:	83 c4 10             	add    $0x10,%esp
  401959:	89 f8                	mov    %edi,%eax
  40195b:	eb 03                	jmp    401960 <.L22+0x13>
  40195d:	83 e8 01             	sub    $0x1,%eax
  401960:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
  401964:	75 f7                	jne    40195d <.L22+0x10>
  401966:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  401969:	e9 54 ff ff ff       	jmp    4018c2 <.L35+0x45>
}
  40196e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  401971:	5b                   	pop    %ebx
  401972:	5e                   	pop    %esi
  401973:	5f                   	pop    %edi
  401974:	5d                   	pop    %ebp
  401975:	c3                   	ret    

00401976 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  401976:	55                   	push   %ebp
  401977:	89 e5                	mov    %esp,%ebp
  401979:	53                   	push   %ebx
  40197a:	83 ec 14             	sub    $0x14,%esp
  40197d:	e8 de e8 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  401982:	81 c3 b2 39 01 00    	add    $0x139b2,%ebx
  401988:	8b 45 08             	mov    0x8(%ebp),%eax
  40198b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  40198e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  401991:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  401995:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  401998:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  40199f:	85 c0                	test   %eax,%eax
  4019a1:	74 2b                	je     4019ce <vsnprintf+0x58>
  4019a3:	85 d2                	test   %edx,%edx
  4019a5:	7e 27                	jle    4019ce <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  4019a7:	ff 75 14             	pushl  0x14(%ebp)
  4019aa:	ff 75 10             	pushl  0x10(%ebp)
  4019ad:	8d 45 ec             	lea    -0x14(%ebp),%eax
  4019b0:	50                   	push   %eax
  4019b1:	8d 83 aa c1 fe ff    	lea    -0x13e56(%ebx),%eax
  4019b7:	50                   	push   %eax
  4019b8:	e8 5b fb ff ff       	call   401518 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  4019bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
  4019c0:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  4019c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  4019c6:	83 c4 10             	add    $0x10,%esp
}
  4019c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  4019cc:	c9                   	leave  
  4019cd:	c3                   	ret    
		return -E_INVAL;
  4019ce:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  4019d3:	eb f4                	jmp    4019c9 <vsnprintf+0x53>

004019d5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  4019d5:	55                   	push   %ebp
  4019d6:	89 e5                	mov    %esp,%ebp
  4019d8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  4019db:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  4019de:	50                   	push   %eax
  4019df:	ff 75 10             	pushl  0x10(%ebp)
  4019e2:	ff 75 0c             	pushl  0xc(%ebp)
  4019e5:	ff 75 08             	pushl  0x8(%ebp)
  4019e8:	e8 89 ff ff ff       	call   401976 <vsnprintf>
	va_end(ap);

	return rc;
}
  4019ed:	c9                   	leave  
  4019ee:	c3                   	ret    

004019ef <__x86.get_pc_thunk.cx>:
  4019ef:	8b 0c 24             	mov    (%esp),%ecx
  4019f2:	c3                   	ret    

004019f3 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
  4019f3:	55                   	push   %ebp
  4019f4:	89 e5                	mov    %esp,%ebp
  4019f6:	57                   	push   %edi
  4019f7:	56                   	push   %esi
  4019f8:	53                   	push   %ebx
  4019f9:	83 ec 1c             	sub    $0x1c,%esp
  4019fc:	e8 5f e8 ff ff       	call   400260 <__x86.get_pc_thunk.bx>
  401a01:	81 c3 33 39 01 00    	add    $0x13933,%ebx
  401a07:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
  401a0a:	85 c0                	test   %eax,%eax
  401a0c:	74 13                	je     401a21 <readline+0x2e>
		cprintf("%s", prompt);
  401a0e:	83 ec 08             	sub    $0x8,%esp
  401a11:	50                   	push   %eax
  401a12:	8d 83 68 d2 fe ff    	lea    -0x12d98(%ebx),%eax
  401a18:	50                   	push   %eax
  401a19:	e8 da ee ff ff       	call   4008f8 <cprintf>
  401a1e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
  401a21:	83 ec 0c             	sub    $0xc,%esp
  401a24:	6a 00                	push   $0x0
  401a26:	e8 cd ed ff ff       	call   4007f8 <iscons>
  401a2b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  401a2e:	83 c4 10             	add    $0x10,%esp
	i = 0;
  401a31:	bf 00 00 00 00       	mov    $0x0,%edi
  401a36:	eb 46                	jmp    401a7e <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
  401a38:	83 ec 08             	sub    $0x8,%esp
  401a3b:	50                   	push   %eax
  401a3c:	8d 83 48 d6 fe ff    	lea    -0x129b8(%ebx),%eax
  401a42:	50                   	push   %eax
  401a43:	e8 b0 ee ff ff       	call   4008f8 <cprintf>
			return NULL;
  401a48:	83 c4 10             	add    $0x10,%esp
  401a4b:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
  401a50:	8d 65 f4             	lea    -0xc(%ebp),%esp
  401a53:	5b                   	pop    %ebx
  401a54:	5e                   	pop    %esi
  401a55:	5f                   	pop    %edi
  401a56:	5d                   	pop    %ebp
  401a57:	c3                   	ret    
			if (echoing)
  401a58:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  401a5c:	75 05                	jne    401a63 <readline+0x70>
			i--;
  401a5e:	83 ef 01             	sub    $0x1,%edi
  401a61:	eb 1b                	jmp    401a7e <readline+0x8b>
				cputchar('\b');
  401a63:	83 ec 0c             	sub    $0xc,%esp
  401a66:	6a 08                	push   $0x8
  401a68:	e8 6a ed ff ff       	call   4007d7 <cputchar>
  401a6d:	83 c4 10             	add    $0x10,%esp
  401a70:	eb ec                	jmp    401a5e <readline+0x6b>
			buf[i++] = c;
  401a72:	89 f0                	mov    %esi,%eax
  401a74:	88 84 3b 6c 28 00 00 	mov    %al,0x286c(%ebx,%edi,1)
  401a7b:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
  401a7e:	e8 64 ed ff ff       	call   4007e7 <getchar>
  401a83:	89 c6                	mov    %eax,%esi
		if (c < 0) {
  401a85:	85 c0                	test   %eax,%eax
  401a87:	78 af                	js     401a38 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
  401a89:	83 f8 08             	cmp    $0x8,%eax
  401a8c:	0f 94 c2             	sete   %dl
  401a8f:	83 f8 7f             	cmp    $0x7f,%eax
  401a92:	0f 94 c0             	sete   %al
  401a95:	08 c2                	or     %al,%dl
  401a97:	74 04                	je     401a9d <readline+0xaa>
  401a99:	85 ff                	test   %edi,%edi
  401a9b:	7f bb                	jg     401a58 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
  401a9d:	83 fe 1f             	cmp    $0x1f,%esi
  401aa0:	7e 1c                	jle    401abe <readline+0xcb>
  401aa2:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
  401aa8:	7f 14                	jg     401abe <readline+0xcb>
			if (echoing)
  401aaa:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  401aae:	74 c2                	je     401a72 <readline+0x7f>
				cputchar(c);
  401ab0:	83 ec 0c             	sub    $0xc,%esp
  401ab3:	56                   	push   %esi
  401ab4:	e8 1e ed ff ff       	call   4007d7 <cputchar>
  401ab9:	83 c4 10             	add    $0x10,%esp
  401abc:	eb b4                	jmp    401a72 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
  401abe:	83 fe 0a             	cmp    $0xa,%esi
  401ac1:	74 05                	je     401ac8 <readline+0xd5>
  401ac3:	83 fe 0d             	cmp    $0xd,%esi
  401ac6:	75 b6                	jne    401a7e <readline+0x8b>
			if (echoing)
  401ac8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  401acc:	75 13                	jne    401ae1 <readline+0xee>
			buf[i] = 0;
  401ace:	c6 84 3b 6c 28 00 00 	movb   $0x0,0x286c(%ebx,%edi,1)
  401ad5:	00 
			return buf;
  401ad6:	8d 83 6c 28 00 00    	lea    0x286c(%ebx),%eax
  401adc:	e9 6f ff ff ff       	jmp    401a50 <readline+0x5d>
				cputchar('\n');
  401ae1:	83 ec 0c             	sub    $0xc,%esp
  401ae4:	6a 0a                	push   $0xa
  401ae6:	e8 ec ec ff ff       	call   4007d7 <cputchar>
  401aeb:	83 c4 10             	add    $0x10,%esp
  401aee:	eb de                	jmp    401ace <readline+0xdb>

00401af0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  401af0:	55                   	push   %ebp
  401af1:	89 e5                	mov    %esp,%ebp
  401af3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  401af6:	b8 00 00 00 00       	mov    $0x0,%eax
  401afb:	eb 03                	jmp    401b00 <strlen+0x10>
		n++;
  401afd:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
  401b00:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  401b04:	75 f7                	jne    401afd <strlen+0xd>
	return n;
}
  401b06:	5d                   	pop    %ebp
  401b07:	c3                   	ret    

00401b08 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  401b08:	55                   	push   %ebp
  401b09:	89 e5                	mov    %esp,%ebp
  401b0b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  401b0e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  401b11:	b8 00 00 00 00       	mov    $0x0,%eax
  401b16:	eb 03                	jmp    401b1b <strnlen+0x13>
		n++;
  401b18:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  401b1b:	39 d0                	cmp    %edx,%eax
  401b1d:	74 06                	je     401b25 <strnlen+0x1d>
  401b1f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  401b23:	75 f3                	jne    401b18 <strnlen+0x10>
	return n;
}
  401b25:	5d                   	pop    %ebp
  401b26:	c3                   	ret    

00401b27 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  401b27:	55                   	push   %ebp
  401b28:	89 e5                	mov    %esp,%ebp
  401b2a:	53                   	push   %ebx
  401b2b:	8b 45 08             	mov    0x8(%ebp),%eax
  401b2e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  401b31:	89 c2                	mov    %eax,%edx
  401b33:	83 c1 01             	add    $0x1,%ecx
  401b36:	83 c2 01             	add    $0x1,%edx
  401b39:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  401b3d:	88 5a ff             	mov    %bl,-0x1(%edx)
  401b40:	84 db                	test   %bl,%bl
  401b42:	75 ef                	jne    401b33 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  401b44:	5b                   	pop    %ebx
  401b45:	5d                   	pop    %ebp
  401b46:	c3                   	ret    

00401b47 <strcat>:

char *
strcat(char *dst, const char *src)
{
  401b47:	55                   	push   %ebp
  401b48:	89 e5                	mov    %esp,%ebp
  401b4a:	53                   	push   %ebx
  401b4b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  401b4e:	53                   	push   %ebx
  401b4f:	e8 9c ff ff ff       	call   401af0 <strlen>
  401b54:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  401b57:	ff 75 0c             	pushl  0xc(%ebp)
  401b5a:	01 d8                	add    %ebx,%eax
  401b5c:	50                   	push   %eax
  401b5d:	e8 c5 ff ff ff       	call   401b27 <strcpy>
	return dst;
}
  401b62:	89 d8                	mov    %ebx,%eax
  401b64:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  401b67:	c9                   	leave  
  401b68:	c3                   	ret    

00401b69 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  401b69:	55                   	push   %ebp
  401b6a:	89 e5                	mov    %esp,%ebp
  401b6c:	56                   	push   %esi
  401b6d:	53                   	push   %ebx
  401b6e:	8b 75 08             	mov    0x8(%ebp),%esi
  401b71:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  401b74:	89 f3                	mov    %esi,%ebx
  401b76:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  401b79:	89 f2                	mov    %esi,%edx
  401b7b:	eb 0f                	jmp    401b8c <strncpy+0x23>
		*dst++ = *src;
  401b7d:	83 c2 01             	add    $0x1,%edx
  401b80:	0f b6 01             	movzbl (%ecx),%eax
  401b83:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  401b86:	80 39 01             	cmpb   $0x1,(%ecx)
  401b89:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
  401b8c:	39 da                	cmp    %ebx,%edx
  401b8e:	75 ed                	jne    401b7d <strncpy+0x14>
	}
	return ret;
}
  401b90:	89 f0                	mov    %esi,%eax
  401b92:	5b                   	pop    %ebx
  401b93:	5e                   	pop    %esi
  401b94:	5d                   	pop    %ebp
  401b95:	c3                   	ret    

00401b96 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  401b96:	55                   	push   %ebp
  401b97:	89 e5                	mov    %esp,%ebp
  401b99:	56                   	push   %esi
  401b9a:	53                   	push   %ebx
  401b9b:	8b 75 08             	mov    0x8(%ebp),%esi
  401b9e:	8b 55 0c             	mov    0xc(%ebp),%edx
  401ba1:	8b 4d 10             	mov    0x10(%ebp),%ecx
  401ba4:	89 f0                	mov    %esi,%eax
  401ba6:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  401baa:	85 c9                	test   %ecx,%ecx
  401bac:	75 0b                	jne    401bb9 <strlcpy+0x23>
  401bae:	eb 17                	jmp    401bc7 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  401bb0:	83 c2 01             	add    $0x1,%edx
  401bb3:	83 c0 01             	add    $0x1,%eax
  401bb6:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
  401bb9:	39 d8                	cmp    %ebx,%eax
  401bbb:	74 07                	je     401bc4 <strlcpy+0x2e>
  401bbd:	0f b6 0a             	movzbl (%edx),%ecx
  401bc0:	84 c9                	test   %cl,%cl
  401bc2:	75 ec                	jne    401bb0 <strlcpy+0x1a>
		*dst = '\0';
  401bc4:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  401bc7:	29 f0                	sub    %esi,%eax
}
  401bc9:	5b                   	pop    %ebx
  401bca:	5e                   	pop    %esi
  401bcb:	5d                   	pop    %ebp
  401bcc:	c3                   	ret    

00401bcd <strcmp>:

int
strcmp(const char *p, const char *q)
{
  401bcd:	55                   	push   %ebp
  401bce:	89 e5                	mov    %esp,%ebp
  401bd0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  401bd3:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  401bd6:	eb 06                	jmp    401bde <strcmp+0x11>
		p++, q++;
  401bd8:	83 c1 01             	add    $0x1,%ecx
  401bdb:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
  401bde:	0f b6 01             	movzbl (%ecx),%eax
  401be1:	84 c0                	test   %al,%al
  401be3:	74 04                	je     401be9 <strcmp+0x1c>
  401be5:	3a 02                	cmp    (%edx),%al
  401be7:	74 ef                	je     401bd8 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  401be9:	0f b6 c0             	movzbl %al,%eax
  401bec:	0f b6 12             	movzbl (%edx),%edx
  401bef:	29 d0                	sub    %edx,%eax
}
  401bf1:	5d                   	pop    %ebp
  401bf2:	c3                   	ret    

00401bf3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  401bf3:	55                   	push   %ebp
  401bf4:	89 e5                	mov    %esp,%ebp
  401bf6:	53                   	push   %ebx
  401bf7:	8b 45 08             	mov    0x8(%ebp),%eax
  401bfa:	8b 55 0c             	mov    0xc(%ebp),%edx
  401bfd:	89 c3                	mov    %eax,%ebx
  401bff:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  401c02:	eb 06                	jmp    401c0a <strncmp+0x17>
		n--, p++, q++;
  401c04:	83 c0 01             	add    $0x1,%eax
  401c07:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
  401c0a:	39 d8                	cmp    %ebx,%eax
  401c0c:	74 16                	je     401c24 <strncmp+0x31>
  401c0e:	0f b6 08             	movzbl (%eax),%ecx
  401c11:	84 c9                	test   %cl,%cl
  401c13:	74 04                	je     401c19 <strncmp+0x26>
  401c15:	3a 0a                	cmp    (%edx),%cl
  401c17:	74 eb                	je     401c04 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  401c19:	0f b6 00             	movzbl (%eax),%eax
  401c1c:	0f b6 12             	movzbl (%edx),%edx
  401c1f:	29 d0                	sub    %edx,%eax
}
  401c21:	5b                   	pop    %ebx
  401c22:	5d                   	pop    %ebp
  401c23:	c3                   	ret    
		return 0;
  401c24:	b8 00 00 00 00       	mov    $0x0,%eax
  401c29:	eb f6                	jmp    401c21 <strncmp+0x2e>

00401c2b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  401c2b:	55                   	push   %ebp
  401c2c:	89 e5                	mov    %esp,%ebp
  401c2e:	8b 45 08             	mov    0x8(%ebp),%eax
  401c31:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  401c35:	0f b6 10             	movzbl (%eax),%edx
  401c38:	84 d2                	test   %dl,%dl
  401c3a:	74 09                	je     401c45 <strchr+0x1a>
		if (*s == c)
  401c3c:	38 ca                	cmp    %cl,%dl
  401c3e:	74 0a                	je     401c4a <strchr+0x1f>
	for (; *s; s++)
  401c40:	83 c0 01             	add    $0x1,%eax
  401c43:	eb f0                	jmp    401c35 <strchr+0xa>
			return (char *) s;
	return 0;
  401c45:	b8 00 00 00 00       	mov    $0x0,%eax
}
  401c4a:	5d                   	pop    %ebp
  401c4b:	c3                   	ret    

00401c4c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  401c4c:	55                   	push   %ebp
  401c4d:	89 e5                	mov    %esp,%ebp
  401c4f:	8b 45 08             	mov    0x8(%ebp),%eax
  401c52:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  401c56:	eb 03                	jmp    401c5b <strfind+0xf>
  401c58:	83 c0 01             	add    $0x1,%eax
  401c5b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  401c5e:	38 ca                	cmp    %cl,%dl
  401c60:	74 04                	je     401c66 <strfind+0x1a>
  401c62:	84 d2                	test   %dl,%dl
  401c64:	75 f2                	jne    401c58 <strfind+0xc>
			break;
	return (char *) s;
}
  401c66:	5d                   	pop    %ebp
  401c67:	c3                   	ret    

00401c68 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  401c68:	55                   	push   %ebp
  401c69:	89 e5                	mov    %esp,%ebp
  401c6b:	57                   	push   %edi
  401c6c:	56                   	push   %esi
  401c6d:	53                   	push   %ebx
  401c6e:	8b 7d 08             	mov    0x8(%ebp),%edi
  401c71:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  401c74:	85 c9                	test   %ecx,%ecx
  401c76:	74 13                	je     401c8b <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  401c78:	f7 c7 03 00 00 00    	test   $0x3,%edi
  401c7e:	75 05                	jne    401c85 <memset+0x1d>
  401c80:	f6 c1 03             	test   $0x3,%cl
  401c83:	74 0d                	je     401c92 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  401c85:	8b 45 0c             	mov    0xc(%ebp),%eax
  401c88:	fc                   	cld    
  401c89:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  401c8b:	89 f8                	mov    %edi,%eax
  401c8d:	5b                   	pop    %ebx
  401c8e:	5e                   	pop    %esi
  401c8f:	5f                   	pop    %edi
  401c90:	5d                   	pop    %ebp
  401c91:	c3                   	ret    
		c &= 0xFF;
  401c92:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  401c96:	89 d3                	mov    %edx,%ebx
  401c98:	c1 e3 08             	shl    $0x8,%ebx
  401c9b:	89 d0                	mov    %edx,%eax
  401c9d:	c1 e0 18             	shl    $0x18,%eax
  401ca0:	89 d6                	mov    %edx,%esi
  401ca2:	c1 e6 10             	shl    $0x10,%esi
  401ca5:	09 f0                	or     %esi,%eax
  401ca7:	09 c2                	or     %eax,%edx
  401ca9:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
  401cab:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
  401cae:	89 d0                	mov    %edx,%eax
  401cb0:	fc                   	cld    
  401cb1:	f3 ab                	rep stos %eax,%es:(%edi)
  401cb3:	eb d6                	jmp    401c8b <memset+0x23>

00401cb5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  401cb5:	55                   	push   %ebp
  401cb6:	89 e5                	mov    %esp,%ebp
  401cb8:	57                   	push   %edi
  401cb9:	56                   	push   %esi
  401cba:	8b 45 08             	mov    0x8(%ebp),%eax
  401cbd:	8b 75 0c             	mov    0xc(%ebp),%esi
  401cc0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  401cc3:	39 c6                	cmp    %eax,%esi
  401cc5:	73 35                	jae    401cfc <memmove+0x47>
  401cc7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  401cca:	39 c2                	cmp    %eax,%edx
  401ccc:	76 2e                	jbe    401cfc <memmove+0x47>
		s += n;
		d += n;
  401cce:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  401cd1:	89 d6                	mov    %edx,%esi
  401cd3:	09 fe                	or     %edi,%esi
  401cd5:	f7 c6 03 00 00 00    	test   $0x3,%esi
  401cdb:	74 0c                	je     401ce9 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  401cdd:	83 ef 01             	sub    $0x1,%edi
  401ce0:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
  401ce3:	fd                   	std    
  401ce4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  401ce6:	fc                   	cld    
  401ce7:	eb 21                	jmp    401d0a <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  401ce9:	f6 c1 03             	test   $0x3,%cl
  401cec:	75 ef                	jne    401cdd <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  401cee:	83 ef 04             	sub    $0x4,%edi
  401cf1:	8d 72 fc             	lea    -0x4(%edx),%esi
  401cf4:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
  401cf7:	fd                   	std    
  401cf8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  401cfa:	eb ea                	jmp    401ce6 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  401cfc:	89 f2                	mov    %esi,%edx
  401cfe:	09 c2                	or     %eax,%edx
  401d00:	f6 c2 03             	test   $0x3,%dl
  401d03:	74 09                	je     401d0e <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  401d05:	89 c7                	mov    %eax,%edi
  401d07:	fc                   	cld    
  401d08:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  401d0a:	5e                   	pop    %esi
  401d0b:	5f                   	pop    %edi
  401d0c:	5d                   	pop    %ebp
  401d0d:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  401d0e:	f6 c1 03             	test   $0x3,%cl
  401d11:	75 f2                	jne    401d05 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  401d13:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
  401d16:	89 c7                	mov    %eax,%edi
  401d18:	fc                   	cld    
  401d19:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  401d1b:	eb ed                	jmp    401d0a <memmove+0x55>

00401d1d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  401d1d:	55                   	push   %ebp
  401d1e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  401d20:	ff 75 10             	pushl  0x10(%ebp)
  401d23:	ff 75 0c             	pushl  0xc(%ebp)
  401d26:	ff 75 08             	pushl  0x8(%ebp)
  401d29:	e8 87 ff ff ff       	call   401cb5 <memmove>
}
  401d2e:	c9                   	leave  
  401d2f:	c3                   	ret    

00401d30 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  401d30:	55                   	push   %ebp
  401d31:	89 e5                	mov    %esp,%ebp
  401d33:	56                   	push   %esi
  401d34:	53                   	push   %ebx
  401d35:	8b 45 08             	mov    0x8(%ebp),%eax
  401d38:	8b 55 0c             	mov    0xc(%ebp),%edx
  401d3b:	89 c6                	mov    %eax,%esi
  401d3d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  401d40:	39 f0                	cmp    %esi,%eax
  401d42:	74 1c                	je     401d60 <memcmp+0x30>
		if (*s1 != *s2)
  401d44:	0f b6 08             	movzbl (%eax),%ecx
  401d47:	0f b6 1a             	movzbl (%edx),%ebx
  401d4a:	38 d9                	cmp    %bl,%cl
  401d4c:	75 08                	jne    401d56 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
  401d4e:	83 c0 01             	add    $0x1,%eax
  401d51:	83 c2 01             	add    $0x1,%edx
  401d54:	eb ea                	jmp    401d40 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
  401d56:	0f b6 c1             	movzbl %cl,%eax
  401d59:	0f b6 db             	movzbl %bl,%ebx
  401d5c:	29 d8                	sub    %ebx,%eax
  401d5e:	eb 05                	jmp    401d65 <memcmp+0x35>
	}

	return 0;
  401d60:	b8 00 00 00 00       	mov    $0x0,%eax
}
  401d65:	5b                   	pop    %ebx
  401d66:	5e                   	pop    %esi
  401d67:	5d                   	pop    %ebp
  401d68:	c3                   	ret    

00401d69 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  401d69:	55                   	push   %ebp
  401d6a:	89 e5                	mov    %esp,%ebp
  401d6c:	8b 45 08             	mov    0x8(%ebp),%eax
  401d6f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  401d72:	89 c2                	mov    %eax,%edx
  401d74:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  401d77:	39 d0                	cmp    %edx,%eax
  401d79:	73 09                	jae    401d84 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
  401d7b:	38 08                	cmp    %cl,(%eax)
  401d7d:	74 05                	je     401d84 <memfind+0x1b>
	for (; s < ends; s++)
  401d7f:	83 c0 01             	add    $0x1,%eax
  401d82:	eb f3                	jmp    401d77 <memfind+0xe>
			break;
	return (void *) s;
}
  401d84:	5d                   	pop    %ebp
  401d85:	c3                   	ret    

00401d86 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  401d86:	55                   	push   %ebp
  401d87:	89 e5                	mov    %esp,%ebp
  401d89:	57                   	push   %edi
  401d8a:	56                   	push   %esi
  401d8b:	53                   	push   %ebx
  401d8c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  401d8f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  401d92:	eb 03                	jmp    401d97 <strtol+0x11>
		s++;
  401d94:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
  401d97:	0f b6 01             	movzbl (%ecx),%eax
  401d9a:	3c 20                	cmp    $0x20,%al
  401d9c:	74 f6                	je     401d94 <strtol+0xe>
  401d9e:	3c 09                	cmp    $0x9,%al
  401da0:	74 f2                	je     401d94 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
  401da2:	3c 2b                	cmp    $0x2b,%al
  401da4:	74 2e                	je     401dd4 <strtol+0x4e>
	int neg = 0;
  401da6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
  401dab:	3c 2d                	cmp    $0x2d,%al
  401dad:	74 2f                	je     401dde <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  401daf:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  401db5:	75 05                	jne    401dbc <strtol+0x36>
  401db7:	80 39 30             	cmpb   $0x30,(%ecx)
  401dba:	74 2c                	je     401de8 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  401dbc:	85 db                	test   %ebx,%ebx
  401dbe:	75 0a                	jne    401dca <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  401dc0:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
  401dc5:	80 39 30             	cmpb   $0x30,(%ecx)
  401dc8:	74 28                	je     401df2 <strtol+0x6c>
		base = 10;
  401dca:	b8 00 00 00 00       	mov    $0x0,%eax
  401dcf:	89 5d 10             	mov    %ebx,0x10(%ebp)
  401dd2:	eb 50                	jmp    401e24 <strtol+0x9e>
		s++;
  401dd4:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
  401dd7:	bf 00 00 00 00       	mov    $0x0,%edi
  401ddc:	eb d1                	jmp    401daf <strtol+0x29>
		s++, neg = 1;
  401dde:	83 c1 01             	add    $0x1,%ecx
  401de1:	bf 01 00 00 00       	mov    $0x1,%edi
  401de6:	eb c7                	jmp    401daf <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  401de8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  401dec:	74 0e                	je     401dfc <strtol+0x76>
	else if (base == 0 && s[0] == '0')
  401dee:	85 db                	test   %ebx,%ebx
  401df0:	75 d8                	jne    401dca <strtol+0x44>
		s++, base = 8;
  401df2:	83 c1 01             	add    $0x1,%ecx
  401df5:	bb 08 00 00 00       	mov    $0x8,%ebx
  401dfa:	eb ce                	jmp    401dca <strtol+0x44>
		s += 2, base = 16;
  401dfc:	83 c1 02             	add    $0x2,%ecx
  401dff:	bb 10 00 00 00       	mov    $0x10,%ebx
  401e04:	eb c4                	jmp    401dca <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
  401e06:	8d 72 9f             	lea    -0x61(%edx),%esi
  401e09:	89 f3                	mov    %esi,%ebx
  401e0b:	80 fb 19             	cmp    $0x19,%bl
  401e0e:	77 29                	ja     401e39 <strtol+0xb3>
			dig = *s - 'a' + 10;
  401e10:	0f be d2             	movsbl %dl,%edx
  401e13:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  401e16:	3b 55 10             	cmp    0x10(%ebp),%edx
  401e19:	7d 30                	jge    401e4b <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
  401e1b:	83 c1 01             	add    $0x1,%ecx
  401e1e:	0f af 45 10          	imul   0x10(%ebp),%eax
  401e22:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
  401e24:	0f b6 11             	movzbl (%ecx),%edx
  401e27:	8d 72 d0             	lea    -0x30(%edx),%esi
  401e2a:	89 f3                	mov    %esi,%ebx
  401e2c:	80 fb 09             	cmp    $0x9,%bl
  401e2f:	77 d5                	ja     401e06 <strtol+0x80>
			dig = *s - '0';
  401e31:	0f be d2             	movsbl %dl,%edx
  401e34:	83 ea 30             	sub    $0x30,%edx
  401e37:	eb dd                	jmp    401e16 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
  401e39:	8d 72 bf             	lea    -0x41(%edx),%esi
  401e3c:	89 f3                	mov    %esi,%ebx
  401e3e:	80 fb 19             	cmp    $0x19,%bl
  401e41:	77 08                	ja     401e4b <strtol+0xc5>
			dig = *s - 'A' + 10;
  401e43:	0f be d2             	movsbl %dl,%edx
  401e46:	83 ea 37             	sub    $0x37,%edx
  401e49:	eb cb                	jmp    401e16 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
  401e4b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  401e4f:	74 05                	je     401e56 <strtol+0xd0>
		*endptr = (char *) s;
  401e51:	8b 75 0c             	mov    0xc(%ebp),%esi
  401e54:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
  401e56:	89 c2                	mov    %eax,%edx
  401e58:	f7 da                	neg    %edx
  401e5a:	85 ff                	test   %edi,%edi
  401e5c:	0f 45 c2             	cmovne %edx,%eax
}
  401e5f:	5b                   	pop    %ebx
  401e60:	5e                   	pop    %esi
  401e61:	5f                   	pop    %edi
  401e62:	5d                   	pop    %ebp
  401e63:	c3                   	ret    
  401e64:	66 90                	xchg   %ax,%ax
  401e66:	66 90                	xchg   %ax,%ax
  401e68:	66 90                	xchg   %ax,%ax
  401e6a:	66 90                	xchg   %ax,%ax
  401e6c:	66 90                	xchg   %ax,%ax
  401e6e:	66 90                	xchg   %ax,%ax

00401e70 <__udivdi3>:
  401e70:	55                   	push   %ebp
  401e71:	57                   	push   %edi
  401e72:	56                   	push   %esi
  401e73:	53                   	push   %ebx
  401e74:	83 ec 1c             	sub    $0x1c,%esp
  401e77:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  401e7b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
  401e7f:	8b 74 24 34          	mov    0x34(%esp),%esi
  401e83:	8b 5c 24 38          	mov    0x38(%esp),%ebx
  401e87:	85 d2                	test   %edx,%edx
  401e89:	75 35                	jne    401ec0 <__udivdi3+0x50>
  401e8b:	39 f3                	cmp    %esi,%ebx
  401e8d:	0f 87 bd 00 00 00    	ja     401f50 <__udivdi3+0xe0>
  401e93:	85 db                	test   %ebx,%ebx
  401e95:	89 d9                	mov    %ebx,%ecx
  401e97:	75 0b                	jne    401ea4 <__udivdi3+0x34>
  401e99:	b8 01 00 00 00       	mov    $0x1,%eax
  401e9e:	31 d2                	xor    %edx,%edx
  401ea0:	f7 f3                	div    %ebx
  401ea2:	89 c1                	mov    %eax,%ecx
  401ea4:	31 d2                	xor    %edx,%edx
  401ea6:	89 f0                	mov    %esi,%eax
  401ea8:	f7 f1                	div    %ecx
  401eaa:	89 c6                	mov    %eax,%esi
  401eac:	89 e8                	mov    %ebp,%eax
  401eae:	89 f7                	mov    %esi,%edi
  401eb0:	f7 f1                	div    %ecx
  401eb2:	89 fa                	mov    %edi,%edx
  401eb4:	83 c4 1c             	add    $0x1c,%esp
  401eb7:	5b                   	pop    %ebx
  401eb8:	5e                   	pop    %esi
  401eb9:	5f                   	pop    %edi
  401eba:	5d                   	pop    %ebp
  401ebb:	c3                   	ret    
  401ebc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  401ec0:	39 f2                	cmp    %esi,%edx
  401ec2:	77 7c                	ja     401f40 <__udivdi3+0xd0>
  401ec4:	0f bd fa             	bsr    %edx,%edi
  401ec7:	83 f7 1f             	xor    $0x1f,%edi
  401eca:	0f 84 98 00 00 00    	je     401f68 <__udivdi3+0xf8>
  401ed0:	89 f9                	mov    %edi,%ecx
  401ed2:	b8 20 00 00 00       	mov    $0x20,%eax
  401ed7:	29 f8                	sub    %edi,%eax
  401ed9:	d3 e2                	shl    %cl,%edx
  401edb:	89 54 24 08          	mov    %edx,0x8(%esp)
  401edf:	89 c1                	mov    %eax,%ecx
  401ee1:	89 da                	mov    %ebx,%edx
  401ee3:	d3 ea                	shr    %cl,%edx
  401ee5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
  401ee9:	09 d1                	or     %edx,%ecx
  401eeb:	89 f2                	mov    %esi,%edx
  401eed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  401ef1:	89 f9                	mov    %edi,%ecx
  401ef3:	d3 e3                	shl    %cl,%ebx
  401ef5:	89 c1                	mov    %eax,%ecx
  401ef7:	d3 ea                	shr    %cl,%edx
  401ef9:	89 f9                	mov    %edi,%ecx
  401efb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  401eff:	d3 e6                	shl    %cl,%esi
  401f01:	89 eb                	mov    %ebp,%ebx
  401f03:	89 c1                	mov    %eax,%ecx
  401f05:	d3 eb                	shr    %cl,%ebx
  401f07:	09 de                	or     %ebx,%esi
  401f09:	89 f0                	mov    %esi,%eax
  401f0b:	f7 74 24 08          	divl   0x8(%esp)
  401f0f:	89 d6                	mov    %edx,%esi
  401f11:	89 c3                	mov    %eax,%ebx
  401f13:	f7 64 24 0c          	mull   0xc(%esp)
  401f17:	39 d6                	cmp    %edx,%esi
  401f19:	72 0c                	jb     401f27 <__udivdi3+0xb7>
  401f1b:	89 f9                	mov    %edi,%ecx
  401f1d:	d3 e5                	shl    %cl,%ebp
  401f1f:	39 c5                	cmp    %eax,%ebp
  401f21:	73 5d                	jae    401f80 <__udivdi3+0x110>
  401f23:	39 d6                	cmp    %edx,%esi
  401f25:	75 59                	jne    401f80 <__udivdi3+0x110>
  401f27:	8d 43 ff             	lea    -0x1(%ebx),%eax
  401f2a:	31 ff                	xor    %edi,%edi
  401f2c:	89 fa                	mov    %edi,%edx
  401f2e:	83 c4 1c             	add    $0x1c,%esp
  401f31:	5b                   	pop    %ebx
  401f32:	5e                   	pop    %esi
  401f33:	5f                   	pop    %edi
  401f34:	5d                   	pop    %ebp
  401f35:	c3                   	ret    
  401f36:	8d 76 00             	lea    0x0(%esi),%esi
  401f39:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
  401f40:	31 ff                	xor    %edi,%edi
  401f42:	31 c0                	xor    %eax,%eax
  401f44:	89 fa                	mov    %edi,%edx
  401f46:	83 c4 1c             	add    $0x1c,%esp
  401f49:	5b                   	pop    %ebx
  401f4a:	5e                   	pop    %esi
  401f4b:	5f                   	pop    %edi
  401f4c:	5d                   	pop    %ebp
  401f4d:	c3                   	ret    
  401f4e:	66 90                	xchg   %ax,%ax
  401f50:	31 ff                	xor    %edi,%edi
  401f52:	89 e8                	mov    %ebp,%eax
  401f54:	89 f2                	mov    %esi,%edx
  401f56:	f7 f3                	div    %ebx
  401f58:	89 fa                	mov    %edi,%edx
  401f5a:	83 c4 1c             	add    $0x1c,%esp
  401f5d:	5b                   	pop    %ebx
  401f5e:	5e                   	pop    %esi
  401f5f:	5f                   	pop    %edi
  401f60:	5d                   	pop    %ebp
  401f61:	c3                   	ret    
  401f62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  401f68:	39 f2                	cmp    %esi,%edx
  401f6a:	72 06                	jb     401f72 <__udivdi3+0x102>
  401f6c:	31 c0                	xor    %eax,%eax
  401f6e:	39 eb                	cmp    %ebp,%ebx
  401f70:	77 d2                	ja     401f44 <__udivdi3+0xd4>
  401f72:	b8 01 00 00 00       	mov    $0x1,%eax
  401f77:	eb cb                	jmp    401f44 <__udivdi3+0xd4>
  401f79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  401f80:	89 d8                	mov    %ebx,%eax
  401f82:	31 ff                	xor    %edi,%edi
  401f84:	eb be                	jmp    401f44 <__udivdi3+0xd4>
  401f86:	66 90                	xchg   %ax,%ax
  401f88:	66 90                	xchg   %ax,%ax
  401f8a:	66 90                	xchg   %ax,%ax
  401f8c:	66 90                	xchg   %ax,%ax
  401f8e:	66 90                	xchg   %ax,%ax

00401f90 <__umoddi3>:
  401f90:	55                   	push   %ebp
  401f91:	57                   	push   %edi
  401f92:	56                   	push   %esi
  401f93:	53                   	push   %ebx
  401f94:	83 ec 1c             	sub    $0x1c,%esp
  401f97:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
  401f9b:	8b 74 24 30          	mov    0x30(%esp),%esi
  401f9f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
  401fa3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  401fa7:	85 ed                	test   %ebp,%ebp
  401fa9:	89 f0                	mov    %esi,%eax
  401fab:	89 da                	mov    %ebx,%edx
  401fad:	75 19                	jne    401fc8 <__umoddi3+0x38>
  401faf:	39 df                	cmp    %ebx,%edi
  401fb1:	0f 86 b1 00 00 00    	jbe    402068 <__umoddi3+0xd8>
  401fb7:	f7 f7                	div    %edi
  401fb9:	89 d0                	mov    %edx,%eax
  401fbb:	31 d2                	xor    %edx,%edx
  401fbd:	83 c4 1c             	add    $0x1c,%esp
  401fc0:	5b                   	pop    %ebx
  401fc1:	5e                   	pop    %esi
  401fc2:	5f                   	pop    %edi
  401fc3:	5d                   	pop    %ebp
  401fc4:	c3                   	ret    
  401fc5:	8d 76 00             	lea    0x0(%esi),%esi
  401fc8:	39 dd                	cmp    %ebx,%ebp
  401fca:	77 f1                	ja     401fbd <__umoddi3+0x2d>
  401fcc:	0f bd cd             	bsr    %ebp,%ecx
  401fcf:	83 f1 1f             	xor    $0x1f,%ecx
  401fd2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  401fd6:	0f 84 b4 00 00 00    	je     402090 <__umoddi3+0x100>
  401fdc:	b8 20 00 00 00       	mov    $0x20,%eax
  401fe1:	89 c2                	mov    %eax,%edx
  401fe3:	8b 44 24 04          	mov    0x4(%esp),%eax
  401fe7:	29 c2                	sub    %eax,%edx
  401fe9:	89 c1                	mov    %eax,%ecx
  401feb:	89 f8                	mov    %edi,%eax
  401fed:	d3 e5                	shl    %cl,%ebp
  401fef:	89 d1                	mov    %edx,%ecx
  401ff1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  401ff5:	d3 e8                	shr    %cl,%eax
  401ff7:	09 c5                	or     %eax,%ebp
  401ff9:	8b 44 24 04          	mov    0x4(%esp),%eax
  401ffd:	89 c1                	mov    %eax,%ecx
  401fff:	d3 e7                	shl    %cl,%edi
  402001:	89 d1                	mov    %edx,%ecx
  402003:	89 7c 24 08          	mov    %edi,0x8(%esp)
  402007:	89 df                	mov    %ebx,%edi
  402009:	d3 ef                	shr    %cl,%edi
  40200b:	89 c1                	mov    %eax,%ecx
  40200d:	89 f0                	mov    %esi,%eax
  40200f:	d3 e3                	shl    %cl,%ebx
  402011:	89 d1                	mov    %edx,%ecx
  402013:	89 fa                	mov    %edi,%edx
  402015:	d3 e8                	shr    %cl,%eax
  402017:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  40201c:	09 d8                	or     %ebx,%eax
  40201e:	f7 f5                	div    %ebp
  402020:	d3 e6                	shl    %cl,%esi
  402022:	89 d1                	mov    %edx,%ecx
  402024:	f7 64 24 08          	mull   0x8(%esp)
  402028:	39 d1                	cmp    %edx,%ecx
  40202a:	89 c3                	mov    %eax,%ebx
  40202c:	89 d7                	mov    %edx,%edi
  40202e:	72 06                	jb     402036 <__umoddi3+0xa6>
  402030:	75 0e                	jne    402040 <__umoddi3+0xb0>
  402032:	39 c6                	cmp    %eax,%esi
  402034:	73 0a                	jae    402040 <__umoddi3+0xb0>
  402036:	2b 44 24 08          	sub    0x8(%esp),%eax
  40203a:	19 ea                	sbb    %ebp,%edx
  40203c:	89 d7                	mov    %edx,%edi
  40203e:	89 c3                	mov    %eax,%ebx
  402040:	89 ca                	mov    %ecx,%edx
  402042:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
  402047:	29 de                	sub    %ebx,%esi
  402049:	19 fa                	sbb    %edi,%edx
  40204b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
  40204f:	89 d0                	mov    %edx,%eax
  402051:	d3 e0                	shl    %cl,%eax
  402053:	89 d9                	mov    %ebx,%ecx
  402055:	d3 ee                	shr    %cl,%esi
  402057:	d3 ea                	shr    %cl,%edx
  402059:	09 f0                	or     %esi,%eax
  40205b:	83 c4 1c             	add    $0x1c,%esp
  40205e:	5b                   	pop    %ebx
  40205f:	5e                   	pop    %esi
  402060:	5f                   	pop    %edi
  402061:	5d                   	pop    %ebp
  402062:	c3                   	ret    
  402063:	90                   	nop
  402064:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  402068:	85 ff                	test   %edi,%edi
  40206a:	89 f9                	mov    %edi,%ecx
  40206c:	75 0b                	jne    402079 <__umoddi3+0xe9>
  40206e:	b8 01 00 00 00       	mov    $0x1,%eax
  402073:	31 d2                	xor    %edx,%edx
  402075:	f7 f7                	div    %edi
  402077:	89 c1                	mov    %eax,%ecx
  402079:	89 d8                	mov    %ebx,%eax
  40207b:	31 d2                	xor    %edx,%edx
  40207d:	f7 f1                	div    %ecx
  40207f:	89 f0                	mov    %esi,%eax
  402081:	f7 f1                	div    %ecx
  402083:	e9 31 ff ff ff       	jmp    401fb9 <__umoddi3+0x29>
  402088:	90                   	nop
  402089:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  402090:	39 dd                	cmp    %ebx,%ebp
  402092:	72 08                	jb     40209c <__umoddi3+0x10c>
  402094:	39 f7                	cmp    %esi,%edi
  402096:	0f 87 21 ff ff ff    	ja     401fbd <__umoddi3+0x2d>
  40209c:	89 da                	mov    %ebx,%edx
  40209e:	89 f0                	mov    %esi,%eax
  4020a0:	29 f8                	sub    %edi,%eax
  4020a2:	19 ea                	sbb    %ebp,%edx
  4020a4:	e9 14 ff ff ff       	jmp    401fbd <__umoddi3+0x2d>
