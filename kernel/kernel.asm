
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	ca478793          	addi	a5,a5,-860 # 80005d00 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e7478793          	addi	a5,a5,-396 # 80000f1a <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b64080e7          	jalr	-1180(ra) # 80000c70 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	460080e7          	jalr	1120(ra) # 80002586 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	796080e7          	jalr	1942(ra) # 800008cc <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bd6080e7          	jalr	-1066(ra) # 80000d24 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	ad4080e7          	jalr	-1324(ra) # 80000c70 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	8f8080e7          	jalr	-1800(ra) # 80001ac2 <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	0fc080e7          	jalr	252(ra) # 800022d6 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	31a080e7          	jalr	794(ra) # 80002530 <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	af2080e7          	jalr	-1294(ra) # 80000d24 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	adc080e7          	jalr	-1316(ra) # 80000d24 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	55e080e7          	jalr	1374(ra) # 800007ee <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	54c080e7          	jalr	1356(ra) # 800007ee <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	540080e7          	jalr	1344(ra) # 800007ee <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	536080e7          	jalr	1334(ra) # 800007ee <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	998080e7          	jalr	-1640(ra) # 80000c70 <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	2e6080e7          	jalr	742(ra) # 800025dc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	a1e080e7          	jalr	-1506(ra) # 80000d24 <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	00c080e7          	jalr	12(ra) # 80002456 <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	774080e7          	jalr	1908(ra) # 80000be0 <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	32a080e7          	jalr	810(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00241797          	auipc	a5,0x241
    80000480:	53478793          	addi	a5,a5,1332 # 802419b0 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b8260613          	addi	a2,a2,-1150 # 80008040 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ac250513          	addi	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b5850513          	addi	a0,a0,-1192 # 800080c8 <digits+0x88>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	addi	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	addi	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	addi	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a56b0b13          	addi	s6,s6,-1450 # 80008040 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	66c080e7          	jalr	1644(ra) # 80000c70 <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	addi	a0,a0,-1510 # 80008028 <etext+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c62080e7          	jalr	-926(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addiw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addiw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e32080e7          	jalr	-462(ra) # 800004a0 <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	addi	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0e080e7          	jalr	-498(ra) # 800004a0 <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	addi	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bd0080e7          	jalr	-1072(ra) # 80000280 <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc4080e7          	jalr	-1084(ra) # 80000280 <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srli	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb0080e7          	jalr	-1104(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	slli	s2,s2,0x4
    800006da:	34fd                	addiw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b8a080e7          	jalr	-1142(ra) # 80000280 <consputc>
      for(; *s; s++)
    800006fe:	0485                	addi	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	91848493          	addi	s1,s1,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b68080e7          	jalr	-1176(ra) # 80000280 <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5c080e7          	jalr	-1188(ra) # 80000280 <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b52080e7          	jalr	-1198(ra) # 80000280 <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	5c2080e7          	jalr	1474(ra) # 80000d24 <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	458080e7          	jalr	1112(ra) # 80000be0 <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079e:	1141                	addi	sp,sp,-16
    800007a0:	e406                	sd	ra,8(sp)
    800007a2:	e022                	sd	s0,0(sp)
    800007a4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a6:	100007b7          	lui	a5,0x10000
    800007aa:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ae:	f8000713          	li	a4,-128
    800007b2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b6:	470d                	li	a4,3
    800007b8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007bc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c4:	469d                	li	a3,7
    800007c6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ca:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ce:	00008597          	auipc	a1,0x8
    800007d2:	88a58593          	addi	a1,a1,-1910 # 80008058 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	addi	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	402080e7          	jalr	1026(ra) # 80000be0 <initlock>
}
    800007e6:	60a2                	ld	ra,8(sp)
    800007e8:	6402                	ld	s0,0(sp)
    800007ea:	0141                	addi	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ee:	1101                	addi	sp,sp,-32
    800007f0:	ec06                	sd	ra,24(sp)
    800007f2:	e822                	sd	s0,16(sp)
    800007f4:	e426                	sd	s1,8(sp)
    800007f6:	1000                	addi	s0,sp,32
    800007f8:	84aa                	mv	s1,a0
  push_off();
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	42a080e7          	jalr	1066(ra) # 80000c24 <push_off>

  if(panicked){
    80000802:	00008797          	auipc	a5,0x8
    80000806:	7fe7a783          	lw	a5,2046(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080e:	c391                	beqz	a5,80000812 <uartputc_sync+0x24>
    for(;;)
    80000810:	a001                	j	80000810 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000816:	0207f793          	andi	a5,a5,32
    8000081a:	dfe5                	beqz	a5,80000812 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081c:	0ff4f513          	andi	a0,s1,255
    80000820:	100007b7          	lui	a5,0x10000
    80000824:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	49c080e7          	jalr	1180(ra) # 80000cc4 <pop_off>
}
    80000830:	60e2                	ld	ra,24(sp)
    80000832:	6442                	ld	s0,16(sp)
    80000834:	64a2                	ld	s1,8(sp)
    80000836:	6105                	addi	sp,sp,32
    80000838:	8082                	ret

000000008000083a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7ca7a783          	lw	a5,1994(a5) # 80009004 <uart_tx_r>
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c672703          	lw	a4,1990(a4) # 80009008 <uart_tx_w>
    8000084a:	08f70063          	beq	a4,a5,800008ca <uartstart+0x90>
{
    8000084e:	7139                	addi	sp,sp,-64
    80000850:	fc06                	sd	ra,56(sp)
    80000852:	f822                	sd	s0,48(sp)
    80000854:	f426                	sd	s1,40(sp)
    80000856:	f04a                	sd	s2,32(sp)
    80000858:	ec4e                	sd	s3,24(sp)
    8000085a:	e852                	sd	s4,16(sp)
    8000085c:	e456                	sd	s5,8(sp)
    8000085e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000860:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000864:	00011a97          	auipc	s5,0x11
    80000868:	094a8a93          	addi	s5,s5,148 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086c:	00008497          	auipc	s1,0x8
    80000870:	79848493          	addi	s1,s1,1944 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000874:	00008a17          	auipc	s4,0x8
    80000878:	794a0a13          	addi	s4,s4,1940 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000880:	02077713          	andi	a4,a4,32
    80000884:	cb15                	beqz	a4,800008b8 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000886:	00fa8733          	add	a4,s5,a5
    8000088a:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088e:	2785                	addiw	a5,a5,1
    80000890:	41f7d71b          	sraiw	a4,a5,0x1f
    80000894:	01b7571b          	srliw	a4,a4,0x1b
    80000898:	9fb9                	addw	a5,a5,a4
    8000089a:	8bfd                	andi	a5,a5,31
    8000089c:	9f99                	subw	a5,a5,a4
    8000089e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	bb4080e7          	jalr	-1100(ra) # 80002456 <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	409c                	lw	a5,0(s1)
    800008b0:	000a2703          	lw	a4,0(s4)
    800008b4:	fcf714e3          	bne	a4,a5,8000087c <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	01a50513          	addi	a0,a0,26 # 800118f8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	38a080e7          	jalr	906(ra) # 80000c70 <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fa:	00008697          	auipc	a3,0x8
    800008fe:	70e6a683          	lw	a3,1806(a3) # 80009008 <uart_tx_w>
    80000902:	0016879b          	addiw	a5,a3,1
    80000906:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090a:	01b7571b          	srliw	a4,a4,0x1b
    8000090e:	9fb9                	addw	a5,a5,a4
    80000910:	8bfd                	andi	a5,a5,31
    80000912:	9f99                	subw	a5,a5,a4
    80000914:	00008717          	auipc	a4,0x8
    80000918:	6f072703          	lw	a4,1776(a4) # 80009004 <uart_tx_r>
    8000091c:	04f71363          	bne	a4,a5,80000962 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000920:	00011a17          	auipc	s4,0x11
    80000924:	fd8a0a13          	addi	s4,s4,-40 # 800118f8 <uart_tx_lock>
    80000928:	00008917          	auipc	s2,0x8
    8000092c:	6dc90913          	addi	s2,s2,1756 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000930:	00008997          	auipc	s3,0x8
    80000934:	6d898993          	addi	s3,s3,1752 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000938:	85d2                	mv	a1,s4
    8000093a:	854a                	mv	a0,s2
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	99a080e7          	jalr	-1638(ra) # 800022d6 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	0009a683          	lw	a3,0(s3)
    80000948:	0016879b          	addiw	a5,a3,1
    8000094c:	41f7d71b          	sraiw	a4,a5,0x1f
    80000950:	01b7571b          	srliw	a4,a4,0x1b
    80000954:	9fb9                	addw	a5,a5,a4
    80000956:	8bfd                	andi	a5,a5,31
    80000958:	9f99                	subw	a5,a5,a4
    8000095a:	00092703          	lw	a4,0(s2)
    8000095e:	fcf70de3          	beq	a4,a5,80000938 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000962:	00011917          	auipc	s2,0x11
    80000966:	f9690913          	addi	s2,s2,-106 # 800118f8 <uart_tx_lock>
    8000096a:	96ca                	add	a3,a3,s2
    8000096c:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000970:	00008717          	auipc	a4,0x8
    80000974:	68f72c23          	sw	a5,1688(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	ec2080e7          	jalr	-318(ra) # 8000083a <uartstart>
      release(&uart_tx_lock);
    80000980:	854a                	mv	a0,s2
    80000982:	00000097          	auipc	ra,0x0
    80000986:	3a2080e7          	jalr	930(ra) # 80000d24 <release>
}
    8000098a:	70a2                	ld	ra,40(sp)
    8000098c:	7402                	ld	s0,32(sp)
    8000098e:	64e2                	ld	s1,24(sp)
    80000990:	6942                	ld	s2,16(sp)
    80000992:	69a2                	ld	s3,8(sp)
    80000994:	6a02                	ld	s4,0(sp)
    80000996:	6145                	addi	sp,sp,48
    80000998:	8082                	ret

000000008000099a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099a:	1141                	addi	sp,sp,-16
    8000099c:	e422                	sd	s0,8(sp)
    8000099e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a8:	8b85                	andi	a5,a5,1
    800009aa:	cb91                	beqz	a5,800009be <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009ac:	100007b7          	lui	a5,0x10000
    800009b0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1e>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f2080e7          	jalr	-1806(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc2080e7          	jalr	-62(ra) # 8000099a <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	282080e7          	jalr	642(ra) # 80000c70 <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e44080e7          	jalr	-444(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	324080e7          	jalr	804(ra) # 80000d24 <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	e3b1                	bnez	a5,80000a66 <kfree+0x54>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00245797          	auipc	a5,0x245
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80246000 <end>
    80000a2e:	02f56c63          	bltu	a0,a5,80000a66 <kfree+0x54>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	02f57863          	bgeu	a0,a5,80000a66 <kfree+0x54>
    panic("kfree");

  ref[(uint64)pa/PGSIZE]--;
    80000a3a:	00c55793          	srli	a5,a0,0xc
    80000a3e:	00279713          	slli	a4,a5,0x2
    80000a42:	00011797          	auipc	a5,0x11
    80000a46:	f0e78793          	addi	a5,a5,-242 # 80011950 <ref>
    80000a4a:	97ba                	add	a5,a5,a4
    80000a4c:	4398                	lw	a4,0(a5)
    80000a4e:	377d                	addiw	a4,a4,-1
    80000a50:	0007069b          	sext.w	a3,a4
    80000a54:	c398                	sw	a4,0(a5)
  if(ref[(uint64)pa/PGSIZE]>0)
    80000a56:	02d05063          	blez	a3,80000a76 <kfree+0x64>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000a5a:	60e2                	ld	ra,24(sp)
    80000a5c:	6442                	ld	s0,16(sp)
    80000a5e:	64a2                	ld	s1,8(sp)
    80000a60:	6902                	ld	s2,0(sp)
    80000a62:	6105                	addi	sp,sp,32
    80000a64:	8082                	ret
    panic("kfree");
    80000a66:	00007517          	auipc	a0,0x7
    80000a6a:	5fa50513          	addi	a0,a0,1530 # 80008060 <digits+0x20>
    80000a6e:	00000097          	auipc	ra,0x0
    80000a72:	ad4080e7          	jalr	-1324(ra) # 80000542 <panic>
  memset(pa, 1, PGSIZE);
    80000a76:	6605                	lui	a2,0x1
    80000a78:	4585                	li	a1,1
    80000a7a:	00000097          	auipc	ra,0x0
    80000a7e:	2f2080e7          	jalr	754(ra) # 80000d6c <memset>
  acquire(&kmem.lock);
    80000a82:	00011917          	auipc	s2,0x11
    80000a86:	eae90913          	addi	s2,s2,-338 # 80011930 <kmem>
    80000a8a:	854a                	mv	a0,s2
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	1e4080e7          	jalr	484(ra) # 80000c70 <acquire>
  r->next = kmem.freelist;
    80000a94:	01893783          	ld	a5,24(s2)
    80000a98:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a9a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a9e:	854a                	mv	a0,s2
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	284080e7          	jalr	644(ra) # 80000d24 <release>
    80000aa8:	bf4d                	j	80000a5a <kfree+0x48>

0000000080000aaa <freerange>:
{
    80000aaa:	7139                	addi	sp,sp,-64
    80000aac:	fc06                	sd	ra,56(sp)
    80000aae:	f822                	sd	s0,48(sp)
    80000ab0:	f426                	sd	s1,40(sp)
    80000ab2:	f04a                	sd	s2,32(sp)
    80000ab4:	ec4e                	sd	s3,24(sp)
    80000ab6:	e852                	sd	s4,16(sp)
    80000ab8:	e456                	sd	s5,8(sp)
    80000aba:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000abc:	6785                	lui	a5,0x1
    80000abe:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ac2:	9526                	add	a0,a0,s1
    80000ac4:	74fd                	lui	s1,0xfffff
    80000ac6:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac8:	97a6                	add	a5,a5,s1
    80000aca:	02f5e963          	bltu	a1,a5,80000afc <freerange+0x52>
    80000ace:	892e                	mv	s2,a1
    ref[(uint64)p/PGSIZE]=0;
    80000ad0:	00011a97          	auipc	s5,0x11
    80000ad4:	e80a8a93          	addi	s5,s5,-384 # 80011950 <ref>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad8:	6a05                	lui	s4,0x1
    80000ada:	6989                	lui	s3,0x2
    ref[(uint64)p/PGSIZE]=0;
    80000adc:	00c4d793          	srli	a5,s1,0xc
    80000ae0:	078a                	slli	a5,a5,0x2
    80000ae2:	97d6                	add	a5,a5,s5
    80000ae4:	0007a023          	sw	zero,0(a5)
    kfree(p);
    80000ae8:	8526                	mv	a0,s1
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f28080e7          	jalr	-216(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af2:	87a6                	mv	a5,s1
    80000af4:	94d2                	add	s1,s1,s4
    80000af6:	97ce                	add	a5,a5,s3
    80000af8:	fef972e3          	bgeu	s2,a5,80000adc <freerange+0x32>
}
    80000afc:	70e2                	ld	ra,56(sp)
    80000afe:	7442                	ld	s0,48(sp)
    80000b00:	74a2                	ld	s1,40(sp)
    80000b02:	7902                	ld	s2,32(sp)
    80000b04:	69e2                	ld	s3,24(sp)
    80000b06:	6a42                	ld	s4,16(sp)
    80000b08:	6aa2                	ld	s5,8(sp)
    80000b0a:	6121                	addi	sp,sp,64
    80000b0c:	8082                	ret

0000000080000b0e <kinit>:
{
    80000b0e:	1141                	addi	sp,sp,-16
    80000b10:	e406                	sd	ra,8(sp)
    80000b12:	e022                	sd	s0,0(sp)
    80000b14:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b16:	00007597          	auipc	a1,0x7
    80000b1a:	55258593          	addi	a1,a1,1362 # 80008068 <digits+0x28>
    80000b1e:	00011517          	auipc	a0,0x11
    80000b22:	e1250513          	addi	a0,a0,-494 # 80011930 <kmem>
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	0ba080e7          	jalr	186(ra) # 80000be0 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b2e:	45c5                	li	a1,17
    80000b30:	05ee                	slli	a1,a1,0x1b
    80000b32:	00245517          	auipc	a0,0x245
    80000b36:	4ce50513          	addi	a0,a0,1230 # 80246000 <end>
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	f70080e7          	jalr	-144(ra) # 80000aaa <freerange>
}
    80000b42:	60a2                	ld	ra,8(sp)
    80000b44:	6402                	ld	s0,0(sp)
    80000b46:	0141                	addi	sp,sp,16
    80000b48:	8082                	ret

0000000080000b4a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b4a:	1101                	addi	sp,sp,-32
    80000b4c:	ec06                	sd	ra,24(sp)
    80000b4e:	e822                	sd	s0,16(sp)
    80000b50:	e426                	sd	s1,8(sp)
    80000b52:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b54:	00011497          	auipc	s1,0x11
    80000b58:	ddc48493          	addi	s1,s1,-548 # 80011930 <kmem>
    80000b5c:	8526                	mv	a0,s1
    80000b5e:	00000097          	auipc	ra,0x0
    80000b62:	112080e7          	jalr	274(ra) # 80000c70 <acquire>
  r = kmem.freelist;
    80000b66:	6c84                	ld	s1,24(s1)
  if(r)
    80000b68:	c0b9                	beqz	s1,80000bae <kalloc+0x64>
  {
    kmem.freelist = r->next;
    80000b6a:	609c                	ld	a5,0(s1)
    80000b6c:	00011517          	auipc	a0,0x11
    80000b70:	dc450513          	addi	a0,a0,-572 # 80011930 <kmem>
    80000b74:	ed1c                	sd	a5,24(a0)
    ref[(uint64)r/PGSIZE]=1;
    80000b76:	00c4d793          	srli	a5,s1,0xc
    80000b7a:	00279713          	slli	a4,a5,0x2
    80000b7e:	00011797          	auipc	a5,0x11
    80000b82:	dd278793          	addi	a5,a5,-558 # 80011950 <ref>
    80000b86:	97ba                	add	a5,a5,a4
    80000b88:	4705                	li	a4,1
    80000b8a:	c398                	sw	a4,0(a5)
  }
  release(&kmem.lock);
    80000b8c:	00000097          	auipc	ra,0x0
    80000b90:	198080e7          	jalr	408(ra) # 80000d24 <release>

  if(r)
  {
     memset((char*)r, 5, PGSIZE); // fill with junk
    80000b94:	6605                	lui	a2,0x1
    80000b96:	4595                	li	a1,5
    80000b98:	8526                	mv	a0,s1
    80000b9a:	00000097          	auipc	ra,0x0
    80000b9e:	1d2080e7          	jalr	466(ra) # 80000d6c <memset>
     //ref[(uint64)r/PGSIZE]=1;
  }
  return (void*)r;
}
    80000ba2:	8526                	mv	a0,s1
    80000ba4:	60e2                	ld	ra,24(sp)
    80000ba6:	6442                	ld	s0,16(sp)
    80000ba8:	64a2                	ld	s1,8(sp)
    80000baa:	6105                	addi	sp,sp,32
    80000bac:	8082                	ret
  release(&kmem.lock);
    80000bae:	00011517          	auipc	a0,0x11
    80000bb2:	d8250513          	addi	a0,a0,-638 # 80011930 <kmem>
    80000bb6:	00000097          	auipc	ra,0x0
    80000bba:	16e080e7          	jalr	366(ra) # 80000d24 <release>
  if(r)
    80000bbe:	b7d5                	j	80000ba2 <kalloc+0x58>

0000000080000bc0 <add_ref>:

void
add_ref(uint64 pa)
{
    80000bc0:	1141                	addi	sp,sp,-16
    80000bc2:	e422                	sd	s0,8(sp)
    80000bc4:	0800                	addi	s0,sp,16
  ref[pa/PGSIZE]++;
    80000bc6:	8131                	srli	a0,a0,0xc
    80000bc8:	050a                	slli	a0,a0,0x2
    80000bca:	00011797          	auipc	a5,0x11
    80000bce:	d8678793          	addi	a5,a5,-634 # 80011950 <ref>
    80000bd2:	953e                	add	a0,a0,a5
    80000bd4:	411c                	lw	a5,0(a0)
    80000bd6:	2785                	addiw	a5,a5,1
    80000bd8:	c11c                	sw	a5,0(a0)
  return;
}
    80000bda:	6422                	ld	s0,8(sp)
    80000bdc:	0141                	addi	sp,sp,16
    80000bde:	8082                	ret

0000000080000be0 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000be0:	1141                	addi	sp,sp,-16
    80000be2:	e422                	sd	s0,8(sp)
    80000be4:	0800                	addi	s0,sp,16
  lk->name = name;
    80000be6:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000be8:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bec:	00053823          	sd	zero,16(a0)
}
    80000bf0:	6422                	ld	s0,8(sp)
    80000bf2:	0141                	addi	sp,sp,16
    80000bf4:	8082                	ret

0000000080000bf6 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bf6:	411c                	lw	a5,0(a0)
    80000bf8:	e399                	bnez	a5,80000bfe <holding+0x8>
    80000bfa:	4501                	li	a0,0
  return r;
}
    80000bfc:	8082                	ret
{
    80000bfe:	1101                	addi	sp,sp,-32
    80000c00:	ec06                	sd	ra,24(sp)
    80000c02:	e822                	sd	s0,16(sp)
    80000c04:	e426                	sd	s1,8(sp)
    80000c06:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c08:	6904                	ld	s1,16(a0)
    80000c0a:	00001097          	auipc	ra,0x1
    80000c0e:	e9c080e7          	jalr	-356(ra) # 80001aa6 <mycpu>
    80000c12:	40a48533          	sub	a0,s1,a0
    80000c16:	00153513          	seqz	a0,a0
}
    80000c1a:	60e2                	ld	ra,24(sp)
    80000c1c:	6442                	ld	s0,16(sp)
    80000c1e:	64a2                	ld	s1,8(sp)
    80000c20:	6105                	addi	sp,sp,32
    80000c22:	8082                	ret

0000000080000c24 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c24:	1101                	addi	sp,sp,-32
    80000c26:	ec06                	sd	ra,24(sp)
    80000c28:	e822                	sd	s0,16(sp)
    80000c2a:	e426                	sd	s1,8(sp)
    80000c2c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c2e:	100024f3          	csrr	s1,sstatus
    80000c32:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c36:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c38:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c3c:	00001097          	auipc	ra,0x1
    80000c40:	e6a080e7          	jalr	-406(ra) # 80001aa6 <mycpu>
    80000c44:	5d3c                	lw	a5,120(a0)
    80000c46:	cf89                	beqz	a5,80000c60 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c48:	00001097          	auipc	ra,0x1
    80000c4c:	e5e080e7          	jalr	-418(ra) # 80001aa6 <mycpu>
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	2785                	addiw	a5,a5,1
    80000c54:	dd3c                	sw	a5,120(a0)
}
    80000c56:	60e2                	ld	ra,24(sp)
    80000c58:	6442                	ld	s0,16(sp)
    80000c5a:	64a2                	ld	s1,8(sp)
    80000c5c:	6105                	addi	sp,sp,32
    80000c5e:	8082                	ret
    mycpu()->intena = old;
    80000c60:	00001097          	auipc	ra,0x1
    80000c64:	e46080e7          	jalr	-442(ra) # 80001aa6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c68:	8085                	srli	s1,s1,0x1
    80000c6a:	8885                	andi	s1,s1,1
    80000c6c:	dd64                	sw	s1,124(a0)
    80000c6e:	bfe9                	j	80000c48 <push_off+0x24>

0000000080000c70 <acquire>:
{
    80000c70:	1101                	addi	sp,sp,-32
    80000c72:	ec06                	sd	ra,24(sp)
    80000c74:	e822                	sd	s0,16(sp)
    80000c76:	e426                	sd	s1,8(sp)
    80000c78:	1000                	addi	s0,sp,32
    80000c7a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	fa8080e7          	jalr	-88(ra) # 80000c24 <push_off>
  if(holding(lk))
    80000c84:	8526                	mv	a0,s1
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	f70080e7          	jalr	-144(ra) # 80000bf6 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c8e:	4705                	li	a4,1
  if(holding(lk))
    80000c90:	e115                	bnez	a0,80000cb4 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c92:	87ba                	mv	a5,a4
    80000c94:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c98:	2781                	sext.w	a5,a5
    80000c9a:	ffe5                	bnez	a5,80000c92 <acquire+0x22>
  __sync_synchronize();
    80000c9c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000ca0:	00001097          	auipc	ra,0x1
    80000ca4:	e06080e7          	jalr	-506(ra) # 80001aa6 <mycpu>
    80000ca8:	e888                	sd	a0,16(s1)
}
    80000caa:	60e2                	ld	ra,24(sp)
    80000cac:	6442                	ld	s0,16(sp)
    80000cae:	64a2                	ld	s1,8(sp)
    80000cb0:	6105                	addi	sp,sp,32
    80000cb2:	8082                	ret
    panic("acquire");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3bc50513          	addi	a0,a0,956 # 80008070 <digits+0x30>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	886080e7          	jalr	-1914(ra) # 80000542 <panic>

0000000080000cc4 <pop_off>:

void
pop_off(void)
{
    80000cc4:	1141                	addi	sp,sp,-16
    80000cc6:	e406                	sd	ra,8(sp)
    80000cc8:	e022                	sd	s0,0(sp)
    80000cca:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000ccc:	00001097          	auipc	ra,0x1
    80000cd0:	dda080e7          	jalr	-550(ra) # 80001aa6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cd8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cda:	e78d                	bnez	a5,80000d04 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cdc:	5d3c                	lw	a5,120(a0)
    80000cde:	02f05b63          	blez	a5,80000d14 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ce2:	37fd                	addiw	a5,a5,-1
    80000ce4:	0007871b          	sext.w	a4,a5
    80000ce8:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cea:	eb09                	bnez	a4,80000cfc <pop_off+0x38>
    80000cec:	5d7c                	lw	a5,124(a0)
    80000cee:	c799                	beqz	a5,80000cfc <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cf0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cf4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cf8:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cfc:	60a2                	ld	ra,8(sp)
    80000cfe:	6402                	ld	s0,0(sp)
    80000d00:	0141                	addi	sp,sp,16
    80000d02:	8082                	ret
    panic("pop_off - interruptible");
    80000d04:	00007517          	auipc	a0,0x7
    80000d08:	37450513          	addi	a0,a0,884 # 80008078 <digits+0x38>
    80000d0c:	00000097          	auipc	ra,0x0
    80000d10:	836080e7          	jalr	-1994(ra) # 80000542 <panic>
    panic("pop_off");
    80000d14:	00007517          	auipc	a0,0x7
    80000d18:	37c50513          	addi	a0,a0,892 # 80008090 <digits+0x50>
    80000d1c:	00000097          	auipc	ra,0x0
    80000d20:	826080e7          	jalr	-2010(ra) # 80000542 <panic>

0000000080000d24 <release>:
{
    80000d24:	1101                	addi	sp,sp,-32
    80000d26:	ec06                	sd	ra,24(sp)
    80000d28:	e822                	sd	s0,16(sp)
    80000d2a:	e426                	sd	s1,8(sp)
    80000d2c:	1000                	addi	s0,sp,32
    80000d2e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d30:	00000097          	auipc	ra,0x0
    80000d34:	ec6080e7          	jalr	-314(ra) # 80000bf6 <holding>
    80000d38:	c115                	beqz	a0,80000d5c <release+0x38>
  lk->cpu = 0;
    80000d3a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d3e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d42:	0f50000f          	fence	iorw,ow
    80000d46:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d4a:	00000097          	auipc	ra,0x0
    80000d4e:	f7a080e7          	jalr	-134(ra) # 80000cc4 <pop_off>
}
    80000d52:	60e2                	ld	ra,24(sp)
    80000d54:	6442                	ld	s0,16(sp)
    80000d56:	64a2                	ld	s1,8(sp)
    80000d58:	6105                	addi	sp,sp,32
    80000d5a:	8082                	ret
    panic("release");
    80000d5c:	00007517          	auipc	a0,0x7
    80000d60:	33c50513          	addi	a0,a0,828 # 80008098 <digits+0x58>
    80000d64:	fffff097          	auipc	ra,0xfffff
    80000d68:	7de080e7          	jalr	2014(ra) # 80000542 <panic>

0000000080000d6c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d72:	ca19                	beqz	a2,80000d88 <memset+0x1c>
    80000d74:	87aa                	mv	a5,a0
    80000d76:	1602                	slli	a2,a2,0x20
    80000d78:	9201                	srli	a2,a2,0x20
    80000d7a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d7e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d82:	0785                	addi	a5,a5,1
    80000d84:	fee79de3          	bne	a5,a4,80000d7e <memset+0x12>
  }
  return dst;
}
    80000d88:	6422                	ld	s0,8(sp)
    80000d8a:	0141                	addi	sp,sp,16
    80000d8c:	8082                	ret

0000000080000d8e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d8e:	1141                	addi	sp,sp,-16
    80000d90:	e422                	sd	s0,8(sp)
    80000d92:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d94:	ca05                	beqz	a2,80000dc4 <memcmp+0x36>
    80000d96:	fff6069b          	addiw	a3,a2,-1
    80000d9a:	1682                	slli	a3,a3,0x20
    80000d9c:	9281                	srli	a3,a3,0x20
    80000d9e:	0685                	addi	a3,a3,1
    80000da0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000da2:	00054783          	lbu	a5,0(a0)
    80000da6:	0005c703          	lbu	a4,0(a1)
    80000daa:	00e79863          	bne	a5,a4,80000dba <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000db2:	fed518e3          	bne	a0,a3,80000da2 <memcmp+0x14>
  }

  return 0;
    80000db6:	4501                	li	a0,0
    80000db8:	a019                	j	80000dbe <memcmp+0x30>
      return *s1 - *s2;
    80000dba:	40e7853b          	subw	a0,a5,a4
}
    80000dbe:	6422                	ld	s0,8(sp)
    80000dc0:	0141                	addi	sp,sp,16
    80000dc2:	8082                	ret
  return 0;
    80000dc4:	4501                	li	a0,0
    80000dc6:	bfe5                	j	80000dbe <memcmp+0x30>

0000000080000dc8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dc8:	1141                	addi	sp,sp,-16
    80000dca:	e422                	sd	s0,8(sp)
    80000dcc:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dce:	02a5e563          	bltu	a1,a0,80000df8 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dd2:	fff6069b          	addiw	a3,a2,-1
    80000dd6:	ce11                	beqz	a2,80000df2 <memmove+0x2a>
    80000dd8:	1682                	slli	a3,a3,0x20
    80000dda:	9281                	srli	a3,a3,0x20
    80000ddc:	0685                	addi	a3,a3,1
    80000dde:	96ae                	add	a3,a3,a1
    80000de0:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000de2:	0585                	addi	a1,a1,1
    80000de4:	0785                	addi	a5,a5,1
    80000de6:	fff5c703          	lbu	a4,-1(a1)
    80000dea:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dee:	fed59ae3          	bne	a1,a3,80000de2 <memmove+0x1a>

  return dst;
}
    80000df2:	6422                	ld	s0,8(sp)
    80000df4:	0141                	addi	sp,sp,16
    80000df6:	8082                	ret
  if(s < d && s + n > d){
    80000df8:	02061713          	slli	a4,a2,0x20
    80000dfc:	9301                	srli	a4,a4,0x20
    80000dfe:	00e587b3          	add	a5,a1,a4
    80000e02:	fcf578e3          	bgeu	a0,a5,80000dd2 <memmove+0xa>
    d += n;
    80000e06:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e08:	fff6069b          	addiw	a3,a2,-1
    80000e0c:	d27d                	beqz	a2,80000df2 <memmove+0x2a>
    80000e0e:	02069613          	slli	a2,a3,0x20
    80000e12:	9201                	srli	a2,a2,0x20
    80000e14:	fff64613          	not	a2,a2
    80000e18:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e1a:	17fd                	addi	a5,a5,-1
    80000e1c:	177d                	addi	a4,a4,-1
    80000e1e:	0007c683          	lbu	a3,0(a5)
    80000e22:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e26:	fef61ae3          	bne	a2,a5,80000e1a <memmove+0x52>
    80000e2a:	b7e1                	j	80000df2 <memmove+0x2a>

0000000080000e2c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e2c:	1141                	addi	sp,sp,-16
    80000e2e:	e406                	sd	ra,8(sp)
    80000e30:	e022                	sd	s0,0(sp)
    80000e32:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e34:	00000097          	auipc	ra,0x0
    80000e38:	f94080e7          	jalr	-108(ra) # 80000dc8 <memmove>
}
    80000e3c:	60a2                	ld	ra,8(sp)
    80000e3e:	6402                	ld	s0,0(sp)
    80000e40:	0141                	addi	sp,sp,16
    80000e42:	8082                	ret

0000000080000e44 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e44:	1141                	addi	sp,sp,-16
    80000e46:	e422                	sd	s0,8(sp)
    80000e48:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e4a:	ce11                	beqz	a2,80000e66 <strncmp+0x22>
    80000e4c:	00054783          	lbu	a5,0(a0)
    80000e50:	cf89                	beqz	a5,80000e6a <strncmp+0x26>
    80000e52:	0005c703          	lbu	a4,0(a1)
    80000e56:	00f71a63          	bne	a4,a5,80000e6a <strncmp+0x26>
    n--, p++, q++;
    80000e5a:	367d                	addiw	a2,a2,-1
    80000e5c:	0505                	addi	a0,a0,1
    80000e5e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e60:	f675                	bnez	a2,80000e4c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e62:	4501                	li	a0,0
    80000e64:	a809                	j	80000e76 <strncmp+0x32>
    80000e66:	4501                	li	a0,0
    80000e68:	a039                	j	80000e76 <strncmp+0x32>
  if(n == 0)
    80000e6a:	ca09                	beqz	a2,80000e7c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e6c:	00054503          	lbu	a0,0(a0)
    80000e70:	0005c783          	lbu	a5,0(a1)
    80000e74:	9d1d                	subw	a0,a0,a5
}
    80000e76:	6422                	ld	s0,8(sp)
    80000e78:	0141                	addi	sp,sp,16
    80000e7a:	8082                	ret
    return 0;
    80000e7c:	4501                	li	a0,0
    80000e7e:	bfe5                	j	80000e76 <strncmp+0x32>

0000000080000e80 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e80:	1141                	addi	sp,sp,-16
    80000e82:	e422                	sd	s0,8(sp)
    80000e84:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e86:	872a                	mv	a4,a0
    80000e88:	8832                	mv	a6,a2
    80000e8a:	367d                	addiw	a2,a2,-1
    80000e8c:	01005963          	blez	a6,80000e9e <strncpy+0x1e>
    80000e90:	0705                	addi	a4,a4,1
    80000e92:	0005c783          	lbu	a5,0(a1)
    80000e96:	fef70fa3          	sb	a5,-1(a4)
    80000e9a:	0585                	addi	a1,a1,1
    80000e9c:	f7f5                	bnez	a5,80000e88 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e9e:	86ba                	mv	a3,a4
    80000ea0:	00c05c63          	blez	a2,80000eb8 <strncpy+0x38>
    *s++ = 0;
    80000ea4:	0685                	addi	a3,a3,1
    80000ea6:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000eaa:	fff6c793          	not	a5,a3
    80000eae:	9fb9                	addw	a5,a5,a4
    80000eb0:	010787bb          	addw	a5,a5,a6
    80000eb4:	fef048e3          	bgtz	a5,80000ea4 <strncpy+0x24>
  return os;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ec4:	02c05363          	blez	a2,80000eea <safestrcpy+0x2c>
    80000ec8:	fff6069b          	addiw	a3,a2,-1
    80000ecc:	1682                	slli	a3,a3,0x20
    80000ece:	9281                	srli	a3,a3,0x20
    80000ed0:	96ae                	add	a3,a3,a1
    80000ed2:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ed4:	00d58963          	beq	a1,a3,80000ee6 <safestrcpy+0x28>
    80000ed8:	0585                	addi	a1,a1,1
    80000eda:	0785                	addi	a5,a5,1
    80000edc:	fff5c703          	lbu	a4,-1(a1)
    80000ee0:	fee78fa3          	sb	a4,-1(a5)
    80000ee4:	fb65                	bnez	a4,80000ed4 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ee6:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eea:	6422                	ld	s0,8(sp)
    80000eec:	0141                	addi	sp,sp,16
    80000eee:	8082                	ret

0000000080000ef0 <strlen>:

int
strlen(const char *s)
{
    80000ef0:	1141                	addi	sp,sp,-16
    80000ef2:	e422                	sd	s0,8(sp)
    80000ef4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ef6:	00054783          	lbu	a5,0(a0)
    80000efa:	cf91                	beqz	a5,80000f16 <strlen+0x26>
    80000efc:	0505                	addi	a0,a0,1
    80000efe:	87aa                	mv	a5,a0
    80000f00:	4685                	li	a3,1
    80000f02:	9e89                	subw	a3,a3,a0
    80000f04:	00f6853b          	addw	a0,a3,a5
    80000f08:	0785                	addi	a5,a5,1
    80000f0a:	fff7c703          	lbu	a4,-1(a5)
    80000f0e:	fb7d                	bnez	a4,80000f04 <strlen+0x14>
    ;
  return n;
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f16:	4501                	li	a0,0
    80000f18:	bfe5                	j	80000f10 <strlen+0x20>

0000000080000f1a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f1a:	1141                	addi	sp,sp,-16
    80000f1c:	e406                	sd	ra,8(sp)
    80000f1e:	e022                	sd	s0,0(sp)
    80000f20:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	b74080e7          	jalr	-1164(ra) # 80001a96 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f2a:	00008717          	auipc	a4,0x8
    80000f2e:	0e270713          	addi	a4,a4,226 # 8000900c <started>
  if(cpuid() == 0){
    80000f32:	c139                	beqz	a0,80000f78 <main+0x5e>
    while(started == 0)
    80000f34:	431c                	lw	a5,0(a4)
    80000f36:	2781                	sext.w	a5,a5
    80000f38:	dff5                	beqz	a5,80000f34 <main+0x1a>
      ;
    __sync_synchronize();
    80000f3a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	b58080e7          	jalr	-1192(ra) # 80001a96 <cpuid>
    80000f46:	85aa                	mv	a1,a0
    80000f48:	00007517          	auipc	a0,0x7
    80000f4c:	17050513          	addi	a0,a0,368 # 800080b8 <digits+0x78>
    80000f50:	fffff097          	auipc	ra,0xfffff
    80000f54:	63c080e7          	jalr	1596(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000f58:	00000097          	auipc	ra,0x0
    80000f5c:	0d8080e7          	jalr	216(ra) # 80001030 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f60:	00001097          	auipc	ra,0x1
    80000f64:	7bc080e7          	jalr	1980(ra) # 8000271c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	dd8080e7          	jalr	-552(ra) # 80005d40 <plicinithart>
  }

  scheduler();        
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	086080e7          	jalr	134(ra) # 80001ff6 <scheduler>
    consoleinit();
    80000f78:	fffff097          	auipc	ra,0xfffff
    80000f7c:	4dc080e7          	jalr	1244(ra) # 80000454 <consoleinit>
    printfinit();
    80000f80:	fffff097          	auipc	ra,0xfffff
    80000f84:	7ec080e7          	jalr	2028(ra) # 8000076c <printfinit>
    printf("\n");
    80000f88:	00007517          	auipc	a0,0x7
    80000f8c:	14050513          	addi	a0,a0,320 # 800080c8 <digits+0x88>
    80000f90:	fffff097          	auipc	ra,0xfffff
    80000f94:	5fc080e7          	jalr	1532(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80000f98:	00007517          	auipc	a0,0x7
    80000f9c:	10850513          	addi	a0,a0,264 # 800080a0 <digits+0x60>
    80000fa0:	fffff097          	auipc	ra,0xfffff
    80000fa4:	5ec080e7          	jalr	1516(ra) # 8000058c <printf>
    printf("\n");
    80000fa8:	00007517          	auipc	a0,0x7
    80000fac:	12050513          	addi	a0,a0,288 # 800080c8 <digits+0x88>
    80000fb0:	fffff097          	auipc	ra,0xfffff
    80000fb4:	5dc080e7          	jalr	1500(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000fb8:	00000097          	auipc	ra,0x0
    80000fbc:	b56080e7          	jalr	-1194(ra) # 80000b0e <kinit>
    kvminit();       // create kernel page table
    80000fc0:	00000097          	auipc	ra,0x0
    80000fc4:	2a0080e7          	jalr	672(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	068080e7          	jalr	104(ra) # 80001030 <kvminithart>
    procinit();      // process table
    80000fd0:	00001097          	auipc	ra,0x1
    80000fd4:	9f6080e7          	jalr	-1546(ra) # 800019c6 <procinit>
    trapinit();      // trap vectors
    80000fd8:	00001097          	auipc	ra,0x1
    80000fdc:	71c080e7          	jalr	1820(ra) # 800026f4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	73c080e7          	jalr	1852(ra) # 8000271c <trapinithart>
    plicinit();      // set up interrupt controller
    80000fe8:	00005097          	auipc	ra,0x5
    80000fec:	d42080e7          	jalr	-702(ra) # 80005d2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ff0:	00005097          	auipc	ra,0x5
    80000ff4:	d50080e7          	jalr	-688(ra) # 80005d40 <plicinithart>
    binit();         // buffer cache
    80000ff8:	00002097          	auipc	ra,0x2
    80000ffc:	f00080e7          	jalr	-256(ra) # 80002ef8 <binit>
    iinit();         // inode cache
    80001000:	00002097          	auipc	ra,0x2
    80001004:	590080e7          	jalr	1424(ra) # 80003590 <iinit>
    fileinit();      // file table
    80001008:	00003097          	auipc	ra,0x3
    8000100c:	52e080e7          	jalr	1326(ra) # 80004536 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001010:	00005097          	auipc	ra,0x5
    80001014:	e38080e7          	jalr	-456(ra) # 80005e48 <virtio_disk_init>
    userinit();      // first user process
    80001018:	00001097          	auipc	ra,0x1
    8000101c:	d74080e7          	jalr	-652(ra) # 80001d8c <userinit>
    __sync_synchronize();
    80001020:	0ff0000f          	fence
    started = 1;
    80001024:	4785                	li	a5,1
    80001026:	00008717          	auipc	a4,0x8
    8000102a:	fef72323          	sw	a5,-26(a4) # 8000900c <started>
    8000102e:	b789                	j	80000f70 <main+0x56>

0000000080001030 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001030:	1141                	addi	sp,sp,-16
    80001032:	e422                	sd	s0,8(sp)
    80001034:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001036:	00008797          	auipc	a5,0x8
    8000103a:	fda7b783          	ld	a5,-38(a5) # 80009010 <kernel_pagetable>
    8000103e:	83b1                	srli	a5,a5,0xc
    80001040:	577d                	li	a4,-1
    80001042:	177e                	slli	a4,a4,0x3f
    80001044:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001046:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000104a:	12000073          	sfence.vma
  sfence_vma();
}
    8000104e:	6422                	ld	s0,8(sp)
    80001050:	0141                	addi	sp,sp,16
    80001052:	8082                	ret

0000000080001054 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001054:	7139                	addi	sp,sp,-64
    80001056:	fc06                	sd	ra,56(sp)
    80001058:	f822                	sd	s0,48(sp)
    8000105a:	f426                	sd	s1,40(sp)
    8000105c:	f04a                	sd	s2,32(sp)
    8000105e:	ec4e                	sd	s3,24(sp)
    80001060:	e852                	sd	s4,16(sp)
    80001062:	e456                	sd	s5,8(sp)
    80001064:	e05a                	sd	s6,0(sp)
    80001066:	0080                	addi	s0,sp,64
    80001068:	84aa                	mv	s1,a0
    8000106a:	89ae                	mv	s3,a1
    8000106c:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001074:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001076:	04b7f263          	bgeu	a5,a1,800010ba <walk+0x66>
    panic("walk");
    8000107a:	00007517          	auipc	a0,0x7
    8000107e:	05650513          	addi	a0,a0,86 # 800080d0 <digits+0x90>
    80001082:	fffff097          	auipc	ra,0xfffff
    80001086:	4c0080e7          	jalr	1216(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000108a:	060a8663          	beqz	s5,800010f6 <walk+0xa2>
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	abc080e7          	jalr	-1348(ra) # 80000b4a <kalloc>
    80001096:	84aa                	mv	s1,a0
    80001098:	c529                	beqz	a0,800010e2 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000109a:	6605                	lui	a2,0x1
    8000109c:	4581                	li	a1,0
    8000109e:	00000097          	auipc	ra,0x0
    800010a2:	cce080e7          	jalr	-818(ra) # 80000d6c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010a6:	00c4d793          	srli	a5,s1,0xc
    800010aa:	07aa                	slli	a5,a5,0xa
    800010ac:	0017e793          	ori	a5,a5,1
    800010b0:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010b4:	3a5d                	addiw	s4,s4,-9
    800010b6:	036a0063          	beq	s4,s6,800010d6 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010ba:	0149d933          	srl	s2,s3,s4
    800010be:	1ff97913          	andi	s2,s2,511
    800010c2:	090e                	slli	s2,s2,0x3
    800010c4:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010c6:	00093483          	ld	s1,0(s2)
    800010ca:	0014f793          	andi	a5,s1,1
    800010ce:	dfd5                	beqz	a5,8000108a <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010d0:	80a9                	srli	s1,s1,0xa
    800010d2:	04b2                	slli	s1,s1,0xc
    800010d4:	b7c5                	j	800010b4 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010d6:	00c9d513          	srli	a0,s3,0xc
    800010da:	1ff57513          	andi	a0,a0,511
    800010de:	050e                	slli	a0,a0,0x3
    800010e0:	9526                	add	a0,a0,s1
}
    800010e2:	70e2                	ld	ra,56(sp)
    800010e4:	7442                	ld	s0,48(sp)
    800010e6:	74a2                	ld	s1,40(sp)
    800010e8:	7902                	ld	s2,32(sp)
    800010ea:	69e2                	ld	s3,24(sp)
    800010ec:	6a42                	ld	s4,16(sp)
    800010ee:	6aa2                	ld	s5,8(sp)
    800010f0:	6b02                	ld	s6,0(sp)
    800010f2:	6121                	addi	sp,sp,64
    800010f4:	8082                	ret
        return 0;
    800010f6:	4501                	li	a0,0
    800010f8:	b7ed                	j	800010e2 <walk+0x8e>

00000000800010fa <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010fa:	57fd                	li	a5,-1
    800010fc:	83e9                	srli	a5,a5,0x1a
    800010fe:	00b7f463          	bgeu	a5,a1,80001106 <walkaddr+0xc>
    return 0;
    80001102:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001104:	8082                	ret
{
    80001106:	1141                	addi	sp,sp,-16
    80001108:	e406                	sd	ra,8(sp)
    8000110a:	e022                	sd	s0,0(sp)
    8000110c:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000110e:	4601                	li	a2,0
    80001110:	00000097          	auipc	ra,0x0
    80001114:	f44080e7          	jalr	-188(ra) # 80001054 <walk>
  if(pte == 0)
    80001118:	c105                	beqz	a0,80001138 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000111a:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000111c:	0117f693          	andi	a3,a5,17
    80001120:	4745                	li	a4,17
    return 0;
    80001122:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001124:	00e68663          	beq	a3,a4,80001130 <walkaddr+0x36>
}
    80001128:	60a2                	ld	ra,8(sp)
    8000112a:	6402                	ld	s0,0(sp)
    8000112c:	0141                	addi	sp,sp,16
    8000112e:	8082                	ret
  pa = PTE2PA(*pte);
    80001130:	00a7d513          	srli	a0,a5,0xa
    80001134:	0532                	slli	a0,a0,0xc
  return pa;
    80001136:	bfcd                	j	80001128 <walkaddr+0x2e>
    return 0;
    80001138:	4501                	li	a0,0
    8000113a:	b7fd                	j	80001128 <walkaddr+0x2e>

000000008000113c <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000113c:	1101                	addi	sp,sp,-32
    8000113e:	ec06                	sd	ra,24(sp)
    80001140:	e822                	sd	s0,16(sp)
    80001142:	e426                	sd	s1,8(sp)
    80001144:	1000                	addi	s0,sp,32
    80001146:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001148:	1552                	slli	a0,a0,0x34
    8000114a:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000114e:	4601                	li	a2,0
    80001150:	00008517          	auipc	a0,0x8
    80001154:	ec053503          	ld	a0,-320(a0) # 80009010 <kernel_pagetable>
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	efc080e7          	jalr	-260(ra) # 80001054 <walk>
  if(pte == 0)
    80001160:	cd09                	beqz	a0,8000117a <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001162:	6108                	ld	a0,0(a0)
    80001164:	00157793          	andi	a5,a0,1
    80001168:	c38d                	beqz	a5,8000118a <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000116a:	8129                	srli	a0,a0,0xa
    8000116c:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000116e:	9526                	add	a0,a0,s1
    80001170:	60e2                	ld	ra,24(sp)
    80001172:	6442                	ld	s0,16(sp)
    80001174:	64a2                	ld	s1,8(sp)
    80001176:	6105                	addi	sp,sp,32
    80001178:	8082                	ret
    panic("kvmpa");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f5e50513          	addi	a0,a0,-162 # 800080d8 <digits+0x98>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c0080e7          	jalr	960(ra) # 80000542 <panic>
    panic("kvmpa");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f4e50513          	addi	a0,a0,-178 # 800080d8 <digits+0x98>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3b0080e7          	jalr	944(ra) # 80000542 <panic>

000000008000119a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000119a:	715d                	addi	sp,sp,-80
    8000119c:	e486                	sd	ra,72(sp)
    8000119e:	e0a2                	sd	s0,64(sp)
    800011a0:	fc26                	sd	s1,56(sp)
    800011a2:	f84a                	sd	s2,48(sp)
    800011a4:	f44e                	sd	s3,40(sp)
    800011a6:	f052                	sd	s4,32(sp)
    800011a8:	ec56                	sd	s5,24(sp)
    800011aa:	e85a                	sd	s6,16(sp)
    800011ac:	e45e                	sd	s7,8(sp)
    800011ae:	0880                	addi	s0,sp,80
    800011b0:	8aaa                	mv	s5,a0
    800011b2:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011b4:	777d                	lui	a4,0xfffff
    800011b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011ba:	167d                	addi	a2,a2,-1
    800011bc:	00b609b3          	add	s3,a2,a1
    800011c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011c4:	893e                	mv	s2,a5
    800011c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011ca:	6b85                	lui	s7,0x1
    800011cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011d0:	4605                	li	a2,1
    800011d2:	85ca                	mv	a1,s2
    800011d4:	8556                	mv	a0,s5
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	e7e080e7          	jalr	-386(ra) # 80001054 <walk>
    800011de:	c51d                	beqz	a0,8000120c <mappages+0x72>
    if(*pte & PTE_V)
    800011e0:	611c                	ld	a5,0(a0)
    800011e2:	8b85                	andi	a5,a5,1
    800011e4:	ef81                	bnez	a5,800011fc <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011e6:	80b1                	srli	s1,s1,0xc
    800011e8:	04aa                	slli	s1,s1,0xa
    800011ea:	0164e4b3          	or	s1,s1,s6
    800011ee:	0014e493          	ori	s1,s1,1
    800011f2:	e104                	sd	s1,0(a0)
    if(a == last)
    800011f4:	03390863          	beq	s2,s3,80001224 <mappages+0x8a>
    a += PGSIZE;
    800011f8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011fa:	bfc9                	j	800011cc <mappages+0x32>
      panic("remap");
    800011fc:	00007517          	auipc	a0,0x7
    80001200:	ee450513          	addi	a0,a0,-284 # 800080e0 <digits+0xa0>
    80001204:	fffff097          	auipc	ra,0xfffff
    80001208:	33e080e7          	jalr	830(ra) # 80000542 <panic>
      return -1;
    8000120c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000120e:	60a6                	ld	ra,72(sp)
    80001210:	6406                	ld	s0,64(sp)
    80001212:	74e2                	ld	s1,56(sp)
    80001214:	7942                	ld	s2,48(sp)
    80001216:	79a2                	ld	s3,40(sp)
    80001218:	7a02                	ld	s4,32(sp)
    8000121a:	6ae2                	ld	s5,24(sp)
    8000121c:	6b42                	ld	s6,16(sp)
    8000121e:	6ba2                	ld	s7,8(sp)
    80001220:	6161                	addi	sp,sp,80
    80001222:	8082                	ret
  return 0;
    80001224:	4501                	li	a0,0
    80001226:	b7e5                	j	8000120e <mappages+0x74>

0000000080001228 <kvmmap>:
{
    80001228:	1141                	addi	sp,sp,-16
    8000122a:	e406                	sd	ra,8(sp)
    8000122c:	e022                	sd	s0,0(sp)
    8000122e:	0800                	addi	s0,sp,16
    80001230:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001232:	86ae                	mv	a3,a1
    80001234:	85aa                	mv	a1,a0
    80001236:	00008517          	auipc	a0,0x8
    8000123a:	dda53503          	ld	a0,-550(a0) # 80009010 <kernel_pagetable>
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f5c080e7          	jalr	-164(ra) # 8000119a <mappages>
    80001246:	e509                	bnez	a0,80001250 <kvmmap+0x28>
}
    80001248:	60a2                	ld	ra,8(sp)
    8000124a:	6402                	ld	s0,0(sp)
    8000124c:	0141                	addi	sp,sp,16
    8000124e:	8082                	ret
    panic("kvmmap");
    80001250:	00007517          	auipc	a0,0x7
    80001254:	e9850513          	addi	a0,a0,-360 # 800080e8 <digits+0xa8>
    80001258:	fffff097          	auipc	ra,0xfffff
    8000125c:	2ea080e7          	jalr	746(ra) # 80000542 <panic>

0000000080001260 <kvminit>:
{
    80001260:	1101                	addi	sp,sp,-32
    80001262:	ec06                	sd	ra,24(sp)
    80001264:	e822                	sd	s0,16(sp)
    80001266:	e426                	sd	s1,8(sp)
    80001268:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000126a:	00000097          	auipc	ra,0x0
    8000126e:	8e0080e7          	jalr	-1824(ra) # 80000b4a <kalloc>
    80001272:	00008797          	auipc	a5,0x8
    80001276:	d8a7bf23          	sd	a0,-610(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000127a:	6605                	lui	a2,0x1
    8000127c:	4581                	li	a1,0
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	aee080e7          	jalr	-1298(ra) # 80000d6c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001286:	4699                	li	a3,6
    80001288:	6605                	lui	a2,0x1
    8000128a:	100005b7          	lui	a1,0x10000
    8000128e:	10000537          	lui	a0,0x10000
    80001292:	00000097          	auipc	ra,0x0
    80001296:	f96080e7          	jalr	-106(ra) # 80001228 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000129a:	4699                	li	a3,6
    8000129c:	6605                	lui	a2,0x1
    8000129e:	100015b7          	lui	a1,0x10001
    800012a2:	10001537          	lui	a0,0x10001
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	f82080e7          	jalr	-126(ra) # 80001228 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012ae:	4699                	li	a3,6
    800012b0:	6641                	lui	a2,0x10
    800012b2:	020005b7          	lui	a1,0x2000
    800012b6:	02000537          	lui	a0,0x2000
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	f6e080e7          	jalr	-146(ra) # 80001228 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012c2:	4699                	li	a3,6
    800012c4:	00400637          	lui	a2,0x400
    800012c8:	0c0005b7          	lui	a1,0xc000
    800012cc:	0c000537          	lui	a0,0xc000
    800012d0:	00000097          	auipc	ra,0x0
    800012d4:	f58080e7          	jalr	-168(ra) # 80001228 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012d8:	00007497          	auipc	s1,0x7
    800012dc:	d2848493          	addi	s1,s1,-728 # 80008000 <etext>
    800012e0:	46a9                	li	a3,10
    800012e2:	80007617          	auipc	a2,0x80007
    800012e6:	d1e60613          	addi	a2,a2,-738 # 8000 <_entry-0x7fff8000>
    800012ea:	4585                	li	a1,1
    800012ec:	05fe                	slli	a1,a1,0x1f
    800012ee:	852e                	mv	a0,a1
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	f38080e7          	jalr	-200(ra) # 80001228 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012f8:	4699                	li	a3,6
    800012fa:	4645                	li	a2,17
    800012fc:	066e                	slli	a2,a2,0x1b
    800012fe:	8e05                	sub	a2,a2,s1
    80001300:	85a6                	mv	a1,s1
    80001302:	8526                	mv	a0,s1
    80001304:	00000097          	auipc	ra,0x0
    80001308:	f24080e7          	jalr	-220(ra) # 80001228 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000130c:	46a9                	li	a3,10
    8000130e:	6605                	lui	a2,0x1
    80001310:	00006597          	auipc	a1,0x6
    80001314:	cf058593          	addi	a1,a1,-784 # 80007000 <_trampoline>
    80001318:	04000537          	lui	a0,0x4000
    8000131c:	157d                	addi	a0,a0,-1
    8000131e:	0532                	slli	a0,a0,0xc
    80001320:	00000097          	auipc	ra,0x0
    80001324:	f08080e7          	jalr	-248(ra) # 80001228 <kvmmap>
}
    80001328:	60e2                	ld	ra,24(sp)
    8000132a:	6442                	ld	s0,16(sp)
    8000132c:	64a2                	ld	s1,8(sp)
    8000132e:	6105                	addi	sp,sp,32
    80001330:	8082                	ret

0000000080001332 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001332:	715d                	addi	sp,sp,-80
    80001334:	e486                	sd	ra,72(sp)
    80001336:	e0a2                	sd	s0,64(sp)
    80001338:	fc26                	sd	s1,56(sp)
    8000133a:	f84a                	sd	s2,48(sp)
    8000133c:	f44e                	sd	s3,40(sp)
    8000133e:	f052                	sd	s4,32(sp)
    80001340:	ec56                	sd	s5,24(sp)
    80001342:	e85a                	sd	s6,16(sp)
    80001344:	e45e                	sd	s7,8(sp)
    80001346:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001348:	03459793          	slli	a5,a1,0x34
    8000134c:	e795                	bnez	a5,80001378 <uvmunmap+0x46>
    8000134e:	8a2a                	mv	s4,a0
    80001350:	892e                	mv	s2,a1
    80001352:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001354:	0632                	slli	a2,a2,0xc
    80001356:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000135a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000135c:	6b05                	lui	s6,0x1
    8000135e:	0735e263          	bltu	a1,s3,800013c2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001362:	60a6                	ld	ra,72(sp)
    80001364:	6406                	ld	s0,64(sp)
    80001366:	74e2                	ld	s1,56(sp)
    80001368:	7942                	ld	s2,48(sp)
    8000136a:	79a2                	ld	s3,40(sp)
    8000136c:	7a02                	ld	s4,32(sp)
    8000136e:	6ae2                	ld	s5,24(sp)
    80001370:	6b42                	ld	s6,16(sp)
    80001372:	6ba2                	ld	s7,8(sp)
    80001374:	6161                	addi	sp,sp,80
    80001376:	8082                	ret
    panic("uvmunmap: not aligned");
    80001378:	00007517          	auipc	a0,0x7
    8000137c:	d7850513          	addi	a0,a0,-648 # 800080f0 <digits+0xb0>
    80001380:	fffff097          	auipc	ra,0xfffff
    80001384:	1c2080e7          	jalr	450(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    80001388:	00007517          	auipc	a0,0x7
    8000138c:	d8050513          	addi	a0,a0,-640 # 80008108 <digits+0xc8>
    80001390:	fffff097          	auipc	ra,0xfffff
    80001394:	1b2080e7          	jalr	434(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    80001398:	00007517          	auipc	a0,0x7
    8000139c:	d8050513          	addi	a0,a0,-640 # 80008118 <digits+0xd8>
    800013a0:	fffff097          	auipc	ra,0xfffff
    800013a4:	1a2080e7          	jalr	418(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    800013a8:	00007517          	auipc	a0,0x7
    800013ac:	d8850513          	addi	a0,a0,-632 # 80008130 <digits+0xf0>
    800013b0:	fffff097          	auipc	ra,0xfffff
    800013b4:	192080e7          	jalr	402(ra) # 80000542 <panic>
    *pte = 0;
    800013b8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013bc:	995a                	add	s2,s2,s6
    800013be:	fb3972e3          	bgeu	s2,s3,80001362 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013c2:	4601                	li	a2,0
    800013c4:	85ca                	mv	a1,s2
    800013c6:	8552                	mv	a0,s4
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	c8c080e7          	jalr	-884(ra) # 80001054 <walk>
    800013d0:	84aa                	mv	s1,a0
    800013d2:	d95d                	beqz	a0,80001388 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013d4:	6108                	ld	a0,0(a0)
    800013d6:	00157793          	andi	a5,a0,1
    800013da:	dfdd                	beqz	a5,80001398 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013dc:	3ff57793          	andi	a5,a0,1023
    800013e0:	fd7784e3          	beq	a5,s7,800013a8 <uvmunmap+0x76>
    if(do_free){
    800013e4:	fc0a8ae3          	beqz	s5,800013b8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013e8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013ea:	0532                	slli	a0,a0,0xc
    800013ec:	fffff097          	auipc	ra,0xfffff
    800013f0:	626080e7          	jalr	1574(ra) # 80000a12 <kfree>
    800013f4:	b7d1                	j	800013b8 <uvmunmap+0x86>

00000000800013f6 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013f6:	1101                	addi	sp,sp,-32
    800013f8:	ec06                	sd	ra,24(sp)
    800013fa:	e822                	sd	s0,16(sp)
    800013fc:	e426                	sd	s1,8(sp)
    800013fe:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001400:	fffff097          	auipc	ra,0xfffff
    80001404:	74a080e7          	jalr	1866(ra) # 80000b4a <kalloc>
    80001408:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000140a:	c519                	beqz	a0,80001418 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000140c:	6605                	lui	a2,0x1
    8000140e:	4581                	li	a1,0
    80001410:	00000097          	auipc	ra,0x0
    80001414:	95c080e7          	jalr	-1700(ra) # 80000d6c <memset>
  return pagetable;
}
    80001418:	8526                	mv	a0,s1
    8000141a:	60e2                	ld	ra,24(sp)
    8000141c:	6442                	ld	s0,16(sp)
    8000141e:	64a2                	ld	s1,8(sp)
    80001420:	6105                	addi	sp,sp,32
    80001422:	8082                	ret

0000000080001424 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001424:	7179                	addi	sp,sp,-48
    80001426:	f406                	sd	ra,40(sp)
    80001428:	f022                	sd	s0,32(sp)
    8000142a:	ec26                	sd	s1,24(sp)
    8000142c:	e84a                	sd	s2,16(sp)
    8000142e:	e44e                	sd	s3,8(sp)
    80001430:	e052                	sd	s4,0(sp)
    80001432:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001434:	6785                	lui	a5,0x1
    80001436:	04f67863          	bgeu	a2,a5,80001486 <uvminit+0x62>
    8000143a:	8a2a                	mv	s4,a0
    8000143c:	89ae                	mv	s3,a1
    8000143e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001440:	fffff097          	auipc	ra,0xfffff
    80001444:	70a080e7          	jalr	1802(ra) # 80000b4a <kalloc>
    80001448:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000144a:	6605                	lui	a2,0x1
    8000144c:	4581                	li	a1,0
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	91e080e7          	jalr	-1762(ra) # 80000d6c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001456:	4779                	li	a4,30
    80001458:	86ca                	mv	a3,s2
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	8552                	mv	a0,s4
    80001460:	00000097          	auipc	ra,0x0
    80001464:	d3a080e7          	jalr	-710(ra) # 8000119a <mappages>
  memmove(mem, src, sz);
    80001468:	8626                	mv	a2,s1
    8000146a:	85ce                	mv	a1,s3
    8000146c:	854a                	mv	a0,s2
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	95a080e7          	jalr	-1702(ra) # 80000dc8 <memmove>
}
    80001476:	70a2                	ld	ra,40(sp)
    80001478:	7402                	ld	s0,32(sp)
    8000147a:	64e2                	ld	s1,24(sp)
    8000147c:	6942                	ld	s2,16(sp)
    8000147e:	69a2                	ld	s3,8(sp)
    80001480:	6a02                	ld	s4,0(sp)
    80001482:	6145                	addi	sp,sp,48
    80001484:	8082                	ret
    panic("inituvm: more than a page");
    80001486:	00007517          	auipc	a0,0x7
    8000148a:	cc250513          	addi	a0,a0,-830 # 80008148 <digits+0x108>
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	0b4080e7          	jalr	180(ra) # 80000542 <panic>

0000000080001496 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001496:	1101                	addi	sp,sp,-32
    80001498:	ec06                	sd	ra,24(sp)
    8000149a:	e822                	sd	s0,16(sp)
    8000149c:	e426                	sd	s1,8(sp)
    8000149e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014a0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014a2:	00b67d63          	bgeu	a2,a1,800014bc <uvmdealloc+0x26>
    800014a6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014a8:	6785                	lui	a5,0x1
    800014aa:	17fd                	addi	a5,a5,-1
    800014ac:	00f60733          	add	a4,a2,a5
    800014b0:	767d                	lui	a2,0xfffff
    800014b2:	8f71                	and	a4,a4,a2
    800014b4:	97ae                	add	a5,a5,a1
    800014b6:	8ff1                	and	a5,a5,a2
    800014b8:	00f76863          	bltu	a4,a5,800014c8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014bc:	8526                	mv	a0,s1
    800014be:	60e2                	ld	ra,24(sp)
    800014c0:	6442                	ld	s0,16(sp)
    800014c2:	64a2                	ld	s1,8(sp)
    800014c4:	6105                	addi	sp,sp,32
    800014c6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014c8:	8f99                	sub	a5,a5,a4
    800014ca:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014cc:	4685                	li	a3,1
    800014ce:	0007861b          	sext.w	a2,a5
    800014d2:	85ba                	mv	a1,a4
    800014d4:	00000097          	auipc	ra,0x0
    800014d8:	e5e080e7          	jalr	-418(ra) # 80001332 <uvmunmap>
    800014dc:	b7c5                	j	800014bc <uvmdealloc+0x26>

00000000800014de <uvmalloc>:
  if(newsz < oldsz)
    800014de:	0ab66163          	bltu	a2,a1,80001580 <uvmalloc+0xa2>
{
    800014e2:	7139                	addi	sp,sp,-64
    800014e4:	fc06                	sd	ra,56(sp)
    800014e6:	f822                	sd	s0,48(sp)
    800014e8:	f426                	sd	s1,40(sp)
    800014ea:	f04a                	sd	s2,32(sp)
    800014ec:	ec4e                	sd	s3,24(sp)
    800014ee:	e852                	sd	s4,16(sp)
    800014f0:	e456                	sd	s5,8(sp)
    800014f2:	0080                	addi	s0,sp,64
    800014f4:	8aaa                	mv	s5,a0
    800014f6:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014f8:	6985                	lui	s3,0x1
    800014fa:	19fd                	addi	s3,s3,-1
    800014fc:	95ce                	add	a1,a1,s3
    800014fe:	79fd                	lui	s3,0xfffff
    80001500:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001504:	08c9f063          	bgeu	s3,a2,80001584 <uvmalloc+0xa6>
    80001508:	894e                	mv	s2,s3
    mem = kalloc();
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	640080e7          	jalr	1600(ra) # 80000b4a <kalloc>
    80001512:	84aa                	mv	s1,a0
    if(mem == 0){
    80001514:	c51d                	beqz	a0,80001542 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001516:	6605                	lui	a2,0x1
    80001518:	4581                	li	a1,0
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	852080e7          	jalr	-1966(ra) # 80000d6c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001522:	4779                	li	a4,30
    80001524:	86a6                	mv	a3,s1
    80001526:	6605                	lui	a2,0x1
    80001528:	85ca                	mv	a1,s2
    8000152a:	8556                	mv	a0,s5
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	c6e080e7          	jalr	-914(ra) # 8000119a <mappages>
    80001534:	e905                	bnez	a0,80001564 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001536:	6785                	lui	a5,0x1
    80001538:	993e                	add	s2,s2,a5
    8000153a:	fd4968e3          	bltu	s2,s4,8000150a <uvmalloc+0x2c>
  return newsz;
    8000153e:	8552                	mv	a0,s4
    80001540:	a809                	j	80001552 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001542:	864e                	mv	a2,s3
    80001544:	85ca                	mv	a1,s2
    80001546:	8556                	mv	a0,s5
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	f4e080e7          	jalr	-178(ra) # 80001496 <uvmdealloc>
      return 0;
    80001550:	4501                	li	a0,0
}
    80001552:	70e2                	ld	ra,56(sp)
    80001554:	7442                	ld	s0,48(sp)
    80001556:	74a2                	ld	s1,40(sp)
    80001558:	7902                	ld	s2,32(sp)
    8000155a:	69e2                	ld	s3,24(sp)
    8000155c:	6a42                	ld	s4,16(sp)
    8000155e:	6aa2                	ld	s5,8(sp)
    80001560:	6121                	addi	sp,sp,64
    80001562:	8082                	ret
      kfree(mem);
    80001564:	8526                	mv	a0,s1
    80001566:	fffff097          	auipc	ra,0xfffff
    8000156a:	4ac080e7          	jalr	1196(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000156e:	864e                	mv	a2,s3
    80001570:	85ca                	mv	a1,s2
    80001572:	8556                	mv	a0,s5
    80001574:	00000097          	auipc	ra,0x0
    80001578:	f22080e7          	jalr	-222(ra) # 80001496 <uvmdealloc>
      return 0;
    8000157c:	4501                	li	a0,0
    8000157e:	bfd1                	j	80001552 <uvmalloc+0x74>
    return oldsz;
    80001580:	852e                	mv	a0,a1
}
    80001582:	8082                	ret
  return newsz;
    80001584:	8532                	mv	a0,a2
    80001586:	b7f1                	j	80001552 <uvmalloc+0x74>

0000000080001588 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001588:	7179                	addi	sp,sp,-48
    8000158a:	f406                	sd	ra,40(sp)
    8000158c:	f022                	sd	s0,32(sp)
    8000158e:	ec26                	sd	s1,24(sp)
    80001590:	e84a                	sd	s2,16(sp)
    80001592:	e44e                	sd	s3,8(sp)
    80001594:	e052                	sd	s4,0(sp)
    80001596:	1800                	addi	s0,sp,48
    80001598:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000159a:	84aa                	mv	s1,a0
    8000159c:	6905                	lui	s2,0x1
    8000159e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a0:	4985                	li	s3,1
    800015a2:	a821                	j	800015ba <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015a4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015a6:	0532                	slli	a0,a0,0xc
    800015a8:	00000097          	auipc	ra,0x0
    800015ac:	fe0080e7          	jalr	-32(ra) # 80001588 <freewalk>
      pagetable[i] = 0;
    800015b0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015b4:	04a1                	addi	s1,s1,8
    800015b6:	03248163          	beq	s1,s2,800015d8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015ba:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015bc:	00f57793          	andi	a5,a0,15
    800015c0:	ff3782e3          	beq	a5,s3,800015a4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015c4:	8905                	andi	a0,a0,1
    800015c6:	d57d                	beqz	a0,800015b4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015c8:	00007517          	auipc	a0,0x7
    800015cc:	ba050513          	addi	a0,a0,-1120 # 80008168 <digits+0x128>
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	f72080e7          	jalr	-142(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    800015d8:	8552                	mv	a0,s4
    800015da:	fffff097          	auipc	ra,0xfffff
    800015de:	438080e7          	jalr	1080(ra) # 80000a12 <kfree>
}
    800015e2:	70a2                	ld	ra,40(sp)
    800015e4:	7402                	ld	s0,32(sp)
    800015e6:	64e2                	ld	s1,24(sp)
    800015e8:	6942                	ld	s2,16(sp)
    800015ea:	69a2                	ld	s3,8(sp)
    800015ec:	6a02                	ld	s4,0(sp)
    800015ee:	6145                	addi	sp,sp,48
    800015f0:	8082                	ret

00000000800015f2 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015f2:	1101                	addi	sp,sp,-32
    800015f4:	ec06                	sd	ra,24(sp)
    800015f6:	e822                	sd	s0,16(sp)
    800015f8:	e426                	sd	s1,8(sp)
    800015fa:	1000                	addi	s0,sp,32
    800015fc:	84aa                	mv	s1,a0
  if(sz > 0)
    800015fe:	e999                	bnez	a1,80001614 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001600:	8526                	mv	a0,s1
    80001602:	00000097          	auipc	ra,0x0
    80001606:	f86080e7          	jalr	-122(ra) # 80001588 <freewalk>
}
    8000160a:	60e2                	ld	ra,24(sp)
    8000160c:	6442                	ld	s0,16(sp)
    8000160e:	64a2                	ld	s1,8(sp)
    80001610:	6105                	addi	sp,sp,32
    80001612:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001614:	6605                	lui	a2,0x1
    80001616:	167d                	addi	a2,a2,-1
    80001618:	962e                	add	a2,a2,a1
    8000161a:	4685                	li	a3,1
    8000161c:	8231                	srli	a2,a2,0xc
    8000161e:	4581                	li	a1,0
    80001620:	00000097          	auipc	ra,0x0
    80001624:	d12080e7          	jalr	-750(ra) # 80001332 <uvmunmap>
    80001628:	bfe1                	j	80001600 <uvmfree+0xe>

000000008000162a <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    8000162a:	715d                	addi	sp,sp,-80
    8000162c:	e486                	sd	ra,72(sp)
    8000162e:	e0a2                	sd	s0,64(sp)
    80001630:	fc26                	sd	s1,56(sp)
    80001632:	f84a                	sd	s2,48(sp)
    80001634:	f44e                	sd	s3,40(sp)
    80001636:	f052                	sd	s4,32(sp)
    80001638:	ec56                	sd	s5,24(sp)
    8000163a:	e85a                	sd	s6,16(sp)
    8000163c:	e45e                	sd	s7,8(sp)
    8000163e:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  
  for(i = 0; i < sz; i += PGSIZE){
    80001640:	ca45                	beqz	a2,800016f0 <uvmcopy+0xc6>
    80001642:	8b2a                	mv	s6,a0
    80001644:	8aae                	mv	s5,a1
    80001646:	8a32                	mv	s4,a2
    80001648:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    8000164a:	4601                	li	a2,0
    8000164c:	85ca                	mv	a1,s2
    8000164e:	855a                	mv	a0,s6
    80001650:	00000097          	auipc	ra,0x0
    80001654:	a04080e7          	jalr	-1532(ra) # 80001054 <walk>
    80001658:	84aa                	mv	s1,a0
    8000165a:	c529                	beqz	a0,800016a4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000165c:	6118                	ld	a4,0(a0)
    8000165e:	00177793          	andi	a5,a4,1
    80001662:	cba9                	beqz	a5,800016b4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001664:	00a75993          	srli	s3,a4,0xa
    80001668:	09b2                	slli	s3,s3,0xc
    //(*pte) &= (~PTE_W);
    //(*pte) |= PTE_COW;
    //flags = PTE_FLAGS(*pte);
    flags=(PTE_FLAGS(*pte)&(~PTE_W))|PTE_COW;
    8000166a:	2fb77713          	andi	a4,a4,763
    //if((mem = kalloc()) == 0)
      //goto err;
    //memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    8000166e:	10076713          	ori	a4,a4,256
    80001672:	86ce                	mv	a3,s3
    80001674:	6605                	lui	a2,0x1
    80001676:	85ca                	mv	a1,s2
    80001678:	8556                	mv	a0,s5
    8000167a:	00000097          	auipc	ra,0x0
    8000167e:	b20080e7          	jalr	-1248(ra) # 8000119a <mappages>
    80001682:	8baa                	mv	s7,a0
    80001684:	e121                	bnez	a0,800016c4 <uvmcopy+0x9a>
      //kfree(mem);
      goto err;
    }
    *pte&=(~PTE_W);
    80001686:	609c                	ld	a5,0(s1)
    80001688:	9bed                	andi	a5,a5,-5
    *pte|=PTE_COW;
    8000168a:	1007e793          	ori	a5,a5,256
    8000168e:	e09c                	sd	a5,0(s1)
    //ref[(uint64)pa/PGSIZE]++;
    add_ref(pa);
    80001690:	854e                	mv	a0,s3
    80001692:	fffff097          	auipc	ra,0xfffff
    80001696:	52e080e7          	jalr	1326(ra) # 80000bc0 <add_ref>
  for(i = 0; i < sz; i += PGSIZE){
    8000169a:	6785                	lui	a5,0x1
    8000169c:	993e                	add	s2,s2,a5
    8000169e:	fb4966e3          	bltu	s2,s4,8000164a <uvmcopy+0x20>
    800016a2:	a81d                	j	800016d8 <uvmcopy+0xae>
      panic("uvmcopy: pte should exist");
    800016a4:	00007517          	auipc	a0,0x7
    800016a8:	ad450513          	addi	a0,a0,-1324 # 80008178 <digits+0x138>
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	e96080e7          	jalr	-362(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    800016b4:	00007517          	auipc	a0,0x7
    800016b8:	ae450513          	addi	a0,a0,-1308 # 80008198 <digits+0x158>
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	e86080e7          	jalr	-378(ra) # 80000542 <panic>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016c4:	4685                	li	a3,1
    800016c6:	00c95613          	srli	a2,s2,0xc
    800016ca:	4581                	li	a1,0
    800016cc:	8556                	mv	a0,s5
    800016ce:	00000097          	auipc	ra,0x0
    800016d2:	c64080e7          	jalr	-924(ra) # 80001332 <uvmunmap>
  return -1;
    800016d6:	5bfd                	li	s7,-1
}
    800016d8:	855e                	mv	a0,s7
    800016da:	60a6                	ld	ra,72(sp)
    800016dc:	6406                	ld	s0,64(sp)
    800016de:	74e2                	ld	s1,56(sp)
    800016e0:	7942                	ld	s2,48(sp)
    800016e2:	79a2                	ld	s3,40(sp)
    800016e4:	7a02                	ld	s4,32(sp)
    800016e6:	6ae2                	ld	s5,24(sp)
    800016e8:	6b42                	ld	s6,16(sp)
    800016ea:	6ba2                	ld	s7,8(sp)
    800016ec:	6161                	addi	sp,sp,80
    800016ee:	8082                	ret
  return 0;
    800016f0:	4b81                	li	s7,0
    800016f2:	b7dd                	j	800016d8 <uvmcopy+0xae>

00000000800016f4 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016f4:	1141                	addi	sp,sp,-16
    800016f6:	e406                	sd	ra,8(sp)
    800016f8:	e022                	sd	s0,0(sp)
    800016fa:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016fc:	4601                	li	a2,0
    800016fe:	00000097          	auipc	ra,0x0
    80001702:	956080e7          	jalr	-1706(ra) # 80001054 <walk>
  if(pte == 0)
    80001706:	c901                	beqz	a0,80001716 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001708:	611c                	ld	a5,0(a0)
    8000170a:	9bbd                	andi	a5,a5,-17
    8000170c:	e11c                	sd	a5,0(a0)
}
    8000170e:	60a2                	ld	ra,8(sp)
    80001710:	6402                	ld	s0,0(sp)
    80001712:	0141                	addi	sp,sp,16
    80001714:	8082                	ret
    panic("uvmclear");
    80001716:	00007517          	auipc	a0,0x7
    8000171a:	aa250513          	addi	a0,a0,-1374 # 800081b8 <digits+0x178>
    8000171e:	fffff097          	auipc	ra,0xfffff
    80001722:	e24080e7          	jalr	-476(ra) # 80000542 <panic>

0000000080001726 <copyout>:
{
  uint64 n, va0, pa0;
  char *mem;
  pte_t *pte;
  uint flags;
  while(len > 0){
    80001726:	c2fd                	beqz	a3,8000180c <copyout+0xe6>
{
    80001728:	7119                	addi	sp,sp,-128
    8000172a:	fc86                	sd	ra,120(sp)
    8000172c:	f8a2                	sd	s0,112(sp)
    8000172e:	f4a6                	sd	s1,104(sp)
    80001730:	f0ca                	sd	s2,96(sp)
    80001732:	ecce                	sd	s3,88(sp)
    80001734:	e8d2                	sd	s4,80(sp)
    80001736:	e4d6                	sd	s5,72(sp)
    80001738:	e0da                	sd	s6,64(sp)
    8000173a:	fc5e                	sd	s7,56(sp)
    8000173c:	f862                	sd	s8,48(sp)
    8000173e:	f466                	sd	s9,40(sp)
    80001740:	f06a                	sd	s10,32(sp)
    80001742:	ec6e                	sd	s11,24(sp)
    80001744:	0100                	addi	s0,sp,128
    80001746:	8caa                	mv	s9,a0
    80001748:	84ae                	mv	s1,a1
    8000174a:	8c32                	mv	s8,a2
    8000174c:	8b36                	mv	s6,a3
    va0 = PGROUNDDOWN(dstva);
    8000174e:	7dfd                	lui	s11,0xfffff
    pa0 = walkaddr(pagetable,va0);
    if(va0>=MAXVA)
    80001750:	5d7d                	li	s10,-1
    80001752:	01ad5d13          	srli	s10,s10,0x1a
    80001756:	a09d                	j	800017bc <copyout+0x96>
    }
    if(PTE_FLAGS(*pte)&PTE_COW)
    {
      //if((*pte)&PTE_W)
      //return -1;
      flags=(PTE_FLAGS(*pte)|PTE_W)&(~PTE_COW);
    80001758:	2fbafa93          	andi	s5,s5,763
    8000175c:	004aea93          	ori	s5,s5,4
      mem=kalloc();
    80001760:	fffff097          	auipc	ra,0xfffff
    80001764:	3ea080e7          	jalr	1002(ra) # 80000b4a <kalloc>
    80001768:	8baa                	mv	s7,a0
      if(mem==0)
    8000176a:	c579                	beqz	a0,80001838 <copyout+0x112>
      return -1;
      else
      {
      memmove(mem,(char*)pa0,PGSIZE);
    8000176c:	f9343423          	sd	s3,-120(s0)
    80001770:	6605                	lui	a2,0x1
    80001772:	85ce                	mv	a1,s3
    80001774:	fffff097          	auipc	ra,0xfffff
    80001778:	654080e7          	jalr	1620(ra) # 80000dc8 <memmove>
      //mappages(pagetable,va0,PGSIZE,(uint64)mem,flags);
      *pte = PA2PTE(mem)|flags;
    8000177c:	89de                	mv	s3,s7
    8000177e:	00cbdb93          	srli	s7,s7,0xc
    80001782:	0baa                	slli	s7,s7,0xa
    80001784:	017aebb3          	or	s7,s5,s7
    80001788:	017a3023          	sd	s7,0(s4) # 1000 <_entry-0x7ffff000>
      kfree((void*)pa0);
    8000178c:	f8843503          	ld	a0,-120(s0)
    80001790:	fffff097          	auipc	ra,0xfffff
    80001794:	282080e7          	jalr	642(ra) # 80000a12 <kfree>
      pa0=(uint64)mem;
      }
    }
    if(pa0 == 0)
    80001798:	a085                	j	800017f8 <copyout+0xd2>
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000179a:	41248533          	sub	a0,s1,s2
    8000179e:	000a061b          	sext.w	a2,s4
    800017a2:	85e2                	mv	a1,s8
    800017a4:	954e                	add	a0,a0,s3
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	622080e7          	jalr	1570(ra) # 80000dc8 <memmove>

    len -= n;
    800017ae:	414b0b33          	sub	s6,s6,s4
    src += n;
    800017b2:	9c52                	add	s8,s8,s4
    dstva = va0 + PGSIZE;
    800017b4:	6485                	lui	s1,0x1
    800017b6:	94ca                	add	s1,s1,s2
  while(len > 0){
    800017b8:	040b0863          	beqz	s6,80001808 <copyout+0xe2>
    va0 = PGROUNDDOWN(dstva);
    800017bc:	01b4f933          	and	s2,s1,s11
    pa0 = walkaddr(pagetable,va0);
    800017c0:	85ca                	mv	a1,s2
    800017c2:	8566                	mv	a0,s9
    800017c4:	00000097          	auipc	ra,0x0
    800017c8:	936080e7          	jalr	-1738(ra) # 800010fa <walkaddr>
    800017cc:	89aa                	mv	s3,a0
    if(va0>=MAXVA)
    800017ce:	052d6163          	bltu	s10,s2,80001810 <copyout+0xea>
    pte = walk(pagetable,va0,0);
    800017d2:	4601                	li	a2,0
    800017d4:	85ca                	mv	a1,s2
    800017d6:	8566                	mv	a0,s9
    800017d8:	00000097          	auipc	ra,0x0
    800017dc:	87c080e7          	jalr	-1924(ra) # 80001054 <walk>
    800017e0:	8a2a                	mv	s4,a0
    if(pte==0)
    800017e2:	c539                	beqz	a0,80001830 <copyout+0x10a>
    if(((*pte)&PTE_V)==0)
    800017e4:	00053a83          	ld	s5,0(a0)
    800017e8:	001af793          	andi	a5,s5,1
    800017ec:	c7a1                	beqz	a5,80001834 <copyout+0x10e>
    if(PTE_FLAGS(*pte)&PTE_COW)
    800017ee:	100af793          	andi	a5,s5,256
    800017f2:	f3bd                	bnez	a5,80001758 <copyout+0x32>
    if(pa0 == 0)
    800017f4:	04098463          	beqz	s3,8000183c <copyout+0x116>
    n = PGSIZE - (dstva - va0);
    800017f8:	40990a33          	sub	s4,s2,s1
    800017fc:	6785                	lui	a5,0x1
    800017fe:	9a3e                	add	s4,s4,a5
    if(n > len)
    80001800:	f94b7de3          	bgeu	s6,s4,8000179a <copyout+0x74>
    80001804:	8a5a                	mv	s4,s6
    80001806:	bf51                	j	8000179a <copyout+0x74>
  }
  return 0;
    80001808:	4501                	li	a0,0
    8000180a:	a021                	j	80001812 <copyout+0xec>
    8000180c:	4501                	li	a0,0
}
    8000180e:	8082                	ret
    return -1;
    80001810:	557d                	li	a0,-1
}
    80001812:	70e6                	ld	ra,120(sp)
    80001814:	7446                	ld	s0,112(sp)
    80001816:	74a6                	ld	s1,104(sp)
    80001818:	7906                	ld	s2,96(sp)
    8000181a:	69e6                	ld	s3,88(sp)
    8000181c:	6a46                	ld	s4,80(sp)
    8000181e:	6aa6                	ld	s5,72(sp)
    80001820:	6b06                	ld	s6,64(sp)
    80001822:	7be2                	ld	s7,56(sp)
    80001824:	7c42                	ld	s8,48(sp)
    80001826:	7ca2                	ld	s9,40(sp)
    80001828:	7d02                	ld	s10,32(sp)
    8000182a:	6de2                	ld	s11,24(sp)
    8000182c:	6109                	addi	sp,sp,128
    8000182e:	8082                	ret
      return -1;
    80001830:	557d                	li	a0,-1
    80001832:	b7c5                	j	80001812 <copyout+0xec>
      return -1;
    80001834:	557d                	li	a0,-1
    80001836:	bff1                	j	80001812 <copyout+0xec>
      return -1;
    80001838:	557d                	li	a0,-1
    8000183a:	bfe1                	j	80001812 <copyout+0xec>
      return -1;
    8000183c:	557d                	li	a0,-1
    8000183e:	bfd1                	j	80001812 <copyout+0xec>

0000000080001840 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001840:	caa5                	beqz	a3,800018b0 <copyin+0x70>
{
    80001842:	715d                	addi	sp,sp,-80
    80001844:	e486                	sd	ra,72(sp)
    80001846:	e0a2                	sd	s0,64(sp)
    80001848:	fc26                	sd	s1,56(sp)
    8000184a:	f84a                	sd	s2,48(sp)
    8000184c:	f44e                	sd	s3,40(sp)
    8000184e:	f052                	sd	s4,32(sp)
    80001850:	ec56                	sd	s5,24(sp)
    80001852:	e85a                	sd	s6,16(sp)
    80001854:	e45e                	sd	s7,8(sp)
    80001856:	e062                	sd	s8,0(sp)
    80001858:	0880                	addi	s0,sp,80
    8000185a:	8b2a                	mv	s6,a0
    8000185c:	8a2e                	mv	s4,a1
    8000185e:	8c32                	mv	s8,a2
    80001860:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001862:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001864:	6a85                	lui	s5,0x1
    80001866:	a01d                	j	8000188c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001868:	018505b3          	add	a1,a0,s8
    8000186c:	0004861b          	sext.w	a2,s1
    80001870:	412585b3          	sub	a1,a1,s2
    80001874:	8552                	mv	a0,s4
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	552080e7          	jalr	1362(ra) # 80000dc8 <memmove>

    len -= n;
    8000187e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001882:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001884:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001888:	02098263          	beqz	s3,800018ac <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000188c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001890:	85ca                	mv	a1,s2
    80001892:	855a                	mv	a0,s6
    80001894:	00000097          	auipc	ra,0x0
    80001898:	866080e7          	jalr	-1946(ra) # 800010fa <walkaddr>
    if(pa0 == 0)
    8000189c:	cd01                	beqz	a0,800018b4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000189e:	418904b3          	sub	s1,s2,s8
    800018a2:	94d6                	add	s1,s1,s5
    if(n > len)
    800018a4:	fc99f2e3          	bgeu	s3,s1,80001868 <copyin+0x28>
    800018a8:	84ce                	mv	s1,s3
    800018aa:	bf7d                	j	80001868 <copyin+0x28>
  }
  return 0;
    800018ac:	4501                	li	a0,0
    800018ae:	a021                	j	800018b6 <copyin+0x76>
    800018b0:	4501                	li	a0,0
}
    800018b2:	8082                	ret
      return -1;
    800018b4:	557d                	li	a0,-1
}
    800018b6:	60a6                	ld	ra,72(sp)
    800018b8:	6406                	ld	s0,64(sp)
    800018ba:	74e2                	ld	s1,56(sp)
    800018bc:	7942                	ld	s2,48(sp)
    800018be:	79a2                	ld	s3,40(sp)
    800018c0:	7a02                	ld	s4,32(sp)
    800018c2:	6ae2                	ld	s5,24(sp)
    800018c4:	6b42                	ld	s6,16(sp)
    800018c6:	6ba2                	ld	s7,8(sp)
    800018c8:	6c02                	ld	s8,0(sp)
    800018ca:	6161                	addi	sp,sp,80
    800018cc:	8082                	ret

00000000800018ce <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018ce:	c6c5                	beqz	a3,80001976 <copyinstr+0xa8>
{
    800018d0:	715d                	addi	sp,sp,-80
    800018d2:	e486                	sd	ra,72(sp)
    800018d4:	e0a2                	sd	s0,64(sp)
    800018d6:	fc26                	sd	s1,56(sp)
    800018d8:	f84a                	sd	s2,48(sp)
    800018da:	f44e                	sd	s3,40(sp)
    800018dc:	f052                	sd	s4,32(sp)
    800018de:	ec56                	sd	s5,24(sp)
    800018e0:	e85a                	sd	s6,16(sp)
    800018e2:	e45e                	sd	s7,8(sp)
    800018e4:	0880                	addi	s0,sp,80
    800018e6:	8a2a                	mv	s4,a0
    800018e8:	8b2e                	mv	s6,a1
    800018ea:	8bb2                	mv	s7,a2
    800018ec:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018ee:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f0:	6985                	lui	s3,0x1
    800018f2:	a035                	j	8000191e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018f4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018f8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018fa:	0017b793          	seqz	a5,a5
    800018fe:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001902:	60a6                	ld	ra,72(sp)
    80001904:	6406                	ld	s0,64(sp)
    80001906:	74e2                	ld	s1,56(sp)
    80001908:	7942                	ld	s2,48(sp)
    8000190a:	79a2                	ld	s3,40(sp)
    8000190c:	7a02                	ld	s4,32(sp)
    8000190e:	6ae2                	ld	s5,24(sp)
    80001910:	6b42                	ld	s6,16(sp)
    80001912:	6ba2                	ld	s7,8(sp)
    80001914:	6161                	addi	sp,sp,80
    80001916:	8082                	ret
    srcva = va0 + PGSIZE;
    80001918:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000191c:	c8a9                	beqz	s1,8000196e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000191e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001922:	85ca                	mv	a1,s2
    80001924:	8552                	mv	a0,s4
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	7d4080e7          	jalr	2004(ra) # 800010fa <walkaddr>
    if(pa0 == 0)
    8000192e:	c131                	beqz	a0,80001972 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001930:	41790833          	sub	a6,s2,s7
    80001934:	984e                	add	a6,a6,s3
    if(n > max)
    80001936:	0104f363          	bgeu	s1,a6,8000193c <copyinstr+0x6e>
    8000193a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000193c:	955e                	add	a0,a0,s7
    8000193e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001942:	fc080be3          	beqz	a6,80001918 <copyinstr+0x4a>
    80001946:	985a                	add	a6,a6,s6
    80001948:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000194a:	41650633          	sub	a2,a0,s6
    8000194e:	14fd                	addi	s1,s1,-1
    80001950:	9b26                	add	s6,s6,s1
    80001952:	00f60733          	add	a4,a2,a5
    80001956:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdb9000>
    8000195a:	df49                	beqz	a4,800018f4 <copyinstr+0x26>
        *dst = *p;
    8000195c:	00e78023          	sb	a4,0(a5)
      --max;
    80001960:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001964:	0785                	addi	a5,a5,1
    while(n > 0){
    80001966:	ff0796e3          	bne	a5,a6,80001952 <copyinstr+0x84>
      dst++;
    8000196a:	8b42                	mv	s6,a6
    8000196c:	b775                	j	80001918 <copyinstr+0x4a>
    8000196e:	4781                	li	a5,0
    80001970:	b769                	j	800018fa <copyinstr+0x2c>
      return -1;
    80001972:	557d                	li	a0,-1
    80001974:	b779                	j	80001902 <copyinstr+0x34>
  int got_null = 0;
    80001976:	4781                	li	a5,0
  if(got_null){
    80001978:	0017b793          	seqz	a5,a5
    8000197c:	40f00533          	neg	a0,a5
}
    80001980:	8082                	ret

0000000080001982 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001982:	1101                	addi	sp,sp,-32
    80001984:	ec06                	sd	ra,24(sp)
    80001986:	e822                	sd	s0,16(sp)
    80001988:	e426                	sd	s1,8(sp)
    8000198a:	1000                	addi	s0,sp,32
    8000198c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	268080e7          	jalr	616(ra) # 80000bf6 <holding>
    80001996:	c909                	beqz	a0,800019a8 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001998:	749c                	ld	a5,40(s1)
    8000199a:	00978f63          	beq	a5,s1,800019b8 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000199e:	60e2                	ld	ra,24(sp)
    800019a0:	6442                	ld	s0,16(sp)
    800019a2:	64a2                	ld	s1,8(sp)
    800019a4:	6105                	addi	sp,sp,32
    800019a6:	8082                	ret
    panic("wakeup1");
    800019a8:	00007517          	auipc	a0,0x7
    800019ac:	82050513          	addi	a0,a0,-2016 # 800081c8 <digits+0x188>
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	b92080e7          	jalr	-1134(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800019b8:	4c98                	lw	a4,24(s1)
    800019ba:	4785                	li	a5,1
    800019bc:	fef711e3          	bne	a4,a5,8000199e <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019c0:	4789                	li	a5,2
    800019c2:	cc9c                	sw	a5,24(s1)
}
    800019c4:	bfe9                	j	8000199e <wakeup1+0x1c>

00000000800019c6 <procinit>:
{
    800019c6:	715d                	addi	sp,sp,-80
    800019c8:	e486                	sd	ra,72(sp)
    800019ca:	e0a2                	sd	s0,64(sp)
    800019cc:	fc26                	sd	s1,56(sp)
    800019ce:	f84a                	sd	s2,48(sp)
    800019d0:	f44e                	sd	s3,40(sp)
    800019d2:	f052                	sd	s4,32(sp)
    800019d4:	ec56                	sd	s5,24(sp)
    800019d6:	e85a                	sd	s6,16(sp)
    800019d8:	e45e                	sd	s7,8(sp)
    800019da:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800019dc:	00006597          	auipc	a1,0x6
    800019e0:	7f458593          	addi	a1,a1,2036 # 800081d0 <digits+0x190>
    800019e4:	00230517          	auipc	a0,0x230
    800019e8:	f6c50513          	addi	a0,a0,-148 # 80231950 <pid_lock>
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	1f4080e7          	jalr	500(ra) # 80000be0 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f4:	00230917          	auipc	s2,0x230
    800019f8:	37490913          	addi	s2,s2,884 # 80231d68 <proc>
      initlock(&p->lock, "proc");
    800019fc:	00006b97          	auipc	s7,0x6
    80001a00:	7dcb8b93          	addi	s7,s7,2012 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001a04:	8b4a                	mv	s6,s2
    80001a06:	00006a97          	auipc	s5,0x6
    80001a0a:	5faa8a93          	addi	s5,s5,1530 # 80008000 <etext>
    80001a0e:	040009b7          	lui	s3,0x4000
    80001a12:	19fd                	addi	s3,s3,-1
    80001a14:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a16:	00236a17          	auipc	s4,0x236
    80001a1a:	d52a0a13          	addi	s4,s4,-686 # 80237768 <tickslock>
      initlock(&p->lock, "proc");
    80001a1e:	85de                	mv	a1,s7
    80001a20:	854a                	mv	a0,s2
    80001a22:	fffff097          	auipc	ra,0xfffff
    80001a26:	1be080e7          	jalr	446(ra) # 80000be0 <initlock>
      char *pa = kalloc();
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	120080e7          	jalr	288(ra) # 80000b4a <kalloc>
    80001a32:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a34:	c929                	beqz	a0,80001a86 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a36:	416904b3          	sub	s1,s2,s6
    80001a3a:	848d                	srai	s1,s1,0x3
    80001a3c:	000ab783          	ld	a5,0(s5)
    80001a40:	02f484b3          	mul	s1,s1,a5
    80001a44:	2485                	addiw	s1,s1,1
    80001a46:	00d4949b          	slliw	s1,s1,0xd
    80001a4a:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a4e:	4699                	li	a3,6
    80001a50:	6605                	lui	a2,0x1
    80001a52:	8526                	mv	a0,s1
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	7d4080e7          	jalr	2004(ra) # 80001228 <kvmmap>
      p->kstack = va;
    80001a5c:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a60:	16890913          	addi	s2,s2,360
    80001a64:	fb491de3          	bne	s2,s4,80001a1e <procinit+0x58>
  kvminithart();
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	5c8080e7          	jalr	1480(ra) # 80001030 <kvminithart>
}
    80001a70:	60a6                	ld	ra,72(sp)
    80001a72:	6406                	ld	s0,64(sp)
    80001a74:	74e2                	ld	s1,56(sp)
    80001a76:	7942                	ld	s2,48(sp)
    80001a78:	79a2                	ld	s3,40(sp)
    80001a7a:	7a02                	ld	s4,32(sp)
    80001a7c:	6ae2                	ld	s5,24(sp)
    80001a7e:	6b42                	ld	s6,16(sp)
    80001a80:	6ba2                	ld	s7,8(sp)
    80001a82:	6161                	addi	sp,sp,80
    80001a84:	8082                	ret
        panic("kalloc");
    80001a86:	00006517          	auipc	a0,0x6
    80001a8a:	75a50513          	addi	a0,a0,1882 # 800081e0 <digits+0x1a0>
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	ab4080e7          	jalr	-1356(ra) # 80000542 <panic>

0000000080001a96 <cpuid>:
{
    80001a96:	1141                	addi	sp,sp,-16
    80001a98:	e422                	sd	s0,8(sp)
    80001a9a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a9c:	8512                	mv	a0,tp
}
    80001a9e:	2501                	sext.w	a0,a0
    80001aa0:	6422                	ld	s0,8(sp)
    80001aa2:	0141                	addi	sp,sp,16
    80001aa4:	8082                	ret

0000000080001aa6 <mycpu>:
mycpu(void) {
    80001aa6:	1141                	addi	sp,sp,-16
    80001aa8:	e422                	sd	s0,8(sp)
    80001aaa:	0800                	addi	s0,sp,16
    80001aac:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001aae:	2781                	sext.w	a5,a5
    80001ab0:	079e                	slli	a5,a5,0x7
}
    80001ab2:	00230517          	auipc	a0,0x230
    80001ab6:	eb650513          	addi	a0,a0,-330 # 80231968 <cpus>
    80001aba:	953e                	add	a0,a0,a5
    80001abc:	6422                	ld	s0,8(sp)
    80001abe:	0141                	addi	sp,sp,16
    80001ac0:	8082                	ret

0000000080001ac2 <myproc>:
myproc(void) {
    80001ac2:	1101                	addi	sp,sp,-32
    80001ac4:	ec06                	sd	ra,24(sp)
    80001ac6:	e822                	sd	s0,16(sp)
    80001ac8:	e426                	sd	s1,8(sp)
    80001aca:	1000                	addi	s0,sp,32
  push_off();
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	158080e7          	jalr	344(ra) # 80000c24 <push_off>
    80001ad4:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001ad6:	2781                	sext.w	a5,a5
    80001ad8:	079e                	slli	a5,a5,0x7
    80001ada:	00230717          	auipc	a4,0x230
    80001ade:	e7670713          	addi	a4,a4,-394 # 80231950 <pid_lock>
    80001ae2:	97ba                	add	a5,a5,a4
    80001ae4:	6f84                	ld	s1,24(a5)
  pop_off();
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	1de080e7          	jalr	478(ra) # 80000cc4 <pop_off>
}
    80001aee:	8526                	mv	a0,s1
    80001af0:	60e2                	ld	ra,24(sp)
    80001af2:	6442                	ld	s0,16(sp)
    80001af4:	64a2                	ld	s1,8(sp)
    80001af6:	6105                	addi	sp,sp,32
    80001af8:	8082                	ret

0000000080001afa <forkret>:
{
    80001afa:	1141                	addi	sp,sp,-16
    80001afc:	e406                	sd	ra,8(sp)
    80001afe:	e022                	sd	s0,0(sp)
    80001b00:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b02:	00000097          	auipc	ra,0x0
    80001b06:	fc0080e7          	jalr	-64(ra) # 80001ac2 <myproc>
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	21a080e7          	jalr	538(ra) # 80000d24 <release>
  if (first) {
    80001b12:	00007797          	auipc	a5,0x7
    80001b16:	cfe7a783          	lw	a5,-770(a5) # 80008810 <first.1>
    80001b1a:	eb89                	bnez	a5,80001b2c <forkret+0x32>
  usertrapret();
    80001b1c:	00001097          	auipc	ra,0x1
    80001b20:	c18080e7          	jalr	-1000(ra) # 80002734 <usertrapret>
}
    80001b24:	60a2                	ld	ra,8(sp)
    80001b26:	6402                	ld	s0,0(sp)
    80001b28:	0141                	addi	sp,sp,16
    80001b2a:	8082                	ret
    first = 0;
    80001b2c:	00007797          	auipc	a5,0x7
    80001b30:	ce07a223          	sw	zero,-796(a5) # 80008810 <first.1>
    fsinit(ROOTDEV);
    80001b34:	4505                	li	a0,1
    80001b36:	00002097          	auipc	ra,0x2
    80001b3a:	9da080e7          	jalr	-1574(ra) # 80003510 <fsinit>
    80001b3e:	bff9                	j	80001b1c <forkret+0x22>

0000000080001b40 <allocpid>:
allocpid() {
    80001b40:	1101                	addi	sp,sp,-32
    80001b42:	ec06                	sd	ra,24(sp)
    80001b44:	e822                	sd	s0,16(sp)
    80001b46:	e426                	sd	s1,8(sp)
    80001b48:	e04a                	sd	s2,0(sp)
    80001b4a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b4c:	00230917          	auipc	s2,0x230
    80001b50:	e0490913          	addi	s2,s2,-508 # 80231950 <pid_lock>
    80001b54:	854a                	mv	a0,s2
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	11a080e7          	jalr	282(ra) # 80000c70 <acquire>
  pid = nextpid;
    80001b5e:	00007797          	auipc	a5,0x7
    80001b62:	cb678793          	addi	a5,a5,-842 # 80008814 <nextpid>
    80001b66:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b68:	0014871b          	addiw	a4,s1,1
    80001b6c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b6e:	854a                	mv	a0,s2
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	1b4080e7          	jalr	436(ra) # 80000d24 <release>
}
    80001b78:	8526                	mv	a0,s1
    80001b7a:	60e2                	ld	ra,24(sp)
    80001b7c:	6442                	ld	s0,16(sp)
    80001b7e:	64a2                	ld	s1,8(sp)
    80001b80:	6902                	ld	s2,0(sp)
    80001b82:	6105                	addi	sp,sp,32
    80001b84:	8082                	ret

0000000080001b86 <proc_pagetable>:
{
    80001b86:	1101                	addi	sp,sp,-32
    80001b88:	ec06                	sd	ra,24(sp)
    80001b8a:	e822                	sd	s0,16(sp)
    80001b8c:	e426                	sd	s1,8(sp)
    80001b8e:	e04a                	sd	s2,0(sp)
    80001b90:	1000                	addi	s0,sp,32
    80001b92:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	862080e7          	jalr	-1950(ra) # 800013f6 <uvmcreate>
    80001b9c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b9e:	c121                	beqz	a0,80001bde <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ba0:	4729                	li	a4,10
    80001ba2:	00005697          	auipc	a3,0x5
    80001ba6:	45e68693          	addi	a3,a3,1118 # 80007000 <_trampoline>
    80001baa:	6605                	lui	a2,0x1
    80001bac:	040005b7          	lui	a1,0x4000
    80001bb0:	15fd                	addi	a1,a1,-1
    80001bb2:	05b2                	slli	a1,a1,0xc
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	5e6080e7          	jalr	1510(ra) # 8000119a <mappages>
    80001bbc:	02054863          	bltz	a0,80001bec <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bc0:	4719                	li	a4,6
    80001bc2:	05893683          	ld	a3,88(s2)
    80001bc6:	6605                	lui	a2,0x1
    80001bc8:	020005b7          	lui	a1,0x2000
    80001bcc:	15fd                	addi	a1,a1,-1
    80001bce:	05b6                	slli	a1,a1,0xd
    80001bd0:	8526                	mv	a0,s1
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	5c8080e7          	jalr	1480(ra) # 8000119a <mappages>
    80001bda:	02054163          	bltz	a0,80001bfc <proc_pagetable+0x76>
}
    80001bde:	8526                	mv	a0,s1
    80001be0:	60e2                	ld	ra,24(sp)
    80001be2:	6442                	ld	s0,16(sp)
    80001be4:	64a2                	ld	s1,8(sp)
    80001be6:	6902                	ld	s2,0(sp)
    80001be8:	6105                	addi	sp,sp,32
    80001bea:	8082                	ret
    uvmfree(pagetable, 0);
    80001bec:	4581                	li	a1,0
    80001bee:	8526                	mv	a0,s1
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	a02080e7          	jalr	-1534(ra) # 800015f2 <uvmfree>
    return 0;
    80001bf8:	4481                	li	s1,0
    80001bfa:	b7d5                	j	80001bde <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bfc:	4681                	li	a3,0
    80001bfe:	4605                	li	a2,1
    80001c00:	040005b7          	lui	a1,0x4000
    80001c04:	15fd                	addi	a1,a1,-1
    80001c06:	05b2                	slli	a1,a1,0xc
    80001c08:	8526                	mv	a0,s1
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	728080e7          	jalr	1832(ra) # 80001332 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c12:	4581                	li	a1,0
    80001c14:	8526                	mv	a0,s1
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	9dc080e7          	jalr	-1572(ra) # 800015f2 <uvmfree>
    return 0;
    80001c1e:	4481                	li	s1,0
    80001c20:	bf7d                	j	80001bde <proc_pagetable+0x58>

0000000080001c22 <proc_freepagetable>:
{
    80001c22:	1101                	addi	sp,sp,-32
    80001c24:	ec06                	sd	ra,24(sp)
    80001c26:	e822                	sd	s0,16(sp)
    80001c28:	e426                	sd	s1,8(sp)
    80001c2a:	e04a                	sd	s2,0(sp)
    80001c2c:	1000                	addi	s0,sp,32
    80001c2e:	84aa                	mv	s1,a0
    80001c30:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c32:	4681                	li	a3,0
    80001c34:	4605                	li	a2,1
    80001c36:	040005b7          	lui	a1,0x4000
    80001c3a:	15fd                	addi	a1,a1,-1
    80001c3c:	05b2                	slli	a1,a1,0xc
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	6f4080e7          	jalr	1780(ra) # 80001332 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c46:	4681                	li	a3,0
    80001c48:	4605                	li	a2,1
    80001c4a:	020005b7          	lui	a1,0x2000
    80001c4e:	15fd                	addi	a1,a1,-1
    80001c50:	05b6                	slli	a1,a1,0xd
    80001c52:	8526                	mv	a0,s1
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	6de080e7          	jalr	1758(ra) # 80001332 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c5c:	85ca                	mv	a1,s2
    80001c5e:	8526                	mv	a0,s1
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	992080e7          	jalr	-1646(ra) # 800015f2 <uvmfree>
}
    80001c68:	60e2                	ld	ra,24(sp)
    80001c6a:	6442                	ld	s0,16(sp)
    80001c6c:	64a2                	ld	s1,8(sp)
    80001c6e:	6902                	ld	s2,0(sp)
    80001c70:	6105                	addi	sp,sp,32
    80001c72:	8082                	ret

0000000080001c74 <freeproc>:
{
    80001c74:	1101                	addi	sp,sp,-32
    80001c76:	ec06                	sd	ra,24(sp)
    80001c78:	e822                	sd	s0,16(sp)
    80001c7a:	e426                	sd	s1,8(sp)
    80001c7c:	1000                	addi	s0,sp,32
    80001c7e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c80:	6d28                	ld	a0,88(a0)
    80001c82:	c509                	beqz	a0,80001c8c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	d8e080e7          	jalr	-626(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001c8c:	0404bc23          	sd	zero,88(s1) # 1058 <_entry-0x7fffefa8>
  if(p->pagetable)
    80001c90:	68a8                	ld	a0,80(s1)
    80001c92:	c511                	beqz	a0,80001c9e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c94:	64ac                	ld	a1,72(s1)
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	f8c080e7          	jalr	-116(ra) # 80001c22 <proc_freepagetable>
  p->pagetable = 0;
    80001c9e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ca2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ca6:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001caa:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001cae:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cb2:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001cb6:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001cba:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001cbe:	0004ac23          	sw	zero,24(s1)
}
    80001cc2:	60e2                	ld	ra,24(sp)
    80001cc4:	6442                	ld	s0,16(sp)
    80001cc6:	64a2                	ld	s1,8(sp)
    80001cc8:	6105                	addi	sp,sp,32
    80001cca:	8082                	ret

0000000080001ccc <allocproc>:
{
    80001ccc:	1101                	addi	sp,sp,-32
    80001cce:	ec06                	sd	ra,24(sp)
    80001cd0:	e822                	sd	s0,16(sp)
    80001cd2:	e426                	sd	s1,8(sp)
    80001cd4:	e04a                	sd	s2,0(sp)
    80001cd6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd8:	00230497          	auipc	s1,0x230
    80001cdc:	09048493          	addi	s1,s1,144 # 80231d68 <proc>
    80001ce0:	00236917          	auipc	s2,0x236
    80001ce4:	a8890913          	addi	s2,s2,-1400 # 80237768 <tickslock>
    acquire(&p->lock);
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	f86080e7          	jalr	-122(ra) # 80000c70 <acquire>
    if(p->state == UNUSED) {
    80001cf2:	4c9c                	lw	a5,24(s1)
    80001cf4:	cf81                	beqz	a5,80001d0c <allocproc+0x40>
      release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	02c080e7          	jalr	44(ra) # 80000d24 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d00:	16848493          	addi	s1,s1,360
    80001d04:	ff2492e3          	bne	s1,s2,80001ce8 <allocproc+0x1c>
  return 0;
    80001d08:	4481                	li	s1,0
    80001d0a:	a0b9                	j	80001d58 <allocproc+0x8c>
  p->pid = allocpid();
    80001d0c:	00000097          	auipc	ra,0x0
    80001d10:	e34080e7          	jalr	-460(ra) # 80001b40 <allocpid>
    80001d14:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	e34080e7          	jalr	-460(ra) # 80000b4a <kalloc>
    80001d1e:	892a                	mv	s2,a0
    80001d20:	eca8                	sd	a0,88(s1)
    80001d22:	c131                	beqz	a0,80001d66 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d24:	8526                	mv	a0,s1
    80001d26:	00000097          	auipc	ra,0x0
    80001d2a:	e60080e7          	jalr	-416(ra) # 80001b86 <proc_pagetable>
    80001d2e:	892a                	mv	s2,a0
    80001d30:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d32:	c129                	beqz	a0,80001d74 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d34:	07000613          	li	a2,112
    80001d38:	4581                	li	a1,0
    80001d3a:	06048513          	addi	a0,s1,96
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	02e080e7          	jalr	46(ra) # 80000d6c <memset>
  p->context.ra = (uint64)forkret;
    80001d46:	00000797          	auipc	a5,0x0
    80001d4a:	db478793          	addi	a5,a5,-588 # 80001afa <forkret>
    80001d4e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d50:	60bc                	ld	a5,64(s1)
    80001d52:	6705                	lui	a4,0x1
    80001d54:	97ba                	add	a5,a5,a4
    80001d56:	f4bc                	sd	a5,104(s1)
}
    80001d58:	8526                	mv	a0,s1
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6902                	ld	s2,0(sp)
    80001d62:	6105                	addi	sp,sp,32
    80001d64:	8082                	ret
    release(&p->lock);
    80001d66:	8526                	mv	a0,s1
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	fbc080e7          	jalr	-68(ra) # 80000d24 <release>
    return 0;
    80001d70:	84ca                	mv	s1,s2
    80001d72:	b7dd                	j	80001d58 <allocproc+0x8c>
    freeproc(p);
    80001d74:	8526                	mv	a0,s1
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	efe080e7          	jalr	-258(ra) # 80001c74 <freeproc>
    release(&p->lock);
    80001d7e:	8526                	mv	a0,s1
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	fa4080e7          	jalr	-92(ra) # 80000d24 <release>
    return 0;
    80001d88:	84ca                	mv	s1,s2
    80001d8a:	b7f9                	j	80001d58 <allocproc+0x8c>

0000000080001d8c <userinit>:
{
    80001d8c:	1101                	addi	sp,sp,-32
    80001d8e:	ec06                	sd	ra,24(sp)
    80001d90:	e822                	sd	s0,16(sp)
    80001d92:	e426                	sd	s1,8(sp)
    80001d94:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	f36080e7          	jalr	-202(ra) # 80001ccc <allocproc>
    80001d9e:	84aa                	mv	s1,a0
  initproc = p;
    80001da0:	00007797          	auipc	a5,0x7
    80001da4:	26a7bc23          	sd	a0,632(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001da8:	03400613          	li	a2,52
    80001dac:	00007597          	auipc	a1,0x7
    80001db0:	a7458593          	addi	a1,a1,-1420 # 80008820 <initcode>
    80001db4:	6928                	ld	a0,80(a0)
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	66e080e7          	jalr	1646(ra) # 80001424 <uvminit>
  p->sz = PGSIZE;
    80001dbe:	6785                	lui	a5,0x1
    80001dc0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dc2:	6cb8                	ld	a4,88(s1)
    80001dc4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dc8:	6cb8                	ld	a4,88(s1)
    80001dca:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dcc:	4641                	li	a2,16
    80001dce:	00006597          	auipc	a1,0x6
    80001dd2:	41a58593          	addi	a1,a1,1050 # 800081e8 <digits+0x1a8>
    80001dd6:	15848513          	addi	a0,s1,344
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	0e4080e7          	jalr	228(ra) # 80000ebe <safestrcpy>
  p->cwd = namei("/");
    80001de2:	00006517          	auipc	a0,0x6
    80001de6:	41650513          	addi	a0,a0,1046 # 800081f8 <digits+0x1b8>
    80001dea:	00002097          	auipc	ra,0x2
    80001dee:	152080e7          	jalr	338(ra) # 80003f3c <namei>
    80001df2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001df6:	4789                	li	a5,2
    80001df8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001dfa:	8526                	mv	a0,s1
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	f28080e7          	jalr	-216(ra) # 80000d24 <release>
}
    80001e04:	60e2                	ld	ra,24(sp)
    80001e06:	6442                	ld	s0,16(sp)
    80001e08:	64a2                	ld	s1,8(sp)
    80001e0a:	6105                	addi	sp,sp,32
    80001e0c:	8082                	ret

0000000080001e0e <growproc>:
{
    80001e0e:	1101                	addi	sp,sp,-32
    80001e10:	ec06                	sd	ra,24(sp)
    80001e12:	e822                	sd	s0,16(sp)
    80001e14:	e426                	sd	s1,8(sp)
    80001e16:	e04a                	sd	s2,0(sp)
    80001e18:	1000                	addi	s0,sp,32
    80001e1a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	ca6080e7          	jalr	-858(ra) # 80001ac2 <myproc>
    80001e24:	892a                	mv	s2,a0
  sz = p->sz;
    80001e26:	652c                	ld	a1,72(a0)
    80001e28:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e2c:	00904f63          	bgtz	s1,80001e4a <growproc+0x3c>
  } else if(n < 0){
    80001e30:	0204cc63          	bltz	s1,80001e68 <growproc+0x5a>
  p->sz = sz;
    80001e34:	1602                	slli	a2,a2,0x20
    80001e36:	9201                	srli	a2,a2,0x20
    80001e38:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e3c:	4501                	li	a0,0
}
    80001e3e:	60e2                	ld	ra,24(sp)
    80001e40:	6442                	ld	s0,16(sp)
    80001e42:	64a2                	ld	s1,8(sp)
    80001e44:	6902                	ld	s2,0(sp)
    80001e46:	6105                	addi	sp,sp,32
    80001e48:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e4a:	9e25                	addw	a2,a2,s1
    80001e4c:	1602                	slli	a2,a2,0x20
    80001e4e:	9201                	srli	a2,a2,0x20
    80001e50:	1582                	slli	a1,a1,0x20
    80001e52:	9181                	srli	a1,a1,0x20
    80001e54:	6928                	ld	a0,80(a0)
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	688080e7          	jalr	1672(ra) # 800014de <uvmalloc>
    80001e5e:	0005061b          	sext.w	a2,a0
    80001e62:	fa69                	bnez	a2,80001e34 <growproc+0x26>
      return -1;
    80001e64:	557d                	li	a0,-1
    80001e66:	bfe1                	j	80001e3e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e68:	9e25                	addw	a2,a2,s1
    80001e6a:	1602                	slli	a2,a2,0x20
    80001e6c:	9201                	srli	a2,a2,0x20
    80001e6e:	1582                	slli	a1,a1,0x20
    80001e70:	9181                	srli	a1,a1,0x20
    80001e72:	6928                	ld	a0,80(a0)
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	622080e7          	jalr	1570(ra) # 80001496 <uvmdealloc>
    80001e7c:	0005061b          	sext.w	a2,a0
    80001e80:	bf55                	j	80001e34 <growproc+0x26>

0000000080001e82 <fork>:
{
    80001e82:	7139                	addi	sp,sp,-64
    80001e84:	fc06                	sd	ra,56(sp)
    80001e86:	f822                	sd	s0,48(sp)
    80001e88:	f426                	sd	s1,40(sp)
    80001e8a:	f04a                	sd	s2,32(sp)
    80001e8c:	ec4e                	sd	s3,24(sp)
    80001e8e:	e852                	sd	s4,16(sp)
    80001e90:	e456                	sd	s5,8(sp)
    80001e92:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	c2e080e7          	jalr	-978(ra) # 80001ac2 <myproc>
    80001e9c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	e2e080e7          	jalr	-466(ra) # 80001ccc <allocproc>
    80001ea6:	c17d                	beqz	a0,80001f8c <fork+0x10a>
    80001ea8:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eaa:	048ab603          	ld	a2,72(s5)
    80001eae:	692c                	ld	a1,80(a0)
    80001eb0:	050ab503          	ld	a0,80(s5)
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	776080e7          	jalr	1910(ra) # 8000162a <uvmcopy>
    80001ebc:	04054a63          	bltz	a0,80001f10 <fork+0x8e>
  np->sz = p->sz;
    80001ec0:	048ab783          	ld	a5,72(s5)
    80001ec4:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001ec8:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001ecc:	058ab683          	ld	a3,88(s5)
    80001ed0:	87b6                	mv	a5,a3
    80001ed2:	058a3703          	ld	a4,88(s4)
    80001ed6:	12068693          	addi	a3,a3,288
    80001eda:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ede:	6788                	ld	a0,8(a5)
    80001ee0:	6b8c                	ld	a1,16(a5)
    80001ee2:	6f90                	ld	a2,24(a5)
    80001ee4:	01073023          	sd	a6,0(a4)
    80001ee8:	e708                	sd	a0,8(a4)
    80001eea:	eb0c                	sd	a1,16(a4)
    80001eec:	ef10                	sd	a2,24(a4)
    80001eee:	02078793          	addi	a5,a5,32
    80001ef2:	02070713          	addi	a4,a4,32
    80001ef6:	fed792e3          	bne	a5,a3,80001eda <fork+0x58>
  np->trapframe->a0 = 0;
    80001efa:	058a3783          	ld	a5,88(s4)
    80001efe:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f02:	0d0a8493          	addi	s1,s5,208
    80001f06:	0d0a0913          	addi	s2,s4,208
    80001f0a:	150a8993          	addi	s3,s5,336
    80001f0e:	a00d                	j	80001f30 <fork+0xae>
    freeproc(np);
    80001f10:	8552                	mv	a0,s4
    80001f12:	00000097          	auipc	ra,0x0
    80001f16:	d62080e7          	jalr	-670(ra) # 80001c74 <freeproc>
    release(&np->lock);
    80001f1a:	8552                	mv	a0,s4
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	e08080e7          	jalr	-504(ra) # 80000d24 <release>
    return -1;
    80001f24:	54fd                	li	s1,-1
    80001f26:	a889                	j	80001f78 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001f28:	04a1                	addi	s1,s1,8
    80001f2a:	0921                	addi	s2,s2,8
    80001f2c:	01348b63          	beq	s1,s3,80001f42 <fork+0xc0>
    if(p->ofile[i])
    80001f30:	6088                	ld	a0,0(s1)
    80001f32:	d97d                	beqz	a0,80001f28 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f34:	00002097          	auipc	ra,0x2
    80001f38:	694080e7          	jalr	1684(ra) # 800045c8 <filedup>
    80001f3c:	00a93023          	sd	a0,0(s2)
    80001f40:	b7e5                	j	80001f28 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001f42:	150ab503          	ld	a0,336(s5)
    80001f46:	00002097          	auipc	ra,0x2
    80001f4a:	804080e7          	jalr	-2044(ra) # 8000374a <idup>
    80001f4e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f52:	4641                	li	a2,16
    80001f54:	158a8593          	addi	a1,s5,344
    80001f58:	158a0513          	addi	a0,s4,344
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	f62080e7          	jalr	-158(ra) # 80000ebe <safestrcpy>
  pid = np->pid;
    80001f64:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001f68:	4789                	li	a5,2
    80001f6a:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f6e:	8552                	mv	a0,s4
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	db4080e7          	jalr	-588(ra) # 80000d24 <release>
}
    80001f78:	8526                	mv	a0,s1
    80001f7a:	70e2                	ld	ra,56(sp)
    80001f7c:	7442                	ld	s0,48(sp)
    80001f7e:	74a2                	ld	s1,40(sp)
    80001f80:	7902                	ld	s2,32(sp)
    80001f82:	69e2                	ld	s3,24(sp)
    80001f84:	6a42                	ld	s4,16(sp)
    80001f86:	6aa2                	ld	s5,8(sp)
    80001f88:	6121                	addi	sp,sp,64
    80001f8a:	8082                	ret
    return -1;
    80001f8c:	54fd                	li	s1,-1
    80001f8e:	b7ed                	j	80001f78 <fork+0xf6>

0000000080001f90 <reparent>:
{
    80001f90:	7179                	addi	sp,sp,-48
    80001f92:	f406                	sd	ra,40(sp)
    80001f94:	f022                	sd	s0,32(sp)
    80001f96:	ec26                	sd	s1,24(sp)
    80001f98:	e84a                	sd	s2,16(sp)
    80001f9a:	e44e                	sd	s3,8(sp)
    80001f9c:	e052                	sd	s4,0(sp)
    80001f9e:	1800                	addi	s0,sp,48
    80001fa0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fa2:	00230497          	auipc	s1,0x230
    80001fa6:	dc648493          	addi	s1,s1,-570 # 80231d68 <proc>
      pp->parent = initproc;
    80001faa:	00007a17          	auipc	s4,0x7
    80001fae:	06ea0a13          	addi	s4,s4,110 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fb2:	00235997          	auipc	s3,0x235
    80001fb6:	7b698993          	addi	s3,s3,1974 # 80237768 <tickslock>
    80001fba:	a029                	j	80001fc4 <reparent+0x34>
    80001fbc:	16848493          	addi	s1,s1,360
    80001fc0:	03348363          	beq	s1,s3,80001fe6 <reparent+0x56>
    if(pp->parent == p){
    80001fc4:	709c                	ld	a5,32(s1)
    80001fc6:	ff279be3          	bne	a5,s2,80001fbc <reparent+0x2c>
      acquire(&pp->lock);
    80001fca:	8526                	mv	a0,s1
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	ca4080e7          	jalr	-860(ra) # 80000c70 <acquire>
      pp->parent = initproc;
    80001fd4:	000a3783          	ld	a5,0(s4)
    80001fd8:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fda:	8526                	mv	a0,s1
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	d48080e7          	jalr	-696(ra) # 80000d24 <release>
    80001fe4:	bfe1                	j	80001fbc <reparent+0x2c>
}
    80001fe6:	70a2                	ld	ra,40(sp)
    80001fe8:	7402                	ld	s0,32(sp)
    80001fea:	64e2                	ld	s1,24(sp)
    80001fec:	6942                	ld	s2,16(sp)
    80001fee:	69a2                	ld	s3,8(sp)
    80001ff0:	6a02                	ld	s4,0(sp)
    80001ff2:	6145                	addi	sp,sp,48
    80001ff4:	8082                	ret

0000000080001ff6 <scheduler>:
{
    80001ff6:	711d                	addi	sp,sp,-96
    80001ff8:	ec86                	sd	ra,88(sp)
    80001ffa:	e8a2                	sd	s0,80(sp)
    80001ffc:	e4a6                	sd	s1,72(sp)
    80001ffe:	e0ca                	sd	s2,64(sp)
    80002000:	fc4e                	sd	s3,56(sp)
    80002002:	f852                	sd	s4,48(sp)
    80002004:	f456                	sd	s5,40(sp)
    80002006:	f05a                	sd	s6,32(sp)
    80002008:	ec5e                	sd	s7,24(sp)
    8000200a:	e862                	sd	s8,16(sp)
    8000200c:	e466                	sd	s9,8(sp)
    8000200e:	1080                	addi	s0,sp,96
    80002010:	8792                	mv	a5,tp
  int id = r_tp();
    80002012:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002014:	00779c13          	slli	s8,a5,0x7
    80002018:	00230717          	auipc	a4,0x230
    8000201c:	93870713          	addi	a4,a4,-1736 # 80231950 <pid_lock>
    80002020:	9762                	add	a4,a4,s8
    80002022:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002026:	00230717          	auipc	a4,0x230
    8000202a:	94a70713          	addi	a4,a4,-1718 # 80231970 <cpus+0x8>
    8000202e:	9c3a                	add	s8,s8,a4
    int nproc = 0;
    80002030:	4c81                	li	s9,0
      if(p->state == RUNNABLE) {
    80002032:	4a89                	li	s5,2
        c->proc = p;
    80002034:	079e                	slli	a5,a5,0x7
    80002036:	00230b17          	auipc	s6,0x230
    8000203a:	91ab0b13          	addi	s6,s6,-1766 # 80231950 <pid_lock>
    8000203e:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002040:	00235a17          	auipc	s4,0x235
    80002044:	728a0a13          	addi	s4,s4,1832 # 80237768 <tickslock>
    80002048:	a8a1                	j	800020a0 <scheduler+0xaa>
      release(&p->lock);
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	cd8080e7          	jalr	-808(ra) # 80000d24 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002054:	16848493          	addi	s1,s1,360
    80002058:	03448a63          	beq	s1,s4,8000208c <scheduler+0x96>
      acquire(&p->lock);
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	c12080e7          	jalr	-1006(ra) # 80000c70 <acquire>
      if(p->state != UNUSED) {
    80002066:	4c9c                	lw	a5,24(s1)
    80002068:	d3ed                	beqz	a5,8000204a <scheduler+0x54>
        nproc++;
    8000206a:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    8000206c:	fd579fe3          	bne	a5,s5,8000204a <scheduler+0x54>
        p->state = RUNNING;
    80002070:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002074:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80002078:	06048593          	addi	a1,s1,96
    8000207c:	8562                	mv	a0,s8
    8000207e:	00000097          	auipc	ra,0x0
    80002082:	60c080e7          	jalr	1548(ra) # 8000268a <swtch>
        c->proc = 0;
    80002086:	000b3c23          	sd	zero,24(s6)
    8000208a:	b7c1                	j	8000204a <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    8000208c:	013aca63          	blt	s5,s3,800020a0 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002090:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002094:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002098:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000209c:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020a4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020a8:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800020ac:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800020ae:	00230497          	auipc	s1,0x230
    800020b2:	cba48493          	addi	s1,s1,-838 # 80231d68 <proc>
        p->state = RUNNING;
    800020b6:	4b8d                	li	s7,3
    800020b8:	b755                	j	8000205c <scheduler+0x66>

00000000800020ba <sched>:
{
    800020ba:	7179                	addi	sp,sp,-48
    800020bc:	f406                	sd	ra,40(sp)
    800020be:	f022                	sd	s0,32(sp)
    800020c0:	ec26                	sd	s1,24(sp)
    800020c2:	e84a                	sd	s2,16(sp)
    800020c4:	e44e                	sd	s3,8(sp)
    800020c6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	9fa080e7          	jalr	-1542(ra) # 80001ac2 <myproc>
    800020d0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b24080e7          	jalr	-1244(ra) # 80000bf6 <holding>
    800020da:	c93d                	beqz	a0,80002150 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020dc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020de:	2781                	sext.w	a5,a5
    800020e0:	079e                	slli	a5,a5,0x7
    800020e2:	00230717          	auipc	a4,0x230
    800020e6:	86e70713          	addi	a4,a4,-1938 # 80231950 <pid_lock>
    800020ea:	97ba                	add	a5,a5,a4
    800020ec:	0907a703          	lw	a4,144(a5)
    800020f0:	4785                	li	a5,1
    800020f2:	06f71763          	bne	a4,a5,80002160 <sched+0xa6>
  if(p->state == RUNNING)
    800020f6:	4c98                	lw	a4,24(s1)
    800020f8:	478d                	li	a5,3
    800020fa:	06f70b63          	beq	a4,a5,80002170 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020fe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002102:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002104:	efb5                	bnez	a5,80002180 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002106:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002108:	00230917          	auipc	s2,0x230
    8000210c:	84890913          	addi	s2,s2,-1976 # 80231950 <pid_lock>
    80002110:	2781                	sext.w	a5,a5
    80002112:	079e                	slli	a5,a5,0x7
    80002114:	97ca                	add	a5,a5,s2
    80002116:	0947a983          	lw	s3,148(a5)
    8000211a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000211c:	2781                	sext.w	a5,a5
    8000211e:	079e                	slli	a5,a5,0x7
    80002120:	00230597          	auipc	a1,0x230
    80002124:	85058593          	addi	a1,a1,-1968 # 80231970 <cpus+0x8>
    80002128:	95be                	add	a1,a1,a5
    8000212a:	06048513          	addi	a0,s1,96
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	55c080e7          	jalr	1372(ra) # 8000268a <swtch>
    80002136:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002138:	2781                	sext.w	a5,a5
    8000213a:	079e                	slli	a5,a5,0x7
    8000213c:	97ca                	add	a5,a5,s2
    8000213e:	0937aa23          	sw	s3,148(a5)
}
    80002142:	70a2                	ld	ra,40(sp)
    80002144:	7402                	ld	s0,32(sp)
    80002146:	64e2                	ld	s1,24(sp)
    80002148:	6942                	ld	s2,16(sp)
    8000214a:	69a2                	ld	s3,8(sp)
    8000214c:	6145                	addi	sp,sp,48
    8000214e:	8082                	ret
    panic("sched p->lock");
    80002150:	00006517          	auipc	a0,0x6
    80002154:	0b050513          	addi	a0,a0,176 # 80008200 <digits+0x1c0>
    80002158:	ffffe097          	auipc	ra,0xffffe
    8000215c:	3ea080e7          	jalr	1002(ra) # 80000542 <panic>
    panic("sched locks");
    80002160:	00006517          	auipc	a0,0x6
    80002164:	0b050513          	addi	a0,a0,176 # 80008210 <digits+0x1d0>
    80002168:	ffffe097          	auipc	ra,0xffffe
    8000216c:	3da080e7          	jalr	986(ra) # 80000542 <panic>
    panic("sched running");
    80002170:	00006517          	auipc	a0,0x6
    80002174:	0b050513          	addi	a0,a0,176 # 80008220 <digits+0x1e0>
    80002178:	ffffe097          	auipc	ra,0xffffe
    8000217c:	3ca080e7          	jalr	970(ra) # 80000542 <panic>
    panic("sched interruptible");
    80002180:	00006517          	auipc	a0,0x6
    80002184:	0b050513          	addi	a0,a0,176 # 80008230 <digits+0x1f0>
    80002188:	ffffe097          	auipc	ra,0xffffe
    8000218c:	3ba080e7          	jalr	954(ra) # 80000542 <panic>

0000000080002190 <exit>:
{
    80002190:	7179                	addi	sp,sp,-48
    80002192:	f406                	sd	ra,40(sp)
    80002194:	f022                	sd	s0,32(sp)
    80002196:	ec26                	sd	s1,24(sp)
    80002198:	e84a                	sd	s2,16(sp)
    8000219a:	e44e                	sd	s3,8(sp)
    8000219c:	e052                	sd	s4,0(sp)
    8000219e:	1800                	addi	s0,sp,48
    800021a0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021a2:	00000097          	auipc	ra,0x0
    800021a6:	920080e7          	jalr	-1760(ra) # 80001ac2 <myproc>
    800021aa:	89aa                	mv	s3,a0
  if(p == initproc)
    800021ac:	00007797          	auipc	a5,0x7
    800021b0:	e6c7b783          	ld	a5,-404(a5) # 80009018 <initproc>
    800021b4:	0d050493          	addi	s1,a0,208
    800021b8:	15050913          	addi	s2,a0,336
    800021bc:	02a79363          	bne	a5,a0,800021e2 <exit+0x52>
    panic("init exiting");
    800021c0:	00006517          	auipc	a0,0x6
    800021c4:	08850513          	addi	a0,a0,136 # 80008248 <digits+0x208>
    800021c8:	ffffe097          	auipc	ra,0xffffe
    800021cc:	37a080e7          	jalr	890(ra) # 80000542 <panic>
      fileclose(f);
    800021d0:	00002097          	auipc	ra,0x2
    800021d4:	44a080e7          	jalr	1098(ra) # 8000461a <fileclose>
      p->ofile[fd] = 0;
    800021d8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021dc:	04a1                	addi	s1,s1,8
    800021de:	01248563          	beq	s1,s2,800021e8 <exit+0x58>
    if(p->ofile[fd]){
    800021e2:	6088                	ld	a0,0(s1)
    800021e4:	f575                	bnez	a0,800021d0 <exit+0x40>
    800021e6:	bfdd                	j	800021dc <exit+0x4c>
  begin_op();
    800021e8:	00002097          	auipc	ra,0x2
    800021ec:	f60080e7          	jalr	-160(ra) # 80004148 <begin_op>
  iput(p->cwd);
    800021f0:	1509b503          	ld	a0,336(s3)
    800021f4:	00001097          	auipc	ra,0x1
    800021f8:	74e080e7          	jalr	1870(ra) # 80003942 <iput>
  end_op();
    800021fc:	00002097          	auipc	ra,0x2
    80002200:	fcc080e7          	jalr	-52(ra) # 800041c8 <end_op>
  p->cwd = 0;
    80002204:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002208:	00007497          	auipc	s1,0x7
    8000220c:	e1048493          	addi	s1,s1,-496 # 80009018 <initproc>
    80002210:	6088                	ld	a0,0(s1)
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a5e080e7          	jalr	-1442(ra) # 80000c70 <acquire>
  wakeup1(initproc);
    8000221a:	6088                	ld	a0,0(s1)
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	766080e7          	jalr	1894(ra) # 80001982 <wakeup1>
  release(&initproc->lock);
    80002224:	6088                	ld	a0,0(s1)
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	afe080e7          	jalr	-1282(ra) # 80000d24 <release>
  acquire(&p->lock);
    8000222e:	854e                	mv	a0,s3
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	a40080e7          	jalr	-1472(ra) # 80000c70 <acquire>
  struct proc *original_parent = p->parent;
    80002238:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000223c:	854e                	mv	a0,s3
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	ae6080e7          	jalr	-1306(ra) # 80000d24 <release>
  acquire(&original_parent->lock);
    80002246:	8526                	mv	a0,s1
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	a28080e7          	jalr	-1496(ra) # 80000c70 <acquire>
  acquire(&p->lock);
    80002250:	854e                	mv	a0,s3
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	a1e080e7          	jalr	-1506(ra) # 80000c70 <acquire>
  reparent(p);
    8000225a:	854e                	mv	a0,s3
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	d34080e7          	jalr	-716(ra) # 80001f90 <reparent>
  wakeup1(original_parent);
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	71c080e7          	jalr	1820(ra) # 80001982 <wakeup1>
  p->xstate = status;
    8000226e:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002272:	4791                	li	a5,4
    80002274:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	aaa080e7          	jalr	-1366(ra) # 80000d24 <release>
  sched();
    80002282:	00000097          	auipc	ra,0x0
    80002286:	e38080e7          	jalr	-456(ra) # 800020ba <sched>
  panic("zombie exit");
    8000228a:	00006517          	auipc	a0,0x6
    8000228e:	fce50513          	addi	a0,a0,-50 # 80008258 <digits+0x218>
    80002292:	ffffe097          	auipc	ra,0xffffe
    80002296:	2b0080e7          	jalr	688(ra) # 80000542 <panic>

000000008000229a <yield>:
{
    8000229a:	1101                	addi	sp,sp,-32
    8000229c:	ec06                	sd	ra,24(sp)
    8000229e:	e822                	sd	s0,16(sp)
    800022a0:	e426                	sd	s1,8(sp)
    800022a2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022a4:	00000097          	auipc	ra,0x0
    800022a8:	81e080e7          	jalr	-2018(ra) # 80001ac2 <myproc>
    800022ac:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	9c2080e7          	jalr	-1598(ra) # 80000c70 <acquire>
  p->state = RUNNABLE;
    800022b6:	4789                	li	a5,2
    800022b8:	cc9c                	sw	a5,24(s1)
  sched();
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	e00080e7          	jalr	-512(ra) # 800020ba <sched>
  release(&p->lock);
    800022c2:	8526                	mv	a0,s1
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	a60080e7          	jalr	-1440(ra) # 80000d24 <release>
}
    800022cc:	60e2                	ld	ra,24(sp)
    800022ce:	6442                	ld	s0,16(sp)
    800022d0:	64a2                	ld	s1,8(sp)
    800022d2:	6105                	addi	sp,sp,32
    800022d4:	8082                	ret

00000000800022d6 <sleep>:
{
    800022d6:	7179                	addi	sp,sp,-48
    800022d8:	f406                	sd	ra,40(sp)
    800022da:	f022                	sd	s0,32(sp)
    800022dc:	ec26                	sd	s1,24(sp)
    800022de:	e84a                	sd	s2,16(sp)
    800022e0:	e44e                	sd	s3,8(sp)
    800022e2:	1800                	addi	s0,sp,48
    800022e4:	89aa                	mv	s3,a0
    800022e6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	7da080e7          	jalr	2010(ra) # 80001ac2 <myproc>
    800022f0:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022f2:	05250663          	beq	a0,s2,8000233e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	97a080e7          	jalr	-1670(ra) # 80000c70 <acquire>
    release(lk);
    800022fe:	854a                	mv	a0,s2
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	a24080e7          	jalr	-1500(ra) # 80000d24 <release>
  p->chan = chan;
    80002308:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000230c:	4785                	li	a5,1
    8000230e:	cc9c                	sw	a5,24(s1)
  sched();
    80002310:	00000097          	auipc	ra,0x0
    80002314:	daa080e7          	jalr	-598(ra) # 800020ba <sched>
  p->chan = 0;
    80002318:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000231c:	8526                	mv	a0,s1
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	a06080e7          	jalr	-1530(ra) # 80000d24 <release>
    acquire(lk);
    80002326:	854a                	mv	a0,s2
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	948080e7          	jalr	-1720(ra) # 80000c70 <acquire>
}
    80002330:	70a2                	ld	ra,40(sp)
    80002332:	7402                	ld	s0,32(sp)
    80002334:	64e2                	ld	s1,24(sp)
    80002336:	6942                	ld	s2,16(sp)
    80002338:	69a2                	ld	s3,8(sp)
    8000233a:	6145                	addi	sp,sp,48
    8000233c:	8082                	ret
  p->chan = chan;
    8000233e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002342:	4785                	li	a5,1
    80002344:	cd1c                	sw	a5,24(a0)
  sched();
    80002346:	00000097          	auipc	ra,0x0
    8000234a:	d74080e7          	jalr	-652(ra) # 800020ba <sched>
  p->chan = 0;
    8000234e:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002352:	bff9                	j	80002330 <sleep+0x5a>

0000000080002354 <wait>:
{
    80002354:	715d                	addi	sp,sp,-80
    80002356:	e486                	sd	ra,72(sp)
    80002358:	e0a2                	sd	s0,64(sp)
    8000235a:	fc26                	sd	s1,56(sp)
    8000235c:	f84a                	sd	s2,48(sp)
    8000235e:	f44e                	sd	s3,40(sp)
    80002360:	f052                	sd	s4,32(sp)
    80002362:	ec56                	sd	s5,24(sp)
    80002364:	e85a                	sd	s6,16(sp)
    80002366:	e45e                	sd	s7,8(sp)
    80002368:	0880                	addi	s0,sp,80
    8000236a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	756080e7          	jalr	1878(ra) # 80001ac2 <myproc>
    80002374:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	8fa080e7          	jalr	-1798(ra) # 80000c70 <acquire>
    havekids = 0;
    8000237e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002380:	4a11                	li	s4,4
        havekids = 1;
    80002382:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002384:	00235997          	auipc	s3,0x235
    80002388:	3e498993          	addi	s3,s3,996 # 80237768 <tickslock>
    havekids = 0;
    8000238c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000238e:	00230497          	auipc	s1,0x230
    80002392:	9da48493          	addi	s1,s1,-1574 # 80231d68 <proc>
    80002396:	a08d                	j	800023f8 <wait+0xa4>
          pid = np->pid;
    80002398:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000239c:	000b0e63          	beqz	s6,800023b8 <wait+0x64>
    800023a0:	4691                	li	a3,4
    800023a2:	03448613          	addi	a2,s1,52
    800023a6:	85da                	mv	a1,s6
    800023a8:	05093503          	ld	a0,80(s2)
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	37a080e7          	jalr	890(ra) # 80001726 <copyout>
    800023b4:	02054263          	bltz	a0,800023d8 <wait+0x84>
          freeproc(np);
    800023b8:	8526                	mv	a0,s1
    800023ba:	00000097          	auipc	ra,0x0
    800023be:	8ba080e7          	jalr	-1862(ra) # 80001c74 <freeproc>
          release(&np->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	960080e7          	jalr	-1696(ra) # 80000d24 <release>
          release(&p->lock);
    800023cc:	854a                	mv	a0,s2
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	956080e7          	jalr	-1706(ra) # 80000d24 <release>
          return pid;
    800023d6:	a8a9                	j	80002430 <wait+0xdc>
            release(&np->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	94a080e7          	jalr	-1718(ra) # 80000d24 <release>
            release(&p->lock);
    800023e2:	854a                	mv	a0,s2
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	940080e7          	jalr	-1728(ra) # 80000d24 <release>
            return -1;
    800023ec:	59fd                	li	s3,-1
    800023ee:	a089                	j	80002430 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    800023f0:	16848493          	addi	s1,s1,360
    800023f4:	03348463          	beq	s1,s3,8000241c <wait+0xc8>
      if(np->parent == p){
    800023f8:	709c                	ld	a5,32(s1)
    800023fa:	ff279be3          	bne	a5,s2,800023f0 <wait+0x9c>
        acquire(&np->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	870080e7          	jalr	-1936(ra) # 80000c70 <acquire>
        if(np->state == ZOMBIE){
    80002408:	4c9c                	lw	a5,24(s1)
    8000240a:	f94787e3          	beq	a5,s4,80002398 <wait+0x44>
        release(&np->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	914080e7          	jalr	-1772(ra) # 80000d24 <release>
        havekids = 1;
    80002418:	8756                	mv	a4,s5
    8000241a:	bfd9                	j	800023f0 <wait+0x9c>
    if(!havekids || p->killed){
    8000241c:	c701                	beqz	a4,80002424 <wait+0xd0>
    8000241e:	03092783          	lw	a5,48(s2)
    80002422:	c39d                	beqz	a5,80002448 <wait+0xf4>
      release(&p->lock);
    80002424:	854a                	mv	a0,s2
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	8fe080e7          	jalr	-1794(ra) # 80000d24 <release>
      return -1;
    8000242e:	59fd                	li	s3,-1
}
    80002430:	854e                	mv	a0,s3
    80002432:	60a6                	ld	ra,72(sp)
    80002434:	6406                	ld	s0,64(sp)
    80002436:	74e2                	ld	s1,56(sp)
    80002438:	7942                	ld	s2,48(sp)
    8000243a:	79a2                	ld	s3,40(sp)
    8000243c:	7a02                	ld	s4,32(sp)
    8000243e:	6ae2                	ld	s5,24(sp)
    80002440:	6b42                	ld	s6,16(sp)
    80002442:	6ba2                	ld	s7,8(sp)
    80002444:	6161                	addi	sp,sp,80
    80002446:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002448:	85ca                	mv	a1,s2
    8000244a:	854a                	mv	a0,s2
    8000244c:	00000097          	auipc	ra,0x0
    80002450:	e8a080e7          	jalr	-374(ra) # 800022d6 <sleep>
    havekids = 0;
    80002454:	bf25                	j	8000238c <wait+0x38>

0000000080002456 <wakeup>:
{
    80002456:	7139                	addi	sp,sp,-64
    80002458:	fc06                	sd	ra,56(sp)
    8000245a:	f822                	sd	s0,48(sp)
    8000245c:	f426                	sd	s1,40(sp)
    8000245e:	f04a                	sd	s2,32(sp)
    80002460:	ec4e                	sd	s3,24(sp)
    80002462:	e852                	sd	s4,16(sp)
    80002464:	e456                	sd	s5,8(sp)
    80002466:	0080                	addi	s0,sp,64
    80002468:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000246a:	00230497          	auipc	s1,0x230
    8000246e:	8fe48493          	addi	s1,s1,-1794 # 80231d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002472:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002474:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002476:	00235917          	auipc	s2,0x235
    8000247a:	2f290913          	addi	s2,s2,754 # 80237768 <tickslock>
    8000247e:	a811                	j	80002492 <wakeup+0x3c>
    release(&p->lock);
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	8a2080e7          	jalr	-1886(ra) # 80000d24 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000248a:	16848493          	addi	s1,s1,360
    8000248e:	03248063          	beq	s1,s2,800024ae <wakeup+0x58>
    acquire(&p->lock);
    80002492:	8526                	mv	a0,s1
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	7dc080e7          	jalr	2012(ra) # 80000c70 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000249c:	4c9c                	lw	a5,24(s1)
    8000249e:	ff3791e3          	bne	a5,s3,80002480 <wakeup+0x2a>
    800024a2:	749c                	ld	a5,40(s1)
    800024a4:	fd479ee3          	bne	a5,s4,80002480 <wakeup+0x2a>
      p->state = RUNNABLE;
    800024a8:	0154ac23          	sw	s5,24(s1)
    800024ac:	bfd1                	j	80002480 <wakeup+0x2a>
}
    800024ae:	70e2                	ld	ra,56(sp)
    800024b0:	7442                	ld	s0,48(sp)
    800024b2:	74a2                	ld	s1,40(sp)
    800024b4:	7902                	ld	s2,32(sp)
    800024b6:	69e2                	ld	s3,24(sp)
    800024b8:	6a42                	ld	s4,16(sp)
    800024ba:	6aa2                	ld	s5,8(sp)
    800024bc:	6121                	addi	sp,sp,64
    800024be:	8082                	ret

00000000800024c0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024c0:	7179                	addi	sp,sp,-48
    800024c2:	f406                	sd	ra,40(sp)
    800024c4:	f022                	sd	s0,32(sp)
    800024c6:	ec26                	sd	s1,24(sp)
    800024c8:	e84a                	sd	s2,16(sp)
    800024ca:	e44e                	sd	s3,8(sp)
    800024cc:	1800                	addi	s0,sp,48
    800024ce:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024d0:	00230497          	auipc	s1,0x230
    800024d4:	89848493          	addi	s1,s1,-1896 # 80231d68 <proc>
    800024d8:	00235997          	auipc	s3,0x235
    800024dc:	29098993          	addi	s3,s3,656 # 80237768 <tickslock>
    acquire(&p->lock);
    800024e0:	8526                	mv	a0,s1
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	78e080e7          	jalr	1934(ra) # 80000c70 <acquire>
    if(p->pid == pid){
    800024ea:	5c9c                	lw	a5,56(s1)
    800024ec:	01278d63          	beq	a5,s2,80002506 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024f0:	8526                	mv	a0,s1
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	832080e7          	jalr	-1998(ra) # 80000d24 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024fa:	16848493          	addi	s1,s1,360
    800024fe:	ff3491e3          	bne	s1,s3,800024e0 <kill+0x20>
  }
  return -1;
    80002502:	557d                	li	a0,-1
    80002504:	a821                	j	8000251c <kill+0x5c>
      p->killed = 1;
    80002506:	4785                	li	a5,1
    80002508:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000250a:	4c98                	lw	a4,24(s1)
    8000250c:	00f70f63          	beq	a4,a5,8000252a <kill+0x6a>
      release(&p->lock);
    80002510:	8526                	mv	a0,s1
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	812080e7          	jalr	-2030(ra) # 80000d24 <release>
      return 0;
    8000251a:	4501                	li	a0,0
}
    8000251c:	70a2                	ld	ra,40(sp)
    8000251e:	7402                	ld	s0,32(sp)
    80002520:	64e2                	ld	s1,24(sp)
    80002522:	6942                	ld	s2,16(sp)
    80002524:	69a2                	ld	s3,8(sp)
    80002526:	6145                	addi	sp,sp,48
    80002528:	8082                	ret
        p->state = RUNNABLE;
    8000252a:	4789                	li	a5,2
    8000252c:	cc9c                	sw	a5,24(s1)
    8000252e:	b7cd                	j	80002510 <kill+0x50>

0000000080002530 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002530:	7179                	addi	sp,sp,-48
    80002532:	f406                	sd	ra,40(sp)
    80002534:	f022                	sd	s0,32(sp)
    80002536:	ec26                	sd	s1,24(sp)
    80002538:	e84a                	sd	s2,16(sp)
    8000253a:	e44e                	sd	s3,8(sp)
    8000253c:	e052                	sd	s4,0(sp)
    8000253e:	1800                	addi	s0,sp,48
    80002540:	84aa                	mv	s1,a0
    80002542:	892e                	mv	s2,a1
    80002544:	89b2                	mv	s3,a2
    80002546:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	57a080e7          	jalr	1402(ra) # 80001ac2 <myproc>
  if(user_dst){
    80002550:	c08d                	beqz	s1,80002572 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002552:	86d2                	mv	a3,s4
    80002554:	864e                	mv	a2,s3
    80002556:	85ca                	mv	a1,s2
    80002558:	6928                	ld	a0,80(a0)
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	1cc080e7          	jalr	460(ra) # 80001726 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002562:	70a2                	ld	ra,40(sp)
    80002564:	7402                	ld	s0,32(sp)
    80002566:	64e2                	ld	s1,24(sp)
    80002568:	6942                	ld	s2,16(sp)
    8000256a:	69a2                	ld	s3,8(sp)
    8000256c:	6a02                	ld	s4,0(sp)
    8000256e:	6145                	addi	sp,sp,48
    80002570:	8082                	ret
    memmove((char *)dst, src, len);
    80002572:	000a061b          	sext.w	a2,s4
    80002576:	85ce                	mv	a1,s3
    80002578:	854a                	mv	a0,s2
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	84e080e7          	jalr	-1970(ra) # 80000dc8 <memmove>
    return 0;
    80002582:	8526                	mv	a0,s1
    80002584:	bff9                	j	80002562 <either_copyout+0x32>

0000000080002586 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002586:	7179                	addi	sp,sp,-48
    80002588:	f406                	sd	ra,40(sp)
    8000258a:	f022                	sd	s0,32(sp)
    8000258c:	ec26                	sd	s1,24(sp)
    8000258e:	e84a                	sd	s2,16(sp)
    80002590:	e44e                	sd	s3,8(sp)
    80002592:	e052                	sd	s4,0(sp)
    80002594:	1800                	addi	s0,sp,48
    80002596:	892a                	mv	s2,a0
    80002598:	84ae                	mv	s1,a1
    8000259a:	89b2                	mv	s3,a2
    8000259c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000259e:	fffff097          	auipc	ra,0xfffff
    800025a2:	524080e7          	jalr	1316(ra) # 80001ac2 <myproc>
  if(user_src){
    800025a6:	c08d                	beqz	s1,800025c8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025a8:	86d2                	mv	a3,s4
    800025aa:	864e                	mv	a2,s3
    800025ac:	85ca                	mv	a1,s2
    800025ae:	6928                	ld	a0,80(a0)
    800025b0:	fffff097          	auipc	ra,0xfffff
    800025b4:	290080e7          	jalr	656(ra) # 80001840 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025b8:	70a2                	ld	ra,40(sp)
    800025ba:	7402                	ld	s0,32(sp)
    800025bc:	64e2                	ld	s1,24(sp)
    800025be:	6942                	ld	s2,16(sp)
    800025c0:	69a2                	ld	s3,8(sp)
    800025c2:	6a02                	ld	s4,0(sp)
    800025c4:	6145                	addi	sp,sp,48
    800025c6:	8082                	ret
    memmove(dst, (char*)src, len);
    800025c8:	000a061b          	sext.w	a2,s4
    800025cc:	85ce                	mv	a1,s3
    800025ce:	854a                	mv	a0,s2
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	7f8080e7          	jalr	2040(ra) # 80000dc8 <memmove>
    return 0;
    800025d8:	8526                	mv	a0,s1
    800025da:	bff9                	j	800025b8 <either_copyin+0x32>

00000000800025dc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025dc:	715d                	addi	sp,sp,-80
    800025de:	e486                	sd	ra,72(sp)
    800025e0:	e0a2                	sd	s0,64(sp)
    800025e2:	fc26                	sd	s1,56(sp)
    800025e4:	f84a                	sd	s2,48(sp)
    800025e6:	f44e                	sd	s3,40(sp)
    800025e8:	f052                	sd	s4,32(sp)
    800025ea:	ec56                	sd	s5,24(sp)
    800025ec:	e85a                	sd	s6,16(sp)
    800025ee:	e45e                	sd	s7,8(sp)
    800025f0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025f2:	00006517          	auipc	a0,0x6
    800025f6:	ad650513          	addi	a0,a0,-1322 # 800080c8 <digits+0x88>
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	f92080e7          	jalr	-110(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002602:	00230497          	auipc	s1,0x230
    80002606:	8be48493          	addi	s1,s1,-1858 # 80231ec0 <proc+0x158>
    8000260a:	00235917          	auipc	s2,0x235
    8000260e:	2b690913          	addi	s2,s2,694 # 802378c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002612:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002614:	00006997          	auipc	s3,0x6
    80002618:	c5498993          	addi	s3,s3,-940 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000261c:	00006a97          	auipc	s5,0x6
    80002620:	c54a8a93          	addi	s5,s5,-940 # 80008270 <digits+0x230>
    printf("\n");
    80002624:	00006a17          	auipc	s4,0x6
    80002628:	aa4a0a13          	addi	s4,s4,-1372 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262c:	00006b97          	auipc	s7,0x6
    80002630:	c7cb8b93          	addi	s7,s7,-900 # 800082a8 <states.0>
    80002634:	a00d                	j	80002656 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002636:	ee06a583          	lw	a1,-288(a3)
    8000263a:	8556                	mv	a0,s5
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	f50080e7          	jalr	-176(ra) # 8000058c <printf>
    printf("\n");
    80002644:	8552                	mv	a0,s4
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	f46080e7          	jalr	-186(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000264e:	16848493          	addi	s1,s1,360
    80002652:	03248163          	beq	s1,s2,80002674 <procdump+0x98>
    if(p->state == UNUSED)
    80002656:	86a6                	mv	a3,s1
    80002658:	ec04a783          	lw	a5,-320(s1)
    8000265c:	dbed                	beqz	a5,8000264e <procdump+0x72>
      state = "???";
    8000265e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002660:	fcfb6be3          	bltu	s6,a5,80002636 <procdump+0x5a>
    80002664:	1782                	slli	a5,a5,0x20
    80002666:	9381                	srli	a5,a5,0x20
    80002668:	078e                	slli	a5,a5,0x3
    8000266a:	97de                	add	a5,a5,s7
    8000266c:	6390                	ld	a2,0(a5)
    8000266e:	f661                	bnez	a2,80002636 <procdump+0x5a>
      state = "???";
    80002670:	864e                	mv	a2,s3
    80002672:	b7d1                	j	80002636 <procdump+0x5a>
  }
}
    80002674:	60a6                	ld	ra,72(sp)
    80002676:	6406                	ld	s0,64(sp)
    80002678:	74e2                	ld	s1,56(sp)
    8000267a:	7942                	ld	s2,48(sp)
    8000267c:	79a2                	ld	s3,40(sp)
    8000267e:	7a02                	ld	s4,32(sp)
    80002680:	6ae2                	ld	s5,24(sp)
    80002682:	6b42                	ld	s6,16(sp)
    80002684:	6ba2                	ld	s7,8(sp)
    80002686:	6161                	addi	sp,sp,80
    80002688:	8082                	ret

000000008000268a <swtch>:
    8000268a:	00153023          	sd	ra,0(a0)
    8000268e:	00253423          	sd	sp,8(a0)
    80002692:	e900                	sd	s0,16(a0)
    80002694:	ed04                	sd	s1,24(a0)
    80002696:	03253023          	sd	s2,32(a0)
    8000269a:	03353423          	sd	s3,40(a0)
    8000269e:	03453823          	sd	s4,48(a0)
    800026a2:	03553c23          	sd	s5,56(a0)
    800026a6:	05653023          	sd	s6,64(a0)
    800026aa:	05753423          	sd	s7,72(a0)
    800026ae:	05853823          	sd	s8,80(a0)
    800026b2:	05953c23          	sd	s9,88(a0)
    800026b6:	07a53023          	sd	s10,96(a0)
    800026ba:	07b53423          	sd	s11,104(a0)
    800026be:	0005b083          	ld	ra,0(a1)
    800026c2:	0085b103          	ld	sp,8(a1)
    800026c6:	6980                	ld	s0,16(a1)
    800026c8:	6d84                	ld	s1,24(a1)
    800026ca:	0205b903          	ld	s2,32(a1)
    800026ce:	0285b983          	ld	s3,40(a1)
    800026d2:	0305ba03          	ld	s4,48(a1)
    800026d6:	0385ba83          	ld	s5,56(a1)
    800026da:	0405bb03          	ld	s6,64(a1)
    800026de:	0485bb83          	ld	s7,72(a1)
    800026e2:	0505bc03          	ld	s8,80(a1)
    800026e6:	0585bc83          	ld	s9,88(a1)
    800026ea:	0605bd03          	ld	s10,96(a1)
    800026ee:	0685bd83          	ld	s11,104(a1)
    800026f2:	8082                	ret

00000000800026f4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f4:	1141                	addi	sp,sp,-16
    800026f6:	e406                	sd	ra,8(sp)
    800026f8:	e022                	sd	s0,0(sp)
    800026fa:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fc:	00006597          	auipc	a1,0x6
    80002700:	bd458593          	addi	a1,a1,-1068 # 800082d0 <states.0+0x28>
    80002704:	00235517          	auipc	a0,0x235
    80002708:	06450513          	addi	a0,a0,100 # 80237768 <tickslock>
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	4d4080e7          	jalr	1236(ra) # 80000be0 <initlock>
}
    80002714:	60a2                	ld	ra,8(sp)
    80002716:	6402                	ld	s0,0(sp)
    80002718:	0141                	addi	sp,sp,16
    8000271a:	8082                	ret

000000008000271c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271c:	1141                	addi	sp,sp,-16
    8000271e:	e422                	sd	s0,8(sp)
    80002720:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002722:	00003797          	auipc	a5,0x3
    80002726:	54e78793          	addi	a5,a5,1358 # 80005c70 <kernelvec>
    8000272a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000272e:	6422                	ld	s0,8(sp)
    80002730:	0141                	addi	sp,sp,16
    80002732:	8082                	ret

0000000080002734 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002734:	1141                	addi	sp,sp,-16
    80002736:	e406                	sd	ra,8(sp)
    80002738:	e022                	sd	s0,0(sp)
    8000273a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273c:	fffff097          	auipc	ra,0xfffff
    80002740:	386080e7          	jalr	902(ra) # 80001ac2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002744:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002748:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000274a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000274e:	00005617          	auipc	a2,0x5
    80002752:	8b260613          	addi	a2,a2,-1870 # 80007000 <_trampoline>
    80002756:	00005697          	auipc	a3,0x5
    8000275a:	8aa68693          	addi	a3,a3,-1878 # 80007000 <_trampoline>
    8000275e:	8e91                	sub	a3,a3,a2
    80002760:	040007b7          	lui	a5,0x4000
    80002764:	17fd                	addi	a5,a5,-1
    80002766:	07b2                	slli	a5,a5,0xc
    80002768:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000276a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000276e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002770:	180026f3          	csrr	a3,satp
    80002774:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002776:	6d38                	ld	a4,88(a0)
    80002778:	6134                	ld	a3,64(a0)
    8000277a:	6585                	lui	a1,0x1
    8000277c:	96ae                	add	a3,a3,a1
    8000277e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002780:	6d38                	ld	a4,88(a0)
    80002782:	00000697          	auipc	a3,0x0
    80002786:	13868693          	addi	a3,a3,312 # 800028ba <usertrap>
    8000278a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000278e:	8692                	mv	a3,tp
    80002790:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002792:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002796:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000279a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a4:	6f18                	ld	a4,24(a4)
    800027a6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027aa:	692c                	ld	a1,80(a0)
    800027ac:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027ae:	00005717          	auipc	a4,0x5
    800027b2:	8e270713          	addi	a4,a4,-1822 # 80007090 <userret>
    800027b6:	8f11                	sub	a4,a4,a2
    800027b8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027ba:	577d                	li	a4,-1
    800027bc:	177e                	slli	a4,a4,0x3f
    800027be:	8dd9                	or	a1,a1,a4
    800027c0:	02000537          	lui	a0,0x2000
    800027c4:	157d                	addi	a0,a0,-1
    800027c6:	0536                	slli	a0,a0,0xd
    800027c8:	9782                	jalr	a5
}
    800027ca:	60a2                	ld	ra,8(sp)
    800027cc:	6402                	ld	s0,0(sp)
    800027ce:	0141                	addi	sp,sp,16
    800027d0:	8082                	ret

00000000800027d2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d2:	1101                	addi	sp,sp,-32
    800027d4:	ec06                	sd	ra,24(sp)
    800027d6:	e822                	sd	s0,16(sp)
    800027d8:	e426                	sd	s1,8(sp)
    800027da:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027dc:	00235497          	auipc	s1,0x235
    800027e0:	f8c48493          	addi	s1,s1,-116 # 80237768 <tickslock>
    800027e4:	8526                	mv	a0,s1
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	48a080e7          	jalr	1162(ra) # 80000c70 <acquire>
  ticks++;
    800027ee:	00007517          	auipc	a0,0x7
    800027f2:	83250513          	addi	a0,a0,-1998 # 80009020 <ticks>
    800027f6:	411c                	lw	a5,0(a0)
    800027f8:	2785                	addiw	a5,a5,1
    800027fa:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027fc:	00000097          	auipc	ra,0x0
    80002800:	c5a080e7          	jalr	-934(ra) # 80002456 <wakeup>
  release(&tickslock);
    80002804:	8526                	mv	a0,s1
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	51e080e7          	jalr	1310(ra) # 80000d24 <release>
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret

0000000080002818 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002818:	1101                	addi	sp,sp,-32
    8000281a:	ec06                	sd	ra,24(sp)
    8000281c:	e822                	sd	s0,16(sp)
    8000281e:	e426                	sd	s1,8(sp)
    80002820:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002822:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002826:	00074d63          	bltz	a4,80002840 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000282a:	57fd                	li	a5,-1
    8000282c:	17fe                	slli	a5,a5,0x3f
    8000282e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002830:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002832:	06f70363          	beq	a4,a5,80002898 <devintr+0x80>
  }
}
    80002836:	60e2                	ld	ra,24(sp)
    80002838:	6442                	ld	s0,16(sp)
    8000283a:	64a2                	ld	s1,8(sp)
    8000283c:	6105                	addi	sp,sp,32
    8000283e:	8082                	ret
     (scause & 0xff) == 9){
    80002840:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002844:	46a5                	li	a3,9
    80002846:	fed792e3          	bne	a5,a3,8000282a <devintr+0x12>
    int irq = plic_claim();
    8000284a:	00003097          	auipc	ra,0x3
    8000284e:	52e080e7          	jalr	1326(ra) # 80005d78 <plic_claim>
    80002852:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002854:	47a9                	li	a5,10
    80002856:	02f50763          	beq	a0,a5,80002884 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000285a:	4785                	li	a5,1
    8000285c:	02f50963          	beq	a0,a5,8000288e <devintr+0x76>
    return 1;
    80002860:	4505                	li	a0,1
    } else if(irq){
    80002862:	d8f1                	beqz	s1,80002836 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002864:	85a6                	mv	a1,s1
    80002866:	00006517          	auipc	a0,0x6
    8000286a:	a7250513          	addi	a0,a0,-1422 # 800082d8 <states.0+0x30>
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	d1e080e7          	jalr	-738(ra) # 8000058c <printf>
      plic_complete(irq);
    80002876:	8526                	mv	a0,s1
    80002878:	00003097          	auipc	ra,0x3
    8000287c:	524080e7          	jalr	1316(ra) # 80005d9c <plic_complete>
    return 1;
    80002880:	4505                	li	a0,1
    80002882:	bf55                	j	80002836 <devintr+0x1e>
      uartintr();
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	13e080e7          	jalr	318(ra) # 800009c2 <uartintr>
    8000288c:	b7ed                	j	80002876 <devintr+0x5e>
      virtio_disk_intr();
    8000288e:	00004097          	auipc	ra,0x4
    80002892:	988080e7          	jalr	-1656(ra) # 80006216 <virtio_disk_intr>
    80002896:	b7c5                	j	80002876 <devintr+0x5e>
    if(cpuid() == 0){
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	1fe080e7          	jalr	510(ra) # 80001a96 <cpuid>
    800028a0:	c901                	beqz	a0,800028b0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028a6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028a8:	14479073          	csrw	sip,a5
    return 2;
    800028ac:	4509                	li	a0,2
    800028ae:	b761                	j	80002836 <devintr+0x1e>
      clockintr();
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	f22080e7          	jalr	-222(ra) # 800027d2 <clockintr>
    800028b8:	b7ed                	j	800028a2 <devintr+0x8a>

00000000800028ba <usertrap>:
{
    800028ba:	7139                	addi	sp,sp,-64
    800028bc:	fc06                	sd	ra,56(sp)
    800028be:	f822                	sd	s0,48(sp)
    800028c0:	f426                	sd	s1,40(sp)
    800028c2:	f04a                	sd	s2,32(sp)
    800028c4:	ec4e                	sd	s3,24(sp)
    800028c6:	e852                	sd	s4,16(sp)
    800028c8:	e456                	sd	s5,8(sp)
    800028ca:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028cc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028d0:	1007f793          	andi	a5,a5,256
    800028d4:	e7ad                	bnez	a5,8000293e <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d6:	00003797          	auipc	a5,0x3
    800028da:	39a78793          	addi	a5,a5,922 # 80005c70 <kernelvec>
    800028de:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028e2:	fffff097          	auipc	ra,0xfffff
    800028e6:	1e0080e7          	jalr	480(ra) # 80001ac2 <myproc>
    800028ea:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ec:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ee:	14102773          	csrr	a4,sepc
    800028f2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f8:	47a1                	li	a5,8
    800028fa:	06f71063          	bne	a4,a5,8000295a <usertrap+0xa0>
    if(p->killed)
    800028fe:	591c                	lw	a5,48(a0)
    80002900:	e7b9                	bnez	a5,8000294e <usertrap+0x94>
    p->trapframe->epc += 4;
    80002902:	6cb8                	ld	a4,88(s1)
    80002904:	6f1c                	ld	a5,24(a4)
    80002906:	0791                	addi	a5,a5,4
    80002908:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002912:	10079073          	csrw	sstatus,a5
    syscall();
    80002916:	00000097          	auipc	ra,0x0
    8000291a:	376080e7          	jalr	886(ra) # 80002c8c <syscall>
  if(p->killed)
    8000291e:	589c                	lw	a5,48(s1)
    80002920:	12079363          	bnez	a5,80002a46 <usertrap+0x18c>
  usertrapret();
    80002924:	00000097          	auipc	ra,0x0
    80002928:	e10080e7          	jalr	-496(ra) # 80002734 <usertrapret>
}
    8000292c:	70e2                	ld	ra,56(sp)
    8000292e:	7442                	ld	s0,48(sp)
    80002930:	74a2                	ld	s1,40(sp)
    80002932:	7902                	ld	s2,32(sp)
    80002934:	69e2                	ld	s3,24(sp)
    80002936:	6a42                	ld	s4,16(sp)
    80002938:	6aa2                	ld	s5,8(sp)
    8000293a:	6121                	addi	sp,sp,64
    8000293c:	8082                	ret
    panic("usertrap: not from user mode");
    8000293e:	00006517          	auipc	a0,0x6
    80002942:	9ba50513          	addi	a0,a0,-1606 # 800082f8 <states.0+0x50>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	bfc080e7          	jalr	-1028(ra) # 80000542 <panic>
      exit(-1);
    8000294e:	557d                	li	a0,-1
    80002950:	00000097          	auipc	ra,0x0
    80002954:	840080e7          	jalr	-1984(ra) # 80002190 <exit>
    80002958:	b76d                	j	80002902 <usertrap+0x48>
  } else if((which_dev = devintr()) != 0){
    8000295a:	00000097          	auipc	ra,0x0
    8000295e:	ebe080e7          	jalr	-322(ra) # 80002818 <devintr>
    80002962:	892a                	mv	s2,a0
    80002964:	ed71                	bnez	a0,80002a40 <usertrap+0x186>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002966:	14202773          	csrr	a4,scause
  else if(r_scause()==13||r_scause()==15)
    8000296a:	47b5                	li	a5,13
    8000296c:	00f70763          	beq	a4,a5,8000297a <usertrap+0xc0>
    80002970:	14202773          	csrr	a4,scause
    80002974:	47bd                	li	a5,15
    80002976:	06f71f63          	bne	a4,a5,800029f4 <usertrap+0x13a>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000297a:	143025f3          	csrr	a1,stval
    pte_t *pte=walk(p->pagetable,addr,0);
    8000297e:	4601                	li	a2,0
    80002980:	77fd                	lui	a5,0xfffff
    80002982:	8dfd                	and	a1,a1,a5
    80002984:	68a8                	ld	a0,80(s1)
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	6ce080e7          	jalr	1742(ra) # 80001054 <walk>
    8000298e:	89aa                	mv	s3,a0
    if(pte==0)
    80002990:	cd01                	beqz	a0,800029a8 <usertrap+0xee>
    if((PTE_FLAGS(*pte))&PTE_COW && (*pte&PTE_V)!=0)
    80002992:	00053a03          	ld	s4,0(a0)
    80002996:	101a7713          	andi	a4,s4,257
    8000299a:	10100793          	li	a5,257
    8000299e:	00f70863          	beq	a4,a5,800029ae <usertrap+0xf4>
      p->killed=1;
    800029a2:	4785                	li	a5,1
    800029a4:	d89c                	sw	a5,48(s1)
    800029a6:	a041                	j	80002a26 <usertrap+0x16c>
      p->killed=1;
    800029a8:	4785                	li	a5,1
    800029aa:	d89c                	sw	a5,48(s1)
    800029ac:	a8ad                	j	80002a26 <usertrap+0x16c>
      char* mem=kalloc();
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	19c080e7          	jalr	412(ra) # 80000b4a <kalloc>
    800029b6:	8aaa                	mv	s5,a0
      if(mem==0)
    800029b8:	c91d                	beqz	a0,800029ee <usertrap+0x134>
      uint64 pa=PTE2PA(*pte);
    800029ba:	00aa5913          	srli	s2,s4,0xa
    800029be:	0932                	slli	s2,s2,0xc
      memmove(mem,(char*)pa,PGSIZE);
    800029c0:	6605                	lui	a2,0x1
    800029c2:	85ca                	mv	a1,s2
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	404080e7          	jalr	1028(ra) # 80000dc8 <memmove>
      *pte=PA2PTE(mem)|flags;
    800029cc:	00cad793          	srli	a5,s5,0xc
    800029d0:	00a79713          	slli	a4,a5,0xa
      uint flags=(PTE_FLAGS(*pte)|PTE_W)&(~PTE_COW);
    800029d4:	2fba7793          	andi	a5,s4,763
      *pte=PA2PTE(mem)|flags;
    800029d8:	0047e793          	ori	a5,a5,4
    800029dc:	8fd9                	or	a5,a5,a4
    800029de:	00f9b023          	sd	a5,0(s3)
      kfree((void*)pa);
    800029e2:	854a                	mv	a0,s2
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	02e080e7          	jalr	46(ra) # 80000a12 <kfree>
    800029ec:	bf0d                	j	8000291e <usertrap+0x64>
      p->killed=1;
    800029ee:	4785                	li	a5,1
    800029f0:	d89c                	sw	a5,48(s1)
    800029f2:	a815                	j	80002a26 <usertrap+0x16c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029f8:	5c90                	lw	a2,56(s1)
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	91e50513          	addi	a0,a0,-1762 # 80008318 <states.0+0x70>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b8a080e7          	jalr	-1142(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a0a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a0e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	93650513          	addi	a0,a0,-1738 # 80008348 <states.0+0xa0>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b72080e7          	jalr	-1166(ra) # 8000058c <printf>
    p->killed = 1;
    80002a22:	4785                	li	a5,1
    80002a24:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002a26:	557d                	li	a0,-1
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	768080e7          	jalr	1896(ra) # 80002190 <exit>
  if(which_dev == 2)
    80002a30:	4789                	li	a5,2
    80002a32:	eef919e3          	bne	s2,a5,80002924 <usertrap+0x6a>
    yield();
    80002a36:	00000097          	auipc	ra,0x0
    80002a3a:	864080e7          	jalr	-1948(ra) # 8000229a <yield>
    80002a3e:	b5dd                	j	80002924 <usertrap+0x6a>
  if(p->killed)
    80002a40:	589c                	lw	a5,48(s1)
    80002a42:	d7fd                	beqz	a5,80002a30 <usertrap+0x176>
    80002a44:	b7cd                	j	80002a26 <usertrap+0x16c>
    80002a46:	4901                	li	s2,0
    80002a48:	bff9                	j	80002a26 <usertrap+0x16c>

0000000080002a4a <kerneltrap>:
{
    80002a4a:	7179                	addi	sp,sp,-48
    80002a4c:	f406                	sd	ra,40(sp)
    80002a4e:	f022                	sd	s0,32(sp)
    80002a50:	ec26                	sd	s1,24(sp)
    80002a52:	e84a                	sd	s2,16(sp)
    80002a54:	e44e                	sd	s3,8(sp)
    80002a56:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a58:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a60:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a64:	1004f793          	andi	a5,s1,256
    80002a68:	cb85                	beqz	a5,80002a98 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a6e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a70:	ef85                	bnez	a5,80002aa8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	da6080e7          	jalr	-602(ra) # 80002818 <devintr>
    80002a7a:	cd1d                	beqz	a0,80002ab8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a7c:	4789                	li	a5,2
    80002a7e:	06f50a63          	beq	a0,a5,80002af2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a82:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a86:	10049073          	csrw	sstatus,s1
}
    80002a8a:	70a2                	ld	ra,40(sp)
    80002a8c:	7402                	ld	s0,32(sp)
    80002a8e:	64e2                	ld	s1,24(sp)
    80002a90:	6942                	ld	s2,16(sp)
    80002a92:	69a2                	ld	s3,8(sp)
    80002a94:	6145                	addi	sp,sp,48
    80002a96:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	8d050513          	addi	a0,a0,-1840 # 80008368 <states.0+0xc0>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	aa2080e7          	jalr	-1374(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    80002aa8:	00006517          	auipc	a0,0x6
    80002aac:	8e850513          	addi	a0,a0,-1816 # 80008390 <states.0+0xe8>
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	a92080e7          	jalr	-1390(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002ab8:	85ce                	mv	a1,s3
    80002aba:	00006517          	auipc	a0,0x6
    80002abe:	8f650513          	addi	a0,a0,-1802 # 800083b0 <states.0+0x108>
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	aca080e7          	jalr	-1334(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aca:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ace:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ad2:	00006517          	auipc	a0,0x6
    80002ad6:	8ee50513          	addi	a0,a0,-1810 # 800083c0 <states.0+0x118>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	ab2080e7          	jalr	-1358(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002ae2:	00006517          	auipc	a0,0x6
    80002ae6:	8f650513          	addi	a0,a0,-1802 # 800083d8 <states.0+0x130>
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	a58080e7          	jalr	-1448(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	fd0080e7          	jalr	-48(ra) # 80001ac2 <myproc>
    80002afa:	d541                	beqz	a0,80002a82 <kerneltrap+0x38>
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	fc6080e7          	jalr	-58(ra) # 80001ac2 <myproc>
    80002b04:	4d18                	lw	a4,24(a0)
    80002b06:	478d                	li	a5,3
    80002b08:	f6f71de3          	bne	a4,a5,80002a82 <kerneltrap+0x38>
    yield();
    80002b0c:	fffff097          	auipc	ra,0xfffff
    80002b10:	78e080e7          	jalr	1934(ra) # 8000229a <yield>
    80002b14:	b7bd                	j	80002a82 <kerneltrap+0x38>

0000000080002b16 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	1000                	addi	s0,sp,32
    80002b20:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b22:	fffff097          	auipc	ra,0xfffff
    80002b26:	fa0080e7          	jalr	-96(ra) # 80001ac2 <myproc>
  switch (n) {
    80002b2a:	4795                	li	a5,5
    80002b2c:	0497e163          	bltu	a5,s1,80002b6e <argraw+0x58>
    80002b30:	048a                	slli	s1,s1,0x2
    80002b32:	00006717          	auipc	a4,0x6
    80002b36:	8de70713          	addi	a4,a4,-1826 # 80008410 <states.0+0x168>
    80002b3a:	94ba                	add	s1,s1,a4
    80002b3c:	409c                	lw	a5,0(s1)
    80002b3e:	97ba                	add	a5,a5,a4
    80002b40:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b42:	6d3c                	ld	a5,88(a0)
    80002b44:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b46:	60e2                	ld	ra,24(sp)
    80002b48:	6442                	ld	s0,16(sp)
    80002b4a:	64a2                	ld	s1,8(sp)
    80002b4c:	6105                	addi	sp,sp,32
    80002b4e:	8082                	ret
    return p->trapframe->a1;
    80002b50:	6d3c                	ld	a5,88(a0)
    80002b52:	7fa8                	ld	a0,120(a5)
    80002b54:	bfcd                	j	80002b46 <argraw+0x30>
    return p->trapframe->a2;
    80002b56:	6d3c                	ld	a5,88(a0)
    80002b58:	63c8                	ld	a0,128(a5)
    80002b5a:	b7f5                	j	80002b46 <argraw+0x30>
    return p->trapframe->a3;
    80002b5c:	6d3c                	ld	a5,88(a0)
    80002b5e:	67c8                	ld	a0,136(a5)
    80002b60:	b7dd                	j	80002b46 <argraw+0x30>
    return p->trapframe->a4;
    80002b62:	6d3c                	ld	a5,88(a0)
    80002b64:	6bc8                	ld	a0,144(a5)
    80002b66:	b7c5                	j	80002b46 <argraw+0x30>
    return p->trapframe->a5;
    80002b68:	6d3c                	ld	a5,88(a0)
    80002b6a:	6fc8                	ld	a0,152(a5)
    80002b6c:	bfe9                	j	80002b46 <argraw+0x30>
  panic("argraw");
    80002b6e:	00006517          	auipc	a0,0x6
    80002b72:	87a50513          	addi	a0,a0,-1926 # 800083e8 <states.0+0x140>
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	9cc080e7          	jalr	-1588(ra) # 80000542 <panic>

0000000080002b7e <fetchaddr>:
{
    80002b7e:	1101                	addi	sp,sp,-32
    80002b80:	ec06                	sd	ra,24(sp)
    80002b82:	e822                	sd	s0,16(sp)
    80002b84:	e426                	sd	s1,8(sp)
    80002b86:	e04a                	sd	s2,0(sp)
    80002b88:	1000                	addi	s0,sp,32
    80002b8a:	84aa                	mv	s1,a0
    80002b8c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	f34080e7          	jalr	-204(ra) # 80001ac2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b96:	653c                	ld	a5,72(a0)
    80002b98:	02f4f863          	bgeu	s1,a5,80002bc8 <fetchaddr+0x4a>
    80002b9c:	00848713          	addi	a4,s1,8
    80002ba0:	02e7e663          	bltu	a5,a4,80002bcc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ba4:	46a1                	li	a3,8
    80002ba6:	8626                	mv	a2,s1
    80002ba8:	85ca                	mv	a1,s2
    80002baa:	6928                	ld	a0,80(a0)
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	c94080e7          	jalr	-876(ra) # 80001840 <copyin>
    80002bb4:	00a03533          	snez	a0,a0
    80002bb8:	40a00533          	neg	a0,a0
}
    80002bbc:	60e2                	ld	ra,24(sp)
    80002bbe:	6442                	ld	s0,16(sp)
    80002bc0:	64a2                	ld	s1,8(sp)
    80002bc2:	6902                	ld	s2,0(sp)
    80002bc4:	6105                	addi	sp,sp,32
    80002bc6:	8082                	ret
    return -1;
    80002bc8:	557d                	li	a0,-1
    80002bca:	bfcd                	j	80002bbc <fetchaddr+0x3e>
    80002bcc:	557d                	li	a0,-1
    80002bce:	b7fd                	j	80002bbc <fetchaddr+0x3e>

0000000080002bd0 <fetchstr>:
{
    80002bd0:	7179                	addi	sp,sp,-48
    80002bd2:	f406                	sd	ra,40(sp)
    80002bd4:	f022                	sd	s0,32(sp)
    80002bd6:	ec26                	sd	s1,24(sp)
    80002bd8:	e84a                	sd	s2,16(sp)
    80002bda:	e44e                	sd	s3,8(sp)
    80002bdc:	1800                	addi	s0,sp,48
    80002bde:	892a                	mv	s2,a0
    80002be0:	84ae                	mv	s1,a1
    80002be2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	ede080e7          	jalr	-290(ra) # 80001ac2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bec:	86ce                	mv	a3,s3
    80002bee:	864a                	mv	a2,s2
    80002bf0:	85a6                	mv	a1,s1
    80002bf2:	6928                	ld	a0,80(a0)
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	cda080e7          	jalr	-806(ra) # 800018ce <copyinstr>
  if(err < 0)
    80002bfc:	00054763          	bltz	a0,80002c0a <fetchstr+0x3a>
  return strlen(buf);
    80002c00:	8526                	mv	a0,s1
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	2ee080e7          	jalr	750(ra) # 80000ef0 <strlen>
}
    80002c0a:	70a2                	ld	ra,40(sp)
    80002c0c:	7402                	ld	s0,32(sp)
    80002c0e:	64e2                	ld	s1,24(sp)
    80002c10:	6942                	ld	s2,16(sp)
    80002c12:	69a2                	ld	s3,8(sp)
    80002c14:	6145                	addi	sp,sp,48
    80002c16:	8082                	ret

0000000080002c18 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c18:	1101                	addi	sp,sp,-32
    80002c1a:	ec06                	sd	ra,24(sp)
    80002c1c:	e822                	sd	s0,16(sp)
    80002c1e:	e426                	sd	s1,8(sp)
    80002c20:	1000                	addi	s0,sp,32
    80002c22:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	ef2080e7          	jalr	-270(ra) # 80002b16 <argraw>
    80002c2c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c2e:	4501                	li	a0,0
    80002c30:	60e2                	ld	ra,24(sp)
    80002c32:	6442                	ld	s0,16(sp)
    80002c34:	64a2                	ld	s1,8(sp)
    80002c36:	6105                	addi	sp,sp,32
    80002c38:	8082                	ret

0000000080002c3a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c3a:	1101                	addi	sp,sp,-32
    80002c3c:	ec06                	sd	ra,24(sp)
    80002c3e:	e822                	sd	s0,16(sp)
    80002c40:	e426                	sd	s1,8(sp)
    80002c42:	1000                	addi	s0,sp,32
    80002c44:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	ed0080e7          	jalr	-304(ra) # 80002b16 <argraw>
    80002c4e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c50:	4501                	li	a0,0
    80002c52:	60e2                	ld	ra,24(sp)
    80002c54:	6442                	ld	s0,16(sp)
    80002c56:	64a2                	ld	s1,8(sp)
    80002c58:	6105                	addi	sp,sp,32
    80002c5a:	8082                	ret

0000000080002c5c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c5c:	1101                	addi	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	e426                	sd	s1,8(sp)
    80002c64:	e04a                	sd	s2,0(sp)
    80002c66:	1000                	addi	s0,sp,32
    80002c68:	84ae                	mv	s1,a1
    80002c6a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c6c:	00000097          	auipc	ra,0x0
    80002c70:	eaa080e7          	jalr	-342(ra) # 80002b16 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c74:	864a                	mv	a2,s2
    80002c76:	85a6                	mv	a1,s1
    80002c78:	00000097          	auipc	ra,0x0
    80002c7c:	f58080e7          	jalr	-168(ra) # 80002bd0 <fetchstr>
}
    80002c80:	60e2                	ld	ra,24(sp)
    80002c82:	6442                	ld	s0,16(sp)
    80002c84:	64a2                	ld	s1,8(sp)
    80002c86:	6902                	ld	s2,0(sp)
    80002c88:	6105                	addi	sp,sp,32
    80002c8a:	8082                	ret

0000000080002c8c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c8c:	1101                	addi	sp,sp,-32
    80002c8e:	ec06                	sd	ra,24(sp)
    80002c90:	e822                	sd	s0,16(sp)
    80002c92:	e426                	sd	s1,8(sp)
    80002c94:	e04a                	sd	s2,0(sp)
    80002c96:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	e2a080e7          	jalr	-470(ra) # 80001ac2 <myproc>
    80002ca0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ca2:	05853903          	ld	s2,88(a0)
    80002ca6:	0a893783          	ld	a5,168(s2)
    80002caa:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cae:	37fd                	addiw	a5,a5,-1
    80002cb0:	4751                	li	a4,20
    80002cb2:	00f76f63          	bltu	a4,a5,80002cd0 <syscall+0x44>
    80002cb6:	00369713          	slli	a4,a3,0x3
    80002cba:	00005797          	auipc	a5,0x5
    80002cbe:	76e78793          	addi	a5,a5,1902 # 80008428 <syscalls>
    80002cc2:	97ba                	add	a5,a5,a4
    80002cc4:	639c                	ld	a5,0(a5)
    80002cc6:	c789                	beqz	a5,80002cd0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cc8:	9782                	jalr	a5
    80002cca:	06a93823          	sd	a0,112(s2)
    80002cce:	a839                	j	80002cec <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cd0:	15848613          	addi	a2,s1,344
    80002cd4:	5c8c                	lw	a1,56(s1)
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	71a50513          	addi	a0,a0,1818 # 800083f0 <states.0+0x148>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	8ae080e7          	jalr	-1874(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ce6:	6cbc                	ld	a5,88(s1)
    80002ce8:	577d                	li	a4,-1
    80002cea:	fbb8                	sd	a4,112(a5)
  }
}
    80002cec:	60e2                	ld	ra,24(sp)
    80002cee:	6442                	ld	s0,16(sp)
    80002cf0:	64a2                	ld	s1,8(sp)
    80002cf2:	6902                	ld	s2,0(sp)
    80002cf4:	6105                	addi	sp,sp,32
    80002cf6:	8082                	ret

0000000080002cf8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cf8:	1101                	addi	sp,sp,-32
    80002cfa:	ec06                	sd	ra,24(sp)
    80002cfc:	e822                	sd	s0,16(sp)
    80002cfe:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d00:	fec40593          	addi	a1,s0,-20
    80002d04:	4501                	li	a0,0
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	f12080e7          	jalr	-238(ra) # 80002c18 <argint>
    return -1;
    80002d0e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d10:	00054963          	bltz	a0,80002d22 <sys_exit+0x2a>
  exit(n);
    80002d14:	fec42503          	lw	a0,-20(s0)
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	478080e7          	jalr	1144(ra) # 80002190 <exit>
  return 0;  // not reached
    80002d20:	4781                	li	a5,0
}
    80002d22:	853e                	mv	a0,a5
    80002d24:	60e2                	ld	ra,24(sp)
    80002d26:	6442                	ld	s0,16(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret

0000000080002d2c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d2c:	1141                	addi	sp,sp,-16
    80002d2e:	e406                	sd	ra,8(sp)
    80002d30:	e022                	sd	s0,0(sp)
    80002d32:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	d8e080e7          	jalr	-626(ra) # 80001ac2 <myproc>
}
    80002d3c:	5d08                	lw	a0,56(a0)
    80002d3e:	60a2                	ld	ra,8(sp)
    80002d40:	6402                	ld	s0,0(sp)
    80002d42:	0141                	addi	sp,sp,16
    80002d44:	8082                	ret

0000000080002d46 <sys_fork>:

uint64
sys_fork(void)
{
    80002d46:	1141                	addi	sp,sp,-16
    80002d48:	e406                	sd	ra,8(sp)
    80002d4a:	e022                	sd	s0,0(sp)
    80002d4c:	0800                	addi	s0,sp,16
  return fork();
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	134080e7          	jalr	308(ra) # 80001e82 <fork>
}
    80002d56:	60a2                	ld	ra,8(sp)
    80002d58:	6402                	ld	s0,0(sp)
    80002d5a:	0141                	addi	sp,sp,16
    80002d5c:	8082                	ret

0000000080002d5e <sys_wait>:

uint64
sys_wait(void)
{
    80002d5e:	1101                	addi	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d66:	fe840593          	addi	a1,s0,-24
    80002d6a:	4501                	li	a0,0
    80002d6c:	00000097          	auipc	ra,0x0
    80002d70:	ece080e7          	jalr	-306(ra) # 80002c3a <argaddr>
    80002d74:	87aa                	mv	a5,a0
    return -1;
    80002d76:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d78:	0007c863          	bltz	a5,80002d88 <sys_wait+0x2a>
  return wait(p);
    80002d7c:	fe843503          	ld	a0,-24(s0)
    80002d80:	fffff097          	auipc	ra,0xfffff
    80002d84:	5d4080e7          	jalr	1492(ra) # 80002354 <wait>
}
    80002d88:	60e2                	ld	ra,24(sp)
    80002d8a:	6442                	ld	s0,16(sp)
    80002d8c:	6105                	addi	sp,sp,32
    80002d8e:	8082                	ret

0000000080002d90 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d90:	7179                	addi	sp,sp,-48
    80002d92:	f406                	sd	ra,40(sp)
    80002d94:	f022                	sd	s0,32(sp)
    80002d96:	ec26                	sd	s1,24(sp)
    80002d98:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d9a:	fdc40593          	addi	a1,s0,-36
    80002d9e:	4501                	li	a0,0
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	e78080e7          	jalr	-392(ra) # 80002c18 <argint>
    return -1;
    80002da8:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002daa:	00054f63          	bltz	a0,80002dc8 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	d14080e7          	jalr	-748(ra) # 80001ac2 <myproc>
    80002db6:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002db8:	fdc42503          	lw	a0,-36(s0)
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	052080e7          	jalr	82(ra) # 80001e0e <growproc>
    80002dc4:	00054863          	bltz	a0,80002dd4 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002dc8:	8526                	mv	a0,s1
    80002dca:	70a2                	ld	ra,40(sp)
    80002dcc:	7402                	ld	s0,32(sp)
    80002dce:	64e2                	ld	s1,24(sp)
    80002dd0:	6145                	addi	sp,sp,48
    80002dd2:	8082                	ret
    return -1;
    80002dd4:	54fd                	li	s1,-1
    80002dd6:	bfcd                	j	80002dc8 <sys_sbrk+0x38>

0000000080002dd8 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dd8:	7139                	addi	sp,sp,-64
    80002dda:	fc06                	sd	ra,56(sp)
    80002ddc:	f822                	sd	s0,48(sp)
    80002dde:	f426                	sd	s1,40(sp)
    80002de0:	f04a                	sd	s2,32(sp)
    80002de2:	ec4e                	sd	s3,24(sp)
    80002de4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002de6:	fcc40593          	addi	a1,s0,-52
    80002dea:	4501                	li	a0,0
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	e2c080e7          	jalr	-468(ra) # 80002c18 <argint>
    return -1;
    80002df4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002df6:	06054563          	bltz	a0,80002e60 <sys_sleep+0x88>
  acquire(&tickslock);
    80002dfa:	00235517          	auipc	a0,0x235
    80002dfe:	96e50513          	addi	a0,a0,-1682 # 80237768 <tickslock>
    80002e02:	ffffe097          	auipc	ra,0xffffe
    80002e06:	e6e080e7          	jalr	-402(ra) # 80000c70 <acquire>
  ticks0 = ticks;
    80002e0a:	00006917          	auipc	s2,0x6
    80002e0e:	21692903          	lw	s2,534(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002e12:	fcc42783          	lw	a5,-52(s0)
    80002e16:	cf85                	beqz	a5,80002e4e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e18:	00235997          	auipc	s3,0x235
    80002e1c:	95098993          	addi	s3,s3,-1712 # 80237768 <tickslock>
    80002e20:	00006497          	auipc	s1,0x6
    80002e24:	20048493          	addi	s1,s1,512 # 80009020 <ticks>
    if(myproc()->killed){
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	c9a080e7          	jalr	-870(ra) # 80001ac2 <myproc>
    80002e30:	591c                	lw	a5,48(a0)
    80002e32:	ef9d                	bnez	a5,80002e70 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e34:	85ce                	mv	a1,s3
    80002e36:	8526                	mv	a0,s1
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	49e080e7          	jalr	1182(ra) # 800022d6 <sleep>
  while(ticks - ticks0 < n){
    80002e40:	409c                	lw	a5,0(s1)
    80002e42:	412787bb          	subw	a5,a5,s2
    80002e46:	fcc42703          	lw	a4,-52(s0)
    80002e4a:	fce7efe3          	bltu	a5,a4,80002e28 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e4e:	00235517          	auipc	a0,0x235
    80002e52:	91a50513          	addi	a0,a0,-1766 # 80237768 <tickslock>
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	ece080e7          	jalr	-306(ra) # 80000d24 <release>
  return 0;
    80002e5e:	4781                	li	a5,0
}
    80002e60:	853e                	mv	a0,a5
    80002e62:	70e2                	ld	ra,56(sp)
    80002e64:	7442                	ld	s0,48(sp)
    80002e66:	74a2                	ld	s1,40(sp)
    80002e68:	7902                	ld	s2,32(sp)
    80002e6a:	69e2                	ld	s3,24(sp)
    80002e6c:	6121                	addi	sp,sp,64
    80002e6e:	8082                	ret
      release(&tickslock);
    80002e70:	00235517          	auipc	a0,0x235
    80002e74:	8f850513          	addi	a0,a0,-1800 # 80237768 <tickslock>
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	eac080e7          	jalr	-340(ra) # 80000d24 <release>
      return -1;
    80002e80:	57fd                	li	a5,-1
    80002e82:	bff9                	j	80002e60 <sys_sleep+0x88>

0000000080002e84 <sys_kill>:

uint64
sys_kill(void)
{
    80002e84:	1101                	addi	sp,sp,-32
    80002e86:	ec06                	sd	ra,24(sp)
    80002e88:	e822                	sd	s0,16(sp)
    80002e8a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e8c:	fec40593          	addi	a1,s0,-20
    80002e90:	4501                	li	a0,0
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	d86080e7          	jalr	-634(ra) # 80002c18 <argint>
    80002e9a:	87aa                	mv	a5,a0
    return -1;
    80002e9c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e9e:	0007c863          	bltz	a5,80002eae <sys_kill+0x2a>
  return kill(pid);
    80002ea2:	fec42503          	lw	a0,-20(s0)
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	61a080e7          	jalr	1562(ra) # 800024c0 <kill>
}
    80002eae:	60e2                	ld	ra,24(sp)
    80002eb0:	6442                	ld	s0,16(sp)
    80002eb2:	6105                	addi	sp,sp,32
    80002eb4:	8082                	ret

0000000080002eb6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002eb6:	1101                	addi	sp,sp,-32
    80002eb8:	ec06                	sd	ra,24(sp)
    80002eba:	e822                	sd	s0,16(sp)
    80002ebc:	e426                	sd	s1,8(sp)
    80002ebe:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ec0:	00235517          	auipc	a0,0x235
    80002ec4:	8a850513          	addi	a0,a0,-1880 # 80237768 <tickslock>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	da8080e7          	jalr	-600(ra) # 80000c70 <acquire>
  xticks = ticks;
    80002ed0:	00006497          	auipc	s1,0x6
    80002ed4:	1504a483          	lw	s1,336(s1) # 80009020 <ticks>
  release(&tickslock);
    80002ed8:	00235517          	auipc	a0,0x235
    80002edc:	89050513          	addi	a0,a0,-1904 # 80237768 <tickslock>
    80002ee0:	ffffe097          	auipc	ra,0xffffe
    80002ee4:	e44080e7          	jalr	-444(ra) # 80000d24 <release>
  return xticks;
}
    80002ee8:	02049513          	slli	a0,s1,0x20
    80002eec:	9101                	srli	a0,a0,0x20
    80002eee:	60e2                	ld	ra,24(sp)
    80002ef0:	6442                	ld	s0,16(sp)
    80002ef2:	64a2                	ld	s1,8(sp)
    80002ef4:	6105                	addi	sp,sp,32
    80002ef6:	8082                	ret

0000000080002ef8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ef8:	7179                	addi	sp,sp,-48
    80002efa:	f406                	sd	ra,40(sp)
    80002efc:	f022                	sd	s0,32(sp)
    80002efe:	ec26                	sd	s1,24(sp)
    80002f00:	e84a                	sd	s2,16(sp)
    80002f02:	e44e                	sd	s3,8(sp)
    80002f04:	e052                	sd	s4,0(sp)
    80002f06:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f08:	00005597          	auipc	a1,0x5
    80002f0c:	5d058593          	addi	a1,a1,1488 # 800084d8 <syscalls+0xb0>
    80002f10:	00235517          	auipc	a0,0x235
    80002f14:	87050513          	addi	a0,a0,-1936 # 80237780 <bcache>
    80002f18:	ffffe097          	auipc	ra,0xffffe
    80002f1c:	cc8080e7          	jalr	-824(ra) # 80000be0 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f20:	0023d797          	auipc	a5,0x23d
    80002f24:	86078793          	addi	a5,a5,-1952 # 8023f780 <bcache+0x8000>
    80002f28:	0023d717          	auipc	a4,0x23d
    80002f2c:	ac070713          	addi	a4,a4,-1344 # 8023f9e8 <bcache+0x8268>
    80002f30:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f34:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f38:	00235497          	auipc	s1,0x235
    80002f3c:	86048493          	addi	s1,s1,-1952 # 80237798 <bcache+0x18>
    b->next = bcache.head.next;
    80002f40:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f42:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f44:	00005a17          	auipc	s4,0x5
    80002f48:	59ca0a13          	addi	s4,s4,1436 # 800084e0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002f4c:	2b893783          	ld	a5,696(s2)
    80002f50:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f52:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f56:	85d2                	mv	a1,s4
    80002f58:	01048513          	addi	a0,s1,16
    80002f5c:	00001097          	auipc	ra,0x1
    80002f60:	4b0080e7          	jalr	1200(ra) # 8000440c <initsleeplock>
    bcache.head.next->prev = b;
    80002f64:	2b893783          	ld	a5,696(s2)
    80002f68:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f6a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f6e:	45848493          	addi	s1,s1,1112
    80002f72:	fd349de3          	bne	s1,s3,80002f4c <binit+0x54>
  }
}
    80002f76:	70a2                	ld	ra,40(sp)
    80002f78:	7402                	ld	s0,32(sp)
    80002f7a:	64e2                	ld	s1,24(sp)
    80002f7c:	6942                	ld	s2,16(sp)
    80002f7e:	69a2                	ld	s3,8(sp)
    80002f80:	6a02                	ld	s4,0(sp)
    80002f82:	6145                	addi	sp,sp,48
    80002f84:	8082                	ret

0000000080002f86 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f86:	7179                	addi	sp,sp,-48
    80002f88:	f406                	sd	ra,40(sp)
    80002f8a:	f022                	sd	s0,32(sp)
    80002f8c:	ec26                	sd	s1,24(sp)
    80002f8e:	e84a                	sd	s2,16(sp)
    80002f90:	e44e                	sd	s3,8(sp)
    80002f92:	1800                	addi	s0,sp,48
    80002f94:	892a                	mv	s2,a0
    80002f96:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f98:	00234517          	auipc	a0,0x234
    80002f9c:	7e850513          	addi	a0,a0,2024 # 80237780 <bcache>
    80002fa0:	ffffe097          	auipc	ra,0xffffe
    80002fa4:	cd0080e7          	jalr	-816(ra) # 80000c70 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fa8:	0023d497          	auipc	s1,0x23d
    80002fac:	a904b483          	ld	s1,-1392(s1) # 8023fa38 <bcache+0x82b8>
    80002fb0:	0023d797          	auipc	a5,0x23d
    80002fb4:	a3878793          	addi	a5,a5,-1480 # 8023f9e8 <bcache+0x8268>
    80002fb8:	02f48f63          	beq	s1,a5,80002ff6 <bread+0x70>
    80002fbc:	873e                	mv	a4,a5
    80002fbe:	a021                	j	80002fc6 <bread+0x40>
    80002fc0:	68a4                	ld	s1,80(s1)
    80002fc2:	02e48a63          	beq	s1,a4,80002ff6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fc6:	449c                	lw	a5,8(s1)
    80002fc8:	ff279ce3          	bne	a5,s2,80002fc0 <bread+0x3a>
    80002fcc:	44dc                	lw	a5,12(s1)
    80002fce:	ff3799e3          	bne	a5,s3,80002fc0 <bread+0x3a>
      b->refcnt++;
    80002fd2:	40bc                	lw	a5,64(s1)
    80002fd4:	2785                	addiw	a5,a5,1
    80002fd6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fd8:	00234517          	auipc	a0,0x234
    80002fdc:	7a850513          	addi	a0,a0,1960 # 80237780 <bcache>
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	d44080e7          	jalr	-700(ra) # 80000d24 <release>
      acquiresleep(&b->lock);
    80002fe8:	01048513          	addi	a0,s1,16
    80002fec:	00001097          	auipc	ra,0x1
    80002ff0:	45a080e7          	jalr	1114(ra) # 80004446 <acquiresleep>
      return b;
    80002ff4:	a8b9                	j	80003052 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ff6:	0023d497          	auipc	s1,0x23d
    80002ffa:	a3a4b483          	ld	s1,-1478(s1) # 8023fa30 <bcache+0x82b0>
    80002ffe:	0023d797          	auipc	a5,0x23d
    80003002:	9ea78793          	addi	a5,a5,-1558 # 8023f9e8 <bcache+0x8268>
    80003006:	00f48863          	beq	s1,a5,80003016 <bread+0x90>
    8000300a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000300c:	40bc                	lw	a5,64(s1)
    8000300e:	cf81                	beqz	a5,80003026 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003010:	64a4                	ld	s1,72(s1)
    80003012:	fee49de3          	bne	s1,a4,8000300c <bread+0x86>
  panic("bget: no buffers");
    80003016:	00005517          	auipc	a0,0x5
    8000301a:	4d250513          	addi	a0,a0,1234 # 800084e8 <syscalls+0xc0>
    8000301e:	ffffd097          	auipc	ra,0xffffd
    80003022:	524080e7          	jalr	1316(ra) # 80000542 <panic>
      b->dev = dev;
    80003026:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000302a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000302e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003032:	4785                	li	a5,1
    80003034:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003036:	00234517          	auipc	a0,0x234
    8000303a:	74a50513          	addi	a0,a0,1866 # 80237780 <bcache>
    8000303e:	ffffe097          	auipc	ra,0xffffe
    80003042:	ce6080e7          	jalr	-794(ra) # 80000d24 <release>
      acquiresleep(&b->lock);
    80003046:	01048513          	addi	a0,s1,16
    8000304a:	00001097          	auipc	ra,0x1
    8000304e:	3fc080e7          	jalr	1020(ra) # 80004446 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003052:	409c                	lw	a5,0(s1)
    80003054:	cb89                	beqz	a5,80003066 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003056:	8526                	mv	a0,s1
    80003058:	70a2                	ld	ra,40(sp)
    8000305a:	7402                	ld	s0,32(sp)
    8000305c:	64e2                	ld	s1,24(sp)
    8000305e:	6942                	ld	s2,16(sp)
    80003060:	69a2                	ld	s3,8(sp)
    80003062:	6145                	addi	sp,sp,48
    80003064:	8082                	ret
    virtio_disk_rw(b, 0);
    80003066:	4581                	li	a1,0
    80003068:	8526                	mv	a0,s1
    8000306a:	00003097          	auipc	ra,0x3
    8000306e:	f22080e7          	jalr	-222(ra) # 80005f8c <virtio_disk_rw>
    b->valid = 1;
    80003072:	4785                	li	a5,1
    80003074:	c09c                	sw	a5,0(s1)
  return b;
    80003076:	b7c5                	j	80003056 <bread+0xd0>

0000000080003078 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003078:	1101                	addi	sp,sp,-32
    8000307a:	ec06                	sd	ra,24(sp)
    8000307c:	e822                	sd	s0,16(sp)
    8000307e:	e426                	sd	s1,8(sp)
    80003080:	1000                	addi	s0,sp,32
    80003082:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003084:	0541                	addi	a0,a0,16
    80003086:	00001097          	auipc	ra,0x1
    8000308a:	45a080e7          	jalr	1114(ra) # 800044e0 <holdingsleep>
    8000308e:	cd01                	beqz	a0,800030a6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003090:	4585                	li	a1,1
    80003092:	8526                	mv	a0,s1
    80003094:	00003097          	auipc	ra,0x3
    80003098:	ef8080e7          	jalr	-264(ra) # 80005f8c <virtio_disk_rw>
}
    8000309c:	60e2                	ld	ra,24(sp)
    8000309e:	6442                	ld	s0,16(sp)
    800030a0:	64a2                	ld	s1,8(sp)
    800030a2:	6105                	addi	sp,sp,32
    800030a4:	8082                	ret
    panic("bwrite");
    800030a6:	00005517          	auipc	a0,0x5
    800030aa:	45a50513          	addi	a0,a0,1114 # 80008500 <syscalls+0xd8>
    800030ae:	ffffd097          	auipc	ra,0xffffd
    800030b2:	494080e7          	jalr	1172(ra) # 80000542 <panic>

00000000800030b6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030b6:	1101                	addi	sp,sp,-32
    800030b8:	ec06                	sd	ra,24(sp)
    800030ba:	e822                	sd	s0,16(sp)
    800030bc:	e426                	sd	s1,8(sp)
    800030be:	e04a                	sd	s2,0(sp)
    800030c0:	1000                	addi	s0,sp,32
    800030c2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030c4:	01050913          	addi	s2,a0,16
    800030c8:	854a                	mv	a0,s2
    800030ca:	00001097          	auipc	ra,0x1
    800030ce:	416080e7          	jalr	1046(ra) # 800044e0 <holdingsleep>
    800030d2:	c92d                	beqz	a0,80003144 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030d4:	854a                	mv	a0,s2
    800030d6:	00001097          	auipc	ra,0x1
    800030da:	3c6080e7          	jalr	966(ra) # 8000449c <releasesleep>

  acquire(&bcache.lock);
    800030de:	00234517          	auipc	a0,0x234
    800030e2:	6a250513          	addi	a0,a0,1698 # 80237780 <bcache>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	b8a080e7          	jalr	-1142(ra) # 80000c70 <acquire>
  b->refcnt--;
    800030ee:	40bc                	lw	a5,64(s1)
    800030f0:	37fd                	addiw	a5,a5,-1
    800030f2:	0007871b          	sext.w	a4,a5
    800030f6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030f8:	eb05                	bnez	a4,80003128 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030fa:	68bc                	ld	a5,80(s1)
    800030fc:	64b8                	ld	a4,72(s1)
    800030fe:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003100:	64bc                	ld	a5,72(s1)
    80003102:	68b8                	ld	a4,80(s1)
    80003104:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003106:	0023c797          	auipc	a5,0x23c
    8000310a:	67a78793          	addi	a5,a5,1658 # 8023f780 <bcache+0x8000>
    8000310e:	2b87b703          	ld	a4,696(a5)
    80003112:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003114:	0023d717          	auipc	a4,0x23d
    80003118:	8d470713          	addi	a4,a4,-1836 # 8023f9e8 <bcache+0x8268>
    8000311c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000311e:	2b87b703          	ld	a4,696(a5)
    80003122:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003124:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003128:	00234517          	auipc	a0,0x234
    8000312c:	65850513          	addi	a0,a0,1624 # 80237780 <bcache>
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	bf4080e7          	jalr	-1036(ra) # 80000d24 <release>
}
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	64a2                	ld	s1,8(sp)
    8000313e:	6902                	ld	s2,0(sp)
    80003140:	6105                	addi	sp,sp,32
    80003142:	8082                	ret
    panic("brelse");
    80003144:	00005517          	auipc	a0,0x5
    80003148:	3c450513          	addi	a0,a0,964 # 80008508 <syscalls+0xe0>
    8000314c:	ffffd097          	auipc	ra,0xffffd
    80003150:	3f6080e7          	jalr	1014(ra) # 80000542 <panic>

0000000080003154 <bpin>:

void
bpin(struct buf *b) {
    80003154:	1101                	addi	sp,sp,-32
    80003156:	ec06                	sd	ra,24(sp)
    80003158:	e822                	sd	s0,16(sp)
    8000315a:	e426                	sd	s1,8(sp)
    8000315c:	1000                	addi	s0,sp,32
    8000315e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003160:	00234517          	auipc	a0,0x234
    80003164:	62050513          	addi	a0,a0,1568 # 80237780 <bcache>
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	b08080e7          	jalr	-1272(ra) # 80000c70 <acquire>
  b->refcnt++;
    80003170:	40bc                	lw	a5,64(s1)
    80003172:	2785                	addiw	a5,a5,1
    80003174:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003176:	00234517          	auipc	a0,0x234
    8000317a:	60a50513          	addi	a0,a0,1546 # 80237780 <bcache>
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	ba6080e7          	jalr	-1114(ra) # 80000d24 <release>
}
    80003186:	60e2                	ld	ra,24(sp)
    80003188:	6442                	ld	s0,16(sp)
    8000318a:	64a2                	ld	s1,8(sp)
    8000318c:	6105                	addi	sp,sp,32
    8000318e:	8082                	ret

0000000080003190 <bunpin>:

void
bunpin(struct buf *b) {
    80003190:	1101                	addi	sp,sp,-32
    80003192:	ec06                	sd	ra,24(sp)
    80003194:	e822                	sd	s0,16(sp)
    80003196:	e426                	sd	s1,8(sp)
    80003198:	1000                	addi	s0,sp,32
    8000319a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000319c:	00234517          	auipc	a0,0x234
    800031a0:	5e450513          	addi	a0,a0,1508 # 80237780 <bcache>
    800031a4:	ffffe097          	auipc	ra,0xffffe
    800031a8:	acc080e7          	jalr	-1332(ra) # 80000c70 <acquire>
  b->refcnt--;
    800031ac:	40bc                	lw	a5,64(s1)
    800031ae:	37fd                	addiw	a5,a5,-1
    800031b0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031b2:	00234517          	auipc	a0,0x234
    800031b6:	5ce50513          	addi	a0,a0,1486 # 80237780 <bcache>
    800031ba:	ffffe097          	auipc	ra,0xffffe
    800031be:	b6a080e7          	jalr	-1174(ra) # 80000d24 <release>
}
    800031c2:	60e2                	ld	ra,24(sp)
    800031c4:	6442                	ld	s0,16(sp)
    800031c6:	64a2                	ld	s1,8(sp)
    800031c8:	6105                	addi	sp,sp,32
    800031ca:	8082                	ret

00000000800031cc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031cc:	1101                	addi	sp,sp,-32
    800031ce:	ec06                	sd	ra,24(sp)
    800031d0:	e822                	sd	s0,16(sp)
    800031d2:	e426                	sd	s1,8(sp)
    800031d4:	e04a                	sd	s2,0(sp)
    800031d6:	1000                	addi	s0,sp,32
    800031d8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031da:	00d5d59b          	srliw	a1,a1,0xd
    800031de:	0023d797          	auipc	a5,0x23d
    800031e2:	c7e7a783          	lw	a5,-898(a5) # 8023fe5c <sb+0x1c>
    800031e6:	9dbd                	addw	a1,a1,a5
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	d9e080e7          	jalr	-610(ra) # 80002f86 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031f0:	0074f713          	andi	a4,s1,7
    800031f4:	4785                	li	a5,1
    800031f6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031fa:	14ce                	slli	s1,s1,0x33
    800031fc:	90d9                	srli	s1,s1,0x36
    800031fe:	00950733          	add	a4,a0,s1
    80003202:	05874703          	lbu	a4,88(a4)
    80003206:	00e7f6b3          	and	a3,a5,a4
    8000320a:	c69d                	beqz	a3,80003238 <bfree+0x6c>
    8000320c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000320e:	94aa                	add	s1,s1,a0
    80003210:	fff7c793          	not	a5,a5
    80003214:	8ff9                	and	a5,a5,a4
    80003216:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000321a:	00001097          	auipc	ra,0x1
    8000321e:	104080e7          	jalr	260(ra) # 8000431e <log_write>
  brelse(bp);
    80003222:	854a                	mv	a0,s2
    80003224:	00000097          	auipc	ra,0x0
    80003228:	e92080e7          	jalr	-366(ra) # 800030b6 <brelse>
}
    8000322c:	60e2                	ld	ra,24(sp)
    8000322e:	6442                	ld	s0,16(sp)
    80003230:	64a2                	ld	s1,8(sp)
    80003232:	6902                	ld	s2,0(sp)
    80003234:	6105                	addi	sp,sp,32
    80003236:	8082                	ret
    panic("freeing free block");
    80003238:	00005517          	auipc	a0,0x5
    8000323c:	2d850513          	addi	a0,a0,728 # 80008510 <syscalls+0xe8>
    80003240:	ffffd097          	auipc	ra,0xffffd
    80003244:	302080e7          	jalr	770(ra) # 80000542 <panic>

0000000080003248 <balloc>:
{
    80003248:	711d                	addi	sp,sp,-96
    8000324a:	ec86                	sd	ra,88(sp)
    8000324c:	e8a2                	sd	s0,80(sp)
    8000324e:	e4a6                	sd	s1,72(sp)
    80003250:	e0ca                	sd	s2,64(sp)
    80003252:	fc4e                	sd	s3,56(sp)
    80003254:	f852                	sd	s4,48(sp)
    80003256:	f456                	sd	s5,40(sp)
    80003258:	f05a                	sd	s6,32(sp)
    8000325a:	ec5e                	sd	s7,24(sp)
    8000325c:	e862                	sd	s8,16(sp)
    8000325e:	e466                	sd	s9,8(sp)
    80003260:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003262:	0023d797          	auipc	a5,0x23d
    80003266:	be27a783          	lw	a5,-1054(a5) # 8023fe44 <sb+0x4>
    8000326a:	cbd1                	beqz	a5,800032fe <balloc+0xb6>
    8000326c:	8baa                	mv	s7,a0
    8000326e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003270:	0023db17          	auipc	s6,0x23d
    80003274:	bd0b0b13          	addi	s6,s6,-1072 # 8023fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003278:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000327a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000327c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000327e:	6c89                	lui	s9,0x2
    80003280:	a831                	j	8000329c <balloc+0x54>
    brelse(bp);
    80003282:	854a                	mv	a0,s2
    80003284:	00000097          	auipc	ra,0x0
    80003288:	e32080e7          	jalr	-462(ra) # 800030b6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000328c:	015c87bb          	addw	a5,s9,s5
    80003290:	00078a9b          	sext.w	s5,a5
    80003294:	004b2703          	lw	a4,4(s6)
    80003298:	06eaf363          	bgeu	s5,a4,800032fe <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000329c:	41fad79b          	sraiw	a5,s5,0x1f
    800032a0:	0137d79b          	srliw	a5,a5,0x13
    800032a4:	015787bb          	addw	a5,a5,s5
    800032a8:	40d7d79b          	sraiw	a5,a5,0xd
    800032ac:	01cb2583          	lw	a1,28(s6)
    800032b0:	9dbd                	addw	a1,a1,a5
    800032b2:	855e                	mv	a0,s7
    800032b4:	00000097          	auipc	ra,0x0
    800032b8:	cd2080e7          	jalr	-814(ra) # 80002f86 <bread>
    800032bc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032be:	004b2503          	lw	a0,4(s6)
    800032c2:	000a849b          	sext.w	s1,s5
    800032c6:	8662                	mv	a2,s8
    800032c8:	faa4fde3          	bgeu	s1,a0,80003282 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032cc:	41f6579b          	sraiw	a5,a2,0x1f
    800032d0:	01d7d69b          	srliw	a3,a5,0x1d
    800032d4:	00c6873b          	addw	a4,a3,a2
    800032d8:	00777793          	andi	a5,a4,7
    800032dc:	9f95                	subw	a5,a5,a3
    800032de:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032e2:	4037571b          	sraiw	a4,a4,0x3
    800032e6:	00e906b3          	add	a3,s2,a4
    800032ea:	0586c683          	lbu	a3,88(a3)
    800032ee:	00d7f5b3          	and	a1,a5,a3
    800032f2:	cd91                	beqz	a1,8000330e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f4:	2605                	addiw	a2,a2,1
    800032f6:	2485                	addiw	s1,s1,1
    800032f8:	fd4618e3          	bne	a2,s4,800032c8 <balloc+0x80>
    800032fc:	b759                	j	80003282 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032fe:	00005517          	auipc	a0,0x5
    80003302:	22a50513          	addi	a0,a0,554 # 80008528 <syscalls+0x100>
    80003306:	ffffd097          	auipc	ra,0xffffd
    8000330a:	23c080e7          	jalr	572(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000330e:	974a                	add	a4,a4,s2
    80003310:	8fd5                	or	a5,a5,a3
    80003312:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003316:	854a                	mv	a0,s2
    80003318:	00001097          	auipc	ra,0x1
    8000331c:	006080e7          	jalr	6(ra) # 8000431e <log_write>
        brelse(bp);
    80003320:	854a                	mv	a0,s2
    80003322:	00000097          	auipc	ra,0x0
    80003326:	d94080e7          	jalr	-620(ra) # 800030b6 <brelse>
  bp = bread(dev, bno);
    8000332a:	85a6                	mv	a1,s1
    8000332c:	855e                	mv	a0,s7
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	c58080e7          	jalr	-936(ra) # 80002f86 <bread>
    80003336:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003338:	40000613          	li	a2,1024
    8000333c:	4581                	li	a1,0
    8000333e:	05850513          	addi	a0,a0,88
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	a2a080e7          	jalr	-1494(ra) # 80000d6c <memset>
  log_write(bp);
    8000334a:	854a                	mv	a0,s2
    8000334c:	00001097          	auipc	ra,0x1
    80003350:	fd2080e7          	jalr	-46(ra) # 8000431e <log_write>
  brelse(bp);
    80003354:	854a                	mv	a0,s2
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	d60080e7          	jalr	-672(ra) # 800030b6 <brelse>
}
    8000335e:	8526                	mv	a0,s1
    80003360:	60e6                	ld	ra,88(sp)
    80003362:	6446                	ld	s0,80(sp)
    80003364:	64a6                	ld	s1,72(sp)
    80003366:	6906                	ld	s2,64(sp)
    80003368:	79e2                	ld	s3,56(sp)
    8000336a:	7a42                	ld	s4,48(sp)
    8000336c:	7aa2                	ld	s5,40(sp)
    8000336e:	7b02                	ld	s6,32(sp)
    80003370:	6be2                	ld	s7,24(sp)
    80003372:	6c42                	ld	s8,16(sp)
    80003374:	6ca2                	ld	s9,8(sp)
    80003376:	6125                	addi	sp,sp,96
    80003378:	8082                	ret

000000008000337a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000337a:	7179                	addi	sp,sp,-48
    8000337c:	f406                	sd	ra,40(sp)
    8000337e:	f022                	sd	s0,32(sp)
    80003380:	ec26                	sd	s1,24(sp)
    80003382:	e84a                	sd	s2,16(sp)
    80003384:	e44e                	sd	s3,8(sp)
    80003386:	e052                	sd	s4,0(sp)
    80003388:	1800                	addi	s0,sp,48
    8000338a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000338c:	47ad                	li	a5,11
    8000338e:	04b7fe63          	bgeu	a5,a1,800033ea <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003392:	ff45849b          	addiw	s1,a1,-12
    80003396:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000339a:	0ff00793          	li	a5,255
    8000339e:	0ae7e363          	bltu	a5,a4,80003444 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033a2:	08052583          	lw	a1,128(a0)
    800033a6:	c5ad                	beqz	a1,80003410 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033a8:	00092503          	lw	a0,0(s2)
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	bda080e7          	jalr	-1062(ra) # 80002f86 <bread>
    800033b4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033b6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ba:	02049593          	slli	a1,s1,0x20
    800033be:	9181                	srli	a1,a1,0x20
    800033c0:	058a                	slli	a1,a1,0x2
    800033c2:	00b784b3          	add	s1,a5,a1
    800033c6:	0004a983          	lw	s3,0(s1)
    800033ca:	04098d63          	beqz	s3,80003424 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033ce:	8552                	mv	a0,s4
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	ce6080e7          	jalr	-794(ra) # 800030b6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033d8:	854e                	mv	a0,s3
    800033da:	70a2                	ld	ra,40(sp)
    800033dc:	7402                	ld	s0,32(sp)
    800033de:	64e2                	ld	s1,24(sp)
    800033e0:	6942                	ld	s2,16(sp)
    800033e2:	69a2                	ld	s3,8(sp)
    800033e4:	6a02                	ld	s4,0(sp)
    800033e6:	6145                	addi	sp,sp,48
    800033e8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033ea:	02059493          	slli	s1,a1,0x20
    800033ee:	9081                	srli	s1,s1,0x20
    800033f0:	048a                	slli	s1,s1,0x2
    800033f2:	94aa                	add	s1,s1,a0
    800033f4:	0504a983          	lw	s3,80(s1)
    800033f8:	fe0990e3          	bnez	s3,800033d8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033fc:	4108                	lw	a0,0(a0)
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	e4a080e7          	jalr	-438(ra) # 80003248 <balloc>
    80003406:	0005099b          	sext.w	s3,a0
    8000340a:	0534a823          	sw	s3,80(s1)
    8000340e:	b7e9                	j	800033d8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003410:	4108                	lw	a0,0(a0)
    80003412:	00000097          	auipc	ra,0x0
    80003416:	e36080e7          	jalr	-458(ra) # 80003248 <balloc>
    8000341a:	0005059b          	sext.w	a1,a0
    8000341e:	08b92023          	sw	a1,128(s2)
    80003422:	b759                	j	800033a8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003424:	00092503          	lw	a0,0(s2)
    80003428:	00000097          	auipc	ra,0x0
    8000342c:	e20080e7          	jalr	-480(ra) # 80003248 <balloc>
    80003430:	0005099b          	sext.w	s3,a0
    80003434:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003438:	8552                	mv	a0,s4
    8000343a:	00001097          	auipc	ra,0x1
    8000343e:	ee4080e7          	jalr	-284(ra) # 8000431e <log_write>
    80003442:	b771                	j	800033ce <bmap+0x54>
  panic("bmap: out of range");
    80003444:	00005517          	auipc	a0,0x5
    80003448:	0fc50513          	addi	a0,a0,252 # 80008540 <syscalls+0x118>
    8000344c:	ffffd097          	auipc	ra,0xffffd
    80003450:	0f6080e7          	jalr	246(ra) # 80000542 <panic>

0000000080003454 <iget>:
{
    80003454:	7179                	addi	sp,sp,-48
    80003456:	f406                	sd	ra,40(sp)
    80003458:	f022                	sd	s0,32(sp)
    8000345a:	ec26                	sd	s1,24(sp)
    8000345c:	e84a                	sd	s2,16(sp)
    8000345e:	e44e                	sd	s3,8(sp)
    80003460:	e052                	sd	s4,0(sp)
    80003462:	1800                	addi	s0,sp,48
    80003464:	89aa                	mv	s3,a0
    80003466:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003468:	0023d517          	auipc	a0,0x23d
    8000346c:	9f850513          	addi	a0,a0,-1544 # 8023fe60 <icache>
    80003470:	ffffe097          	auipc	ra,0xffffe
    80003474:	800080e7          	jalr	-2048(ra) # 80000c70 <acquire>
  empty = 0;
    80003478:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000347a:	0023d497          	auipc	s1,0x23d
    8000347e:	9fe48493          	addi	s1,s1,-1538 # 8023fe78 <icache+0x18>
    80003482:	0023e697          	auipc	a3,0x23e
    80003486:	48668693          	addi	a3,a3,1158 # 80241908 <log>
    8000348a:	a039                	j	80003498 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000348c:	02090b63          	beqz	s2,800034c2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003490:	08848493          	addi	s1,s1,136
    80003494:	02d48a63          	beq	s1,a3,800034c8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003498:	449c                	lw	a5,8(s1)
    8000349a:	fef059e3          	blez	a5,8000348c <iget+0x38>
    8000349e:	4098                	lw	a4,0(s1)
    800034a0:	ff3716e3          	bne	a4,s3,8000348c <iget+0x38>
    800034a4:	40d8                	lw	a4,4(s1)
    800034a6:	ff4713e3          	bne	a4,s4,8000348c <iget+0x38>
      ip->ref++;
    800034aa:	2785                	addiw	a5,a5,1
    800034ac:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034ae:	0023d517          	auipc	a0,0x23d
    800034b2:	9b250513          	addi	a0,a0,-1614 # 8023fe60 <icache>
    800034b6:	ffffe097          	auipc	ra,0xffffe
    800034ba:	86e080e7          	jalr	-1938(ra) # 80000d24 <release>
      return ip;
    800034be:	8926                	mv	s2,s1
    800034c0:	a03d                	j	800034ee <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034c2:	f7f9                	bnez	a5,80003490 <iget+0x3c>
    800034c4:	8926                	mv	s2,s1
    800034c6:	b7e9                	j	80003490 <iget+0x3c>
  if(empty == 0)
    800034c8:	02090c63          	beqz	s2,80003500 <iget+0xac>
  ip->dev = dev;
    800034cc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034d0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034d4:	4785                	li	a5,1
    800034d6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034da:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034de:	0023d517          	auipc	a0,0x23d
    800034e2:	98250513          	addi	a0,a0,-1662 # 8023fe60 <icache>
    800034e6:	ffffe097          	auipc	ra,0xffffe
    800034ea:	83e080e7          	jalr	-1986(ra) # 80000d24 <release>
}
    800034ee:	854a                	mv	a0,s2
    800034f0:	70a2                	ld	ra,40(sp)
    800034f2:	7402                	ld	s0,32(sp)
    800034f4:	64e2                	ld	s1,24(sp)
    800034f6:	6942                	ld	s2,16(sp)
    800034f8:	69a2                	ld	s3,8(sp)
    800034fa:	6a02                	ld	s4,0(sp)
    800034fc:	6145                	addi	sp,sp,48
    800034fe:	8082                	ret
    panic("iget: no inodes");
    80003500:	00005517          	auipc	a0,0x5
    80003504:	05850513          	addi	a0,a0,88 # 80008558 <syscalls+0x130>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	03a080e7          	jalr	58(ra) # 80000542 <panic>

0000000080003510 <fsinit>:
fsinit(int dev) {
    80003510:	7179                	addi	sp,sp,-48
    80003512:	f406                	sd	ra,40(sp)
    80003514:	f022                	sd	s0,32(sp)
    80003516:	ec26                	sd	s1,24(sp)
    80003518:	e84a                	sd	s2,16(sp)
    8000351a:	e44e                	sd	s3,8(sp)
    8000351c:	1800                	addi	s0,sp,48
    8000351e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003520:	4585                	li	a1,1
    80003522:	00000097          	auipc	ra,0x0
    80003526:	a64080e7          	jalr	-1436(ra) # 80002f86 <bread>
    8000352a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000352c:	0023d997          	auipc	s3,0x23d
    80003530:	91498993          	addi	s3,s3,-1772 # 8023fe40 <sb>
    80003534:	02000613          	li	a2,32
    80003538:	05850593          	addi	a1,a0,88
    8000353c:	854e                	mv	a0,s3
    8000353e:	ffffe097          	auipc	ra,0xffffe
    80003542:	88a080e7          	jalr	-1910(ra) # 80000dc8 <memmove>
  brelse(bp);
    80003546:	8526                	mv	a0,s1
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	b6e080e7          	jalr	-1170(ra) # 800030b6 <brelse>
  if(sb.magic != FSMAGIC)
    80003550:	0009a703          	lw	a4,0(s3)
    80003554:	102037b7          	lui	a5,0x10203
    80003558:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000355c:	02f71263          	bne	a4,a5,80003580 <fsinit+0x70>
  initlog(dev, &sb);
    80003560:	0023d597          	auipc	a1,0x23d
    80003564:	8e058593          	addi	a1,a1,-1824 # 8023fe40 <sb>
    80003568:	854a                	mv	a0,s2
    8000356a:	00001097          	auipc	ra,0x1
    8000356e:	b3c080e7          	jalr	-1220(ra) # 800040a6 <initlog>
}
    80003572:	70a2                	ld	ra,40(sp)
    80003574:	7402                	ld	s0,32(sp)
    80003576:	64e2                	ld	s1,24(sp)
    80003578:	6942                	ld	s2,16(sp)
    8000357a:	69a2                	ld	s3,8(sp)
    8000357c:	6145                	addi	sp,sp,48
    8000357e:	8082                	ret
    panic("invalid file system");
    80003580:	00005517          	auipc	a0,0x5
    80003584:	fe850513          	addi	a0,a0,-24 # 80008568 <syscalls+0x140>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	fba080e7          	jalr	-70(ra) # 80000542 <panic>

0000000080003590 <iinit>:
{
    80003590:	7179                	addi	sp,sp,-48
    80003592:	f406                	sd	ra,40(sp)
    80003594:	f022                	sd	s0,32(sp)
    80003596:	ec26                	sd	s1,24(sp)
    80003598:	e84a                	sd	s2,16(sp)
    8000359a:	e44e                	sd	s3,8(sp)
    8000359c:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000359e:	00005597          	auipc	a1,0x5
    800035a2:	fe258593          	addi	a1,a1,-30 # 80008580 <syscalls+0x158>
    800035a6:	0023d517          	auipc	a0,0x23d
    800035aa:	8ba50513          	addi	a0,a0,-1862 # 8023fe60 <icache>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	632080e7          	jalr	1586(ra) # 80000be0 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035b6:	0023d497          	auipc	s1,0x23d
    800035ba:	8d248493          	addi	s1,s1,-1838 # 8023fe88 <icache+0x28>
    800035be:	0023e997          	auipc	s3,0x23e
    800035c2:	35a98993          	addi	s3,s3,858 # 80241918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035c6:	00005917          	auipc	s2,0x5
    800035ca:	fc290913          	addi	s2,s2,-62 # 80008588 <syscalls+0x160>
    800035ce:	85ca                	mv	a1,s2
    800035d0:	8526                	mv	a0,s1
    800035d2:	00001097          	auipc	ra,0x1
    800035d6:	e3a080e7          	jalr	-454(ra) # 8000440c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035da:	08848493          	addi	s1,s1,136
    800035de:	ff3498e3          	bne	s1,s3,800035ce <iinit+0x3e>
}
    800035e2:	70a2                	ld	ra,40(sp)
    800035e4:	7402                	ld	s0,32(sp)
    800035e6:	64e2                	ld	s1,24(sp)
    800035e8:	6942                	ld	s2,16(sp)
    800035ea:	69a2                	ld	s3,8(sp)
    800035ec:	6145                	addi	sp,sp,48
    800035ee:	8082                	ret

00000000800035f0 <ialloc>:
{
    800035f0:	715d                	addi	sp,sp,-80
    800035f2:	e486                	sd	ra,72(sp)
    800035f4:	e0a2                	sd	s0,64(sp)
    800035f6:	fc26                	sd	s1,56(sp)
    800035f8:	f84a                	sd	s2,48(sp)
    800035fa:	f44e                	sd	s3,40(sp)
    800035fc:	f052                	sd	s4,32(sp)
    800035fe:	ec56                	sd	s5,24(sp)
    80003600:	e85a                	sd	s6,16(sp)
    80003602:	e45e                	sd	s7,8(sp)
    80003604:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003606:	0023d717          	auipc	a4,0x23d
    8000360a:	84672703          	lw	a4,-1978(a4) # 8023fe4c <sb+0xc>
    8000360e:	4785                	li	a5,1
    80003610:	04e7fa63          	bgeu	a5,a4,80003664 <ialloc+0x74>
    80003614:	8aaa                	mv	s5,a0
    80003616:	8bae                	mv	s7,a1
    80003618:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000361a:	0023da17          	auipc	s4,0x23d
    8000361e:	826a0a13          	addi	s4,s4,-2010 # 8023fe40 <sb>
    80003622:	00048b1b          	sext.w	s6,s1
    80003626:	0044d793          	srli	a5,s1,0x4
    8000362a:	018a2583          	lw	a1,24(s4)
    8000362e:	9dbd                	addw	a1,a1,a5
    80003630:	8556                	mv	a0,s5
    80003632:	00000097          	auipc	ra,0x0
    80003636:	954080e7          	jalr	-1708(ra) # 80002f86 <bread>
    8000363a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000363c:	05850993          	addi	s3,a0,88
    80003640:	00f4f793          	andi	a5,s1,15
    80003644:	079a                	slli	a5,a5,0x6
    80003646:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003648:	00099783          	lh	a5,0(s3)
    8000364c:	c785                	beqz	a5,80003674 <ialloc+0x84>
    brelse(bp);
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	a68080e7          	jalr	-1432(ra) # 800030b6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003656:	0485                	addi	s1,s1,1
    80003658:	00ca2703          	lw	a4,12(s4)
    8000365c:	0004879b          	sext.w	a5,s1
    80003660:	fce7e1e3          	bltu	a5,a4,80003622 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003664:	00005517          	auipc	a0,0x5
    80003668:	f2c50513          	addi	a0,a0,-212 # 80008590 <syscalls+0x168>
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	ed6080e7          	jalr	-298(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    80003674:	04000613          	li	a2,64
    80003678:	4581                	li	a1,0
    8000367a:	854e                	mv	a0,s3
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	6f0080e7          	jalr	1776(ra) # 80000d6c <memset>
      dip->type = type;
    80003684:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003688:	854a                	mv	a0,s2
    8000368a:	00001097          	auipc	ra,0x1
    8000368e:	c94080e7          	jalr	-876(ra) # 8000431e <log_write>
      brelse(bp);
    80003692:	854a                	mv	a0,s2
    80003694:	00000097          	auipc	ra,0x0
    80003698:	a22080e7          	jalr	-1502(ra) # 800030b6 <brelse>
      return iget(dev, inum);
    8000369c:	85da                	mv	a1,s6
    8000369e:	8556                	mv	a0,s5
    800036a0:	00000097          	auipc	ra,0x0
    800036a4:	db4080e7          	jalr	-588(ra) # 80003454 <iget>
}
    800036a8:	60a6                	ld	ra,72(sp)
    800036aa:	6406                	ld	s0,64(sp)
    800036ac:	74e2                	ld	s1,56(sp)
    800036ae:	7942                	ld	s2,48(sp)
    800036b0:	79a2                	ld	s3,40(sp)
    800036b2:	7a02                	ld	s4,32(sp)
    800036b4:	6ae2                	ld	s5,24(sp)
    800036b6:	6b42                	ld	s6,16(sp)
    800036b8:	6ba2                	ld	s7,8(sp)
    800036ba:	6161                	addi	sp,sp,80
    800036bc:	8082                	ret

00000000800036be <iupdate>:
{
    800036be:	1101                	addi	sp,sp,-32
    800036c0:	ec06                	sd	ra,24(sp)
    800036c2:	e822                	sd	s0,16(sp)
    800036c4:	e426                	sd	s1,8(sp)
    800036c6:	e04a                	sd	s2,0(sp)
    800036c8:	1000                	addi	s0,sp,32
    800036ca:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036cc:	415c                	lw	a5,4(a0)
    800036ce:	0047d79b          	srliw	a5,a5,0x4
    800036d2:	0023c597          	auipc	a1,0x23c
    800036d6:	7865a583          	lw	a1,1926(a1) # 8023fe58 <sb+0x18>
    800036da:	9dbd                	addw	a1,a1,a5
    800036dc:	4108                	lw	a0,0(a0)
    800036de:	00000097          	auipc	ra,0x0
    800036e2:	8a8080e7          	jalr	-1880(ra) # 80002f86 <bread>
    800036e6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036e8:	05850793          	addi	a5,a0,88
    800036ec:	40c8                	lw	a0,4(s1)
    800036ee:	893d                	andi	a0,a0,15
    800036f0:	051a                	slli	a0,a0,0x6
    800036f2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036f4:	04449703          	lh	a4,68(s1)
    800036f8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036fc:	04649703          	lh	a4,70(s1)
    80003700:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003704:	04849703          	lh	a4,72(s1)
    80003708:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000370c:	04a49703          	lh	a4,74(s1)
    80003710:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003714:	44f8                	lw	a4,76(s1)
    80003716:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003718:	03400613          	li	a2,52
    8000371c:	05048593          	addi	a1,s1,80
    80003720:	0531                	addi	a0,a0,12
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	6a6080e7          	jalr	1702(ra) # 80000dc8 <memmove>
  log_write(bp);
    8000372a:	854a                	mv	a0,s2
    8000372c:	00001097          	auipc	ra,0x1
    80003730:	bf2080e7          	jalr	-1038(ra) # 8000431e <log_write>
  brelse(bp);
    80003734:	854a                	mv	a0,s2
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	980080e7          	jalr	-1664(ra) # 800030b6 <brelse>
}
    8000373e:	60e2                	ld	ra,24(sp)
    80003740:	6442                	ld	s0,16(sp)
    80003742:	64a2                	ld	s1,8(sp)
    80003744:	6902                	ld	s2,0(sp)
    80003746:	6105                	addi	sp,sp,32
    80003748:	8082                	ret

000000008000374a <idup>:
{
    8000374a:	1101                	addi	sp,sp,-32
    8000374c:	ec06                	sd	ra,24(sp)
    8000374e:	e822                	sd	s0,16(sp)
    80003750:	e426                	sd	s1,8(sp)
    80003752:	1000                	addi	s0,sp,32
    80003754:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003756:	0023c517          	auipc	a0,0x23c
    8000375a:	70a50513          	addi	a0,a0,1802 # 8023fe60 <icache>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	512080e7          	jalr	1298(ra) # 80000c70 <acquire>
  ip->ref++;
    80003766:	449c                	lw	a5,8(s1)
    80003768:	2785                	addiw	a5,a5,1
    8000376a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000376c:	0023c517          	auipc	a0,0x23c
    80003770:	6f450513          	addi	a0,a0,1780 # 8023fe60 <icache>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	5b0080e7          	jalr	1456(ra) # 80000d24 <release>
}
    8000377c:	8526                	mv	a0,s1
    8000377e:	60e2                	ld	ra,24(sp)
    80003780:	6442                	ld	s0,16(sp)
    80003782:	64a2                	ld	s1,8(sp)
    80003784:	6105                	addi	sp,sp,32
    80003786:	8082                	ret

0000000080003788 <ilock>:
{
    80003788:	1101                	addi	sp,sp,-32
    8000378a:	ec06                	sd	ra,24(sp)
    8000378c:	e822                	sd	s0,16(sp)
    8000378e:	e426                	sd	s1,8(sp)
    80003790:	e04a                	sd	s2,0(sp)
    80003792:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003794:	c115                	beqz	a0,800037b8 <ilock+0x30>
    80003796:	84aa                	mv	s1,a0
    80003798:	451c                	lw	a5,8(a0)
    8000379a:	00f05f63          	blez	a5,800037b8 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000379e:	0541                	addi	a0,a0,16
    800037a0:	00001097          	auipc	ra,0x1
    800037a4:	ca6080e7          	jalr	-858(ra) # 80004446 <acquiresleep>
  if(ip->valid == 0){
    800037a8:	40bc                	lw	a5,64(s1)
    800037aa:	cf99                	beqz	a5,800037c8 <ilock+0x40>
}
    800037ac:	60e2                	ld	ra,24(sp)
    800037ae:	6442                	ld	s0,16(sp)
    800037b0:	64a2                	ld	s1,8(sp)
    800037b2:	6902                	ld	s2,0(sp)
    800037b4:	6105                	addi	sp,sp,32
    800037b6:	8082                	ret
    panic("ilock");
    800037b8:	00005517          	auipc	a0,0x5
    800037bc:	df050513          	addi	a0,a0,-528 # 800085a8 <syscalls+0x180>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	d82080e7          	jalr	-638(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037c8:	40dc                	lw	a5,4(s1)
    800037ca:	0047d79b          	srliw	a5,a5,0x4
    800037ce:	0023c597          	auipc	a1,0x23c
    800037d2:	68a5a583          	lw	a1,1674(a1) # 8023fe58 <sb+0x18>
    800037d6:	9dbd                	addw	a1,a1,a5
    800037d8:	4088                	lw	a0,0(s1)
    800037da:	fffff097          	auipc	ra,0xfffff
    800037de:	7ac080e7          	jalr	1964(ra) # 80002f86 <bread>
    800037e2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037e4:	05850593          	addi	a1,a0,88
    800037e8:	40dc                	lw	a5,4(s1)
    800037ea:	8bbd                	andi	a5,a5,15
    800037ec:	079a                	slli	a5,a5,0x6
    800037ee:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037f0:	00059783          	lh	a5,0(a1)
    800037f4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037f8:	00259783          	lh	a5,2(a1)
    800037fc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003800:	00459783          	lh	a5,4(a1)
    80003804:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003808:	00659783          	lh	a5,6(a1)
    8000380c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003810:	459c                	lw	a5,8(a1)
    80003812:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003814:	03400613          	li	a2,52
    80003818:	05b1                	addi	a1,a1,12
    8000381a:	05048513          	addi	a0,s1,80
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	5aa080e7          	jalr	1450(ra) # 80000dc8 <memmove>
    brelse(bp);
    80003826:	854a                	mv	a0,s2
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	88e080e7          	jalr	-1906(ra) # 800030b6 <brelse>
    ip->valid = 1;
    80003830:	4785                	li	a5,1
    80003832:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003834:	04449783          	lh	a5,68(s1)
    80003838:	fbb5                	bnez	a5,800037ac <ilock+0x24>
      panic("ilock: no type");
    8000383a:	00005517          	auipc	a0,0x5
    8000383e:	d7650513          	addi	a0,a0,-650 # 800085b0 <syscalls+0x188>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	d00080e7          	jalr	-768(ra) # 80000542 <panic>

000000008000384a <iunlock>:
{
    8000384a:	1101                	addi	sp,sp,-32
    8000384c:	ec06                	sd	ra,24(sp)
    8000384e:	e822                	sd	s0,16(sp)
    80003850:	e426                	sd	s1,8(sp)
    80003852:	e04a                	sd	s2,0(sp)
    80003854:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003856:	c905                	beqz	a0,80003886 <iunlock+0x3c>
    80003858:	84aa                	mv	s1,a0
    8000385a:	01050913          	addi	s2,a0,16
    8000385e:	854a                	mv	a0,s2
    80003860:	00001097          	auipc	ra,0x1
    80003864:	c80080e7          	jalr	-896(ra) # 800044e0 <holdingsleep>
    80003868:	cd19                	beqz	a0,80003886 <iunlock+0x3c>
    8000386a:	449c                	lw	a5,8(s1)
    8000386c:	00f05d63          	blez	a5,80003886 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003870:	854a                	mv	a0,s2
    80003872:	00001097          	auipc	ra,0x1
    80003876:	c2a080e7          	jalr	-982(ra) # 8000449c <releasesleep>
}
    8000387a:	60e2                	ld	ra,24(sp)
    8000387c:	6442                	ld	s0,16(sp)
    8000387e:	64a2                	ld	s1,8(sp)
    80003880:	6902                	ld	s2,0(sp)
    80003882:	6105                	addi	sp,sp,32
    80003884:	8082                	ret
    panic("iunlock");
    80003886:	00005517          	auipc	a0,0x5
    8000388a:	d3a50513          	addi	a0,a0,-710 # 800085c0 <syscalls+0x198>
    8000388e:	ffffd097          	auipc	ra,0xffffd
    80003892:	cb4080e7          	jalr	-844(ra) # 80000542 <panic>

0000000080003896 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003896:	7179                	addi	sp,sp,-48
    80003898:	f406                	sd	ra,40(sp)
    8000389a:	f022                	sd	s0,32(sp)
    8000389c:	ec26                	sd	s1,24(sp)
    8000389e:	e84a                	sd	s2,16(sp)
    800038a0:	e44e                	sd	s3,8(sp)
    800038a2:	e052                	sd	s4,0(sp)
    800038a4:	1800                	addi	s0,sp,48
    800038a6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038a8:	05050493          	addi	s1,a0,80
    800038ac:	08050913          	addi	s2,a0,128
    800038b0:	a021                	j	800038b8 <itrunc+0x22>
    800038b2:	0491                	addi	s1,s1,4
    800038b4:	01248d63          	beq	s1,s2,800038ce <itrunc+0x38>
    if(ip->addrs[i]){
    800038b8:	408c                	lw	a1,0(s1)
    800038ba:	dde5                	beqz	a1,800038b2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038bc:	0009a503          	lw	a0,0(s3)
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	90c080e7          	jalr	-1780(ra) # 800031cc <bfree>
      ip->addrs[i] = 0;
    800038c8:	0004a023          	sw	zero,0(s1)
    800038cc:	b7dd                	j	800038b2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038ce:	0809a583          	lw	a1,128(s3)
    800038d2:	e185                	bnez	a1,800038f2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038d4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038d8:	854e                	mv	a0,s3
    800038da:	00000097          	auipc	ra,0x0
    800038de:	de4080e7          	jalr	-540(ra) # 800036be <iupdate>
}
    800038e2:	70a2                	ld	ra,40(sp)
    800038e4:	7402                	ld	s0,32(sp)
    800038e6:	64e2                	ld	s1,24(sp)
    800038e8:	6942                	ld	s2,16(sp)
    800038ea:	69a2                	ld	s3,8(sp)
    800038ec:	6a02                	ld	s4,0(sp)
    800038ee:	6145                	addi	sp,sp,48
    800038f0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038f2:	0009a503          	lw	a0,0(s3)
    800038f6:	fffff097          	auipc	ra,0xfffff
    800038fa:	690080e7          	jalr	1680(ra) # 80002f86 <bread>
    800038fe:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003900:	05850493          	addi	s1,a0,88
    80003904:	45850913          	addi	s2,a0,1112
    80003908:	a021                	j	80003910 <itrunc+0x7a>
    8000390a:	0491                	addi	s1,s1,4
    8000390c:	01248b63          	beq	s1,s2,80003922 <itrunc+0x8c>
      if(a[j])
    80003910:	408c                	lw	a1,0(s1)
    80003912:	dde5                	beqz	a1,8000390a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003914:	0009a503          	lw	a0,0(s3)
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	8b4080e7          	jalr	-1868(ra) # 800031cc <bfree>
    80003920:	b7ed                	j	8000390a <itrunc+0x74>
    brelse(bp);
    80003922:	8552                	mv	a0,s4
    80003924:	fffff097          	auipc	ra,0xfffff
    80003928:	792080e7          	jalr	1938(ra) # 800030b6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000392c:	0809a583          	lw	a1,128(s3)
    80003930:	0009a503          	lw	a0,0(s3)
    80003934:	00000097          	auipc	ra,0x0
    80003938:	898080e7          	jalr	-1896(ra) # 800031cc <bfree>
    ip->addrs[NDIRECT] = 0;
    8000393c:	0809a023          	sw	zero,128(s3)
    80003940:	bf51                	j	800038d4 <itrunc+0x3e>

0000000080003942 <iput>:
{
    80003942:	1101                	addi	sp,sp,-32
    80003944:	ec06                	sd	ra,24(sp)
    80003946:	e822                	sd	s0,16(sp)
    80003948:	e426                	sd	s1,8(sp)
    8000394a:	e04a                	sd	s2,0(sp)
    8000394c:	1000                	addi	s0,sp,32
    8000394e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003950:	0023c517          	auipc	a0,0x23c
    80003954:	51050513          	addi	a0,a0,1296 # 8023fe60 <icache>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	318080e7          	jalr	792(ra) # 80000c70 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003960:	4498                	lw	a4,8(s1)
    80003962:	4785                	li	a5,1
    80003964:	02f70363          	beq	a4,a5,8000398a <iput+0x48>
  ip->ref--;
    80003968:	449c                	lw	a5,8(s1)
    8000396a:	37fd                	addiw	a5,a5,-1
    8000396c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000396e:	0023c517          	auipc	a0,0x23c
    80003972:	4f250513          	addi	a0,a0,1266 # 8023fe60 <icache>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	3ae080e7          	jalr	942(ra) # 80000d24 <release>
}
    8000397e:	60e2                	ld	ra,24(sp)
    80003980:	6442                	ld	s0,16(sp)
    80003982:	64a2                	ld	s1,8(sp)
    80003984:	6902                	ld	s2,0(sp)
    80003986:	6105                	addi	sp,sp,32
    80003988:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000398a:	40bc                	lw	a5,64(s1)
    8000398c:	dff1                	beqz	a5,80003968 <iput+0x26>
    8000398e:	04a49783          	lh	a5,74(s1)
    80003992:	fbf9                	bnez	a5,80003968 <iput+0x26>
    acquiresleep(&ip->lock);
    80003994:	01048913          	addi	s2,s1,16
    80003998:	854a                	mv	a0,s2
    8000399a:	00001097          	auipc	ra,0x1
    8000399e:	aac080e7          	jalr	-1364(ra) # 80004446 <acquiresleep>
    release(&icache.lock);
    800039a2:	0023c517          	auipc	a0,0x23c
    800039a6:	4be50513          	addi	a0,a0,1214 # 8023fe60 <icache>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	37a080e7          	jalr	890(ra) # 80000d24 <release>
    itrunc(ip);
    800039b2:	8526                	mv	a0,s1
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	ee2080e7          	jalr	-286(ra) # 80003896 <itrunc>
    ip->type = 0;
    800039bc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039c0:	8526                	mv	a0,s1
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	cfc080e7          	jalr	-772(ra) # 800036be <iupdate>
    ip->valid = 0;
    800039ca:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039ce:	854a                	mv	a0,s2
    800039d0:	00001097          	auipc	ra,0x1
    800039d4:	acc080e7          	jalr	-1332(ra) # 8000449c <releasesleep>
    acquire(&icache.lock);
    800039d8:	0023c517          	auipc	a0,0x23c
    800039dc:	48850513          	addi	a0,a0,1160 # 8023fe60 <icache>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	290080e7          	jalr	656(ra) # 80000c70 <acquire>
    800039e8:	b741                	j	80003968 <iput+0x26>

00000000800039ea <iunlockput>:
{
    800039ea:	1101                	addi	sp,sp,-32
    800039ec:	ec06                	sd	ra,24(sp)
    800039ee:	e822                	sd	s0,16(sp)
    800039f0:	e426                	sd	s1,8(sp)
    800039f2:	1000                	addi	s0,sp,32
    800039f4:	84aa                	mv	s1,a0
  iunlock(ip);
    800039f6:	00000097          	auipc	ra,0x0
    800039fa:	e54080e7          	jalr	-428(ra) # 8000384a <iunlock>
  iput(ip);
    800039fe:	8526                	mv	a0,s1
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	f42080e7          	jalr	-190(ra) # 80003942 <iput>
}
    80003a08:	60e2                	ld	ra,24(sp)
    80003a0a:	6442                	ld	s0,16(sp)
    80003a0c:	64a2                	ld	s1,8(sp)
    80003a0e:	6105                	addi	sp,sp,32
    80003a10:	8082                	ret

0000000080003a12 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a12:	1141                	addi	sp,sp,-16
    80003a14:	e422                	sd	s0,8(sp)
    80003a16:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a18:	411c                	lw	a5,0(a0)
    80003a1a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a1c:	415c                	lw	a5,4(a0)
    80003a1e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a20:	04451783          	lh	a5,68(a0)
    80003a24:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a28:	04a51783          	lh	a5,74(a0)
    80003a2c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a30:	04c56783          	lwu	a5,76(a0)
    80003a34:	e99c                	sd	a5,16(a1)
}
    80003a36:	6422                	ld	s0,8(sp)
    80003a38:	0141                	addi	sp,sp,16
    80003a3a:	8082                	ret

0000000080003a3c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a3c:	457c                	lw	a5,76(a0)
    80003a3e:	0ed7e963          	bltu	a5,a3,80003b30 <readi+0xf4>
{
    80003a42:	7159                	addi	sp,sp,-112
    80003a44:	f486                	sd	ra,104(sp)
    80003a46:	f0a2                	sd	s0,96(sp)
    80003a48:	eca6                	sd	s1,88(sp)
    80003a4a:	e8ca                	sd	s2,80(sp)
    80003a4c:	e4ce                	sd	s3,72(sp)
    80003a4e:	e0d2                	sd	s4,64(sp)
    80003a50:	fc56                	sd	s5,56(sp)
    80003a52:	f85a                	sd	s6,48(sp)
    80003a54:	f45e                	sd	s7,40(sp)
    80003a56:	f062                	sd	s8,32(sp)
    80003a58:	ec66                	sd	s9,24(sp)
    80003a5a:	e86a                	sd	s10,16(sp)
    80003a5c:	e46e                	sd	s11,8(sp)
    80003a5e:	1880                	addi	s0,sp,112
    80003a60:	8baa                	mv	s7,a0
    80003a62:	8c2e                	mv	s8,a1
    80003a64:	8ab2                	mv	s5,a2
    80003a66:	84b6                	mv	s1,a3
    80003a68:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a6a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a6c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a6e:	0ad76063          	bltu	a4,a3,80003b0e <readi+0xd2>
  if(off + n > ip->size)
    80003a72:	00e7f463          	bgeu	a5,a4,80003a7a <readi+0x3e>
    n = ip->size - off;
    80003a76:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a7a:	0a0b0963          	beqz	s6,80003b2c <readi+0xf0>
    80003a7e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a80:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a84:	5cfd                	li	s9,-1
    80003a86:	a82d                	j	80003ac0 <readi+0x84>
    80003a88:	020a1d93          	slli	s11,s4,0x20
    80003a8c:	020ddd93          	srli	s11,s11,0x20
    80003a90:	05890793          	addi	a5,s2,88
    80003a94:	86ee                	mv	a3,s11
    80003a96:	963e                	add	a2,a2,a5
    80003a98:	85d6                	mv	a1,s5
    80003a9a:	8562                	mv	a0,s8
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	a94080e7          	jalr	-1388(ra) # 80002530 <either_copyout>
    80003aa4:	05950d63          	beq	a0,s9,80003afe <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003aa8:	854a                	mv	a0,s2
    80003aaa:	fffff097          	auipc	ra,0xfffff
    80003aae:	60c080e7          	jalr	1548(ra) # 800030b6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab2:	013a09bb          	addw	s3,s4,s3
    80003ab6:	009a04bb          	addw	s1,s4,s1
    80003aba:	9aee                	add	s5,s5,s11
    80003abc:	0569f763          	bgeu	s3,s6,80003b0a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ac0:	000ba903          	lw	s2,0(s7)
    80003ac4:	00a4d59b          	srliw	a1,s1,0xa
    80003ac8:	855e                	mv	a0,s7
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	8b0080e7          	jalr	-1872(ra) # 8000337a <bmap>
    80003ad2:	0005059b          	sext.w	a1,a0
    80003ad6:	854a                	mv	a0,s2
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	4ae080e7          	jalr	1198(ra) # 80002f86 <bread>
    80003ae0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ae2:	3ff4f613          	andi	a2,s1,1023
    80003ae6:	40cd07bb          	subw	a5,s10,a2
    80003aea:	413b073b          	subw	a4,s6,s3
    80003aee:	8a3e                	mv	s4,a5
    80003af0:	2781                	sext.w	a5,a5
    80003af2:	0007069b          	sext.w	a3,a4
    80003af6:	f8f6f9e3          	bgeu	a3,a5,80003a88 <readi+0x4c>
    80003afa:	8a3a                	mv	s4,a4
    80003afc:	b771                	j	80003a88 <readi+0x4c>
      brelse(bp);
    80003afe:	854a                	mv	a0,s2
    80003b00:	fffff097          	auipc	ra,0xfffff
    80003b04:	5b6080e7          	jalr	1462(ra) # 800030b6 <brelse>
      tot = -1;
    80003b08:	59fd                	li	s3,-1
  }
  return tot;
    80003b0a:	0009851b          	sext.w	a0,s3
}
    80003b0e:	70a6                	ld	ra,104(sp)
    80003b10:	7406                	ld	s0,96(sp)
    80003b12:	64e6                	ld	s1,88(sp)
    80003b14:	6946                	ld	s2,80(sp)
    80003b16:	69a6                	ld	s3,72(sp)
    80003b18:	6a06                	ld	s4,64(sp)
    80003b1a:	7ae2                	ld	s5,56(sp)
    80003b1c:	7b42                	ld	s6,48(sp)
    80003b1e:	7ba2                	ld	s7,40(sp)
    80003b20:	7c02                	ld	s8,32(sp)
    80003b22:	6ce2                	ld	s9,24(sp)
    80003b24:	6d42                	ld	s10,16(sp)
    80003b26:	6da2                	ld	s11,8(sp)
    80003b28:	6165                	addi	sp,sp,112
    80003b2a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b2c:	89da                	mv	s3,s6
    80003b2e:	bff1                	j	80003b0a <readi+0xce>
    return 0;
    80003b30:	4501                	li	a0,0
}
    80003b32:	8082                	ret

0000000080003b34 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b34:	457c                	lw	a5,76(a0)
    80003b36:	10d7e763          	bltu	a5,a3,80003c44 <writei+0x110>
{
    80003b3a:	7159                	addi	sp,sp,-112
    80003b3c:	f486                	sd	ra,104(sp)
    80003b3e:	f0a2                	sd	s0,96(sp)
    80003b40:	eca6                	sd	s1,88(sp)
    80003b42:	e8ca                	sd	s2,80(sp)
    80003b44:	e4ce                	sd	s3,72(sp)
    80003b46:	e0d2                	sd	s4,64(sp)
    80003b48:	fc56                	sd	s5,56(sp)
    80003b4a:	f85a                	sd	s6,48(sp)
    80003b4c:	f45e                	sd	s7,40(sp)
    80003b4e:	f062                	sd	s8,32(sp)
    80003b50:	ec66                	sd	s9,24(sp)
    80003b52:	e86a                	sd	s10,16(sp)
    80003b54:	e46e                	sd	s11,8(sp)
    80003b56:	1880                	addi	s0,sp,112
    80003b58:	8baa                	mv	s7,a0
    80003b5a:	8c2e                	mv	s8,a1
    80003b5c:	8ab2                	mv	s5,a2
    80003b5e:	8936                	mv	s2,a3
    80003b60:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b62:	00e687bb          	addw	a5,a3,a4
    80003b66:	0ed7e163          	bltu	a5,a3,80003c48 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b6a:	00043737          	lui	a4,0x43
    80003b6e:	0cf76f63          	bltu	a4,a5,80003c4c <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b72:	0a0b0863          	beqz	s6,80003c22 <writei+0xee>
    80003b76:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b78:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b7c:	5cfd                	li	s9,-1
    80003b7e:	a091                	j	80003bc2 <writei+0x8e>
    80003b80:	02099d93          	slli	s11,s3,0x20
    80003b84:	020ddd93          	srli	s11,s11,0x20
    80003b88:	05848793          	addi	a5,s1,88
    80003b8c:	86ee                	mv	a3,s11
    80003b8e:	8656                	mv	a2,s5
    80003b90:	85e2                	mv	a1,s8
    80003b92:	953e                	add	a0,a0,a5
    80003b94:	fffff097          	auipc	ra,0xfffff
    80003b98:	9f2080e7          	jalr	-1550(ra) # 80002586 <either_copyin>
    80003b9c:	07950263          	beq	a0,s9,80003c00 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003ba0:	8526                	mv	a0,s1
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	77c080e7          	jalr	1916(ra) # 8000431e <log_write>
    brelse(bp);
    80003baa:	8526                	mv	a0,s1
    80003bac:	fffff097          	auipc	ra,0xfffff
    80003bb0:	50a080e7          	jalr	1290(ra) # 800030b6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb4:	01498a3b          	addw	s4,s3,s4
    80003bb8:	0129893b          	addw	s2,s3,s2
    80003bbc:	9aee                	add	s5,s5,s11
    80003bbe:	056a7763          	bgeu	s4,s6,80003c0c <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bc2:	000ba483          	lw	s1,0(s7)
    80003bc6:	00a9559b          	srliw	a1,s2,0xa
    80003bca:	855e                	mv	a0,s7
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	7ae080e7          	jalr	1966(ra) # 8000337a <bmap>
    80003bd4:	0005059b          	sext.w	a1,a0
    80003bd8:	8526                	mv	a0,s1
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	3ac080e7          	jalr	940(ra) # 80002f86 <bread>
    80003be2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003be4:	3ff97513          	andi	a0,s2,1023
    80003be8:	40ad07bb          	subw	a5,s10,a0
    80003bec:	414b073b          	subw	a4,s6,s4
    80003bf0:	89be                	mv	s3,a5
    80003bf2:	2781                	sext.w	a5,a5
    80003bf4:	0007069b          	sext.w	a3,a4
    80003bf8:	f8f6f4e3          	bgeu	a3,a5,80003b80 <writei+0x4c>
    80003bfc:	89ba                	mv	s3,a4
    80003bfe:	b749                	j	80003b80 <writei+0x4c>
      brelse(bp);
    80003c00:	8526                	mv	a0,s1
    80003c02:	fffff097          	auipc	ra,0xfffff
    80003c06:	4b4080e7          	jalr	1204(ra) # 800030b6 <brelse>
      n = -1;
    80003c0a:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003c0c:	04cba783          	lw	a5,76(s7)
    80003c10:	0127f463          	bgeu	a5,s2,80003c18 <writei+0xe4>
      ip->size = off;
    80003c14:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c18:	855e                	mv	a0,s7
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	aa4080e7          	jalr	-1372(ra) # 800036be <iupdate>
  }

  return n;
    80003c22:	000b051b          	sext.w	a0,s6
}
    80003c26:	70a6                	ld	ra,104(sp)
    80003c28:	7406                	ld	s0,96(sp)
    80003c2a:	64e6                	ld	s1,88(sp)
    80003c2c:	6946                	ld	s2,80(sp)
    80003c2e:	69a6                	ld	s3,72(sp)
    80003c30:	6a06                	ld	s4,64(sp)
    80003c32:	7ae2                	ld	s5,56(sp)
    80003c34:	7b42                	ld	s6,48(sp)
    80003c36:	7ba2                	ld	s7,40(sp)
    80003c38:	7c02                	ld	s8,32(sp)
    80003c3a:	6ce2                	ld	s9,24(sp)
    80003c3c:	6d42                	ld	s10,16(sp)
    80003c3e:	6da2                	ld	s11,8(sp)
    80003c40:	6165                	addi	sp,sp,112
    80003c42:	8082                	ret
    return -1;
    80003c44:	557d                	li	a0,-1
}
    80003c46:	8082                	ret
    return -1;
    80003c48:	557d                	li	a0,-1
    80003c4a:	bff1                	j	80003c26 <writei+0xf2>
    return -1;
    80003c4c:	557d                	li	a0,-1
    80003c4e:	bfe1                	j	80003c26 <writei+0xf2>

0000000080003c50 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c50:	1141                	addi	sp,sp,-16
    80003c52:	e406                	sd	ra,8(sp)
    80003c54:	e022                	sd	s0,0(sp)
    80003c56:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c58:	4639                	li	a2,14
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	1ea080e7          	jalr	490(ra) # 80000e44 <strncmp>
}
    80003c62:	60a2                	ld	ra,8(sp)
    80003c64:	6402                	ld	s0,0(sp)
    80003c66:	0141                	addi	sp,sp,16
    80003c68:	8082                	ret

0000000080003c6a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c6a:	7139                	addi	sp,sp,-64
    80003c6c:	fc06                	sd	ra,56(sp)
    80003c6e:	f822                	sd	s0,48(sp)
    80003c70:	f426                	sd	s1,40(sp)
    80003c72:	f04a                	sd	s2,32(sp)
    80003c74:	ec4e                	sd	s3,24(sp)
    80003c76:	e852                	sd	s4,16(sp)
    80003c78:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c7a:	04451703          	lh	a4,68(a0)
    80003c7e:	4785                	li	a5,1
    80003c80:	00f71a63          	bne	a4,a5,80003c94 <dirlookup+0x2a>
    80003c84:	892a                	mv	s2,a0
    80003c86:	89ae                	mv	s3,a1
    80003c88:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c8a:	457c                	lw	a5,76(a0)
    80003c8c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c8e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c90:	e79d                	bnez	a5,80003cbe <dirlookup+0x54>
    80003c92:	a8a5                	j	80003d0a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c94:	00005517          	auipc	a0,0x5
    80003c98:	93450513          	addi	a0,a0,-1740 # 800085c8 <syscalls+0x1a0>
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	8a6080e7          	jalr	-1882(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003ca4:	00005517          	auipc	a0,0x5
    80003ca8:	93c50513          	addi	a0,a0,-1732 # 800085e0 <syscalls+0x1b8>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	896080e7          	jalr	-1898(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb4:	24c1                	addiw	s1,s1,16
    80003cb6:	04c92783          	lw	a5,76(s2)
    80003cba:	04f4f763          	bgeu	s1,a5,80003d08 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cbe:	4741                	li	a4,16
    80003cc0:	86a6                	mv	a3,s1
    80003cc2:	fc040613          	addi	a2,s0,-64
    80003cc6:	4581                	li	a1,0
    80003cc8:	854a                	mv	a0,s2
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	d72080e7          	jalr	-654(ra) # 80003a3c <readi>
    80003cd2:	47c1                	li	a5,16
    80003cd4:	fcf518e3          	bne	a0,a5,80003ca4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cd8:	fc045783          	lhu	a5,-64(s0)
    80003cdc:	dfe1                	beqz	a5,80003cb4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cde:	fc240593          	addi	a1,s0,-62
    80003ce2:	854e                	mv	a0,s3
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	f6c080e7          	jalr	-148(ra) # 80003c50 <namecmp>
    80003cec:	f561                	bnez	a0,80003cb4 <dirlookup+0x4a>
      if(poff)
    80003cee:	000a0463          	beqz	s4,80003cf6 <dirlookup+0x8c>
        *poff = off;
    80003cf2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cf6:	fc045583          	lhu	a1,-64(s0)
    80003cfa:	00092503          	lw	a0,0(s2)
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	756080e7          	jalr	1878(ra) # 80003454 <iget>
    80003d06:	a011                	j	80003d0a <dirlookup+0xa0>
  return 0;
    80003d08:	4501                	li	a0,0
}
    80003d0a:	70e2                	ld	ra,56(sp)
    80003d0c:	7442                	ld	s0,48(sp)
    80003d0e:	74a2                	ld	s1,40(sp)
    80003d10:	7902                	ld	s2,32(sp)
    80003d12:	69e2                	ld	s3,24(sp)
    80003d14:	6a42                	ld	s4,16(sp)
    80003d16:	6121                	addi	sp,sp,64
    80003d18:	8082                	ret

0000000080003d1a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d1a:	711d                	addi	sp,sp,-96
    80003d1c:	ec86                	sd	ra,88(sp)
    80003d1e:	e8a2                	sd	s0,80(sp)
    80003d20:	e4a6                	sd	s1,72(sp)
    80003d22:	e0ca                	sd	s2,64(sp)
    80003d24:	fc4e                	sd	s3,56(sp)
    80003d26:	f852                	sd	s4,48(sp)
    80003d28:	f456                	sd	s5,40(sp)
    80003d2a:	f05a                	sd	s6,32(sp)
    80003d2c:	ec5e                	sd	s7,24(sp)
    80003d2e:	e862                	sd	s8,16(sp)
    80003d30:	e466                	sd	s9,8(sp)
    80003d32:	1080                	addi	s0,sp,96
    80003d34:	84aa                	mv	s1,a0
    80003d36:	8aae                	mv	s5,a1
    80003d38:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d3a:	00054703          	lbu	a4,0(a0)
    80003d3e:	02f00793          	li	a5,47
    80003d42:	02f70363          	beq	a4,a5,80003d68 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d46:	ffffe097          	auipc	ra,0xffffe
    80003d4a:	d7c080e7          	jalr	-644(ra) # 80001ac2 <myproc>
    80003d4e:	15053503          	ld	a0,336(a0)
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	9f8080e7          	jalr	-1544(ra) # 8000374a <idup>
    80003d5a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d5c:	02f00913          	li	s2,47
  len = path - s;
    80003d60:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d62:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d64:	4b85                	li	s7,1
    80003d66:	a865                	j	80003e1e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d68:	4585                	li	a1,1
    80003d6a:	4505                	li	a0,1
    80003d6c:	fffff097          	auipc	ra,0xfffff
    80003d70:	6e8080e7          	jalr	1768(ra) # 80003454 <iget>
    80003d74:	89aa                	mv	s3,a0
    80003d76:	b7dd                	j	80003d5c <namex+0x42>
      iunlockput(ip);
    80003d78:	854e                	mv	a0,s3
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	c70080e7          	jalr	-912(ra) # 800039ea <iunlockput>
      return 0;
    80003d82:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d84:	854e                	mv	a0,s3
    80003d86:	60e6                	ld	ra,88(sp)
    80003d88:	6446                	ld	s0,80(sp)
    80003d8a:	64a6                	ld	s1,72(sp)
    80003d8c:	6906                	ld	s2,64(sp)
    80003d8e:	79e2                	ld	s3,56(sp)
    80003d90:	7a42                	ld	s4,48(sp)
    80003d92:	7aa2                	ld	s5,40(sp)
    80003d94:	7b02                	ld	s6,32(sp)
    80003d96:	6be2                	ld	s7,24(sp)
    80003d98:	6c42                	ld	s8,16(sp)
    80003d9a:	6ca2                	ld	s9,8(sp)
    80003d9c:	6125                	addi	sp,sp,96
    80003d9e:	8082                	ret
      iunlock(ip);
    80003da0:	854e                	mv	a0,s3
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	aa8080e7          	jalr	-1368(ra) # 8000384a <iunlock>
      return ip;
    80003daa:	bfe9                	j	80003d84 <namex+0x6a>
      iunlockput(ip);
    80003dac:	854e                	mv	a0,s3
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	c3c080e7          	jalr	-964(ra) # 800039ea <iunlockput>
      return 0;
    80003db6:	89e6                	mv	s3,s9
    80003db8:	b7f1                	j	80003d84 <namex+0x6a>
  len = path - s;
    80003dba:	40b48633          	sub	a2,s1,a1
    80003dbe:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003dc2:	099c5463          	bge	s8,s9,80003e4a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dc6:	4639                	li	a2,14
    80003dc8:	8552                	mv	a0,s4
    80003dca:	ffffd097          	auipc	ra,0xffffd
    80003dce:	ffe080e7          	jalr	-2(ra) # 80000dc8 <memmove>
  while(*path == '/')
    80003dd2:	0004c783          	lbu	a5,0(s1)
    80003dd6:	01279763          	bne	a5,s2,80003de4 <namex+0xca>
    path++;
    80003dda:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ddc:	0004c783          	lbu	a5,0(s1)
    80003de0:	ff278de3          	beq	a5,s2,80003dda <namex+0xc0>
    ilock(ip);
    80003de4:	854e                	mv	a0,s3
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	9a2080e7          	jalr	-1630(ra) # 80003788 <ilock>
    if(ip->type != T_DIR){
    80003dee:	04499783          	lh	a5,68(s3)
    80003df2:	f97793e3          	bne	a5,s7,80003d78 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003df6:	000a8563          	beqz	s5,80003e00 <namex+0xe6>
    80003dfa:	0004c783          	lbu	a5,0(s1)
    80003dfe:	d3cd                	beqz	a5,80003da0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e00:	865a                	mv	a2,s6
    80003e02:	85d2                	mv	a1,s4
    80003e04:	854e                	mv	a0,s3
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	e64080e7          	jalr	-412(ra) # 80003c6a <dirlookup>
    80003e0e:	8caa                	mv	s9,a0
    80003e10:	dd51                	beqz	a0,80003dac <namex+0x92>
    iunlockput(ip);
    80003e12:	854e                	mv	a0,s3
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	bd6080e7          	jalr	-1066(ra) # 800039ea <iunlockput>
    ip = next;
    80003e1c:	89e6                	mv	s3,s9
  while(*path == '/')
    80003e1e:	0004c783          	lbu	a5,0(s1)
    80003e22:	05279763          	bne	a5,s2,80003e70 <namex+0x156>
    path++;
    80003e26:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e28:	0004c783          	lbu	a5,0(s1)
    80003e2c:	ff278de3          	beq	a5,s2,80003e26 <namex+0x10c>
  if(*path == 0)
    80003e30:	c79d                	beqz	a5,80003e5e <namex+0x144>
    path++;
    80003e32:	85a6                	mv	a1,s1
  len = path - s;
    80003e34:	8cda                	mv	s9,s6
    80003e36:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e38:	01278963          	beq	a5,s2,80003e4a <namex+0x130>
    80003e3c:	dfbd                	beqz	a5,80003dba <namex+0xa0>
    path++;
    80003e3e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e40:	0004c783          	lbu	a5,0(s1)
    80003e44:	ff279ce3          	bne	a5,s2,80003e3c <namex+0x122>
    80003e48:	bf8d                	j	80003dba <namex+0xa0>
    memmove(name, s, len);
    80003e4a:	2601                	sext.w	a2,a2
    80003e4c:	8552                	mv	a0,s4
    80003e4e:	ffffd097          	auipc	ra,0xffffd
    80003e52:	f7a080e7          	jalr	-134(ra) # 80000dc8 <memmove>
    name[len] = 0;
    80003e56:	9cd2                	add	s9,s9,s4
    80003e58:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e5c:	bf9d                	j	80003dd2 <namex+0xb8>
  if(nameiparent){
    80003e5e:	f20a83e3          	beqz	s5,80003d84 <namex+0x6a>
    iput(ip);
    80003e62:	854e                	mv	a0,s3
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	ade080e7          	jalr	-1314(ra) # 80003942 <iput>
    return 0;
    80003e6c:	4981                	li	s3,0
    80003e6e:	bf19                	j	80003d84 <namex+0x6a>
  if(*path == 0)
    80003e70:	d7fd                	beqz	a5,80003e5e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e72:	0004c783          	lbu	a5,0(s1)
    80003e76:	85a6                	mv	a1,s1
    80003e78:	b7d1                	j	80003e3c <namex+0x122>

0000000080003e7a <dirlink>:
{
    80003e7a:	7139                	addi	sp,sp,-64
    80003e7c:	fc06                	sd	ra,56(sp)
    80003e7e:	f822                	sd	s0,48(sp)
    80003e80:	f426                	sd	s1,40(sp)
    80003e82:	f04a                	sd	s2,32(sp)
    80003e84:	ec4e                	sd	s3,24(sp)
    80003e86:	e852                	sd	s4,16(sp)
    80003e88:	0080                	addi	s0,sp,64
    80003e8a:	892a                	mv	s2,a0
    80003e8c:	8a2e                	mv	s4,a1
    80003e8e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e90:	4601                	li	a2,0
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	dd8080e7          	jalr	-552(ra) # 80003c6a <dirlookup>
    80003e9a:	e93d                	bnez	a0,80003f10 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e9c:	04c92483          	lw	s1,76(s2)
    80003ea0:	c49d                	beqz	s1,80003ece <dirlink+0x54>
    80003ea2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea4:	4741                	li	a4,16
    80003ea6:	86a6                	mv	a3,s1
    80003ea8:	fc040613          	addi	a2,s0,-64
    80003eac:	4581                	li	a1,0
    80003eae:	854a                	mv	a0,s2
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	b8c080e7          	jalr	-1140(ra) # 80003a3c <readi>
    80003eb8:	47c1                	li	a5,16
    80003eba:	06f51163          	bne	a0,a5,80003f1c <dirlink+0xa2>
    if(de.inum == 0)
    80003ebe:	fc045783          	lhu	a5,-64(s0)
    80003ec2:	c791                	beqz	a5,80003ece <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec4:	24c1                	addiw	s1,s1,16
    80003ec6:	04c92783          	lw	a5,76(s2)
    80003eca:	fcf4ede3          	bltu	s1,a5,80003ea4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ece:	4639                	li	a2,14
    80003ed0:	85d2                	mv	a1,s4
    80003ed2:	fc240513          	addi	a0,s0,-62
    80003ed6:	ffffd097          	auipc	ra,0xffffd
    80003eda:	faa080e7          	jalr	-86(ra) # 80000e80 <strncpy>
  de.inum = inum;
    80003ede:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee2:	4741                	li	a4,16
    80003ee4:	86a6                	mv	a3,s1
    80003ee6:	fc040613          	addi	a2,s0,-64
    80003eea:	4581                	li	a1,0
    80003eec:	854a                	mv	a0,s2
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	c46080e7          	jalr	-954(ra) # 80003b34 <writei>
    80003ef6:	872a                	mv	a4,a0
    80003ef8:	47c1                	li	a5,16
  return 0;
    80003efa:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003efc:	02f71863          	bne	a4,a5,80003f2c <dirlink+0xb2>
}
    80003f00:	70e2                	ld	ra,56(sp)
    80003f02:	7442                	ld	s0,48(sp)
    80003f04:	74a2                	ld	s1,40(sp)
    80003f06:	7902                	ld	s2,32(sp)
    80003f08:	69e2                	ld	s3,24(sp)
    80003f0a:	6a42                	ld	s4,16(sp)
    80003f0c:	6121                	addi	sp,sp,64
    80003f0e:	8082                	ret
    iput(ip);
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	a32080e7          	jalr	-1486(ra) # 80003942 <iput>
    return -1;
    80003f18:	557d                	li	a0,-1
    80003f1a:	b7dd                	j	80003f00 <dirlink+0x86>
      panic("dirlink read");
    80003f1c:	00004517          	auipc	a0,0x4
    80003f20:	6d450513          	addi	a0,a0,1748 # 800085f0 <syscalls+0x1c8>
    80003f24:	ffffc097          	auipc	ra,0xffffc
    80003f28:	61e080e7          	jalr	1566(ra) # 80000542 <panic>
    panic("dirlink");
    80003f2c:	00004517          	auipc	a0,0x4
    80003f30:	7e450513          	addi	a0,a0,2020 # 80008710 <syscalls+0x2e8>
    80003f34:	ffffc097          	auipc	ra,0xffffc
    80003f38:	60e080e7          	jalr	1550(ra) # 80000542 <panic>

0000000080003f3c <namei>:

struct inode*
namei(char *path)
{
    80003f3c:	1101                	addi	sp,sp,-32
    80003f3e:	ec06                	sd	ra,24(sp)
    80003f40:	e822                	sd	s0,16(sp)
    80003f42:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f44:	fe040613          	addi	a2,s0,-32
    80003f48:	4581                	li	a1,0
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	dd0080e7          	jalr	-560(ra) # 80003d1a <namex>
}
    80003f52:	60e2                	ld	ra,24(sp)
    80003f54:	6442                	ld	s0,16(sp)
    80003f56:	6105                	addi	sp,sp,32
    80003f58:	8082                	ret

0000000080003f5a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f5a:	1141                	addi	sp,sp,-16
    80003f5c:	e406                	sd	ra,8(sp)
    80003f5e:	e022                	sd	s0,0(sp)
    80003f60:	0800                	addi	s0,sp,16
    80003f62:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f64:	4585                	li	a1,1
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	db4080e7          	jalr	-588(ra) # 80003d1a <namex>
}
    80003f6e:	60a2                	ld	ra,8(sp)
    80003f70:	6402                	ld	s0,0(sp)
    80003f72:	0141                	addi	sp,sp,16
    80003f74:	8082                	ret

0000000080003f76 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f76:	1101                	addi	sp,sp,-32
    80003f78:	ec06                	sd	ra,24(sp)
    80003f7a:	e822                	sd	s0,16(sp)
    80003f7c:	e426                	sd	s1,8(sp)
    80003f7e:	e04a                	sd	s2,0(sp)
    80003f80:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f82:	0023e917          	auipc	s2,0x23e
    80003f86:	98690913          	addi	s2,s2,-1658 # 80241908 <log>
    80003f8a:	01892583          	lw	a1,24(s2)
    80003f8e:	02892503          	lw	a0,40(s2)
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	ff4080e7          	jalr	-12(ra) # 80002f86 <bread>
    80003f9a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f9c:	02c92683          	lw	a3,44(s2)
    80003fa0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fa2:	02d05763          	blez	a3,80003fd0 <write_head+0x5a>
    80003fa6:	0023e797          	auipc	a5,0x23e
    80003faa:	99278793          	addi	a5,a5,-1646 # 80241938 <log+0x30>
    80003fae:	05c50713          	addi	a4,a0,92
    80003fb2:	36fd                	addiw	a3,a3,-1
    80003fb4:	1682                	slli	a3,a3,0x20
    80003fb6:	9281                	srli	a3,a3,0x20
    80003fb8:	068a                	slli	a3,a3,0x2
    80003fba:	0023e617          	auipc	a2,0x23e
    80003fbe:	98260613          	addi	a2,a2,-1662 # 8024193c <log+0x34>
    80003fc2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fc4:	4390                	lw	a2,0(a5)
    80003fc6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fc8:	0791                	addi	a5,a5,4
    80003fca:	0711                	addi	a4,a4,4
    80003fcc:	fed79ce3          	bne	a5,a3,80003fc4 <write_head+0x4e>
  }
  bwrite(buf);
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	0a6080e7          	jalr	166(ra) # 80003078 <bwrite>
  brelse(buf);
    80003fda:	8526                	mv	a0,s1
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	0da080e7          	jalr	218(ra) # 800030b6 <brelse>
}
    80003fe4:	60e2                	ld	ra,24(sp)
    80003fe6:	6442                	ld	s0,16(sp)
    80003fe8:	64a2                	ld	s1,8(sp)
    80003fea:	6902                	ld	s2,0(sp)
    80003fec:	6105                	addi	sp,sp,32
    80003fee:	8082                	ret

0000000080003ff0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff0:	0023e797          	auipc	a5,0x23e
    80003ff4:	9447a783          	lw	a5,-1724(a5) # 80241934 <log+0x2c>
    80003ff8:	0af05663          	blez	a5,800040a4 <install_trans+0xb4>
{
    80003ffc:	7139                	addi	sp,sp,-64
    80003ffe:	fc06                	sd	ra,56(sp)
    80004000:	f822                	sd	s0,48(sp)
    80004002:	f426                	sd	s1,40(sp)
    80004004:	f04a                	sd	s2,32(sp)
    80004006:	ec4e                	sd	s3,24(sp)
    80004008:	e852                	sd	s4,16(sp)
    8000400a:	e456                	sd	s5,8(sp)
    8000400c:	0080                	addi	s0,sp,64
    8000400e:	0023ea97          	auipc	s5,0x23e
    80004012:	92aa8a93          	addi	s5,s5,-1750 # 80241938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004016:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004018:	0023e997          	auipc	s3,0x23e
    8000401c:	8f098993          	addi	s3,s3,-1808 # 80241908 <log>
    80004020:	0189a583          	lw	a1,24(s3)
    80004024:	014585bb          	addw	a1,a1,s4
    80004028:	2585                	addiw	a1,a1,1
    8000402a:	0289a503          	lw	a0,40(s3)
    8000402e:	fffff097          	auipc	ra,0xfffff
    80004032:	f58080e7          	jalr	-168(ra) # 80002f86 <bread>
    80004036:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004038:	000aa583          	lw	a1,0(s5)
    8000403c:	0289a503          	lw	a0,40(s3)
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	f46080e7          	jalr	-186(ra) # 80002f86 <bread>
    80004048:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000404a:	40000613          	li	a2,1024
    8000404e:	05890593          	addi	a1,s2,88
    80004052:	05850513          	addi	a0,a0,88
    80004056:	ffffd097          	auipc	ra,0xffffd
    8000405a:	d72080e7          	jalr	-654(ra) # 80000dc8 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000405e:	8526                	mv	a0,s1
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	018080e7          	jalr	24(ra) # 80003078 <bwrite>
    bunpin(dbuf);
    80004068:	8526                	mv	a0,s1
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	126080e7          	jalr	294(ra) # 80003190 <bunpin>
    brelse(lbuf);
    80004072:	854a                	mv	a0,s2
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	042080e7          	jalr	66(ra) # 800030b6 <brelse>
    brelse(dbuf);
    8000407c:	8526                	mv	a0,s1
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	038080e7          	jalr	56(ra) # 800030b6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004086:	2a05                	addiw	s4,s4,1
    80004088:	0a91                	addi	s5,s5,4
    8000408a:	02c9a783          	lw	a5,44(s3)
    8000408e:	f8fa49e3          	blt	s4,a5,80004020 <install_trans+0x30>
}
    80004092:	70e2                	ld	ra,56(sp)
    80004094:	7442                	ld	s0,48(sp)
    80004096:	74a2                	ld	s1,40(sp)
    80004098:	7902                	ld	s2,32(sp)
    8000409a:	69e2                	ld	s3,24(sp)
    8000409c:	6a42                	ld	s4,16(sp)
    8000409e:	6aa2                	ld	s5,8(sp)
    800040a0:	6121                	addi	sp,sp,64
    800040a2:	8082                	ret
    800040a4:	8082                	ret

00000000800040a6 <initlog>:
{
    800040a6:	7179                	addi	sp,sp,-48
    800040a8:	f406                	sd	ra,40(sp)
    800040aa:	f022                	sd	s0,32(sp)
    800040ac:	ec26                	sd	s1,24(sp)
    800040ae:	e84a                	sd	s2,16(sp)
    800040b0:	e44e                	sd	s3,8(sp)
    800040b2:	1800                	addi	s0,sp,48
    800040b4:	892a                	mv	s2,a0
    800040b6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040b8:	0023e497          	auipc	s1,0x23e
    800040bc:	85048493          	addi	s1,s1,-1968 # 80241908 <log>
    800040c0:	00004597          	auipc	a1,0x4
    800040c4:	54058593          	addi	a1,a1,1344 # 80008600 <syscalls+0x1d8>
    800040c8:	8526                	mv	a0,s1
    800040ca:	ffffd097          	auipc	ra,0xffffd
    800040ce:	b16080e7          	jalr	-1258(ra) # 80000be0 <initlock>
  log.start = sb->logstart;
    800040d2:	0149a583          	lw	a1,20(s3)
    800040d6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040d8:	0109a783          	lw	a5,16(s3)
    800040dc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040de:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040e2:	854a                	mv	a0,s2
    800040e4:	fffff097          	auipc	ra,0xfffff
    800040e8:	ea2080e7          	jalr	-350(ra) # 80002f86 <bread>
  log.lh.n = lh->n;
    800040ec:	4d34                	lw	a3,88(a0)
    800040ee:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040f0:	02d05563          	blez	a3,8000411a <initlog+0x74>
    800040f4:	05c50793          	addi	a5,a0,92
    800040f8:	0023e717          	auipc	a4,0x23e
    800040fc:	84070713          	addi	a4,a4,-1984 # 80241938 <log+0x30>
    80004100:	36fd                	addiw	a3,a3,-1
    80004102:	1682                	slli	a3,a3,0x20
    80004104:	9281                	srli	a3,a3,0x20
    80004106:	068a                	slli	a3,a3,0x2
    80004108:	06050613          	addi	a2,a0,96
    8000410c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000410e:	4390                	lw	a2,0(a5)
    80004110:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004112:	0791                	addi	a5,a5,4
    80004114:	0711                	addi	a4,a4,4
    80004116:	fed79ce3          	bne	a5,a3,8000410e <initlog+0x68>
  brelse(buf);
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	f9c080e7          	jalr	-100(ra) # 800030b6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004122:	00000097          	auipc	ra,0x0
    80004126:	ece080e7          	jalr	-306(ra) # 80003ff0 <install_trans>
  log.lh.n = 0;
    8000412a:	0023e797          	auipc	a5,0x23e
    8000412e:	8007a523          	sw	zero,-2038(a5) # 80241934 <log+0x2c>
  write_head(); // clear the log
    80004132:	00000097          	auipc	ra,0x0
    80004136:	e44080e7          	jalr	-444(ra) # 80003f76 <write_head>
}
    8000413a:	70a2                	ld	ra,40(sp)
    8000413c:	7402                	ld	s0,32(sp)
    8000413e:	64e2                	ld	s1,24(sp)
    80004140:	6942                	ld	s2,16(sp)
    80004142:	69a2                	ld	s3,8(sp)
    80004144:	6145                	addi	sp,sp,48
    80004146:	8082                	ret

0000000080004148 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004148:	1101                	addi	sp,sp,-32
    8000414a:	ec06                	sd	ra,24(sp)
    8000414c:	e822                	sd	s0,16(sp)
    8000414e:	e426                	sd	s1,8(sp)
    80004150:	e04a                	sd	s2,0(sp)
    80004152:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004154:	0023d517          	auipc	a0,0x23d
    80004158:	7b450513          	addi	a0,a0,1972 # 80241908 <log>
    8000415c:	ffffd097          	auipc	ra,0xffffd
    80004160:	b14080e7          	jalr	-1260(ra) # 80000c70 <acquire>
  while(1){
    if(log.committing){
    80004164:	0023d497          	auipc	s1,0x23d
    80004168:	7a448493          	addi	s1,s1,1956 # 80241908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000416c:	4979                	li	s2,30
    8000416e:	a039                	j	8000417c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004170:	85a6                	mv	a1,s1
    80004172:	8526                	mv	a0,s1
    80004174:	ffffe097          	auipc	ra,0xffffe
    80004178:	162080e7          	jalr	354(ra) # 800022d6 <sleep>
    if(log.committing){
    8000417c:	50dc                	lw	a5,36(s1)
    8000417e:	fbed                	bnez	a5,80004170 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004180:	509c                	lw	a5,32(s1)
    80004182:	0017871b          	addiw	a4,a5,1
    80004186:	0007069b          	sext.w	a3,a4
    8000418a:	0027179b          	slliw	a5,a4,0x2
    8000418e:	9fb9                	addw	a5,a5,a4
    80004190:	0017979b          	slliw	a5,a5,0x1
    80004194:	54d8                	lw	a4,44(s1)
    80004196:	9fb9                	addw	a5,a5,a4
    80004198:	00f95963          	bge	s2,a5,800041aa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000419c:	85a6                	mv	a1,s1
    8000419e:	8526                	mv	a0,s1
    800041a0:	ffffe097          	auipc	ra,0xffffe
    800041a4:	136080e7          	jalr	310(ra) # 800022d6 <sleep>
    800041a8:	bfd1                	j	8000417c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041aa:	0023d517          	auipc	a0,0x23d
    800041ae:	75e50513          	addi	a0,a0,1886 # 80241908 <log>
    800041b2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	b70080e7          	jalr	-1168(ra) # 80000d24 <release>
      break;
    }
  }
}
    800041bc:	60e2                	ld	ra,24(sp)
    800041be:	6442                	ld	s0,16(sp)
    800041c0:	64a2                	ld	s1,8(sp)
    800041c2:	6902                	ld	s2,0(sp)
    800041c4:	6105                	addi	sp,sp,32
    800041c6:	8082                	ret

00000000800041c8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041c8:	7139                	addi	sp,sp,-64
    800041ca:	fc06                	sd	ra,56(sp)
    800041cc:	f822                	sd	s0,48(sp)
    800041ce:	f426                	sd	s1,40(sp)
    800041d0:	f04a                	sd	s2,32(sp)
    800041d2:	ec4e                	sd	s3,24(sp)
    800041d4:	e852                	sd	s4,16(sp)
    800041d6:	e456                	sd	s5,8(sp)
    800041d8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041da:	0023d497          	auipc	s1,0x23d
    800041de:	72e48493          	addi	s1,s1,1838 # 80241908 <log>
    800041e2:	8526                	mv	a0,s1
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	a8c080e7          	jalr	-1396(ra) # 80000c70 <acquire>
  log.outstanding -= 1;
    800041ec:	509c                	lw	a5,32(s1)
    800041ee:	37fd                	addiw	a5,a5,-1
    800041f0:	0007891b          	sext.w	s2,a5
    800041f4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041f6:	50dc                	lw	a5,36(s1)
    800041f8:	e7b9                	bnez	a5,80004246 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041fa:	04091e63          	bnez	s2,80004256 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041fe:	0023d497          	auipc	s1,0x23d
    80004202:	70a48493          	addi	s1,s1,1802 # 80241908 <log>
    80004206:	4785                	li	a5,1
    80004208:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000420a:	8526                	mv	a0,s1
    8000420c:	ffffd097          	auipc	ra,0xffffd
    80004210:	b18080e7          	jalr	-1256(ra) # 80000d24 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004214:	54dc                	lw	a5,44(s1)
    80004216:	06f04763          	bgtz	a5,80004284 <end_op+0xbc>
    acquire(&log.lock);
    8000421a:	0023d497          	auipc	s1,0x23d
    8000421e:	6ee48493          	addi	s1,s1,1774 # 80241908 <log>
    80004222:	8526                	mv	a0,s1
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	a4c080e7          	jalr	-1460(ra) # 80000c70 <acquire>
    log.committing = 0;
    8000422c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004230:	8526                	mv	a0,s1
    80004232:	ffffe097          	auipc	ra,0xffffe
    80004236:	224080e7          	jalr	548(ra) # 80002456 <wakeup>
    release(&log.lock);
    8000423a:	8526                	mv	a0,s1
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	ae8080e7          	jalr	-1304(ra) # 80000d24 <release>
}
    80004244:	a03d                	j	80004272 <end_op+0xaa>
    panic("log.committing");
    80004246:	00004517          	auipc	a0,0x4
    8000424a:	3c250513          	addi	a0,a0,962 # 80008608 <syscalls+0x1e0>
    8000424e:	ffffc097          	auipc	ra,0xffffc
    80004252:	2f4080e7          	jalr	756(ra) # 80000542 <panic>
    wakeup(&log);
    80004256:	0023d497          	auipc	s1,0x23d
    8000425a:	6b248493          	addi	s1,s1,1714 # 80241908 <log>
    8000425e:	8526                	mv	a0,s1
    80004260:	ffffe097          	auipc	ra,0xffffe
    80004264:	1f6080e7          	jalr	502(ra) # 80002456 <wakeup>
  release(&log.lock);
    80004268:	8526                	mv	a0,s1
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	aba080e7          	jalr	-1350(ra) # 80000d24 <release>
}
    80004272:	70e2                	ld	ra,56(sp)
    80004274:	7442                	ld	s0,48(sp)
    80004276:	74a2                	ld	s1,40(sp)
    80004278:	7902                	ld	s2,32(sp)
    8000427a:	69e2                	ld	s3,24(sp)
    8000427c:	6a42                	ld	s4,16(sp)
    8000427e:	6aa2                	ld	s5,8(sp)
    80004280:	6121                	addi	sp,sp,64
    80004282:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004284:	0023da97          	auipc	s5,0x23d
    80004288:	6b4a8a93          	addi	s5,s5,1716 # 80241938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000428c:	0023da17          	auipc	s4,0x23d
    80004290:	67ca0a13          	addi	s4,s4,1660 # 80241908 <log>
    80004294:	018a2583          	lw	a1,24(s4)
    80004298:	012585bb          	addw	a1,a1,s2
    8000429c:	2585                	addiw	a1,a1,1
    8000429e:	028a2503          	lw	a0,40(s4)
    800042a2:	fffff097          	auipc	ra,0xfffff
    800042a6:	ce4080e7          	jalr	-796(ra) # 80002f86 <bread>
    800042aa:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ac:	000aa583          	lw	a1,0(s5)
    800042b0:	028a2503          	lw	a0,40(s4)
    800042b4:	fffff097          	auipc	ra,0xfffff
    800042b8:	cd2080e7          	jalr	-814(ra) # 80002f86 <bread>
    800042bc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042be:	40000613          	li	a2,1024
    800042c2:	05850593          	addi	a1,a0,88
    800042c6:	05848513          	addi	a0,s1,88
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	afe080e7          	jalr	-1282(ra) # 80000dc8 <memmove>
    bwrite(to);  // write the log
    800042d2:	8526                	mv	a0,s1
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	da4080e7          	jalr	-604(ra) # 80003078 <bwrite>
    brelse(from);
    800042dc:	854e                	mv	a0,s3
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	dd8080e7          	jalr	-552(ra) # 800030b6 <brelse>
    brelse(to);
    800042e6:	8526                	mv	a0,s1
    800042e8:	fffff097          	auipc	ra,0xfffff
    800042ec:	dce080e7          	jalr	-562(ra) # 800030b6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f0:	2905                	addiw	s2,s2,1
    800042f2:	0a91                	addi	s5,s5,4
    800042f4:	02ca2783          	lw	a5,44(s4)
    800042f8:	f8f94ee3          	blt	s2,a5,80004294 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042fc:	00000097          	auipc	ra,0x0
    80004300:	c7a080e7          	jalr	-902(ra) # 80003f76 <write_head>
    install_trans(); // Now install writes to home locations
    80004304:	00000097          	auipc	ra,0x0
    80004308:	cec080e7          	jalr	-788(ra) # 80003ff0 <install_trans>
    log.lh.n = 0;
    8000430c:	0023d797          	auipc	a5,0x23d
    80004310:	6207a423          	sw	zero,1576(a5) # 80241934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004314:	00000097          	auipc	ra,0x0
    80004318:	c62080e7          	jalr	-926(ra) # 80003f76 <write_head>
    8000431c:	bdfd                	j	8000421a <end_op+0x52>

000000008000431e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000431e:	1101                	addi	sp,sp,-32
    80004320:	ec06                	sd	ra,24(sp)
    80004322:	e822                	sd	s0,16(sp)
    80004324:	e426                	sd	s1,8(sp)
    80004326:	e04a                	sd	s2,0(sp)
    80004328:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000432a:	0023d717          	auipc	a4,0x23d
    8000432e:	60a72703          	lw	a4,1546(a4) # 80241934 <log+0x2c>
    80004332:	47f5                	li	a5,29
    80004334:	08e7c063          	blt	a5,a4,800043b4 <log_write+0x96>
    80004338:	84aa                	mv	s1,a0
    8000433a:	0023d797          	auipc	a5,0x23d
    8000433e:	5ea7a783          	lw	a5,1514(a5) # 80241924 <log+0x1c>
    80004342:	37fd                	addiw	a5,a5,-1
    80004344:	06f75863          	bge	a4,a5,800043b4 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004348:	0023d797          	auipc	a5,0x23d
    8000434c:	5e07a783          	lw	a5,1504(a5) # 80241928 <log+0x20>
    80004350:	06f05a63          	blez	a5,800043c4 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004354:	0023d917          	auipc	s2,0x23d
    80004358:	5b490913          	addi	s2,s2,1460 # 80241908 <log>
    8000435c:	854a                	mv	a0,s2
    8000435e:	ffffd097          	auipc	ra,0xffffd
    80004362:	912080e7          	jalr	-1774(ra) # 80000c70 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004366:	02c92603          	lw	a2,44(s2)
    8000436a:	06c05563          	blez	a2,800043d4 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000436e:	44cc                	lw	a1,12(s1)
    80004370:	0023d717          	auipc	a4,0x23d
    80004374:	5c870713          	addi	a4,a4,1480 # 80241938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004378:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000437a:	4314                	lw	a3,0(a4)
    8000437c:	04b68d63          	beq	a3,a1,800043d6 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004380:	2785                	addiw	a5,a5,1
    80004382:	0711                	addi	a4,a4,4
    80004384:	fec79be3          	bne	a5,a2,8000437a <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004388:	0621                	addi	a2,a2,8
    8000438a:	060a                	slli	a2,a2,0x2
    8000438c:	0023d797          	auipc	a5,0x23d
    80004390:	57c78793          	addi	a5,a5,1404 # 80241908 <log>
    80004394:	963e                	add	a2,a2,a5
    80004396:	44dc                	lw	a5,12(s1)
    80004398:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000439a:	8526                	mv	a0,s1
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	db8080e7          	jalr	-584(ra) # 80003154 <bpin>
    log.lh.n++;
    800043a4:	0023d717          	auipc	a4,0x23d
    800043a8:	56470713          	addi	a4,a4,1380 # 80241908 <log>
    800043ac:	575c                	lw	a5,44(a4)
    800043ae:	2785                	addiw	a5,a5,1
    800043b0:	d75c                	sw	a5,44(a4)
    800043b2:	a83d                	j	800043f0 <log_write+0xd2>
    panic("too big a transaction");
    800043b4:	00004517          	auipc	a0,0x4
    800043b8:	26450513          	addi	a0,a0,612 # 80008618 <syscalls+0x1f0>
    800043bc:	ffffc097          	auipc	ra,0xffffc
    800043c0:	186080e7          	jalr	390(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    800043c4:	00004517          	auipc	a0,0x4
    800043c8:	26c50513          	addi	a0,a0,620 # 80008630 <syscalls+0x208>
    800043cc:	ffffc097          	auipc	ra,0xffffc
    800043d0:	176080e7          	jalr	374(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800043d4:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800043d6:	00878713          	addi	a4,a5,8
    800043da:	00271693          	slli	a3,a4,0x2
    800043de:	0023d717          	auipc	a4,0x23d
    800043e2:	52a70713          	addi	a4,a4,1322 # 80241908 <log>
    800043e6:	9736                	add	a4,a4,a3
    800043e8:	44d4                	lw	a3,12(s1)
    800043ea:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043ec:	faf607e3          	beq	a2,a5,8000439a <log_write+0x7c>
  }
  release(&log.lock);
    800043f0:	0023d517          	auipc	a0,0x23d
    800043f4:	51850513          	addi	a0,a0,1304 # 80241908 <log>
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	92c080e7          	jalr	-1748(ra) # 80000d24 <release>
}
    80004400:	60e2                	ld	ra,24(sp)
    80004402:	6442                	ld	s0,16(sp)
    80004404:	64a2                	ld	s1,8(sp)
    80004406:	6902                	ld	s2,0(sp)
    80004408:	6105                	addi	sp,sp,32
    8000440a:	8082                	ret

000000008000440c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000440c:	1101                	addi	sp,sp,-32
    8000440e:	ec06                	sd	ra,24(sp)
    80004410:	e822                	sd	s0,16(sp)
    80004412:	e426                	sd	s1,8(sp)
    80004414:	e04a                	sd	s2,0(sp)
    80004416:	1000                	addi	s0,sp,32
    80004418:	84aa                	mv	s1,a0
    8000441a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000441c:	00004597          	auipc	a1,0x4
    80004420:	23458593          	addi	a1,a1,564 # 80008650 <syscalls+0x228>
    80004424:	0521                	addi	a0,a0,8
    80004426:	ffffc097          	auipc	ra,0xffffc
    8000442a:	7ba080e7          	jalr	1978(ra) # 80000be0 <initlock>
  lk->name = name;
    8000442e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004432:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004436:	0204a423          	sw	zero,40(s1)
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
    80004452:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004454:	00850913          	addi	s2,a0,8
    80004458:	854a                	mv	a0,s2
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	816080e7          	jalr	-2026(ra) # 80000c70 <acquire>
  while (lk->locked) {
    80004462:	409c                	lw	a5,0(s1)
    80004464:	cb89                	beqz	a5,80004476 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004466:	85ca                	mv	a1,s2
    80004468:	8526                	mv	a0,s1
    8000446a:	ffffe097          	auipc	ra,0xffffe
    8000446e:	e6c080e7          	jalr	-404(ra) # 800022d6 <sleep>
  while (lk->locked) {
    80004472:	409c                	lw	a5,0(s1)
    80004474:	fbed                	bnez	a5,80004466 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004476:	4785                	li	a5,1
    80004478:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	648080e7          	jalr	1608(ra) # 80001ac2 <myproc>
    80004482:	5d1c                	lw	a5,56(a0)
    80004484:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004486:	854a                	mv	a0,s2
    80004488:	ffffd097          	auipc	ra,0xffffd
    8000448c:	89c080e7          	jalr	-1892(ra) # 80000d24 <release>
}
    80004490:	60e2                	ld	ra,24(sp)
    80004492:	6442                	ld	s0,16(sp)
    80004494:	64a2                	ld	s1,8(sp)
    80004496:	6902                	ld	s2,0(sp)
    80004498:	6105                	addi	sp,sp,32
    8000449a:	8082                	ret

000000008000449c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000449c:	1101                	addi	sp,sp,-32
    8000449e:	ec06                	sd	ra,24(sp)
    800044a0:	e822                	sd	s0,16(sp)
    800044a2:	e426                	sd	s1,8(sp)
    800044a4:	e04a                	sd	s2,0(sp)
    800044a6:	1000                	addi	s0,sp,32
    800044a8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044aa:	00850913          	addi	s2,a0,8
    800044ae:	854a                	mv	a0,s2
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	7c0080e7          	jalr	1984(ra) # 80000c70 <acquire>
  lk->locked = 0;
    800044b8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044bc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044c0:	8526                	mv	a0,s1
    800044c2:	ffffe097          	auipc	ra,0xffffe
    800044c6:	f94080e7          	jalr	-108(ra) # 80002456 <wakeup>
  release(&lk->lk);
    800044ca:	854a                	mv	a0,s2
    800044cc:	ffffd097          	auipc	ra,0xffffd
    800044d0:	858080e7          	jalr	-1960(ra) # 80000d24 <release>
}
    800044d4:	60e2                	ld	ra,24(sp)
    800044d6:	6442                	ld	s0,16(sp)
    800044d8:	64a2                	ld	s1,8(sp)
    800044da:	6902                	ld	s2,0(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret

00000000800044e0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044e0:	7179                	addi	sp,sp,-48
    800044e2:	f406                	sd	ra,40(sp)
    800044e4:	f022                	sd	s0,32(sp)
    800044e6:	ec26                	sd	s1,24(sp)
    800044e8:	e84a                	sd	s2,16(sp)
    800044ea:	e44e                	sd	s3,8(sp)
    800044ec:	1800                	addi	s0,sp,48
    800044ee:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044f0:	00850913          	addi	s2,a0,8
    800044f4:	854a                	mv	a0,s2
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	77a080e7          	jalr	1914(ra) # 80000c70 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044fe:	409c                	lw	a5,0(s1)
    80004500:	ef99                	bnez	a5,8000451e <holdingsleep+0x3e>
    80004502:	4481                	li	s1,0
  release(&lk->lk);
    80004504:	854a                	mv	a0,s2
    80004506:	ffffd097          	auipc	ra,0xffffd
    8000450a:	81e080e7          	jalr	-2018(ra) # 80000d24 <release>
  return r;
}
    8000450e:	8526                	mv	a0,s1
    80004510:	70a2                	ld	ra,40(sp)
    80004512:	7402                	ld	s0,32(sp)
    80004514:	64e2                	ld	s1,24(sp)
    80004516:	6942                	ld	s2,16(sp)
    80004518:	69a2                	ld	s3,8(sp)
    8000451a:	6145                	addi	sp,sp,48
    8000451c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000451e:	0284a983          	lw	s3,40(s1)
    80004522:	ffffd097          	auipc	ra,0xffffd
    80004526:	5a0080e7          	jalr	1440(ra) # 80001ac2 <myproc>
    8000452a:	5d04                	lw	s1,56(a0)
    8000452c:	413484b3          	sub	s1,s1,s3
    80004530:	0014b493          	seqz	s1,s1
    80004534:	bfc1                	j	80004504 <holdingsleep+0x24>

0000000080004536 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004536:	1141                	addi	sp,sp,-16
    80004538:	e406                	sd	ra,8(sp)
    8000453a:	e022                	sd	s0,0(sp)
    8000453c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000453e:	00004597          	auipc	a1,0x4
    80004542:	12258593          	addi	a1,a1,290 # 80008660 <syscalls+0x238>
    80004546:	0023d517          	auipc	a0,0x23d
    8000454a:	50a50513          	addi	a0,a0,1290 # 80241a50 <ftable>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	692080e7          	jalr	1682(ra) # 80000be0 <initlock>
}
    80004556:	60a2                	ld	ra,8(sp)
    80004558:	6402                	ld	s0,0(sp)
    8000455a:	0141                	addi	sp,sp,16
    8000455c:	8082                	ret

000000008000455e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000455e:	1101                	addi	sp,sp,-32
    80004560:	ec06                	sd	ra,24(sp)
    80004562:	e822                	sd	s0,16(sp)
    80004564:	e426                	sd	s1,8(sp)
    80004566:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004568:	0023d517          	auipc	a0,0x23d
    8000456c:	4e850513          	addi	a0,a0,1256 # 80241a50 <ftable>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	700080e7          	jalr	1792(ra) # 80000c70 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004578:	0023d497          	auipc	s1,0x23d
    8000457c:	4f048493          	addi	s1,s1,1264 # 80241a68 <ftable+0x18>
    80004580:	0023e717          	auipc	a4,0x23e
    80004584:	48870713          	addi	a4,a4,1160 # 80242a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004588:	40dc                	lw	a5,4(s1)
    8000458a:	cf99                	beqz	a5,800045a8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000458c:	02848493          	addi	s1,s1,40
    80004590:	fee49ce3          	bne	s1,a4,80004588 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004594:	0023d517          	auipc	a0,0x23d
    80004598:	4bc50513          	addi	a0,a0,1212 # 80241a50 <ftable>
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	788080e7          	jalr	1928(ra) # 80000d24 <release>
  return 0;
    800045a4:	4481                	li	s1,0
    800045a6:	a819                	j	800045bc <filealloc+0x5e>
      f->ref = 1;
    800045a8:	4785                	li	a5,1
    800045aa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ac:	0023d517          	auipc	a0,0x23d
    800045b0:	4a450513          	addi	a0,a0,1188 # 80241a50 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	770080e7          	jalr	1904(ra) # 80000d24 <release>
}
    800045bc:	8526                	mv	a0,s1
    800045be:	60e2                	ld	ra,24(sp)
    800045c0:	6442                	ld	s0,16(sp)
    800045c2:	64a2                	ld	s1,8(sp)
    800045c4:	6105                	addi	sp,sp,32
    800045c6:	8082                	ret

00000000800045c8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045c8:	1101                	addi	sp,sp,-32
    800045ca:	ec06                	sd	ra,24(sp)
    800045cc:	e822                	sd	s0,16(sp)
    800045ce:	e426                	sd	s1,8(sp)
    800045d0:	1000                	addi	s0,sp,32
    800045d2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045d4:	0023d517          	auipc	a0,0x23d
    800045d8:	47c50513          	addi	a0,a0,1148 # 80241a50 <ftable>
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	694080e7          	jalr	1684(ra) # 80000c70 <acquire>
  if(f->ref < 1)
    800045e4:	40dc                	lw	a5,4(s1)
    800045e6:	02f05263          	blez	a5,8000460a <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045ea:	2785                	addiw	a5,a5,1
    800045ec:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045ee:	0023d517          	auipc	a0,0x23d
    800045f2:	46250513          	addi	a0,a0,1122 # 80241a50 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	72e080e7          	jalr	1838(ra) # 80000d24 <release>
  return f;
}
    800045fe:	8526                	mv	a0,s1
    80004600:	60e2                	ld	ra,24(sp)
    80004602:	6442                	ld	s0,16(sp)
    80004604:	64a2                	ld	s1,8(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret
    panic("filedup");
    8000460a:	00004517          	auipc	a0,0x4
    8000460e:	05e50513          	addi	a0,a0,94 # 80008668 <syscalls+0x240>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	f30080e7          	jalr	-208(ra) # 80000542 <panic>

000000008000461a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000461a:	7139                	addi	sp,sp,-64
    8000461c:	fc06                	sd	ra,56(sp)
    8000461e:	f822                	sd	s0,48(sp)
    80004620:	f426                	sd	s1,40(sp)
    80004622:	f04a                	sd	s2,32(sp)
    80004624:	ec4e                	sd	s3,24(sp)
    80004626:	e852                	sd	s4,16(sp)
    80004628:	e456                	sd	s5,8(sp)
    8000462a:	0080                	addi	s0,sp,64
    8000462c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000462e:	0023d517          	auipc	a0,0x23d
    80004632:	42250513          	addi	a0,a0,1058 # 80241a50 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	63a080e7          	jalr	1594(ra) # 80000c70 <acquire>
  if(f->ref < 1)
    8000463e:	40dc                	lw	a5,4(s1)
    80004640:	06f05163          	blez	a5,800046a2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004644:	37fd                	addiw	a5,a5,-1
    80004646:	0007871b          	sext.w	a4,a5
    8000464a:	c0dc                	sw	a5,4(s1)
    8000464c:	06e04363          	bgtz	a4,800046b2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004650:	0004a903          	lw	s2,0(s1)
    80004654:	0094ca83          	lbu	s5,9(s1)
    80004658:	0104ba03          	ld	s4,16(s1)
    8000465c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004660:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004664:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004668:	0023d517          	auipc	a0,0x23d
    8000466c:	3e850513          	addi	a0,a0,1000 # 80241a50 <ftable>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	6b4080e7          	jalr	1716(ra) # 80000d24 <release>

  if(ff.type == FD_PIPE){
    80004678:	4785                	li	a5,1
    8000467a:	04f90d63          	beq	s2,a5,800046d4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000467e:	3979                	addiw	s2,s2,-2
    80004680:	4785                	li	a5,1
    80004682:	0527e063          	bltu	a5,s2,800046c2 <fileclose+0xa8>
    begin_op();
    80004686:	00000097          	auipc	ra,0x0
    8000468a:	ac2080e7          	jalr	-1342(ra) # 80004148 <begin_op>
    iput(ff.ip);
    8000468e:	854e                	mv	a0,s3
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	2b2080e7          	jalr	690(ra) # 80003942 <iput>
    end_op();
    80004698:	00000097          	auipc	ra,0x0
    8000469c:	b30080e7          	jalr	-1232(ra) # 800041c8 <end_op>
    800046a0:	a00d                	j	800046c2 <fileclose+0xa8>
    panic("fileclose");
    800046a2:	00004517          	auipc	a0,0x4
    800046a6:	fce50513          	addi	a0,a0,-50 # 80008670 <syscalls+0x248>
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	e98080e7          	jalr	-360(ra) # 80000542 <panic>
    release(&ftable.lock);
    800046b2:	0023d517          	auipc	a0,0x23d
    800046b6:	39e50513          	addi	a0,a0,926 # 80241a50 <ftable>
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	66a080e7          	jalr	1642(ra) # 80000d24 <release>
  }
}
    800046c2:	70e2                	ld	ra,56(sp)
    800046c4:	7442                	ld	s0,48(sp)
    800046c6:	74a2                	ld	s1,40(sp)
    800046c8:	7902                	ld	s2,32(sp)
    800046ca:	69e2                	ld	s3,24(sp)
    800046cc:	6a42                	ld	s4,16(sp)
    800046ce:	6aa2                	ld	s5,8(sp)
    800046d0:	6121                	addi	sp,sp,64
    800046d2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046d4:	85d6                	mv	a1,s5
    800046d6:	8552                	mv	a0,s4
    800046d8:	00000097          	auipc	ra,0x0
    800046dc:	372080e7          	jalr	882(ra) # 80004a4a <pipeclose>
    800046e0:	b7cd                	j	800046c2 <fileclose+0xa8>

00000000800046e2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046e2:	715d                	addi	sp,sp,-80
    800046e4:	e486                	sd	ra,72(sp)
    800046e6:	e0a2                	sd	s0,64(sp)
    800046e8:	fc26                	sd	s1,56(sp)
    800046ea:	f84a                	sd	s2,48(sp)
    800046ec:	f44e                	sd	s3,40(sp)
    800046ee:	0880                	addi	s0,sp,80
    800046f0:	84aa                	mv	s1,a0
    800046f2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046f4:	ffffd097          	auipc	ra,0xffffd
    800046f8:	3ce080e7          	jalr	974(ra) # 80001ac2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046fc:	409c                	lw	a5,0(s1)
    800046fe:	37f9                	addiw	a5,a5,-2
    80004700:	4705                	li	a4,1
    80004702:	04f76763          	bltu	a4,a5,80004750 <filestat+0x6e>
    80004706:	892a                	mv	s2,a0
    ilock(f->ip);
    80004708:	6c88                	ld	a0,24(s1)
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	07e080e7          	jalr	126(ra) # 80003788 <ilock>
    stati(f->ip, &st);
    80004712:	fb840593          	addi	a1,s0,-72
    80004716:	6c88                	ld	a0,24(s1)
    80004718:	fffff097          	auipc	ra,0xfffff
    8000471c:	2fa080e7          	jalr	762(ra) # 80003a12 <stati>
    iunlock(f->ip);
    80004720:	6c88                	ld	a0,24(s1)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	128080e7          	jalr	296(ra) # 8000384a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000472a:	46e1                	li	a3,24
    8000472c:	fb840613          	addi	a2,s0,-72
    80004730:	85ce                	mv	a1,s3
    80004732:	05093503          	ld	a0,80(s2)
    80004736:	ffffd097          	auipc	ra,0xffffd
    8000473a:	ff0080e7          	jalr	-16(ra) # 80001726 <copyout>
    8000473e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004742:	60a6                	ld	ra,72(sp)
    80004744:	6406                	ld	s0,64(sp)
    80004746:	74e2                	ld	s1,56(sp)
    80004748:	7942                	ld	s2,48(sp)
    8000474a:	79a2                	ld	s3,40(sp)
    8000474c:	6161                	addi	sp,sp,80
    8000474e:	8082                	ret
  return -1;
    80004750:	557d                	li	a0,-1
    80004752:	bfc5                	j	80004742 <filestat+0x60>

0000000080004754 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004754:	7179                	addi	sp,sp,-48
    80004756:	f406                	sd	ra,40(sp)
    80004758:	f022                	sd	s0,32(sp)
    8000475a:	ec26                	sd	s1,24(sp)
    8000475c:	e84a                	sd	s2,16(sp)
    8000475e:	e44e                	sd	s3,8(sp)
    80004760:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004762:	00854783          	lbu	a5,8(a0)
    80004766:	c3d5                	beqz	a5,8000480a <fileread+0xb6>
    80004768:	84aa                	mv	s1,a0
    8000476a:	89ae                	mv	s3,a1
    8000476c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000476e:	411c                	lw	a5,0(a0)
    80004770:	4705                	li	a4,1
    80004772:	04e78963          	beq	a5,a4,800047c4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004776:	470d                	li	a4,3
    80004778:	04e78d63          	beq	a5,a4,800047d2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000477c:	4709                	li	a4,2
    8000477e:	06e79e63          	bne	a5,a4,800047fa <fileread+0xa6>
    ilock(f->ip);
    80004782:	6d08                	ld	a0,24(a0)
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	004080e7          	jalr	4(ra) # 80003788 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000478c:	874a                	mv	a4,s2
    8000478e:	5094                	lw	a3,32(s1)
    80004790:	864e                	mv	a2,s3
    80004792:	4585                	li	a1,1
    80004794:	6c88                	ld	a0,24(s1)
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	2a6080e7          	jalr	678(ra) # 80003a3c <readi>
    8000479e:	892a                	mv	s2,a0
    800047a0:	00a05563          	blez	a0,800047aa <fileread+0x56>
      f->off += r;
    800047a4:	509c                	lw	a5,32(s1)
    800047a6:	9fa9                	addw	a5,a5,a0
    800047a8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047aa:	6c88                	ld	a0,24(s1)
    800047ac:	fffff097          	auipc	ra,0xfffff
    800047b0:	09e080e7          	jalr	158(ra) # 8000384a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047b4:	854a                	mv	a0,s2
    800047b6:	70a2                	ld	ra,40(sp)
    800047b8:	7402                	ld	s0,32(sp)
    800047ba:	64e2                	ld	s1,24(sp)
    800047bc:	6942                	ld	s2,16(sp)
    800047be:	69a2                	ld	s3,8(sp)
    800047c0:	6145                	addi	sp,sp,48
    800047c2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047c4:	6908                	ld	a0,16(a0)
    800047c6:	00000097          	auipc	ra,0x0
    800047ca:	3f4080e7          	jalr	1012(ra) # 80004bba <piperead>
    800047ce:	892a                	mv	s2,a0
    800047d0:	b7d5                	j	800047b4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047d2:	02451783          	lh	a5,36(a0)
    800047d6:	03079693          	slli	a3,a5,0x30
    800047da:	92c1                	srli	a3,a3,0x30
    800047dc:	4725                	li	a4,9
    800047de:	02d76863          	bltu	a4,a3,8000480e <fileread+0xba>
    800047e2:	0792                	slli	a5,a5,0x4
    800047e4:	0023d717          	auipc	a4,0x23d
    800047e8:	1cc70713          	addi	a4,a4,460 # 802419b0 <devsw>
    800047ec:	97ba                	add	a5,a5,a4
    800047ee:	639c                	ld	a5,0(a5)
    800047f0:	c38d                	beqz	a5,80004812 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047f2:	4505                	li	a0,1
    800047f4:	9782                	jalr	a5
    800047f6:	892a                	mv	s2,a0
    800047f8:	bf75                	j	800047b4 <fileread+0x60>
    panic("fileread");
    800047fa:	00004517          	auipc	a0,0x4
    800047fe:	e8650513          	addi	a0,a0,-378 # 80008680 <syscalls+0x258>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	d40080e7          	jalr	-704(ra) # 80000542 <panic>
    return -1;
    8000480a:	597d                	li	s2,-1
    8000480c:	b765                	j	800047b4 <fileread+0x60>
      return -1;
    8000480e:	597d                	li	s2,-1
    80004810:	b755                	j	800047b4 <fileread+0x60>
    80004812:	597d                	li	s2,-1
    80004814:	b745                	j	800047b4 <fileread+0x60>

0000000080004816 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004816:	00954783          	lbu	a5,9(a0)
    8000481a:	14078563          	beqz	a5,80004964 <filewrite+0x14e>
{
    8000481e:	715d                	addi	sp,sp,-80
    80004820:	e486                	sd	ra,72(sp)
    80004822:	e0a2                	sd	s0,64(sp)
    80004824:	fc26                	sd	s1,56(sp)
    80004826:	f84a                	sd	s2,48(sp)
    80004828:	f44e                	sd	s3,40(sp)
    8000482a:	f052                	sd	s4,32(sp)
    8000482c:	ec56                	sd	s5,24(sp)
    8000482e:	e85a                	sd	s6,16(sp)
    80004830:	e45e                	sd	s7,8(sp)
    80004832:	e062                	sd	s8,0(sp)
    80004834:	0880                	addi	s0,sp,80
    80004836:	892a                	mv	s2,a0
    80004838:	8aae                	mv	s5,a1
    8000483a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000483c:	411c                	lw	a5,0(a0)
    8000483e:	4705                	li	a4,1
    80004840:	02e78263          	beq	a5,a4,80004864 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004844:	470d                	li	a4,3
    80004846:	02e78563          	beq	a5,a4,80004870 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000484a:	4709                	li	a4,2
    8000484c:	10e79463          	bne	a5,a4,80004954 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004850:	0ec05e63          	blez	a2,8000494c <filewrite+0x136>
    int i = 0;
    80004854:	4981                	li	s3,0
    80004856:	6b05                	lui	s6,0x1
    80004858:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000485c:	6b85                	lui	s7,0x1
    8000485e:	c00b8b9b          	addiw	s7,s7,-1024
    80004862:	a851                	j	800048f6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004864:	6908                	ld	a0,16(a0)
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	254080e7          	jalr	596(ra) # 80004aba <pipewrite>
    8000486e:	a85d                	j	80004924 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004870:	02451783          	lh	a5,36(a0)
    80004874:	03079693          	slli	a3,a5,0x30
    80004878:	92c1                	srli	a3,a3,0x30
    8000487a:	4725                	li	a4,9
    8000487c:	0ed76663          	bltu	a4,a3,80004968 <filewrite+0x152>
    80004880:	0792                	slli	a5,a5,0x4
    80004882:	0023d717          	auipc	a4,0x23d
    80004886:	12e70713          	addi	a4,a4,302 # 802419b0 <devsw>
    8000488a:	97ba                	add	a5,a5,a4
    8000488c:	679c                	ld	a5,8(a5)
    8000488e:	cff9                	beqz	a5,8000496c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004890:	4505                	li	a0,1
    80004892:	9782                	jalr	a5
    80004894:	a841                	j	80004924 <filewrite+0x10e>
    80004896:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	8ae080e7          	jalr	-1874(ra) # 80004148 <begin_op>
      ilock(f->ip);
    800048a2:	01893503          	ld	a0,24(s2)
    800048a6:	fffff097          	auipc	ra,0xfffff
    800048aa:	ee2080e7          	jalr	-286(ra) # 80003788 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048ae:	8762                	mv	a4,s8
    800048b0:	02092683          	lw	a3,32(s2)
    800048b4:	01598633          	add	a2,s3,s5
    800048b8:	4585                	li	a1,1
    800048ba:	01893503          	ld	a0,24(s2)
    800048be:	fffff097          	auipc	ra,0xfffff
    800048c2:	276080e7          	jalr	630(ra) # 80003b34 <writei>
    800048c6:	84aa                	mv	s1,a0
    800048c8:	02a05f63          	blez	a0,80004906 <filewrite+0xf0>
        f->off += r;
    800048cc:	02092783          	lw	a5,32(s2)
    800048d0:	9fa9                	addw	a5,a5,a0
    800048d2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048d6:	01893503          	ld	a0,24(s2)
    800048da:	fffff097          	auipc	ra,0xfffff
    800048de:	f70080e7          	jalr	-144(ra) # 8000384a <iunlock>
      end_op();
    800048e2:	00000097          	auipc	ra,0x0
    800048e6:	8e6080e7          	jalr	-1818(ra) # 800041c8 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048ea:	049c1963          	bne	s8,s1,8000493c <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048ee:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048f2:	0349d663          	bge	s3,s4,8000491e <filewrite+0x108>
      int n1 = n - i;
    800048f6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048fa:	84be                	mv	s1,a5
    800048fc:	2781                	sext.w	a5,a5
    800048fe:	f8fb5ce3          	bge	s6,a5,80004896 <filewrite+0x80>
    80004902:	84de                	mv	s1,s7
    80004904:	bf49                	j	80004896 <filewrite+0x80>
      iunlock(f->ip);
    80004906:	01893503          	ld	a0,24(s2)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	f40080e7          	jalr	-192(ra) # 8000384a <iunlock>
      end_op();
    80004912:	00000097          	auipc	ra,0x0
    80004916:	8b6080e7          	jalr	-1866(ra) # 800041c8 <end_op>
      if(r < 0)
    8000491a:	fc04d8e3          	bgez	s1,800048ea <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000491e:	8552                	mv	a0,s4
    80004920:	033a1863          	bne	s4,s3,80004950 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004924:	60a6                	ld	ra,72(sp)
    80004926:	6406                	ld	s0,64(sp)
    80004928:	74e2                	ld	s1,56(sp)
    8000492a:	7942                	ld	s2,48(sp)
    8000492c:	79a2                	ld	s3,40(sp)
    8000492e:	7a02                	ld	s4,32(sp)
    80004930:	6ae2                	ld	s5,24(sp)
    80004932:	6b42                	ld	s6,16(sp)
    80004934:	6ba2                	ld	s7,8(sp)
    80004936:	6c02                	ld	s8,0(sp)
    80004938:	6161                	addi	sp,sp,80
    8000493a:	8082                	ret
        panic("short filewrite");
    8000493c:	00004517          	auipc	a0,0x4
    80004940:	d5450513          	addi	a0,a0,-684 # 80008690 <syscalls+0x268>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	bfe080e7          	jalr	-1026(ra) # 80000542 <panic>
    int i = 0;
    8000494c:	4981                	li	s3,0
    8000494e:	bfc1                	j	8000491e <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004950:	557d                	li	a0,-1
    80004952:	bfc9                	j	80004924 <filewrite+0x10e>
    panic("filewrite");
    80004954:	00004517          	auipc	a0,0x4
    80004958:	d4c50513          	addi	a0,a0,-692 # 800086a0 <syscalls+0x278>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	be6080e7          	jalr	-1050(ra) # 80000542 <panic>
    return -1;
    80004964:	557d                	li	a0,-1
}
    80004966:	8082                	ret
      return -1;
    80004968:	557d                	li	a0,-1
    8000496a:	bf6d                	j	80004924 <filewrite+0x10e>
    8000496c:	557d                	li	a0,-1
    8000496e:	bf5d                	j	80004924 <filewrite+0x10e>

0000000080004970 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004970:	7179                	addi	sp,sp,-48
    80004972:	f406                	sd	ra,40(sp)
    80004974:	f022                	sd	s0,32(sp)
    80004976:	ec26                	sd	s1,24(sp)
    80004978:	e84a                	sd	s2,16(sp)
    8000497a:	e44e                	sd	s3,8(sp)
    8000497c:	e052                	sd	s4,0(sp)
    8000497e:	1800                	addi	s0,sp,48
    80004980:	84aa                	mv	s1,a0
    80004982:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004984:	0005b023          	sd	zero,0(a1)
    80004988:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000498c:	00000097          	auipc	ra,0x0
    80004990:	bd2080e7          	jalr	-1070(ra) # 8000455e <filealloc>
    80004994:	e088                	sd	a0,0(s1)
    80004996:	c551                	beqz	a0,80004a22 <pipealloc+0xb2>
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	bc6080e7          	jalr	-1082(ra) # 8000455e <filealloc>
    800049a0:	00aa3023          	sd	a0,0(s4)
    800049a4:	c92d                	beqz	a0,80004a16 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	1a4080e7          	jalr	420(ra) # 80000b4a <kalloc>
    800049ae:	892a                	mv	s2,a0
    800049b0:	c125                	beqz	a0,80004a10 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049b2:	4985                	li	s3,1
    800049b4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049b8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049bc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049c0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c4:	00004597          	auipc	a1,0x4
    800049c8:	cec58593          	addi	a1,a1,-788 # 800086b0 <syscalls+0x288>
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	214080e7          	jalr	532(ra) # 80000be0 <initlock>
  (*f0)->type = FD_PIPE;
    800049d4:	609c                	ld	a5,0(s1)
    800049d6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049da:	609c                	ld	a5,0(s1)
    800049dc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049e0:	609c                	ld	a5,0(s1)
    800049e2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049e6:	609c                	ld	a5,0(s1)
    800049e8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049ec:	000a3783          	ld	a5,0(s4)
    800049f0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049f4:	000a3783          	ld	a5,0(s4)
    800049f8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049fc:	000a3783          	ld	a5,0(s4)
    80004a00:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a04:	000a3783          	ld	a5,0(s4)
    80004a08:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a0c:	4501                	li	a0,0
    80004a0e:	a025                	j	80004a36 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a10:	6088                	ld	a0,0(s1)
    80004a12:	e501                	bnez	a0,80004a1a <pipealloc+0xaa>
    80004a14:	a039                	j	80004a22 <pipealloc+0xb2>
    80004a16:	6088                	ld	a0,0(s1)
    80004a18:	c51d                	beqz	a0,80004a46 <pipealloc+0xd6>
    fileclose(*f0);
    80004a1a:	00000097          	auipc	ra,0x0
    80004a1e:	c00080e7          	jalr	-1024(ra) # 8000461a <fileclose>
  if(*f1)
    80004a22:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a26:	557d                	li	a0,-1
  if(*f1)
    80004a28:	c799                	beqz	a5,80004a36 <pipealloc+0xc6>
    fileclose(*f1);
    80004a2a:	853e                	mv	a0,a5
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	bee080e7          	jalr	-1042(ra) # 8000461a <fileclose>
  return -1;
    80004a34:	557d                	li	a0,-1
}
    80004a36:	70a2                	ld	ra,40(sp)
    80004a38:	7402                	ld	s0,32(sp)
    80004a3a:	64e2                	ld	s1,24(sp)
    80004a3c:	6942                	ld	s2,16(sp)
    80004a3e:	69a2                	ld	s3,8(sp)
    80004a40:	6a02                	ld	s4,0(sp)
    80004a42:	6145                	addi	sp,sp,48
    80004a44:	8082                	ret
  return -1;
    80004a46:	557d                	li	a0,-1
    80004a48:	b7fd                	j	80004a36 <pipealloc+0xc6>

0000000080004a4a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a4a:	1101                	addi	sp,sp,-32
    80004a4c:	ec06                	sd	ra,24(sp)
    80004a4e:	e822                	sd	s0,16(sp)
    80004a50:	e426                	sd	s1,8(sp)
    80004a52:	e04a                	sd	s2,0(sp)
    80004a54:	1000                	addi	s0,sp,32
    80004a56:	84aa                	mv	s1,a0
    80004a58:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	216080e7          	jalr	534(ra) # 80000c70 <acquire>
  if(writable){
    80004a62:	02090d63          	beqz	s2,80004a9c <pipeclose+0x52>
    pi->writeopen = 0;
    80004a66:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a6a:	21848513          	addi	a0,s1,536
    80004a6e:	ffffe097          	auipc	ra,0xffffe
    80004a72:	9e8080e7          	jalr	-1560(ra) # 80002456 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a76:	2204b783          	ld	a5,544(s1)
    80004a7a:	eb95                	bnez	a5,80004aae <pipeclose+0x64>
    release(&pi->lock);
    80004a7c:	8526                	mv	a0,s1
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	2a6080e7          	jalr	678(ra) # 80000d24 <release>
    kfree((char*)pi);
    80004a86:	8526                	mv	a0,s1
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	f8a080e7          	jalr	-118(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004a90:	60e2                	ld	ra,24(sp)
    80004a92:	6442                	ld	s0,16(sp)
    80004a94:	64a2                	ld	s1,8(sp)
    80004a96:	6902                	ld	s2,0(sp)
    80004a98:	6105                	addi	sp,sp,32
    80004a9a:	8082                	ret
    pi->readopen = 0;
    80004a9c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aa0:	21c48513          	addi	a0,s1,540
    80004aa4:	ffffe097          	auipc	ra,0xffffe
    80004aa8:	9b2080e7          	jalr	-1614(ra) # 80002456 <wakeup>
    80004aac:	b7e9                	j	80004a76 <pipeclose+0x2c>
    release(&pi->lock);
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	274080e7          	jalr	628(ra) # 80000d24 <release>
}
    80004ab8:	bfe1                	j	80004a90 <pipeclose+0x46>

0000000080004aba <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aba:	711d                	addi	sp,sp,-96
    80004abc:	ec86                	sd	ra,88(sp)
    80004abe:	e8a2                	sd	s0,80(sp)
    80004ac0:	e4a6                	sd	s1,72(sp)
    80004ac2:	e0ca                	sd	s2,64(sp)
    80004ac4:	fc4e                	sd	s3,56(sp)
    80004ac6:	f852                	sd	s4,48(sp)
    80004ac8:	f456                	sd	s5,40(sp)
    80004aca:	f05a                	sd	s6,32(sp)
    80004acc:	ec5e                	sd	s7,24(sp)
    80004ace:	e862                	sd	s8,16(sp)
    80004ad0:	1080                	addi	s0,sp,96
    80004ad2:	84aa                	mv	s1,a0
    80004ad4:	8b2e                	mv	s6,a1
    80004ad6:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ad8:	ffffd097          	auipc	ra,0xffffd
    80004adc:	fea080e7          	jalr	-22(ra) # 80001ac2 <myproc>
    80004ae0:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ae2:	8526                	mv	a0,s1
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	18c080e7          	jalr	396(ra) # 80000c70 <acquire>
  for(i = 0; i < n; i++){
    80004aec:	09505763          	blez	s5,80004b7a <pipewrite+0xc0>
    80004af0:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004af2:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004af6:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004afa:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004afc:	2184a783          	lw	a5,536(s1)
    80004b00:	21c4a703          	lw	a4,540(s1)
    80004b04:	2007879b          	addiw	a5,a5,512
    80004b08:	02f71b63          	bne	a4,a5,80004b3e <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004b0c:	2204a783          	lw	a5,544(s1)
    80004b10:	c3d1                	beqz	a5,80004b94 <pipewrite+0xda>
    80004b12:	03092783          	lw	a5,48(s2)
    80004b16:	efbd                	bnez	a5,80004b94 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004b18:	8552                	mv	a0,s4
    80004b1a:	ffffe097          	auipc	ra,0xffffe
    80004b1e:	93c080e7          	jalr	-1732(ra) # 80002456 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b22:	85a6                	mv	a1,s1
    80004b24:	854e                	mv	a0,s3
    80004b26:	ffffd097          	auipc	ra,0xffffd
    80004b2a:	7b0080e7          	jalr	1968(ra) # 800022d6 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b2e:	2184a783          	lw	a5,536(s1)
    80004b32:	21c4a703          	lw	a4,540(s1)
    80004b36:	2007879b          	addiw	a5,a5,512
    80004b3a:	fcf709e3          	beq	a4,a5,80004b0c <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b3e:	4685                	li	a3,1
    80004b40:	865a                	mv	a2,s6
    80004b42:	faf40593          	addi	a1,s0,-81
    80004b46:	05093503          	ld	a0,80(s2)
    80004b4a:	ffffd097          	auipc	ra,0xffffd
    80004b4e:	cf6080e7          	jalr	-778(ra) # 80001840 <copyin>
    80004b52:	03850563          	beq	a0,s8,80004b7c <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b56:	21c4a783          	lw	a5,540(s1)
    80004b5a:	0017871b          	addiw	a4,a5,1
    80004b5e:	20e4ae23          	sw	a4,540(s1)
    80004b62:	1ff7f793          	andi	a5,a5,511
    80004b66:	97a6                	add	a5,a5,s1
    80004b68:	faf44703          	lbu	a4,-81(s0)
    80004b6c:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b70:	2b85                	addiw	s7,s7,1
    80004b72:	0b05                	addi	s6,s6,1
    80004b74:	f97a94e3          	bne	s5,s7,80004afc <pipewrite+0x42>
    80004b78:	a011                	j	80004b7c <pipewrite+0xc2>
    80004b7a:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004b7c:	21848513          	addi	a0,s1,536
    80004b80:	ffffe097          	auipc	ra,0xffffe
    80004b84:	8d6080e7          	jalr	-1834(ra) # 80002456 <wakeup>
  release(&pi->lock);
    80004b88:	8526                	mv	a0,s1
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	19a080e7          	jalr	410(ra) # 80000d24 <release>
  return i;
    80004b92:	a039                	j	80004ba0 <pipewrite+0xe6>
        release(&pi->lock);
    80004b94:	8526                	mv	a0,s1
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	18e080e7          	jalr	398(ra) # 80000d24 <release>
        return -1;
    80004b9e:	5bfd                	li	s7,-1
}
    80004ba0:	855e                	mv	a0,s7
    80004ba2:	60e6                	ld	ra,88(sp)
    80004ba4:	6446                	ld	s0,80(sp)
    80004ba6:	64a6                	ld	s1,72(sp)
    80004ba8:	6906                	ld	s2,64(sp)
    80004baa:	79e2                	ld	s3,56(sp)
    80004bac:	7a42                	ld	s4,48(sp)
    80004bae:	7aa2                	ld	s5,40(sp)
    80004bb0:	7b02                	ld	s6,32(sp)
    80004bb2:	6be2                	ld	s7,24(sp)
    80004bb4:	6c42                	ld	s8,16(sp)
    80004bb6:	6125                	addi	sp,sp,96
    80004bb8:	8082                	ret

0000000080004bba <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bba:	715d                	addi	sp,sp,-80
    80004bbc:	e486                	sd	ra,72(sp)
    80004bbe:	e0a2                	sd	s0,64(sp)
    80004bc0:	fc26                	sd	s1,56(sp)
    80004bc2:	f84a                	sd	s2,48(sp)
    80004bc4:	f44e                	sd	s3,40(sp)
    80004bc6:	f052                	sd	s4,32(sp)
    80004bc8:	ec56                	sd	s5,24(sp)
    80004bca:	e85a                	sd	s6,16(sp)
    80004bcc:	0880                	addi	s0,sp,80
    80004bce:	84aa                	mv	s1,a0
    80004bd0:	892e                	mv	s2,a1
    80004bd2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	eee080e7          	jalr	-274(ra) # 80001ac2 <myproc>
    80004bdc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bde:	8526                	mv	a0,s1
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	090080e7          	jalr	144(ra) # 80000c70 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be8:	2184a703          	lw	a4,536(s1)
    80004bec:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf4:	02f71463          	bne	a4,a5,80004c1c <piperead+0x62>
    80004bf8:	2244a783          	lw	a5,548(s1)
    80004bfc:	c385                	beqz	a5,80004c1c <piperead+0x62>
    if(pr->killed){
    80004bfe:	030a2783          	lw	a5,48(s4)
    80004c02:	ebc1                	bnez	a5,80004c92 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c04:	85a6                	mv	a1,s1
    80004c06:	854e                	mv	a0,s3
    80004c08:	ffffd097          	auipc	ra,0xffffd
    80004c0c:	6ce080e7          	jalr	1742(ra) # 800022d6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c10:	2184a703          	lw	a4,536(s1)
    80004c14:	21c4a783          	lw	a5,540(s1)
    80004c18:	fef700e3          	beq	a4,a5,80004bf8 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c1c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c1e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c20:	05505363          	blez	s5,80004c66 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004c24:	2184a783          	lw	a5,536(s1)
    80004c28:	21c4a703          	lw	a4,540(s1)
    80004c2c:	02f70d63          	beq	a4,a5,80004c66 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c30:	0017871b          	addiw	a4,a5,1
    80004c34:	20e4ac23          	sw	a4,536(s1)
    80004c38:	1ff7f793          	andi	a5,a5,511
    80004c3c:	97a6                	add	a5,a5,s1
    80004c3e:	0187c783          	lbu	a5,24(a5)
    80004c42:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c46:	4685                	li	a3,1
    80004c48:	fbf40613          	addi	a2,s0,-65
    80004c4c:	85ca                	mv	a1,s2
    80004c4e:	050a3503          	ld	a0,80(s4)
    80004c52:	ffffd097          	auipc	ra,0xffffd
    80004c56:	ad4080e7          	jalr	-1324(ra) # 80001726 <copyout>
    80004c5a:	01650663          	beq	a0,s6,80004c66 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c5e:	2985                	addiw	s3,s3,1
    80004c60:	0905                	addi	s2,s2,1
    80004c62:	fd3a91e3          	bne	s5,s3,80004c24 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c66:	21c48513          	addi	a0,s1,540
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	7ec080e7          	jalr	2028(ra) # 80002456 <wakeup>
  release(&pi->lock);
    80004c72:	8526                	mv	a0,s1
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	0b0080e7          	jalr	176(ra) # 80000d24 <release>
  return i;
}
    80004c7c:	854e                	mv	a0,s3
    80004c7e:	60a6                	ld	ra,72(sp)
    80004c80:	6406                	ld	s0,64(sp)
    80004c82:	74e2                	ld	s1,56(sp)
    80004c84:	7942                	ld	s2,48(sp)
    80004c86:	79a2                	ld	s3,40(sp)
    80004c88:	7a02                	ld	s4,32(sp)
    80004c8a:	6ae2                	ld	s5,24(sp)
    80004c8c:	6b42                	ld	s6,16(sp)
    80004c8e:	6161                	addi	sp,sp,80
    80004c90:	8082                	ret
      release(&pi->lock);
    80004c92:	8526                	mv	a0,s1
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	090080e7          	jalr	144(ra) # 80000d24 <release>
      return -1;
    80004c9c:	59fd                	li	s3,-1
    80004c9e:	bff9                	j	80004c7c <piperead+0xc2>

0000000080004ca0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ca0:	de010113          	addi	sp,sp,-544
    80004ca4:	20113c23          	sd	ra,536(sp)
    80004ca8:	20813823          	sd	s0,528(sp)
    80004cac:	20913423          	sd	s1,520(sp)
    80004cb0:	21213023          	sd	s2,512(sp)
    80004cb4:	ffce                	sd	s3,504(sp)
    80004cb6:	fbd2                	sd	s4,496(sp)
    80004cb8:	f7d6                	sd	s5,488(sp)
    80004cba:	f3da                	sd	s6,480(sp)
    80004cbc:	efde                	sd	s7,472(sp)
    80004cbe:	ebe2                	sd	s8,464(sp)
    80004cc0:	e7e6                	sd	s9,456(sp)
    80004cc2:	e3ea                	sd	s10,448(sp)
    80004cc4:	ff6e                	sd	s11,440(sp)
    80004cc6:	1400                	addi	s0,sp,544
    80004cc8:	892a                	mv	s2,a0
    80004cca:	dea43423          	sd	a0,-536(s0)
    80004cce:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	df0080e7          	jalr	-528(ra) # 80001ac2 <myproc>
    80004cda:	84aa                	mv	s1,a0

  begin_op();
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	46c080e7          	jalr	1132(ra) # 80004148 <begin_op>

  if((ip = namei(path)) == 0){
    80004ce4:	854a                	mv	a0,s2
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	256080e7          	jalr	598(ra) # 80003f3c <namei>
    80004cee:	c93d                	beqz	a0,80004d64 <exec+0xc4>
    80004cf0:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	a96080e7          	jalr	-1386(ra) # 80003788 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cfa:	04000713          	li	a4,64
    80004cfe:	4681                	li	a3,0
    80004d00:	e4840613          	addi	a2,s0,-440
    80004d04:	4581                	li	a1,0
    80004d06:	8556                	mv	a0,s5
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	d34080e7          	jalr	-716(ra) # 80003a3c <readi>
    80004d10:	04000793          	li	a5,64
    80004d14:	00f51a63          	bne	a0,a5,80004d28 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d18:	e4842703          	lw	a4,-440(s0)
    80004d1c:	464c47b7          	lui	a5,0x464c4
    80004d20:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d24:	04f70663          	beq	a4,a5,80004d70 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d28:	8556                	mv	a0,s5
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	cc0080e7          	jalr	-832(ra) # 800039ea <iunlockput>
    end_op();
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	496080e7          	jalr	1174(ra) # 800041c8 <end_op>
  }
  return -1;
    80004d3a:	557d                	li	a0,-1
}
    80004d3c:	21813083          	ld	ra,536(sp)
    80004d40:	21013403          	ld	s0,528(sp)
    80004d44:	20813483          	ld	s1,520(sp)
    80004d48:	20013903          	ld	s2,512(sp)
    80004d4c:	79fe                	ld	s3,504(sp)
    80004d4e:	7a5e                	ld	s4,496(sp)
    80004d50:	7abe                	ld	s5,488(sp)
    80004d52:	7b1e                	ld	s6,480(sp)
    80004d54:	6bfe                	ld	s7,472(sp)
    80004d56:	6c5e                	ld	s8,464(sp)
    80004d58:	6cbe                	ld	s9,456(sp)
    80004d5a:	6d1e                	ld	s10,448(sp)
    80004d5c:	7dfa                	ld	s11,440(sp)
    80004d5e:	22010113          	addi	sp,sp,544
    80004d62:	8082                	ret
    end_op();
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	464080e7          	jalr	1124(ra) # 800041c8 <end_op>
    return -1;
    80004d6c:	557d                	li	a0,-1
    80004d6e:	b7f9                	j	80004d3c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d70:	8526                	mv	a0,s1
    80004d72:	ffffd097          	auipc	ra,0xffffd
    80004d76:	e14080e7          	jalr	-492(ra) # 80001b86 <proc_pagetable>
    80004d7a:	8b2a                	mv	s6,a0
    80004d7c:	d555                	beqz	a0,80004d28 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d7e:	e6842783          	lw	a5,-408(s0)
    80004d82:	e8045703          	lhu	a4,-384(s0)
    80004d86:	c735                	beqz	a4,80004df2 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d88:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d8a:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d8e:	6a05                	lui	s4,0x1
    80004d90:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d94:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004d98:	6d85                	lui	s11,0x1
    80004d9a:	7d7d                	lui	s10,0xfffff
    80004d9c:	ac1d                	j	80004fd2 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d9e:	00004517          	auipc	a0,0x4
    80004da2:	91a50513          	addi	a0,a0,-1766 # 800086b8 <syscalls+0x290>
    80004da6:	ffffb097          	auipc	ra,0xffffb
    80004daa:	79c080e7          	jalr	1948(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dae:	874a                	mv	a4,s2
    80004db0:	009c86bb          	addw	a3,s9,s1
    80004db4:	4581                	li	a1,0
    80004db6:	8556                	mv	a0,s5
    80004db8:	fffff097          	auipc	ra,0xfffff
    80004dbc:	c84080e7          	jalr	-892(ra) # 80003a3c <readi>
    80004dc0:	2501                	sext.w	a0,a0
    80004dc2:	1aa91863          	bne	s2,a0,80004f72 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004dc6:	009d84bb          	addw	s1,s11,s1
    80004dca:	013d09bb          	addw	s3,s10,s3
    80004dce:	1f74f263          	bgeu	s1,s7,80004fb2 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004dd2:	02049593          	slli	a1,s1,0x20
    80004dd6:	9181                	srli	a1,a1,0x20
    80004dd8:	95e2                	add	a1,a1,s8
    80004dda:	855a                	mv	a0,s6
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	31e080e7          	jalr	798(ra) # 800010fa <walkaddr>
    80004de4:	862a                	mv	a2,a0
    if(pa == 0)
    80004de6:	dd45                	beqz	a0,80004d9e <exec+0xfe>
      n = PGSIZE;
    80004de8:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dea:	fd49f2e3          	bgeu	s3,s4,80004dae <exec+0x10e>
      n = sz - i;
    80004dee:	894e                	mv	s2,s3
    80004df0:	bf7d                	j	80004dae <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004df2:	4481                	li	s1,0
  iunlockput(ip);
    80004df4:	8556                	mv	a0,s5
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	bf4080e7          	jalr	-1036(ra) # 800039ea <iunlockput>
  end_op();
    80004dfe:	fffff097          	auipc	ra,0xfffff
    80004e02:	3ca080e7          	jalr	970(ra) # 800041c8 <end_op>
  p = myproc();
    80004e06:	ffffd097          	auipc	ra,0xffffd
    80004e0a:	cbc080e7          	jalr	-836(ra) # 80001ac2 <myproc>
    80004e0e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e10:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e14:	6785                	lui	a5,0x1
    80004e16:	17fd                	addi	a5,a5,-1
    80004e18:	94be                	add	s1,s1,a5
    80004e1a:	77fd                	lui	a5,0xfffff
    80004e1c:	8fe5                	and	a5,a5,s1
    80004e1e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e22:	6609                	lui	a2,0x2
    80004e24:	963e                	add	a2,a2,a5
    80004e26:	85be                	mv	a1,a5
    80004e28:	855a                	mv	a0,s6
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	6b4080e7          	jalr	1716(ra) # 800014de <uvmalloc>
    80004e32:	8c2a                	mv	s8,a0
  ip = 0;
    80004e34:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e36:	12050e63          	beqz	a0,80004f72 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e3a:	75f9                	lui	a1,0xffffe
    80004e3c:	95aa                	add	a1,a1,a0
    80004e3e:	855a                	mv	a0,s6
    80004e40:	ffffd097          	auipc	ra,0xffffd
    80004e44:	8b4080e7          	jalr	-1868(ra) # 800016f4 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e48:	7afd                	lui	s5,0xfffff
    80004e4a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e4c:	df043783          	ld	a5,-528(s0)
    80004e50:	6388                	ld	a0,0(a5)
    80004e52:	c925                	beqz	a0,80004ec2 <exec+0x222>
    80004e54:	e8840993          	addi	s3,s0,-376
    80004e58:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e5c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e5e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	090080e7          	jalr	144(ra) # 80000ef0 <strlen>
    80004e68:	0015079b          	addiw	a5,a0,1
    80004e6c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e70:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e74:	13596363          	bltu	s2,s5,80004f9a <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e78:	df043d83          	ld	s11,-528(s0)
    80004e7c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e80:	8552                	mv	a0,s4
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	06e080e7          	jalr	110(ra) # 80000ef0 <strlen>
    80004e8a:	0015069b          	addiw	a3,a0,1
    80004e8e:	8652                	mv	a2,s4
    80004e90:	85ca                	mv	a1,s2
    80004e92:	855a                	mv	a0,s6
    80004e94:	ffffd097          	auipc	ra,0xffffd
    80004e98:	892080e7          	jalr	-1902(ra) # 80001726 <copyout>
    80004e9c:	10054363          	bltz	a0,80004fa2 <exec+0x302>
    ustack[argc] = sp;
    80004ea0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ea4:	0485                	addi	s1,s1,1
    80004ea6:	008d8793          	addi	a5,s11,8
    80004eaa:	def43823          	sd	a5,-528(s0)
    80004eae:	008db503          	ld	a0,8(s11)
    80004eb2:	c911                	beqz	a0,80004ec6 <exec+0x226>
    if(argc >= MAXARG)
    80004eb4:	09a1                	addi	s3,s3,8
    80004eb6:	fb3c95e3          	bne	s9,s3,80004e60 <exec+0x1c0>
  sz = sz1;
    80004eba:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ebe:	4a81                	li	s5,0
    80004ec0:	a84d                	j	80004f72 <exec+0x2d2>
  sp = sz;
    80004ec2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ec4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ec6:	00349793          	slli	a5,s1,0x3
    80004eca:	f9040713          	addi	a4,s0,-112
    80004ece:	97ba                	add	a5,a5,a4
    80004ed0:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7fdb8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004ed4:	00148693          	addi	a3,s1,1
    80004ed8:	068e                	slli	a3,a3,0x3
    80004eda:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ede:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ee2:	01597663          	bgeu	s2,s5,80004eee <exec+0x24e>
  sz = sz1;
    80004ee6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eea:	4a81                	li	s5,0
    80004eec:	a059                	j	80004f72 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004eee:	e8840613          	addi	a2,s0,-376
    80004ef2:	85ca                	mv	a1,s2
    80004ef4:	855a                	mv	a0,s6
    80004ef6:	ffffd097          	auipc	ra,0xffffd
    80004efa:	830080e7          	jalr	-2000(ra) # 80001726 <copyout>
    80004efe:	0a054663          	bltz	a0,80004faa <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f02:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f06:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f0a:	de843783          	ld	a5,-536(s0)
    80004f0e:	0007c703          	lbu	a4,0(a5)
    80004f12:	cf11                	beqz	a4,80004f2e <exec+0x28e>
    80004f14:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f16:	02f00693          	li	a3,47
    80004f1a:	a039                	j	80004f28 <exec+0x288>
      last = s+1;
    80004f1c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f20:	0785                	addi	a5,a5,1
    80004f22:	fff7c703          	lbu	a4,-1(a5)
    80004f26:	c701                	beqz	a4,80004f2e <exec+0x28e>
    if(*s == '/')
    80004f28:	fed71ce3          	bne	a4,a3,80004f20 <exec+0x280>
    80004f2c:	bfc5                	j	80004f1c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f2e:	4641                	li	a2,16
    80004f30:	de843583          	ld	a1,-536(s0)
    80004f34:	158b8513          	addi	a0,s7,344
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	f86080e7          	jalr	-122(ra) # 80000ebe <safestrcpy>
  oldpagetable = p->pagetable;
    80004f40:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f44:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f48:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f4c:	058bb783          	ld	a5,88(s7)
    80004f50:	e6043703          	ld	a4,-416(s0)
    80004f54:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f56:	058bb783          	ld	a5,88(s7)
    80004f5a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f5e:	85ea                	mv	a1,s10
    80004f60:	ffffd097          	auipc	ra,0xffffd
    80004f64:	cc2080e7          	jalr	-830(ra) # 80001c22 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f68:	0004851b          	sext.w	a0,s1
    80004f6c:	bbc1                	j	80004d3c <exec+0x9c>
    80004f6e:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f72:	df843583          	ld	a1,-520(s0)
    80004f76:	855a                	mv	a0,s6
    80004f78:	ffffd097          	auipc	ra,0xffffd
    80004f7c:	caa080e7          	jalr	-854(ra) # 80001c22 <proc_freepagetable>
  if(ip){
    80004f80:	da0a94e3          	bnez	s5,80004d28 <exec+0x88>
  return -1;
    80004f84:	557d                	li	a0,-1
    80004f86:	bb5d                	j	80004d3c <exec+0x9c>
    80004f88:	de943c23          	sd	s1,-520(s0)
    80004f8c:	b7dd                	j	80004f72 <exec+0x2d2>
    80004f8e:	de943c23          	sd	s1,-520(s0)
    80004f92:	b7c5                	j	80004f72 <exec+0x2d2>
    80004f94:	de943c23          	sd	s1,-520(s0)
    80004f98:	bfe9                	j	80004f72 <exec+0x2d2>
  sz = sz1;
    80004f9a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f9e:	4a81                	li	s5,0
    80004fa0:	bfc9                	j	80004f72 <exec+0x2d2>
  sz = sz1;
    80004fa2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fa6:	4a81                	li	s5,0
    80004fa8:	b7e9                	j	80004f72 <exec+0x2d2>
  sz = sz1;
    80004faa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fae:	4a81                	li	s5,0
    80004fb0:	b7c9                	j	80004f72 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fb2:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fb6:	e0843783          	ld	a5,-504(s0)
    80004fba:	0017869b          	addiw	a3,a5,1
    80004fbe:	e0d43423          	sd	a3,-504(s0)
    80004fc2:	e0043783          	ld	a5,-512(s0)
    80004fc6:	0387879b          	addiw	a5,a5,56
    80004fca:	e8045703          	lhu	a4,-384(s0)
    80004fce:	e2e6d3e3          	bge	a3,a4,80004df4 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fd2:	2781                	sext.w	a5,a5
    80004fd4:	e0f43023          	sd	a5,-512(s0)
    80004fd8:	03800713          	li	a4,56
    80004fdc:	86be                	mv	a3,a5
    80004fde:	e1040613          	addi	a2,s0,-496
    80004fe2:	4581                	li	a1,0
    80004fe4:	8556                	mv	a0,s5
    80004fe6:	fffff097          	auipc	ra,0xfffff
    80004fea:	a56080e7          	jalr	-1450(ra) # 80003a3c <readi>
    80004fee:	03800793          	li	a5,56
    80004ff2:	f6f51ee3          	bne	a0,a5,80004f6e <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004ff6:	e1042783          	lw	a5,-496(s0)
    80004ffa:	4705                	li	a4,1
    80004ffc:	fae79de3          	bne	a5,a4,80004fb6 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005000:	e3843603          	ld	a2,-456(s0)
    80005004:	e3043783          	ld	a5,-464(s0)
    80005008:	f8f660e3          	bltu	a2,a5,80004f88 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000500c:	e2043783          	ld	a5,-480(s0)
    80005010:	963e                	add	a2,a2,a5
    80005012:	f6f66ee3          	bltu	a2,a5,80004f8e <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005016:	85a6                	mv	a1,s1
    80005018:	855a                	mv	a0,s6
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	4c4080e7          	jalr	1220(ra) # 800014de <uvmalloc>
    80005022:	dea43c23          	sd	a0,-520(s0)
    80005026:	d53d                	beqz	a0,80004f94 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005028:	e2043c03          	ld	s8,-480(s0)
    8000502c:	de043783          	ld	a5,-544(s0)
    80005030:	00fc77b3          	and	a5,s8,a5
    80005034:	ff9d                	bnez	a5,80004f72 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005036:	e1842c83          	lw	s9,-488(s0)
    8000503a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000503e:	f60b8ae3          	beqz	s7,80004fb2 <exec+0x312>
    80005042:	89de                	mv	s3,s7
    80005044:	4481                	li	s1,0
    80005046:	b371                	j	80004dd2 <exec+0x132>

0000000080005048 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005048:	7179                	addi	sp,sp,-48
    8000504a:	f406                	sd	ra,40(sp)
    8000504c:	f022                	sd	s0,32(sp)
    8000504e:	ec26                	sd	s1,24(sp)
    80005050:	e84a                	sd	s2,16(sp)
    80005052:	1800                	addi	s0,sp,48
    80005054:	892e                	mv	s2,a1
    80005056:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005058:	fdc40593          	addi	a1,s0,-36
    8000505c:	ffffe097          	auipc	ra,0xffffe
    80005060:	bbc080e7          	jalr	-1092(ra) # 80002c18 <argint>
    80005064:	04054063          	bltz	a0,800050a4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005068:	fdc42703          	lw	a4,-36(s0)
    8000506c:	47bd                	li	a5,15
    8000506e:	02e7ed63          	bltu	a5,a4,800050a8 <argfd+0x60>
    80005072:	ffffd097          	auipc	ra,0xffffd
    80005076:	a50080e7          	jalr	-1456(ra) # 80001ac2 <myproc>
    8000507a:	fdc42703          	lw	a4,-36(s0)
    8000507e:	01a70793          	addi	a5,a4,26
    80005082:	078e                	slli	a5,a5,0x3
    80005084:	953e                	add	a0,a0,a5
    80005086:	611c                	ld	a5,0(a0)
    80005088:	c395                	beqz	a5,800050ac <argfd+0x64>
    return -1;
  if(pfd)
    8000508a:	00090463          	beqz	s2,80005092 <argfd+0x4a>
    *pfd = fd;
    8000508e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005092:	4501                	li	a0,0
  if(pf)
    80005094:	c091                	beqz	s1,80005098 <argfd+0x50>
    *pf = f;
    80005096:	e09c                	sd	a5,0(s1)
}
    80005098:	70a2                	ld	ra,40(sp)
    8000509a:	7402                	ld	s0,32(sp)
    8000509c:	64e2                	ld	s1,24(sp)
    8000509e:	6942                	ld	s2,16(sp)
    800050a0:	6145                	addi	sp,sp,48
    800050a2:	8082                	ret
    return -1;
    800050a4:	557d                	li	a0,-1
    800050a6:	bfcd                	j	80005098 <argfd+0x50>
    return -1;
    800050a8:	557d                	li	a0,-1
    800050aa:	b7fd                	j	80005098 <argfd+0x50>
    800050ac:	557d                	li	a0,-1
    800050ae:	b7ed                	j	80005098 <argfd+0x50>

00000000800050b0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050b0:	1101                	addi	sp,sp,-32
    800050b2:	ec06                	sd	ra,24(sp)
    800050b4:	e822                	sd	s0,16(sp)
    800050b6:	e426                	sd	s1,8(sp)
    800050b8:	1000                	addi	s0,sp,32
    800050ba:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050bc:	ffffd097          	auipc	ra,0xffffd
    800050c0:	a06080e7          	jalr	-1530(ra) # 80001ac2 <myproc>
    800050c4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050c6:	0d050793          	addi	a5,a0,208
    800050ca:	4501                	li	a0,0
    800050cc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ce:	6398                	ld	a4,0(a5)
    800050d0:	cb19                	beqz	a4,800050e6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050d2:	2505                	addiw	a0,a0,1
    800050d4:	07a1                	addi	a5,a5,8
    800050d6:	fed51ce3          	bne	a0,a3,800050ce <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050da:	557d                	li	a0,-1
}
    800050dc:	60e2                	ld	ra,24(sp)
    800050de:	6442                	ld	s0,16(sp)
    800050e0:	64a2                	ld	s1,8(sp)
    800050e2:	6105                	addi	sp,sp,32
    800050e4:	8082                	ret
      p->ofile[fd] = f;
    800050e6:	01a50793          	addi	a5,a0,26
    800050ea:	078e                	slli	a5,a5,0x3
    800050ec:	963e                	add	a2,a2,a5
    800050ee:	e204                	sd	s1,0(a2)
      return fd;
    800050f0:	b7f5                	j	800050dc <fdalloc+0x2c>

00000000800050f2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050f2:	715d                	addi	sp,sp,-80
    800050f4:	e486                	sd	ra,72(sp)
    800050f6:	e0a2                	sd	s0,64(sp)
    800050f8:	fc26                	sd	s1,56(sp)
    800050fa:	f84a                	sd	s2,48(sp)
    800050fc:	f44e                	sd	s3,40(sp)
    800050fe:	f052                	sd	s4,32(sp)
    80005100:	ec56                	sd	s5,24(sp)
    80005102:	0880                	addi	s0,sp,80
    80005104:	89ae                	mv	s3,a1
    80005106:	8ab2                	mv	s5,a2
    80005108:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000510a:	fb040593          	addi	a1,s0,-80
    8000510e:	fffff097          	auipc	ra,0xfffff
    80005112:	e4c080e7          	jalr	-436(ra) # 80003f5a <nameiparent>
    80005116:	892a                	mv	s2,a0
    80005118:	12050e63          	beqz	a0,80005254 <create+0x162>
    return 0;

  ilock(dp);
    8000511c:	ffffe097          	auipc	ra,0xffffe
    80005120:	66c080e7          	jalr	1644(ra) # 80003788 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005124:	4601                	li	a2,0
    80005126:	fb040593          	addi	a1,s0,-80
    8000512a:	854a                	mv	a0,s2
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	b3e080e7          	jalr	-1218(ra) # 80003c6a <dirlookup>
    80005134:	84aa                	mv	s1,a0
    80005136:	c921                	beqz	a0,80005186 <create+0x94>
    iunlockput(dp);
    80005138:	854a                	mv	a0,s2
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	8b0080e7          	jalr	-1872(ra) # 800039ea <iunlockput>
    ilock(ip);
    80005142:	8526                	mv	a0,s1
    80005144:	ffffe097          	auipc	ra,0xffffe
    80005148:	644080e7          	jalr	1604(ra) # 80003788 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000514c:	2981                	sext.w	s3,s3
    8000514e:	4789                	li	a5,2
    80005150:	02f99463          	bne	s3,a5,80005178 <create+0x86>
    80005154:	0444d783          	lhu	a5,68(s1)
    80005158:	37f9                	addiw	a5,a5,-2
    8000515a:	17c2                	slli	a5,a5,0x30
    8000515c:	93c1                	srli	a5,a5,0x30
    8000515e:	4705                	li	a4,1
    80005160:	00f76c63          	bltu	a4,a5,80005178 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005164:	8526                	mv	a0,s1
    80005166:	60a6                	ld	ra,72(sp)
    80005168:	6406                	ld	s0,64(sp)
    8000516a:	74e2                	ld	s1,56(sp)
    8000516c:	7942                	ld	s2,48(sp)
    8000516e:	79a2                	ld	s3,40(sp)
    80005170:	7a02                	ld	s4,32(sp)
    80005172:	6ae2                	ld	s5,24(sp)
    80005174:	6161                	addi	sp,sp,80
    80005176:	8082                	ret
    iunlockput(ip);
    80005178:	8526                	mv	a0,s1
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	870080e7          	jalr	-1936(ra) # 800039ea <iunlockput>
    return 0;
    80005182:	4481                	li	s1,0
    80005184:	b7c5                	j	80005164 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005186:	85ce                	mv	a1,s3
    80005188:	00092503          	lw	a0,0(s2)
    8000518c:	ffffe097          	auipc	ra,0xffffe
    80005190:	464080e7          	jalr	1124(ra) # 800035f0 <ialloc>
    80005194:	84aa                	mv	s1,a0
    80005196:	c521                	beqz	a0,800051de <create+0xec>
  ilock(ip);
    80005198:	ffffe097          	auipc	ra,0xffffe
    8000519c:	5f0080e7          	jalr	1520(ra) # 80003788 <ilock>
  ip->major = major;
    800051a0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051a4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051a8:	4a05                	li	s4,1
    800051aa:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800051ae:	8526                	mv	a0,s1
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	50e080e7          	jalr	1294(ra) # 800036be <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051b8:	2981                	sext.w	s3,s3
    800051ba:	03498a63          	beq	s3,s4,800051ee <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800051be:	40d0                	lw	a2,4(s1)
    800051c0:	fb040593          	addi	a1,s0,-80
    800051c4:	854a                	mv	a0,s2
    800051c6:	fffff097          	auipc	ra,0xfffff
    800051ca:	cb4080e7          	jalr	-844(ra) # 80003e7a <dirlink>
    800051ce:	06054b63          	bltz	a0,80005244 <create+0x152>
  iunlockput(dp);
    800051d2:	854a                	mv	a0,s2
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	816080e7          	jalr	-2026(ra) # 800039ea <iunlockput>
  return ip;
    800051dc:	b761                	j	80005164 <create+0x72>
    panic("create: ialloc");
    800051de:	00003517          	auipc	a0,0x3
    800051e2:	4fa50513          	addi	a0,a0,1274 # 800086d8 <syscalls+0x2b0>
    800051e6:	ffffb097          	auipc	ra,0xffffb
    800051ea:	35c080e7          	jalr	860(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    800051ee:	04a95783          	lhu	a5,74(s2)
    800051f2:	2785                	addiw	a5,a5,1
    800051f4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051f8:	854a                	mv	a0,s2
    800051fa:	ffffe097          	auipc	ra,0xffffe
    800051fe:	4c4080e7          	jalr	1220(ra) # 800036be <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005202:	40d0                	lw	a2,4(s1)
    80005204:	00003597          	auipc	a1,0x3
    80005208:	4e458593          	addi	a1,a1,1252 # 800086e8 <syscalls+0x2c0>
    8000520c:	8526                	mv	a0,s1
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	c6c080e7          	jalr	-916(ra) # 80003e7a <dirlink>
    80005216:	00054f63          	bltz	a0,80005234 <create+0x142>
    8000521a:	00492603          	lw	a2,4(s2)
    8000521e:	00003597          	auipc	a1,0x3
    80005222:	4d258593          	addi	a1,a1,1234 # 800086f0 <syscalls+0x2c8>
    80005226:	8526                	mv	a0,s1
    80005228:	fffff097          	auipc	ra,0xfffff
    8000522c:	c52080e7          	jalr	-942(ra) # 80003e7a <dirlink>
    80005230:	f80557e3          	bgez	a0,800051be <create+0xcc>
      panic("create dots");
    80005234:	00003517          	auipc	a0,0x3
    80005238:	4c450513          	addi	a0,a0,1220 # 800086f8 <syscalls+0x2d0>
    8000523c:	ffffb097          	auipc	ra,0xffffb
    80005240:	306080e7          	jalr	774(ra) # 80000542 <panic>
    panic("create: dirlink");
    80005244:	00003517          	auipc	a0,0x3
    80005248:	4c450513          	addi	a0,a0,1220 # 80008708 <syscalls+0x2e0>
    8000524c:	ffffb097          	auipc	ra,0xffffb
    80005250:	2f6080e7          	jalr	758(ra) # 80000542 <panic>
    return 0;
    80005254:	84aa                	mv	s1,a0
    80005256:	b739                	j	80005164 <create+0x72>

0000000080005258 <sys_dup>:
{
    80005258:	7179                	addi	sp,sp,-48
    8000525a:	f406                	sd	ra,40(sp)
    8000525c:	f022                	sd	s0,32(sp)
    8000525e:	ec26                	sd	s1,24(sp)
    80005260:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005262:	fd840613          	addi	a2,s0,-40
    80005266:	4581                	li	a1,0
    80005268:	4501                	li	a0,0
    8000526a:	00000097          	auipc	ra,0x0
    8000526e:	dde080e7          	jalr	-546(ra) # 80005048 <argfd>
    return -1;
    80005272:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005274:	02054363          	bltz	a0,8000529a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005278:	fd843503          	ld	a0,-40(s0)
    8000527c:	00000097          	auipc	ra,0x0
    80005280:	e34080e7          	jalr	-460(ra) # 800050b0 <fdalloc>
    80005284:	84aa                	mv	s1,a0
    return -1;
    80005286:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005288:	00054963          	bltz	a0,8000529a <sys_dup+0x42>
  filedup(f);
    8000528c:	fd843503          	ld	a0,-40(s0)
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	338080e7          	jalr	824(ra) # 800045c8 <filedup>
  return fd;
    80005298:	87a6                	mv	a5,s1
}
    8000529a:	853e                	mv	a0,a5
    8000529c:	70a2                	ld	ra,40(sp)
    8000529e:	7402                	ld	s0,32(sp)
    800052a0:	64e2                	ld	s1,24(sp)
    800052a2:	6145                	addi	sp,sp,48
    800052a4:	8082                	ret

00000000800052a6 <sys_read>:
{
    800052a6:	7179                	addi	sp,sp,-48
    800052a8:	f406                	sd	ra,40(sp)
    800052aa:	f022                	sd	s0,32(sp)
    800052ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ae:	fe840613          	addi	a2,s0,-24
    800052b2:	4581                	li	a1,0
    800052b4:	4501                	li	a0,0
    800052b6:	00000097          	auipc	ra,0x0
    800052ba:	d92080e7          	jalr	-622(ra) # 80005048 <argfd>
    return -1;
    800052be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c0:	04054163          	bltz	a0,80005302 <sys_read+0x5c>
    800052c4:	fe440593          	addi	a1,s0,-28
    800052c8:	4509                	li	a0,2
    800052ca:	ffffe097          	auipc	ra,0xffffe
    800052ce:	94e080e7          	jalr	-1714(ra) # 80002c18 <argint>
    return -1;
    800052d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d4:	02054763          	bltz	a0,80005302 <sys_read+0x5c>
    800052d8:	fd840593          	addi	a1,s0,-40
    800052dc:	4505                	li	a0,1
    800052de:	ffffe097          	auipc	ra,0xffffe
    800052e2:	95c080e7          	jalr	-1700(ra) # 80002c3a <argaddr>
    return -1;
    800052e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e8:	00054d63          	bltz	a0,80005302 <sys_read+0x5c>
  return fileread(f, p, n);
    800052ec:	fe442603          	lw	a2,-28(s0)
    800052f0:	fd843583          	ld	a1,-40(s0)
    800052f4:	fe843503          	ld	a0,-24(s0)
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	45c080e7          	jalr	1116(ra) # 80004754 <fileread>
    80005300:	87aa                	mv	a5,a0
}
    80005302:	853e                	mv	a0,a5
    80005304:	70a2                	ld	ra,40(sp)
    80005306:	7402                	ld	s0,32(sp)
    80005308:	6145                	addi	sp,sp,48
    8000530a:	8082                	ret

000000008000530c <sys_write>:
{
    8000530c:	7179                	addi	sp,sp,-48
    8000530e:	f406                	sd	ra,40(sp)
    80005310:	f022                	sd	s0,32(sp)
    80005312:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005314:	fe840613          	addi	a2,s0,-24
    80005318:	4581                	li	a1,0
    8000531a:	4501                	li	a0,0
    8000531c:	00000097          	auipc	ra,0x0
    80005320:	d2c080e7          	jalr	-724(ra) # 80005048 <argfd>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005326:	04054163          	bltz	a0,80005368 <sys_write+0x5c>
    8000532a:	fe440593          	addi	a1,s0,-28
    8000532e:	4509                	li	a0,2
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	8e8080e7          	jalr	-1816(ra) # 80002c18 <argint>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533a:	02054763          	bltz	a0,80005368 <sys_write+0x5c>
    8000533e:	fd840593          	addi	a1,s0,-40
    80005342:	4505                	li	a0,1
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	8f6080e7          	jalr	-1802(ra) # 80002c3a <argaddr>
    return -1;
    8000534c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534e:	00054d63          	bltz	a0,80005368 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005352:	fe442603          	lw	a2,-28(s0)
    80005356:	fd843583          	ld	a1,-40(s0)
    8000535a:	fe843503          	ld	a0,-24(s0)
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	4b8080e7          	jalr	1208(ra) # 80004816 <filewrite>
    80005366:	87aa                	mv	a5,a0
}
    80005368:	853e                	mv	a0,a5
    8000536a:	70a2                	ld	ra,40(sp)
    8000536c:	7402                	ld	s0,32(sp)
    8000536e:	6145                	addi	sp,sp,48
    80005370:	8082                	ret

0000000080005372 <sys_close>:
{
    80005372:	1101                	addi	sp,sp,-32
    80005374:	ec06                	sd	ra,24(sp)
    80005376:	e822                	sd	s0,16(sp)
    80005378:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000537a:	fe040613          	addi	a2,s0,-32
    8000537e:	fec40593          	addi	a1,s0,-20
    80005382:	4501                	li	a0,0
    80005384:	00000097          	auipc	ra,0x0
    80005388:	cc4080e7          	jalr	-828(ra) # 80005048 <argfd>
    return -1;
    8000538c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000538e:	02054463          	bltz	a0,800053b6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005392:	ffffc097          	auipc	ra,0xffffc
    80005396:	730080e7          	jalr	1840(ra) # 80001ac2 <myproc>
    8000539a:	fec42783          	lw	a5,-20(s0)
    8000539e:	07e9                	addi	a5,a5,26
    800053a0:	078e                	slli	a5,a5,0x3
    800053a2:	97aa                	add	a5,a5,a0
    800053a4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053a8:	fe043503          	ld	a0,-32(s0)
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	26e080e7          	jalr	622(ra) # 8000461a <fileclose>
  return 0;
    800053b4:	4781                	li	a5,0
}
    800053b6:	853e                	mv	a0,a5
    800053b8:	60e2                	ld	ra,24(sp)
    800053ba:	6442                	ld	s0,16(sp)
    800053bc:	6105                	addi	sp,sp,32
    800053be:	8082                	ret

00000000800053c0 <sys_fstat>:
{
    800053c0:	1101                	addi	sp,sp,-32
    800053c2:	ec06                	sd	ra,24(sp)
    800053c4:	e822                	sd	s0,16(sp)
    800053c6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c8:	fe840613          	addi	a2,s0,-24
    800053cc:	4581                	li	a1,0
    800053ce:	4501                	li	a0,0
    800053d0:	00000097          	auipc	ra,0x0
    800053d4:	c78080e7          	jalr	-904(ra) # 80005048 <argfd>
    return -1;
    800053d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053da:	02054563          	bltz	a0,80005404 <sys_fstat+0x44>
    800053de:	fe040593          	addi	a1,s0,-32
    800053e2:	4505                	li	a0,1
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	856080e7          	jalr	-1962(ra) # 80002c3a <argaddr>
    return -1;
    800053ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ee:	00054b63          	bltz	a0,80005404 <sys_fstat+0x44>
  return filestat(f, st);
    800053f2:	fe043583          	ld	a1,-32(s0)
    800053f6:	fe843503          	ld	a0,-24(s0)
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	2e8080e7          	jalr	744(ra) # 800046e2 <filestat>
    80005402:	87aa                	mv	a5,a0
}
    80005404:	853e                	mv	a0,a5
    80005406:	60e2                	ld	ra,24(sp)
    80005408:	6442                	ld	s0,16(sp)
    8000540a:	6105                	addi	sp,sp,32
    8000540c:	8082                	ret

000000008000540e <sys_link>:
{
    8000540e:	7169                	addi	sp,sp,-304
    80005410:	f606                	sd	ra,296(sp)
    80005412:	f222                	sd	s0,288(sp)
    80005414:	ee26                	sd	s1,280(sp)
    80005416:	ea4a                	sd	s2,272(sp)
    80005418:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541a:	08000613          	li	a2,128
    8000541e:	ed040593          	addi	a1,s0,-304
    80005422:	4501                	li	a0,0
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	838080e7          	jalr	-1992(ra) # 80002c5c <argstr>
    return -1;
    8000542c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000542e:	10054e63          	bltz	a0,8000554a <sys_link+0x13c>
    80005432:	08000613          	li	a2,128
    80005436:	f5040593          	addi	a1,s0,-176
    8000543a:	4505                	li	a0,1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	820080e7          	jalr	-2016(ra) # 80002c5c <argstr>
    return -1;
    80005444:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005446:	10054263          	bltz	a0,8000554a <sys_link+0x13c>
  begin_op();
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	cfe080e7          	jalr	-770(ra) # 80004148 <begin_op>
  if((ip = namei(old)) == 0){
    80005452:	ed040513          	addi	a0,s0,-304
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	ae6080e7          	jalr	-1306(ra) # 80003f3c <namei>
    8000545e:	84aa                	mv	s1,a0
    80005460:	c551                	beqz	a0,800054ec <sys_link+0xde>
  ilock(ip);
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	326080e7          	jalr	806(ra) # 80003788 <ilock>
  if(ip->type == T_DIR){
    8000546a:	04449703          	lh	a4,68(s1)
    8000546e:	4785                	li	a5,1
    80005470:	08f70463          	beq	a4,a5,800054f8 <sys_link+0xea>
  ip->nlink++;
    80005474:	04a4d783          	lhu	a5,74(s1)
    80005478:	2785                	addiw	a5,a5,1
    8000547a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000547e:	8526                	mv	a0,s1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	23e080e7          	jalr	574(ra) # 800036be <iupdate>
  iunlock(ip);
    80005488:	8526                	mv	a0,s1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	3c0080e7          	jalr	960(ra) # 8000384a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005492:	fd040593          	addi	a1,s0,-48
    80005496:	f5040513          	addi	a0,s0,-176
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	ac0080e7          	jalr	-1344(ra) # 80003f5a <nameiparent>
    800054a2:	892a                	mv	s2,a0
    800054a4:	c935                	beqz	a0,80005518 <sys_link+0x10a>
  ilock(dp);
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	2e2080e7          	jalr	738(ra) # 80003788 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054ae:	00092703          	lw	a4,0(s2)
    800054b2:	409c                	lw	a5,0(s1)
    800054b4:	04f71d63          	bne	a4,a5,8000550e <sys_link+0x100>
    800054b8:	40d0                	lw	a2,4(s1)
    800054ba:	fd040593          	addi	a1,s0,-48
    800054be:	854a                	mv	a0,s2
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	9ba080e7          	jalr	-1606(ra) # 80003e7a <dirlink>
    800054c8:	04054363          	bltz	a0,8000550e <sys_link+0x100>
  iunlockput(dp);
    800054cc:	854a                	mv	a0,s2
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	51c080e7          	jalr	1308(ra) # 800039ea <iunlockput>
  iput(ip);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	46a080e7          	jalr	1130(ra) # 80003942 <iput>
  end_op();
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	ce8080e7          	jalr	-792(ra) # 800041c8 <end_op>
  return 0;
    800054e8:	4781                	li	a5,0
    800054ea:	a085                	j	8000554a <sys_link+0x13c>
    end_op();
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	cdc080e7          	jalr	-804(ra) # 800041c8 <end_op>
    return -1;
    800054f4:	57fd                	li	a5,-1
    800054f6:	a891                	j	8000554a <sys_link+0x13c>
    iunlockput(ip);
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	4f0080e7          	jalr	1264(ra) # 800039ea <iunlockput>
    end_op();
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	cc6080e7          	jalr	-826(ra) # 800041c8 <end_op>
    return -1;
    8000550a:	57fd                	li	a5,-1
    8000550c:	a83d                	j	8000554a <sys_link+0x13c>
    iunlockput(dp);
    8000550e:	854a                	mv	a0,s2
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	4da080e7          	jalr	1242(ra) # 800039ea <iunlockput>
  ilock(ip);
    80005518:	8526                	mv	a0,s1
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	26e080e7          	jalr	622(ra) # 80003788 <ilock>
  ip->nlink--;
    80005522:	04a4d783          	lhu	a5,74(s1)
    80005526:	37fd                	addiw	a5,a5,-1
    80005528:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000552c:	8526                	mv	a0,s1
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	190080e7          	jalr	400(ra) # 800036be <iupdate>
  iunlockput(ip);
    80005536:	8526                	mv	a0,s1
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	4b2080e7          	jalr	1202(ra) # 800039ea <iunlockput>
  end_op();
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	c88080e7          	jalr	-888(ra) # 800041c8 <end_op>
  return -1;
    80005548:	57fd                	li	a5,-1
}
    8000554a:	853e                	mv	a0,a5
    8000554c:	70b2                	ld	ra,296(sp)
    8000554e:	7412                	ld	s0,288(sp)
    80005550:	64f2                	ld	s1,280(sp)
    80005552:	6952                	ld	s2,272(sp)
    80005554:	6155                	addi	sp,sp,304
    80005556:	8082                	ret

0000000080005558 <sys_unlink>:
{
    80005558:	7151                	addi	sp,sp,-240
    8000555a:	f586                	sd	ra,232(sp)
    8000555c:	f1a2                	sd	s0,224(sp)
    8000555e:	eda6                	sd	s1,216(sp)
    80005560:	e9ca                	sd	s2,208(sp)
    80005562:	e5ce                	sd	s3,200(sp)
    80005564:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005566:	08000613          	li	a2,128
    8000556a:	f3040593          	addi	a1,s0,-208
    8000556e:	4501                	li	a0,0
    80005570:	ffffd097          	auipc	ra,0xffffd
    80005574:	6ec080e7          	jalr	1772(ra) # 80002c5c <argstr>
    80005578:	18054163          	bltz	a0,800056fa <sys_unlink+0x1a2>
  begin_op();
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	bcc080e7          	jalr	-1076(ra) # 80004148 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005584:	fb040593          	addi	a1,s0,-80
    80005588:	f3040513          	addi	a0,s0,-208
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	9ce080e7          	jalr	-1586(ra) # 80003f5a <nameiparent>
    80005594:	84aa                	mv	s1,a0
    80005596:	c979                	beqz	a0,8000566c <sys_unlink+0x114>
  ilock(dp);
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	1f0080e7          	jalr	496(ra) # 80003788 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055a0:	00003597          	auipc	a1,0x3
    800055a4:	14858593          	addi	a1,a1,328 # 800086e8 <syscalls+0x2c0>
    800055a8:	fb040513          	addi	a0,s0,-80
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	6a4080e7          	jalr	1700(ra) # 80003c50 <namecmp>
    800055b4:	14050a63          	beqz	a0,80005708 <sys_unlink+0x1b0>
    800055b8:	00003597          	auipc	a1,0x3
    800055bc:	13858593          	addi	a1,a1,312 # 800086f0 <syscalls+0x2c8>
    800055c0:	fb040513          	addi	a0,s0,-80
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	68c080e7          	jalr	1676(ra) # 80003c50 <namecmp>
    800055cc:	12050e63          	beqz	a0,80005708 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055d0:	f2c40613          	addi	a2,s0,-212
    800055d4:	fb040593          	addi	a1,s0,-80
    800055d8:	8526                	mv	a0,s1
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	690080e7          	jalr	1680(ra) # 80003c6a <dirlookup>
    800055e2:	892a                	mv	s2,a0
    800055e4:	12050263          	beqz	a0,80005708 <sys_unlink+0x1b0>
  ilock(ip);
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	1a0080e7          	jalr	416(ra) # 80003788 <ilock>
  if(ip->nlink < 1)
    800055f0:	04a91783          	lh	a5,74(s2)
    800055f4:	08f05263          	blez	a5,80005678 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055f8:	04491703          	lh	a4,68(s2)
    800055fc:	4785                	li	a5,1
    800055fe:	08f70563          	beq	a4,a5,80005688 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005602:	4641                	li	a2,16
    80005604:	4581                	li	a1,0
    80005606:	fc040513          	addi	a0,s0,-64
    8000560a:	ffffb097          	auipc	ra,0xffffb
    8000560e:	762080e7          	jalr	1890(ra) # 80000d6c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005612:	4741                	li	a4,16
    80005614:	f2c42683          	lw	a3,-212(s0)
    80005618:	fc040613          	addi	a2,s0,-64
    8000561c:	4581                	li	a1,0
    8000561e:	8526                	mv	a0,s1
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	514080e7          	jalr	1300(ra) # 80003b34 <writei>
    80005628:	47c1                	li	a5,16
    8000562a:	0af51563          	bne	a0,a5,800056d4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000562e:	04491703          	lh	a4,68(s2)
    80005632:	4785                	li	a5,1
    80005634:	0af70863          	beq	a4,a5,800056e4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005638:	8526                	mv	a0,s1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	3b0080e7          	jalr	944(ra) # 800039ea <iunlockput>
  ip->nlink--;
    80005642:	04a95783          	lhu	a5,74(s2)
    80005646:	37fd                	addiw	a5,a5,-1
    80005648:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000564c:	854a                	mv	a0,s2
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	070080e7          	jalr	112(ra) # 800036be <iupdate>
  iunlockput(ip);
    80005656:	854a                	mv	a0,s2
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	392080e7          	jalr	914(ra) # 800039ea <iunlockput>
  end_op();
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	b68080e7          	jalr	-1176(ra) # 800041c8 <end_op>
  return 0;
    80005668:	4501                	li	a0,0
    8000566a:	a84d                	j	8000571c <sys_unlink+0x1c4>
    end_op();
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	b5c080e7          	jalr	-1188(ra) # 800041c8 <end_op>
    return -1;
    80005674:	557d                	li	a0,-1
    80005676:	a05d                	j	8000571c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005678:	00003517          	auipc	a0,0x3
    8000567c:	0a050513          	addi	a0,a0,160 # 80008718 <syscalls+0x2f0>
    80005680:	ffffb097          	auipc	ra,0xffffb
    80005684:	ec2080e7          	jalr	-318(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005688:	04c92703          	lw	a4,76(s2)
    8000568c:	02000793          	li	a5,32
    80005690:	f6e7f9e3          	bgeu	a5,a4,80005602 <sys_unlink+0xaa>
    80005694:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005698:	4741                	li	a4,16
    8000569a:	86ce                	mv	a3,s3
    8000569c:	f1840613          	addi	a2,s0,-232
    800056a0:	4581                	li	a1,0
    800056a2:	854a                	mv	a0,s2
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	398080e7          	jalr	920(ra) # 80003a3c <readi>
    800056ac:	47c1                	li	a5,16
    800056ae:	00f51b63          	bne	a0,a5,800056c4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056b2:	f1845783          	lhu	a5,-232(s0)
    800056b6:	e7a1                	bnez	a5,800056fe <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b8:	29c1                	addiw	s3,s3,16
    800056ba:	04c92783          	lw	a5,76(s2)
    800056be:	fcf9ede3          	bltu	s3,a5,80005698 <sys_unlink+0x140>
    800056c2:	b781                	j	80005602 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056c4:	00003517          	auipc	a0,0x3
    800056c8:	06c50513          	addi	a0,a0,108 # 80008730 <syscalls+0x308>
    800056cc:	ffffb097          	auipc	ra,0xffffb
    800056d0:	e76080e7          	jalr	-394(ra) # 80000542 <panic>
    panic("unlink: writei");
    800056d4:	00003517          	auipc	a0,0x3
    800056d8:	07450513          	addi	a0,a0,116 # 80008748 <syscalls+0x320>
    800056dc:	ffffb097          	auipc	ra,0xffffb
    800056e0:	e66080e7          	jalr	-410(ra) # 80000542 <panic>
    dp->nlink--;
    800056e4:	04a4d783          	lhu	a5,74(s1)
    800056e8:	37fd                	addiw	a5,a5,-1
    800056ea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056ee:	8526                	mv	a0,s1
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	fce080e7          	jalr	-50(ra) # 800036be <iupdate>
    800056f8:	b781                	j	80005638 <sys_unlink+0xe0>
    return -1;
    800056fa:	557d                	li	a0,-1
    800056fc:	a005                	j	8000571c <sys_unlink+0x1c4>
    iunlockput(ip);
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	2ea080e7          	jalr	746(ra) # 800039ea <iunlockput>
  iunlockput(dp);
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	2e0080e7          	jalr	736(ra) # 800039ea <iunlockput>
  end_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	ab6080e7          	jalr	-1354(ra) # 800041c8 <end_op>
  return -1;
    8000571a:	557d                	li	a0,-1
}
    8000571c:	70ae                	ld	ra,232(sp)
    8000571e:	740e                	ld	s0,224(sp)
    80005720:	64ee                	ld	s1,216(sp)
    80005722:	694e                	ld	s2,208(sp)
    80005724:	69ae                	ld	s3,200(sp)
    80005726:	616d                	addi	sp,sp,240
    80005728:	8082                	ret

000000008000572a <sys_open>:

uint64
sys_open(void)
{
    8000572a:	7131                	addi	sp,sp,-192
    8000572c:	fd06                	sd	ra,184(sp)
    8000572e:	f922                	sd	s0,176(sp)
    80005730:	f526                	sd	s1,168(sp)
    80005732:	f14a                	sd	s2,160(sp)
    80005734:	ed4e                	sd	s3,152(sp)
    80005736:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005738:	08000613          	li	a2,128
    8000573c:	f5040593          	addi	a1,s0,-176
    80005740:	4501                	li	a0,0
    80005742:	ffffd097          	auipc	ra,0xffffd
    80005746:	51a080e7          	jalr	1306(ra) # 80002c5c <argstr>
    return -1;
    8000574a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000574c:	0c054163          	bltz	a0,8000580e <sys_open+0xe4>
    80005750:	f4c40593          	addi	a1,s0,-180
    80005754:	4505                	li	a0,1
    80005756:	ffffd097          	auipc	ra,0xffffd
    8000575a:	4c2080e7          	jalr	1218(ra) # 80002c18 <argint>
    8000575e:	0a054863          	bltz	a0,8000580e <sys_open+0xe4>

  begin_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	9e6080e7          	jalr	-1562(ra) # 80004148 <begin_op>

  if(omode & O_CREATE){
    8000576a:	f4c42783          	lw	a5,-180(s0)
    8000576e:	2007f793          	andi	a5,a5,512
    80005772:	cbdd                	beqz	a5,80005828 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005774:	4681                	li	a3,0
    80005776:	4601                	li	a2,0
    80005778:	4589                	li	a1,2
    8000577a:	f5040513          	addi	a0,s0,-176
    8000577e:	00000097          	auipc	ra,0x0
    80005782:	974080e7          	jalr	-1676(ra) # 800050f2 <create>
    80005786:	892a                	mv	s2,a0
    if(ip == 0){
    80005788:	c959                	beqz	a0,8000581e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000578a:	04491703          	lh	a4,68(s2)
    8000578e:	478d                	li	a5,3
    80005790:	00f71763          	bne	a4,a5,8000579e <sys_open+0x74>
    80005794:	04695703          	lhu	a4,70(s2)
    80005798:	47a5                	li	a5,9
    8000579a:	0ce7ec63          	bltu	a5,a4,80005872 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	dc0080e7          	jalr	-576(ra) # 8000455e <filealloc>
    800057a6:	89aa                	mv	s3,a0
    800057a8:	10050263          	beqz	a0,800058ac <sys_open+0x182>
    800057ac:	00000097          	auipc	ra,0x0
    800057b0:	904080e7          	jalr	-1788(ra) # 800050b0 <fdalloc>
    800057b4:	84aa                	mv	s1,a0
    800057b6:	0e054663          	bltz	a0,800058a2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ba:	04491703          	lh	a4,68(s2)
    800057be:	478d                	li	a5,3
    800057c0:	0cf70463          	beq	a4,a5,80005888 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057c4:	4789                	li	a5,2
    800057c6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057ca:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057ce:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057d2:	f4c42783          	lw	a5,-180(s0)
    800057d6:	0017c713          	xori	a4,a5,1
    800057da:	8b05                	andi	a4,a4,1
    800057dc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057e0:	0037f713          	andi	a4,a5,3
    800057e4:	00e03733          	snez	a4,a4
    800057e8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057ec:	4007f793          	andi	a5,a5,1024
    800057f0:	c791                	beqz	a5,800057fc <sys_open+0xd2>
    800057f2:	04491703          	lh	a4,68(s2)
    800057f6:	4789                	li	a5,2
    800057f8:	08f70f63          	beq	a4,a5,80005896 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057fc:	854a                	mv	a0,s2
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	04c080e7          	jalr	76(ra) # 8000384a <iunlock>
  end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	9c2080e7          	jalr	-1598(ra) # 800041c8 <end_op>

  return fd;
}
    8000580e:	8526                	mv	a0,s1
    80005810:	70ea                	ld	ra,184(sp)
    80005812:	744a                	ld	s0,176(sp)
    80005814:	74aa                	ld	s1,168(sp)
    80005816:	790a                	ld	s2,160(sp)
    80005818:	69ea                	ld	s3,152(sp)
    8000581a:	6129                	addi	sp,sp,192
    8000581c:	8082                	ret
      end_op();
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	9aa080e7          	jalr	-1622(ra) # 800041c8 <end_op>
      return -1;
    80005826:	b7e5                	j	8000580e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005828:	f5040513          	addi	a0,s0,-176
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	710080e7          	jalr	1808(ra) # 80003f3c <namei>
    80005834:	892a                	mv	s2,a0
    80005836:	c905                	beqz	a0,80005866 <sys_open+0x13c>
    ilock(ip);
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	f50080e7          	jalr	-176(ra) # 80003788 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005840:	04491703          	lh	a4,68(s2)
    80005844:	4785                	li	a5,1
    80005846:	f4f712e3          	bne	a4,a5,8000578a <sys_open+0x60>
    8000584a:	f4c42783          	lw	a5,-180(s0)
    8000584e:	dba1                	beqz	a5,8000579e <sys_open+0x74>
      iunlockput(ip);
    80005850:	854a                	mv	a0,s2
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	198080e7          	jalr	408(ra) # 800039ea <iunlockput>
      end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	96e080e7          	jalr	-1682(ra) # 800041c8 <end_op>
      return -1;
    80005862:	54fd                	li	s1,-1
    80005864:	b76d                	j	8000580e <sys_open+0xe4>
      end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	962080e7          	jalr	-1694(ra) # 800041c8 <end_op>
      return -1;
    8000586e:	54fd                	li	s1,-1
    80005870:	bf79                	j	8000580e <sys_open+0xe4>
    iunlockput(ip);
    80005872:	854a                	mv	a0,s2
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	176080e7          	jalr	374(ra) # 800039ea <iunlockput>
    end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	94c080e7          	jalr	-1716(ra) # 800041c8 <end_op>
    return -1;
    80005884:	54fd                	li	s1,-1
    80005886:	b761                	j	8000580e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005888:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000588c:	04691783          	lh	a5,70(s2)
    80005890:	02f99223          	sh	a5,36(s3)
    80005894:	bf2d                	j	800057ce <sys_open+0xa4>
    itrunc(ip);
    80005896:	854a                	mv	a0,s2
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	ffe080e7          	jalr	-2(ra) # 80003896 <itrunc>
    800058a0:	bfb1                	j	800057fc <sys_open+0xd2>
      fileclose(f);
    800058a2:	854e                	mv	a0,s3
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	d76080e7          	jalr	-650(ra) # 8000461a <fileclose>
    iunlockput(ip);
    800058ac:	854a                	mv	a0,s2
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	13c080e7          	jalr	316(ra) # 800039ea <iunlockput>
    end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	912080e7          	jalr	-1774(ra) # 800041c8 <end_op>
    return -1;
    800058be:	54fd                	li	s1,-1
    800058c0:	b7b9                	j	8000580e <sys_open+0xe4>

00000000800058c2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058c2:	7175                	addi	sp,sp,-144
    800058c4:	e506                	sd	ra,136(sp)
    800058c6:	e122                	sd	s0,128(sp)
    800058c8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	87e080e7          	jalr	-1922(ra) # 80004148 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058d2:	08000613          	li	a2,128
    800058d6:	f7040593          	addi	a1,s0,-144
    800058da:	4501                	li	a0,0
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	380080e7          	jalr	896(ra) # 80002c5c <argstr>
    800058e4:	02054963          	bltz	a0,80005916 <sys_mkdir+0x54>
    800058e8:	4681                	li	a3,0
    800058ea:	4601                	li	a2,0
    800058ec:	4585                	li	a1,1
    800058ee:	f7040513          	addi	a0,s0,-144
    800058f2:	00000097          	auipc	ra,0x0
    800058f6:	800080e7          	jalr	-2048(ra) # 800050f2 <create>
    800058fa:	cd11                	beqz	a0,80005916 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	0ee080e7          	jalr	238(ra) # 800039ea <iunlockput>
  end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	8c4080e7          	jalr	-1852(ra) # 800041c8 <end_op>
  return 0;
    8000590c:	4501                	li	a0,0
}
    8000590e:	60aa                	ld	ra,136(sp)
    80005910:	640a                	ld	s0,128(sp)
    80005912:	6149                	addi	sp,sp,144
    80005914:	8082                	ret
    end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	8b2080e7          	jalr	-1870(ra) # 800041c8 <end_op>
    return -1;
    8000591e:	557d                	li	a0,-1
    80005920:	b7fd                	j	8000590e <sys_mkdir+0x4c>

0000000080005922 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005922:	7135                	addi	sp,sp,-160
    80005924:	ed06                	sd	ra,152(sp)
    80005926:	e922                	sd	s0,144(sp)
    80005928:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	81e080e7          	jalr	-2018(ra) # 80004148 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005932:	08000613          	li	a2,128
    80005936:	f7040593          	addi	a1,s0,-144
    8000593a:	4501                	li	a0,0
    8000593c:	ffffd097          	auipc	ra,0xffffd
    80005940:	320080e7          	jalr	800(ra) # 80002c5c <argstr>
    80005944:	04054a63          	bltz	a0,80005998 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005948:	f6c40593          	addi	a1,s0,-148
    8000594c:	4505                	li	a0,1
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	2ca080e7          	jalr	714(ra) # 80002c18 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005956:	04054163          	bltz	a0,80005998 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000595a:	f6840593          	addi	a1,s0,-152
    8000595e:	4509                	li	a0,2
    80005960:	ffffd097          	auipc	ra,0xffffd
    80005964:	2b8080e7          	jalr	696(ra) # 80002c18 <argint>
     argint(1, &major) < 0 ||
    80005968:	02054863          	bltz	a0,80005998 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000596c:	f6841683          	lh	a3,-152(s0)
    80005970:	f6c41603          	lh	a2,-148(s0)
    80005974:	458d                	li	a1,3
    80005976:	f7040513          	addi	a0,s0,-144
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	778080e7          	jalr	1912(ra) # 800050f2 <create>
     argint(2, &minor) < 0 ||
    80005982:	c919                	beqz	a0,80005998 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	066080e7          	jalr	102(ra) # 800039ea <iunlockput>
  end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	83c080e7          	jalr	-1988(ra) # 800041c8 <end_op>
  return 0;
    80005994:	4501                	li	a0,0
    80005996:	a031                	j	800059a2 <sys_mknod+0x80>
    end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	830080e7          	jalr	-2000(ra) # 800041c8 <end_op>
    return -1;
    800059a0:	557d                	li	a0,-1
}
    800059a2:	60ea                	ld	ra,152(sp)
    800059a4:	644a                	ld	s0,144(sp)
    800059a6:	610d                	addi	sp,sp,160
    800059a8:	8082                	ret

00000000800059aa <sys_chdir>:

uint64
sys_chdir(void)
{
    800059aa:	7135                	addi	sp,sp,-160
    800059ac:	ed06                	sd	ra,152(sp)
    800059ae:	e922                	sd	s0,144(sp)
    800059b0:	e526                	sd	s1,136(sp)
    800059b2:	e14a                	sd	s2,128(sp)
    800059b4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059b6:	ffffc097          	auipc	ra,0xffffc
    800059ba:	10c080e7          	jalr	268(ra) # 80001ac2 <myproc>
    800059be:	892a                	mv	s2,a0
  
  begin_op();
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	788080e7          	jalr	1928(ra) # 80004148 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059c8:	08000613          	li	a2,128
    800059cc:	f6040593          	addi	a1,s0,-160
    800059d0:	4501                	li	a0,0
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	28a080e7          	jalr	650(ra) # 80002c5c <argstr>
    800059da:	04054b63          	bltz	a0,80005a30 <sys_chdir+0x86>
    800059de:	f6040513          	addi	a0,s0,-160
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	55a080e7          	jalr	1370(ra) # 80003f3c <namei>
    800059ea:	84aa                	mv	s1,a0
    800059ec:	c131                	beqz	a0,80005a30 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	d9a080e7          	jalr	-614(ra) # 80003788 <ilock>
  if(ip->type != T_DIR){
    800059f6:	04449703          	lh	a4,68(s1)
    800059fa:	4785                	li	a5,1
    800059fc:	04f71063          	bne	a4,a5,80005a3c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a00:	8526                	mv	a0,s1
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	e48080e7          	jalr	-440(ra) # 8000384a <iunlock>
  iput(p->cwd);
    80005a0a:	15093503          	ld	a0,336(s2)
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	f34080e7          	jalr	-204(ra) # 80003942 <iput>
  end_op();
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	7b2080e7          	jalr	1970(ra) # 800041c8 <end_op>
  p->cwd = ip;
    80005a1e:	14993823          	sd	s1,336(s2)
  return 0;
    80005a22:	4501                	li	a0,0
}
    80005a24:	60ea                	ld	ra,152(sp)
    80005a26:	644a                	ld	s0,144(sp)
    80005a28:	64aa                	ld	s1,136(sp)
    80005a2a:	690a                	ld	s2,128(sp)
    80005a2c:	610d                	addi	sp,sp,160
    80005a2e:	8082                	ret
    end_op();
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	798080e7          	jalr	1944(ra) # 800041c8 <end_op>
    return -1;
    80005a38:	557d                	li	a0,-1
    80005a3a:	b7ed                	j	80005a24 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a3c:	8526                	mv	a0,s1
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	fac080e7          	jalr	-84(ra) # 800039ea <iunlockput>
    end_op();
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	782080e7          	jalr	1922(ra) # 800041c8 <end_op>
    return -1;
    80005a4e:	557d                	li	a0,-1
    80005a50:	bfd1                	j	80005a24 <sys_chdir+0x7a>

0000000080005a52 <sys_exec>:

uint64
sys_exec(void)
{
    80005a52:	7145                	addi	sp,sp,-464
    80005a54:	e786                	sd	ra,456(sp)
    80005a56:	e3a2                	sd	s0,448(sp)
    80005a58:	ff26                	sd	s1,440(sp)
    80005a5a:	fb4a                	sd	s2,432(sp)
    80005a5c:	f74e                	sd	s3,424(sp)
    80005a5e:	f352                	sd	s4,416(sp)
    80005a60:	ef56                	sd	s5,408(sp)
    80005a62:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a64:	08000613          	li	a2,128
    80005a68:	f4040593          	addi	a1,s0,-192
    80005a6c:	4501                	li	a0,0
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	1ee080e7          	jalr	494(ra) # 80002c5c <argstr>
    return -1;
    80005a76:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a78:	0c054a63          	bltz	a0,80005b4c <sys_exec+0xfa>
    80005a7c:	e3840593          	addi	a1,s0,-456
    80005a80:	4505                	li	a0,1
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	1b8080e7          	jalr	440(ra) # 80002c3a <argaddr>
    80005a8a:	0c054163          	bltz	a0,80005b4c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a8e:	10000613          	li	a2,256
    80005a92:	4581                	li	a1,0
    80005a94:	e4040513          	addi	a0,s0,-448
    80005a98:	ffffb097          	auipc	ra,0xffffb
    80005a9c:	2d4080e7          	jalr	724(ra) # 80000d6c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aa0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005aa4:	89a6                	mv	s3,s1
    80005aa6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aa8:	02000a13          	li	s4,32
    80005aac:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ab0:	00391793          	slli	a5,s2,0x3
    80005ab4:	e3040593          	addi	a1,s0,-464
    80005ab8:	e3843503          	ld	a0,-456(s0)
    80005abc:	953e                	add	a0,a0,a5
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	0c0080e7          	jalr	192(ra) # 80002b7e <fetchaddr>
    80005ac6:	02054a63          	bltz	a0,80005afa <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005aca:	e3043783          	ld	a5,-464(s0)
    80005ace:	c3b9                	beqz	a5,80005b14 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ad0:	ffffb097          	auipc	ra,0xffffb
    80005ad4:	07a080e7          	jalr	122(ra) # 80000b4a <kalloc>
    80005ad8:	85aa                	mv	a1,a0
    80005ada:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ade:	cd11                	beqz	a0,80005afa <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ae0:	6605                	lui	a2,0x1
    80005ae2:	e3043503          	ld	a0,-464(s0)
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	0ea080e7          	jalr	234(ra) # 80002bd0 <fetchstr>
    80005aee:	00054663          	bltz	a0,80005afa <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005af2:	0905                	addi	s2,s2,1
    80005af4:	09a1                	addi	s3,s3,8
    80005af6:	fb491be3          	bne	s2,s4,80005aac <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005afa:	10048913          	addi	s2,s1,256
    80005afe:	6088                	ld	a0,0(s1)
    80005b00:	c529                	beqz	a0,80005b4a <sys_exec+0xf8>
    kfree(argv[i]);
    80005b02:	ffffb097          	auipc	ra,0xffffb
    80005b06:	f10080e7          	jalr	-240(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b0a:	04a1                	addi	s1,s1,8
    80005b0c:	ff2499e3          	bne	s1,s2,80005afe <sys_exec+0xac>
  return -1;
    80005b10:	597d                	li	s2,-1
    80005b12:	a82d                	j	80005b4c <sys_exec+0xfa>
      argv[i] = 0;
    80005b14:	0a8e                	slli	s5,s5,0x3
    80005b16:	fc040793          	addi	a5,s0,-64
    80005b1a:	9abe                	add	s5,s5,a5
    80005b1c:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7fdb8e80>
  int ret = exec(path, argv);
    80005b20:	e4040593          	addi	a1,s0,-448
    80005b24:	f4040513          	addi	a0,s0,-192
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	178080e7          	jalr	376(ra) # 80004ca0 <exec>
    80005b30:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b32:	10048993          	addi	s3,s1,256
    80005b36:	6088                	ld	a0,0(s1)
    80005b38:	c911                	beqz	a0,80005b4c <sys_exec+0xfa>
    kfree(argv[i]);
    80005b3a:	ffffb097          	auipc	ra,0xffffb
    80005b3e:	ed8080e7          	jalr	-296(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b42:	04a1                	addi	s1,s1,8
    80005b44:	ff3499e3          	bne	s1,s3,80005b36 <sys_exec+0xe4>
    80005b48:	a011                	j	80005b4c <sys_exec+0xfa>
  return -1;
    80005b4a:	597d                	li	s2,-1
}
    80005b4c:	854a                	mv	a0,s2
    80005b4e:	60be                	ld	ra,456(sp)
    80005b50:	641e                	ld	s0,448(sp)
    80005b52:	74fa                	ld	s1,440(sp)
    80005b54:	795a                	ld	s2,432(sp)
    80005b56:	79ba                	ld	s3,424(sp)
    80005b58:	7a1a                	ld	s4,416(sp)
    80005b5a:	6afa                	ld	s5,408(sp)
    80005b5c:	6179                	addi	sp,sp,464
    80005b5e:	8082                	ret

0000000080005b60 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b60:	7139                	addi	sp,sp,-64
    80005b62:	fc06                	sd	ra,56(sp)
    80005b64:	f822                	sd	s0,48(sp)
    80005b66:	f426                	sd	s1,40(sp)
    80005b68:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b6a:	ffffc097          	auipc	ra,0xffffc
    80005b6e:	f58080e7          	jalr	-168(ra) # 80001ac2 <myproc>
    80005b72:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b74:	fd840593          	addi	a1,s0,-40
    80005b78:	4501                	li	a0,0
    80005b7a:	ffffd097          	auipc	ra,0xffffd
    80005b7e:	0c0080e7          	jalr	192(ra) # 80002c3a <argaddr>
    return -1;
    80005b82:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b84:	0e054063          	bltz	a0,80005c64 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b88:	fc840593          	addi	a1,s0,-56
    80005b8c:	fd040513          	addi	a0,s0,-48
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	de0080e7          	jalr	-544(ra) # 80004970 <pipealloc>
    return -1;
    80005b98:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b9a:	0c054563          	bltz	a0,80005c64 <sys_pipe+0x104>
  fd0 = -1;
    80005b9e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ba2:	fd043503          	ld	a0,-48(s0)
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	50a080e7          	jalr	1290(ra) # 800050b0 <fdalloc>
    80005bae:	fca42223          	sw	a0,-60(s0)
    80005bb2:	08054c63          	bltz	a0,80005c4a <sys_pipe+0xea>
    80005bb6:	fc843503          	ld	a0,-56(s0)
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	4f6080e7          	jalr	1270(ra) # 800050b0 <fdalloc>
    80005bc2:	fca42023          	sw	a0,-64(s0)
    80005bc6:	06054863          	bltz	a0,80005c36 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bca:	4691                	li	a3,4
    80005bcc:	fc440613          	addi	a2,s0,-60
    80005bd0:	fd843583          	ld	a1,-40(s0)
    80005bd4:	68a8                	ld	a0,80(s1)
    80005bd6:	ffffc097          	auipc	ra,0xffffc
    80005bda:	b50080e7          	jalr	-1200(ra) # 80001726 <copyout>
    80005bde:	02054063          	bltz	a0,80005bfe <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005be2:	4691                	li	a3,4
    80005be4:	fc040613          	addi	a2,s0,-64
    80005be8:	fd843583          	ld	a1,-40(s0)
    80005bec:	0591                	addi	a1,a1,4
    80005bee:	68a8                	ld	a0,80(s1)
    80005bf0:	ffffc097          	auipc	ra,0xffffc
    80005bf4:	b36080e7          	jalr	-1226(ra) # 80001726 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bf8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bfa:	06055563          	bgez	a0,80005c64 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bfe:	fc442783          	lw	a5,-60(s0)
    80005c02:	07e9                	addi	a5,a5,26
    80005c04:	078e                	slli	a5,a5,0x3
    80005c06:	97a6                	add	a5,a5,s1
    80005c08:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c0c:	fc042503          	lw	a0,-64(s0)
    80005c10:	0569                	addi	a0,a0,26
    80005c12:	050e                	slli	a0,a0,0x3
    80005c14:	9526                	add	a0,a0,s1
    80005c16:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c1a:	fd043503          	ld	a0,-48(s0)
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	9fc080e7          	jalr	-1540(ra) # 8000461a <fileclose>
    fileclose(wf);
    80005c26:	fc843503          	ld	a0,-56(s0)
    80005c2a:	fffff097          	auipc	ra,0xfffff
    80005c2e:	9f0080e7          	jalr	-1552(ra) # 8000461a <fileclose>
    return -1;
    80005c32:	57fd                	li	a5,-1
    80005c34:	a805                	j	80005c64 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c36:	fc442783          	lw	a5,-60(s0)
    80005c3a:	0007c863          	bltz	a5,80005c4a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c3e:	01a78513          	addi	a0,a5,26
    80005c42:	050e                	slli	a0,a0,0x3
    80005c44:	9526                	add	a0,a0,s1
    80005c46:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c4a:	fd043503          	ld	a0,-48(s0)
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	9cc080e7          	jalr	-1588(ra) # 8000461a <fileclose>
    fileclose(wf);
    80005c56:	fc843503          	ld	a0,-56(s0)
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	9c0080e7          	jalr	-1600(ra) # 8000461a <fileclose>
    return -1;
    80005c62:	57fd                	li	a5,-1
}
    80005c64:	853e                	mv	a0,a5
    80005c66:	70e2                	ld	ra,56(sp)
    80005c68:	7442                	ld	s0,48(sp)
    80005c6a:	74a2                	ld	s1,40(sp)
    80005c6c:	6121                	addi	sp,sp,64
    80005c6e:	8082                	ret

0000000080005c70 <kernelvec>:
    80005c70:	7111                	addi	sp,sp,-256
    80005c72:	e006                	sd	ra,0(sp)
    80005c74:	e40a                	sd	sp,8(sp)
    80005c76:	e80e                	sd	gp,16(sp)
    80005c78:	ec12                	sd	tp,24(sp)
    80005c7a:	f016                	sd	t0,32(sp)
    80005c7c:	f41a                	sd	t1,40(sp)
    80005c7e:	f81e                	sd	t2,48(sp)
    80005c80:	fc22                	sd	s0,56(sp)
    80005c82:	e0a6                	sd	s1,64(sp)
    80005c84:	e4aa                	sd	a0,72(sp)
    80005c86:	e8ae                	sd	a1,80(sp)
    80005c88:	ecb2                	sd	a2,88(sp)
    80005c8a:	f0b6                	sd	a3,96(sp)
    80005c8c:	f4ba                	sd	a4,104(sp)
    80005c8e:	f8be                	sd	a5,112(sp)
    80005c90:	fcc2                	sd	a6,120(sp)
    80005c92:	e146                	sd	a7,128(sp)
    80005c94:	e54a                	sd	s2,136(sp)
    80005c96:	e94e                	sd	s3,144(sp)
    80005c98:	ed52                	sd	s4,152(sp)
    80005c9a:	f156                	sd	s5,160(sp)
    80005c9c:	f55a                	sd	s6,168(sp)
    80005c9e:	f95e                	sd	s7,176(sp)
    80005ca0:	fd62                	sd	s8,184(sp)
    80005ca2:	e1e6                	sd	s9,192(sp)
    80005ca4:	e5ea                	sd	s10,200(sp)
    80005ca6:	e9ee                	sd	s11,208(sp)
    80005ca8:	edf2                	sd	t3,216(sp)
    80005caa:	f1f6                	sd	t4,224(sp)
    80005cac:	f5fa                	sd	t5,232(sp)
    80005cae:	f9fe                	sd	t6,240(sp)
    80005cb0:	d9bfc0ef          	jal	ra,80002a4a <kerneltrap>
    80005cb4:	6082                	ld	ra,0(sp)
    80005cb6:	6122                	ld	sp,8(sp)
    80005cb8:	61c2                	ld	gp,16(sp)
    80005cba:	7282                	ld	t0,32(sp)
    80005cbc:	7322                	ld	t1,40(sp)
    80005cbe:	73c2                	ld	t2,48(sp)
    80005cc0:	7462                	ld	s0,56(sp)
    80005cc2:	6486                	ld	s1,64(sp)
    80005cc4:	6526                	ld	a0,72(sp)
    80005cc6:	65c6                	ld	a1,80(sp)
    80005cc8:	6666                	ld	a2,88(sp)
    80005cca:	7686                	ld	a3,96(sp)
    80005ccc:	7726                	ld	a4,104(sp)
    80005cce:	77c6                	ld	a5,112(sp)
    80005cd0:	7866                	ld	a6,120(sp)
    80005cd2:	688a                	ld	a7,128(sp)
    80005cd4:	692a                	ld	s2,136(sp)
    80005cd6:	69ca                	ld	s3,144(sp)
    80005cd8:	6a6a                	ld	s4,152(sp)
    80005cda:	7a8a                	ld	s5,160(sp)
    80005cdc:	7b2a                	ld	s6,168(sp)
    80005cde:	7bca                	ld	s7,176(sp)
    80005ce0:	7c6a                	ld	s8,184(sp)
    80005ce2:	6c8e                	ld	s9,192(sp)
    80005ce4:	6d2e                	ld	s10,200(sp)
    80005ce6:	6dce                	ld	s11,208(sp)
    80005ce8:	6e6e                	ld	t3,216(sp)
    80005cea:	7e8e                	ld	t4,224(sp)
    80005cec:	7f2e                	ld	t5,232(sp)
    80005cee:	7fce                	ld	t6,240(sp)
    80005cf0:	6111                	addi	sp,sp,256
    80005cf2:	10200073          	sret
    80005cf6:	00000013          	nop
    80005cfa:	00000013          	nop
    80005cfe:	0001                	nop

0000000080005d00 <timervec>:
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	e10c                	sd	a1,0(a0)
    80005d06:	e510                	sd	a2,8(a0)
    80005d08:	e914                	sd	a3,16(a0)
    80005d0a:	710c                	ld	a1,32(a0)
    80005d0c:	7510                	ld	a2,40(a0)
    80005d0e:	6194                	ld	a3,0(a1)
    80005d10:	96b2                	add	a3,a3,a2
    80005d12:	e194                	sd	a3,0(a1)
    80005d14:	4589                	li	a1,2
    80005d16:	14459073          	csrw	sip,a1
    80005d1a:	6914                	ld	a3,16(a0)
    80005d1c:	6510                	ld	a2,8(a0)
    80005d1e:	610c                	ld	a1,0(a0)
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	30200073          	mret
	...

0000000080005d2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d2a:	1141                	addi	sp,sp,-16
    80005d2c:	e422                	sd	s0,8(sp)
    80005d2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d30:	0c0007b7          	lui	a5,0xc000
    80005d34:	4705                	li	a4,1
    80005d36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d38:	c3d8                	sw	a4,4(a5)
}
    80005d3a:	6422                	ld	s0,8(sp)
    80005d3c:	0141                	addi	sp,sp,16
    80005d3e:	8082                	ret

0000000080005d40 <plicinithart>:

void
plicinithart(void)
{
    80005d40:	1141                	addi	sp,sp,-16
    80005d42:	e406                	sd	ra,8(sp)
    80005d44:	e022                	sd	s0,0(sp)
    80005d46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	d4e080e7          	jalr	-690(ra) # 80001a96 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d50:	0085171b          	slliw	a4,a0,0x8
    80005d54:	0c0027b7          	lui	a5,0xc002
    80005d58:	97ba                	add	a5,a5,a4
    80005d5a:	40200713          	li	a4,1026
    80005d5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d62:	00d5151b          	slliw	a0,a0,0xd
    80005d66:	0c2017b7          	lui	a5,0xc201
    80005d6a:	953e                	add	a0,a0,a5
    80005d6c:	00052023          	sw	zero,0(a0)
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret

0000000080005d78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d78:	1141                	addi	sp,sp,-16
    80005d7a:	e406                	sd	ra,8(sp)
    80005d7c:	e022                	sd	s0,0(sp)
    80005d7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	d16080e7          	jalr	-746(ra) # 80001a96 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d88:	00d5179b          	slliw	a5,a0,0xd
    80005d8c:	0c201537          	lui	a0,0xc201
    80005d90:	953e                	add	a0,a0,a5
  return irq;
}
    80005d92:	4148                	lw	a0,4(a0)
    80005d94:	60a2                	ld	ra,8(sp)
    80005d96:	6402                	ld	s0,0(sp)
    80005d98:	0141                	addi	sp,sp,16
    80005d9a:	8082                	ret

0000000080005d9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d9c:	1101                	addi	sp,sp,-32
    80005d9e:	ec06                	sd	ra,24(sp)
    80005da0:	e822                	sd	s0,16(sp)
    80005da2:	e426                	sd	s1,8(sp)
    80005da4:	1000                	addi	s0,sp,32
    80005da6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	cee080e7          	jalr	-786(ra) # 80001a96 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005db0:	00d5151b          	slliw	a0,a0,0xd
    80005db4:	0c2017b7          	lui	a5,0xc201
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	c3c4                	sw	s1,4(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dc6:	1141                	addi	sp,sp,-16
    80005dc8:	e406                	sd	ra,8(sp)
    80005dca:	e022                	sd	s0,0(sp)
    80005dcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dce:	479d                	li	a5,7
    80005dd0:	04a7cc63          	blt	a5,a0,80005e28 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005dd4:	0023d797          	auipc	a5,0x23d
    80005dd8:	22c78793          	addi	a5,a5,556 # 80243000 <disk>
    80005ddc:	00a78733          	add	a4,a5,a0
    80005de0:	6789                	lui	a5,0x2
    80005de2:	97ba                	add	a5,a5,a4
    80005de4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005de8:	eba1                	bnez	a5,80005e38 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005dea:	00451713          	slli	a4,a0,0x4
    80005dee:	0023f797          	auipc	a5,0x23f
    80005df2:	2127b783          	ld	a5,530(a5) # 80245000 <disk+0x2000>
    80005df6:	97ba                	add	a5,a5,a4
    80005df8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dfc:	0023d797          	auipc	a5,0x23d
    80005e00:	20478793          	addi	a5,a5,516 # 80243000 <disk>
    80005e04:	97aa                	add	a5,a5,a0
    80005e06:	6509                	lui	a0,0x2
    80005e08:	953e                	add	a0,a0,a5
    80005e0a:	4785                	li	a5,1
    80005e0c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e10:	0023f517          	auipc	a0,0x23f
    80005e14:	20850513          	addi	a0,a0,520 # 80245018 <disk+0x2018>
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	63e080e7          	jalr	1598(ra) # 80002456 <wakeup>
}
    80005e20:	60a2                	ld	ra,8(sp)
    80005e22:	6402                	ld	s0,0(sp)
    80005e24:	0141                	addi	sp,sp,16
    80005e26:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	93050513          	addi	a0,a0,-1744 # 80008758 <syscalls+0x330>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	712080e7          	jalr	1810(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005e38:	00003517          	auipc	a0,0x3
    80005e3c:	93850513          	addi	a0,a0,-1736 # 80008770 <syscalls+0x348>
    80005e40:	ffffa097          	auipc	ra,0xffffa
    80005e44:	702080e7          	jalr	1794(ra) # 80000542 <panic>

0000000080005e48 <virtio_disk_init>:
{
    80005e48:	1101                	addi	sp,sp,-32
    80005e4a:	ec06                	sd	ra,24(sp)
    80005e4c:	e822                	sd	s0,16(sp)
    80005e4e:	e426                	sd	s1,8(sp)
    80005e50:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e52:	00003597          	auipc	a1,0x3
    80005e56:	93658593          	addi	a1,a1,-1738 # 80008788 <syscalls+0x360>
    80005e5a:	0023f517          	auipc	a0,0x23f
    80005e5e:	24e50513          	addi	a0,a0,590 # 802450a8 <disk+0x20a8>
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	d7e080e7          	jalr	-642(ra) # 80000be0 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e6a:	100017b7          	lui	a5,0x10001
    80005e6e:	4398                	lw	a4,0(a5)
    80005e70:	2701                	sext.w	a4,a4
    80005e72:	747277b7          	lui	a5,0x74727
    80005e76:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e7a:	0ef71163          	bne	a4,a5,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	43dc                	lw	a5,4(a5)
    80005e84:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e86:	4705                	li	a4,1
    80005e88:	0ce79a63          	bne	a5,a4,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	479c                	lw	a5,8(a5)
    80005e92:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e94:	4709                	li	a4,2
    80005e96:	0ce79363          	bne	a5,a4,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e9a:	100017b7          	lui	a5,0x10001
    80005e9e:	47d8                	lw	a4,12(a5)
    80005ea0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ea2:	554d47b7          	lui	a5,0x554d4
    80005ea6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eaa:	0af71963          	bne	a4,a5,80005f5c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	4705                	li	a4,1
    80005eb4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb6:	470d                	li	a4,3
    80005eb8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ebc:	c7ffe737          	lui	a4,0xc7ffe
    80005ec0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47db875f>
    80005ec4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ec6:	2701                	sext.w	a4,a4
    80005ec8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eca:	472d                	li	a4,11
    80005ecc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	473d                	li	a4,15
    80005ed0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ed2:	6705                	lui	a4,0x1
    80005ed4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ed6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eda:	5bdc                	lw	a5,52(a5)
    80005edc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ede:	c7d9                	beqz	a5,80005f6c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ee0:	471d                	li	a4,7
    80005ee2:	08f77d63          	bgeu	a4,a5,80005f7c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ee6:	100014b7          	lui	s1,0x10001
    80005eea:	47a1                	li	a5,8
    80005eec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005eee:	6609                	lui	a2,0x2
    80005ef0:	4581                	li	a1,0
    80005ef2:	0023d517          	auipc	a0,0x23d
    80005ef6:	10e50513          	addi	a0,a0,270 # 80243000 <disk>
    80005efa:	ffffb097          	auipc	ra,0xffffb
    80005efe:	e72080e7          	jalr	-398(ra) # 80000d6c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f02:	0023d717          	auipc	a4,0x23d
    80005f06:	0fe70713          	addi	a4,a4,254 # 80243000 <disk>
    80005f0a:	00c75793          	srli	a5,a4,0xc
    80005f0e:	2781                	sext.w	a5,a5
    80005f10:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f12:	0023f797          	auipc	a5,0x23f
    80005f16:	0ee78793          	addi	a5,a5,238 # 80245000 <disk+0x2000>
    80005f1a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f1c:	0023d717          	auipc	a4,0x23d
    80005f20:	16470713          	addi	a4,a4,356 # 80243080 <disk+0x80>
    80005f24:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f26:	0023e717          	auipc	a4,0x23e
    80005f2a:	0da70713          	addi	a4,a4,218 # 80244000 <disk+0x1000>
    80005f2e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f30:	4705                	li	a4,1
    80005f32:	00e78c23          	sb	a4,24(a5)
    80005f36:	00e78ca3          	sb	a4,25(a5)
    80005f3a:	00e78d23          	sb	a4,26(a5)
    80005f3e:	00e78da3          	sb	a4,27(a5)
    80005f42:	00e78e23          	sb	a4,28(a5)
    80005f46:	00e78ea3          	sb	a4,29(a5)
    80005f4a:	00e78f23          	sb	a4,30(a5)
    80005f4e:	00e78fa3          	sb	a4,31(a5)
}
    80005f52:	60e2                	ld	ra,24(sp)
    80005f54:	6442                	ld	s0,16(sp)
    80005f56:	64a2                	ld	s1,8(sp)
    80005f58:	6105                	addi	sp,sp,32
    80005f5a:	8082                	ret
    panic("could not find virtio disk");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	83c50513          	addi	a0,a0,-1988 # 80008798 <syscalls+0x370>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	5de080e7          	jalr	1502(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    80005f6c:	00003517          	auipc	a0,0x3
    80005f70:	84c50513          	addi	a0,a0,-1972 # 800087b8 <syscalls+0x390>
    80005f74:	ffffa097          	auipc	ra,0xffffa
    80005f78:	5ce080e7          	jalr	1486(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    80005f7c:	00003517          	auipc	a0,0x3
    80005f80:	85c50513          	addi	a0,a0,-1956 # 800087d8 <syscalls+0x3b0>
    80005f84:	ffffa097          	auipc	ra,0xffffa
    80005f88:	5be080e7          	jalr	1470(ra) # 80000542 <panic>

0000000080005f8c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f8c:	7175                	addi	sp,sp,-144
    80005f8e:	e506                	sd	ra,136(sp)
    80005f90:	e122                	sd	s0,128(sp)
    80005f92:	fca6                	sd	s1,120(sp)
    80005f94:	f8ca                	sd	s2,112(sp)
    80005f96:	f4ce                	sd	s3,104(sp)
    80005f98:	f0d2                	sd	s4,96(sp)
    80005f9a:	ecd6                	sd	s5,88(sp)
    80005f9c:	e8da                	sd	s6,80(sp)
    80005f9e:	e4de                	sd	s7,72(sp)
    80005fa0:	e0e2                	sd	s8,64(sp)
    80005fa2:	fc66                	sd	s9,56(sp)
    80005fa4:	f86a                	sd	s10,48(sp)
    80005fa6:	f46e                	sd	s11,40(sp)
    80005fa8:	0900                	addi	s0,sp,144
    80005faa:	8aaa                	mv	s5,a0
    80005fac:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fae:	00c52c83          	lw	s9,12(a0)
    80005fb2:	001c9c9b          	slliw	s9,s9,0x1
    80005fb6:	1c82                	slli	s9,s9,0x20
    80005fb8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fbc:	0023f517          	auipc	a0,0x23f
    80005fc0:	0ec50513          	addi	a0,a0,236 # 802450a8 <disk+0x20a8>
    80005fc4:	ffffb097          	auipc	ra,0xffffb
    80005fc8:	cac080e7          	jalr	-852(ra) # 80000c70 <acquire>
  for(int i = 0; i < 3; i++){
    80005fcc:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fce:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005fd0:	0023dc17          	auipc	s8,0x23d
    80005fd4:	030c0c13          	addi	s8,s8,48 # 80243000 <disk>
    80005fd8:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005fda:	4b0d                	li	s6,3
    80005fdc:	a0ad                	j	80006046 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005fde:	00fc0733          	add	a4,s8,a5
    80005fe2:	975e                	add	a4,a4,s7
    80005fe4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005fe8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005fea:	0207c563          	bltz	a5,80006014 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fee:	2905                	addiw	s2,s2,1
    80005ff0:	0611                	addi	a2,a2,4
    80005ff2:	19690d63          	beq	s2,s6,8000618c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005ff6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005ff8:	0023f717          	auipc	a4,0x23f
    80005ffc:	02070713          	addi	a4,a4,32 # 80245018 <disk+0x2018>
    80006000:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006002:	00074683          	lbu	a3,0(a4)
    80006006:	fee1                	bnez	a3,80005fde <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006008:	2785                	addiw	a5,a5,1
    8000600a:	0705                	addi	a4,a4,1
    8000600c:	fe979be3          	bne	a5,s1,80006002 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006010:	57fd                	li	a5,-1
    80006012:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006014:	01205d63          	blez	s2,8000602e <virtio_disk_rw+0xa2>
    80006018:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000601a:	000a2503          	lw	a0,0(s4)
    8000601e:	00000097          	auipc	ra,0x0
    80006022:	da8080e7          	jalr	-600(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006026:	2d85                	addiw	s11,s11,1
    80006028:	0a11                	addi	s4,s4,4
    8000602a:	ffb918e3          	bne	s2,s11,8000601a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000602e:	0023f597          	auipc	a1,0x23f
    80006032:	07a58593          	addi	a1,a1,122 # 802450a8 <disk+0x20a8>
    80006036:	0023f517          	auipc	a0,0x23f
    8000603a:	fe250513          	addi	a0,a0,-30 # 80245018 <disk+0x2018>
    8000603e:	ffffc097          	auipc	ra,0xffffc
    80006042:	298080e7          	jalr	664(ra) # 800022d6 <sleep>
  for(int i = 0; i < 3; i++){
    80006046:	f8040a13          	addi	s4,s0,-128
{
    8000604a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000604c:	894e                	mv	s2,s3
    8000604e:	b765                	j	80005ff6 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006050:	0023f717          	auipc	a4,0x23f
    80006054:	fb073703          	ld	a4,-80(a4) # 80245000 <disk+0x2000>
    80006058:	973e                	add	a4,a4,a5
    8000605a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000605e:	0023d517          	auipc	a0,0x23d
    80006062:	fa250513          	addi	a0,a0,-94 # 80243000 <disk>
    80006066:	0023f717          	auipc	a4,0x23f
    8000606a:	f9a70713          	addi	a4,a4,-102 # 80245000 <disk+0x2000>
    8000606e:	6314                	ld	a3,0(a4)
    80006070:	96be                	add	a3,a3,a5
    80006072:	00c6d603          	lhu	a2,12(a3)
    80006076:	00166613          	ori	a2,a2,1
    8000607a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000607e:	f8842683          	lw	a3,-120(s0)
    80006082:	6310                	ld	a2,0(a4)
    80006084:	97b2                	add	a5,a5,a2
    80006086:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000608a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000608e:	0612                	slli	a2,a2,0x4
    80006090:	962a                	add	a2,a2,a0
    80006092:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006096:	00469793          	slli	a5,a3,0x4
    8000609a:	630c                	ld	a1,0(a4)
    8000609c:	95be                	add	a1,a1,a5
    8000609e:	6689                	lui	a3,0x2
    800060a0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800060a4:	96ca                	add	a3,a3,s2
    800060a6:	96aa                	add	a3,a3,a0
    800060a8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800060aa:	6314                	ld	a3,0(a4)
    800060ac:	96be                	add	a3,a3,a5
    800060ae:	4585                	li	a1,1
    800060b0:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060b2:	6314                	ld	a3,0(a4)
    800060b4:	96be                	add	a3,a3,a5
    800060b6:	4509                	li	a0,2
    800060b8:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800060bc:	6314                	ld	a3,0(a4)
    800060be:	97b6                	add	a5,a5,a3
    800060c0:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060c4:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800060c8:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800060cc:	6714                	ld	a3,8(a4)
    800060ce:	0026d783          	lhu	a5,2(a3)
    800060d2:	8b9d                	andi	a5,a5,7
    800060d4:	0789                	addi	a5,a5,2
    800060d6:	0786                	slli	a5,a5,0x1
    800060d8:	97b6                	add	a5,a5,a3
    800060da:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800060de:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800060e2:	6718                	ld	a4,8(a4)
    800060e4:	00275783          	lhu	a5,2(a4)
    800060e8:	2785                	addiw	a5,a5,1
    800060ea:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060ee:	100017b7          	lui	a5,0x10001
    800060f2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060f6:	004aa783          	lw	a5,4(s5)
    800060fa:	02b79163          	bne	a5,a1,8000611c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800060fe:	0023f917          	auipc	s2,0x23f
    80006102:	faa90913          	addi	s2,s2,-86 # 802450a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006106:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006108:	85ca                	mv	a1,s2
    8000610a:	8556                	mv	a0,s5
    8000610c:	ffffc097          	auipc	ra,0xffffc
    80006110:	1ca080e7          	jalr	458(ra) # 800022d6 <sleep>
  while(b->disk == 1) {
    80006114:	004aa783          	lw	a5,4(s5)
    80006118:	fe9788e3          	beq	a5,s1,80006108 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000611c:	f8042483          	lw	s1,-128(s0)
    80006120:	20048793          	addi	a5,s1,512
    80006124:	00479713          	slli	a4,a5,0x4
    80006128:	0023d797          	auipc	a5,0x23d
    8000612c:	ed878793          	addi	a5,a5,-296 # 80243000 <disk>
    80006130:	97ba                	add	a5,a5,a4
    80006132:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006136:	0023f917          	auipc	s2,0x23f
    8000613a:	eca90913          	addi	s2,s2,-310 # 80245000 <disk+0x2000>
    8000613e:	a019                	j	80006144 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006140:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006144:	8526                	mv	a0,s1
    80006146:	00000097          	auipc	ra,0x0
    8000614a:	c80080e7          	jalr	-896(ra) # 80005dc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000614e:	0492                	slli	s1,s1,0x4
    80006150:	00093783          	ld	a5,0(s2)
    80006154:	94be                	add	s1,s1,a5
    80006156:	00c4d783          	lhu	a5,12(s1)
    8000615a:	8b85                	andi	a5,a5,1
    8000615c:	f3f5                	bnez	a5,80006140 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000615e:	0023f517          	auipc	a0,0x23f
    80006162:	f4a50513          	addi	a0,a0,-182 # 802450a8 <disk+0x20a8>
    80006166:	ffffb097          	auipc	ra,0xffffb
    8000616a:	bbe080e7          	jalr	-1090(ra) # 80000d24 <release>
}
    8000616e:	60aa                	ld	ra,136(sp)
    80006170:	640a                	ld	s0,128(sp)
    80006172:	74e6                	ld	s1,120(sp)
    80006174:	7946                	ld	s2,112(sp)
    80006176:	79a6                	ld	s3,104(sp)
    80006178:	7a06                	ld	s4,96(sp)
    8000617a:	6ae6                	ld	s5,88(sp)
    8000617c:	6b46                	ld	s6,80(sp)
    8000617e:	6ba6                	ld	s7,72(sp)
    80006180:	6c06                	ld	s8,64(sp)
    80006182:	7ce2                	ld	s9,56(sp)
    80006184:	7d42                	ld	s10,48(sp)
    80006186:	7da2                	ld	s11,40(sp)
    80006188:	6149                	addi	sp,sp,144
    8000618a:	8082                	ret
  if(write)
    8000618c:	01a037b3          	snez	a5,s10
    80006190:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006194:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006198:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000619c:	f8042483          	lw	s1,-128(s0)
    800061a0:	00449913          	slli	s2,s1,0x4
    800061a4:	0023f997          	auipc	s3,0x23f
    800061a8:	e5c98993          	addi	s3,s3,-420 # 80245000 <disk+0x2000>
    800061ac:	0009ba03          	ld	s4,0(s3)
    800061b0:	9a4a                	add	s4,s4,s2
    800061b2:	f7040513          	addi	a0,s0,-144
    800061b6:	ffffb097          	auipc	ra,0xffffb
    800061ba:	f86080e7          	jalr	-122(ra) # 8000113c <kvmpa>
    800061be:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800061c2:	0009b783          	ld	a5,0(s3)
    800061c6:	97ca                	add	a5,a5,s2
    800061c8:	4741                	li	a4,16
    800061ca:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061cc:	0009b783          	ld	a5,0(s3)
    800061d0:	97ca                	add	a5,a5,s2
    800061d2:	4705                	li	a4,1
    800061d4:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800061d8:	f8442783          	lw	a5,-124(s0)
    800061dc:	0009b703          	ld	a4,0(s3)
    800061e0:	974a                	add	a4,a4,s2
    800061e2:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    800061e6:	0792                	slli	a5,a5,0x4
    800061e8:	0009b703          	ld	a4,0(s3)
    800061ec:	973e                	add	a4,a4,a5
    800061ee:	058a8693          	addi	a3,s5,88
    800061f2:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    800061f4:	0009b703          	ld	a4,0(s3)
    800061f8:	973e                	add	a4,a4,a5
    800061fa:	40000693          	li	a3,1024
    800061fe:	c714                	sw	a3,8(a4)
  if(write)
    80006200:	e40d18e3          	bnez	s10,80006050 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006204:	0023f717          	auipc	a4,0x23f
    80006208:	dfc73703          	ld	a4,-516(a4) # 80245000 <disk+0x2000>
    8000620c:	973e                	add	a4,a4,a5
    8000620e:	4689                	li	a3,2
    80006210:	00d71623          	sh	a3,12(a4)
    80006214:	b5a9                	j	8000605e <virtio_disk_rw+0xd2>

0000000080006216 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006216:	1101                	addi	sp,sp,-32
    80006218:	ec06                	sd	ra,24(sp)
    8000621a:	e822                	sd	s0,16(sp)
    8000621c:	e426                	sd	s1,8(sp)
    8000621e:	e04a                	sd	s2,0(sp)
    80006220:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006222:	0023f517          	auipc	a0,0x23f
    80006226:	e8650513          	addi	a0,a0,-378 # 802450a8 <disk+0x20a8>
    8000622a:	ffffb097          	auipc	ra,0xffffb
    8000622e:	a46080e7          	jalr	-1466(ra) # 80000c70 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006232:	0023f717          	auipc	a4,0x23f
    80006236:	dce70713          	addi	a4,a4,-562 # 80245000 <disk+0x2000>
    8000623a:	02075783          	lhu	a5,32(a4)
    8000623e:	6b18                	ld	a4,16(a4)
    80006240:	00275683          	lhu	a3,2(a4)
    80006244:	8ebd                	xor	a3,a3,a5
    80006246:	8a9d                	andi	a3,a3,7
    80006248:	cab9                	beqz	a3,8000629e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000624a:	0023d917          	auipc	s2,0x23d
    8000624e:	db690913          	addi	s2,s2,-586 # 80243000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006252:	0023f497          	auipc	s1,0x23f
    80006256:	dae48493          	addi	s1,s1,-594 # 80245000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000625a:	078e                	slli	a5,a5,0x3
    8000625c:	97ba                	add	a5,a5,a4
    8000625e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006260:	20078713          	addi	a4,a5,512
    80006264:	0712                	slli	a4,a4,0x4
    80006266:	974a                	add	a4,a4,s2
    80006268:	03074703          	lbu	a4,48(a4)
    8000626c:	ef21                	bnez	a4,800062c4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000626e:	20078793          	addi	a5,a5,512
    80006272:	0792                	slli	a5,a5,0x4
    80006274:	97ca                	add	a5,a5,s2
    80006276:	7798                	ld	a4,40(a5)
    80006278:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000627c:	7788                	ld	a0,40(a5)
    8000627e:	ffffc097          	auipc	ra,0xffffc
    80006282:	1d8080e7          	jalr	472(ra) # 80002456 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006286:	0204d783          	lhu	a5,32(s1)
    8000628a:	2785                	addiw	a5,a5,1
    8000628c:	8b9d                	andi	a5,a5,7
    8000628e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006292:	6898                	ld	a4,16(s1)
    80006294:	00275683          	lhu	a3,2(a4)
    80006298:	8a9d                	andi	a3,a3,7
    8000629a:	fcf690e3          	bne	a3,a5,8000625a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000629e:	10001737          	lui	a4,0x10001
    800062a2:	533c                	lw	a5,96(a4)
    800062a4:	8b8d                	andi	a5,a5,3
    800062a6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062a8:	0023f517          	auipc	a0,0x23f
    800062ac:	e0050513          	addi	a0,a0,-512 # 802450a8 <disk+0x20a8>
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	a74080e7          	jalr	-1420(ra) # 80000d24 <release>
}
    800062b8:	60e2                	ld	ra,24(sp)
    800062ba:	6442                	ld	s0,16(sp)
    800062bc:	64a2                	ld	s1,8(sp)
    800062be:	6902                	ld	s2,0(sp)
    800062c0:	6105                	addi	sp,sp,32
    800062c2:	8082                	ret
      panic("virtio_disk_intr status");
    800062c4:	00002517          	auipc	a0,0x2
    800062c8:	53450513          	addi	a0,a0,1332 # 800087f8 <syscalls+0x3d0>
    800062cc:	ffffa097          	auipc	ra,0xffffa
    800062d0:	276080e7          	jalr	630(ra) # 80000542 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
