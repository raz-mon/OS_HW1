
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	90013103          	ld	sp,-1792(sp) # 80008900 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000056:	ffe70713          	addi	a4,a4,-2 # 80009050 <timer_scratch>
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
    80000068:	dbc78793          	addi	a5,a5,-580 # 80005e20 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
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
    80000130:	5f2080e7          	jalr	1522(ra) # 8000271e <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
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
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	00450513          	addi	a0,a0,4 # 80011190 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	ff448493          	addi	s1,s1,-12 # 80011190 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	08290913          	addi	s2,s2,130 # 80011228 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	80c080e7          	jalr	-2036(ra) # 800019d0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	e48080e7          	jalr	-440(ra) # 8000201c <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	4b8080e7          	jalr	1208(ra) # 800026c8 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f6c50513          	addi	a0,a0,-148 # 80011190 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f5650513          	addi	a0,a0,-170 # 80011190 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72b23          	sw	a5,-74(a4) # 80011228 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

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
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ec450513          	addi	a0,a0,-316 # 80011190 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f6:	482080e7          	jalr	1154(ra) # 80002774 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e9650513          	addi	a0,a0,-362 # 80011190 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e7270713          	addi	a4,a4,-398 # 80011190 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e4878793          	addi	a5,a5,-440 # 80011190 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	eb27a783          	lw	a5,-334(a5) # 80011228 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e0670713          	addi	a4,a4,-506 # 80011190 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	df648493          	addi	s1,s1,-522 # 80011190 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	dba70713          	addi	a4,a4,-582 # 80011190 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72223          	sw	a5,-444(a4) # 80011230 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d7e78793          	addi	a5,a5,-642 # 80011190 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7ab23          	sw	a2,-522(a5) # 8001122c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dea50513          	addi	a0,a0,-534 # 80011228 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d62080e7          	jalr	-670(ra) # 800021a8 <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d3050513          	addi	a0,a0,-720 # 80011190 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	2b078793          	addi	a5,a5,688 # 80021728 <devsw>
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
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	d007a323          	sw	zero,-762(a5) # 80011250 <pr+0x18>
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
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
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
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c96dad83          	lw	s11,-874(s11) # 80011250 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c4050513          	addi	a0,a0,-960 # 80011238 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
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
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
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
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
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
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	adc50513          	addi	a0,a0,-1316 # 80011238 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ac048493          	addi	s1,s1,-1344 # 80011238 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a8050513          	addi	a0,a0,-1408 # 80011258 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9eea0a13          	addi	s4,s4,-1554 # 80011258 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	908080e7          	jalr	-1784(ra) # 800021a8 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	97c50513          	addi	a0,a0,-1668 # 80011258 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	948a0a13          	addi	s4,s4,-1720 # 80011258 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	6f0080e7          	jalr	1776(ra) # 8000201c <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	91648493          	addi	s1,s1,-1770 # 80011258 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	88e48493          	addi	s1,s1,-1906 # 80011258 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	86490913          	addi	s2,s2,-1948 # 80011290 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7c850513          	addi	a0,a0,1992 # 80011290 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	79248493          	addi	s1,s1,1938 # 80011290 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	77a50513          	addi	a0,a0,1914 # 80011290 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	74e50513          	addi	a0,a0,1870 # 80011290 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e36080e7          	jalr	-458(ra) # 800019b4 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	e04080e7          	jalr	-508(ra) # 800019b4 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	df8080e7          	jalr	-520(ra) # 800019b4 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	de0080e7          	jalr	-544(ra) # 800019b4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	da0080e7          	jalr	-608(ra) # 800019b4 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d74080e7          	jalr	-652(ra) # 800019b4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b0e080e7          	jalr	-1266(ra) # 800019a4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c13d                	beqz	a0,80000f0c <main+0x7e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	af2080e7          	jalr	-1294(ra) # 800019a4 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0f8080e7          	jalr	248(ra) # 80000fc4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	9e0080e7          	jalr	-1568(ra) # 800028b4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f84080e7          	jalr	-124(ra) # 80005e60 <plicinithart>
  }
  printf("hello world\n");
    80000ee4:	00007517          	auipc	a0,0x7
    80000ee8:	1ec50513          	addi	a0,a0,492 # 800080d0 <digits+0x90>
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	69c080e7          	jalr	1692(ra) # 80000588 <printf>
  #endif
  #ifdef RR
  scheduler();
  #endif

  printf("hello world 1\n");
    80000ef4:	00007517          	auipc	a0,0x7
    80000ef8:	1ec50513          	addi	a0,a0,492 # 800080e0 <digits+0xa0>
    80000efc:	fffff097          	auipc	ra,0xfffff
    80000f00:	68c080e7          	jalr	1676(ra) # 80000588 <printf>
}
    80000f04:	60a2                	ld	ra,8(sp)
    80000f06:	6402                	ld	s0,0(sp)
    80000f08:	0141                	addi	sp,sp,16
    80000f0a:	8082                	ret
    consoleinit();
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	544080e7          	jalr	1348(ra) # 80000450 <consoleinit>
    printfinit();
    80000f14:	00000097          	auipc	ra,0x0
    80000f18:	85a080e7          	jalr	-1958(ra) # 8000076e <printfinit>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	17450513          	addi	a0,a0,372 # 800080a0 <digits+0x60>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	654080e7          	jalr	1620(ra) # 80000588 <printf>
    printf("\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	18c50513          	addi	a0,a0,396 # 800080c8 <digits+0x88>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	644080e7          	jalr	1604(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f4c:	00000097          	auipc	ra,0x0
    80000f50:	b6c080e7          	jalr	-1172(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f54:	00000097          	auipc	ra,0x0
    80000f58:	322080e7          	jalr	802(ra) # 80001276 <kvminit>
    kvminithart();   // turn on paging
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	068080e7          	jalr	104(ra) # 80000fc4 <kvminithart>
    procinit();      // process table
    80000f64:	00001097          	auipc	ra,0x1
    80000f68:	990080e7          	jalr	-1648(ra) # 800018f4 <procinit>
    trapinit();      // trap vectors
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	920080e7          	jalr	-1760(ra) # 8000288c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	940080e7          	jalr	-1728(ra) # 800028b4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f7c:	00005097          	auipc	ra,0x5
    80000f80:	ece080e7          	jalr	-306(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	edc080e7          	jalr	-292(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	0b4080e7          	jalr	180(ra) # 80003040 <binit>
    iinit();         // inode table
    80000f94:	00002097          	auipc	ra,0x2
    80000f98:	744080e7          	jalr	1860(ra) # 800036d8 <iinit>
    fileinit();      // file table
    80000f9c:	00003097          	auipc	ra,0x3
    80000fa0:	6ee080e7          	jalr	1774(ra) # 8000468a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa4:	00005097          	auipc	ra,0x5
    80000fa8:	fde080e7          	jalr	-34(ra) # 80005f82 <virtio_disk_init>
    userinit();      // first user process
    80000fac:	00001097          	auipc	ra,0x1
    80000fb0:	d0c080e7          	jalr	-756(ra) # 80001cb8 <userinit>
    __sync_synchronize();
    80000fb4:	0ff0000f          	fence
    started = 1;
    80000fb8:	4785                	li	a5,1
    80000fba:	00008717          	auipc	a4,0x8
    80000fbe:	04f72f23          	sw	a5,94(a4) # 80009018 <started>
    80000fc2:	b70d                	j	80000ee4 <main+0x56>

0000000080000fc4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc4:	1141                	addi	sp,sp,-16
    80000fc6:	e422                	sd	s0,8(sp)
    80000fc8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fca:	00008797          	auipc	a5,0x8
    80000fce:	0567b783          	ld	a5,86(a5) # 80009020 <kernel_pagetable>
    80000fd2:	83b1                	srli	a5,a5,0xc
    80000fd4:	577d                	li	a4,-1
    80000fd6:	177e                	slli	a4,a4,0x3f
    80000fd8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fda:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fde:	12000073          	sfence.vma
  sfence_vma();
}
    80000fe2:	6422                	ld	s0,8(sp)
    80000fe4:	0141                	addi	sp,sp,16
    80000fe6:	8082                	ret

0000000080000fe8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fe8:	7139                	addi	sp,sp,-64
    80000fea:	fc06                	sd	ra,56(sp)
    80000fec:	f822                	sd	s0,48(sp)
    80000fee:	f426                	sd	s1,40(sp)
    80000ff0:	f04a                	sd	s2,32(sp)
    80000ff2:	ec4e                	sd	s3,24(sp)
    80000ff4:	e852                	sd	s4,16(sp)
    80000ff6:	e456                	sd	s5,8(sp)
    80000ff8:	e05a                	sd	s6,0(sp)
    80000ffa:	0080                	addi	s0,sp,64
    80000ffc:	84aa                	mv	s1,a0
    80000ffe:	89ae                	mv	s3,a1
    80001000:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001002:	57fd                	li	a5,-1
    80001004:	83e9                	srli	a5,a5,0x1a
    80001006:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001008:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000100a:	04b7f263          	bgeu	a5,a1,8000104e <walk+0x66>
    panic("walk");
    8000100e:	00007517          	auipc	a0,0x7
    80001012:	0e250513          	addi	a0,a0,226 # 800080f0 <digits+0xb0>
    80001016:	fffff097          	auipc	ra,0xfffff
    8000101a:	528080e7          	jalr	1320(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000101e:	060a8663          	beqz	s5,8000108a <walk+0xa2>
    80001022:	00000097          	auipc	ra,0x0
    80001026:	ad2080e7          	jalr	-1326(ra) # 80000af4 <kalloc>
    8000102a:	84aa                	mv	s1,a0
    8000102c:	c529                	beqz	a0,80001076 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000102e:	6605                	lui	a2,0x1
    80001030:	4581                	li	a1,0
    80001032:	00000097          	auipc	ra,0x0
    80001036:	cae080e7          	jalr	-850(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000103a:	00c4d793          	srli	a5,s1,0xc
    8000103e:	07aa                	slli	a5,a5,0xa
    80001040:	0017e793          	ori	a5,a5,1
    80001044:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001048:	3a5d                	addiw	s4,s4,-9
    8000104a:	036a0063          	beq	s4,s6,8000106a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000104e:	0149d933          	srl	s2,s3,s4
    80001052:	1ff97913          	andi	s2,s2,511
    80001056:	090e                	slli	s2,s2,0x3
    80001058:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000105a:	00093483          	ld	s1,0(s2)
    8000105e:	0014f793          	andi	a5,s1,1
    80001062:	dfd5                	beqz	a5,8000101e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001064:	80a9                	srli	s1,s1,0xa
    80001066:	04b2                	slli	s1,s1,0xc
    80001068:	b7c5                	j	80001048 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000106a:	00c9d513          	srli	a0,s3,0xc
    8000106e:	1ff57513          	andi	a0,a0,511
    80001072:	050e                	slli	a0,a0,0x3
    80001074:	9526                	add	a0,a0,s1
}
    80001076:	70e2                	ld	ra,56(sp)
    80001078:	7442                	ld	s0,48(sp)
    8000107a:	74a2                	ld	s1,40(sp)
    8000107c:	7902                	ld	s2,32(sp)
    8000107e:	69e2                	ld	s3,24(sp)
    80001080:	6a42                	ld	s4,16(sp)
    80001082:	6aa2                	ld	s5,8(sp)
    80001084:	6b02                	ld	s6,0(sp)
    80001086:	6121                	addi	sp,sp,64
    80001088:	8082                	ret
        return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7ed                	j	80001076 <walk+0x8e>

000000008000108e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000108e:	57fd                	li	a5,-1
    80001090:	83e9                	srli	a5,a5,0x1a
    80001092:	00b7f463          	bgeu	a5,a1,8000109a <walkaddr+0xc>
    return 0;
    80001096:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001098:	8082                	ret
{
    8000109a:	1141                	addi	sp,sp,-16
    8000109c:	e406                	sd	ra,8(sp)
    8000109e:	e022                	sd	s0,0(sp)
    800010a0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010a2:	4601                	li	a2,0
    800010a4:	00000097          	auipc	ra,0x0
    800010a8:	f44080e7          	jalr	-188(ra) # 80000fe8 <walk>
  if(pte == 0)
    800010ac:	c105                	beqz	a0,800010cc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010ae:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010b0:	0117f693          	andi	a3,a5,17
    800010b4:	4745                	li	a4,17
    return 0;
    800010b6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010b8:	00e68663          	beq	a3,a4,800010c4 <walkaddr+0x36>
}
    800010bc:	60a2                	ld	ra,8(sp)
    800010be:	6402                	ld	s0,0(sp)
    800010c0:	0141                	addi	sp,sp,16
    800010c2:	8082                	ret
  pa = PTE2PA(*pte);
    800010c4:	00a7d513          	srli	a0,a5,0xa
    800010c8:	0532                	slli	a0,a0,0xc
  return pa;
    800010ca:	bfcd                	j	800010bc <walkaddr+0x2e>
    return 0;
    800010cc:	4501                	li	a0,0
    800010ce:	b7fd                	j	800010bc <walkaddr+0x2e>

00000000800010d0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010d0:	715d                	addi	sp,sp,-80
    800010d2:	e486                	sd	ra,72(sp)
    800010d4:	e0a2                	sd	s0,64(sp)
    800010d6:	fc26                	sd	s1,56(sp)
    800010d8:	f84a                	sd	s2,48(sp)
    800010da:	f44e                	sd	s3,40(sp)
    800010dc:	f052                	sd	s4,32(sp)
    800010de:	ec56                	sd	s5,24(sp)
    800010e0:	e85a                	sd	s6,16(sp)
    800010e2:	e45e                	sd	s7,8(sp)
    800010e4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010e6:	c205                	beqz	a2,80001106 <mappages+0x36>
    800010e8:	8aaa                	mv	s5,a0
    800010ea:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ec:	77fd                	lui	a5,0xfffff
    800010ee:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010f2:	15fd                	addi	a1,a1,-1
    800010f4:	00c589b3          	add	s3,a1,a2
    800010f8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010fc:	8952                	mv	s2,s4
    800010fe:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001102:	6b85                	lui	s7,0x1
    80001104:	a015                	j	80001128 <mappages+0x58>
    panic("mappages: size");
    80001106:	00007517          	auipc	a0,0x7
    8000110a:	ff250513          	addi	a0,a0,-14 # 800080f8 <digits+0xb8>
    8000110e:	fffff097          	auipc	ra,0xfffff
    80001112:	430080e7          	jalr	1072(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001116:	00007517          	auipc	a0,0x7
    8000111a:	ff250513          	addi	a0,a0,-14 # 80008108 <digits+0xc8>
    8000111e:	fffff097          	auipc	ra,0xfffff
    80001122:	420080e7          	jalr	1056(ra) # 8000053e <panic>
    a += PGSIZE;
    80001126:	995e                	add	s2,s2,s7
  for(;;){
    80001128:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000112c:	4605                	li	a2,1
    8000112e:	85ca                	mv	a1,s2
    80001130:	8556                	mv	a0,s5
    80001132:	00000097          	auipc	ra,0x0
    80001136:	eb6080e7          	jalr	-330(ra) # 80000fe8 <walk>
    8000113a:	cd19                	beqz	a0,80001158 <mappages+0x88>
    if(*pte & PTE_V)
    8000113c:	611c                	ld	a5,0(a0)
    8000113e:	8b85                	andi	a5,a5,1
    80001140:	fbf9                	bnez	a5,80001116 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001142:	80b1                	srli	s1,s1,0xc
    80001144:	04aa                	slli	s1,s1,0xa
    80001146:	0164e4b3          	or	s1,s1,s6
    8000114a:	0014e493          	ori	s1,s1,1
    8000114e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001150:	fd391be3          	bne	s2,s3,80001126 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001154:	4501                	li	a0,0
    80001156:	a011                	j	8000115a <mappages+0x8a>
      return -1;
    80001158:	557d                	li	a0,-1
}
    8000115a:	60a6                	ld	ra,72(sp)
    8000115c:	6406                	ld	s0,64(sp)
    8000115e:	74e2                	ld	s1,56(sp)
    80001160:	7942                	ld	s2,48(sp)
    80001162:	79a2                	ld	s3,40(sp)
    80001164:	7a02                	ld	s4,32(sp)
    80001166:	6ae2                	ld	s5,24(sp)
    80001168:	6b42                	ld	s6,16(sp)
    8000116a:	6ba2                	ld	s7,8(sp)
    8000116c:	6161                	addi	sp,sp,80
    8000116e:	8082                	ret

0000000080001170 <kvmmap>:
{
    80001170:	1141                	addi	sp,sp,-16
    80001172:	e406                	sd	ra,8(sp)
    80001174:	e022                	sd	s0,0(sp)
    80001176:	0800                	addi	s0,sp,16
    80001178:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000117a:	86b2                	mv	a3,a2
    8000117c:	863e                	mv	a2,a5
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	f52080e7          	jalr	-174(ra) # 800010d0 <mappages>
    80001186:	e509                	bnez	a0,80001190 <kvmmap+0x20>
}
    80001188:	60a2                	ld	ra,8(sp)
    8000118a:	6402                	ld	s0,0(sp)
    8000118c:	0141                	addi	sp,sp,16
    8000118e:	8082                	ret
    panic("kvmmap");
    80001190:	00007517          	auipc	a0,0x7
    80001194:	f8850513          	addi	a0,a0,-120 # 80008118 <digits+0xd8>
    80001198:	fffff097          	auipc	ra,0xfffff
    8000119c:	3a6080e7          	jalr	934(ra) # 8000053e <panic>

00000000800011a0 <kvmmake>:
{
    800011a0:	1101                	addi	sp,sp,-32
    800011a2:	ec06                	sd	ra,24(sp)
    800011a4:	e822                	sd	s0,16(sp)
    800011a6:	e426                	sd	s1,8(sp)
    800011a8:	e04a                	sd	s2,0(sp)
    800011aa:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011ac:	00000097          	auipc	ra,0x0
    800011b0:	948080e7          	jalr	-1720(ra) # 80000af4 <kalloc>
    800011b4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011b6:	6605                	lui	a2,0x1
    800011b8:	4581                	li	a1,0
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	b26080e7          	jalr	-1242(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10000637          	lui	a2,0x10000
    800011ca:	100005b7          	lui	a1,0x10000
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	fa0080e7          	jalr	-96(ra) # 80001170 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	6685                	lui	a3,0x1
    800011dc:	10001637          	lui	a2,0x10001
    800011e0:	100015b7          	lui	a1,0x10001
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f8a080e7          	jalr	-118(ra) # 80001170 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ee:	4719                	li	a4,6
    800011f0:	004006b7          	lui	a3,0x400
    800011f4:	0c000637          	lui	a2,0xc000
    800011f8:	0c0005b7          	lui	a1,0xc000
    800011fc:	8526                	mv	a0,s1
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f72080e7          	jalr	-142(ra) # 80001170 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001206:	00007917          	auipc	s2,0x7
    8000120a:	dfa90913          	addi	s2,s2,-518 # 80008000 <etext>
    8000120e:	4729                	li	a4,10
    80001210:	80007697          	auipc	a3,0x80007
    80001214:	df068693          	addi	a3,a3,-528 # 8000 <_entry-0x7fff8000>
    80001218:	4605                	li	a2,1
    8000121a:	067e                	slli	a2,a2,0x1f
    8000121c:	85b2                	mv	a1,a2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f50080e7          	jalr	-176(ra) # 80001170 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001228:	4719                	li	a4,6
    8000122a:	46c5                	li	a3,17
    8000122c:	06ee                	slli	a3,a3,0x1b
    8000122e:	412686b3          	sub	a3,a3,s2
    80001232:	864a                	mv	a2,s2
    80001234:	85ca                	mv	a1,s2
    80001236:	8526                	mv	a0,s1
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	f38080e7          	jalr	-200(ra) # 80001170 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001240:	4729                	li	a4,10
    80001242:	6685                	lui	a3,0x1
    80001244:	00006617          	auipc	a2,0x6
    80001248:	dbc60613          	addi	a2,a2,-580 # 80007000 <_trampoline>
    8000124c:	040005b7          	lui	a1,0x4000
    80001250:	15fd                	addi	a1,a1,-1
    80001252:	05b2                	slli	a1,a1,0xc
    80001254:	8526                	mv	a0,s1
    80001256:	00000097          	auipc	ra,0x0
    8000125a:	f1a080e7          	jalr	-230(ra) # 80001170 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000125e:	8526                	mv	a0,s1
    80001260:	00000097          	auipc	ra,0x0
    80001264:	5fe080e7          	jalr	1534(ra) # 8000185e <proc_mapstacks>
}
    80001268:	8526                	mv	a0,s1
    8000126a:	60e2                	ld	ra,24(sp)
    8000126c:	6442                	ld	s0,16(sp)
    8000126e:	64a2                	ld	s1,8(sp)
    80001270:	6902                	ld	s2,0(sp)
    80001272:	6105                	addi	sp,sp,32
    80001274:	8082                	ret

0000000080001276 <kvminit>:
{
    80001276:	1141                	addi	sp,sp,-16
    80001278:	e406                	sd	ra,8(sp)
    8000127a:	e022                	sd	s0,0(sp)
    8000127c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f22080e7          	jalr	-222(ra) # 800011a0 <kvmmake>
    80001286:	00008797          	auipc	a5,0x8
    8000128a:	d8a7bd23          	sd	a0,-614(a5) # 80009020 <kernel_pagetable>
}
    8000128e:	60a2                	ld	ra,8(sp)
    80001290:	6402                	ld	s0,0(sp)
    80001292:	0141                	addi	sp,sp,16
    80001294:	8082                	ret

0000000080001296 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001296:	715d                	addi	sp,sp,-80
    80001298:	e486                	sd	ra,72(sp)
    8000129a:	e0a2                	sd	s0,64(sp)
    8000129c:	fc26                	sd	s1,56(sp)
    8000129e:	f84a                	sd	s2,48(sp)
    800012a0:	f44e                	sd	s3,40(sp)
    800012a2:	f052                	sd	s4,32(sp)
    800012a4:	ec56                	sd	s5,24(sp)
    800012a6:	e85a                	sd	s6,16(sp)
    800012a8:	e45e                	sd	s7,8(sp)
    800012aa:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ac:	03459793          	slli	a5,a1,0x34
    800012b0:	e795                	bnez	a5,800012dc <uvmunmap+0x46>
    800012b2:	8a2a                	mv	s4,a0
    800012b4:	892e                	mv	s2,a1
    800012b6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012b8:	0632                	slli	a2,a2,0xc
    800012ba:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012be:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c0:	6b05                	lui	s6,0x1
    800012c2:	0735e863          	bltu	a1,s3,80001332 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012c6:	60a6                	ld	ra,72(sp)
    800012c8:	6406                	ld	s0,64(sp)
    800012ca:	74e2                	ld	s1,56(sp)
    800012cc:	7942                	ld	s2,48(sp)
    800012ce:	79a2                	ld	s3,40(sp)
    800012d0:	7a02                	ld	s4,32(sp)
    800012d2:	6ae2                	ld	s5,24(sp)
    800012d4:	6b42                	ld	s6,16(sp)
    800012d6:	6ba2                	ld	s7,8(sp)
    800012d8:	6161                	addi	sp,sp,80
    800012da:	8082                	ret
    panic("uvmunmap: not aligned");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4450513          	addi	a0,a0,-444 # 80008120 <digits+0xe0>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e4c50513          	addi	a0,a0,-436 # 80008138 <digits+0xf8>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012fc:	00007517          	auipc	a0,0x7
    80001300:	e4c50513          	addi	a0,a0,-436 # 80008148 <digits+0x108>
    80001304:	fffff097          	auipc	ra,0xfffff
    80001308:	23a080e7          	jalr	570(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000130c:	00007517          	auipc	a0,0x7
    80001310:	e5450513          	addi	a0,a0,-428 # 80008160 <digits+0x120>
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	22a080e7          	jalr	554(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    8000131c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131e:	0532                	slli	a0,a0,0xc
    80001320:	fffff097          	auipc	ra,0xfffff
    80001324:	6d8080e7          	jalr	1752(ra) # 800009f8 <kfree>
    *pte = 0;
    80001328:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000132c:	995a                	add	s2,s2,s6
    8000132e:	f9397ce3          	bgeu	s2,s3,800012c6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001332:	4601                	li	a2,0
    80001334:	85ca                	mv	a1,s2
    80001336:	8552                	mv	a0,s4
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	cb0080e7          	jalr	-848(ra) # 80000fe8 <walk>
    80001340:	84aa                	mv	s1,a0
    80001342:	d54d                	beqz	a0,800012ec <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001344:	6108                	ld	a0,0(a0)
    80001346:	00157793          	andi	a5,a0,1
    8000134a:	dbcd                	beqz	a5,800012fc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000134c:	3ff57793          	andi	a5,a0,1023
    80001350:	fb778ee3          	beq	a5,s7,8000130c <uvmunmap+0x76>
    if(do_free){
    80001354:	fc0a8ae3          	beqz	s5,80001328 <uvmunmap+0x92>
    80001358:	b7d1                	j	8000131c <uvmunmap+0x86>

000000008000135a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000135a:	1101                	addi	sp,sp,-32
    8000135c:	ec06                	sd	ra,24(sp)
    8000135e:	e822                	sd	s0,16(sp)
    80001360:	e426                	sd	s1,8(sp)
    80001362:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001364:	fffff097          	auipc	ra,0xfffff
    80001368:	790080e7          	jalr	1936(ra) # 80000af4 <kalloc>
    8000136c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000136e:	c519                	beqz	a0,8000137c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001370:	6605                	lui	a2,0x1
    80001372:	4581                	li	a1,0
    80001374:	00000097          	auipc	ra,0x0
    80001378:	96c080e7          	jalr	-1684(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000137c:	8526                	mv	a0,s1
    8000137e:	60e2                	ld	ra,24(sp)
    80001380:	6442                	ld	s0,16(sp)
    80001382:	64a2                	ld	s1,8(sp)
    80001384:	6105                	addi	sp,sp,32
    80001386:	8082                	ret

0000000080001388 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001388:	7179                	addi	sp,sp,-48
    8000138a:	f406                	sd	ra,40(sp)
    8000138c:	f022                	sd	s0,32(sp)
    8000138e:	ec26                	sd	s1,24(sp)
    80001390:	e84a                	sd	s2,16(sp)
    80001392:	e44e                	sd	s3,8(sp)
    80001394:	e052                	sd	s4,0(sp)
    80001396:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001398:	6785                	lui	a5,0x1
    8000139a:	04f67863          	bgeu	a2,a5,800013ea <uvminit+0x62>
    8000139e:	8a2a                	mv	s4,a0
    800013a0:	89ae                	mv	s3,a1
    800013a2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	750080e7          	jalr	1872(ra) # 80000af4 <kalloc>
    800013ac:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013ae:	6605                	lui	a2,0x1
    800013b0:	4581                	li	a1,0
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	92e080e7          	jalr	-1746(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013ba:	4779                	li	a4,30
    800013bc:	86ca                	mv	a3,s2
    800013be:	6605                	lui	a2,0x1
    800013c0:	4581                	li	a1,0
    800013c2:	8552                	mv	a0,s4
    800013c4:	00000097          	auipc	ra,0x0
    800013c8:	d0c080e7          	jalr	-756(ra) # 800010d0 <mappages>
  memmove(mem, src, sz);
    800013cc:	8626                	mv	a2,s1
    800013ce:	85ce                	mv	a1,s3
    800013d0:	854a                	mv	a0,s2
    800013d2:	00000097          	auipc	ra,0x0
    800013d6:	96e080e7          	jalr	-1682(ra) # 80000d40 <memmove>
}
    800013da:	70a2                	ld	ra,40(sp)
    800013dc:	7402                	ld	s0,32(sp)
    800013de:	64e2                	ld	s1,24(sp)
    800013e0:	6942                	ld	s2,16(sp)
    800013e2:	69a2                	ld	s3,8(sp)
    800013e4:	6a02                	ld	s4,0(sp)
    800013e6:	6145                	addi	sp,sp,48
    800013e8:	8082                	ret
    panic("inituvm: more than a page");
    800013ea:	00007517          	auipc	a0,0x7
    800013ee:	d8e50513          	addi	a0,a0,-626 # 80008178 <digits+0x138>
    800013f2:	fffff097          	auipc	ra,0xfffff
    800013f6:	14c080e7          	jalr	332(ra) # 8000053e <panic>

00000000800013fa <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013fa:	1101                	addi	sp,sp,-32
    800013fc:	ec06                	sd	ra,24(sp)
    800013fe:	e822                	sd	s0,16(sp)
    80001400:	e426                	sd	s1,8(sp)
    80001402:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001404:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001406:	00b67d63          	bgeu	a2,a1,80001420 <uvmdealloc+0x26>
    8000140a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000140c:	6785                	lui	a5,0x1
    8000140e:	17fd                	addi	a5,a5,-1
    80001410:	00f60733          	add	a4,a2,a5
    80001414:	767d                	lui	a2,0xfffff
    80001416:	8f71                	and	a4,a4,a2
    80001418:	97ae                	add	a5,a5,a1
    8000141a:	8ff1                	and	a5,a5,a2
    8000141c:	00f76863          	bltu	a4,a5,8000142c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001420:	8526                	mv	a0,s1
    80001422:	60e2                	ld	ra,24(sp)
    80001424:	6442                	ld	s0,16(sp)
    80001426:	64a2                	ld	s1,8(sp)
    80001428:	6105                	addi	sp,sp,32
    8000142a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000142c:	8f99                	sub	a5,a5,a4
    8000142e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001430:	4685                	li	a3,1
    80001432:	0007861b          	sext.w	a2,a5
    80001436:	85ba                	mv	a1,a4
    80001438:	00000097          	auipc	ra,0x0
    8000143c:	e5e080e7          	jalr	-418(ra) # 80001296 <uvmunmap>
    80001440:	b7c5                	j	80001420 <uvmdealloc+0x26>

0000000080001442 <uvmalloc>:
  if(newsz < oldsz)
    80001442:	0ab66163          	bltu	a2,a1,800014e4 <uvmalloc+0xa2>
{
    80001446:	7139                	addi	sp,sp,-64
    80001448:	fc06                	sd	ra,56(sp)
    8000144a:	f822                	sd	s0,48(sp)
    8000144c:	f426                	sd	s1,40(sp)
    8000144e:	f04a                	sd	s2,32(sp)
    80001450:	ec4e                	sd	s3,24(sp)
    80001452:	e852                	sd	s4,16(sp)
    80001454:	e456                	sd	s5,8(sp)
    80001456:	0080                	addi	s0,sp,64
    80001458:	8aaa                	mv	s5,a0
    8000145a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000145c:	6985                	lui	s3,0x1
    8000145e:	19fd                	addi	s3,s3,-1
    80001460:	95ce                	add	a1,a1,s3
    80001462:	79fd                	lui	s3,0xfffff
    80001464:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001468:	08c9f063          	bgeu	s3,a2,800014e8 <uvmalloc+0xa6>
    8000146c:	894e                	mv	s2,s3
    mem = kalloc();
    8000146e:	fffff097          	auipc	ra,0xfffff
    80001472:	686080e7          	jalr	1670(ra) # 80000af4 <kalloc>
    80001476:	84aa                	mv	s1,a0
    if(mem == 0){
    80001478:	c51d                	beqz	a0,800014a6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000147a:	6605                	lui	a2,0x1
    8000147c:	4581                	li	a1,0
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	862080e7          	jalr	-1950(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001486:	4779                	li	a4,30
    80001488:	86a6                	mv	a3,s1
    8000148a:	6605                	lui	a2,0x1
    8000148c:	85ca                	mv	a1,s2
    8000148e:	8556                	mv	a0,s5
    80001490:	00000097          	auipc	ra,0x0
    80001494:	c40080e7          	jalr	-960(ra) # 800010d0 <mappages>
    80001498:	e905                	bnez	a0,800014c8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149a:	6785                	lui	a5,0x1
    8000149c:	993e                	add	s2,s2,a5
    8000149e:	fd4968e3          	bltu	s2,s4,8000146e <uvmalloc+0x2c>
  return newsz;
    800014a2:	8552                	mv	a0,s4
    800014a4:	a809                	j	800014b6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014a6:	864e                	mv	a2,s3
    800014a8:	85ca                	mv	a1,s2
    800014aa:	8556                	mv	a0,s5
    800014ac:	00000097          	auipc	ra,0x0
    800014b0:	f4e080e7          	jalr	-178(ra) # 800013fa <uvmdealloc>
      return 0;
    800014b4:	4501                	li	a0,0
}
    800014b6:	70e2                	ld	ra,56(sp)
    800014b8:	7442                	ld	s0,48(sp)
    800014ba:	74a2                	ld	s1,40(sp)
    800014bc:	7902                	ld	s2,32(sp)
    800014be:	69e2                	ld	s3,24(sp)
    800014c0:	6a42                	ld	s4,16(sp)
    800014c2:	6aa2                	ld	s5,8(sp)
    800014c4:	6121                	addi	sp,sp,64
    800014c6:	8082                	ret
      kfree(mem);
    800014c8:	8526                	mv	a0,s1
    800014ca:	fffff097          	auipc	ra,0xfffff
    800014ce:	52e080e7          	jalr	1326(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014d2:	864e                	mv	a2,s3
    800014d4:	85ca                	mv	a1,s2
    800014d6:	8556                	mv	a0,s5
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	f22080e7          	jalr	-222(ra) # 800013fa <uvmdealloc>
      return 0;
    800014e0:	4501                	li	a0,0
    800014e2:	bfd1                	j	800014b6 <uvmalloc+0x74>
    return oldsz;
    800014e4:	852e                	mv	a0,a1
}
    800014e6:	8082                	ret
  return newsz;
    800014e8:	8532                	mv	a0,a2
    800014ea:	b7f1                	j	800014b6 <uvmalloc+0x74>

00000000800014ec <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ec:	7179                	addi	sp,sp,-48
    800014ee:	f406                	sd	ra,40(sp)
    800014f0:	f022                	sd	s0,32(sp)
    800014f2:	ec26                	sd	s1,24(sp)
    800014f4:	e84a                	sd	s2,16(sp)
    800014f6:	e44e                	sd	s3,8(sp)
    800014f8:	e052                	sd	s4,0(sp)
    800014fa:	1800                	addi	s0,sp,48
    800014fc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014fe:	84aa                	mv	s1,a0
    80001500:	6905                	lui	s2,0x1
    80001502:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001504:	4985                	li	s3,1
    80001506:	a821                	j	8000151e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001508:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000150a:	0532                	slli	a0,a0,0xc
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	fe0080e7          	jalr	-32(ra) # 800014ec <freewalk>
      pagetable[i] = 0;
    80001514:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001518:	04a1                	addi	s1,s1,8
    8000151a:	03248163          	beq	s1,s2,8000153c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000151e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001520:	00f57793          	andi	a5,a0,15
    80001524:	ff3782e3          	beq	a5,s3,80001508 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001528:	8905                	andi	a0,a0,1
    8000152a:	d57d                	beqz	a0,80001518 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000152c:	00007517          	auipc	a0,0x7
    80001530:	c6c50513          	addi	a0,a0,-916 # 80008198 <digits+0x158>
    80001534:	fffff097          	auipc	ra,0xfffff
    80001538:	00a080e7          	jalr	10(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000153c:	8552                	mv	a0,s4
    8000153e:	fffff097          	auipc	ra,0xfffff
    80001542:	4ba080e7          	jalr	1210(ra) # 800009f8 <kfree>
}
    80001546:	70a2                	ld	ra,40(sp)
    80001548:	7402                	ld	s0,32(sp)
    8000154a:	64e2                	ld	s1,24(sp)
    8000154c:	6942                	ld	s2,16(sp)
    8000154e:	69a2                	ld	s3,8(sp)
    80001550:	6a02                	ld	s4,0(sp)
    80001552:	6145                	addi	sp,sp,48
    80001554:	8082                	ret

0000000080001556 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001556:	1101                	addi	sp,sp,-32
    80001558:	ec06                	sd	ra,24(sp)
    8000155a:	e822                	sd	s0,16(sp)
    8000155c:	e426                	sd	s1,8(sp)
    8000155e:	1000                	addi	s0,sp,32
    80001560:	84aa                	mv	s1,a0
  if(sz > 0)
    80001562:	e999                	bnez	a1,80001578 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001564:	8526                	mv	a0,s1
    80001566:	00000097          	auipc	ra,0x0
    8000156a:	f86080e7          	jalr	-122(ra) # 800014ec <freewalk>
}
    8000156e:	60e2                	ld	ra,24(sp)
    80001570:	6442                	ld	s0,16(sp)
    80001572:	64a2                	ld	s1,8(sp)
    80001574:	6105                	addi	sp,sp,32
    80001576:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001578:	6605                	lui	a2,0x1
    8000157a:	167d                	addi	a2,a2,-1
    8000157c:	962e                	add	a2,a2,a1
    8000157e:	4685                	li	a3,1
    80001580:	8231                	srli	a2,a2,0xc
    80001582:	4581                	li	a1,0
    80001584:	00000097          	auipc	ra,0x0
    80001588:	d12080e7          	jalr	-750(ra) # 80001296 <uvmunmap>
    8000158c:	bfe1                	j	80001564 <uvmfree+0xe>

000000008000158e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000158e:	c679                	beqz	a2,8000165c <uvmcopy+0xce>
{
    80001590:	715d                	addi	sp,sp,-80
    80001592:	e486                	sd	ra,72(sp)
    80001594:	e0a2                	sd	s0,64(sp)
    80001596:	fc26                	sd	s1,56(sp)
    80001598:	f84a                	sd	s2,48(sp)
    8000159a:	f44e                	sd	s3,40(sp)
    8000159c:	f052                	sd	s4,32(sp)
    8000159e:	ec56                	sd	s5,24(sp)
    800015a0:	e85a                	sd	s6,16(sp)
    800015a2:	e45e                	sd	s7,8(sp)
    800015a4:	0880                	addi	s0,sp,80
    800015a6:	8b2a                	mv	s6,a0
    800015a8:	8aae                	mv	s5,a1
    800015aa:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015ac:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015ae:	4601                	li	a2,0
    800015b0:	85ce                	mv	a1,s3
    800015b2:	855a                	mv	a0,s6
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	a34080e7          	jalr	-1484(ra) # 80000fe8 <walk>
    800015bc:	c531                	beqz	a0,80001608 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015be:	6118                	ld	a4,0(a0)
    800015c0:	00177793          	andi	a5,a4,1
    800015c4:	cbb1                	beqz	a5,80001618 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015c6:	00a75593          	srli	a1,a4,0xa
    800015ca:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ce:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015d2:	fffff097          	auipc	ra,0xfffff
    800015d6:	522080e7          	jalr	1314(ra) # 80000af4 <kalloc>
    800015da:	892a                	mv	s2,a0
    800015dc:	c939                	beqz	a0,80001632 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015de:	6605                	lui	a2,0x1
    800015e0:	85de                	mv	a1,s7
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	75e080e7          	jalr	1886(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ea:	8726                	mv	a4,s1
    800015ec:	86ca                	mv	a3,s2
    800015ee:	6605                	lui	a2,0x1
    800015f0:	85ce                	mv	a1,s3
    800015f2:	8556                	mv	a0,s5
    800015f4:	00000097          	auipc	ra,0x0
    800015f8:	adc080e7          	jalr	-1316(ra) # 800010d0 <mappages>
    800015fc:	e515                	bnez	a0,80001628 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015fe:	6785                	lui	a5,0x1
    80001600:	99be                	add	s3,s3,a5
    80001602:	fb49e6e3          	bltu	s3,s4,800015ae <uvmcopy+0x20>
    80001606:	a081                	j	80001646 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001608:	00007517          	auipc	a0,0x7
    8000160c:	ba050513          	addi	a0,a0,-1120 # 800081a8 <digits+0x168>
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	f2e080e7          	jalr	-210(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001618:	00007517          	auipc	a0,0x7
    8000161c:	bb050513          	addi	a0,a0,-1104 # 800081c8 <digits+0x188>
    80001620:	fffff097          	auipc	ra,0xfffff
    80001624:	f1e080e7          	jalr	-226(ra) # 8000053e <panic>
      kfree(mem);
    80001628:	854a                	mv	a0,s2
    8000162a:	fffff097          	auipc	ra,0xfffff
    8000162e:	3ce080e7          	jalr	974(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001632:	4685                	li	a3,1
    80001634:	00c9d613          	srli	a2,s3,0xc
    80001638:	4581                	li	a1,0
    8000163a:	8556                	mv	a0,s5
    8000163c:	00000097          	auipc	ra,0x0
    80001640:	c5a080e7          	jalr	-934(ra) # 80001296 <uvmunmap>
  return -1;
    80001644:	557d                	li	a0,-1
}
    80001646:	60a6                	ld	ra,72(sp)
    80001648:	6406                	ld	s0,64(sp)
    8000164a:	74e2                	ld	s1,56(sp)
    8000164c:	7942                	ld	s2,48(sp)
    8000164e:	79a2                	ld	s3,40(sp)
    80001650:	7a02                	ld	s4,32(sp)
    80001652:	6ae2                	ld	s5,24(sp)
    80001654:	6b42                	ld	s6,16(sp)
    80001656:	6ba2                	ld	s7,8(sp)
    80001658:	6161                	addi	sp,sp,80
    8000165a:	8082                	ret
  return 0;
    8000165c:	4501                	li	a0,0
}
    8000165e:	8082                	ret

0000000080001660 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001660:	1141                	addi	sp,sp,-16
    80001662:	e406                	sd	ra,8(sp)
    80001664:	e022                	sd	s0,0(sp)
    80001666:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001668:	4601                	li	a2,0
    8000166a:	00000097          	auipc	ra,0x0
    8000166e:	97e080e7          	jalr	-1666(ra) # 80000fe8 <walk>
  if(pte == 0)
    80001672:	c901                	beqz	a0,80001682 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001674:	611c                	ld	a5,0(a0)
    80001676:	9bbd                	andi	a5,a5,-17
    80001678:	e11c                	sd	a5,0(a0)
}
    8000167a:	60a2                	ld	ra,8(sp)
    8000167c:	6402                	ld	s0,0(sp)
    8000167e:	0141                	addi	sp,sp,16
    80001680:	8082                	ret
    panic("uvmclear");
    80001682:	00007517          	auipc	a0,0x7
    80001686:	b6650513          	addi	a0,a0,-1178 # 800081e8 <digits+0x1a8>
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	eb4080e7          	jalr	-332(ra) # 8000053e <panic>

0000000080001692 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001692:	c6bd                	beqz	a3,80001700 <copyout+0x6e>
{
    80001694:	715d                	addi	sp,sp,-80
    80001696:	e486                	sd	ra,72(sp)
    80001698:	e0a2                	sd	s0,64(sp)
    8000169a:	fc26                	sd	s1,56(sp)
    8000169c:	f84a                	sd	s2,48(sp)
    8000169e:	f44e                	sd	s3,40(sp)
    800016a0:	f052                	sd	s4,32(sp)
    800016a2:	ec56                	sd	s5,24(sp)
    800016a4:	e85a                	sd	s6,16(sp)
    800016a6:	e45e                	sd	s7,8(sp)
    800016a8:	e062                	sd	s8,0(sp)
    800016aa:	0880                	addi	s0,sp,80
    800016ac:	8b2a                	mv	s6,a0
    800016ae:	8c2e                	mv	s8,a1
    800016b0:	8a32                	mv	s4,a2
    800016b2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016b4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016b6:	6a85                	lui	s5,0x1
    800016b8:	a015                	j	800016dc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ba:	9562                	add	a0,a0,s8
    800016bc:	0004861b          	sext.w	a2,s1
    800016c0:	85d2                	mv	a1,s4
    800016c2:	41250533          	sub	a0,a0,s2
    800016c6:	fffff097          	auipc	ra,0xfffff
    800016ca:	67a080e7          	jalr	1658(ra) # 80000d40 <memmove>

    len -= n;
    800016ce:	409989b3          	sub	s3,s3,s1
    src += n;
    800016d2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016d4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016d8:	02098263          	beqz	s3,800016fc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016dc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016e0:	85ca                	mv	a1,s2
    800016e2:	855a                	mv	a0,s6
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	9aa080e7          	jalr	-1622(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    800016ec:	cd01                	beqz	a0,80001704 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ee:	418904b3          	sub	s1,s2,s8
    800016f2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016f4:	fc99f3e3          	bgeu	s3,s1,800016ba <copyout+0x28>
    800016f8:	84ce                	mv	s1,s3
    800016fa:	b7c1                	j	800016ba <copyout+0x28>
  }
  return 0;
    800016fc:	4501                	li	a0,0
    800016fe:	a021                	j	80001706 <copyout+0x74>
    80001700:	4501                	li	a0,0
}
    80001702:	8082                	ret
      return -1;
    80001704:	557d                	li	a0,-1
}
    80001706:	60a6                	ld	ra,72(sp)
    80001708:	6406                	ld	s0,64(sp)
    8000170a:	74e2                	ld	s1,56(sp)
    8000170c:	7942                	ld	s2,48(sp)
    8000170e:	79a2                	ld	s3,40(sp)
    80001710:	7a02                	ld	s4,32(sp)
    80001712:	6ae2                	ld	s5,24(sp)
    80001714:	6b42                	ld	s6,16(sp)
    80001716:	6ba2                	ld	s7,8(sp)
    80001718:	6c02                	ld	s8,0(sp)
    8000171a:	6161                	addi	sp,sp,80
    8000171c:	8082                	ret

000000008000171e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171e:	c6bd                	beqz	a3,8000178c <copyin+0x6e>
{
    80001720:	715d                	addi	sp,sp,-80
    80001722:	e486                	sd	ra,72(sp)
    80001724:	e0a2                	sd	s0,64(sp)
    80001726:	fc26                	sd	s1,56(sp)
    80001728:	f84a                	sd	s2,48(sp)
    8000172a:	f44e                	sd	s3,40(sp)
    8000172c:	f052                	sd	s4,32(sp)
    8000172e:	ec56                	sd	s5,24(sp)
    80001730:	e85a                	sd	s6,16(sp)
    80001732:	e45e                	sd	s7,8(sp)
    80001734:	e062                	sd	s8,0(sp)
    80001736:	0880                	addi	s0,sp,80
    80001738:	8b2a                	mv	s6,a0
    8000173a:	8a2e                	mv	s4,a1
    8000173c:	8c32                	mv	s8,a2
    8000173e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001740:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001742:	6a85                	lui	s5,0x1
    80001744:	a015                	j	80001768 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001746:	9562                	add	a0,a0,s8
    80001748:	0004861b          	sext.w	a2,s1
    8000174c:	412505b3          	sub	a1,a0,s2
    80001750:	8552                	mv	a0,s4
    80001752:	fffff097          	auipc	ra,0xfffff
    80001756:	5ee080e7          	jalr	1518(ra) # 80000d40 <memmove>

    len -= n;
    8000175a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000175e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001760:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001764:	02098263          	beqz	s3,80001788 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001768:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176c:	85ca                	mv	a1,s2
    8000176e:	855a                	mv	a0,s6
    80001770:	00000097          	auipc	ra,0x0
    80001774:	91e080e7          	jalr	-1762(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    80001778:	cd01                	beqz	a0,80001790 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000177a:	418904b3          	sub	s1,s2,s8
    8000177e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001780:	fc99f3e3          	bgeu	s3,s1,80001746 <copyin+0x28>
    80001784:	84ce                	mv	s1,s3
    80001786:	b7c1                	j	80001746 <copyin+0x28>
  }
  return 0;
    80001788:	4501                	li	a0,0
    8000178a:	a021                	j	80001792 <copyin+0x74>
    8000178c:	4501                	li	a0,0
}
    8000178e:	8082                	ret
      return -1;
    80001790:	557d                	li	a0,-1
}
    80001792:	60a6                	ld	ra,72(sp)
    80001794:	6406                	ld	s0,64(sp)
    80001796:	74e2                	ld	s1,56(sp)
    80001798:	7942                	ld	s2,48(sp)
    8000179a:	79a2                	ld	s3,40(sp)
    8000179c:	7a02                	ld	s4,32(sp)
    8000179e:	6ae2                	ld	s5,24(sp)
    800017a0:	6b42                	ld	s6,16(sp)
    800017a2:	6ba2                	ld	s7,8(sp)
    800017a4:	6c02                	ld	s8,0(sp)
    800017a6:	6161                	addi	sp,sp,80
    800017a8:	8082                	ret

00000000800017aa <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017aa:	c6c5                	beqz	a3,80001852 <copyinstr+0xa8>
{
    800017ac:	715d                	addi	sp,sp,-80
    800017ae:	e486                	sd	ra,72(sp)
    800017b0:	e0a2                	sd	s0,64(sp)
    800017b2:	fc26                	sd	s1,56(sp)
    800017b4:	f84a                	sd	s2,48(sp)
    800017b6:	f44e                	sd	s3,40(sp)
    800017b8:	f052                	sd	s4,32(sp)
    800017ba:	ec56                	sd	s5,24(sp)
    800017bc:	e85a                	sd	s6,16(sp)
    800017be:	e45e                	sd	s7,8(sp)
    800017c0:	0880                	addi	s0,sp,80
    800017c2:	8a2a                	mv	s4,a0
    800017c4:	8b2e                	mv	s6,a1
    800017c6:	8bb2                	mv	s7,a2
    800017c8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ca:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017cc:	6985                	lui	s3,0x1
    800017ce:	a035                	j	800017fa <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017d0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017d4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017d6:	0017b793          	seqz	a5,a5
    800017da:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017de:	60a6                	ld	ra,72(sp)
    800017e0:	6406                	ld	s0,64(sp)
    800017e2:	74e2                	ld	s1,56(sp)
    800017e4:	7942                	ld	s2,48(sp)
    800017e6:	79a2                	ld	s3,40(sp)
    800017e8:	7a02                	ld	s4,32(sp)
    800017ea:	6ae2                	ld	s5,24(sp)
    800017ec:	6b42                	ld	s6,16(sp)
    800017ee:	6ba2                	ld	s7,8(sp)
    800017f0:	6161                	addi	sp,sp,80
    800017f2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017f4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017f8:	c8a9                	beqz	s1,8000184a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017fa:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017fe:	85ca                	mv	a1,s2
    80001800:	8552                	mv	a0,s4
    80001802:	00000097          	auipc	ra,0x0
    80001806:	88c080e7          	jalr	-1908(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    8000180a:	c131                	beqz	a0,8000184e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000180c:	41790833          	sub	a6,s2,s7
    80001810:	984e                	add	a6,a6,s3
    if(n > max)
    80001812:	0104f363          	bgeu	s1,a6,80001818 <copyinstr+0x6e>
    80001816:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001818:	955e                	add	a0,a0,s7
    8000181a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000181e:	fc080be3          	beqz	a6,800017f4 <copyinstr+0x4a>
    80001822:	985a                	add	a6,a6,s6
    80001824:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001826:	41650633          	sub	a2,a0,s6
    8000182a:	14fd                	addi	s1,s1,-1
    8000182c:	9b26                	add	s6,s6,s1
    8000182e:	00f60733          	add	a4,a2,a5
    80001832:	00074703          	lbu	a4,0(a4)
    80001836:	df49                	beqz	a4,800017d0 <copyinstr+0x26>
        *dst = *p;
    80001838:	00e78023          	sb	a4,0(a5)
      --max;
    8000183c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001840:	0785                	addi	a5,a5,1
    while(n > 0){
    80001842:	ff0796e3          	bne	a5,a6,8000182e <copyinstr+0x84>
      dst++;
    80001846:	8b42                	mv	s6,a6
    80001848:	b775                	j	800017f4 <copyinstr+0x4a>
    8000184a:	4781                	li	a5,0
    8000184c:	b769                	j	800017d6 <copyinstr+0x2c>
      return -1;
    8000184e:	557d                	li	a0,-1
    80001850:	b779                	j	800017de <copyinstr+0x34>
  int got_null = 0;
    80001852:	4781                	li	a5,0
  if(got_null){
    80001854:	0017b793          	seqz	a5,a5
    80001858:	40f00533          	neg	a0,a5
}
    8000185c:	8082                	ret

000000008000185e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000185e:	7139                	addi	sp,sp,-64
    80001860:	fc06                	sd	ra,56(sp)
    80001862:	f822                	sd	s0,48(sp)
    80001864:	f426                	sd	s1,40(sp)
    80001866:	f04a                	sd	s2,32(sp)
    80001868:	ec4e                	sd	s3,24(sp)
    8000186a:	e852                	sd	s4,16(sp)
    8000186c:	e456                	sd	s5,8(sp)
    8000186e:	e05a                	sd	s6,0(sp)
    80001870:	0080                	addi	s0,sp,64
    80001872:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001874:	00010497          	auipc	s1,0x10
    80001878:	e6c48493          	addi	s1,s1,-404 # 800116e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000187c:	8b26                	mv	s6,s1
    8000187e:	00006a97          	auipc	s5,0x6
    80001882:	782a8a93          	addi	s5,s5,1922 # 80008000 <etext>
    80001886:	04000937          	lui	s2,0x4000
    8000188a:	197d                	addi	s2,s2,-1
    8000188c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	00016a17          	auipc	s4,0x16
    80001892:	c52a0a13          	addi	s4,s4,-942 # 800174e0 <tickslock>
    char *pa = kalloc();
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	25e080e7          	jalr	606(ra) # 80000af4 <kalloc>
    8000189e:	862a                	mv	a2,a0
    if(pa == 0)
    800018a0:	c131                	beqz	a0,800018e4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018a2:	416485b3          	sub	a1,s1,s6
    800018a6:	858d                	srai	a1,a1,0x3
    800018a8:	000ab783          	ld	a5,0(s5)
    800018ac:	02f585b3          	mul	a1,a1,a5
    800018b0:	2585                	addiw	a1,a1,1
    800018b2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018b6:	4719                	li	a4,6
    800018b8:	6685                	lui	a3,0x1
    800018ba:	40b905b3          	sub	a1,s2,a1
    800018be:	854e                	mv	a0,s3
    800018c0:	00000097          	auipc	ra,0x0
    800018c4:	8b0080e7          	jalr	-1872(ra) # 80001170 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c8:	17848493          	addi	s1,s1,376
    800018cc:	fd4495e3          	bne	s1,s4,80001896 <proc_mapstacks+0x38>
  }
}
    800018d0:	70e2                	ld	ra,56(sp)
    800018d2:	7442                	ld	s0,48(sp)
    800018d4:	74a2                	ld	s1,40(sp)
    800018d6:	7902                	ld	s2,32(sp)
    800018d8:	69e2                	ld	s3,24(sp)
    800018da:	6a42                	ld	s4,16(sp)
    800018dc:	6aa2                	ld	s5,8(sp)
    800018de:	6b02                	ld	s6,0(sp)
    800018e0:	6121                	addi	sp,sp,64
    800018e2:	8082                	ret
      panic("kalloc");
    800018e4:	00007517          	auipc	a0,0x7
    800018e8:	91450513          	addi	a0,a0,-1772 # 800081f8 <digits+0x1b8>
    800018ec:	fffff097          	auipc	ra,0xfffff
    800018f0:	c52080e7          	jalr	-942(ra) # 8000053e <panic>

00000000800018f4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018f4:	7139                	addi	sp,sp,-64
    800018f6:	fc06                	sd	ra,56(sp)
    800018f8:	f822                	sd	s0,48(sp)
    800018fa:	f426                	sd	s1,40(sp)
    800018fc:	f04a                	sd	s2,32(sp)
    800018fe:	ec4e                	sd	s3,24(sp)
    80001900:	e852                	sd	s4,16(sp)
    80001902:	e456                	sd	s5,8(sp)
    80001904:	e05a                	sd	s6,0(sp)
    80001906:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001908:	00007597          	auipc	a1,0x7
    8000190c:	8f858593          	addi	a1,a1,-1800 # 80008200 <digits+0x1c0>
    80001910:	00010517          	auipc	a0,0x10
    80001914:	9a050513          	addi	a0,a0,-1632 # 800112b0 <pid_lock>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	23c080e7          	jalr	572(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001920:	00007597          	auipc	a1,0x7
    80001924:	8e858593          	addi	a1,a1,-1816 # 80008208 <digits+0x1c8>
    80001928:	00010517          	auipc	a0,0x10
    8000192c:	9a050513          	addi	a0,a0,-1632 # 800112c8 <wait_lock>
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	224080e7          	jalr	548(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001938:	00010497          	auipc	s1,0x10
    8000193c:	da848493          	addi	s1,s1,-600 # 800116e0 <proc>
      initlock(&p->lock, "proc");
    80001940:	00007b17          	auipc	s6,0x7
    80001944:	8d8b0b13          	addi	s6,s6,-1832 # 80008218 <digits+0x1d8>
      p->kstack = KSTACK((int) (p - proc));
    80001948:	8aa6                	mv	s5,s1
    8000194a:	00006a17          	auipc	s4,0x6
    8000194e:	6b6a0a13          	addi	s4,s4,1718 # 80008000 <etext>
    80001952:	04000937          	lui	s2,0x4000
    80001956:	197d                	addi	s2,s2,-1
    80001958:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00016997          	auipc	s3,0x16
    8000195e:	b8698993          	addi	s3,s3,-1146 # 800174e0 <tickslock>
      initlock(&p->lock, "proc");
    80001962:	85da                	mv	a1,s6
    80001964:	8526                	mv	a0,s1
    80001966:	fffff097          	auipc	ra,0xfffff
    8000196a:	1ee080e7          	jalr	494(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000196e:	415487b3          	sub	a5,s1,s5
    80001972:	878d                	srai	a5,a5,0x3
    80001974:	000a3703          	ld	a4,0(s4)
    80001978:	02e787b3          	mul	a5,a5,a4
    8000197c:	2785                	addiw	a5,a5,1
    8000197e:	00d7979b          	slliw	a5,a5,0xd
    80001982:	40f907b3          	sub	a5,s2,a5
    80001986:	e8bc                	sd	a5,80(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001988:	17848493          	addi	s1,s1,376
    8000198c:	fd349be3          	bne	s1,s3,80001962 <procinit+0x6e>
  }
}
    80001990:	70e2                	ld	ra,56(sp)
    80001992:	7442                	ld	s0,48(sp)
    80001994:	74a2                	ld	s1,40(sp)
    80001996:	7902                	ld	s2,32(sp)
    80001998:	69e2                	ld	s3,24(sp)
    8000199a:	6a42                	ld	s4,16(sp)
    8000199c:	6aa2                	ld	s5,8(sp)
    8000199e:	6b02                	ld	s6,0(sp)
    800019a0:	6121                	addi	sp,sp,64
    800019a2:	8082                	ret

00000000800019a4 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019a4:	1141                	addi	sp,sp,-16
    800019a6:	e422                	sd	s0,8(sp)
    800019a8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019aa:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019ac:	2501                	sext.w	a0,a0
    800019ae:	6422                	ld	s0,8(sp)
    800019b0:	0141                	addi	sp,sp,16
    800019b2:	8082                	ret

00000000800019b4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019b4:	1141                	addi	sp,sp,-16
    800019b6:	e422                	sd	s0,8(sp)
    800019b8:	0800                	addi	s0,sp,16
    800019ba:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019bc:	2781                	sext.w	a5,a5
    800019be:	079e                	slli	a5,a5,0x7
  return c;
}
    800019c0:	00010517          	auipc	a0,0x10
    800019c4:	92050513          	addi	a0,a0,-1760 # 800112e0 <cpus>
    800019c8:	953e                	add	a0,a0,a5
    800019ca:	6422                	ld	s0,8(sp)
    800019cc:	0141                	addi	sp,sp,16
    800019ce:	8082                	ret

00000000800019d0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019d0:	1101                	addi	sp,sp,-32
    800019d2:	ec06                	sd	ra,24(sp)
    800019d4:	e822                	sd	s0,16(sp)
    800019d6:	e426                	sd	s1,8(sp)
    800019d8:	1000                	addi	s0,sp,32
  push_off();
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	1be080e7          	jalr	446(ra) # 80000b98 <push_off>
    800019e2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e4:	2781                	sext.w	a5,a5
    800019e6:	079e                	slli	a5,a5,0x7
    800019e8:	00010717          	auipc	a4,0x10
    800019ec:	8c870713          	addi	a4,a4,-1848 # 800112b0 <pid_lock>
    800019f0:	97ba                	add	a5,a5,a4
    800019f2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	244080e7          	jalr	580(ra) # 80000c38 <pop_off>
  return p;
}
    800019fc:	8526                	mv	a0,s1
    800019fe:	60e2                	ld	ra,24(sp)
    80001a00:	6442                	ld	s0,16(sp)
    80001a02:	64a2                	ld	s1,8(sp)
    80001a04:	6105                	addi	sp,sp,32
    80001a06:	8082                	ret

0000000080001a08 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a08:	1141                	addi	sp,sp,-16
    80001a0a:	e406                	sd	ra,8(sp)
    80001a0c:	e022                	sd	s0,0(sp)
    80001a0e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a10:	00000097          	auipc	ra,0x0
    80001a14:	fc0080e7          	jalr	-64(ra) # 800019d0 <myproc>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	280080e7          	jalr	640(ra) # 80000c98 <release>

  if (first) {
    80001a20:	00007797          	auipc	a5,0x7
    80001a24:	e907a783          	lw	a5,-368(a5) # 800088b0 <first.1709>
    80001a28:	eb89                	bnez	a5,80001a3a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a2a:	00001097          	auipc	ra,0x1
    80001a2e:	ea2080e7          	jalr	-350(ra) # 800028cc <usertrapret>
}
    80001a32:	60a2                	ld	ra,8(sp)
    80001a34:	6402                	ld	s0,0(sp)
    80001a36:	0141                	addi	sp,sp,16
    80001a38:	8082                	ret
    first = 0;
    80001a3a:	00007797          	auipc	a5,0x7
    80001a3e:	e607ab23          	sw	zero,-394(a5) # 800088b0 <first.1709>
    fsinit(ROOTDEV);
    80001a42:	4505                	li	a0,1
    80001a44:	00002097          	auipc	ra,0x2
    80001a48:	c14080e7          	jalr	-1004(ra) # 80003658 <fsinit>
    80001a4c:	bff9                	j	80001a2a <forkret+0x22>

0000000080001a4e <allocpid>:
allocpid() {
    80001a4e:	1101                	addi	sp,sp,-32
    80001a50:	ec06                	sd	ra,24(sp)
    80001a52:	e822                	sd	s0,16(sp)
    80001a54:	e426                	sd	s1,8(sp)
    80001a56:	e04a                	sd	s2,0(sp)
    80001a58:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a5a:	00010917          	auipc	s2,0x10
    80001a5e:	85690913          	addi	s2,s2,-1962 # 800112b0 <pid_lock>
    80001a62:	854a                	mv	a0,s2
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	180080e7          	jalr	384(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a6c:	00007797          	auipc	a5,0x7
    80001a70:	e4c78793          	addi	a5,a5,-436 # 800088b8 <nextpid>
    80001a74:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a76:	0014871b          	addiw	a4,s1,1
    80001a7a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a7c:	854a                	mv	a0,s2
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	21a080e7          	jalr	538(ra) # 80000c98 <release>
}
    80001a86:	8526                	mv	a0,s1
    80001a88:	60e2                	ld	ra,24(sp)
    80001a8a:	6442                	ld	s0,16(sp)
    80001a8c:	64a2                	ld	s1,8(sp)
    80001a8e:	6902                	ld	s2,0(sp)
    80001a90:	6105                	addi	sp,sp,32
    80001a92:	8082                	ret

0000000080001a94 <proc_pagetable>:
{
    80001a94:	1101                	addi	sp,sp,-32
    80001a96:	ec06                	sd	ra,24(sp)
    80001a98:	e822                	sd	s0,16(sp)
    80001a9a:	e426                	sd	s1,8(sp)
    80001a9c:	e04a                	sd	s2,0(sp)
    80001a9e:	1000                	addi	s0,sp,32
    80001aa0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa2:	00000097          	auipc	ra,0x0
    80001aa6:	8b8080e7          	jalr	-1864(ra) # 8000135a <uvmcreate>
    80001aaa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aac:	c121                	beqz	a0,80001aec <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aae:	4729                	li	a4,10
    80001ab0:	00005697          	auipc	a3,0x5
    80001ab4:	55068693          	addi	a3,a3,1360 # 80007000 <_trampoline>
    80001ab8:	6605                	lui	a2,0x1
    80001aba:	040005b7          	lui	a1,0x4000
    80001abe:	15fd                	addi	a1,a1,-1
    80001ac0:	05b2                	slli	a1,a1,0xc
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	60e080e7          	jalr	1550(ra) # 800010d0 <mappages>
    80001aca:	02054863          	bltz	a0,80001afa <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ace:	4719                	li	a4,6
    80001ad0:	06893683          	ld	a3,104(s2)
    80001ad4:	6605                	lui	a2,0x1
    80001ad6:	020005b7          	lui	a1,0x2000
    80001ada:	15fd                	addi	a1,a1,-1
    80001adc:	05b6                	slli	a1,a1,0xd
    80001ade:	8526                	mv	a0,s1
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	5f0080e7          	jalr	1520(ra) # 800010d0 <mappages>
    80001ae8:	02054163          	bltz	a0,80001b0a <proc_pagetable+0x76>
}
    80001aec:	8526                	mv	a0,s1
    80001aee:	60e2                	ld	ra,24(sp)
    80001af0:	6442                	ld	s0,16(sp)
    80001af2:	64a2                	ld	s1,8(sp)
    80001af4:	6902                	ld	s2,0(sp)
    80001af6:	6105                	addi	sp,sp,32
    80001af8:	8082                	ret
    uvmfree(pagetable, 0);
    80001afa:	4581                	li	a1,0
    80001afc:	8526                	mv	a0,s1
    80001afe:	00000097          	auipc	ra,0x0
    80001b02:	a58080e7          	jalr	-1448(ra) # 80001556 <uvmfree>
    return 0;
    80001b06:	4481                	li	s1,0
    80001b08:	b7d5                	j	80001aec <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b0a:	4681                	li	a3,0
    80001b0c:	4605                	li	a2,1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	addi	a1,a1,-1
    80001b14:	05b2                	slli	a1,a1,0xc
    80001b16:	8526                	mv	a0,s1
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	77e080e7          	jalr	1918(ra) # 80001296 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b20:	4581                	li	a1,0
    80001b22:	8526                	mv	a0,s1
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	a32080e7          	jalr	-1486(ra) # 80001556 <uvmfree>
    return 0;
    80001b2c:	4481                	li	s1,0
    80001b2e:	bf7d                	j	80001aec <proc_pagetable+0x58>

0000000080001b30 <proc_freepagetable>:
{
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	e04a                	sd	s2,0(sp)
    80001b3a:	1000                	addi	s0,sp,32
    80001b3c:	84aa                	mv	s1,a0
    80001b3e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b40:	4681                	li	a3,0
    80001b42:	4605                	li	a2,1
    80001b44:	040005b7          	lui	a1,0x4000
    80001b48:	15fd                	addi	a1,a1,-1
    80001b4a:	05b2                	slli	a1,a1,0xc
    80001b4c:	fffff097          	auipc	ra,0xfffff
    80001b50:	74a080e7          	jalr	1866(ra) # 80001296 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b54:	4681                	li	a3,0
    80001b56:	4605                	li	a2,1
    80001b58:	020005b7          	lui	a1,0x2000
    80001b5c:	15fd                	addi	a1,a1,-1
    80001b5e:	05b6                	slli	a1,a1,0xd
    80001b60:	8526                	mv	a0,s1
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	734080e7          	jalr	1844(ra) # 80001296 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b6a:	85ca                	mv	a1,s2
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	00000097          	auipc	ra,0x0
    80001b72:	9e8080e7          	jalr	-1560(ra) # 80001556 <uvmfree>
}
    80001b76:	60e2                	ld	ra,24(sp)
    80001b78:	6442                	ld	s0,16(sp)
    80001b7a:	64a2                	ld	s1,8(sp)
    80001b7c:	6902                	ld	s2,0(sp)
    80001b7e:	6105                	addi	sp,sp,32
    80001b80:	8082                	ret

0000000080001b82 <freeproc>:
{
    80001b82:	1101                	addi	sp,sp,-32
    80001b84:	ec06                	sd	ra,24(sp)
    80001b86:	e822                	sd	s0,16(sp)
    80001b88:	e426                	sd	s1,8(sp)
    80001b8a:	1000                	addi	s0,sp,32
    80001b8c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b8e:	7528                	ld	a0,104(a0)
    80001b90:	c509                	beqz	a0,80001b9a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	e66080e7          	jalr	-410(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b9a:	0604b423          	sd	zero,104(s1)
  if(p->pagetable)
    80001b9e:	70a8                	ld	a0,96(s1)
    80001ba0:	c511                	beqz	a0,80001bac <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba2:	6cac                	ld	a1,88(s1)
    80001ba4:	00000097          	auipc	ra,0x0
    80001ba8:	f8c080e7          	jalr	-116(ra) # 80001b30 <proc_freepagetable>
  p->pagetable = 0;
    80001bac:	0604b023          	sd	zero,96(s1)
  p->sz = 0;
    80001bb0:	0404bc23          	sd	zero,88(s1)
  p->pid = 0;
    80001bb4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb8:	0404b423          	sd	zero,72(s1)
  p->name[0] = 0;
    80001bbc:	16048423          	sb	zero,360(s1)
  p->chan = 0;
    80001bc0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bcc:	0004ac23          	sw	zero,24(s1)
}
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <allocproc>:
{
    80001bda:	1101                	addi	sp,sp,-32
    80001bdc:	ec06                	sd	ra,24(sp)
    80001bde:	e822                	sd	s0,16(sp)
    80001be0:	e426                	sd	s1,8(sp)
    80001be2:	e04a                	sd	s2,0(sp)
    80001be4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be6:	00010497          	auipc	s1,0x10
    80001bea:	afa48493          	addi	s1,s1,-1286 # 800116e0 <proc>
    80001bee:	00016917          	auipc	s2,0x16
    80001bf2:	8f290913          	addi	s2,s2,-1806 # 800174e0 <tickslock>
    acquire(&p->lock);
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	fec080e7          	jalr	-20(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c00:	4c9c                	lw	a5,24(s1)
    80001c02:	cf81                	beqz	a5,80001c1a <allocproc+0x40>
      release(&p->lock);
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	092080e7          	jalr	146(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0e:	17848493          	addi	s1,s1,376
    80001c12:	ff2492e3          	bne	s1,s2,80001bf6 <allocproc+0x1c>
  return 0;
    80001c16:	4481                	li	s1,0
    80001c18:	a08d                	j	80001c7a <allocproc+0xa0>
  p->pid = allocpid();
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	e34080e7          	jalr	-460(ra) # 80001a4e <allocpid>
    80001c22:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c24:	4785                	li	a5,1
    80001c26:	cc9c                	sw	a5,24(s1)
  p->ticks_start = 0;
    80001c28:	0204ae23          	sw	zero,60(s1)
  p->last_ticks = 0;
    80001c2c:	0204ac23          	sw	zero,56(s1)
  p->mean_ticks = 0;
    80001c30:	0204aa23          	sw	zero,52(s1)
  p->last_runnable_time = 0;
    80001c34:	0404a023          	sw	zero,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	ebc080e7          	jalr	-324(ra) # 80000af4 <kalloc>
    80001c40:	892a                	mv	s2,a0
    80001c42:	f4a8                	sd	a0,104(s1)
    80001c44:	c131                	beqz	a0,80001c88 <allocproc+0xae>
  p->pagetable = proc_pagetable(p);
    80001c46:	8526                	mv	a0,s1
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	e4c080e7          	jalr	-436(ra) # 80001a94 <proc_pagetable>
    80001c50:	892a                	mv	s2,a0
    80001c52:	f0a8                	sd	a0,96(s1)
  if(p->pagetable == 0){
    80001c54:	c531                	beqz	a0,80001ca0 <allocproc+0xc6>
  memset(&p->context, 0, sizeof(p->context));
    80001c56:	07000613          	li	a2,112
    80001c5a:	4581                	li	a1,0
    80001c5c:	07048513          	addi	a0,s1,112
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	080080e7          	jalr	128(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c68:	00000797          	auipc	a5,0x0
    80001c6c:	da078793          	addi	a5,a5,-608 # 80001a08 <forkret>
    80001c70:	f8bc                	sd	a5,112(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c72:	68bc                	ld	a5,80(s1)
    80001c74:	6705                	lui	a4,0x1
    80001c76:	97ba                	add	a5,a5,a4
    80001c78:	fcbc                	sd	a5,120(s1)
}
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	60e2                	ld	ra,24(sp)
    80001c7e:	6442                	ld	s0,16(sp)
    80001c80:	64a2                	ld	s1,8(sp)
    80001c82:	6902                	ld	s2,0(sp)
    80001c84:	6105                	addi	sp,sp,32
    80001c86:	8082                	ret
    freeproc(p);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	ef8080e7          	jalr	-264(ra) # 80001b82 <freeproc>
    release(&p->lock);
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	004080e7          	jalr	4(ra) # 80000c98 <release>
    return 0;
    80001c9c:	84ca                	mv	s1,s2
    80001c9e:	bff1                	j	80001c7a <allocproc+0xa0>
    freeproc(p);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	ee0080e7          	jalr	-288(ra) # 80001b82 <freeproc>
    release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	fec080e7          	jalr	-20(ra) # 80000c98 <release>
    return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	b7d1                	j	80001c7a <allocproc+0xa0>

0000000080001cb8 <userinit>:
{
    80001cb8:	1101                	addi	sp,sp,-32
    80001cba:	ec06                	sd	ra,24(sp)
    80001cbc:	e822                	sd	s0,16(sp)
    80001cbe:	e426                	sd	s1,8(sp)
    80001cc0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc2:	00000097          	auipc	ra,0x0
    80001cc6:	f18080e7          	jalr	-232(ra) # 80001bda <allocproc>
    80001cca:	84aa                	mv	s1,a0
  initproc = p;
    80001ccc:	00007797          	auipc	a5,0x7
    80001cd0:	36a7b623          	sd	a0,876(a5) # 80009038 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd4:	03400613          	li	a2,52
    80001cd8:	00007597          	auipc	a1,0x7
    80001cdc:	be858593          	addi	a1,a1,-1048 # 800088c0 <initcode>
    80001ce0:	7128                	ld	a0,96(a0)
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	6a6080e7          	jalr	1702(ra) # 80001388 <uvminit>
  p->sz = PGSIZE;
    80001cea:	6785                	lui	a5,0x1
    80001cec:	ecbc                	sd	a5,88(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cee:	74b8                	ld	a4,104(s1)
    80001cf0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf4:	74b8                	ld	a4,104(s1)
    80001cf6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf8:	4641                	li	a2,16
    80001cfa:	00006597          	auipc	a1,0x6
    80001cfe:	52658593          	addi	a1,a1,1318 # 80008220 <digits+0x1e0>
    80001d02:	16848513          	addi	a0,s1,360
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	12c080e7          	jalr	300(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d0e:	00006517          	auipc	a0,0x6
    80001d12:	52250513          	addi	a0,a0,1314 # 80008230 <digits+0x1f0>
    80001d16:	00002097          	auipc	ra,0x2
    80001d1a:	370080e7          	jalr	880(ra) # 80004086 <namei>
    80001d1e:	16a4b023          	sd	a0,352(s1)
  p->state = RUNNABLE;
    80001d22:	478d                	li	a5,3
    80001d24:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d26:	8526                	mv	a0,s1
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	f70080e7          	jalr	-144(ra) # 80000c98 <release>
}
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6105                	addi	sp,sp,32
    80001d38:	8082                	ret

0000000080001d3a <growproc>:
{
    80001d3a:	1101                	addi	sp,sp,-32
    80001d3c:	ec06                	sd	ra,24(sp)
    80001d3e:	e822                	sd	s0,16(sp)
    80001d40:	e426                	sd	s1,8(sp)
    80001d42:	e04a                	sd	s2,0(sp)
    80001d44:	1000                	addi	s0,sp,32
    80001d46:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	c88080e7          	jalr	-888(ra) # 800019d0 <myproc>
    80001d50:	892a                	mv	s2,a0
  sz = p->sz;
    80001d52:	6d2c                	ld	a1,88(a0)
    80001d54:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d58:	00904f63          	bgtz	s1,80001d76 <growproc+0x3c>
  } else if(n < 0){
    80001d5c:	0204cc63          	bltz	s1,80001d94 <growproc+0x5a>
  p->sz = sz;
    80001d60:	1602                	slli	a2,a2,0x20
    80001d62:	9201                	srli	a2,a2,0x20
    80001d64:	04c93c23          	sd	a2,88(s2)
  return 0;
    80001d68:	4501                	li	a0,0
}
    80001d6a:	60e2                	ld	ra,24(sp)
    80001d6c:	6442                	ld	s0,16(sp)
    80001d6e:	64a2                	ld	s1,8(sp)
    80001d70:	6902                	ld	s2,0(sp)
    80001d72:	6105                	addi	sp,sp,32
    80001d74:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d76:	9e25                	addw	a2,a2,s1
    80001d78:	1602                	slli	a2,a2,0x20
    80001d7a:	9201                	srli	a2,a2,0x20
    80001d7c:	1582                	slli	a1,a1,0x20
    80001d7e:	9181                	srli	a1,a1,0x20
    80001d80:	7128                	ld	a0,96(a0)
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	6c0080e7          	jalr	1728(ra) # 80001442 <uvmalloc>
    80001d8a:	0005061b          	sext.w	a2,a0
    80001d8e:	fa69                	bnez	a2,80001d60 <growproc+0x26>
      return -1;
    80001d90:	557d                	li	a0,-1
    80001d92:	bfe1                	j	80001d6a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d94:	9e25                	addw	a2,a2,s1
    80001d96:	1602                	slli	a2,a2,0x20
    80001d98:	9201                	srli	a2,a2,0x20
    80001d9a:	1582                	slli	a1,a1,0x20
    80001d9c:	9181                	srli	a1,a1,0x20
    80001d9e:	7128                	ld	a0,96(a0)
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	65a080e7          	jalr	1626(ra) # 800013fa <uvmdealloc>
    80001da8:	0005061b          	sext.w	a2,a0
    80001dac:	bf55                	j	80001d60 <growproc+0x26>

0000000080001dae <fork>:
{
    80001dae:	7179                	addi	sp,sp,-48
    80001db0:	f406                	sd	ra,40(sp)
    80001db2:	f022                	sd	s0,32(sp)
    80001db4:	ec26                	sd	s1,24(sp)
    80001db6:	e84a                	sd	s2,16(sp)
    80001db8:	e44e                	sd	s3,8(sp)
    80001dba:	e052                	sd	s4,0(sp)
    80001dbc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	c12080e7          	jalr	-1006(ra) # 800019d0 <myproc>
    80001dc6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dc8:	00000097          	auipc	ra,0x0
    80001dcc:	e12080e7          	jalr	-494(ra) # 80001bda <allocproc>
    80001dd0:	10050b63          	beqz	a0,80001ee6 <fork+0x138>
    80001dd4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dd6:	05893603          	ld	a2,88(s2)
    80001dda:	712c                	ld	a1,96(a0)
    80001ddc:	06093503          	ld	a0,96(s2)
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	7ae080e7          	jalr	1966(ra) # 8000158e <uvmcopy>
    80001de8:	04054663          	bltz	a0,80001e34 <fork+0x86>
  np->sz = p->sz;
    80001dec:	05893783          	ld	a5,88(s2)
    80001df0:	04f9bc23          	sd	a5,88(s3)
  *(np->trapframe) = *(p->trapframe);
    80001df4:	06893683          	ld	a3,104(s2)
    80001df8:	87b6                	mv	a5,a3
    80001dfa:	0689b703          	ld	a4,104(s3)
    80001dfe:	12068693          	addi	a3,a3,288
    80001e02:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e06:	6788                	ld	a0,8(a5)
    80001e08:	6b8c                	ld	a1,16(a5)
    80001e0a:	6f90                	ld	a2,24(a5)
    80001e0c:	01073023          	sd	a6,0(a4)
    80001e10:	e708                	sd	a0,8(a4)
    80001e12:	eb0c                	sd	a1,16(a4)
    80001e14:	ef10                	sd	a2,24(a4)
    80001e16:	02078793          	addi	a5,a5,32
    80001e1a:	02070713          	addi	a4,a4,32
    80001e1e:	fed792e3          	bne	a5,a3,80001e02 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e22:	0689b783          	ld	a5,104(s3)
    80001e26:	0607b823          	sd	zero,112(a5)
    80001e2a:	0e000493          	li	s1,224
  for(i = 0; i < NOFILE; i++)
    80001e2e:	16000a13          	li	s4,352
    80001e32:	a03d                	j	80001e60 <fork+0xb2>
    freeproc(np);
    80001e34:	854e                	mv	a0,s3
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	d4c080e7          	jalr	-692(ra) # 80001b82 <freeproc>
    release(&np->lock);
    80001e3e:	854e                	mv	a0,s3
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	e58080e7          	jalr	-424(ra) # 80000c98 <release>
    return -1;
    80001e48:	5a7d                	li	s4,-1
    80001e4a:	a069                	j	80001ed4 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e4c:	00003097          	auipc	ra,0x3
    80001e50:	8d0080e7          	jalr	-1840(ra) # 8000471c <filedup>
    80001e54:	009987b3          	add	a5,s3,s1
    80001e58:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e5a:	04a1                	addi	s1,s1,8
    80001e5c:	01448763          	beq	s1,s4,80001e6a <fork+0xbc>
    if(p->ofile[i])
    80001e60:	009907b3          	add	a5,s2,s1
    80001e64:	6388                	ld	a0,0(a5)
    80001e66:	f17d                	bnez	a0,80001e4c <fork+0x9e>
    80001e68:	bfcd                	j	80001e5a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e6a:	16093503          	ld	a0,352(s2)
    80001e6e:	00002097          	auipc	ra,0x2
    80001e72:	a24080e7          	jalr	-1500(ra) # 80003892 <idup>
    80001e76:	16a9b023          	sd	a0,352(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7a:	4641                	li	a2,16
    80001e7c:	16890593          	addi	a1,s2,360
    80001e80:	16898513          	addi	a0,s3,360
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	fae080e7          	jalr	-82(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e8c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e90:	854e                	mv	a0,s3
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	e06080e7          	jalr	-506(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e9a:	0000f497          	auipc	s1,0xf
    80001e9e:	42e48493          	addi	s1,s1,1070 # 800112c8 <wait_lock>
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	d40080e7          	jalr	-704(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eac:	0529b423          	sd	s2,72(s3)
  release(&wait_lock);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	de6080e7          	jalr	-538(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001eba:	854e                	mv	a0,s3
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	d28080e7          	jalr	-728(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ec4:	478d                	li	a5,3
    80001ec6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eca:	854e                	mv	a0,s3
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	dcc080e7          	jalr	-564(ra) # 80000c98 <release>
}
    80001ed4:	8552                	mv	a0,s4
    80001ed6:	70a2                	ld	ra,40(sp)
    80001ed8:	7402                	ld	s0,32(sp)
    80001eda:	64e2                	ld	s1,24(sp)
    80001edc:	6942                	ld	s2,16(sp)
    80001ede:	69a2                	ld	s3,8(sp)
    80001ee0:	6a02                	ld	s4,0(sp)
    80001ee2:	6145                	addi	sp,sp,48
    80001ee4:	8082                	ret
    return -1;
    80001ee6:	5a7d                	li	s4,-1
    80001ee8:	b7f5                	j	80001ed4 <fork+0x126>

0000000080001eea <scheduler_fcfs>:
{
    80001eea:	1141                	addi	sp,sp,-16
    80001eec:	e406                	sd	ra,8(sp)
    80001eee:	e022                	sd	s0,0(sp)
    80001ef0:	0800                	addi	s0,sp,16
  printf("TBD..");
    80001ef2:	00006517          	auipc	a0,0x6
    80001ef6:	34650513          	addi	a0,a0,838 # 80008238 <digits+0x1f8>
    80001efa:	ffffe097          	auipc	ra,0xffffe
    80001efe:	68e080e7          	jalr	1678(ra) # 80000588 <printf>
}
    80001f02:	60a2                	ld	ra,8(sp)
    80001f04:	6402                	ld	s0,0(sp)
    80001f06:	0141                	addi	sp,sp,16
    80001f08:	8082                	ret

0000000080001f0a <sched>:
{
    80001f0a:	7179                	addi	sp,sp,-48
    80001f0c:	f406                	sd	ra,40(sp)
    80001f0e:	f022                	sd	s0,32(sp)
    80001f10:	ec26                	sd	s1,24(sp)
    80001f12:	e84a                	sd	s2,16(sp)
    80001f14:	e44e                	sd	s3,8(sp)
    80001f16:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f18:	00000097          	auipc	ra,0x0
    80001f1c:	ab8080e7          	jalr	-1352(ra) # 800019d0 <myproc>
    80001f20:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	c48080e7          	jalr	-952(ra) # 80000b6a <holding>
    80001f2a:	c93d                	beqz	a0,80001fa0 <sched+0x96>
    80001f2c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f2e:	2781                	sext.w	a5,a5
    80001f30:	079e                	slli	a5,a5,0x7
    80001f32:	0000f717          	auipc	a4,0xf
    80001f36:	37e70713          	addi	a4,a4,894 # 800112b0 <pid_lock>
    80001f3a:	97ba                	add	a5,a5,a4
    80001f3c:	0a87a703          	lw	a4,168(a5)
    80001f40:	4785                	li	a5,1
    80001f42:	06f71763          	bne	a4,a5,80001fb0 <sched+0xa6>
  if(p->state == RUNNING)
    80001f46:	4c98                	lw	a4,24(s1)
    80001f48:	4791                	li	a5,4
    80001f4a:	06f70b63          	beq	a4,a5,80001fc0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f54:	efb5                	bnez	a5,80001fd0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f56:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f58:	0000f917          	auipc	s2,0xf
    80001f5c:	35890913          	addi	s2,s2,856 # 800112b0 <pid_lock>
    80001f60:	2781                	sext.w	a5,a5
    80001f62:	079e                	slli	a5,a5,0x7
    80001f64:	97ca                	add	a5,a5,s2
    80001f66:	0ac7a983          	lw	s3,172(a5)
    80001f6a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f6c:	2781                	sext.w	a5,a5
    80001f6e:	079e                	slli	a5,a5,0x7
    80001f70:	0000f597          	auipc	a1,0xf
    80001f74:	37858593          	addi	a1,a1,888 # 800112e8 <cpus+0x8>
    80001f78:	95be                	add	a1,a1,a5
    80001f7a:	07048513          	addi	a0,s1,112
    80001f7e:	00001097          	auipc	ra,0x1
    80001f82:	8a4080e7          	jalr	-1884(ra) # 80002822 <swtch>
    80001f86:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f88:	2781                	sext.w	a5,a5
    80001f8a:	079e                	slli	a5,a5,0x7
    80001f8c:	97ca                	add	a5,a5,s2
    80001f8e:	0b37a623          	sw	s3,172(a5)
}
    80001f92:	70a2                	ld	ra,40(sp)
    80001f94:	7402                	ld	s0,32(sp)
    80001f96:	64e2                	ld	s1,24(sp)
    80001f98:	6942                	ld	s2,16(sp)
    80001f9a:	69a2                	ld	s3,8(sp)
    80001f9c:	6145                	addi	sp,sp,48
    80001f9e:	8082                	ret
    panic("sched p->lock");
    80001fa0:	00006517          	auipc	a0,0x6
    80001fa4:	2a050513          	addi	a0,a0,672 # 80008240 <digits+0x200>
    80001fa8:	ffffe097          	auipc	ra,0xffffe
    80001fac:	596080e7          	jalr	1430(ra) # 8000053e <panic>
    panic("sched locks");
    80001fb0:	00006517          	auipc	a0,0x6
    80001fb4:	2a050513          	addi	a0,a0,672 # 80008250 <digits+0x210>
    80001fb8:	ffffe097          	auipc	ra,0xffffe
    80001fbc:	586080e7          	jalr	1414(ra) # 8000053e <panic>
    panic("sched running");
    80001fc0:	00006517          	auipc	a0,0x6
    80001fc4:	2a050513          	addi	a0,a0,672 # 80008260 <digits+0x220>
    80001fc8:	ffffe097          	auipc	ra,0xffffe
    80001fcc:	576080e7          	jalr	1398(ra) # 8000053e <panic>
    panic("sched interruptible");
    80001fd0:	00006517          	auipc	a0,0x6
    80001fd4:	2a050513          	addi	a0,a0,672 # 80008270 <digits+0x230>
    80001fd8:	ffffe097          	auipc	ra,0xffffe
    80001fdc:	566080e7          	jalr	1382(ra) # 8000053e <panic>

0000000080001fe0 <yield>:
{
    80001fe0:	1101                	addi	sp,sp,-32
    80001fe2:	ec06                	sd	ra,24(sp)
    80001fe4:	e822                	sd	s0,16(sp)
    80001fe6:	e426                	sd	s1,8(sp)
    80001fe8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001fea:	00000097          	auipc	ra,0x0
    80001fee:	9e6080e7          	jalr	-1562(ra) # 800019d0 <myproc>
    80001ff2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	bf0080e7          	jalr	-1040(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80001ffc:	478d                	li	a5,3
    80001ffe:	cc9c                	sw	a5,24(s1)
  sched();
    80002000:	00000097          	auipc	ra,0x0
    80002004:	f0a080e7          	jalr	-246(ra) # 80001f0a <sched>
  release(&p->lock);
    80002008:	8526                	mv	a0,s1
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	c8e080e7          	jalr	-882(ra) # 80000c98 <release>
}
    80002012:	60e2                	ld	ra,24(sp)
    80002014:	6442                	ld	s0,16(sp)
    80002016:	64a2                	ld	s1,8(sp)
    80002018:	6105                	addi	sp,sp,32
    8000201a:	8082                	ret

000000008000201c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000201c:	7179                	addi	sp,sp,-48
    8000201e:	f406                	sd	ra,40(sp)
    80002020:	f022                	sd	s0,32(sp)
    80002022:	ec26                	sd	s1,24(sp)
    80002024:	e84a                	sd	s2,16(sp)
    80002026:	e44e                	sd	s3,8(sp)
    80002028:	1800                	addi	s0,sp,48
    8000202a:	89aa                	mv	s3,a0
    8000202c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	9a2080e7          	jalr	-1630(ra) # 800019d0 <myproc>
    80002036:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	bac080e7          	jalr	-1108(ra) # 80000be4 <acquire>
  release(lk);
    80002040:	854a                	mv	a0,s2
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c56080e7          	jalr	-938(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000204a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000204e:	4789                	li	a5,2
    80002050:	cc9c                	sw	a5,24(s1)

  sched();
    80002052:	00000097          	auipc	ra,0x0
    80002056:	eb8080e7          	jalr	-328(ra) # 80001f0a <sched>

  // Tidy up.
  p->chan = 0;
    8000205a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000205e:	8526                	mv	a0,s1
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	c38080e7          	jalr	-968(ra) # 80000c98 <release>
  acquire(lk);
    80002068:	854a                	mv	a0,s2
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	b7a080e7          	jalr	-1158(ra) # 80000be4 <acquire>
}
    80002072:	70a2                	ld	ra,40(sp)
    80002074:	7402                	ld	s0,32(sp)
    80002076:	64e2                	ld	s1,24(sp)
    80002078:	6942                	ld	s2,16(sp)
    8000207a:	69a2                	ld	s3,8(sp)
    8000207c:	6145                	addi	sp,sp,48
    8000207e:	8082                	ret

0000000080002080 <wait>:
{
    80002080:	715d                	addi	sp,sp,-80
    80002082:	e486                	sd	ra,72(sp)
    80002084:	e0a2                	sd	s0,64(sp)
    80002086:	fc26                	sd	s1,56(sp)
    80002088:	f84a                	sd	s2,48(sp)
    8000208a:	f44e                	sd	s3,40(sp)
    8000208c:	f052                	sd	s4,32(sp)
    8000208e:	ec56                	sd	s5,24(sp)
    80002090:	e85a                	sd	s6,16(sp)
    80002092:	e45e                	sd	s7,8(sp)
    80002094:	e062                	sd	s8,0(sp)
    80002096:	0880                	addi	s0,sp,80
    80002098:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	936080e7          	jalr	-1738(ra) # 800019d0 <myproc>
    800020a2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020a4:	0000f517          	auipc	a0,0xf
    800020a8:	22450513          	addi	a0,a0,548 # 800112c8 <wait_lock>
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	b38080e7          	jalr	-1224(ra) # 80000be4 <acquire>
    havekids = 0;
    800020b4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020b6:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800020b8:	00015997          	auipc	s3,0x15
    800020bc:	42898993          	addi	s3,s3,1064 # 800174e0 <tickslock>
        havekids = 1;
    800020c0:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020c2:	0000fc17          	auipc	s8,0xf
    800020c6:	206c0c13          	addi	s8,s8,518 # 800112c8 <wait_lock>
    havekids = 0;
    800020ca:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	61448493          	addi	s1,s1,1556 # 800116e0 <proc>
    800020d4:	a0bd                	j	80002142 <wait+0xc2>
          pid = np->pid;
    800020d6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800020da:	000b0e63          	beqz	s6,800020f6 <wait+0x76>
    800020de:	4691                	li	a3,4
    800020e0:	02c48613          	addi	a2,s1,44
    800020e4:	85da                	mv	a1,s6
    800020e6:	06093503          	ld	a0,96(s2)
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	5a8080e7          	jalr	1448(ra) # 80001692 <copyout>
    800020f2:	02054563          	bltz	a0,8000211c <wait+0x9c>
          freeproc(np);
    800020f6:	8526                	mv	a0,s1
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	a8a080e7          	jalr	-1398(ra) # 80001b82 <freeproc>
          release(&np->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	b96080e7          	jalr	-1130(ra) # 80000c98 <release>
          release(&wait_lock);
    8000210a:	0000f517          	auipc	a0,0xf
    8000210e:	1be50513          	addi	a0,a0,446 # 800112c8 <wait_lock>
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	b86080e7          	jalr	-1146(ra) # 80000c98 <release>
          return pid;
    8000211a:	a09d                	j	80002180 <wait+0x100>
            release(&np->lock);
    8000211c:	8526                	mv	a0,s1
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	b7a080e7          	jalr	-1158(ra) # 80000c98 <release>
            release(&wait_lock);
    80002126:	0000f517          	auipc	a0,0xf
    8000212a:	1a250513          	addi	a0,a0,418 # 800112c8 <wait_lock>
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	b6a080e7          	jalr	-1174(ra) # 80000c98 <release>
            return -1;
    80002136:	59fd                	li	s3,-1
    80002138:	a0a1                	j	80002180 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000213a:	17848493          	addi	s1,s1,376
    8000213e:	03348463          	beq	s1,s3,80002166 <wait+0xe6>
      if(np->parent == p){
    80002142:	64bc                	ld	a5,72(s1)
    80002144:	ff279be3          	bne	a5,s2,8000213a <wait+0xba>
        acquire(&np->lock);
    80002148:	8526                	mv	a0,s1
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	a9a080e7          	jalr	-1382(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002152:	4c9c                	lw	a5,24(s1)
    80002154:	f94781e3          	beq	a5,s4,800020d6 <wait+0x56>
        release(&np->lock);
    80002158:	8526                	mv	a0,s1
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	b3e080e7          	jalr	-1218(ra) # 80000c98 <release>
        havekids = 1;
    80002162:	8756                	mv	a4,s5
    80002164:	bfd9                	j	8000213a <wait+0xba>
    if(!havekids || p->killed){
    80002166:	c701                	beqz	a4,8000216e <wait+0xee>
    80002168:	02892783          	lw	a5,40(s2)
    8000216c:	c79d                	beqz	a5,8000219a <wait+0x11a>
      release(&wait_lock);
    8000216e:	0000f517          	auipc	a0,0xf
    80002172:	15a50513          	addi	a0,a0,346 # 800112c8 <wait_lock>
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b22080e7          	jalr	-1246(ra) # 80000c98 <release>
      return -1;
    8000217e:	59fd                	li	s3,-1
}
    80002180:	854e                	mv	a0,s3
    80002182:	60a6                	ld	ra,72(sp)
    80002184:	6406                	ld	s0,64(sp)
    80002186:	74e2                	ld	s1,56(sp)
    80002188:	7942                	ld	s2,48(sp)
    8000218a:	79a2                	ld	s3,40(sp)
    8000218c:	7a02                	ld	s4,32(sp)
    8000218e:	6ae2                	ld	s5,24(sp)
    80002190:	6b42                	ld	s6,16(sp)
    80002192:	6ba2                	ld	s7,8(sp)
    80002194:	6c02                	ld	s8,0(sp)
    80002196:	6161                	addi	sp,sp,80
    80002198:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000219a:	85e2                	mv	a1,s8
    8000219c:	854a                	mv	a0,s2
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	e7e080e7          	jalr	-386(ra) # 8000201c <sleep>
    havekids = 0;
    800021a6:	b715                	j	800020ca <wait+0x4a>

00000000800021a8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021a8:	7139                	addi	sp,sp,-64
    800021aa:	fc06                	sd	ra,56(sp)
    800021ac:	f822                	sd	s0,48(sp)
    800021ae:	f426                	sd	s1,40(sp)
    800021b0:	f04a                	sd	s2,32(sp)
    800021b2:	ec4e                	sd	s3,24(sp)
    800021b4:	e852                	sd	s4,16(sp)
    800021b6:	e456                	sd	s5,8(sp)
    800021b8:	0080                	addi	s0,sp,64
    800021ba:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021bc:	0000f497          	auipc	s1,0xf
    800021c0:	52448493          	addi	s1,s1,1316 # 800116e0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021c4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021c6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021c8:	00015917          	auipc	s2,0x15
    800021cc:	31890913          	addi	s2,s2,792 # 800174e0 <tickslock>
    800021d0:	a821                	j	800021e8 <wakeup+0x40>
        p->state = RUNNABLE;
    800021d2:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800021d6:	8526                	mv	a0,s1
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	ac0080e7          	jalr	-1344(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021e0:	17848493          	addi	s1,s1,376
    800021e4:	03248463          	beq	s1,s2,8000220c <wakeup+0x64>
    if(p != myproc()){
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	7e8080e7          	jalr	2024(ra) # 800019d0 <myproc>
    800021f0:	fea488e3          	beq	s1,a0,800021e0 <wakeup+0x38>
      acquire(&p->lock);
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	9ee080e7          	jalr	-1554(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021fe:	4c9c                	lw	a5,24(s1)
    80002200:	fd379be3          	bne	a5,s3,800021d6 <wakeup+0x2e>
    80002204:	709c                	ld	a5,32(s1)
    80002206:	fd4798e3          	bne	a5,s4,800021d6 <wakeup+0x2e>
    8000220a:	b7e1                	j	800021d2 <wakeup+0x2a>
    }
  }
}
    8000220c:	70e2                	ld	ra,56(sp)
    8000220e:	7442                	ld	s0,48(sp)
    80002210:	74a2                	ld	s1,40(sp)
    80002212:	7902                	ld	s2,32(sp)
    80002214:	69e2                	ld	s3,24(sp)
    80002216:	6a42                	ld	s4,16(sp)
    80002218:	6aa2                	ld	s5,8(sp)
    8000221a:	6121                	addi	sp,sp,64
    8000221c:	8082                	ret

000000008000221e <reparent>:
{
    8000221e:	7179                	addi	sp,sp,-48
    80002220:	f406                	sd	ra,40(sp)
    80002222:	f022                	sd	s0,32(sp)
    80002224:	ec26                	sd	s1,24(sp)
    80002226:	e84a                	sd	s2,16(sp)
    80002228:	e44e                	sd	s3,8(sp)
    8000222a:	e052                	sd	s4,0(sp)
    8000222c:	1800                	addi	s0,sp,48
    8000222e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002230:	0000f497          	auipc	s1,0xf
    80002234:	4b048493          	addi	s1,s1,1200 # 800116e0 <proc>
      pp->parent = initproc;
    80002238:	00007a17          	auipc	s4,0x7
    8000223c:	e00a0a13          	addi	s4,s4,-512 # 80009038 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002240:	00015997          	auipc	s3,0x15
    80002244:	2a098993          	addi	s3,s3,672 # 800174e0 <tickslock>
    80002248:	a029                	j	80002252 <reparent+0x34>
    8000224a:	17848493          	addi	s1,s1,376
    8000224e:	01348d63          	beq	s1,s3,80002268 <reparent+0x4a>
    if(pp->parent == p){
    80002252:	64bc                	ld	a5,72(s1)
    80002254:	ff279be3          	bne	a5,s2,8000224a <reparent+0x2c>
      pp->parent = initproc;
    80002258:	000a3503          	ld	a0,0(s4)
    8000225c:	e4a8                	sd	a0,72(s1)
      wakeup(initproc);
    8000225e:	00000097          	auipc	ra,0x0
    80002262:	f4a080e7          	jalr	-182(ra) # 800021a8 <wakeup>
    80002266:	b7d5                	j	8000224a <reparent+0x2c>
}
    80002268:	70a2                	ld	ra,40(sp)
    8000226a:	7402                	ld	s0,32(sp)
    8000226c:	64e2                	ld	s1,24(sp)
    8000226e:	6942                	ld	s2,16(sp)
    80002270:	69a2                	ld	s3,8(sp)
    80002272:	6a02                	ld	s4,0(sp)
    80002274:	6145                	addi	sp,sp,48
    80002276:	8082                	ret

0000000080002278 <exit>:
{
    80002278:	7179                	addi	sp,sp,-48
    8000227a:	f406                	sd	ra,40(sp)
    8000227c:	f022                	sd	s0,32(sp)
    8000227e:	ec26                	sd	s1,24(sp)
    80002280:	e84a                	sd	s2,16(sp)
    80002282:	e44e                	sd	s3,8(sp)
    80002284:	e052                	sd	s4,0(sp)
    80002286:	1800                	addi	s0,sp,48
    80002288:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	746080e7          	jalr	1862(ra) # 800019d0 <myproc>
    80002292:	89aa                	mv	s3,a0
  if(p == initproc)
    80002294:	00007797          	auipc	a5,0x7
    80002298:	da47b783          	ld	a5,-604(a5) # 80009038 <initproc>
    8000229c:	0e050493          	addi	s1,a0,224
    800022a0:	16050913          	addi	s2,a0,352
    800022a4:	02a79363          	bne	a5,a0,800022ca <exit+0x52>
    panic("init exiting");
    800022a8:	00006517          	auipc	a0,0x6
    800022ac:	fe050513          	addi	a0,a0,-32 # 80008288 <digits+0x248>
    800022b0:	ffffe097          	auipc	ra,0xffffe
    800022b4:	28e080e7          	jalr	654(ra) # 8000053e <panic>
      fileclose(f);
    800022b8:	00002097          	auipc	ra,0x2
    800022bc:	4b6080e7          	jalr	1206(ra) # 8000476e <fileclose>
      p->ofile[fd] = 0;
    800022c0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022c4:	04a1                	addi	s1,s1,8
    800022c6:	01248563          	beq	s1,s2,800022d0 <exit+0x58>
    if(p->ofile[fd]){
    800022ca:	6088                	ld	a0,0(s1)
    800022cc:	f575                	bnez	a0,800022b8 <exit+0x40>
    800022ce:	bfdd                	j	800022c4 <exit+0x4c>
  begin_op();
    800022d0:	00002097          	auipc	ra,0x2
    800022d4:	fd2080e7          	jalr	-46(ra) # 800042a2 <begin_op>
  iput(p->cwd);
    800022d8:	1609b503          	ld	a0,352(s3)
    800022dc:	00001097          	auipc	ra,0x1
    800022e0:	7ae080e7          	jalr	1966(ra) # 80003a8a <iput>
  end_op();
    800022e4:	00002097          	auipc	ra,0x2
    800022e8:	03e080e7          	jalr	62(ra) # 80004322 <end_op>
  p->cwd = 0;
    800022ec:	1609b023          	sd	zero,352(s3)
  acquire(&wait_lock);
    800022f0:	0000f497          	auipc	s1,0xf
    800022f4:	fd848493          	addi	s1,s1,-40 # 800112c8 <wait_lock>
    800022f8:	8526                	mv	a0,s1
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	8ea080e7          	jalr	-1814(ra) # 80000be4 <acquire>
  reparent(p);
    80002302:	854e                	mv	a0,s3
    80002304:	00000097          	auipc	ra,0x0
    80002308:	f1a080e7          	jalr	-230(ra) # 8000221e <reparent>
  wakeup(p->parent);
    8000230c:	0489b503          	ld	a0,72(s3)
    80002310:	00000097          	auipc	ra,0x0
    80002314:	e98080e7          	jalr	-360(ra) # 800021a8 <wakeup>
  acquire(&p->lock);
    80002318:	854e                	mv	a0,s3
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	8ca080e7          	jalr	-1846(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002322:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002326:	4795                	li	a5,5
    80002328:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	96a080e7          	jalr	-1686(ra) # 80000c98 <release>
  sched();
    80002336:	00000097          	auipc	ra,0x0
    8000233a:	bd4080e7          	jalr	-1068(ra) # 80001f0a <sched>
  panic("zombie exit");
    8000233e:	00006517          	auipc	a0,0x6
    80002342:	f5a50513          	addi	a0,a0,-166 # 80008298 <digits+0x258>
    80002346:	ffffe097          	auipc	ra,0xffffe
    8000234a:	1f8080e7          	jalr	504(ra) # 8000053e <panic>

000000008000234e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000234e:	7179                	addi	sp,sp,-48
    80002350:	f406                	sd	ra,40(sp)
    80002352:	f022                	sd	s0,32(sp)
    80002354:	ec26                	sd	s1,24(sp)
    80002356:	e84a                	sd	s2,16(sp)
    80002358:	e44e                	sd	s3,8(sp)
    8000235a:	1800                	addi	s0,sp,48
    8000235c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000235e:	0000f497          	auipc	s1,0xf
    80002362:	38248493          	addi	s1,s1,898 # 800116e0 <proc>
    80002366:	00015997          	auipc	s3,0x15
    8000236a:	17a98993          	addi	s3,s3,378 # 800174e0 <tickslock>
    acquire(&p->lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	874080e7          	jalr	-1932(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002378:	589c                	lw	a5,48(s1)
    8000237a:	01278d63          	beq	a5,s2,80002394 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	918080e7          	jalr	-1768(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002388:	17848493          	addi	s1,s1,376
    8000238c:	ff3491e3          	bne	s1,s3,8000236e <kill+0x20>
  }
  return -1;
    80002390:	557d                	li	a0,-1
    80002392:	a829                	j	800023ac <kill+0x5e>
      p->killed = 1;
    80002394:	4785                	li	a5,1
    80002396:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002398:	4c98                	lw	a4,24(s1)
    8000239a:	4789                	li	a5,2
    8000239c:	00f70f63          	beq	a4,a5,800023ba <kill+0x6c>
      release(&p->lock);
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	8f6080e7          	jalr	-1802(ra) # 80000c98 <release>
      return 0;
    800023aa:	4501                	li	a0,0
}
    800023ac:	70a2                	ld	ra,40(sp)
    800023ae:	7402                	ld	s0,32(sp)
    800023b0:	64e2                	ld	s1,24(sp)
    800023b2:	6942                	ld	s2,16(sp)
    800023b4:	69a2                	ld	s3,8(sp)
    800023b6:	6145                	addi	sp,sp,48
    800023b8:	8082                	ret
        p->state = RUNNABLE;
    800023ba:	478d                	li	a5,3
    800023bc:	cc9c                	sw	a5,24(s1)
    800023be:	b7cd                	j	800023a0 <kill+0x52>

00000000800023c0 <pause_system>:

// Pause all user processes for the number of seconds specified by the second's integer parameter.
int
pause_system(int time)
{
    800023c0:	1141                	addi	sp,sp,-16
    800023c2:	e406                	sd	ra,8(sp)
    800023c4:	e022                	sd	s0,0(sp)
    800023c6:	0800                	addi	s0,sp,16
  // Make running processes RUNNABLE, and after time seconds - continue running. 
  pause_time = 10 * time;   // Pause_time in seconds (1 tick = 1/10 sec).
    800023c8:	0025179b          	slliw	a5,a0,0x2
    800023cc:	9fa9                	addw	a5,a5,a0
    800023ce:	0017979b          	slliw	a5,a5,0x1
    800023d2:	00007717          	auipc	a4,0x7
    800023d6:	c4f72b23          	sw	a5,-938(a4) # 80009028 <pause_time>
  ticks_0 = ticks;
    800023da:	00007797          	auipc	a5,0x7
    800023de:	c667a783          	lw	a5,-922(a5) # 80009040 <ticks>
    800023e2:	00007717          	auipc	a4,0x7
    800023e6:	c4f72523          	sw	a5,-950(a4) # 8000902c <ticks_0>
  yield();                  // Change state to runnable, go to scheduler (via sched()). 
    800023ea:	00000097          	auipc	ra,0x0
    800023ee:	bf6080e7          	jalr	-1034(ra) # 80001fe0 <yield>
  // Question - Is is important that we continue execution from this process? If so, may add another (global) flag..
  return 0;
}
    800023f2:	4501                	li	a0,0
    800023f4:	60a2                	ld	ra,8(sp)
    800023f6:	6402                	ld	s0,0(sp)
    800023f8:	0141                	addi	sp,sp,16
    800023fa:	8082                	ret

00000000800023fc <should_pause>:

// Return 1 if should pause, 0 otherwise.
int
should_pause()
{
    800023fc:	1141                	addi	sp,sp,-16
    800023fe:	e422                	sd	s0,8(sp)
    80002400:	0800                	addi	s0,sp,16
  return (ticks - ticks_0) > pause_time ? 0 : 1;
    80002402:	00007517          	auipc	a0,0x7
    80002406:	c3e52503          	lw	a0,-962(a0) # 80009040 <ticks>
    8000240a:	00007797          	auipc	a5,0x7
    8000240e:	c227a783          	lw	a5,-990(a5) # 8000902c <ticks_0>
    80002412:	9d1d                	subw	a0,a0,a5
    80002414:	00007797          	auipc	a5,0x7
    80002418:	c147a783          	lw	a5,-1004(a5) # 80009028 <pause_time>
    8000241c:	00a7b533          	sltu	a0,a5,a0
    80002420:	00154513          	xori	a0,a0,1
}
    80002424:	2501                	sext.w	a0,a0
    80002426:	6422                	ld	s0,8(sp)
    80002428:	0141                	addi	sp,sp,16
    8000242a:	8082                	ret

000000008000242c <scheduler>:
{
    8000242c:	715d                	addi	sp,sp,-80
    8000242e:	e486                	sd	ra,72(sp)
    80002430:	e0a2                	sd	s0,64(sp)
    80002432:	fc26                	sd	s1,56(sp)
    80002434:	f84a                	sd	s2,48(sp)
    80002436:	f44e                	sd	s3,40(sp)
    80002438:	f052                	sd	s4,32(sp)
    8000243a:	ec56                	sd	s5,24(sp)
    8000243c:	e85a                	sd	s6,16(sp)
    8000243e:	e45e                	sd	s7,8(sp)
    80002440:	e062                	sd	s8,0(sp)
    80002442:	0880                	addi	s0,sp,80
  printf("hello world 2\n");
    80002444:	00006517          	auipc	a0,0x6
    80002448:	e6450513          	addi	a0,a0,-412 # 800082a8 <digits+0x268>
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	13c080e7          	jalr	316(ra) # 80000588 <printf>
    80002454:	8792                	mv	a5,tp
  int id = r_tp();
    80002456:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002458:	00779b93          	slli	s7,a5,0x7
    8000245c:	0000f717          	auipc	a4,0xf
    80002460:	e5470713          	addi	a4,a4,-428 # 800112b0 <pid_lock>
    80002464:	975e                	add	a4,a4,s7
    80002466:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000246a:	0000f717          	auipc	a4,0xf
    8000246e:	e7e70713          	addi	a4,a4,-386 # 800112e8 <cpus+0x8>
    80002472:	9bba                	add	s7,s7,a4
      paused = should_pause(); 
    80002474:	00007a97          	auipc	s5,0x7
    80002478:	bbca8a93          	addi	s5,s5,-1092 # 80009030 <paused>
        p->state = RUNNING;
    8000247c:	4c11                	li	s8,4
        c->proc = p;
    8000247e:	079e                	slli	a5,a5,0x7
    80002480:	0000fb17          	auipc	s6,0xf
    80002484:	e30b0b13          	addi	s6,s6,-464 # 800112b0 <pid_lock>
    80002488:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000248a:	00015a17          	auipc	s4,0x15
    8000248e:	056a0a13          	addi	s4,s4,86 # 800174e0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002492:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002496:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000249a:	10079073          	csrw	sstatus,a5
    8000249e:	0000f497          	auipc	s1,0xf
    800024a2:	24248493          	addi	s1,s1,578 # 800116e0 <proc>
      if(p->state == RUNNABLE && paused==0) {
    800024a6:	498d                	li	s3,3
    800024a8:	a03d                	j	800024d6 <scheduler+0xaa>
        p->state = RUNNING;
    800024aa:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    800024ae:	029b3823          	sd	s1,48(s6)
        swtch(&c->context, &p->context);
    800024b2:	07048593          	addi	a1,s1,112
    800024b6:	855e                	mv	a0,s7
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	36a080e7          	jalr	874(ra) # 80002822 <swtch>
        c->proc = 0;
    800024c0:	020b3823          	sd	zero,48(s6)
      release(&p->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	7d2080e7          	jalr	2002(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800024ce:	17848493          	addi	s1,s1,376
    800024d2:	fd4480e3          	beq	s1,s4,80002492 <scheduler+0x66>
      acquire(&p->lock);
    800024d6:	8526                	mv	a0,s1
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	70c080e7          	jalr	1804(ra) # 80000be4 <acquire>
      paused = should_pause(); 
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	f1c080e7          	jalr	-228(ra) # 800023fc <should_pause>
    800024e8:	00aaa023          	sw	a0,0(s5)
      if(p->state == RUNNABLE && paused==0) {
    800024ec:	4c9c                	lw	a5,24(s1)
    800024ee:	fd379be3          	bne	a5,s3,800024c4 <scheduler+0x98>
    800024f2:	f969                	bnez	a0,800024c4 <scheduler+0x98>
    800024f4:	bf5d                	j	800024aa <scheduler+0x7e>

00000000800024f6 <scheduler_sjf>:
{
    800024f6:	7159                	addi	sp,sp,-112
    800024f8:	f486                	sd	ra,104(sp)
    800024fa:	f0a2                	sd	s0,96(sp)
    800024fc:	eca6                	sd	s1,88(sp)
    800024fe:	e8ca                	sd	s2,80(sp)
    80002500:	e4ce                	sd	s3,72(sp)
    80002502:	e0d2                	sd	s4,64(sp)
    80002504:	fc56                	sd	s5,56(sp)
    80002506:	f85a                	sd	s6,48(sp)
    80002508:	f45e                	sd	s7,40(sp)
    8000250a:	f062                	sd	s8,32(sp)
    8000250c:	ec66                	sd	s9,24(sp)
    8000250e:	e86a                	sd	s10,16(sp)
    80002510:	e46e                	sd	s11,8(sp)
    80002512:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    80002514:	8792                	mv	a5,tp
  int id = r_tp();
    80002516:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002518:	00779c93          	slli	s9,a5,0x7
    8000251c:	0000f717          	auipc	a4,0xf
    80002520:	d9470713          	addi	a4,a4,-620 # 800112b0 <pid_lock>
    80002524:	9766                	add	a4,a4,s9
    80002526:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &co->context);
    8000252a:	0000f717          	auipc	a4,0xf
    8000252e:	dbe70713          	addi	a4,a4,-578 # 800112e8 <cpus+0x8>
    80002532:	9cba                	add	s9,s9,a4
  int min_mean_ticks = __INT_MAX__;   // Large initial number.
    80002534:	80000a37          	lui	s4,0x80000
    80002538:	fffa4a13          	not	s4,s4
  struct proc *co = 0;
    8000253c:	4a81                	li	s5,0
        printf("proc %d: has mean ticks of: %d\n", p->pid, p->mean_ticks);
    8000253e:	00006b17          	auipc	s6,0x6
    80002542:	d7ab0b13          	addi	s6,s6,-646 # 800082b8 <digits+0x278>
    for(p = proc; p < &proc[NPROC]; p++){
    80002546:	00015997          	auipc	s3,0x15
    8000254a:	f9a98993          	addi	s3,s3,-102 # 800174e0 <tickslock>
        p->state = RUNNING;
    8000254e:	00015d97          	auipc	s11,0x15
    80002552:	192d8d93          	addi	s11,s11,402 # 800176e0 <bcache+0x1e8>
        c->proc = co;
    80002556:	079e                	slli	a5,a5,0x7
    80002558:	0000fb97          	auipc	s7,0xf
    8000255c:	d58b8b93          	addi	s7,s7,-680 # 800112b0 <pid_lock>
    80002560:	9bbe                	add	s7,s7,a5
        co->ticks_start = ticks;
    80002562:	00007c17          	auipc	s8,0x7
    80002566:	adec0c13          	addi	s8,s8,-1314 # 80009040 <ticks>
        co->mean_ticks = ((10-rate)*co->mean_ticks + co->last_ticks*rate)/10;
    8000256a:	00006d17          	auipc	s10,0x6
    8000256e:	34ad0d13          	addi	s10,s10,842 # 800088b4 <rate>
    80002572:	a8f1                	j	8000264e <scheduler_sjf+0x158>
        printf("proc %d: has mean ticks of: %d\n", p->pid, p->mean_ticks);
    80002574:	588c                	lw	a1,48(s1)
    80002576:	855a                	mv	a0,s6
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	010080e7          	jalr	16(ra) # 80000588 <printf>
	      min_mean_ticks = p->mean_ticks;
    80002580:	0344aa03          	lw	s4,52(s1)
    80002584:	8aa6                	mv	s5,s1
      release(&p->lock);
    80002586:	8526                	mv	a0,s1
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	710080e7          	jalr	1808(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++){
    80002590:	17848493          	addi	s1,s1,376
    80002594:	01348e63          	beq	s1,s3,800025b0 <scheduler_sjf+0xba>
      acquire(&p->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	64a080e7          	jalr	1610(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && (p->mean_ticks < min_mean_ticks)){
    800025a2:	4c9c                	lw	a5,24(s1)
    800025a4:	ff2791e3          	bne	a5,s2,80002586 <scheduler_sjf+0x90>
    800025a8:	58d0                	lw	a2,52(s1)
    800025aa:	fd465ee3          	bge	a2,s4,80002586 <scheduler_sjf+0x90>
    800025ae:	b7d9                	j	80002574 <scheduler_sjf+0x7e>
    if(co != 0){
    800025b0:	080a8f63          	beqz	s5,8000264e <scheduler_sjf+0x158>
      acquire(&co->lock);
    800025b4:	84d6                	mv	s1,s5
    800025b6:	8556                	mv	a0,s5
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	62c080e7          	jalr	1580(ra) # 80000be4 <acquire>
      if(co->state==RUNNABLE){
    800025c0:	018aa703          	lw	a4,24(s5)
    800025c4:	478d                	li	a5,3
    800025c6:	06f71f63          	bne	a4,a5,80002644 <scheduler_sjf+0x14e>
        p->state = RUNNING;
    800025ca:	4791                	li	a5,4
    800025cc:	e0fdac23          	sw	a5,-488(s11)
        c->proc = co;
    800025d0:	035bb823          	sd	s5,48(s7)
        co->ticks_start = ticks;
    800025d4:	000c2783          	lw	a5,0(s8)
    800025d8:	02faae23          	sw	a5,60(s5)
        printf("proc switch: %d\n", co->pid);
    800025dc:	030aa583          	lw	a1,48(s5)
    800025e0:	00006517          	auipc	a0,0x6
    800025e4:	cf850513          	addi	a0,a0,-776 # 800082d8 <digits+0x298>
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	fa0080e7          	jalr	-96(ra) # 80000588 <printf>
        swtch(&c->context, &co->context);
    800025f0:	070a8593          	addi	a1,s5,112
    800025f4:	8566                	mv	a0,s9
    800025f6:	00000097          	auipc	ra,0x0
    800025fa:	22c080e7          	jalr	556(ra) # 80002822 <swtch>
        printf("proc got out from switch: %d\n", co->pid);
    800025fe:	030aa583          	lw	a1,48(s5)
    80002602:	00006517          	auipc	a0,0x6
    80002606:	cee50513          	addi	a0,a0,-786 # 800082f0 <digits+0x2b0>
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	f7e080e7          	jalr	-130(ra) # 80000588 <printf>
        co->last_ticks = ticks - co->ticks_start;
    80002612:	000c2703          	lw	a4,0(s8)
    80002616:	03caa783          	lw	a5,60(s5)
    8000261a:	9f1d                	subw	a4,a4,a5
    8000261c:	02eaac23          	sw	a4,56(s5)
        co->mean_ticks = ((10-rate)*co->mean_ticks + co->last_ticks*rate)/10;
    80002620:	000d2603          	lw	a2,0(s10)
    80002624:	46a9                	li	a3,10
    80002626:	40c687bb          	subw	a5,a3,a2
    8000262a:	034aa583          	lw	a1,52(s5)
    8000262e:	02b787bb          	mulw	a5,a5,a1
    80002632:	02c7073b          	mulw	a4,a4,a2
    80002636:	9fb9                	addw	a5,a5,a4
    80002638:	02d7c7bb          	divw	a5,a5,a3
    8000263c:	02faaa23          	sw	a5,52(s5)
        c->proc = 0;
    80002640:	020bb823          	sd	zero,48(s7)
      release(&co->lock);
    80002644:	8526                	mv	a0,s1
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	652080e7          	jalr	1618(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000264e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002652:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002656:	10079073          	csrw	sstatus,a5
    while(should_pause()==1){
    8000265a:	00000097          	auipc	ra,0x0
    8000265e:	da2080e7          	jalr	-606(ra) # 800023fc <should_pause>
    80002662:	4785                	li	a5,1
    80002664:	00f50063          	beq	a0,a5,80002664 <scheduler_sjf+0x16e>
    for(p = proc; p < &proc[NPROC]; p++){
    80002668:	0000f497          	auipc	s1,0xf
    8000266c:	07848493          	addi	s1,s1,120 # 800116e0 <proc>
      if(p->state == RUNNABLE && (p->mean_ticks < min_mean_ticks)){
    80002670:	490d                	li	s2,3
    80002672:	b71d                	j	80002598 <scheduler_sjf+0xa2>

0000000080002674 <kill_system>:

// Kill all processes, except the init process (pid=???) and the shell process(pid=???).
int
kill_system(void)
{
    80002674:	7179                	addi	sp,sp,-48
    80002676:	f406                	sd	ra,40(sp)
    80002678:	f022                	sd	s0,32(sp)
    8000267a:	ec26                	sd	s1,24(sp)
    8000267c:	e84a                	sd	s2,16(sp)
    8000267e:	e44e                	sd	s3,8(sp)
    80002680:	1800                	addi	s0,sp,48
  int init_proc_pid = 1;
  int shell_proc_pid = 2;
  
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++){
    80002682:	0000f497          	auipc	s1,0xf
    80002686:	05e48493          	addi	s1,s1,94 # 800116e0 <proc>
    if ((p->pid != init_proc_pid) && (p->pid != shell_proc_pid)){
    8000268a:	4905                	li	s2,1
  for (p = proc; p < &proc[NPROC]; p++){
    8000268c:	00015997          	auipc	s3,0x15
    80002690:	e5498993          	addi	s3,s3,-428 # 800174e0 <tickslock>
    80002694:	a029                	j	8000269e <kill_system+0x2a>
    80002696:	17848493          	addi	s1,s1,376
    8000269a:	03348563          	beq	s1,s3,800026c4 <kill_system+0x50>
    if ((p->pid != init_proc_pid) && (p->pid != shell_proc_pid)){
    8000269e:	5888                	lw	a0,48(s1)
    800026a0:	fff5079b          	addiw	a5,a0,-1
    800026a4:	fef979e3          	bgeu	s2,a5,80002696 <kill_system+0x22>
      if (kill(p->pid) < 0)
    800026a8:	00000097          	auipc	ra,0x0
    800026ac:	ca6080e7          	jalr	-858(ra) # 8000234e <kill>
    800026b0:	fe0553e3          	bgez	a0,80002696 <kill_system+0x22>
        return -1;
    800026b4:	557d                	li	a0,-1
    }
  }
  return 0;
}
    800026b6:	70a2                	ld	ra,40(sp)
    800026b8:	7402                	ld	s0,32(sp)
    800026ba:	64e2                	ld	s1,24(sp)
    800026bc:	6942                	ld	s2,16(sp)
    800026be:	69a2                	ld	s3,8(sp)
    800026c0:	6145                	addi	sp,sp,48
    800026c2:	8082                	ret
  return 0;
    800026c4:	4501                	li	a0,0
    800026c6:	bfc5                	j	800026b6 <kill_system+0x42>

00000000800026c8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026c8:	7179                	addi	sp,sp,-48
    800026ca:	f406                	sd	ra,40(sp)
    800026cc:	f022                	sd	s0,32(sp)
    800026ce:	ec26                	sd	s1,24(sp)
    800026d0:	e84a                	sd	s2,16(sp)
    800026d2:	e44e                	sd	s3,8(sp)
    800026d4:	e052                	sd	s4,0(sp)
    800026d6:	1800                	addi	s0,sp,48
    800026d8:	84aa                	mv	s1,a0
    800026da:	892e                	mv	s2,a1
    800026dc:	89b2                	mv	s3,a2
    800026de:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026e0:	fffff097          	auipc	ra,0xfffff
    800026e4:	2f0080e7          	jalr	752(ra) # 800019d0 <myproc>
  if(user_dst){
    800026e8:	c08d                	beqz	s1,8000270a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026ea:	86d2                	mv	a3,s4
    800026ec:	864e                	mv	a2,s3
    800026ee:	85ca                	mv	a1,s2
    800026f0:	7128                	ld	a0,96(a0)
    800026f2:	fffff097          	auipc	ra,0xfffff
    800026f6:	fa0080e7          	jalr	-96(ra) # 80001692 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026fa:	70a2                	ld	ra,40(sp)
    800026fc:	7402                	ld	s0,32(sp)
    800026fe:	64e2                	ld	s1,24(sp)
    80002700:	6942                	ld	s2,16(sp)
    80002702:	69a2                	ld	s3,8(sp)
    80002704:	6a02                	ld	s4,0(sp)
    80002706:	6145                	addi	sp,sp,48
    80002708:	8082                	ret
    memmove((char *)dst, src, len);
    8000270a:	000a061b          	sext.w	a2,s4
    8000270e:	85ce                	mv	a1,s3
    80002710:	854a                	mv	a0,s2
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	62e080e7          	jalr	1582(ra) # 80000d40 <memmove>
    return 0;
    8000271a:	8526                	mv	a0,s1
    8000271c:	bff9                	j	800026fa <either_copyout+0x32>

000000008000271e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000271e:	7179                	addi	sp,sp,-48
    80002720:	f406                	sd	ra,40(sp)
    80002722:	f022                	sd	s0,32(sp)
    80002724:	ec26                	sd	s1,24(sp)
    80002726:	e84a                	sd	s2,16(sp)
    80002728:	e44e                	sd	s3,8(sp)
    8000272a:	e052                	sd	s4,0(sp)
    8000272c:	1800                	addi	s0,sp,48
    8000272e:	892a                	mv	s2,a0
    80002730:	84ae                	mv	s1,a1
    80002732:	89b2                	mv	s3,a2
    80002734:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002736:	fffff097          	auipc	ra,0xfffff
    8000273a:	29a080e7          	jalr	666(ra) # 800019d0 <myproc>
  if(user_src){
    8000273e:	c08d                	beqz	s1,80002760 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002740:	86d2                	mv	a3,s4
    80002742:	864e                	mv	a2,s3
    80002744:	85ca                	mv	a1,s2
    80002746:	7128                	ld	a0,96(a0)
    80002748:	fffff097          	auipc	ra,0xfffff
    8000274c:	fd6080e7          	jalr	-42(ra) # 8000171e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002750:	70a2                	ld	ra,40(sp)
    80002752:	7402                	ld	s0,32(sp)
    80002754:	64e2                	ld	s1,24(sp)
    80002756:	6942                	ld	s2,16(sp)
    80002758:	69a2                	ld	s3,8(sp)
    8000275a:	6a02                	ld	s4,0(sp)
    8000275c:	6145                	addi	sp,sp,48
    8000275e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002760:	000a061b          	sext.w	a2,s4
    80002764:	85ce                	mv	a1,s3
    80002766:	854a                	mv	a0,s2
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	5d8080e7          	jalr	1496(ra) # 80000d40 <memmove>
    return 0;
    80002770:	8526                	mv	a0,s1
    80002772:	bff9                	j	80002750 <either_copyin+0x32>

0000000080002774 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002774:	715d                	addi	sp,sp,-80
    80002776:	e486                	sd	ra,72(sp)
    80002778:	e0a2                	sd	s0,64(sp)
    8000277a:	fc26                	sd	s1,56(sp)
    8000277c:	f84a                	sd	s2,48(sp)
    8000277e:	f44e                	sd	s3,40(sp)
    80002780:	f052                	sd	s4,32(sp)
    80002782:	ec56                	sd	s5,24(sp)
    80002784:	e85a                	sd	s6,16(sp)
    80002786:	e45e                	sd	s7,8(sp)
    80002788:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000278a:	00006517          	auipc	a0,0x6
    8000278e:	93e50513          	addi	a0,a0,-1730 # 800080c8 <digits+0x88>
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	df6080e7          	jalr	-522(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000279a:	0000f497          	auipc	s1,0xf
    8000279e:	0ae48493          	addi	s1,s1,174 # 80011848 <proc+0x168>
    800027a2:	00015917          	auipc	s2,0x15
    800027a6:	ea690913          	addi	s2,s2,-346 # 80017648 <bcache+0x150>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027aa:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027ac:	00006997          	auipc	s3,0x6
    800027b0:	b6498993          	addi	s3,s3,-1180 # 80008310 <digits+0x2d0>
    printf("%d %s %s", p->pid, state, p->name);
    800027b4:	00006a97          	auipc	s5,0x6
    800027b8:	b64a8a93          	addi	s5,s5,-1180 # 80008318 <digits+0x2d8>
    printf("\n");
    800027bc:	00006a17          	auipc	s4,0x6
    800027c0:	90ca0a13          	addi	s4,s4,-1780 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c4:	00006b97          	auipc	s7,0x6
    800027c8:	b8cb8b93          	addi	s7,s7,-1140 # 80008350 <states.1760>
    800027cc:	a00d                	j	800027ee <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027ce:	ec86a583          	lw	a1,-312(a3)
    800027d2:	8556                	mv	a0,s5
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	db4080e7          	jalr	-588(ra) # 80000588 <printf>
    printf("\n");
    800027dc:	8552                	mv	a0,s4
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	daa080e7          	jalr	-598(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027e6:	17848493          	addi	s1,s1,376
    800027ea:	03248163          	beq	s1,s2,8000280c <procdump+0x98>
    if(p->state == UNUSED)
    800027ee:	86a6                	mv	a3,s1
    800027f0:	eb04a783          	lw	a5,-336(s1)
    800027f4:	dbed                	beqz	a5,800027e6 <procdump+0x72>
      state = "???";
    800027f6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027f8:	fcfb6be3          	bltu	s6,a5,800027ce <procdump+0x5a>
    800027fc:	1782                	slli	a5,a5,0x20
    800027fe:	9381                	srli	a5,a5,0x20
    80002800:	078e                	slli	a5,a5,0x3
    80002802:	97de                	add	a5,a5,s7
    80002804:	6390                	ld	a2,0(a5)
    80002806:	f661                	bnez	a2,800027ce <procdump+0x5a>
      state = "???";
    80002808:	864e                	mv	a2,s3
    8000280a:	b7d1                	j	800027ce <procdump+0x5a>
  }
}
    8000280c:	60a6                	ld	ra,72(sp)
    8000280e:	6406                	ld	s0,64(sp)
    80002810:	74e2                	ld	s1,56(sp)
    80002812:	7942                	ld	s2,48(sp)
    80002814:	79a2                	ld	s3,40(sp)
    80002816:	7a02                	ld	s4,32(sp)
    80002818:	6ae2                	ld	s5,24(sp)
    8000281a:	6b42                	ld	s6,16(sp)
    8000281c:	6ba2                	ld	s7,8(sp)
    8000281e:	6161                	addi	sp,sp,80
    80002820:	8082                	ret

0000000080002822 <swtch>:
    80002822:	00153023          	sd	ra,0(a0)
    80002826:	00253423          	sd	sp,8(a0)
    8000282a:	e900                	sd	s0,16(a0)
    8000282c:	ed04                	sd	s1,24(a0)
    8000282e:	03253023          	sd	s2,32(a0)
    80002832:	03353423          	sd	s3,40(a0)
    80002836:	03453823          	sd	s4,48(a0)
    8000283a:	03553c23          	sd	s5,56(a0)
    8000283e:	05653023          	sd	s6,64(a0)
    80002842:	05753423          	sd	s7,72(a0)
    80002846:	05853823          	sd	s8,80(a0)
    8000284a:	05953c23          	sd	s9,88(a0)
    8000284e:	07a53023          	sd	s10,96(a0)
    80002852:	07b53423          	sd	s11,104(a0)
    80002856:	0005b083          	ld	ra,0(a1)
    8000285a:	0085b103          	ld	sp,8(a1)
    8000285e:	6980                	ld	s0,16(a1)
    80002860:	6d84                	ld	s1,24(a1)
    80002862:	0205b903          	ld	s2,32(a1)
    80002866:	0285b983          	ld	s3,40(a1)
    8000286a:	0305ba03          	ld	s4,48(a1)
    8000286e:	0385ba83          	ld	s5,56(a1)
    80002872:	0405bb03          	ld	s6,64(a1)
    80002876:	0485bb83          	ld	s7,72(a1)
    8000287a:	0505bc03          	ld	s8,80(a1)
    8000287e:	0585bc83          	ld	s9,88(a1)
    80002882:	0605bd03          	ld	s10,96(a1)
    80002886:	0685bd83          	ld	s11,104(a1)
    8000288a:	8082                	ret

000000008000288c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000288c:	1141                	addi	sp,sp,-16
    8000288e:	e406                	sd	ra,8(sp)
    80002890:	e022                	sd	s0,0(sp)
    80002892:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002894:	00006597          	auipc	a1,0x6
    80002898:	aec58593          	addi	a1,a1,-1300 # 80008380 <states.1760+0x30>
    8000289c:	00015517          	auipc	a0,0x15
    800028a0:	c4450513          	addi	a0,a0,-956 # 800174e0 <tickslock>
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	2b0080e7          	jalr	688(ra) # 80000b54 <initlock>
}
    800028ac:	60a2                	ld	ra,8(sp)
    800028ae:	6402                	ld	s0,0(sp)
    800028b0:	0141                	addi	sp,sp,16
    800028b2:	8082                	ret

00000000800028b4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028b4:	1141                	addi	sp,sp,-16
    800028b6:	e422                	sd	s0,8(sp)
    800028b8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ba:	00003797          	auipc	a5,0x3
    800028be:	4d678793          	addi	a5,a5,1238 # 80005d90 <kernelvec>
    800028c2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028c6:	6422                	ld	s0,8(sp)
    800028c8:	0141                	addi	sp,sp,16
    800028ca:	8082                	ret

00000000800028cc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028cc:	1141                	addi	sp,sp,-16
    800028ce:	e406                	sd	ra,8(sp)
    800028d0:	e022                	sd	s0,0(sp)
    800028d2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028d4:	fffff097          	auipc	ra,0xfffff
    800028d8:	0fc080e7          	jalr	252(ra) # 800019d0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028e0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028e6:	00004617          	auipc	a2,0x4
    800028ea:	71a60613          	addi	a2,a2,1818 # 80007000 <_trampoline>
    800028ee:	00004697          	auipc	a3,0x4
    800028f2:	71268693          	addi	a3,a3,1810 # 80007000 <_trampoline>
    800028f6:	8e91                	sub	a3,a3,a2
    800028f8:	040007b7          	lui	a5,0x4000
    800028fc:	17fd                	addi	a5,a5,-1
    800028fe:	07b2                	slli	a5,a5,0xc
    80002900:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002902:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002906:	7538                	ld	a4,104(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002908:	180026f3          	csrr	a3,satp
    8000290c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000290e:	7538                	ld	a4,104(a0)
    80002910:	6934                	ld	a3,80(a0)
    80002912:	6585                	lui	a1,0x1
    80002914:	96ae                	add	a3,a3,a1
    80002916:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002918:	7538                	ld	a4,104(a0)
    8000291a:	00000697          	auipc	a3,0x0
    8000291e:	13868693          	addi	a3,a3,312 # 80002a52 <usertrap>
    80002922:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002924:	7538                	ld	a4,104(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002926:	8692                	mv	a3,tp
    80002928:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000292e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002932:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002936:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000293a:	7538                	ld	a4,104(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000293c:	6f18                	ld	a4,24(a4)
    8000293e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002942:	712c                	ld	a1,96(a0)
    80002944:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002946:	00004717          	auipc	a4,0x4
    8000294a:	74a70713          	addi	a4,a4,1866 # 80007090 <userret>
    8000294e:	8f11                	sub	a4,a4,a2
    80002950:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002952:	577d                	li	a4,-1
    80002954:	177e                	slli	a4,a4,0x3f
    80002956:	8dd9                	or	a1,a1,a4
    80002958:	02000537          	lui	a0,0x2000
    8000295c:	157d                	addi	a0,a0,-1
    8000295e:	0536                	slli	a0,a0,0xd
    80002960:	9782                	jalr	a5
}
    80002962:	60a2                	ld	ra,8(sp)
    80002964:	6402                	ld	s0,0(sp)
    80002966:	0141                	addi	sp,sp,16
    80002968:	8082                	ret

000000008000296a <clockintr>:
  //printf("End kernel trap\n");
}

void
clockintr()
{
    8000296a:	1101                	addi	sp,sp,-32
    8000296c:	ec06                	sd	ra,24(sp)
    8000296e:	e822                	sd	s0,16(sp)
    80002970:	e426                	sd	s1,8(sp)
    80002972:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002974:	00015497          	auipc	s1,0x15
    80002978:	b6c48493          	addi	s1,s1,-1172 # 800174e0 <tickslock>
    8000297c:	8526                	mv	a0,s1
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	266080e7          	jalr	614(ra) # 80000be4 <acquire>
  ticks++;
    80002986:	00006517          	auipc	a0,0x6
    8000298a:	6ba50513          	addi	a0,a0,1722 # 80009040 <ticks>
    8000298e:	411c                	lw	a5,0(a0)
    80002990:	2785                	addiw	a5,a5,1
    80002992:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002994:	00000097          	auipc	ra,0x0
    80002998:	814080e7          	jalr	-2028(ra) # 800021a8 <wakeup>
  release(&tickslock);
    8000299c:	8526                	mv	a0,s1
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	2fa080e7          	jalr	762(ra) # 80000c98 <release>
}
    800029a6:	60e2                	ld	ra,24(sp)
    800029a8:	6442                	ld	s0,16(sp)
    800029aa:	64a2                	ld	s1,8(sp)
    800029ac:	6105                	addi	sp,sp,32
    800029ae:	8082                	ret

00000000800029b0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029b0:	1101                	addi	sp,sp,-32
    800029b2:	ec06                	sd	ra,24(sp)
    800029b4:	e822                	sd	s0,16(sp)
    800029b6:	e426                	sd	s1,8(sp)
    800029b8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ba:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029be:	00074d63          	bltz	a4,800029d8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029c2:	57fd                	li	a5,-1
    800029c4:	17fe                	slli	a5,a5,0x3f
    800029c6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029c8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029ca:	06f70363          	beq	a4,a5,80002a30 <devintr+0x80>
  }
}
    800029ce:	60e2                	ld	ra,24(sp)
    800029d0:	6442                	ld	s0,16(sp)
    800029d2:	64a2                	ld	s1,8(sp)
    800029d4:	6105                	addi	sp,sp,32
    800029d6:	8082                	ret
     (scause & 0xff) == 9){
    800029d8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029dc:	46a5                	li	a3,9
    800029de:	fed792e3          	bne	a5,a3,800029c2 <devintr+0x12>
    int irq = plic_claim();
    800029e2:	00003097          	auipc	ra,0x3
    800029e6:	4b6080e7          	jalr	1206(ra) # 80005e98 <plic_claim>
    800029ea:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029ec:	47a9                	li	a5,10
    800029ee:	02f50763          	beq	a0,a5,80002a1c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029f2:	4785                	li	a5,1
    800029f4:	02f50963          	beq	a0,a5,80002a26 <devintr+0x76>
    return 1;
    800029f8:	4505                	li	a0,1
    } else if(irq){
    800029fa:	d8f1                	beqz	s1,800029ce <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029fc:	85a6                	mv	a1,s1
    800029fe:	00006517          	auipc	a0,0x6
    80002a02:	98a50513          	addi	a0,a0,-1654 # 80008388 <states.1760+0x38>
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	b82080e7          	jalr	-1150(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a0e:	8526                	mv	a0,s1
    80002a10:	00003097          	auipc	ra,0x3
    80002a14:	4ac080e7          	jalr	1196(ra) # 80005ebc <plic_complete>
    return 1;
    80002a18:	4505                	li	a0,1
    80002a1a:	bf55                	j	800029ce <devintr+0x1e>
      uartintr();
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	f8c080e7          	jalr	-116(ra) # 800009a8 <uartintr>
    80002a24:	b7ed                	j	80002a0e <devintr+0x5e>
      virtio_disk_intr();
    80002a26:	00004097          	auipc	ra,0x4
    80002a2a:	976080e7          	jalr	-1674(ra) # 8000639c <virtio_disk_intr>
    80002a2e:	b7c5                	j	80002a0e <devintr+0x5e>
    if(cpuid() == 0){
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	f74080e7          	jalr	-140(ra) # 800019a4 <cpuid>
    80002a38:	c901                	beqz	a0,80002a48 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a3a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a3e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a40:	14479073          	csrw	sip,a5
    return 2;
    80002a44:	4509                	li	a0,2
    80002a46:	b761                	j	800029ce <devintr+0x1e>
      clockintr();
    80002a48:	00000097          	auipc	ra,0x0
    80002a4c:	f22080e7          	jalr	-222(ra) # 8000296a <clockintr>
    80002a50:	b7ed                	j	80002a3a <devintr+0x8a>

0000000080002a52 <usertrap>:
{
    80002a52:	1101                	addi	sp,sp,-32
    80002a54:	ec06                	sd	ra,24(sp)
    80002a56:	e822                	sd	s0,16(sp)
    80002a58:	e426                	sd	s1,8(sp)
    80002a5a:	e04a                	sd	s2,0(sp)
    80002a5c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a62:	1007f793          	andi	a5,a5,256
    80002a66:	e3ad                	bnez	a5,80002ac8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a68:	00003797          	auipc	a5,0x3
    80002a6c:	32878793          	addi	a5,a5,808 # 80005d90 <kernelvec>
    80002a70:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	f5c080e7          	jalr	-164(ra) # 800019d0 <myproc>
    80002a7c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a7e:	753c                	ld	a5,104(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a80:	14102773          	csrr	a4,sepc
    80002a84:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a86:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a8a:	47a1                	li	a5,8
    80002a8c:	04f71c63          	bne	a4,a5,80002ae4 <usertrap+0x92>
    if(p->killed)
    80002a90:	551c                	lw	a5,40(a0)
    80002a92:	e3b9                	bnez	a5,80002ad8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a94:	74b8                	ld	a4,104(s1)
    80002a96:	6f1c                	ld	a5,24(a4)
    80002a98:	0791                	addi	a5,a5,4
    80002a9a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002aa0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aa4:	10079073          	csrw	sstatus,a5
    syscall();
    80002aa8:	00000097          	auipc	ra,0x0
    80002aac:	2e0080e7          	jalr	736(ra) # 80002d88 <syscall>
  if(p->killed)
    80002ab0:	549c                	lw	a5,40(s1)
    80002ab2:	ebc1                	bnez	a5,80002b42 <usertrap+0xf0>
  usertrapret();
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	e18080e7          	jalr	-488(ra) # 800028cc <usertrapret>
}
    80002abc:	60e2                	ld	ra,24(sp)
    80002abe:	6442                	ld	s0,16(sp)
    80002ac0:	64a2                	ld	s1,8(sp)
    80002ac2:	6902                	ld	s2,0(sp)
    80002ac4:	6105                	addi	sp,sp,32
    80002ac6:	8082                	ret
    panic("usertrap: not from user mode");
    80002ac8:	00006517          	auipc	a0,0x6
    80002acc:	8e050513          	addi	a0,a0,-1824 # 800083a8 <states.1760+0x58>
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	a6e080e7          	jalr	-1426(ra) # 8000053e <panic>
      exit(-1);
    80002ad8:	557d                	li	a0,-1
    80002ada:	fffff097          	auipc	ra,0xfffff
    80002ade:	79e080e7          	jalr	1950(ra) # 80002278 <exit>
    80002ae2:	bf4d                	j	80002a94 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ae4:	00000097          	auipc	ra,0x0
    80002ae8:	ecc080e7          	jalr	-308(ra) # 800029b0 <devintr>
    80002aec:	892a                	mv	s2,a0
    80002aee:	c501                	beqz	a0,80002af6 <usertrap+0xa4>
  if(p->killed)
    80002af0:	549c                	lw	a5,40(s1)
    80002af2:	c3a1                	beqz	a5,80002b32 <usertrap+0xe0>
    80002af4:	a815                	j	80002b28 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002af6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002afa:	5890                	lw	a2,48(s1)
    80002afc:	00006517          	auipc	a0,0x6
    80002b00:	8cc50513          	addi	a0,a0,-1844 # 800083c8 <states.1760+0x78>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	a84080e7          	jalr	-1404(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b0c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b10:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	8e450513          	addi	a0,a0,-1820 # 800083f8 <states.1760+0xa8>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a6c080e7          	jalr	-1428(ra) # 80000588 <printf>
    p->killed = 1;
    80002b24:	4785                	li	a5,1
    80002b26:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b28:	557d                	li	a0,-1
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	74e080e7          	jalr	1870(ra) # 80002278 <exit>
  if(which_dev == 2)
    80002b32:	4789                	li	a5,2
    80002b34:	f8f910e3          	bne	s2,a5,80002ab4 <usertrap+0x62>
    yield();
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	4a8080e7          	jalr	1192(ra) # 80001fe0 <yield>
    80002b40:	bf95                	j	80002ab4 <usertrap+0x62>
  int which_dev = 0;
    80002b42:	4901                	li	s2,0
    80002b44:	b7d5                	j	80002b28 <usertrap+0xd6>

0000000080002b46 <kerneltrap>:
{
    80002b46:	7179                	addi	sp,sp,-48
    80002b48:	f406                	sd	ra,40(sp)
    80002b4a:	f022                	sd	s0,32(sp)
    80002b4c:	ec26                	sd	s1,24(sp)
    80002b4e:	e84a                	sd	s2,16(sp)
    80002b50:	e44e                	sd	s3,8(sp)
    80002b52:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b54:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b58:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b60:	1004f793          	andi	a5,s1,256
    80002b64:	cb85                	beqz	a5,80002b94 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b66:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b6a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b6c:	ef85                	bnez	a5,80002ba4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	e42080e7          	jalr	-446(ra) # 800029b0 <devintr>
    80002b76:	cd1d                	beqz	a0,80002bb4 <kerneltrap+0x6e>
  if((which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING))
    80002b78:	4789                	li	a5,2
    80002b7a:	06f50a63          	beq	a0,a5,80002bee <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b7e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b82:	10049073          	csrw	sstatus,s1
}
    80002b86:	70a2                	ld	ra,40(sp)
    80002b88:	7402                	ld	s0,32(sp)
    80002b8a:	64e2                	ld	s1,24(sp)
    80002b8c:	6942                	ld	s2,16(sp)
    80002b8e:	69a2                	ld	s3,8(sp)
    80002b90:	6145                	addi	sp,sp,48
    80002b92:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b94:	00006517          	auipc	a0,0x6
    80002b98:	88450513          	addi	a0,a0,-1916 # 80008418 <states.1760+0xc8>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	9a2080e7          	jalr	-1630(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ba4:	00006517          	auipc	a0,0x6
    80002ba8:	89c50513          	addi	a0,a0,-1892 # 80008440 <states.1760+0xf0>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	992080e7          	jalr	-1646(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002bb4:	85ce                	mv	a1,s3
    80002bb6:	00006517          	auipc	a0,0x6
    80002bba:	8aa50513          	addi	a0,a0,-1878 # 80008460 <states.1760+0x110>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	9ca080e7          	jalr	-1590(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bca:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bce:	00006517          	auipc	a0,0x6
    80002bd2:	8a250513          	addi	a0,a0,-1886 # 80008470 <states.1760+0x120>
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	9b2080e7          	jalr	-1614(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002bde:	00006517          	auipc	a0,0x6
    80002be2:	8aa50513          	addi	a0,a0,-1878 # 80008488 <states.1760+0x138>
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	958080e7          	jalr	-1704(ra) # 8000053e <panic>
  if((which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING))
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	de2080e7          	jalr	-542(ra) # 800019d0 <myproc>
    80002bf6:	d541                	beqz	a0,80002b7e <kerneltrap+0x38>
    80002bf8:	fffff097          	auipc	ra,0xfffff
    80002bfc:	dd8080e7          	jalr	-552(ra) # 800019d0 <myproc>
    80002c00:	4d18                	lw	a4,24(a0)
    80002c02:	4791                	li	a5,4
    80002c04:	f6f71de3          	bne	a4,a5,80002b7e <kerneltrap+0x38>
    yield();
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	3d8080e7          	jalr	984(ra) # 80001fe0 <yield>
    80002c10:	b7bd                	j	80002b7e <kerneltrap+0x38>

0000000080002c12 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c12:	1101                	addi	sp,sp,-32
    80002c14:	ec06                	sd	ra,24(sp)
    80002c16:	e822                	sd	s0,16(sp)
    80002c18:	e426                	sd	s1,8(sp)
    80002c1a:	1000                	addi	s0,sp,32
    80002c1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	db2080e7          	jalr	-590(ra) # 800019d0 <myproc>
  switch (n) {
    80002c26:	4795                	li	a5,5
    80002c28:	0497e163          	bltu	a5,s1,80002c6a <argraw+0x58>
    80002c2c:	048a                	slli	s1,s1,0x2
    80002c2e:	00006717          	auipc	a4,0x6
    80002c32:	89270713          	addi	a4,a4,-1902 # 800084c0 <states.1760+0x170>
    80002c36:	94ba                	add	s1,s1,a4
    80002c38:	409c                	lw	a5,0(s1)
    80002c3a:	97ba                	add	a5,a5,a4
    80002c3c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c3e:	753c                	ld	a5,104(a0)
    80002c40:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c42:	60e2                	ld	ra,24(sp)
    80002c44:	6442                	ld	s0,16(sp)
    80002c46:	64a2                	ld	s1,8(sp)
    80002c48:	6105                	addi	sp,sp,32
    80002c4a:	8082                	ret
    return p->trapframe->a1;
    80002c4c:	753c                	ld	a5,104(a0)
    80002c4e:	7fa8                	ld	a0,120(a5)
    80002c50:	bfcd                	j	80002c42 <argraw+0x30>
    return p->trapframe->a2;
    80002c52:	753c                	ld	a5,104(a0)
    80002c54:	63c8                	ld	a0,128(a5)
    80002c56:	b7f5                	j	80002c42 <argraw+0x30>
    return p->trapframe->a3;
    80002c58:	753c                	ld	a5,104(a0)
    80002c5a:	67c8                	ld	a0,136(a5)
    80002c5c:	b7dd                	j	80002c42 <argraw+0x30>
    return p->trapframe->a4;
    80002c5e:	753c                	ld	a5,104(a0)
    80002c60:	6bc8                	ld	a0,144(a5)
    80002c62:	b7c5                	j	80002c42 <argraw+0x30>
    return p->trapframe->a5;
    80002c64:	753c                	ld	a5,104(a0)
    80002c66:	6fc8                	ld	a0,152(a5)
    80002c68:	bfe9                	j	80002c42 <argraw+0x30>
  panic("argraw");
    80002c6a:	00006517          	auipc	a0,0x6
    80002c6e:	82e50513          	addi	a0,a0,-2002 # 80008498 <states.1760+0x148>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>

0000000080002c7a <fetchaddr>:
{
    80002c7a:	1101                	addi	sp,sp,-32
    80002c7c:	ec06                	sd	ra,24(sp)
    80002c7e:	e822                	sd	s0,16(sp)
    80002c80:	e426                	sd	s1,8(sp)
    80002c82:	e04a                	sd	s2,0(sp)
    80002c84:	1000                	addi	s0,sp,32
    80002c86:	84aa                	mv	s1,a0
    80002c88:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	d46080e7          	jalr	-698(ra) # 800019d0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c92:	6d3c                	ld	a5,88(a0)
    80002c94:	02f4f863          	bgeu	s1,a5,80002cc4 <fetchaddr+0x4a>
    80002c98:	00848713          	addi	a4,s1,8
    80002c9c:	02e7e663          	bltu	a5,a4,80002cc8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ca0:	46a1                	li	a3,8
    80002ca2:	8626                	mv	a2,s1
    80002ca4:	85ca                	mv	a1,s2
    80002ca6:	7128                	ld	a0,96(a0)
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	a76080e7          	jalr	-1418(ra) # 8000171e <copyin>
    80002cb0:	00a03533          	snez	a0,a0
    80002cb4:	40a00533          	neg	a0,a0
}
    80002cb8:	60e2                	ld	ra,24(sp)
    80002cba:	6442                	ld	s0,16(sp)
    80002cbc:	64a2                	ld	s1,8(sp)
    80002cbe:	6902                	ld	s2,0(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret
    return -1;
    80002cc4:	557d                	li	a0,-1
    80002cc6:	bfcd                	j	80002cb8 <fetchaddr+0x3e>
    80002cc8:	557d                	li	a0,-1
    80002cca:	b7fd                	j	80002cb8 <fetchaddr+0x3e>

0000000080002ccc <fetchstr>:
{
    80002ccc:	7179                	addi	sp,sp,-48
    80002cce:	f406                	sd	ra,40(sp)
    80002cd0:	f022                	sd	s0,32(sp)
    80002cd2:	ec26                	sd	s1,24(sp)
    80002cd4:	e84a                	sd	s2,16(sp)
    80002cd6:	e44e                	sd	s3,8(sp)
    80002cd8:	1800                	addi	s0,sp,48
    80002cda:	892a                	mv	s2,a0
    80002cdc:	84ae                	mv	s1,a1
    80002cde:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	cf0080e7          	jalr	-784(ra) # 800019d0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ce8:	86ce                	mv	a3,s3
    80002cea:	864a                	mv	a2,s2
    80002cec:	85a6                	mv	a1,s1
    80002cee:	7128                	ld	a0,96(a0)
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	aba080e7          	jalr	-1350(ra) # 800017aa <copyinstr>
  if(err < 0)
    80002cf8:	00054763          	bltz	a0,80002d06 <fetchstr+0x3a>
  return strlen(buf);
    80002cfc:	8526                	mv	a0,s1
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	166080e7          	jalr	358(ra) # 80000e64 <strlen>
}
    80002d06:	70a2                	ld	ra,40(sp)
    80002d08:	7402                	ld	s0,32(sp)
    80002d0a:	64e2                	ld	s1,24(sp)
    80002d0c:	6942                	ld	s2,16(sp)
    80002d0e:	69a2                	ld	s3,8(sp)
    80002d10:	6145                	addi	sp,sp,48
    80002d12:	8082                	ret

0000000080002d14 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	e426                	sd	s1,8(sp)
    80002d1c:	1000                	addi	s0,sp,32
    80002d1e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	ef2080e7          	jalr	-270(ra) # 80002c12 <argraw>
    80002d28:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d2a:	4501                	li	a0,0
    80002d2c:	60e2                	ld	ra,24(sp)
    80002d2e:	6442                	ld	s0,16(sp)
    80002d30:	64a2                	ld	s1,8(sp)
    80002d32:	6105                	addi	sp,sp,32
    80002d34:	8082                	ret

0000000080002d36 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d36:	1101                	addi	sp,sp,-32
    80002d38:	ec06                	sd	ra,24(sp)
    80002d3a:	e822                	sd	s0,16(sp)
    80002d3c:	e426                	sd	s1,8(sp)
    80002d3e:	1000                	addi	s0,sp,32
    80002d40:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	ed0080e7          	jalr	-304(ra) # 80002c12 <argraw>
    80002d4a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d4c:	4501                	li	a0,0
    80002d4e:	60e2                	ld	ra,24(sp)
    80002d50:	6442                	ld	s0,16(sp)
    80002d52:	64a2                	ld	s1,8(sp)
    80002d54:	6105                	addi	sp,sp,32
    80002d56:	8082                	ret

0000000080002d58 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d58:	1101                	addi	sp,sp,-32
    80002d5a:	ec06                	sd	ra,24(sp)
    80002d5c:	e822                	sd	s0,16(sp)
    80002d5e:	e426                	sd	s1,8(sp)
    80002d60:	e04a                	sd	s2,0(sp)
    80002d62:	1000                	addi	s0,sp,32
    80002d64:	84ae                	mv	s1,a1
    80002d66:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d68:	00000097          	auipc	ra,0x0
    80002d6c:	eaa080e7          	jalr	-342(ra) # 80002c12 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d70:	864a                	mv	a2,s2
    80002d72:	85a6                	mv	a1,s1
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	f58080e7          	jalr	-168(ra) # 80002ccc <fetchstr>
}
    80002d7c:	60e2                	ld	ra,24(sp)
    80002d7e:	6442                	ld	s0,16(sp)
    80002d80:	64a2                	ld	s1,8(sp)
    80002d82:	6902                	ld	s2,0(sp)
    80002d84:	6105                	addi	sp,sp,32
    80002d86:	8082                	ret

0000000080002d88 <syscall>:
[SYS_kill_system] sys_kill_system
};

void
syscall(void)
{
    80002d88:	1101                	addi	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	e426                	sd	s1,8(sp)
    80002d90:	e04a                	sd	s2,0(sp)
    80002d92:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	c3c080e7          	jalr	-964(ra) # 800019d0 <myproc>
    80002d9c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d9e:	06853903          	ld	s2,104(a0)
    80002da2:	0a893783          	ld	a5,168(s2)
    80002da6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002daa:	37fd                	addiw	a5,a5,-1
    80002dac:	4759                	li	a4,22
    80002dae:	00f76f63          	bltu	a4,a5,80002dcc <syscall+0x44>
    80002db2:	00369713          	slli	a4,a3,0x3
    80002db6:	00005797          	auipc	a5,0x5
    80002dba:	72278793          	addi	a5,a5,1826 # 800084d8 <syscalls>
    80002dbe:	97ba                	add	a5,a5,a4
    80002dc0:	639c                	ld	a5,0(a5)
    80002dc2:	c789                	beqz	a5,80002dcc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002dc4:	9782                	jalr	a5
    80002dc6:	06a93823          	sd	a0,112(s2)
    80002dca:	a839                	j	80002de8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dcc:	16848613          	addi	a2,s1,360
    80002dd0:	588c                	lw	a1,48(s1)
    80002dd2:	00005517          	auipc	a0,0x5
    80002dd6:	6ce50513          	addi	a0,a0,1742 # 800084a0 <states.1760+0x150>
    80002dda:	ffffd097          	auipc	ra,0xffffd
    80002dde:	7ae080e7          	jalr	1966(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002de2:	74bc                	ld	a5,104(s1)
    80002de4:	577d                	li	a4,-1
    80002de6:	fbb8                	sd	a4,112(a5)
  }
}
    80002de8:	60e2                	ld	ra,24(sp)
    80002dea:	6442                	ld	s0,16(sp)
    80002dec:	64a2                	ld	s1,8(sp)
    80002dee:	6902                	ld	s2,0(sp)
    80002df0:	6105                	addi	sp,sp,32
    80002df2:	8082                	ret

0000000080002df4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002df4:	1101                	addi	sp,sp,-32
    80002df6:	ec06                	sd	ra,24(sp)
    80002df8:	e822                	sd	s0,16(sp)
    80002dfa:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dfc:	fec40593          	addi	a1,s0,-20
    80002e00:	4501                	li	a0,0
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	f12080e7          	jalr	-238(ra) # 80002d14 <argint>
    return -1;
    80002e0a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e0c:	00054963          	bltz	a0,80002e1e <sys_exit+0x2a>
  exit(n);
    80002e10:	fec42503          	lw	a0,-20(s0)
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	464080e7          	jalr	1124(ra) # 80002278 <exit>
  return 0;  // not reached
    80002e1c:	4781                	li	a5,0
}
    80002e1e:	853e                	mv	a0,a5
    80002e20:	60e2                	ld	ra,24(sp)
    80002e22:	6442                	ld	s0,16(sp)
    80002e24:	6105                	addi	sp,sp,32
    80002e26:	8082                	ret

0000000080002e28 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e28:	1141                	addi	sp,sp,-16
    80002e2a:	e406                	sd	ra,8(sp)
    80002e2c:	e022                	sd	s0,0(sp)
    80002e2e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	ba0080e7          	jalr	-1120(ra) # 800019d0 <myproc>
}
    80002e38:	5908                	lw	a0,48(a0)
    80002e3a:	60a2                	ld	ra,8(sp)
    80002e3c:	6402                	ld	s0,0(sp)
    80002e3e:	0141                	addi	sp,sp,16
    80002e40:	8082                	ret

0000000080002e42 <sys_fork>:

uint64
sys_fork(void)
{
    80002e42:	1141                	addi	sp,sp,-16
    80002e44:	e406                	sd	ra,8(sp)
    80002e46:	e022                	sd	s0,0(sp)
    80002e48:	0800                	addi	s0,sp,16
  return fork();
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	f64080e7          	jalr	-156(ra) # 80001dae <fork>
}
    80002e52:	60a2                	ld	ra,8(sp)
    80002e54:	6402                	ld	s0,0(sp)
    80002e56:	0141                	addi	sp,sp,16
    80002e58:	8082                	ret

0000000080002e5a <sys_wait>:

uint64
sys_wait(void)
{
    80002e5a:	1101                	addi	sp,sp,-32
    80002e5c:	ec06                	sd	ra,24(sp)
    80002e5e:	e822                	sd	s0,16(sp)
    80002e60:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e62:	fe840593          	addi	a1,s0,-24
    80002e66:	4501                	li	a0,0
    80002e68:	00000097          	auipc	ra,0x0
    80002e6c:	ece080e7          	jalr	-306(ra) # 80002d36 <argaddr>
    80002e70:	87aa                	mv	a5,a0
    return -1;
    80002e72:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e74:	0007c863          	bltz	a5,80002e84 <sys_wait+0x2a>
  return wait(p);
    80002e78:	fe843503          	ld	a0,-24(s0)
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	204080e7          	jalr	516(ra) # 80002080 <wait>
}
    80002e84:	60e2                	ld	ra,24(sp)
    80002e86:	6442                	ld	s0,16(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret

0000000080002e8c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e8c:	7179                	addi	sp,sp,-48
    80002e8e:	f406                	sd	ra,40(sp)
    80002e90:	f022                	sd	s0,32(sp)
    80002e92:	ec26                	sd	s1,24(sp)
    80002e94:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e96:	fdc40593          	addi	a1,s0,-36
    80002e9a:	4501                	li	a0,0
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	e78080e7          	jalr	-392(ra) # 80002d14 <argint>
    80002ea4:	87aa                	mv	a5,a0
    return -1;
    80002ea6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ea8:	0207c063          	bltz	a5,80002ec8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	b24080e7          	jalr	-1244(ra) # 800019d0 <myproc>
    80002eb4:	4d24                	lw	s1,88(a0)
  if(growproc(n) < 0)
    80002eb6:	fdc42503          	lw	a0,-36(s0)
    80002eba:	fffff097          	auipc	ra,0xfffff
    80002ebe:	e80080e7          	jalr	-384(ra) # 80001d3a <growproc>
    80002ec2:	00054863          	bltz	a0,80002ed2 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ec6:	8526                	mv	a0,s1
}
    80002ec8:	70a2                	ld	ra,40(sp)
    80002eca:	7402                	ld	s0,32(sp)
    80002ecc:	64e2                	ld	s1,24(sp)
    80002ece:	6145                	addi	sp,sp,48
    80002ed0:	8082                	ret
    return -1;
    80002ed2:	557d                	li	a0,-1
    80002ed4:	bfd5                	j	80002ec8 <sys_sbrk+0x3c>

0000000080002ed6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ed6:	7139                	addi	sp,sp,-64
    80002ed8:	fc06                	sd	ra,56(sp)
    80002eda:	f822                	sd	s0,48(sp)
    80002edc:	f426                	sd	s1,40(sp)
    80002ede:	f04a                	sd	s2,32(sp)
    80002ee0:	ec4e                	sd	s3,24(sp)
    80002ee2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ee4:	fcc40593          	addi	a1,s0,-52
    80002ee8:	4501                	li	a0,0
    80002eea:	00000097          	auipc	ra,0x0
    80002eee:	e2a080e7          	jalr	-470(ra) # 80002d14 <argint>
    return -1;
    80002ef2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ef4:	06054563          	bltz	a0,80002f5e <sys_sleep+0x88>
  acquire(&tickslock);
    80002ef8:	00014517          	auipc	a0,0x14
    80002efc:	5e850513          	addi	a0,a0,1512 # 800174e0 <tickslock>
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	ce4080e7          	jalr	-796(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f08:	00006917          	auipc	s2,0x6
    80002f0c:	13892903          	lw	s2,312(s2) # 80009040 <ticks>
  while(ticks - ticks0 < n){
    80002f10:	fcc42783          	lw	a5,-52(s0)
    80002f14:	cf85                	beqz	a5,80002f4c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f16:	00014997          	auipc	s3,0x14
    80002f1a:	5ca98993          	addi	s3,s3,1482 # 800174e0 <tickslock>
    80002f1e:	00006497          	auipc	s1,0x6
    80002f22:	12248493          	addi	s1,s1,290 # 80009040 <ticks>
    if(myproc()->killed){
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	aaa080e7          	jalr	-1366(ra) # 800019d0 <myproc>
    80002f2e:	551c                	lw	a5,40(a0)
    80002f30:	ef9d                	bnez	a5,80002f6e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f32:	85ce                	mv	a1,s3
    80002f34:	8526                	mv	a0,s1
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	0e6080e7          	jalr	230(ra) # 8000201c <sleep>
  while(ticks - ticks0 < n){
    80002f3e:	409c                	lw	a5,0(s1)
    80002f40:	412787bb          	subw	a5,a5,s2
    80002f44:	fcc42703          	lw	a4,-52(s0)
    80002f48:	fce7efe3          	bltu	a5,a4,80002f26 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f4c:	00014517          	auipc	a0,0x14
    80002f50:	59450513          	addi	a0,a0,1428 # 800174e0 <tickslock>
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	d44080e7          	jalr	-700(ra) # 80000c98 <release>
  return 0;
    80002f5c:	4781                	li	a5,0
}
    80002f5e:	853e                	mv	a0,a5
    80002f60:	70e2                	ld	ra,56(sp)
    80002f62:	7442                	ld	s0,48(sp)
    80002f64:	74a2                	ld	s1,40(sp)
    80002f66:	7902                	ld	s2,32(sp)
    80002f68:	69e2                	ld	s3,24(sp)
    80002f6a:	6121                	addi	sp,sp,64
    80002f6c:	8082                	ret
      release(&tickslock);
    80002f6e:	00014517          	auipc	a0,0x14
    80002f72:	57250513          	addi	a0,a0,1394 # 800174e0 <tickslock>
    80002f76:	ffffe097          	auipc	ra,0xffffe
    80002f7a:	d22080e7          	jalr	-734(ra) # 80000c98 <release>
      return -1;
    80002f7e:	57fd                	li	a5,-1
    80002f80:	bff9                	j	80002f5e <sys_sleep+0x88>

0000000080002f82 <sys_kill>:

uint64
sys_kill(void)
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f8a:	fec40593          	addi	a1,s0,-20
    80002f8e:	4501                	li	a0,0
    80002f90:	00000097          	auipc	ra,0x0
    80002f94:	d84080e7          	jalr	-636(ra) # 80002d14 <argint>
    80002f98:	87aa                	mv	a5,a0
    return -1;
    80002f9a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f9c:	0007c863          	bltz	a5,80002fac <sys_kill+0x2a>
  return kill(pid);
    80002fa0:	fec42503          	lw	a0,-20(s0)
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	3aa080e7          	jalr	938(ra) # 8000234e <kill>
}
    80002fac:	60e2                	ld	ra,24(sp)
    80002fae:	6442                	ld	s0,16(sp)
    80002fb0:	6105                	addi	sp,sp,32
    80002fb2:	8082                	ret

0000000080002fb4 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80002fb4:	1101                	addi	sp,sp,-32
    80002fb6:	ec06                	sd	ra,24(sp)
    80002fb8:	e822                	sd	s0,16(sp)
    80002fba:	1000                	addi	s0,sp,32
  // care of the sys_call there.

  int time;
  // uint ticks0;

  if(argint(0, &time) < 0)
    80002fbc:	fec40593          	addi	a1,s0,-20
    80002fc0:	4501                	li	a0,0
    80002fc2:	00000097          	auipc	ra,0x0
    80002fc6:	d52080e7          	jalr	-686(ra) # 80002d14 <argint>
    80002fca:	87aa                	mv	a5,a0
    return -1;
    80002fcc:	557d                	li	a0,-1
  if(argint(0, &time) < 0)
    80002fce:	0007c863          	bltz	a5,80002fde <sys_pause_system+0x2a>

  return pause_system(time);
    80002fd2:	fec42503          	lw	a0,-20(s0)
    80002fd6:	fffff097          	auipc	ra,0xfffff
    80002fda:	3ea080e7          	jalr	1002(ra) # 800023c0 <pause_system>
}
    80002fde:	60e2                	ld	ra,24(sp)
    80002fe0:	6442                	ld	s0,16(sp)
    80002fe2:	6105                	addi	sp,sp,32
    80002fe4:	8082                	ret

0000000080002fe6 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002fe6:	1141                	addi	sp,sp,-16
    80002fe8:	e406                	sd	ra,8(sp)
    80002fea:	e022                	sd	s0,0(sp)
    80002fec:	0800                	addi	s0,sp,16
  return kill_system();
    80002fee:	fffff097          	auipc	ra,0xfffff
    80002ff2:	686080e7          	jalr	1670(ra) # 80002674 <kill_system>
}
    80002ff6:	60a2                	ld	ra,8(sp)
    80002ff8:	6402                	ld	s0,0(sp)
    80002ffa:	0141                	addi	sp,sp,16
    80002ffc:	8082                	ret

0000000080002ffe <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ffe:	1101                	addi	sp,sp,-32
    80003000:	ec06                	sd	ra,24(sp)
    80003002:	e822                	sd	s0,16(sp)
    80003004:	e426                	sd	s1,8(sp)
    80003006:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003008:	00014517          	auipc	a0,0x14
    8000300c:	4d850513          	addi	a0,a0,1240 # 800174e0 <tickslock>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	bd4080e7          	jalr	-1068(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003018:	00006497          	auipc	s1,0x6
    8000301c:	0284a483          	lw	s1,40(s1) # 80009040 <ticks>
  release(&tickslock);
    80003020:	00014517          	auipc	a0,0x14
    80003024:	4c050513          	addi	a0,a0,1216 # 800174e0 <tickslock>
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	c70080e7          	jalr	-912(ra) # 80000c98 <release>
  return xticks;
}
    80003030:	02049513          	slli	a0,s1,0x20
    80003034:	9101                	srli	a0,a0,0x20
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	64a2                	ld	s1,8(sp)
    8000303c:	6105                	addi	sp,sp,32
    8000303e:	8082                	ret

0000000080003040 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003040:	7179                	addi	sp,sp,-48
    80003042:	f406                	sd	ra,40(sp)
    80003044:	f022                	sd	s0,32(sp)
    80003046:	ec26                	sd	s1,24(sp)
    80003048:	e84a                	sd	s2,16(sp)
    8000304a:	e44e                	sd	s3,8(sp)
    8000304c:	e052                	sd	s4,0(sp)
    8000304e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003050:	00005597          	auipc	a1,0x5
    80003054:	54858593          	addi	a1,a1,1352 # 80008598 <syscalls+0xc0>
    80003058:	00014517          	auipc	a0,0x14
    8000305c:	4a050513          	addi	a0,a0,1184 # 800174f8 <bcache>
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	af4080e7          	jalr	-1292(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003068:	0001c797          	auipc	a5,0x1c
    8000306c:	49078793          	addi	a5,a5,1168 # 8001f4f8 <bcache+0x8000>
    80003070:	0001c717          	auipc	a4,0x1c
    80003074:	6f070713          	addi	a4,a4,1776 # 8001f760 <bcache+0x8268>
    80003078:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000307c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003080:	00014497          	auipc	s1,0x14
    80003084:	49048493          	addi	s1,s1,1168 # 80017510 <bcache+0x18>
    b->next = bcache.head.next;
    80003088:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000308a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000308c:	00005a17          	auipc	s4,0x5
    80003090:	514a0a13          	addi	s4,s4,1300 # 800085a0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003094:	2b893783          	ld	a5,696(s2)
    80003098:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000309a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000309e:	85d2                	mv	a1,s4
    800030a0:	01048513          	addi	a0,s1,16
    800030a4:	00001097          	auipc	ra,0x1
    800030a8:	4bc080e7          	jalr	1212(ra) # 80004560 <initsleeplock>
    bcache.head.next->prev = b;
    800030ac:	2b893783          	ld	a5,696(s2)
    800030b0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030b2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030b6:	45848493          	addi	s1,s1,1112
    800030ba:	fd349de3          	bne	s1,s3,80003094 <binit+0x54>
  }
}
    800030be:	70a2                	ld	ra,40(sp)
    800030c0:	7402                	ld	s0,32(sp)
    800030c2:	64e2                	ld	s1,24(sp)
    800030c4:	6942                	ld	s2,16(sp)
    800030c6:	69a2                	ld	s3,8(sp)
    800030c8:	6a02                	ld	s4,0(sp)
    800030ca:	6145                	addi	sp,sp,48
    800030cc:	8082                	ret

00000000800030ce <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030ce:	7179                	addi	sp,sp,-48
    800030d0:	f406                	sd	ra,40(sp)
    800030d2:	f022                	sd	s0,32(sp)
    800030d4:	ec26                	sd	s1,24(sp)
    800030d6:	e84a                	sd	s2,16(sp)
    800030d8:	e44e                	sd	s3,8(sp)
    800030da:	1800                	addi	s0,sp,48
    800030dc:	89aa                	mv	s3,a0
    800030de:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030e0:	00014517          	auipc	a0,0x14
    800030e4:	41850513          	addi	a0,a0,1048 # 800174f8 <bcache>
    800030e8:	ffffe097          	auipc	ra,0xffffe
    800030ec:	afc080e7          	jalr	-1284(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030f0:	0001c497          	auipc	s1,0x1c
    800030f4:	6c04b483          	ld	s1,1728(s1) # 8001f7b0 <bcache+0x82b8>
    800030f8:	0001c797          	auipc	a5,0x1c
    800030fc:	66878793          	addi	a5,a5,1640 # 8001f760 <bcache+0x8268>
    80003100:	02f48f63          	beq	s1,a5,8000313e <bread+0x70>
    80003104:	873e                	mv	a4,a5
    80003106:	a021                	j	8000310e <bread+0x40>
    80003108:	68a4                	ld	s1,80(s1)
    8000310a:	02e48a63          	beq	s1,a4,8000313e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000310e:	449c                	lw	a5,8(s1)
    80003110:	ff379ce3          	bne	a5,s3,80003108 <bread+0x3a>
    80003114:	44dc                	lw	a5,12(s1)
    80003116:	ff2799e3          	bne	a5,s2,80003108 <bread+0x3a>
      b->refcnt++;
    8000311a:	40bc                	lw	a5,64(s1)
    8000311c:	2785                	addiw	a5,a5,1
    8000311e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003120:	00014517          	auipc	a0,0x14
    80003124:	3d850513          	addi	a0,a0,984 # 800174f8 <bcache>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	b70080e7          	jalr	-1168(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003130:	01048513          	addi	a0,s1,16
    80003134:	00001097          	auipc	ra,0x1
    80003138:	466080e7          	jalr	1126(ra) # 8000459a <acquiresleep>
      return b;
    8000313c:	a8b9                	j	8000319a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000313e:	0001c497          	auipc	s1,0x1c
    80003142:	66a4b483          	ld	s1,1642(s1) # 8001f7a8 <bcache+0x82b0>
    80003146:	0001c797          	auipc	a5,0x1c
    8000314a:	61a78793          	addi	a5,a5,1562 # 8001f760 <bcache+0x8268>
    8000314e:	00f48863          	beq	s1,a5,8000315e <bread+0x90>
    80003152:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003154:	40bc                	lw	a5,64(s1)
    80003156:	cf81                	beqz	a5,8000316e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003158:	64a4                	ld	s1,72(s1)
    8000315a:	fee49de3          	bne	s1,a4,80003154 <bread+0x86>
  panic("bget: no buffers");
    8000315e:	00005517          	auipc	a0,0x5
    80003162:	44a50513          	addi	a0,a0,1098 # 800085a8 <syscalls+0xd0>
    80003166:	ffffd097          	auipc	ra,0xffffd
    8000316a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>
      b->dev = dev;
    8000316e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003172:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003176:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000317a:	4785                	li	a5,1
    8000317c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000317e:	00014517          	auipc	a0,0x14
    80003182:	37a50513          	addi	a0,a0,890 # 800174f8 <bcache>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	b12080e7          	jalr	-1262(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000318e:	01048513          	addi	a0,s1,16
    80003192:	00001097          	auipc	ra,0x1
    80003196:	408080e7          	jalr	1032(ra) # 8000459a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000319a:	409c                	lw	a5,0(s1)
    8000319c:	cb89                	beqz	a5,800031ae <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000319e:	8526                	mv	a0,s1
    800031a0:	70a2                	ld	ra,40(sp)
    800031a2:	7402                	ld	s0,32(sp)
    800031a4:	64e2                	ld	s1,24(sp)
    800031a6:	6942                	ld	s2,16(sp)
    800031a8:	69a2                	ld	s3,8(sp)
    800031aa:	6145                	addi	sp,sp,48
    800031ac:	8082                	ret
    virtio_disk_rw(b, 0);
    800031ae:	4581                	li	a1,0
    800031b0:	8526                	mv	a0,s1
    800031b2:	00003097          	auipc	ra,0x3
    800031b6:	f14080e7          	jalr	-236(ra) # 800060c6 <virtio_disk_rw>
    b->valid = 1;
    800031ba:	4785                	li	a5,1
    800031bc:	c09c                	sw	a5,0(s1)
  return b;
    800031be:	b7c5                	j	8000319e <bread+0xd0>

00000000800031c0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031c0:	1101                	addi	sp,sp,-32
    800031c2:	ec06                	sd	ra,24(sp)
    800031c4:	e822                	sd	s0,16(sp)
    800031c6:	e426                	sd	s1,8(sp)
    800031c8:	1000                	addi	s0,sp,32
    800031ca:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031cc:	0541                	addi	a0,a0,16
    800031ce:	00001097          	auipc	ra,0x1
    800031d2:	466080e7          	jalr	1126(ra) # 80004634 <holdingsleep>
    800031d6:	cd01                	beqz	a0,800031ee <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031d8:	4585                	li	a1,1
    800031da:	8526                	mv	a0,s1
    800031dc:	00003097          	auipc	ra,0x3
    800031e0:	eea080e7          	jalr	-278(ra) # 800060c6 <virtio_disk_rw>
}
    800031e4:	60e2                	ld	ra,24(sp)
    800031e6:	6442                	ld	s0,16(sp)
    800031e8:	64a2                	ld	s1,8(sp)
    800031ea:	6105                	addi	sp,sp,32
    800031ec:	8082                	ret
    panic("bwrite");
    800031ee:	00005517          	auipc	a0,0x5
    800031f2:	3d250513          	addi	a0,a0,978 # 800085c0 <syscalls+0xe8>
    800031f6:	ffffd097          	auipc	ra,0xffffd
    800031fa:	348080e7          	jalr	840(ra) # 8000053e <panic>

00000000800031fe <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031fe:	1101                	addi	sp,sp,-32
    80003200:	ec06                	sd	ra,24(sp)
    80003202:	e822                	sd	s0,16(sp)
    80003204:	e426                	sd	s1,8(sp)
    80003206:	e04a                	sd	s2,0(sp)
    80003208:	1000                	addi	s0,sp,32
    8000320a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000320c:	01050913          	addi	s2,a0,16
    80003210:	854a                	mv	a0,s2
    80003212:	00001097          	auipc	ra,0x1
    80003216:	422080e7          	jalr	1058(ra) # 80004634 <holdingsleep>
    8000321a:	c92d                	beqz	a0,8000328c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000321c:	854a                	mv	a0,s2
    8000321e:	00001097          	auipc	ra,0x1
    80003222:	3d2080e7          	jalr	978(ra) # 800045f0 <releasesleep>

  acquire(&bcache.lock);
    80003226:	00014517          	auipc	a0,0x14
    8000322a:	2d250513          	addi	a0,a0,722 # 800174f8 <bcache>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	9b6080e7          	jalr	-1610(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003236:	40bc                	lw	a5,64(s1)
    80003238:	37fd                	addiw	a5,a5,-1
    8000323a:	0007871b          	sext.w	a4,a5
    8000323e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003240:	eb05                	bnez	a4,80003270 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003242:	68bc                	ld	a5,80(s1)
    80003244:	64b8                	ld	a4,72(s1)
    80003246:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003248:	64bc                	ld	a5,72(s1)
    8000324a:	68b8                	ld	a4,80(s1)
    8000324c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000324e:	0001c797          	auipc	a5,0x1c
    80003252:	2aa78793          	addi	a5,a5,682 # 8001f4f8 <bcache+0x8000>
    80003256:	2b87b703          	ld	a4,696(a5)
    8000325a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000325c:	0001c717          	auipc	a4,0x1c
    80003260:	50470713          	addi	a4,a4,1284 # 8001f760 <bcache+0x8268>
    80003264:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003266:	2b87b703          	ld	a4,696(a5)
    8000326a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000326c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003270:	00014517          	auipc	a0,0x14
    80003274:	28850513          	addi	a0,a0,648 # 800174f8 <bcache>
    80003278:	ffffe097          	auipc	ra,0xffffe
    8000327c:	a20080e7          	jalr	-1504(ra) # 80000c98 <release>
}
    80003280:	60e2                	ld	ra,24(sp)
    80003282:	6442                	ld	s0,16(sp)
    80003284:	64a2                	ld	s1,8(sp)
    80003286:	6902                	ld	s2,0(sp)
    80003288:	6105                	addi	sp,sp,32
    8000328a:	8082                	ret
    panic("brelse");
    8000328c:	00005517          	auipc	a0,0x5
    80003290:	33c50513          	addi	a0,a0,828 # 800085c8 <syscalls+0xf0>
    80003294:	ffffd097          	auipc	ra,0xffffd
    80003298:	2aa080e7          	jalr	682(ra) # 8000053e <panic>

000000008000329c <bpin>:

void
bpin(struct buf *b) {
    8000329c:	1101                	addi	sp,sp,-32
    8000329e:	ec06                	sd	ra,24(sp)
    800032a0:	e822                	sd	s0,16(sp)
    800032a2:	e426                	sd	s1,8(sp)
    800032a4:	1000                	addi	s0,sp,32
    800032a6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032a8:	00014517          	auipc	a0,0x14
    800032ac:	25050513          	addi	a0,a0,592 # 800174f8 <bcache>
    800032b0:	ffffe097          	auipc	ra,0xffffe
    800032b4:	934080e7          	jalr	-1740(ra) # 80000be4 <acquire>
  b->refcnt++;
    800032b8:	40bc                	lw	a5,64(s1)
    800032ba:	2785                	addiw	a5,a5,1
    800032bc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032be:	00014517          	auipc	a0,0x14
    800032c2:	23a50513          	addi	a0,a0,570 # 800174f8 <bcache>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	9d2080e7          	jalr	-1582(ra) # 80000c98 <release>
}
    800032ce:	60e2                	ld	ra,24(sp)
    800032d0:	6442                	ld	s0,16(sp)
    800032d2:	64a2                	ld	s1,8(sp)
    800032d4:	6105                	addi	sp,sp,32
    800032d6:	8082                	ret

00000000800032d8 <bunpin>:

void
bunpin(struct buf *b) {
    800032d8:	1101                	addi	sp,sp,-32
    800032da:	ec06                	sd	ra,24(sp)
    800032dc:	e822                	sd	s0,16(sp)
    800032de:	e426                	sd	s1,8(sp)
    800032e0:	1000                	addi	s0,sp,32
    800032e2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032e4:	00014517          	auipc	a0,0x14
    800032e8:	21450513          	addi	a0,a0,532 # 800174f8 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	8f8080e7          	jalr	-1800(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032f4:	40bc                	lw	a5,64(s1)
    800032f6:	37fd                	addiw	a5,a5,-1
    800032f8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032fa:	00014517          	auipc	a0,0x14
    800032fe:	1fe50513          	addi	a0,a0,510 # 800174f8 <bcache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000330a:	60e2                	ld	ra,24(sp)
    8000330c:	6442                	ld	s0,16(sp)
    8000330e:	64a2                	ld	s1,8(sp)
    80003310:	6105                	addi	sp,sp,32
    80003312:	8082                	ret

0000000080003314 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003314:	1101                	addi	sp,sp,-32
    80003316:	ec06                	sd	ra,24(sp)
    80003318:	e822                	sd	s0,16(sp)
    8000331a:	e426                	sd	s1,8(sp)
    8000331c:	e04a                	sd	s2,0(sp)
    8000331e:	1000                	addi	s0,sp,32
    80003320:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003322:	00d5d59b          	srliw	a1,a1,0xd
    80003326:	0001d797          	auipc	a5,0x1d
    8000332a:	8ae7a783          	lw	a5,-1874(a5) # 8001fbd4 <sb+0x1c>
    8000332e:	9dbd                	addw	a1,a1,a5
    80003330:	00000097          	auipc	ra,0x0
    80003334:	d9e080e7          	jalr	-610(ra) # 800030ce <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003338:	0074f713          	andi	a4,s1,7
    8000333c:	4785                	li	a5,1
    8000333e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003342:	14ce                	slli	s1,s1,0x33
    80003344:	90d9                	srli	s1,s1,0x36
    80003346:	00950733          	add	a4,a0,s1
    8000334a:	05874703          	lbu	a4,88(a4)
    8000334e:	00e7f6b3          	and	a3,a5,a4
    80003352:	c69d                	beqz	a3,80003380 <bfree+0x6c>
    80003354:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003356:	94aa                	add	s1,s1,a0
    80003358:	fff7c793          	not	a5,a5
    8000335c:	8ff9                	and	a5,a5,a4
    8000335e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003362:	00001097          	auipc	ra,0x1
    80003366:	118080e7          	jalr	280(ra) # 8000447a <log_write>
  brelse(bp);
    8000336a:	854a                	mv	a0,s2
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	e92080e7          	jalr	-366(ra) # 800031fe <brelse>
}
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	64a2                	ld	s1,8(sp)
    8000337a:	6902                	ld	s2,0(sp)
    8000337c:	6105                	addi	sp,sp,32
    8000337e:	8082                	ret
    panic("freeing free block");
    80003380:	00005517          	auipc	a0,0x5
    80003384:	25050513          	addi	a0,a0,592 # 800085d0 <syscalls+0xf8>
    80003388:	ffffd097          	auipc	ra,0xffffd
    8000338c:	1b6080e7          	jalr	438(ra) # 8000053e <panic>

0000000080003390 <balloc>:
{
    80003390:	711d                	addi	sp,sp,-96
    80003392:	ec86                	sd	ra,88(sp)
    80003394:	e8a2                	sd	s0,80(sp)
    80003396:	e4a6                	sd	s1,72(sp)
    80003398:	e0ca                	sd	s2,64(sp)
    8000339a:	fc4e                	sd	s3,56(sp)
    8000339c:	f852                	sd	s4,48(sp)
    8000339e:	f456                	sd	s5,40(sp)
    800033a0:	f05a                	sd	s6,32(sp)
    800033a2:	ec5e                	sd	s7,24(sp)
    800033a4:	e862                	sd	s8,16(sp)
    800033a6:	e466                	sd	s9,8(sp)
    800033a8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033aa:	0001d797          	auipc	a5,0x1d
    800033ae:	8127a783          	lw	a5,-2030(a5) # 8001fbbc <sb+0x4>
    800033b2:	cbd1                	beqz	a5,80003446 <balloc+0xb6>
    800033b4:	8baa                	mv	s7,a0
    800033b6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033b8:	0001db17          	auipc	s6,0x1d
    800033bc:	800b0b13          	addi	s6,s6,-2048 # 8001fbb8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033c2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033c6:	6c89                	lui	s9,0x2
    800033c8:	a831                	j	800033e4 <balloc+0x54>
    brelse(bp);
    800033ca:	854a                	mv	a0,s2
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	e32080e7          	jalr	-462(ra) # 800031fe <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033d4:	015c87bb          	addw	a5,s9,s5
    800033d8:	00078a9b          	sext.w	s5,a5
    800033dc:	004b2703          	lw	a4,4(s6)
    800033e0:	06eaf363          	bgeu	s5,a4,80003446 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033e4:	41fad79b          	sraiw	a5,s5,0x1f
    800033e8:	0137d79b          	srliw	a5,a5,0x13
    800033ec:	015787bb          	addw	a5,a5,s5
    800033f0:	40d7d79b          	sraiw	a5,a5,0xd
    800033f4:	01cb2583          	lw	a1,28(s6)
    800033f8:	9dbd                	addw	a1,a1,a5
    800033fa:	855e                	mv	a0,s7
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	cd2080e7          	jalr	-814(ra) # 800030ce <bread>
    80003404:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003406:	004b2503          	lw	a0,4(s6)
    8000340a:	000a849b          	sext.w	s1,s5
    8000340e:	8662                	mv	a2,s8
    80003410:	faa4fde3          	bgeu	s1,a0,800033ca <balloc+0x3a>
      m = 1 << (bi % 8);
    80003414:	41f6579b          	sraiw	a5,a2,0x1f
    80003418:	01d7d69b          	srliw	a3,a5,0x1d
    8000341c:	00c6873b          	addw	a4,a3,a2
    80003420:	00777793          	andi	a5,a4,7
    80003424:	9f95                	subw	a5,a5,a3
    80003426:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000342a:	4037571b          	sraiw	a4,a4,0x3
    8000342e:	00e906b3          	add	a3,s2,a4
    80003432:	0586c683          	lbu	a3,88(a3)
    80003436:	00d7f5b3          	and	a1,a5,a3
    8000343a:	cd91                	beqz	a1,80003456 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000343c:	2605                	addiw	a2,a2,1
    8000343e:	2485                	addiw	s1,s1,1
    80003440:	fd4618e3          	bne	a2,s4,80003410 <balloc+0x80>
    80003444:	b759                	j	800033ca <balloc+0x3a>
  panic("balloc: out of blocks");
    80003446:	00005517          	auipc	a0,0x5
    8000344a:	1a250513          	addi	a0,a0,418 # 800085e8 <syscalls+0x110>
    8000344e:	ffffd097          	auipc	ra,0xffffd
    80003452:	0f0080e7          	jalr	240(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003456:	974a                	add	a4,a4,s2
    80003458:	8fd5                	or	a5,a5,a3
    8000345a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000345e:	854a                	mv	a0,s2
    80003460:	00001097          	auipc	ra,0x1
    80003464:	01a080e7          	jalr	26(ra) # 8000447a <log_write>
        brelse(bp);
    80003468:	854a                	mv	a0,s2
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	d94080e7          	jalr	-620(ra) # 800031fe <brelse>
  bp = bread(dev, bno);
    80003472:	85a6                	mv	a1,s1
    80003474:	855e                	mv	a0,s7
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	c58080e7          	jalr	-936(ra) # 800030ce <bread>
    8000347e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003480:	40000613          	li	a2,1024
    80003484:	4581                	li	a1,0
    80003486:	05850513          	addi	a0,a0,88
    8000348a:	ffffe097          	auipc	ra,0xffffe
    8000348e:	856080e7          	jalr	-1962(ra) # 80000ce0 <memset>
  log_write(bp);
    80003492:	854a                	mv	a0,s2
    80003494:	00001097          	auipc	ra,0x1
    80003498:	fe6080e7          	jalr	-26(ra) # 8000447a <log_write>
  brelse(bp);
    8000349c:	854a                	mv	a0,s2
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	d60080e7          	jalr	-672(ra) # 800031fe <brelse>
}
    800034a6:	8526                	mv	a0,s1
    800034a8:	60e6                	ld	ra,88(sp)
    800034aa:	6446                	ld	s0,80(sp)
    800034ac:	64a6                	ld	s1,72(sp)
    800034ae:	6906                	ld	s2,64(sp)
    800034b0:	79e2                	ld	s3,56(sp)
    800034b2:	7a42                	ld	s4,48(sp)
    800034b4:	7aa2                	ld	s5,40(sp)
    800034b6:	7b02                	ld	s6,32(sp)
    800034b8:	6be2                	ld	s7,24(sp)
    800034ba:	6c42                	ld	s8,16(sp)
    800034bc:	6ca2                	ld	s9,8(sp)
    800034be:	6125                	addi	sp,sp,96
    800034c0:	8082                	ret

00000000800034c2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034c2:	7179                	addi	sp,sp,-48
    800034c4:	f406                	sd	ra,40(sp)
    800034c6:	f022                	sd	s0,32(sp)
    800034c8:	ec26                	sd	s1,24(sp)
    800034ca:	e84a                	sd	s2,16(sp)
    800034cc:	e44e                	sd	s3,8(sp)
    800034ce:	e052                	sd	s4,0(sp)
    800034d0:	1800                	addi	s0,sp,48
    800034d2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034d4:	47ad                	li	a5,11
    800034d6:	04b7fe63          	bgeu	a5,a1,80003532 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034da:	ff45849b          	addiw	s1,a1,-12
    800034de:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034e2:	0ff00793          	li	a5,255
    800034e6:	0ae7e363          	bltu	a5,a4,8000358c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034ea:	08052583          	lw	a1,128(a0)
    800034ee:	c5ad                	beqz	a1,80003558 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034f0:	00092503          	lw	a0,0(s2)
    800034f4:	00000097          	auipc	ra,0x0
    800034f8:	bda080e7          	jalr	-1062(ra) # 800030ce <bread>
    800034fc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034fe:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003502:	02049593          	slli	a1,s1,0x20
    80003506:	9181                	srli	a1,a1,0x20
    80003508:	058a                	slli	a1,a1,0x2
    8000350a:	00b784b3          	add	s1,a5,a1
    8000350e:	0004a983          	lw	s3,0(s1)
    80003512:	04098d63          	beqz	s3,8000356c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003516:	8552                	mv	a0,s4
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	ce6080e7          	jalr	-794(ra) # 800031fe <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003520:	854e                	mv	a0,s3
    80003522:	70a2                	ld	ra,40(sp)
    80003524:	7402                	ld	s0,32(sp)
    80003526:	64e2                	ld	s1,24(sp)
    80003528:	6942                	ld	s2,16(sp)
    8000352a:	69a2                	ld	s3,8(sp)
    8000352c:	6a02                	ld	s4,0(sp)
    8000352e:	6145                	addi	sp,sp,48
    80003530:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003532:	02059493          	slli	s1,a1,0x20
    80003536:	9081                	srli	s1,s1,0x20
    80003538:	048a                	slli	s1,s1,0x2
    8000353a:	94aa                	add	s1,s1,a0
    8000353c:	0504a983          	lw	s3,80(s1)
    80003540:	fe0990e3          	bnez	s3,80003520 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003544:	4108                	lw	a0,0(a0)
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	e4a080e7          	jalr	-438(ra) # 80003390 <balloc>
    8000354e:	0005099b          	sext.w	s3,a0
    80003552:	0534a823          	sw	s3,80(s1)
    80003556:	b7e9                	j	80003520 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003558:	4108                	lw	a0,0(a0)
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	e36080e7          	jalr	-458(ra) # 80003390 <balloc>
    80003562:	0005059b          	sext.w	a1,a0
    80003566:	08b92023          	sw	a1,128(s2)
    8000356a:	b759                	j	800034f0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000356c:	00092503          	lw	a0,0(s2)
    80003570:	00000097          	auipc	ra,0x0
    80003574:	e20080e7          	jalr	-480(ra) # 80003390 <balloc>
    80003578:	0005099b          	sext.w	s3,a0
    8000357c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003580:	8552                	mv	a0,s4
    80003582:	00001097          	auipc	ra,0x1
    80003586:	ef8080e7          	jalr	-264(ra) # 8000447a <log_write>
    8000358a:	b771                	j	80003516 <bmap+0x54>
  panic("bmap: out of range");
    8000358c:	00005517          	auipc	a0,0x5
    80003590:	07450513          	addi	a0,a0,116 # 80008600 <syscalls+0x128>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	faa080e7          	jalr	-86(ra) # 8000053e <panic>

000000008000359c <iget>:
{
    8000359c:	7179                	addi	sp,sp,-48
    8000359e:	f406                	sd	ra,40(sp)
    800035a0:	f022                	sd	s0,32(sp)
    800035a2:	ec26                	sd	s1,24(sp)
    800035a4:	e84a                	sd	s2,16(sp)
    800035a6:	e44e                	sd	s3,8(sp)
    800035a8:	e052                	sd	s4,0(sp)
    800035aa:	1800                	addi	s0,sp,48
    800035ac:	89aa                	mv	s3,a0
    800035ae:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035b0:	0001c517          	auipc	a0,0x1c
    800035b4:	62850513          	addi	a0,a0,1576 # 8001fbd8 <itable>
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	62c080e7          	jalr	1580(ra) # 80000be4 <acquire>
  empty = 0;
    800035c0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035c2:	0001c497          	auipc	s1,0x1c
    800035c6:	62e48493          	addi	s1,s1,1582 # 8001fbf0 <itable+0x18>
    800035ca:	0001e697          	auipc	a3,0x1e
    800035ce:	0b668693          	addi	a3,a3,182 # 80021680 <log>
    800035d2:	a039                	j	800035e0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035d4:	02090b63          	beqz	s2,8000360a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035d8:	08848493          	addi	s1,s1,136
    800035dc:	02d48a63          	beq	s1,a3,80003610 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035e0:	449c                	lw	a5,8(s1)
    800035e2:	fef059e3          	blez	a5,800035d4 <iget+0x38>
    800035e6:	4098                	lw	a4,0(s1)
    800035e8:	ff3716e3          	bne	a4,s3,800035d4 <iget+0x38>
    800035ec:	40d8                	lw	a4,4(s1)
    800035ee:	ff4713e3          	bne	a4,s4,800035d4 <iget+0x38>
      ip->ref++;
    800035f2:	2785                	addiw	a5,a5,1
    800035f4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035f6:	0001c517          	auipc	a0,0x1c
    800035fa:	5e250513          	addi	a0,a0,1506 # 8001fbd8 <itable>
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	69a080e7          	jalr	1690(ra) # 80000c98 <release>
      return ip;
    80003606:	8926                	mv	s2,s1
    80003608:	a03d                	j	80003636 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000360a:	f7f9                	bnez	a5,800035d8 <iget+0x3c>
    8000360c:	8926                	mv	s2,s1
    8000360e:	b7e9                	j	800035d8 <iget+0x3c>
  if(empty == 0)
    80003610:	02090c63          	beqz	s2,80003648 <iget+0xac>
  ip->dev = dev;
    80003614:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003618:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000361c:	4785                	li	a5,1
    8000361e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003622:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003626:	0001c517          	auipc	a0,0x1c
    8000362a:	5b250513          	addi	a0,a0,1458 # 8001fbd8 <itable>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>
}
    80003636:	854a                	mv	a0,s2
    80003638:	70a2                	ld	ra,40(sp)
    8000363a:	7402                	ld	s0,32(sp)
    8000363c:	64e2                	ld	s1,24(sp)
    8000363e:	6942                	ld	s2,16(sp)
    80003640:	69a2                	ld	s3,8(sp)
    80003642:	6a02                	ld	s4,0(sp)
    80003644:	6145                	addi	sp,sp,48
    80003646:	8082                	ret
    panic("iget: no inodes");
    80003648:	00005517          	auipc	a0,0x5
    8000364c:	fd050513          	addi	a0,a0,-48 # 80008618 <syscalls+0x140>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	eee080e7          	jalr	-274(ra) # 8000053e <panic>

0000000080003658 <fsinit>:
fsinit(int dev) {
    80003658:	7179                	addi	sp,sp,-48
    8000365a:	f406                	sd	ra,40(sp)
    8000365c:	f022                	sd	s0,32(sp)
    8000365e:	ec26                	sd	s1,24(sp)
    80003660:	e84a                	sd	s2,16(sp)
    80003662:	e44e                	sd	s3,8(sp)
    80003664:	1800                	addi	s0,sp,48
    80003666:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003668:	4585                	li	a1,1
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	a64080e7          	jalr	-1436(ra) # 800030ce <bread>
    80003672:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003674:	0001c997          	auipc	s3,0x1c
    80003678:	54498993          	addi	s3,s3,1348 # 8001fbb8 <sb>
    8000367c:	02000613          	li	a2,32
    80003680:	05850593          	addi	a1,a0,88
    80003684:	854e                	mv	a0,s3
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	6ba080e7          	jalr	1722(ra) # 80000d40 <memmove>
  brelse(bp);
    8000368e:	8526                	mv	a0,s1
    80003690:	00000097          	auipc	ra,0x0
    80003694:	b6e080e7          	jalr	-1170(ra) # 800031fe <brelse>
  if(sb.magic != FSMAGIC)
    80003698:	0009a703          	lw	a4,0(s3)
    8000369c:	102037b7          	lui	a5,0x10203
    800036a0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036a4:	02f71263          	bne	a4,a5,800036c8 <fsinit+0x70>
  initlog(dev, &sb);
    800036a8:	0001c597          	auipc	a1,0x1c
    800036ac:	51058593          	addi	a1,a1,1296 # 8001fbb8 <sb>
    800036b0:	854a                	mv	a0,s2
    800036b2:	00001097          	auipc	ra,0x1
    800036b6:	b4c080e7          	jalr	-1204(ra) # 800041fe <initlog>
}
    800036ba:	70a2                	ld	ra,40(sp)
    800036bc:	7402                	ld	s0,32(sp)
    800036be:	64e2                	ld	s1,24(sp)
    800036c0:	6942                	ld	s2,16(sp)
    800036c2:	69a2                	ld	s3,8(sp)
    800036c4:	6145                	addi	sp,sp,48
    800036c6:	8082                	ret
    panic("invalid file system");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	f6050513          	addi	a0,a0,-160 # 80008628 <syscalls+0x150>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	e6e080e7          	jalr	-402(ra) # 8000053e <panic>

00000000800036d8 <iinit>:
{
    800036d8:	7179                	addi	sp,sp,-48
    800036da:	f406                	sd	ra,40(sp)
    800036dc:	f022                	sd	s0,32(sp)
    800036de:	ec26                	sd	s1,24(sp)
    800036e0:	e84a                	sd	s2,16(sp)
    800036e2:	e44e                	sd	s3,8(sp)
    800036e4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036e6:	00005597          	auipc	a1,0x5
    800036ea:	f5a58593          	addi	a1,a1,-166 # 80008640 <syscalls+0x168>
    800036ee:	0001c517          	auipc	a0,0x1c
    800036f2:	4ea50513          	addi	a0,a0,1258 # 8001fbd8 <itable>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	45e080e7          	jalr	1118(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036fe:	0001c497          	auipc	s1,0x1c
    80003702:	50248493          	addi	s1,s1,1282 # 8001fc00 <itable+0x28>
    80003706:	0001e997          	auipc	s3,0x1e
    8000370a:	f8a98993          	addi	s3,s3,-118 # 80021690 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000370e:	00005917          	auipc	s2,0x5
    80003712:	f3a90913          	addi	s2,s2,-198 # 80008648 <syscalls+0x170>
    80003716:	85ca                	mv	a1,s2
    80003718:	8526                	mv	a0,s1
    8000371a:	00001097          	auipc	ra,0x1
    8000371e:	e46080e7          	jalr	-442(ra) # 80004560 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003722:	08848493          	addi	s1,s1,136
    80003726:	ff3498e3          	bne	s1,s3,80003716 <iinit+0x3e>
}
    8000372a:	70a2                	ld	ra,40(sp)
    8000372c:	7402                	ld	s0,32(sp)
    8000372e:	64e2                	ld	s1,24(sp)
    80003730:	6942                	ld	s2,16(sp)
    80003732:	69a2                	ld	s3,8(sp)
    80003734:	6145                	addi	sp,sp,48
    80003736:	8082                	ret

0000000080003738 <ialloc>:
{
    80003738:	715d                	addi	sp,sp,-80
    8000373a:	e486                	sd	ra,72(sp)
    8000373c:	e0a2                	sd	s0,64(sp)
    8000373e:	fc26                	sd	s1,56(sp)
    80003740:	f84a                	sd	s2,48(sp)
    80003742:	f44e                	sd	s3,40(sp)
    80003744:	f052                	sd	s4,32(sp)
    80003746:	ec56                	sd	s5,24(sp)
    80003748:	e85a                	sd	s6,16(sp)
    8000374a:	e45e                	sd	s7,8(sp)
    8000374c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000374e:	0001c717          	auipc	a4,0x1c
    80003752:	47672703          	lw	a4,1142(a4) # 8001fbc4 <sb+0xc>
    80003756:	4785                	li	a5,1
    80003758:	04e7fa63          	bgeu	a5,a4,800037ac <ialloc+0x74>
    8000375c:	8aaa                	mv	s5,a0
    8000375e:	8bae                	mv	s7,a1
    80003760:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003762:	0001ca17          	auipc	s4,0x1c
    80003766:	456a0a13          	addi	s4,s4,1110 # 8001fbb8 <sb>
    8000376a:	00048b1b          	sext.w	s6,s1
    8000376e:	0044d593          	srli	a1,s1,0x4
    80003772:	018a2783          	lw	a5,24(s4)
    80003776:	9dbd                	addw	a1,a1,a5
    80003778:	8556                	mv	a0,s5
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	954080e7          	jalr	-1708(ra) # 800030ce <bread>
    80003782:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003784:	05850993          	addi	s3,a0,88
    80003788:	00f4f793          	andi	a5,s1,15
    8000378c:	079a                	slli	a5,a5,0x6
    8000378e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003790:	00099783          	lh	a5,0(s3)
    80003794:	c785                	beqz	a5,800037bc <ialloc+0x84>
    brelse(bp);
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	a68080e7          	jalr	-1432(ra) # 800031fe <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000379e:	0485                	addi	s1,s1,1
    800037a0:	00ca2703          	lw	a4,12(s4)
    800037a4:	0004879b          	sext.w	a5,s1
    800037a8:	fce7e1e3          	bltu	a5,a4,8000376a <ialloc+0x32>
  panic("ialloc: no inodes");
    800037ac:	00005517          	auipc	a0,0x5
    800037b0:	ea450513          	addi	a0,a0,-348 # 80008650 <syscalls+0x178>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800037bc:	04000613          	li	a2,64
    800037c0:	4581                	li	a1,0
    800037c2:	854e                	mv	a0,s3
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	51c080e7          	jalr	1308(ra) # 80000ce0 <memset>
      dip->type = type;
    800037cc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037d0:	854a                	mv	a0,s2
    800037d2:	00001097          	auipc	ra,0x1
    800037d6:	ca8080e7          	jalr	-856(ra) # 8000447a <log_write>
      brelse(bp);
    800037da:	854a                	mv	a0,s2
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	a22080e7          	jalr	-1502(ra) # 800031fe <brelse>
      return iget(dev, inum);
    800037e4:	85da                	mv	a1,s6
    800037e6:	8556                	mv	a0,s5
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	db4080e7          	jalr	-588(ra) # 8000359c <iget>
}
    800037f0:	60a6                	ld	ra,72(sp)
    800037f2:	6406                	ld	s0,64(sp)
    800037f4:	74e2                	ld	s1,56(sp)
    800037f6:	7942                	ld	s2,48(sp)
    800037f8:	79a2                	ld	s3,40(sp)
    800037fa:	7a02                	ld	s4,32(sp)
    800037fc:	6ae2                	ld	s5,24(sp)
    800037fe:	6b42                	ld	s6,16(sp)
    80003800:	6ba2                	ld	s7,8(sp)
    80003802:	6161                	addi	sp,sp,80
    80003804:	8082                	ret

0000000080003806 <iupdate>:
{
    80003806:	1101                	addi	sp,sp,-32
    80003808:	ec06                	sd	ra,24(sp)
    8000380a:	e822                	sd	s0,16(sp)
    8000380c:	e426                	sd	s1,8(sp)
    8000380e:	e04a                	sd	s2,0(sp)
    80003810:	1000                	addi	s0,sp,32
    80003812:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003814:	415c                	lw	a5,4(a0)
    80003816:	0047d79b          	srliw	a5,a5,0x4
    8000381a:	0001c597          	auipc	a1,0x1c
    8000381e:	3b65a583          	lw	a1,950(a1) # 8001fbd0 <sb+0x18>
    80003822:	9dbd                	addw	a1,a1,a5
    80003824:	4108                	lw	a0,0(a0)
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	8a8080e7          	jalr	-1880(ra) # 800030ce <bread>
    8000382e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003830:	05850793          	addi	a5,a0,88
    80003834:	40c8                	lw	a0,4(s1)
    80003836:	893d                	andi	a0,a0,15
    80003838:	051a                	slli	a0,a0,0x6
    8000383a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000383c:	04449703          	lh	a4,68(s1)
    80003840:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003844:	04649703          	lh	a4,70(s1)
    80003848:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000384c:	04849703          	lh	a4,72(s1)
    80003850:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003854:	04a49703          	lh	a4,74(s1)
    80003858:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000385c:	44f8                	lw	a4,76(s1)
    8000385e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003860:	03400613          	li	a2,52
    80003864:	05048593          	addi	a1,s1,80
    80003868:	0531                	addi	a0,a0,12
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	4d6080e7          	jalr	1238(ra) # 80000d40 <memmove>
  log_write(bp);
    80003872:	854a                	mv	a0,s2
    80003874:	00001097          	auipc	ra,0x1
    80003878:	c06080e7          	jalr	-1018(ra) # 8000447a <log_write>
  brelse(bp);
    8000387c:	854a                	mv	a0,s2
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	980080e7          	jalr	-1664(ra) # 800031fe <brelse>
}
    80003886:	60e2                	ld	ra,24(sp)
    80003888:	6442                	ld	s0,16(sp)
    8000388a:	64a2                	ld	s1,8(sp)
    8000388c:	6902                	ld	s2,0(sp)
    8000388e:	6105                	addi	sp,sp,32
    80003890:	8082                	ret

0000000080003892 <idup>:
{
    80003892:	1101                	addi	sp,sp,-32
    80003894:	ec06                	sd	ra,24(sp)
    80003896:	e822                	sd	s0,16(sp)
    80003898:	e426                	sd	s1,8(sp)
    8000389a:	1000                	addi	s0,sp,32
    8000389c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000389e:	0001c517          	auipc	a0,0x1c
    800038a2:	33a50513          	addi	a0,a0,826 # 8001fbd8 <itable>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	33e080e7          	jalr	830(ra) # 80000be4 <acquire>
  ip->ref++;
    800038ae:	449c                	lw	a5,8(s1)
    800038b0:	2785                	addiw	a5,a5,1
    800038b2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038b4:	0001c517          	auipc	a0,0x1c
    800038b8:	32450513          	addi	a0,a0,804 # 8001fbd8 <itable>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	3dc080e7          	jalr	988(ra) # 80000c98 <release>
}
    800038c4:	8526                	mv	a0,s1
    800038c6:	60e2                	ld	ra,24(sp)
    800038c8:	6442                	ld	s0,16(sp)
    800038ca:	64a2                	ld	s1,8(sp)
    800038cc:	6105                	addi	sp,sp,32
    800038ce:	8082                	ret

00000000800038d0 <ilock>:
{
    800038d0:	1101                	addi	sp,sp,-32
    800038d2:	ec06                	sd	ra,24(sp)
    800038d4:	e822                	sd	s0,16(sp)
    800038d6:	e426                	sd	s1,8(sp)
    800038d8:	e04a                	sd	s2,0(sp)
    800038da:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038dc:	c115                	beqz	a0,80003900 <ilock+0x30>
    800038de:	84aa                	mv	s1,a0
    800038e0:	451c                	lw	a5,8(a0)
    800038e2:	00f05f63          	blez	a5,80003900 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038e6:	0541                	addi	a0,a0,16
    800038e8:	00001097          	auipc	ra,0x1
    800038ec:	cb2080e7          	jalr	-846(ra) # 8000459a <acquiresleep>
  if(ip->valid == 0){
    800038f0:	40bc                	lw	a5,64(s1)
    800038f2:	cf99                	beqz	a5,80003910 <ilock+0x40>
}
    800038f4:	60e2                	ld	ra,24(sp)
    800038f6:	6442                	ld	s0,16(sp)
    800038f8:	64a2                	ld	s1,8(sp)
    800038fa:	6902                	ld	s2,0(sp)
    800038fc:	6105                	addi	sp,sp,32
    800038fe:	8082                	ret
    panic("ilock");
    80003900:	00005517          	auipc	a0,0x5
    80003904:	d6850513          	addi	a0,a0,-664 # 80008668 <syscalls+0x190>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	c36080e7          	jalr	-970(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003910:	40dc                	lw	a5,4(s1)
    80003912:	0047d79b          	srliw	a5,a5,0x4
    80003916:	0001c597          	auipc	a1,0x1c
    8000391a:	2ba5a583          	lw	a1,698(a1) # 8001fbd0 <sb+0x18>
    8000391e:	9dbd                	addw	a1,a1,a5
    80003920:	4088                	lw	a0,0(s1)
    80003922:	fffff097          	auipc	ra,0xfffff
    80003926:	7ac080e7          	jalr	1964(ra) # 800030ce <bread>
    8000392a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000392c:	05850593          	addi	a1,a0,88
    80003930:	40dc                	lw	a5,4(s1)
    80003932:	8bbd                	andi	a5,a5,15
    80003934:	079a                	slli	a5,a5,0x6
    80003936:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003938:	00059783          	lh	a5,0(a1)
    8000393c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003940:	00259783          	lh	a5,2(a1)
    80003944:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003948:	00459783          	lh	a5,4(a1)
    8000394c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003950:	00659783          	lh	a5,6(a1)
    80003954:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003958:	459c                	lw	a5,8(a1)
    8000395a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000395c:	03400613          	li	a2,52
    80003960:	05b1                	addi	a1,a1,12
    80003962:	05048513          	addi	a0,s1,80
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	3da080e7          	jalr	986(ra) # 80000d40 <memmove>
    brelse(bp);
    8000396e:	854a                	mv	a0,s2
    80003970:	00000097          	auipc	ra,0x0
    80003974:	88e080e7          	jalr	-1906(ra) # 800031fe <brelse>
    ip->valid = 1;
    80003978:	4785                	li	a5,1
    8000397a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000397c:	04449783          	lh	a5,68(s1)
    80003980:	fbb5                	bnez	a5,800038f4 <ilock+0x24>
      panic("ilock: no type");
    80003982:	00005517          	auipc	a0,0x5
    80003986:	cee50513          	addi	a0,a0,-786 # 80008670 <syscalls+0x198>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	bb4080e7          	jalr	-1100(ra) # 8000053e <panic>

0000000080003992 <iunlock>:
{
    80003992:	1101                	addi	sp,sp,-32
    80003994:	ec06                	sd	ra,24(sp)
    80003996:	e822                	sd	s0,16(sp)
    80003998:	e426                	sd	s1,8(sp)
    8000399a:	e04a                	sd	s2,0(sp)
    8000399c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000399e:	c905                	beqz	a0,800039ce <iunlock+0x3c>
    800039a0:	84aa                	mv	s1,a0
    800039a2:	01050913          	addi	s2,a0,16
    800039a6:	854a                	mv	a0,s2
    800039a8:	00001097          	auipc	ra,0x1
    800039ac:	c8c080e7          	jalr	-884(ra) # 80004634 <holdingsleep>
    800039b0:	cd19                	beqz	a0,800039ce <iunlock+0x3c>
    800039b2:	449c                	lw	a5,8(s1)
    800039b4:	00f05d63          	blez	a5,800039ce <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039b8:	854a                	mv	a0,s2
    800039ba:	00001097          	auipc	ra,0x1
    800039be:	c36080e7          	jalr	-970(ra) # 800045f0 <releasesleep>
}
    800039c2:	60e2                	ld	ra,24(sp)
    800039c4:	6442                	ld	s0,16(sp)
    800039c6:	64a2                	ld	s1,8(sp)
    800039c8:	6902                	ld	s2,0(sp)
    800039ca:	6105                	addi	sp,sp,32
    800039cc:	8082                	ret
    panic("iunlock");
    800039ce:	00005517          	auipc	a0,0x5
    800039d2:	cb250513          	addi	a0,a0,-846 # 80008680 <syscalls+0x1a8>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	b68080e7          	jalr	-1176(ra) # 8000053e <panic>

00000000800039de <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039de:	7179                	addi	sp,sp,-48
    800039e0:	f406                	sd	ra,40(sp)
    800039e2:	f022                	sd	s0,32(sp)
    800039e4:	ec26                	sd	s1,24(sp)
    800039e6:	e84a                	sd	s2,16(sp)
    800039e8:	e44e                	sd	s3,8(sp)
    800039ea:	e052                	sd	s4,0(sp)
    800039ec:	1800                	addi	s0,sp,48
    800039ee:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039f0:	05050493          	addi	s1,a0,80
    800039f4:	08050913          	addi	s2,a0,128
    800039f8:	a021                	j	80003a00 <itrunc+0x22>
    800039fa:	0491                	addi	s1,s1,4
    800039fc:	01248d63          	beq	s1,s2,80003a16 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a00:	408c                	lw	a1,0(s1)
    80003a02:	dde5                	beqz	a1,800039fa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a04:	0009a503          	lw	a0,0(s3)
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	90c080e7          	jalr	-1780(ra) # 80003314 <bfree>
      ip->addrs[i] = 0;
    80003a10:	0004a023          	sw	zero,0(s1)
    80003a14:	b7dd                	j	800039fa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a16:	0809a583          	lw	a1,128(s3)
    80003a1a:	e185                	bnez	a1,80003a3a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a1c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a20:	854e                	mv	a0,s3
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	de4080e7          	jalr	-540(ra) # 80003806 <iupdate>
}
    80003a2a:	70a2                	ld	ra,40(sp)
    80003a2c:	7402                	ld	s0,32(sp)
    80003a2e:	64e2                	ld	s1,24(sp)
    80003a30:	6942                	ld	s2,16(sp)
    80003a32:	69a2                	ld	s3,8(sp)
    80003a34:	6a02                	ld	s4,0(sp)
    80003a36:	6145                	addi	sp,sp,48
    80003a38:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a3a:	0009a503          	lw	a0,0(s3)
    80003a3e:	fffff097          	auipc	ra,0xfffff
    80003a42:	690080e7          	jalr	1680(ra) # 800030ce <bread>
    80003a46:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a48:	05850493          	addi	s1,a0,88
    80003a4c:	45850913          	addi	s2,a0,1112
    80003a50:	a811                	j	80003a64 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a52:	0009a503          	lw	a0,0(s3)
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	8be080e7          	jalr	-1858(ra) # 80003314 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a5e:	0491                	addi	s1,s1,4
    80003a60:	01248563          	beq	s1,s2,80003a6a <itrunc+0x8c>
      if(a[j])
    80003a64:	408c                	lw	a1,0(s1)
    80003a66:	dde5                	beqz	a1,80003a5e <itrunc+0x80>
    80003a68:	b7ed                	j	80003a52 <itrunc+0x74>
    brelse(bp);
    80003a6a:	8552                	mv	a0,s4
    80003a6c:	fffff097          	auipc	ra,0xfffff
    80003a70:	792080e7          	jalr	1938(ra) # 800031fe <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a74:	0809a583          	lw	a1,128(s3)
    80003a78:	0009a503          	lw	a0,0(s3)
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	898080e7          	jalr	-1896(ra) # 80003314 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a84:	0809a023          	sw	zero,128(s3)
    80003a88:	bf51                	j	80003a1c <itrunc+0x3e>

0000000080003a8a <iput>:
{
    80003a8a:	1101                	addi	sp,sp,-32
    80003a8c:	ec06                	sd	ra,24(sp)
    80003a8e:	e822                	sd	s0,16(sp)
    80003a90:	e426                	sd	s1,8(sp)
    80003a92:	e04a                	sd	s2,0(sp)
    80003a94:	1000                	addi	s0,sp,32
    80003a96:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a98:	0001c517          	auipc	a0,0x1c
    80003a9c:	14050513          	addi	a0,a0,320 # 8001fbd8 <itable>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	144080e7          	jalr	324(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aa8:	4498                	lw	a4,8(s1)
    80003aaa:	4785                	li	a5,1
    80003aac:	02f70363          	beq	a4,a5,80003ad2 <iput+0x48>
  ip->ref--;
    80003ab0:	449c                	lw	a5,8(s1)
    80003ab2:	37fd                	addiw	a5,a5,-1
    80003ab4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ab6:	0001c517          	auipc	a0,0x1c
    80003aba:	12250513          	addi	a0,a0,290 # 8001fbd8 <itable>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	1da080e7          	jalr	474(ra) # 80000c98 <release>
}
    80003ac6:	60e2                	ld	ra,24(sp)
    80003ac8:	6442                	ld	s0,16(sp)
    80003aca:	64a2                	ld	s1,8(sp)
    80003acc:	6902                	ld	s2,0(sp)
    80003ace:	6105                	addi	sp,sp,32
    80003ad0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ad2:	40bc                	lw	a5,64(s1)
    80003ad4:	dff1                	beqz	a5,80003ab0 <iput+0x26>
    80003ad6:	04a49783          	lh	a5,74(s1)
    80003ada:	fbf9                	bnez	a5,80003ab0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003adc:	01048913          	addi	s2,s1,16
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	00001097          	auipc	ra,0x1
    80003ae6:	ab8080e7          	jalr	-1352(ra) # 8000459a <acquiresleep>
    release(&itable.lock);
    80003aea:	0001c517          	auipc	a0,0x1c
    80003aee:	0ee50513          	addi	a0,a0,238 # 8001fbd8 <itable>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	1a6080e7          	jalr	422(ra) # 80000c98 <release>
    itrunc(ip);
    80003afa:	8526                	mv	a0,s1
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	ee2080e7          	jalr	-286(ra) # 800039de <itrunc>
    ip->type = 0;
    80003b04:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b08:	8526                	mv	a0,s1
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	cfc080e7          	jalr	-772(ra) # 80003806 <iupdate>
    ip->valid = 0;
    80003b12:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b16:	854a                	mv	a0,s2
    80003b18:	00001097          	auipc	ra,0x1
    80003b1c:	ad8080e7          	jalr	-1320(ra) # 800045f0 <releasesleep>
    acquire(&itable.lock);
    80003b20:	0001c517          	auipc	a0,0x1c
    80003b24:	0b850513          	addi	a0,a0,184 # 8001fbd8 <itable>
    80003b28:	ffffd097          	auipc	ra,0xffffd
    80003b2c:	0bc080e7          	jalr	188(ra) # 80000be4 <acquire>
    80003b30:	b741                	j	80003ab0 <iput+0x26>

0000000080003b32 <iunlockput>:
{
    80003b32:	1101                	addi	sp,sp,-32
    80003b34:	ec06                	sd	ra,24(sp)
    80003b36:	e822                	sd	s0,16(sp)
    80003b38:	e426                	sd	s1,8(sp)
    80003b3a:	1000                	addi	s0,sp,32
    80003b3c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	e54080e7          	jalr	-428(ra) # 80003992 <iunlock>
  iput(ip);
    80003b46:	8526                	mv	a0,s1
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	f42080e7          	jalr	-190(ra) # 80003a8a <iput>
}
    80003b50:	60e2                	ld	ra,24(sp)
    80003b52:	6442                	ld	s0,16(sp)
    80003b54:	64a2                	ld	s1,8(sp)
    80003b56:	6105                	addi	sp,sp,32
    80003b58:	8082                	ret

0000000080003b5a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b5a:	1141                	addi	sp,sp,-16
    80003b5c:	e422                	sd	s0,8(sp)
    80003b5e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b60:	411c                	lw	a5,0(a0)
    80003b62:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b64:	415c                	lw	a5,4(a0)
    80003b66:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b68:	04451783          	lh	a5,68(a0)
    80003b6c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b70:	04a51783          	lh	a5,74(a0)
    80003b74:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b78:	04c56783          	lwu	a5,76(a0)
    80003b7c:	e99c                	sd	a5,16(a1)
}
    80003b7e:	6422                	ld	s0,8(sp)
    80003b80:	0141                	addi	sp,sp,16
    80003b82:	8082                	ret

0000000080003b84 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b84:	457c                	lw	a5,76(a0)
    80003b86:	0ed7e963          	bltu	a5,a3,80003c78 <readi+0xf4>
{
    80003b8a:	7159                	addi	sp,sp,-112
    80003b8c:	f486                	sd	ra,104(sp)
    80003b8e:	f0a2                	sd	s0,96(sp)
    80003b90:	eca6                	sd	s1,88(sp)
    80003b92:	e8ca                	sd	s2,80(sp)
    80003b94:	e4ce                	sd	s3,72(sp)
    80003b96:	e0d2                	sd	s4,64(sp)
    80003b98:	fc56                	sd	s5,56(sp)
    80003b9a:	f85a                	sd	s6,48(sp)
    80003b9c:	f45e                	sd	s7,40(sp)
    80003b9e:	f062                	sd	s8,32(sp)
    80003ba0:	ec66                	sd	s9,24(sp)
    80003ba2:	e86a                	sd	s10,16(sp)
    80003ba4:	e46e                	sd	s11,8(sp)
    80003ba6:	1880                	addi	s0,sp,112
    80003ba8:	8baa                	mv	s7,a0
    80003baa:	8c2e                	mv	s8,a1
    80003bac:	8ab2                	mv	s5,a2
    80003bae:	84b6                	mv	s1,a3
    80003bb0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bb2:	9f35                	addw	a4,a4,a3
    return 0;
    80003bb4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bb6:	0ad76063          	bltu	a4,a3,80003c56 <readi+0xd2>
  if(off + n > ip->size)
    80003bba:	00e7f463          	bgeu	a5,a4,80003bc2 <readi+0x3e>
    n = ip->size - off;
    80003bbe:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc2:	0a0b0963          	beqz	s6,80003c74 <readi+0xf0>
    80003bc6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bcc:	5cfd                	li	s9,-1
    80003bce:	a82d                	j	80003c08 <readi+0x84>
    80003bd0:	020a1d93          	slli	s11,s4,0x20
    80003bd4:	020ddd93          	srli	s11,s11,0x20
    80003bd8:	05890613          	addi	a2,s2,88
    80003bdc:	86ee                	mv	a3,s11
    80003bde:	963a                	add	a2,a2,a4
    80003be0:	85d6                	mv	a1,s5
    80003be2:	8562                	mv	a0,s8
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	ae4080e7          	jalr	-1308(ra) # 800026c8 <either_copyout>
    80003bec:	05950d63          	beq	a0,s9,80003c46 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bf0:	854a                	mv	a0,s2
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	60c080e7          	jalr	1548(ra) # 800031fe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bfa:	013a09bb          	addw	s3,s4,s3
    80003bfe:	009a04bb          	addw	s1,s4,s1
    80003c02:	9aee                	add	s5,s5,s11
    80003c04:	0569f763          	bgeu	s3,s6,80003c52 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c08:	000ba903          	lw	s2,0(s7)
    80003c0c:	00a4d59b          	srliw	a1,s1,0xa
    80003c10:	855e                	mv	a0,s7
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	8b0080e7          	jalr	-1872(ra) # 800034c2 <bmap>
    80003c1a:	0005059b          	sext.w	a1,a0
    80003c1e:	854a                	mv	a0,s2
    80003c20:	fffff097          	auipc	ra,0xfffff
    80003c24:	4ae080e7          	jalr	1198(ra) # 800030ce <bread>
    80003c28:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2a:	3ff4f713          	andi	a4,s1,1023
    80003c2e:	40ed07bb          	subw	a5,s10,a4
    80003c32:	413b06bb          	subw	a3,s6,s3
    80003c36:	8a3e                	mv	s4,a5
    80003c38:	2781                	sext.w	a5,a5
    80003c3a:	0006861b          	sext.w	a2,a3
    80003c3e:	f8f679e3          	bgeu	a2,a5,80003bd0 <readi+0x4c>
    80003c42:	8a36                	mv	s4,a3
    80003c44:	b771                	j	80003bd0 <readi+0x4c>
      brelse(bp);
    80003c46:	854a                	mv	a0,s2
    80003c48:	fffff097          	auipc	ra,0xfffff
    80003c4c:	5b6080e7          	jalr	1462(ra) # 800031fe <brelse>
      tot = -1;
    80003c50:	59fd                	li	s3,-1
  }
  return tot;
    80003c52:	0009851b          	sext.w	a0,s3
}
    80003c56:	70a6                	ld	ra,104(sp)
    80003c58:	7406                	ld	s0,96(sp)
    80003c5a:	64e6                	ld	s1,88(sp)
    80003c5c:	6946                	ld	s2,80(sp)
    80003c5e:	69a6                	ld	s3,72(sp)
    80003c60:	6a06                	ld	s4,64(sp)
    80003c62:	7ae2                	ld	s5,56(sp)
    80003c64:	7b42                	ld	s6,48(sp)
    80003c66:	7ba2                	ld	s7,40(sp)
    80003c68:	7c02                	ld	s8,32(sp)
    80003c6a:	6ce2                	ld	s9,24(sp)
    80003c6c:	6d42                	ld	s10,16(sp)
    80003c6e:	6da2                	ld	s11,8(sp)
    80003c70:	6165                	addi	sp,sp,112
    80003c72:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c74:	89da                	mv	s3,s6
    80003c76:	bff1                	j	80003c52 <readi+0xce>
    return 0;
    80003c78:	4501                	li	a0,0
}
    80003c7a:	8082                	ret

0000000080003c7c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c7c:	457c                	lw	a5,76(a0)
    80003c7e:	10d7e863          	bltu	a5,a3,80003d8e <writei+0x112>
{
    80003c82:	7159                	addi	sp,sp,-112
    80003c84:	f486                	sd	ra,104(sp)
    80003c86:	f0a2                	sd	s0,96(sp)
    80003c88:	eca6                	sd	s1,88(sp)
    80003c8a:	e8ca                	sd	s2,80(sp)
    80003c8c:	e4ce                	sd	s3,72(sp)
    80003c8e:	e0d2                	sd	s4,64(sp)
    80003c90:	fc56                	sd	s5,56(sp)
    80003c92:	f85a                	sd	s6,48(sp)
    80003c94:	f45e                	sd	s7,40(sp)
    80003c96:	f062                	sd	s8,32(sp)
    80003c98:	ec66                	sd	s9,24(sp)
    80003c9a:	e86a                	sd	s10,16(sp)
    80003c9c:	e46e                	sd	s11,8(sp)
    80003c9e:	1880                	addi	s0,sp,112
    80003ca0:	8b2a                	mv	s6,a0
    80003ca2:	8c2e                	mv	s8,a1
    80003ca4:	8ab2                	mv	s5,a2
    80003ca6:	8936                	mv	s2,a3
    80003ca8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003caa:	00e687bb          	addw	a5,a3,a4
    80003cae:	0ed7e263          	bltu	a5,a3,80003d92 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cb2:	00043737          	lui	a4,0x43
    80003cb6:	0ef76063          	bltu	a4,a5,80003d96 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cba:	0c0b8863          	beqz	s7,80003d8a <writei+0x10e>
    80003cbe:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cc4:	5cfd                	li	s9,-1
    80003cc6:	a091                	j	80003d0a <writei+0x8e>
    80003cc8:	02099d93          	slli	s11,s3,0x20
    80003ccc:	020ddd93          	srli	s11,s11,0x20
    80003cd0:	05848513          	addi	a0,s1,88
    80003cd4:	86ee                	mv	a3,s11
    80003cd6:	8656                	mv	a2,s5
    80003cd8:	85e2                	mv	a1,s8
    80003cda:	953a                	add	a0,a0,a4
    80003cdc:	fffff097          	auipc	ra,0xfffff
    80003ce0:	a42080e7          	jalr	-1470(ra) # 8000271e <either_copyin>
    80003ce4:	07950263          	beq	a0,s9,80003d48 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ce8:	8526                	mv	a0,s1
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	790080e7          	jalr	1936(ra) # 8000447a <log_write>
    brelse(bp);
    80003cf2:	8526                	mv	a0,s1
    80003cf4:	fffff097          	auipc	ra,0xfffff
    80003cf8:	50a080e7          	jalr	1290(ra) # 800031fe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cfc:	01498a3b          	addw	s4,s3,s4
    80003d00:	0129893b          	addw	s2,s3,s2
    80003d04:	9aee                	add	s5,s5,s11
    80003d06:	057a7663          	bgeu	s4,s7,80003d52 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d0a:	000b2483          	lw	s1,0(s6)
    80003d0e:	00a9559b          	srliw	a1,s2,0xa
    80003d12:	855a                	mv	a0,s6
    80003d14:	fffff097          	auipc	ra,0xfffff
    80003d18:	7ae080e7          	jalr	1966(ra) # 800034c2 <bmap>
    80003d1c:	0005059b          	sext.w	a1,a0
    80003d20:	8526                	mv	a0,s1
    80003d22:	fffff097          	auipc	ra,0xfffff
    80003d26:	3ac080e7          	jalr	940(ra) # 800030ce <bread>
    80003d2a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d2c:	3ff97713          	andi	a4,s2,1023
    80003d30:	40ed07bb          	subw	a5,s10,a4
    80003d34:	414b86bb          	subw	a3,s7,s4
    80003d38:	89be                	mv	s3,a5
    80003d3a:	2781                	sext.w	a5,a5
    80003d3c:	0006861b          	sext.w	a2,a3
    80003d40:	f8f674e3          	bgeu	a2,a5,80003cc8 <writei+0x4c>
    80003d44:	89b6                	mv	s3,a3
    80003d46:	b749                	j	80003cc8 <writei+0x4c>
      brelse(bp);
    80003d48:	8526                	mv	a0,s1
    80003d4a:	fffff097          	auipc	ra,0xfffff
    80003d4e:	4b4080e7          	jalr	1204(ra) # 800031fe <brelse>
  }

  if(off > ip->size)
    80003d52:	04cb2783          	lw	a5,76(s6)
    80003d56:	0127f463          	bgeu	a5,s2,80003d5e <writei+0xe2>
    ip->size = off;
    80003d5a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d5e:	855a                	mv	a0,s6
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	aa6080e7          	jalr	-1370(ra) # 80003806 <iupdate>

  return tot;
    80003d68:	000a051b          	sext.w	a0,s4
}
    80003d6c:	70a6                	ld	ra,104(sp)
    80003d6e:	7406                	ld	s0,96(sp)
    80003d70:	64e6                	ld	s1,88(sp)
    80003d72:	6946                	ld	s2,80(sp)
    80003d74:	69a6                	ld	s3,72(sp)
    80003d76:	6a06                	ld	s4,64(sp)
    80003d78:	7ae2                	ld	s5,56(sp)
    80003d7a:	7b42                	ld	s6,48(sp)
    80003d7c:	7ba2                	ld	s7,40(sp)
    80003d7e:	7c02                	ld	s8,32(sp)
    80003d80:	6ce2                	ld	s9,24(sp)
    80003d82:	6d42                	ld	s10,16(sp)
    80003d84:	6da2                	ld	s11,8(sp)
    80003d86:	6165                	addi	sp,sp,112
    80003d88:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d8a:	8a5e                	mv	s4,s7
    80003d8c:	bfc9                	j	80003d5e <writei+0xe2>
    return -1;
    80003d8e:	557d                	li	a0,-1
}
    80003d90:	8082                	ret
    return -1;
    80003d92:	557d                	li	a0,-1
    80003d94:	bfe1                	j	80003d6c <writei+0xf0>
    return -1;
    80003d96:	557d                	li	a0,-1
    80003d98:	bfd1                	j	80003d6c <writei+0xf0>

0000000080003d9a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d9a:	1141                	addi	sp,sp,-16
    80003d9c:	e406                	sd	ra,8(sp)
    80003d9e:	e022                	sd	s0,0(sp)
    80003da0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003da2:	4639                	li	a2,14
    80003da4:	ffffd097          	auipc	ra,0xffffd
    80003da8:	014080e7          	jalr	20(ra) # 80000db8 <strncmp>
}
    80003dac:	60a2                	ld	ra,8(sp)
    80003dae:	6402                	ld	s0,0(sp)
    80003db0:	0141                	addi	sp,sp,16
    80003db2:	8082                	ret

0000000080003db4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003db4:	7139                	addi	sp,sp,-64
    80003db6:	fc06                	sd	ra,56(sp)
    80003db8:	f822                	sd	s0,48(sp)
    80003dba:	f426                	sd	s1,40(sp)
    80003dbc:	f04a                	sd	s2,32(sp)
    80003dbe:	ec4e                	sd	s3,24(sp)
    80003dc0:	e852                	sd	s4,16(sp)
    80003dc2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dc4:	04451703          	lh	a4,68(a0)
    80003dc8:	4785                	li	a5,1
    80003dca:	00f71a63          	bne	a4,a5,80003dde <dirlookup+0x2a>
    80003dce:	892a                	mv	s2,a0
    80003dd0:	89ae                	mv	s3,a1
    80003dd2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd4:	457c                	lw	a5,76(a0)
    80003dd6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dd8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dda:	e79d                	bnez	a5,80003e08 <dirlookup+0x54>
    80003ddc:	a8a5                	j	80003e54 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dde:	00005517          	auipc	a0,0x5
    80003de2:	8aa50513          	addi	a0,a0,-1878 # 80008688 <syscalls+0x1b0>
    80003de6:	ffffc097          	auipc	ra,0xffffc
    80003dea:	758080e7          	jalr	1880(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dee:	00005517          	auipc	a0,0x5
    80003df2:	8b250513          	addi	a0,a0,-1870 # 800086a0 <syscalls+0x1c8>
    80003df6:	ffffc097          	auipc	ra,0xffffc
    80003dfa:	748080e7          	jalr	1864(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfe:	24c1                	addiw	s1,s1,16
    80003e00:	04c92783          	lw	a5,76(s2)
    80003e04:	04f4f763          	bgeu	s1,a5,80003e52 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e08:	4741                	li	a4,16
    80003e0a:	86a6                	mv	a3,s1
    80003e0c:	fc040613          	addi	a2,s0,-64
    80003e10:	4581                	li	a1,0
    80003e12:	854a                	mv	a0,s2
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	d70080e7          	jalr	-656(ra) # 80003b84 <readi>
    80003e1c:	47c1                	li	a5,16
    80003e1e:	fcf518e3          	bne	a0,a5,80003dee <dirlookup+0x3a>
    if(de.inum == 0)
    80003e22:	fc045783          	lhu	a5,-64(s0)
    80003e26:	dfe1                	beqz	a5,80003dfe <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e28:	fc240593          	addi	a1,s0,-62
    80003e2c:	854e                	mv	a0,s3
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	f6c080e7          	jalr	-148(ra) # 80003d9a <namecmp>
    80003e36:	f561                	bnez	a0,80003dfe <dirlookup+0x4a>
      if(poff)
    80003e38:	000a0463          	beqz	s4,80003e40 <dirlookup+0x8c>
        *poff = off;
    80003e3c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e40:	fc045583          	lhu	a1,-64(s0)
    80003e44:	00092503          	lw	a0,0(s2)
    80003e48:	fffff097          	auipc	ra,0xfffff
    80003e4c:	754080e7          	jalr	1876(ra) # 8000359c <iget>
    80003e50:	a011                	j	80003e54 <dirlookup+0xa0>
  return 0;
    80003e52:	4501                	li	a0,0
}
    80003e54:	70e2                	ld	ra,56(sp)
    80003e56:	7442                	ld	s0,48(sp)
    80003e58:	74a2                	ld	s1,40(sp)
    80003e5a:	7902                	ld	s2,32(sp)
    80003e5c:	69e2                	ld	s3,24(sp)
    80003e5e:	6a42                	ld	s4,16(sp)
    80003e60:	6121                	addi	sp,sp,64
    80003e62:	8082                	ret

0000000080003e64 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e64:	711d                	addi	sp,sp,-96
    80003e66:	ec86                	sd	ra,88(sp)
    80003e68:	e8a2                	sd	s0,80(sp)
    80003e6a:	e4a6                	sd	s1,72(sp)
    80003e6c:	e0ca                	sd	s2,64(sp)
    80003e6e:	fc4e                	sd	s3,56(sp)
    80003e70:	f852                	sd	s4,48(sp)
    80003e72:	f456                	sd	s5,40(sp)
    80003e74:	f05a                	sd	s6,32(sp)
    80003e76:	ec5e                	sd	s7,24(sp)
    80003e78:	e862                	sd	s8,16(sp)
    80003e7a:	e466                	sd	s9,8(sp)
    80003e7c:	1080                	addi	s0,sp,96
    80003e7e:	84aa                	mv	s1,a0
    80003e80:	8b2e                	mv	s6,a1
    80003e82:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e84:	00054703          	lbu	a4,0(a0)
    80003e88:	02f00793          	li	a5,47
    80003e8c:	02f70363          	beq	a4,a5,80003eb2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e90:	ffffe097          	auipc	ra,0xffffe
    80003e94:	b40080e7          	jalr	-1216(ra) # 800019d0 <myproc>
    80003e98:	16053503          	ld	a0,352(a0)
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	9f6080e7          	jalr	-1546(ra) # 80003892 <idup>
    80003ea4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ea6:	02f00913          	li	s2,47
  len = path - s;
    80003eaa:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003eac:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003eae:	4c05                	li	s8,1
    80003eb0:	a865                	j	80003f68 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003eb2:	4585                	li	a1,1
    80003eb4:	4505                	li	a0,1
    80003eb6:	fffff097          	auipc	ra,0xfffff
    80003eba:	6e6080e7          	jalr	1766(ra) # 8000359c <iget>
    80003ebe:	89aa                	mv	s3,a0
    80003ec0:	b7dd                	j	80003ea6 <namex+0x42>
      iunlockput(ip);
    80003ec2:	854e                	mv	a0,s3
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	c6e080e7          	jalr	-914(ra) # 80003b32 <iunlockput>
      return 0;
    80003ecc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ece:	854e                	mv	a0,s3
    80003ed0:	60e6                	ld	ra,88(sp)
    80003ed2:	6446                	ld	s0,80(sp)
    80003ed4:	64a6                	ld	s1,72(sp)
    80003ed6:	6906                	ld	s2,64(sp)
    80003ed8:	79e2                	ld	s3,56(sp)
    80003eda:	7a42                	ld	s4,48(sp)
    80003edc:	7aa2                	ld	s5,40(sp)
    80003ede:	7b02                	ld	s6,32(sp)
    80003ee0:	6be2                	ld	s7,24(sp)
    80003ee2:	6c42                	ld	s8,16(sp)
    80003ee4:	6ca2                	ld	s9,8(sp)
    80003ee6:	6125                	addi	sp,sp,96
    80003ee8:	8082                	ret
      iunlock(ip);
    80003eea:	854e                	mv	a0,s3
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	aa6080e7          	jalr	-1370(ra) # 80003992 <iunlock>
      return ip;
    80003ef4:	bfe9                	j	80003ece <namex+0x6a>
      iunlockput(ip);
    80003ef6:	854e                	mv	a0,s3
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	c3a080e7          	jalr	-966(ra) # 80003b32 <iunlockput>
      return 0;
    80003f00:	89d2                	mv	s3,s4
    80003f02:	b7f1                	j	80003ece <namex+0x6a>
  len = path - s;
    80003f04:	40b48633          	sub	a2,s1,a1
    80003f08:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f0c:	094cd463          	bge	s9,s4,80003f94 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f10:	4639                	li	a2,14
    80003f12:	8556                	mv	a0,s5
    80003f14:	ffffd097          	auipc	ra,0xffffd
    80003f18:	e2c080e7          	jalr	-468(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f1c:	0004c783          	lbu	a5,0(s1)
    80003f20:	01279763          	bne	a5,s2,80003f2e <namex+0xca>
    path++;
    80003f24:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f26:	0004c783          	lbu	a5,0(s1)
    80003f2a:	ff278de3          	beq	a5,s2,80003f24 <namex+0xc0>
    ilock(ip);
    80003f2e:	854e                	mv	a0,s3
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	9a0080e7          	jalr	-1632(ra) # 800038d0 <ilock>
    if(ip->type != T_DIR){
    80003f38:	04499783          	lh	a5,68(s3)
    80003f3c:	f98793e3          	bne	a5,s8,80003ec2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f40:	000b0563          	beqz	s6,80003f4a <namex+0xe6>
    80003f44:	0004c783          	lbu	a5,0(s1)
    80003f48:	d3cd                	beqz	a5,80003eea <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f4a:	865e                	mv	a2,s7
    80003f4c:	85d6                	mv	a1,s5
    80003f4e:	854e                	mv	a0,s3
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	e64080e7          	jalr	-412(ra) # 80003db4 <dirlookup>
    80003f58:	8a2a                	mv	s4,a0
    80003f5a:	dd51                	beqz	a0,80003ef6 <namex+0x92>
    iunlockput(ip);
    80003f5c:	854e                	mv	a0,s3
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	bd4080e7          	jalr	-1068(ra) # 80003b32 <iunlockput>
    ip = next;
    80003f66:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f68:	0004c783          	lbu	a5,0(s1)
    80003f6c:	05279763          	bne	a5,s2,80003fba <namex+0x156>
    path++;
    80003f70:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f72:	0004c783          	lbu	a5,0(s1)
    80003f76:	ff278de3          	beq	a5,s2,80003f70 <namex+0x10c>
  if(*path == 0)
    80003f7a:	c79d                	beqz	a5,80003fa8 <namex+0x144>
    path++;
    80003f7c:	85a6                	mv	a1,s1
  len = path - s;
    80003f7e:	8a5e                	mv	s4,s7
    80003f80:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f82:	01278963          	beq	a5,s2,80003f94 <namex+0x130>
    80003f86:	dfbd                	beqz	a5,80003f04 <namex+0xa0>
    path++;
    80003f88:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f8a:	0004c783          	lbu	a5,0(s1)
    80003f8e:	ff279ce3          	bne	a5,s2,80003f86 <namex+0x122>
    80003f92:	bf8d                	j	80003f04 <namex+0xa0>
    memmove(name, s, len);
    80003f94:	2601                	sext.w	a2,a2
    80003f96:	8556                	mv	a0,s5
    80003f98:	ffffd097          	auipc	ra,0xffffd
    80003f9c:	da8080e7          	jalr	-600(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003fa0:	9a56                	add	s4,s4,s5
    80003fa2:	000a0023          	sb	zero,0(s4)
    80003fa6:	bf9d                	j	80003f1c <namex+0xb8>
  if(nameiparent){
    80003fa8:	f20b03e3          	beqz	s6,80003ece <namex+0x6a>
    iput(ip);
    80003fac:	854e                	mv	a0,s3
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	adc080e7          	jalr	-1316(ra) # 80003a8a <iput>
    return 0;
    80003fb6:	4981                	li	s3,0
    80003fb8:	bf19                	j	80003ece <namex+0x6a>
  if(*path == 0)
    80003fba:	d7fd                	beqz	a5,80003fa8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fbc:	0004c783          	lbu	a5,0(s1)
    80003fc0:	85a6                	mv	a1,s1
    80003fc2:	b7d1                	j	80003f86 <namex+0x122>

0000000080003fc4 <dirlink>:
{
    80003fc4:	7139                	addi	sp,sp,-64
    80003fc6:	fc06                	sd	ra,56(sp)
    80003fc8:	f822                	sd	s0,48(sp)
    80003fca:	f426                	sd	s1,40(sp)
    80003fcc:	f04a                	sd	s2,32(sp)
    80003fce:	ec4e                	sd	s3,24(sp)
    80003fd0:	e852                	sd	s4,16(sp)
    80003fd2:	0080                	addi	s0,sp,64
    80003fd4:	892a                	mv	s2,a0
    80003fd6:	8a2e                	mv	s4,a1
    80003fd8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fda:	4601                	li	a2,0
    80003fdc:	00000097          	auipc	ra,0x0
    80003fe0:	dd8080e7          	jalr	-552(ra) # 80003db4 <dirlookup>
    80003fe4:	e93d                	bnez	a0,8000405a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe6:	04c92483          	lw	s1,76(s2)
    80003fea:	c49d                	beqz	s1,80004018 <dirlink+0x54>
    80003fec:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fee:	4741                	li	a4,16
    80003ff0:	86a6                	mv	a3,s1
    80003ff2:	fc040613          	addi	a2,s0,-64
    80003ff6:	4581                	li	a1,0
    80003ff8:	854a                	mv	a0,s2
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	b8a080e7          	jalr	-1142(ra) # 80003b84 <readi>
    80004002:	47c1                	li	a5,16
    80004004:	06f51163          	bne	a0,a5,80004066 <dirlink+0xa2>
    if(de.inum == 0)
    80004008:	fc045783          	lhu	a5,-64(s0)
    8000400c:	c791                	beqz	a5,80004018 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400e:	24c1                	addiw	s1,s1,16
    80004010:	04c92783          	lw	a5,76(s2)
    80004014:	fcf4ede3          	bltu	s1,a5,80003fee <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004018:	4639                	li	a2,14
    8000401a:	85d2                	mv	a1,s4
    8000401c:	fc240513          	addi	a0,s0,-62
    80004020:	ffffd097          	auipc	ra,0xffffd
    80004024:	dd4080e7          	jalr	-556(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004028:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402c:	4741                	li	a4,16
    8000402e:	86a6                	mv	a3,s1
    80004030:	fc040613          	addi	a2,s0,-64
    80004034:	4581                	li	a1,0
    80004036:	854a                	mv	a0,s2
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	c44080e7          	jalr	-956(ra) # 80003c7c <writei>
    80004040:	872a                	mv	a4,a0
    80004042:	47c1                	li	a5,16
  return 0;
    80004044:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004046:	02f71863          	bne	a4,a5,80004076 <dirlink+0xb2>
}
    8000404a:	70e2                	ld	ra,56(sp)
    8000404c:	7442                	ld	s0,48(sp)
    8000404e:	74a2                	ld	s1,40(sp)
    80004050:	7902                	ld	s2,32(sp)
    80004052:	69e2                	ld	s3,24(sp)
    80004054:	6a42                	ld	s4,16(sp)
    80004056:	6121                	addi	sp,sp,64
    80004058:	8082                	ret
    iput(ip);
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	a30080e7          	jalr	-1488(ra) # 80003a8a <iput>
    return -1;
    80004062:	557d                	li	a0,-1
    80004064:	b7dd                	j	8000404a <dirlink+0x86>
      panic("dirlink read");
    80004066:	00004517          	auipc	a0,0x4
    8000406a:	64a50513          	addi	a0,a0,1610 # 800086b0 <syscalls+0x1d8>
    8000406e:	ffffc097          	auipc	ra,0xffffc
    80004072:	4d0080e7          	jalr	1232(ra) # 8000053e <panic>
    panic("dirlink");
    80004076:	00004517          	auipc	a0,0x4
    8000407a:	74a50513          	addi	a0,a0,1866 # 800087c0 <syscalls+0x2e8>
    8000407e:	ffffc097          	auipc	ra,0xffffc
    80004082:	4c0080e7          	jalr	1216(ra) # 8000053e <panic>

0000000080004086 <namei>:

struct inode*
namei(char *path)
{
    80004086:	1101                	addi	sp,sp,-32
    80004088:	ec06                	sd	ra,24(sp)
    8000408a:	e822                	sd	s0,16(sp)
    8000408c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000408e:	fe040613          	addi	a2,s0,-32
    80004092:	4581                	li	a1,0
    80004094:	00000097          	auipc	ra,0x0
    80004098:	dd0080e7          	jalr	-560(ra) # 80003e64 <namex>
}
    8000409c:	60e2                	ld	ra,24(sp)
    8000409e:	6442                	ld	s0,16(sp)
    800040a0:	6105                	addi	sp,sp,32
    800040a2:	8082                	ret

00000000800040a4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040a4:	1141                	addi	sp,sp,-16
    800040a6:	e406                	sd	ra,8(sp)
    800040a8:	e022                	sd	s0,0(sp)
    800040aa:	0800                	addi	s0,sp,16
    800040ac:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040ae:	4585                	li	a1,1
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	db4080e7          	jalr	-588(ra) # 80003e64 <namex>
}
    800040b8:	60a2                	ld	ra,8(sp)
    800040ba:	6402                	ld	s0,0(sp)
    800040bc:	0141                	addi	sp,sp,16
    800040be:	8082                	ret

00000000800040c0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040c0:	1101                	addi	sp,sp,-32
    800040c2:	ec06                	sd	ra,24(sp)
    800040c4:	e822                	sd	s0,16(sp)
    800040c6:	e426                	sd	s1,8(sp)
    800040c8:	e04a                	sd	s2,0(sp)
    800040ca:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040cc:	0001d917          	auipc	s2,0x1d
    800040d0:	5b490913          	addi	s2,s2,1460 # 80021680 <log>
    800040d4:	01892583          	lw	a1,24(s2)
    800040d8:	02892503          	lw	a0,40(s2)
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	ff2080e7          	jalr	-14(ra) # 800030ce <bread>
    800040e4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040e6:	02c92683          	lw	a3,44(s2)
    800040ea:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040ec:	02d05763          	blez	a3,8000411a <write_head+0x5a>
    800040f0:	0001d797          	auipc	a5,0x1d
    800040f4:	5c078793          	addi	a5,a5,1472 # 800216b0 <log+0x30>
    800040f8:	05c50713          	addi	a4,a0,92
    800040fc:	36fd                	addiw	a3,a3,-1
    800040fe:	1682                	slli	a3,a3,0x20
    80004100:	9281                	srli	a3,a3,0x20
    80004102:	068a                	slli	a3,a3,0x2
    80004104:	0001d617          	auipc	a2,0x1d
    80004108:	5b060613          	addi	a2,a2,1456 # 800216b4 <log+0x34>
    8000410c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000410e:	4390                	lw	a2,0(a5)
    80004110:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004112:	0791                	addi	a5,a5,4
    80004114:	0711                	addi	a4,a4,4
    80004116:	fed79ce3          	bne	a5,a3,8000410e <write_head+0x4e>
  }
  bwrite(buf);
    8000411a:	8526                	mv	a0,s1
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	0a4080e7          	jalr	164(ra) # 800031c0 <bwrite>
  brelse(buf);
    80004124:	8526                	mv	a0,s1
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	0d8080e7          	jalr	216(ra) # 800031fe <brelse>
}
    8000412e:	60e2                	ld	ra,24(sp)
    80004130:	6442                	ld	s0,16(sp)
    80004132:	64a2                	ld	s1,8(sp)
    80004134:	6902                	ld	s2,0(sp)
    80004136:	6105                	addi	sp,sp,32
    80004138:	8082                	ret

000000008000413a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413a:	0001d797          	auipc	a5,0x1d
    8000413e:	5727a783          	lw	a5,1394(a5) # 800216ac <log+0x2c>
    80004142:	0af05d63          	blez	a5,800041fc <install_trans+0xc2>
{
    80004146:	7139                	addi	sp,sp,-64
    80004148:	fc06                	sd	ra,56(sp)
    8000414a:	f822                	sd	s0,48(sp)
    8000414c:	f426                	sd	s1,40(sp)
    8000414e:	f04a                	sd	s2,32(sp)
    80004150:	ec4e                	sd	s3,24(sp)
    80004152:	e852                	sd	s4,16(sp)
    80004154:	e456                	sd	s5,8(sp)
    80004156:	e05a                	sd	s6,0(sp)
    80004158:	0080                	addi	s0,sp,64
    8000415a:	8b2a                	mv	s6,a0
    8000415c:	0001da97          	auipc	s5,0x1d
    80004160:	554a8a93          	addi	s5,s5,1364 # 800216b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004164:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004166:	0001d997          	auipc	s3,0x1d
    8000416a:	51a98993          	addi	s3,s3,1306 # 80021680 <log>
    8000416e:	a035                	j	8000419a <install_trans+0x60>
      bunpin(dbuf);
    80004170:	8526                	mv	a0,s1
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	166080e7          	jalr	358(ra) # 800032d8 <bunpin>
    brelse(lbuf);
    8000417a:	854a                	mv	a0,s2
    8000417c:	fffff097          	auipc	ra,0xfffff
    80004180:	082080e7          	jalr	130(ra) # 800031fe <brelse>
    brelse(dbuf);
    80004184:	8526                	mv	a0,s1
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	078080e7          	jalr	120(ra) # 800031fe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000418e:	2a05                	addiw	s4,s4,1
    80004190:	0a91                	addi	s5,s5,4
    80004192:	02c9a783          	lw	a5,44(s3)
    80004196:	04fa5963          	bge	s4,a5,800041e8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000419a:	0189a583          	lw	a1,24(s3)
    8000419e:	014585bb          	addw	a1,a1,s4
    800041a2:	2585                	addiw	a1,a1,1
    800041a4:	0289a503          	lw	a0,40(s3)
    800041a8:	fffff097          	auipc	ra,0xfffff
    800041ac:	f26080e7          	jalr	-218(ra) # 800030ce <bread>
    800041b0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041b2:	000aa583          	lw	a1,0(s5)
    800041b6:	0289a503          	lw	a0,40(s3)
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	f14080e7          	jalr	-236(ra) # 800030ce <bread>
    800041c2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041c4:	40000613          	li	a2,1024
    800041c8:	05890593          	addi	a1,s2,88
    800041cc:	05850513          	addi	a0,a0,88
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	b70080e7          	jalr	-1168(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041d8:	8526                	mv	a0,s1
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	fe6080e7          	jalr	-26(ra) # 800031c0 <bwrite>
    if(recovering == 0)
    800041e2:	f80b1ce3          	bnez	s6,8000417a <install_trans+0x40>
    800041e6:	b769                	j	80004170 <install_trans+0x36>
}
    800041e8:	70e2                	ld	ra,56(sp)
    800041ea:	7442                	ld	s0,48(sp)
    800041ec:	74a2                	ld	s1,40(sp)
    800041ee:	7902                	ld	s2,32(sp)
    800041f0:	69e2                	ld	s3,24(sp)
    800041f2:	6a42                	ld	s4,16(sp)
    800041f4:	6aa2                	ld	s5,8(sp)
    800041f6:	6b02                	ld	s6,0(sp)
    800041f8:	6121                	addi	sp,sp,64
    800041fa:	8082                	ret
    800041fc:	8082                	ret

00000000800041fe <initlog>:
{
    800041fe:	7179                	addi	sp,sp,-48
    80004200:	f406                	sd	ra,40(sp)
    80004202:	f022                	sd	s0,32(sp)
    80004204:	ec26                	sd	s1,24(sp)
    80004206:	e84a                	sd	s2,16(sp)
    80004208:	e44e                	sd	s3,8(sp)
    8000420a:	1800                	addi	s0,sp,48
    8000420c:	892a                	mv	s2,a0
    8000420e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004210:	0001d497          	auipc	s1,0x1d
    80004214:	47048493          	addi	s1,s1,1136 # 80021680 <log>
    80004218:	00004597          	auipc	a1,0x4
    8000421c:	4a858593          	addi	a1,a1,1192 # 800086c0 <syscalls+0x1e8>
    80004220:	8526                	mv	a0,s1
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	932080e7          	jalr	-1742(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000422a:	0149a583          	lw	a1,20(s3)
    8000422e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004230:	0109a783          	lw	a5,16(s3)
    80004234:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004236:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000423a:	854a                	mv	a0,s2
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	e92080e7          	jalr	-366(ra) # 800030ce <bread>
  log.lh.n = lh->n;
    80004244:	4d3c                	lw	a5,88(a0)
    80004246:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004248:	02f05563          	blez	a5,80004272 <initlog+0x74>
    8000424c:	05c50713          	addi	a4,a0,92
    80004250:	0001d697          	auipc	a3,0x1d
    80004254:	46068693          	addi	a3,a3,1120 # 800216b0 <log+0x30>
    80004258:	37fd                	addiw	a5,a5,-1
    8000425a:	1782                	slli	a5,a5,0x20
    8000425c:	9381                	srli	a5,a5,0x20
    8000425e:	078a                	slli	a5,a5,0x2
    80004260:	06050613          	addi	a2,a0,96
    80004264:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004266:	4310                	lw	a2,0(a4)
    80004268:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000426a:	0711                	addi	a4,a4,4
    8000426c:	0691                	addi	a3,a3,4
    8000426e:	fef71ce3          	bne	a4,a5,80004266 <initlog+0x68>
  brelse(buf);
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	f8c080e7          	jalr	-116(ra) # 800031fe <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000427a:	4505                	li	a0,1
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	ebe080e7          	jalr	-322(ra) # 8000413a <install_trans>
  log.lh.n = 0;
    80004284:	0001d797          	auipc	a5,0x1d
    80004288:	4207a423          	sw	zero,1064(a5) # 800216ac <log+0x2c>
  write_head(); // clear the log
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	e34080e7          	jalr	-460(ra) # 800040c0 <write_head>
}
    80004294:	70a2                	ld	ra,40(sp)
    80004296:	7402                	ld	s0,32(sp)
    80004298:	64e2                	ld	s1,24(sp)
    8000429a:	6942                	ld	s2,16(sp)
    8000429c:	69a2                	ld	s3,8(sp)
    8000429e:	6145                	addi	sp,sp,48
    800042a0:	8082                	ret

00000000800042a2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042a2:	1101                	addi	sp,sp,-32
    800042a4:	ec06                	sd	ra,24(sp)
    800042a6:	e822                	sd	s0,16(sp)
    800042a8:	e426                	sd	s1,8(sp)
    800042aa:	e04a                	sd	s2,0(sp)
    800042ac:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042ae:	0001d517          	auipc	a0,0x1d
    800042b2:	3d250513          	addi	a0,a0,978 # 80021680 <log>
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	92e080e7          	jalr	-1746(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800042be:	0001d497          	auipc	s1,0x1d
    800042c2:	3c248493          	addi	s1,s1,962 # 80021680 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042c6:	4979                	li	s2,30
    800042c8:	a039                	j	800042d6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042ca:	85a6                	mv	a1,s1
    800042cc:	8526                	mv	a0,s1
    800042ce:	ffffe097          	auipc	ra,0xffffe
    800042d2:	d4e080e7          	jalr	-690(ra) # 8000201c <sleep>
    if(log.committing){
    800042d6:	50dc                	lw	a5,36(s1)
    800042d8:	fbed                	bnez	a5,800042ca <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042da:	509c                	lw	a5,32(s1)
    800042dc:	0017871b          	addiw	a4,a5,1
    800042e0:	0007069b          	sext.w	a3,a4
    800042e4:	0027179b          	slliw	a5,a4,0x2
    800042e8:	9fb9                	addw	a5,a5,a4
    800042ea:	0017979b          	slliw	a5,a5,0x1
    800042ee:	54d8                	lw	a4,44(s1)
    800042f0:	9fb9                	addw	a5,a5,a4
    800042f2:	00f95963          	bge	s2,a5,80004304 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042f6:	85a6                	mv	a1,s1
    800042f8:	8526                	mv	a0,s1
    800042fa:	ffffe097          	auipc	ra,0xffffe
    800042fe:	d22080e7          	jalr	-734(ra) # 8000201c <sleep>
    80004302:	bfd1                	j	800042d6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004304:	0001d517          	auipc	a0,0x1d
    80004308:	37c50513          	addi	a0,a0,892 # 80021680 <log>
    8000430c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000430e:	ffffd097          	auipc	ra,0xffffd
    80004312:	98a080e7          	jalr	-1654(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004316:	60e2                	ld	ra,24(sp)
    80004318:	6442                	ld	s0,16(sp)
    8000431a:	64a2                	ld	s1,8(sp)
    8000431c:	6902                	ld	s2,0(sp)
    8000431e:	6105                	addi	sp,sp,32
    80004320:	8082                	ret

0000000080004322 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004322:	7139                	addi	sp,sp,-64
    80004324:	fc06                	sd	ra,56(sp)
    80004326:	f822                	sd	s0,48(sp)
    80004328:	f426                	sd	s1,40(sp)
    8000432a:	f04a                	sd	s2,32(sp)
    8000432c:	ec4e                	sd	s3,24(sp)
    8000432e:	e852                	sd	s4,16(sp)
    80004330:	e456                	sd	s5,8(sp)
    80004332:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004334:	0001d497          	auipc	s1,0x1d
    80004338:	34c48493          	addi	s1,s1,844 # 80021680 <log>
    8000433c:	8526                	mv	a0,s1
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	8a6080e7          	jalr	-1882(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004346:	509c                	lw	a5,32(s1)
    80004348:	37fd                	addiw	a5,a5,-1
    8000434a:	0007891b          	sext.w	s2,a5
    8000434e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004350:	50dc                	lw	a5,36(s1)
    80004352:	efb9                	bnez	a5,800043b0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004354:	06091663          	bnez	s2,800043c0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004358:	0001d497          	auipc	s1,0x1d
    8000435c:	32848493          	addi	s1,s1,808 # 80021680 <log>
    80004360:	4785                	li	a5,1
    80004362:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004364:	8526                	mv	a0,s1
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	932080e7          	jalr	-1742(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000436e:	54dc                	lw	a5,44(s1)
    80004370:	06f04763          	bgtz	a5,800043de <end_op+0xbc>
    acquire(&log.lock);
    80004374:	0001d497          	auipc	s1,0x1d
    80004378:	30c48493          	addi	s1,s1,780 # 80021680 <log>
    8000437c:	8526                	mv	a0,s1
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	866080e7          	jalr	-1946(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004386:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000438a:	8526                	mv	a0,s1
    8000438c:	ffffe097          	auipc	ra,0xffffe
    80004390:	e1c080e7          	jalr	-484(ra) # 800021a8 <wakeup>
    release(&log.lock);
    80004394:	8526                	mv	a0,s1
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	902080e7          	jalr	-1790(ra) # 80000c98 <release>
}
    8000439e:	70e2                	ld	ra,56(sp)
    800043a0:	7442                	ld	s0,48(sp)
    800043a2:	74a2                	ld	s1,40(sp)
    800043a4:	7902                	ld	s2,32(sp)
    800043a6:	69e2                	ld	s3,24(sp)
    800043a8:	6a42                	ld	s4,16(sp)
    800043aa:	6aa2                	ld	s5,8(sp)
    800043ac:	6121                	addi	sp,sp,64
    800043ae:	8082                	ret
    panic("log.committing");
    800043b0:	00004517          	auipc	a0,0x4
    800043b4:	31850513          	addi	a0,a0,792 # 800086c8 <syscalls+0x1f0>
    800043b8:	ffffc097          	auipc	ra,0xffffc
    800043bc:	186080e7          	jalr	390(ra) # 8000053e <panic>
    wakeup(&log);
    800043c0:	0001d497          	auipc	s1,0x1d
    800043c4:	2c048493          	addi	s1,s1,704 # 80021680 <log>
    800043c8:	8526                	mv	a0,s1
    800043ca:	ffffe097          	auipc	ra,0xffffe
    800043ce:	dde080e7          	jalr	-546(ra) # 800021a8 <wakeup>
  release(&log.lock);
    800043d2:	8526                	mv	a0,s1
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	8c4080e7          	jalr	-1852(ra) # 80000c98 <release>
  if(do_commit){
    800043dc:	b7c9                	j	8000439e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043de:	0001da97          	auipc	s5,0x1d
    800043e2:	2d2a8a93          	addi	s5,s5,722 # 800216b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043e6:	0001da17          	auipc	s4,0x1d
    800043ea:	29aa0a13          	addi	s4,s4,666 # 80021680 <log>
    800043ee:	018a2583          	lw	a1,24(s4)
    800043f2:	012585bb          	addw	a1,a1,s2
    800043f6:	2585                	addiw	a1,a1,1
    800043f8:	028a2503          	lw	a0,40(s4)
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	cd2080e7          	jalr	-814(ra) # 800030ce <bread>
    80004404:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004406:	000aa583          	lw	a1,0(s5)
    8000440a:	028a2503          	lw	a0,40(s4)
    8000440e:	fffff097          	auipc	ra,0xfffff
    80004412:	cc0080e7          	jalr	-832(ra) # 800030ce <bread>
    80004416:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004418:	40000613          	li	a2,1024
    8000441c:	05850593          	addi	a1,a0,88
    80004420:	05848513          	addi	a0,s1,88
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	91c080e7          	jalr	-1764(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000442c:	8526                	mv	a0,s1
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	d92080e7          	jalr	-622(ra) # 800031c0 <bwrite>
    brelse(from);
    80004436:	854e                	mv	a0,s3
    80004438:	fffff097          	auipc	ra,0xfffff
    8000443c:	dc6080e7          	jalr	-570(ra) # 800031fe <brelse>
    brelse(to);
    80004440:	8526                	mv	a0,s1
    80004442:	fffff097          	auipc	ra,0xfffff
    80004446:	dbc080e7          	jalr	-580(ra) # 800031fe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444a:	2905                	addiw	s2,s2,1
    8000444c:	0a91                	addi	s5,s5,4
    8000444e:	02ca2783          	lw	a5,44(s4)
    80004452:	f8f94ee3          	blt	s2,a5,800043ee <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	c6a080e7          	jalr	-918(ra) # 800040c0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000445e:	4501                	li	a0,0
    80004460:	00000097          	auipc	ra,0x0
    80004464:	cda080e7          	jalr	-806(ra) # 8000413a <install_trans>
    log.lh.n = 0;
    80004468:	0001d797          	auipc	a5,0x1d
    8000446c:	2407a223          	sw	zero,580(a5) # 800216ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004470:	00000097          	auipc	ra,0x0
    80004474:	c50080e7          	jalr	-944(ra) # 800040c0 <write_head>
    80004478:	bdf5                	j	80004374 <end_op+0x52>

000000008000447a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000447a:	1101                	addi	sp,sp,-32
    8000447c:	ec06                	sd	ra,24(sp)
    8000447e:	e822                	sd	s0,16(sp)
    80004480:	e426                	sd	s1,8(sp)
    80004482:	e04a                	sd	s2,0(sp)
    80004484:	1000                	addi	s0,sp,32
    80004486:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004488:	0001d917          	auipc	s2,0x1d
    8000448c:	1f890913          	addi	s2,s2,504 # 80021680 <log>
    80004490:	854a                	mv	a0,s2
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	752080e7          	jalr	1874(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000449a:	02c92603          	lw	a2,44(s2)
    8000449e:	47f5                	li	a5,29
    800044a0:	06c7c563          	blt	a5,a2,8000450a <log_write+0x90>
    800044a4:	0001d797          	auipc	a5,0x1d
    800044a8:	1f87a783          	lw	a5,504(a5) # 8002169c <log+0x1c>
    800044ac:	37fd                	addiw	a5,a5,-1
    800044ae:	04f65e63          	bge	a2,a5,8000450a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044b2:	0001d797          	auipc	a5,0x1d
    800044b6:	1ee7a783          	lw	a5,494(a5) # 800216a0 <log+0x20>
    800044ba:	06f05063          	blez	a5,8000451a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044be:	4781                	li	a5,0
    800044c0:	06c05563          	blez	a2,8000452a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044c4:	44cc                	lw	a1,12(s1)
    800044c6:	0001d717          	auipc	a4,0x1d
    800044ca:	1ea70713          	addi	a4,a4,490 # 800216b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044ce:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044d0:	4314                	lw	a3,0(a4)
    800044d2:	04b68c63          	beq	a3,a1,8000452a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044d6:	2785                	addiw	a5,a5,1
    800044d8:	0711                	addi	a4,a4,4
    800044da:	fef61be3          	bne	a2,a5,800044d0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044de:	0621                	addi	a2,a2,8
    800044e0:	060a                	slli	a2,a2,0x2
    800044e2:	0001d797          	auipc	a5,0x1d
    800044e6:	19e78793          	addi	a5,a5,414 # 80021680 <log>
    800044ea:	963e                	add	a2,a2,a5
    800044ec:	44dc                	lw	a5,12(s1)
    800044ee:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044f0:	8526                	mv	a0,s1
    800044f2:	fffff097          	auipc	ra,0xfffff
    800044f6:	daa080e7          	jalr	-598(ra) # 8000329c <bpin>
    log.lh.n++;
    800044fa:	0001d717          	auipc	a4,0x1d
    800044fe:	18670713          	addi	a4,a4,390 # 80021680 <log>
    80004502:	575c                	lw	a5,44(a4)
    80004504:	2785                	addiw	a5,a5,1
    80004506:	d75c                	sw	a5,44(a4)
    80004508:	a835                	j	80004544 <log_write+0xca>
    panic("too big a transaction");
    8000450a:	00004517          	auipc	a0,0x4
    8000450e:	1ce50513          	addi	a0,a0,462 # 800086d8 <syscalls+0x200>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	02c080e7          	jalr	44(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000451a:	00004517          	auipc	a0,0x4
    8000451e:	1d650513          	addi	a0,a0,470 # 800086f0 <syscalls+0x218>
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	01c080e7          	jalr	28(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000452a:	00878713          	addi	a4,a5,8
    8000452e:	00271693          	slli	a3,a4,0x2
    80004532:	0001d717          	auipc	a4,0x1d
    80004536:	14e70713          	addi	a4,a4,334 # 80021680 <log>
    8000453a:	9736                	add	a4,a4,a3
    8000453c:	44d4                	lw	a3,12(s1)
    8000453e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004540:	faf608e3          	beq	a2,a5,800044f0 <log_write+0x76>
  }
  release(&log.lock);
    80004544:	0001d517          	auipc	a0,0x1d
    80004548:	13c50513          	addi	a0,a0,316 # 80021680 <log>
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	74c080e7          	jalr	1868(ra) # 80000c98 <release>
}
    80004554:	60e2                	ld	ra,24(sp)
    80004556:	6442                	ld	s0,16(sp)
    80004558:	64a2                	ld	s1,8(sp)
    8000455a:	6902                	ld	s2,0(sp)
    8000455c:	6105                	addi	sp,sp,32
    8000455e:	8082                	ret

0000000080004560 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004560:	1101                	addi	sp,sp,-32
    80004562:	ec06                	sd	ra,24(sp)
    80004564:	e822                	sd	s0,16(sp)
    80004566:	e426                	sd	s1,8(sp)
    80004568:	e04a                	sd	s2,0(sp)
    8000456a:	1000                	addi	s0,sp,32
    8000456c:	84aa                	mv	s1,a0
    8000456e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004570:	00004597          	auipc	a1,0x4
    80004574:	1a058593          	addi	a1,a1,416 # 80008710 <syscalls+0x238>
    80004578:	0521                	addi	a0,a0,8
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	5da080e7          	jalr	1498(ra) # 80000b54 <initlock>
  lk->name = name;
    80004582:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004586:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000458a:	0204a423          	sw	zero,40(s1)
}
    8000458e:	60e2                	ld	ra,24(sp)
    80004590:	6442                	ld	s0,16(sp)
    80004592:	64a2                	ld	s1,8(sp)
    80004594:	6902                	ld	s2,0(sp)
    80004596:	6105                	addi	sp,sp,32
    80004598:	8082                	ret

000000008000459a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000459a:	1101                	addi	sp,sp,-32
    8000459c:	ec06                	sd	ra,24(sp)
    8000459e:	e822                	sd	s0,16(sp)
    800045a0:	e426                	sd	s1,8(sp)
    800045a2:	e04a                	sd	s2,0(sp)
    800045a4:	1000                	addi	s0,sp,32
    800045a6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045a8:	00850913          	addi	s2,a0,8
    800045ac:	854a                	mv	a0,s2
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	636080e7          	jalr	1590(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800045b6:	409c                	lw	a5,0(s1)
    800045b8:	cb89                	beqz	a5,800045ca <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045ba:	85ca                	mv	a1,s2
    800045bc:	8526                	mv	a0,s1
    800045be:	ffffe097          	auipc	ra,0xffffe
    800045c2:	a5e080e7          	jalr	-1442(ra) # 8000201c <sleep>
  while (lk->locked) {
    800045c6:	409c                	lw	a5,0(s1)
    800045c8:	fbed                	bnez	a5,800045ba <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045ca:	4785                	li	a5,1
    800045cc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045ce:	ffffd097          	auipc	ra,0xffffd
    800045d2:	402080e7          	jalr	1026(ra) # 800019d0 <myproc>
    800045d6:	591c                	lw	a5,48(a0)
    800045d8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045da:	854a                	mv	a0,s2
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	6bc080e7          	jalr	1724(ra) # 80000c98 <release>
}
    800045e4:	60e2                	ld	ra,24(sp)
    800045e6:	6442                	ld	s0,16(sp)
    800045e8:	64a2                	ld	s1,8(sp)
    800045ea:	6902                	ld	s2,0(sp)
    800045ec:	6105                	addi	sp,sp,32
    800045ee:	8082                	ret

00000000800045f0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045f0:	1101                	addi	sp,sp,-32
    800045f2:	ec06                	sd	ra,24(sp)
    800045f4:	e822                	sd	s0,16(sp)
    800045f6:	e426                	sd	s1,8(sp)
    800045f8:	e04a                	sd	s2,0(sp)
    800045fa:	1000                	addi	s0,sp,32
    800045fc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045fe:	00850913          	addi	s2,a0,8
    80004602:	854a                	mv	a0,s2
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	5e0080e7          	jalr	1504(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000460c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004610:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004614:	8526                	mv	a0,s1
    80004616:	ffffe097          	auipc	ra,0xffffe
    8000461a:	b92080e7          	jalr	-1134(ra) # 800021a8 <wakeup>
  release(&lk->lk);
    8000461e:	854a                	mv	a0,s2
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	678080e7          	jalr	1656(ra) # 80000c98 <release>
}
    80004628:	60e2                	ld	ra,24(sp)
    8000462a:	6442                	ld	s0,16(sp)
    8000462c:	64a2                	ld	s1,8(sp)
    8000462e:	6902                	ld	s2,0(sp)
    80004630:	6105                	addi	sp,sp,32
    80004632:	8082                	ret

0000000080004634 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004634:	7179                	addi	sp,sp,-48
    80004636:	f406                	sd	ra,40(sp)
    80004638:	f022                	sd	s0,32(sp)
    8000463a:	ec26                	sd	s1,24(sp)
    8000463c:	e84a                	sd	s2,16(sp)
    8000463e:	e44e                	sd	s3,8(sp)
    80004640:	1800                	addi	s0,sp,48
    80004642:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004644:	00850913          	addi	s2,a0,8
    80004648:	854a                	mv	a0,s2
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	59a080e7          	jalr	1434(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004652:	409c                	lw	a5,0(s1)
    80004654:	ef99                	bnez	a5,80004672 <holdingsleep+0x3e>
    80004656:	4481                	li	s1,0
  release(&lk->lk);
    80004658:	854a                	mv	a0,s2
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	63e080e7          	jalr	1598(ra) # 80000c98 <release>
  return r;
}
    80004662:	8526                	mv	a0,s1
    80004664:	70a2                	ld	ra,40(sp)
    80004666:	7402                	ld	s0,32(sp)
    80004668:	64e2                	ld	s1,24(sp)
    8000466a:	6942                	ld	s2,16(sp)
    8000466c:	69a2                	ld	s3,8(sp)
    8000466e:	6145                	addi	sp,sp,48
    80004670:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004672:	0284a983          	lw	s3,40(s1)
    80004676:	ffffd097          	auipc	ra,0xffffd
    8000467a:	35a080e7          	jalr	858(ra) # 800019d0 <myproc>
    8000467e:	5904                	lw	s1,48(a0)
    80004680:	413484b3          	sub	s1,s1,s3
    80004684:	0014b493          	seqz	s1,s1
    80004688:	bfc1                	j	80004658 <holdingsleep+0x24>

000000008000468a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000468a:	1141                	addi	sp,sp,-16
    8000468c:	e406                	sd	ra,8(sp)
    8000468e:	e022                	sd	s0,0(sp)
    80004690:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004692:	00004597          	auipc	a1,0x4
    80004696:	08e58593          	addi	a1,a1,142 # 80008720 <syscalls+0x248>
    8000469a:	0001d517          	auipc	a0,0x1d
    8000469e:	12e50513          	addi	a0,a0,302 # 800217c8 <ftable>
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	4b2080e7          	jalr	1202(ra) # 80000b54 <initlock>
}
    800046aa:	60a2                	ld	ra,8(sp)
    800046ac:	6402                	ld	s0,0(sp)
    800046ae:	0141                	addi	sp,sp,16
    800046b0:	8082                	ret

00000000800046b2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046b2:	1101                	addi	sp,sp,-32
    800046b4:	ec06                	sd	ra,24(sp)
    800046b6:	e822                	sd	s0,16(sp)
    800046b8:	e426                	sd	s1,8(sp)
    800046ba:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046bc:	0001d517          	auipc	a0,0x1d
    800046c0:	10c50513          	addi	a0,a0,268 # 800217c8 <ftable>
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	520080e7          	jalr	1312(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046cc:	0001d497          	auipc	s1,0x1d
    800046d0:	11448493          	addi	s1,s1,276 # 800217e0 <ftable+0x18>
    800046d4:	0001e717          	auipc	a4,0x1e
    800046d8:	0ac70713          	addi	a4,a4,172 # 80022780 <ftable+0xfb8>
    if(f->ref == 0){
    800046dc:	40dc                	lw	a5,4(s1)
    800046de:	cf99                	beqz	a5,800046fc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046e0:	02848493          	addi	s1,s1,40
    800046e4:	fee49ce3          	bne	s1,a4,800046dc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046e8:	0001d517          	auipc	a0,0x1d
    800046ec:	0e050513          	addi	a0,a0,224 # 800217c8 <ftable>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	5a8080e7          	jalr	1448(ra) # 80000c98 <release>
  return 0;
    800046f8:	4481                	li	s1,0
    800046fa:	a819                	j	80004710 <filealloc+0x5e>
      f->ref = 1;
    800046fc:	4785                	li	a5,1
    800046fe:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004700:	0001d517          	auipc	a0,0x1d
    80004704:	0c850513          	addi	a0,a0,200 # 800217c8 <ftable>
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	590080e7          	jalr	1424(ra) # 80000c98 <release>
}
    80004710:	8526                	mv	a0,s1
    80004712:	60e2                	ld	ra,24(sp)
    80004714:	6442                	ld	s0,16(sp)
    80004716:	64a2                	ld	s1,8(sp)
    80004718:	6105                	addi	sp,sp,32
    8000471a:	8082                	ret

000000008000471c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000471c:	1101                	addi	sp,sp,-32
    8000471e:	ec06                	sd	ra,24(sp)
    80004720:	e822                	sd	s0,16(sp)
    80004722:	e426                	sd	s1,8(sp)
    80004724:	1000                	addi	s0,sp,32
    80004726:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004728:	0001d517          	auipc	a0,0x1d
    8000472c:	0a050513          	addi	a0,a0,160 # 800217c8 <ftable>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	4b4080e7          	jalr	1204(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004738:	40dc                	lw	a5,4(s1)
    8000473a:	02f05263          	blez	a5,8000475e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000473e:	2785                	addiw	a5,a5,1
    80004740:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004742:	0001d517          	auipc	a0,0x1d
    80004746:	08650513          	addi	a0,a0,134 # 800217c8 <ftable>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	54e080e7          	jalr	1358(ra) # 80000c98 <release>
  return f;
}
    80004752:	8526                	mv	a0,s1
    80004754:	60e2                	ld	ra,24(sp)
    80004756:	6442                	ld	s0,16(sp)
    80004758:	64a2                	ld	s1,8(sp)
    8000475a:	6105                	addi	sp,sp,32
    8000475c:	8082                	ret
    panic("filedup");
    8000475e:	00004517          	auipc	a0,0x4
    80004762:	fca50513          	addi	a0,a0,-54 # 80008728 <syscalls+0x250>
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	dd8080e7          	jalr	-552(ra) # 8000053e <panic>

000000008000476e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000476e:	7139                	addi	sp,sp,-64
    80004770:	fc06                	sd	ra,56(sp)
    80004772:	f822                	sd	s0,48(sp)
    80004774:	f426                	sd	s1,40(sp)
    80004776:	f04a                	sd	s2,32(sp)
    80004778:	ec4e                	sd	s3,24(sp)
    8000477a:	e852                	sd	s4,16(sp)
    8000477c:	e456                	sd	s5,8(sp)
    8000477e:	0080                	addi	s0,sp,64
    80004780:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004782:	0001d517          	auipc	a0,0x1d
    80004786:	04650513          	addi	a0,a0,70 # 800217c8 <ftable>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	45a080e7          	jalr	1114(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004792:	40dc                	lw	a5,4(s1)
    80004794:	06f05163          	blez	a5,800047f6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004798:	37fd                	addiw	a5,a5,-1
    8000479a:	0007871b          	sext.w	a4,a5
    8000479e:	c0dc                	sw	a5,4(s1)
    800047a0:	06e04363          	bgtz	a4,80004806 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047a4:	0004a903          	lw	s2,0(s1)
    800047a8:	0094ca83          	lbu	s5,9(s1)
    800047ac:	0104ba03          	ld	s4,16(s1)
    800047b0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047b4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047b8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047bc:	0001d517          	auipc	a0,0x1d
    800047c0:	00c50513          	addi	a0,a0,12 # 800217c8 <ftable>
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	4d4080e7          	jalr	1236(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800047cc:	4785                	li	a5,1
    800047ce:	04f90d63          	beq	s2,a5,80004828 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047d2:	3979                	addiw	s2,s2,-2
    800047d4:	4785                	li	a5,1
    800047d6:	0527e063          	bltu	a5,s2,80004816 <fileclose+0xa8>
    begin_op();
    800047da:	00000097          	auipc	ra,0x0
    800047de:	ac8080e7          	jalr	-1336(ra) # 800042a2 <begin_op>
    iput(ff.ip);
    800047e2:	854e                	mv	a0,s3
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	2a6080e7          	jalr	678(ra) # 80003a8a <iput>
    end_op();
    800047ec:	00000097          	auipc	ra,0x0
    800047f0:	b36080e7          	jalr	-1226(ra) # 80004322 <end_op>
    800047f4:	a00d                	j	80004816 <fileclose+0xa8>
    panic("fileclose");
    800047f6:	00004517          	auipc	a0,0x4
    800047fa:	f3a50513          	addi	a0,a0,-198 # 80008730 <syscalls+0x258>
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	d40080e7          	jalr	-704(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004806:	0001d517          	auipc	a0,0x1d
    8000480a:	fc250513          	addi	a0,a0,-62 # 800217c8 <ftable>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	48a080e7          	jalr	1162(ra) # 80000c98 <release>
  }
}
    80004816:	70e2                	ld	ra,56(sp)
    80004818:	7442                	ld	s0,48(sp)
    8000481a:	74a2                	ld	s1,40(sp)
    8000481c:	7902                	ld	s2,32(sp)
    8000481e:	69e2                	ld	s3,24(sp)
    80004820:	6a42                	ld	s4,16(sp)
    80004822:	6aa2                	ld	s5,8(sp)
    80004824:	6121                	addi	sp,sp,64
    80004826:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004828:	85d6                	mv	a1,s5
    8000482a:	8552                	mv	a0,s4
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	34c080e7          	jalr	844(ra) # 80004b78 <pipeclose>
    80004834:	b7cd                	j	80004816 <fileclose+0xa8>

0000000080004836 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004836:	715d                	addi	sp,sp,-80
    80004838:	e486                	sd	ra,72(sp)
    8000483a:	e0a2                	sd	s0,64(sp)
    8000483c:	fc26                	sd	s1,56(sp)
    8000483e:	f84a                	sd	s2,48(sp)
    80004840:	f44e                	sd	s3,40(sp)
    80004842:	0880                	addi	s0,sp,80
    80004844:	84aa                	mv	s1,a0
    80004846:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004848:	ffffd097          	auipc	ra,0xffffd
    8000484c:	188080e7          	jalr	392(ra) # 800019d0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004850:	409c                	lw	a5,0(s1)
    80004852:	37f9                	addiw	a5,a5,-2
    80004854:	4705                	li	a4,1
    80004856:	04f76763          	bltu	a4,a5,800048a4 <filestat+0x6e>
    8000485a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000485c:	6c88                	ld	a0,24(s1)
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	072080e7          	jalr	114(ra) # 800038d0 <ilock>
    stati(f->ip, &st);
    80004866:	fb840593          	addi	a1,s0,-72
    8000486a:	6c88                	ld	a0,24(s1)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	2ee080e7          	jalr	750(ra) # 80003b5a <stati>
    iunlock(f->ip);
    80004874:	6c88                	ld	a0,24(s1)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	11c080e7          	jalr	284(ra) # 80003992 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000487e:	46e1                	li	a3,24
    80004880:	fb840613          	addi	a2,s0,-72
    80004884:	85ce                	mv	a1,s3
    80004886:	06093503          	ld	a0,96(s2)
    8000488a:	ffffd097          	auipc	ra,0xffffd
    8000488e:	e08080e7          	jalr	-504(ra) # 80001692 <copyout>
    80004892:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004896:	60a6                	ld	ra,72(sp)
    80004898:	6406                	ld	s0,64(sp)
    8000489a:	74e2                	ld	s1,56(sp)
    8000489c:	7942                	ld	s2,48(sp)
    8000489e:	79a2                	ld	s3,40(sp)
    800048a0:	6161                	addi	sp,sp,80
    800048a2:	8082                	ret
  return -1;
    800048a4:	557d                	li	a0,-1
    800048a6:	bfc5                	j	80004896 <filestat+0x60>

00000000800048a8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048a8:	7179                	addi	sp,sp,-48
    800048aa:	f406                	sd	ra,40(sp)
    800048ac:	f022                	sd	s0,32(sp)
    800048ae:	ec26                	sd	s1,24(sp)
    800048b0:	e84a                	sd	s2,16(sp)
    800048b2:	e44e                	sd	s3,8(sp)
    800048b4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048b6:	00854783          	lbu	a5,8(a0)
    800048ba:	c3d5                	beqz	a5,8000495e <fileread+0xb6>
    800048bc:	84aa                	mv	s1,a0
    800048be:	89ae                	mv	s3,a1
    800048c0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048c2:	411c                	lw	a5,0(a0)
    800048c4:	4705                	li	a4,1
    800048c6:	04e78963          	beq	a5,a4,80004918 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ca:	470d                	li	a4,3
    800048cc:	04e78d63          	beq	a5,a4,80004926 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048d0:	4709                	li	a4,2
    800048d2:	06e79e63          	bne	a5,a4,8000494e <fileread+0xa6>
    ilock(f->ip);
    800048d6:	6d08                	ld	a0,24(a0)
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	ff8080e7          	jalr	-8(ra) # 800038d0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048e0:	874a                	mv	a4,s2
    800048e2:	5094                	lw	a3,32(s1)
    800048e4:	864e                	mv	a2,s3
    800048e6:	4585                	li	a1,1
    800048e8:	6c88                	ld	a0,24(s1)
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	29a080e7          	jalr	666(ra) # 80003b84 <readi>
    800048f2:	892a                	mv	s2,a0
    800048f4:	00a05563          	blez	a0,800048fe <fileread+0x56>
      f->off += r;
    800048f8:	509c                	lw	a5,32(s1)
    800048fa:	9fa9                	addw	a5,a5,a0
    800048fc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048fe:	6c88                	ld	a0,24(s1)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	092080e7          	jalr	146(ra) # 80003992 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004908:	854a                	mv	a0,s2
    8000490a:	70a2                	ld	ra,40(sp)
    8000490c:	7402                	ld	s0,32(sp)
    8000490e:	64e2                	ld	s1,24(sp)
    80004910:	6942                	ld	s2,16(sp)
    80004912:	69a2                	ld	s3,8(sp)
    80004914:	6145                	addi	sp,sp,48
    80004916:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004918:	6908                	ld	a0,16(a0)
    8000491a:	00000097          	auipc	ra,0x0
    8000491e:	3c8080e7          	jalr	968(ra) # 80004ce2 <piperead>
    80004922:	892a                	mv	s2,a0
    80004924:	b7d5                	j	80004908 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004926:	02451783          	lh	a5,36(a0)
    8000492a:	03079693          	slli	a3,a5,0x30
    8000492e:	92c1                	srli	a3,a3,0x30
    80004930:	4725                	li	a4,9
    80004932:	02d76863          	bltu	a4,a3,80004962 <fileread+0xba>
    80004936:	0792                	slli	a5,a5,0x4
    80004938:	0001d717          	auipc	a4,0x1d
    8000493c:	df070713          	addi	a4,a4,-528 # 80021728 <devsw>
    80004940:	97ba                	add	a5,a5,a4
    80004942:	639c                	ld	a5,0(a5)
    80004944:	c38d                	beqz	a5,80004966 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004946:	4505                	li	a0,1
    80004948:	9782                	jalr	a5
    8000494a:	892a                	mv	s2,a0
    8000494c:	bf75                	j	80004908 <fileread+0x60>
    panic("fileread");
    8000494e:	00004517          	auipc	a0,0x4
    80004952:	df250513          	addi	a0,a0,-526 # 80008740 <syscalls+0x268>
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	be8080e7          	jalr	-1048(ra) # 8000053e <panic>
    return -1;
    8000495e:	597d                	li	s2,-1
    80004960:	b765                	j	80004908 <fileread+0x60>
      return -1;
    80004962:	597d                	li	s2,-1
    80004964:	b755                	j	80004908 <fileread+0x60>
    80004966:	597d                	li	s2,-1
    80004968:	b745                	j	80004908 <fileread+0x60>

000000008000496a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000496a:	715d                	addi	sp,sp,-80
    8000496c:	e486                	sd	ra,72(sp)
    8000496e:	e0a2                	sd	s0,64(sp)
    80004970:	fc26                	sd	s1,56(sp)
    80004972:	f84a                	sd	s2,48(sp)
    80004974:	f44e                	sd	s3,40(sp)
    80004976:	f052                	sd	s4,32(sp)
    80004978:	ec56                	sd	s5,24(sp)
    8000497a:	e85a                	sd	s6,16(sp)
    8000497c:	e45e                	sd	s7,8(sp)
    8000497e:	e062                	sd	s8,0(sp)
    80004980:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004982:	00954783          	lbu	a5,9(a0)
    80004986:	10078663          	beqz	a5,80004a92 <filewrite+0x128>
    8000498a:	892a                	mv	s2,a0
    8000498c:	8aae                	mv	s5,a1
    8000498e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004990:	411c                	lw	a5,0(a0)
    80004992:	4705                	li	a4,1
    80004994:	02e78263          	beq	a5,a4,800049b8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004998:	470d                	li	a4,3
    8000499a:	02e78663          	beq	a5,a4,800049c6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000499e:	4709                	li	a4,2
    800049a0:	0ee79163          	bne	a5,a4,80004a82 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049a4:	0ac05d63          	blez	a2,80004a5e <filewrite+0xf4>
    int i = 0;
    800049a8:	4981                	li	s3,0
    800049aa:	6b05                	lui	s6,0x1
    800049ac:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049b0:	6b85                	lui	s7,0x1
    800049b2:	c00b8b9b          	addiw	s7,s7,-1024
    800049b6:	a861                	j	80004a4e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049b8:	6908                	ld	a0,16(a0)
    800049ba:	00000097          	auipc	ra,0x0
    800049be:	22e080e7          	jalr	558(ra) # 80004be8 <pipewrite>
    800049c2:	8a2a                	mv	s4,a0
    800049c4:	a045                	j	80004a64 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049c6:	02451783          	lh	a5,36(a0)
    800049ca:	03079693          	slli	a3,a5,0x30
    800049ce:	92c1                	srli	a3,a3,0x30
    800049d0:	4725                	li	a4,9
    800049d2:	0cd76263          	bltu	a4,a3,80004a96 <filewrite+0x12c>
    800049d6:	0792                	slli	a5,a5,0x4
    800049d8:	0001d717          	auipc	a4,0x1d
    800049dc:	d5070713          	addi	a4,a4,-688 # 80021728 <devsw>
    800049e0:	97ba                	add	a5,a5,a4
    800049e2:	679c                	ld	a5,8(a5)
    800049e4:	cbdd                	beqz	a5,80004a9a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049e6:	4505                	li	a0,1
    800049e8:	9782                	jalr	a5
    800049ea:	8a2a                	mv	s4,a0
    800049ec:	a8a5                	j	80004a64 <filewrite+0xfa>
    800049ee:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	8b0080e7          	jalr	-1872(ra) # 800042a2 <begin_op>
      ilock(f->ip);
    800049fa:	01893503          	ld	a0,24(s2)
    800049fe:	fffff097          	auipc	ra,0xfffff
    80004a02:	ed2080e7          	jalr	-302(ra) # 800038d0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a06:	8762                	mv	a4,s8
    80004a08:	02092683          	lw	a3,32(s2)
    80004a0c:	01598633          	add	a2,s3,s5
    80004a10:	4585                	li	a1,1
    80004a12:	01893503          	ld	a0,24(s2)
    80004a16:	fffff097          	auipc	ra,0xfffff
    80004a1a:	266080e7          	jalr	614(ra) # 80003c7c <writei>
    80004a1e:	84aa                	mv	s1,a0
    80004a20:	00a05763          	blez	a0,80004a2e <filewrite+0xc4>
        f->off += r;
    80004a24:	02092783          	lw	a5,32(s2)
    80004a28:	9fa9                	addw	a5,a5,a0
    80004a2a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a2e:	01893503          	ld	a0,24(s2)
    80004a32:	fffff097          	auipc	ra,0xfffff
    80004a36:	f60080e7          	jalr	-160(ra) # 80003992 <iunlock>
      end_op();
    80004a3a:	00000097          	auipc	ra,0x0
    80004a3e:	8e8080e7          	jalr	-1816(ra) # 80004322 <end_op>

      if(r != n1){
    80004a42:	009c1f63          	bne	s8,s1,80004a60 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a46:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a4a:	0149db63          	bge	s3,s4,80004a60 <filewrite+0xf6>
      int n1 = n - i;
    80004a4e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a52:	84be                	mv	s1,a5
    80004a54:	2781                	sext.w	a5,a5
    80004a56:	f8fb5ce3          	bge	s6,a5,800049ee <filewrite+0x84>
    80004a5a:	84de                	mv	s1,s7
    80004a5c:	bf49                	j	800049ee <filewrite+0x84>
    int i = 0;
    80004a5e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a60:	013a1f63          	bne	s4,s3,80004a7e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a64:	8552                	mv	a0,s4
    80004a66:	60a6                	ld	ra,72(sp)
    80004a68:	6406                	ld	s0,64(sp)
    80004a6a:	74e2                	ld	s1,56(sp)
    80004a6c:	7942                	ld	s2,48(sp)
    80004a6e:	79a2                	ld	s3,40(sp)
    80004a70:	7a02                	ld	s4,32(sp)
    80004a72:	6ae2                	ld	s5,24(sp)
    80004a74:	6b42                	ld	s6,16(sp)
    80004a76:	6ba2                	ld	s7,8(sp)
    80004a78:	6c02                	ld	s8,0(sp)
    80004a7a:	6161                	addi	sp,sp,80
    80004a7c:	8082                	ret
    ret = (i == n ? n : -1);
    80004a7e:	5a7d                	li	s4,-1
    80004a80:	b7d5                	j	80004a64 <filewrite+0xfa>
    panic("filewrite");
    80004a82:	00004517          	auipc	a0,0x4
    80004a86:	cce50513          	addi	a0,a0,-818 # 80008750 <syscalls+0x278>
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>
    return -1;
    80004a92:	5a7d                	li	s4,-1
    80004a94:	bfc1                	j	80004a64 <filewrite+0xfa>
      return -1;
    80004a96:	5a7d                	li	s4,-1
    80004a98:	b7f1                	j	80004a64 <filewrite+0xfa>
    80004a9a:	5a7d                	li	s4,-1
    80004a9c:	b7e1                	j	80004a64 <filewrite+0xfa>

0000000080004a9e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a9e:	7179                	addi	sp,sp,-48
    80004aa0:	f406                	sd	ra,40(sp)
    80004aa2:	f022                	sd	s0,32(sp)
    80004aa4:	ec26                	sd	s1,24(sp)
    80004aa6:	e84a                	sd	s2,16(sp)
    80004aa8:	e44e                	sd	s3,8(sp)
    80004aaa:	e052                	sd	s4,0(sp)
    80004aac:	1800                	addi	s0,sp,48
    80004aae:	84aa                	mv	s1,a0
    80004ab0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ab2:	0005b023          	sd	zero,0(a1)
    80004ab6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aba:	00000097          	auipc	ra,0x0
    80004abe:	bf8080e7          	jalr	-1032(ra) # 800046b2 <filealloc>
    80004ac2:	e088                	sd	a0,0(s1)
    80004ac4:	c551                	beqz	a0,80004b50 <pipealloc+0xb2>
    80004ac6:	00000097          	auipc	ra,0x0
    80004aca:	bec080e7          	jalr	-1044(ra) # 800046b2 <filealloc>
    80004ace:	00aa3023          	sd	a0,0(s4)
    80004ad2:	c92d                	beqz	a0,80004b44 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	020080e7          	jalr	32(ra) # 80000af4 <kalloc>
    80004adc:	892a                	mv	s2,a0
    80004ade:	c125                	beqz	a0,80004b3e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ae0:	4985                	li	s3,1
    80004ae2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ae6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aea:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aee:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004af2:	00004597          	auipc	a1,0x4
    80004af6:	c6e58593          	addi	a1,a1,-914 # 80008760 <syscalls+0x288>
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	05a080e7          	jalr	90(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b02:	609c                	ld	a5,0(s1)
    80004b04:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b08:	609c                	ld	a5,0(s1)
    80004b0a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b0e:	609c                	ld	a5,0(s1)
    80004b10:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b14:	609c                	ld	a5,0(s1)
    80004b16:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b1a:	000a3783          	ld	a5,0(s4)
    80004b1e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b22:	000a3783          	ld	a5,0(s4)
    80004b26:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b2a:	000a3783          	ld	a5,0(s4)
    80004b2e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b32:	000a3783          	ld	a5,0(s4)
    80004b36:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b3a:	4501                	li	a0,0
    80004b3c:	a025                	j	80004b64 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b3e:	6088                	ld	a0,0(s1)
    80004b40:	e501                	bnez	a0,80004b48 <pipealloc+0xaa>
    80004b42:	a039                	j	80004b50 <pipealloc+0xb2>
    80004b44:	6088                	ld	a0,0(s1)
    80004b46:	c51d                	beqz	a0,80004b74 <pipealloc+0xd6>
    fileclose(*f0);
    80004b48:	00000097          	auipc	ra,0x0
    80004b4c:	c26080e7          	jalr	-986(ra) # 8000476e <fileclose>
  if(*f1)
    80004b50:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b54:	557d                	li	a0,-1
  if(*f1)
    80004b56:	c799                	beqz	a5,80004b64 <pipealloc+0xc6>
    fileclose(*f1);
    80004b58:	853e                	mv	a0,a5
    80004b5a:	00000097          	auipc	ra,0x0
    80004b5e:	c14080e7          	jalr	-1004(ra) # 8000476e <fileclose>
  return -1;
    80004b62:	557d                	li	a0,-1
}
    80004b64:	70a2                	ld	ra,40(sp)
    80004b66:	7402                	ld	s0,32(sp)
    80004b68:	64e2                	ld	s1,24(sp)
    80004b6a:	6942                	ld	s2,16(sp)
    80004b6c:	69a2                	ld	s3,8(sp)
    80004b6e:	6a02                	ld	s4,0(sp)
    80004b70:	6145                	addi	sp,sp,48
    80004b72:	8082                	ret
  return -1;
    80004b74:	557d                	li	a0,-1
    80004b76:	b7fd                	j	80004b64 <pipealloc+0xc6>

0000000080004b78 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b78:	1101                	addi	sp,sp,-32
    80004b7a:	ec06                	sd	ra,24(sp)
    80004b7c:	e822                	sd	s0,16(sp)
    80004b7e:	e426                	sd	s1,8(sp)
    80004b80:	e04a                	sd	s2,0(sp)
    80004b82:	1000                	addi	s0,sp,32
    80004b84:	84aa                	mv	s1,a0
    80004b86:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	05c080e7          	jalr	92(ra) # 80000be4 <acquire>
  if(writable){
    80004b90:	02090d63          	beqz	s2,80004bca <pipeclose+0x52>
    pi->writeopen = 0;
    80004b94:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b98:	21848513          	addi	a0,s1,536
    80004b9c:	ffffd097          	auipc	ra,0xffffd
    80004ba0:	60c080e7          	jalr	1548(ra) # 800021a8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ba4:	2204b783          	ld	a5,544(s1)
    80004ba8:	eb95                	bnez	a5,80004bdc <pipeclose+0x64>
    release(&pi->lock);
    80004baa:	8526                	mv	a0,s1
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	0ec080e7          	jalr	236(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	e42080e7          	jalr	-446(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004bbe:	60e2                	ld	ra,24(sp)
    80004bc0:	6442                	ld	s0,16(sp)
    80004bc2:	64a2                	ld	s1,8(sp)
    80004bc4:	6902                	ld	s2,0(sp)
    80004bc6:	6105                	addi	sp,sp,32
    80004bc8:	8082                	ret
    pi->readopen = 0;
    80004bca:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bce:	21c48513          	addi	a0,s1,540
    80004bd2:	ffffd097          	auipc	ra,0xffffd
    80004bd6:	5d6080e7          	jalr	1494(ra) # 800021a8 <wakeup>
    80004bda:	b7e9                	j	80004ba4 <pipeclose+0x2c>
    release(&pi->lock);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	0ba080e7          	jalr	186(ra) # 80000c98 <release>
}
    80004be6:	bfe1                	j	80004bbe <pipeclose+0x46>

0000000080004be8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004be8:	7159                	addi	sp,sp,-112
    80004bea:	f486                	sd	ra,104(sp)
    80004bec:	f0a2                	sd	s0,96(sp)
    80004bee:	eca6                	sd	s1,88(sp)
    80004bf0:	e8ca                	sd	s2,80(sp)
    80004bf2:	e4ce                	sd	s3,72(sp)
    80004bf4:	e0d2                	sd	s4,64(sp)
    80004bf6:	fc56                	sd	s5,56(sp)
    80004bf8:	f85a                	sd	s6,48(sp)
    80004bfa:	f45e                	sd	s7,40(sp)
    80004bfc:	f062                	sd	s8,32(sp)
    80004bfe:	ec66                	sd	s9,24(sp)
    80004c00:	1880                	addi	s0,sp,112
    80004c02:	84aa                	mv	s1,a0
    80004c04:	8aae                	mv	s5,a1
    80004c06:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c08:	ffffd097          	auipc	ra,0xffffd
    80004c0c:	dc8080e7          	jalr	-568(ra) # 800019d0 <myproc>
    80004c10:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c12:	8526                	mv	a0,s1
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	fd0080e7          	jalr	-48(ra) # 80000be4 <acquire>
  while(i < n){
    80004c1c:	0d405163          	blez	s4,80004cde <pipewrite+0xf6>
    80004c20:	8ba6                	mv	s7,s1
  int i = 0;
    80004c22:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c24:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c26:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c2a:	21c48c13          	addi	s8,s1,540
    80004c2e:	a08d                	j	80004c90 <pipewrite+0xa8>
      release(&pi->lock);
    80004c30:	8526                	mv	a0,s1
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	066080e7          	jalr	102(ra) # 80000c98 <release>
      return -1;
    80004c3a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c3c:	854a                	mv	a0,s2
    80004c3e:	70a6                	ld	ra,104(sp)
    80004c40:	7406                	ld	s0,96(sp)
    80004c42:	64e6                	ld	s1,88(sp)
    80004c44:	6946                	ld	s2,80(sp)
    80004c46:	69a6                	ld	s3,72(sp)
    80004c48:	6a06                	ld	s4,64(sp)
    80004c4a:	7ae2                	ld	s5,56(sp)
    80004c4c:	7b42                	ld	s6,48(sp)
    80004c4e:	7ba2                	ld	s7,40(sp)
    80004c50:	7c02                	ld	s8,32(sp)
    80004c52:	6ce2                	ld	s9,24(sp)
    80004c54:	6165                	addi	sp,sp,112
    80004c56:	8082                	ret
      wakeup(&pi->nread);
    80004c58:	8566                	mv	a0,s9
    80004c5a:	ffffd097          	auipc	ra,0xffffd
    80004c5e:	54e080e7          	jalr	1358(ra) # 800021a8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c62:	85de                	mv	a1,s7
    80004c64:	8562                	mv	a0,s8
    80004c66:	ffffd097          	auipc	ra,0xffffd
    80004c6a:	3b6080e7          	jalr	950(ra) # 8000201c <sleep>
    80004c6e:	a839                	j	80004c8c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c70:	21c4a783          	lw	a5,540(s1)
    80004c74:	0017871b          	addiw	a4,a5,1
    80004c78:	20e4ae23          	sw	a4,540(s1)
    80004c7c:	1ff7f793          	andi	a5,a5,511
    80004c80:	97a6                	add	a5,a5,s1
    80004c82:	f9f44703          	lbu	a4,-97(s0)
    80004c86:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c8a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c8c:	03495d63          	bge	s2,s4,80004cc6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c90:	2204a783          	lw	a5,544(s1)
    80004c94:	dfd1                	beqz	a5,80004c30 <pipewrite+0x48>
    80004c96:	0289a783          	lw	a5,40(s3)
    80004c9a:	fbd9                	bnez	a5,80004c30 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c9c:	2184a783          	lw	a5,536(s1)
    80004ca0:	21c4a703          	lw	a4,540(s1)
    80004ca4:	2007879b          	addiw	a5,a5,512
    80004ca8:	faf708e3          	beq	a4,a5,80004c58 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cac:	4685                	li	a3,1
    80004cae:	01590633          	add	a2,s2,s5
    80004cb2:	f9f40593          	addi	a1,s0,-97
    80004cb6:	0609b503          	ld	a0,96(s3)
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	a64080e7          	jalr	-1436(ra) # 8000171e <copyin>
    80004cc2:	fb6517e3          	bne	a0,s6,80004c70 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cc6:	21848513          	addi	a0,s1,536
    80004cca:	ffffd097          	auipc	ra,0xffffd
    80004cce:	4de080e7          	jalr	1246(ra) # 800021a8 <wakeup>
  release(&pi->lock);
    80004cd2:	8526                	mv	a0,s1
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	fc4080e7          	jalr	-60(ra) # 80000c98 <release>
  return i;
    80004cdc:	b785                	j	80004c3c <pipewrite+0x54>
  int i = 0;
    80004cde:	4901                	li	s2,0
    80004ce0:	b7dd                	j	80004cc6 <pipewrite+0xde>

0000000080004ce2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ce2:	715d                	addi	sp,sp,-80
    80004ce4:	e486                	sd	ra,72(sp)
    80004ce6:	e0a2                	sd	s0,64(sp)
    80004ce8:	fc26                	sd	s1,56(sp)
    80004cea:	f84a                	sd	s2,48(sp)
    80004cec:	f44e                	sd	s3,40(sp)
    80004cee:	f052                	sd	s4,32(sp)
    80004cf0:	ec56                	sd	s5,24(sp)
    80004cf2:	e85a                	sd	s6,16(sp)
    80004cf4:	0880                	addi	s0,sp,80
    80004cf6:	84aa                	mv	s1,a0
    80004cf8:	892e                	mv	s2,a1
    80004cfa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	cd4080e7          	jalr	-812(ra) # 800019d0 <myproc>
    80004d04:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d06:	8b26                	mv	s6,s1
    80004d08:	8526                	mv	a0,s1
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	eda080e7          	jalr	-294(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d12:	2184a703          	lw	a4,536(s1)
    80004d16:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d1a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d1e:	02f71463          	bne	a4,a5,80004d46 <piperead+0x64>
    80004d22:	2244a783          	lw	a5,548(s1)
    80004d26:	c385                	beqz	a5,80004d46 <piperead+0x64>
    if(pr->killed){
    80004d28:	028a2783          	lw	a5,40(s4)
    80004d2c:	ebc1                	bnez	a5,80004dbc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d2e:	85da                	mv	a1,s6
    80004d30:	854e                	mv	a0,s3
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	2ea080e7          	jalr	746(ra) # 8000201c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d3a:	2184a703          	lw	a4,536(s1)
    80004d3e:	21c4a783          	lw	a5,540(s1)
    80004d42:	fef700e3          	beq	a4,a5,80004d22 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d46:	09505263          	blez	s5,80004dca <piperead+0xe8>
    80004d4a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d4c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d4e:	2184a783          	lw	a5,536(s1)
    80004d52:	21c4a703          	lw	a4,540(s1)
    80004d56:	02f70d63          	beq	a4,a5,80004d90 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d5a:	0017871b          	addiw	a4,a5,1
    80004d5e:	20e4ac23          	sw	a4,536(s1)
    80004d62:	1ff7f793          	andi	a5,a5,511
    80004d66:	97a6                	add	a5,a5,s1
    80004d68:	0187c783          	lbu	a5,24(a5)
    80004d6c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d70:	4685                	li	a3,1
    80004d72:	fbf40613          	addi	a2,s0,-65
    80004d76:	85ca                	mv	a1,s2
    80004d78:	060a3503          	ld	a0,96(s4)
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	916080e7          	jalr	-1770(ra) # 80001692 <copyout>
    80004d84:	01650663          	beq	a0,s6,80004d90 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d88:	2985                	addiw	s3,s3,1
    80004d8a:	0905                	addi	s2,s2,1
    80004d8c:	fd3a91e3          	bne	s5,s3,80004d4e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d90:	21c48513          	addi	a0,s1,540
    80004d94:	ffffd097          	auipc	ra,0xffffd
    80004d98:	414080e7          	jalr	1044(ra) # 800021a8 <wakeup>
  release(&pi->lock);
    80004d9c:	8526                	mv	a0,s1
    80004d9e:	ffffc097          	auipc	ra,0xffffc
    80004da2:	efa080e7          	jalr	-262(ra) # 80000c98 <release>
  return i;
}
    80004da6:	854e                	mv	a0,s3
    80004da8:	60a6                	ld	ra,72(sp)
    80004daa:	6406                	ld	s0,64(sp)
    80004dac:	74e2                	ld	s1,56(sp)
    80004dae:	7942                	ld	s2,48(sp)
    80004db0:	79a2                	ld	s3,40(sp)
    80004db2:	7a02                	ld	s4,32(sp)
    80004db4:	6ae2                	ld	s5,24(sp)
    80004db6:	6b42                	ld	s6,16(sp)
    80004db8:	6161                	addi	sp,sp,80
    80004dba:	8082                	ret
      release(&pi->lock);
    80004dbc:	8526                	mv	a0,s1
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	eda080e7          	jalr	-294(ra) # 80000c98 <release>
      return -1;
    80004dc6:	59fd                	li	s3,-1
    80004dc8:	bff9                	j	80004da6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dca:	4981                	li	s3,0
    80004dcc:	b7d1                	j	80004d90 <piperead+0xae>

0000000080004dce <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004dce:	df010113          	addi	sp,sp,-528
    80004dd2:	20113423          	sd	ra,520(sp)
    80004dd6:	20813023          	sd	s0,512(sp)
    80004dda:	ffa6                	sd	s1,504(sp)
    80004ddc:	fbca                	sd	s2,496(sp)
    80004dde:	f7ce                	sd	s3,488(sp)
    80004de0:	f3d2                	sd	s4,480(sp)
    80004de2:	efd6                	sd	s5,472(sp)
    80004de4:	ebda                	sd	s6,464(sp)
    80004de6:	e7de                	sd	s7,456(sp)
    80004de8:	e3e2                	sd	s8,448(sp)
    80004dea:	ff66                	sd	s9,440(sp)
    80004dec:	fb6a                	sd	s10,432(sp)
    80004dee:	f76e                	sd	s11,424(sp)
    80004df0:	0c00                	addi	s0,sp,528
    80004df2:	84aa                	mv	s1,a0
    80004df4:	dea43c23          	sd	a0,-520(s0)
    80004df8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	bd4080e7          	jalr	-1068(ra) # 800019d0 <myproc>
    80004e04:	892a                	mv	s2,a0

  begin_op();
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	49c080e7          	jalr	1180(ra) # 800042a2 <begin_op>

  if((ip = namei(path)) == 0){
    80004e0e:	8526                	mv	a0,s1
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	276080e7          	jalr	630(ra) # 80004086 <namei>
    80004e18:	c92d                	beqz	a0,80004e8a <exec+0xbc>
    80004e1a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	ab4080e7          	jalr	-1356(ra) # 800038d0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e24:	04000713          	li	a4,64
    80004e28:	4681                	li	a3,0
    80004e2a:	e5040613          	addi	a2,s0,-432
    80004e2e:	4581                	li	a1,0
    80004e30:	8526                	mv	a0,s1
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	d52080e7          	jalr	-686(ra) # 80003b84 <readi>
    80004e3a:	04000793          	li	a5,64
    80004e3e:	00f51a63          	bne	a0,a5,80004e52 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e42:	e5042703          	lw	a4,-432(s0)
    80004e46:	464c47b7          	lui	a5,0x464c4
    80004e4a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e4e:	04f70463          	beq	a4,a5,80004e96 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e52:	8526                	mv	a0,s1
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	cde080e7          	jalr	-802(ra) # 80003b32 <iunlockput>
    end_op();
    80004e5c:	fffff097          	auipc	ra,0xfffff
    80004e60:	4c6080e7          	jalr	1222(ra) # 80004322 <end_op>
  }
  return -1;
    80004e64:	557d                	li	a0,-1
}
    80004e66:	20813083          	ld	ra,520(sp)
    80004e6a:	20013403          	ld	s0,512(sp)
    80004e6e:	74fe                	ld	s1,504(sp)
    80004e70:	795e                	ld	s2,496(sp)
    80004e72:	79be                	ld	s3,488(sp)
    80004e74:	7a1e                	ld	s4,480(sp)
    80004e76:	6afe                	ld	s5,472(sp)
    80004e78:	6b5e                	ld	s6,464(sp)
    80004e7a:	6bbe                	ld	s7,456(sp)
    80004e7c:	6c1e                	ld	s8,448(sp)
    80004e7e:	7cfa                	ld	s9,440(sp)
    80004e80:	7d5a                	ld	s10,432(sp)
    80004e82:	7dba                	ld	s11,424(sp)
    80004e84:	21010113          	addi	sp,sp,528
    80004e88:	8082                	ret
    end_op();
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	498080e7          	jalr	1176(ra) # 80004322 <end_op>
    return -1;
    80004e92:	557d                	li	a0,-1
    80004e94:	bfc9                	j	80004e66 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e96:	854a                	mv	a0,s2
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	bfc080e7          	jalr	-1028(ra) # 80001a94 <proc_pagetable>
    80004ea0:	8baa                	mv	s7,a0
    80004ea2:	d945                	beqz	a0,80004e52 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea4:	e7042983          	lw	s3,-400(s0)
    80004ea8:	e8845783          	lhu	a5,-376(s0)
    80004eac:	c7ad                	beqz	a5,80004f16 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eae:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eb0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004eb2:	6c85                	lui	s9,0x1
    80004eb4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004eb8:	def43823          	sd	a5,-528(s0)
    80004ebc:	a42d                	j	800050e6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ebe:	00004517          	auipc	a0,0x4
    80004ec2:	8aa50513          	addi	a0,a0,-1878 # 80008768 <syscalls+0x290>
    80004ec6:	ffffb097          	auipc	ra,0xffffb
    80004eca:	678080e7          	jalr	1656(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ece:	8756                	mv	a4,s5
    80004ed0:	012d86bb          	addw	a3,s11,s2
    80004ed4:	4581                	li	a1,0
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	cac080e7          	jalr	-852(ra) # 80003b84 <readi>
    80004ee0:	2501                	sext.w	a0,a0
    80004ee2:	1aaa9963          	bne	s5,a0,80005094 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ee6:	6785                	lui	a5,0x1
    80004ee8:	0127893b          	addw	s2,a5,s2
    80004eec:	77fd                	lui	a5,0xfffff
    80004eee:	01478a3b          	addw	s4,a5,s4
    80004ef2:	1f897163          	bgeu	s2,s8,800050d4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ef6:	02091593          	slli	a1,s2,0x20
    80004efa:	9181                	srli	a1,a1,0x20
    80004efc:	95ea                	add	a1,a1,s10
    80004efe:	855e                	mv	a0,s7
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	18e080e7          	jalr	398(ra) # 8000108e <walkaddr>
    80004f08:	862a                	mv	a2,a0
    if(pa == 0)
    80004f0a:	d955                	beqz	a0,80004ebe <exec+0xf0>
      n = PGSIZE;
    80004f0c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f0e:	fd9a70e3          	bgeu	s4,s9,80004ece <exec+0x100>
      n = sz - i;
    80004f12:	8ad2                	mv	s5,s4
    80004f14:	bf6d                	j	80004ece <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f16:	4901                	li	s2,0
  iunlockput(ip);
    80004f18:	8526                	mv	a0,s1
    80004f1a:	fffff097          	auipc	ra,0xfffff
    80004f1e:	c18080e7          	jalr	-1000(ra) # 80003b32 <iunlockput>
  end_op();
    80004f22:	fffff097          	auipc	ra,0xfffff
    80004f26:	400080e7          	jalr	1024(ra) # 80004322 <end_op>
  p = myproc();
    80004f2a:	ffffd097          	auipc	ra,0xffffd
    80004f2e:	aa6080e7          	jalr	-1370(ra) # 800019d0 <myproc>
    80004f32:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f34:	05853d03          	ld	s10,88(a0)
  sz = PGROUNDUP(sz);
    80004f38:	6785                	lui	a5,0x1
    80004f3a:	17fd                	addi	a5,a5,-1
    80004f3c:	993e                	add	s2,s2,a5
    80004f3e:	757d                	lui	a0,0xfffff
    80004f40:	00a977b3          	and	a5,s2,a0
    80004f44:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f48:	6609                	lui	a2,0x2
    80004f4a:	963e                	add	a2,a2,a5
    80004f4c:	85be                	mv	a1,a5
    80004f4e:	855e                	mv	a0,s7
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	4f2080e7          	jalr	1266(ra) # 80001442 <uvmalloc>
    80004f58:	8b2a                	mv	s6,a0
  ip = 0;
    80004f5a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f5c:	12050c63          	beqz	a0,80005094 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f60:	75f9                	lui	a1,0xffffe
    80004f62:	95aa                	add	a1,a1,a0
    80004f64:	855e                	mv	a0,s7
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	6fa080e7          	jalr	1786(ra) # 80001660 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f6e:	7c7d                	lui	s8,0xfffff
    80004f70:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f72:	e0043783          	ld	a5,-512(s0)
    80004f76:	6388                	ld	a0,0(a5)
    80004f78:	c535                	beqz	a0,80004fe4 <exec+0x216>
    80004f7a:	e9040993          	addi	s3,s0,-368
    80004f7e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f82:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	ee0080e7          	jalr	-288(ra) # 80000e64 <strlen>
    80004f8c:	2505                	addiw	a0,a0,1
    80004f8e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f92:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f96:	13896363          	bltu	s2,s8,800050bc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f9a:	e0043d83          	ld	s11,-512(s0)
    80004f9e:	000dba03          	ld	s4,0(s11)
    80004fa2:	8552                	mv	a0,s4
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	ec0080e7          	jalr	-320(ra) # 80000e64 <strlen>
    80004fac:	0015069b          	addiw	a3,a0,1
    80004fb0:	8652                	mv	a2,s4
    80004fb2:	85ca                	mv	a1,s2
    80004fb4:	855e                	mv	a0,s7
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	6dc080e7          	jalr	1756(ra) # 80001692 <copyout>
    80004fbe:	10054363          	bltz	a0,800050c4 <exec+0x2f6>
    ustack[argc] = sp;
    80004fc2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fc6:	0485                	addi	s1,s1,1
    80004fc8:	008d8793          	addi	a5,s11,8
    80004fcc:	e0f43023          	sd	a5,-512(s0)
    80004fd0:	008db503          	ld	a0,8(s11)
    80004fd4:	c911                	beqz	a0,80004fe8 <exec+0x21a>
    if(argc >= MAXARG)
    80004fd6:	09a1                	addi	s3,s3,8
    80004fd8:	fb3c96e3          	bne	s9,s3,80004f84 <exec+0x1b6>
  sz = sz1;
    80004fdc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe0:	4481                	li	s1,0
    80004fe2:	a84d                	j	80005094 <exec+0x2c6>
  sp = sz;
    80004fe4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fe6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fe8:	00349793          	slli	a5,s1,0x3
    80004fec:	f9040713          	addi	a4,s0,-112
    80004ff0:	97ba                	add	a5,a5,a4
    80004ff2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ff6:	00148693          	addi	a3,s1,1
    80004ffa:	068e                	slli	a3,a3,0x3
    80004ffc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005000:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005004:	01897663          	bgeu	s2,s8,80005010 <exec+0x242>
  sz = sz1;
    80005008:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000500c:	4481                	li	s1,0
    8000500e:	a059                	j	80005094 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005010:	e9040613          	addi	a2,s0,-368
    80005014:	85ca                	mv	a1,s2
    80005016:	855e                	mv	a0,s7
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	67a080e7          	jalr	1658(ra) # 80001692 <copyout>
    80005020:	0a054663          	bltz	a0,800050cc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005024:	068ab783          	ld	a5,104(s5)
    80005028:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000502c:	df843783          	ld	a5,-520(s0)
    80005030:	0007c703          	lbu	a4,0(a5)
    80005034:	cf11                	beqz	a4,80005050 <exec+0x282>
    80005036:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005038:	02f00693          	li	a3,47
    8000503c:	a039                	j	8000504a <exec+0x27c>
      last = s+1;
    8000503e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005042:	0785                	addi	a5,a5,1
    80005044:	fff7c703          	lbu	a4,-1(a5)
    80005048:	c701                	beqz	a4,80005050 <exec+0x282>
    if(*s == '/')
    8000504a:	fed71ce3          	bne	a4,a3,80005042 <exec+0x274>
    8000504e:	bfc5                	j	8000503e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005050:	4641                	li	a2,16
    80005052:	df843583          	ld	a1,-520(s0)
    80005056:	168a8513          	addi	a0,s5,360
    8000505a:	ffffc097          	auipc	ra,0xffffc
    8000505e:	dd8080e7          	jalr	-552(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005062:	060ab503          	ld	a0,96(s5)
  p->pagetable = pagetable;
    80005066:	077ab023          	sd	s7,96(s5)
  p->sz = sz;
    8000506a:	056abc23          	sd	s6,88(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000506e:	068ab783          	ld	a5,104(s5)
    80005072:	e6843703          	ld	a4,-408(s0)
    80005076:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005078:	068ab783          	ld	a5,104(s5)
    8000507c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005080:	85ea                	mv	a1,s10
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	aae080e7          	jalr	-1362(ra) # 80001b30 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000508a:	0004851b          	sext.w	a0,s1
    8000508e:	bbe1                	j	80004e66 <exec+0x98>
    80005090:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005094:	e0843583          	ld	a1,-504(s0)
    80005098:	855e                	mv	a0,s7
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	a96080e7          	jalr	-1386(ra) # 80001b30 <proc_freepagetable>
  if(ip){
    800050a2:	da0498e3          	bnez	s1,80004e52 <exec+0x84>
  return -1;
    800050a6:	557d                	li	a0,-1
    800050a8:	bb7d                	j	80004e66 <exec+0x98>
    800050aa:	e1243423          	sd	s2,-504(s0)
    800050ae:	b7dd                	j	80005094 <exec+0x2c6>
    800050b0:	e1243423          	sd	s2,-504(s0)
    800050b4:	b7c5                	j	80005094 <exec+0x2c6>
    800050b6:	e1243423          	sd	s2,-504(s0)
    800050ba:	bfe9                	j	80005094 <exec+0x2c6>
  sz = sz1;
    800050bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c0:	4481                	li	s1,0
    800050c2:	bfc9                	j	80005094 <exec+0x2c6>
  sz = sz1;
    800050c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c8:	4481                	li	s1,0
    800050ca:	b7e9                	j	80005094 <exec+0x2c6>
  sz = sz1;
    800050cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d0:	4481                	li	s1,0
    800050d2:	b7c9                	j	80005094 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050d4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050d8:	2b05                	addiw	s6,s6,1
    800050da:	0389899b          	addiw	s3,s3,56
    800050de:	e8845783          	lhu	a5,-376(s0)
    800050e2:	e2fb5be3          	bge	s6,a5,80004f18 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050e6:	2981                	sext.w	s3,s3
    800050e8:	03800713          	li	a4,56
    800050ec:	86ce                	mv	a3,s3
    800050ee:	e1840613          	addi	a2,s0,-488
    800050f2:	4581                	li	a1,0
    800050f4:	8526                	mv	a0,s1
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	a8e080e7          	jalr	-1394(ra) # 80003b84 <readi>
    800050fe:	03800793          	li	a5,56
    80005102:	f8f517e3          	bne	a0,a5,80005090 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005106:	e1842783          	lw	a5,-488(s0)
    8000510a:	4705                	li	a4,1
    8000510c:	fce796e3          	bne	a5,a4,800050d8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005110:	e4043603          	ld	a2,-448(s0)
    80005114:	e3843783          	ld	a5,-456(s0)
    80005118:	f8f669e3          	bltu	a2,a5,800050aa <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000511c:	e2843783          	ld	a5,-472(s0)
    80005120:	963e                	add	a2,a2,a5
    80005122:	f8f667e3          	bltu	a2,a5,800050b0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005126:	85ca                	mv	a1,s2
    80005128:	855e                	mv	a0,s7
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	318080e7          	jalr	792(ra) # 80001442 <uvmalloc>
    80005132:	e0a43423          	sd	a0,-504(s0)
    80005136:	d141                	beqz	a0,800050b6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005138:	e2843d03          	ld	s10,-472(s0)
    8000513c:	df043783          	ld	a5,-528(s0)
    80005140:	00fd77b3          	and	a5,s10,a5
    80005144:	fba1                	bnez	a5,80005094 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005146:	e2042d83          	lw	s11,-480(s0)
    8000514a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000514e:	f80c03e3          	beqz	s8,800050d4 <exec+0x306>
    80005152:	8a62                	mv	s4,s8
    80005154:	4901                	li	s2,0
    80005156:	b345                	j	80004ef6 <exec+0x128>

0000000080005158 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005158:	7179                	addi	sp,sp,-48
    8000515a:	f406                	sd	ra,40(sp)
    8000515c:	f022                	sd	s0,32(sp)
    8000515e:	ec26                	sd	s1,24(sp)
    80005160:	e84a                	sd	s2,16(sp)
    80005162:	1800                	addi	s0,sp,48
    80005164:	892e                	mv	s2,a1
    80005166:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005168:	fdc40593          	addi	a1,s0,-36
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	ba8080e7          	jalr	-1112(ra) # 80002d14 <argint>
    80005174:	04054063          	bltz	a0,800051b4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005178:	fdc42703          	lw	a4,-36(s0)
    8000517c:	47bd                	li	a5,15
    8000517e:	02e7ed63          	bltu	a5,a4,800051b8 <argfd+0x60>
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	84e080e7          	jalr	-1970(ra) # 800019d0 <myproc>
    8000518a:	fdc42703          	lw	a4,-36(s0)
    8000518e:	01c70793          	addi	a5,a4,28
    80005192:	078e                	slli	a5,a5,0x3
    80005194:	953e                	add	a0,a0,a5
    80005196:	611c                	ld	a5,0(a0)
    80005198:	c395                	beqz	a5,800051bc <argfd+0x64>
    return -1;
  if(pfd)
    8000519a:	00090463          	beqz	s2,800051a2 <argfd+0x4a>
    *pfd = fd;
    8000519e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051a2:	4501                	li	a0,0
  if(pf)
    800051a4:	c091                	beqz	s1,800051a8 <argfd+0x50>
    *pf = f;
    800051a6:	e09c                	sd	a5,0(s1)
}
    800051a8:	70a2                	ld	ra,40(sp)
    800051aa:	7402                	ld	s0,32(sp)
    800051ac:	64e2                	ld	s1,24(sp)
    800051ae:	6942                	ld	s2,16(sp)
    800051b0:	6145                	addi	sp,sp,48
    800051b2:	8082                	ret
    return -1;
    800051b4:	557d                	li	a0,-1
    800051b6:	bfcd                	j	800051a8 <argfd+0x50>
    return -1;
    800051b8:	557d                	li	a0,-1
    800051ba:	b7fd                	j	800051a8 <argfd+0x50>
    800051bc:	557d                	li	a0,-1
    800051be:	b7ed                	j	800051a8 <argfd+0x50>

00000000800051c0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051c0:	1101                	addi	sp,sp,-32
    800051c2:	ec06                	sd	ra,24(sp)
    800051c4:	e822                	sd	s0,16(sp)
    800051c6:	e426                	sd	s1,8(sp)
    800051c8:	1000                	addi	s0,sp,32
    800051ca:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051cc:	ffffd097          	auipc	ra,0xffffd
    800051d0:	804080e7          	jalr	-2044(ra) # 800019d0 <myproc>
    800051d4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051d6:	0e050793          	addi	a5,a0,224 # fffffffffffff0e0 <end+0xffffffff7ffd90e0>
    800051da:	4501                	li	a0,0
    800051dc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051de:	6398                	ld	a4,0(a5)
    800051e0:	cb19                	beqz	a4,800051f6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051e2:	2505                	addiw	a0,a0,1
    800051e4:	07a1                	addi	a5,a5,8
    800051e6:	fed51ce3          	bne	a0,a3,800051de <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051ea:	557d                	li	a0,-1
}
    800051ec:	60e2                	ld	ra,24(sp)
    800051ee:	6442                	ld	s0,16(sp)
    800051f0:	64a2                	ld	s1,8(sp)
    800051f2:	6105                	addi	sp,sp,32
    800051f4:	8082                	ret
      p->ofile[fd] = f;
    800051f6:	01c50793          	addi	a5,a0,28
    800051fa:	078e                	slli	a5,a5,0x3
    800051fc:	963e                	add	a2,a2,a5
    800051fe:	e204                	sd	s1,0(a2)
      return fd;
    80005200:	b7f5                	j	800051ec <fdalloc+0x2c>

0000000080005202 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005202:	715d                	addi	sp,sp,-80
    80005204:	e486                	sd	ra,72(sp)
    80005206:	e0a2                	sd	s0,64(sp)
    80005208:	fc26                	sd	s1,56(sp)
    8000520a:	f84a                	sd	s2,48(sp)
    8000520c:	f44e                	sd	s3,40(sp)
    8000520e:	f052                	sd	s4,32(sp)
    80005210:	ec56                	sd	s5,24(sp)
    80005212:	0880                	addi	s0,sp,80
    80005214:	89ae                	mv	s3,a1
    80005216:	8ab2                	mv	s5,a2
    80005218:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000521a:	fb040593          	addi	a1,s0,-80
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	e86080e7          	jalr	-378(ra) # 800040a4 <nameiparent>
    80005226:	892a                	mv	s2,a0
    80005228:	12050f63          	beqz	a0,80005366 <create+0x164>
    return 0;

  ilock(dp);
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	6a4080e7          	jalr	1700(ra) # 800038d0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005234:	4601                	li	a2,0
    80005236:	fb040593          	addi	a1,s0,-80
    8000523a:	854a                	mv	a0,s2
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	b78080e7          	jalr	-1160(ra) # 80003db4 <dirlookup>
    80005244:	84aa                	mv	s1,a0
    80005246:	c921                	beqz	a0,80005296 <create+0x94>
    iunlockput(dp);
    80005248:	854a                	mv	a0,s2
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	8e8080e7          	jalr	-1816(ra) # 80003b32 <iunlockput>
    ilock(ip);
    80005252:	8526                	mv	a0,s1
    80005254:	ffffe097          	auipc	ra,0xffffe
    80005258:	67c080e7          	jalr	1660(ra) # 800038d0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000525c:	2981                	sext.w	s3,s3
    8000525e:	4789                	li	a5,2
    80005260:	02f99463          	bne	s3,a5,80005288 <create+0x86>
    80005264:	0444d783          	lhu	a5,68(s1)
    80005268:	37f9                	addiw	a5,a5,-2
    8000526a:	17c2                	slli	a5,a5,0x30
    8000526c:	93c1                	srli	a5,a5,0x30
    8000526e:	4705                	li	a4,1
    80005270:	00f76c63          	bltu	a4,a5,80005288 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005274:	8526                	mv	a0,s1
    80005276:	60a6                	ld	ra,72(sp)
    80005278:	6406                	ld	s0,64(sp)
    8000527a:	74e2                	ld	s1,56(sp)
    8000527c:	7942                	ld	s2,48(sp)
    8000527e:	79a2                	ld	s3,40(sp)
    80005280:	7a02                	ld	s4,32(sp)
    80005282:	6ae2                	ld	s5,24(sp)
    80005284:	6161                	addi	sp,sp,80
    80005286:	8082                	ret
    iunlockput(ip);
    80005288:	8526                	mv	a0,s1
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	8a8080e7          	jalr	-1880(ra) # 80003b32 <iunlockput>
    return 0;
    80005292:	4481                	li	s1,0
    80005294:	b7c5                	j	80005274 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005296:	85ce                	mv	a1,s3
    80005298:	00092503          	lw	a0,0(s2)
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	49c080e7          	jalr	1180(ra) # 80003738 <ialloc>
    800052a4:	84aa                	mv	s1,a0
    800052a6:	c529                	beqz	a0,800052f0 <create+0xee>
  ilock(ip);
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	628080e7          	jalr	1576(ra) # 800038d0 <ilock>
  ip->major = major;
    800052b0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052b4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052b8:	4785                	li	a5,1
    800052ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052be:	8526                	mv	a0,s1
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	546080e7          	jalr	1350(ra) # 80003806 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052c8:	2981                	sext.w	s3,s3
    800052ca:	4785                	li	a5,1
    800052cc:	02f98a63          	beq	s3,a5,80005300 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052d0:	40d0                	lw	a2,4(s1)
    800052d2:	fb040593          	addi	a1,s0,-80
    800052d6:	854a                	mv	a0,s2
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	cec080e7          	jalr	-788(ra) # 80003fc4 <dirlink>
    800052e0:	06054b63          	bltz	a0,80005356 <create+0x154>
  iunlockput(dp);
    800052e4:	854a                	mv	a0,s2
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	84c080e7          	jalr	-1972(ra) # 80003b32 <iunlockput>
  return ip;
    800052ee:	b759                	j	80005274 <create+0x72>
    panic("create: ialloc");
    800052f0:	00003517          	auipc	a0,0x3
    800052f4:	49850513          	addi	a0,a0,1176 # 80008788 <syscalls+0x2b0>
    800052f8:	ffffb097          	auipc	ra,0xffffb
    800052fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005300:	04a95783          	lhu	a5,74(s2)
    80005304:	2785                	addiw	a5,a5,1
    80005306:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000530a:	854a                	mv	a0,s2
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	4fa080e7          	jalr	1274(ra) # 80003806 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005314:	40d0                	lw	a2,4(s1)
    80005316:	00003597          	auipc	a1,0x3
    8000531a:	48258593          	addi	a1,a1,1154 # 80008798 <syscalls+0x2c0>
    8000531e:	8526                	mv	a0,s1
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	ca4080e7          	jalr	-860(ra) # 80003fc4 <dirlink>
    80005328:	00054f63          	bltz	a0,80005346 <create+0x144>
    8000532c:	00492603          	lw	a2,4(s2)
    80005330:	00003597          	auipc	a1,0x3
    80005334:	47058593          	addi	a1,a1,1136 # 800087a0 <syscalls+0x2c8>
    80005338:	8526                	mv	a0,s1
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	c8a080e7          	jalr	-886(ra) # 80003fc4 <dirlink>
    80005342:	f80557e3          	bgez	a0,800052d0 <create+0xce>
      panic("create dots");
    80005346:	00003517          	auipc	a0,0x3
    8000534a:	46250513          	addi	a0,a0,1122 # 800087a8 <syscalls+0x2d0>
    8000534e:	ffffb097          	auipc	ra,0xffffb
    80005352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005356:	00003517          	auipc	a0,0x3
    8000535a:	46250513          	addi	a0,a0,1122 # 800087b8 <syscalls+0x2e0>
    8000535e:	ffffb097          	auipc	ra,0xffffb
    80005362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>
    return 0;
    80005366:	84aa                	mv	s1,a0
    80005368:	b731                	j	80005274 <create+0x72>

000000008000536a <sys_dup>:
{
    8000536a:	7179                	addi	sp,sp,-48
    8000536c:	f406                	sd	ra,40(sp)
    8000536e:	f022                	sd	s0,32(sp)
    80005370:	ec26                	sd	s1,24(sp)
    80005372:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005374:	fd840613          	addi	a2,s0,-40
    80005378:	4581                	li	a1,0
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	ddc080e7          	jalr	-548(ra) # 80005158 <argfd>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005386:	02054363          	bltz	a0,800053ac <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000538a:	fd843503          	ld	a0,-40(s0)
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	e32080e7          	jalr	-462(ra) # 800051c0 <fdalloc>
    80005396:	84aa                	mv	s1,a0
    return -1;
    80005398:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000539a:	00054963          	bltz	a0,800053ac <sys_dup+0x42>
  filedup(f);
    8000539e:	fd843503          	ld	a0,-40(s0)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	37a080e7          	jalr	890(ra) # 8000471c <filedup>
  return fd;
    800053aa:	87a6                	mv	a5,s1
}
    800053ac:	853e                	mv	a0,a5
    800053ae:	70a2                	ld	ra,40(sp)
    800053b0:	7402                	ld	s0,32(sp)
    800053b2:	64e2                	ld	s1,24(sp)
    800053b4:	6145                	addi	sp,sp,48
    800053b6:	8082                	ret

00000000800053b8 <sys_read>:
{
    800053b8:	7179                	addi	sp,sp,-48
    800053ba:	f406                	sd	ra,40(sp)
    800053bc:	f022                	sd	s0,32(sp)
    800053be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c0:	fe840613          	addi	a2,s0,-24
    800053c4:	4581                	li	a1,0
    800053c6:	4501                	li	a0,0
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	d90080e7          	jalr	-624(ra) # 80005158 <argfd>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d2:	04054163          	bltz	a0,80005414 <sys_read+0x5c>
    800053d6:	fe440593          	addi	a1,s0,-28
    800053da:	4509                	li	a0,2
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	938080e7          	jalr	-1736(ra) # 80002d14 <argint>
    return -1;
    800053e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e6:	02054763          	bltz	a0,80005414 <sys_read+0x5c>
    800053ea:	fd840593          	addi	a1,s0,-40
    800053ee:	4505                	li	a0,1
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	946080e7          	jalr	-1722(ra) # 80002d36 <argaddr>
    return -1;
    800053f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fa:	00054d63          	bltz	a0,80005414 <sys_read+0x5c>
  return fileread(f, p, n);
    800053fe:	fe442603          	lw	a2,-28(s0)
    80005402:	fd843583          	ld	a1,-40(s0)
    80005406:	fe843503          	ld	a0,-24(s0)
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	49e080e7          	jalr	1182(ra) # 800048a8 <fileread>
    80005412:	87aa                	mv	a5,a0
}
    80005414:	853e                	mv	a0,a5
    80005416:	70a2                	ld	ra,40(sp)
    80005418:	7402                	ld	s0,32(sp)
    8000541a:	6145                	addi	sp,sp,48
    8000541c:	8082                	ret

000000008000541e <sys_write>:
{
    8000541e:	7179                	addi	sp,sp,-48
    80005420:	f406                	sd	ra,40(sp)
    80005422:	f022                	sd	s0,32(sp)
    80005424:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005426:	fe840613          	addi	a2,s0,-24
    8000542a:	4581                	li	a1,0
    8000542c:	4501                	li	a0,0
    8000542e:	00000097          	auipc	ra,0x0
    80005432:	d2a080e7          	jalr	-726(ra) # 80005158 <argfd>
    return -1;
    80005436:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005438:	04054163          	bltz	a0,8000547a <sys_write+0x5c>
    8000543c:	fe440593          	addi	a1,s0,-28
    80005440:	4509                	li	a0,2
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	8d2080e7          	jalr	-1838(ra) # 80002d14 <argint>
    return -1;
    8000544a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544c:	02054763          	bltz	a0,8000547a <sys_write+0x5c>
    80005450:	fd840593          	addi	a1,s0,-40
    80005454:	4505                	li	a0,1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	8e0080e7          	jalr	-1824(ra) # 80002d36 <argaddr>
    return -1;
    8000545e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005460:	00054d63          	bltz	a0,8000547a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005464:	fe442603          	lw	a2,-28(s0)
    80005468:	fd843583          	ld	a1,-40(s0)
    8000546c:	fe843503          	ld	a0,-24(s0)
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	4fa080e7          	jalr	1274(ra) # 8000496a <filewrite>
    80005478:	87aa                	mv	a5,a0
}
    8000547a:	853e                	mv	a0,a5
    8000547c:	70a2                	ld	ra,40(sp)
    8000547e:	7402                	ld	s0,32(sp)
    80005480:	6145                	addi	sp,sp,48
    80005482:	8082                	ret

0000000080005484 <sys_close>:
{
    80005484:	1101                	addi	sp,sp,-32
    80005486:	ec06                	sd	ra,24(sp)
    80005488:	e822                	sd	s0,16(sp)
    8000548a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000548c:	fe040613          	addi	a2,s0,-32
    80005490:	fec40593          	addi	a1,s0,-20
    80005494:	4501                	li	a0,0
    80005496:	00000097          	auipc	ra,0x0
    8000549a:	cc2080e7          	jalr	-830(ra) # 80005158 <argfd>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054a0:	02054463          	bltz	a0,800054c8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	52c080e7          	jalr	1324(ra) # 800019d0 <myproc>
    800054ac:	fec42783          	lw	a5,-20(s0)
    800054b0:	07f1                	addi	a5,a5,28
    800054b2:	078e                	slli	a5,a5,0x3
    800054b4:	97aa                	add	a5,a5,a0
    800054b6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054ba:	fe043503          	ld	a0,-32(s0)
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	2b0080e7          	jalr	688(ra) # 8000476e <fileclose>
  return 0;
    800054c6:	4781                	li	a5,0
}
    800054c8:	853e                	mv	a0,a5
    800054ca:	60e2                	ld	ra,24(sp)
    800054cc:	6442                	ld	s0,16(sp)
    800054ce:	6105                	addi	sp,sp,32
    800054d0:	8082                	ret

00000000800054d2 <sys_fstat>:
{
    800054d2:	1101                	addi	sp,sp,-32
    800054d4:	ec06                	sd	ra,24(sp)
    800054d6:	e822                	sd	s0,16(sp)
    800054d8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054da:	fe840613          	addi	a2,s0,-24
    800054de:	4581                	li	a1,0
    800054e0:	4501                	li	a0,0
    800054e2:	00000097          	auipc	ra,0x0
    800054e6:	c76080e7          	jalr	-906(ra) # 80005158 <argfd>
    return -1;
    800054ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054ec:	02054563          	bltz	a0,80005516 <sys_fstat+0x44>
    800054f0:	fe040593          	addi	a1,s0,-32
    800054f4:	4505                	li	a0,1
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	840080e7          	jalr	-1984(ra) # 80002d36 <argaddr>
    return -1;
    800054fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005500:	00054b63          	bltz	a0,80005516 <sys_fstat+0x44>
  return filestat(f, st);
    80005504:	fe043583          	ld	a1,-32(s0)
    80005508:	fe843503          	ld	a0,-24(s0)
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	32a080e7          	jalr	810(ra) # 80004836 <filestat>
    80005514:	87aa                	mv	a5,a0
}
    80005516:	853e                	mv	a0,a5
    80005518:	60e2                	ld	ra,24(sp)
    8000551a:	6442                	ld	s0,16(sp)
    8000551c:	6105                	addi	sp,sp,32
    8000551e:	8082                	ret

0000000080005520 <sys_link>:
{
    80005520:	7169                	addi	sp,sp,-304
    80005522:	f606                	sd	ra,296(sp)
    80005524:	f222                	sd	s0,288(sp)
    80005526:	ee26                	sd	s1,280(sp)
    80005528:	ea4a                	sd	s2,272(sp)
    8000552a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000552c:	08000613          	li	a2,128
    80005530:	ed040593          	addi	a1,s0,-304
    80005534:	4501                	li	a0,0
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	822080e7          	jalr	-2014(ra) # 80002d58 <argstr>
    return -1;
    8000553e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005540:	10054e63          	bltz	a0,8000565c <sys_link+0x13c>
    80005544:	08000613          	li	a2,128
    80005548:	f5040593          	addi	a1,s0,-176
    8000554c:	4505                	li	a0,1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	80a080e7          	jalr	-2038(ra) # 80002d58 <argstr>
    return -1;
    80005556:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005558:	10054263          	bltz	a0,8000565c <sys_link+0x13c>
  begin_op();
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	d46080e7          	jalr	-698(ra) # 800042a2 <begin_op>
  if((ip = namei(old)) == 0){
    80005564:	ed040513          	addi	a0,s0,-304
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	b1e080e7          	jalr	-1250(ra) # 80004086 <namei>
    80005570:	84aa                	mv	s1,a0
    80005572:	c551                	beqz	a0,800055fe <sys_link+0xde>
  ilock(ip);
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	35c080e7          	jalr	860(ra) # 800038d0 <ilock>
  if(ip->type == T_DIR){
    8000557c:	04449703          	lh	a4,68(s1)
    80005580:	4785                	li	a5,1
    80005582:	08f70463          	beq	a4,a5,8000560a <sys_link+0xea>
  ip->nlink++;
    80005586:	04a4d783          	lhu	a5,74(s1)
    8000558a:	2785                	addiw	a5,a5,1
    8000558c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005590:	8526                	mv	a0,s1
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	274080e7          	jalr	628(ra) # 80003806 <iupdate>
  iunlock(ip);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	3f6080e7          	jalr	1014(ra) # 80003992 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055a4:	fd040593          	addi	a1,s0,-48
    800055a8:	f5040513          	addi	a0,s0,-176
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	af8080e7          	jalr	-1288(ra) # 800040a4 <nameiparent>
    800055b4:	892a                	mv	s2,a0
    800055b6:	c935                	beqz	a0,8000562a <sys_link+0x10a>
  ilock(dp);
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	318080e7          	jalr	792(ra) # 800038d0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055c0:	00092703          	lw	a4,0(s2)
    800055c4:	409c                	lw	a5,0(s1)
    800055c6:	04f71d63          	bne	a4,a5,80005620 <sys_link+0x100>
    800055ca:	40d0                	lw	a2,4(s1)
    800055cc:	fd040593          	addi	a1,s0,-48
    800055d0:	854a                	mv	a0,s2
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	9f2080e7          	jalr	-1550(ra) # 80003fc4 <dirlink>
    800055da:	04054363          	bltz	a0,80005620 <sys_link+0x100>
  iunlockput(dp);
    800055de:	854a                	mv	a0,s2
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	552080e7          	jalr	1362(ra) # 80003b32 <iunlockput>
  iput(ip);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	4a0080e7          	jalr	1184(ra) # 80003a8a <iput>
  end_op();
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	d30080e7          	jalr	-720(ra) # 80004322 <end_op>
  return 0;
    800055fa:	4781                	li	a5,0
    800055fc:	a085                	j	8000565c <sys_link+0x13c>
    end_op();
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	d24080e7          	jalr	-732(ra) # 80004322 <end_op>
    return -1;
    80005606:	57fd                	li	a5,-1
    80005608:	a891                	j	8000565c <sys_link+0x13c>
    iunlockput(ip);
    8000560a:	8526                	mv	a0,s1
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	526080e7          	jalr	1318(ra) # 80003b32 <iunlockput>
    end_op();
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	d0e080e7          	jalr	-754(ra) # 80004322 <end_op>
    return -1;
    8000561c:	57fd                	li	a5,-1
    8000561e:	a83d                	j	8000565c <sys_link+0x13c>
    iunlockput(dp);
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	510080e7          	jalr	1296(ra) # 80003b32 <iunlockput>
  ilock(ip);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	2a4080e7          	jalr	676(ra) # 800038d0 <ilock>
  ip->nlink--;
    80005634:	04a4d783          	lhu	a5,74(s1)
    80005638:	37fd                	addiw	a5,a5,-1
    8000563a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	1c6080e7          	jalr	454(ra) # 80003806 <iupdate>
  iunlockput(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	4e8080e7          	jalr	1256(ra) # 80003b32 <iunlockput>
  end_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	cd0080e7          	jalr	-816(ra) # 80004322 <end_op>
  return -1;
    8000565a:	57fd                	li	a5,-1
}
    8000565c:	853e                	mv	a0,a5
    8000565e:	70b2                	ld	ra,296(sp)
    80005660:	7412                	ld	s0,288(sp)
    80005662:	64f2                	ld	s1,280(sp)
    80005664:	6952                	ld	s2,272(sp)
    80005666:	6155                	addi	sp,sp,304
    80005668:	8082                	ret

000000008000566a <sys_unlink>:
{
    8000566a:	7151                	addi	sp,sp,-240
    8000566c:	f586                	sd	ra,232(sp)
    8000566e:	f1a2                	sd	s0,224(sp)
    80005670:	eda6                	sd	s1,216(sp)
    80005672:	e9ca                	sd	s2,208(sp)
    80005674:	e5ce                	sd	s3,200(sp)
    80005676:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005678:	08000613          	li	a2,128
    8000567c:	f3040593          	addi	a1,s0,-208
    80005680:	4501                	li	a0,0
    80005682:	ffffd097          	auipc	ra,0xffffd
    80005686:	6d6080e7          	jalr	1750(ra) # 80002d58 <argstr>
    8000568a:	18054163          	bltz	a0,8000580c <sys_unlink+0x1a2>
  begin_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	c14080e7          	jalr	-1004(ra) # 800042a2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005696:	fb040593          	addi	a1,s0,-80
    8000569a:	f3040513          	addi	a0,s0,-208
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	a06080e7          	jalr	-1530(ra) # 800040a4 <nameiparent>
    800056a6:	84aa                	mv	s1,a0
    800056a8:	c979                	beqz	a0,8000577e <sys_unlink+0x114>
  ilock(dp);
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	226080e7          	jalr	550(ra) # 800038d0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056b2:	00003597          	auipc	a1,0x3
    800056b6:	0e658593          	addi	a1,a1,230 # 80008798 <syscalls+0x2c0>
    800056ba:	fb040513          	addi	a0,s0,-80
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	6dc080e7          	jalr	1756(ra) # 80003d9a <namecmp>
    800056c6:	14050a63          	beqz	a0,8000581a <sys_unlink+0x1b0>
    800056ca:	00003597          	auipc	a1,0x3
    800056ce:	0d658593          	addi	a1,a1,214 # 800087a0 <syscalls+0x2c8>
    800056d2:	fb040513          	addi	a0,s0,-80
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	6c4080e7          	jalr	1732(ra) # 80003d9a <namecmp>
    800056de:	12050e63          	beqz	a0,8000581a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056e2:	f2c40613          	addi	a2,s0,-212
    800056e6:	fb040593          	addi	a1,s0,-80
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	6c8080e7          	jalr	1736(ra) # 80003db4 <dirlookup>
    800056f4:	892a                	mv	s2,a0
    800056f6:	12050263          	beqz	a0,8000581a <sys_unlink+0x1b0>
  ilock(ip);
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	1d6080e7          	jalr	470(ra) # 800038d0 <ilock>
  if(ip->nlink < 1)
    80005702:	04a91783          	lh	a5,74(s2)
    80005706:	08f05263          	blez	a5,8000578a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000570a:	04491703          	lh	a4,68(s2)
    8000570e:	4785                	li	a5,1
    80005710:	08f70563          	beq	a4,a5,8000579a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005714:	4641                	li	a2,16
    80005716:	4581                	li	a1,0
    80005718:	fc040513          	addi	a0,s0,-64
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	5c4080e7          	jalr	1476(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005724:	4741                	li	a4,16
    80005726:	f2c42683          	lw	a3,-212(s0)
    8000572a:	fc040613          	addi	a2,s0,-64
    8000572e:	4581                	li	a1,0
    80005730:	8526                	mv	a0,s1
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	54a080e7          	jalr	1354(ra) # 80003c7c <writei>
    8000573a:	47c1                	li	a5,16
    8000573c:	0af51563          	bne	a0,a5,800057e6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005740:	04491703          	lh	a4,68(s2)
    80005744:	4785                	li	a5,1
    80005746:	0af70863          	beq	a4,a5,800057f6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000574a:	8526                	mv	a0,s1
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	3e6080e7          	jalr	998(ra) # 80003b32 <iunlockput>
  ip->nlink--;
    80005754:	04a95783          	lhu	a5,74(s2)
    80005758:	37fd                	addiw	a5,a5,-1
    8000575a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000575e:	854a                	mv	a0,s2
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	0a6080e7          	jalr	166(ra) # 80003806 <iupdate>
  iunlockput(ip);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	3c8080e7          	jalr	968(ra) # 80003b32 <iunlockput>
  end_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	bb0080e7          	jalr	-1104(ra) # 80004322 <end_op>
  return 0;
    8000577a:	4501                	li	a0,0
    8000577c:	a84d                	j	8000582e <sys_unlink+0x1c4>
    end_op();
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	ba4080e7          	jalr	-1116(ra) # 80004322 <end_op>
    return -1;
    80005786:	557d                	li	a0,-1
    80005788:	a05d                	j	8000582e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000578a:	00003517          	auipc	a0,0x3
    8000578e:	03e50513          	addi	a0,a0,62 # 800087c8 <syscalls+0x2f0>
    80005792:	ffffb097          	auipc	ra,0xffffb
    80005796:	dac080e7          	jalr	-596(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000579a:	04c92703          	lw	a4,76(s2)
    8000579e:	02000793          	li	a5,32
    800057a2:	f6e7f9e3          	bgeu	a5,a4,80005714 <sys_unlink+0xaa>
    800057a6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057aa:	4741                	li	a4,16
    800057ac:	86ce                	mv	a3,s3
    800057ae:	f1840613          	addi	a2,s0,-232
    800057b2:	4581                	li	a1,0
    800057b4:	854a                	mv	a0,s2
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	3ce080e7          	jalr	974(ra) # 80003b84 <readi>
    800057be:	47c1                	li	a5,16
    800057c0:	00f51b63          	bne	a0,a5,800057d6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057c4:	f1845783          	lhu	a5,-232(s0)
    800057c8:	e7a1                	bnez	a5,80005810 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ca:	29c1                	addiw	s3,s3,16
    800057cc:	04c92783          	lw	a5,76(s2)
    800057d0:	fcf9ede3          	bltu	s3,a5,800057aa <sys_unlink+0x140>
    800057d4:	b781                	j	80005714 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057d6:	00003517          	auipc	a0,0x3
    800057da:	00a50513          	addi	a0,a0,10 # 800087e0 <syscalls+0x308>
    800057de:	ffffb097          	auipc	ra,0xffffb
    800057e2:	d60080e7          	jalr	-672(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057e6:	00003517          	auipc	a0,0x3
    800057ea:	01250513          	addi	a0,a0,18 # 800087f8 <syscalls+0x320>
    800057ee:	ffffb097          	auipc	ra,0xffffb
    800057f2:	d50080e7          	jalr	-688(ra) # 8000053e <panic>
    dp->nlink--;
    800057f6:	04a4d783          	lhu	a5,74(s1)
    800057fa:	37fd                	addiw	a5,a5,-1
    800057fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005800:	8526                	mv	a0,s1
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	004080e7          	jalr	4(ra) # 80003806 <iupdate>
    8000580a:	b781                	j	8000574a <sys_unlink+0xe0>
    return -1;
    8000580c:	557d                	li	a0,-1
    8000580e:	a005                	j	8000582e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005810:	854a                	mv	a0,s2
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	320080e7          	jalr	800(ra) # 80003b32 <iunlockput>
  iunlockput(dp);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	316080e7          	jalr	790(ra) # 80003b32 <iunlockput>
  end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	afe080e7          	jalr	-1282(ra) # 80004322 <end_op>
  return -1;
    8000582c:	557d                	li	a0,-1
}
    8000582e:	70ae                	ld	ra,232(sp)
    80005830:	740e                	ld	s0,224(sp)
    80005832:	64ee                	ld	s1,216(sp)
    80005834:	694e                	ld	s2,208(sp)
    80005836:	69ae                	ld	s3,200(sp)
    80005838:	616d                	addi	sp,sp,240
    8000583a:	8082                	ret

000000008000583c <sys_open>:

uint64
sys_open(void)
{
    8000583c:	7131                	addi	sp,sp,-192
    8000583e:	fd06                	sd	ra,184(sp)
    80005840:	f922                	sd	s0,176(sp)
    80005842:	f526                	sd	s1,168(sp)
    80005844:	f14a                	sd	s2,160(sp)
    80005846:	ed4e                	sd	s3,152(sp)
    80005848:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000584a:	08000613          	li	a2,128
    8000584e:	f5040593          	addi	a1,s0,-176
    80005852:	4501                	li	a0,0
    80005854:	ffffd097          	auipc	ra,0xffffd
    80005858:	504080e7          	jalr	1284(ra) # 80002d58 <argstr>
    return -1;
    8000585c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000585e:	0c054163          	bltz	a0,80005920 <sys_open+0xe4>
    80005862:	f4c40593          	addi	a1,s0,-180
    80005866:	4505                	li	a0,1
    80005868:	ffffd097          	auipc	ra,0xffffd
    8000586c:	4ac080e7          	jalr	1196(ra) # 80002d14 <argint>
    80005870:	0a054863          	bltz	a0,80005920 <sys_open+0xe4>

  begin_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	a2e080e7          	jalr	-1490(ra) # 800042a2 <begin_op>

  if(omode & O_CREATE){
    8000587c:	f4c42783          	lw	a5,-180(s0)
    80005880:	2007f793          	andi	a5,a5,512
    80005884:	cbdd                	beqz	a5,8000593a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005886:	4681                	li	a3,0
    80005888:	4601                	li	a2,0
    8000588a:	4589                	li	a1,2
    8000588c:	f5040513          	addi	a0,s0,-176
    80005890:	00000097          	auipc	ra,0x0
    80005894:	972080e7          	jalr	-1678(ra) # 80005202 <create>
    80005898:	892a                	mv	s2,a0
    if(ip == 0){
    8000589a:	c959                	beqz	a0,80005930 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000589c:	04491703          	lh	a4,68(s2)
    800058a0:	478d                	li	a5,3
    800058a2:	00f71763          	bne	a4,a5,800058b0 <sys_open+0x74>
    800058a6:	04695703          	lhu	a4,70(s2)
    800058aa:	47a5                	li	a5,9
    800058ac:	0ce7ec63          	bltu	a5,a4,80005984 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	e02080e7          	jalr	-510(ra) # 800046b2 <filealloc>
    800058b8:	89aa                	mv	s3,a0
    800058ba:	10050263          	beqz	a0,800059be <sys_open+0x182>
    800058be:	00000097          	auipc	ra,0x0
    800058c2:	902080e7          	jalr	-1790(ra) # 800051c0 <fdalloc>
    800058c6:	84aa                	mv	s1,a0
    800058c8:	0e054663          	bltz	a0,800059b4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058cc:	04491703          	lh	a4,68(s2)
    800058d0:	478d                	li	a5,3
    800058d2:	0cf70463          	beq	a4,a5,8000599a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058d6:	4789                	li	a5,2
    800058d8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058dc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058e0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058e4:	f4c42783          	lw	a5,-180(s0)
    800058e8:	0017c713          	xori	a4,a5,1
    800058ec:	8b05                	andi	a4,a4,1
    800058ee:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058f2:	0037f713          	andi	a4,a5,3
    800058f6:	00e03733          	snez	a4,a4
    800058fa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058fe:	4007f793          	andi	a5,a5,1024
    80005902:	c791                	beqz	a5,8000590e <sys_open+0xd2>
    80005904:	04491703          	lh	a4,68(s2)
    80005908:	4789                	li	a5,2
    8000590a:	08f70f63          	beq	a4,a5,800059a8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000590e:	854a                	mv	a0,s2
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	082080e7          	jalr	130(ra) # 80003992 <iunlock>
  end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	a0a080e7          	jalr	-1526(ra) # 80004322 <end_op>

  return fd;
}
    80005920:	8526                	mv	a0,s1
    80005922:	70ea                	ld	ra,184(sp)
    80005924:	744a                	ld	s0,176(sp)
    80005926:	74aa                	ld	s1,168(sp)
    80005928:	790a                	ld	s2,160(sp)
    8000592a:	69ea                	ld	s3,152(sp)
    8000592c:	6129                	addi	sp,sp,192
    8000592e:	8082                	ret
      end_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	9f2080e7          	jalr	-1550(ra) # 80004322 <end_op>
      return -1;
    80005938:	b7e5                	j	80005920 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000593a:	f5040513          	addi	a0,s0,-176
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	748080e7          	jalr	1864(ra) # 80004086 <namei>
    80005946:	892a                	mv	s2,a0
    80005948:	c905                	beqz	a0,80005978 <sys_open+0x13c>
    ilock(ip);
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	f86080e7          	jalr	-122(ra) # 800038d0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005952:	04491703          	lh	a4,68(s2)
    80005956:	4785                	li	a5,1
    80005958:	f4f712e3          	bne	a4,a5,8000589c <sys_open+0x60>
    8000595c:	f4c42783          	lw	a5,-180(s0)
    80005960:	dba1                	beqz	a5,800058b0 <sys_open+0x74>
      iunlockput(ip);
    80005962:	854a                	mv	a0,s2
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	1ce080e7          	jalr	462(ra) # 80003b32 <iunlockput>
      end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	9b6080e7          	jalr	-1610(ra) # 80004322 <end_op>
      return -1;
    80005974:	54fd                	li	s1,-1
    80005976:	b76d                	j	80005920 <sys_open+0xe4>
      end_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	9aa080e7          	jalr	-1622(ra) # 80004322 <end_op>
      return -1;
    80005980:	54fd                	li	s1,-1
    80005982:	bf79                	j	80005920 <sys_open+0xe4>
    iunlockput(ip);
    80005984:	854a                	mv	a0,s2
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	1ac080e7          	jalr	428(ra) # 80003b32 <iunlockput>
    end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	994080e7          	jalr	-1644(ra) # 80004322 <end_op>
    return -1;
    80005996:	54fd                	li	s1,-1
    80005998:	b761                	j	80005920 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000599a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000599e:	04691783          	lh	a5,70(s2)
    800059a2:	02f99223          	sh	a5,36(s3)
    800059a6:	bf2d                	j	800058e0 <sys_open+0xa4>
    itrunc(ip);
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	034080e7          	jalr	52(ra) # 800039de <itrunc>
    800059b2:	bfb1                	j	8000590e <sys_open+0xd2>
      fileclose(f);
    800059b4:	854e                	mv	a0,s3
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	db8080e7          	jalr	-584(ra) # 8000476e <fileclose>
    iunlockput(ip);
    800059be:	854a                	mv	a0,s2
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	172080e7          	jalr	370(ra) # 80003b32 <iunlockput>
    end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	95a080e7          	jalr	-1702(ra) # 80004322 <end_op>
    return -1;
    800059d0:	54fd                	li	s1,-1
    800059d2:	b7b9                	j	80005920 <sys_open+0xe4>

00000000800059d4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059d4:	7175                	addi	sp,sp,-144
    800059d6:	e506                	sd	ra,136(sp)
    800059d8:	e122                	sd	s0,128(sp)
    800059da:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	8c6080e7          	jalr	-1850(ra) # 800042a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059e4:	08000613          	li	a2,128
    800059e8:	f7040593          	addi	a1,s0,-144
    800059ec:	4501                	li	a0,0
    800059ee:	ffffd097          	auipc	ra,0xffffd
    800059f2:	36a080e7          	jalr	874(ra) # 80002d58 <argstr>
    800059f6:	02054963          	bltz	a0,80005a28 <sys_mkdir+0x54>
    800059fa:	4681                	li	a3,0
    800059fc:	4601                	li	a2,0
    800059fe:	4585                	li	a1,1
    80005a00:	f7040513          	addi	a0,s0,-144
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	7fe080e7          	jalr	2046(ra) # 80005202 <create>
    80005a0c:	cd11                	beqz	a0,80005a28 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	124080e7          	jalr	292(ra) # 80003b32 <iunlockput>
  end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	90c080e7          	jalr	-1780(ra) # 80004322 <end_op>
  return 0;
    80005a1e:	4501                	li	a0,0
}
    80005a20:	60aa                	ld	ra,136(sp)
    80005a22:	640a                	ld	s0,128(sp)
    80005a24:	6149                	addi	sp,sp,144
    80005a26:	8082                	ret
    end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	8fa080e7          	jalr	-1798(ra) # 80004322 <end_op>
    return -1;
    80005a30:	557d                	li	a0,-1
    80005a32:	b7fd                	j	80005a20 <sys_mkdir+0x4c>

0000000080005a34 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a34:	7135                	addi	sp,sp,-160
    80005a36:	ed06                	sd	ra,152(sp)
    80005a38:	e922                	sd	s0,144(sp)
    80005a3a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	866080e7          	jalr	-1946(ra) # 800042a2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a44:	08000613          	li	a2,128
    80005a48:	f7040593          	addi	a1,s0,-144
    80005a4c:	4501                	li	a0,0
    80005a4e:	ffffd097          	auipc	ra,0xffffd
    80005a52:	30a080e7          	jalr	778(ra) # 80002d58 <argstr>
    80005a56:	04054a63          	bltz	a0,80005aaa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a5a:	f6c40593          	addi	a1,s0,-148
    80005a5e:	4505                	li	a0,1
    80005a60:	ffffd097          	auipc	ra,0xffffd
    80005a64:	2b4080e7          	jalr	692(ra) # 80002d14 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a68:	04054163          	bltz	a0,80005aaa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a6c:	f6840593          	addi	a1,s0,-152
    80005a70:	4509                	li	a0,2
    80005a72:	ffffd097          	auipc	ra,0xffffd
    80005a76:	2a2080e7          	jalr	674(ra) # 80002d14 <argint>
     argint(1, &major) < 0 ||
    80005a7a:	02054863          	bltz	a0,80005aaa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a7e:	f6841683          	lh	a3,-152(s0)
    80005a82:	f6c41603          	lh	a2,-148(s0)
    80005a86:	458d                	li	a1,3
    80005a88:	f7040513          	addi	a0,s0,-144
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	776080e7          	jalr	1910(ra) # 80005202 <create>
     argint(2, &minor) < 0 ||
    80005a94:	c919                	beqz	a0,80005aaa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	09c080e7          	jalr	156(ra) # 80003b32 <iunlockput>
  end_op();
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	884080e7          	jalr	-1916(ra) # 80004322 <end_op>
  return 0;
    80005aa6:	4501                	li	a0,0
    80005aa8:	a031                	j	80005ab4 <sys_mknod+0x80>
    end_op();
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	878080e7          	jalr	-1928(ra) # 80004322 <end_op>
    return -1;
    80005ab2:	557d                	li	a0,-1
}
    80005ab4:	60ea                	ld	ra,152(sp)
    80005ab6:	644a                	ld	s0,144(sp)
    80005ab8:	610d                	addi	sp,sp,160
    80005aba:	8082                	ret

0000000080005abc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005abc:	7135                	addi	sp,sp,-160
    80005abe:	ed06                	sd	ra,152(sp)
    80005ac0:	e922                	sd	s0,144(sp)
    80005ac2:	e526                	sd	s1,136(sp)
    80005ac4:	e14a                	sd	s2,128(sp)
    80005ac6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ac8:	ffffc097          	auipc	ra,0xffffc
    80005acc:	f08080e7          	jalr	-248(ra) # 800019d0 <myproc>
    80005ad0:	892a                	mv	s2,a0
  
  begin_op();
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	7d0080e7          	jalr	2000(ra) # 800042a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ada:	08000613          	li	a2,128
    80005ade:	f6040593          	addi	a1,s0,-160
    80005ae2:	4501                	li	a0,0
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	274080e7          	jalr	628(ra) # 80002d58 <argstr>
    80005aec:	04054b63          	bltz	a0,80005b42 <sys_chdir+0x86>
    80005af0:	f6040513          	addi	a0,s0,-160
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	592080e7          	jalr	1426(ra) # 80004086 <namei>
    80005afc:	84aa                	mv	s1,a0
    80005afe:	c131                	beqz	a0,80005b42 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	dd0080e7          	jalr	-560(ra) # 800038d0 <ilock>
  if(ip->type != T_DIR){
    80005b08:	04449703          	lh	a4,68(s1)
    80005b0c:	4785                	li	a5,1
    80005b0e:	04f71063          	bne	a4,a5,80005b4e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b12:	8526                	mv	a0,s1
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	e7e080e7          	jalr	-386(ra) # 80003992 <iunlock>
  iput(p->cwd);
    80005b1c:	16093503          	ld	a0,352(s2)
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	f6a080e7          	jalr	-150(ra) # 80003a8a <iput>
  end_op();
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	7fa080e7          	jalr	2042(ra) # 80004322 <end_op>
  p->cwd = ip;
    80005b30:	16993023          	sd	s1,352(s2)
  return 0;
    80005b34:	4501                	li	a0,0
}
    80005b36:	60ea                	ld	ra,152(sp)
    80005b38:	644a                	ld	s0,144(sp)
    80005b3a:	64aa                	ld	s1,136(sp)
    80005b3c:	690a                	ld	s2,128(sp)
    80005b3e:	610d                	addi	sp,sp,160
    80005b40:	8082                	ret
    end_op();
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	7e0080e7          	jalr	2016(ra) # 80004322 <end_op>
    return -1;
    80005b4a:	557d                	li	a0,-1
    80005b4c:	b7ed                	j	80005b36 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b4e:	8526                	mv	a0,s1
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	fe2080e7          	jalr	-30(ra) # 80003b32 <iunlockput>
    end_op();
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	7ca080e7          	jalr	1994(ra) # 80004322 <end_op>
    return -1;
    80005b60:	557d                	li	a0,-1
    80005b62:	bfd1                	j	80005b36 <sys_chdir+0x7a>

0000000080005b64 <sys_exec>:

uint64
sys_exec(void)
{
    80005b64:	7145                	addi	sp,sp,-464
    80005b66:	e786                	sd	ra,456(sp)
    80005b68:	e3a2                	sd	s0,448(sp)
    80005b6a:	ff26                	sd	s1,440(sp)
    80005b6c:	fb4a                	sd	s2,432(sp)
    80005b6e:	f74e                	sd	s3,424(sp)
    80005b70:	f352                	sd	s4,416(sp)
    80005b72:	ef56                	sd	s5,408(sp)
    80005b74:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b76:	08000613          	li	a2,128
    80005b7a:	f4040593          	addi	a1,s0,-192
    80005b7e:	4501                	li	a0,0
    80005b80:	ffffd097          	auipc	ra,0xffffd
    80005b84:	1d8080e7          	jalr	472(ra) # 80002d58 <argstr>
    return -1;
    80005b88:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b8a:	0c054a63          	bltz	a0,80005c5e <sys_exec+0xfa>
    80005b8e:	e3840593          	addi	a1,s0,-456
    80005b92:	4505                	li	a0,1
    80005b94:	ffffd097          	auipc	ra,0xffffd
    80005b98:	1a2080e7          	jalr	418(ra) # 80002d36 <argaddr>
    80005b9c:	0c054163          	bltz	a0,80005c5e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ba0:	10000613          	li	a2,256
    80005ba4:	4581                	li	a1,0
    80005ba6:	e4040513          	addi	a0,s0,-448
    80005baa:	ffffb097          	auipc	ra,0xffffb
    80005bae:	136080e7          	jalr	310(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bb2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bb6:	89a6                	mv	s3,s1
    80005bb8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bba:	02000a13          	li	s4,32
    80005bbe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bc2:	00391513          	slli	a0,s2,0x3
    80005bc6:	e3040593          	addi	a1,s0,-464
    80005bca:	e3843783          	ld	a5,-456(s0)
    80005bce:	953e                	add	a0,a0,a5
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	0aa080e7          	jalr	170(ra) # 80002c7a <fetchaddr>
    80005bd8:	02054a63          	bltz	a0,80005c0c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bdc:	e3043783          	ld	a5,-464(s0)
    80005be0:	c3b9                	beqz	a5,80005c26 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	f12080e7          	jalr	-238(ra) # 80000af4 <kalloc>
    80005bea:	85aa                	mv	a1,a0
    80005bec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bf0:	cd11                	beqz	a0,80005c0c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bf2:	6605                	lui	a2,0x1
    80005bf4:	e3043503          	ld	a0,-464(s0)
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	0d4080e7          	jalr	212(ra) # 80002ccc <fetchstr>
    80005c00:	00054663          	bltz	a0,80005c0c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c04:	0905                	addi	s2,s2,1
    80005c06:	09a1                	addi	s3,s3,8
    80005c08:	fb491be3          	bne	s2,s4,80005bbe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0c:	10048913          	addi	s2,s1,256
    80005c10:	6088                	ld	a0,0(s1)
    80005c12:	c529                	beqz	a0,80005c5c <sys_exec+0xf8>
    kfree(argv[i]);
    80005c14:	ffffb097          	auipc	ra,0xffffb
    80005c18:	de4080e7          	jalr	-540(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1c:	04a1                	addi	s1,s1,8
    80005c1e:	ff2499e3          	bne	s1,s2,80005c10 <sys_exec+0xac>
  return -1;
    80005c22:	597d                	li	s2,-1
    80005c24:	a82d                	j	80005c5e <sys_exec+0xfa>
      argv[i] = 0;
    80005c26:	0a8e                	slli	s5,s5,0x3
    80005c28:	fc040793          	addi	a5,s0,-64
    80005c2c:	9abe                	add	s5,s5,a5
    80005c2e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c32:	e4040593          	addi	a1,s0,-448
    80005c36:	f4040513          	addi	a0,s0,-192
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	194080e7          	jalr	404(ra) # 80004dce <exec>
    80005c42:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c44:	10048993          	addi	s3,s1,256
    80005c48:	6088                	ld	a0,0(s1)
    80005c4a:	c911                	beqz	a0,80005c5e <sys_exec+0xfa>
    kfree(argv[i]);
    80005c4c:	ffffb097          	auipc	ra,0xffffb
    80005c50:	dac080e7          	jalr	-596(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c54:	04a1                	addi	s1,s1,8
    80005c56:	ff3499e3          	bne	s1,s3,80005c48 <sys_exec+0xe4>
    80005c5a:	a011                	j	80005c5e <sys_exec+0xfa>
  return -1;
    80005c5c:	597d                	li	s2,-1
}
    80005c5e:	854a                	mv	a0,s2
    80005c60:	60be                	ld	ra,456(sp)
    80005c62:	641e                	ld	s0,448(sp)
    80005c64:	74fa                	ld	s1,440(sp)
    80005c66:	795a                	ld	s2,432(sp)
    80005c68:	79ba                	ld	s3,424(sp)
    80005c6a:	7a1a                	ld	s4,416(sp)
    80005c6c:	6afa                	ld	s5,408(sp)
    80005c6e:	6179                	addi	sp,sp,464
    80005c70:	8082                	ret

0000000080005c72 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c72:	7139                	addi	sp,sp,-64
    80005c74:	fc06                	sd	ra,56(sp)
    80005c76:	f822                	sd	s0,48(sp)
    80005c78:	f426                	sd	s1,40(sp)
    80005c7a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c7c:	ffffc097          	auipc	ra,0xffffc
    80005c80:	d54080e7          	jalr	-684(ra) # 800019d0 <myproc>
    80005c84:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c86:	fd840593          	addi	a1,s0,-40
    80005c8a:	4501                	li	a0,0
    80005c8c:	ffffd097          	auipc	ra,0xffffd
    80005c90:	0aa080e7          	jalr	170(ra) # 80002d36 <argaddr>
    return -1;
    80005c94:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c96:	0e054063          	bltz	a0,80005d76 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c9a:	fc840593          	addi	a1,s0,-56
    80005c9e:	fd040513          	addi	a0,s0,-48
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	dfc080e7          	jalr	-516(ra) # 80004a9e <pipealloc>
    return -1;
    80005caa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cac:	0c054563          	bltz	a0,80005d76 <sys_pipe+0x104>
  fd0 = -1;
    80005cb0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cb4:	fd043503          	ld	a0,-48(s0)
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	508080e7          	jalr	1288(ra) # 800051c0 <fdalloc>
    80005cc0:	fca42223          	sw	a0,-60(s0)
    80005cc4:	08054c63          	bltz	a0,80005d5c <sys_pipe+0xea>
    80005cc8:	fc843503          	ld	a0,-56(s0)
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	4f4080e7          	jalr	1268(ra) # 800051c0 <fdalloc>
    80005cd4:	fca42023          	sw	a0,-64(s0)
    80005cd8:	06054863          	bltz	a0,80005d48 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cdc:	4691                	li	a3,4
    80005cde:	fc440613          	addi	a2,s0,-60
    80005ce2:	fd843583          	ld	a1,-40(s0)
    80005ce6:	70a8                	ld	a0,96(s1)
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	9aa080e7          	jalr	-1622(ra) # 80001692 <copyout>
    80005cf0:	02054063          	bltz	a0,80005d10 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cf4:	4691                	li	a3,4
    80005cf6:	fc040613          	addi	a2,s0,-64
    80005cfa:	fd843583          	ld	a1,-40(s0)
    80005cfe:	0591                	addi	a1,a1,4
    80005d00:	70a8                	ld	a0,96(s1)
    80005d02:	ffffc097          	auipc	ra,0xffffc
    80005d06:	990080e7          	jalr	-1648(ra) # 80001692 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d0a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d0c:	06055563          	bgez	a0,80005d76 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d10:	fc442783          	lw	a5,-60(s0)
    80005d14:	07f1                	addi	a5,a5,28
    80005d16:	078e                	slli	a5,a5,0x3
    80005d18:	97a6                	add	a5,a5,s1
    80005d1a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d1e:	fc042503          	lw	a0,-64(s0)
    80005d22:	0571                	addi	a0,a0,28
    80005d24:	050e                	slli	a0,a0,0x3
    80005d26:	9526                	add	a0,a0,s1
    80005d28:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d2c:	fd043503          	ld	a0,-48(s0)
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	a3e080e7          	jalr	-1474(ra) # 8000476e <fileclose>
    fileclose(wf);
    80005d38:	fc843503          	ld	a0,-56(s0)
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	a32080e7          	jalr	-1486(ra) # 8000476e <fileclose>
    return -1;
    80005d44:	57fd                	li	a5,-1
    80005d46:	a805                	j	80005d76 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d48:	fc442783          	lw	a5,-60(s0)
    80005d4c:	0007c863          	bltz	a5,80005d5c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d50:	01c78513          	addi	a0,a5,28
    80005d54:	050e                	slli	a0,a0,0x3
    80005d56:	9526                	add	a0,a0,s1
    80005d58:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d5c:	fd043503          	ld	a0,-48(s0)
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	a0e080e7          	jalr	-1522(ra) # 8000476e <fileclose>
    fileclose(wf);
    80005d68:	fc843503          	ld	a0,-56(s0)
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	a02080e7          	jalr	-1534(ra) # 8000476e <fileclose>
    return -1;
    80005d74:	57fd                	li	a5,-1
}
    80005d76:	853e                	mv	a0,a5
    80005d78:	70e2                	ld	ra,56(sp)
    80005d7a:	7442                	ld	s0,48(sp)
    80005d7c:	74a2                	ld	s1,40(sp)
    80005d7e:	6121                	addi	sp,sp,64
    80005d80:	8082                	ret
	...

0000000080005d90 <kernelvec>:
    80005d90:	7111                	addi	sp,sp,-256
    80005d92:	e006                	sd	ra,0(sp)
    80005d94:	e40a                	sd	sp,8(sp)
    80005d96:	e80e                	sd	gp,16(sp)
    80005d98:	ec12                	sd	tp,24(sp)
    80005d9a:	f016                	sd	t0,32(sp)
    80005d9c:	f41a                	sd	t1,40(sp)
    80005d9e:	f81e                	sd	t2,48(sp)
    80005da0:	fc22                	sd	s0,56(sp)
    80005da2:	e0a6                	sd	s1,64(sp)
    80005da4:	e4aa                	sd	a0,72(sp)
    80005da6:	e8ae                	sd	a1,80(sp)
    80005da8:	ecb2                	sd	a2,88(sp)
    80005daa:	f0b6                	sd	a3,96(sp)
    80005dac:	f4ba                	sd	a4,104(sp)
    80005dae:	f8be                	sd	a5,112(sp)
    80005db0:	fcc2                	sd	a6,120(sp)
    80005db2:	e146                	sd	a7,128(sp)
    80005db4:	e54a                	sd	s2,136(sp)
    80005db6:	e94e                	sd	s3,144(sp)
    80005db8:	ed52                	sd	s4,152(sp)
    80005dba:	f156                	sd	s5,160(sp)
    80005dbc:	f55a                	sd	s6,168(sp)
    80005dbe:	f95e                	sd	s7,176(sp)
    80005dc0:	fd62                	sd	s8,184(sp)
    80005dc2:	e1e6                	sd	s9,192(sp)
    80005dc4:	e5ea                	sd	s10,200(sp)
    80005dc6:	e9ee                	sd	s11,208(sp)
    80005dc8:	edf2                	sd	t3,216(sp)
    80005dca:	f1f6                	sd	t4,224(sp)
    80005dcc:	f5fa                	sd	t5,232(sp)
    80005dce:	f9fe                	sd	t6,240(sp)
    80005dd0:	d77fc0ef          	jal	ra,80002b46 <kerneltrap>
    80005dd4:	6082                	ld	ra,0(sp)
    80005dd6:	6122                	ld	sp,8(sp)
    80005dd8:	61c2                	ld	gp,16(sp)
    80005dda:	7282                	ld	t0,32(sp)
    80005ddc:	7322                	ld	t1,40(sp)
    80005dde:	73c2                	ld	t2,48(sp)
    80005de0:	7462                	ld	s0,56(sp)
    80005de2:	6486                	ld	s1,64(sp)
    80005de4:	6526                	ld	a0,72(sp)
    80005de6:	65c6                	ld	a1,80(sp)
    80005de8:	6666                	ld	a2,88(sp)
    80005dea:	7686                	ld	a3,96(sp)
    80005dec:	7726                	ld	a4,104(sp)
    80005dee:	77c6                	ld	a5,112(sp)
    80005df0:	7866                	ld	a6,120(sp)
    80005df2:	688a                	ld	a7,128(sp)
    80005df4:	692a                	ld	s2,136(sp)
    80005df6:	69ca                	ld	s3,144(sp)
    80005df8:	6a6a                	ld	s4,152(sp)
    80005dfa:	7a8a                	ld	s5,160(sp)
    80005dfc:	7b2a                	ld	s6,168(sp)
    80005dfe:	7bca                	ld	s7,176(sp)
    80005e00:	7c6a                	ld	s8,184(sp)
    80005e02:	6c8e                	ld	s9,192(sp)
    80005e04:	6d2e                	ld	s10,200(sp)
    80005e06:	6dce                	ld	s11,208(sp)
    80005e08:	6e6e                	ld	t3,216(sp)
    80005e0a:	7e8e                	ld	t4,224(sp)
    80005e0c:	7f2e                	ld	t5,232(sp)
    80005e0e:	7fce                	ld	t6,240(sp)
    80005e10:	6111                	addi	sp,sp,256
    80005e12:	10200073          	sret
    80005e16:	00000013          	nop
    80005e1a:	00000013          	nop
    80005e1e:	0001                	nop

0000000080005e20 <timervec>:
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	e10c                	sd	a1,0(a0)
    80005e26:	e510                	sd	a2,8(a0)
    80005e28:	e914                	sd	a3,16(a0)
    80005e2a:	6d0c                	ld	a1,24(a0)
    80005e2c:	7110                	ld	a2,32(a0)
    80005e2e:	6194                	ld	a3,0(a1)
    80005e30:	96b2                	add	a3,a3,a2
    80005e32:	e194                	sd	a3,0(a1)
    80005e34:	4589                	li	a1,2
    80005e36:	14459073          	csrw	sip,a1
    80005e3a:	6914                	ld	a3,16(a0)
    80005e3c:	6510                	ld	a2,8(a0)
    80005e3e:	610c                	ld	a1,0(a0)
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	30200073          	mret
	...

0000000080005e4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e4a:	1141                	addi	sp,sp,-16
    80005e4c:	e422                	sd	s0,8(sp)
    80005e4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e50:	0c0007b7          	lui	a5,0xc000
    80005e54:	4705                	li	a4,1
    80005e56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e58:	c3d8                	sw	a4,4(a5)
}
    80005e5a:	6422                	ld	s0,8(sp)
    80005e5c:	0141                	addi	sp,sp,16
    80005e5e:	8082                	ret

0000000080005e60 <plicinithart>:

void
plicinithart(void)
{
    80005e60:	1141                	addi	sp,sp,-16
    80005e62:	e406                	sd	ra,8(sp)
    80005e64:	e022                	sd	s0,0(sp)
    80005e66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	b3c080e7          	jalr	-1220(ra) # 800019a4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e70:	0085171b          	slliw	a4,a0,0x8
    80005e74:	0c0027b7          	lui	a5,0xc002
    80005e78:	97ba                	add	a5,a5,a4
    80005e7a:	40200713          	li	a4,1026
    80005e7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e82:	00d5151b          	slliw	a0,a0,0xd
    80005e86:	0c2017b7          	lui	a5,0xc201
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	00052023          	sw	zero,0(a0)
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret

0000000080005e98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e98:	1141                	addi	sp,sp,-16
    80005e9a:	e406                	sd	ra,8(sp)
    80005e9c:	e022                	sd	s0,0(sp)
    80005e9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	b04080e7          	jalr	-1276(ra) # 800019a4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ea8:	00d5179b          	slliw	a5,a0,0xd
    80005eac:	0c201537          	lui	a0,0xc201
    80005eb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005eb2:	4148                	lw	a0,4(a0)
    80005eb4:	60a2                	ld	ra,8(sp)
    80005eb6:	6402                	ld	s0,0(sp)
    80005eb8:	0141                	addi	sp,sp,16
    80005eba:	8082                	ret

0000000080005ebc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ebc:	1101                	addi	sp,sp,-32
    80005ebe:	ec06                	sd	ra,24(sp)
    80005ec0:	e822                	sd	s0,16(sp)
    80005ec2:	e426                	sd	s1,8(sp)
    80005ec4:	1000                	addi	s0,sp,32
    80005ec6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	adc080e7          	jalr	-1316(ra) # 800019a4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ed0:	00d5151b          	slliw	a0,a0,0xd
    80005ed4:	0c2017b7          	lui	a5,0xc201
    80005ed8:	97aa                	add	a5,a5,a0
    80005eda:	c3c4                	sw	s1,4(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret

0000000080005ee6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ee6:	1141                	addi	sp,sp,-16
    80005ee8:	e406                	sd	ra,8(sp)
    80005eea:	e022                	sd	s0,0(sp)
    80005eec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eee:	479d                	li	a5,7
    80005ef0:	06a7c963          	blt	a5,a0,80005f62 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ef4:	0001d797          	auipc	a5,0x1d
    80005ef8:	10c78793          	addi	a5,a5,268 # 80023000 <disk>
    80005efc:	00a78733          	add	a4,a5,a0
    80005f00:	6789                	lui	a5,0x2
    80005f02:	97ba                	add	a5,a5,a4
    80005f04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f08:	e7ad                	bnez	a5,80005f72 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f0a:	00451793          	slli	a5,a0,0x4
    80005f0e:	0001f717          	auipc	a4,0x1f
    80005f12:	0f270713          	addi	a4,a4,242 # 80025000 <disk+0x2000>
    80005f16:	6314                	ld	a3,0(a4)
    80005f18:	96be                	add	a3,a3,a5
    80005f1a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f1e:	6314                	ld	a3,0(a4)
    80005f20:	96be                	add	a3,a3,a5
    80005f22:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f26:	6314                	ld	a3,0(a4)
    80005f28:	96be                	add	a3,a3,a5
    80005f2a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f2e:	6318                	ld	a4,0(a4)
    80005f30:	97ba                	add	a5,a5,a4
    80005f32:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f36:	0001d797          	auipc	a5,0x1d
    80005f3a:	0ca78793          	addi	a5,a5,202 # 80023000 <disk>
    80005f3e:	97aa                	add	a5,a5,a0
    80005f40:	6509                	lui	a0,0x2
    80005f42:	953e                	add	a0,a0,a5
    80005f44:	4785                	li	a5,1
    80005f46:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f4a:	0001f517          	auipc	a0,0x1f
    80005f4e:	0ce50513          	addi	a0,a0,206 # 80025018 <disk+0x2018>
    80005f52:	ffffc097          	auipc	ra,0xffffc
    80005f56:	256080e7          	jalr	598(ra) # 800021a8 <wakeup>
}
    80005f5a:	60a2                	ld	ra,8(sp)
    80005f5c:	6402                	ld	s0,0(sp)
    80005f5e:	0141                	addi	sp,sp,16
    80005f60:	8082                	ret
    panic("free_desc 1");
    80005f62:	00003517          	auipc	a0,0x3
    80005f66:	8a650513          	addi	a0,a0,-1882 # 80008808 <syscalls+0x330>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	8a650513          	addi	a0,a0,-1882 # 80008818 <syscalls+0x340>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c4080e7          	jalr	1476(ra) # 8000053e <panic>

0000000080005f82 <virtio_disk_init>:
{
    80005f82:	1101                	addi	sp,sp,-32
    80005f84:	ec06                	sd	ra,24(sp)
    80005f86:	e822                	sd	s0,16(sp)
    80005f88:	e426                	sd	s1,8(sp)
    80005f8a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f8c:	00003597          	auipc	a1,0x3
    80005f90:	89c58593          	addi	a1,a1,-1892 # 80008828 <syscalls+0x350>
    80005f94:	0001f517          	auipc	a0,0x1f
    80005f98:	19450513          	addi	a0,a0,404 # 80025128 <disk+0x2128>
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	bb8080e7          	jalr	-1096(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa4:	100017b7          	lui	a5,0x10001
    80005fa8:	4398                	lw	a4,0(a5)
    80005faa:	2701                	sext.w	a4,a4
    80005fac:	747277b7          	lui	a5,0x74727
    80005fb0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fb4:	0ef71163          	bne	a4,a5,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fb8:	100017b7          	lui	a5,0x10001
    80005fbc:	43dc                	lw	a5,4(a5)
    80005fbe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc0:	4705                	li	a4,1
    80005fc2:	0ce79a63          	bne	a5,a4,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fc6:	100017b7          	lui	a5,0x10001
    80005fca:	479c                	lw	a5,8(a5)
    80005fcc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fce:	4709                	li	a4,2
    80005fd0:	0ce79363          	bne	a5,a4,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fd4:	100017b7          	lui	a5,0x10001
    80005fd8:	47d8                	lw	a4,12(a5)
    80005fda:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fdc:	554d47b7          	lui	a5,0x554d4
    80005fe0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fe4:	0af71963          	bne	a4,a5,80006096 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe8:	100017b7          	lui	a5,0x10001
    80005fec:	4705                	li	a4,1
    80005fee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff0:	470d                	li	a4,3
    80005ff2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ff4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ff6:	c7ffe737          	lui	a4,0xc7ffe
    80005ffa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ffe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006000:	2701                	sext.w	a4,a4
    80006002:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006004:	472d                	li	a4,11
    80006006:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006008:	473d                	li	a4,15
    8000600a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000600c:	6705                	lui	a4,0x1
    8000600e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006010:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006014:	5bdc                	lw	a5,52(a5)
    80006016:	2781                	sext.w	a5,a5
  if(max == 0)
    80006018:	c7d9                	beqz	a5,800060a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000601a:	471d                	li	a4,7
    8000601c:	08f77d63          	bgeu	a4,a5,800060b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006020:	100014b7          	lui	s1,0x10001
    80006024:	47a1                	li	a5,8
    80006026:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006028:	6609                	lui	a2,0x2
    8000602a:	4581                	li	a1,0
    8000602c:	0001d517          	auipc	a0,0x1d
    80006030:	fd450513          	addi	a0,a0,-44 # 80023000 <disk>
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	cac080e7          	jalr	-852(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000603c:	0001d717          	auipc	a4,0x1d
    80006040:	fc470713          	addi	a4,a4,-60 # 80023000 <disk>
    80006044:	00c75793          	srli	a5,a4,0xc
    80006048:	2781                	sext.w	a5,a5
    8000604a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000604c:	0001f797          	auipc	a5,0x1f
    80006050:	fb478793          	addi	a5,a5,-76 # 80025000 <disk+0x2000>
    80006054:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006056:	0001d717          	auipc	a4,0x1d
    8000605a:	02a70713          	addi	a4,a4,42 # 80023080 <disk+0x80>
    8000605e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006060:	0001e717          	auipc	a4,0x1e
    80006064:	fa070713          	addi	a4,a4,-96 # 80024000 <disk+0x1000>
    80006068:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000606a:	4705                	li	a4,1
    8000606c:	00e78c23          	sb	a4,24(a5)
    80006070:	00e78ca3          	sb	a4,25(a5)
    80006074:	00e78d23          	sb	a4,26(a5)
    80006078:	00e78da3          	sb	a4,27(a5)
    8000607c:	00e78e23          	sb	a4,28(a5)
    80006080:	00e78ea3          	sb	a4,29(a5)
    80006084:	00e78f23          	sb	a4,30(a5)
    80006088:	00e78fa3          	sb	a4,31(a5)
}
    8000608c:	60e2                	ld	ra,24(sp)
    8000608e:	6442                	ld	s0,16(sp)
    80006090:	64a2                	ld	s1,8(sp)
    80006092:	6105                	addi	sp,sp,32
    80006094:	8082                	ret
    panic("could not find virtio disk");
    80006096:	00002517          	auipc	a0,0x2
    8000609a:	7a250513          	addi	a0,a0,1954 # 80008838 <syscalls+0x360>
    8000609e:	ffffa097          	auipc	ra,0xffffa
    800060a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800060a6:	00002517          	auipc	a0,0x2
    800060aa:	7b250513          	addi	a0,a0,1970 # 80008858 <syscalls+0x380>
    800060ae:	ffffa097          	auipc	ra,0xffffa
    800060b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800060b6:	00002517          	auipc	a0,0x2
    800060ba:	7c250513          	addi	a0,a0,1986 # 80008878 <syscalls+0x3a0>
    800060be:	ffffa097          	auipc	ra,0xffffa
    800060c2:	480080e7          	jalr	1152(ra) # 8000053e <panic>

00000000800060c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060c6:	7159                	addi	sp,sp,-112
    800060c8:	f486                	sd	ra,104(sp)
    800060ca:	f0a2                	sd	s0,96(sp)
    800060cc:	eca6                	sd	s1,88(sp)
    800060ce:	e8ca                	sd	s2,80(sp)
    800060d0:	e4ce                	sd	s3,72(sp)
    800060d2:	e0d2                	sd	s4,64(sp)
    800060d4:	fc56                	sd	s5,56(sp)
    800060d6:	f85a                	sd	s6,48(sp)
    800060d8:	f45e                	sd	s7,40(sp)
    800060da:	f062                	sd	s8,32(sp)
    800060dc:	ec66                	sd	s9,24(sp)
    800060de:	e86a                	sd	s10,16(sp)
    800060e0:	1880                	addi	s0,sp,112
    800060e2:	892a                	mv	s2,a0
    800060e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060e6:	00c52c83          	lw	s9,12(a0)
    800060ea:	001c9c9b          	slliw	s9,s9,0x1
    800060ee:	1c82                	slli	s9,s9,0x20
    800060f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060f4:	0001f517          	auipc	a0,0x1f
    800060f8:	03450513          	addi	a0,a0,52 # 80025128 <disk+0x2128>
    800060fc:	ffffb097          	auipc	ra,0xffffb
    80006100:	ae8080e7          	jalr	-1304(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006104:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006106:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006108:	0001db97          	auipc	s7,0x1d
    8000610c:	ef8b8b93          	addi	s7,s7,-264 # 80023000 <disk>
    80006110:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006112:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006114:	8a4e                	mv	s4,s3
    80006116:	a051                	j	8000619a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006118:	00fb86b3          	add	a3,s7,a5
    8000611c:	96da                	add	a3,a3,s6
    8000611e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006122:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006124:	0207c563          	bltz	a5,8000614e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006128:	2485                	addiw	s1,s1,1
    8000612a:	0711                	addi	a4,a4,4
    8000612c:	25548063          	beq	s1,s5,8000636c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006130:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006132:	0001f697          	auipc	a3,0x1f
    80006136:	ee668693          	addi	a3,a3,-282 # 80025018 <disk+0x2018>
    8000613a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000613c:	0006c583          	lbu	a1,0(a3)
    80006140:	fde1                	bnez	a1,80006118 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006142:	2785                	addiw	a5,a5,1
    80006144:	0685                	addi	a3,a3,1
    80006146:	ff879be3          	bne	a5,s8,8000613c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000614a:	57fd                	li	a5,-1
    8000614c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000614e:	02905a63          	blez	s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006152:	f9042503          	lw	a0,-112(s0)
    80006156:	00000097          	auipc	ra,0x0
    8000615a:	d90080e7          	jalr	-624(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    8000615e:	4785                	li	a5,1
    80006160:	0297d163          	bge	a5,s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006164:	f9442503          	lw	a0,-108(s0)
    80006168:	00000097          	auipc	ra,0x0
    8000616c:	d7e080e7          	jalr	-642(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    80006170:	4789                	li	a5,2
    80006172:	0097d863          	bge	a5,s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006176:	f9842503          	lw	a0,-104(s0)
    8000617a:	00000097          	auipc	ra,0x0
    8000617e:	d6c080e7          	jalr	-660(ra) # 80005ee6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006182:	0001f597          	auipc	a1,0x1f
    80006186:	fa658593          	addi	a1,a1,-90 # 80025128 <disk+0x2128>
    8000618a:	0001f517          	auipc	a0,0x1f
    8000618e:	e8e50513          	addi	a0,a0,-370 # 80025018 <disk+0x2018>
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	e8a080e7          	jalr	-374(ra) # 8000201c <sleep>
  for(int i = 0; i < 3; i++){
    8000619a:	f9040713          	addi	a4,s0,-112
    8000619e:	84ce                	mv	s1,s3
    800061a0:	bf41                	j	80006130 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061a2:	20058713          	addi	a4,a1,512
    800061a6:	00471693          	slli	a3,a4,0x4
    800061aa:	0001d717          	auipc	a4,0x1d
    800061ae:	e5670713          	addi	a4,a4,-426 # 80023000 <disk>
    800061b2:	9736                	add	a4,a4,a3
    800061b4:	4685                	li	a3,1
    800061b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061ba:	20058713          	addi	a4,a1,512
    800061be:	00471693          	slli	a3,a4,0x4
    800061c2:	0001d717          	auipc	a4,0x1d
    800061c6:	e3e70713          	addi	a4,a4,-450 # 80023000 <disk>
    800061ca:	9736                	add	a4,a4,a3
    800061cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061d4:	7679                	lui	a2,0xffffe
    800061d6:	963e                	add	a2,a2,a5
    800061d8:	0001f697          	auipc	a3,0x1f
    800061dc:	e2868693          	addi	a3,a3,-472 # 80025000 <disk+0x2000>
    800061e0:	6298                	ld	a4,0(a3)
    800061e2:	9732                	add	a4,a4,a2
    800061e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061e6:	6298                	ld	a4,0(a3)
    800061e8:	9732                	add	a4,a4,a2
    800061ea:	4541                	li	a0,16
    800061ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061ee:	6298                	ld	a4,0(a3)
    800061f0:	9732                	add	a4,a4,a2
    800061f2:	4505                	li	a0,1
    800061f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061f8:	f9442703          	lw	a4,-108(s0)
    800061fc:	6288                	ld	a0,0(a3)
    800061fe:	962a                	add	a2,a2,a0
    80006200:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006204:	0712                	slli	a4,a4,0x4
    80006206:	6290                	ld	a2,0(a3)
    80006208:	963a                	add	a2,a2,a4
    8000620a:	05890513          	addi	a0,s2,88
    8000620e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006210:	6294                	ld	a3,0(a3)
    80006212:	96ba                	add	a3,a3,a4
    80006214:	40000613          	li	a2,1024
    80006218:	c690                	sw	a2,8(a3)
  if(write)
    8000621a:	140d0063          	beqz	s10,8000635a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000621e:	0001f697          	auipc	a3,0x1f
    80006222:	de26b683          	ld	a3,-542(a3) # 80025000 <disk+0x2000>
    80006226:	96ba                	add	a3,a3,a4
    80006228:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000622c:	0001d817          	auipc	a6,0x1d
    80006230:	dd480813          	addi	a6,a6,-556 # 80023000 <disk>
    80006234:	0001f517          	auipc	a0,0x1f
    80006238:	dcc50513          	addi	a0,a0,-564 # 80025000 <disk+0x2000>
    8000623c:	6114                	ld	a3,0(a0)
    8000623e:	96ba                	add	a3,a3,a4
    80006240:	00c6d603          	lhu	a2,12(a3)
    80006244:	00166613          	ori	a2,a2,1
    80006248:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000624c:	f9842683          	lw	a3,-104(s0)
    80006250:	6110                	ld	a2,0(a0)
    80006252:	9732                	add	a4,a4,a2
    80006254:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006258:	20058613          	addi	a2,a1,512
    8000625c:	0612                	slli	a2,a2,0x4
    8000625e:	9642                	add	a2,a2,a6
    80006260:	577d                	li	a4,-1
    80006262:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006266:	00469713          	slli	a4,a3,0x4
    8000626a:	6114                	ld	a3,0(a0)
    8000626c:	96ba                	add	a3,a3,a4
    8000626e:	03078793          	addi	a5,a5,48
    80006272:	97c2                	add	a5,a5,a6
    80006274:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006276:	611c                	ld	a5,0(a0)
    80006278:	97ba                	add	a5,a5,a4
    8000627a:	4685                	li	a3,1
    8000627c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000627e:	611c                	ld	a5,0(a0)
    80006280:	97ba                	add	a5,a5,a4
    80006282:	4809                	li	a6,2
    80006284:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006288:	611c                	ld	a5,0(a0)
    8000628a:	973e                	add	a4,a4,a5
    8000628c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006290:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006294:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006298:	6518                	ld	a4,8(a0)
    8000629a:	00275783          	lhu	a5,2(a4)
    8000629e:	8b9d                	andi	a5,a5,7
    800062a0:	0786                	slli	a5,a5,0x1
    800062a2:	97ba                	add	a5,a5,a4
    800062a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062ac:	6518                	ld	a4,8(a0)
    800062ae:	00275783          	lhu	a5,2(a4)
    800062b2:	2785                	addiw	a5,a5,1
    800062b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062bc:	100017b7          	lui	a5,0x10001
    800062c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062c4:	00492703          	lw	a4,4(s2)
    800062c8:	4785                	li	a5,1
    800062ca:	02f71163          	bne	a4,a5,800062ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062ce:	0001f997          	auipc	s3,0x1f
    800062d2:	e5a98993          	addi	s3,s3,-422 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800062d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062d8:	85ce                	mv	a1,s3
    800062da:	854a                	mv	a0,s2
    800062dc:	ffffc097          	auipc	ra,0xffffc
    800062e0:	d40080e7          	jalr	-704(ra) # 8000201c <sleep>
  while(b->disk == 1) {
    800062e4:	00492783          	lw	a5,4(s2)
    800062e8:	fe9788e3          	beq	a5,s1,800062d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062ec:	f9042903          	lw	s2,-112(s0)
    800062f0:	20090793          	addi	a5,s2,512
    800062f4:	00479713          	slli	a4,a5,0x4
    800062f8:	0001d797          	auipc	a5,0x1d
    800062fc:	d0878793          	addi	a5,a5,-760 # 80023000 <disk>
    80006300:	97ba                	add	a5,a5,a4
    80006302:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006306:	0001f997          	auipc	s3,0x1f
    8000630a:	cfa98993          	addi	s3,s3,-774 # 80025000 <disk+0x2000>
    8000630e:	00491713          	slli	a4,s2,0x4
    80006312:	0009b783          	ld	a5,0(s3)
    80006316:	97ba                	add	a5,a5,a4
    80006318:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000631c:	854a                	mv	a0,s2
    8000631e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006322:	00000097          	auipc	ra,0x0
    80006326:	bc4080e7          	jalr	-1084(ra) # 80005ee6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000632a:	8885                	andi	s1,s1,1
    8000632c:	f0ed                	bnez	s1,8000630e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000632e:	0001f517          	auipc	a0,0x1f
    80006332:	dfa50513          	addi	a0,a0,-518 # 80025128 <disk+0x2128>
    80006336:	ffffb097          	auipc	ra,0xffffb
    8000633a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
}
    8000633e:	70a6                	ld	ra,104(sp)
    80006340:	7406                	ld	s0,96(sp)
    80006342:	64e6                	ld	s1,88(sp)
    80006344:	6946                	ld	s2,80(sp)
    80006346:	69a6                	ld	s3,72(sp)
    80006348:	6a06                	ld	s4,64(sp)
    8000634a:	7ae2                	ld	s5,56(sp)
    8000634c:	7b42                	ld	s6,48(sp)
    8000634e:	7ba2                	ld	s7,40(sp)
    80006350:	7c02                	ld	s8,32(sp)
    80006352:	6ce2                	ld	s9,24(sp)
    80006354:	6d42                	ld	s10,16(sp)
    80006356:	6165                	addi	sp,sp,112
    80006358:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000635a:	0001f697          	auipc	a3,0x1f
    8000635e:	ca66b683          	ld	a3,-858(a3) # 80025000 <disk+0x2000>
    80006362:	96ba                	add	a3,a3,a4
    80006364:	4609                	li	a2,2
    80006366:	00c69623          	sh	a2,12(a3)
    8000636a:	b5c9                	j	8000622c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000636c:	f9042583          	lw	a1,-112(s0)
    80006370:	20058793          	addi	a5,a1,512
    80006374:	0792                	slli	a5,a5,0x4
    80006376:	0001d517          	auipc	a0,0x1d
    8000637a:	d3250513          	addi	a0,a0,-718 # 800230a8 <disk+0xa8>
    8000637e:	953e                	add	a0,a0,a5
  if(write)
    80006380:	e20d11e3          	bnez	s10,800061a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006384:	20058713          	addi	a4,a1,512
    80006388:	00471693          	slli	a3,a4,0x4
    8000638c:	0001d717          	auipc	a4,0x1d
    80006390:	c7470713          	addi	a4,a4,-908 # 80023000 <disk>
    80006394:	9736                	add	a4,a4,a3
    80006396:	0a072423          	sw	zero,168(a4)
    8000639a:	b505                	j	800061ba <virtio_disk_rw+0xf4>

000000008000639c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000639c:	1101                	addi	sp,sp,-32
    8000639e:	ec06                	sd	ra,24(sp)
    800063a0:	e822                	sd	s0,16(sp)
    800063a2:	e426                	sd	s1,8(sp)
    800063a4:	e04a                	sd	s2,0(sp)
    800063a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063a8:	0001f517          	auipc	a0,0x1f
    800063ac:	d8050513          	addi	a0,a0,-640 # 80025128 <disk+0x2128>
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	834080e7          	jalr	-1996(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063b8:	10001737          	lui	a4,0x10001
    800063bc:	533c                	lw	a5,96(a4)
    800063be:	8b8d                	andi	a5,a5,3
    800063c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063c6:	0001f797          	auipc	a5,0x1f
    800063ca:	c3a78793          	addi	a5,a5,-966 # 80025000 <disk+0x2000>
    800063ce:	6b94                	ld	a3,16(a5)
    800063d0:	0207d703          	lhu	a4,32(a5)
    800063d4:	0026d783          	lhu	a5,2(a3)
    800063d8:	06f70163          	beq	a4,a5,8000643a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063dc:	0001d917          	auipc	s2,0x1d
    800063e0:	c2490913          	addi	s2,s2,-988 # 80023000 <disk>
    800063e4:	0001f497          	auipc	s1,0x1f
    800063e8:	c1c48493          	addi	s1,s1,-996 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063f0:	6898                	ld	a4,16(s1)
    800063f2:	0204d783          	lhu	a5,32(s1)
    800063f6:	8b9d                	andi	a5,a5,7
    800063f8:	078e                	slli	a5,a5,0x3
    800063fa:	97ba                	add	a5,a5,a4
    800063fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063fe:	20078713          	addi	a4,a5,512
    80006402:	0712                	slli	a4,a4,0x4
    80006404:	974a                	add	a4,a4,s2
    80006406:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000640a:	e731                	bnez	a4,80006456 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000640c:	20078793          	addi	a5,a5,512
    80006410:	0792                	slli	a5,a5,0x4
    80006412:	97ca                	add	a5,a5,s2
    80006414:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006416:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000641a:	ffffc097          	auipc	ra,0xffffc
    8000641e:	d8e080e7          	jalr	-626(ra) # 800021a8 <wakeup>

    disk.used_idx += 1;
    80006422:	0204d783          	lhu	a5,32(s1)
    80006426:	2785                	addiw	a5,a5,1
    80006428:	17c2                	slli	a5,a5,0x30
    8000642a:	93c1                	srli	a5,a5,0x30
    8000642c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006430:	6898                	ld	a4,16(s1)
    80006432:	00275703          	lhu	a4,2(a4)
    80006436:	faf71be3          	bne	a4,a5,800063ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000643a:	0001f517          	auipc	a0,0x1f
    8000643e:	cee50513          	addi	a0,a0,-786 # 80025128 <disk+0x2128>
    80006442:	ffffb097          	auipc	ra,0xffffb
    80006446:	856080e7          	jalr	-1962(ra) # 80000c98 <release>
}
    8000644a:	60e2                	ld	ra,24(sp)
    8000644c:	6442                	ld	s0,16(sp)
    8000644e:	64a2                	ld	s1,8(sp)
    80006450:	6902                	ld	s2,0(sp)
    80006452:	6105                	addi	sp,sp,32
    80006454:	8082                	ret
      panic("virtio_disk_intr status");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	44250513          	addi	a0,a0,1090 # 80008898 <syscalls+0x3c0>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>
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
