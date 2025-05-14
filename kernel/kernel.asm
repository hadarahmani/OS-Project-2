
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8be70713          	addi	a4,a4,-1858 # 80008910 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	ccc78793          	addi	a5,a5,-820 # 80005d30 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc98f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	38e080e7          	jalr	910(ra) # 800024ba <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7f4080e7          	jalr	2036(ra) # 800019b4 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	13c080e7          	jalr	316(ra) # 80002304 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e86080e7          	jalr	-378(ra) # 8000205c <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	252080e7          	jalr	594(ra) # 80002464 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	21e080e7          	jalr	542(ra) # 80002510 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c7a080e7          	jalr	-902(ra) # 800020c0 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	77078793          	addi	a5,a5,1904 # 80020be8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5c07a323          	sw	zero,1478(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	34f72923          	sw	a5,850(a4) # 800088d0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	556dad83          	lw	s11,1366(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	50050513          	addi	a0,a0,1280 # 80010af8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3a250513          	addi	a0,a0,930 # 80010af8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	38648493          	addi	s1,s1,902 # 80010af8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	34650513          	addi	a0,a0,838 # 80010b18 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0d27a783          	lw	a5,210(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0a27b783          	ld	a5,162(a5) # 800088d8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0a273703          	ld	a4,162(a4) # 800088e0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2b8a0a13          	addi	s4,s4,696 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	07048493          	addi	s1,s1,112 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	07098993          	addi	s3,s3,112 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	82e080e7          	jalr	-2002(ra) # 800020c0 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	24a50513          	addi	a0,a0,586 # 80010b18 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	ff27a783          	lw	a5,-14(a5) # 800088d0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	ff873703          	ld	a4,-8(a4) # 800088e0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fe87b783          	ld	a5,-24(a5) # 800088d8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	21c98993          	addi	s3,s3,540 # 80010b18 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fd448493          	addi	s1,s1,-44 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fd490913          	addi	s2,s2,-44 # 800088e0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	740080e7          	jalr	1856(ra) # 8000205c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1e648493          	addi	s1,s1,486 # 80010b18 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f8e7bd23          	sd	a4,-102(a5) # 800088e0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	15c48493          	addi	s1,s1,348 # 80010b18 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00021797          	auipc	a5,0x21
    80000a02:	47278793          	addi	a5,a5,1138 # 80021e70 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	13290913          	addi	s2,s2,306 # 80010b50 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	3a250513          	addi	a0,a0,930 # 80021e70 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e28080e7          	jalr	-472(ra) # 80001998 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	df6080e7          	jalr	-522(ra) # 80001998 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	dea080e7          	jalr	-534(ra) # 80001998 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dd2080e7          	jalr	-558(ra) # 80001998 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d92080e7          	jalr	-622(ra) # 80001998 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d66080e7          	jalr	-666(ra) # 80001998 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b08080e7          	jalr	-1272(ra) # 80001988 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	aec080e7          	jalr	-1300(ra) # 80001988 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0e0080e7          	jalr	224(ra) # 80000f96 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	792080e7          	jalr	1938(ra) # 80002650 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	eaa080e7          	jalr	-342(ra) # 80005d70 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fdc080e7          	jalr	-36(ra) # 80001eaa <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	32e080e7          	jalr	814(ra) # 8000124c <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	070080e7          	jalr	112(ra) # 80000f96 <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	9a6080e7          	jalr	-1626(ra) # 800018d4 <procinit>
    petersoninit();
    80000f36:	00005097          	auipc	ra,0x5
    80000f3a:	416080e7          	jalr	1046(ra) # 8000634c <petersoninit>
    trapinit();      // trap vectors
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	6ea080e7          	jalr	1770(ra) # 80002628 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f46:	00001097          	auipc	ra,0x1
    80000f4a:	70a080e7          	jalr	1802(ra) # 80002650 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	e0c080e7          	jalr	-500(ra) # 80005d5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	e1a080e7          	jalr	-486(ra) # 80005d70 <plicinithart>
    binit();         // buffer cache
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	fba080e7          	jalr	-70(ra) # 80002f18 <binit>
    iinit();         // inode table
    80000f66:	00002097          	auipc	ra,0x2
    80000f6a:	65e080e7          	jalr	1630(ra) # 800035c4 <iinit>
    fileinit();      // file table
    80000f6e:	00003097          	auipc	ra,0x3
    80000f72:	5fc080e7          	jalr	1532(ra) # 8000456a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	f02080e7          	jalr	-254(ra) # 80005e78 <virtio_disk_init>
    userinit();      // first user process
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	d0e080e7          	jalr	-754(ra) # 80001c8c <userinit>
    __sync_synchronize();
    80000f86:	0ff0000f          	fence
    started = 1;
    80000f8a:	4785                	li	a5,1
    80000f8c:	00008717          	auipc	a4,0x8
    80000f90:	94f72e23          	sw	a5,-1700(a4) # 800088e8 <started>
    80000f94:	bf2d                	j	80000ece <main+0x56>

0000000080000f96 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f96:	1141                	addi	sp,sp,-16
    80000f98:	e422                	sd	s0,8(sp)
    80000f9a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	9507b783          	ld	a5,-1712(a5) # 800088f0 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	552080e7          	jalr	1362(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010bc:	c639                	beqz	a2,8000110a <mappages+0x64>
    800010be:	8aaa                	mv	s5,a0
    800010c0:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010c2:	77fd                	lui	a5,0xfffff
    800010c4:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c8:	15fd                	addi	a1,a1,-1
    800010ca:	00c589b3          	add	s3,a1,a2
    800010ce:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010d2:	8952                	mv	s2,s4
    800010d4:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d8:	6b85                	lui	s7,0x1
    800010da:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010de:	4605                	li	a2,1
    800010e0:	85ca                	mv	a1,s2
    800010e2:	8556                	mv	a0,s5
    800010e4:	00000097          	auipc	ra,0x0
    800010e8:	eda080e7          	jalr	-294(ra) # 80000fbe <walk>
    800010ec:	cd1d                	beqz	a0,8000112a <mappages+0x84>
    if(*pte & PTE_V)
    800010ee:	611c                	ld	a5,0(a0)
    800010f0:	8b85                	andi	a5,a5,1
    800010f2:	e785                	bnez	a5,8000111a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f4:	80b1                	srli	s1,s1,0xc
    800010f6:	04aa                	slli	s1,s1,0xa
    800010f8:	0164e4b3          	or	s1,s1,s6
    800010fc:	0014e493          	ori	s1,s1,1
    80001100:	e104                	sd	s1,0(a0)
    if(a == last)
    80001102:	05390063          	beq	s2,s3,80001142 <mappages+0x9c>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001108:	bfc9                	j	800010da <mappages+0x34>
    panic("mappages: size");
    8000110a:	00007517          	auipc	a0,0x7
    8000110e:	fce50513          	addi	a0,a0,-50 # 800080d8 <digits+0x98>
    80001112:	fffff097          	auipc	ra,0xfffff
    80001116:	42c080e7          	jalr	1068(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000111a:	00007517          	auipc	a0,0x7
    8000111e:	fce50513          	addi	a0,a0,-50 # 800080e8 <digits+0xa8>
    80001122:	fffff097          	auipc	ra,0xfffff
    80001126:	41c080e7          	jalr	1052(ra) # 8000053e <panic>
      return -1;
    8000112a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000112c:	60a6                	ld	ra,72(sp)
    8000112e:	6406                	ld	s0,64(sp)
    80001130:	74e2                	ld	s1,56(sp)
    80001132:	7942                	ld	s2,48(sp)
    80001134:	79a2                	ld	s3,40(sp)
    80001136:	7a02                	ld	s4,32(sp)
    80001138:	6ae2                	ld	s5,24(sp)
    8000113a:	6b42                	ld	s6,16(sp)
    8000113c:	6ba2                	ld	s7,8(sp)
    8000113e:	6161                	addi	sp,sp,80
    80001140:	8082                	ret
  return 0;
    80001142:	4501                	li	a0,0
    80001144:	b7e5                	j	8000112c <mappages+0x86>

0000000080001146 <kvmmap>:
{
    80001146:	1141                	addi	sp,sp,-16
    80001148:	e406                	sd	ra,8(sp)
    8000114a:	e022                	sd	s0,0(sp)
    8000114c:	0800                	addi	s0,sp,16
    8000114e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001150:	86b2                	mv	a3,a2
    80001152:	863e                	mv	a2,a5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	f52080e7          	jalr	-174(ra) # 800010a6 <mappages>
    8000115c:	e509                	bnez	a0,80001166 <kvmmap+0x20>
}
    8000115e:	60a2                	ld	ra,8(sp)
    80001160:	6402                	ld	s0,0(sp)
    80001162:	0141                	addi	sp,sp,16
    80001164:	8082                	ret
    panic("kvmmap");
    80001166:	00007517          	auipc	a0,0x7
    8000116a:	f9250513          	addi	a0,a0,-110 # 800080f8 <digits+0xb8>
    8000116e:	fffff097          	auipc	ra,0xfffff
    80001172:	3d0080e7          	jalr	976(ra) # 8000053e <panic>

0000000080001176 <kvmmake>:
{
    80001176:	1101                	addi	sp,sp,-32
    80001178:	ec06                	sd	ra,24(sp)
    8000117a:	e822                	sd	s0,16(sp)
    8000117c:	e426                	sd	s1,8(sp)
    8000117e:	e04a                	sd	s2,0(sp)
    80001180:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001182:	00000097          	auipc	ra,0x0
    80001186:	964080e7          	jalr	-1692(ra) # 80000ae6 <kalloc>
    8000118a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000118c:	6605                	lui	a2,0x1
    8000118e:	4581                	li	a1,0
    80001190:	00000097          	auipc	ra,0x0
    80001194:	b42080e7          	jalr	-1214(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001198:	4719                	li	a4,6
    8000119a:	6685                	lui	a3,0x1
    8000119c:	10000637          	lui	a2,0x10000
    800011a0:	100005b7          	lui	a1,0x10000
    800011a4:	8526                	mv	a0,s1
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	fa0080e7          	jalr	-96(ra) # 80001146 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011ae:	4719                	li	a4,6
    800011b0:	6685                	lui	a3,0x1
    800011b2:	10001637          	lui	a2,0x10001
    800011b6:	100015b7          	lui	a1,0x10001
    800011ba:	8526                	mv	a0,s1
    800011bc:	00000097          	auipc	ra,0x0
    800011c0:	f8a080e7          	jalr	-118(ra) # 80001146 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011c4:	4719                	li	a4,6
    800011c6:	004006b7          	lui	a3,0x400
    800011ca:	0c000637          	lui	a2,0xc000
    800011ce:	0c0005b7          	lui	a1,0xc000
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	f72080e7          	jalr	-142(ra) # 80001146 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011dc:	00007917          	auipc	s2,0x7
    800011e0:	e2490913          	addi	s2,s2,-476 # 80008000 <etext>
    800011e4:	4729                	li	a4,10
    800011e6:	80007697          	auipc	a3,0x80007
    800011ea:	e1a68693          	addi	a3,a3,-486 # 8000 <_entry-0x7fff8000>
    800011ee:	4605                	li	a2,1
    800011f0:	067e                	slli	a2,a2,0x1f
    800011f2:	85b2                	mv	a1,a2
    800011f4:	8526                	mv	a0,s1
    800011f6:	00000097          	auipc	ra,0x0
    800011fa:	f50080e7          	jalr	-176(ra) # 80001146 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011fe:	4719                	li	a4,6
    80001200:	46c5                	li	a3,17
    80001202:	06ee                	slli	a3,a3,0x1b
    80001204:	412686b3          	sub	a3,a3,s2
    80001208:	864a                	mv	a2,s2
    8000120a:	85ca                	mv	a1,s2
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f38080e7          	jalr	-200(ra) # 80001146 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001216:	4729                	li	a4,10
    80001218:	6685                	lui	a3,0x1
    8000121a:	00006617          	auipc	a2,0x6
    8000121e:	de660613          	addi	a2,a2,-538 # 80007000 <_trampoline>
    80001222:	040005b7          	lui	a1,0x4000
    80001226:	15fd                	addi	a1,a1,-1
    80001228:	05b2                	slli	a1,a1,0xc
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f1a080e7          	jalr	-230(ra) # 80001146 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	608080e7          	jalr	1544(ra) # 8000183e <proc_mapstacks>
}
    8000123e:	8526                	mv	a0,s1
    80001240:	60e2                	ld	ra,24(sp)
    80001242:	6442                	ld	s0,16(sp)
    80001244:	64a2                	ld	s1,8(sp)
    80001246:	6902                	ld	s2,0(sp)
    80001248:	6105                	addi	sp,sp,32
    8000124a:	8082                	ret

000000008000124c <kvminit>:
{
    8000124c:	1141                	addi	sp,sp,-16
    8000124e:	e406                	sd	ra,8(sp)
    80001250:	e022                	sd	s0,0(sp)
    80001252:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001254:	00000097          	auipc	ra,0x0
    80001258:	f22080e7          	jalr	-222(ra) # 80001176 <kvmmake>
    8000125c:	00007797          	auipc	a5,0x7
    80001260:	68a7ba23          	sd	a0,1684(a5) # 800088f0 <kernel_pagetable>
}
    80001264:	60a2                	ld	ra,8(sp)
    80001266:	6402                	ld	s0,0(sp)
    80001268:	0141                	addi	sp,sp,16
    8000126a:	8082                	ret

000000008000126c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000126c:	715d                	addi	sp,sp,-80
    8000126e:	e486                	sd	ra,72(sp)
    80001270:	e0a2                	sd	s0,64(sp)
    80001272:	fc26                	sd	s1,56(sp)
    80001274:	f84a                	sd	s2,48(sp)
    80001276:	f44e                	sd	s3,40(sp)
    80001278:	f052                	sd	s4,32(sp)
    8000127a:	ec56                	sd	s5,24(sp)
    8000127c:	e85a                	sd	s6,16(sp)
    8000127e:	e45e                	sd	s7,8(sp)
    80001280:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001282:	03459793          	slli	a5,a1,0x34
    80001286:	e795                	bnez	a5,800012b2 <uvmunmap+0x46>
    80001288:	8a2a                	mv	s4,a0
    8000128a:	892e                	mv	s2,a1
    8000128c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	0632                	slli	a2,a2,0xc
    80001290:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001294:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001296:	6b05                	lui	s6,0x1
    80001298:	0735e263          	bltu	a1,s3,800012fc <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000129c:	60a6                	ld	ra,72(sp)
    8000129e:	6406                	ld	s0,64(sp)
    800012a0:	74e2                	ld	s1,56(sp)
    800012a2:	7942                	ld	s2,48(sp)
    800012a4:	79a2                	ld	s3,40(sp)
    800012a6:	7a02                	ld	s4,32(sp)
    800012a8:	6ae2                	ld	s5,24(sp)
    800012aa:	6b42                	ld	s6,16(sp)
    800012ac:	6ba2                	ld	s7,8(sp)
    800012ae:	6161                	addi	sp,sp,80
    800012b0:	8082                	ret
    panic("uvmunmap: not aligned");
    800012b2:	00007517          	auipc	a0,0x7
    800012b6:	e4e50513          	addi	a0,a0,-434 # 80008100 <digits+0xc0>
    800012ba:	fffff097          	auipc	ra,0xfffff
    800012be:	284080e7          	jalr	644(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012c2:	00007517          	auipc	a0,0x7
    800012c6:	e5650513          	addi	a0,a0,-426 # 80008118 <digits+0xd8>
    800012ca:	fffff097          	auipc	ra,0xfffff
    800012ce:	274080e7          	jalr	628(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012d2:	00007517          	auipc	a0,0x7
    800012d6:	e5650513          	addi	a0,a0,-426 # 80008128 <digits+0xe8>
    800012da:	fffff097          	auipc	ra,0xfffff
    800012de:	264080e7          	jalr	612(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012e2:	00007517          	auipc	a0,0x7
    800012e6:	e5e50513          	addi	a0,a0,-418 # 80008140 <digits+0x100>
    800012ea:	fffff097          	auipc	ra,0xfffff
    800012ee:	254080e7          	jalr	596(ra) # 8000053e <panic>
    *pte = 0;
    800012f2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f6:	995a                	add	s2,s2,s6
    800012f8:	fb3972e3          	bgeu	s2,s3,8000129c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012fc:	4601                	li	a2,0
    800012fe:	85ca                	mv	a1,s2
    80001300:	8552                	mv	a0,s4
    80001302:	00000097          	auipc	ra,0x0
    80001306:	cbc080e7          	jalr	-836(ra) # 80000fbe <walk>
    8000130a:	84aa                	mv	s1,a0
    8000130c:	d95d                	beqz	a0,800012c2 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000130e:	6108                	ld	a0,0(a0)
    80001310:	00157793          	andi	a5,a0,1
    80001314:	dfdd                	beqz	a5,800012d2 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001316:	3ff57793          	andi	a5,a0,1023
    8000131a:	fd7784e3          	beq	a5,s7,800012e2 <uvmunmap+0x76>
    if(do_free){
    8000131e:	fc0a8ae3          	beqz	s5,800012f2 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001322:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001324:	0532                	slli	a0,a0,0xc
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	6c4080e7          	jalr	1732(ra) # 800009ea <kfree>
    8000132e:	b7d1                	j	800012f2 <uvmunmap+0x86>

0000000080001330 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001330:	1101                	addi	sp,sp,-32
    80001332:	ec06                	sd	ra,24(sp)
    80001334:	e822                	sd	s0,16(sp)
    80001336:	e426                	sd	s1,8(sp)
    80001338:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	7ac080e7          	jalr	1964(ra) # 80000ae6 <kalloc>
    80001342:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001344:	c519                	beqz	a0,80001352 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001346:	6605                	lui	a2,0x1
    80001348:	4581                	li	a1,0
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	988080e7          	jalr	-1656(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001352:	8526                	mv	a0,s1
    80001354:	60e2                	ld	ra,24(sp)
    80001356:	6442                	ld	s0,16(sp)
    80001358:	64a2                	ld	s1,8(sp)
    8000135a:	6105                	addi	sp,sp,32
    8000135c:	8082                	ret

000000008000135e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000135e:	7179                	addi	sp,sp,-48
    80001360:	f406                	sd	ra,40(sp)
    80001362:	f022                	sd	s0,32(sp)
    80001364:	ec26                	sd	s1,24(sp)
    80001366:	e84a                	sd	s2,16(sp)
    80001368:	e44e                	sd	s3,8(sp)
    8000136a:	e052                	sd	s4,0(sp)
    8000136c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000136e:	6785                	lui	a5,0x1
    80001370:	04f67863          	bgeu	a2,a5,800013c0 <uvmfirst+0x62>
    80001374:	8a2a                	mv	s4,a0
    80001376:	89ae                	mv	s3,a1
    80001378:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	76c080e7          	jalr	1900(ra) # 80000ae6 <kalloc>
    80001382:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001384:	6605                	lui	a2,0x1
    80001386:	4581                	li	a1,0
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	94a080e7          	jalr	-1718(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001390:	4779                	li	a4,30
    80001392:	86ca                	mv	a3,s2
    80001394:	6605                	lui	a2,0x1
    80001396:	4581                	li	a1,0
    80001398:	8552                	mv	a0,s4
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	d0c080e7          	jalr	-756(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    800013a2:	8626                	mv	a2,s1
    800013a4:	85ce                	mv	a1,s3
    800013a6:	854a                	mv	a0,s2
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	986080e7          	jalr	-1658(ra) # 80000d2e <memmove>
}
    800013b0:	70a2                	ld	ra,40(sp)
    800013b2:	7402                	ld	s0,32(sp)
    800013b4:	64e2                	ld	s1,24(sp)
    800013b6:	6942                	ld	s2,16(sp)
    800013b8:	69a2                	ld	s3,8(sp)
    800013ba:	6a02                	ld	s4,0(sp)
    800013bc:	6145                	addi	sp,sp,48
    800013be:	8082                	ret
    panic("uvmfirst: more than a page");
    800013c0:	00007517          	auipc	a0,0x7
    800013c4:	d9850513          	addi	a0,a0,-616 # 80008158 <digits+0x118>
    800013c8:	fffff097          	auipc	ra,0xfffff
    800013cc:	176080e7          	jalr	374(ra) # 8000053e <panic>

00000000800013d0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013d0:	1101                	addi	sp,sp,-32
    800013d2:	ec06                	sd	ra,24(sp)
    800013d4:	e822                	sd	s0,16(sp)
    800013d6:	e426                	sd	s1,8(sp)
    800013d8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013da:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013dc:	00b67d63          	bgeu	a2,a1,800013f6 <uvmdealloc+0x26>
    800013e0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013e2:	6785                	lui	a5,0x1
    800013e4:	17fd                	addi	a5,a5,-1
    800013e6:	00f60733          	add	a4,a2,a5
    800013ea:	767d                	lui	a2,0xfffff
    800013ec:	8f71                	and	a4,a4,a2
    800013ee:	97ae                	add	a5,a5,a1
    800013f0:	8ff1                	and	a5,a5,a2
    800013f2:	00f76863          	bltu	a4,a5,80001402 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013f6:	8526                	mv	a0,s1
    800013f8:	60e2                	ld	ra,24(sp)
    800013fa:	6442                	ld	s0,16(sp)
    800013fc:	64a2                	ld	s1,8(sp)
    800013fe:	6105                	addi	sp,sp,32
    80001400:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001402:	8f99                	sub	a5,a5,a4
    80001404:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001406:	4685                	li	a3,1
    80001408:	0007861b          	sext.w	a2,a5
    8000140c:	85ba                	mv	a1,a4
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	e5e080e7          	jalr	-418(ra) # 8000126c <uvmunmap>
    80001416:	b7c5                	j	800013f6 <uvmdealloc+0x26>

0000000080001418 <uvmalloc>:
  if(newsz < oldsz)
    80001418:	0ab66563          	bltu	a2,a1,800014c2 <uvmalloc+0xaa>
{
    8000141c:	7139                	addi	sp,sp,-64
    8000141e:	fc06                	sd	ra,56(sp)
    80001420:	f822                	sd	s0,48(sp)
    80001422:	f426                	sd	s1,40(sp)
    80001424:	f04a                	sd	s2,32(sp)
    80001426:	ec4e                	sd	s3,24(sp)
    80001428:	e852                	sd	s4,16(sp)
    8000142a:	e456                	sd	s5,8(sp)
    8000142c:	e05a                	sd	s6,0(sp)
    8000142e:	0080                	addi	s0,sp,64
    80001430:	8aaa                	mv	s5,a0
    80001432:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001434:	6985                	lui	s3,0x1
    80001436:	19fd                	addi	s3,s3,-1
    80001438:	95ce                	add	a1,a1,s3
    8000143a:	79fd                	lui	s3,0xfffff
    8000143c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001440:	08c9f363          	bgeu	s3,a2,800014c6 <uvmalloc+0xae>
    80001444:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001446:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	69c080e7          	jalr	1692(ra) # 80000ae6 <kalloc>
    80001452:	84aa                	mv	s1,a0
    if(mem == 0){
    80001454:	c51d                	beqz	a0,80001482 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001456:	6605                	lui	a2,0x1
    80001458:	4581                	li	a1,0
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	878080e7          	jalr	-1928(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001462:	875a                	mv	a4,s6
    80001464:	86a6                	mv	a3,s1
    80001466:	6605                	lui	a2,0x1
    80001468:	85ca                	mv	a1,s2
    8000146a:	8556                	mv	a0,s5
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	c3a080e7          	jalr	-966(ra) # 800010a6 <mappages>
    80001474:	e90d                	bnez	a0,800014a6 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001476:	6785                	lui	a5,0x1
    80001478:	993e                	add	s2,s2,a5
    8000147a:	fd4968e3          	bltu	s2,s4,8000144a <uvmalloc+0x32>
  return newsz;
    8000147e:	8552                	mv	a0,s4
    80001480:	a809                	j	80001492 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001482:	864e                	mv	a2,s3
    80001484:	85ca                	mv	a1,s2
    80001486:	8556                	mv	a0,s5
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	f48080e7          	jalr	-184(ra) # 800013d0 <uvmdealloc>
      return 0;
    80001490:	4501                	li	a0,0
}
    80001492:	70e2                	ld	ra,56(sp)
    80001494:	7442                	ld	s0,48(sp)
    80001496:	74a2                	ld	s1,40(sp)
    80001498:	7902                	ld	s2,32(sp)
    8000149a:	69e2                	ld	s3,24(sp)
    8000149c:	6a42                	ld	s4,16(sp)
    8000149e:	6aa2                	ld	s5,8(sp)
    800014a0:	6b02                	ld	s6,0(sp)
    800014a2:	6121                	addi	sp,sp,64
    800014a4:	8082                	ret
      kfree(mem);
    800014a6:	8526                	mv	a0,s1
    800014a8:	fffff097          	auipc	ra,0xfffff
    800014ac:	542080e7          	jalr	1346(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b0:	864e                	mv	a2,s3
    800014b2:	85ca                	mv	a1,s2
    800014b4:	8556                	mv	a0,s5
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	f1a080e7          	jalr	-230(ra) # 800013d0 <uvmdealloc>
      return 0;
    800014be:	4501                	li	a0,0
    800014c0:	bfc9                	j	80001492 <uvmalloc+0x7a>
    return oldsz;
    800014c2:	852e                	mv	a0,a1
}
    800014c4:	8082                	ret
  return newsz;
    800014c6:	8532                	mv	a0,a2
    800014c8:	b7e9                	j	80001492 <uvmalloc+0x7a>

00000000800014ca <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ca:	7179                	addi	sp,sp,-48
    800014cc:	f406                	sd	ra,40(sp)
    800014ce:	f022                	sd	s0,32(sp)
    800014d0:	ec26                	sd	s1,24(sp)
    800014d2:	e84a                	sd	s2,16(sp)
    800014d4:	e44e                	sd	s3,8(sp)
    800014d6:	e052                	sd	s4,0(sp)
    800014d8:	1800                	addi	s0,sp,48
    800014da:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014dc:	84aa                	mv	s1,a0
    800014de:	6905                	lui	s2,0x1
    800014e0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e2:	4985                	li	s3,1
    800014e4:	a821                	j	800014fc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e8:	0532                	slli	a0,a0,0xc
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	fe0080e7          	jalr	-32(ra) # 800014ca <freewalk>
      pagetable[i] = 0;
    800014f2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f6:	04a1                	addi	s1,s1,8
    800014f8:	03248163          	beq	s1,s2,8000151a <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014fe:	00f57793          	andi	a5,a0,15
    80001502:	ff3782e3          	beq	a5,s3,800014e6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001506:	8905                	andi	a0,a0,1
    80001508:	d57d                	beqz	a0,800014f6 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150a:	00007517          	auipc	a0,0x7
    8000150e:	c6e50513          	addi	a0,a0,-914 # 80008178 <digits+0x138>
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	02c080e7          	jalr	44(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151a:	8552                	mv	a0,s4
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	4ce080e7          	jalr	1230(ra) # 800009ea <kfree>
}
    80001524:	70a2                	ld	ra,40(sp)
    80001526:	7402                	ld	s0,32(sp)
    80001528:	64e2                	ld	s1,24(sp)
    8000152a:	6942                	ld	s2,16(sp)
    8000152c:	69a2                	ld	s3,8(sp)
    8000152e:	6a02                	ld	s4,0(sp)
    80001530:	6145                	addi	sp,sp,48
    80001532:	8082                	ret

0000000080001534 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001534:	1101                	addi	sp,sp,-32
    80001536:	ec06                	sd	ra,24(sp)
    80001538:	e822                	sd	s0,16(sp)
    8000153a:	e426                	sd	s1,8(sp)
    8000153c:	1000                	addi	s0,sp,32
    8000153e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001540:	e999                	bnez	a1,80001556 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001542:	8526                	mv	a0,s1
    80001544:	00000097          	auipc	ra,0x0
    80001548:	f86080e7          	jalr	-122(ra) # 800014ca <freewalk>
}
    8000154c:	60e2                	ld	ra,24(sp)
    8000154e:	6442                	ld	s0,16(sp)
    80001550:	64a2                	ld	s1,8(sp)
    80001552:	6105                	addi	sp,sp,32
    80001554:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001556:	6605                	lui	a2,0x1
    80001558:	167d                	addi	a2,a2,-1
    8000155a:	962e                	add	a2,a2,a1
    8000155c:	4685                	li	a3,1
    8000155e:	8231                	srli	a2,a2,0xc
    80001560:	4581                	li	a1,0
    80001562:	00000097          	auipc	ra,0x0
    80001566:	d0a080e7          	jalr	-758(ra) # 8000126c <uvmunmap>
    8000156a:	bfe1                	j	80001542 <uvmfree+0xe>

000000008000156c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156c:	c679                	beqz	a2,8000163a <uvmcopy+0xce>
{
    8000156e:	715d                	addi	sp,sp,-80
    80001570:	e486                	sd	ra,72(sp)
    80001572:	e0a2                	sd	s0,64(sp)
    80001574:	fc26                	sd	s1,56(sp)
    80001576:	f84a                	sd	s2,48(sp)
    80001578:	f44e                	sd	s3,40(sp)
    8000157a:	f052                	sd	s4,32(sp)
    8000157c:	ec56                	sd	s5,24(sp)
    8000157e:	e85a                	sd	s6,16(sp)
    80001580:	e45e                	sd	s7,8(sp)
    80001582:	0880                	addi	s0,sp,80
    80001584:	8b2a                	mv	s6,a0
    80001586:	8aae                	mv	s5,a1
    80001588:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158c:	4601                	li	a2,0
    8000158e:	85ce                	mv	a1,s3
    80001590:	855a                	mv	a0,s6
    80001592:	00000097          	auipc	ra,0x0
    80001596:	a2c080e7          	jalr	-1492(ra) # 80000fbe <walk>
    8000159a:	c531                	beqz	a0,800015e6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159c:	6118                	ld	a4,0(a0)
    8000159e:	00177793          	andi	a5,a4,1
    800015a2:	cbb1                	beqz	a5,800015f6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a4:	00a75593          	srli	a1,a4,0xa
    800015a8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ac:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b0:	fffff097          	auipc	ra,0xfffff
    800015b4:	536080e7          	jalr	1334(ra) # 80000ae6 <kalloc>
    800015b8:	892a                	mv	s2,a0
    800015ba:	c939                	beqz	a0,80001610 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015bc:	6605                	lui	a2,0x1
    800015be:	85de                	mv	a1,s7
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	76e080e7          	jalr	1902(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c8:	8726                	mv	a4,s1
    800015ca:	86ca                	mv	a3,s2
    800015cc:	6605                	lui	a2,0x1
    800015ce:	85ce                	mv	a1,s3
    800015d0:	8556                	mv	a0,s5
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	ad4080e7          	jalr	-1324(ra) # 800010a6 <mappages>
    800015da:	e515                	bnez	a0,80001606 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015dc:	6785                	lui	a5,0x1
    800015de:	99be                	add	s3,s3,a5
    800015e0:	fb49e6e3          	bltu	s3,s4,8000158c <uvmcopy+0x20>
    800015e4:	a081                	j	80001624 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e6:	00007517          	auipc	a0,0x7
    800015ea:	ba250513          	addi	a0,a0,-1118 # 80008188 <digits+0x148>
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f6:	00007517          	auipc	a0,0x7
    800015fa:	bb250513          	addi	a0,a0,-1102 # 800081a8 <digits+0x168>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
      kfree(mem);
    80001606:	854a                	mv	a0,s2
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	3e2080e7          	jalr	994(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001610:	4685                	li	a3,1
    80001612:	00c9d613          	srli	a2,s3,0xc
    80001616:	4581                	li	a1,0
    80001618:	8556                	mv	a0,s5
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	c52080e7          	jalr	-942(ra) # 8000126c <uvmunmap>
  return -1;
    80001622:	557d                	li	a0,-1
}
    80001624:	60a6                	ld	ra,72(sp)
    80001626:	6406                	ld	s0,64(sp)
    80001628:	74e2                	ld	s1,56(sp)
    8000162a:	7942                	ld	s2,48(sp)
    8000162c:	79a2                	ld	s3,40(sp)
    8000162e:	7a02                	ld	s4,32(sp)
    80001630:	6ae2                	ld	s5,24(sp)
    80001632:	6b42                	ld	s6,16(sp)
    80001634:	6ba2                	ld	s7,8(sp)
    80001636:	6161                	addi	sp,sp,80
    80001638:	8082                	ret
  return 0;
    8000163a:	4501                	li	a0,0
}
    8000163c:	8082                	ret

000000008000163e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163e:	1141                	addi	sp,sp,-16
    80001640:	e406                	sd	ra,8(sp)
    80001642:	e022                	sd	s0,0(sp)
    80001644:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001646:	4601                	li	a2,0
    80001648:	00000097          	auipc	ra,0x0
    8000164c:	976080e7          	jalr	-1674(ra) # 80000fbe <walk>
  if(pte == 0)
    80001650:	c901                	beqz	a0,80001660 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001652:	611c                	ld	a5,0(a0)
    80001654:	9bbd                	andi	a5,a5,-17
    80001656:	e11c                	sd	a5,0(a0)
}
    80001658:	60a2                	ld	ra,8(sp)
    8000165a:	6402                	ld	s0,0(sp)
    8000165c:	0141                	addi	sp,sp,16
    8000165e:	8082                	ret
    panic("uvmclear");
    80001660:	00007517          	auipc	a0,0x7
    80001664:	b6850513          	addi	a0,a0,-1176 # 800081c8 <digits+0x188>
    80001668:	fffff097          	auipc	ra,0xfffff
    8000166c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>

0000000080001670 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001670:	c6bd                	beqz	a3,800016de <copyout+0x6e>
{
    80001672:	715d                	addi	sp,sp,-80
    80001674:	e486                	sd	ra,72(sp)
    80001676:	e0a2                	sd	s0,64(sp)
    80001678:	fc26                	sd	s1,56(sp)
    8000167a:	f84a                	sd	s2,48(sp)
    8000167c:	f44e                	sd	s3,40(sp)
    8000167e:	f052                	sd	s4,32(sp)
    80001680:	ec56                	sd	s5,24(sp)
    80001682:	e85a                	sd	s6,16(sp)
    80001684:	e45e                	sd	s7,8(sp)
    80001686:	e062                	sd	s8,0(sp)
    80001688:	0880                	addi	s0,sp,80
    8000168a:	8b2a                	mv	s6,a0
    8000168c:	8c2e                	mv	s8,a1
    8000168e:	8a32                	mv	s4,a2
    80001690:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001692:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001694:	6a85                	lui	s5,0x1
    80001696:	a015                	j	800016ba <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001698:	9562                	add	a0,a0,s8
    8000169a:	0004861b          	sext.w	a2,s1
    8000169e:	85d2                	mv	a1,s4
    800016a0:	41250533          	sub	a0,a0,s2
    800016a4:	fffff097          	auipc	ra,0xfffff
    800016a8:	68a080e7          	jalr	1674(ra) # 80000d2e <memmove>

    len -= n;
    800016ac:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b6:	02098263          	beqz	s3,800016da <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016be:	85ca                	mv	a1,s2
    800016c0:	855a                	mv	a0,s6
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	9a2080e7          	jalr	-1630(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800016ca:	cd01                	beqz	a0,800016e2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016cc:	418904b3          	sub	s1,s2,s8
    800016d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d2:	fc99f3e3          	bgeu	s3,s1,80001698 <copyout+0x28>
    800016d6:	84ce                	mv	s1,s3
    800016d8:	b7c1                	j	80001698 <copyout+0x28>
  }
  return 0;
    800016da:	4501                	li	a0,0
    800016dc:	a021                	j	800016e4 <copyout+0x74>
    800016de:	4501                	li	a0,0
}
    800016e0:	8082                	ret
      return -1;
    800016e2:	557d                	li	a0,-1
}
    800016e4:	60a6                	ld	ra,72(sp)
    800016e6:	6406                	ld	s0,64(sp)
    800016e8:	74e2                	ld	s1,56(sp)
    800016ea:	7942                	ld	s2,48(sp)
    800016ec:	79a2                	ld	s3,40(sp)
    800016ee:	7a02                	ld	s4,32(sp)
    800016f0:	6ae2                	ld	s5,24(sp)
    800016f2:	6b42                	ld	s6,16(sp)
    800016f4:	6ba2                	ld	s7,8(sp)
    800016f6:	6c02                	ld	s8,0(sp)
    800016f8:	6161                	addi	sp,sp,80
    800016fa:	8082                	ret

00000000800016fc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fc:	caa5                	beqz	a3,8000176c <copyin+0x70>
{
    800016fe:	715d                	addi	sp,sp,-80
    80001700:	e486                	sd	ra,72(sp)
    80001702:	e0a2                	sd	s0,64(sp)
    80001704:	fc26                	sd	s1,56(sp)
    80001706:	f84a                	sd	s2,48(sp)
    80001708:	f44e                	sd	s3,40(sp)
    8000170a:	f052                	sd	s4,32(sp)
    8000170c:	ec56                	sd	s5,24(sp)
    8000170e:	e85a                	sd	s6,16(sp)
    80001710:	e45e                	sd	s7,8(sp)
    80001712:	e062                	sd	s8,0(sp)
    80001714:	0880                	addi	s0,sp,80
    80001716:	8b2a                	mv	s6,a0
    80001718:	8a2e                	mv	s4,a1
    8000171a:	8c32                	mv	s8,a2
    8000171c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001720:	6a85                	lui	s5,0x1
    80001722:	a01d                	j	80001748 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001724:	018505b3          	add	a1,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412585b3          	sub	a1,a1,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	5fc080e7          	jalr	1532(ra) # 80000d2e <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	914080e7          	jalr	-1772(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f2e3          	bgeu	s3,s1,80001724 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	bf7d                	j	80001724 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x76>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	882080e7          	jalr	-1918(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	0000f497          	auipc	s1,0xf
    80001858:	74c48493          	addi	s1,s1,1868 # 80010fa0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00015a17          	auipc	s4,0x15
    80001872:	132a0a13          	addi	s4,s4,306 # 800169a0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	270080e7          	jalr	624(ra) # 80000ae6 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8a6080e7          	jalr	-1882(ra) # 80001146 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	16848493          	addi	s1,s1,360
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	0000f517          	auipc	a0,0xf
    800018f4:	28050513          	addi	a0,a0,640 # 80010b70 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	24e080e7          	jalr	590(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	0000f517          	auipc	a0,0xf
    8000190c:	28050513          	addi	a0,a0,640 # 80010b88 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	236080e7          	jalr	566(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	0000f497          	auipc	s1,0xf
    8000191c:	68848493          	addi	s1,s1,1672 # 80010fa0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00015997          	auipc	s3,0x15
    8000193e:	06698993          	addi	s3,s3,102 # 800169a0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	200080e7          	jalr	512(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    8000194e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001952:	415487b3          	sub	a5,s1,s5
    80001956:	878d                	srai	a5,a5,0x3
    80001958:	000a3703          	ld	a4,0(s4)
    8000195c:	02e787b3          	mul	a5,a5,a4
    80001960:	2785                	addiw	a5,a5,1
    80001962:	00d7979b          	slliw	a5,a5,0xd
    80001966:	40f907b3          	sub	a5,s2,a5
    8000196a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	16848493          	addi	s1,s1,360
    80001970:	fd3499e3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001974:	70e2                	ld	ra,56(sp)
    80001976:	7442                	ld	s0,48(sp)
    80001978:	74a2                	ld	s1,40(sp)
    8000197a:	7902                	ld	s2,32(sp)
    8000197c:	69e2                	ld	s3,24(sp)
    8000197e:	6a42                	ld	s4,16(sp)
    80001980:	6aa2                	ld	s5,8(sp)
    80001982:	6b02                	ld	s6,0(sp)
    80001984:	6121                	addi	sp,sp,64
    80001986:	8082                	ret

0000000080001988 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001988:	1141                	addi	sp,sp,-16
    8000198a:	e422                	sd	s0,8(sp)
    8000198c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001990:	2501                	sext.w	a0,a0
    80001992:	6422                	ld	s0,8(sp)
    80001994:	0141                	addi	sp,sp,16
    80001996:	8082                	ret

0000000080001998 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001998:	1141                	addi	sp,sp,-16
    8000199a:	e422                	sd	s0,8(sp)
    8000199c:	0800                	addi	s0,sp,16
    8000199e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a0:	2781                	sext.w	a5,a5
    800019a2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a4:	0000f517          	auipc	a0,0xf
    800019a8:	1fc50513          	addi	a0,a0,508 # 80010ba0 <cpus>
    800019ac:	953e                	add	a0,a0,a5
    800019ae:	6422                	ld	s0,8(sp)
    800019b0:	0141                	addi	sp,sp,16
    800019b2:	8082                	ret

00000000800019b4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019b4:	1101                	addi	sp,sp,-32
    800019b6:	ec06                	sd	ra,24(sp)
    800019b8:	e822                	sd	s0,16(sp)
    800019ba:	e426                	sd	s1,8(sp)
    800019bc:	1000                	addi	s0,sp,32
  push_off();
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	1cc080e7          	jalr	460(ra) # 80000b8a <push_off>
    800019c6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c8:	2781                	sext.w	a5,a5
    800019ca:	079e                	slli	a5,a5,0x7
    800019cc:	0000f717          	auipc	a4,0xf
    800019d0:	1a470713          	addi	a4,a4,420 # 80010b70 <pid_lock>
    800019d4:	97ba                	add	a5,a5,a4
    800019d6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	252080e7          	jalr	594(ra) # 80000c2a <pop_off>
  return p;
}
    800019e0:	8526                	mv	a0,s1
    800019e2:	60e2                	ld	ra,24(sp)
    800019e4:	6442                	ld	s0,16(sp)
    800019e6:	64a2                	ld	s1,8(sp)
    800019e8:	6105                	addi	sp,sp,32
    800019ea:	8082                	ret

00000000800019ec <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ec:	1141                	addi	sp,sp,-16
    800019ee:	e406                	sd	ra,8(sp)
    800019f0:	e022                	sd	s0,0(sp)
    800019f2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f4:	00000097          	auipc	ra,0x0
    800019f8:	fc0080e7          	jalr	-64(ra) # 800019b4 <myproc>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	28e080e7          	jalr	654(ra) # 80000c8a <release>

  if (first) {
    80001a04:	00007797          	auipc	a5,0x7
    80001a08:	e5c7a783          	lw	a5,-420(a5) # 80008860 <first.1>
    80001a0c:	eb89                	bnez	a5,80001a1e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0e:	00001097          	auipc	ra,0x1
    80001a12:	c5a080e7          	jalr	-934(ra) # 80002668 <usertrapret>
}
    80001a16:	60a2                	ld	ra,8(sp)
    80001a18:	6402                	ld	s0,0(sp)
    80001a1a:	0141                	addi	sp,sp,16
    80001a1c:	8082                	ret
    first = 0;
    80001a1e:	00007797          	auipc	a5,0x7
    80001a22:	e407a123          	sw	zero,-446(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a26:	4505                	li	a0,1
    80001a28:	00002097          	auipc	ra,0x2
    80001a2c:	b1c080e7          	jalr	-1252(ra) # 80003544 <fsinit>
    80001a30:	bff9                	j	80001a0e <forkret+0x22>

0000000080001a32 <allocpid>:
{
    80001a32:	1101                	addi	sp,sp,-32
    80001a34:	ec06                	sd	ra,24(sp)
    80001a36:	e822                	sd	s0,16(sp)
    80001a38:	e426                	sd	s1,8(sp)
    80001a3a:	e04a                	sd	s2,0(sp)
    80001a3c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3e:	0000f917          	auipc	s2,0xf
    80001a42:	13290913          	addi	s2,s2,306 # 80010b70 <pid_lock>
    80001a46:	854a                	mv	a0,s2
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	18e080e7          	jalr	398(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a50:	00007797          	auipc	a5,0x7
    80001a54:	e1478793          	addi	a5,a5,-492 # 80008864 <nextpid>
    80001a58:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a5a:	0014871b          	addiw	a4,s1,1
    80001a5e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a60:	854a                	mv	a0,s2
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	228080e7          	jalr	552(ra) # 80000c8a <release>
}
    80001a6a:	8526                	mv	a0,s1
    80001a6c:	60e2                	ld	ra,24(sp)
    80001a6e:	6442                	ld	s0,16(sp)
    80001a70:	64a2                	ld	s1,8(sp)
    80001a72:	6902                	ld	s2,0(sp)
    80001a74:	6105                	addi	sp,sp,32
    80001a76:	8082                	ret

0000000080001a78 <proc_pagetable>:
{
    80001a78:	1101                	addi	sp,sp,-32
    80001a7a:	ec06                	sd	ra,24(sp)
    80001a7c:	e822                	sd	s0,16(sp)
    80001a7e:	e426                	sd	s1,8(sp)
    80001a80:	e04a                	sd	s2,0(sp)
    80001a82:	1000                	addi	s0,sp,32
    80001a84:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a86:	00000097          	auipc	ra,0x0
    80001a8a:	8aa080e7          	jalr	-1878(ra) # 80001330 <uvmcreate>
    80001a8e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a90:	c121                	beqz	a0,80001ad0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a92:	4729                	li	a4,10
    80001a94:	00005697          	auipc	a3,0x5
    80001a98:	56c68693          	addi	a3,a3,1388 # 80007000 <_trampoline>
    80001a9c:	6605                	lui	a2,0x1
    80001a9e:	040005b7          	lui	a1,0x4000
    80001aa2:	15fd                	addi	a1,a1,-1
    80001aa4:	05b2                	slli	a1,a1,0xc
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	600080e7          	jalr	1536(ra) # 800010a6 <mappages>
    80001aae:	02054863          	bltz	a0,80001ade <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab2:	4719                	li	a4,6
    80001ab4:	05893683          	ld	a3,88(s2)
    80001ab8:	6605                	lui	a2,0x1
    80001aba:	020005b7          	lui	a1,0x2000
    80001abe:	15fd                	addi	a1,a1,-1
    80001ac0:	05b6                	slli	a1,a1,0xd
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	5e2080e7          	jalr	1506(ra) # 800010a6 <mappages>
    80001acc:	02054163          	bltz	a0,80001aee <proc_pagetable+0x76>
}
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	60e2                	ld	ra,24(sp)
    80001ad4:	6442                	ld	s0,16(sp)
    80001ad6:	64a2                	ld	s1,8(sp)
    80001ad8:	6902                	ld	s2,0(sp)
    80001ada:	6105                	addi	sp,sp,32
    80001adc:	8082                	ret
    uvmfree(pagetable, 0);
    80001ade:	4581                	li	a1,0
    80001ae0:	8526                	mv	a0,s1
    80001ae2:	00000097          	auipc	ra,0x0
    80001ae6:	a52080e7          	jalr	-1454(ra) # 80001534 <uvmfree>
    return 0;
    80001aea:	4481                	li	s1,0
    80001aec:	b7d5                	j	80001ad0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aee:	4681                	li	a3,0
    80001af0:	4605                	li	a2,1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	8526                	mv	a0,s1
    80001afc:	fffff097          	auipc	ra,0xfffff
    80001b00:	770080e7          	jalr	1904(ra) # 8000126c <uvmunmap>
    uvmfree(pagetable, 0);
    80001b04:	4581                	li	a1,0
    80001b06:	8526                	mv	a0,s1
    80001b08:	00000097          	auipc	ra,0x0
    80001b0c:	a2c080e7          	jalr	-1492(ra) # 80001534 <uvmfree>
    return 0;
    80001b10:	4481                	li	s1,0
    80001b12:	bf7d                	j	80001ad0 <proc_pagetable+0x58>

0000000080001b14 <proc_freepagetable>:
{
    80001b14:	1101                	addi	sp,sp,-32
    80001b16:	ec06                	sd	ra,24(sp)
    80001b18:	e822                	sd	s0,16(sp)
    80001b1a:	e426                	sd	s1,8(sp)
    80001b1c:	e04a                	sd	s2,0(sp)
    80001b1e:	1000                	addi	s0,sp,32
    80001b20:	84aa                	mv	s1,a0
    80001b22:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b24:	4681                	li	a3,0
    80001b26:	4605                	li	a2,1
    80001b28:	040005b7          	lui	a1,0x4000
    80001b2c:	15fd                	addi	a1,a1,-1
    80001b2e:	05b2                	slli	a1,a1,0xc
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	73c080e7          	jalr	1852(ra) # 8000126c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b38:	4681                	li	a3,0
    80001b3a:	4605                	li	a2,1
    80001b3c:	020005b7          	lui	a1,0x2000
    80001b40:	15fd                	addi	a1,a1,-1
    80001b42:	05b6                	slli	a1,a1,0xd
    80001b44:	8526                	mv	a0,s1
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	726080e7          	jalr	1830(ra) # 8000126c <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4e:	85ca                	mv	a1,s2
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	9e2080e7          	jalr	-1566(ra) # 80001534 <uvmfree>
}
    80001b5a:	60e2                	ld	ra,24(sp)
    80001b5c:	6442                	ld	s0,16(sp)
    80001b5e:	64a2                	ld	s1,8(sp)
    80001b60:	6902                	ld	s2,0(sp)
    80001b62:	6105                	addi	sp,sp,32
    80001b64:	8082                	ret

0000000080001b66 <freeproc>:
{
    80001b66:	1101                	addi	sp,sp,-32
    80001b68:	ec06                	sd	ra,24(sp)
    80001b6a:	e822                	sd	s0,16(sp)
    80001b6c:	e426                	sd	s1,8(sp)
    80001b6e:	1000                	addi	s0,sp,32
    80001b70:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b72:	6d28                	ld	a0,88(a0)
    80001b74:	c509                	beqz	a0,80001b7e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	e74080e7          	jalr	-396(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b7e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b82:	68a8                	ld	a0,80(s1)
    80001b84:	c511                	beqz	a0,80001b90 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b86:	64ac                	ld	a1,72(s1)
    80001b88:	00000097          	auipc	ra,0x0
    80001b8c:	f8c080e7          	jalr	-116(ra) # 80001b14 <proc_freepagetable>
  p->pagetable = 0;
    80001b90:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b94:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b98:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b9c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ba0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bac:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bb0:	0004ac23          	sw	zero,24(s1)
}
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6105                	addi	sp,sp,32
    80001bbc:	8082                	ret

0000000080001bbe <allocproc>:
{
    80001bbe:	1101                	addi	sp,sp,-32
    80001bc0:	ec06                	sd	ra,24(sp)
    80001bc2:	e822                	sd	s0,16(sp)
    80001bc4:	e426                	sd	s1,8(sp)
    80001bc6:	e04a                	sd	s2,0(sp)
    80001bc8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bca:	0000f497          	auipc	s1,0xf
    80001bce:	3d648493          	addi	s1,s1,982 # 80010fa0 <proc>
    80001bd2:	00015917          	auipc	s2,0x15
    80001bd6:	dce90913          	addi	s2,s2,-562 # 800169a0 <tickslock>
    acquire(&p->lock);
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	ffa080e7          	jalr	-6(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001be4:	4c9c                	lw	a5,24(s1)
    80001be6:	cf81                	beqz	a5,80001bfe <allocproc+0x40>
      release(&p->lock);
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	0a0080e7          	jalr	160(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf2:	16848493          	addi	s1,s1,360
    80001bf6:	ff2492e3          	bne	s1,s2,80001bda <allocproc+0x1c>
  return 0;
    80001bfa:	4481                	li	s1,0
    80001bfc:	a889                	j	80001c4e <allocproc+0x90>
  p->pid = allocpid();
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e34080e7          	jalr	-460(ra) # 80001a32 <allocpid>
    80001c06:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c08:	4785                	li	a5,1
    80001c0a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	eda080e7          	jalr	-294(ra) # 80000ae6 <kalloc>
    80001c14:	892a                	mv	s2,a0
    80001c16:	eca8                	sd	a0,88(s1)
    80001c18:	c131                	beqz	a0,80001c5c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	e5c080e7          	jalr	-420(ra) # 80001a78 <proc_pagetable>
    80001c24:	892a                	mv	s2,a0
    80001c26:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c28:	c531                	beqz	a0,80001c74 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c2a:	07000613          	li	a2,112
    80001c2e:	4581                	li	a1,0
    80001c30:	06048513          	addi	a0,s1,96
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	09e080e7          	jalr	158(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c3c:	00000797          	auipc	a5,0x0
    80001c40:	db078793          	addi	a5,a5,-592 # 800019ec <forkret>
    80001c44:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c46:	60bc                	ld	a5,64(s1)
    80001c48:	6705                	lui	a4,0x1
    80001c4a:	97ba                	add	a5,a5,a4
    80001c4c:	f4bc                	sd	a5,104(s1)
}
    80001c4e:	8526                	mv	a0,s1
    80001c50:	60e2                	ld	ra,24(sp)
    80001c52:	6442                	ld	s0,16(sp)
    80001c54:	64a2                	ld	s1,8(sp)
    80001c56:	6902                	ld	s2,0(sp)
    80001c58:	6105                	addi	sp,sp,32
    80001c5a:	8082                	ret
    freeproc(p);
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	f08080e7          	jalr	-248(ra) # 80001b66 <freeproc>
    release(&p->lock);
    80001c66:	8526                	mv	a0,s1
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	022080e7          	jalr	34(ra) # 80000c8a <release>
    return 0;
    80001c70:	84ca                	mv	s1,s2
    80001c72:	bff1                	j	80001c4e <allocproc+0x90>
    freeproc(p);
    80001c74:	8526                	mv	a0,s1
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	ef0080e7          	jalr	-272(ra) # 80001b66 <freeproc>
    release(&p->lock);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	00a080e7          	jalr	10(ra) # 80000c8a <release>
    return 0;
    80001c88:	84ca                	mv	s1,s2
    80001c8a:	b7d1                	j	80001c4e <allocproc+0x90>

0000000080001c8c <userinit>:
{
    80001c8c:	1101                	addi	sp,sp,-32
    80001c8e:	ec06                	sd	ra,24(sp)
    80001c90:	e822                	sd	s0,16(sp)
    80001c92:	e426                	sd	s1,8(sp)
    80001c94:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	f28080e7          	jalr	-216(ra) # 80001bbe <allocproc>
    80001c9e:	84aa                	mv	s1,a0
  initproc = p;
    80001ca0:	00007797          	auipc	a5,0x7
    80001ca4:	c4a7bc23          	sd	a0,-936(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca8:	03400613          	li	a2,52
    80001cac:	00007597          	auipc	a1,0x7
    80001cb0:	bc458593          	addi	a1,a1,-1084 # 80008870 <initcode>
    80001cb4:	6928                	ld	a0,80(a0)
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	6a8080e7          	jalr	1704(ra) # 8000135e <uvmfirst>
  p->sz = PGSIZE;
    80001cbe:	6785                	lui	a5,0x1
    80001cc0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cc2:	6cb8                	ld	a4,88(s1)
    80001cc4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc8:	6cb8                	ld	a4,88(s1)
    80001cca:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ccc:	4641                	li	a2,16
    80001cce:	00006597          	auipc	a1,0x6
    80001cd2:	53258593          	addi	a1,a1,1330 # 80008200 <digits+0x1c0>
    80001cd6:	15848513          	addi	a0,s1,344
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	142080e7          	jalr	322(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001ce2:	00006517          	auipc	a0,0x6
    80001ce6:	52e50513          	addi	a0,a0,1326 # 80008210 <digits+0x1d0>
    80001cea:	00002097          	auipc	ra,0x2
    80001cee:	27c080e7          	jalr	636(ra) # 80003f66 <namei>
    80001cf2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf6:	478d                	li	a5,3
    80001cf8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	f8e080e7          	jalr	-114(ra) # 80000c8a <release>
}
    80001d04:	60e2                	ld	ra,24(sp)
    80001d06:	6442                	ld	s0,16(sp)
    80001d08:	64a2                	ld	s1,8(sp)
    80001d0a:	6105                	addi	sp,sp,32
    80001d0c:	8082                	ret

0000000080001d0e <growproc>:
{
    80001d0e:	1101                	addi	sp,sp,-32
    80001d10:	ec06                	sd	ra,24(sp)
    80001d12:	e822                	sd	s0,16(sp)
    80001d14:	e426                	sd	s1,8(sp)
    80001d16:	e04a                	sd	s2,0(sp)
    80001d18:	1000                	addi	s0,sp,32
    80001d1a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d1c:	00000097          	auipc	ra,0x0
    80001d20:	c98080e7          	jalr	-872(ra) # 800019b4 <myproc>
    80001d24:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d26:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d28:	01204c63          	bgtz	s2,80001d40 <growproc+0x32>
  } else if(n < 0){
    80001d2c:	02094663          	bltz	s2,80001d58 <growproc+0x4a>
  p->sz = sz;
    80001d30:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d32:	4501                	li	a0,0
}
    80001d34:	60e2                	ld	ra,24(sp)
    80001d36:	6442                	ld	s0,16(sp)
    80001d38:	64a2                	ld	s1,8(sp)
    80001d3a:	6902                	ld	s2,0(sp)
    80001d3c:	6105                	addi	sp,sp,32
    80001d3e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d40:	4691                	li	a3,4
    80001d42:	00b90633          	add	a2,s2,a1
    80001d46:	6928                	ld	a0,80(a0)
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	6d0080e7          	jalr	1744(ra) # 80001418 <uvmalloc>
    80001d50:	85aa                	mv	a1,a0
    80001d52:	fd79                	bnez	a0,80001d30 <growproc+0x22>
      return -1;
    80001d54:	557d                	li	a0,-1
    80001d56:	bff9                	j	80001d34 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d58:	00b90633          	add	a2,s2,a1
    80001d5c:	6928                	ld	a0,80(a0)
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	672080e7          	jalr	1650(ra) # 800013d0 <uvmdealloc>
    80001d66:	85aa                	mv	a1,a0
    80001d68:	b7e1                	j	80001d30 <growproc+0x22>

0000000080001d6a <fork>:
{
    80001d6a:	7139                	addi	sp,sp,-64
    80001d6c:	fc06                	sd	ra,56(sp)
    80001d6e:	f822                	sd	s0,48(sp)
    80001d70:	f426                	sd	s1,40(sp)
    80001d72:	f04a                	sd	s2,32(sp)
    80001d74:	ec4e                	sd	s3,24(sp)
    80001d76:	e852                	sd	s4,16(sp)
    80001d78:	e456                	sd	s5,8(sp)
    80001d7a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	c38080e7          	jalr	-968(ra) # 800019b4 <myproc>
    80001d84:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	e38080e7          	jalr	-456(ra) # 80001bbe <allocproc>
    80001d8e:	10050c63          	beqz	a0,80001ea6 <fork+0x13c>
    80001d92:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d94:	048ab603          	ld	a2,72(s5)
    80001d98:	692c                	ld	a1,80(a0)
    80001d9a:	050ab503          	ld	a0,80(s5)
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	7ce080e7          	jalr	1998(ra) # 8000156c <uvmcopy>
    80001da6:	04054863          	bltz	a0,80001df6 <fork+0x8c>
  np->sz = p->sz;
    80001daa:	048ab783          	ld	a5,72(s5)
    80001dae:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001db2:	058ab683          	ld	a3,88(s5)
    80001db6:	87b6                	mv	a5,a3
    80001db8:	058a3703          	ld	a4,88(s4)
    80001dbc:	12068693          	addi	a3,a3,288
    80001dc0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc4:	6788                	ld	a0,8(a5)
    80001dc6:	6b8c                	ld	a1,16(a5)
    80001dc8:	6f90                	ld	a2,24(a5)
    80001dca:	01073023          	sd	a6,0(a4)
    80001dce:	e708                	sd	a0,8(a4)
    80001dd0:	eb0c                	sd	a1,16(a4)
    80001dd2:	ef10                	sd	a2,24(a4)
    80001dd4:	02078793          	addi	a5,a5,32
    80001dd8:	02070713          	addi	a4,a4,32
    80001ddc:	fed792e3          	bne	a5,a3,80001dc0 <fork+0x56>
  np->trapframe->a0 = 0;
    80001de0:	058a3783          	ld	a5,88(s4)
    80001de4:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de8:	0d0a8493          	addi	s1,s5,208
    80001dec:	0d0a0913          	addi	s2,s4,208
    80001df0:	150a8993          	addi	s3,s5,336
    80001df4:	a00d                	j	80001e16 <fork+0xac>
    freeproc(np);
    80001df6:	8552                	mv	a0,s4
    80001df8:	00000097          	auipc	ra,0x0
    80001dfc:	d6e080e7          	jalr	-658(ra) # 80001b66 <freeproc>
    release(&np->lock);
    80001e00:	8552                	mv	a0,s4
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	e88080e7          	jalr	-376(ra) # 80000c8a <release>
    return -1;
    80001e0a:	597d                	li	s2,-1
    80001e0c:	a059                	j	80001e92 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e0e:	04a1                	addi	s1,s1,8
    80001e10:	0921                	addi	s2,s2,8
    80001e12:	01348b63          	beq	s1,s3,80001e28 <fork+0xbe>
    if(p->ofile[i])
    80001e16:	6088                	ld	a0,0(s1)
    80001e18:	d97d                	beqz	a0,80001e0e <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1a:	00002097          	auipc	ra,0x2
    80001e1e:	7e2080e7          	jalr	2018(ra) # 800045fc <filedup>
    80001e22:	00a93023          	sd	a0,0(s2)
    80001e26:	b7e5                	j	80001e0e <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e28:	150ab503          	ld	a0,336(s5)
    80001e2c:	00002097          	auipc	ra,0x2
    80001e30:	956080e7          	jalr	-1706(ra) # 80003782 <idup>
    80001e34:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e38:	4641                	li	a2,16
    80001e3a:	158a8593          	addi	a1,s5,344
    80001e3e:	158a0513          	addi	a0,s4,344
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	fda080e7          	jalr	-38(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e4a:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e4e:	8552                	mv	a0,s4
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	e3a080e7          	jalr	-454(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e58:	0000f497          	auipc	s1,0xf
    80001e5c:	d3048493          	addi	s1,s1,-720 # 80010b88 <wait_lock>
    80001e60:	8526                	mv	a0,s1
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	d74080e7          	jalr	-652(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e6a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e6e:	8526                	mv	a0,s1
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	e1a080e7          	jalr	-486(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e78:	8552                	mv	a0,s4
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	d5c080e7          	jalr	-676(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e82:	478d                	li	a5,3
    80001e84:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e88:	8552                	mv	a0,s4
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e00080e7          	jalr	-512(ra) # 80000c8a <release>
}
    80001e92:	854a                	mv	a0,s2
    80001e94:	70e2                	ld	ra,56(sp)
    80001e96:	7442                	ld	s0,48(sp)
    80001e98:	74a2                	ld	s1,40(sp)
    80001e9a:	7902                	ld	s2,32(sp)
    80001e9c:	69e2                	ld	s3,24(sp)
    80001e9e:	6a42                	ld	s4,16(sp)
    80001ea0:	6aa2                	ld	s5,8(sp)
    80001ea2:	6121                	addi	sp,sp,64
    80001ea4:	8082                	ret
    return -1;
    80001ea6:	597d                	li	s2,-1
    80001ea8:	b7ed                	j	80001e92 <fork+0x128>

0000000080001eaa <scheduler>:
{
    80001eaa:	7139                	addi	sp,sp,-64
    80001eac:	fc06                	sd	ra,56(sp)
    80001eae:	f822                	sd	s0,48(sp)
    80001eb0:	f426                	sd	s1,40(sp)
    80001eb2:	f04a                	sd	s2,32(sp)
    80001eb4:	ec4e                	sd	s3,24(sp)
    80001eb6:	e852                	sd	s4,16(sp)
    80001eb8:	e456                	sd	s5,8(sp)
    80001eba:	e05a                	sd	s6,0(sp)
    80001ebc:	0080                	addi	s0,sp,64
    80001ebe:	8792                	mv	a5,tp
  int id = r_tp();
    80001ec0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec2:	00779a93          	slli	s5,a5,0x7
    80001ec6:	0000f717          	auipc	a4,0xf
    80001eca:	caa70713          	addi	a4,a4,-854 # 80010b70 <pid_lock>
    80001ece:	9756                	add	a4,a4,s5
    80001ed0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ed4:	0000f717          	auipc	a4,0xf
    80001ed8:	cd470713          	addi	a4,a4,-812 # 80010ba8 <cpus+0x8>
    80001edc:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ede:	498d                	li	s3,3
        p->state = RUNNING;
    80001ee0:	4b11                	li	s6,4
        c->proc = p;
    80001ee2:	079e                	slli	a5,a5,0x7
    80001ee4:	0000fa17          	auipc	s4,0xf
    80001ee8:	c8ca0a13          	addi	s4,s4,-884 # 80010b70 <pid_lock>
    80001eec:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eee:	00015917          	auipc	s2,0x15
    80001ef2:	ab290913          	addi	s2,s2,-1358 # 800169a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001efa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001efe:	10079073          	csrw	sstatus,a5
    80001f02:	0000f497          	auipc	s1,0xf
    80001f06:	09e48493          	addi	s1,s1,158 # 80010fa0 <proc>
    80001f0a:	a811                	j	80001f1e <scheduler+0x74>
      release(&p->lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	d7c080e7          	jalr	-644(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f16:	16848493          	addi	s1,s1,360
    80001f1a:	fd248ee3          	beq	s1,s2,80001ef6 <scheduler+0x4c>
      acquire(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	cb6080e7          	jalr	-842(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f28:	4c9c                	lw	a5,24(s1)
    80001f2a:	ff3791e3          	bne	a5,s3,80001f0c <scheduler+0x62>
        p->state = RUNNING;
    80001f2e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f32:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f36:	06048593          	addi	a1,s1,96
    80001f3a:	8556                	mv	a0,s5
    80001f3c:	00000097          	auipc	ra,0x0
    80001f40:	682080e7          	jalr	1666(ra) # 800025be <swtch>
        c->proc = 0;
    80001f44:	020a3823          	sd	zero,48(s4)
    80001f48:	b7d1                	j	80001f0c <scheduler+0x62>

0000000080001f4a <sched>:
{
    80001f4a:	7179                	addi	sp,sp,-48
    80001f4c:	f406                	sd	ra,40(sp)
    80001f4e:	f022                	sd	s0,32(sp)
    80001f50:	ec26                	sd	s1,24(sp)
    80001f52:	e84a                	sd	s2,16(sp)
    80001f54:	e44e                	sd	s3,8(sp)
    80001f56:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f58:	00000097          	auipc	ra,0x0
    80001f5c:	a5c080e7          	jalr	-1444(ra) # 800019b4 <myproc>
    80001f60:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	bfa080e7          	jalr	-1030(ra) # 80000b5c <holding>
    80001f6a:	c93d                	beqz	a0,80001fe0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f6c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f6e:	2781                	sext.w	a5,a5
    80001f70:	079e                	slli	a5,a5,0x7
    80001f72:	0000f717          	auipc	a4,0xf
    80001f76:	bfe70713          	addi	a4,a4,-1026 # 80010b70 <pid_lock>
    80001f7a:	97ba                	add	a5,a5,a4
    80001f7c:	0a87a703          	lw	a4,168(a5)
    80001f80:	4785                	li	a5,1
    80001f82:	06f71763          	bne	a4,a5,80001ff0 <sched+0xa6>
  if(p->state == RUNNING)
    80001f86:	4c98                	lw	a4,24(s1)
    80001f88:	4791                	li	a5,4
    80001f8a:	06f70b63          	beq	a4,a5,80002000 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f8e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f92:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f94:	efb5                	bnez	a5,80002010 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f96:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f98:	0000f917          	auipc	s2,0xf
    80001f9c:	bd890913          	addi	s2,s2,-1064 # 80010b70 <pid_lock>
    80001fa0:	2781                	sext.w	a5,a5
    80001fa2:	079e                	slli	a5,a5,0x7
    80001fa4:	97ca                	add	a5,a5,s2
    80001fa6:	0ac7a983          	lw	s3,172(a5)
    80001faa:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fac:	2781                	sext.w	a5,a5
    80001fae:	079e                	slli	a5,a5,0x7
    80001fb0:	0000f597          	auipc	a1,0xf
    80001fb4:	bf858593          	addi	a1,a1,-1032 # 80010ba8 <cpus+0x8>
    80001fb8:	95be                	add	a1,a1,a5
    80001fba:	06048513          	addi	a0,s1,96
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	600080e7          	jalr	1536(ra) # 800025be <swtch>
    80001fc6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc8:	2781                	sext.w	a5,a5
    80001fca:	079e                	slli	a5,a5,0x7
    80001fcc:	97ca                	add	a5,a5,s2
    80001fce:	0b37a623          	sw	s3,172(a5)
}
    80001fd2:	70a2                	ld	ra,40(sp)
    80001fd4:	7402                	ld	s0,32(sp)
    80001fd6:	64e2                	ld	s1,24(sp)
    80001fd8:	6942                	ld	s2,16(sp)
    80001fda:	69a2                	ld	s3,8(sp)
    80001fdc:	6145                	addi	sp,sp,48
    80001fde:	8082                	ret
    panic("sched p->lock");
    80001fe0:	00006517          	auipc	a0,0x6
    80001fe4:	23850513          	addi	a0,a0,568 # 80008218 <digits+0x1d8>
    80001fe8:	ffffe097          	auipc	ra,0xffffe
    80001fec:	556080e7          	jalr	1366(ra) # 8000053e <panic>
    panic("sched locks");
    80001ff0:	00006517          	auipc	a0,0x6
    80001ff4:	23850513          	addi	a0,a0,568 # 80008228 <digits+0x1e8>
    80001ff8:	ffffe097          	auipc	ra,0xffffe
    80001ffc:	546080e7          	jalr	1350(ra) # 8000053e <panic>
    panic("sched running");
    80002000:	00006517          	auipc	a0,0x6
    80002004:	23850513          	addi	a0,a0,568 # 80008238 <digits+0x1f8>
    80002008:	ffffe097          	auipc	ra,0xffffe
    8000200c:	536080e7          	jalr	1334(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002010:	00006517          	auipc	a0,0x6
    80002014:	23850513          	addi	a0,a0,568 # 80008248 <digits+0x208>
    80002018:	ffffe097          	auipc	ra,0xffffe
    8000201c:	526080e7          	jalr	1318(ra) # 8000053e <panic>

0000000080002020 <yield>:
{
    80002020:	1101                	addi	sp,sp,-32
    80002022:	ec06                	sd	ra,24(sp)
    80002024:	e822                	sd	s0,16(sp)
    80002026:	e426                	sd	s1,8(sp)
    80002028:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	98a080e7          	jalr	-1654(ra) # 800019b4 <myproc>
    80002032:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	ba2080e7          	jalr	-1118(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000203c:	478d                	li	a5,3
    8000203e:	cc9c                	sw	a5,24(s1)
  sched();
    80002040:	00000097          	auipc	ra,0x0
    80002044:	f0a080e7          	jalr	-246(ra) # 80001f4a <sched>
  release(&p->lock);
    80002048:	8526                	mv	a0,s1
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	c40080e7          	jalr	-960(ra) # 80000c8a <release>
}
    80002052:	60e2                	ld	ra,24(sp)
    80002054:	6442                	ld	s0,16(sp)
    80002056:	64a2                	ld	s1,8(sp)
    80002058:	6105                	addi	sp,sp,32
    8000205a:	8082                	ret

000000008000205c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000205c:	7179                	addi	sp,sp,-48
    8000205e:	f406                	sd	ra,40(sp)
    80002060:	f022                	sd	s0,32(sp)
    80002062:	ec26                	sd	s1,24(sp)
    80002064:	e84a                	sd	s2,16(sp)
    80002066:	e44e                	sd	s3,8(sp)
    80002068:	1800                	addi	s0,sp,48
    8000206a:	89aa                	mv	s3,a0
    8000206c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	946080e7          	jalr	-1722(ra) # 800019b4 <myproc>
    80002076:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	b5e080e7          	jalr	-1186(ra) # 80000bd6 <acquire>
  release(lk);
    80002080:	854a                	mv	a0,s2
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	c08080e7          	jalr	-1016(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000208a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000208e:	4789                	li	a5,2
    80002090:	cc9c                	sw	a5,24(s1)

  sched();
    80002092:	00000097          	auipc	ra,0x0
    80002096:	eb8080e7          	jalr	-328(ra) # 80001f4a <sched>

  // Tidy up.
  p->chan = 0;
    8000209a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000209e:	8526                	mv	a0,s1
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	bea080e7          	jalr	-1046(ra) # 80000c8a <release>
  acquire(lk);
    800020a8:	854a                	mv	a0,s2
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	b2c080e7          	jalr	-1236(ra) # 80000bd6 <acquire>
}
    800020b2:	70a2                	ld	ra,40(sp)
    800020b4:	7402                	ld	s0,32(sp)
    800020b6:	64e2                	ld	s1,24(sp)
    800020b8:	6942                	ld	s2,16(sp)
    800020ba:	69a2                	ld	s3,8(sp)
    800020bc:	6145                	addi	sp,sp,48
    800020be:	8082                	ret

00000000800020c0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020c0:	7139                	addi	sp,sp,-64
    800020c2:	fc06                	sd	ra,56(sp)
    800020c4:	f822                	sd	s0,48(sp)
    800020c6:	f426                	sd	s1,40(sp)
    800020c8:	f04a                	sd	s2,32(sp)
    800020ca:	ec4e                	sd	s3,24(sp)
    800020cc:	e852                	sd	s4,16(sp)
    800020ce:	e456                	sd	s5,8(sp)
    800020d0:	0080                	addi	s0,sp,64
    800020d2:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020d4:	0000f497          	auipc	s1,0xf
    800020d8:	ecc48493          	addi	s1,s1,-308 # 80010fa0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020dc:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020de:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020e0:	00015917          	auipc	s2,0x15
    800020e4:	8c090913          	addi	s2,s2,-1856 # 800169a0 <tickslock>
    800020e8:	a811                	j	800020fc <wakeup+0x3c>
      }
      release(&p->lock);
    800020ea:	8526                	mv	a0,s1
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	b9e080e7          	jalr	-1122(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020f4:	16848493          	addi	s1,s1,360
    800020f8:	03248663          	beq	s1,s2,80002124 <wakeup+0x64>
    if(p != myproc()){
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	8b8080e7          	jalr	-1864(ra) # 800019b4 <myproc>
    80002104:	fea488e3          	beq	s1,a0,800020f4 <wakeup+0x34>
      acquire(&p->lock);
    80002108:	8526                	mv	a0,s1
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	acc080e7          	jalr	-1332(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002112:	4c9c                	lw	a5,24(s1)
    80002114:	fd379be3          	bne	a5,s3,800020ea <wakeup+0x2a>
    80002118:	709c                	ld	a5,32(s1)
    8000211a:	fd4798e3          	bne	a5,s4,800020ea <wakeup+0x2a>
        p->state = RUNNABLE;
    8000211e:	0154ac23          	sw	s5,24(s1)
    80002122:	b7e1                	j	800020ea <wakeup+0x2a>
    }
  }
}
    80002124:	70e2                	ld	ra,56(sp)
    80002126:	7442                	ld	s0,48(sp)
    80002128:	74a2                	ld	s1,40(sp)
    8000212a:	7902                	ld	s2,32(sp)
    8000212c:	69e2                	ld	s3,24(sp)
    8000212e:	6a42                	ld	s4,16(sp)
    80002130:	6aa2                	ld	s5,8(sp)
    80002132:	6121                	addi	sp,sp,64
    80002134:	8082                	ret

0000000080002136 <reparent>:
{
    80002136:	7179                	addi	sp,sp,-48
    80002138:	f406                	sd	ra,40(sp)
    8000213a:	f022                	sd	s0,32(sp)
    8000213c:	ec26                	sd	s1,24(sp)
    8000213e:	e84a                	sd	s2,16(sp)
    80002140:	e44e                	sd	s3,8(sp)
    80002142:	e052                	sd	s4,0(sp)
    80002144:	1800                	addi	s0,sp,48
    80002146:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002148:	0000f497          	auipc	s1,0xf
    8000214c:	e5848493          	addi	s1,s1,-424 # 80010fa0 <proc>
      pp->parent = initproc;
    80002150:	00006a17          	auipc	s4,0x6
    80002154:	7a8a0a13          	addi	s4,s4,1960 # 800088f8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002158:	00015997          	auipc	s3,0x15
    8000215c:	84898993          	addi	s3,s3,-1976 # 800169a0 <tickslock>
    80002160:	a029                	j	8000216a <reparent+0x34>
    80002162:	16848493          	addi	s1,s1,360
    80002166:	01348d63          	beq	s1,s3,80002180 <reparent+0x4a>
    if(pp->parent == p){
    8000216a:	7c9c                	ld	a5,56(s1)
    8000216c:	ff279be3          	bne	a5,s2,80002162 <reparent+0x2c>
      pp->parent = initproc;
    80002170:	000a3503          	ld	a0,0(s4)
    80002174:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002176:	00000097          	auipc	ra,0x0
    8000217a:	f4a080e7          	jalr	-182(ra) # 800020c0 <wakeup>
    8000217e:	b7d5                	j	80002162 <reparent+0x2c>
}
    80002180:	70a2                	ld	ra,40(sp)
    80002182:	7402                	ld	s0,32(sp)
    80002184:	64e2                	ld	s1,24(sp)
    80002186:	6942                	ld	s2,16(sp)
    80002188:	69a2                	ld	s3,8(sp)
    8000218a:	6a02                	ld	s4,0(sp)
    8000218c:	6145                	addi	sp,sp,48
    8000218e:	8082                	ret

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
    800021a6:	812080e7          	jalr	-2030(ra) # 800019b4 <myproc>
    800021aa:	89aa                	mv	s3,a0
  if(p == initproc)
    800021ac:	00006797          	auipc	a5,0x6
    800021b0:	74c7b783          	ld	a5,1868(a5) # 800088f8 <initproc>
    800021b4:	0d050493          	addi	s1,a0,208
    800021b8:	15050913          	addi	s2,a0,336
    800021bc:	02a79363          	bne	a5,a0,800021e2 <exit+0x52>
    panic("init exiting");
    800021c0:	00006517          	auipc	a0,0x6
    800021c4:	0a050513          	addi	a0,a0,160 # 80008260 <digits+0x220>
    800021c8:	ffffe097          	auipc	ra,0xffffe
    800021cc:	376080e7          	jalr	886(ra) # 8000053e <panic>
      fileclose(f);
    800021d0:	00002097          	auipc	ra,0x2
    800021d4:	47e080e7          	jalr	1150(ra) # 8000464e <fileclose>
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
    800021ec:	f9a080e7          	jalr	-102(ra) # 80004182 <begin_op>
  iput(p->cwd);
    800021f0:	1509b503          	ld	a0,336(s3)
    800021f4:	00001097          	auipc	ra,0x1
    800021f8:	786080e7          	jalr	1926(ra) # 8000397a <iput>
  end_op();
    800021fc:	00002097          	auipc	ra,0x2
    80002200:	006080e7          	jalr	6(ra) # 80004202 <end_op>
  p->cwd = 0;
    80002204:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002208:	0000f497          	auipc	s1,0xf
    8000220c:	98048493          	addi	s1,s1,-1664 # 80010b88 <wait_lock>
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	9c4080e7          	jalr	-1596(ra) # 80000bd6 <acquire>
  reparent(p);
    8000221a:	854e                	mv	a0,s3
    8000221c:	00000097          	auipc	ra,0x0
    80002220:	f1a080e7          	jalr	-230(ra) # 80002136 <reparent>
  wakeup(p->parent);
    80002224:	0389b503          	ld	a0,56(s3)
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	e98080e7          	jalr	-360(ra) # 800020c0 <wakeup>
  acquire(&p->lock);
    80002230:	854e                	mv	a0,s3
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	9a4080e7          	jalr	-1628(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000223a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000223e:	4795                	li	a5,5
    80002240:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a44080e7          	jalr	-1468(ra) # 80000c8a <release>
  sched();
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	cfc080e7          	jalr	-772(ra) # 80001f4a <sched>
  panic("zombie exit");
    80002256:	00006517          	auipc	a0,0x6
    8000225a:	01a50513          	addi	a0,a0,26 # 80008270 <digits+0x230>
    8000225e:	ffffe097          	auipc	ra,0xffffe
    80002262:	2e0080e7          	jalr	736(ra) # 8000053e <panic>

0000000080002266 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002266:	7179                	addi	sp,sp,-48
    80002268:	f406                	sd	ra,40(sp)
    8000226a:	f022                	sd	s0,32(sp)
    8000226c:	ec26                	sd	s1,24(sp)
    8000226e:	e84a                	sd	s2,16(sp)
    80002270:	e44e                	sd	s3,8(sp)
    80002272:	1800                	addi	s0,sp,48
    80002274:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002276:	0000f497          	auipc	s1,0xf
    8000227a:	d2a48493          	addi	s1,s1,-726 # 80010fa0 <proc>
    8000227e:	00014997          	auipc	s3,0x14
    80002282:	72298993          	addi	s3,s3,1826 # 800169a0 <tickslock>
    acquire(&p->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	94e080e7          	jalr	-1714(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002290:	589c                	lw	a5,48(s1)
    80002292:	01278d63          	beq	a5,s2,800022ac <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002296:	8526                	mv	a0,s1
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	9f2080e7          	jalr	-1550(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022a0:	16848493          	addi	s1,s1,360
    800022a4:	ff3491e3          	bne	s1,s3,80002286 <kill+0x20>
  }
  return -1;
    800022a8:	557d                	li	a0,-1
    800022aa:	a829                	j	800022c4 <kill+0x5e>
      p->killed = 1;
    800022ac:	4785                	li	a5,1
    800022ae:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022b0:	4c98                	lw	a4,24(s1)
    800022b2:	4789                	li	a5,2
    800022b4:	00f70f63          	beq	a4,a5,800022d2 <kill+0x6c>
      release(&p->lock);
    800022b8:	8526                	mv	a0,s1
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	9d0080e7          	jalr	-1584(ra) # 80000c8a <release>
      return 0;
    800022c2:	4501                	li	a0,0
}
    800022c4:	70a2                	ld	ra,40(sp)
    800022c6:	7402                	ld	s0,32(sp)
    800022c8:	64e2                	ld	s1,24(sp)
    800022ca:	6942                	ld	s2,16(sp)
    800022cc:	69a2                	ld	s3,8(sp)
    800022ce:	6145                	addi	sp,sp,48
    800022d0:	8082                	ret
        p->state = RUNNABLE;
    800022d2:	478d                	li	a5,3
    800022d4:	cc9c                	sw	a5,24(s1)
    800022d6:	b7cd                	j	800022b8 <kill+0x52>

00000000800022d8 <setkilled>:

void
setkilled(struct proc *p)
{
    800022d8:	1101                	addi	sp,sp,-32
    800022da:	ec06                	sd	ra,24(sp)
    800022dc:	e822                	sd	s0,16(sp)
    800022de:	e426                	sd	s1,8(sp)
    800022e0:	1000                	addi	s0,sp,32
    800022e2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	8f2080e7          	jalr	-1806(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022ec:	4785                	li	a5,1
    800022ee:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022f0:	8526                	mv	a0,s1
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	998080e7          	jalr	-1640(ra) # 80000c8a <release>
}
    800022fa:	60e2                	ld	ra,24(sp)
    800022fc:	6442                	ld	s0,16(sp)
    800022fe:	64a2                	ld	s1,8(sp)
    80002300:	6105                	addi	sp,sp,32
    80002302:	8082                	ret

0000000080002304 <killed>:

int
killed(struct proc *p)
{
    80002304:	1101                	addi	sp,sp,-32
    80002306:	ec06                	sd	ra,24(sp)
    80002308:	e822                	sd	s0,16(sp)
    8000230a:	e426                	sd	s1,8(sp)
    8000230c:	e04a                	sd	s2,0(sp)
    8000230e:	1000                	addi	s0,sp,32
    80002310:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	8c4080e7          	jalr	-1852(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000231a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	96a080e7          	jalr	-1686(ra) # 80000c8a <release>
  return k;
}
    80002328:	854a                	mv	a0,s2
    8000232a:	60e2                	ld	ra,24(sp)
    8000232c:	6442                	ld	s0,16(sp)
    8000232e:	64a2                	ld	s1,8(sp)
    80002330:	6902                	ld	s2,0(sp)
    80002332:	6105                	addi	sp,sp,32
    80002334:	8082                	ret

0000000080002336 <wait>:
{
    80002336:	715d                	addi	sp,sp,-80
    80002338:	e486                	sd	ra,72(sp)
    8000233a:	e0a2                	sd	s0,64(sp)
    8000233c:	fc26                	sd	s1,56(sp)
    8000233e:	f84a                	sd	s2,48(sp)
    80002340:	f44e                	sd	s3,40(sp)
    80002342:	f052                	sd	s4,32(sp)
    80002344:	ec56                	sd	s5,24(sp)
    80002346:	e85a                	sd	s6,16(sp)
    80002348:	e45e                	sd	s7,8(sp)
    8000234a:	e062                	sd	s8,0(sp)
    8000234c:	0880                	addi	s0,sp,80
    8000234e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	664080e7          	jalr	1636(ra) # 800019b4 <myproc>
    80002358:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000235a:	0000f517          	auipc	a0,0xf
    8000235e:	82e50513          	addi	a0,a0,-2002 # 80010b88 <wait_lock>
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	874080e7          	jalr	-1932(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000236a:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000236c:	4a15                	li	s4,5
        havekids = 1;
    8000236e:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002370:	00014997          	auipc	s3,0x14
    80002374:	63098993          	addi	s3,s3,1584 # 800169a0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002378:	0000fc17          	auipc	s8,0xf
    8000237c:	810c0c13          	addi	s8,s8,-2032 # 80010b88 <wait_lock>
    havekids = 0;
    80002380:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002382:	0000f497          	auipc	s1,0xf
    80002386:	c1e48493          	addi	s1,s1,-994 # 80010fa0 <proc>
    8000238a:	a0bd                	j	800023f8 <wait+0xc2>
          pid = pp->pid;
    8000238c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002390:	000b0e63          	beqz	s6,800023ac <wait+0x76>
    80002394:	4691                	li	a3,4
    80002396:	02c48613          	addi	a2,s1,44
    8000239a:	85da                	mv	a1,s6
    8000239c:	05093503          	ld	a0,80(s2)
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	2d0080e7          	jalr	720(ra) # 80001670 <copyout>
    800023a8:	02054563          	bltz	a0,800023d2 <wait+0x9c>
          freeproc(pp);
    800023ac:	8526                	mv	a0,s1
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	7b8080e7          	jalr	1976(ra) # 80001b66 <freeproc>
          release(&pp->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	8d2080e7          	jalr	-1838(ra) # 80000c8a <release>
          release(&wait_lock);
    800023c0:	0000e517          	auipc	a0,0xe
    800023c4:	7c850513          	addi	a0,a0,1992 # 80010b88 <wait_lock>
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8c2080e7          	jalr	-1854(ra) # 80000c8a <release>
          return pid;
    800023d0:	a0b5                	j	8000243c <wait+0x106>
            release(&pp->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8b6080e7          	jalr	-1866(ra) # 80000c8a <release>
            release(&wait_lock);
    800023dc:	0000e517          	auipc	a0,0xe
    800023e0:	7ac50513          	addi	a0,a0,1964 # 80010b88 <wait_lock>
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8a6080e7          	jalr	-1882(ra) # 80000c8a <release>
            return -1;
    800023ec:	59fd                	li	s3,-1
    800023ee:	a0b9                	j	8000243c <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f0:	16848493          	addi	s1,s1,360
    800023f4:	03348463          	beq	s1,s3,8000241c <wait+0xe6>
      if(pp->parent == p){
    800023f8:	7c9c                	ld	a5,56(s1)
    800023fa:	ff279be3          	bne	a5,s2,800023f0 <wait+0xba>
        acquire(&pp->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7d6080e7          	jalr	2006(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002408:	4c9c                	lw	a5,24(s1)
    8000240a:	f94781e3          	beq	a5,s4,8000238c <wait+0x56>
        release(&pp->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	87a080e7          	jalr	-1926(ra) # 80000c8a <release>
        havekids = 1;
    80002418:	8756                	mv	a4,s5
    8000241a:	bfd9                	j	800023f0 <wait+0xba>
    if(!havekids || killed(p)){
    8000241c:	c719                	beqz	a4,8000242a <wait+0xf4>
    8000241e:	854a                	mv	a0,s2
    80002420:	00000097          	auipc	ra,0x0
    80002424:	ee4080e7          	jalr	-284(ra) # 80002304 <killed>
    80002428:	c51d                	beqz	a0,80002456 <wait+0x120>
      release(&wait_lock);
    8000242a:	0000e517          	auipc	a0,0xe
    8000242e:	75e50513          	addi	a0,a0,1886 # 80010b88 <wait_lock>
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	858080e7          	jalr	-1960(ra) # 80000c8a <release>
      return -1;
    8000243a:	59fd                	li	s3,-1
}
    8000243c:	854e                	mv	a0,s3
    8000243e:	60a6                	ld	ra,72(sp)
    80002440:	6406                	ld	s0,64(sp)
    80002442:	74e2                	ld	s1,56(sp)
    80002444:	7942                	ld	s2,48(sp)
    80002446:	79a2                	ld	s3,40(sp)
    80002448:	7a02                	ld	s4,32(sp)
    8000244a:	6ae2                	ld	s5,24(sp)
    8000244c:	6b42                	ld	s6,16(sp)
    8000244e:	6ba2                	ld	s7,8(sp)
    80002450:	6c02                	ld	s8,0(sp)
    80002452:	6161                	addi	sp,sp,80
    80002454:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002456:	85e2                	mv	a1,s8
    80002458:	854a                	mv	a0,s2
    8000245a:	00000097          	auipc	ra,0x0
    8000245e:	c02080e7          	jalr	-1022(ra) # 8000205c <sleep>
    havekids = 0;
    80002462:	bf39                	j	80002380 <wait+0x4a>

0000000080002464 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002464:	7179                	addi	sp,sp,-48
    80002466:	f406                	sd	ra,40(sp)
    80002468:	f022                	sd	s0,32(sp)
    8000246a:	ec26                	sd	s1,24(sp)
    8000246c:	e84a                	sd	s2,16(sp)
    8000246e:	e44e                	sd	s3,8(sp)
    80002470:	e052                	sd	s4,0(sp)
    80002472:	1800                	addi	s0,sp,48
    80002474:	84aa                	mv	s1,a0
    80002476:	892e                	mv	s2,a1
    80002478:	89b2                	mv	s3,a2
    8000247a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	538080e7          	jalr	1336(ra) # 800019b4 <myproc>
  if(user_dst){
    80002484:	c08d                	beqz	s1,800024a6 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002486:	86d2                	mv	a3,s4
    80002488:	864e                	mv	a2,s3
    8000248a:	85ca                	mv	a1,s2
    8000248c:	6928                	ld	a0,80(a0)
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	1e2080e7          	jalr	482(ra) # 80001670 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6a02                	ld	s4,0(sp)
    800024a2:	6145                	addi	sp,sp,48
    800024a4:	8082                	ret
    memmove((char *)dst, src, len);
    800024a6:	000a061b          	sext.w	a2,s4
    800024aa:	85ce                	mv	a1,s3
    800024ac:	854a                	mv	a0,s2
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	880080e7          	jalr	-1920(ra) # 80000d2e <memmove>
    return 0;
    800024b6:	8526                	mv	a0,s1
    800024b8:	bff9                	j	80002496 <either_copyout+0x32>

00000000800024ba <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ba:	7179                	addi	sp,sp,-48
    800024bc:	f406                	sd	ra,40(sp)
    800024be:	f022                	sd	s0,32(sp)
    800024c0:	ec26                	sd	s1,24(sp)
    800024c2:	e84a                	sd	s2,16(sp)
    800024c4:	e44e                	sd	s3,8(sp)
    800024c6:	e052                	sd	s4,0(sp)
    800024c8:	1800                	addi	s0,sp,48
    800024ca:	892a                	mv	s2,a0
    800024cc:	84ae                	mv	s1,a1
    800024ce:	89b2                	mv	s3,a2
    800024d0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	4e2080e7          	jalr	1250(ra) # 800019b4 <myproc>
  if(user_src){
    800024da:	c08d                	beqz	s1,800024fc <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024dc:	86d2                	mv	a3,s4
    800024de:	864e                	mv	a2,s3
    800024e0:	85ca                	mv	a1,s2
    800024e2:	6928                	ld	a0,80(a0)
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	218080e7          	jalr	536(ra) # 800016fc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024ec:	70a2                	ld	ra,40(sp)
    800024ee:	7402                	ld	s0,32(sp)
    800024f0:	64e2                	ld	s1,24(sp)
    800024f2:	6942                	ld	s2,16(sp)
    800024f4:	69a2                	ld	s3,8(sp)
    800024f6:	6a02                	ld	s4,0(sp)
    800024f8:	6145                	addi	sp,sp,48
    800024fa:	8082                	ret
    memmove(dst, (char*)src, len);
    800024fc:	000a061b          	sext.w	a2,s4
    80002500:	85ce                	mv	a1,s3
    80002502:	854a                	mv	a0,s2
    80002504:	fffff097          	auipc	ra,0xfffff
    80002508:	82a080e7          	jalr	-2006(ra) # 80000d2e <memmove>
    return 0;
    8000250c:	8526                	mv	a0,s1
    8000250e:	bff9                	j	800024ec <either_copyin+0x32>

0000000080002510 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002510:	715d                	addi	sp,sp,-80
    80002512:	e486                	sd	ra,72(sp)
    80002514:	e0a2                	sd	s0,64(sp)
    80002516:	fc26                	sd	s1,56(sp)
    80002518:	f84a                	sd	s2,48(sp)
    8000251a:	f44e                	sd	s3,40(sp)
    8000251c:	f052                	sd	s4,32(sp)
    8000251e:	ec56                	sd	s5,24(sp)
    80002520:	e85a                	sd	s6,16(sp)
    80002522:	e45e                	sd	s7,8(sp)
    80002524:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002526:	00006517          	auipc	a0,0x6
    8000252a:	ba250513          	addi	a0,a0,-1118 # 800080c8 <digits+0x88>
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	05a080e7          	jalr	90(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002536:	0000f497          	auipc	s1,0xf
    8000253a:	bc248493          	addi	s1,s1,-1086 # 800110f8 <proc+0x158>
    8000253e:	00014917          	auipc	s2,0x14
    80002542:	5ba90913          	addi	s2,s2,1466 # 80016af8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002546:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002548:	00006997          	auipc	s3,0x6
    8000254c:	d3898993          	addi	s3,s3,-712 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002550:	00006a97          	auipc	s5,0x6
    80002554:	d38a8a93          	addi	s5,s5,-712 # 80008288 <digits+0x248>
    printf("\n");
    80002558:	00006a17          	auipc	s4,0x6
    8000255c:	b70a0a13          	addi	s4,s4,-1168 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002560:	00006b97          	auipc	s7,0x6
    80002564:	d68b8b93          	addi	s7,s7,-664 # 800082c8 <states.0>
    80002568:	a00d                	j	8000258a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000256a:	ed86a583          	lw	a1,-296(a3)
    8000256e:	8556                	mv	a0,s5
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	018080e7          	jalr	24(ra) # 80000588 <printf>
    printf("\n");
    80002578:	8552                	mv	a0,s4
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	00e080e7          	jalr	14(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002582:	16848493          	addi	s1,s1,360
    80002586:	03248163          	beq	s1,s2,800025a8 <procdump+0x98>
    if(p->state == UNUSED)
    8000258a:	86a6                	mv	a3,s1
    8000258c:	ec04a783          	lw	a5,-320(s1)
    80002590:	dbed                	beqz	a5,80002582 <procdump+0x72>
      state = "???";
    80002592:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002594:	fcfb6be3          	bltu	s6,a5,8000256a <procdump+0x5a>
    80002598:	1782                	slli	a5,a5,0x20
    8000259a:	9381                	srli	a5,a5,0x20
    8000259c:	078e                	slli	a5,a5,0x3
    8000259e:	97de                	add	a5,a5,s7
    800025a0:	6390                	ld	a2,0(a5)
    800025a2:	f661                	bnez	a2,8000256a <procdump+0x5a>
      state = "???";
    800025a4:	864e                	mv	a2,s3
    800025a6:	b7d1                	j	8000256a <procdump+0x5a>
  }
}
    800025a8:	60a6                	ld	ra,72(sp)
    800025aa:	6406                	ld	s0,64(sp)
    800025ac:	74e2                	ld	s1,56(sp)
    800025ae:	7942                	ld	s2,48(sp)
    800025b0:	79a2                	ld	s3,40(sp)
    800025b2:	7a02                	ld	s4,32(sp)
    800025b4:	6ae2                	ld	s5,24(sp)
    800025b6:	6b42                	ld	s6,16(sp)
    800025b8:	6ba2                	ld	s7,8(sp)
    800025ba:	6161                	addi	sp,sp,80
    800025bc:	8082                	ret

00000000800025be <swtch>:
    800025be:	00153023          	sd	ra,0(a0)
    800025c2:	00253423          	sd	sp,8(a0)
    800025c6:	e900                	sd	s0,16(a0)
    800025c8:	ed04                	sd	s1,24(a0)
    800025ca:	03253023          	sd	s2,32(a0)
    800025ce:	03353423          	sd	s3,40(a0)
    800025d2:	03453823          	sd	s4,48(a0)
    800025d6:	03553c23          	sd	s5,56(a0)
    800025da:	05653023          	sd	s6,64(a0)
    800025de:	05753423          	sd	s7,72(a0)
    800025e2:	05853823          	sd	s8,80(a0)
    800025e6:	05953c23          	sd	s9,88(a0)
    800025ea:	07a53023          	sd	s10,96(a0)
    800025ee:	07b53423          	sd	s11,104(a0)
    800025f2:	0005b083          	ld	ra,0(a1)
    800025f6:	0085b103          	ld	sp,8(a1)
    800025fa:	6980                	ld	s0,16(a1)
    800025fc:	6d84                	ld	s1,24(a1)
    800025fe:	0205b903          	ld	s2,32(a1)
    80002602:	0285b983          	ld	s3,40(a1)
    80002606:	0305ba03          	ld	s4,48(a1)
    8000260a:	0385ba83          	ld	s5,56(a1)
    8000260e:	0405bb03          	ld	s6,64(a1)
    80002612:	0485bb83          	ld	s7,72(a1)
    80002616:	0505bc03          	ld	s8,80(a1)
    8000261a:	0585bc83          	ld	s9,88(a1)
    8000261e:	0605bd03          	ld	s10,96(a1)
    80002622:	0685bd83          	ld	s11,104(a1)
    80002626:	8082                	ret

0000000080002628 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002628:	1141                	addi	sp,sp,-16
    8000262a:	e406                	sd	ra,8(sp)
    8000262c:	e022                	sd	s0,0(sp)
    8000262e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002630:	00006597          	auipc	a1,0x6
    80002634:	cc858593          	addi	a1,a1,-824 # 800082f8 <states.0+0x30>
    80002638:	00014517          	auipc	a0,0x14
    8000263c:	36850513          	addi	a0,a0,872 # 800169a0 <tickslock>
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	506080e7          	jalr	1286(ra) # 80000b46 <initlock>
}
    80002648:	60a2                	ld	ra,8(sp)
    8000264a:	6402                	ld	s0,0(sp)
    8000264c:	0141                	addi	sp,sp,16
    8000264e:	8082                	ret

0000000080002650 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002650:	1141                	addi	sp,sp,-16
    80002652:	e422                	sd	s0,8(sp)
    80002654:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002656:	00003797          	auipc	a5,0x3
    8000265a:	64a78793          	addi	a5,a5,1610 # 80005ca0 <kernelvec>
    8000265e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002662:	6422                	ld	s0,8(sp)
    80002664:	0141                	addi	sp,sp,16
    80002666:	8082                	ret

0000000080002668 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002668:	1141                	addi	sp,sp,-16
    8000266a:	e406                	sd	ra,8(sp)
    8000266c:	e022                	sd	s0,0(sp)
    8000266e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002670:	fffff097          	auipc	ra,0xfffff
    80002674:	344080e7          	jalr	836(ra) # 800019b4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002678:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000267c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000267e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002682:	00005617          	auipc	a2,0x5
    80002686:	97e60613          	addi	a2,a2,-1666 # 80007000 <_trampoline>
    8000268a:	00005697          	auipc	a3,0x5
    8000268e:	97668693          	addi	a3,a3,-1674 # 80007000 <_trampoline>
    80002692:	8e91                	sub	a3,a3,a2
    80002694:	040007b7          	lui	a5,0x4000
    80002698:	17fd                	addi	a5,a5,-1
    8000269a:	07b2                	slli	a5,a5,0xc
    8000269c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000269e:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026a2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026a4:	180026f3          	csrr	a3,satp
    800026a8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026aa:	6d38                	ld	a4,88(a0)
    800026ac:	6134                	ld	a3,64(a0)
    800026ae:	6585                	lui	a1,0x1
    800026b0:	96ae                	add	a3,a3,a1
    800026b2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026b4:	6d38                	ld	a4,88(a0)
    800026b6:	00000697          	auipc	a3,0x0
    800026ba:	13068693          	addi	a3,a3,304 # 800027e6 <usertrap>
    800026be:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026c0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026c2:	8692                	mv	a3,tp
    800026c4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026ca:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026ce:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026d2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026d6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026d8:	6f18                	ld	a4,24(a4)
    800026da:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026de:	6928                	ld	a0,80(a0)
    800026e0:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026e2:	00005717          	auipc	a4,0x5
    800026e6:	9ba70713          	addi	a4,a4,-1606 # 8000709c <userret>
    800026ea:	8f11                	sub	a4,a4,a2
    800026ec:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800026ee:	577d                	li	a4,-1
    800026f0:	177e                	slli	a4,a4,0x3f
    800026f2:	8d59                	or	a0,a0,a4
    800026f4:	9782                	jalr	a5
}
    800026f6:	60a2                	ld	ra,8(sp)
    800026f8:	6402                	ld	s0,0(sp)
    800026fa:	0141                	addi	sp,sp,16
    800026fc:	8082                	ret

00000000800026fe <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026fe:	1101                	addi	sp,sp,-32
    80002700:	ec06                	sd	ra,24(sp)
    80002702:	e822                	sd	s0,16(sp)
    80002704:	e426                	sd	s1,8(sp)
    80002706:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002708:	00014497          	auipc	s1,0x14
    8000270c:	29848493          	addi	s1,s1,664 # 800169a0 <tickslock>
    80002710:	8526                	mv	a0,s1
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	4c4080e7          	jalr	1220(ra) # 80000bd6 <acquire>
  ticks++;
    8000271a:	00006517          	auipc	a0,0x6
    8000271e:	1e650513          	addi	a0,a0,486 # 80008900 <ticks>
    80002722:	411c                	lw	a5,0(a0)
    80002724:	2785                	addiw	a5,a5,1
    80002726:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002728:	00000097          	auipc	ra,0x0
    8000272c:	998080e7          	jalr	-1640(ra) # 800020c0 <wakeup>
  release(&tickslock);
    80002730:	8526                	mv	a0,s1
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	558080e7          	jalr	1368(ra) # 80000c8a <release>
}
    8000273a:	60e2                	ld	ra,24(sp)
    8000273c:	6442                	ld	s0,16(sp)
    8000273e:	64a2                	ld	s1,8(sp)
    80002740:	6105                	addi	sp,sp,32
    80002742:	8082                	ret

0000000080002744 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002744:	1101                	addi	sp,sp,-32
    80002746:	ec06                	sd	ra,24(sp)
    80002748:	e822                	sd	s0,16(sp)
    8000274a:	e426                	sd	s1,8(sp)
    8000274c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000274e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002752:	00074d63          	bltz	a4,8000276c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002756:	57fd                	li	a5,-1
    80002758:	17fe                	slli	a5,a5,0x3f
    8000275a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000275c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000275e:	06f70363          	beq	a4,a5,800027c4 <devintr+0x80>
  }
}
    80002762:	60e2                	ld	ra,24(sp)
    80002764:	6442                	ld	s0,16(sp)
    80002766:	64a2                	ld	s1,8(sp)
    80002768:	6105                	addi	sp,sp,32
    8000276a:	8082                	ret
     (scause & 0xff) == 9){
    8000276c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002770:	46a5                	li	a3,9
    80002772:	fed792e3          	bne	a5,a3,80002756 <devintr+0x12>
    int irq = plic_claim();
    80002776:	00003097          	auipc	ra,0x3
    8000277a:	632080e7          	jalr	1586(ra) # 80005da8 <plic_claim>
    8000277e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002780:	47a9                	li	a5,10
    80002782:	02f50763          	beq	a0,a5,800027b0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002786:	4785                	li	a5,1
    80002788:	02f50963          	beq	a0,a5,800027ba <devintr+0x76>
    return 1;
    8000278c:	4505                	li	a0,1
    } else if(irq){
    8000278e:	d8f1                	beqz	s1,80002762 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002790:	85a6                	mv	a1,s1
    80002792:	00006517          	auipc	a0,0x6
    80002796:	b6e50513          	addi	a0,a0,-1170 # 80008300 <states.0+0x38>
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	dee080e7          	jalr	-530(ra) # 80000588 <printf>
      plic_complete(irq);
    800027a2:	8526                	mv	a0,s1
    800027a4:	00003097          	auipc	ra,0x3
    800027a8:	628080e7          	jalr	1576(ra) # 80005dcc <plic_complete>
    return 1;
    800027ac:	4505                	li	a0,1
    800027ae:	bf55                	j	80002762 <devintr+0x1e>
      uartintr();
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	1ea080e7          	jalr	490(ra) # 8000099a <uartintr>
    800027b8:	b7ed                	j	800027a2 <devintr+0x5e>
      virtio_disk_intr();
    800027ba:	00004097          	auipc	ra,0x4
    800027be:	ade080e7          	jalr	-1314(ra) # 80006298 <virtio_disk_intr>
    800027c2:	b7c5                	j	800027a2 <devintr+0x5e>
    if(cpuid() == 0){
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	1c4080e7          	jalr	452(ra) # 80001988 <cpuid>
    800027cc:	c901                	beqz	a0,800027dc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027ce:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027d2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027d4:	14479073          	csrw	sip,a5
    return 2;
    800027d8:	4509                	li	a0,2
    800027da:	b761                	j	80002762 <devintr+0x1e>
      clockintr();
    800027dc:	00000097          	auipc	ra,0x0
    800027e0:	f22080e7          	jalr	-222(ra) # 800026fe <clockintr>
    800027e4:	b7ed                	j	800027ce <devintr+0x8a>

00000000800027e6 <usertrap>:
{
    800027e6:	1101                	addi	sp,sp,-32
    800027e8:	ec06                	sd	ra,24(sp)
    800027ea:	e822                	sd	s0,16(sp)
    800027ec:	e426                	sd	s1,8(sp)
    800027ee:	e04a                	sd	s2,0(sp)
    800027f0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027f6:	1007f793          	andi	a5,a5,256
    800027fa:	e3b1                	bnez	a5,8000283e <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027fc:	00003797          	auipc	a5,0x3
    80002800:	4a478793          	addi	a5,a5,1188 # 80005ca0 <kernelvec>
    80002804:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002808:	fffff097          	auipc	ra,0xfffff
    8000280c:	1ac080e7          	jalr	428(ra) # 800019b4 <myproc>
    80002810:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002812:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002814:	14102773          	csrr	a4,sepc
    80002818:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000281a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000281e:	47a1                	li	a5,8
    80002820:	02f70763          	beq	a4,a5,8000284e <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002824:	00000097          	auipc	ra,0x0
    80002828:	f20080e7          	jalr	-224(ra) # 80002744 <devintr>
    8000282c:	892a                	mv	s2,a0
    8000282e:	c151                	beqz	a0,800028b2 <usertrap+0xcc>
  if(killed(p))
    80002830:	8526                	mv	a0,s1
    80002832:	00000097          	auipc	ra,0x0
    80002836:	ad2080e7          	jalr	-1326(ra) # 80002304 <killed>
    8000283a:	c929                	beqz	a0,8000288c <usertrap+0xa6>
    8000283c:	a099                	j	80002882 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    8000283e:	00006517          	auipc	a0,0x6
    80002842:	ae250513          	addi	a0,a0,-1310 # 80008320 <states.0+0x58>
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	cf8080e7          	jalr	-776(ra) # 8000053e <panic>
    if(killed(p))
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	ab6080e7          	jalr	-1354(ra) # 80002304 <killed>
    80002856:	e921                	bnez	a0,800028a6 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002858:	6cb8                	ld	a4,88(s1)
    8000285a:	6f1c                	ld	a5,24(a4)
    8000285c:	0791                	addi	a5,a5,4
    8000285e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002860:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002864:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002868:	10079073          	csrw	sstatus,a5
    syscall();
    8000286c:	00000097          	auipc	ra,0x0
    80002870:	2d4080e7          	jalr	724(ra) # 80002b40 <syscall>
  if(killed(p))
    80002874:	8526                	mv	a0,s1
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	a8e080e7          	jalr	-1394(ra) # 80002304 <killed>
    8000287e:	c911                	beqz	a0,80002892 <usertrap+0xac>
    80002880:	4901                	li	s2,0
    exit(-1);
    80002882:	557d                	li	a0,-1
    80002884:	00000097          	auipc	ra,0x0
    80002888:	90c080e7          	jalr	-1780(ra) # 80002190 <exit>
  if(which_dev == 2)
    8000288c:	4789                	li	a5,2
    8000288e:	04f90f63          	beq	s2,a5,800028ec <usertrap+0x106>
  usertrapret();
    80002892:	00000097          	auipc	ra,0x0
    80002896:	dd6080e7          	jalr	-554(ra) # 80002668 <usertrapret>
}
    8000289a:	60e2                	ld	ra,24(sp)
    8000289c:	6442                	ld	s0,16(sp)
    8000289e:	64a2                	ld	s1,8(sp)
    800028a0:	6902                	ld	s2,0(sp)
    800028a2:	6105                	addi	sp,sp,32
    800028a4:	8082                	ret
      exit(-1);
    800028a6:	557d                	li	a0,-1
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	8e8080e7          	jalr	-1816(ra) # 80002190 <exit>
    800028b0:	b765                	j	80002858 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028b6:	5890                	lw	a2,48(s1)
    800028b8:	00006517          	auipc	a0,0x6
    800028bc:	a8850513          	addi	a0,a0,-1400 # 80008340 <states.0+0x78>
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	cc8080e7          	jalr	-824(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028cc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028d0:	00006517          	auipc	a0,0x6
    800028d4:	aa050513          	addi	a0,a0,-1376 # 80008370 <states.0+0xa8>
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	cb0080e7          	jalr	-848(ra) # 80000588 <printf>
    setkilled(p);
    800028e0:	8526                	mv	a0,s1
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	9f6080e7          	jalr	-1546(ra) # 800022d8 <setkilled>
    800028ea:	b769                	j	80002874 <usertrap+0x8e>
    yield();
    800028ec:	fffff097          	auipc	ra,0xfffff
    800028f0:	734080e7          	jalr	1844(ra) # 80002020 <yield>
    800028f4:	bf79                	j	80002892 <usertrap+0xac>

00000000800028f6 <kerneltrap>:
{
    800028f6:	7179                	addi	sp,sp,-48
    800028f8:	f406                	sd	ra,40(sp)
    800028fa:	f022                	sd	s0,32(sp)
    800028fc:	ec26                	sd	s1,24(sp)
    800028fe:	e84a                	sd	s2,16(sp)
    80002900:	e44e                	sd	s3,8(sp)
    80002902:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002904:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002908:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000290c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002910:	1004f793          	andi	a5,s1,256
    80002914:	cb85                	beqz	a5,80002944 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002916:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000291a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000291c:	ef85                	bnez	a5,80002954 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	e26080e7          	jalr	-474(ra) # 80002744 <devintr>
    80002926:	cd1d                	beqz	a0,80002964 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002928:	4789                	li	a5,2
    8000292a:	06f50a63          	beq	a0,a5,8000299e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000292e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002932:	10049073          	csrw	sstatus,s1
}
    80002936:	70a2                	ld	ra,40(sp)
    80002938:	7402                	ld	s0,32(sp)
    8000293a:	64e2                	ld	s1,24(sp)
    8000293c:	6942                	ld	s2,16(sp)
    8000293e:	69a2                	ld	s3,8(sp)
    80002940:	6145                	addi	sp,sp,48
    80002942:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002944:	00006517          	auipc	a0,0x6
    80002948:	a4c50513          	addi	a0,a0,-1460 # 80008390 <states.0+0xc8>
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	bf2080e7          	jalr	-1038(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002954:	00006517          	auipc	a0,0x6
    80002958:	a6450513          	addi	a0,a0,-1436 # 800083b8 <states.0+0xf0>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	be2080e7          	jalr	-1054(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002964:	85ce                	mv	a1,s3
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	a7250513          	addi	a0,a0,-1422 # 800083d8 <states.0+0x110>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	c1a080e7          	jalr	-998(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002976:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000297a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000297e:	00006517          	auipc	a0,0x6
    80002982:	a6a50513          	addi	a0,a0,-1430 # 800083e8 <states.0+0x120>
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	c02080e7          	jalr	-1022(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000298e:	00006517          	auipc	a0,0x6
    80002992:	a7250513          	addi	a0,a0,-1422 # 80008400 <states.0+0x138>
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	ba8080e7          	jalr	-1112(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	016080e7          	jalr	22(ra) # 800019b4 <myproc>
    800029a6:	d541                	beqz	a0,8000292e <kerneltrap+0x38>
    800029a8:	fffff097          	auipc	ra,0xfffff
    800029ac:	00c080e7          	jalr	12(ra) # 800019b4 <myproc>
    800029b0:	4d18                	lw	a4,24(a0)
    800029b2:	4791                	li	a5,4
    800029b4:	f6f71de3          	bne	a4,a5,8000292e <kerneltrap+0x38>
    yield();
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	668080e7          	jalr	1640(ra) # 80002020 <yield>
    800029c0:	b7bd                	j	8000292e <kerneltrap+0x38>

00000000800029c2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029c2:	1101                	addi	sp,sp,-32
    800029c4:	ec06                	sd	ra,24(sp)
    800029c6:	e822                	sd	s0,16(sp)
    800029c8:	e426                	sd	s1,8(sp)
    800029ca:	1000                	addi	s0,sp,32
    800029cc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	fe6080e7          	jalr	-26(ra) # 800019b4 <myproc>
  switch (n) {
    800029d6:	4795                	li	a5,5
    800029d8:	0497e163          	bltu	a5,s1,80002a1a <argraw+0x58>
    800029dc:	048a                	slli	s1,s1,0x2
    800029de:	00006717          	auipc	a4,0x6
    800029e2:	a5a70713          	addi	a4,a4,-1446 # 80008438 <states.0+0x170>
    800029e6:	94ba                	add	s1,s1,a4
    800029e8:	409c                	lw	a5,0(s1)
    800029ea:	97ba                	add	a5,a5,a4
    800029ec:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029ee:	6d3c                	ld	a5,88(a0)
    800029f0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029f2:	60e2                	ld	ra,24(sp)
    800029f4:	6442                	ld	s0,16(sp)
    800029f6:	64a2                	ld	s1,8(sp)
    800029f8:	6105                	addi	sp,sp,32
    800029fa:	8082                	ret
    return p->trapframe->a1;
    800029fc:	6d3c                	ld	a5,88(a0)
    800029fe:	7fa8                	ld	a0,120(a5)
    80002a00:	bfcd                	j	800029f2 <argraw+0x30>
    return p->trapframe->a2;
    80002a02:	6d3c                	ld	a5,88(a0)
    80002a04:	63c8                	ld	a0,128(a5)
    80002a06:	b7f5                	j	800029f2 <argraw+0x30>
    return p->trapframe->a3;
    80002a08:	6d3c                	ld	a5,88(a0)
    80002a0a:	67c8                	ld	a0,136(a5)
    80002a0c:	b7dd                	j	800029f2 <argraw+0x30>
    return p->trapframe->a4;
    80002a0e:	6d3c                	ld	a5,88(a0)
    80002a10:	6bc8                	ld	a0,144(a5)
    80002a12:	b7c5                	j	800029f2 <argraw+0x30>
    return p->trapframe->a5;
    80002a14:	6d3c                	ld	a5,88(a0)
    80002a16:	6fc8                	ld	a0,152(a5)
    80002a18:	bfe9                	j	800029f2 <argraw+0x30>
  panic("argraw");
    80002a1a:	00006517          	auipc	a0,0x6
    80002a1e:	9f650513          	addi	a0,a0,-1546 # 80008410 <states.0+0x148>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	b1c080e7          	jalr	-1252(ra) # 8000053e <panic>

0000000080002a2a <fetchaddr>:
{
    80002a2a:	1101                	addi	sp,sp,-32
    80002a2c:	ec06                	sd	ra,24(sp)
    80002a2e:	e822                	sd	s0,16(sp)
    80002a30:	e426                	sd	s1,8(sp)
    80002a32:	e04a                	sd	s2,0(sp)
    80002a34:	1000                	addi	s0,sp,32
    80002a36:	84aa                	mv	s1,a0
    80002a38:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a3a:	fffff097          	auipc	ra,0xfffff
    80002a3e:	f7a080e7          	jalr	-134(ra) # 800019b4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a42:	653c                	ld	a5,72(a0)
    80002a44:	02f4f863          	bgeu	s1,a5,80002a74 <fetchaddr+0x4a>
    80002a48:	00848713          	addi	a4,s1,8
    80002a4c:	02e7e663          	bltu	a5,a4,80002a78 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a50:	46a1                	li	a3,8
    80002a52:	8626                	mv	a2,s1
    80002a54:	85ca                	mv	a1,s2
    80002a56:	6928                	ld	a0,80(a0)
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	ca4080e7          	jalr	-860(ra) # 800016fc <copyin>
    80002a60:	00a03533          	snez	a0,a0
    80002a64:	40a00533          	neg	a0,a0
}
    80002a68:	60e2                	ld	ra,24(sp)
    80002a6a:	6442                	ld	s0,16(sp)
    80002a6c:	64a2                	ld	s1,8(sp)
    80002a6e:	6902                	ld	s2,0(sp)
    80002a70:	6105                	addi	sp,sp,32
    80002a72:	8082                	ret
    return -1;
    80002a74:	557d                	li	a0,-1
    80002a76:	bfcd                	j	80002a68 <fetchaddr+0x3e>
    80002a78:	557d                	li	a0,-1
    80002a7a:	b7fd                	j	80002a68 <fetchaddr+0x3e>

0000000080002a7c <fetchstr>:
{
    80002a7c:	7179                	addi	sp,sp,-48
    80002a7e:	f406                	sd	ra,40(sp)
    80002a80:	f022                	sd	s0,32(sp)
    80002a82:	ec26                	sd	s1,24(sp)
    80002a84:	e84a                	sd	s2,16(sp)
    80002a86:	e44e                	sd	s3,8(sp)
    80002a88:	1800                	addi	s0,sp,48
    80002a8a:	892a                	mv	s2,a0
    80002a8c:	84ae                	mv	s1,a1
    80002a8e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	f24080e7          	jalr	-220(ra) # 800019b4 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002a98:	86ce                	mv	a3,s3
    80002a9a:	864a                	mv	a2,s2
    80002a9c:	85a6                	mv	a1,s1
    80002a9e:	6928                	ld	a0,80(a0)
    80002aa0:	fffff097          	auipc	ra,0xfffff
    80002aa4:	cea080e7          	jalr	-790(ra) # 8000178a <copyinstr>
    80002aa8:	00054e63          	bltz	a0,80002ac4 <fetchstr+0x48>
  return strlen(buf);
    80002aac:	8526                	mv	a0,s1
    80002aae:	ffffe097          	auipc	ra,0xffffe
    80002ab2:	3a0080e7          	jalr	928(ra) # 80000e4e <strlen>
}
    80002ab6:	70a2                	ld	ra,40(sp)
    80002ab8:	7402                	ld	s0,32(sp)
    80002aba:	64e2                	ld	s1,24(sp)
    80002abc:	6942                	ld	s2,16(sp)
    80002abe:	69a2                	ld	s3,8(sp)
    80002ac0:	6145                	addi	sp,sp,48
    80002ac2:	8082                	ret
    return -1;
    80002ac4:	557d                	li	a0,-1
    80002ac6:	bfc5                	j	80002ab6 <fetchstr+0x3a>

0000000080002ac8 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ac8:	1101                	addi	sp,sp,-32
    80002aca:	ec06                	sd	ra,24(sp)
    80002acc:	e822                	sd	s0,16(sp)
    80002ace:	e426                	sd	s1,8(sp)
    80002ad0:	1000                	addi	s0,sp,32
    80002ad2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ad4:	00000097          	auipc	ra,0x0
    80002ad8:	eee080e7          	jalr	-274(ra) # 800029c2 <argraw>
    80002adc:	c088                	sw	a0,0(s1)
}
    80002ade:	60e2                	ld	ra,24(sp)
    80002ae0:	6442                	ld	s0,16(sp)
    80002ae2:	64a2                	ld	s1,8(sp)
    80002ae4:	6105                	addi	sp,sp,32
    80002ae6:	8082                	ret

0000000080002ae8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	e426                	sd	s1,8(sp)
    80002af0:	1000                	addi	s0,sp,32
    80002af2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	ece080e7          	jalr	-306(ra) # 800029c2 <argraw>
    80002afc:	e088                	sd	a0,0(s1)
}
    80002afe:	60e2                	ld	ra,24(sp)
    80002b00:	6442                	ld	s0,16(sp)
    80002b02:	64a2                	ld	s1,8(sp)
    80002b04:	6105                	addi	sp,sp,32
    80002b06:	8082                	ret

0000000080002b08 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b08:	7179                	addi	sp,sp,-48
    80002b0a:	f406                	sd	ra,40(sp)
    80002b0c:	f022                	sd	s0,32(sp)
    80002b0e:	ec26                	sd	s1,24(sp)
    80002b10:	e84a                	sd	s2,16(sp)
    80002b12:	1800                	addi	s0,sp,48
    80002b14:	84ae                	mv	s1,a1
    80002b16:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b18:	fd840593          	addi	a1,s0,-40
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	fcc080e7          	jalr	-52(ra) # 80002ae8 <argaddr>
  return fetchstr(addr, buf, max);
    80002b24:	864a                	mv	a2,s2
    80002b26:	85a6                	mv	a1,s1
    80002b28:	fd843503          	ld	a0,-40(s0)
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	f50080e7          	jalr	-176(ra) # 80002a7c <fetchstr>
}
    80002b34:	70a2                	ld	ra,40(sp)
    80002b36:	7402                	ld	s0,32(sp)
    80002b38:	64e2                	ld	s1,24(sp)
    80002b3a:	6942                	ld	s2,16(sp)
    80002b3c:	6145                	addi	sp,sp,48
    80002b3e:	8082                	ret

0000000080002b40 <syscall>:
[SYS_peterson_destroy]  sys_peterson_destroy,
};

void
syscall(void)
{
    80002b40:	1101                	addi	sp,sp,-32
    80002b42:	ec06                	sd	ra,24(sp)
    80002b44:	e822                	sd	s0,16(sp)
    80002b46:	e426                	sd	s1,8(sp)
    80002b48:	e04a                	sd	s2,0(sp)
    80002b4a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	e68080e7          	jalr	-408(ra) # 800019b4 <myproc>
    80002b54:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b56:	05853903          	ld	s2,88(a0)
    80002b5a:	0a893783          	ld	a5,168(s2)
    80002b5e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b62:	37fd                	addiw	a5,a5,-1
    80002b64:	4761                	li	a4,24
    80002b66:	00f76f63          	bltu	a4,a5,80002b84 <syscall+0x44>
    80002b6a:	00369713          	slli	a4,a3,0x3
    80002b6e:	00006797          	auipc	a5,0x6
    80002b72:	8e278793          	addi	a5,a5,-1822 # 80008450 <syscalls>
    80002b76:	97ba                	add	a5,a5,a4
    80002b78:	639c                	ld	a5,0(a5)
    80002b7a:	c789                	beqz	a5,80002b84 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b7c:	9782                	jalr	a5
    80002b7e:	06a93823          	sd	a0,112(s2)
    80002b82:	a839                	j	80002ba0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b84:	15848613          	addi	a2,s1,344
    80002b88:	588c                	lw	a1,48(s1)
    80002b8a:	00006517          	auipc	a0,0x6
    80002b8e:	88e50513          	addi	a0,a0,-1906 # 80008418 <states.0+0x150>
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	9f6080e7          	jalr	-1546(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b9a:	6cbc                	ld	a5,88(s1)
    80002b9c:	577d                	li	a4,-1
    80002b9e:	fbb8                	sd	a4,112(a5)
  }
}
    80002ba0:	60e2                	ld	ra,24(sp)
    80002ba2:	6442                	ld	s0,16(sp)
    80002ba4:	64a2                	ld	s1,8(sp)
    80002ba6:	6902                	ld	s2,0(sp)
    80002ba8:	6105                	addi	sp,sp,32
    80002baa:	8082                	ret

0000000080002bac <sys_peterson_create>:

extern struct petersonlock peterson_locks[MAX_PETERSON_LOCKS];

uint64
sys_peterson_create(void)
{
    80002bac:	1141                	addi	sp,sp,-16
    80002bae:	e422                	sd	s0,8(sp)
    80002bb0:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PETERSON_LOCKS; i++) {
    80002bb2:	0001f797          	auipc	a5,0x1f
    80002bb6:	1ce78793          	addi	a5,a5,462 # 80021d80 <peterson_locks>
    80002bba:	4501                	li	a0,0
    80002bbc:	46bd                	li	a3,15
    if (!peterson_locks[i].active) {
    80002bbe:	4398                	lw	a4,0(a5)
    80002bc0:	cb09                	beqz	a4,80002bd2 <sys_peterson_create+0x26>
  for (int i = 0; i < MAX_PETERSON_LOCKS; i++) {
    80002bc2:	2505                	addiw	a0,a0,1
    80002bc4:	07c1                	addi	a5,a5,16
    80002bc6:	fed51ce3          	bne	a0,a3,80002bbe <sys_peterson_create+0x12>
      peterson_locks[i].active = 1;
      __sync_synchronize();
      return i;
    }
  }
  return -1;
    80002bca:	557d                	li	a0,-1
}
    80002bcc:	6422                	ld	s0,8(sp)
    80002bce:	0141                	addi	sp,sp,16
    80002bd0:	8082                	ret
      peterson_locks[i].active = 1;
    80002bd2:	00451713          	slli	a4,a0,0x4
    80002bd6:	0001f797          	auipc	a5,0x1f
    80002bda:	1aa78793          	addi	a5,a5,426 # 80021d80 <peterson_locks>
    80002bde:	97ba                	add	a5,a5,a4
    80002be0:	4705                	li	a4,1
    80002be2:	c398                	sw	a4,0(a5)
      __sync_synchronize();
    80002be4:	0ff0000f          	fence
      return i;
    80002be8:	b7d5                	j	80002bcc <sys_peterson_create+0x20>

0000000080002bea <sys_peterson_acquire>:

uint64
sys_peterson_acquire(void)
{
    80002bea:	7139                	addi	sp,sp,-64
    80002bec:	fc06                	sd	ra,56(sp)
    80002bee:	f822                	sd	s0,48(sp)
    80002bf0:	f426                	sd	s1,40(sp)
    80002bf2:	f04a                	sd	s2,32(sp)
    80002bf4:	ec4e                	sd	s3,24(sp)
    80002bf6:	e852                	sd	s4,16(sp)
    80002bf8:	0080                	addi	s0,sp,64
  int lock_id;
  int role;

  argint(0, &lock_id);
    80002bfa:	fcc40593          	addi	a1,s0,-52
    80002bfe:	4501                	li	a0,0
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	ec8080e7          	jalr	-312(ra) # 80002ac8 <argint>
  argint(1, &role);
    80002c08:	fc840593          	addi	a1,s0,-56
    80002c0c:	4505                	li	a0,1
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	eba080e7          	jalr	-326(ra) # 80002ac8 <argint>

  struct petersonlock *lock = &peterson_locks[lock_id];
    80002c16:	fcc42483          	lw	s1,-52(s0)

  __sync_lock_test_and_set(&lock->flag[role], 1);
    80002c1a:	fc842783          	lw	a5,-56(s0)
    80002c1e:	00249693          	slli	a3,s1,0x2
    80002c22:	97b6                	add	a5,a5,a3
    80002c24:	0785                	addi	a5,a5,1
    80002c26:	078a                	slli	a5,a5,0x2
    80002c28:	0001f617          	auipc	a2,0x1f
    80002c2c:	15860613          	addi	a2,a2,344 # 80021d80 <peterson_locks>
    80002c30:	97b2                	add	a5,a5,a2
    80002c32:	4705                	li	a4,1
    80002c34:	85ba                	mv	a1,a4
    80002c36:	0cb7a5af          	amoswap.w.aq	a1,a1,(a5)
  __sync_synchronize();
    80002c3a:	0ff0000f          	fence
  lock->turn = 1 - role;
    80002c3e:	fc842583          	lw	a1,-56(s0)
    80002c42:	40b705bb          	subw	a1,a4,a1
    80002c46:	00449793          	slli	a5,s1,0x4
    80002c4a:	97b2                	add	a5,a5,a2
    80002c4c:	c7cc                	sw	a1,12(a5)
  __sync_synchronize();
    80002c4e:	0ff0000f          	fence

  while (lock->flag[1 - role] && lock->turn == 1 - role) {
    80002c52:	fc842783          	lw	a5,-56(s0)
    80002c56:	9f1d                	subw	a4,a4,a5
    80002c58:	96ba                	add	a3,a3,a4
    80002c5a:	068a                	slli	a3,a3,0x2
    80002c5c:	96b2                	add	a3,a3,a2
    80002c5e:	42dc                	lw	a5,4(a3)
    80002c60:	2781                	sext.w	a5,a5
    80002c62:	cb9d                	beqz	a5,80002c98 <sys_peterson_acquire+0xae>
    80002c64:	89b2                	mv	s3,a2
    80002c66:	00449913          	slli	s2,s1,0x4
    80002c6a:	9932                	add	s2,s2,a2
    80002c6c:	4a05                	li	s4,1
    80002c6e:	048a                	slli	s1,s1,0x2
    80002c70:	00c92783          	lw	a5,12(s2)
    80002c74:	2781                	sext.w	a5,a5
    80002c76:	02e79163          	bne	a5,a4,80002c98 <sys_peterson_acquire+0xae>
    yield();
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	3a6080e7          	jalr	934(ra) # 80002020 <yield>
  while (lock->flag[1 - role] && lock->turn == 1 - role) {
    80002c82:	fc842703          	lw	a4,-56(s0)
    80002c86:	40ea073b          	subw	a4,s4,a4
    80002c8a:	00e487b3          	add	a5,s1,a4
    80002c8e:	078a                	slli	a5,a5,0x2
    80002c90:	97ce                	add	a5,a5,s3
    80002c92:	43dc                	lw	a5,4(a5)
    80002c94:	2781                	sext.w	a5,a5
    80002c96:	ffe9                	bnez	a5,80002c70 <sys_peterson_acquire+0x86>
  }

  return 0;
}
    80002c98:	4501                	li	a0,0
    80002c9a:	70e2                	ld	ra,56(sp)
    80002c9c:	7442                	ld	s0,48(sp)
    80002c9e:	74a2                	ld	s1,40(sp)
    80002ca0:	7902                	ld	s2,32(sp)
    80002ca2:	69e2                	ld	s3,24(sp)
    80002ca4:	6a42                	ld	s4,16(sp)
    80002ca6:	6121                	addi	sp,sp,64
    80002ca8:	8082                	ret

0000000080002caa <sys_peterson_release>:

uint64
sys_peterson_release(void)
{
    80002caa:	1101                	addi	sp,sp,-32
    80002cac:	ec06                	sd	ra,24(sp)
    80002cae:	e822                	sd	s0,16(sp)
    80002cb0:	1000                	addi	s0,sp,32
  int lock_id;
  int role;

  argint(0, &lock_id);
    80002cb2:	fec40593          	addi	a1,s0,-20
    80002cb6:	4501                	li	a0,0
    80002cb8:	00000097          	auipc	ra,0x0
    80002cbc:	e10080e7          	jalr	-496(ra) # 80002ac8 <argint>
  argint(1, &role);
    80002cc0:	fe840593          	addi	a1,s0,-24
    80002cc4:	4505                	li	a0,1
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	e02080e7          	jalr	-510(ra) # 80002ac8 <argint>

  struct petersonlock *lock = &peterson_locks[lock_id];

  __sync_lock_release(&lock->flag[role]);
    80002cce:	fec42783          	lw	a5,-20(s0)
    80002cd2:	fe842703          	lw	a4,-24(s0)
    80002cd6:	078a                	slli	a5,a5,0x2
    80002cd8:	0705                	addi	a4,a4,1
    80002cda:	97ba                	add	a5,a5,a4
    80002cdc:	078a                	slli	a5,a5,0x2
    80002cde:	0001f717          	auipc	a4,0x1f
    80002ce2:	0a270713          	addi	a4,a4,162 # 80021d80 <peterson_locks>
    80002ce6:	97ba                	add	a5,a5,a4
    80002ce8:	0f50000f          	fence	iorw,ow
    80002cec:	0807a02f          	amoswap.w	zero,zero,(a5)
  __sync_synchronize();
    80002cf0:	0ff0000f          	fence

  return 0;
}
    80002cf4:	4501                	li	a0,0
    80002cf6:	60e2                	ld	ra,24(sp)
    80002cf8:	6442                	ld	s0,16(sp)
    80002cfa:	6105                	addi	sp,sp,32
    80002cfc:	8082                	ret

0000000080002cfe <sys_peterson_destroy>:

uint64
sys_peterson_destroy(void)
{
    80002cfe:	1101                	addi	sp,sp,-32
    80002d00:	ec06                	sd	ra,24(sp)
    80002d02:	e822                	sd	s0,16(sp)
    80002d04:	1000                	addi	s0,sp,32
  int lock_id;

  argint(0, &lock_id);
    80002d06:	fec40593          	addi	a1,s0,-20
    80002d0a:	4501                	li	a0,0
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	dbc080e7          	jalr	-580(ra) # 80002ac8 <argint>

  peterson_locks[lock_id].active = 0;
    80002d14:	fec42783          	lw	a5,-20(s0)
    80002d18:	00479713          	slli	a4,a5,0x4
    80002d1c:	0001f797          	auipc	a5,0x1f
    80002d20:	06478793          	addi	a5,a5,100 # 80021d80 <peterson_locks>
    80002d24:	97ba                	add	a5,a5,a4
    80002d26:	0007a023          	sw	zero,0(a5)
  __sync_synchronize();
    80002d2a:	0ff0000f          	fence

  return 0;
}
    80002d2e:	4501                	li	a0,0
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	6105                	addi	sp,sp,32
    80002d36:	8082                	ret

0000000080002d38 <sys_exit>:


uint64
sys_exit(void)
{
    80002d38:	1101                	addi	sp,sp,-32
    80002d3a:	ec06                	sd	ra,24(sp)
    80002d3c:	e822                	sd	s0,16(sp)
    80002d3e:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d40:	fec40593          	addi	a1,s0,-20
    80002d44:	4501                	li	a0,0
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	d82080e7          	jalr	-638(ra) # 80002ac8 <argint>
  exit(n);
    80002d4e:	fec42503          	lw	a0,-20(s0)
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	43e080e7          	jalr	1086(ra) # 80002190 <exit>
  return 0;  // not reached
}
    80002d5a:	4501                	li	a0,0
    80002d5c:	60e2                	ld	ra,24(sp)
    80002d5e:	6442                	ld	s0,16(sp)
    80002d60:	6105                	addi	sp,sp,32
    80002d62:	8082                	ret

0000000080002d64 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d64:	1141                	addi	sp,sp,-16
    80002d66:	e406                	sd	ra,8(sp)
    80002d68:	e022                	sd	s0,0(sp)
    80002d6a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	c48080e7          	jalr	-952(ra) # 800019b4 <myproc>
}
    80002d74:	5908                	lw	a0,48(a0)
    80002d76:	60a2                	ld	ra,8(sp)
    80002d78:	6402                	ld	s0,0(sp)
    80002d7a:	0141                	addi	sp,sp,16
    80002d7c:	8082                	ret

0000000080002d7e <sys_fork>:

uint64
sys_fork(void)
{
    80002d7e:	1141                	addi	sp,sp,-16
    80002d80:	e406                	sd	ra,8(sp)
    80002d82:	e022                	sd	s0,0(sp)
    80002d84:	0800                	addi	s0,sp,16
  return fork();
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	fe4080e7          	jalr	-28(ra) # 80001d6a <fork>
}
    80002d8e:	60a2                	ld	ra,8(sp)
    80002d90:	6402                	ld	s0,0(sp)
    80002d92:	0141                	addi	sp,sp,16
    80002d94:	8082                	ret

0000000080002d96 <sys_wait>:

uint64
sys_wait(void)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d9e:	fe840593          	addi	a1,s0,-24
    80002da2:	4501                	li	a0,0
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	d44080e7          	jalr	-700(ra) # 80002ae8 <argaddr>
  return wait(p);
    80002dac:	fe843503          	ld	a0,-24(s0)
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	586080e7          	jalr	1414(ra) # 80002336 <wait>
}
    80002db8:	60e2                	ld	ra,24(sp)
    80002dba:	6442                	ld	s0,16(sp)
    80002dbc:	6105                	addi	sp,sp,32
    80002dbe:	8082                	ret

0000000080002dc0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dc0:	7179                	addi	sp,sp,-48
    80002dc2:	f406                	sd	ra,40(sp)
    80002dc4:	f022                	sd	s0,32(sp)
    80002dc6:	ec26                	sd	s1,24(sp)
    80002dc8:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002dca:	fdc40593          	addi	a1,s0,-36
    80002dce:	4501                	li	a0,0
    80002dd0:	00000097          	auipc	ra,0x0
    80002dd4:	cf8080e7          	jalr	-776(ra) # 80002ac8 <argint>
  addr = myproc()->sz;
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	bdc080e7          	jalr	-1060(ra) # 800019b4 <myproc>
    80002de0:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002de2:	fdc42503          	lw	a0,-36(s0)
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	f28080e7          	jalr	-216(ra) # 80001d0e <growproc>
    80002dee:	00054863          	bltz	a0,80002dfe <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002df2:	8526                	mv	a0,s1
    80002df4:	70a2                	ld	ra,40(sp)
    80002df6:	7402                	ld	s0,32(sp)
    80002df8:	64e2                	ld	s1,24(sp)
    80002dfa:	6145                	addi	sp,sp,48
    80002dfc:	8082                	ret
    return -1;
    80002dfe:	54fd                	li	s1,-1
    80002e00:	bfcd                	j	80002df2 <sys_sbrk+0x32>

0000000080002e02 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e02:	7139                	addi	sp,sp,-64
    80002e04:	fc06                	sd	ra,56(sp)
    80002e06:	f822                	sd	s0,48(sp)
    80002e08:	f426                	sd	s1,40(sp)
    80002e0a:	f04a                	sd	s2,32(sp)
    80002e0c:	ec4e                	sd	s3,24(sp)
    80002e0e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e10:	fcc40593          	addi	a1,s0,-52
    80002e14:	4501                	li	a0,0
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	cb2080e7          	jalr	-846(ra) # 80002ac8 <argint>
  acquire(&tickslock);
    80002e1e:	00014517          	auipc	a0,0x14
    80002e22:	b8250513          	addi	a0,a0,-1150 # 800169a0 <tickslock>
    80002e26:	ffffe097          	auipc	ra,0xffffe
    80002e2a:	db0080e7          	jalr	-592(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002e2e:	00006917          	auipc	s2,0x6
    80002e32:	ad292903          	lw	s2,-1326(s2) # 80008900 <ticks>
  while(ticks - ticks0 < n){
    80002e36:	fcc42783          	lw	a5,-52(s0)
    80002e3a:	cf9d                	beqz	a5,80002e78 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e3c:	00014997          	auipc	s3,0x14
    80002e40:	b6498993          	addi	s3,s3,-1180 # 800169a0 <tickslock>
    80002e44:	00006497          	auipc	s1,0x6
    80002e48:	abc48493          	addi	s1,s1,-1348 # 80008900 <ticks>
    if(killed(myproc())){
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	b68080e7          	jalr	-1176(ra) # 800019b4 <myproc>
    80002e54:	fffff097          	auipc	ra,0xfffff
    80002e58:	4b0080e7          	jalr	1200(ra) # 80002304 <killed>
    80002e5c:	ed15                	bnez	a0,80002e98 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e5e:	85ce                	mv	a1,s3
    80002e60:	8526                	mv	a0,s1
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	1fa080e7          	jalr	506(ra) # 8000205c <sleep>
  while(ticks - ticks0 < n){
    80002e6a:	409c                	lw	a5,0(s1)
    80002e6c:	412787bb          	subw	a5,a5,s2
    80002e70:	fcc42703          	lw	a4,-52(s0)
    80002e74:	fce7ece3          	bltu	a5,a4,80002e4c <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e78:	00014517          	auipc	a0,0x14
    80002e7c:	b2850513          	addi	a0,a0,-1240 # 800169a0 <tickslock>
    80002e80:	ffffe097          	auipc	ra,0xffffe
    80002e84:	e0a080e7          	jalr	-502(ra) # 80000c8a <release>
  return 0;
    80002e88:	4501                	li	a0,0
}
    80002e8a:	70e2                	ld	ra,56(sp)
    80002e8c:	7442                	ld	s0,48(sp)
    80002e8e:	74a2                	ld	s1,40(sp)
    80002e90:	7902                	ld	s2,32(sp)
    80002e92:	69e2                	ld	s3,24(sp)
    80002e94:	6121                	addi	sp,sp,64
    80002e96:	8082                	ret
      release(&tickslock);
    80002e98:	00014517          	auipc	a0,0x14
    80002e9c:	b0850513          	addi	a0,a0,-1272 # 800169a0 <tickslock>
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	dea080e7          	jalr	-534(ra) # 80000c8a <release>
      return -1;
    80002ea8:	557d                	li	a0,-1
    80002eaa:	b7c5                	j	80002e8a <sys_sleep+0x88>

0000000080002eac <sys_kill>:

uint64
sys_kill(void)
{
    80002eac:	1101                	addi	sp,sp,-32
    80002eae:	ec06                	sd	ra,24(sp)
    80002eb0:	e822                	sd	s0,16(sp)
    80002eb2:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002eb4:	fec40593          	addi	a1,s0,-20
    80002eb8:	4501                	li	a0,0
    80002eba:	00000097          	auipc	ra,0x0
    80002ebe:	c0e080e7          	jalr	-1010(ra) # 80002ac8 <argint>
  return kill(pid);
    80002ec2:	fec42503          	lw	a0,-20(s0)
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	3a0080e7          	jalr	928(ra) # 80002266 <kill>
}
    80002ece:	60e2                	ld	ra,24(sp)
    80002ed0:	6442                	ld	s0,16(sp)
    80002ed2:	6105                	addi	sp,sp,32
    80002ed4:	8082                	ret

0000000080002ed6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ed6:	1101                	addi	sp,sp,-32
    80002ed8:	ec06                	sd	ra,24(sp)
    80002eda:	e822                	sd	s0,16(sp)
    80002edc:	e426                	sd	s1,8(sp)
    80002ede:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ee0:	00014517          	auipc	a0,0x14
    80002ee4:	ac050513          	addi	a0,a0,-1344 # 800169a0 <tickslock>
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	cee080e7          	jalr	-786(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002ef0:	00006497          	auipc	s1,0x6
    80002ef4:	a104a483          	lw	s1,-1520(s1) # 80008900 <ticks>
  release(&tickslock);
    80002ef8:	00014517          	auipc	a0,0x14
    80002efc:	aa850513          	addi	a0,a0,-1368 # 800169a0 <tickslock>
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	d8a080e7          	jalr	-630(ra) # 80000c8a <release>
  return xticks;
}
    80002f08:	02049513          	slli	a0,s1,0x20
    80002f0c:	9101                	srli	a0,a0,0x20
    80002f0e:	60e2                	ld	ra,24(sp)
    80002f10:	6442                	ld	s0,16(sp)
    80002f12:	64a2                	ld	s1,8(sp)
    80002f14:	6105                	addi	sp,sp,32
    80002f16:	8082                	ret

0000000080002f18 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f18:	7179                	addi	sp,sp,-48
    80002f1a:	f406                	sd	ra,40(sp)
    80002f1c:	f022                	sd	s0,32(sp)
    80002f1e:	ec26                	sd	s1,24(sp)
    80002f20:	e84a                	sd	s2,16(sp)
    80002f22:	e44e                	sd	s3,8(sp)
    80002f24:	e052                	sd	s4,0(sp)
    80002f26:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f28:	00005597          	auipc	a1,0x5
    80002f2c:	5f858593          	addi	a1,a1,1528 # 80008520 <syscalls+0xd0>
    80002f30:	00014517          	auipc	a0,0x14
    80002f34:	a8850513          	addi	a0,a0,-1400 # 800169b8 <bcache>
    80002f38:	ffffe097          	auipc	ra,0xffffe
    80002f3c:	c0e080e7          	jalr	-1010(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f40:	0001c797          	auipc	a5,0x1c
    80002f44:	a7878793          	addi	a5,a5,-1416 # 8001e9b8 <bcache+0x8000>
    80002f48:	0001c717          	auipc	a4,0x1c
    80002f4c:	cd870713          	addi	a4,a4,-808 # 8001ec20 <bcache+0x8268>
    80002f50:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f54:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f58:	00014497          	auipc	s1,0x14
    80002f5c:	a7848493          	addi	s1,s1,-1416 # 800169d0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f60:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f62:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f64:	00005a17          	auipc	s4,0x5
    80002f68:	5c4a0a13          	addi	s4,s4,1476 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002f6c:	2b893783          	ld	a5,696(s2)
    80002f70:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f72:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f76:	85d2                	mv	a1,s4
    80002f78:	01048513          	addi	a0,s1,16
    80002f7c:	00001097          	auipc	ra,0x1
    80002f80:	4c4080e7          	jalr	1220(ra) # 80004440 <initsleeplock>
    bcache.head.next->prev = b;
    80002f84:	2b893783          	ld	a5,696(s2)
    80002f88:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f8a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f8e:	45848493          	addi	s1,s1,1112
    80002f92:	fd349de3          	bne	s1,s3,80002f6c <binit+0x54>
  }
}
    80002f96:	70a2                	ld	ra,40(sp)
    80002f98:	7402                	ld	s0,32(sp)
    80002f9a:	64e2                	ld	s1,24(sp)
    80002f9c:	6942                	ld	s2,16(sp)
    80002f9e:	69a2                	ld	s3,8(sp)
    80002fa0:	6a02                	ld	s4,0(sp)
    80002fa2:	6145                	addi	sp,sp,48
    80002fa4:	8082                	ret

0000000080002fa6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fa6:	7179                	addi	sp,sp,-48
    80002fa8:	f406                	sd	ra,40(sp)
    80002faa:	f022                	sd	s0,32(sp)
    80002fac:	ec26                	sd	s1,24(sp)
    80002fae:	e84a                	sd	s2,16(sp)
    80002fb0:	e44e                	sd	s3,8(sp)
    80002fb2:	1800                	addi	s0,sp,48
    80002fb4:	892a                	mv	s2,a0
    80002fb6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fb8:	00014517          	auipc	a0,0x14
    80002fbc:	a0050513          	addi	a0,a0,-1536 # 800169b8 <bcache>
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	c16080e7          	jalr	-1002(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fc8:	0001c497          	auipc	s1,0x1c
    80002fcc:	ca84b483          	ld	s1,-856(s1) # 8001ec70 <bcache+0x82b8>
    80002fd0:	0001c797          	auipc	a5,0x1c
    80002fd4:	c5078793          	addi	a5,a5,-944 # 8001ec20 <bcache+0x8268>
    80002fd8:	02f48f63          	beq	s1,a5,80003016 <bread+0x70>
    80002fdc:	873e                	mv	a4,a5
    80002fde:	a021                	j	80002fe6 <bread+0x40>
    80002fe0:	68a4                	ld	s1,80(s1)
    80002fe2:	02e48a63          	beq	s1,a4,80003016 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fe6:	449c                	lw	a5,8(s1)
    80002fe8:	ff279ce3          	bne	a5,s2,80002fe0 <bread+0x3a>
    80002fec:	44dc                	lw	a5,12(s1)
    80002fee:	ff3799e3          	bne	a5,s3,80002fe0 <bread+0x3a>
      b->refcnt++;
    80002ff2:	40bc                	lw	a5,64(s1)
    80002ff4:	2785                	addiw	a5,a5,1
    80002ff6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ff8:	00014517          	auipc	a0,0x14
    80002ffc:	9c050513          	addi	a0,a0,-1600 # 800169b8 <bcache>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	c8a080e7          	jalr	-886(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003008:	01048513          	addi	a0,s1,16
    8000300c:	00001097          	auipc	ra,0x1
    80003010:	46e080e7          	jalr	1134(ra) # 8000447a <acquiresleep>
      return b;
    80003014:	a8b9                	j	80003072 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003016:	0001c497          	auipc	s1,0x1c
    8000301a:	c524b483          	ld	s1,-942(s1) # 8001ec68 <bcache+0x82b0>
    8000301e:	0001c797          	auipc	a5,0x1c
    80003022:	c0278793          	addi	a5,a5,-1022 # 8001ec20 <bcache+0x8268>
    80003026:	00f48863          	beq	s1,a5,80003036 <bread+0x90>
    8000302a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000302c:	40bc                	lw	a5,64(s1)
    8000302e:	cf81                	beqz	a5,80003046 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003030:	64a4                	ld	s1,72(s1)
    80003032:	fee49de3          	bne	s1,a4,8000302c <bread+0x86>
  panic("bget: no buffers");
    80003036:	00005517          	auipc	a0,0x5
    8000303a:	4fa50513          	addi	a0,a0,1274 # 80008530 <syscalls+0xe0>
    8000303e:	ffffd097          	auipc	ra,0xffffd
    80003042:	500080e7          	jalr	1280(ra) # 8000053e <panic>
      b->dev = dev;
    80003046:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000304a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000304e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003052:	4785                	li	a5,1
    80003054:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003056:	00014517          	auipc	a0,0x14
    8000305a:	96250513          	addi	a0,a0,-1694 # 800169b8 <bcache>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	c2c080e7          	jalr	-980(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003066:	01048513          	addi	a0,s1,16
    8000306a:	00001097          	auipc	ra,0x1
    8000306e:	410080e7          	jalr	1040(ra) # 8000447a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003072:	409c                	lw	a5,0(s1)
    80003074:	cb89                	beqz	a5,80003086 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003076:	8526                	mv	a0,s1
    80003078:	70a2                	ld	ra,40(sp)
    8000307a:	7402                	ld	s0,32(sp)
    8000307c:	64e2                	ld	s1,24(sp)
    8000307e:	6942                	ld	s2,16(sp)
    80003080:	69a2                	ld	s3,8(sp)
    80003082:	6145                	addi	sp,sp,48
    80003084:	8082                	ret
    virtio_disk_rw(b, 0);
    80003086:	4581                	li	a1,0
    80003088:	8526                	mv	a0,s1
    8000308a:	00003097          	auipc	ra,0x3
    8000308e:	fda080e7          	jalr	-38(ra) # 80006064 <virtio_disk_rw>
    b->valid = 1;
    80003092:	4785                	li	a5,1
    80003094:	c09c                	sw	a5,0(s1)
  return b;
    80003096:	b7c5                	j	80003076 <bread+0xd0>

0000000080003098 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003098:	1101                	addi	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	e426                	sd	s1,8(sp)
    800030a0:	1000                	addi	s0,sp,32
    800030a2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030a4:	0541                	addi	a0,a0,16
    800030a6:	00001097          	auipc	ra,0x1
    800030aa:	46e080e7          	jalr	1134(ra) # 80004514 <holdingsleep>
    800030ae:	cd01                	beqz	a0,800030c6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030b0:	4585                	li	a1,1
    800030b2:	8526                	mv	a0,s1
    800030b4:	00003097          	auipc	ra,0x3
    800030b8:	fb0080e7          	jalr	-80(ra) # 80006064 <virtio_disk_rw>
}
    800030bc:	60e2                	ld	ra,24(sp)
    800030be:	6442                	ld	s0,16(sp)
    800030c0:	64a2                	ld	s1,8(sp)
    800030c2:	6105                	addi	sp,sp,32
    800030c4:	8082                	ret
    panic("bwrite");
    800030c6:	00005517          	auipc	a0,0x5
    800030ca:	48250513          	addi	a0,a0,1154 # 80008548 <syscalls+0xf8>
    800030ce:	ffffd097          	auipc	ra,0xffffd
    800030d2:	470080e7          	jalr	1136(ra) # 8000053e <panic>

00000000800030d6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030d6:	1101                	addi	sp,sp,-32
    800030d8:	ec06                	sd	ra,24(sp)
    800030da:	e822                	sd	s0,16(sp)
    800030dc:	e426                	sd	s1,8(sp)
    800030de:	e04a                	sd	s2,0(sp)
    800030e0:	1000                	addi	s0,sp,32
    800030e2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030e4:	01050913          	addi	s2,a0,16
    800030e8:	854a                	mv	a0,s2
    800030ea:	00001097          	auipc	ra,0x1
    800030ee:	42a080e7          	jalr	1066(ra) # 80004514 <holdingsleep>
    800030f2:	c92d                	beqz	a0,80003164 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030f4:	854a                	mv	a0,s2
    800030f6:	00001097          	auipc	ra,0x1
    800030fa:	3da080e7          	jalr	986(ra) # 800044d0 <releasesleep>

  acquire(&bcache.lock);
    800030fe:	00014517          	auipc	a0,0x14
    80003102:	8ba50513          	addi	a0,a0,-1862 # 800169b8 <bcache>
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	ad0080e7          	jalr	-1328(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000310e:	40bc                	lw	a5,64(s1)
    80003110:	37fd                	addiw	a5,a5,-1
    80003112:	0007871b          	sext.w	a4,a5
    80003116:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003118:	eb05                	bnez	a4,80003148 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000311a:	68bc                	ld	a5,80(s1)
    8000311c:	64b8                	ld	a4,72(s1)
    8000311e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003120:	64bc                	ld	a5,72(s1)
    80003122:	68b8                	ld	a4,80(s1)
    80003124:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003126:	0001c797          	auipc	a5,0x1c
    8000312a:	89278793          	addi	a5,a5,-1902 # 8001e9b8 <bcache+0x8000>
    8000312e:	2b87b703          	ld	a4,696(a5)
    80003132:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003134:	0001c717          	auipc	a4,0x1c
    80003138:	aec70713          	addi	a4,a4,-1300 # 8001ec20 <bcache+0x8268>
    8000313c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000313e:	2b87b703          	ld	a4,696(a5)
    80003142:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003144:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003148:	00014517          	auipc	a0,0x14
    8000314c:	87050513          	addi	a0,a0,-1936 # 800169b8 <bcache>
    80003150:	ffffe097          	auipc	ra,0xffffe
    80003154:	b3a080e7          	jalr	-1222(ra) # 80000c8a <release>
}
    80003158:	60e2                	ld	ra,24(sp)
    8000315a:	6442                	ld	s0,16(sp)
    8000315c:	64a2                	ld	s1,8(sp)
    8000315e:	6902                	ld	s2,0(sp)
    80003160:	6105                	addi	sp,sp,32
    80003162:	8082                	ret
    panic("brelse");
    80003164:	00005517          	auipc	a0,0x5
    80003168:	3ec50513          	addi	a0,a0,1004 # 80008550 <syscalls+0x100>
    8000316c:	ffffd097          	auipc	ra,0xffffd
    80003170:	3d2080e7          	jalr	978(ra) # 8000053e <panic>

0000000080003174 <bpin>:

void
bpin(struct buf *b) {
    80003174:	1101                	addi	sp,sp,-32
    80003176:	ec06                	sd	ra,24(sp)
    80003178:	e822                	sd	s0,16(sp)
    8000317a:	e426                	sd	s1,8(sp)
    8000317c:	1000                	addi	s0,sp,32
    8000317e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003180:	00014517          	auipc	a0,0x14
    80003184:	83850513          	addi	a0,a0,-1992 # 800169b8 <bcache>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	a4e080e7          	jalr	-1458(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003190:	40bc                	lw	a5,64(s1)
    80003192:	2785                	addiw	a5,a5,1
    80003194:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003196:	00014517          	auipc	a0,0x14
    8000319a:	82250513          	addi	a0,a0,-2014 # 800169b8 <bcache>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	aec080e7          	jalr	-1300(ra) # 80000c8a <release>
}
    800031a6:	60e2                	ld	ra,24(sp)
    800031a8:	6442                	ld	s0,16(sp)
    800031aa:	64a2                	ld	s1,8(sp)
    800031ac:	6105                	addi	sp,sp,32
    800031ae:	8082                	ret

00000000800031b0 <bunpin>:

void
bunpin(struct buf *b) {
    800031b0:	1101                	addi	sp,sp,-32
    800031b2:	ec06                	sd	ra,24(sp)
    800031b4:	e822                	sd	s0,16(sp)
    800031b6:	e426                	sd	s1,8(sp)
    800031b8:	1000                	addi	s0,sp,32
    800031ba:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031bc:	00013517          	auipc	a0,0x13
    800031c0:	7fc50513          	addi	a0,a0,2044 # 800169b8 <bcache>
    800031c4:	ffffe097          	auipc	ra,0xffffe
    800031c8:	a12080e7          	jalr	-1518(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031cc:	40bc                	lw	a5,64(s1)
    800031ce:	37fd                	addiw	a5,a5,-1
    800031d0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031d2:	00013517          	auipc	a0,0x13
    800031d6:	7e650513          	addi	a0,a0,2022 # 800169b8 <bcache>
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	ab0080e7          	jalr	-1360(ra) # 80000c8a <release>
}
    800031e2:	60e2                	ld	ra,24(sp)
    800031e4:	6442                	ld	s0,16(sp)
    800031e6:	64a2                	ld	s1,8(sp)
    800031e8:	6105                	addi	sp,sp,32
    800031ea:	8082                	ret

00000000800031ec <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031ec:	1101                	addi	sp,sp,-32
    800031ee:	ec06                	sd	ra,24(sp)
    800031f0:	e822                	sd	s0,16(sp)
    800031f2:	e426                	sd	s1,8(sp)
    800031f4:	e04a                	sd	s2,0(sp)
    800031f6:	1000                	addi	s0,sp,32
    800031f8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031fa:	00d5d59b          	srliw	a1,a1,0xd
    800031fe:	0001c797          	auipc	a5,0x1c
    80003202:	e967a783          	lw	a5,-362(a5) # 8001f094 <sb+0x1c>
    80003206:	9dbd                	addw	a1,a1,a5
    80003208:	00000097          	auipc	ra,0x0
    8000320c:	d9e080e7          	jalr	-610(ra) # 80002fa6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003210:	0074f713          	andi	a4,s1,7
    80003214:	4785                	li	a5,1
    80003216:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000321a:	14ce                	slli	s1,s1,0x33
    8000321c:	90d9                	srli	s1,s1,0x36
    8000321e:	00950733          	add	a4,a0,s1
    80003222:	05874703          	lbu	a4,88(a4)
    80003226:	00e7f6b3          	and	a3,a5,a4
    8000322a:	c69d                	beqz	a3,80003258 <bfree+0x6c>
    8000322c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000322e:	94aa                	add	s1,s1,a0
    80003230:	fff7c793          	not	a5,a5
    80003234:	8ff9                	and	a5,a5,a4
    80003236:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000323a:	00001097          	auipc	ra,0x1
    8000323e:	120080e7          	jalr	288(ra) # 8000435a <log_write>
  brelse(bp);
    80003242:	854a                	mv	a0,s2
    80003244:	00000097          	auipc	ra,0x0
    80003248:	e92080e7          	jalr	-366(ra) # 800030d6 <brelse>
}
    8000324c:	60e2                	ld	ra,24(sp)
    8000324e:	6442                	ld	s0,16(sp)
    80003250:	64a2                	ld	s1,8(sp)
    80003252:	6902                	ld	s2,0(sp)
    80003254:	6105                	addi	sp,sp,32
    80003256:	8082                	ret
    panic("freeing free block");
    80003258:	00005517          	auipc	a0,0x5
    8000325c:	30050513          	addi	a0,a0,768 # 80008558 <syscalls+0x108>
    80003260:	ffffd097          	auipc	ra,0xffffd
    80003264:	2de080e7          	jalr	734(ra) # 8000053e <panic>

0000000080003268 <balloc>:
{
    80003268:	711d                	addi	sp,sp,-96
    8000326a:	ec86                	sd	ra,88(sp)
    8000326c:	e8a2                	sd	s0,80(sp)
    8000326e:	e4a6                	sd	s1,72(sp)
    80003270:	e0ca                	sd	s2,64(sp)
    80003272:	fc4e                	sd	s3,56(sp)
    80003274:	f852                	sd	s4,48(sp)
    80003276:	f456                	sd	s5,40(sp)
    80003278:	f05a                	sd	s6,32(sp)
    8000327a:	ec5e                	sd	s7,24(sp)
    8000327c:	e862                	sd	s8,16(sp)
    8000327e:	e466                	sd	s9,8(sp)
    80003280:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003282:	0001c797          	auipc	a5,0x1c
    80003286:	dfa7a783          	lw	a5,-518(a5) # 8001f07c <sb+0x4>
    8000328a:	10078163          	beqz	a5,8000338c <balloc+0x124>
    8000328e:	8baa                	mv	s7,a0
    80003290:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003292:	0001cb17          	auipc	s6,0x1c
    80003296:	de6b0b13          	addi	s6,s6,-538 # 8001f078 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000329a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000329c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000329e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032a0:	6c89                	lui	s9,0x2
    800032a2:	a061                	j	8000332a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032a4:	974a                	add	a4,a4,s2
    800032a6:	8fd5                	or	a5,a5,a3
    800032a8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032ac:	854a                	mv	a0,s2
    800032ae:	00001097          	auipc	ra,0x1
    800032b2:	0ac080e7          	jalr	172(ra) # 8000435a <log_write>
        brelse(bp);
    800032b6:	854a                	mv	a0,s2
    800032b8:	00000097          	auipc	ra,0x0
    800032bc:	e1e080e7          	jalr	-482(ra) # 800030d6 <brelse>
  bp = bread(dev, bno);
    800032c0:	85a6                	mv	a1,s1
    800032c2:	855e                	mv	a0,s7
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	ce2080e7          	jalr	-798(ra) # 80002fa6 <bread>
    800032cc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032ce:	40000613          	li	a2,1024
    800032d2:	4581                	li	a1,0
    800032d4:	05850513          	addi	a0,a0,88
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	9fa080e7          	jalr	-1542(ra) # 80000cd2 <memset>
  log_write(bp);
    800032e0:	854a                	mv	a0,s2
    800032e2:	00001097          	auipc	ra,0x1
    800032e6:	078080e7          	jalr	120(ra) # 8000435a <log_write>
  brelse(bp);
    800032ea:	854a                	mv	a0,s2
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	dea080e7          	jalr	-534(ra) # 800030d6 <brelse>
}
    800032f4:	8526                	mv	a0,s1
    800032f6:	60e6                	ld	ra,88(sp)
    800032f8:	6446                	ld	s0,80(sp)
    800032fa:	64a6                	ld	s1,72(sp)
    800032fc:	6906                	ld	s2,64(sp)
    800032fe:	79e2                	ld	s3,56(sp)
    80003300:	7a42                	ld	s4,48(sp)
    80003302:	7aa2                	ld	s5,40(sp)
    80003304:	7b02                	ld	s6,32(sp)
    80003306:	6be2                	ld	s7,24(sp)
    80003308:	6c42                	ld	s8,16(sp)
    8000330a:	6ca2                	ld	s9,8(sp)
    8000330c:	6125                	addi	sp,sp,96
    8000330e:	8082                	ret
    brelse(bp);
    80003310:	854a                	mv	a0,s2
    80003312:	00000097          	auipc	ra,0x0
    80003316:	dc4080e7          	jalr	-572(ra) # 800030d6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000331a:	015c87bb          	addw	a5,s9,s5
    8000331e:	00078a9b          	sext.w	s5,a5
    80003322:	004b2703          	lw	a4,4(s6)
    80003326:	06eaf363          	bgeu	s5,a4,8000338c <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000332a:	41fad79b          	sraiw	a5,s5,0x1f
    8000332e:	0137d79b          	srliw	a5,a5,0x13
    80003332:	015787bb          	addw	a5,a5,s5
    80003336:	40d7d79b          	sraiw	a5,a5,0xd
    8000333a:	01cb2583          	lw	a1,28(s6)
    8000333e:	9dbd                	addw	a1,a1,a5
    80003340:	855e                	mv	a0,s7
    80003342:	00000097          	auipc	ra,0x0
    80003346:	c64080e7          	jalr	-924(ra) # 80002fa6 <bread>
    8000334a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000334c:	004b2503          	lw	a0,4(s6)
    80003350:	000a849b          	sext.w	s1,s5
    80003354:	8662                	mv	a2,s8
    80003356:	faa4fde3          	bgeu	s1,a0,80003310 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000335a:	41f6579b          	sraiw	a5,a2,0x1f
    8000335e:	01d7d69b          	srliw	a3,a5,0x1d
    80003362:	00c6873b          	addw	a4,a3,a2
    80003366:	00777793          	andi	a5,a4,7
    8000336a:	9f95                	subw	a5,a5,a3
    8000336c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003370:	4037571b          	sraiw	a4,a4,0x3
    80003374:	00e906b3          	add	a3,s2,a4
    80003378:	0586c683          	lbu	a3,88(a3)
    8000337c:	00d7f5b3          	and	a1,a5,a3
    80003380:	d195                	beqz	a1,800032a4 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003382:	2605                	addiw	a2,a2,1
    80003384:	2485                	addiw	s1,s1,1
    80003386:	fd4618e3          	bne	a2,s4,80003356 <balloc+0xee>
    8000338a:	b759                	j	80003310 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000338c:	00005517          	auipc	a0,0x5
    80003390:	1e450513          	addi	a0,a0,484 # 80008570 <syscalls+0x120>
    80003394:	ffffd097          	auipc	ra,0xffffd
    80003398:	1f4080e7          	jalr	500(ra) # 80000588 <printf>
  return 0;
    8000339c:	4481                	li	s1,0
    8000339e:	bf99                	j	800032f4 <balloc+0x8c>

00000000800033a0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033a0:	7179                	addi	sp,sp,-48
    800033a2:	f406                	sd	ra,40(sp)
    800033a4:	f022                	sd	s0,32(sp)
    800033a6:	ec26                	sd	s1,24(sp)
    800033a8:	e84a                	sd	s2,16(sp)
    800033aa:	e44e                	sd	s3,8(sp)
    800033ac:	e052                	sd	s4,0(sp)
    800033ae:	1800                	addi	s0,sp,48
    800033b0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033b2:	47ad                	li	a5,11
    800033b4:	02b7e763          	bltu	a5,a1,800033e2 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033b8:	02059493          	slli	s1,a1,0x20
    800033bc:	9081                	srli	s1,s1,0x20
    800033be:	048a                	slli	s1,s1,0x2
    800033c0:	94aa                	add	s1,s1,a0
    800033c2:	0504a903          	lw	s2,80(s1)
    800033c6:	06091e63          	bnez	s2,80003442 <bmap+0xa2>
      addr = balloc(ip->dev);
    800033ca:	4108                	lw	a0,0(a0)
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	e9c080e7          	jalr	-356(ra) # 80003268 <balloc>
    800033d4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033d8:	06090563          	beqz	s2,80003442 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033dc:	0524a823          	sw	s2,80(s1)
    800033e0:	a08d                	j	80003442 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033e2:	ff45849b          	addiw	s1,a1,-12
    800033e6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033ea:	0ff00793          	li	a5,255
    800033ee:	08e7e563          	bltu	a5,a4,80003478 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033f2:	08052903          	lw	s2,128(a0)
    800033f6:	00091d63          	bnez	s2,80003410 <bmap+0x70>
      addr = balloc(ip->dev);
    800033fa:	4108                	lw	a0,0(a0)
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	e6c080e7          	jalr	-404(ra) # 80003268 <balloc>
    80003404:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003408:	02090d63          	beqz	s2,80003442 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000340c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003410:	85ca                	mv	a1,s2
    80003412:	0009a503          	lw	a0,0(s3)
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	b90080e7          	jalr	-1136(ra) # 80002fa6 <bread>
    8000341e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003420:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003424:	02049593          	slli	a1,s1,0x20
    80003428:	9181                	srli	a1,a1,0x20
    8000342a:	058a                	slli	a1,a1,0x2
    8000342c:	00b784b3          	add	s1,a5,a1
    80003430:	0004a903          	lw	s2,0(s1)
    80003434:	02090063          	beqz	s2,80003454 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003438:	8552                	mv	a0,s4
    8000343a:	00000097          	auipc	ra,0x0
    8000343e:	c9c080e7          	jalr	-868(ra) # 800030d6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003442:	854a                	mv	a0,s2
    80003444:	70a2                	ld	ra,40(sp)
    80003446:	7402                	ld	s0,32(sp)
    80003448:	64e2                	ld	s1,24(sp)
    8000344a:	6942                	ld	s2,16(sp)
    8000344c:	69a2                	ld	s3,8(sp)
    8000344e:	6a02                	ld	s4,0(sp)
    80003450:	6145                	addi	sp,sp,48
    80003452:	8082                	ret
      addr = balloc(ip->dev);
    80003454:	0009a503          	lw	a0,0(s3)
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	e10080e7          	jalr	-496(ra) # 80003268 <balloc>
    80003460:	0005091b          	sext.w	s2,a0
      if(addr){
    80003464:	fc090ae3          	beqz	s2,80003438 <bmap+0x98>
        a[bn] = addr;
    80003468:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000346c:	8552                	mv	a0,s4
    8000346e:	00001097          	auipc	ra,0x1
    80003472:	eec080e7          	jalr	-276(ra) # 8000435a <log_write>
    80003476:	b7c9                	j	80003438 <bmap+0x98>
  panic("bmap: out of range");
    80003478:	00005517          	auipc	a0,0x5
    8000347c:	11050513          	addi	a0,a0,272 # 80008588 <syscalls+0x138>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	0be080e7          	jalr	190(ra) # 8000053e <panic>

0000000080003488 <iget>:
{
    80003488:	7179                	addi	sp,sp,-48
    8000348a:	f406                	sd	ra,40(sp)
    8000348c:	f022                	sd	s0,32(sp)
    8000348e:	ec26                	sd	s1,24(sp)
    80003490:	e84a                	sd	s2,16(sp)
    80003492:	e44e                	sd	s3,8(sp)
    80003494:	e052                	sd	s4,0(sp)
    80003496:	1800                	addi	s0,sp,48
    80003498:	89aa                	mv	s3,a0
    8000349a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000349c:	0001c517          	auipc	a0,0x1c
    800034a0:	bfc50513          	addi	a0,a0,-1028 # 8001f098 <itable>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	732080e7          	jalr	1842(ra) # 80000bd6 <acquire>
  empty = 0;
    800034ac:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034ae:	0001c497          	auipc	s1,0x1c
    800034b2:	c0248493          	addi	s1,s1,-1022 # 8001f0b0 <itable+0x18>
    800034b6:	0001d697          	auipc	a3,0x1d
    800034ba:	68a68693          	addi	a3,a3,1674 # 80020b40 <log>
    800034be:	a039                	j	800034cc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034c0:	02090b63          	beqz	s2,800034f6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034c4:	08848493          	addi	s1,s1,136
    800034c8:	02d48a63          	beq	s1,a3,800034fc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034cc:	449c                	lw	a5,8(s1)
    800034ce:	fef059e3          	blez	a5,800034c0 <iget+0x38>
    800034d2:	4098                	lw	a4,0(s1)
    800034d4:	ff3716e3          	bne	a4,s3,800034c0 <iget+0x38>
    800034d8:	40d8                	lw	a4,4(s1)
    800034da:	ff4713e3          	bne	a4,s4,800034c0 <iget+0x38>
      ip->ref++;
    800034de:	2785                	addiw	a5,a5,1
    800034e0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034e2:	0001c517          	auipc	a0,0x1c
    800034e6:	bb650513          	addi	a0,a0,-1098 # 8001f098 <itable>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	7a0080e7          	jalr	1952(ra) # 80000c8a <release>
      return ip;
    800034f2:	8926                	mv	s2,s1
    800034f4:	a03d                	j	80003522 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f6:	f7f9                	bnez	a5,800034c4 <iget+0x3c>
    800034f8:	8926                	mv	s2,s1
    800034fa:	b7e9                	j	800034c4 <iget+0x3c>
  if(empty == 0)
    800034fc:	02090c63          	beqz	s2,80003534 <iget+0xac>
  ip->dev = dev;
    80003500:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003504:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003508:	4785                	li	a5,1
    8000350a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000350e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003512:	0001c517          	auipc	a0,0x1c
    80003516:	b8650513          	addi	a0,a0,-1146 # 8001f098 <itable>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	770080e7          	jalr	1904(ra) # 80000c8a <release>
}
    80003522:	854a                	mv	a0,s2
    80003524:	70a2                	ld	ra,40(sp)
    80003526:	7402                	ld	s0,32(sp)
    80003528:	64e2                	ld	s1,24(sp)
    8000352a:	6942                	ld	s2,16(sp)
    8000352c:	69a2                	ld	s3,8(sp)
    8000352e:	6a02                	ld	s4,0(sp)
    80003530:	6145                	addi	sp,sp,48
    80003532:	8082                	ret
    panic("iget: no inodes");
    80003534:	00005517          	auipc	a0,0x5
    80003538:	06c50513          	addi	a0,a0,108 # 800085a0 <syscalls+0x150>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	002080e7          	jalr	2(ra) # 8000053e <panic>

0000000080003544 <fsinit>:
fsinit(int dev) {
    80003544:	7179                	addi	sp,sp,-48
    80003546:	f406                	sd	ra,40(sp)
    80003548:	f022                	sd	s0,32(sp)
    8000354a:	ec26                	sd	s1,24(sp)
    8000354c:	e84a                	sd	s2,16(sp)
    8000354e:	e44e                	sd	s3,8(sp)
    80003550:	1800                	addi	s0,sp,48
    80003552:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003554:	4585                	li	a1,1
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	a50080e7          	jalr	-1456(ra) # 80002fa6 <bread>
    8000355e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003560:	0001c997          	auipc	s3,0x1c
    80003564:	b1898993          	addi	s3,s3,-1256 # 8001f078 <sb>
    80003568:	02000613          	li	a2,32
    8000356c:	05850593          	addi	a1,a0,88
    80003570:	854e                	mv	a0,s3
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	7bc080e7          	jalr	1980(ra) # 80000d2e <memmove>
  brelse(bp);
    8000357a:	8526                	mv	a0,s1
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	b5a080e7          	jalr	-1190(ra) # 800030d6 <brelse>
  if(sb.magic != FSMAGIC)
    80003584:	0009a703          	lw	a4,0(s3)
    80003588:	102037b7          	lui	a5,0x10203
    8000358c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003590:	02f71263          	bne	a4,a5,800035b4 <fsinit+0x70>
  initlog(dev, &sb);
    80003594:	0001c597          	auipc	a1,0x1c
    80003598:	ae458593          	addi	a1,a1,-1308 # 8001f078 <sb>
    8000359c:	854a                	mv	a0,s2
    8000359e:	00001097          	auipc	ra,0x1
    800035a2:	b40080e7          	jalr	-1216(ra) # 800040de <initlog>
}
    800035a6:	70a2                	ld	ra,40(sp)
    800035a8:	7402                	ld	s0,32(sp)
    800035aa:	64e2                	ld	s1,24(sp)
    800035ac:	6942                	ld	s2,16(sp)
    800035ae:	69a2                	ld	s3,8(sp)
    800035b0:	6145                	addi	sp,sp,48
    800035b2:	8082                	ret
    panic("invalid file system");
    800035b4:	00005517          	auipc	a0,0x5
    800035b8:	ffc50513          	addi	a0,a0,-4 # 800085b0 <syscalls+0x160>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	f82080e7          	jalr	-126(ra) # 8000053e <panic>

00000000800035c4 <iinit>:
{
    800035c4:	7179                	addi	sp,sp,-48
    800035c6:	f406                	sd	ra,40(sp)
    800035c8:	f022                	sd	s0,32(sp)
    800035ca:	ec26                	sd	s1,24(sp)
    800035cc:	e84a                	sd	s2,16(sp)
    800035ce:	e44e                	sd	s3,8(sp)
    800035d0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035d2:	00005597          	auipc	a1,0x5
    800035d6:	ff658593          	addi	a1,a1,-10 # 800085c8 <syscalls+0x178>
    800035da:	0001c517          	auipc	a0,0x1c
    800035de:	abe50513          	addi	a0,a0,-1346 # 8001f098 <itable>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	564080e7          	jalr	1380(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035ea:	0001c497          	auipc	s1,0x1c
    800035ee:	ad648493          	addi	s1,s1,-1322 # 8001f0c0 <itable+0x28>
    800035f2:	0001d997          	auipc	s3,0x1d
    800035f6:	55e98993          	addi	s3,s3,1374 # 80020b50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035fa:	00005917          	auipc	s2,0x5
    800035fe:	fd690913          	addi	s2,s2,-42 # 800085d0 <syscalls+0x180>
    80003602:	85ca                	mv	a1,s2
    80003604:	8526                	mv	a0,s1
    80003606:	00001097          	auipc	ra,0x1
    8000360a:	e3a080e7          	jalr	-454(ra) # 80004440 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000360e:	08848493          	addi	s1,s1,136
    80003612:	ff3498e3          	bne	s1,s3,80003602 <iinit+0x3e>
}
    80003616:	70a2                	ld	ra,40(sp)
    80003618:	7402                	ld	s0,32(sp)
    8000361a:	64e2                	ld	s1,24(sp)
    8000361c:	6942                	ld	s2,16(sp)
    8000361e:	69a2                	ld	s3,8(sp)
    80003620:	6145                	addi	sp,sp,48
    80003622:	8082                	ret

0000000080003624 <ialloc>:
{
    80003624:	715d                	addi	sp,sp,-80
    80003626:	e486                	sd	ra,72(sp)
    80003628:	e0a2                	sd	s0,64(sp)
    8000362a:	fc26                	sd	s1,56(sp)
    8000362c:	f84a                	sd	s2,48(sp)
    8000362e:	f44e                	sd	s3,40(sp)
    80003630:	f052                	sd	s4,32(sp)
    80003632:	ec56                	sd	s5,24(sp)
    80003634:	e85a                	sd	s6,16(sp)
    80003636:	e45e                	sd	s7,8(sp)
    80003638:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000363a:	0001c717          	auipc	a4,0x1c
    8000363e:	a4a72703          	lw	a4,-1462(a4) # 8001f084 <sb+0xc>
    80003642:	4785                	li	a5,1
    80003644:	04e7fa63          	bgeu	a5,a4,80003698 <ialloc+0x74>
    80003648:	8aaa                	mv	s5,a0
    8000364a:	8bae                	mv	s7,a1
    8000364c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000364e:	0001ca17          	auipc	s4,0x1c
    80003652:	a2aa0a13          	addi	s4,s4,-1494 # 8001f078 <sb>
    80003656:	00048b1b          	sext.w	s6,s1
    8000365a:	0044d793          	srli	a5,s1,0x4
    8000365e:	018a2583          	lw	a1,24(s4)
    80003662:	9dbd                	addw	a1,a1,a5
    80003664:	8556                	mv	a0,s5
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	940080e7          	jalr	-1728(ra) # 80002fa6 <bread>
    8000366e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003670:	05850993          	addi	s3,a0,88
    80003674:	00f4f793          	andi	a5,s1,15
    80003678:	079a                	slli	a5,a5,0x6
    8000367a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000367c:	00099783          	lh	a5,0(s3)
    80003680:	c3a1                	beqz	a5,800036c0 <ialloc+0x9c>
    brelse(bp);
    80003682:	00000097          	auipc	ra,0x0
    80003686:	a54080e7          	jalr	-1452(ra) # 800030d6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000368a:	0485                	addi	s1,s1,1
    8000368c:	00ca2703          	lw	a4,12(s4)
    80003690:	0004879b          	sext.w	a5,s1
    80003694:	fce7e1e3          	bltu	a5,a4,80003656 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003698:	00005517          	auipc	a0,0x5
    8000369c:	f4050513          	addi	a0,a0,-192 # 800085d8 <syscalls+0x188>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	ee8080e7          	jalr	-280(ra) # 80000588 <printf>
  return 0;
    800036a8:	4501                	li	a0,0
}
    800036aa:	60a6                	ld	ra,72(sp)
    800036ac:	6406                	ld	s0,64(sp)
    800036ae:	74e2                	ld	s1,56(sp)
    800036b0:	7942                	ld	s2,48(sp)
    800036b2:	79a2                	ld	s3,40(sp)
    800036b4:	7a02                	ld	s4,32(sp)
    800036b6:	6ae2                	ld	s5,24(sp)
    800036b8:	6b42                	ld	s6,16(sp)
    800036ba:	6ba2                	ld	s7,8(sp)
    800036bc:	6161                	addi	sp,sp,80
    800036be:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036c0:	04000613          	li	a2,64
    800036c4:	4581                	li	a1,0
    800036c6:	854e                	mv	a0,s3
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	60a080e7          	jalr	1546(ra) # 80000cd2 <memset>
      dip->type = type;
    800036d0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036d4:	854a                	mv	a0,s2
    800036d6:	00001097          	auipc	ra,0x1
    800036da:	c84080e7          	jalr	-892(ra) # 8000435a <log_write>
      brelse(bp);
    800036de:	854a                	mv	a0,s2
    800036e0:	00000097          	auipc	ra,0x0
    800036e4:	9f6080e7          	jalr	-1546(ra) # 800030d6 <brelse>
      return iget(dev, inum);
    800036e8:	85da                	mv	a1,s6
    800036ea:	8556                	mv	a0,s5
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	d9c080e7          	jalr	-612(ra) # 80003488 <iget>
    800036f4:	bf5d                	j	800036aa <ialloc+0x86>

00000000800036f6 <iupdate>:
{
    800036f6:	1101                	addi	sp,sp,-32
    800036f8:	ec06                	sd	ra,24(sp)
    800036fa:	e822                	sd	s0,16(sp)
    800036fc:	e426                	sd	s1,8(sp)
    800036fe:	e04a                	sd	s2,0(sp)
    80003700:	1000                	addi	s0,sp,32
    80003702:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003704:	415c                	lw	a5,4(a0)
    80003706:	0047d79b          	srliw	a5,a5,0x4
    8000370a:	0001c597          	auipc	a1,0x1c
    8000370e:	9865a583          	lw	a1,-1658(a1) # 8001f090 <sb+0x18>
    80003712:	9dbd                	addw	a1,a1,a5
    80003714:	4108                	lw	a0,0(a0)
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	890080e7          	jalr	-1904(ra) # 80002fa6 <bread>
    8000371e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003720:	05850793          	addi	a5,a0,88
    80003724:	40c8                	lw	a0,4(s1)
    80003726:	893d                	andi	a0,a0,15
    80003728:	051a                	slli	a0,a0,0x6
    8000372a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000372c:	04449703          	lh	a4,68(s1)
    80003730:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003734:	04649703          	lh	a4,70(s1)
    80003738:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000373c:	04849703          	lh	a4,72(s1)
    80003740:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003744:	04a49703          	lh	a4,74(s1)
    80003748:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000374c:	44f8                	lw	a4,76(s1)
    8000374e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003750:	03400613          	li	a2,52
    80003754:	05048593          	addi	a1,s1,80
    80003758:	0531                	addi	a0,a0,12
    8000375a:	ffffd097          	auipc	ra,0xffffd
    8000375e:	5d4080e7          	jalr	1492(ra) # 80000d2e <memmove>
  log_write(bp);
    80003762:	854a                	mv	a0,s2
    80003764:	00001097          	auipc	ra,0x1
    80003768:	bf6080e7          	jalr	-1034(ra) # 8000435a <log_write>
  brelse(bp);
    8000376c:	854a                	mv	a0,s2
    8000376e:	00000097          	auipc	ra,0x0
    80003772:	968080e7          	jalr	-1688(ra) # 800030d6 <brelse>
}
    80003776:	60e2                	ld	ra,24(sp)
    80003778:	6442                	ld	s0,16(sp)
    8000377a:	64a2                	ld	s1,8(sp)
    8000377c:	6902                	ld	s2,0(sp)
    8000377e:	6105                	addi	sp,sp,32
    80003780:	8082                	ret

0000000080003782 <idup>:
{
    80003782:	1101                	addi	sp,sp,-32
    80003784:	ec06                	sd	ra,24(sp)
    80003786:	e822                	sd	s0,16(sp)
    80003788:	e426                	sd	s1,8(sp)
    8000378a:	1000                	addi	s0,sp,32
    8000378c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000378e:	0001c517          	auipc	a0,0x1c
    80003792:	90a50513          	addi	a0,a0,-1782 # 8001f098 <itable>
    80003796:	ffffd097          	auipc	ra,0xffffd
    8000379a:	440080e7          	jalr	1088(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000379e:	449c                	lw	a5,8(s1)
    800037a0:	2785                	addiw	a5,a5,1
    800037a2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037a4:	0001c517          	auipc	a0,0x1c
    800037a8:	8f450513          	addi	a0,a0,-1804 # 8001f098 <itable>
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	4de080e7          	jalr	1246(ra) # 80000c8a <release>
}
    800037b4:	8526                	mv	a0,s1
    800037b6:	60e2                	ld	ra,24(sp)
    800037b8:	6442                	ld	s0,16(sp)
    800037ba:	64a2                	ld	s1,8(sp)
    800037bc:	6105                	addi	sp,sp,32
    800037be:	8082                	ret

00000000800037c0 <ilock>:
{
    800037c0:	1101                	addi	sp,sp,-32
    800037c2:	ec06                	sd	ra,24(sp)
    800037c4:	e822                	sd	s0,16(sp)
    800037c6:	e426                	sd	s1,8(sp)
    800037c8:	e04a                	sd	s2,0(sp)
    800037ca:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037cc:	c115                	beqz	a0,800037f0 <ilock+0x30>
    800037ce:	84aa                	mv	s1,a0
    800037d0:	451c                	lw	a5,8(a0)
    800037d2:	00f05f63          	blez	a5,800037f0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037d6:	0541                	addi	a0,a0,16
    800037d8:	00001097          	auipc	ra,0x1
    800037dc:	ca2080e7          	jalr	-862(ra) # 8000447a <acquiresleep>
  if(ip->valid == 0){
    800037e0:	40bc                	lw	a5,64(s1)
    800037e2:	cf99                	beqz	a5,80003800 <ilock+0x40>
}
    800037e4:	60e2                	ld	ra,24(sp)
    800037e6:	6442                	ld	s0,16(sp)
    800037e8:	64a2                	ld	s1,8(sp)
    800037ea:	6902                	ld	s2,0(sp)
    800037ec:	6105                	addi	sp,sp,32
    800037ee:	8082                	ret
    panic("ilock");
    800037f0:	00005517          	auipc	a0,0x5
    800037f4:	e0050513          	addi	a0,a0,-512 # 800085f0 <syscalls+0x1a0>
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	d46080e7          	jalr	-698(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003800:	40dc                	lw	a5,4(s1)
    80003802:	0047d79b          	srliw	a5,a5,0x4
    80003806:	0001c597          	auipc	a1,0x1c
    8000380a:	88a5a583          	lw	a1,-1910(a1) # 8001f090 <sb+0x18>
    8000380e:	9dbd                	addw	a1,a1,a5
    80003810:	4088                	lw	a0,0(s1)
    80003812:	fffff097          	auipc	ra,0xfffff
    80003816:	794080e7          	jalr	1940(ra) # 80002fa6 <bread>
    8000381a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000381c:	05850593          	addi	a1,a0,88
    80003820:	40dc                	lw	a5,4(s1)
    80003822:	8bbd                	andi	a5,a5,15
    80003824:	079a                	slli	a5,a5,0x6
    80003826:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003828:	00059783          	lh	a5,0(a1)
    8000382c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003830:	00259783          	lh	a5,2(a1)
    80003834:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003838:	00459783          	lh	a5,4(a1)
    8000383c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003840:	00659783          	lh	a5,6(a1)
    80003844:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003848:	459c                	lw	a5,8(a1)
    8000384a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000384c:	03400613          	li	a2,52
    80003850:	05b1                	addi	a1,a1,12
    80003852:	05048513          	addi	a0,s1,80
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	4d8080e7          	jalr	1240(ra) # 80000d2e <memmove>
    brelse(bp);
    8000385e:	854a                	mv	a0,s2
    80003860:	00000097          	auipc	ra,0x0
    80003864:	876080e7          	jalr	-1930(ra) # 800030d6 <brelse>
    ip->valid = 1;
    80003868:	4785                	li	a5,1
    8000386a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000386c:	04449783          	lh	a5,68(s1)
    80003870:	fbb5                	bnez	a5,800037e4 <ilock+0x24>
      panic("ilock: no type");
    80003872:	00005517          	auipc	a0,0x5
    80003876:	d8650513          	addi	a0,a0,-634 # 800085f8 <syscalls+0x1a8>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	cc4080e7          	jalr	-828(ra) # 8000053e <panic>

0000000080003882 <iunlock>:
{
    80003882:	1101                	addi	sp,sp,-32
    80003884:	ec06                	sd	ra,24(sp)
    80003886:	e822                	sd	s0,16(sp)
    80003888:	e426                	sd	s1,8(sp)
    8000388a:	e04a                	sd	s2,0(sp)
    8000388c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000388e:	c905                	beqz	a0,800038be <iunlock+0x3c>
    80003890:	84aa                	mv	s1,a0
    80003892:	01050913          	addi	s2,a0,16
    80003896:	854a                	mv	a0,s2
    80003898:	00001097          	auipc	ra,0x1
    8000389c:	c7c080e7          	jalr	-900(ra) # 80004514 <holdingsleep>
    800038a0:	cd19                	beqz	a0,800038be <iunlock+0x3c>
    800038a2:	449c                	lw	a5,8(s1)
    800038a4:	00f05d63          	blez	a5,800038be <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038a8:	854a                	mv	a0,s2
    800038aa:	00001097          	auipc	ra,0x1
    800038ae:	c26080e7          	jalr	-986(ra) # 800044d0 <releasesleep>
}
    800038b2:	60e2                	ld	ra,24(sp)
    800038b4:	6442                	ld	s0,16(sp)
    800038b6:	64a2                	ld	s1,8(sp)
    800038b8:	6902                	ld	s2,0(sp)
    800038ba:	6105                	addi	sp,sp,32
    800038bc:	8082                	ret
    panic("iunlock");
    800038be:	00005517          	auipc	a0,0x5
    800038c2:	d4a50513          	addi	a0,a0,-694 # 80008608 <syscalls+0x1b8>
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	c78080e7          	jalr	-904(ra) # 8000053e <panic>

00000000800038ce <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038ce:	7179                	addi	sp,sp,-48
    800038d0:	f406                	sd	ra,40(sp)
    800038d2:	f022                	sd	s0,32(sp)
    800038d4:	ec26                	sd	s1,24(sp)
    800038d6:	e84a                	sd	s2,16(sp)
    800038d8:	e44e                	sd	s3,8(sp)
    800038da:	e052                	sd	s4,0(sp)
    800038dc:	1800                	addi	s0,sp,48
    800038de:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038e0:	05050493          	addi	s1,a0,80
    800038e4:	08050913          	addi	s2,a0,128
    800038e8:	a021                	j	800038f0 <itrunc+0x22>
    800038ea:	0491                	addi	s1,s1,4
    800038ec:	01248d63          	beq	s1,s2,80003906 <itrunc+0x38>
    if(ip->addrs[i]){
    800038f0:	408c                	lw	a1,0(s1)
    800038f2:	dde5                	beqz	a1,800038ea <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038f4:	0009a503          	lw	a0,0(s3)
    800038f8:	00000097          	auipc	ra,0x0
    800038fc:	8f4080e7          	jalr	-1804(ra) # 800031ec <bfree>
      ip->addrs[i] = 0;
    80003900:	0004a023          	sw	zero,0(s1)
    80003904:	b7dd                	j	800038ea <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003906:	0809a583          	lw	a1,128(s3)
    8000390a:	e185                	bnez	a1,8000392a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000390c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003910:	854e                	mv	a0,s3
    80003912:	00000097          	auipc	ra,0x0
    80003916:	de4080e7          	jalr	-540(ra) # 800036f6 <iupdate>
}
    8000391a:	70a2                	ld	ra,40(sp)
    8000391c:	7402                	ld	s0,32(sp)
    8000391e:	64e2                	ld	s1,24(sp)
    80003920:	6942                	ld	s2,16(sp)
    80003922:	69a2                	ld	s3,8(sp)
    80003924:	6a02                	ld	s4,0(sp)
    80003926:	6145                	addi	sp,sp,48
    80003928:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000392a:	0009a503          	lw	a0,0(s3)
    8000392e:	fffff097          	auipc	ra,0xfffff
    80003932:	678080e7          	jalr	1656(ra) # 80002fa6 <bread>
    80003936:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003938:	05850493          	addi	s1,a0,88
    8000393c:	45850913          	addi	s2,a0,1112
    80003940:	a021                	j	80003948 <itrunc+0x7a>
    80003942:	0491                	addi	s1,s1,4
    80003944:	01248b63          	beq	s1,s2,8000395a <itrunc+0x8c>
      if(a[j])
    80003948:	408c                	lw	a1,0(s1)
    8000394a:	dde5                	beqz	a1,80003942 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000394c:	0009a503          	lw	a0,0(s3)
    80003950:	00000097          	auipc	ra,0x0
    80003954:	89c080e7          	jalr	-1892(ra) # 800031ec <bfree>
    80003958:	b7ed                	j	80003942 <itrunc+0x74>
    brelse(bp);
    8000395a:	8552                	mv	a0,s4
    8000395c:	fffff097          	auipc	ra,0xfffff
    80003960:	77a080e7          	jalr	1914(ra) # 800030d6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003964:	0809a583          	lw	a1,128(s3)
    80003968:	0009a503          	lw	a0,0(s3)
    8000396c:	00000097          	auipc	ra,0x0
    80003970:	880080e7          	jalr	-1920(ra) # 800031ec <bfree>
    ip->addrs[NDIRECT] = 0;
    80003974:	0809a023          	sw	zero,128(s3)
    80003978:	bf51                	j	8000390c <itrunc+0x3e>

000000008000397a <iput>:
{
    8000397a:	1101                	addi	sp,sp,-32
    8000397c:	ec06                	sd	ra,24(sp)
    8000397e:	e822                	sd	s0,16(sp)
    80003980:	e426                	sd	s1,8(sp)
    80003982:	e04a                	sd	s2,0(sp)
    80003984:	1000                	addi	s0,sp,32
    80003986:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003988:	0001b517          	auipc	a0,0x1b
    8000398c:	71050513          	addi	a0,a0,1808 # 8001f098 <itable>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	246080e7          	jalr	582(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003998:	4498                	lw	a4,8(s1)
    8000399a:	4785                	li	a5,1
    8000399c:	02f70363          	beq	a4,a5,800039c2 <iput+0x48>
  ip->ref--;
    800039a0:	449c                	lw	a5,8(s1)
    800039a2:	37fd                	addiw	a5,a5,-1
    800039a4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039a6:	0001b517          	auipc	a0,0x1b
    800039aa:	6f250513          	addi	a0,a0,1778 # 8001f098 <itable>
    800039ae:	ffffd097          	auipc	ra,0xffffd
    800039b2:	2dc080e7          	jalr	732(ra) # 80000c8a <release>
}
    800039b6:	60e2                	ld	ra,24(sp)
    800039b8:	6442                	ld	s0,16(sp)
    800039ba:	64a2                	ld	s1,8(sp)
    800039bc:	6902                	ld	s2,0(sp)
    800039be:	6105                	addi	sp,sp,32
    800039c0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039c2:	40bc                	lw	a5,64(s1)
    800039c4:	dff1                	beqz	a5,800039a0 <iput+0x26>
    800039c6:	04a49783          	lh	a5,74(s1)
    800039ca:	fbf9                	bnez	a5,800039a0 <iput+0x26>
    acquiresleep(&ip->lock);
    800039cc:	01048913          	addi	s2,s1,16
    800039d0:	854a                	mv	a0,s2
    800039d2:	00001097          	auipc	ra,0x1
    800039d6:	aa8080e7          	jalr	-1368(ra) # 8000447a <acquiresleep>
    release(&itable.lock);
    800039da:	0001b517          	auipc	a0,0x1b
    800039de:	6be50513          	addi	a0,a0,1726 # 8001f098 <itable>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	2a8080e7          	jalr	680(ra) # 80000c8a <release>
    itrunc(ip);
    800039ea:	8526                	mv	a0,s1
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	ee2080e7          	jalr	-286(ra) # 800038ce <itrunc>
    ip->type = 0;
    800039f4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039f8:	8526                	mv	a0,s1
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	cfc080e7          	jalr	-772(ra) # 800036f6 <iupdate>
    ip->valid = 0;
    80003a02:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a06:	854a                	mv	a0,s2
    80003a08:	00001097          	auipc	ra,0x1
    80003a0c:	ac8080e7          	jalr	-1336(ra) # 800044d0 <releasesleep>
    acquire(&itable.lock);
    80003a10:	0001b517          	auipc	a0,0x1b
    80003a14:	68850513          	addi	a0,a0,1672 # 8001f098 <itable>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	1be080e7          	jalr	446(ra) # 80000bd6 <acquire>
    80003a20:	b741                	j	800039a0 <iput+0x26>

0000000080003a22 <iunlockput>:
{
    80003a22:	1101                	addi	sp,sp,-32
    80003a24:	ec06                	sd	ra,24(sp)
    80003a26:	e822                	sd	s0,16(sp)
    80003a28:	e426                	sd	s1,8(sp)
    80003a2a:	1000                	addi	s0,sp,32
    80003a2c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	e54080e7          	jalr	-428(ra) # 80003882 <iunlock>
  iput(ip);
    80003a36:	8526                	mv	a0,s1
    80003a38:	00000097          	auipc	ra,0x0
    80003a3c:	f42080e7          	jalr	-190(ra) # 8000397a <iput>
}
    80003a40:	60e2                	ld	ra,24(sp)
    80003a42:	6442                	ld	s0,16(sp)
    80003a44:	64a2                	ld	s1,8(sp)
    80003a46:	6105                	addi	sp,sp,32
    80003a48:	8082                	ret

0000000080003a4a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a4a:	1141                	addi	sp,sp,-16
    80003a4c:	e422                	sd	s0,8(sp)
    80003a4e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a50:	411c                	lw	a5,0(a0)
    80003a52:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a54:	415c                	lw	a5,4(a0)
    80003a56:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a58:	04451783          	lh	a5,68(a0)
    80003a5c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a60:	04a51783          	lh	a5,74(a0)
    80003a64:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a68:	04c56783          	lwu	a5,76(a0)
    80003a6c:	e99c                	sd	a5,16(a1)
}
    80003a6e:	6422                	ld	s0,8(sp)
    80003a70:	0141                	addi	sp,sp,16
    80003a72:	8082                	ret

0000000080003a74 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a74:	457c                	lw	a5,76(a0)
    80003a76:	0ed7e963          	bltu	a5,a3,80003b68 <readi+0xf4>
{
    80003a7a:	7159                	addi	sp,sp,-112
    80003a7c:	f486                	sd	ra,104(sp)
    80003a7e:	f0a2                	sd	s0,96(sp)
    80003a80:	eca6                	sd	s1,88(sp)
    80003a82:	e8ca                	sd	s2,80(sp)
    80003a84:	e4ce                	sd	s3,72(sp)
    80003a86:	e0d2                	sd	s4,64(sp)
    80003a88:	fc56                	sd	s5,56(sp)
    80003a8a:	f85a                	sd	s6,48(sp)
    80003a8c:	f45e                	sd	s7,40(sp)
    80003a8e:	f062                	sd	s8,32(sp)
    80003a90:	ec66                	sd	s9,24(sp)
    80003a92:	e86a                	sd	s10,16(sp)
    80003a94:	e46e                	sd	s11,8(sp)
    80003a96:	1880                	addi	s0,sp,112
    80003a98:	8b2a                	mv	s6,a0
    80003a9a:	8bae                	mv	s7,a1
    80003a9c:	8a32                	mv	s4,a2
    80003a9e:	84b6                	mv	s1,a3
    80003aa0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003aa2:	9f35                	addw	a4,a4,a3
    return 0;
    80003aa4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aa6:	0ad76063          	bltu	a4,a3,80003b46 <readi+0xd2>
  if(off + n > ip->size)
    80003aaa:	00e7f463          	bgeu	a5,a4,80003ab2 <readi+0x3e>
    n = ip->size - off;
    80003aae:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab2:	0a0a8963          	beqz	s5,80003b64 <readi+0xf0>
    80003ab6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003abc:	5c7d                	li	s8,-1
    80003abe:	a82d                	j	80003af8 <readi+0x84>
    80003ac0:	020d1d93          	slli	s11,s10,0x20
    80003ac4:	020ddd93          	srli	s11,s11,0x20
    80003ac8:	05890793          	addi	a5,s2,88
    80003acc:	86ee                	mv	a3,s11
    80003ace:	963e                	add	a2,a2,a5
    80003ad0:	85d2                	mv	a1,s4
    80003ad2:	855e                	mv	a0,s7
    80003ad4:	fffff097          	auipc	ra,0xfffff
    80003ad8:	990080e7          	jalr	-1648(ra) # 80002464 <either_copyout>
    80003adc:	05850d63          	beq	a0,s8,80003b36 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	fffff097          	auipc	ra,0xfffff
    80003ae6:	5f4080e7          	jalr	1524(ra) # 800030d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aea:	013d09bb          	addw	s3,s10,s3
    80003aee:	009d04bb          	addw	s1,s10,s1
    80003af2:	9a6e                	add	s4,s4,s11
    80003af4:	0559f763          	bgeu	s3,s5,80003b42 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003af8:	00a4d59b          	srliw	a1,s1,0xa
    80003afc:	855a                	mv	a0,s6
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	8a2080e7          	jalr	-1886(ra) # 800033a0 <bmap>
    80003b06:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b0a:	cd85                	beqz	a1,80003b42 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b0c:	000b2503          	lw	a0,0(s6)
    80003b10:	fffff097          	auipc	ra,0xfffff
    80003b14:	496080e7          	jalr	1174(ra) # 80002fa6 <bread>
    80003b18:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b1a:	3ff4f613          	andi	a2,s1,1023
    80003b1e:	40cc87bb          	subw	a5,s9,a2
    80003b22:	413a873b          	subw	a4,s5,s3
    80003b26:	8d3e                	mv	s10,a5
    80003b28:	2781                	sext.w	a5,a5
    80003b2a:	0007069b          	sext.w	a3,a4
    80003b2e:	f8f6f9e3          	bgeu	a3,a5,80003ac0 <readi+0x4c>
    80003b32:	8d3a                	mv	s10,a4
    80003b34:	b771                	j	80003ac0 <readi+0x4c>
      brelse(bp);
    80003b36:	854a                	mv	a0,s2
    80003b38:	fffff097          	auipc	ra,0xfffff
    80003b3c:	59e080e7          	jalr	1438(ra) # 800030d6 <brelse>
      tot = -1;
    80003b40:	59fd                	li	s3,-1
  }
  return tot;
    80003b42:	0009851b          	sext.w	a0,s3
}
    80003b46:	70a6                	ld	ra,104(sp)
    80003b48:	7406                	ld	s0,96(sp)
    80003b4a:	64e6                	ld	s1,88(sp)
    80003b4c:	6946                	ld	s2,80(sp)
    80003b4e:	69a6                	ld	s3,72(sp)
    80003b50:	6a06                	ld	s4,64(sp)
    80003b52:	7ae2                	ld	s5,56(sp)
    80003b54:	7b42                	ld	s6,48(sp)
    80003b56:	7ba2                	ld	s7,40(sp)
    80003b58:	7c02                	ld	s8,32(sp)
    80003b5a:	6ce2                	ld	s9,24(sp)
    80003b5c:	6d42                	ld	s10,16(sp)
    80003b5e:	6da2                	ld	s11,8(sp)
    80003b60:	6165                	addi	sp,sp,112
    80003b62:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b64:	89d6                	mv	s3,s5
    80003b66:	bff1                	j	80003b42 <readi+0xce>
    return 0;
    80003b68:	4501                	li	a0,0
}
    80003b6a:	8082                	ret

0000000080003b6c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b6c:	457c                	lw	a5,76(a0)
    80003b6e:	10d7e863          	bltu	a5,a3,80003c7e <writei+0x112>
{
    80003b72:	7159                	addi	sp,sp,-112
    80003b74:	f486                	sd	ra,104(sp)
    80003b76:	f0a2                	sd	s0,96(sp)
    80003b78:	eca6                	sd	s1,88(sp)
    80003b7a:	e8ca                	sd	s2,80(sp)
    80003b7c:	e4ce                	sd	s3,72(sp)
    80003b7e:	e0d2                	sd	s4,64(sp)
    80003b80:	fc56                	sd	s5,56(sp)
    80003b82:	f85a                	sd	s6,48(sp)
    80003b84:	f45e                	sd	s7,40(sp)
    80003b86:	f062                	sd	s8,32(sp)
    80003b88:	ec66                	sd	s9,24(sp)
    80003b8a:	e86a                	sd	s10,16(sp)
    80003b8c:	e46e                	sd	s11,8(sp)
    80003b8e:	1880                	addi	s0,sp,112
    80003b90:	8aaa                	mv	s5,a0
    80003b92:	8bae                	mv	s7,a1
    80003b94:	8a32                	mv	s4,a2
    80003b96:	8936                	mv	s2,a3
    80003b98:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b9a:	00e687bb          	addw	a5,a3,a4
    80003b9e:	0ed7e263          	bltu	a5,a3,80003c82 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ba2:	00043737          	lui	a4,0x43
    80003ba6:	0ef76063          	bltu	a4,a5,80003c86 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003baa:	0c0b0863          	beqz	s6,80003c7a <writei+0x10e>
    80003bae:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bb4:	5c7d                	li	s8,-1
    80003bb6:	a091                	j	80003bfa <writei+0x8e>
    80003bb8:	020d1d93          	slli	s11,s10,0x20
    80003bbc:	020ddd93          	srli	s11,s11,0x20
    80003bc0:	05848793          	addi	a5,s1,88
    80003bc4:	86ee                	mv	a3,s11
    80003bc6:	8652                	mv	a2,s4
    80003bc8:	85de                	mv	a1,s7
    80003bca:	953e                	add	a0,a0,a5
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	8ee080e7          	jalr	-1810(ra) # 800024ba <either_copyin>
    80003bd4:	07850263          	beq	a0,s8,80003c38 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bd8:	8526                	mv	a0,s1
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	780080e7          	jalr	1920(ra) # 8000435a <log_write>
    brelse(bp);
    80003be2:	8526                	mv	a0,s1
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	4f2080e7          	jalr	1266(ra) # 800030d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bec:	013d09bb          	addw	s3,s10,s3
    80003bf0:	012d093b          	addw	s2,s10,s2
    80003bf4:	9a6e                	add	s4,s4,s11
    80003bf6:	0569f663          	bgeu	s3,s6,80003c42 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bfa:	00a9559b          	srliw	a1,s2,0xa
    80003bfe:	8556                	mv	a0,s5
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	7a0080e7          	jalr	1952(ra) # 800033a0 <bmap>
    80003c08:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c0c:	c99d                	beqz	a1,80003c42 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c0e:	000aa503          	lw	a0,0(s5)
    80003c12:	fffff097          	auipc	ra,0xfffff
    80003c16:	394080e7          	jalr	916(ra) # 80002fa6 <bread>
    80003c1a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c1c:	3ff97513          	andi	a0,s2,1023
    80003c20:	40ac87bb          	subw	a5,s9,a0
    80003c24:	413b073b          	subw	a4,s6,s3
    80003c28:	8d3e                	mv	s10,a5
    80003c2a:	2781                	sext.w	a5,a5
    80003c2c:	0007069b          	sext.w	a3,a4
    80003c30:	f8f6f4e3          	bgeu	a3,a5,80003bb8 <writei+0x4c>
    80003c34:	8d3a                	mv	s10,a4
    80003c36:	b749                	j	80003bb8 <writei+0x4c>
      brelse(bp);
    80003c38:	8526                	mv	a0,s1
    80003c3a:	fffff097          	auipc	ra,0xfffff
    80003c3e:	49c080e7          	jalr	1180(ra) # 800030d6 <brelse>
  }

  if(off > ip->size)
    80003c42:	04caa783          	lw	a5,76(s5)
    80003c46:	0127f463          	bgeu	a5,s2,80003c4e <writei+0xe2>
    ip->size = off;
    80003c4a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c4e:	8556                	mv	a0,s5
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	aa6080e7          	jalr	-1370(ra) # 800036f6 <iupdate>

  return tot;
    80003c58:	0009851b          	sext.w	a0,s3
}
    80003c5c:	70a6                	ld	ra,104(sp)
    80003c5e:	7406                	ld	s0,96(sp)
    80003c60:	64e6                	ld	s1,88(sp)
    80003c62:	6946                	ld	s2,80(sp)
    80003c64:	69a6                	ld	s3,72(sp)
    80003c66:	6a06                	ld	s4,64(sp)
    80003c68:	7ae2                	ld	s5,56(sp)
    80003c6a:	7b42                	ld	s6,48(sp)
    80003c6c:	7ba2                	ld	s7,40(sp)
    80003c6e:	7c02                	ld	s8,32(sp)
    80003c70:	6ce2                	ld	s9,24(sp)
    80003c72:	6d42                	ld	s10,16(sp)
    80003c74:	6da2                	ld	s11,8(sp)
    80003c76:	6165                	addi	sp,sp,112
    80003c78:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c7a:	89da                	mv	s3,s6
    80003c7c:	bfc9                	j	80003c4e <writei+0xe2>
    return -1;
    80003c7e:	557d                	li	a0,-1
}
    80003c80:	8082                	ret
    return -1;
    80003c82:	557d                	li	a0,-1
    80003c84:	bfe1                	j	80003c5c <writei+0xf0>
    return -1;
    80003c86:	557d                	li	a0,-1
    80003c88:	bfd1                	j	80003c5c <writei+0xf0>

0000000080003c8a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c8a:	1141                	addi	sp,sp,-16
    80003c8c:	e406                	sd	ra,8(sp)
    80003c8e:	e022                	sd	s0,0(sp)
    80003c90:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c92:	4639                	li	a2,14
    80003c94:	ffffd097          	auipc	ra,0xffffd
    80003c98:	10e080e7          	jalr	270(ra) # 80000da2 <strncmp>
}
    80003c9c:	60a2                	ld	ra,8(sp)
    80003c9e:	6402                	ld	s0,0(sp)
    80003ca0:	0141                	addi	sp,sp,16
    80003ca2:	8082                	ret

0000000080003ca4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ca4:	7139                	addi	sp,sp,-64
    80003ca6:	fc06                	sd	ra,56(sp)
    80003ca8:	f822                	sd	s0,48(sp)
    80003caa:	f426                	sd	s1,40(sp)
    80003cac:	f04a                	sd	s2,32(sp)
    80003cae:	ec4e                	sd	s3,24(sp)
    80003cb0:	e852                	sd	s4,16(sp)
    80003cb2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cb4:	04451703          	lh	a4,68(a0)
    80003cb8:	4785                	li	a5,1
    80003cba:	00f71a63          	bne	a4,a5,80003cce <dirlookup+0x2a>
    80003cbe:	892a                	mv	s2,a0
    80003cc0:	89ae                	mv	s3,a1
    80003cc2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc4:	457c                	lw	a5,76(a0)
    80003cc6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cc8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cca:	e79d                	bnez	a5,80003cf8 <dirlookup+0x54>
    80003ccc:	a8a5                	j	80003d44 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cce:	00005517          	auipc	a0,0x5
    80003cd2:	94250513          	addi	a0,a0,-1726 # 80008610 <syscalls+0x1c0>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	868080e7          	jalr	-1944(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cde:	00005517          	auipc	a0,0x5
    80003ce2:	94a50513          	addi	a0,a0,-1718 # 80008628 <syscalls+0x1d8>
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	858080e7          	jalr	-1960(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cee:	24c1                	addiw	s1,s1,16
    80003cf0:	04c92783          	lw	a5,76(s2)
    80003cf4:	04f4f763          	bgeu	s1,a5,80003d42 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cf8:	4741                	li	a4,16
    80003cfa:	86a6                	mv	a3,s1
    80003cfc:	fc040613          	addi	a2,s0,-64
    80003d00:	4581                	li	a1,0
    80003d02:	854a                	mv	a0,s2
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	d70080e7          	jalr	-656(ra) # 80003a74 <readi>
    80003d0c:	47c1                	li	a5,16
    80003d0e:	fcf518e3          	bne	a0,a5,80003cde <dirlookup+0x3a>
    if(de.inum == 0)
    80003d12:	fc045783          	lhu	a5,-64(s0)
    80003d16:	dfe1                	beqz	a5,80003cee <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d18:	fc240593          	addi	a1,s0,-62
    80003d1c:	854e                	mv	a0,s3
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	f6c080e7          	jalr	-148(ra) # 80003c8a <namecmp>
    80003d26:	f561                	bnez	a0,80003cee <dirlookup+0x4a>
      if(poff)
    80003d28:	000a0463          	beqz	s4,80003d30 <dirlookup+0x8c>
        *poff = off;
    80003d2c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d30:	fc045583          	lhu	a1,-64(s0)
    80003d34:	00092503          	lw	a0,0(s2)
    80003d38:	fffff097          	auipc	ra,0xfffff
    80003d3c:	750080e7          	jalr	1872(ra) # 80003488 <iget>
    80003d40:	a011                	j	80003d44 <dirlookup+0xa0>
  return 0;
    80003d42:	4501                	li	a0,0
}
    80003d44:	70e2                	ld	ra,56(sp)
    80003d46:	7442                	ld	s0,48(sp)
    80003d48:	74a2                	ld	s1,40(sp)
    80003d4a:	7902                	ld	s2,32(sp)
    80003d4c:	69e2                	ld	s3,24(sp)
    80003d4e:	6a42                	ld	s4,16(sp)
    80003d50:	6121                	addi	sp,sp,64
    80003d52:	8082                	ret

0000000080003d54 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d54:	711d                	addi	sp,sp,-96
    80003d56:	ec86                	sd	ra,88(sp)
    80003d58:	e8a2                	sd	s0,80(sp)
    80003d5a:	e4a6                	sd	s1,72(sp)
    80003d5c:	e0ca                	sd	s2,64(sp)
    80003d5e:	fc4e                	sd	s3,56(sp)
    80003d60:	f852                	sd	s4,48(sp)
    80003d62:	f456                	sd	s5,40(sp)
    80003d64:	f05a                	sd	s6,32(sp)
    80003d66:	ec5e                	sd	s7,24(sp)
    80003d68:	e862                	sd	s8,16(sp)
    80003d6a:	e466                	sd	s9,8(sp)
    80003d6c:	1080                	addi	s0,sp,96
    80003d6e:	84aa                	mv	s1,a0
    80003d70:	8aae                	mv	s5,a1
    80003d72:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d74:	00054703          	lbu	a4,0(a0)
    80003d78:	02f00793          	li	a5,47
    80003d7c:	02f70363          	beq	a4,a5,80003da2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d80:	ffffe097          	auipc	ra,0xffffe
    80003d84:	c34080e7          	jalr	-972(ra) # 800019b4 <myproc>
    80003d88:	15053503          	ld	a0,336(a0)
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	9f6080e7          	jalr	-1546(ra) # 80003782 <idup>
    80003d94:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d96:	02f00913          	li	s2,47
  len = path - s;
    80003d9a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d9c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d9e:	4b85                	li	s7,1
    80003da0:	a865                	j	80003e58 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003da2:	4585                	li	a1,1
    80003da4:	4505                	li	a0,1
    80003da6:	fffff097          	auipc	ra,0xfffff
    80003daa:	6e2080e7          	jalr	1762(ra) # 80003488 <iget>
    80003dae:	89aa                	mv	s3,a0
    80003db0:	b7dd                	j	80003d96 <namex+0x42>
      iunlockput(ip);
    80003db2:	854e                	mv	a0,s3
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	c6e080e7          	jalr	-914(ra) # 80003a22 <iunlockput>
      return 0;
    80003dbc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dbe:	854e                	mv	a0,s3
    80003dc0:	60e6                	ld	ra,88(sp)
    80003dc2:	6446                	ld	s0,80(sp)
    80003dc4:	64a6                	ld	s1,72(sp)
    80003dc6:	6906                	ld	s2,64(sp)
    80003dc8:	79e2                	ld	s3,56(sp)
    80003dca:	7a42                	ld	s4,48(sp)
    80003dcc:	7aa2                	ld	s5,40(sp)
    80003dce:	7b02                	ld	s6,32(sp)
    80003dd0:	6be2                	ld	s7,24(sp)
    80003dd2:	6c42                	ld	s8,16(sp)
    80003dd4:	6ca2                	ld	s9,8(sp)
    80003dd6:	6125                	addi	sp,sp,96
    80003dd8:	8082                	ret
      iunlock(ip);
    80003dda:	854e                	mv	a0,s3
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	aa6080e7          	jalr	-1370(ra) # 80003882 <iunlock>
      return ip;
    80003de4:	bfe9                	j	80003dbe <namex+0x6a>
      iunlockput(ip);
    80003de6:	854e                	mv	a0,s3
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	c3a080e7          	jalr	-966(ra) # 80003a22 <iunlockput>
      return 0;
    80003df0:	89e6                	mv	s3,s9
    80003df2:	b7f1                	j	80003dbe <namex+0x6a>
  len = path - s;
    80003df4:	40b48633          	sub	a2,s1,a1
    80003df8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003dfc:	099c5463          	bge	s8,s9,80003e84 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e00:	4639                	li	a2,14
    80003e02:	8552                	mv	a0,s4
    80003e04:	ffffd097          	auipc	ra,0xffffd
    80003e08:	f2a080e7          	jalr	-214(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003e0c:	0004c783          	lbu	a5,0(s1)
    80003e10:	01279763          	bne	a5,s2,80003e1e <namex+0xca>
    path++;
    80003e14:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e16:	0004c783          	lbu	a5,0(s1)
    80003e1a:	ff278de3          	beq	a5,s2,80003e14 <namex+0xc0>
    ilock(ip);
    80003e1e:	854e                	mv	a0,s3
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	9a0080e7          	jalr	-1632(ra) # 800037c0 <ilock>
    if(ip->type != T_DIR){
    80003e28:	04499783          	lh	a5,68(s3)
    80003e2c:	f97793e3          	bne	a5,s7,80003db2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e30:	000a8563          	beqz	s5,80003e3a <namex+0xe6>
    80003e34:	0004c783          	lbu	a5,0(s1)
    80003e38:	d3cd                	beqz	a5,80003dda <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e3a:	865a                	mv	a2,s6
    80003e3c:	85d2                	mv	a1,s4
    80003e3e:	854e                	mv	a0,s3
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	e64080e7          	jalr	-412(ra) # 80003ca4 <dirlookup>
    80003e48:	8caa                	mv	s9,a0
    80003e4a:	dd51                	beqz	a0,80003de6 <namex+0x92>
    iunlockput(ip);
    80003e4c:	854e                	mv	a0,s3
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	bd4080e7          	jalr	-1068(ra) # 80003a22 <iunlockput>
    ip = next;
    80003e56:	89e6                	mv	s3,s9
  while(*path == '/')
    80003e58:	0004c783          	lbu	a5,0(s1)
    80003e5c:	05279763          	bne	a5,s2,80003eaa <namex+0x156>
    path++;
    80003e60:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e62:	0004c783          	lbu	a5,0(s1)
    80003e66:	ff278de3          	beq	a5,s2,80003e60 <namex+0x10c>
  if(*path == 0)
    80003e6a:	c79d                	beqz	a5,80003e98 <namex+0x144>
    path++;
    80003e6c:	85a6                	mv	a1,s1
  len = path - s;
    80003e6e:	8cda                	mv	s9,s6
    80003e70:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e72:	01278963          	beq	a5,s2,80003e84 <namex+0x130>
    80003e76:	dfbd                	beqz	a5,80003df4 <namex+0xa0>
    path++;
    80003e78:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e7a:	0004c783          	lbu	a5,0(s1)
    80003e7e:	ff279ce3          	bne	a5,s2,80003e76 <namex+0x122>
    80003e82:	bf8d                	j	80003df4 <namex+0xa0>
    memmove(name, s, len);
    80003e84:	2601                	sext.w	a2,a2
    80003e86:	8552                	mv	a0,s4
    80003e88:	ffffd097          	auipc	ra,0xffffd
    80003e8c:	ea6080e7          	jalr	-346(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003e90:	9cd2                	add	s9,s9,s4
    80003e92:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e96:	bf9d                	j	80003e0c <namex+0xb8>
  if(nameiparent){
    80003e98:	f20a83e3          	beqz	s5,80003dbe <namex+0x6a>
    iput(ip);
    80003e9c:	854e                	mv	a0,s3
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	adc080e7          	jalr	-1316(ra) # 8000397a <iput>
    return 0;
    80003ea6:	4981                	li	s3,0
    80003ea8:	bf19                	j	80003dbe <namex+0x6a>
  if(*path == 0)
    80003eaa:	d7fd                	beqz	a5,80003e98 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003eac:	0004c783          	lbu	a5,0(s1)
    80003eb0:	85a6                	mv	a1,s1
    80003eb2:	b7d1                	j	80003e76 <namex+0x122>

0000000080003eb4 <dirlink>:
{
    80003eb4:	7139                	addi	sp,sp,-64
    80003eb6:	fc06                	sd	ra,56(sp)
    80003eb8:	f822                	sd	s0,48(sp)
    80003eba:	f426                	sd	s1,40(sp)
    80003ebc:	f04a                	sd	s2,32(sp)
    80003ebe:	ec4e                	sd	s3,24(sp)
    80003ec0:	e852                	sd	s4,16(sp)
    80003ec2:	0080                	addi	s0,sp,64
    80003ec4:	892a                	mv	s2,a0
    80003ec6:	8a2e                	mv	s4,a1
    80003ec8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eca:	4601                	li	a2,0
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	dd8080e7          	jalr	-552(ra) # 80003ca4 <dirlookup>
    80003ed4:	e93d                	bnez	a0,80003f4a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed6:	04c92483          	lw	s1,76(s2)
    80003eda:	c49d                	beqz	s1,80003f08 <dirlink+0x54>
    80003edc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ede:	4741                	li	a4,16
    80003ee0:	86a6                	mv	a3,s1
    80003ee2:	fc040613          	addi	a2,s0,-64
    80003ee6:	4581                	li	a1,0
    80003ee8:	854a                	mv	a0,s2
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	b8a080e7          	jalr	-1142(ra) # 80003a74 <readi>
    80003ef2:	47c1                	li	a5,16
    80003ef4:	06f51163          	bne	a0,a5,80003f56 <dirlink+0xa2>
    if(de.inum == 0)
    80003ef8:	fc045783          	lhu	a5,-64(s0)
    80003efc:	c791                	beqz	a5,80003f08 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003efe:	24c1                	addiw	s1,s1,16
    80003f00:	04c92783          	lw	a5,76(s2)
    80003f04:	fcf4ede3          	bltu	s1,a5,80003ede <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f08:	4639                	li	a2,14
    80003f0a:	85d2                	mv	a1,s4
    80003f0c:	fc240513          	addi	a0,s0,-62
    80003f10:	ffffd097          	auipc	ra,0xffffd
    80003f14:	ece080e7          	jalr	-306(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003f18:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f1c:	4741                	li	a4,16
    80003f1e:	86a6                	mv	a3,s1
    80003f20:	fc040613          	addi	a2,s0,-64
    80003f24:	4581                	li	a1,0
    80003f26:	854a                	mv	a0,s2
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	c44080e7          	jalr	-956(ra) # 80003b6c <writei>
    80003f30:	1541                	addi	a0,a0,-16
    80003f32:	00a03533          	snez	a0,a0
    80003f36:	40a00533          	neg	a0,a0
}
    80003f3a:	70e2                	ld	ra,56(sp)
    80003f3c:	7442                	ld	s0,48(sp)
    80003f3e:	74a2                	ld	s1,40(sp)
    80003f40:	7902                	ld	s2,32(sp)
    80003f42:	69e2                	ld	s3,24(sp)
    80003f44:	6a42                	ld	s4,16(sp)
    80003f46:	6121                	addi	sp,sp,64
    80003f48:	8082                	ret
    iput(ip);
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	a30080e7          	jalr	-1488(ra) # 8000397a <iput>
    return -1;
    80003f52:	557d                	li	a0,-1
    80003f54:	b7dd                	j	80003f3a <dirlink+0x86>
      panic("dirlink read");
    80003f56:	00004517          	auipc	a0,0x4
    80003f5a:	6e250513          	addi	a0,a0,1762 # 80008638 <syscalls+0x1e8>
    80003f5e:	ffffc097          	auipc	ra,0xffffc
    80003f62:	5e0080e7          	jalr	1504(ra) # 8000053e <panic>

0000000080003f66 <namei>:

struct inode*
namei(char *path)
{
    80003f66:	1101                	addi	sp,sp,-32
    80003f68:	ec06                	sd	ra,24(sp)
    80003f6a:	e822                	sd	s0,16(sp)
    80003f6c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f6e:	fe040613          	addi	a2,s0,-32
    80003f72:	4581                	li	a1,0
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	de0080e7          	jalr	-544(ra) # 80003d54 <namex>
}
    80003f7c:	60e2                	ld	ra,24(sp)
    80003f7e:	6442                	ld	s0,16(sp)
    80003f80:	6105                	addi	sp,sp,32
    80003f82:	8082                	ret

0000000080003f84 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f84:	1141                	addi	sp,sp,-16
    80003f86:	e406                	sd	ra,8(sp)
    80003f88:	e022                	sd	s0,0(sp)
    80003f8a:	0800                	addi	s0,sp,16
    80003f8c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f8e:	4585                	li	a1,1
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	dc4080e7          	jalr	-572(ra) # 80003d54 <namex>
}
    80003f98:	60a2                	ld	ra,8(sp)
    80003f9a:	6402                	ld	s0,0(sp)
    80003f9c:	0141                	addi	sp,sp,16
    80003f9e:	8082                	ret

0000000080003fa0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fa0:	1101                	addi	sp,sp,-32
    80003fa2:	ec06                	sd	ra,24(sp)
    80003fa4:	e822                	sd	s0,16(sp)
    80003fa6:	e426                	sd	s1,8(sp)
    80003fa8:	e04a                	sd	s2,0(sp)
    80003faa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fac:	0001d917          	auipc	s2,0x1d
    80003fb0:	b9490913          	addi	s2,s2,-1132 # 80020b40 <log>
    80003fb4:	01892583          	lw	a1,24(s2)
    80003fb8:	02892503          	lw	a0,40(s2)
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	fea080e7          	jalr	-22(ra) # 80002fa6 <bread>
    80003fc4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fc6:	02c92683          	lw	a3,44(s2)
    80003fca:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fcc:	02d05763          	blez	a3,80003ffa <write_head+0x5a>
    80003fd0:	0001d797          	auipc	a5,0x1d
    80003fd4:	ba078793          	addi	a5,a5,-1120 # 80020b70 <log+0x30>
    80003fd8:	05c50713          	addi	a4,a0,92
    80003fdc:	36fd                	addiw	a3,a3,-1
    80003fde:	1682                	slli	a3,a3,0x20
    80003fe0:	9281                	srli	a3,a3,0x20
    80003fe2:	068a                	slli	a3,a3,0x2
    80003fe4:	0001d617          	auipc	a2,0x1d
    80003fe8:	b9060613          	addi	a2,a2,-1136 # 80020b74 <log+0x34>
    80003fec:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fee:	4390                	lw	a2,0(a5)
    80003ff0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ff2:	0791                	addi	a5,a5,4
    80003ff4:	0711                	addi	a4,a4,4
    80003ff6:	fed79ce3          	bne	a5,a3,80003fee <write_head+0x4e>
  }
  bwrite(buf);
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	09c080e7          	jalr	156(ra) # 80003098 <bwrite>
  brelse(buf);
    80004004:	8526                	mv	a0,s1
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	0d0080e7          	jalr	208(ra) # 800030d6 <brelse>
}
    8000400e:	60e2                	ld	ra,24(sp)
    80004010:	6442                	ld	s0,16(sp)
    80004012:	64a2                	ld	s1,8(sp)
    80004014:	6902                	ld	s2,0(sp)
    80004016:	6105                	addi	sp,sp,32
    80004018:	8082                	ret

000000008000401a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000401a:	0001d797          	auipc	a5,0x1d
    8000401e:	b527a783          	lw	a5,-1198(a5) # 80020b6c <log+0x2c>
    80004022:	0af05d63          	blez	a5,800040dc <install_trans+0xc2>
{
    80004026:	7139                	addi	sp,sp,-64
    80004028:	fc06                	sd	ra,56(sp)
    8000402a:	f822                	sd	s0,48(sp)
    8000402c:	f426                	sd	s1,40(sp)
    8000402e:	f04a                	sd	s2,32(sp)
    80004030:	ec4e                	sd	s3,24(sp)
    80004032:	e852                	sd	s4,16(sp)
    80004034:	e456                	sd	s5,8(sp)
    80004036:	e05a                	sd	s6,0(sp)
    80004038:	0080                	addi	s0,sp,64
    8000403a:	8b2a                	mv	s6,a0
    8000403c:	0001da97          	auipc	s5,0x1d
    80004040:	b34a8a93          	addi	s5,s5,-1228 # 80020b70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004044:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004046:	0001d997          	auipc	s3,0x1d
    8000404a:	afa98993          	addi	s3,s3,-1286 # 80020b40 <log>
    8000404e:	a00d                	j	80004070 <install_trans+0x56>
    brelse(lbuf);
    80004050:	854a                	mv	a0,s2
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	084080e7          	jalr	132(ra) # 800030d6 <brelse>
    brelse(dbuf);
    8000405a:	8526                	mv	a0,s1
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	07a080e7          	jalr	122(ra) # 800030d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004064:	2a05                	addiw	s4,s4,1
    80004066:	0a91                	addi	s5,s5,4
    80004068:	02c9a783          	lw	a5,44(s3)
    8000406c:	04fa5e63          	bge	s4,a5,800040c8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004070:	0189a583          	lw	a1,24(s3)
    80004074:	014585bb          	addw	a1,a1,s4
    80004078:	2585                	addiw	a1,a1,1
    8000407a:	0289a503          	lw	a0,40(s3)
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	f28080e7          	jalr	-216(ra) # 80002fa6 <bread>
    80004086:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004088:	000aa583          	lw	a1,0(s5)
    8000408c:	0289a503          	lw	a0,40(s3)
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	f16080e7          	jalr	-234(ra) # 80002fa6 <bread>
    80004098:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000409a:	40000613          	li	a2,1024
    8000409e:	05890593          	addi	a1,s2,88
    800040a2:	05850513          	addi	a0,a0,88
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	c88080e7          	jalr	-888(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800040ae:	8526                	mv	a0,s1
    800040b0:	fffff097          	auipc	ra,0xfffff
    800040b4:	fe8080e7          	jalr	-24(ra) # 80003098 <bwrite>
    if(recovering == 0)
    800040b8:	f80b1ce3          	bnez	s6,80004050 <install_trans+0x36>
      bunpin(dbuf);
    800040bc:	8526                	mv	a0,s1
    800040be:	fffff097          	auipc	ra,0xfffff
    800040c2:	0f2080e7          	jalr	242(ra) # 800031b0 <bunpin>
    800040c6:	b769                	j	80004050 <install_trans+0x36>
}
    800040c8:	70e2                	ld	ra,56(sp)
    800040ca:	7442                	ld	s0,48(sp)
    800040cc:	74a2                	ld	s1,40(sp)
    800040ce:	7902                	ld	s2,32(sp)
    800040d0:	69e2                	ld	s3,24(sp)
    800040d2:	6a42                	ld	s4,16(sp)
    800040d4:	6aa2                	ld	s5,8(sp)
    800040d6:	6b02                	ld	s6,0(sp)
    800040d8:	6121                	addi	sp,sp,64
    800040da:	8082                	ret
    800040dc:	8082                	ret

00000000800040de <initlog>:
{
    800040de:	7179                	addi	sp,sp,-48
    800040e0:	f406                	sd	ra,40(sp)
    800040e2:	f022                	sd	s0,32(sp)
    800040e4:	ec26                	sd	s1,24(sp)
    800040e6:	e84a                	sd	s2,16(sp)
    800040e8:	e44e                	sd	s3,8(sp)
    800040ea:	1800                	addi	s0,sp,48
    800040ec:	892a                	mv	s2,a0
    800040ee:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040f0:	0001d497          	auipc	s1,0x1d
    800040f4:	a5048493          	addi	s1,s1,-1456 # 80020b40 <log>
    800040f8:	00004597          	auipc	a1,0x4
    800040fc:	55058593          	addi	a1,a1,1360 # 80008648 <syscalls+0x1f8>
    80004100:	8526                	mv	a0,s1
    80004102:	ffffd097          	auipc	ra,0xffffd
    80004106:	a44080e7          	jalr	-1468(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000410a:	0149a583          	lw	a1,20(s3)
    8000410e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004110:	0109a783          	lw	a5,16(s3)
    80004114:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004116:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000411a:	854a                	mv	a0,s2
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	e8a080e7          	jalr	-374(ra) # 80002fa6 <bread>
  log.lh.n = lh->n;
    80004124:	4d34                	lw	a3,88(a0)
    80004126:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004128:	02d05563          	blez	a3,80004152 <initlog+0x74>
    8000412c:	05c50793          	addi	a5,a0,92
    80004130:	0001d717          	auipc	a4,0x1d
    80004134:	a4070713          	addi	a4,a4,-1472 # 80020b70 <log+0x30>
    80004138:	36fd                	addiw	a3,a3,-1
    8000413a:	1682                	slli	a3,a3,0x20
    8000413c:	9281                	srli	a3,a3,0x20
    8000413e:	068a                	slli	a3,a3,0x2
    80004140:	06050613          	addi	a2,a0,96
    80004144:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004146:	4390                	lw	a2,0(a5)
    80004148:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000414a:	0791                	addi	a5,a5,4
    8000414c:	0711                	addi	a4,a4,4
    8000414e:	fed79ce3          	bne	a5,a3,80004146 <initlog+0x68>
  brelse(buf);
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	f84080e7          	jalr	-124(ra) # 800030d6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000415a:	4505                	li	a0,1
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	ebe080e7          	jalr	-322(ra) # 8000401a <install_trans>
  log.lh.n = 0;
    80004164:	0001d797          	auipc	a5,0x1d
    80004168:	a007a423          	sw	zero,-1528(a5) # 80020b6c <log+0x2c>
  write_head(); // clear the log
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	e34080e7          	jalr	-460(ra) # 80003fa0 <write_head>
}
    80004174:	70a2                	ld	ra,40(sp)
    80004176:	7402                	ld	s0,32(sp)
    80004178:	64e2                	ld	s1,24(sp)
    8000417a:	6942                	ld	s2,16(sp)
    8000417c:	69a2                	ld	s3,8(sp)
    8000417e:	6145                	addi	sp,sp,48
    80004180:	8082                	ret

0000000080004182 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004182:	1101                	addi	sp,sp,-32
    80004184:	ec06                	sd	ra,24(sp)
    80004186:	e822                	sd	s0,16(sp)
    80004188:	e426                	sd	s1,8(sp)
    8000418a:	e04a                	sd	s2,0(sp)
    8000418c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000418e:	0001d517          	auipc	a0,0x1d
    80004192:	9b250513          	addi	a0,a0,-1614 # 80020b40 <log>
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	a40080e7          	jalr	-1472(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000419e:	0001d497          	auipc	s1,0x1d
    800041a2:	9a248493          	addi	s1,s1,-1630 # 80020b40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041a6:	4979                	li	s2,30
    800041a8:	a039                	j	800041b6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041aa:	85a6                	mv	a1,s1
    800041ac:	8526                	mv	a0,s1
    800041ae:	ffffe097          	auipc	ra,0xffffe
    800041b2:	eae080e7          	jalr	-338(ra) # 8000205c <sleep>
    if(log.committing){
    800041b6:	50dc                	lw	a5,36(s1)
    800041b8:	fbed                	bnez	a5,800041aa <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ba:	509c                	lw	a5,32(s1)
    800041bc:	0017871b          	addiw	a4,a5,1
    800041c0:	0007069b          	sext.w	a3,a4
    800041c4:	0027179b          	slliw	a5,a4,0x2
    800041c8:	9fb9                	addw	a5,a5,a4
    800041ca:	0017979b          	slliw	a5,a5,0x1
    800041ce:	54d8                	lw	a4,44(s1)
    800041d0:	9fb9                	addw	a5,a5,a4
    800041d2:	00f95963          	bge	s2,a5,800041e4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041d6:	85a6                	mv	a1,s1
    800041d8:	8526                	mv	a0,s1
    800041da:	ffffe097          	auipc	ra,0xffffe
    800041de:	e82080e7          	jalr	-382(ra) # 8000205c <sleep>
    800041e2:	bfd1                	j	800041b6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041e4:	0001d517          	auipc	a0,0x1d
    800041e8:	95c50513          	addi	a0,a0,-1700 # 80020b40 <log>
    800041ec:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	a9c080e7          	jalr	-1380(ra) # 80000c8a <release>
      break;
    }
  }
}
    800041f6:	60e2                	ld	ra,24(sp)
    800041f8:	6442                	ld	s0,16(sp)
    800041fa:	64a2                	ld	s1,8(sp)
    800041fc:	6902                	ld	s2,0(sp)
    800041fe:	6105                	addi	sp,sp,32
    80004200:	8082                	ret

0000000080004202 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004202:	7139                	addi	sp,sp,-64
    80004204:	fc06                	sd	ra,56(sp)
    80004206:	f822                	sd	s0,48(sp)
    80004208:	f426                	sd	s1,40(sp)
    8000420a:	f04a                	sd	s2,32(sp)
    8000420c:	ec4e                	sd	s3,24(sp)
    8000420e:	e852                	sd	s4,16(sp)
    80004210:	e456                	sd	s5,8(sp)
    80004212:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004214:	0001d497          	auipc	s1,0x1d
    80004218:	92c48493          	addi	s1,s1,-1748 # 80020b40 <log>
    8000421c:	8526                	mv	a0,s1
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	9b8080e7          	jalr	-1608(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004226:	509c                	lw	a5,32(s1)
    80004228:	37fd                	addiw	a5,a5,-1
    8000422a:	0007891b          	sext.w	s2,a5
    8000422e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004230:	50dc                	lw	a5,36(s1)
    80004232:	e7b9                	bnez	a5,80004280 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004234:	04091e63          	bnez	s2,80004290 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004238:	0001d497          	auipc	s1,0x1d
    8000423c:	90848493          	addi	s1,s1,-1784 # 80020b40 <log>
    80004240:	4785                	li	a5,1
    80004242:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004244:	8526                	mv	a0,s1
    80004246:	ffffd097          	auipc	ra,0xffffd
    8000424a:	a44080e7          	jalr	-1468(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000424e:	54dc                	lw	a5,44(s1)
    80004250:	06f04763          	bgtz	a5,800042be <end_op+0xbc>
    acquire(&log.lock);
    80004254:	0001d497          	auipc	s1,0x1d
    80004258:	8ec48493          	addi	s1,s1,-1812 # 80020b40 <log>
    8000425c:	8526                	mv	a0,s1
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	978080e7          	jalr	-1672(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004266:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000426a:	8526                	mv	a0,s1
    8000426c:	ffffe097          	auipc	ra,0xffffe
    80004270:	e54080e7          	jalr	-428(ra) # 800020c0 <wakeup>
    release(&log.lock);
    80004274:	8526                	mv	a0,s1
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	a14080e7          	jalr	-1516(ra) # 80000c8a <release>
}
    8000427e:	a03d                	j	800042ac <end_op+0xaa>
    panic("log.committing");
    80004280:	00004517          	auipc	a0,0x4
    80004284:	3d050513          	addi	a0,a0,976 # 80008650 <syscalls+0x200>
    80004288:	ffffc097          	auipc	ra,0xffffc
    8000428c:	2b6080e7          	jalr	694(ra) # 8000053e <panic>
    wakeup(&log);
    80004290:	0001d497          	auipc	s1,0x1d
    80004294:	8b048493          	addi	s1,s1,-1872 # 80020b40 <log>
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffe097          	auipc	ra,0xffffe
    8000429e:	e26080e7          	jalr	-474(ra) # 800020c0 <wakeup>
  release(&log.lock);
    800042a2:	8526                	mv	a0,s1
    800042a4:	ffffd097          	auipc	ra,0xffffd
    800042a8:	9e6080e7          	jalr	-1562(ra) # 80000c8a <release>
}
    800042ac:	70e2                	ld	ra,56(sp)
    800042ae:	7442                	ld	s0,48(sp)
    800042b0:	74a2                	ld	s1,40(sp)
    800042b2:	7902                	ld	s2,32(sp)
    800042b4:	69e2                	ld	s3,24(sp)
    800042b6:	6a42                	ld	s4,16(sp)
    800042b8:	6aa2                	ld	s5,8(sp)
    800042ba:	6121                	addi	sp,sp,64
    800042bc:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042be:	0001da97          	auipc	s5,0x1d
    800042c2:	8b2a8a93          	addi	s5,s5,-1870 # 80020b70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042c6:	0001da17          	auipc	s4,0x1d
    800042ca:	87aa0a13          	addi	s4,s4,-1926 # 80020b40 <log>
    800042ce:	018a2583          	lw	a1,24(s4)
    800042d2:	012585bb          	addw	a1,a1,s2
    800042d6:	2585                	addiw	a1,a1,1
    800042d8:	028a2503          	lw	a0,40(s4)
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	cca080e7          	jalr	-822(ra) # 80002fa6 <bread>
    800042e4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042e6:	000aa583          	lw	a1,0(s5)
    800042ea:	028a2503          	lw	a0,40(s4)
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	cb8080e7          	jalr	-840(ra) # 80002fa6 <bread>
    800042f6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042f8:	40000613          	li	a2,1024
    800042fc:	05850593          	addi	a1,a0,88
    80004300:	05848513          	addi	a0,s1,88
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	a2a080e7          	jalr	-1494(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000430c:	8526                	mv	a0,s1
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	d8a080e7          	jalr	-630(ra) # 80003098 <bwrite>
    brelse(from);
    80004316:	854e                	mv	a0,s3
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	dbe080e7          	jalr	-578(ra) # 800030d6 <brelse>
    brelse(to);
    80004320:	8526                	mv	a0,s1
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	db4080e7          	jalr	-588(ra) # 800030d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000432a:	2905                	addiw	s2,s2,1
    8000432c:	0a91                	addi	s5,s5,4
    8000432e:	02ca2783          	lw	a5,44(s4)
    80004332:	f8f94ee3          	blt	s2,a5,800042ce <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	c6a080e7          	jalr	-918(ra) # 80003fa0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000433e:	4501                	li	a0,0
    80004340:	00000097          	auipc	ra,0x0
    80004344:	cda080e7          	jalr	-806(ra) # 8000401a <install_trans>
    log.lh.n = 0;
    80004348:	0001d797          	auipc	a5,0x1d
    8000434c:	8207a223          	sw	zero,-2012(a5) # 80020b6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004350:	00000097          	auipc	ra,0x0
    80004354:	c50080e7          	jalr	-944(ra) # 80003fa0 <write_head>
    80004358:	bdf5                	j	80004254 <end_op+0x52>

000000008000435a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000435a:	1101                	addi	sp,sp,-32
    8000435c:	ec06                	sd	ra,24(sp)
    8000435e:	e822                	sd	s0,16(sp)
    80004360:	e426                	sd	s1,8(sp)
    80004362:	e04a                	sd	s2,0(sp)
    80004364:	1000                	addi	s0,sp,32
    80004366:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004368:	0001c917          	auipc	s2,0x1c
    8000436c:	7d890913          	addi	s2,s2,2008 # 80020b40 <log>
    80004370:	854a                	mv	a0,s2
    80004372:	ffffd097          	auipc	ra,0xffffd
    80004376:	864080e7          	jalr	-1948(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000437a:	02c92603          	lw	a2,44(s2)
    8000437e:	47f5                	li	a5,29
    80004380:	06c7c563          	blt	a5,a2,800043ea <log_write+0x90>
    80004384:	0001c797          	auipc	a5,0x1c
    80004388:	7d87a783          	lw	a5,2008(a5) # 80020b5c <log+0x1c>
    8000438c:	37fd                	addiw	a5,a5,-1
    8000438e:	04f65e63          	bge	a2,a5,800043ea <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004392:	0001c797          	auipc	a5,0x1c
    80004396:	7ce7a783          	lw	a5,1998(a5) # 80020b60 <log+0x20>
    8000439a:	06f05063          	blez	a5,800043fa <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000439e:	4781                	li	a5,0
    800043a0:	06c05563          	blez	a2,8000440a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043a4:	44cc                	lw	a1,12(s1)
    800043a6:	0001c717          	auipc	a4,0x1c
    800043aa:	7ca70713          	addi	a4,a4,1994 # 80020b70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ae:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043b0:	4314                	lw	a3,0(a4)
    800043b2:	04b68c63          	beq	a3,a1,8000440a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043b6:	2785                	addiw	a5,a5,1
    800043b8:	0711                	addi	a4,a4,4
    800043ba:	fef61be3          	bne	a2,a5,800043b0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043be:	0621                	addi	a2,a2,8
    800043c0:	060a                	slli	a2,a2,0x2
    800043c2:	0001c797          	auipc	a5,0x1c
    800043c6:	77e78793          	addi	a5,a5,1918 # 80020b40 <log>
    800043ca:	963e                	add	a2,a2,a5
    800043cc:	44dc                	lw	a5,12(s1)
    800043ce:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043d0:	8526                	mv	a0,s1
    800043d2:	fffff097          	auipc	ra,0xfffff
    800043d6:	da2080e7          	jalr	-606(ra) # 80003174 <bpin>
    log.lh.n++;
    800043da:	0001c717          	auipc	a4,0x1c
    800043de:	76670713          	addi	a4,a4,1894 # 80020b40 <log>
    800043e2:	575c                	lw	a5,44(a4)
    800043e4:	2785                	addiw	a5,a5,1
    800043e6:	d75c                	sw	a5,44(a4)
    800043e8:	a835                	j	80004424 <log_write+0xca>
    panic("too big a transaction");
    800043ea:	00004517          	auipc	a0,0x4
    800043ee:	27650513          	addi	a0,a0,630 # 80008660 <syscalls+0x210>
    800043f2:	ffffc097          	auipc	ra,0xffffc
    800043f6:	14c080e7          	jalr	332(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043fa:	00004517          	auipc	a0,0x4
    800043fe:	27e50513          	addi	a0,a0,638 # 80008678 <syscalls+0x228>
    80004402:	ffffc097          	auipc	ra,0xffffc
    80004406:	13c080e7          	jalr	316(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000440a:	00878713          	addi	a4,a5,8
    8000440e:	00271693          	slli	a3,a4,0x2
    80004412:	0001c717          	auipc	a4,0x1c
    80004416:	72e70713          	addi	a4,a4,1838 # 80020b40 <log>
    8000441a:	9736                	add	a4,a4,a3
    8000441c:	44d4                	lw	a3,12(s1)
    8000441e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004420:	faf608e3          	beq	a2,a5,800043d0 <log_write+0x76>
  }
  release(&log.lock);
    80004424:	0001c517          	auipc	a0,0x1c
    80004428:	71c50513          	addi	a0,a0,1820 # 80020b40 <log>
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	85e080e7          	jalr	-1954(ra) # 80000c8a <release>
}
    80004434:	60e2                	ld	ra,24(sp)
    80004436:	6442                	ld	s0,16(sp)
    80004438:	64a2                	ld	s1,8(sp)
    8000443a:	6902                	ld	s2,0(sp)
    8000443c:	6105                	addi	sp,sp,32
    8000443e:	8082                	ret

0000000080004440 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004440:	1101                	addi	sp,sp,-32
    80004442:	ec06                	sd	ra,24(sp)
    80004444:	e822                	sd	s0,16(sp)
    80004446:	e426                	sd	s1,8(sp)
    80004448:	e04a                	sd	s2,0(sp)
    8000444a:	1000                	addi	s0,sp,32
    8000444c:	84aa                	mv	s1,a0
    8000444e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004450:	00004597          	auipc	a1,0x4
    80004454:	24858593          	addi	a1,a1,584 # 80008698 <syscalls+0x248>
    80004458:	0521                	addi	a0,a0,8
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	6ec080e7          	jalr	1772(ra) # 80000b46 <initlock>
  lk->name = name;
    80004462:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004466:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000446a:	0204a423          	sw	zero,40(s1)
}
    8000446e:	60e2                	ld	ra,24(sp)
    80004470:	6442                	ld	s0,16(sp)
    80004472:	64a2                	ld	s1,8(sp)
    80004474:	6902                	ld	s2,0(sp)
    80004476:	6105                	addi	sp,sp,32
    80004478:	8082                	ret

000000008000447a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000447a:	1101                	addi	sp,sp,-32
    8000447c:	ec06                	sd	ra,24(sp)
    8000447e:	e822                	sd	s0,16(sp)
    80004480:	e426                	sd	s1,8(sp)
    80004482:	e04a                	sd	s2,0(sp)
    80004484:	1000                	addi	s0,sp,32
    80004486:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004488:	00850913          	addi	s2,a0,8
    8000448c:	854a                	mv	a0,s2
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	748080e7          	jalr	1864(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004496:	409c                	lw	a5,0(s1)
    80004498:	cb89                	beqz	a5,800044aa <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000449a:	85ca                	mv	a1,s2
    8000449c:	8526                	mv	a0,s1
    8000449e:	ffffe097          	auipc	ra,0xffffe
    800044a2:	bbe080e7          	jalr	-1090(ra) # 8000205c <sleep>
  while (lk->locked) {
    800044a6:	409c                	lw	a5,0(s1)
    800044a8:	fbed                	bnez	a5,8000449a <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044aa:	4785                	li	a5,1
    800044ac:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044ae:	ffffd097          	auipc	ra,0xffffd
    800044b2:	506080e7          	jalr	1286(ra) # 800019b4 <myproc>
    800044b6:	591c                	lw	a5,48(a0)
    800044b8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044ba:	854a                	mv	a0,s2
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	7ce080e7          	jalr	1998(ra) # 80000c8a <release>
}
    800044c4:	60e2                	ld	ra,24(sp)
    800044c6:	6442                	ld	s0,16(sp)
    800044c8:	64a2                	ld	s1,8(sp)
    800044ca:	6902                	ld	s2,0(sp)
    800044cc:	6105                	addi	sp,sp,32
    800044ce:	8082                	ret

00000000800044d0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044d0:	1101                	addi	sp,sp,-32
    800044d2:	ec06                	sd	ra,24(sp)
    800044d4:	e822                	sd	s0,16(sp)
    800044d6:	e426                	sd	s1,8(sp)
    800044d8:	e04a                	sd	s2,0(sp)
    800044da:	1000                	addi	s0,sp,32
    800044dc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044de:	00850913          	addi	s2,a0,8
    800044e2:	854a                	mv	a0,s2
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	6f2080e7          	jalr	1778(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044ec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044f0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044f4:	8526                	mv	a0,s1
    800044f6:	ffffe097          	auipc	ra,0xffffe
    800044fa:	bca080e7          	jalr	-1078(ra) # 800020c0 <wakeup>
  release(&lk->lk);
    800044fe:	854a                	mv	a0,s2
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	78a080e7          	jalr	1930(ra) # 80000c8a <release>
}
    80004508:	60e2                	ld	ra,24(sp)
    8000450a:	6442                	ld	s0,16(sp)
    8000450c:	64a2                	ld	s1,8(sp)
    8000450e:	6902                	ld	s2,0(sp)
    80004510:	6105                	addi	sp,sp,32
    80004512:	8082                	ret

0000000080004514 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004514:	7179                	addi	sp,sp,-48
    80004516:	f406                	sd	ra,40(sp)
    80004518:	f022                	sd	s0,32(sp)
    8000451a:	ec26                	sd	s1,24(sp)
    8000451c:	e84a                	sd	s2,16(sp)
    8000451e:	e44e                	sd	s3,8(sp)
    80004520:	1800                	addi	s0,sp,48
    80004522:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004524:	00850913          	addi	s2,a0,8
    80004528:	854a                	mv	a0,s2
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	6ac080e7          	jalr	1708(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004532:	409c                	lw	a5,0(s1)
    80004534:	ef99                	bnez	a5,80004552 <holdingsleep+0x3e>
    80004536:	4481                	li	s1,0
  release(&lk->lk);
    80004538:	854a                	mv	a0,s2
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	750080e7          	jalr	1872(ra) # 80000c8a <release>
  return r;
}
    80004542:	8526                	mv	a0,s1
    80004544:	70a2                	ld	ra,40(sp)
    80004546:	7402                	ld	s0,32(sp)
    80004548:	64e2                	ld	s1,24(sp)
    8000454a:	6942                	ld	s2,16(sp)
    8000454c:	69a2                	ld	s3,8(sp)
    8000454e:	6145                	addi	sp,sp,48
    80004550:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004552:	0284a983          	lw	s3,40(s1)
    80004556:	ffffd097          	auipc	ra,0xffffd
    8000455a:	45e080e7          	jalr	1118(ra) # 800019b4 <myproc>
    8000455e:	5904                	lw	s1,48(a0)
    80004560:	413484b3          	sub	s1,s1,s3
    80004564:	0014b493          	seqz	s1,s1
    80004568:	bfc1                	j	80004538 <holdingsleep+0x24>

000000008000456a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000456a:	1141                	addi	sp,sp,-16
    8000456c:	e406                	sd	ra,8(sp)
    8000456e:	e022                	sd	s0,0(sp)
    80004570:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004572:	00004597          	auipc	a1,0x4
    80004576:	13658593          	addi	a1,a1,310 # 800086a8 <syscalls+0x258>
    8000457a:	0001c517          	auipc	a0,0x1c
    8000457e:	70e50513          	addi	a0,a0,1806 # 80020c88 <ftable>
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	5c4080e7          	jalr	1476(ra) # 80000b46 <initlock>
}
    8000458a:	60a2                	ld	ra,8(sp)
    8000458c:	6402                	ld	s0,0(sp)
    8000458e:	0141                	addi	sp,sp,16
    80004590:	8082                	ret

0000000080004592 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004592:	1101                	addi	sp,sp,-32
    80004594:	ec06                	sd	ra,24(sp)
    80004596:	e822                	sd	s0,16(sp)
    80004598:	e426                	sd	s1,8(sp)
    8000459a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000459c:	0001c517          	auipc	a0,0x1c
    800045a0:	6ec50513          	addi	a0,a0,1772 # 80020c88 <ftable>
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	632080e7          	jalr	1586(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ac:	0001c497          	auipc	s1,0x1c
    800045b0:	6f448493          	addi	s1,s1,1780 # 80020ca0 <ftable+0x18>
    800045b4:	0001d717          	auipc	a4,0x1d
    800045b8:	68c70713          	addi	a4,a4,1676 # 80021c40 <disk>
    if(f->ref == 0){
    800045bc:	40dc                	lw	a5,4(s1)
    800045be:	cf99                	beqz	a5,800045dc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045c0:	02848493          	addi	s1,s1,40
    800045c4:	fee49ce3          	bne	s1,a4,800045bc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045c8:	0001c517          	auipc	a0,0x1c
    800045cc:	6c050513          	addi	a0,a0,1728 # 80020c88 <ftable>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	6ba080e7          	jalr	1722(ra) # 80000c8a <release>
  return 0;
    800045d8:	4481                	li	s1,0
    800045da:	a819                	j	800045f0 <filealloc+0x5e>
      f->ref = 1;
    800045dc:	4785                	li	a5,1
    800045de:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045e0:	0001c517          	auipc	a0,0x1c
    800045e4:	6a850513          	addi	a0,a0,1704 # 80020c88 <ftable>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	6a2080e7          	jalr	1698(ra) # 80000c8a <release>
}
    800045f0:	8526                	mv	a0,s1
    800045f2:	60e2                	ld	ra,24(sp)
    800045f4:	6442                	ld	s0,16(sp)
    800045f6:	64a2                	ld	s1,8(sp)
    800045f8:	6105                	addi	sp,sp,32
    800045fa:	8082                	ret

00000000800045fc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045fc:	1101                	addi	sp,sp,-32
    800045fe:	ec06                	sd	ra,24(sp)
    80004600:	e822                	sd	s0,16(sp)
    80004602:	e426                	sd	s1,8(sp)
    80004604:	1000                	addi	s0,sp,32
    80004606:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004608:	0001c517          	auipc	a0,0x1c
    8000460c:	68050513          	addi	a0,a0,1664 # 80020c88 <ftable>
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	5c6080e7          	jalr	1478(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004618:	40dc                	lw	a5,4(s1)
    8000461a:	02f05263          	blez	a5,8000463e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000461e:	2785                	addiw	a5,a5,1
    80004620:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004622:	0001c517          	auipc	a0,0x1c
    80004626:	66650513          	addi	a0,a0,1638 # 80020c88 <ftable>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	660080e7          	jalr	1632(ra) # 80000c8a <release>
  return f;
}
    80004632:	8526                	mv	a0,s1
    80004634:	60e2                	ld	ra,24(sp)
    80004636:	6442                	ld	s0,16(sp)
    80004638:	64a2                	ld	s1,8(sp)
    8000463a:	6105                	addi	sp,sp,32
    8000463c:	8082                	ret
    panic("filedup");
    8000463e:	00004517          	auipc	a0,0x4
    80004642:	07250513          	addi	a0,a0,114 # 800086b0 <syscalls+0x260>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	ef8080e7          	jalr	-264(ra) # 8000053e <panic>

000000008000464e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000464e:	7139                	addi	sp,sp,-64
    80004650:	fc06                	sd	ra,56(sp)
    80004652:	f822                	sd	s0,48(sp)
    80004654:	f426                	sd	s1,40(sp)
    80004656:	f04a                	sd	s2,32(sp)
    80004658:	ec4e                	sd	s3,24(sp)
    8000465a:	e852                	sd	s4,16(sp)
    8000465c:	e456                	sd	s5,8(sp)
    8000465e:	0080                	addi	s0,sp,64
    80004660:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004662:	0001c517          	auipc	a0,0x1c
    80004666:	62650513          	addi	a0,a0,1574 # 80020c88 <ftable>
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	56c080e7          	jalr	1388(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004672:	40dc                	lw	a5,4(s1)
    80004674:	06f05163          	blez	a5,800046d6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004678:	37fd                	addiw	a5,a5,-1
    8000467a:	0007871b          	sext.w	a4,a5
    8000467e:	c0dc                	sw	a5,4(s1)
    80004680:	06e04363          	bgtz	a4,800046e6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004684:	0004a903          	lw	s2,0(s1)
    80004688:	0094ca83          	lbu	s5,9(s1)
    8000468c:	0104ba03          	ld	s4,16(s1)
    80004690:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004694:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004698:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000469c:	0001c517          	auipc	a0,0x1c
    800046a0:	5ec50513          	addi	a0,a0,1516 # 80020c88 <ftable>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	5e6080e7          	jalr	1510(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046ac:	4785                	li	a5,1
    800046ae:	04f90d63          	beq	s2,a5,80004708 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046b2:	3979                	addiw	s2,s2,-2
    800046b4:	4785                	li	a5,1
    800046b6:	0527e063          	bltu	a5,s2,800046f6 <fileclose+0xa8>
    begin_op();
    800046ba:	00000097          	auipc	ra,0x0
    800046be:	ac8080e7          	jalr	-1336(ra) # 80004182 <begin_op>
    iput(ff.ip);
    800046c2:	854e                	mv	a0,s3
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	2b6080e7          	jalr	694(ra) # 8000397a <iput>
    end_op();
    800046cc:	00000097          	auipc	ra,0x0
    800046d0:	b36080e7          	jalr	-1226(ra) # 80004202 <end_op>
    800046d4:	a00d                	j	800046f6 <fileclose+0xa8>
    panic("fileclose");
    800046d6:	00004517          	auipc	a0,0x4
    800046da:	fe250513          	addi	a0,a0,-30 # 800086b8 <syscalls+0x268>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	e60080e7          	jalr	-416(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046e6:	0001c517          	auipc	a0,0x1c
    800046ea:	5a250513          	addi	a0,a0,1442 # 80020c88 <ftable>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	59c080e7          	jalr	1436(ra) # 80000c8a <release>
  }
}
    800046f6:	70e2                	ld	ra,56(sp)
    800046f8:	7442                	ld	s0,48(sp)
    800046fa:	74a2                	ld	s1,40(sp)
    800046fc:	7902                	ld	s2,32(sp)
    800046fe:	69e2                	ld	s3,24(sp)
    80004700:	6a42                	ld	s4,16(sp)
    80004702:	6aa2                	ld	s5,8(sp)
    80004704:	6121                	addi	sp,sp,64
    80004706:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004708:	85d6                	mv	a1,s5
    8000470a:	8552                	mv	a0,s4
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	34c080e7          	jalr	844(ra) # 80004a58 <pipeclose>
    80004714:	b7cd                	j	800046f6 <fileclose+0xa8>

0000000080004716 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004716:	715d                	addi	sp,sp,-80
    80004718:	e486                	sd	ra,72(sp)
    8000471a:	e0a2                	sd	s0,64(sp)
    8000471c:	fc26                	sd	s1,56(sp)
    8000471e:	f84a                	sd	s2,48(sp)
    80004720:	f44e                	sd	s3,40(sp)
    80004722:	0880                	addi	s0,sp,80
    80004724:	84aa                	mv	s1,a0
    80004726:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004728:	ffffd097          	auipc	ra,0xffffd
    8000472c:	28c080e7          	jalr	652(ra) # 800019b4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004730:	409c                	lw	a5,0(s1)
    80004732:	37f9                	addiw	a5,a5,-2
    80004734:	4705                	li	a4,1
    80004736:	04f76763          	bltu	a4,a5,80004784 <filestat+0x6e>
    8000473a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000473c:	6c88                	ld	a0,24(s1)
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	082080e7          	jalr	130(ra) # 800037c0 <ilock>
    stati(f->ip, &st);
    80004746:	fb840593          	addi	a1,s0,-72
    8000474a:	6c88                	ld	a0,24(s1)
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	2fe080e7          	jalr	766(ra) # 80003a4a <stati>
    iunlock(f->ip);
    80004754:	6c88                	ld	a0,24(s1)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	12c080e7          	jalr	300(ra) # 80003882 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000475e:	46e1                	li	a3,24
    80004760:	fb840613          	addi	a2,s0,-72
    80004764:	85ce                	mv	a1,s3
    80004766:	05093503          	ld	a0,80(s2)
    8000476a:	ffffd097          	auipc	ra,0xffffd
    8000476e:	f06080e7          	jalr	-250(ra) # 80001670 <copyout>
    80004772:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004776:	60a6                	ld	ra,72(sp)
    80004778:	6406                	ld	s0,64(sp)
    8000477a:	74e2                	ld	s1,56(sp)
    8000477c:	7942                	ld	s2,48(sp)
    8000477e:	79a2                	ld	s3,40(sp)
    80004780:	6161                	addi	sp,sp,80
    80004782:	8082                	ret
  return -1;
    80004784:	557d                	li	a0,-1
    80004786:	bfc5                	j	80004776 <filestat+0x60>

0000000080004788 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004788:	7179                	addi	sp,sp,-48
    8000478a:	f406                	sd	ra,40(sp)
    8000478c:	f022                	sd	s0,32(sp)
    8000478e:	ec26                	sd	s1,24(sp)
    80004790:	e84a                	sd	s2,16(sp)
    80004792:	e44e                	sd	s3,8(sp)
    80004794:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004796:	00854783          	lbu	a5,8(a0)
    8000479a:	c3d5                	beqz	a5,8000483e <fileread+0xb6>
    8000479c:	84aa                	mv	s1,a0
    8000479e:	89ae                	mv	s3,a1
    800047a0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047a2:	411c                	lw	a5,0(a0)
    800047a4:	4705                	li	a4,1
    800047a6:	04e78963          	beq	a5,a4,800047f8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047aa:	470d                	li	a4,3
    800047ac:	04e78d63          	beq	a5,a4,80004806 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047b0:	4709                	li	a4,2
    800047b2:	06e79e63          	bne	a5,a4,8000482e <fileread+0xa6>
    ilock(f->ip);
    800047b6:	6d08                	ld	a0,24(a0)
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	008080e7          	jalr	8(ra) # 800037c0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047c0:	874a                	mv	a4,s2
    800047c2:	5094                	lw	a3,32(s1)
    800047c4:	864e                	mv	a2,s3
    800047c6:	4585                	li	a1,1
    800047c8:	6c88                	ld	a0,24(s1)
    800047ca:	fffff097          	auipc	ra,0xfffff
    800047ce:	2aa080e7          	jalr	682(ra) # 80003a74 <readi>
    800047d2:	892a                	mv	s2,a0
    800047d4:	00a05563          	blez	a0,800047de <fileread+0x56>
      f->off += r;
    800047d8:	509c                	lw	a5,32(s1)
    800047da:	9fa9                	addw	a5,a5,a0
    800047dc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047de:	6c88                	ld	a0,24(s1)
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	0a2080e7          	jalr	162(ra) # 80003882 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047e8:	854a                	mv	a0,s2
    800047ea:	70a2                	ld	ra,40(sp)
    800047ec:	7402                	ld	s0,32(sp)
    800047ee:	64e2                	ld	s1,24(sp)
    800047f0:	6942                	ld	s2,16(sp)
    800047f2:	69a2                	ld	s3,8(sp)
    800047f4:	6145                	addi	sp,sp,48
    800047f6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047f8:	6908                	ld	a0,16(a0)
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	3c6080e7          	jalr	966(ra) # 80004bc0 <piperead>
    80004802:	892a                	mv	s2,a0
    80004804:	b7d5                	j	800047e8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004806:	02451783          	lh	a5,36(a0)
    8000480a:	03079693          	slli	a3,a5,0x30
    8000480e:	92c1                	srli	a3,a3,0x30
    80004810:	4725                	li	a4,9
    80004812:	02d76863          	bltu	a4,a3,80004842 <fileread+0xba>
    80004816:	0792                	slli	a5,a5,0x4
    80004818:	0001c717          	auipc	a4,0x1c
    8000481c:	3d070713          	addi	a4,a4,976 # 80020be8 <devsw>
    80004820:	97ba                	add	a5,a5,a4
    80004822:	639c                	ld	a5,0(a5)
    80004824:	c38d                	beqz	a5,80004846 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004826:	4505                	li	a0,1
    80004828:	9782                	jalr	a5
    8000482a:	892a                	mv	s2,a0
    8000482c:	bf75                	j	800047e8 <fileread+0x60>
    panic("fileread");
    8000482e:	00004517          	auipc	a0,0x4
    80004832:	e9a50513          	addi	a0,a0,-358 # 800086c8 <syscalls+0x278>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	d08080e7          	jalr	-760(ra) # 8000053e <panic>
    return -1;
    8000483e:	597d                	li	s2,-1
    80004840:	b765                	j	800047e8 <fileread+0x60>
      return -1;
    80004842:	597d                	li	s2,-1
    80004844:	b755                	j	800047e8 <fileread+0x60>
    80004846:	597d                	li	s2,-1
    80004848:	b745                	j	800047e8 <fileread+0x60>

000000008000484a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000484a:	715d                	addi	sp,sp,-80
    8000484c:	e486                	sd	ra,72(sp)
    8000484e:	e0a2                	sd	s0,64(sp)
    80004850:	fc26                	sd	s1,56(sp)
    80004852:	f84a                	sd	s2,48(sp)
    80004854:	f44e                	sd	s3,40(sp)
    80004856:	f052                	sd	s4,32(sp)
    80004858:	ec56                	sd	s5,24(sp)
    8000485a:	e85a                	sd	s6,16(sp)
    8000485c:	e45e                	sd	s7,8(sp)
    8000485e:	e062                	sd	s8,0(sp)
    80004860:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004862:	00954783          	lbu	a5,9(a0)
    80004866:	10078663          	beqz	a5,80004972 <filewrite+0x128>
    8000486a:	892a                	mv	s2,a0
    8000486c:	8aae                	mv	s5,a1
    8000486e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004870:	411c                	lw	a5,0(a0)
    80004872:	4705                	li	a4,1
    80004874:	02e78263          	beq	a5,a4,80004898 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004878:	470d                	li	a4,3
    8000487a:	02e78663          	beq	a5,a4,800048a6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000487e:	4709                	li	a4,2
    80004880:	0ee79163          	bne	a5,a4,80004962 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004884:	0ac05d63          	blez	a2,8000493e <filewrite+0xf4>
    int i = 0;
    80004888:	4981                	li	s3,0
    8000488a:	6b05                	lui	s6,0x1
    8000488c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004890:	6b85                	lui	s7,0x1
    80004892:	c00b8b9b          	addiw	s7,s7,-1024
    80004896:	a861                	j	8000492e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004898:	6908                	ld	a0,16(a0)
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	22e080e7          	jalr	558(ra) # 80004ac8 <pipewrite>
    800048a2:	8a2a                	mv	s4,a0
    800048a4:	a045                	j	80004944 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048a6:	02451783          	lh	a5,36(a0)
    800048aa:	03079693          	slli	a3,a5,0x30
    800048ae:	92c1                	srli	a3,a3,0x30
    800048b0:	4725                	li	a4,9
    800048b2:	0cd76263          	bltu	a4,a3,80004976 <filewrite+0x12c>
    800048b6:	0792                	slli	a5,a5,0x4
    800048b8:	0001c717          	auipc	a4,0x1c
    800048bc:	33070713          	addi	a4,a4,816 # 80020be8 <devsw>
    800048c0:	97ba                	add	a5,a5,a4
    800048c2:	679c                	ld	a5,8(a5)
    800048c4:	cbdd                	beqz	a5,8000497a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048c6:	4505                	li	a0,1
    800048c8:	9782                	jalr	a5
    800048ca:	8a2a                	mv	s4,a0
    800048cc:	a8a5                	j	80004944 <filewrite+0xfa>
    800048ce:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	8b0080e7          	jalr	-1872(ra) # 80004182 <begin_op>
      ilock(f->ip);
    800048da:	01893503          	ld	a0,24(s2)
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	ee2080e7          	jalr	-286(ra) # 800037c0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048e6:	8762                	mv	a4,s8
    800048e8:	02092683          	lw	a3,32(s2)
    800048ec:	01598633          	add	a2,s3,s5
    800048f0:	4585                	li	a1,1
    800048f2:	01893503          	ld	a0,24(s2)
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	276080e7          	jalr	630(ra) # 80003b6c <writei>
    800048fe:	84aa                	mv	s1,a0
    80004900:	00a05763          	blez	a0,8000490e <filewrite+0xc4>
        f->off += r;
    80004904:	02092783          	lw	a5,32(s2)
    80004908:	9fa9                	addw	a5,a5,a0
    8000490a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000490e:	01893503          	ld	a0,24(s2)
    80004912:	fffff097          	auipc	ra,0xfffff
    80004916:	f70080e7          	jalr	-144(ra) # 80003882 <iunlock>
      end_op();
    8000491a:	00000097          	auipc	ra,0x0
    8000491e:	8e8080e7          	jalr	-1816(ra) # 80004202 <end_op>

      if(r != n1){
    80004922:	009c1f63          	bne	s8,s1,80004940 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004926:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000492a:	0149db63          	bge	s3,s4,80004940 <filewrite+0xf6>
      int n1 = n - i;
    8000492e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004932:	84be                	mv	s1,a5
    80004934:	2781                	sext.w	a5,a5
    80004936:	f8fb5ce3          	bge	s6,a5,800048ce <filewrite+0x84>
    8000493a:	84de                	mv	s1,s7
    8000493c:	bf49                	j	800048ce <filewrite+0x84>
    int i = 0;
    8000493e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004940:	013a1f63          	bne	s4,s3,8000495e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004944:	8552                	mv	a0,s4
    80004946:	60a6                	ld	ra,72(sp)
    80004948:	6406                	ld	s0,64(sp)
    8000494a:	74e2                	ld	s1,56(sp)
    8000494c:	7942                	ld	s2,48(sp)
    8000494e:	79a2                	ld	s3,40(sp)
    80004950:	7a02                	ld	s4,32(sp)
    80004952:	6ae2                	ld	s5,24(sp)
    80004954:	6b42                	ld	s6,16(sp)
    80004956:	6ba2                	ld	s7,8(sp)
    80004958:	6c02                	ld	s8,0(sp)
    8000495a:	6161                	addi	sp,sp,80
    8000495c:	8082                	ret
    ret = (i == n ? n : -1);
    8000495e:	5a7d                	li	s4,-1
    80004960:	b7d5                	j	80004944 <filewrite+0xfa>
    panic("filewrite");
    80004962:	00004517          	auipc	a0,0x4
    80004966:	d7650513          	addi	a0,a0,-650 # 800086d8 <syscalls+0x288>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	bd4080e7          	jalr	-1068(ra) # 8000053e <panic>
    return -1;
    80004972:	5a7d                	li	s4,-1
    80004974:	bfc1                	j	80004944 <filewrite+0xfa>
      return -1;
    80004976:	5a7d                	li	s4,-1
    80004978:	b7f1                	j	80004944 <filewrite+0xfa>
    8000497a:	5a7d                	li	s4,-1
    8000497c:	b7e1                	j	80004944 <filewrite+0xfa>

000000008000497e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000497e:	7179                	addi	sp,sp,-48
    80004980:	f406                	sd	ra,40(sp)
    80004982:	f022                	sd	s0,32(sp)
    80004984:	ec26                	sd	s1,24(sp)
    80004986:	e84a                	sd	s2,16(sp)
    80004988:	e44e                	sd	s3,8(sp)
    8000498a:	e052                	sd	s4,0(sp)
    8000498c:	1800                	addi	s0,sp,48
    8000498e:	84aa                	mv	s1,a0
    80004990:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004992:	0005b023          	sd	zero,0(a1)
    80004996:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000499a:	00000097          	auipc	ra,0x0
    8000499e:	bf8080e7          	jalr	-1032(ra) # 80004592 <filealloc>
    800049a2:	e088                	sd	a0,0(s1)
    800049a4:	c551                	beqz	a0,80004a30 <pipealloc+0xb2>
    800049a6:	00000097          	auipc	ra,0x0
    800049aa:	bec080e7          	jalr	-1044(ra) # 80004592 <filealloc>
    800049ae:	00aa3023          	sd	a0,0(s4)
    800049b2:	c92d                	beqz	a0,80004a24 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	132080e7          	jalr	306(ra) # 80000ae6 <kalloc>
    800049bc:	892a                	mv	s2,a0
    800049be:	c125                	beqz	a0,80004a1e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049c0:	4985                	li	s3,1
    800049c2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049c6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049ca:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049ce:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049d2:	00004597          	auipc	a1,0x4
    800049d6:	d1658593          	addi	a1,a1,-746 # 800086e8 <syscalls+0x298>
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	16c080e7          	jalr	364(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049e2:	609c                	ld	a5,0(s1)
    800049e4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049e8:	609c                	ld	a5,0(s1)
    800049ea:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049ee:	609c                	ld	a5,0(s1)
    800049f0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049f4:	609c                	ld	a5,0(s1)
    800049f6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049fa:	000a3783          	ld	a5,0(s4)
    800049fe:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a02:	000a3783          	ld	a5,0(s4)
    80004a06:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a0a:	000a3783          	ld	a5,0(s4)
    80004a0e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a12:	000a3783          	ld	a5,0(s4)
    80004a16:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a1a:	4501                	li	a0,0
    80004a1c:	a025                	j	80004a44 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a1e:	6088                	ld	a0,0(s1)
    80004a20:	e501                	bnez	a0,80004a28 <pipealloc+0xaa>
    80004a22:	a039                	j	80004a30 <pipealloc+0xb2>
    80004a24:	6088                	ld	a0,0(s1)
    80004a26:	c51d                	beqz	a0,80004a54 <pipealloc+0xd6>
    fileclose(*f0);
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	c26080e7          	jalr	-986(ra) # 8000464e <fileclose>
  if(*f1)
    80004a30:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a34:	557d                	li	a0,-1
  if(*f1)
    80004a36:	c799                	beqz	a5,80004a44 <pipealloc+0xc6>
    fileclose(*f1);
    80004a38:	853e                	mv	a0,a5
    80004a3a:	00000097          	auipc	ra,0x0
    80004a3e:	c14080e7          	jalr	-1004(ra) # 8000464e <fileclose>
  return -1;
    80004a42:	557d                	li	a0,-1
}
    80004a44:	70a2                	ld	ra,40(sp)
    80004a46:	7402                	ld	s0,32(sp)
    80004a48:	64e2                	ld	s1,24(sp)
    80004a4a:	6942                	ld	s2,16(sp)
    80004a4c:	69a2                	ld	s3,8(sp)
    80004a4e:	6a02                	ld	s4,0(sp)
    80004a50:	6145                	addi	sp,sp,48
    80004a52:	8082                	ret
  return -1;
    80004a54:	557d                	li	a0,-1
    80004a56:	b7fd                	j	80004a44 <pipealloc+0xc6>

0000000080004a58 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a58:	1101                	addi	sp,sp,-32
    80004a5a:	ec06                	sd	ra,24(sp)
    80004a5c:	e822                	sd	s0,16(sp)
    80004a5e:	e426                	sd	s1,8(sp)
    80004a60:	e04a                	sd	s2,0(sp)
    80004a62:	1000                	addi	s0,sp,32
    80004a64:	84aa                	mv	s1,a0
    80004a66:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	16e080e7          	jalr	366(ra) # 80000bd6 <acquire>
  if(writable){
    80004a70:	02090d63          	beqz	s2,80004aaa <pipeclose+0x52>
    pi->writeopen = 0;
    80004a74:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a78:	21848513          	addi	a0,s1,536
    80004a7c:	ffffd097          	auipc	ra,0xffffd
    80004a80:	644080e7          	jalr	1604(ra) # 800020c0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a84:	2204b783          	ld	a5,544(s1)
    80004a88:	eb95                	bnez	a5,80004abc <pipeclose+0x64>
    release(&pi->lock);
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	1fe080e7          	jalr	510(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a94:	8526                	mv	a0,s1
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	f54080e7          	jalr	-172(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004a9e:	60e2                	ld	ra,24(sp)
    80004aa0:	6442                	ld	s0,16(sp)
    80004aa2:	64a2                	ld	s1,8(sp)
    80004aa4:	6902                	ld	s2,0(sp)
    80004aa6:	6105                	addi	sp,sp,32
    80004aa8:	8082                	ret
    pi->readopen = 0;
    80004aaa:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aae:	21c48513          	addi	a0,s1,540
    80004ab2:	ffffd097          	auipc	ra,0xffffd
    80004ab6:	60e080e7          	jalr	1550(ra) # 800020c0 <wakeup>
    80004aba:	b7e9                	j	80004a84 <pipeclose+0x2c>
    release(&pi->lock);
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	1cc080e7          	jalr	460(ra) # 80000c8a <release>
}
    80004ac6:	bfe1                	j	80004a9e <pipeclose+0x46>

0000000080004ac8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ac8:	711d                	addi	sp,sp,-96
    80004aca:	ec86                	sd	ra,88(sp)
    80004acc:	e8a2                	sd	s0,80(sp)
    80004ace:	e4a6                	sd	s1,72(sp)
    80004ad0:	e0ca                	sd	s2,64(sp)
    80004ad2:	fc4e                	sd	s3,56(sp)
    80004ad4:	f852                	sd	s4,48(sp)
    80004ad6:	f456                	sd	s5,40(sp)
    80004ad8:	f05a                	sd	s6,32(sp)
    80004ada:	ec5e                	sd	s7,24(sp)
    80004adc:	e862                	sd	s8,16(sp)
    80004ade:	1080                	addi	s0,sp,96
    80004ae0:	84aa                	mv	s1,a0
    80004ae2:	8aae                	mv	s5,a1
    80004ae4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ae6:	ffffd097          	auipc	ra,0xffffd
    80004aea:	ece080e7          	jalr	-306(ra) # 800019b4 <myproc>
    80004aee:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004af0:	8526                	mv	a0,s1
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	0e4080e7          	jalr	228(ra) # 80000bd6 <acquire>
  while(i < n){
    80004afa:	0b405663          	blez	s4,80004ba6 <pipewrite+0xde>
  int i = 0;
    80004afe:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b00:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b02:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b06:	21c48b93          	addi	s7,s1,540
    80004b0a:	a089                	j	80004b4c <pipewrite+0x84>
      release(&pi->lock);
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	17c080e7          	jalr	380(ra) # 80000c8a <release>
      return -1;
    80004b16:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b18:	854a                	mv	a0,s2
    80004b1a:	60e6                	ld	ra,88(sp)
    80004b1c:	6446                	ld	s0,80(sp)
    80004b1e:	64a6                	ld	s1,72(sp)
    80004b20:	6906                	ld	s2,64(sp)
    80004b22:	79e2                	ld	s3,56(sp)
    80004b24:	7a42                	ld	s4,48(sp)
    80004b26:	7aa2                	ld	s5,40(sp)
    80004b28:	7b02                	ld	s6,32(sp)
    80004b2a:	6be2                	ld	s7,24(sp)
    80004b2c:	6c42                	ld	s8,16(sp)
    80004b2e:	6125                	addi	sp,sp,96
    80004b30:	8082                	ret
      wakeup(&pi->nread);
    80004b32:	8562                	mv	a0,s8
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	58c080e7          	jalr	1420(ra) # 800020c0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b3c:	85a6                	mv	a1,s1
    80004b3e:	855e                	mv	a0,s7
    80004b40:	ffffd097          	auipc	ra,0xffffd
    80004b44:	51c080e7          	jalr	1308(ra) # 8000205c <sleep>
  while(i < n){
    80004b48:	07495063          	bge	s2,s4,80004ba8 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b4c:	2204a783          	lw	a5,544(s1)
    80004b50:	dfd5                	beqz	a5,80004b0c <pipewrite+0x44>
    80004b52:	854e                	mv	a0,s3
    80004b54:	ffffd097          	auipc	ra,0xffffd
    80004b58:	7b0080e7          	jalr	1968(ra) # 80002304 <killed>
    80004b5c:	f945                	bnez	a0,80004b0c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b5e:	2184a783          	lw	a5,536(s1)
    80004b62:	21c4a703          	lw	a4,540(s1)
    80004b66:	2007879b          	addiw	a5,a5,512
    80004b6a:	fcf704e3          	beq	a4,a5,80004b32 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b6e:	4685                	li	a3,1
    80004b70:	01590633          	add	a2,s2,s5
    80004b74:	faf40593          	addi	a1,s0,-81
    80004b78:	0509b503          	ld	a0,80(s3)
    80004b7c:	ffffd097          	auipc	ra,0xffffd
    80004b80:	b80080e7          	jalr	-1152(ra) # 800016fc <copyin>
    80004b84:	03650263          	beq	a0,s6,80004ba8 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b88:	21c4a783          	lw	a5,540(s1)
    80004b8c:	0017871b          	addiw	a4,a5,1
    80004b90:	20e4ae23          	sw	a4,540(s1)
    80004b94:	1ff7f793          	andi	a5,a5,511
    80004b98:	97a6                	add	a5,a5,s1
    80004b9a:	faf44703          	lbu	a4,-81(s0)
    80004b9e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ba2:	2905                	addiw	s2,s2,1
    80004ba4:	b755                	j	80004b48 <pipewrite+0x80>
  int i = 0;
    80004ba6:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ba8:	21848513          	addi	a0,s1,536
    80004bac:	ffffd097          	auipc	ra,0xffffd
    80004bb0:	514080e7          	jalr	1300(ra) # 800020c0 <wakeup>
  release(&pi->lock);
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	0d4080e7          	jalr	212(ra) # 80000c8a <release>
  return i;
    80004bbe:	bfa9                	j	80004b18 <pipewrite+0x50>

0000000080004bc0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bc0:	715d                	addi	sp,sp,-80
    80004bc2:	e486                	sd	ra,72(sp)
    80004bc4:	e0a2                	sd	s0,64(sp)
    80004bc6:	fc26                	sd	s1,56(sp)
    80004bc8:	f84a                	sd	s2,48(sp)
    80004bca:	f44e                	sd	s3,40(sp)
    80004bcc:	f052                	sd	s4,32(sp)
    80004bce:	ec56                	sd	s5,24(sp)
    80004bd0:	e85a                	sd	s6,16(sp)
    80004bd2:	0880                	addi	s0,sp,80
    80004bd4:	84aa                	mv	s1,a0
    80004bd6:	892e                	mv	s2,a1
    80004bd8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bda:	ffffd097          	auipc	ra,0xffffd
    80004bde:	dda080e7          	jalr	-550(ra) # 800019b4 <myproc>
    80004be2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004be4:	8526                	mv	a0,s1
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	ff0080e7          	jalr	-16(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bee:	2184a703          	lw	a4,536(s1)
    80004bf2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfa:	02f71763          	bne	a4,a5,80004c28 <piperead+0x68>
    80004bfe:	2244a783          	lw	a5,548(s1)
    80004c02:	c39d                	beqz	a5,80004c28 <piperead+0x68>
    if(killed(pr)){
    80004c04:	8552                	mv	a0,s4
    80004c06:	ffffd097          	auipc	ra,0xffffd
    80004c0a:	6fe080e7          	jalr	1790(ra) # 80002304 <killed>
    80004c0e:	e941                	bnez	a0,80004c9e <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c10:	85a6                	mv	a1,s1
    80004c12:	854e                	mv	a0,s3
    80004c14:	ffffd097          	auipc	ra,0xffffd
    80004c18:	448080e7          	jalr	1096(ra) # 8000205c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c1c:	2184a703          	lw	a4,536(s1)
    80004c20:	21c4a783          	lw	a5,540(s1)
    80004c24:	fcf70de3          	beq	a4,a5,80004bfe <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c28:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c2a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c2c:	05505363          	blez	s5,80004c72 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004c30:	2184a783          	lw	a5,536(s1)
    80004c34:	21c4a703          	lw	a4,540(s1)
    80004c38:	02f70d63          	beq	a4,a5,80004c72 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c3c:	0017871b          	addiw	a4,a5,1
    80004c40:	20e4ac23          	sw	a4,536(s1)
    80004c44:	1ff7f793          	andi	a5,a5,511
    80004c48:	97a6                	add	a5,a5,s1
    80004c4a:	0187c783          	lbu	a5,24(a5)
    80004c4e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c52:	4685                	li	a3,1
    80004c54:	fbf40613          	addi	a2,s0,-65
    80004c58:	85ca                	mv	a1,s2
    80004c5a:	050a3503          	ld	a0,80(s4)
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	a12080e7          	jalr	-1518(ra) # 80001670 <copyout>
    80004c66:	01650663          	beq	a0,s6,80004c72 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6a:	2985                	addiw	s3,s3,1
    80004c6c:	0905                	addi	s2,s2,1
    80004c6e:	fd3a91e3          	bne	s5,s3,80004c30 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c72:	21c48513          	addi	a0,s1,540
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	44a080e7          	jalr	1098(ra) # 800020c0 <wakeup>
  release(&pi->lock);
    80004c7e:	8526                	mv	a0,s1
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	00a080e7          	jalr	10(ra) # 80000c8a <release>
  return i;
}
    80004c88:	854e                	mv	a0,s3
    80004c8a:	60a6                	ld	ra,72(sp)
    80004c8c:	6406                	ld	s0,64(sp)
    80004c8e:	74e2                	ld	s1,56(sp)
    80004c90:	7942                	ld	s2,48(sp)
    80004c92:	79a2                	ld	s3,40(sp)
    80004c94:	7a02                	ld	s4,32(sp)
    80004c96:	6ae2                	ld	s5,24(sp)
    80004c98:	6b42                	ld	s6,16(sp)
    80004c9a:	6161                	addi	sp,sp,80
    80004c9c:	8082                	ret
      release(&pi->lock);
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	fea080e7          	jalr	-22(ra) # 80000c8a <release>
      return -1;
    80004ca8:	59fd                	li	s3,-1
    80004caa:	bff9                	j	80004c88 <piperead+0xc8>

0000000080004cac <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cac:	1141                	addi	sp,sp,-16
    80004cae:	e422                	sd	s0,8(sp)
    80004cb0:	0800                	addi	s0,sp,16
    80004cb2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cb4:	8905                	andi	a0,a0,1
    80004cb6:	c111                	beqz	a0,80004cba <flags2perm+0xe>
      perm = PTE_X;
    80004cb8:	4521                	li	a0,8
    if(flags & 0x2)
    80004cba:	8b89                	andi	a5,a5,2
    80004cbc:	c399                	beqz	a5,80004cc2 <flags2perm+0x16>
      perm |= PTE_W;
    80004cbe:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cc2:	6422                	ld	s0,8(sp)
    80004cc4:	0141                	addi	sp,sp,16
    80004cc6:	8082                	ret

0000000080004cc8 <exec>:

int
exec(char *path, char **argv)
{
    80004cc8:	de010113          	addi	sp,sp,-544
    80004ccc:	20113c23          	sd	ra,536(sp)
    80004cd0:	20813823          	sd	s0,528(sp)
    80004cd4:	20913423          	sd	s1,520(sp)
    80004cd8:	21213023          	sd	s2,512(sp)
    80004cdc:	ffce                	sd	s3,504(sp)
    80004cde:	fbd2                	sd	s4,496(sp)
    80004ce0:	f7d6                	sd	s5,488(sp)
    80004ce2:	f3da                	sd	s6,480(sp)
    80004ce4:	efde                	sd	s7,472(sp)
    80004ce6:	ebe2                	sd	s8,464(sp)
    80004ce8:	e7e6                	sd	s9,456(sp)
    80004cea:	e3ea                	sd	s10,448(sp)
    80004cec:	ff6e                	sd	s11,440(sp)
    80004cee:	1400                	addi	s0,sp,544
    80004cf0:	892a                	mv	s2,a0
    80004cf2:	dea43423          	sd	a0,-536(s0)
    80004cf6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	cba080e7          	jalr	-838(ra) # 800019b4 <myproc>
    80004d02:	84aa                	mv	s1,a0

  begin_op();
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	47e080e7          	jalr	1150(ra) # 80004182 <begin_op>

  if((ip = namei(path)) == 0){
    80004d0c:	854a                	mv	a0,s2
    80004d0e:	fffff097          	auipc	ra,0xfffff
    80004d12:	258080e7          	jalr	600(ra) # 80003f66 <namei>
    80004d16:	c93d                	beqz	a0,80004d8c <exec+0xc4>
    80004d18:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	aa6080e7          	jalr	-1370(ra) # 800037c0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d22:	04000713          	li	a4,64
    80004d26:	4681                	li	a3,0
    80004d28:	e5040613          	addi	a2,s0,-432
    80004d2c:	4581                	li	a1,0
    80004d2e:	8556                	mv	a0,s5
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	d44080e7          	jalr	-700(ra) # 80003a74 <readi>
    80004d38:	04000793          	li	a5,64
    80004d3c:	00f51a63          	bne	a0,a5,80004d50 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d40:	e5042703          	lw	a4,-432(s0)
    80004d44:	464c47b7          	lui	a5,0x464c4
    80004d48:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d4c:	04f70663          	beq	a4,a5,80004d98 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d50:	8556                	mv	a0,s5
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	cd0080e7          	jalr	-816(ra) # 80003a22 <iunlockput>
    end_op();
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	4a8080e7          	jalr	1192(ra) # 80004202 <end_op>
  }
  return -1;
    80004d62:	557d                	li	a0,-1
}
    80004d64:	21813083          	ld	ra,536(sp)
    80004d68:	21013403          	ld	s0,528(sp)
    80004d6c:	20813483          	ld	s1,520(sp)
    80004d70:	20013903          	ld	s2,512(sp)
    80004d74:	79fe                	ld	s3,504(sp)
    80004d76:	7a5e                	ld	s4,496(sp)
    80004d78:	7abe                	ld	s5,488(sp)
    80004d7a:	7b1e                	ld	s6,480(sp)
    80004d7c:	6bfe                	ld	s7,472(sp)
    80004d7e:	6c5e                	ld	s8,464(sp)
    80004d80:	6cbe                	ld	s9,456(sp)
    80004d82:	6d1e                	ld	s10,448(sp)
    80004d84:	7dfa                	ld	s11,440(sp)
    80004d86:	22010113          	addi	sp,sp,544
    80004d8a:	8082                	ret
    end_op();
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	476080e7          	jalr	1142(ra) # 80004202 <end_op>
    return -1;
    80004d94:	557d                	li	a0,-1
    80004d96:	b7f9                	j	80004d64 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	cde080e7          	jalr	-802(ra) # 80001a78 <proc_pagetable>
    80004da2:	8b2a                	mv	s6,a0
    80004da4:	d555                	beqz	a0,80004d50 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da6:	e7042783          	lw	a5,-400(s0)
    80004daa:	e8845703          	lhu	a4,-376(s0)
    80004dae:	c735                	beqz	a4,80004e1a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004db0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004db2:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004db6:	6a05                	lui	s4,0x1
    80004db8:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004dbc:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004dc0:	6d85                	lui	s11,0x1
    80004dc2:	7d7d                	lui	s10,0xfffff
    80004dc4:	a481                	j	80005004 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dc6:	00004517          	auipc	a0,0x4
    80004dca:	92a50513          	addi	a0,a0,-1750 # 800086f0 <syscalls+0x2a0>
    80004dce:	ffffb097          	auipc	ra,0xffffb
    80004dd2:	770080e7          	jalr	1904(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dd6:	874a                	mv	a4,s2
    80004dd8:	009c86bb          	addw	a3,s9,s1
    80004ddc:	4581                	li	a1,0
    80004dde:	8556                	mv	a0,s5
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	c94080e7          	jalr	-876(ra) # 80003a74 <readi>
    80004de8:	2501                	sext.w	a0,a0
    80004dea:	1aa91a63          	bne	s2,a0,80004f9e <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dee:	009d84bb          	addw	s1,s11,s1
    80004df2:	013d09bb          	addw	s3,s10,s3
    80004df6:	1f74f763          	bgeu	s1,s7,80004fe4 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004dfa:	02049593          	slli	a1,s1,0x20
    80004dfe:	9181                	srli	a1,a1,0x20
    80004e00:	95e2                	add	a1,a1,s8
    80004e02:	855a                	mv	a0,s6
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	260080e7          	jalr	608(ra) # 80001064 <walkaddr>
    80004e0c:	862a                	mv	a2,a0
    if(pa == 0)
    80004e0e:	dd45                	beqz	a0,80004dc6 <exec+0xfe>
      n = PGSIZE;
    80004e10:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e12:	fd49f2e3          	bgeu	s3,s4,80004dd6 <exec+0x10e>
      n = sz - i;
    80004e16:	894e                	mv	s2,s3
    80004e18:	bf7d                	j	80004dd6 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e1a:	4901                	li	s2,0
  iunlockput(ip);
    80004e1c:	8556                	mv	a0,s5
    80004e1e:	fffff097          	auipc	ra,0xfffff
    80004e22:	c04080e7          	jalr	-1020(ra) # 80003a22 <iunlockput>
  end_op();
    80004e26:	fffff097          	auipc	ra,0xfffff
    80004e2a:	3dc080e7          	jalr	988(ra) # 80004202 <end_op>
  p = myproc();
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	b86080e7          	jalr	-1146(ra) # 800019b4 <myproc>
    80004e36:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e38:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e3c:	6785                	lui	a5,0x1
    80004e3e:	17fd                	addi	a5,a5,-1
    80004e40:	993e                	add	s2,s2,a5
    80004e42:	77fd                	lui	a5,0xfffff
    80004e44:	00f977b3          	and	a5,s2,a5
    80004e48:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e4c:	4691                	li	a3,4
    80004e4e:	6609                	lui	a2,0x2
    80004e50:	963e                	add	a2,a2,a5
    80004e52:	85be                	mv	a1,a5
    80004e54:	855a                	mv	a0,s6
    80004e56:	ffffc097          	auipc	ra,0xffffc
    80004e5a:	5c2080e7          	jalr	1474(ra) # 80001418 <uvmalloc>
    80004e5e:	8c2a                	mv	s8,a0
  ip = 0;
    80004e60:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e62:	12050e63          	beqz	a0,80004f9e <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e66:	75f9                	lui	a1,0xffffe
    80004e68:	95aa                	add	a1,a1,a0
    80004e6a:	855a                	mv	a0,s6
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	7d2080e7          	jalr	2002(ra) # 8000163e <uvmclear>
  stackbase = sp - PGSIZE;
    80004e74:	7afd                	lui	s5,0xfffff
    80004e76:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e78:	df043783          	ld	a5,-528(s0)
    80004e7c:	6388                	ld	a0,0(a5)
    80004e7e:	c925                	beqz	a0,80004eee <exec+0x226>
    80004e80:	e9040993          	addi	s3,s0,-368
    80004e84:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e88:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e8a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	fc2080e7          	jalr	-62(ra) # 80000e4e <strlen>
    80004e94:	0015079b          	addiw	a5,a0,1
    80004e98:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e9c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ea0:	13596663          	bltu	s2,s5,80004fcc <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ea4:	df043d83          	ld	s11,-528(s0)
    80004ea8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004eac:	8552                	mv	a0,s4
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	fa0080e7          	jalr	-96(ra) # 80000e4e <strlen>
    80004eb6:	0015069b          	addiw	a3,a0,1
    80004eba:	8652                	mv	a2,s4
    80004ebc:	85ca                	mv	a1,s2
    80004ebe:	855a                	mv	a0,s6
    80004ec0:	ffffc097          	auipc	ra,0xffffc
    80004ec4:	7b0080e7          	jalr	1968(ra) # 80001670 <copyout>
    80004ec8:	10054663          	bltz	a0,80004fd4 <exec+0x30c>
    ustack[argc] = sp;
    80004ecc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ed0:	0485                	addi	s1,s1,1
    80004ed2:	008d8793          	addi	a5,s11,8
    80004ed6:	def43823          	sd	a5,-528(s0)
    80004eda:	008db503          	ld	a0,8(s11)
    80004ede:	c911                	beqz	a0,80004ef2 <exec+0x22a>
    if(argc >= MAXARG)
    80004ee0:	09a1                	addi	s3,s3,8
    80004ee2:	fb3c95e3          	bne	s9,s3,80004e8c <exec+0x1c4>
  sz = sz1;
    80004ee6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eea:	4a81                	li	s5,0
    80004eec:	a84d                	j	80004f9e <exec+0x2d6>
  sp = sz;
    80004eee:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ef0:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ef2:	00349793          	slli	a5,s1,0x3
    80004ef6:	f9040713          	addi	a4,s0,-112
    80004efa:	97ba                	add	a5,a5,a4
    80004efc:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdd090>
  sp -= (argc+1) * sizeof(uint64);
    80004f00:	00148693          	addi	a3,s1,1
    80004f04:	068e                	slli	a3,a3,0x3
    80004f06:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f0a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f0e:	01597663          	bgeu	s2,s5,80004f1a <exec+0x252>
  sz = sz1;
    80004f12:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f16:	4a81                	li	s5,0
    80004f18:	a059                	j	80004f9e <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f1a:	e9040613          	addi	a2,s0,-368
    80004f1e:	85ca                	mv	a1,s2
    80004f20:	855a                	mv	a0,s6
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	74e080e7          	jalr	1870(ra) # 80001670 <copyout>
    80004f2a:	0a054963          	bltz	a0,80004fdc <exec+0x314>
  p->trapframe->a1 = sp;
    80004f2e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f32:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f36:	de843783          	ld	a5,-536(s0)
    80004f3a:	0007c703          	lbu	a4,0(a5)
    80004f3e:	cf11                	beqz	a4,80004f5a <exec+0x292>
    80004f40:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f42:	02f00693          	li	a3,47
    80004f46:	a039                	j	80004f54 <exec+0x28c>
      last = s+1;
    80004f48:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f4c:	0785                	addi	a5,a5,1
    80004f4e:	fff7c703          	lbu	a4,-1(a5)
    80004f52:	c701                	beqz	a4,80004f5a <exec+0x292>
    if(*s == '/')
    80004f54:	fed71ce3          	bne	a4,a3,80004f4c <exec+0x284>
    80004f58:	bfc5                	j	80004f48 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f5a:	4641                	li	a2,16
    80004f5c:	de843583          	ld	a1,-536(s0)
    80004f60:	158b8513          	addi	a0,s7,344
    80004f64:	ffffc097          	auipc	ra,0xffffc
    80004f68:	eb8080e7          	jalr	-328(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f6c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f70:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f74:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f78:	058bb783          	ld	a5,88(s7)
    80004f7c:	e6843703          	ld	a4,-408(s0)
    80004f80:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f82:	058bb783          	ld	a5,88(s7)
    80004f86:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f8a:	85ea                	mv	a1,s10
    80004f8c:	ffffd097          	auipc	ra,0xffffd
    80004f90:	b88080e7          	jalr	-1144(ra) # 80001b14 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f94:	0004851b          	sext.w	a0,s1
    80004f98:	b3f1                	j	80004d64 <exec+0x9c>
    80004f9a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f9e:	df843583          	ld	a1,-520(s0)
    80004fa2:	855a                	mv	a0,s6
    80004fa4:	ffffd097          	auipc	ra,0xffffd
    80004fa8:	b70080e7          	jalr	-1168(ra) # 80001b14 <proc_freepagetable>
  if(ip){
    80004fac:	da0a92e3          	bnez	s5,80004d50 <exec+0x88>
  return -1;
    80004fb0:	557d                	li	a0,-1
    80004fb2:	bb4d                	j	80004d64 <exec+0x9c>
    80004fb4:	df243c23          	sd	s2,-520(s0)
    80004fb8:	b7dd                	j	80004f9e <exec+0x2d6>
    80004fba:	df243c23          	sd	s2,-520(s0)
    80004fbe:	b7c5                	j	80004f9e <exec+0x2d6>
    80004fc0:	df243c23          	sd	s2,-520(s0)
    80004fc4:	bfe9                	j	80004f9e <exec+0x2d6>
    80004fc6:	df243c23          	sd	s2,-520(s0)
    80004fca:	bfd1                	j	80004f9e <exec+0x2d6>
  sz = sz1;
    80004fcc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fd0:	4a81                	li	s5,0
    80004fd2:	b7f1                	j	80004f9e <exec+0x2d6>
  sz = sz1;
    80004fd4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fd8:	4a81                	li	s5,0
    80004fda:	b7d1                	j	80004f9e <exec+0x2d6>
  sz = sz1;
    80004fdc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fe0:	4a81                	li	s5,0
    80004fe2:	bf75                	j	80004f9e <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fe4:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fe8:	e0843783          	ld	a5,-504(s0)
    80004fec:	0017869b          	addiw	a3,a5,1
    80004ff0:	e0d43423          	sd	a3,-504(s0)
    80004ff4:	e0043783          	ld	a5,-512(s0)
    80004ff8:	0387879b          	addiw	a5,a5,56
    80004ffc:	e8845703          	lhu	a4,-376(s0)
    80005000:	e0e6dee3          	bge	a3,a4,80004e1c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005004:	2781                	sext.w	a5,a5
    80005006:	e0f43023          	sd	a5,-512(s0)
    8000500a:	03800713          	li	a4,56
    8000500e:	86be                	mv	a3,a5
    80005010:	e1840613          	addi	a2,s0,-488
    80005014:	4581                	li	a1,0
    80005016:	8556                	mv	a0,s5
    80005018:	fffff097          	auipc	ra,0xfffff
    8000501c:	a5c080e7          	jalr	-1444(ra) # 80003a74 <readi>
    80005020:	03800793          	li	a5,56
    80005024:	f6f51be3          	bne	a0,a5,80004f9a <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005028:	e1842783          	lw	a5,-488(s0)
    8000502c:	4705                	li	a4,1
    8000502e:	fae79de3          	bne	a5,a4,80004fe8 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005032:	e4043483          	ld	s1,-448(s0)
    80005036:	e3843783          	ld	a5,-456(s0)
    8000503a:	f6f4ede3          	bltu	s1,a5,80004fb4 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000503e:	e2843783          	ld	a5,-472(s0)
    80005042:	94be                	add	s1,s1,a5
    80005044:	f6f4ebe3          	bltu	s1,a5,80004fba <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005048:	de043703          	ld	a4,-544(s0)
    8000504c:	8ff9                	and	a5,a5,a4
    8000504e:	fbad                	bnez	a5,80004fc0 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005050:	e1c42503          	lw	a0,-484(s0)
    80005054:	00000097          	auipc	ra,0x0
    80005058:	c58080e7          	jalr	-936(ra) # 80004cac <flags2perm>
    8000505c:	86aa                	mv	a3,a0
    8000505e:	8626                	mv	a2,s1
    80005060:	85ca                	mv	a1,s2
    80005062:	855a                	mv	a0,s6
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	3b4080e7          	jalr	948(ra) # 80001418 <uvmalloc>
    8000506c:	dea43c23          	sd	a0,-520(s0)
    80005070:	d939                	beqz	a0,80004fc6 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005072:	e2843c03          	ld	s8,-472(s0)
    80005076:	e2042c83          	lw	s9,-480(s0)
    8000507a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000507e:	f60b83e3          	beqz	s7,80004fe4 <exec+0x31c>
    80005082:	89de                	mv	s3,s7
    80005084:	4481                	li	s1,0
    80005086:	bb95                	j	80004dfa <exec+0x132>

0000000080005088 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005088:	7179                	addi	sp,sp,-48
    8000508a:	f406                	sd	ra,40(sp)
    8000508c:	f022                	sd	s0,32(sp)
    8000508e:	ec26                	sd	s1,24(sp)
    80005090:	e84a                	sd	s2,16(sp)
    80005092:	1800                	addi	s0,sp,48
    80005094:	892e                	mv	s2,a1
    80005096:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005098:	fdc40593          	addi	a1,s0,-36
    8000509c:	ffffe097          	auipc	ra,0xffffe
    800050a0:	a2c080e7          	jalr	-1492(ra) # 80002ac8 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050a4:	fdc42703          	lw	a4,-36(s0)
    800050a8:	47bd                	li	a5,15
    800050aa:	02e7eb63          	bltu	a5,a4,800050e0 <argfd+0x58>
    800050ae:	ffffd097          	auipc	ra,0xffffd
    800050b2:	906080e7          	jalr	-1786(ra) # 800019b4 <myproc>
    800050b6:	fdc42703          	lw	a4,-36(s0)
    800050ba:	01a70793          	addi	a5,a4,26
    800050be:	078e                	slli	a5,a5,0x3
    800050c0:	953e                	add	a0,a0,a5
    800050c2:	611c                	ld	a5,0(a0)
    800050c4:	c385                	beqz	a5,800050e4 <argfd+0x5c>
    return -1;
  if(pfd)
    800050c6:	00090463          	beqz	s2,800050ce <argfd+0x46>
    *pfd = fd;
    800050ca:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050ce:	4501                	li	a0,0
  if(pf)
    800050d0:	c091                	beqz	s1,800050d4 <argfd+0x4c>
    *pf = f;
    800050d2:	e09c                	sd	a5,0(s1)
}
    800050d4:	70a2                	ld	ra,40(sp)
    800050d6:	7402                	ld	s0,32(sp)
    800050d8:	64e2                	ld	s1,24(sp)
    800050da:	6942                	ld	s2,16(sp)
    800050dc:	6145                	addi	sp,sp,48
    800050de:	8082                	ret
    return -1;
    800050e0:	557d                	li	a0,-1
    800050e2:	bfcd                	j	800050d4 <argfd+0x4c>
    800050e4:	557d                	li	a0,-1
    800050e6:	b7fd                	j	800050d4 <argfd+0x4c>

00000000800050e8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050e8:	1101                	addi	sp,sp,-32
    800050ea:	ec06                	sd	ra,24(sp)
    800050ec:	e822                	sd	s0,16(sp)
    800050ee:	e426                	sd	s1,8(sp)
    800050f0:	1000                	addi	s0,sp,32
    800050f2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050f4:	ffffd097          	auipc	ra,0xffffd
    800050f8:	8c0080e7          	jalr	-1856(ra) # 800019b4 <myproc>
    800050fc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050fe:	0d050793          	addi	a5,a0,208
    80005102:	4501                	li	a0,0
    80005104:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005106:	6398                	ld	a4,0(a5)
    80005108:	cb19                	beqz	a4,8000511e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000510a:	2505                	addiw	a0,a0,1
    8000510c:	07a1                	addi	a5,a5,8
    8000510e:	fed51ce3          	bne	a0,a3,80005106 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005112:	557d                	li	a0,-1
}
    80005114:	60e2                	ld	ra,24(sp)
    80005116:	6442                	ld	s0,16(sp)
    80005118:	64a2                	ld	s1,8(sp)
    8000511a:	6105                	addi	sp,sp,32
    8000511c:	8082                	ret
      p->ofile[fd] = f;
    8000511e:	01a50793          	addi	a5,a0,26
    80005122:	078e                	slli	a5,a5,0x3
    80005124:	963e                	add	a2,a2,a5
    80005126:	e204                	sd	s1,0(a2)
      return fd;
    80005128:	b7f5                	j	80005114 <fdalloc+0x2c>

000000008000512a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000512a:	715d                	addi	sp,sp,-80
    8000512c:	e486                	sd	ra,72(sp)
    8000512e:	e0a2                	sd	s0,64(sp)
    80005130:	fc26                	sd	s1,56(sp)
    80005132:	f84a                	sd	s2,48(sp)
    80005134:	f44e                	sd	s3,40(sp)
    80005136:	f052                	sd	s4,32(sp)
    80005138:	ec56                	sd	s5,24(sp)
    8000513a:	e85a                	sd	s6,16(sp)
    8000513c:	0880                	addi	s0,sp,80
    8000513e:	8b2e                	mv	s6,a1
    80005140:	89b2                	mv	s3,a2
    80005142:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005144:	fb040593          	addi	a1,s0,-80
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	e3c080e7          	jalr	-452(ra) # 80003f84 <nameiparent>
    80005150:	84aa                	mv	s1,a0
    80005152:	14050f63          	beqz	a0,800052b0 <create+0x186>
    return 0;

  ilock(dp);
    80005156:	ffffe097          	auipc	ra,0xffffe
    8000515a:	66a080e7          	jalr	1642(ra) # 800037c0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000515e:	4601                	li	a2,0
    80005160:	fb040593          	addi	a1,s0,-80
    80005164:	8526                	mv	a0,s1
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	b3e080e7          	jalr	-1218(ra) # 80003ca4 <dirlookup>
    8000516e:	8aaa                	mv	s5,a0
    80005170:	c931                	beqz	a0,800051c4 <create+0x9a>
    iunlockput(dp);
    80005172:	8526                	mv	a0,s1
    80005174:	fffff097          	auipc	ra,0xfffff
    80005178:	8ae080e7          	jalr	-1874(ra) # 80003a22 <iunlockput>
    ilock(ip);
    8000517c:	8556                	mv	a0,s5
    8000517e:	ffffe097          	auipc	ra,0xffffe
    80005182:	642080e7          	jalr	1602(ra) # 800037c0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005186:	000b059b          	sext.w	a1,s6
    8000518a:	4789                	li	a5,2
    8000518c:	02f59563          	bne	a1,a5,800051b6 <create+0x8c>
    80005190:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd1d4>
    80005194:	37f9                	addiw	a5,a5,-2
    80005196:	17c2                	slli	a5,a5,0x30
    80005198:	93c1                	srli	a5,a5,0x30
    8000519a:	4705                	li	a4,1
    8000519c:	00f76d63          	bltu	a4,a5,800051b6 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800051a0:	8556                	mv	a0,s5
    800051a2:	60a6                	ld	ra,72(sp)
    800051a4:	6406                	ld	s0,64(sp)
    800051a6:	74e2                	ld	s1,56(sp)
    800051a8:	7942                	ld	s2,48(sp)
    800051aa:	79a2                	ld	s3,40(sp)
    800051ac:	7a02                	ld	s4,32(sp)
    800051ae:	6ae2                	ld	s5,24(sp)
    800051b0:	6b42                	ld	s6,16(sp)
    800051b2:	6161                	addi	sp,sp,80
    800051b4:	8082                	ret
    iunlockput(ip);
    800051b6:	8556                	mv	a0,s5
    800051b8:	fffff097          	auipc	ra,0xfffff
    800051bc:	86a080e7          	jalr	-1942(ra) # 80003a22 <iunlockput>
    return 0;
    800051c0:	4a81                	li	s5,0
    800051c2:	bff9                	j	800051a0 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051c4:	85da                	mv	a1,s6
    800051c6:	4088                	lw	a0,0(s1)
    800051c8:	ffffe097          	auipc	ra,0xffffe
    800051cc:	45c080e7          	jalr	1116(ra) # 80003624 <ialloc>
    800051d0:	8a2a                	mv	s4,a0
    800051d2:	c539                	beqz	a0,80005220 <create+0xf6>
  ilock(ip);
    800051d4:	ffffe097          	auipc	ra,0xffffe
    800051d8:	5ec080e7          	jalr	1516(ra) # 800037c0 <ilock>
  ip->major = major;
    800051dc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051e0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051e4:	4905                	li	s2,1
    800051e6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051ea:	8552                	mv	a0,s4
    800051ec:	ffffe097          	auipc	ra,0xffffe
    800051f0:	50a080e7          	jalr	1290(ra) # 800036f6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051f4:	000b059b          	sext.w	a1,s6
    800051f8:	03258b63          	beq	a1,s2,8000522e <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051fc:	004a2603          	lw	a2,4(s4)
    80005200:	fb040593          	addi	a1,s0,-80
    80005204:	8526                	mv	a0,s1
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	cae080e7          	jalr	-850(ra) # 80003eb4 <dirlink>
    8000520e:	06054f63          	bltz	a0,8000528c <create+0x162>
  iunlockput(dp);
    80005212:	8526                	mv	a0,s1
    80005214:	fffff097          	auipc	ra,0xfffff
    80005218:	80e080e7          	jalr	-2034(ra) # 80003a22 <iunlockput>
  return ip;
    8000521c:	8ad2                	mv	s5,s4
    8000521e:	b749                	j	800051a0 <create+0x76>
    iunlockput(dp);
    80005220:	8526                	mv	a0,s1
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	800080e7          	jalr	-2048(ra) # 80003a22 <iunlockput>
    return 0;
    8000522a:	8ad2                	mv	s5,s4
    8000522c:	bf95                	j	800051a0 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000522e:	004a2603          	lw	a2,4(s4)
    80005232:	00003597          	auipc	a1,0x3
    80005236:	4de58593          	addi	a1,a1,1246 # 80008710 <syscalls+0x2c0>
    8000523a:	8552                	mv	a0,s4
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	c78080e7          	jalr	-904(ra) # 80003eb4 <dirlink>
    80005244:	04054463          	bltz	a0,8000528c <create+0x162>
    80005248:	40d0                	lw	a2,4(s1)
    8000524a:	00003597          	auipc	a1,0x3
    8000524e:	4ce58593          	addi	a1,a1,1230 # 80008718 <syscalls+0x2c8>
    80005252:	8552                	mv	a0,s4
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	c60080e7          	jalr	-928(ra) # 80003eb4 <dirlink>
    8000525c:	02054863          	bltz	a0,8000528c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005260:	004a2603          	lw	a2,4(s4)
    80005264:	fb040593          	addi	a1,s0,-80
    80005268:	8526                	mv	a0,s1
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	c4a080e7          	jalr	-950(ra) # 80003eb4 <dirlink>
    80005272:	00054d63          	bltz	a0,8000528c <create+0x162>
    dp->nlink++;  // for ".."
    80005276:	04a4d783          	lhu	a5,74(s1)
    8000527a:	2785                	addiw	a5,a5,1
    8000527c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005280:	8526                	mv	a0,s1
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	474080e7          	jalr	1140(ra) # 800036f6 <iupdate>
    8000528a:	b761                	j	80005212 <create+0xe8>
  ip->nlink = 0;
    8000528c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005290:	8552                	mv	a0,s4
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	464080e7          	jalr	1124(ra) # 800036f6 <iupdate>
  iunlockput(ip);
    8000529a:	8552                	mv	a0,s4
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	786080e7          	jalr	1926(ra) # 80003a22 <iunlockput>
  iunlockput(dp);
    800052a4:	8526                	mv	a0,s1
    800052a6:	ffffe097          	auipc	ra,0xffffe
    800052aa:	77c080e7          	jalr	1916(ra) # 80003a22 <iunlockput>
  return 0;
    800052ae:	bdcd                	j	800051a0 <create+0x76>
    return 0;
    800052b0:	8aaa                	mv	s5,a0
    800052b2:	b5fd                	j	800051a0 <create+0x76>

00000000800052b4 <sys_dup>:
{
    800052b4:	7179                	addi	sp,sp,-48
    800052b6:	f406                	sd	ra,40(sp)
    800052b8:	f022                	sd	s0,32(sp)
    800052ba:	ec26                	sd	s1,24(sp)
    800052bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052be:	fd840613          	addi	a2,s0,-40
    800052c2:	4581                	li	a1,0
    800052c4:	4501                	li	a0,0
    800052c6:	00000097          	auipc	ra,0x0
    800052ca:	dc2080e7          	jalr	-574(ra) # 80005088 <argfd>
    return -1;
    800052ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052d0:	02054363          	bltz	a0,800052f6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052d4:	fd843503          	ld	a0,-40(s0)
    800052d8:	00000097          	auipc	ra,0x0
    800052dc:	e10080e7          	jalr	-496(ra) # 800050e8 <fdalloc>
    800052e0:	84aa                	mv	s1,a0
    return -1;
    800052e2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052e4:	00054963          	bltz	a0,800052f6 <sys_dup+0x42>
  filedup(f);
    800052e8:	fd843503          	ld	a0,-40(s0)
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	310080e7          	jalr	784(ra) # 800045fc <filedup>
  return fd;
    800052f4:	87a6                	mv	a5,s1
}
    800052f6:	853e                	mv	a0,a5
    800052f8:	70a2                	ld	ra,40(sp)
    800052fa:	7402                	ld	s0,32(sp)
    800052fc:	64e2                	ld	s1,24(sp)
    800052fe:	6145                	addi	sp,sp,48
    80005300:	8082                	ret

0000000080005302 <sys_read>:
{
    80005302:	7179                	addi	sp,sp,-48
    80005304:	f406                	sd	ra,40(sp)
    80005306:	f022                	sd	s0,32(sp)
    80005308:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000530a:	fd840593          	addi	a1,s0,-40
    8000530e:	4505                	li	a0,1
    80005310:	ffffd097          	auipc	ra,0xffffd
    80005314:	7d8080e7          	jalr	2008(ra) # 80002ae8 <argaddr>
  argint(2, &n);
    80005318:	fe440593          	addi	a1,s0,-28
    8000531c:	4509                	li	a0,2
    8000531e:	ffffd097          	auipc	ra,0xffffd
    80005322:	7aa080e7          	jalr	1962(ra) # 80002ac8 <argint>
  if(argfd(0, 0, &f) < 0)
    80005326:	fe840613          	addi	a2,s0,-24
    8000532a:	4581                	li	a1,0
    8000532c:	4501                	li	a0,0
    8000532e:	00000097          	auipc	ra,0x0
    80005332:	d5a080e7          	jalr	-678(ra) # 80005088 <argfd>
    80005336:	87aa                	mv	a5,a0
    return -1;
    80005338:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000533a:	0007cc63          	bltz	a5,80005352 <sys_read+0x50>
  return fileread(f, p, n);
    8000533e:	fe442603          	lw	a2,-28(s0)
    80005342:	fd843583          	ld	a1,-40(s0)
    80005346:	fe843503          	ld	a0,-24(s0)
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	43e080e7          	jalr	1086(ra) # 80004788 <fileread>
}
    80005352:	70a2                	ld	ra,40(sp)
    80005354:	7402                	ld	s0,32(sp)
    80005356:	6145                	addi	sp,sp,48
    80005358:	8082                	ret

000000008000535a <sys_write>:
{
    8000535a:	7179                	addi	sp,sp,-48
    8000535c:	f406                	sd	ra,40(sp)
    8000535e:	f022                	sd	s0,32(sp)
    80005360:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005362:	fd840593          	addi	a1,s0,-40
    80005366:	4505                	li	a0,1
    80005368:	ffffd097          	auipc	ra,0xffffd
    8000536c:	780080e7          	jalr	1920(ra) # 80002ae8 <argaddr>
  argint(2, &n);
    80005370:	fe440593          	addi	a1,s0,-28
    80005374:	4509                	li	a0,2
    80005376:	ffffd097          	auipc	ra,0xffffd
    8000537a:	752080e7          	jalr	1874(ra) # 80002ac8 <argint>
  if(argfd(0, 0, &f) < 0)
    8000537e:	fe840613          	addi	a2,s0,-24
    80005382:	4581                	li	a1,0
    80005384:	4501                	li	a0,0
    80005386:	00000097          	auipc	ra,0x0
    8000538a:	d02080e7          	jalr	-766(ra) # 80005088 <argfd>
    8000538e:	87aa                	mv	a5,a0
    return -1;
    80005390:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005392:	0007cc63          	bltz	a5,800053aa <sys_write+0x50>
  return filewrite(f, p, n);
    80005396:	fe442603          	lw	a2,-28(s0)
    8000539a:	fd843583          	ld	a1,-40(s0)
    8000539e:	fe843503          	ld	a0,-24(s0)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	4a8080e7          	jalr	1192(ra) # 8000484a <filewrite>
}
    800053aa:	70a2                	ld	ra,40(sp)
    800053ac:	7402                	ld	s0,32(sp)
    800053ae:	6145                	addi	sp,sp,48
    800053b0:	8082                	ret

00000000800053b2 <sys_close>:
{
    800053b2:	1101                	addi	sp,sp,-32
    800053b4:	ec06                	sd	ra,24(sp)
    800053b6:	e822                	sd	s0,16(sp)
    800053b8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053ba:	fe040613          	addi	a2,s0,-32
    800053be:	fec40593          	addi	a1,s0,-20
    800053c2:	4501                	li	a0,0
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	cc4080e7          	jalr	-828(ra) # 80005088 <argfd>
    return -1;
    800053cc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ce:	02054463          	bltz	a0,800053f6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053d2:	ffffc097          	auipc	ra,0xffffc
    800053d6:	5e2080e7          	jalr	1506(ra) # 800019b4 <myproc>
    800053da:	fec42783          	lw	a5,-20(s0)
    800053de:	07e9                	addi	a5,a5,26
    800053e0:	078e                	slli	a5,a5,0x3
    800053e2:	97aa                	add	a5,a5,a0
    800053e4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053e8:	fe043503          	ld	a0,-32(s0)
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	262080e7          	jalr	610(ra) # 8000464e <fileclose>
  return 0;
    800053f4:	4781                	li	a5,0
}
    800053f6:	853e                	mv	a0,a5
    800053f8:	60e2                	ld	ra,24(sp)
    800053fa:	6442                	ld	s0,16(sp)
    800053fc:	6105                	addi	sp,sp,32
    800053fe:	8082                	ret

0000000080005400 <sys_fstat>:
{
    80005400:	1101                	addi	sp,sp,-32
    80005402:	ec06                	sd	ra,24(sp)
    80005404:	e822                	sd	s0,16(sp)
    80005406:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005408:	fe040593          	addi	a1,s0,-32
    8000540c:	4505                	li	a0,1
    8000540e:	ffffd097          	auipc	ra,0xffffd
    80005412:	6da080e7          	jalr	1754(ra) # 80002ae8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005416:	fe840613          	addi	a2,s0,-24
    8000541a:	4581                	li	a1,0
    8000541c:	4501                	li	a0,0
    8000541e:	00000097          	auipc	ra,0x0
    80005422:	c6a080e7          	jalr	-918(ra) # 80005088 <argfd>
    80005426:	87aa                	mv	a5,a0
    return -1;
    80005428:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000542a:	0007ca63          	bltz	a5,8000543e <sys_fstat+0x3e>
  return filestat(f, st);
    8000542e:	fe043583          	ld	a1,-32(s0)
    80005432:	fe843503          	ld	a0,-24(s0)
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	2e0080e7          	jalr	736(ra) # 80004716 <filestat>
}
    8000543e:	60e2                	ld	ra,24(sp)
    80005440:	6442                	ld	s0,16(sp)
    80005442:	6105                	addi	sp,sp,32
    80005444:	8082                	ret

0000000080005446 <sys_link>:
{
    80005446:	7169                	addi	sp,sp,-304
    80005448:	f606                	sd	ra,296(sp)
    8000544a:	f222                	sd	s0,288(sp)
    8000544c:	ee26                	sd	s1,280(sp)
    8000544e:	ea4a                	sd	s2,272(sp)
    80005450:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005452:	08000613          	li	a2,128
    80005456:	ed040593          	addi	a1,s0,-304
    8000545a:	4501                	li	a0,0
    8000545c:	ffffd097          	auipc	ra,0xffffd
    80005460:	6ac080e7          	jalr	1708(ra) # 80002b08 <argstr>
    return -1;
    80005464:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005466:	10054e63          	bltz	a0,80005582 <sys_link+0x13c>
    8000546a:	08000613          	li	a2,128
    8000546e:	f5040593          	addi	a1,s0,-176
    80005472:	4505                	li	a0,1
    80005474:	ffffd097          	auipc	ra,0xffffd
    80005478:	694080e7          	jalr	1684(ra) # 80002b08 <argstr>
    return -1;
    8000547c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000547e:	10054263          	bltz	a0,80005582 <sys_link+0x13c>
  begin_op();
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	d00080e7          	jalr	-768(ra) # 80004182 <begin_op>
  if((ip = namei(old)) == 0){
    8000548a:	ed040513          	addi	a0,s0,-304
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	ad8080e7          	jalr	-1320(ra) # 80003f66 <namei>
    80005496:	84aa                	mv	s1,a0
    80005498:	c551                	beqz	a0,80005524 <sys_link+0xde>
  ilock(ip);
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	326080e7          	jalr	806(ra) # 800037c0 <ilock>
  if(ip->type == T_DIR){
    800054a2:	04449703          	lh	a4,68(s1)
    800054a6:	4785                	li	a5,1
    800054a8:	08f70463          	beq	a4,a5,80005530 <sys_link+0xea>
  ip->nlink++;
    800054ac:	04a4d783          	lhu	a5,74(s1)
    800054b0:	2785                	addiw	a5,a5,1
    800054b2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054b6:	8526                	mv	a0,s1
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	23e080e7          	jalr	574(ra) # 800036f6 <iupdate>
  iunlock(ip);
    800054c0:	8526                	mv	a0,s1
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	3c0080e7          	jalr	960(ra) # 80003882 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054ca:	fd040593          	addi	a1,s0,-48
    800054ce:	f5040513          	addi	a0,s0,-176
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	ab2080e7          	jalr	-1358(ra) # 80003f84 <nameiparent>
    800054da:	892a                	mv	s2,a0
    800054dc:	c935                	beqz	a0,80005550 <sys_link+0x10a>
  ilock(dp);
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	2e2080e7          	jalr	738(ra) # 800037c0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054e6:	00092703          	lw	a4,0(s2)
    800054ea:	409c                	lw	a5,0(s1)
    800054ec:	04f71d63          	bne	a4,a5,80005546 <sys_link+0x100>
    800054f0:	40d0                	lw	a2,4(s1)
    800054f2:	fd040593          	addi	a1,s0,-48
    800054f6:	854a                	mv	a0,s2
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	9bc080e7          	jalr	-1604(ra) # 80003eb4 <dirlink>
    80005500:	04054363          	bltz	a0,80005546 <sys_link+0x100>
  iunlockput(dp);
    80005504:	854a                	mv	a0,s2
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	51c080e7          	jalr	1308(ra) # 80003a22 <iunlockput>
  iput(ip);
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	46a080e7          	jalr	1130(ra) # 8000397a <iput>
  end_op();
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	cea080e7          	jalr	-790(ra) # 80004202 <end_op>
  return 0;
    80005520:	4781                	li	a5,0
    80005522:	a085                	j	80005582 <sys_link+0x13c>
    end_op();
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	cde080e7          	jalr	-802(ra) # 80004202 <end_op>
    return -1;
    8000552c:	57fd                	li	a5,-1
    8000552e:	a891                	j	80005582 <sys_link+0x13c>
    iunlockput(ip);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	4f0080e7          	jalr	1264(ra) # 80003a22 <iunlockput>
    end_op();
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	cc8080e7          	jalr	-824(ra) # 80004202 <end_op>
    return -1;
    80005542:	57fd                	li	a5,-1
    80005544:	a83d                	j	80005582 <sys_link+0x13c>
    iunlockput(dp);
    80005546:	854a                	mv	a0,s2
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	4da080e7          	jalr	1242(ra) # 80003a22 <iunlockput>
  ilock(ip);
    80005550:	8526                	mv	a0,s1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	26e080e7          	jalr	622(ra) # 800037c0 <ilock>
  ip->nlink--;
    8000555a:	04a4d783          	lhu	a5,74(s1)
    8000555e:	37fd                	addiw	a5,a5,-1
    80005560:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005564:	8526                	mv	a0,s1
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	190080e7          	jalr	400(ra) # 800036f6 <iupdate>
  iunlockput(ip);
    8000556e:	8526                	mv	a0,s1
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	4b2080e7          	jalr	1202(ra) # 80003a22 <iunlockput>
  end_op();
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	c8a080e7          	jalr	-886(ra) # 80004202 <end_op>
  return -1;
    80005580:	57fd                	li	a5,-1
}
    80005582:	853e                	mv	a0,a5
    80005584:	70b2                	ld	ra,296(sp)
    80005586:	7412                	ld	s0,288(sp)
    80005588:	64f2                	ld	s1,280(sp)
    8000558a:	6952                	ld	s2,272(sp)
    8000558c:	6155                	addi	sp,sp,304
    8000558e:	8082                	ret

0000000080005590 <sys_unlink>:
{
    80005590:	7151                	addi	sp,sp,-240
    80005592:	f586                	sd	ra,232(sp)
    80005594:	f1a2                	sd	s0,224(sp)
    80005596:	eda6                	sd	s1,216(sp)
    80005598:	e9ca                	sd	s2,208(sp)
    8000559a:	e5ce                	sd	s3,200(sp)
    8000559c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000559e:	08000613          	li	a2,128
    800055a2:	f3040593          	addi	a1,s0,-208
    800055a6:	4501                	li	a0,0
    800055a8:	ffffd097          	auipc	ra,0xffffd
    800055ac:	560080e7          	jalr	1376(ra) # 80002b08 <argstr>
    800055b0:	18054163          	bltz	a0,80005732 <sys_unlink+0x1a2>
  begin_op();
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	bce080e7          	jalr	-1074(ra) # 80004182 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055bc:	fb040593          	addi	a1,s0,-80
    800055c0:	f3040513          	addi	a0,s0,-208
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	9c0080e7          	jalr	-1600(ra) # 80003f84 <nameiparent>
    800055cc:	84aa                	mv	s1,a0
    800055ce:	c979                	beqz	a0,800056a4 <sys_unlink+0x114>
  ilock(dp);
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	1f0080e7          	jalr	496(ra) # 800037c0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055d8:	00003597          	auipc	a1,0x3
    800055dc:	13858593          	addi	a1,a1,312 # 80008710 <syscalls+0x2c0>
    800055e0:	fb040513          	addi	a0,s0,-80
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	6a6080e7          	jalr	1702(ra) # 80003c8a <namecmp>
    800055ec:	14050a63          	beqz	a0,80005740 <sys_unlink+0x1b0>
    800055f0:	00003597          	auipc	a1,0x3
    800055f4:	12858593          	addi	a1,a1,296 # 80008718 <syscalls+0x2c8>
    800055f8:	fb040513          	addi	a0,s0,-80
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	68e080e7          	jalr	1678(ra) # 80003c8a <namecmp>
    80005604:	12050e63          	beqz	a0,80005740 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005608:	f2c40613          	addi	a2,s0,-212
    8000560c:	fb040593          	addi	a1,s0,-80
    80005610:	8526                	mv	a0,s1
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	692080e7          	jalr	1682(ra) # 80003ca4 <dirlookup>
    8000561a:	892a                	mv	s2,a0
    8000561c:	12050263          	beqz	a0,80005740 <sys_unlink+0x1b0>
  ilock(ip);
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	1a0080e7          	jalr	416(ra) # 800037c0 <ilock>
  if(ip->nlink < 1)
    80005628:	04a91783          	lh	a5,74(s2)
    8000562c:	08f05263          	blez	a5,800056b0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005630:	04491703          	lh	a4,68(s2)
    80005634:	4785                	li	a5,1
    80005636:	08f70563          	beq	a4,a5,800056c0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000563a:	4641                	li	a2,16
    8000563c:	4581                	li	a1,0
    8000563e:	fc040513          	addi	a0,s0,-64
    80005642:	ffffb097          	auipc	ra,0xffffb
    80005646:	690080e7          	jalr	1680(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000564a:	4741                	li	a4,16
    8000564c:	f2c42683          	lw	a3,-212(s0)
    80005650:	fc040613          	addi	a2,s0,-64
    80005654:	4581                	li	a1,0
    80005656:	8526                	mv	a0,s1
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	514080e7          	jalr	1300(ra) # 80003b6c <writei>
    80005660:	47c1                	li	a5,16
    80005662:	0af51563          	bne	a0,a5,8000570c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005666:	04491703          	lh	a4,68(s2)
    8000566a:	4785                	li	a5,1
    8000566c:	0af70863          	beq	a4,a5,8000571c <sys_unlink+0x18c>
  iunlockput(dp);
    80005670:	8526                	mv	a0,s1
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	3b0080e7          	jalr	944(ra) # 80003a22 <iunlockput>
  ip->nlink--;
    8000567a:	04a95783          	lhu	a5,74(s2)
    8000567e:	37fd                	addiw	a5,a5,-1
    80005680:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005684:	854a                	mv	a0,s2
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	070080e7          	jalr	112(ra) # 800036f6 <iupdate>
  iunlockput(ip);
    8000568e:	854a                	mv	a0,s2
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	392080e7          	jalr	914(ra) # 80003a22 <iunlockput>
  end_op();
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	b6a080e7          	jalr	-1174(ra) # 80004202 <end_op>
  return 0;
    800056a0:	4501                	li	a0,0
    800056a2:	a84d                	j	80005754 <sys_unlink+0x1c4>
    end_op();
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	b5e080e7          	jalr	-1186(ra) # 80004202 <end_op>
    return -1;
    800056ac:	557d                	li	a0,-1
    800056ae:	a05d                	j	80005754 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056b0:	00003517          	auipc	a0,0x3
    800056b4:	07050513          	addi	a0,a0,112 # 80008720 <syscalls+0x2d0>
    800056b8:	ffffb097          	auipc	ra,0xffffb
    800056bc:	e86080e7          	jalr	-378(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056c0:	04c92703          	lw	a4,76(s2)
    800056c4:	02000793          	li	a5,32
    800056c8:	f6e7f9e3          	bgeu	a5,a4,8000563a <sys_unlink+0xaa>
    800056cc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056d0:	4741                	li	a4,16
    800056d2:	86ce                	mv	a3,s3
    800056d4:	f1840613          	addi	a2,s0,-232
    800056d8:	4581                	li	a1,0
    800056da:	854a                	mv	a0,s2
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	398080e7          	jalr	920(ra) # 80003a74 <readi>
    800056e4:	47c1                	li	a5,16
    800056e6:	00f51b63          	bne	a0,a5,800056fc <sys_unlink+0x16c>
    if(de.inum != 0)
    800056ea:	f1845783          	lhu	a5,-232(s0)
    800056ee:	e7a1                	bnez	a5,80005736 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056f0:	29c1                	addiw	s3,s3,16
    800056f2:	04c92783          	lw	a5,76(s2)
    800056f6:	fcf9ede3          	bltu	s3,a5,800056d0 <sys_unlink+0x140>
    800056fa:	b781                	j	8000563a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056fc:	00003517          	auipc	a0,0x3
    80005700:	03c50513          	addi	a0,a0,60 # 80008738 <syscalls+0x2e8>
    80005704:	ffffb097          	auipc	ra,0xffffb
    80005708:	e3a080e7          	jalr	-454(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000570c:	00003517          	auipc	a0,0x3
    80005710:	04450513          	addi	a0,a0,68 # 80008750 <syscalls+0x300>
    80005714:	ffffb097          	auipc	ra,0xffffb
    80005718:	e2a080e7          	jalr	-470(ra) # 8000053e <panic>
    dp->nlink--;
    8000571c:	04a4d783          	lhu	a5,74(s1)
    80005720:	37fd                	addiw	a5,a5,-1
    80005722:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005726:	8526                	mv	a0,s1
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	fce080e7          	jalr	-50(ra) # 800036f6 <iupdate>
    80005730:	b781                	j	80005670 <sys_unlink+0xe0>
    return -1;
    80005732:	557d                	li	a0,-1
    80005734:	a005                	j	80005754 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005736:	854a                	mv	a0,s2
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	2ea080e7          	jalr	746(ra) # 80003a22 <iunlockput>
  iunlockput(dp);
    80005740:	8526                	mv	a0,s1
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	2e0080e7          	jalr	736(ra) # 80003a22 <iunlockput>
  end_op();
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	ab8080e7          	jalr	-1352(ra) # 80004202 <end_op>
  return -1;
    80005752:	557d                	li	a0,-1
}
    80005754:	70ae                	ld	ra,232(sp)
    80005756:	740e                	ld	s0,224(sp)
    80005758:	64ee                	ld	s1,216(sp)
    8000575a:	694e                	ld	s2,208(sp)
    8000575c:	69ae                	ld	s3,200(sp)
    8000575e:	616d                	addi	sp,sp,240
    80005760:	8082                	ret

0000000080005762 <sys_open>:

uint64
sys_open(void)
{
    80005762:	7131                	addi	sp,sp,-192
    80005764:	fd06                	sd	ra,184(sp)
    80005766:	f922                	sd	s0,176(sp)
    80005768:	f526                	sd	s1,168(sp)
    8000576a:	f14a                	sd	s2,160(sp)
    8000576c:	ed4e                	sd	s3,152(sp)
    8000576e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005770:	f4c40593          	addi	a1,s0,-180
    80005774:	4505                	li	a0,1
    80005776:	ffffd097          	auipc	ra,0xffffd
    8000577a:	352080e7          	jalr	850(ra) # 80002ac8 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000577e:	08000613          	li	a2,128
    80005782:	f5040593          	addi	a1,s0,-176
    80005786:	4501                	li	a0,0
    80005788:	ffffd097          	auipc	ra,0xffffd
    8000578c:	380080e7          	jalr	896(ra) # 80002b08 <argstr>
    80005790:	87aa                	mv	a5,a0
    return -1;
    80005792:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005794:	0a07c963          	bltz	a5,80005846 <sys_open+0xe4>

  begin_op();
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	9ea080e7          	jalr	-1558(ra) # 80004182 <begin_op>

  if(omode & O_CREATE){
    800057a0:	f4c42783          	lw	a5,-180(s0)
    800057a4:	2007f793          	andi	a5,a5,512
    800057a8:	cfc5                	beqz	a5,80005860 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057aa:	4681                	li	a3,0
    800057ac:	4601                	li	a2,0
    800057ae:	4589                	li	a1,2
    800057b0:	f5040513          	addi	a0,s0,-176
    800057b4:	00000097          	auipc	ra,0x0
    800057b8:	976080e7          	jalr	-1674(ra) # 8000512a <create>
    800057bc:	84aa                	mv	s1,a0
    if(ip == 0){
    800057be:	c959                	beqz	a0,80005854 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057c0:	04449703          	lh	a4,68(s1)
    800057c4:	478d                	li	a5,3
    800057c6:	00f71763          	bne	a4,a5,800057d4 <sys_open+0x72>
    800057ca:	0464d703          	lhu	a4,70(s1)
    800057ce:	47a5                	li	a5,9
    800057d0:	0ce7ed63          	bltu	a5,a4,800058aa <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	dbe080e7          	jalr	-578(ra) # 80004592 <filealloc>
    800057dc:	89aa                	mv	s3,a0
    800057de:	10050363          	beqz	a0,800058e4 <sys_open+0x182>
    800057e2:	00000097          	auipc	ra,0x0
    800057e6:	906080e7          	jalr	-1786(ra) # 800050e8 <fdalloc>
    800057ea:	892a                	mv	s2,a0
    800057ec:	0e054763          	bltz	a0,800058da <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057f0:	04449703          	lh	a4,68(s1)
    800057f4:	478d                	li	a5,3
    800057f6:	0cf70563          	beq	a4,a5,800058c0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057fa:	4789                	li	a5,2
    800057fc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005800:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005804:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005808:	f4c42783          	lw	a5,-180(s0)
    8000580c:	0017c713          	xori	a4,a5,1
    80005810:	8b05                	andi	a4,a4,1
    80005812:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005816:	0037f713          	andi	a4,a5,3
    8000581a:	00e03733          	snez	a4,a4
    8000581e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005822:	4007f793          	andi	a5,a5,1024
    80005826:	c791                	beqz	a5,80005832 <sys_open+0xd0>
    80005828:	04449703          	lh	a4,68(s1)
    8000582c:	4789                	li	a5,2
    8000582e:	0af70063          	beq	a4,a5,800058ce <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	04e080e7          	jalr	78(ra) # 80003882 <iunlock>
  end_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	9c6080e7          	jalr	-1594(ra) # 80004202 <end_op>

  return fd;
    80005844:	854a                	mv	a0,s2
}
    80005846:	70ea                	ld	ra,184(sp)
    80005848:	744a                	ld	s0,176(sp)
    8000584a:	74aa                	ld	s1,168(sp)
    8000584c:	790a                	ld	s2,160(sp)
    8000584e:	69ea                	ld	s3,152(sp)
    80005850:	6129                	addi	sp,sp,192
    80005852:	8082                	ret
      end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	9ae080e7          	jalr	-1618(ra) # 80004202 <end_op>
      return -1;
    8000585c:	557d                	li	a0,-1
    8000585e:	b7e5                	j	80005846 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005860:	f5040513          	addi	a0,s0,-176
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	702080e7          	jalr	1794(ra) # 80003f66 <namei>
    8000586c:	84aa                	mv	s1,a0
    8000586e:	c905                	beqz	a0,8000589e <sys_open+0x13c>
    ilock(ip);
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	f50080e7          	jalr	-176(ra) # 800037c0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005878:	04449703          	lh	a4,68(s1)
    8000587c:	4785                	li	a5,1
    8000587e:	f4f711e3          	bne	a4,a5,800057c0 <sys_open+0x5e>
    80005882:	f4c42783          	lw	a5,-180(s0)
    80005886:	d7b9                	beqz	a5,800057d4 <sys_open+0x72>
      iunlockput(ip);
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	198080e7          	jalr	408(ra) # 80003a22 <iunlockput>
      end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	970080e7          	jalr	-1680(ra) # 80004202 <end_op>
      return -1;
    8000589a:	557d                	li	a0,-1
    8000589c:	b76d                	j	80005846 <sys_open+0xe4>
      end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	964080e7          	jalr	-1692(ra) # 80004202 <end_op>
      return -1;
    800058a6:	557d                	li	a0,-1
    800058a8:	bf79                	j	80005846 <sys_open+0xe4>
    iunlockput(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	176080e7          	jalr	374(ra) # 80003a22 <iunlockput>
    end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	94e080e7          	jalr	-1714(ra) # 80004202 <end_op>
    return -1;
    800058bc:	557d                	li	a0,-1
    800058be:	b761                	j	80005846 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058c0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058c4:	04649783          	lh	a5,70(s1)
    800058c8:	02f99223          	sh	a5,36(s3)
    800058cc:	bf25                	j	80005804 <sys_open+0xa2>
    itrunc(ip);
    800058ce:	8526                	mv	a0,s1
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	ffe080e7          	jalr	-2(ra) # 800038ce <itrunc>
    800058d8:	bfa9                	j	80005832 <sys_open+0xd0>
      fileclose(f);
    800058da:	854e                	mv	a0,s3
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	d72080e7          	jalr	-654(ra) # 8000464e <fileclose>
    iunlockput(ip);
    800058e4:	8526                	mv	a0,s1
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	13c080e7          	jalr	316(ra) # 80003a22 <iunlockput>
    end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	914080e7          	jalr	-1772(ra) # 80004202 <end_op>
    return -1;
    800058f6:	557d                	li	a0,-1
    800058f8:	b7b9                	j	80005846 <sys_open+0xe4>

00000000800058fa <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058fa:	7175                	addi	sp,sp,-144
    800058fc:	e506                	sd	ra,136(sp)
    800058fe:	e122                	sd	s0,128(sp)
    80005900:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	880080e7          	jalr	-1920(ra) # 80004182 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000590a:	08000613          	li	a2,128
    8000590e:	f7040593          	addi	a1,s0,-144
    80005912:	4501                	li	a0,0
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	1f4080e7          	jalr	500(ra) # 80002b08 <argstr>
    8000591c:	02054963          	bltz	a0,8000594e <sys_mkdir+0x54>
    80005920:	4681                	li	a3,0
    80005922:	4601                	li	a2,0
    80005924:	4585                	li	a1,1
    80005926:	f7040513          	addi	a0,s0,-144
    8000592a:	00000097          	auipc	ra,0x0
    8000592e:	800080e7          	jalr	-2048(ra) # 8000512a <create>
    80005932:	cd11                	beqz	a0,8000594e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	0ee080e7          	jalr	238(ra) # 80003a22 <iunlockput>
  end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	8c6080e7          	jalr	-1850(ra) # 80004202 <end_op>
  return 0;
    80005944:	4501                	li	a0,0
}
    80005946:	60aa                	ld	ra,136(sp)
    80005948:	640a                	ld	s0,128(sp)
    8000594a:	6149                	addi	sp,sp,144
    8000594c:	8082                	ret
    end_op();
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	8b4080e7          	jalr	-1868(ra) # 80004202 <end_op>
    return -1;
    80005956:	557d                	li	a0,-1
    80005958:	b7fd                	j	80005946 <sys_mkdir+0x4c>

000000008000595a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000595a:	7135                	addi	sp,sp,-160
    8000595c:	ed06                	sd	ra,152(sp)
    8000595e:	e922                	sd	s0,144(sp)
    80005960:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	820080e7          	jalr	-2016(ra) # 80004182 <begin_op>
  argint(1, &major);
    8000596a:	f6c40593          	addi	a1,s0,-148
    8000596e:	4505                	li	a0,1
    80005970:	ffffd097          	auipc	ra,0xffffd
    80005974:	158080e7          	jalr	344(ra) # 80002ac8 <argint>
  argint(2, &minor);
    80005978:	f6840593          	addi	a1,s0,-152
    8000597c:	4509                	li	a0,2
    8000597e:	ffffd097          	auipc	ra,0xffffd
    80005982:	14a080e7          	jalr	330(ra) # 80002ac8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005986:	08000613          	li	a2,128
    8000598a:	f7040593          	addi	a1,s0,-144
    8000598e:	4501                	li	a0,0
    80005990:	ffffd097          	auipc	ra,0xffffd
    80005994:	178080e7          	jalr	376(ra) # 80002b08 <argstr>
    80005998:	02054b63          	bltz	a0,800059ce <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000599c:	f6841683          	lh	a3,-152(s0)
    800059a0:	f6c41603          	lh	a2,-148(s0)
    800059a4:	458d                	li	a1,3
    800059a6:	f7040513          	addi	a0,s0,-144
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	780080e7          	jalr	1920(ra) # 8000512a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059b2:	cd11                	beqz	a0,800059ce <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	06e080e7          	jalr	110(ra) # 80003a22 <iunlockput>
  end_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	846080e7          	jalr	-1978(ra) # 80004202 <end_op>
  return 0;
    800059c4:	4501                	li	a0,0
}
    800059c6:	60ea                	ld	ra,152(sp)
    800059c8:	644a                	ld	s0,144(sp)
    800059ca:	610d                	addi	sp,sp,160
    800059cc:	8082                	ret
    end_op();
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	834080e7          	jalr	-1996(ra) # 80004202 <end_op>
    return -1;
    800059d6:	557d                	li	a0,-1
    800059d8:	b7fd                	j	800059c6 <sys_mknod+0x6c>

00000000800059da <sys_chdir>:

uint64
sys_chdir(void)
{
    800059da:	7135                	addi	sp,sp,-160
    800059dc:	ed06                	sd	ra,152(sp)
    800059de:	e922                	sd	s0,144(sp)
    800059e0:	e526                	sd	s1,136(sp)
    800059e2:	e14a                	sd	s2,128(sp)
    800059e4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059e6:	ffffc097          	auipc	ra,0xffffc
    800059ea:	fce080e7          	jalr	-50(ra) # 800019b4 <myproc>
    800059ee:	892a                	mv	s2,a0
  
  begin_op();
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	792080e7          	jalr	1938(ra) # 80004182 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059f8:	08000613          	li	a2,128
    800059fc:	f6040593          	addi	a1,s0,-160
    80005a00:	4501                	li	a0,0
    80005a02:	ffffd097          	auipc	ra,0xffffd
    80005a06:	106080e7          	jalr	262(ra) # 80002b08 <argstr>
    80005a0a:	04054b63          	bltz	a0,80005a60 <sys_chdir+0x86>
    80005a0e:	f6040513          	addi	a0,s0,-160
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	554080e7          	jalr	1364(ra) # 80003f66 <namei>
    80005a1a:	84aa                	mv	s1,a0
    80005a1c:	c131                	beqz	a0,80005a60 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	da2080e7          	jalr	-606(ra) # 800037c0 <ilock>
  if(ip->type != T_DIR){
    80005a26:	04449703          	lh	a4,68(s1)
    80005a2a:	4785                	li	a5,1
    80005a2c:	04f71063          	bne	a4,a5,80005a6c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	e50080e7          	jalr	-432(ra) # 80003882 <iunlock>
  iput(p->cwd);
    80005a3a:	15093503          	ld	a0,336(s2)
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	f3c080e7          	jalr	-196(ra) # 8000397a <iput>
  end_op();
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	7bc080e7          	jalr	1980(ra) # 80004202 <end_op>
  p->cwd = ip;
    80005a4e:	14993823          	sd	s1,336(s2)
  return 0;
    80005a52:	4501                	li	a0,0
}
    80005a54:	60ea                	ld	ra,152(sp)
    80005a56:	644a                	ld	s0,144(sp)
    80005a58:	64aa                	ld	s1,136(sp)
    80005a5a:	690a                	ld	s2,128(sp)
    80005a5c:	610d                	addi	sp,sp,160
    80005a5e:	8082                	ret
    end_op();
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	7a2080e7          	jalr	1954(ra) # 80004202 <end_op>
    return -1;
    80005a68:	557d                	li	a0,-1
    80005a6a:	b7ed                	j	80005a54 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a6c:	8526                	mv	a0,s1
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	fb4080e7          	jalr	-76(ra) # 80003a22 <iunlockput>
    end_op();
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	78c080e7          	jalr	1932(ra) # 80004202 <end_op>
    return -1;
    80005a7e:	557d                	li	a0,-1
    80005a80:	bfd1                	j	80005a54 <sys_chdir+0x7a>

0000000080005a82 <sys_exec>:

uint64
sys_exec(void)
{
    80005a82:	7145                	addi	sp,sp,-464
    80005a84:	e786                	sd	ra,456(sp)
    80005a86:	e3a2                	sd	s0,448(sp)
    80005a88:	ff26                	sd	s1,440(sp)
    80005a8a:	fb4a                	sd	s2,432(sp)
    80005a8c:	f74e                	sd	s3,424(sp)
    80005a8e:	f352                	sd	s4,416(sp)
    80005a90:	ef56                	sd	s5,408(sp)
    80005a92:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a94:	e3840593          	addi	a1,s0,-456
    80005a98:	4505                	li	a0,1
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	04e080e7          	jalr	78(ra) # 80002ae8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005aa2:	08000613          	li	a2,128
    80005aa6:	f4040593          	addi	a1,s0,-192
    80005aaa:	4501                	li	a0,0
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	05c080e7          	jalr	92(ra) # 80002b08 <argstr>
    80005ab4:	87aa                	mv	a5,a0
    return -1;
    80005ab6:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ab8:	0c07c263          	bltz	a5,80005b7c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005abc:	10000613          	li	a2,256
    80005ac0:	4581                	li	a1,0
    80005ac2:	e4040513          	addi	a0,s0,-448
    80005ac6:	ffffb097          	auipc	ra,0xffffb
    80005aca:	20c080e7          	jalr	524(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ace:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ad2:	89a6                	mv	s3,s1
    80005ad4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ad6:	02000a13          	li	s4,32
    80005ada:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ade:	00391793          	slli	a5,s2,0x3
    80005ae2:	e3040593          	addi	a1,s0,-464
    80005ae6:	e3843503          	ld	a0,-456(s0)
    80005aea:	953e                	add	a0,a0,a5
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	f3e080e7          	jalr	-194(ra) # 80002a2a <fetchaddr>
    80005af4:	02054a63          	bltz	a0,80005b28 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005af8:	e3043783          	ld	a5,-464(s0)
    80005afc:	c3b9                	beqz	a5,80005b42 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005afe:	ffffb097          	auipc	ra,0xffffb
    80005b02:	fe8080e7          	jalr	-24(ra) # 80000ae6 <kalloc>
    80005b06:	85aa                	mv	a1,a0
    80005b08:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b0c:	cd11                	beqz	a0,80005b28 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b0e:	6605                	lui	a2,0x1
    80005b10:	e3043503          	ld	a0,-464(s0)
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	f68080e7          	jalr	-152(ra) # 80002a7c <fetchstr>
    80005b1c:	00054663          	bltz	a0,80005b28 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b20:	0905                	addi	s2,s2,1
    80005b22:	09a1                	addi	s3,s3,8
    80005b24:	fb491be3          	bne	s2,s4,80005ada <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b28:	10048913          	addi	s2,s1,256
    80005b2c:	6088                	ld	a0,0(s1)
    80005b2e:	c531                	beqz	a0,80005b7a <sys_exec+0xf8>
    kfree(argv[i]);
    80005b30:	ffffb097          	auipc	ra,0xffffb
    80005b34:	eba080e7          	jalr	-326(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b38:	04a1                	addi	s1,s1,8
    80005b3a:	ff2499e3          	bne	s1,s2,80005b2c <sys_exec+0xaa>
  return -1;
    80005b3e:	557d                	li	a0,-1
    80005b40:	a835                	j	80005b7c <sys_exec+0xfa>
      argv[i] = 0;
    80005b42:	0a8e                	slli	s5,s5,0x3
    80005b44:	fc040793          	addi	a5,s0,-64
    80005b48:	9abe                	add	s5,s5,a5
    80005b4a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b4e:	e4040593          	addi	a1,s0,-448
    80005b52:	f4040513          	addi	a0,s0,-192
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	172080e7          	jalr	370(ra) # 80004cc8 <exec>
    80005b5e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b60:	10048993          	addi	s3,s1,256
    80005b64:	6088                	ld	a0,0(s1)
    80005b66:	c901                	beqz	a0,80005b76 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b68:	ffffb097          	auipc	ra,0xffffb
    80005b6c:	e82080e7          	jalr	-382(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b70:	04a1                	addi	s1,s1,8
    80005b72:	ff3499e3          	bne	s1,s3,80005b64 <sys_exec+0xe2>
  return ret;
    80005b76:	854a                	mv	a0,s2
    80005b78:	a011                	j	80005b7c <sys_exec+0xfa>
  return -1;
    80005b7a:	557d                	li	a0,-1
}
    80005b7c:	60be                	ld	ra,456(sp)
    80005b7e:	641e                	ld	s0,448(sp)
    80005b80:	74fa                	ld	s1,440(sp)
    80005b82:	795a                	ld	s2,432(sp)
    80005b84:	79ba                	ld	s3,424(sp)
    80005b86:	7a1a                	ld	s4,416(sp)
    80005b88:	6afa                	ld	s5,408(sp)
    80005b8a:	6179                	addi	sp,sp,464
    80005b8c:	8082                	ret

0000000080005b8e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b8e:	7139                	addi	sp,sp,-64
    80005b90:	fc06                	sd	ra,56(sp)
    80005b92:	f822                	sd	s0,48(sp)
    80005b94:	f426                	sd	s1,40(sp)
    80005b96:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b98:	ffffc097          	auipc	ra,0xffffc
    80005b9c:	e1c080e7          	jalr	-484(ra) # 800019b4 <myproc>
    80005ba0:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ba2:	fd840593          	addi	a1,s0,-40
    80005ba6:	4501                	li	a0,0
    80005ba8:	ffffd097          	auipc	ra,0xffffd
    80005bac:	f40080e7          	jalr	-192(ra) # 80002ae8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005bb0:	fc840593          	addi	a1,s0,-56
    80005bb4:	fd040513          	addi	a0,s0,-48
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	dc6080e7          	jalr	-570(ra) # 8000497e <pipealloc>
    return -1;
    80005bc0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bc2:	0c054463          	bltz	a0,80005c8a <sys_pipe+0xfc>
  fd0 = -1;
    80005bc6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bca:	fd043503          	ld	a0,-48(s0)
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	51a080e7          	jalr	1306(ra) # 800050e8 <fdalloc>
    80005bd6:	fca42223          	sw	a0,-60(s0)
    80005bda:	08054b63          	bltz	a0,80005c70 <sys_pipe+0xe2>
    80005bde:	fc843503          	ld	a0,-56(s0)
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	506080e7          	jalr	1286(ra) # 800050e8 <fdalloc>
    80005bea:	fca42023          	sw	a0,-64(s0)
    80005bee:	06054863          	bltz	a0,80005c5e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf2:	4691                	li	a3,4
    80005bf4:	fc440613          	addi	a2,s0,-60
    80005bf8:	fd843583          	ld	a1,-40(s0)
    80005bfc:	68a8                	ld	a0,80(s1)
    80005bfe:	ffffc097          	auipc	ra,0xffffc
    80005c02:	a72080e7          	jalr	-1422(ra) # 80001670 <copyout>
    80005c06:	02054063          	bltz	a0,80005c26 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c0a:	4691                	li	a3,4
    80005c0c:	fc040613          	addi	a2,s0,-64
    80005c10:	fd843583          	ld	a1,-40(s0)
    80005c14:	0591                	addi	a1,a1,4
    80005c16:	68a8                	ld	a0,80(s1)
    80005c18:	ffffc097          	auipc	ra,0xffffc
    80005c1c:	a58080e7          	jalr	-1448(ra) # 80001670 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c20:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c22:	06055463          	bgez	a0,80005c8a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c26:	fc442783          	lw	a5,-60(s0)
    80005c2a:	07e9                	addi	a5,a5,26
    80005c2c:	078e                	slli	a5,a5,0x3
    80005c2e:	97a6                	add	a5,a5,s1
    80005c30:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c34:	fc042503          	lw	a0,-64(s0)
    80005c38:	0569                	addi	a0,a0,26
    80005c3a:	050e                	slli	a0,a0,0x3
    80005c3c:	94aa                	add	s1,s1,a0
    80005c3e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c42:	fd043503          	ld	a0,-48(s0)
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	a08080e7          	jalr	-1528(ra) # 8000464e <fileclose>
    fileclose(wf);
    80005c4e:	fc843503          	ld	a0,-56(s0)
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	9fc080e7          	jalr	-1540(ra) # 8000464e <fileclose>
    return -1;
    80005c5a:	57fd                	li	a5,-1
    80005c5c:	a03d                	j	80005c8a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c5e:	fc442783          	lw	a5,-60(s0)
    80005c62:	0007c763          	bltz	a5,80005c70 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c66:	07e9                	addi	a5,a5,26
    80005c68:	078e                	slli	a5,a5,0x3
    80005c6a:	94be                	add	s1,s1,a5
    80005c6c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c70:	fd043503          	ld	a0,-48(s0)
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	9da080e7          	jalr	-1574(ra) # 8000464e <fileclose>
    fileclose(wf);
    80005c7c:	fc843503          	ld	a0,-56(s0)
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	9ce080e7          	jalr	-1586(ra) # 8000464e <fileclose>
    return -1;
    80005c88:	57fd                	li	a5,-1
}
    80005c8a:	853e                	mv	a0,a5
    80005c8c:	70e2                	ld	ra,56(sp)
    80005c8e:	7442                	ld	s0,48(sp)
    80005c90:	74a2                	ld	s1,40(sp)
    80005c92:	6121                	addi	sp,sp,64
    80005c94:	8082                	ret
	...

0000000080005ca0 <kernelvec>:
    80005ca0:	7111                	addi	sp,sp,-256
    80005ca2:	e006                	sd	ra,0(sp)
    80005ca4:	e40a                	sd	sp,8(sp)
    80005ca6:	e80e                	sd	gp,16(sp)
    80005ca8:	ec12                	sd	tp,24(sp)
    80005caa:	f016                	sd	t0,32(sp)
    80005cac:	f41a                	sd	t1,40(sp)
    80005cae:	f81e                	sd	t2,48(sp)
    80005cb0:	fc22                	sd	s0,56(sp)
    80005cb2:	e0a6                	sd	s1,64(sp)
    80005cb4:	e4aa                	sd	a0,72(sp)
    80005cb6:	e8ae                	sd	a1,80(sp)
    80005cb8:	ecb2                	sd	a2,88(sp)
    80005cba:	f0b6                	sd	a3,96(sp)
    80005cbc:	f4ba                	sd	a4,104(sp)
    80005cbe:	f8be                	sd	a5,112(sp)
    80005cc0:	fcc2                	sd	a6,120(sp)
    80005cc2:	e146                	sd	a7,128(sp)
    80005cc4:	e54a                	sd	s2,136(sp)
    80005cc6:	e94e                	sd	s3,144(sp)
    80005cc8:	ed52                	sd	s4,152(sp)
    80005cca:	f156                	sd	s5,160(sp)
    80005ccc:	f55a                	sd	s6,168(sp)
    80005cce:	f95e                	sd	s7,176(sp)
    80005cd0:	fd62                	sd	s8,184(sp)
    80005cd2:	e1e6                	sd	s9,192(sp)
    80005cd4:	e5ea                	sd	s10,200(sp)
    80005cd6:	e9ee                	sd	s11,208(sp)
    80005cd8:	edf2                	sd	t3,216(sp)
    80005cda:	f1f6                	sd	t4,224(sp)
    80005cdc:	f5fa                	sd	t5,232(sp)
    80005cde:	f9fe                	sd	t6,240(sp)
    80005ce0:	c17fc0ef          	jal	ra,800028f6 <kerneltrap>
    80005ce4:	6082                	ld	ra,0(sp)
    80005ce6:	6122                	ld	sp,8(sp)
    80005ce8:	61c2                	ld	gp,16(sp)
    80005cea:	7282                	ld	t0,32(sp)
    80005cec:	7322                	ld	t1,40(sp)
    80005cee:	73c2                	ld	t2,48(sp)
    80005cf0:	7462                	ld	s0,56(sp)
    80005cf2:	6486                	ld	s1,64(sp)
    80005cf4:	6526                	ld	a0,72(sp)
    80005cf6:	65c6                	ld	a1,80(sp)
    80005cf8:	6666                	ld	a2,88(sp)
    80005cfa:	7686                	ld	a3,96(sp)
    80005cfc:	7726                	ld	a4,104(sp)
    80005cfe:	77c6                	ld	a5,112(sp)
    80005d00:	7866                	ld	a6,120(sp)
    80005d02:	688a                	ld	a7,128(sp)
    80005d04:	692a                	ld	s2,136(sp)
    80005d06:	69ca                	ld	s3,144(sp)
    80005d08:	6a6a                	ld	s4,152(sp)
    80005d0a:	7a8a                	ld	s5,160(sp)
    80005d0c:	7b2a                	ld	s6,168(sp)
    80005d0e:	7bca                	ld	s7,176(sp)
    80005d10:	7c6a                	ld	s8,184(sp)
    80005d12:	6c8e                	ld	s9,192(sp)
    80005d14:	6d2e                	ld	s10,200(sp)
    80005d16:	6dce                	ld	s11,208(sp)
    80005d18:	6e6e                	ld	t3,216(sp)
    80005d1a:	7e8e                	ld	t4,224(sp)
    80005d1c:	7f2e                	ld	t5,232(sp)
    80005d1e:	7fce                	ld	t6,240(sp)
    80005d20:	6111                	addi	sp,sp,256
    80005d22:	10200073          	sret
    80005d26:	00000013          	nop
    80005d2a:	00000013          	nop
    80005d2e:	0001                	nop

0000000080005d30 <timervec>:
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	e10c                	sd	a1,0(a0)
    80005d36:	e510                	sd	a2,8(a0)
    80005d38:	e914                	sd	a3,16(a0)
    80005d3a:	6d0c                	ld	a1,24(a0)
    80005d3c:	7110                	ld	a2,32(a0)
    80005d3e:	6194                	ld	a3,0(a1)
    80005d40:	96b2                	add	a3,a3,a2
    80005d42:	e194                	sd	a3,0(a1)
    80005d44:	4589                	li	a1,2
    80005d46:	14459073          	csrw	sip,a1
    80005d4a:	6914                	ld	a3,16(a0)
    80005d4c:	6510                	ld	a2,8(a0)
    80005d4e:	610c                	ld	a1,0(a0)
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	30200073          	mret
	...

0000000080005d5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d5a:	1141                	addi	sp,sp,-16
    80005d5c:	e422                	sd	s0,8(sp)
    80005d5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d60:	0c0007b7          	lui	a5,0xc000
    80005d64:	4705                	li	a4,1
    80005d66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d68:	c3d8                	sw	a4,4(a5)
}
    80005d6a:	6422                	ld	s0,8(sp)
    80005d6c:	0141                	addi	sp,sp,16
    80005d6e:	8082                	ret

0000000080005d70 <plicinithart>:

void
plicinithart(void)
{
    80005d70:	1141                	addi	sp,sp,-16
    80005d72:	e406                	sd	ra,8(sp)
    80005d74:	e022                	sd	s0,0(sp)
    80005d76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	c10080e7          	jalr	-1008(ra) # 80001988 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d80:	0085171b          	slliw	a4,a0,0x8
    80005d84:	0c0027b7          	lui	a5,0xc002
    80005d88:	97ba                	add	a5,a5,a4
    80005d8a:	40200713          	li	a4,1026
    80005d8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d92:	00d5151b          	slliw	a0,a0,0xd
    80005d96:	0c2017b7          	lui	a5,0xc201
    80005d9a:	953e                	add	a0,a0,a5
    80005d9c:	00052023          	sw	zero,0(a0)
}
    80005da0:	60a2                	ld	ra,8(sp)
    80005da2:	6402                	ld	s0,0(sp)
    80005da4:	0141                	addi	sp,sp,16
    80005da6:	8082                	ret

0000000080005da8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005da8:	1141                	addi	sp,sp,-16
    80005daa:	e406                	sd	ra,8(sp)
    80005dac:	e022                	sd	s0,0(sp)
    80005dae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005db0:	ffffc097          	auipc	ra,0xffffc
    80005db4:	bd8080e7          	jalr	-1064(ra) # 80001988 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005db8:	00d5179b          	slliw	a5,a0,0xd
    80005dbc:	0c201537          	lui	a0,0xc201
    80005dc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005dc2:	4148                	lw	a0,4(a0)
    80005dc4:	60a2                	ld	ra,8(sp)
    80005dc6:	6402                	ld	s0,0(sp)
    80005dc8:	0141                	addi	sp,sp,16
    80005dca:	8082                	ret

0000000080005dcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dcc:	1101                	addi	sp,sp,-32
    80005dce:	ec06                	sd	ra,24(sp)
    80005dd0:	e822                	sd	s0,16(sp)
    80005dd2:	e426                	sd	s1,8(sp)
    80005dd4:	1000                	addi	s0,sp,32
    80005dd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	bb0080e7          	jalr	-1104(ra) # 80001988 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005de0:	00d5151b          	slliw	a0,a0,0xd
    80005de4:	0c2017b7          	lui	a5,0xc201
    80005de8:	97aa                	add	a5,a5,a0
    80005dea:	c3c4                	sw	s1,4(a5)
}
    80005dec:	60e2                	ld	ra,24(sp)
    80005dee:	6442                	ld	s0,16(sp)
    80005df0:	64a2                	ld	s1,8(sp)
    80005df2:	6105                	addi	sp,sp,32
    80005df4:	8082                	ret

0000000080005df6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005df6:	1141                	addi	sp,sp,-16
    80005df8:	e406                	sd	ra,8(sp)
    80005dfa:	e022                	sd	s0,0(sp)
    80005dfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dfe:	479d                	li	a5,7
    80005e00:	04a7cc63          	blt	a5,a0,80005e58 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e04:	0001c797          	auipc	a5,0x1c
    80005e08:	e3c78793          	addi	a5,a5,-452 # 80021c40 <disk>
    80005e0c:	97aa                	add	a5,a5,a0
    80005e0e:	0187c783          	lbu	a5,24(a5)
    80005e12:	ebb9                	bnez	a5,80005e68 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e14:	00451613          	slli	a2,a0,0x4
    80005e18:	0001c797          	auipc	a5,0x1c
    80005e1c:	e2878793          	addi	a5,a5,-472 # 80021c40 <disk>
    80005e20:	6394                	ld	a3,0(a5)
    80005e22:	96b2                	add	a3,a3,a2
    80005e24:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e28:	6398                	ld	a4,0(a5)
    80005e2a:	9732                	add	a4,a4,a2
    80005e2c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e30:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e34:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e38:	953e                	add	a0,a0,a5
    80005e3a:	4785                	li	a5,1
    80005e3c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e40:	0001c517          	auipc	a0,0x1c
    80005e44:	e1850513          	addi	a0,a0,-488 # 80021c58 <disk+0x18>
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	278080e7          	jalr	632(ra) # 800020c0 <wakeup>
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret
    panic("free_desc 1");
    80005e58:	00003517          	auipc	a0,0x3
    80005e5c:	90850513          	addi	a0,a0,-1784 # 80008760 <syscalls+0x310>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6de080e7          	jalr	1758(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e68:	00003517          	auipc	a0,0x3
    80005e6c:	90850513          	addi	a0,a0,-1784 # 80008770 <syscalls+0x320>
    80005e70:	ffffa097          	auipc	ra,0xffffa
    80005e74:	6ce080e7          	jalr	1742(ra) # 8000053e <panic>

0000000080005e78 <virtio_disk_init>:
{
    80005e78:	1101                	addi	sp,sp,-32
    80005e7a:	ec06                	sd	ra,24(sp)
    80005e7c:	e822                	sd	s0,16(sp)
    80005e7e:	e426                	sd	s1,8(sp)
    80005e80:	e04a                	sd	s2,0(sp)
    80005e82:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e84:	00003597          	auipc	a1,0x3
    80005e88:	8fc58593          	addi	a1,a1,-1796 # 80008780 <syscalls+0x330>
    80005e8c:	0001c517          	auipc	a0,0x1c
    80005e90:	edc50513          	addi	a0,a0,-292 # 80021d68 <disk+0x128>
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	cb2080e7          	jalr	-846(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e9c:	100017b7          	lui	a5,0x10001
    80005ea0:	4398                	lw	a4,0(a5)
    80005ea2:	2701                	sext.w	a4,a4
    80005ea4:	747277b7          	lui	a5,0x74727
    80005ea8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eac:	14f71c63          	bne	a4,a5,80006004 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005eb0:	100017b7          	lui	a5,0x10001
    80005eb4:	43dc                	lw	a5,4(a5)
    80005eb6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eb8:	4709                	li	a4,2
    80005eba:	14e79563          	bne	a5,a4,80006004 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ebe:	100017b7          	lui	a5,0x10001
    80005ec2:	479c                	lw	a5,8(a5)
    80005ec4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ec6:	12e79f63          	bne	a5,a4,80006004 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eca:	100017b7          	lui	a5,0x10001
    80005ece:	47d8                	lw	a4,12(a5)
    80005ed0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ed2:	554d47b7          	lui	a5,0x554d4
    80005ed6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eda:	12f71563          	bne	a4,a5,80006004 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ede:	100017b7          	lui	a5,0x10001
    80005ee2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee6:	4705                	li	a4,1
    80005ee8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eea:	470d                	li	a4,3
    80005eec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ef0:	c7ffe737          	lui	a4,0xc7ffe
    80005ef4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc8ef>
    80005ef8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005efa:	2701                	sext.w	a4,a4
    80005efc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efe:	472d                	li	a4,11
    80005f00:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f02:	5bbc                	lw	a5,112(a5)
    80005f04:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f08:	8ba1                	andi	a5,a5,8
    80005f0a:	10078563          	beqz	a5,80006014 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f0e:	100017b7          	lui	a5,0x10001
    80005f12:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f16:	43fc                	lw	a5,68(a5)
    80005f18:	2781                	sext.w	a5,a5
    80005f1a:	10079563          	bnez	a5,80006024 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f1e:	100017b7          	lui	a5,0x10001
    80005f22:	5bdc                	lw	a5,52(a5)
    80005f24:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f26:	10078763          	beqz	a5,80006034 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005f2a:	471d                	li	a4,7
    80005f2c:	10f77c63          	bgeu	a4,a5,80006044 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005f30:	ffffb097          	auipc	ra,0xffffb
    80005f34:	bb6080e7          	jalr	-1098(ra) # 80000ae6 <kalloc>
    80005f38:	0001c497          	auipc	s1,0x1c
    80005f3c:	d0848493          	addi	s1,s1,-760 # 80021c40 <disk>
    80005f40:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f42:	ffffb097          	auipc	ra,0xffffb
    80005f46:	ba4080e7          	jalr	-1116(ra) # 80000ae6 <kalloc>
    80005f4a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f4c:	ffffb097          	auipc	ra,0xffffb
    80005f50:	b9a080e7          	jalr	-1126(ra) # 80000ae6 <kalloc>
    80005f54:	87aa                	mv	a5,a0
    80005f56:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f58:	6088                	ld	a0,0(s1)
    80005f5a:	cd6d                	beqz	a0,80006054 <virtio_disk_init+0x1dc>
    80005f5c:	0001c717          	auipc	a4,0x1c
    80005f60:	cec73703          	ld	a4,-788(a4) # 80021c48 <disk+0x8>
    80005f64:	cb65                	beqz	a4,80006054 <virtio_disk_init+0x1dc>
    80005f66:	c7fd                	beqz	a5,80006054 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80005f68:	6605                	lui	a2,0x1
    80005f6a:	4581                	li	a1,0
    80005f6c:	ffffb097          	auipc	ra,0xffffb
    80005f70:	d66080e7          	jalr	-666(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f74:	0001c497          	auipc	s1,0x1c
    80005f78:	ccc48493          	addi	s1,s1,-820 # 80021c40 <disk>
    80005f7c:	6605                	lui	a2,0x1
    80005f7e:	4581                	li	a1,0
    80005f80:	6488                	ld	a0,8(s1)
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	d50080e7          	jalr	-688(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f8a:	6605                	lui	a2,0x1
    80005f8c:	4581                	li	a1,0
    80005f8e:	6888                	ld	a0,16(s1)
    80005f90:	ffffb097          	auipc	ra,0xffffb
    80005f94:	d42080e7          	jalr	-702(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f98:	100017b7          	lui	a5,0x10001
    80005f9c:	4721                	li	a4,8
    80005f9e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fa0:	4098                	lw	a4,0(s1)
    80005fa2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005fa6:	40d8                	lw	a4,4(s1)
    80005fa8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005fac:	6498                	ld	a4,8(s1)
    80005fae:	0007069b          	sext.w	a3,a4
    80005fb2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fb6:	9701                	srai	a4,a4,0x20
    80005fb8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fbc:	6898                	ld	a4,16(s1)
    80005fbe:	0007069b          	sext.w	a3,a4
    80005fc2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fc6:	9701                	srai	a4,a4,0x20
    80005fc8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fcc:	4705                	li	a4,1
    80005fce:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005fd0:	00e48c23          	sb	a4,24(s1)
    80005fd4:	00e48ca3          	sb	a4,25(s1)
    80005fd8:	00e48d23          	sb	a4,26(s1)
    80005fdc:	00e48da3          	sb	a4,27(s1)
    80005fe0:	00e48e23          	sb	a4,28(s1)
    80005fe4:	00e48ea3          	sb	a4,29(s1)
    80005fe8:	00e48f23          	sb	a4,30(s1)
    80005fec:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005ff0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff4:	0727a823          	sw	s2,112(a5)
}
    80005ff8:	60e2                	ld	ra,24(sp)
    80005ffa:	6442                	ld	s0,16(sp)
    80005ffc:	64a2                	ld	s1,8(sp)
    80005ffe:	6902                	ld	s2,0(sp)
    80006000:	6105                	addi	sp,sp,32
    80006002:	8082                	ret
    panic("could not find virtio disk");
    80006004:	00002517          	auipc	a0,0x2
    80006008:	78c50513          	addi	a0,a0,1932 # 80008790 <syscalls+0x340>
    8000600c:	ffffa097          	auipc	ra,0xffffa
    80006010:	532080e7          	jalr	1330(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006014:	00002517          	auipc	a0,0x2
    80006018:	79c50513          	addi	a0,a0,1948 # 800087b0 <syscalls+0x360>
    8000601c:	ffffa097          	auipc	ra,0xffffa
    80006020:	522080e7          	jalr	1314(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006024:	00002517          	auipc	a0,0x2
    80006028:	7ac50513          	addi	a0,a0,1964 # 800087d0 <syscalls+0x380>
    8000602c:	ffffa097          	auipc	ra,0xffffa
    80006030:	512080e7          	jalr	1298(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006034:	00002517          	auipc	a0,0x2
    80006038:	7bc50513          	addi	a0,a0,1980 # 800087f0 <syscalls+0x3a0>
    8000603c:	ffffa097          	auipc	ra,0xffffa
    80006040:	502080e7          	jalr	1282(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006044:	00002517          	auipc	a0,0x2
    80006048:	7cc50513          	addi	a0,a0,1996 # 80008810 <syscalls+0x3c0>
    8000604c:	ffffa097          	auipc	ra,0xffffa
    80006050:	4f2080e7          	jalr	1266(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006054:	00002517          	auipc	a0,0x2
    80006058:	7dc50513          	addi	a0,a0,2012 # 80008830 <syscalls+0x3e0>
    8000605c:	ffffa097          	auipc	ra,0xffffa
    80006060:	4e2080e7          	jalr	1250(ra) # 8000053e <panic>

0000000080006064 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006064:	7119                	addi	sp,sp,-128
    80006066:	fc86                	sd	ra,120(sp)
    80006068:	f8a2                	sd	s0,112(sp)
    8000606a:	f4a6                	sd	s1,104(sp)
    8000606c:	f0ca                	sd	s2,96(sp)
    8000606e:	ecce                	sd	s3,88(sp)
    80006070:	e8d2                	sd	s4,80(sp)
    80006072:	e4d6                	sd	s5,72(sp)
    80006074:	e0da                	sd	s6,64(sp)
    80006076:	fc5e                	sd	s7,56(sp)
    80006078:	f862                	sd	s8,48(sp)
    8000607a:	f466                	sd	s9,40(sp)
    8000607c:	f06a                	sd	s10,32(sp)
    8000607e:	ec6e                	sd	s11,24(sp)
    80006080:	0100                	addi	s0,sp,128
    80006082:	8aaa                	mv	s5,a0
    80006084:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006086:	00c52d03          	lw	s10,12(a0)
    8000608a:	001d1d1b          	slliw	s10,s10,0x1
    8000608e:	1d02                	slli	s10,s10,0x20
    80006090:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006094:	0001c517          	auipc	a0,0x1c
    80006098:	cd450513          	addi	a0,a0,-812 # 80021d68 <disk+0x128>
    8000609c:	ffffb097          	auipc	ra,0xffffb
    800060a0:	b3a080e7          	jalr	-1222(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800060a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060a6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800060a8:	0001cb97          	auipc	s7,0x1c
    800060ac:	b98b8b93          	addi	s7,s7,-1128 # 80021c40 <disk>
  for(int i = 0; i < 3; i++){
    800060b0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060b2:	0001cc97          	auipc	s9,0x1c
    800060b6:	cb6c8c93          	addi	s9,s9,-842 # 80021d68 <disk+0x128>
    800060ba:	a08d                	j	8000611c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800060bc:	00fb8733          	add	a4,s7,a5
    800060c0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060c4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060c6:	0207c563          	bltz	a5,800060f0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060ca:	2905                	addiw	s2,s2,1
    800060cc:	0611                	addi	a2,a2,4
    800060ce:	05690c63          	beq	s2,s6,80006126 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060d2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060d4:	0001c717          	auipc	a4,0x1c
    800060d8:	b6c70713          	addi	a4,a4,-1172 # 80021c40 <disk>
    800060dc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060de:	01874683          	lbu	a3,24(a4)
    800060e2:	fee9                	bnez	a3,800060bc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060e4:	2785                	addiw	a5,a5,1
    800060e6:	0705                	addi	a4,a4,1
    800060e8:	fe979be3          	bne	a5,s1,800060de <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060ec:	57fd                	li	a5,-1
    800060ee:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060f0:	01205d63          	blez	s2,8000610a <virtio_disk_rw+0xa6>
    800060f4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060f6:	000a2503          	lw	a0,0(s4)
    800060fa:	00000097          	auipc	ra,0x0
    800060fe:	cfc080e7          	jalr	-772(ra) # 80005df6 <free_desc>
      for(int j = 0; j < i; j++)
    80006102:	2d85                	addiw	s11,s11,1
    80006104:	0a11                	addi	s4,s4,4
    80006106:	ffb918e3          	bne	s2,s11,800060f6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000610a:	85e6                	mv	a1,s9
    8000610c:	0001c517          	auipc	a0,0x1c
    80006110:	b4c50513          	addi	a0,a0,-1204 # 80021c58 <disk+0x18>
    80006114:	ffffc097          	auipc	ra,0xffffc
    80006118:	f48080e7          	jalr	-184(ra) # 8000205c <sleep>
  for(int i = 0; i < 3; i++){
    8000611c:	f8040a13          	addi	s4,s0,-128
{
    80006120:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006122:	894e                	mv	s2,s3
    80006124:	b77d                	j	800060d2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006126:	f8042583          	lw	a1,-128(s0)
    8000612a:	00a58793          	addi	a5,a1,10
    8000612e:	0792                	slli	a5,a5,0x4

  if(write)
    80006130:	0001c617          	auipc	a2,0x1c
    80006134:	b1060613          	addi	a2,a2,-1264 # 80021c40 <disk>
    80006138:	00f60733          	add	a4,a2,a5
    8000613c:	018036b3          	snez	a3,s8
    80006140:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006142:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006146:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000614a:	f6078693          	addi	a3,a5,-160
    8000614e:	6218                	ld	a4,0(a2)
    80006150:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006152:	00878513          	addi	a0,a5,8
    80006156:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006158:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000615a:	6208                	ld	a0,0(a2)
    8000615c:	96aa                	add	a3,a3,a0
    8000615e:	4741                	li	a4,16
    80006160:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006162:	4705                	li	a4,1
    80006164:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006168:	f8442703          	lw	a4,-124(s0)
    8000616c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006170:	0712                	slli	a4,a4,0x4
    80006172:	953a                	add	a0,a0,a4
    80006174:	058a8693          	addi	a3,s5,88
    80006178:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000617a:	6208                	ld	a0,0(a2)
    8000617c:	972a                	add	a4,a4,a0
    8000617e:	40000693          	li	a3,1024
    80006182:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006184:	001c3c13          	seqz	s8,s8
    80006188:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000618a:	001c6c13          	ori	s8,s8,1
    8000618e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006192:	f8842603          	lw	a2,-120(s0)
    80006196:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000619a:	0001c697          	auipc	a3,0x1c
    8000619e:	aa668693          	addi	a3,a3,-1370 # 80021c40 <disk>
    800061a2:	00258713          	addi	a4,a1,2
    800061a6:	0712                	slli	a4,a4,0x4
    800061a8:	9736                	add	a4,a4,a3
    800061aa:	587d                	li	a6,-1
    800061ac:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061b0:	0612                	slli	a2,a2,0x4
    800061b2:	9532                	add	a0,a0,a2
    800061b4:	f9078793          	addi	a5,a5,-112
    800061b8:	97b6                	add	a5,a5,a3
    800061ba:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800061bc:	629c                	ld	a5,0(a3)
    800061be:	97b2                	add	a5,a5,a2
    800061c0:	4605                	li	a2,1
    800061c2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061c4:	4509                	li	a0,2
    800061c6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800061ca:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061ce:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800061d2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061d6:	6698                	ld	a4,8(a3)
    800061d8:	00275783          	lhu	a5,2(a4)
    800061dc:	8b9d                	andi	a5,a5,7
    800061de:	0786                	slli	a5,a5,0x1
    800061e0:	97ba                	add	a5,a5,a4
    800061e2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800061e6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061ea:	6698                	ld	a4,8(a3)
    800061ec:	00275783          	lhu	a5,2(a4)
    800061f0:	2785                	addiw	a5,a5,1
    800061f2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061f6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061fa:	100017b7          	lui	a5,0x10001
    800061fe:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006202:	004aa783          	lw	a5,4(s5)
    80006206:	02c79163          	bne	a5,a2,80006228 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000620a:	0001c917          	auipc	s2,0x1c
    8000620e:	b5e90913          	addi	s2,s2,-1186 # 80021d68 <disk+0x128>
  while(b->disk == 1) {
    80006212:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006214:	85ca                	mv	a1,s2
    80006216:	8556                	mv	a0,s5
    80006218:	ffffc097          	auipc	ra,0xffffc
    8000621c:	e44080e7          	jalr	-444(ra) # 8000205c <sleep>
  while(b->disk == 1) {
    80006220:	004aa783          	lw	a5,4(s5)
    80006224:	fe9788e3          	beq	a5,s1,80006214 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006228:	f8042903          	lw	s2,-128(s0)
    8000622c:	00290793          	addi	a5,s2,2
    80006230:	00479713          	slli	a4,a5,0x4
    80006234:	0001c797          	auipc	a5,0x1c
    80006238:	a0c78793          	addi	a5,a5,-1524 # 80021c40 <disk>
    8000623c:	97ba                	add	a5,a5,a4
    8000623e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006242:	0001c997          	auipc	s3,0x1c
    80006246:	9fe98993          	addi	s3,s3,-1538 # 80021c40 <disk>
    8000624a:	00491713          	slli	a4,s2,0x4
    8000624e:	0009b783          	ld	a5,0(s3)
    80006252:	97ba                	add	a5,a5,a4
    80006254:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006258:	854a                	mv	a0,s2
    8000625a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000625e:	00000097          	auipc	ra,0x0
    80006262:	b98080e7          	jalr	-1128(ra) # 80005df6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006266:	8885                	andi	s1,s1,1
    80006268:	f0ed                	bnez	s1,8000624a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000626a:	0001c517          	auipc	a0,0x1c
    8000626e:	afe50513          	addi	a0,a0,-1282 # 80021d68 <disk+0x128>
    80006272:	ffffb097          	auipc	ra,0xffffb
    80006276:	a18080e7          	jalr	-1512(ra) # 80000c8a <release>
}
    8000627a:	70e6                	ld	ra,120(sp)
    8000627c:	7446                	ld	s0,112(sp)
    8000627e:	74a6                	ld	s1,104(sp)
    80006280:	7906                	ld	s2,96(sp)
    80006282:	69e6                	ld	s3,88(sp)
    80006284:	6a46                	ld	s4,80(sp)
    80006286:	6aa6                	ld	s5,72(sp)
    80006288:	6b06                	ld	s6,64(sp)
    8000628a:	7be2                	ld	s7,56(sp)
    8000628c:	7c42                	ld	s8,48(sp)
    8000628e:	7ca2                	ld	s9,40(sp)
    80006290:	7d02                	ld	s10,32(sp)
    80006292:	6de2                	ld	s11,24(sp)
    80006294:	6109                	addi	sp,sp,128
    80006296:	8082                	ret

0000000080006298 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006298:	1101                	addi	sp,sp,-32
    8000629a:	ec06                	sd	ra,24(sp)
    8000629c:	e822                	sd	s0,16(sp)
    8000629e:	e426                	sd	s1,8(sp)
    800062a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062a2:	0001c497          	auipc	s1,0x1c
    800062a6:	99e48493          	addi	s1,s1,-1634 # 80021c40 <disk>
    800062aa:	0001c517          	auipc	a0,0x1c
    800062ae:	abe50513          	addi	a0,a0,-1346 # 80021d68 <disk+0x128>
    800062b2:	ffffb097          	auipc	ra,0xffffb
    800062b6:	924080e7          	jalr	-1756(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062ba:	10001737          	lui	a4,0x10001
    800062be:	533c                	lw	a5,96(a4)
    800062c0:	8b8d                	andi	a5,a5,3
    800062c2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062c4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062c8:	689c                	ld	a5,16(s1)
    800062ca:	0204d703          	lhu	a4,32(s1)
    800062ce:	0027d783          	lhu	a5,2(a5)
    800062d2:	04f70863          	beq	a4,a5,80006322 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062d6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062da:	6898                	ld	a4,16(s1)
    800062dc:	0204d783          	lhu	a5,32(s1)
    800062e0:	8b9d                	andi	a5,a5,7
    800062e2:	078e                	slli	a5,a5,0x3
    800062e4:	97ba                	add	a5,a5,a4
    800062e6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062e8:	00278713          	addi	a4,a5,2
    800062ec:	0712                	slli	a4,a4,0x4
    800062ee:	9726                	add	a4,a4,s1
    800062f0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062f4:	e721                	bnez	a4,8000633c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062f6:	0789                	addi	a5,a5,2
    800062f8:	0792                	slli	a5,a5,0x4
    800062fa:	97a6                	add	a5,a5,s1
    800062fc:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062fe:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006302:	ffffc097          	auipc	ra,0xffffc
    80006306:	dbe080e7          	jalr	-578(ra) # 800020c0 <wakeup>

    disk.used_idx += 1;
    8000630a:	0204d783          	lhu	a5,32(s1)
    8000630e:	2785                	addiw	a5,a5,1
    80006310:	17c2                	slli	a5,a5,0x30
    80006312:	93c1                	srli	a5,a5,0x30
    80006314:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006318:	6898                	ld	a4,16(s1)
    8000631a:	00275703          	lhu	a4,2(a4)
    8000631e:	faf71ce3          	bne	a4,a5,800062d6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006322:	0001c517          	auipc	a0,0x1c
    80006326:	a4650513          	addi	a0,a0,-1466 # 80021d68 <disk+0x128>
    8000632a:	ffffb097          	auipc	ra,0xffffb
    8000632e:	960080e7          	jalr	-1696(ra) # 80000c8a <release>
}
    80006332:	60e2                	ld	ra,24(sp)
    80006334:	6442                	ld	s0,16(sp)
    80006336:	64a2                	ld	s1,8(sp)
    80006338:	6105                	addi	sp,sp,32
    8000633a:	8082                	ret
      panic("virtio_disk_intr status");
    8000633c:	00002517          	auipc	a0,0x2
    80006340:	50c50513          	addi	a0,a0,1292 # 80008848 <syscalls+0x3f8>
    80006344:	ffffa097          	auipc	ra,0xffffa
    80006348:	1fa080e7          	jalr	506(ra) # 8000053e <panic>

000000008000634c <petersoninit>:
struct petersonlock peterson_locks[MAX_PETERSON_LOCKS];

// אתחול כל המנעולים במערכת
void
petersoninit(void)
{
    8000634c:	1141                	addi	sp,sp,-16
    8000634e:	e422                	sd	s0,8(sp)
    80006350:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PETERSON_LOCKS; i++) {
    80006352:	0001c697          	auipc	a3,0x1c
    80006356:	a2e68693          	addi	a3,a3,-1490 # 80021d80 <peterson_locks>
    8000635a:	4701                	li	a4,0
    peterson_locks[i].active = 0;
    peterson_locks[i].flag[0] = 0;
    8000635c:	85b6                	mv	a1,a3
  for (int i = 0; i < MAX_PETERSON_LOCKS; i++) {
    8000635e:	463d                	li	a2,15
    peterson_locks[i].active = 0;
    80006360:	0006a023          	sw	zero,0(a3)
    peterson_locks[i].flag[0] = 0;
    80006364:	00471793          	slli	a5,a4,0x4
    80006368:	97ae                	add	a5,a5,a1
    8000636a:	0007a223          	sw	zero,4(a5)
    peterson_locks[i].flag[1] = 0;
    8000636e:	0007a423          	sw	zero,8(a5)
    peterson_locks[i].turn = 0;
    80006372:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_PETERSON_LOCKS; i++) {
    80006376:	2705                	addiw	a4,a4,1
    80006378:	06c1                	addi	a3,a3,16
    8000637a:	fec713e3          	bne	a4,a2,80006360 <petersoninit+0x14>
  }
}
    8000637e:	6422                	ld	s0,8(sp)
    80006380:	0141                	addi	sp,sp,16
    80006382:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
