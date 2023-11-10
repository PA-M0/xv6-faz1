
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b0010113          	addi	sp,sp,-1280 # 80008b00 <stack0>
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
    80000056:	96e70713          	addi	a4,a4,-1682 # 800089c0 <timer_scratch>
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
    80000068:	e9c78793          	addi	a5,a5,-356 # 80005f00 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb9c7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	ed878793          	addi	a5,a5,-296 # 80000f86 <main>
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
    80000130:	494080e7          	jalr	1172(ra) # 800025c0 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00001097          	auipc	ra,0x1
    80000140:	88e080e7          	jalr	-1906(ra) # 800009ca <uartputc>
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
    8000018e:	97650513          	addi	a0,a0,-1674 # 80010b00 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b52080e7          	jalr	-1198(ra) # 80000ce4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	96648493          	addi	s1,s1,-1690 # 80010b00 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9f690913          	addi	s2,s2,-1546 # 80010b98 <cons+0x98>
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
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	8fa080e7          	jalr	-1798(ra) # 80001aba <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	242080e7          	jalr	578(ra) # 8000240a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f8c080e7          	jalr	-116(ra) # 80002162 <sleep>
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
    80000216:	358080e7          	jalr	856(ra) # 8000256a <either_copyout>
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
    8000022a:	8da50513          	addi	a0,a0,-1830 # 80010b00 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b6a080e7          	jalr	-1174(ra) # 80000d98 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	8c450513          	addi	a0,a0,-1852 # 80010b00 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b54080e7          	jalr	-1196(ra) # 80000d98 <release>
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
    80000276:	92f72323          	sw	a5,-1754(a4) # 80010b98 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <printToConsole>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e422                	sd	s0,8(sp)
    80000280:	0800                	addi	s0,sp,16
}
    80000282:	6422                	ld	s0,8(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret

0000000080000288 <call_sys_history>:
void call_sys_history(void){
    80000288:	1141                	addi	sp,sp,-16
    8000028a:	e422                	sd	s0,8(sp)
    8000028c:	0800                	addi	s0,sp,16
    for (int i = 0; historyBuf.current_cm[i] != '\n' ; ++i) {
    8000028e:	00011717          	auipc	a4,0x11
    80000292:	16674703          	lbu	a4,358(a4) # 800113f4 <historyBuf+0x84c>
    80000296:	47a9                	li	a5,10
    80000298:	06f70f63          	beq	a4,a5,80000316 <call_sys_history+0x8e>
    8000029c:	00011717          	auipc	a4,0x11
    800002a0:	15970713          	addi	a4,a4,345 # 800113f5 <historyBuf+0x84d>
    int size = 0;
    800002a4:	4781                	li	a5,0
    for (int i = 0; historyBuf.current_cm[i] != '\n' ; ++i) {
    800002a6:	45a9                	li	a1,10
        size++;
    800002a8:	86be                	mv	a3,a5
    800002aa:	2785                	addiw	a5,a5,1
    for (int i = 0; historyBuf.current_cm[i] != '\n' ; ++i) {
    800002ac:	0705                	addi	a4,a4,1
    800002ae:	fff74603          	lbu	a2,-1(a4)
    800002b2:	feb61be3          	bne	a2,a1,800002a8 <call_sys_history+0x20>
    historyBuf.lengthsArr[row] = size;
    800002b6:	00008817          	auipc	a6,0x8
    800002ba:	6ca82803          	lw	a6,1738(a6) # 80008980 <row>
    800002be:	20080713          	addi	a4,a6,512
    800002c2:	00271613          	slli	a2,a4,0x2
    800002c6:	00011717          	auipc	a4,0x11
    800002ca:	8e270713          	addi	a4,a4,-1822 # 80010ba8 <historyBuf>
    800002ce:	9732                	add	a4,a4,a2
    800002d0:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < size ; i++) {
    800002d2:	02f05a63          	blez	a5,80000306 <call_sys_history+0x7e>
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	11e50513          	addi	a0,a0,286 # 800113f4 <historyBuf+0x84c>
    800002de:	00781593          	slli	a1,a6,0x7
    800002e2:	87aa                	mv	a5,a0
        historyBuf.bufferArr[row][i]= historyBuf.current_cm[i];
    800002e4:	777d                	lui	a4,0xfffff
    800002e6:	7b470713          	addi	a4,a4,1972 # fffffffffffff7b4 <end+0xffffffff7ffdc97c>
    800002ea:	95ba                	add	a1,a1,a4
    for (int i = 0; i < size ; i++) {
    800002ec:	fff54513          	not	a0,a0
        historyBuf.bufferArr[row][i]= historyBuf.current_cm[i];
    800002f0:	0007c603          	lbu	a2,0(a5) # 10000 <_entry-0x7fff0000>
    800002f4:	00b78733          	add	a4,a5,a1
    800002f8:	00c70023          	sb	a2,0(a4)
    for (int i = 0; i < size ; i++) {
    800002fc:	0785                	addi	a5,a5,1
    800002fe:	00f5073b          	addw	a4,a0,a5
    80000302:	fed747e3          	blt	a4,a3,800002f0 <call_sys_history+0x68>
    row++;
    80000306:	2805                	addiw	a6,a6,1
    80000308:	00008797          	auipc	a5,0x8
    8000030c:	6707ac23          	sw	a6,1656(a5) # 80008980 <row>
}
    80000310:	6422                	ld	s0,8(sp)
    80000312:	0141                	addi	sp,sp,16
    80000314:	8082                	ret
    historyBuf.lengthsArr[row] = size;
    80000316:	00008817          	auipc	a6,0x8
    8000031a:	66a82803          	lw	a6,1642(a6) # 80008980 <row>
    8000031e:	20080793          	addi	a5,a6,512
    80000322:	00279713          	slli	a4,a5,0x2
    80000326:	00011797          	auipc	a5,0x11
    8000032a:	88278793          	addi	a5,a5,-1918 # 80010ba8 <historyBuf>
    8000032e:	97ba                	add	a5,a5,a4
    80000330:	0007a023          	sw	zero,0(a5)
    for (int i = 0; i < size ; i++) {
    80000334:	bfc9                	j	80000306 <call_sys_history+0x7e>

0000000080000336 <consputc>:
{
    80000336:	1141                	addi	sp,sp,-16
    80000338:	e406                	sd	ra,8(sp)
    8000033a:	e022                	sd	s0,0(sp)
    8000033c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000033e:	10000793          	li	a5,256
    80000342:	00f50a63          	beq	a0,a5,80000356 <consputc+0x20>
    uartputc_sync(c);
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	5b2080e7          	jalr	1458(ra) # 800008f8 <uartputc_sync>
}
    8000034e:	60a2                	ld	ra,8(sp)
    80000350:	6402                	ld	s0,0(sp)
    80000352:	0141                	addi	sp,sp,16
    80000354:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000356:	4521                	li	a0,8
    80000358:	00000097          	auipc	ra,0x0
    8000035c:	5a0080e7          	jalr	1440(ra) # 800008f8 <uartputc_sync>
    80000360:	02000513          	li	a0,32
    80000364:	00000097          	auipc	ra,0x0
    80000368:	594080e7          	jalr	1428(ra) # 800008f8 <uartputc_sync>
    8000036c:	4521                	li	a0,8
    8000036e:	00000097          	auipc	ra,0x0
    80000372:	58a080e7          	jalr	1418(ra) # 800008f8 <uartputc_sync>
    80000376:	bfe1                	j	8000034e <consputc+0x18>

0000000080000378 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    80000378:	1101                	addi	sp,sp,-32
    8000037a:	ec06                	sd	ra,24(sp)
    8000037c:	e822                	sd	s0,16(sp)
    8000037e:	e426                	sd	s1,8(sp)
    80000380:	e04a                	sd	s2,0(sp)
    80000382:	1000                	addi	s0,sp,32
    80000384:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    80000386:	00010517          	auipc	a0,0x10
    8000038a:	77a50513          	addi	a0,a0,1914 # 80010b00 <cons>
    8000038e:	00001097          	auipc	ra,0x1
    80000392:	956080e7          	jalr	-1706(ra) # 80000ce4 <acquire>



  switch(c){
    80000396:	47d5                	li	a5,21
    80000398:	0cf48063          	beq	s1,a5,80000458 <consoleintr+0xe0>
    8000039c:	0297ca63          	blt	a5,s1,800003d0 <consoleintr+0x58>
    800003a0:	47a1                	li	a5,8
    800003a2:	10f48163          	beq	s1,a5,800004a4 <consoleintr+0x12c>
    800003a6:	47c1                	li	a5,16
    800003a8:	12f49b63          	bne	s1,a5,800004de <consoleintr+0x166>
  case C('P'):  // Print process list.
    procdump();
    800003ac:	00002097          	auipc	ra,0x2
    800003b0:	26a080e7          	jalr	618(ra) # 80002616 <procdump>




  
  release(&cons.lock);
    800003b4:	00010517          	auipc	a0,0x10
    800003b8:	74c50513          	addi	a0,a0,1868 # 80010b00 <cons>
    800003bc:	00001097          	auipc	ra,0x1
    800003c0:	9dc080e7          	jalr	-1572(ra) # 80000d98 <release>
  //  printf(cons.w);
}
    800003c4:	60e2                	ld	ra,24(sp)
    800003c6:	6442                	ld	s0,16(sp)
    800003c8:	64a2                	ld	s1,8(sp)
    800003ca:	6902                	ld	s2,0(sp)
    800003cc:	6105                	addi	sp,sp,32
    800003ce:	8082                	ret
  switch(c){
    800003d0:	07f00793          	li	a5,127
    800003d4:	0cf48863          	beq	s1,a5,800004a4 <consoleintr+0x12c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003d8:	00010717          	auipc	a4,0x10
    800003dc:	72870713          	addi	a4,a4,1832 # 80010b00 <cons>
    800003e0:	0a072783          	lw	a5,160(a4)
    800003e4:	09872703          	lw	a4,152(a4)
    800003e8:	40e7863b          	subw	a2,a5,a4
    800003ec:	07f00693          	li	a3,127
    800003f0:	fcc6e2e3          	bltu	a3,a2,800003b4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    800003f4:	46b5                	li	a3,13
    800003f6:	0ed48763          	beq	s1,a3,800004e4 <consoleintr+0x16c>
      historyBuf.current_cm[index] = c;
    800003fa:	00008817          	auipc	a6,0x8
    800003fe:	58a80813          	addi	a6,a6,1418 # 80008984 <index>
    80000402:	00082683          	lw	a3,0(a6)
    80000406:	0ff4f613          	andi	a2,s1,255
    8000040a:	00010597          	auipc	a1,0x10
    8000040e:	79e58593          	addi	a1,a1,1950 # 80010ba8 <historyBuf>
    80000412:	00d58533          	add	a0,a1,a3
    80000416:	6585                	lui	a1,0x1
    80000418:	95aa                	add	a1,a1,a0
    8000041a:	84c58623          	sb	a2,-1972(a1) # 84c <_entry-0x7ffff7b4>
      index++;
    8000041e:	2685                	addiw	a3,a3,1
    80000420:	00d82023          	sw	a3,0(a6)
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000424:	0017859b          	addiw	a1,a5,1
    80000428:	00010697          	auipc	a3,0x10
    8000042c:	6d868693          	addi	a3,a3,1752 # 80010b00 <cons>
    80000430:	0ab6a023          	sw	a1,160(a3)
    80000434:	07f7f793          	andi	a5,a5,127
    80000438:	97b6                	add	a5,a5,a3
    8000043a:	00c78c23          	sb	a2,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000043e:	47a9                	li	a5,10
    80000440:	0cf48d63          	beq	s1,a5,8000051a <consoleintr+0x1a2>
    80000444:	4791                	li	a5,4
    80000446:	0cf48a63          	beq	s1,a5,8000051a <consoleintr+0x1a2>
    8000044a:	40e5873b          	subw	a4,a1,a4
    8000044e:	08000793          	li	a5,128
    80000452:	f6f711e3          	bne	a4,a5,800003b4 <consoleintr+0x3c>
    80000456:	a0d1                	j	8000051a <consoleintr+0x1a2>
    while(cons.e != cons.w &&
    80000458:	00010717          	auipc	a4,0x10
    8000045c:	6a870713          	addi	a4,a4,1704 # 80010b00 <cons>
    80000460:	0a072783          	lw	a5,160(a4)
    80000464:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000468:	00010497          	auipc	s1,0x10
    8000046c:	69848493          	addi	s1,s1,1688 # 80010b00 <cons>
    while(cons.e != cons.w &&
    80000470:	4929                	li	s2,10
    80000472:	f4f701e3          	beq	a4,a5,800003b4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000476:	37fd                	addiw	a5,a5,-1
    80000478:	07f7f713          	andi	a4,a5,127
    8000047c:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000047e:	01874703          	lbu	a4,24(a4)
    80000482:	f32709e3          	beq	a4,s2,800003b4 <consoleintr+0x3c>
      cons.e--;
    80000486:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    8000048a:	10000513          	li	a0,256
    8000048e:	00000097          	auipc	ra,0x0
    80000492:	ea8080e7          	jalr	-344(ra) # 80000336 <consputc>
    while(cons.e != cons.w &&
    80000496:	0a04a783          	lw	a5,160(s1)
    8000049a:	09c4a703          	lw	a4,156(s1)
    8000049e:	fcf71ce3          	bne	a4,a5,80000476 <consoleintr+0xfe>
    800004a2:	bf09                	j	800003b4 <consoleintr+0x3c>
    index--;
    800004a4:	00008717          	auipc	a4,0x8
    800004a8:	4e070713          	addi	a4,a4,1248 # 80008984 <index>
    800004ac:	431c                	lw	a5,0(a4)
    800004ae:	37fd                	addiw	a5,a5,-1
    800004b0:	c31c                	sw	a5,0(a4)
    if(cons.e != cons.w){
    800004b2:	00010717          	auipc	a4,0x10
    800004b6:	64e70713          	addi	a4,a4,1614 # 80010b00 <cons>
    800004ba:	0a072783          	lw	a5,160(a4)
    800004be:	09c72703          	lw	a4,156(a4)
    800004c2:	eef709e3          	beq	a4,a5,800003b4 <consoleintr+0x3c>
      cons.e--;
    800004c6:	37fd                	addiw	a5,a5,-1
    800004c8:	00010717          	auipc	a4,0x10
    800004cc:	6cf72c23          	sw	a5,1752(a4) # 80010ba0 <cons+0xa0>
      consputc(BACKSPACE);
    800004d0:	10000513          	li	a0,256
    800004d4:	00000097          	auipc	ra,0x0
    800004d8:	e62080e7          	jalr	-414(ra) # 80000336 <consputc>
    800004dc:	bde1                	j	800003b4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800004de:	ec048be3          	beqz	s1,800003b4 <consoleintr+0x3c>
    800004e2:	bddd                	j	800003d8 <consoleintr+0x60>
      historyBuf.current_cm[index] = c;
    800004e4:	00008697          	auipc	a3,0x8
    800004e8:	4a06a683          	lw	a3,1184(a3) # 80008984 <index>
    800004ec:	00010717          	auipc	a4,0x10
    800004f0:	6bc70713          	addi	a4,a4,1724 # 80010ba8 <historyBuf>
    800004f4:	96ba                	add	a3,a3,a4
    800004f6:	6705                	lui	a4,0x1
    800004f8:	9736                	add	a4,a4,a3
    800004fa:	46a9                	li	a3,10
    800004fc:	84d70623          	sb	a3,-1972(a4) # 84c <_entry-0x7ffff7b4>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000500:	00010717          	auipc	a4,0x10
    80000504:	60070713          	addi	a4,a4,1536 # 80010b00 <cons>
    80000508:	0017861b          	addiw	a2,a5,1
    8000050c:	0ac72023          	sw	a2,160(a4)
    80000510:	07f7f793          	andi	a5,a5,127
    80000514:	97ba                	add	a5,a5,a4
    80000516:	00d78c23          	sb	a3,24(a5)
        index = 0;
    8000051a:	00008797          	auipc	a5,0x8
    8000051e:	4607a523          	sw	zero,1130(a5) # 80008984 <index>
        call_sys_history();
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d66080e7          	jalr	-666(ra) # 80000288 <call_sys_history>
        historyBuf.lastCommandIndex++;
    8000052a:	00011717          	auipc	a4,0x11
    8000052e:	67e70713          	addi	a4,a4,1662 # 80011ba8 <topp+0x288>
    80000532:	84072783          	lw	a5,-1984(a4)
    80000536:	2785                	addiw	a5,a5,1
    80000538:	84f72023          	sw	a5,-1984(a4)
        cons.w = cons.e;
    8000053c:	00010797          	auipc	a5,0x10
    80000540:	5c478793          	addi	a5,a5,1476 # 80010b00 <cons>
    80000544:	0a07a703          	lw	a4,160(a5)
    80000548:	08e7ae23          	sw	a4,156(a5)
        wakeup(&cons.r);
    8000054c:	00010517          	auipc	a0,0x10
    80000550:	64c50513          	addi	a0,a0,1612 # 80010b98 <cons+0x98>
    80000554:	00002097          	auipc	ra,0x2
    80000558:	c72080e7          	jalr	-910(ra) # 800021c6 <wakeup>
    8000055c:	bda1                	j	800003b4 <consoleintr+0x3c>

000000008000055e <consoleinit>:

void
consoleinit(void)
{
    8000055e:	1141                	addi	sp,sp,-16
    80000560:	e406                	sd	ra,8(sp)
    80000562:	e022                	sd	s0,0(sp)
    80000564:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000566:	00008597          	auipc	a1,0x8
    8000056a:	aaa58593          	addi	a1,a1,-1366 # 80008010 <etext+0x10>
    8000056e:	00010517          	auipc	a0,0x10
    80000572:	59250513          	addi	a0,a0,1426 # 80010b00 <cons>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	6de080e7          	jalr	1758(ra) # 80000c54 <initlock>

  uartinit();
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	32a080e7          	jalr	810(ra) # 800008a8 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000586:	00021797          	auipc	a5,0x21
    8000058a:	71a78793          	addi	a5,a5,1818 # 80021ca0 <devsw>
    8000058e:	00000717          	auipc	a4,0x0
    80000592:	bd670713          	addi	a4,a4,-1066 # 80000164 <consoleread>
    80000596:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000598:	00000717          	auipc	a4,0x0
    8000059c:	b6a70713          	addi	a4,a4,-1174 # 80000102 <consolewrite>
    800005a0:	ef98                	sd	a4,24(a5)
}
    800005a2:	60a2                	ld	ra,8(sp)
    800005a4:	6402                	ld	s0,0(sp)
    800005a6:	0141                	addi	sp,sp,16
    800005a8:	8082                	ret

00000000800005aa <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800005aa:	7179                	addi	sp,sp,-48
    800005ac:	f406                	sd	ra,40(sp)
    800005ae:	f022                	sd	s0,32(sp)
    800005b0:	ec26                	sd	s1,24(sp)
    800005b2:	e84a                	sd	s2,16(sp)
    800005b4:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800005b6:	c219                	beqz	a2,800005bc <printint+0x12>
    800005b8:	08054663          	bltz	a0,80000644 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800005bc:	2501                	sext.w	a0,a0
    800005be:	4881                	li	a7,0
    800005c0:	fd040693          	addi	a3,s0,-48

  i = 0;
    800005c4:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800005c6:	2581                	sext.w	a1,a1
    800005c8:	00008617          	auipc	a2,0x8
    800005cc:	a7860613          	addi	a2,a2,-1416 # 80008040 <digits>
    800005d0:	883a                	mv	a6,a4
    800005d2:	2705                	addiw	a4,a4,1
    800005d4:	02b577bb          	remuw	a5,a0,a1
    800005d8:	1782                	slli	a5,a5,0x20
    800005da:	9381                	srli	a5,a5,0x20
    800005dc:	97b2                	add	a5,a5,a2
    800005de:	0007c783          	lbu	a5,0(a5)
    800005e2:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800005e6:	0005079b          	sext.w	a5,a0
    800005ea:	02b5553b          	divuw	a0,a0,a1
    800005ee:	0685                	addi	a3,a3,1
    800005f0:	feb7f0e3          	bgeu	a5,a1,800005d0 <printint+0x26>

  if(sign)
    800005f4:	00088b63          	beqz	a7,8000060a <printint+0x60>
    buf[i++] = '-';
    800005f8:	fe040793          	addi	a5,s0,-32
    800005fc:	973e                	add	a4,a4,a5
    800005fe:	02d00793          	li	a5,45
    80000602:	fef70823          	sb	a5,-16(a4)
    80000606:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000060a:	02e05763          	blez	a4,80000638 <printint+0x8e>
    8000060e:	fd040793          	addi	a5,s0,-48
    80000612:	00e784b3          	add	s1,a5,a4
    80000616:	fff78913          	addi	s2,a5,-1
    8000061a:	993a                	add	s2,s2,a4
    8000061c:	377d                	addiw	a4,a4,-1
    8000061e:	1702                	slli	a4,a4,0x20
    80000620:	9301                	srli	a4,a4,0x20
    80000622:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000626:	fff4c503          	lbu	a0,-1(s1)
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	d0c080e7          	jalr	-756(ra) # 80000336 <consputc>
  while(--i >= 0)
    80000632:	14fd                	addi	s1,s1,-1
    80000634:	ff2499e3          	bne	s1,s2,80000626 <printint+0x7c>
}
    80000638:	70a2                	ld	ra,40(sp)
    8000063a:	7402                	ld	s0,32(sp)
    8000063c:	64e2                	ld	s1,24(sp)
    8000063e:	6942                	ld	s2,16(sp)
    80000640:	6145                	addi	sp,sp,48
    80000642:	8082                	ret
    x = -xx;
    80000644:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000648:	4885                	li	a7,1
    x = -xx;
    8000064a:	bf9d                	j	800005c0 <printint+0x16>

000000008000064c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000064c:	1101                	addi	sp,sp,-32
    8000064e:	ec06                	sd	ra,24(sp)
    80000650:	e822                	sd	s0,16(sp)
    80000652:	e426                	sd	s1,8(sp)
    80000654:	1000                	addi	s0,sp,32
    80000656:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000658:	00011797          	auipc	a5,0x11
    8000065c:	e207ac23          	sw	zero,-456(a5) # 80011490 <pr+0x18>
  printf("panic: ");
    80000660:	00008517          	auipc	a0,0x8
    80000664:	9b850513          	addi	a0,a0,-1608 # 80008018 <etext+0x18>
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	02e080e7          	jalr	46(ra) # 80000696 <printf>
  printf(s);
    80000670:	8526                	mv	a0,s1
    80000672:	00000097          	auipc	ra,0x0
    80000676:	024080e7          	jalr	36(ra) # 80000696 <printf>
  printf("\n");
    8000067a:	00008517          	auipc	a0,0x8
    8000067e:	cae50513          	addi	a0,a0,-850 # 80008328 <digits+0x2e8>
    80000682:	00000097          	auipc	ra,0x0
    80000686:	014080e7          	jalr	20(ra) # 80000696 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000068a:	4785                	li	a5,1
    8000068c:	00008717          	auipc	a4,0x8
    80000690:	2ef72e23          	sw	a5,764(a4) # 80008988 <panicked>
  for(;;)
    80000694:	a001                	j	80000694 <panic+0x48>

0000000080000696 <printf>:
{
    80000696:	7131                	addi	sp,sp,-192
    80000698:	fc86                	sd	ra,120(sp)
    8000069a:	f8a2                	sd	s0,112(sp)
    8000069c:	f4a6                	sd	s1,104(sp)
    8000069e:	f0ca                	sd	s2,96(sp)
    800006a0:	ecce                	sd	s3,88(sp)
    800006a2:	e8d2                	sd	s4,80(sp)
    800006a4:	e4d6                	sd	s5,72(sp)
    800006a6:	e0da                	sd	s6,64(sp)
    800006a8:	fc5e                	sd	s7,56(sp)
    800006aa:	f862                	sd	s8,48(sp)
    800006ac:	f466                	sd	s9,40(sp)
    800006ae:	f06a                	sd	s10,32(sp)
    800006b0:	ec6e                	sd	s11,24(sp)
    800006b2:	0100                	addi	s0,sp,128
    800006b4:	8a2a                	mv	s4,a0
    800006b6:	e40c                	sd	a1,8(s0)
    800006b8:	e810                	sd	a2,16(s0)
    800006ba:	ec14                	sd	a3,24(s0)
    800006bc:	f018                	sd	a4,32(s0)
    800006be:	f41c                	sd	a5,40(s0)
    800006c0:	03043823          	sd	a6,48(s0)
    800006c4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800006c8:	00011d97          	auipc	s11,0x11
    800006cc:	dc8dad83          	lw	s11,-568(s11) # 80011490 <pr+0x18>
  if(locking)
    800006d0:	020d9b63          	bnez	s11,80000706 <printf+0x70>
  if (fmt == 0)
    800006d4:	040a0263          	beqz	s4,80000718 <printf+0x82>
  va_start(ap, fmt);
    800006d8:	00840793          	addi	a5,s0,8
    800006dc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006e0:	000a4503          	lbu	a0,0(s4)
    800006e4:	14050f63          	beqz	a0,80000842 <printf+0x1ac>
    800006e8:	4981                	li	s3,0
    if(c != '%'){
    800006ea:	02500a93          	li	s5,37
    switch(c){
    800006ee:	07000b93          	li	s7,112
  consputc('x');
    800006f2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006f4:	00008b17          	auipc	s6,0x8
    800006f8:	94cb0b13          	addi	s6,s6,-1716 # 80008040 <digits>
    switch(c){
    800006fc:	07300c93          	li	s9,115
    80000700:	06400c13          	li	s8,100
    80000704:	a82d                	j	8000073e <printf+0xa8>
    acquire(&pr.lock);
    80000706:	00011517          	auipc	a0,0x11
    8000070a:	d7250513          	addi	a0,a0,-654 # 80011478 <pr>
    8000070e:	00000097          	auipc	ra,0x0
    80000712:	5d6080e7          	jalr	1494(ra) # 80000ce4 <acquire>
    80000716:	bf7d                	j	800006d4 <printf+0x3e>
    panic("null fmt");
    80000718:	00008517          	auipc	a0,0x8
    8000071c:	91050513          	addi	a0,a0,-1776 # 80008028 <etext+0x28>
    80000720:	00000097          	auipc	ra,0x0
    80000724:	f2c080e7          	jalr	-212(ra) # 8000064c <panic>
      consputc(c);
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	c0e080e7          	jalr	-1010(ra) # 80000336 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000730:	2985                	addiw	s3,s3,1
    80000732:	013a07b3          	add	a5,s4,s3
    80000736:	0007c503          	lbu	a0,0(a5)
    8000073a:	10050463          	beqz	a0,80000842 <printf+0x1ac>
    if(c != '%'){
    8000073e:	ff5515e3          	bne	a0,s5,80000728 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000742:	2985                	addiw	s3,s3,1
    80000744:	013a07b3          	add	a5,s4,s3
    80000748:	0007c783          	lbu	a5,0(a5)
    8000074c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000750:	cbed                	beqz	a5,80000842 <printf+0x1ac>
    switch(c){
    80000752:	05778a63          	beq	a5,s7,800007a6 <printf+0x110>
    80000756:	02fbf663          	bgeu	s7,a5,80000782 <printf+0xec>
    8000075a:	09978863          	beq	a5,s9,800007ea <printf+0x154>
    8000075e:	07800713          	li	a4,120
    80000762:	0ce79563          	bne	a5,a4,8000082c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000766:	f8843783          	ld	a5,-120(s0)
    8000076a:	00878713          	addi	a4,a5,8
    8000076e:	f8e43423          	sd	a4,-120(s0)
    80000772:	4605                	li	a2,1
    80000774:	85ea                	mv	a1,s10
    80000776:	4388                	lw	a0,0(a5)
    80000778:	00000097          	auipc	ra,0x0
    8000077c:	e32080e7          	jalr	-462(ra) # 800005aa <printint>
      break;
    80000780:	bf45                	j	80000730 <printf+0x9a>
    switch(c){
    80000782:	09578f63          	beq	a5,s5,80000820 <printf+0x18a>
    80000786:	0b879363          	bne	a5,s8,8000082c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000078a:	f8843783          	ld	a5,-120(s0)
    8000078e:	00878713          	addi	a4,a5,8
    80000792:	f8e43423          	sd	a4,-120(s0)
    80000796:	4605                	li	a2,1
    80000798:	45a9                	li	a1,10
    8000079a:	4388                	lw	a0,0(a5)
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	e0e080e7          	jalr	-498(ra) # 800005aa <printint>
      break;
    800007a4:	b771                	j	80000730 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800007a6:	f8843783          	ld	a5,-120(s0)
    800007aa:	00878713          	addi	a4,a5,8
    800007ae:	f8e43423          	sd	a4,-120(s0)
    800007b2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800007b6:	03000513          	li	a0,48
    800007ba:	00000097          	auipc	ra,0x0
    800007be:	b7c080e7          	jalr	-1156(ra) # 80000336 <consputc>
  consputc('x');
    800007c2:	07800513          	li	a0,120
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	b70080e7          	jalr	-1168(ra) # 80000336 <consputc>
    800007ce:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800007d0:	03c95793          	srli	a5,s2,0x3c
    800007d4:	97da                	add	a5,a5,s6
    800007d6:	0007c503          	lbu	a0,0(a5)
    800007da:	00000097          	auipc	ra,0x0
    800007de:	b5c080e7          	jalr	-1188(ra) # 80000336 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800007e2:	0912                	slli	s2,s2,0x4
    800007e4:	34fd                	addiw	s1,s1,-1
    800007e6:	f4ed                	bnez	s1,800007d0 <printf+0x13a>
    800007e8:	b7a1                	j	80000730 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800007ea:	f8843783          	ld	a5,-120(s0)
    800007ee:	00878713          	addi	a4,a5,8
    800007f2:	f8e43423          	sd	a4,-120(s0)
    800007f6:	6384                	ld	s1,0(a5)
    800007f8:	cc89                	beqz	s1,80000812 <printf+0x17c>
      for(; *s; s++)
    800007fa:	0004c503          	lbu	a0,0(s1)
    800007fe:	d90d                	beqz	a0,80000730 <printf+0x9a>
        consputc(*s);
    80000800:	00000097          	auipc	ra,0x0
    80000804:	b36080e7          	jalr	-1226(ra) # 80000336 <consputc>
      for(; *s; s++)
    80000808:	0485                	addi	s1,s1,1
    8000080a:	0004c503          	lbu	a0,0(s1)
    8000080e:	f96d                	bnez	a0,80000800 <printf+0x16a>
    80000810:	b705                	j	80000730 <printf+0x9a>
        s = "(null)";
    80000812:	00008497          	auipc	s1,0x8
    80000816:	80e48493          	addi	s1,s1,-2034 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000081a:	02800513          	li	a0,40
    8000081e:	b7cd                	j	80000800 <printf+0x16a>
      consputc('%');
    80000820:	8556                	mv	a0,s5
    80000822:	00000097          	auipc	ra,0x0
    80000826:	b14080e7          	jalr	-1260(ra) # 80000336 <consputc>
      break;
    8000082a:	b719                	j	80000730 <printf+0x9a>
      consputc('%');
    8000082c:	8556                	mv	a0,s5
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	b08080e7          	jalr	-1272(ra) # 80000336 <consputc>
      consputc(c);
    80000836:	8526                	mv	a0,s1
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	afe080e7          	jalr	-1282(ra) # 80000336 <consputc>
      break;
    80000840:	bdc5                	j	80000730 <printf+0x9a>
  if(locking)
    80000842:	020d9163          	bnez	s11,80000864 <printf+0x1ce>
}
    80000846:	70e6                	ld	ra,120(sp)
    80000848:	7446                	ld	s0,112(sp)
    8000084a:	74a6                	ld	s1,104(sp)
    8000084c:	7906                	ld	s2,96(sp)
    8000084e:	69e6                	ld	s3,88(sp)
    80000850:	6a46                	ld	s4,80(sp)
    80000852:	6aa6                	ld	s5,72(sp)
    80000854:	6b06                	ld	s6,64(sp)
    80000856:	7be2                	ld	s7,56(sp)
    80000858:	7c42                	ld	s8,48(sp)
    8000085a:	7ca2                	ld	s9,40(sp)
    8000085c:	7d02                	ld	s10,32(sp)
    8000085e:	6de2                	ld	s11,24(sp)
    80000860:	6129                	addi	sp,sp,192
    80000862:	8082                	ret
    release(&pr.lock);
    80000864:	00011517          	auipc	a0,0x11
    80000868:	c1450513          	addi	a0,a0,-1004 # 80011478 <pr>
    8000086c:	00000097          	auipc	ra,0x0
    80000870:	52c080e7          	jalr	1324(ra) # 80000d98 <release>
}
    80000874:	bfc9                	j	80000846 <printf+0x1b0>

0000000080000876 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000876:	1101                	addi	sp,sp,-32
    80000878:	ec06                	sd	ra,24(sp)
    8000087a:	e822                	sd	s0,16(sp)
    8000087c:	e426                	sd	s1,8(sp)
    8000087e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000880:	00011497          	auipc	s1,0x11
    80000884:	bf848493          	addi	s1,s1,-1032 # 80011478 <pr>
    80000888:	00007597          	auipc	a1,0x7
    8000088c:	7b058593          	addi	a1,a1,1968 # 80008038 <etext+0x38>
    80000890:	8526                	mv	a0,s1
    80000892:	00000097          	auipc	ra,0x0
    80000896:	3c2080e7          	jalr	962(ra) # 80000c54 <initlock>
  pr.locking = 1;
    8000089a:	4785                	li	a5,1
    8000089c:	cc9c                	sw	a5,24(s1)
}
    8000089e:	60e2                	ld	ra,24(sp)
    800008a0:	6442                	ld	s0,16(sp)
    800008a2:	64a2                	ld	s1,8(sp)
    800008a4:	6105                	addi	sp,sp,32
    800008a6:	8082                	ret

00000000800008a8 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800008a8:	1141                	addi	sp,sp,-16
    800008aa:	e406                	sd	ra,8(sp)
    800008ac:	e022                	sd	s0,0(sp)
    800008ae:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800008b0:	100007b7          	lui	a5,0x10000
    800008b4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800008b8:	f8000713          	li	a4,-128
    800008bc:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800008c0:	470d                	li	a4,3
    800008c2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800008c6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800008ca:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800008ce:	469d                	li	a3,7
    800008d0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800008d4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800008d8:	00007597          	auipc	a1,0x7
    800008dc:	78058593          	addi	a1,a1,1920 # 80008058 <digits+0x18>
    800008e0:	00011517          	auipc	a0,0x11
    800008e4:	bb850513          	addi	a0,a0,-1096 # 80011498 <uart_tx_lock>
    800008e8:	00000097          	auipc	ra,0x0
    800008ec:	36c080e7          	jalr	876(ra) # 80000c54 <initlock>
}
    800008f0:	60a2                	ld	ra,8(sp)
    800008f2:	6402                	ld	s0,0(sp)
    800008f4:	0141                	addi	sp,sp,16
    800008f6:	8082                	ret

00000000800008f8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800008f8:	1101                	addi	sp,sp,-32
    800008fa:	ec06                	sd	ra,24(sp)
    800008fc:	e822                	sd	s0,16(sp)
    800008fe:	e426                	sd	s1,8(sp)
    80000900:	1000                	addi	s0,sp,32
    80000902:	84aa                	mv	s1,a0
  push_off();
    80000904:	00000097          	auipc	ra,0x0
    80000908:	394080e7          	jalr	916(ra) # 80000c98 <push_off>

  if(panicked){
    8000090c:	00008797          	auipc	a5,0x8
    80000910:	07c7a783          	lw	a5,124(a5) # 80008988 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000914:	10000737          	lui	a4,0x10000
  if(panicked){
    80000918:	c391                	beqz	a5,8000091c <uartputc_sync+0x24>
    for(;;)
    8000091a:	a001                	j	8000091a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000091c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000920:	0207f793          	andi	a5,a5,32
    80000924:	dfe5                	beqz	a5,8000091c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000926:	0ff4f513          	andi	a0,s1,255
    8000092a:	100007b7          	lui	a5,0x10000
    8000092e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000932:	00000097          	auipc	ra,0x0
    80000936:	406080e7          	jalr	1030(ra) # 80000d38 <pop_off>
}
    8000093a:	60e2                	ld	ra,24(sp)
    8000093c:	6442                	ld	s0,16(sp)
    8000093e:	64a2                	ld	s1,8(sp)
    80000940:	6105                	addi	sp,sp,32
    80000942:	8082                	ret

0000000080000944 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000944:	00008797          	auipc	a5,0x8
    80000948:	04c7b783          	ld	a5,76(a5) # 80008990 <uart_tx_r>
    8000094c:	00008717          	auipc	a4,0x8
    80000950:	04c73703          	ld	a4,76(a4) # 80008998 <uart_tx_w>
    80000954:	06f70a63          	beq	a4,a5,800009c8 <uartstart+0x84>
{
    80000958:	7139                	addi	sp,sp,-64
    8000095a:	fc06                	sd	ra,56(sp)
    8000095c:	f822                	sd	s0,48(sp)
    8000095e:	f426                	sd	s1,40(sp)
    80000960:	f04a                	sd	s2,32(sp)
    80000962:	ec4e                	sd	s3,24(sp)
    80000964:	e852                	sd	s4,16(sp)
    80000966:	e456                	sd	s5,8(sp)
    80000968:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000096a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000096e:	00011a17          	auipc	s4,0x11
    80000972:	b2aa0a13          	addi	s4,s4,-1238 # 80011498 <uart_tx_lock>
    uart_tx_r += 1;
    80000976:	00008497          	auipc	s1,0x8
    8000097a:	01a48493          	addi	s1,s1,26 # 80008990 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000097e:	00008997          	auipc	s3,0x8
    80000982:	01a98993          	addi	s3,s3,26 # 80008998 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000986:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000098a:	02077713          	andi	a4,a4,32
    8000098e:	c705                	beqz	a4,800009b6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000990:	01f7f713          	andi	a4,a5,31
    80000994:	9752                	add	a4,a4,s4
    80000996:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000099a:	0785                	addi	a5,a5,1
    8000099c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000099e:	8526                	mv	a0,s1
    800009a0:	00002097          	auipc	ra,0x2
    800009a4:	826080e7          	jalr	-2010(ra) # 800021c6 <wakeup>
    
    WriteReg(THR, c);
    800009a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800009ac:	609c                	ld	a5,0(s1)
    800009ae:	0009b703          	ld	a4,0(s3)
    800009b2:	fcf71ae3          	bne	a4,a5,80000986 <uartstart+0x42>
  }
}
    800009b6:	70e2                	ld	ra,56(sp)
    800009b8:	7442                	ld	s0,48(sp)
    800009ba:	74a2                	ld	s1,40(sp)
    800009bc:	7902                	ld	s2,32(sp)
    800009be:	69e2                	ld	s3,24(sp)
    800009c0:	6a42                	ld	s4,16(sp)
    800009c2:	6aa2                	ld	s5,8(sp)
    800009c4:	6121                	addi	sp,sp,64
    800009c6:	8082                	ret
    800009c8:	8082                	ret

00000000800009ca <uartputc>:
{
    800009ca:	7179                	addi	sp,sp,-48
    800009cc:	f406                	sd	ra,40(sp)
    800009ce:	f022                	sd	s0,32(sp)
    800009d0:	ec26                	sd	s1,24(sp)
    800009d2:	e84a                	sd	s2,16(sp)
    800009d4:	e44e                	sd	s3,8(sp)
    800009d6:	e052                	sd	s4,0(sp)
    800009d8:	1800                	addi	s0,sp,48
    800009da:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800009dc:	00011517          	auipc	a0,0x11
    800009e0:	abc50513          	addi	a0,a0,-1348 # 80011498 <uart_tx_lock>
    800009e4:	00000097          	auipc	ra,0x0
    800009e8:	300080e7          	jalr	768(ra) # 80000ce4 <acquire>
  if(panicked){
    800009ec:	00008797          	auipc	a5,0x8
    800009f0:	f9c7a783          	lw	a5,-100(a5) # 80008988 <panicked>
    800009f4:	e7c9                	bnez	a5,80000a7e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800009f6:	00008717          	auipc	a4,0x8
    800009fa:	fa273703          	ld	a4,-94(a4) # 80008998 <uart_tx_w>
    800009fe:	00008797          	auipc	a5,0x8
    80000a02:	f927b783          	ld	a5,-110(a5) # 80008990 <uart_tx_r>
    80000a06:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000a0a:	00011997          	auipc	s3,0x11
    80000a0e:	a8e98993          	addi	s3,s3,-1394 # 80011498 <uart_tx_lock>
    80000a12:	00008497          	auipc	s1,0x8
    80000a16:	f7e48493          	addi	s1,s1,-130 # 80008990 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000a1a:	00008917          	auipc	s2,0x8
    80000a1e:	f7e90913          	addi	s2,s2,-130 # 80008998 <uart_tx_w>
    80000a22:	00e79f63          	bne	a5,a4,80000a40 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000a26:	85ce                	mv	a1,s3
    80000a28:	8526                	mv	a0,s1
    80000a2a:	00001097          	auipc	ra,0x1
    80000a2e:	738080e7          	jalr	1848(ra) # 80002162 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000a32:	00093703          	ld	a4,0(s2)
    80000a36:	609c                	ld	a5,0(s1)
    80000a38:	02078793          	addi	a5,a5,32
    80000a3c:	fee785e3          	beq	a5,a4,80000a26 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000a40:	00011497          	auipc	s1,0x11
    80000a44:	a5848493          	addi	s1,s1,-1448 # 80011498 <uart_tx_lock>
    80000a48:	01f77793          	andi	a5,a4,31
    80000a4c:	97a6                	add	a5,a5,s1
    80000a4e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000a52:	0705                	addi	a4,a4,1
    80000a54:	00008797          	auipc	a5,0x8
    80000a58:	f4e7b223          	sd	a4,-188(a5) # 80008998 <uart_tx_w>
  uartstart();
    80000a5c:	00000097          	auipc	ra,0x0
    80000a60:	ee8080e7          	jalr	-280(ra) # 80000944 <uartstart>
  release(&uart_tx_lock);
    80000a64:	8526                	mv	a0,s1
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	332080e7          	jalr	818(ra) # 80000d98 <release>
}
    80000a6e:	70a2                	ld	ra,40(sp)
    80000a70:	7402                	ld	s0,32(sp)
    80000a72:	64e2                	ld	s1,24(sp)
    80000a74:	6942                	ld	s2,16(sp)
    80000a76:	69a2                	ld	s3,8(sp)
    80000a78:	6a02                	ld	s4,0(sp)
    80000a7a:	6145                	addi	sp,sp,48
    80000a7c:	8082                	ret
    for(;;)
    80000a7e:	a001                	j	80000a7e <uartputc+0xb4>

0000000080000a80 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a80:	1141                	addi	sp,sp,-16
    80000a82:	e422                	sd	s0,8(sp)
    80000a84:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a86:	100007b7          	lui	a5,0x10000
    80000a8a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a8e:	8b85                	andi	a5,a5,1
    80000a90:	cb91                	beqz	a5,80000aa4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a92:	100007b7          	lui	a5,0x10000
    80000a96:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a9a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a9e:	6422                	ld	s0,8(sp)
    80000aa0:	0141                	addi	sp,sp,16
    80000aa2:	8082                	ret
    return -1;
    80000aa4:	557d                	li	a0,-1
    80000aa6:	bfe5                	j	80000a9e <uartgetc+0x1e>

0000000080000aa8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000aa8:	1101                	addi	sp,sp,-32
    80000aaa:	ec06                	sd	ra,24(sp)
    80000aac:	e822                	sd	s0,16(sp)
    80000aae:	e426                	sd	s1,8(sp)
    80000ab0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000ab2:	54fd                	li	s1,-1
    80000ab4:	a029                	j	80000abe <uartintr+0x16>
      break;
    consoleintr(c);
    80000ab6:	00000097          	auipc	ra,0x0
    80000aba:	8c2080e7          	jalr	-1854(ra) # 80000378 <consoleintr>
    int c = uartgetc();
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	fc2080e7          	jalr	-62(ra) # 80000a80 <uartgetc>
    if(c == -1)
    80000ac6:	fe9518e3          	bne	a0,s1,80000ab6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000aca:	00011497          	auipc	s1,0x11
    80000ace:	9ce48493          	addi	s1,s1,-1586 # 80011498 <uart_tx_lock>
    80000ad2:	8526                	mv	a0,s1
    80000ad4:	00000097          	auipc	ra,0x0
    80000ad8:	210080e7          	jalr	528(ra) # 80000ce4 <acquire>
  uartstart();
    80000adc:	00000097          	auipc	ra,0x0
    80000ae0:	e68080e7          	jalr	-408(ra) # 80000944 <uartstart>
  release(&uart_tx_lock);
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	2b2080e7          	jalr	690(ra) # 80000d98 <release>
}
    80000aee:	60e2                	ld	ra,24(sp)
    80000af0:	6442                	ld	s0,16(sp)
    80000af2:	64a2                	ld	s1,8(sp)
    80000af4:	6105                	addi	sp,sp,32
    80000af6:	8082                	ret

0000000080000af8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000af8:	1101                	addi	sp,sp,-32
    80000afa:	ec06                	sd	ra,24(sp)
    80000afc:	e822                	sd	s0,16(sp)
    80000afe:	e426                	sd	s1,8(sp)
    80000b00:	e04a                	sd	s2,0(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000b04:	03451793          	slli	a5,a0,0x34
    80000b08:	ebb9                	bnez	a5,80000b5e <kfree+0x66>
    80000b0a:	84aa                	mv	s1,a0
    80000b0c:	00022797          	auipc	a5,0x22
    80000b10:	32c78793          	addi	a5,a5,812 # 80022e38 <end>
    80000b14:	04f56563          	bltu	a0,a5,80000b5e <kfree+0x66>
    80000b18:	47c5                	li	a5,17
    80000b1a:	07ee                	slli	a5,a5,0x1b
    80000b1c:	04f57163          	bgeu	a0,a5,80000b5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000b20:	6605                	lui	a2,0x1
    80000b22:	4585                	li	a1,1
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	2bc080e7          	jalr	700(ra) # 80000de0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000b2c:	00011917          	auipc	s2,0x11
    80000b30:	9a490913          	addi	s2,s2,-1628 # 800114d0 <kmem>
    80000b34:	854a                	mv	a0,s2
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	1ae080e7          	jalr	430(ra) # 80000ce4 <acquire>
  r->next = kmem.freelist;
    80000b3e:	01893783          	ld	a5,24(s2)
    80000b42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b48:	854a                	mv	a0,s2
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	24e080e7          	jalr	590(ra) # 80000d98 <release>
}
    80000b52:	60e2                	ld	ra,24(sp)
    80000b54:	6442                	ld	s0,16(sp)
    80000b56:	64a2                	ld	s1,8(sp)
    80000b58:	6902                	ld	s2,0(sp)
    80000b5a:	6105                	addi	sp,sp,32
    80000b5c:	8082                	ret
    panic("kfree");
    80000b5e:	00007517          	auipc	a0,0x7
    80000b62:	50250513          	addi	a0,a0,1282 # 80008060 <digits+0x20>
    80000b66:	00000097          	auipc	ra,0x0
    80000b6a:	ae6080e7          	jalr	-1306(ra) # 8000064c <panic>

0000000080000b6e <freerange>:
{
    80000b6e:	7179                	addi	sp,sp,-48
    80000b70:	f406                	sd	ra,40(sp)
    80000b72:	f022                	sd	s0,32(sp)
    80000b74:	ec26                	sd	s1,24(sp)
    80000b76:	e84a                	sd	s2,16(sp)
    80000b78:	e44e                	sd	s3,8(sp)
    80000b7a:	e052                	sd	s4,0(sp)
    80000b7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b7e:	6785                	lui	a5,0x1
    80000b80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b84:	94aa                	add	s1,s1,a0
    80000b86:	757d                	lui	a0,0xfffff
    80000b88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b8a:	94be                	add	s1,s1,a5
    80000b8c:	0095ee63          	bltu	a1,s1,80000ba8 <freerange+0x3a>
    80000b90:	892e                	mv	s2,a1
    kfree(p);
    80000b92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b94:	6985                	lui	s3,0x1
    kfree(p);
    80000b96:	01448533          	add	a0,s1,s4
    80000b9a:	00000097          	auipc	ra,0x0
    80000b9e:	f5e080e7          	jalr	-162(ra) # 80000af8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ba2:	94ce                	add	s1,s1,s3
    80000ba4:	fe9979e3          	bgeu	s2,s1,80000b96 <freerange+0x28>
}
    80000ba8:	70a2                	ld	ra,40(sp)
    80000baa:	7402                	ld	s0,32(sp)
    80000bac:	64e2                	ld	s1,24(sp)
    80000bae:	6942                	ld	s2,16(sp)
    80000bb0:	69a2                	ld	s3,8(sp)
    80000bb2:	6a02                	ld	s4,0(sp)
    80000bb4:	6145                	addi	sp,sp,48
    80000bb6:	8082                	ret

0000000080000bb8 <kinit>:
{
    80000bb8:	1141                	addi	sp,sp,-16
    80000bba:	e406                	sd	ra,8(sp)
    80000bbc:	e022                	sd	s0,0(sp)
    80000bbe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000bc0:	00007597          	auipc	a1,0x7
    80000bc4:	4a858593          	addi	a1,a1,1192 # 80008068 <digits+0x28>
    80000bc8:	00011517          	auipc	a0,0x11
    80000bcc:	90850513          	addi	a0,a0,-1784 # 800114d0 <kmem>
    80000bd0:	00000097          	auipc	ra,0x0
    80000bd4:	084080e7          	jalr	132(ra) # 80000c54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000bd8:	45c5                	li	a1,17
    80000bda:	05ee                	slli	a1,a1,0x1b
    80000bdc:	00022517          	auipc	a0,0x22
    80000be0:	25c50513          	addi	a0,a0,604 # 80022e38 <end>
    80000be4:	00000097          	auipc	ra,0x0
    80000be8:	f8a080e7          	jalr	-118(ra) # 80000b6e <freerange>
}
    80000bec:	60a2                	ld	ra,8(sp)
    80000bee:	6402                	ld	s0,0(sp)
    80000bf0:	0141                	addi	sp,sp,16
    80000bf2:	8082                	ret

0000000080000bf4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bf4:	1101                	addi	sp,sp,-32
    80000bf6:	ec06                	sd	ra,24(sp)
    80000bf8:	e822                	sd	s0,16(sp)
    80000bfa:	e426                	sd	s1,8(sp)
    80000bfc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000bfe:	00011497          	auipc	s1,0x11
    80000c02:	8d248493          	addi	s1,s1,-1838 # 800114d0 <kmem>
    80000c06:	8526                	mv	a0,s1
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	0dc080e7          	jalr	220(ra) # 80000ce4 <acquire>
  r = kmem.freelist;
    80000c10:	6c84                	ld	s1,24(s1)
  if(r)
    80000c12:	c885                	beqz	s1,80000c42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000c14:	609c                	ld	a5,0(s1)
    80000c16:	00011517          	auipc	a0,0x11
    80000c1a:	8ba50513          	addi	a0,a0,-1862 # 800114d0 <kmem>
    80000c1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000c20:	00000097          	auipc	ra,0x0
    80000c24:	178080e7          	jalr	376(ra) # 80000d98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c28:	6605                	lui	a2,0x1
    80000c2a:	4595                	li	a1,5
    80000c2c:	8526                	mv	a0,s1
    80000c2e:	00000097          	auipc	ra,0x0
    80000c32:	1b2080e7          	jalr	434(ra) # 80000de0 <memset>
  return (void*)r;
}
    80000c36:	8526                	mv	a0,s1
    80000c38:	60e2                	ld	ra,24(sp)
    80000c3a:	6442                	ld	s0,16(sp)
    80000c3c:	64a2                	ld	s1,8(sp)
    80000c3e:	6105                	addi	sp,sp,32
    80000c40:	8082                	ret
  release(&kmem.lock);
    80000c42:	00011517          	auipc	a0,0x11
    80000c46:	88e50513          	addi	a0,a0,-1906 # 800114d0 <kmem>
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	14e080e7          	jalr	334(ra) # 80000d98 <release>
  if(r)
    80000c52:	b7d5                	j	80000c36 <kalloc+0x42>

0000000080000c54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c54:	1141                	addi	sp,sp,-16
    80000c56:	e422                	sd	s0,8(sp)
    80000c58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c60:	00053823          	sd	zero,16(a0)
}
    80000c64:	6422                	ld	s0,8(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret

0000000080000c6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c6a:	411c                	lw	a5,0(a0)
    80000c6c:	e399                	bnez	a5,80000c72 <holding+0x8>
    80000c6e:	4501                	li	a0,0
  return r;
}
    80000c70:	8082                	ret
{
    80000c72:	1101                	addi	sp,sp,-32
    80000c74:	ec06                	sd	ra,24(sp)
    80000c76:	e822                	sd	s0,16(sp)
    80000c78:	e426                	sd	s1,8(sp)
    80000c7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c7c:	6904                	ld	s1,16(a0)
    80000c7e:	00001097          	auipc	ra,0x1
    80000c82:	e20080e7          	jalr	-480(ra) # 80001a9e <mycpu>
    80000c86:	40a48533          	sub	a0,s1,a0
    80000c8a:	00153513          	seqz	a0,a0
}
    80000c8e:	60e2                	ld	ra,24(sp)
    80000c90:	6442                	ld	s0,16(sp)
    80000c92:	64a2                	ld	s1,8(sp)
    80000c94:	6105                	addi	sp,sp,32
    80000c96:	8082                	ret

0000000080000c98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca2:	100024f3          	csrr	s1,sstatus
    80000ca6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000caa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cb0:	00001097          	auipc	ra,0x1
    80000cb4:	dee080e7          	jalr	-530(ra) # 80001a9e <mycpu>
    80000cb8:	5d3c                	lw	a5,120(a0)
    80000cba:	cf89                	beqz	a5,80000cd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cbc:	00001097          	auipc	ra,0x1
    80000cc0:	de2080e7          	jalr	-542(ra) # 80001a9e <mycpu>
    80000cc4:	5d3c                	lw	a5,120(a0)
    80000cc6:	2785                	addiw	a5,a5,1
    80000cc8:	dd3c                	sw	a5,120(a0)
}
    80000cca:	60e2                	ld	ra,24(sp)
    80000ccc:	6442                	ld	s0,16(sp)
    80000cce:	64a2                	ld	s1,8(sp)
    80000cd0:	6105                	addi	sp,sp,32
    80000cd2:	8082                	ret
    mycpu()->intena = old;
    80000cd4:	00001097          	auipc	ra,0x1
    80000cd8:	dca080e7          	jalr	-566(ra) # 80001a9e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cdc:	8085                	srli	s1,s1,0x1
    80000cde:	8885                	andi	s1,s1,1
    80000ce0:	dd64                	sw	s1,124(a0)
    80000ce2:	bfe9                	j	80000cbc <push_off+0x24>

0000000080000ce4 <acquire>:
{
    80000ce4:	1101                	addi	sp,sp,-32
    80000ce6:	ec06                	sd	ra,24(sp)
    80000ce8:	e822                	sd	s0,16(sp)
    80000cea:	e426                	sd	s1,8(sp)
    80000cec:	1000                	addi	s0,sp,32
    80000cee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cf0:	00000097          	auipc	ra,0x0
    80000cf4:	fa8080e7          	jalr	-88(ra) # 80000c98 <push_off>
  if(holding(lk))
    80000cf8:	8526                	mv	a0,s1
    80000cfa:	00000097          	auipc	ra,0x0
    80000cfe:	f70080e7          	jalr	-144(ra) # 80000c6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d02:	4705                	li	a4,1
  if(holding(lk))
    80000d04:	e115                	bnez	a0,80000d28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d06:	87ba                	mv	a5,a4
    80000d08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d0c:	2781                	sext.w	a5,a5
    80000d0e:	ffe5                	bnez	a5,80000d06 <acquire+0x22>
  __sync_synchronize();
    80000d10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d14:	00001097          	auipc	ra,0x1
    80000d18:	d8a080e7          	jalr	-630(ra) # 80001a9e <mycpu>
    80000d1c:	e888                	sd	a0,16(s1)
}
    80000d1e:	60e2                	ld	ra,24(sp)
    80000d20:	6442                	ld	s0,16(sp)
    80000d22:	64a2                	ld	s1,8(sp)
    80000d24:	6105                	addi	sp,sp,32
    80000d26:	8082                	ret
    panic("acquire");
    80000d28:	00007517          	auipc	a0,0x7
    80000d2c:	34850513          	addi	a0,a0,840 # 80008070 <digits+0x30>
    80000d30:	00000097          	auipc	ra,0x0
    80000d34:	91c080e7          	jalr	-1764(ra) # 8000064c <panic>

0000000080000d38 <pop_off>:

void
pop_off(void)
{
    80000d38:	1141                	addi	sp,sp,-16
    80000d3a:	e406                	sd	ra,8(sp)
    80000d3c:	e022                	sd	s0,0(sp)
    80000d3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d40:	00001097          	auipc	ra,0x1
    80000d44:	d5e080e7          	jalr	-674(ra) # 80001a9e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d4e:	e78d                	bnez	a5,80000d78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d50:	5d3c                	lw	a5,120(a0)
    80000d52:	02f05b63          	blez	a5,80000d88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d56:	37fd                	addiw	a5,a5,-1
    80000d58:	0007871b          	sext.w	a4,a5
    80000d5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d5e:	eb09                	bnez	a4,80000d70 <pop_off+0x38>
    80000d60:	5d7c                	lw	a5,124(a0)
    80000d62:	c799                	beqz	a5,80000d70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d70:	60a2                	ld	ra,8(sp)
    80000d72:	6402                	ld	s0,0(sp)
    80000d74:	0141                	addi	sp,sp,16
    80000d76:	8082                	ret
    panic("pop_off - interruptible");
    80000d78:	00007517          	auipc	a0,0x7
    80000d7c:	30050513          	addi	a0,a0,768 # 80008078 <digits+0x38>
    80000d80:	00000097          	auipc	ra,0x0
    80000d84:	8cc080e7          	jalr	-1844(ra) # 8000064c <panic>
    panic("pop_off");
    80000d88:	00007517          	auipc	a0,0x7
    80000d8c:	30850513          	addi	a0,a0,776 # 80008090 <digits+0x50>
    80000d90:	00000097          	auipc	ra,0x0
    80000d94:	8bc080e7          	jalr	-1860(ra) # 8000064c <panic>

0000000080000d98 <release>:
{
    80000d98:	1101                	addi	sp,sp,-32
    80000d9a:	ec06                	sd	ra,24(sp)
    80000d9c:	e822                	sd	s0,16(sp)
    80000d9e:	e426                	sd	s1,8(sp)
    80000da0:	1000                	addi	s0,sp,32
    80000da2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000da4:	00000097          	auipc	ra,0x0
    80000da8:	ec6080e7          	jalr	-314(ra) # 80000c6a <holding>
    80000dac:	c115                	beqz	a0,80000dd0 <release+0x38>
  lk->cpu = 0;
    80000dae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000db2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000db6:	0f50000f          	fence	iorw,ow
    80000dba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000dbe:	00000097          	auipc	ra,0x0
    80000dc2:	f7a080e7          	jalr	-134(ra) # 80000d38 <pop_off>
}
    80000dc6:	60e2                	ld	ra,24(sp)
    80000dc8:	6442                	ld	s0,16(sp)
    80000dca:	64a2                	ld	s1,8(sp)
    80000dcc:	6105                	addi	sp,sp,32
    80000dce:	8082                	ret
    panic("release");
    80000dd0:	00007517          	auipc	a0,0x7
    80000dd4:	2c850513          	addi	a0,a0,712 # 80008098 <digits+0x58>
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	874080e7          	jalr	-1932(ra) # 8000064c <panic>

0000000080000de0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000de0:	1141                	addi	sp,sp,-16
    80000de2:	e422                	sd	s0,8(sp)
    80000de4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000de6:	ca19                	beqz	a2,80000dfc <memset+0x1c>
    80000de8:	87aa                	mv	a5,a0
    80000dea:	1602                	slli	a2,a2,0x20
    80000dec:	9201                	srli	a2,a2,0x20
    80000dee:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000df2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000df6:	0785                	addi	a5,a5,1
    80000df8:	fee79de3          	bne	a5,a4,80000df2 <memset+0x12>
  }
  return dst;
}
    80000dfc:	6422                	ld	s0,8(sp)
    80000dfe:	0141                	addi	sp,sp,16
    80000e00:	8082                	ret

0000000080000e02 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e02:	1141                	addi	sp,sp,-16
    80000e04:	e422                	sd	s0,8(sp)
    80000e06:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e08:	ca05                	beqz	a2,80000e38 <memcmp+0x36>
    80000e0a:	fff6069b          	addiw	a3,a2,-1
    80000e0e:	1682                	slli	a3,a3,0x20
    80000e10:	9281                	srli	a3,a3,0x20
    80000e12:	0685                	addi	a3,a3,1
    80000e14:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e16:	00054783          	lbu	a5,0(a0)
    80000e1a:	0005c703          	lbu	a4,0(a1)
    80000e1e:	00e79863          	bne	a5,a4,80000e2e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e22:	0505                	addi	a0,a0,1
    80000e24:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e26:	fed518e3          	bne	a0,a3,80000e16 <memcmp+0x14>
  }

  return 0;
    80000e2a:	4501                	li	a0,0
    80000e2c:	a019                	j	80000e32 <memcmp+0x30>
      return *s1 - *s2;
    80000e2e:	40e7853b          	subw	a0,a5,a4
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret
  return 0;
    80000e38:	4501                	li	a0,0
    80000e3a:	bfe5                	j	80000e32 <memcmp+0x30>

0000000080000e3c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e422                	sd	s0,8(sp)
    80000e40:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e42:	c205                	beqz	a2,80000e62 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e44:	02a5e263          	bltu	a1,a0,80000e68 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e48:	1602                	slli	a2,a2,0x20
    80000e4a:	9201                	srli	a2,a2,0x20
    80000e4c:	00c587b3          	add	a5,a1,a2
{
    80000e50:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0705                	addi	a4,a4,1
    80000e56:	fff5c683          	lbu	a3,-1(a1)
    80000e5a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e5e:	fef59ae3          	bne	a1,a5,80000e52 <memmove+0x16>

  return dst;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  if(s < d && s + n > d){
    80000e68:	02061693          	slli	a3,a2,0x20
    80000e6c:	9281                	srli	a3,a3,0x20
    80000e6e:	00d58733          	add	a4,a1,a3
    80000e72:	fce57be3          	bgeu	a0,a4,80000e48 <memmove+0xc>
    d += n;
    80000e76:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e78:	fff6079b          	addiw	a5,a2,-1
    80000e7c:	1782                	slli	a5,a5,0x20
    80000e7e:	9381                	srli	a5,a5,0x20
    80000e80:	fff7c793          	not	a5,a5
    80000e84:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e86:	177d                	addi	a4,a4,-1
    80000e88:	16fd                	addi	a3,a3,-1
    80000e8a:	00074603          	lbu	a2,0(a4)
    80000e8e:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e92:	fee79ae3          	bne	a5,a4,80000e86 <memmove+0x4a>
    80000e96:	b7f1                	j	80000e62 <memmove+0x26>

0000000080000e98 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e98:	1141                	addi	sp,sp,-16
    80000e9a:	e406                	sd	ra,8(sp)
    80000e9c:	e022                	sd	s0,0(sp)
    80000e9e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ea0:	00000097          	auipc	ra,0x0
    80000ea4:	f9c080e7          	jalr	-100(ra) # 80000e3c <memmove>
}
    80000ea8:	60a2                	ld	ra,8(sp)
    80000eaa:	6402                	ld	s0,0(sp)
    80000eac:	0141                	addi	sp,sp,16
    80000eae:	8082                	ret

0000000080000eb0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000eb0:	1141                	addi	sp,sp,-16
    80000eb2:	e422                	sd	s0,8(sp)
    80000eb4:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eb6:	ce11                	beqz	a2,80000ed2 <strncmp+0x22>
    80000eb8:	00054783          	lbu	a5,0(a0)
    80000ebc:	cf89                	beqz	a5,80000ed6 <strncmp+0x26>
    80000ebe:	0005c703          	lbu	a4,0(a1)
    80000ec2:	00f71a63          	bne	a4,a5,80000ed6 <strncmp+0x26>
    n--, p++, q++;
    80000ec6:	367d                	addiw	a2,a2,-1
    80000ec8:	0505                	addi	a0,a0,1
    80000eca:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ecc:	f675                	bnez	a2,80000eb8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ece:	4501                	li	a0,0
    80000ed0:	a809                	j	80000ee2 <strncmp+0x32>
    80000ed2:	4501                	li	a0,0
    80000ed4:	a039                	j	80000ee2 <strncmp+0x32>
  if(n == 0)
    80000ed6:	ca09                	beqz	a2,80000ee8 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000ed8:	00054503          	lbu	a0,0(a0)
    80000edc:	0005c783          	lbu	a5,0(a1)
    80000ee0:	9d1d                	subw	a0,a0,a5
}
    80000ee2:	6422                	ld	s0,8(sp)
    80000ee4:	0141                	addi	sp,sp,16
    80000ee6:	8082                	ret
    return 0;
    80000ee8:	4501                	li	a0,0
    80000eea:	bfe5                	j	80000ee2 <strncmp+0x32>

0000000080000eec <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000eec:	1141                	addi	sp,sp,-16
    80000eee:	e422                	sd	s0,8(sp)
    80000ef0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ef2:	872a                	mv	a4,a0
    80000ef4:	8832                	mv	a6,a2
    80000ef6:	367d                	addiw	a2,a2,-1
    80000ef8:	01005963          	blez	a6,80000f0a <strncpy+0x1e>
    80000efc:	0705                	addi	a4,a4,1
    80000efe:	0005c783          	lbu	a5,0(a1)
    80000f02:	fef70fa3          	sb	a5,-1(a4)
    80000f06:	0585                	addi	a1,a1,1
    80000f08:	f7f5                	bnez	a5,80000ef4 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f0a:	86ba                	mv	a3,a4
    80000f0c:	00c05c63          	blez	a2,80000f24 <strncpy+0x38>
    *s++ = 0;
    80000f10:	0685                	addi	a3,a3,1
    80000f12:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f16:	fff6c793          	not	a5,a3
    80000f1a:	9fb9                	addw	a5,a5,a4
    80000f1c:	010787bb          	addw	a5,a5,a6
    80000f20:	fef048e3          	bgtz	a5,80000f10 <strncpy+0x24>
  return os;
}
    80000f24:	6422                	ld	s0,8(sp)
    80000f26:	0141                	addi	sp,sp,16
    80000f28:	8082                	ret

0000000080000f2a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f2a:	1141                	addi	sp,sp,-16
    80000f2c:	e422                	sd	s0,8(sp)
    80000f2e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f30:	02c05363          	blez	a2,80000f56 <safestrcpy+0x2c>
    80000f34:	fff6069b          	addiw	a3,a2,-1
    80000f38:	1682                	slli	a3,a3,0x20
    80000f3a:	9281                	srli	a3,a3,0x20
    80000f3c:	96ae                	add	a3,a3,a1
    80000f3e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f40:	00d58963          	beq	a1,a3,80000f52 <safestrcpy+0x28>
    80000f44:	0585                	addi	a1,a1,1
    80000f46:	0785                	addi	a5,a5,1
    80000f48:	fff5c703          	lbu	a4,-1(a1)
    80000f4c:	fee78fa3          	sb	a4,-1(a5)
    80000f50:	fb65                	bnez	a4,80000f40 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f52:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f56:	6422                	ld	s0,8(sp)
    80000f58:	0141                	addi	sp,sp,16
    80000f5a:	8082                	ret

0000000080000f5c <strlen>:

int
strlen(const char *s)
{
    80000f5c:	1141                	addi	sp,sp,-16
    80000f5e:	e422                	sd	s0,8(sp)
    80000f60:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f62:	00054783          	lbu	a5,0(a0)
    80000f66:	cf91                	beqz	a5,80000f82 <strlen+0x26>
    80000f68:	0505                	addi	a0,a0,1
    80000f6a:	87aa                	mv	a5,a0
    80000f6c:	4685                	li	a3,1
    80000f6e:	9e89                	subw	a3,a3,a0
    80000f70:	00f6853b          	addw	a0,a3,a5
    80000f74:	0785                	addi	a5,a5,1
    80000f76:	fff7c703          	lbu	a4,-1(a5)
    80000f7a:	fb7d                	bnez	a4,80000f70 <strlen+0x14>
    ;
  return n;
}
    80000f7c:	6422                	ld	s0,8(sp)
    80000f7e:	0141                	addi	sp,sp,16
    80000f80:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f82:	4501                	li	a0,0
    80000f84:	bfe5                	j	80000f7c <strlen+0x20>

0000000080000f86 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f86:	1141                	addi	sp,sp,-16
    80000f88:	e406                	sd	ra,8(sp)
    80000f8a:	e022                	sd	s0,0(sp)
    80000f8c:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	b00080e7          	jalr	-1280(ra) # 80001a8e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f96:	00008717          	auipc	a4,0x8
    80000f9a:	a0a70713          	addi	a4,a4,-1526 # 800089a0 <started>
  if(cpuid() == 0){
    80000f9e:	c139                	beqz	a0,80000fe4 <main+0x5e>
    while(started == 0)
    80000fa0:	431c                	lw	a5,0(a4)
    80000fa2:	2781                	sext.w	a5,a5
    80000fa4:	dff5                	beqz	a5,80000fa0 <main+0x1a>
      ;
    __sync_synchronize();
    80000fa6:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000faa:	00001097          	auipc	ra,0x1
    80000fae:	ae4080e7          	jalr	-1308(ra) # 80001a8e <cpuid>
    80000fb2:	85aa                	mv	a1,a0
    80000fb4:	00007517          	auipc	a0,0x7
    80000fb8:	10450513          	addi	a0,a0,260 # 800080b8 <digits+0x78>
    80000fbc:	fffff097          	auipc	ra,0xfffff
    80000fc0:	6da080e7          	jalr	1754(ra) # 80000696 <printf>
    kvminithart();    // turn on paging
    80000fc4:	00000097          	auipc	ra,0x0
    80000fc8:	0d8080e7          	jalr	216(ra) # 8000109c <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fcc:	00002097          	auipc	ra,0x2
    80000fd0:	95a080e7          	jalr	-1702(ra) # 80002926 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fd4:	00005097          	auipc	ra,0x5
    80000fd8:	f6c080e7          	jalr	-148(ra) # 80005f40 <plicinithart>
  }

  scheduler();        
    80000fdc:	00001097          	auipc	ra,0x1
    80000fe0:	fd4080e7          	jalr	-44(ra) # 80001fb0 <scheduler>
    consoleinit();
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	57a080e7          	jalr	1402(ra) # 8000055e <consoleinit>
    printfinit();
    80000fec:	00000097          	auipc	ra,0x0
    80000ff0:	88a080e7          	jalr	-1910(ra) # 80000876 <printfinit>
    printf("\n");
    80000ff4:	00007517          	auipc	a0,0x7
    80000ff8:	33450513          	addi	a0,a0,820 # 80008328 <digits+0x2e8>
    80000ffc:	fffff097          	auipc	ra,0xfffff
    80001000:	69a080e7          	jalr	1690(ra) # 80000696 <printf>
    printf("xv6 kernel is booting\n");
    80001004:	00007517          	auipc	a0,0x7
    80001008:	09c50513          	addi	a0,a0,156 # 800080a0 <digits+0x60>
    8000100c:	fffff097          	auipc	ra,0xfffff
    80001010:	68a080e7          	jalr	1674(ra) # 80000696 <printf>
    printf("\n");
    80001014:	00007517          	auipc	a0,0x7
    80001018:	31450513          	addi	a0,a0,788 # 80008328 <digits+0x2e8>
    8000101c:	fffff097          	auipc	ra,0xfffff
    80001020:	67a080e7          	jalr	1658(ra) # 80000696 <printf>
    kinit();         // physical page allocator
    80001024:	00000097          	auipc	ra,0x0
    80001028:	b94080e7          	jalr	-1132(ra) # 80000bb8 <kinit>
    kvminit();       // create kernel page table
    8000102c:	00000097          	auipc	ra,0x0
    80001030:	326080e7          	jalr	806(ra) # 80001352 <kvminit>
    kvminithart();   // turn on paging
    80001034:	00000097          	auipc	ra,0x0
    80001038:	068080e7          	jalr	104(ra) # 8000109c <kvminithart>
    procinit();      // process table
    8000103c:	00001097          	auipc	ra,0x1
    80001040:	99e080e7          	jalr	-1634(ra) # 800019da <procinit>
    trapinit();      // trap vectors
    80001044:	00002097          	auipc	ra,0x2
    80001048:	8ba080e7          	jalr	-1862(ra) # 800028fe <trapinit>
    trapinithart();  // install kernel trap vector
    8000104c:	00002097          	auipc	ra,0x2
    80001050:	8da080e7          	jalr	-1830(ra) # 80002926 <trapinithart>
    plicinit();      // set up interrupt controller
    80001054:	00005097          	auipc	ra,0x5
    80001058:	ed6080e7          	jalr	-298(ra) # 80005f2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000105c:	00005097          	auipc	ra,0x5
    80001060:	ee4080e7          	jalr	-284(ra) # 80005f40 <plicinithart>
    binit();         // buffer cache
    80001064:	00002097          	auipc	ra,0x2
    80001068:	084080e7          	jalr	132(ra) # 800030e8 <binit>
    iinit();         // inode table
    8000106c:	00002097          	auipc	ra,0x2
    80001070:	728080e7          	jalr	1832(ra) # 80003794 <iinit>
    fileinit();      // file table
    80001074:	00003097          	auipc	ra,0x3
    80001078:	6c6080e7          	jalr	1734(ra) # 8000473a <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000107c:	00005097          	auipc	ra,0x5
    80001080:	fcc080e7          	jalr	-52(ra) # 80006048 <virtio_disk_init>
    userinit();      // first user process
    80001084:	00001097          	auipc	ra,0x1
    80001088:	d0e080e7          	jalr	-754(ra) # 80001d92 <userinit>
    __sync_synchronize();
    8000108c:	0ff0000f          	fence
    started = 1;
    80001090:	4785                	li	a5,1
    80001092:	00008717          	auipc	a4,0x8
    80001096:	90f72723          	sw	a5,-1778(a4) # 800089a0 <started>
    8000109a:	b789                	j	80000fdc <main+0x56>

000000008000109c <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000109c:	1141                	addi	sp,sp,-16
    8000109e:	e422                	sd	s0,8(sp)
    800010a0:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010a2:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010a6:	00008797          	auipc	a5,0x8
    800010aa:	9027b783          	ld	a5,-1790(a5) # 800089a8 <kernel_pagetable>
    800010ae:	83b1                	srli	a5,a5,0xc
    800010b0:	577d                	li	a4,-1
    800010b2:	177e                	slli	a4,a4,0x3f
    800010b4:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010b6:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010ba:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010be:	6422                	ld	s0,8(sp)
    800010c0:	0141                	addi	sp,sp,16
    800010c2:	8082                	ret

00000000800010c4 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010c4:	7139                	addi	sp,sp,-64
    800010c6:	fc06                	sd	ra,56(sp)
    800010c8:	f822                	sd	s0,48(sp)
    800010ca:	f426                	sd	s1,40(sp)
    800010cc:	f04a                	sd	s2,32(sp)
    800010ce:	ec4e                	sd	s3,24(sp)
    800010d0:	e852                	sd	s4,16(sp)
    800010d2:	e456                	sd	s5,8(sp)
    800010d4:	e05a                	sd	s6,0(sp)
    800010d6:	0080                	addi	s0,sp,64
    800010d8:	84aa                	mv	s1,a0
    800010da:	89ae                	mv	s3,a1
    800010dc:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010de:	57fd                	li	a5,-1
    800010e0:	83e9                	srli	a5,a5,0x1a
    800010e2:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010e4:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010e6:	04b7f263          	bgeu	a5,a1,8000112a <walk+0x66>
    panic("walk");
    800010ea:	00007517          	auipc	a0,0x7
    800010ee:	fe650513          	addi	a0,a0,-26 # 800080d0 <digits+0x90>
    800010f2:	fffff097          	auipc	ra,0xfffff
    800010f6:	55a080e7          	jalr	1370(ra) # 8000064c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010fa:	060a8663          	beqz	s5,80001166 <walk+0xa2>
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	af6080e7          	jalr	-1290(ra) # 80000bf4 <kalloc>
    80001106:	84aa                	mv	s1,a0
    80001108:	c529                	beqz	a0,80001152 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000110a:	6605                	lui	a2,0x1
    8000110c:	4581                	li	a1,0
    8000110e:	00000097          	auipc	ra,0x0
    80001112:	cd2080e7          	jalr	-814(ra) # 80000de0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001116:	00c4d793          	srli	a5,s1,0xc
    8000111a:	07aa                	slli	a5,a5,0xa
    8000111c:	0017e793          	ori	a5,a5,1
    80001120:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001124:	3a5d                	addiw	s4,s4,-9
    80001126:	036a0063          	beq	s4,s6,80001146 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000112a:	0149d933          	srl	s2,s3,s4
    8000112e:	1ff97913          	andi	s2,s2,511
    80001132:	090e                	slli	s2,s2,0x3
    80001134:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001136:	00093483          	ld	s1,0(s2)
    8000113a:	0014f793          	andi	a5,s1,1
    8000113e:	dfd5                	beqz	a5,800010fa <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001140:	80a9                	srli	s1,s1,0xa
    80001142:	04b2                	slli	s1,s1,0xc
    80001144:	b7c5                	j	80001124 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001146:	00c9d513          	srli	a0,s3,0xc
    8000114a:	1ff57513          	andi	a0,a0,511
    8000114e:	050e                	slli	a0,a0,0x3
    80001150:	9526                	add	a0,a0,s1
}
    80001152:	70e2                	ld	ra,56(sp)
    80001154:	7442                	ld	s0,48(sp)
    80001156:	74a2                	ld	s1,40(sp)
    80001158:	7902                	ld	s2,32(sp)
    8000115a:	69e2                	ld	s3,24(sp)
    8000115c:	6a42                	ld	s4,16(sp)
    8000115e:	6aa2                	ld	s5,8(sp)
    80001160:	6b02                	ld	s6,0(sp)
    80001162:	6121                	addi	sp,sp,64
    80001164:	8082                	ret
        return 0;
    80001166:	4501                	li	a0,0
    80001168:	b7ed                	j	80001152 <walk+0x8e>

000000008000116a <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000116a:	57fd                	li	a5,-1
    8000116c:	83e9                	srli	a5,a5,0x1a
    8000116e:	00b7f463          	bgeu	a5,a1,80001176 <walkaddr+0xc>
    return 0;
    80001172:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001174:	8082                	ret
{
    80001176:	1141                	addi	sp,sp,-16
    80001178:	e406                	sd	ra,8(sp)
    8000117a:	e022                	sd	s0,0(sp)
    8000117c:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000117e:	4601                	li	a2,0
    80001180:	00000097          	auipc	ra,0x0
    80001184:	f44080e7          	jalr	-188(ra) # 800010c4 <walk>
  if(pte == 0)
    80001188:	c105                	beqz	a0,800011a8 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000118a:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000118c:	0117f693          	andi	a3,a5,17
    80001190:	4745                	li	a4,17
    return 0;
    80001192:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001194:	00e68663          	beq	a3,a4,800011a0 <walkaddr+0x36>
}
    80001198:	60a2                	ld	ra,8(sp)
    8000119a:	6402                	ld	s0,0(sp)
    8000119c:	0141                	addi	sp,sp,16
    8000119e:	8082                	ret
  pa = PTE2PA(*pte);
    800011a0:	00a7d513          	srli	a0,a5,0xa
    800011a4:	0532                	slli	a0,a0,0xc
  return pa;
    800011a6:	bfcd                	j	80001198 <walkaddr+0x2e>
    return 0;
    800011a8:	4501                	li	a0,0
    800011aa:	b7fd                	j	80001198 <walkaddr+0x2e>

00000000800011ac <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011ac:	715d                	addi	sp,sp,-80
    800011ae:	e486                	sd	ra,72(sp)
    800011b0:	e0a2                	sd	s0,64(sp)
    800011b2:	fc26                	sd	s1,56(sp)
    800011b4:	f84a                	sd	s2,48(sp)
    800011b6:	f44e                	sd	s3,40(sp)
    800011b8:	f052                	sd	s4,32(sp)
    800011ba:	ec56                	sd	s5,24(sp)
    800011bc:	e85a                	sd	s6,16(sp)
    800011be:	e45e                	sd	s7,8(sp)
    800011c0:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011c2:	c639                	beqz	a2,80001210 <mappages+0x64>
    800011c4:	8aaa                	mv	s5,a0
    800011c6:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011c8:	77fd                	lui	a5,0xfffff
    800011ca:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011ce:	15fd                	addi	a1,a1,-1
    800011d0:	00c589b3          	add	s3,a1,a2
    800011d4:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800011d8:	8952                	mv	s2,s4
    800011da:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011de:	6b85                	lui	s7,0x1
    800011e0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e4:	4605                	li	a2,1
    800011e6:	85ca                	mv	a1,s2
    800011e8:	8556                	mv	a0,s5
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	eda080e7          	jalr	-294(ra) # 800010c4 <walk>
    800011f2:	cd1d                	beqz	a0,80001230 <mappages+0x84>
    if(*pte & PTE_V)
    800011f4:	611c                	ld	a5,0(a0)
    800011f6:	8b85                	andi	a5,a5,1
    800011f8:	e785                	bnez	a5,80001220 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011fa:	80b1                	srli	s1,s1,0xc
    800011fc:	04aa                	slli	s1,s1,0xa
    800011fe:	0164e4b3          	or	s1,s1,s6
    80001202:	0014e493          	ori	s1,s1,1
    80001206:	e104                	sd	s1,0(a0)
    if(a == last)
    80001208:	05390063          	beq	s2,s3,80001248 <mappages+0x9c>
    a += PGSIZE;
    8000120c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000120e:	bfc9                	j	800011e0 <mappages+0x34>
    panic("mappages: size");
    80001210:	00007517          	auipc	a0,0x7
    80001214:	ec850513          	addi	a0,a0,-312 # 800080d8 <digits+0x98>
    80001218:	fffff097          	auipc	ra,0xfffff
    8000121c:	434080e7          	jalr	1076(ra) # 8000064c <panic>
      panic("mappages: remap");
    80001220:	00007517          	auipc	a0,0x7
    80001224:	ec850513          	addi	a0,a0,-312 # 800080e8 <digits+0xa8>
    80001228:	fffff097          	auipc	ra,0xfffff
    8000122c:	424080e7          	jalr	1060(ra) # 8000064c <panic>
      return -1;
    80001230:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001232:	60a6                	ld	ra,72(sp)
    80001234:	6406                	ld	s0,64(sp)
    80001236:	74e2                	ld	s1,56(sp)
    80001238:	7942                	ld	s2,48(sp)
    8000123a:	79a2                	ld	s3,40(sp)
    8000123c:	7a02                	ld	s4,32(sp)
    8000123e:	6ae2                	ld	s5,24(sp)
    80001240:	6b42                	ld	s6,16(sp)
    80001242:	6ba2                	ld	s7,8(sp)
    80001244:	6161                	addi	sp,sp,80
    80001246:	8082                	ret
  return 0;
    80001248:	4501                	li	a0,0
    8000124a:	b7e5                	j	80001232 <mappages+0x86>

000000008000124c <kvmmap>:
{
    8000124c:	1141                	addi	sp,sp,-16
    8000124e:	e406                	sd	ra,8(sp)
    80001250:	e022                	sd	s0,0(sp)
    80001252:	0800                	addi	s0,sp,16
    80001254:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001256:	86b2                	mv	a3,a2
    80001258:	863e                	mv	a2,a5
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f52080e7          	jalr	-174(ra) # 800011ac <mappages>
    80001262:	e509                	bnez	a0,8000126c <kvmmap+0x20>
}
    80001264:	60a2                	ld	ra,8(sp)
    80001266:	6402                	ld	s0,0(sp)
    80001268:	0141                	addi	sp,sp,16
    8000126a:	8082                	ret
    panic("kvmmap");
    8000126c:	00007517          	auipc	a0,0x7
    80001270:	e8c50513          	addi	a0,a0,-372 # 800080f8 <digits+0xb8>
    80001274:	fffff097          	auipc	ra,0xfffff
    80001278:	3d8080e7          	jalr	984(ra) # 8000064c <panic>

000000008000127c <kvmmake>:
{
    8000127c:	1101                	addi	sp,sp,-32
    8000127e:	ec06                	sd	ra,24(sp)
    80001280:	e822                	sd	s0,16(sp)
    80001282:	e426                	sd	s1,8(sp)
    80001284:	e04a                	sd	s2,0(sp)
    80001286:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	96c080e7          	jalr	-1684(ra) # 80000bf4 <kalloc>
    80001290:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001292:	6605                	lui	a2,0x1
    80001294:	4581                	li	a1,0
    80001296:	00000097          	auipc	ra,0x0
    8000129a:	b4a080e7          	jalr	-1206(ra) # 80000de0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000129e:	4719                	li	a4,6
    800012a0:	6685                	lui	a3,0x1
    800012a2:	10000637          	lui	a2,0x10000
    800012a6:	100005b7          	lui	a1,0x10000
    800012aa:	8526                	mv	a0,s1
    800012ac:	00000097          	auipc	ra,0x0
    800012b0:	fa0080e7          	jalr	-96(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012b4:	4719                	li	a4,6
    800012b6:	6685                	lui	a3,0x1
    800012b8:	10001637          	lui	a2,0x10001
    800012bc:	100015b7          	lui	a1,0x10001
    800012c0:	8526                	mv	a0,s1
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	f8a080e7          	jalr	-118(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ca:	4719                	li	a4,6
    800012cc:	004006b7          	lui	a3,0x400
    800012d0:	0c000637          	lui	a2,0xc000
    800012d4:	0c0005b7          	lui	a1,0xc000
    800012d8:	8526                	mv	a0,s1
    800012da:	00000097          	auipc	ra,0x0
    800012de:	f72080e7          	jalr	-142(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012e2:	00007917          	auipc	s2,0x7
    800012e6:	d1e90913          	addi	s2,s2,-738 # 80008000 <etext>
    800012ea:	4729                	li	a4,10
    800012ec:	80007697          	auipc	a3,0x80007
    800012f0:	d1468693          	addi	a3,a3,-748 # 8000 <_entry-0x7fff8000>
    800012f4:	4605                	li	a2,1
    800012f6:	067e                	slli	a2,a2,0x1f
    800012f8:	85b2                	mv	a1,a2
    800012fa:	8526                	mv	a0,s1
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	f50080e7          	jalr	-176(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001304:	4719                	li	a4,6
    80001306:	46c5                	li	a3,17
    80001308:	06ee                	slli	a3,a3,0x1b
    8000130a:	412686b3          	sub	a3,a3,s2
    8000130e:	864a                	mv	a2,s2
    80001310:	85ca                	mv	a1,s2
    80001312:	8526                	mv	a0,s1
    80001314:	00000097          	auipc	ra,0x0
    80001318:	f38080e7          	jalr	-200(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000131c:	4729                	li	a4,10
    8000131e:	6685                	lui	a3,0x1
    80001320:	00006617          	auipc	a2,0x6
    80001324:	ce060613          	addi	a2,a2,-800 # 80007000 <_trampoline>
    80001328:	040005b7          	lui	a1,0x4000
    8000132c:	15fd                	addi	a1,a1,-1
    8000132e:	05b2                	slli	a1,a1,0xc
    80001330:	8526                	mv	a0,s1
    80001332:	00000097          	auipc	ra,0x0
    80001336:	f1a080e7          	jalr	-230(ra) # 8000124c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000133a:	8526                	mv	a0,s1
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	608080e7          	jalr	1544(ra) # 80001944 <proc_mapstacks>
}
    80001344:	8526                	mv	a0,s1
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6902                	ld	s2,0(sp)
    8000134e:	6105                	addi	sp,sp,32
    80001350:	8082                	ret

0000000080001352 <kvminit>:
{
    80001352:	1141                	addi	sp,sp,-16
    80001354:	e406                	sd	ra,8(sp)
    80001356:	e022                	sd	s0,0(sp)
    80001358:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	f22080e7          	jalr	-222(ra) # 8000127c <kvmmake>
    80001362:	00007797          	auipc	a5,0x7
    80001366:	64a7b323          	sd	a0,1606(a5) # 800089a8 <kernel_pagetable>
}
    8000136a:	60a2                	ld	ra,8(sp)
    8000136c:	6402                	ld	s0,0(sp)
    8000136e:	0141                	addi	sp,sp,16
    80001370:	8082                	ret

0000000080001372 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001372:	715d                	addi	sp,sp,-80
    80001374:	e486                	sd	ra,72(sp)
    80001376:	e0a2                	sd	s0,64(sp)
    80001378:	fc26                	sd	s1,56(sp)
    8000137a:	f84a                	sd	s2,48(sp)
    8000137c:	f44e                	sd	s3,40(sp)
    8000137e:	f052                	sd	s4,32(sp)
    80001380:	ec56                	sd	s5,24(sp)
    80001382:	e85a                	sd	s6,16(sp)
    80001384:	e45e                	sd	s7,8(sp)
    80001386:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001388:	03459793          	slli	a5,a1,0x34
    8000138c:	e795                	bnez	a5,800013b8 <uvmunmap+0x46>
    8000138e:	8a2a                	mv	s4,a0
    80001390:	892e                	mv	s2,a1
    80001392:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001394:	0632                	slli	a2,a2,0xc
    80001396:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000139a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000139c:	6b05                	lui	s6,0x1
    8000139e:	0735e263          	bltu	a1,s3,80001402 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013a2:	60a6                	ld	ra,72(sp)
    800013a4:	6406                	ld	s0,64(sp)
    800013a6:	74e2                	ld	s1,56(sp)
    800013a8:	7942                	ld	s2,48(sp)
    800013aa:	79a2                	ld	s3,40(sp)
    800013ac:	7a02                	ld	s4,32(sp)
    800013ae:	6ae2                	ld	s5,24(sp)
    800013b0:	6b42                	ld	s6,16(sp)
    800013b2:	6ba2                	ld	s7,8(sp)
    800013b4:	6161                	addi	sp,sp,80
    800013b6:	8082                	ret
    panic("uvmunmap: not aligned");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	d4850513          	addi	a0,a0,-696 # 80008100 <digits+0xc0>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	28c080e7          	jalr	652(ra) # 8000064c <panic>
      panic("uvmunmap: walk");
    800013c8:	00007517          	auipc	a0,0x7
    800013cc:	d5050513          	addi	a0,a0,-688 # 80008118 <digits+0xd8>
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	27c080e7          	jalr	636(ra) # 8000064c <panic>
      panic("uvmunmap: not mapped");
    800013d8:	00007517          	auipc	a0,0x7
    800013dc:	d5050513          	addi	a0,a0,-688 # 80008128 <digits+0xe8>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	26c080e7          	jalr	620(ra) # 8000064c <panic>
      panic("uvmunmap: not a leaf");
    800013e8:	00007517          	auipc	a0,0x7
    800013ec:	d5850513          	addi	a0,a0,-680 # 80008140 <digits+0x100>
    800013f0:	fffff097          	auipc	ra,0xfffff
    800013f4:	25c080e7          	jalr	604(ra) # 8000064c <panic>
    *pte = 0;
    800013f8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013fc:	995a                	add	s2,s2,s6
    800013fe:	fb3972e3          	bgeu	s2,s3,800013a2 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001402:	4601                	li	a2,0
    80001404:	85ca                	mv	a1,s2
    80001406:	8552                	mv	a0,s4
    80001408:	00000097          	auipc	ra,0x0
    8000140c:	cbc080e7          	jalr	-836(ra) # 800010c4 <walk>
    80001410:	84aa                	mv	s1,a0
    80001412:	d95d                	beqz	a0,800013c8 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001414:	6108                	ld	a0,0(a0)
    80001416:	00157793          	andi	a5,a0,1
    8000141a:	dfdd                	beqz	a5,800013d8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000141c:	3ff57793          	andi	a5,a0,1023
    80001420:	fd7784e3          	beq	a5,s7,800013e8 <uvmunmap+0x76>
    if(do_free){
    80001424:	fc0a8ae3          	beqz	s5,800013f8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001428:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000142a:	0532                	slli	a0,a0,0xc
    8000142c:	fffff097          	auipc	ra,0xfffff
    80001430:	6cc080e7          	jalr	1740(ra) # 80000af8 <kfree>
    80001434:	b7d1                	j	800013f8 <uvmunmap+0x86>

0000000080001436 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001436:	1101                	addi	sp,sp,-32
    80001438:	ec06                	sd	ra,24(sp)
    8000143a:	e822                	sd	s0,16(sp)
    8000143c:	e426                	sd	s1,8(sp)
    8000143e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001440:	fffff097          	auipc	ra,0xfffff
    80001444:	7b4080e7          	jalr	1972(ra) # 80000bf4 <kalloc>
    80001448:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000144a:	c519                	beqz	a0,80001458 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000144c:	6605                	lui	a2,0x1
    8000144e:	4581                	li	a1,0
    80001450:	00000097          	auipc	ra,0x0
    80001454:	990080e7          	jalr	-1648(ra) # 80000de0 <memset>
  return pagetable;
}
    80001458:	8526                	mv	a0,s1
    8000145a:	60e2                	ld	ra,24(sp)
    8000145c:	6442                	ld	s0,16(sp)
    8000145e:	64a2                	ld	s1,8(sp)
    80001460:	6105                	addi	sp,sp,32
    80001462:	8082                	ret

0000000080001464 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001464:	7179                	addi	sp,sp,-48
    80001466:	f406                	sd	ra,40(sp)
    80001468:	f022                	sd	s0,32(sp)
    8000146a:	ec26                	sd	s1,24(sp)
    8000146c:	e84a                	sd	s2,16(sp)
    8000146e:	e44e                	sd	s3,8(sp)
    80001470:	e052                	sd	s4,0(sp)
    80001472:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001474:	6785                	lui	a5,0x1
    80001476:	04f67863          	bgeu	a2,a5,800014c6 <uvmfirst+0x62>
    8000147a:	8a2a                	mv	s4,a0
    8000147c:	89ae                	mv	s3,a1
    8000147e:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	774080e7          	jalr	1908(ra) # 80000bf4 <kalloc>
    80001488:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000148a:	6605                	lui	a2,0x1
    8000148c:	4581                	li	a1,0
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	952080e7          	jalr	-1710(ra) # 80000de0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001496:	4779                	li	a4,30
    80001498:	86ca                	mv	a3,s2
    8000149a:	6605                	lui	a2,0x1
    8000149c:	4581                	li	a1,0
    8000149e:	8552                	mv	a0,s4
    800014a0:	00000097          	auipc	ra,0x0
    800014a4:	d0c080e7          	jalr	-756(ra) # 800011ac <mappages>
  memmove(mem, src, sz);
    800014a8:	8626                	mv	a2,s1
    800014aa:	85ce                	mv	a1,s3
    800014ac:	854a                	mv	a0,s2
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	98e080e7          	jalr	-1650(ra) # 80000e3c <memmove>
}
    800014b6:	70a2                	ld	ra,40(sp)
    800014b8:	7402                	ld	s0,32(sp)
    800014ba:	64e2                	ld	s1,24(sp)
    800014bc:	6942                	ld	s2,16(sp)
    800014be:	69a2                	ld	s3,8(sp)
    800014c0:	6a02                	ld	s4,0(sp)
    800014c2:	6145                	addi	sp,sp,48
    800014c4:	8082                	ret
    panic("uvmfirst: more than a page");
    800014c6:	00007517          	auipc	a0,0x7
    800014ca:	c9250513          	addi	a0,a0,-878 # 80008158 <digits+0x118>
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	17e080e7          	jalr	382(ra) # 8000064c <panic>

00000000800014d6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014d6:	1101                	addi	sp,sp,-32
    800014d8:	ec06                	sd	ra,24(sp)
    800014da:	e822                	sd	s0,16(sp)
    800014dc:	e426                	sd	s1,8(sp)
    800014de:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014e0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014e2:	00b67d63          	bgeu	a2,a1,800014fc <uvmdealloc+0x26>
    800014e6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014e8:	6785                	lui	a5,0x1
    800014ea:	17fd                	addi	a5,a5,-1
    800014ec:	00f60733          	add	a4,a2,a5
    800014f0:	767d                	lui	a2,0xfffff
    800014f2:	8f71                	and	a4,a4,a2
    800014f4:	97ae                	add	a5,a5,a1
    800014f6:	8ff1                	and	a5,a5,a2
    800014f8:	00f76863          	bltu	a4,a5,80001508 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014fc:	8526                	mv	a0,s1
    800014fe:	60e2                	ld	ra,24(sp)
    80001500:	6442                	ld	s0,16(sp)
    80001502:	64a2                	ld	s1,8(sp)
    80001504:	6105                	addi	sp,sp,32
    80001506:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001508:	8f99                	sub	a5,a5,a4
    8000150a:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000150c:	4685                	li	a3,1
    8000150e:	0007861b          	sext.w	a2,a5
    80001512:	85ba                	mv	a1,a4
    80001514:	00000097          	auipc	ra,0x0
    80001518:	e5e080e7          	jalr	-418(ra) # 80001372 <uvmunmap>
    8000151c:	b7c5                	j	800014fc <uvmdealloc+0x26>

000000008000151e <uvmalloc>:
  if(newsz < oldsz)
    8000151e:	0ab66563          	bltu	a2,a1,800015c8 <uvmalloc+0xaa>
{
    80001522:	7139                	addi	sp,sp,-64
    80001524:	fc06                	sd	ra,56(sp)
    80001526:	f822                	sd	s0,48(sp)
    80001528:	f426                	sd	s1,40(sp)
    8000152a:	f04a                	sd	s2,32(sp)
    8000152c:	ec4e                	sd	s3,24(sp)
    8000152e:	e852                	sd	s4,16(sp)
    80001530:	e456                	sd	s5,8(sp)
    80001532:	e05a                	sd	s6,0(sp)
    80001534:	0080                	addi	s0,sp,64
    80001536:	8aaa                	mv	s5,a0
    80001538:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000153a:	6985                	lui	s3,0x1
    8000153c:	19fd                	addi	s3,s3,-1
    8000153e:	95ce                	add	a1,a1,s3
    80001540:	79fd                	lui	s3,0xfffff
    80001542:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001546:	08c9f363          	bgeu	s3,a2,800015cc <uvmalloc+0xae>
    8000154a:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000154c:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001550:	fffff097          	auipc	ra,0xfffff
    80001554:	6a4080e7          	jalr	1700(ra) # 80000bf4 <kalloc>
    80001558:	84aa                	mv	s1,a0
    if(mem == 0){
    8000155a:	c51d                	beqz	a0,80001588 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000155c:	6605                	lui	a2,0x1
    8000155e:	4581                	li	a1,0
    80001560:	00000097          	auipc	ra,0x0
    80001564:	880080e7          	jalr	-1920(ra) # 80000de0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001568:	875a                	mv	a4,s6
    8000156a:	86a6                	mv	a3,s1
    8000156c:	6605                	lui	a2,0x1
    8000156e:	85ca                	mv	a1,s2
    80001570:	8556                	mv	a0,s5
    80001572:	00000097          	auipc	ra,0x0
    80001576:	c3a080e7          	jalr	-966(ra) # 800011ac <mappages>
    8000157a:	e90d                	bnez	a0,800015ac <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000157c:	6785                	lui	a5,0x1
    8000157e:	993e                	add	s2,s2,a5
    80001580:	fd4968e3          	bltu	s2,s4,80001550 <uvmalloc+0x32>
  return newsz;
    80001584:	8552                	mv	a0,s4
    80001586:	a809                	j	80001598 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001588:	864e                	mv	a2,s3
    8000158a:	85ca                	mv	a1,s2
    8000158c:	8556                	mv	a0,s5
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	f48080e7          	jalr	-184(ra) # 800014d6 <uvmdealloc>
      return 0;
    80001596:	4501                	li	a0,0
}
    80001598:	70e2                	ld	ra,56(sp)
    8000159a:	7442                	ld	s0,48(sp)
    8000159c:	74a2                	ld	s1,40(sp)
    8000159e:	7902                	ld	s2,32(sp)
    800015a0:	69e2                	ld	s3,24(sp)
    800015a2:	6a42                	ld	s4,16(sp)
    800015a4:	6aa2                	ld	s5,8(sp)
    800015a6:	6b02                	ld	s6,0(sp)
    800015a8:	6121                	addi	sp,sp,64
    800015aa:	8082                	ret
      kfree(mem);
    800015ac:	8526                	mv	a0,s1
    800015ae:	fffff097          	auipc	ra,0xfffff
    800015b2:	54a080e7          	jalr	1354(ra) # 80000af8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015b6:	864e                	mv	a2,s3
    800015b8:	85ca                	mv	a1,s2
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	f1a080e7          	jalr	-230(ra) # 800014d6 <uvmdealloc>
      return 0;
    800015c4:	4501                	li	a0,0
    800015c6:	bfc9                	j	80001598 <uvmalloc+0x7a>
    return oldsz;
    800015c8:	852e                	mv	a0,a1
}
    800015ca:	8082                	ret
  return newsz;
    800015cc:	8532                	mv	a0,a2
    800015ce:	b7e9                	j	80001598 <uvmalloc+0x7a>

00000000800015d0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015d0:	7179                	addi	sp,sp,-48
    800015d2:	f406                	sd	ra,40(sp)
    800015d4:	f022                	sd	s0,32(sp)
    800015d6:	ec26                	sd	s1,24(sp)
    800015d8:	e84a                	sd	s2,16(sp)
    800015da:	e44e                	sd	s3,8(sp)
    800015dc:	e052                	sd	s4,0(sp)
    800015de:	1800                	addi	s0,sp,48
    800015e0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015e2:	84aa                	mv	s1,a0
    800015e4:	6905                	lui	s2,0x1
    800015e6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015e8:	4985                	li	s3,1
    800015ea:	a821                	j	80001602 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015ec:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015ee:	0532                	slli	a0,a0,0xc
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	fe0080e7          	jalr	-32(ra) # 800015d0 <freewalk>
      pagetable[i] = 0;
    800015f8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015fc:	04a1                	addi	s1,s1,8
    800015fe:	03248163          	beq	s1,s2,80001620 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001602:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001604:	00f57793          	andi	a5,a0,15
    80001608:	ff3782e3          	beq	a5,s3,800015ec <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000160c:	8905                	andi	a0,a0,1
    8000160e:	d57d                	beqz	a0,800015fc <freewalk+0x2c>
      panic("freewalk: leaf");
    80001610:	00007517          	auipc	a0,0x7
    80001614:	b6850513          	addi	a0,a0,-1176 # 80008178 <digits+0x138>
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	034080e7          	jalr	52(ra) # 8000064c <panic>
    }
  }
  kfree((void*)pagetable);
    80001620:	8552                	mv	a0,s4
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	4d6080e7          	jalr	1238(ra) # 80000af8 <kfree>
}
    8000162a:	70a2                	ld	ra,40(sp)
    8000162c:	7402                	ld	s0,32(sp)
    8000162e:	64e2                	ld	s1,24(sp)
    80001630:	6942                	ld	s2,16(sp)
    80001632:	69a2                	ld	s3,8(sp)
    80001634:	6a02                	ld	s4,0(sp)
    80001636:	6145                	addi	sp,sp,48
    80001638:	8082                	ret

000000008000163a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000163a:	1101                	addi	sp,sp,-32
    8000163c:	ec06                	sd	ra,24(sp)
    8000163e:	e822                	sd	s0,16(sp)
    80001640:	e426                	sd	s1,8(sp)
    80001642:	1000                	addi	s0,sp,32
    80001644:	84aa                	mv	s1,a0
  if(sz > 0)
    80001646:	e999                	bnez	a1,8000165c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001648:	8526                	mv	a0,s1
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	f86080e7          	jalr	-122(ra) # 800015d0 <freewalk>
}
    80001652:	60e2                	ld	ra,24(sp)
    80001654:	6442                	ld	s0,16(sp)
    80001656:	64a2                	ld	s1,8(sp)
    80001658:	6105                	addi	sp,sp,32
    8000165a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000165c:	6605                	lui	a2,0x1
    8000165e:	167d                	addi	a2,a2,-1
    80001660:	962e                	add	a2,a2,a1
    80001662:	4685                	li	a3,1
    80001664:	8231                	srli	a2,a2,0xc
    80001666:	4581                	li	a1,0
    80001668:	00000097          	auipc	ra,0x0
    8000166c:	d0a080e7          	jalr	-758(ra) # 80001372 <uvmunmap>
    80001670:	bfe1                	j	80001648 <uvmfree+0xe>

0000000080001672 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001672:	c679                	beqz	a2,80001740 <uvmcopy+0xce>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	0880                	addi	s0,sp,80
    8000168a:	8b2a                	mv	s6,a0
    8000168c:	8aae                	mv	s5,a1
    8000168e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001690:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001692:	4601                	li	a2,0
    80001694:	85ce                	mv	a1,s3
    80001696:	855a                	mv	a0,s6
    80001698:	00000097          	auipc	ra,0x0
    8000169c:	a2c080e7          	jalr	-1492(ra) # 800010c4 <walk>
    800016a0:	c531                	beqz	a0,800016ec <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016a2:	6118                	ld	a4,0(a0)
    800016a4:	00177793          	andi	a5,a4,1
    800016a8:	cbb1                	beqz	a5,800016fc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016aa:	00a75593          	srli	a1,a4,0xa
    800016ae:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016b2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016b6:	fffff097          	auipc	ra,0xfffff
    800016ba:	53e080e7          	jalr	1342(ra) # 80000bf4 <kalloc>
    800016be:	892a                	mv	s2,a0
    800016c0:	c939                	beqz	a0,80001716 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016c2:	6605                	lui	a2,0x1
    800016c4:	85de                	mv	a1,s7
    800016c6:	fffff097          	auipc	ra,0xfffff
    800016ca:	776080e7          	jalr	1910(ra) # 80000e3c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016ce:	8726                	mv	a4,s1
    800016d0:	86ca                	mv	a3,s2
    800016d2:	6605                	lui	a2,0x1
    800016d4:	85ce                	mv	a1,s3
    800016d6:	8556                	mv	a0,s5
    800016d8:	00000097          	auipc	ra,0x0
    800016dc:	ad4080e7          	jalr	-1324(ra) # 800011ac <mappages>
    800016e0:	e515                	bnez	a0,8000170c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016e2:	6785                	lui	a5,0x1
    800016e4:	99be                	add	s3,s3,a5
    800016e6:	fb49e6e3          	bltu	s3,s4,80001692 <uvmcopy+0x20>
    800016ea:	a081                	j	8000172a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016ec:	00007517          	auipc	a0,0x7
    800016f0:	a9c50513          	addi	a0,a0,-1380 # 80008188 <digits+0x148>
    800016f4:	fffff097          	auipc	ra,0xfffff
    800016f8:	f58080e7          	jalr	-168(ra) # 8000064c <panic>
      panic("uvmcopy: page not present");
    800016fc:	00007517          	auipc	a0,0x7
    80001700:	aac50513          	addi	a0,a0,-1364 # 800081a8 <digits+0x168>
    80001704:	fffff097          	auipc	ra,0xfffff
    80001708:	f48080e7          	jalr	-184(ra) # 8000064c <panic>
      kfree(mem);
    8000170c:	854a                	mv	a0,s2
    8000170e:	fffff097          	auipc	ra,0xfffff
    80001712:	3ea080e7          	jalr	1002(ra) # 80000af8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001716:	4685                	li	a3,1
    80001718:	00c9d613          	srli	a2,s3,0xc
    8000171c:	4581                	li	a1,0
    8000171e:	8556                	mv	a0,s5
    80001720:	00000097          	auipc	ra,0x0
    80001724:	c52080e7          	jalr	-942(ra) # 80001372 <uvmunmap>
  return -1;
    80001728:	557d                	li	a0,-1
}
    8000172a:	60a6                	ld	ra,72(sp)
    8000172c:	6406                	ld	s0,64(sp)
    8000172e:	74e2                	ld	s1,56(sp)
    80001730:	7942                	ld	s2,48(sp)
    80001732:	79a2                	ld	s3,40(sp)
    80001734:	7a02                	ld	s4,32(sp)
    80001736:	6ae2                	ld	s5,24(sp)
    80001738:	6b42                	ld	s6,16(sp)
    8000173a:	6ba2                	ld	s7,8(sp)
    8000173c:	6161                	addi	sp,sp,80
    8000173e:	8082                	ret
  return 0;
    80001740:	4501                	li	a0,0
}
    80001742:	8082                	ret

0000000080001744 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001744:	1141                	addi	sp,sp,-16
    80001746:	e406                	sd	ra,8(sp)
    80001748:	e022                	sd	s0,0(sp)
    8000174a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000174c:	4601                	li	a2,0
    8000174e:	00000097          	auipc	ra,0x0
    80001752:	976080e7          	jalr	-1674(ra) # 800010c4 <walk>
  if(pte == 0)
    80001756:	c901                	beqz	a0,80001766 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001758:	611c                	ld	a5,0(a0)
    8000175a:	9bbd                	andi	a5,a5,-17
    8000175c:	e11c                	sd	a5,0(a0)
}
    8000175e:	60a2                	ld	ra,8(sp)
    80001760:	6402                	ld	s0,0(sp)
    80001762:	0141                	addi	sp,sp,16
    80001764:	8082                	ret
    panic("uvmclear");
    80001766:	00007517          	auipc	a0,0x7
    8000176a:	a6250513          	addi	a0,a0,-1438 # 800081c8 <digits+0x188>
    8000176e:	fffff097          	auipc	ra,0xfffff
    80001772:	ede080e7          	jalr	-290(ra) # 8000064c <panic>

0000000080001776 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001776:	c6bd                	beqz	a3,800017e4 <copyout+0x6e>
{
    80001778:	715d                	addi	sp,sp,-80
    8000177a:	e486                	sd	ra,72(sp)
    8000177c:	e0a2                	sd	s0,64(sp)
    8000177e:	fc26                	sd	s1,56(sp)
    80001780:	f84a                	sd	s2,48(sp)
    80001782:	f44e                	sd	s3,40(sp)
    80001784:	f052                	sd	s4,32(sp)
    80001786:	ec56                	sd	s5,24(sp)
    80001788:	e85a                	sd	s6,16(sp)
    8000178a:	e45e                	sd	s7,8(sp)
    8000178c:	e062                	sd	s8,0(sp)
    8000178e:	0880                	addi	s0,sp,80
    80001790:	8b2a                	mv	s6,a0
    80001792:	8c2e                	mv	s8,a1
    80001794:	8a32                	mv	s4,a2
    80001796:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001798:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000179a:	6a85                	lui	s5,0x1
    8000179c:	a015                	j	800017c0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000179e:	9562                	add	a0,a0,s8
    800017a0:	0004861b          	sext.w	a2,s1
    800017a4:	85d2                	mv	a1,s4
    800017a6:	41250533          	sub	a0,a0,s2
    800017aa:	fffff097          	auipc	ra,0xfffff
    800017ae:	692080e7          	jalr	1682(ra) # 80000e3c <memmove>

    len -= n;
    800017b2:	409989b3          	sub	s3,s3,s1
    src += n;
    800017b6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017b8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017bc:	02098263          	beqz	s3,800017e0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017c0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017c4:	85ca                	mv	a1,s2
    800017c6:	855a                	mv	a0,s6
    800017c8:	00000097          	auipc	ra,0x0
    800017cc:	9a2080e7          	jalr	-1630(ra) # 8000116a <walkaddr>
    if(pa0 == 0)
    800017d0:	cd01                	beqz	a0,800017e8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017d2:	418904b3          	sub	s1,s2,s8
    800017d6:	94d6                	add	s1,s1,s5
    if(n > len)
    800017d8:	fc99f3e3          	bgeu	s3,s1,8000179e <copyout+0x28>
    800017dc:	84ce                	mv	s1,s3
    800017de:	b7c1                	j	8000179e <copyout+0x28>
  }
  return 0;
    800017e0:	4501                	li	a0,0
    800017e2:	a021                	j	800017ea <copyout+0x74>
    800017e4:	4501                	li	a0,0
}
    800017e6:	8082                	ret
      return -1;
    800017e8:	557d                	li	a0,-1
}
    800017ea:	60a6                	ld	ra,72(sp)
    800017ec:	6406                	ld	s0,64(sp)
    800017ee:	74e2                	ld	s1,56(sp)
    800017f0:	7942                	ld	s2,48(sp)
    800017f2:	79a2                	ld	s3,40(sp)
    800017f4:	7a02                	ld	s4,32(sp)
    800017f6:	6ae2                	ld	s5,24(sp)
    800017f8:	6b42                	ld	s6,16(sp)
    800017fa:	6ba2                	ld	s7,8(sp)
    800017fc:	6c02                	ld	s8,0(sp)
    800017fe:	6161                	addi	sp,sp,80
    80001800:	8082                	ret

0000000080001802 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001802:	caa5                	beqz	a3,80001872 <copyin+0x70>
{
    80001804:	715d                	addi	sp,sp,-80
    80001806:	e486                	sd	ra,72(sp)
    80001808:	e0a2                	sd	s0,64(sp)
    8000180a:	fc26                	sd	s1,56(sp)
    8000180c:	f84a                	sd	s2,48(sp)
    8000180e:	f44e                	sd	s3,40(sp)
    80001810:	f052                	sd	s4,32(sp)
    80001812:	ec56                	sd	s5,24(sp)
    80001814:	e85a                	sd	s6,16(sp)
    80001816:	e45e                	sd	s7,8(sp)
    80001818:	e062                	sd	s8,0(sp)
    8000181a:	0880                	addi	s0,sp,80
    8000181c:	8b2a                	mv	s6,a0
    8000181e:	8a2e                	mv	s4,a1
    80001820:	8c32                	mv	s8,a2
    80001822:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001824:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001826:	6a85                	lui	s5,0x1
    80001828:	a01d                	j	8000184e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000182a:	018505b3          	add	a1,a0,s8
    8000182e:	0004861b          	sext.w	a2,s1
    80001832:	412585b3          	sub	a1,a1,s2
    80001836:	8552                	mv	a0,s4
    80001838:	fffff097          	auipc	ra,0xfffff
    8000183c:	604080e7          	jalr	1540(ra) # 80000e3c <memmove>

    len -= n;
    80001840:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001844:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001846:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000184a:	02098263          	beqz	s3,8000186e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000184e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001852:	85ca                	mv	a1,s2
    80001854:	855a                	mv	a0,s6
    80001856:	00000097          	auipc	ra,0x0
    8000185a:	914080e7          	jalr	-1772(ra) # 8000116a <walkaddr>
    if(pa0 == 0)
    8000185e:	cd01                	beqz	a0,80001876 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001860:	418904b3          	sub	s1,s2,s8
    80001864:	94d6                	add	s1,s1,s5
    if(n > len)
    80001866:	fc99f2e3          	bgeu	s3,s1,8000182a <copyin+0x28>
    8000186a:	84ce                	mv	s1,s3
    8000186c:	bf7d                	j	8000182a <copyin+0x28>
  }
  return 0;
    8000186e:	4501                	li	a0,0
    80001870:	a021                	j	80001878 <copyin+0x76>
    80001872:	4501                	li	a0,0
}
    80001874:	8082                	ret
      return -1;
    80001876:	557d                	li	a0,-1
}
    80001878:	60a6                	ld	ra,72(sp)
    8000187a:	6406                	ld	s0,64(sp)
    8000187c:	74e2                	ld	s1,56(sp)
    8000187e:	7942                	ld	s2,48(sp)
    80001880:	79a2                	ld	s3,40(sp)
    80001882:	7a02                	ld	s4,32(sp)
    80001884:	6ae2                	ld	s5,24(sp)
    80001886:	6b42                	ld	s6,16(sp)
    80001888:	6ba2                	ld	s7,8(sp)
    8000188a:	6c02                	ld	s8,0(sp)
    8000188c:	6161                	addi	sp,sp,80
    8000188e:	8082                	ret

0000000080001890 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001890:	c6c5                	beqz	a3,80001938 <copyinstr+0xa8>
{
    80001892:	715d                	addi	sp,sp,-80
    80001894:	e486                	sd	ra,72(sp)
    80001896:	e0a2                	sd	s0,64(sp)
    80001898:	fc26                	sd	s1,56(sp)
    8000189a:	f84a                	sd	s2,48(sp)
    8000189c:	f44e                	sd	s3,40(sp)
    8000189e:	f052                	sd	s4,32(sp)
    800018a0:	ec56                	sd	s5,24(sp)
    800018a2:	e85a                	sd	s6,16(sp)
    800018a4:	e45e                	sd	s7,8(sp)
    800018a6:	0880                	addi	s0,sp,80
    800018a8:	8a2a                	mv	s4,a0
    800018aa:	8b2e                	mv	s6,a1
    800018ac:	8bb2                	mv	s7,a2
    800018ae:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018b0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018b2:	6985                	lui	s3,0x1
    800018b4:	a035                	j	800018e0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018b6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018ba:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018bc:	0017b793          	seqz	a5,a5
    800018c0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018c4:	60a6                	ld	ra,72(sp)
    800018c6:	6406                	ld	s0,64(sp)
    800018c8:	74e2                	ld	s1,56(sp)
    800018ca:	7942                	ld	s2,48(sp)
    800018cc:	79a2                	ld	s3,40(sp)
    800018ce:	7a02                	ld	s4,32(sp)
    800018d0:	6ae2                	ld	s5,24(sp)
    800018d2:	6b42                	ld	s6,16(sp)
    800018d4:	6ba2                	ld	s7,8(sp)
    800018d6:	6161                	addi	sp,sp,80
    800018d8:	8082                	ret
    srcva = va0 + PGSIZE;
    800018da:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018de:	c8a9                	beqz	s1,80001930 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018e0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018e4:	85ca                	mv	a1,s2
    800018e6:	8552                	mv	a0,s4
    800018e8:	00000097          	auipc	ra,0x0
    800018ec:	882080e7          	jalr	-1918(ra) # 8000116a <walkaddr>
    if(pa0 == 0)
    800018f0:	c131                	beqz	a0,80001934 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018f2:	41790833          	sub	a6,s2,s7
    800018f6:	984e                	add	a6,a6,s3
    if(n > max)
    800018f8:	0104f363          	bgeu	s1,a6,800018fe <copyinstr+0x6e>
    800018fc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018fe:	955e                	add	a0,a0,s7
    80001900:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001904:	fc080be3          	beqz	a6,800018da <copyinstr+0x4a>
    80001908:	985a                	add	a6,a6,s6
    8000190a:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000190c:	41650633          	sub	a2,a0,s6
    80001910:	14fd                	addi	s1,s1,-1
    80001912:	9b26                	add	s6,s6,s1
    80001914:	00f60733          	add	a4,a2,a5
    80001918:	00074703          	lbu	a4,0(a4)
    8000191c:	df49                	beqz	a4,800018b6 <copyinstr+0x26>
        *dst = *p;
    8000191e:	00e78023          	sb	a4,0(a5)
      --max;
    80001922:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001926:	0785                	addi	a5,a5,1
    while(n > 0){
    80001928:	ff0796e3          	bne	a5,a6,80001914 <copyinstr+0x84>
      dst++;
    8000192c:	8b42                	mv	s6,a6
    8000192e:	b775                	j	800018da <copyinstr+0x4a>
    80001930:	4781                	li	a5,0
    80001932:	b769                	j	800018bc <copyinstr+0x2c>
      return -1;
    80001934:	557d                	li	a0,-1
    80001936:	b779                	j	800018c4 <copyinstr+0x34>
  int got_null = 0;
    80001938:	4781                	li	a5,0
  if(got_null){
    8000193a:	0017b793          	seqz	a5,a5
    8000193e:	40f00533          	neg	a0,a5
}
    80001942:	8082                	ret

0000000080001944 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001944:	7139                	addi	sp,sp,-64
    80001946:	fc06                	sd	ra,56(sp)
    80001948:	f822                	sd	s0,48(sp)
    8000194a:	f426                	sd	s1,40(sp)
    8000194c:	f04a                	sd	s2,32(sp)
    8000194e:	ec4e                	sd	s3,24(sp)
    80001950:	e852                	sd	s4,16(sp)
    80001952:	e456                	sd	s5,8(sp)
    80001954:	e05a                	sd	s6,0(sp)
    80001956:	0080                	addi	s0,sp,64
    80001958:	89aa                	mv	s3,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00010497          	auipc	s1,0x10
    8000195e:	6fe48493          	addi	s1,s1,1790 # 80012058 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001962:	8b26                	mv	s6,s1
    80001964:	00006a97          	auipc	s5,0x6
    80001968:	69ca8a93          	addi	s5,s5,1692 # 80008000 <etext>
    8000196c:	04000937          	lui	s2,0x4000
    80001970:	197d                	addi	s2,s2,-1
    80001972:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001974:	00016a17          	auipc	s4,0x16
    80001978:	0e4a0a13          	addi	s4,s4,228 # 80017a58 <tickslock>
    char *pa = kalloc();
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	278080e7          	jalr	632(ra) # 80000bf4 <kalloc>
    80001984:	862a                	mv	a2,a0
    if(pa == 0)
    80001986:	c131                	beqz	a0,800019ca <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001988:	416485b3          	sub	a1,s1,s6
    8000198c:	858d                	srai	a1,a1,0x3
    8000198e:	000ab783          	ld	a5,0(s5)
    80001992:	02f585b3          	mul	a1,a1,a5
    80001996:	2585                	addiw	a1,a1,1
    80001998:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000199c:	4719                	li	a4,6
    8000199e:	6685                	lui	a3,0x1
    800019a0:	40b905b3          	sub	a1,s2,a1
    800019a4:	854e                	mv	a0,s3
    800019a6:	00000097          	auipc	ra,0x0
    800019aa:	8a6080e7          	jalr	-1882(ra) # 8000124c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ae:	16848493          	addi	s1,s1,360
    800019b2:	fd4495e3          	bne	s1,s4,8000197c <proc_mapstacks+0x38>
  }
}
    800019b6:	70e2                	ld	ra,56(sp)
    800019b8:	7442                	ld	s0,48(sp)
    800019ba:	74a2                	ld	s1,40(sp)
    800019bc:	7902                	ld	s2,32(sp)
    800019be:	69e2                	ld	s3,24(sp)
    800019c0:	6a42                	ld	s4,16(sp)
    800019c2:	6aa2                	ld	s5,8(sp)
    800019c4:	6b02                	ld	s6,0(sp)
    800019c6:	6121                	addi	sp,sp,64
    800019c8:	8082                	ret
      panic("kalloc");
    800019ca:	00007517          	auipc	a0,0x7
    800019ce:	80e50513          	addi	a0,a0,-2034 # 800081d8 <digits+0x198>
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	c7a080e7          	jalr	-902(ra) # 8000064c <panic>

00000000800019da <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800019da:	7139                	addi	sp,sp,-64
    800019dc:	fc06                	sd	ra,56(sp)
    800019de:	f822                	sd	s0,48(sp)
    800019e0:	f426                	sd	s1,40(sp)
    800019e2:	f04a                	sd	s2,32(sp)
    800019e4:	ec4e                	sd	s3,24(sp)
    800019e6:	e852                	sd	s4,16(sp)
    800019e8:	e456                	sd	s5,8(sp)
    800019ea:	e05a                	sd	s6,0(sp)
    800019ec:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800019ee:	00006597          	auipc	a1,0x6
    800019f2:	7f258593          	addi	a1,a1,2034 # 800081e0 <digits+0x1a0>
    800019f6:	00010517          	auipc	a0,0x10
    800019fa:	afa50513          	addi	a0,a0,-1286 # 800114f0 <pid_lock>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	256080e7          	jalr	598(ra) # 80000c54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a06:	00006597          	auipc	a1,0x6
    80001a0a:	7e258593          	addi	a1,a1,2018 # 800081e8 <digits+0x1a8>
    80001a0e:	00010517          	auipc	a0,0x10
    80001a12:	afa50513          	addi	a0,a0,-1286 # 80011508 <wait_lock>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	23e080e7          	jalr	574(ra) # 80000c54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a1e:	00010497          	auipc	s1,0x10
    80001a22:	63a48493          	addi	s1,s1,1594 # 80012058 <proc>
      initlock(&p->lock, "proc");
    80001a26:	00006b17          	auipc	s6,0x6
    80001a2a:	7d2b0b13          	addi	s6,s6,2002 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a2e:	8aa6                	mv	s5,s1
    80001a30:	00006a17          	auipc	s4,0x6
    80001a34:	5d0a0a13          	addi	s4,s4,1488 # 80008000 <etext>
    80001a38:	04000937          	lui	s2,0x4000
    80001a3c:	197d                	addi	s2,s2,-1
    80001a3e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a40:	00016997          	auipc	s3,0x16
    80001a44:	01898993          	addi	s3,s3,24 # 80017a58 <tickslock>
      initlock(&p->lock, "proc");
    80001a48:	85da                	mv	a1,s6
    80001a4a:	8526                	mv	a0,s1
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	208080e7          	jalr	520(ra) # 80000c54 <initlock>
      p->state = UNUSED;
    80001a54:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001a58:	415487b3          	sub	a5,s1,s5
    80001a5c:	878d                	srai	a5,a5,0x3
    80001a5e:	000a3703          	ld	a4,0(s4)
    80001a62:	02e787b3          	mul	a5,a5,a4
    80001a66:	2785                	addiw	a5,a5,1
    80001a68:	00d7979b          	slliw	a5,a5,0xd
    80001a6c:	40f907b3          	sub	a5,s2,a5
    80001a70:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a72:	16848493          	addi	s1,s1,360
    80001a76:	fd3499e3          	bne	s1,s3,80001a48 <procinit+0x6e>
  }
}
    80001a7a:	70e2                	ld	ra,56(sp)
    80001a7c:	7442                	ld	s0,48(sp)
    80001a7e:	74a2                	ld	s1,40(sp)
    80001a80:	7902                	ld	s2,32(sp)
    80001a82:	69e2                	ld	s3,24(sp)
    80001a84:	6a42                	ld	s4,16(sp)
    80001a86:	6aa2                	ld	s5,8(sp)
    80001a88:	6b02                	ld	s6,0(sp)
    80001a8a:	6121                	addi	sp,sp,64
    80001a8c:	8082                	ret

0000000080001a8e <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a8e:	1141                	addi	sp,sp,-16
    80001a90:	e422                	sd	s0,8(sp)
    80001a92:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a94:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a96:	2501                	sext.w	a0,a0
    80001a98:	6422                	ld	s0,8(sp)
    80001a9a:	0141                	addi	sp,sp,16
    80001a9c:	8082                	ret

0000000080001a9e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a9e:	1141                	addi	sp,sp,-16
    80001aa0:	e422                	sd	s0,8(sp)
    80001aa2:	0800                	addi	s0,sp,16
    80001aa4:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001aa6:	2781                	sext.w	a5,a5
    80001aa8:	079e                	slli	a5,a5,0x7
  return c;
}
    80001aaa:	00010517          	auipc	a0,0x10
    80001aae:	a7650513          	addi	a0,a0,-1418 # 80011520 <cpus>
    80001ab2:	953e                	add	a0,a0,a5
    80001ab4:	6422                	ld	s0,8(sp)
    80001ab6:	0141                	addi	sp,sp,16
    80001ab8:	8082                	ret

0000000080001aba <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001aba:	1101                	addi	sp,sp,-32
    80001abc:	ec06                	sd	ra,24(sp)
    80001abe:	e822                	sd	s0,16(sp)
    80001ac0:	e426                	sd	s1,8(sp)
    80001ac2:	1000                	addi	s0,sp,32
  push_off();
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	1d4080e7          	jalr	468(ra) # 80000c98 <push_off>
    80001acc:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ace:	2781                	sext.w	a5,a5
    80001ad0:	079e                	slli	a5,a5,0x7
    80001ad2:	00010717          	auipc	a4,0x10
    80001ad6:	a1e70713          	addi	a4,a4,-1506 # 800114f0 <pid_lock>
    80001ada:	97ba                	add	a5,a5,a4
    80001adc:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	25a080e7          	jalr	602(ra) # 80000d38 <pop_off>
  return p;
}
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	60e2                	ld	ra,24(sp)
    80001aea:	6442                	ld	s0,16(sp)
    80001aec:	64a2                	ld	s1,8(sp)
    80001aee:	6105                	addi	sp,sp,32
    80001af0:	8082                	ret

0000000080001af2 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001af2:	1141                	addi	sp,sp,-16
    80001af4:	e406                	sd	ra,8(sp)
    80001af6:	e022                	sd	s0,0(sp)
    80001af8:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	fc0080e7          	jalr	-64(ra) # 80001aba <myproc>
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	296080e7          	jalr	662(ra) # 80000d98 <release>

  if (first) {
    80001b0a:	00007797          	auipc	a5,0x7
    80001b0e:	e267a783          	lw	a5,-474(a5) # 80008930 <first.0>
    80001b12:	eb89                	bnez	a5,80001b24 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b14:	00001097          	auipc	ra,0x1
    80001b18:	e2a080e7          	jalr	-470(ra) # 8000293e <usertrapret>
}
    80001b1c:	60a2                	ld	ra,8(sp)
    80001b1e:	6402                	ld	s0,0(sp)
    80001b20:	0141                	addi	sp,sp,16
    80001b22:	8082                	ret
    first = 0;
    80001b24:	00007797          	auipc	a5,0x7
    80001b28:	e007a623          	sw	zero,-500(a5) # 80008930 <first.0>
    fsinit(ROOTDEV);
    80001b2c:	4505                	li	a0,1
    80001b2e:	00002097          	auipc	ra,0x2
    80001b32:	be6080e7          	jalr	-1050(ra) # 80003714 <fsinit>
    80001b36:	bff9                	j	80001b14 <forkret+0x22>

0000000080001b38 <allocpid>:
{
    80001b38:	1101                	addi	sp,sp,-32
    80001b3a:	ec06                	sd	ra,24(sp)
    80001b3c:	e822                	sd	s0,16(sp)
    80001b3e:	e426                	sd	s1,8(sp)
    80001b40:	e04a                	sd	s2,0(sp)
    80001b42:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b44:	00010917          	auipc	s2,0x10
    80001b48:	9ac90913          	addi	s2,s2,-1620 # 800114f0 <pid_lock>
    80001b4c:	854a                	mv	a0,s2
    80001b4e:	fffff097          	auipc	ra,0xfffff
    80001b52:	196080e7          	jalr	406(ra) # 80000ce4 <acquire>
  pid = nextpid;
    80001b56:	00007797          	auipc	a5,0x7
    80001b5a:	dde78793          	addi	a5,a5,-546 # 80008934 <nextpid>
    80001b5e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b60:	0014871b          	addiw	a4,s1,1
    80001b64:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b66:	854a                	mv	a0,s2
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	230080e7          	jalr	560(ra) # 80000d98 <release>
}
    80001b70:	8526                	mv	a0,s1
    80001b72:	60e2                	ld	ra,24(sp)
    80001b74:	6442                	ld	s0,16(sp)
    80001b76:	64a2                	ld	s1,8(sp)
    80001b78:	6902                	ld	s2,0(sp)
    80001b7a:	6105                	addi	sp,sp,32
    80001b7c:	8082                	ret

0000000080001b7e <proc_pagetable>:
{
    80001b7e:	1101                	addi	sp,sp,-32
    80001b80:	ec06                	sd	ra,24(sp)
    80001b82:	e822                	sd	s0,16(sp)
    80001b84:	e426                	sd	s1,8(sp)
    80001b86:	e04a                	sd	s2,0(sp)
    80001b88:	1000                	addi	s0,sp,32
    80001b8a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b8c:	00000097          	auipc	ra,0x0
    80001b90:	8aa080e7          	jalr	-1878(ra) # 80001436 <uvmcreate>
    80001b94:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b96:	c121                	beqz	a0,80001bd6 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b98:	4729                	li	a4,10
    80001b9a:	00005697          	auipc	a3,0x5
    80001b9e:	46668693          	addi	a3,a3,1126 # 80007000 <_trampoline>
    80001ba2:	6605                	lui	a2,0x1
    80001ba4:	040005b7          	lui	a1,0x4000
    80001ba8:	15fd                	addi	a1,a1,-1
    80001baa:	05b2                	slli	a1,a1,0xc
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	600080e7          	jalr	1536(ra) # 800011ac <mappages>
    80001bb4:	02054863          	bltz	a0,80001be4 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bb8:	4719                	li	a4,6
    80001bba:	05893683          	ld	a3,88(s2)
    80001bbe:	6605                	lui	a2,0x1
    80001bc0:	020005b7          	lui	a1,0x2000
    80001bc4:	15fd                	addi	a1,a1,-1
    80001bc6:	05b6                	slli	a1,a1,0xd
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	5e2080e7          	jalr	1506(ra) # 800011ac <mappages>
    80001bd2:	02054163          	bltz	a0,80001bf4 <proc_pagetable+0x76>
}
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	60e2                	ld	ra,24(sp)
    80001bda:	6442                	ld	s0,16(sp)
    80001bdc:	64a2                	ld	s1,8(sp)
    80001bde:	6902                	ld	s2,0(sp)
    80001be0:	6105                	addi	sp,sp,32
    80001be2:	8082                	ret
    uvmfree(pagetable, 0);
    80001be4:	4581                	li	a1,0
    80001be6:	8526                	mv	a0,s1
    80001be8:	00000097          	auipc	ra,0x0
    80001bec:	a52080e7          	jalr	-1454(ra) # 8000163a <uvmfree>
    return 0;
    80001bf0:	4481                	li	s1,0
    80001bf2:	b7d5                	j	80001bd6 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bf4:	4681                	li	a3,0
    80001bf6:	4605                	li	a2,1
    80001bf8:	040005b7          	lui	a1,0x4000
    80001bfc:	15fd                	addi	a1,a1,-1
    80001bfe:	05b2                	slli	a1,a1,0xc
    80001c00:	8526                	mv	a0,s1
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	770080e7          	jalr	1904(ra) # 80001372 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c0a:	4581                	li	a1,0
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	a2c080e7          	jalr	-1492(ra) # 8000163a <uvmfree>
    return 0;
    80001c16:	4481                	li	s1,0
    80001c18:	bf7d                	j	80001bd6 <proc_pagetable+0x58>

0000000080001c1a <proc_freepagetable>:
{
    80001c1a:	1101                	addi	sp,sp,-32
    80001c1c:	ec06                	sd	ra,24(sp)
    80001c1e:	e822                	sd	s0,16(sp)
    80001c20:	e426                	sd	s1,8(sp)
    80001c22:	e04a                	sd	s2,0(sp)
    80001c24:	1000                	addi	s0,sp,32
    80001c26:	84aa                	mv	s1,a0
    80001c28:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c2a:	4681                	li	a3,0
    80001c2c:	4605                	li	a2,1
    80001c2e:	040005b7          	lui	a1,0x4000
    80001c32:	15fd                	addi	a1,a1,-1
    80001c34:	05b2                	slli	a1,a1,0xc
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	73c080e7          	jalr	1852(ra) # 80001372 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c3e:	4681                	li	a3,0
    80001c40:	4605                	li	a2,1
    80001c42:	020005b7          	lui	a1,0x2000
    80001c46:	15fd                	addi	a1,a1,-1
    80001c48:	05b6                	slli	a1,a1,0xd
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	726080e7          	jalr	1830(ra) # 80001372 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c54:	85ca                	mv	a1,s2
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	9e2080e7          	jalr	-1566(ra) # 8000163a <uvmfree>
}
    80001c60:	60e2                	ld	ra,24(sp)
    80001c62:	6442                	ld	s0,16(sp)
    80001c64:	64a2                	ld	s1,8(sp)
    80001c66:	6902                	ld	s2,0(sp)
    80001c68:	6105                	addi	sp,sp,32
    80001c6a:	8082                	ret

0000000080001c6c <freeproc>:
{
    80001c6c:	1101                	addi	sp,sp,-32
    80001c6e:	ec06                	sd	ra,24(sp)
    80001c70:	e822                	sd	s0,16(sp)
    80001c72:	e426                	sd	s1,8(sp)
    80001c74:	1000                	addi	s0,sp,32
    80001c76:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c78:	6d28                	ld	a0,88(a0)
    80001c7a:	c509                	beqz	a0,80001c84 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	e7c080e7          	jalr	-388(ra) # 80000af8 <kfree>
  p->trapframe = 0;
    80001c84:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c88:	68a8                	ld	a0,80(s1)
    80001c8a:	c511                	beqz	a0,80001c96 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c8c:	64ac                	ld	a1,72(s1)
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f8c080e7          	jalr	-116(ra) # 80001c1a <proc_freepagetable>
  p->pagetable = 0;
    80001c96:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c9a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c9e:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ca2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ca6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001caa:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cae:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cb2:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cb6:	0004ac23          	sw	zero,24(s1)
}
    80001cba:	60e2                	ld	ra,24(sp)
    80001cbc:	6442                	ld	s0,16(sp)
    80001cbe:	64a2                	ld	s1,8(sp)
    80001cc0:	6105                	addi	sp,sp,32
    80001cc2:	8082                	ret

0000000080001cc4 <allocproc>:
{
    80001cc4:	1101                	addi	sp,sp,-32
    80001cc6:	ec06                	sd	ra,24(sp)
    80001cc8:	e822                	sd	s0,16(sp)
    80001cca:	e426                	sd	s1,8(sp)
    80001ccc:	e04a                	sd	s2,0(sp)
    80001cce:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd0:	00010497          	auipc	s1,0x10
    80001cd4:	38848493          	addi	s1,s1,904 # 80012058 <proc>
    80001cd8:	00016917          	auipc	s2,0x16
    80001cdc:	d8090913          	addi	s2,s2,-640 # 80017a58 <tickslock>
    acquire(&p->lock);
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	002080e7          	jalr	2(ra) # 80000ce4 <acquire>
    if(p->state == UNUSED) {
    80001cea:	4c9c                	lw	a5,24(s1)
    80001cec:	cf81                	beqz	a5,80001d04 <allocproc+0x40>
      release(&p->lock);
    80001cee:	8526                	mv	a0,s1
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	0a8080e7          	jalr	168(ra) # 80000d98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf8:	16848493          	addi	s1,s1,360
    80001cfc:	ff2492e3          	bne	s1,s2,80001ce0 <allocproc+0x1c>
  return 0;
    80001d00:	4481                	li	s1,0
    80001d02:	a889                	j	80001d54 <allocproc+0x90>
  p->pid = allocpid();
    80001d04:	00000097          	auipc	ra,0x0
    80001d08:	e34080e7          	jalr	-460(ra) # 80001b38 <allocpid>
    80001d0c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d0e:	4785                	li	a5,1
    80001d10:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	ee2080e7          	jalr	-286(ra) # 80000bf4 <kalloc>
    80001d1a:	892a                	mv	s2,a0
    80001d1c:	eca8                	sd	a0,88(s1)
    80001d1e:	c131                	beqz	a0,80001d62 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d20:	8526                	mv	a0,s1
    80001d22:	00000097          	auipc	ra,0x0
    80001d26:	e5c080e7          	jalr	-420(ra) # 80001b7e <proc_pagetable>
    80001d2a:	892a                	mv	s2,a0
    80001d2c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d2e:	c531                	beqz	a0,80001d7a <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d30:	07000613          	li	a2,112
    80001d34:	4581                	li	a1,0
    80001d36:	06048513          	addi	a0,s1,96
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	0a6080e7          	jalr	166(ra) # 80000de0 <memset>
  p->context.ra = (uint64)forkret;
    80001d42:	00000797          	auipc	a5,0x0
    80001d46:	db078793          	addi	a5,a5,-592 # 80001af2 <forkret>
    80001d4a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d4c:	60bc                	ld	a5,64(s1)
    80001d4e:	6705                	lui	a4,0x1
    80001d50:	97ba                	add	a5,a5,a4
    80001d52:	f4bc                	sd	a5,104(s1)
}
    80001d54:	8526                	mv	a0,s1
    80001d56:	60e2                	ld	ra,24(sp)
    80001d58:	6442                	ld	s0,16(sp)
    80001d5a:	64a2                	ld	s1,8(sp)
    80001d5c:	6902                	ld	s2,0(sp)
    80001d5e:	6105                	addi	sp,sp,32
    80001d60:	8082                	ret
    freeproc(p);
    80001d62:	8526                	mv	a0,s1
    80001d64:	00000097          	auipc	ra,0x0
    80001d68:	f08080e7          	jalr	-248(ra) # 80001c6c <freeproc>
    release(&p->lock);
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	02a080e7          	jalr	42(ra) # 80000d98 <release>
    return 0;
    80001d76:	84ca                	mv	s1,s2
    80001d78:	bff1                	j	80001d54 <allocproc+0x90>
    freeproc(p);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	ef0080e7          	jalr	-272(ra) # 80001c6c <freeproc>
    release(&p->lock);
    80001d84:	8526                	mv	a0,s1
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	012080e7          	jalr	18(ra) # 80000d98 <release>
    return 0;
    80001d8e:	84ca                	mv	s1,s2
    80001d90:	b7d1                	j	80001d54 <allocproc+0x90>

0000000080001d92 <userinit>:
{
    80001d92:	1101                	addi	sp,sp,-32
    80001d94:	ec06                	sd	ra,24(sp)
    80001d96:	e822                	sd	s0,16(sp)
    80001d98:	e426                	sd	s1,8(sp)
    80001d9a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	f28080e7          	jalr	-216(ra) # 80001cc4 <allocproc>
    80001da4:	84aa                	mv	s1,a0
  initproc = p;
    80001da6:	00007797          	auipc	a5,0x7
    80001daa:	c0a7b523          	sd	a0,-1014(a5) # 800089b0 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001dae:	03400613          	li	a2,52
    80001db2:	00007597          	auipc	a1,0x7
    80001db6:	b8e58593          	addi	a1,a1,-1138 # 80008940 <initcode>
    80001dba:	6928                	ld	a0,80(a0)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	6a8080e7          	jalr	1704(ra) # 80001464 <uvmfirst>
  p->sz = PGSIZE;
    80001dc4:	6785                	lui	a5,0x1
    80001dc6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dc8:	6cb8                	ld	a4,88(s1)
    80001dca:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dce:	6cb8                	ld	a4,88(s1)
    80001dd0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dd2:	4641                	li	a2,16
    80001dd4:	00006597          	auipc	a1,0x6
    80001dd8:	42c58593          	addi	a1,a1,1068 # 80008200 <digits+0x1c0>
    80001ddc:	15848513          	addi	a0,s1,344
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	14a080e7          	jalr	330(ra) # 80000f2a <safestrcpy>
  p->cwd = namei("/");
    80001de8:	00006517          	auipc	a0,0x6
    80001dec:	42850513          	addi	a0,a0,1064 # 80008210 <digits+0x1d0>
    80001df0:	00002097          	auipc	ra,0x2
    80001df4:	346080e7          	jalr	838(ra) # 80004136 <namei>
    80001df8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001dfc:	478d                	li	a5,3
    80001dfe:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e00:	8526                	mv	a0,s1
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	f96080e7          	jalr	-106(ra) # 80000d98 <release>
}
    80001e0a:	60e2                	ld	ra,24(sp)
    80001e0c:	6442                	ld	s0,16(sp)
    80001e0e:	64a2                	ld	s1,8(sp)
    80001e10:	6105                	addi	sp,sp,32
    80001e12:	8082                	ret

0000000080001e14 <growproc>:
{
    80001e14:	1101                	addi	sp,sp,-32
    80001e16:	ec06                	sd	ra,24(sp)
    80001e18:	e822                	sd	s0,16(sp)
    80001e1a:	e426                	sd	s1,8(sp)
    80001e1c:	e04a                	sd	s2,0(sp)
    80001e1e:	1000                	addi	s0,sp,32
    80001e20:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	c98080e7          	jalr	-872(ra) # 80001aba <myproc>
    80001e2a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e2c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001e2e:	01204c63          	bgtz	s2,80001e46 <growproc+0x32>
  } else if(n < 0){
    80001e32:	02094663          	bltz	s2,80001e5e <growproc+0x4a>
  p->sz = sz;
    80001e36:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e38:	4501                	li	a0,0
}
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6902                	ld	s2,0(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e46:	4691                	li	a3,4
    80001e48:	00b90633          	add	a2,s2,a1
    80001e4c:	6928                	ld	a0,80(a0)
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	6d0080e7          	jalr	1744(ra) # 8000151e <uvmalloc>
    80001e56:	85aa                	mv	a1,a0
    80001e58:	fd79                	bnez	a0,80001e36 <growproc+0x22>
      return -1;
    80001e5a:	557d                	li	a0,-1
    80001e5c:	bff9                	j	80001e3a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e5e:	00b90633          	add	a2,s2,a1
    80001e62:	6928                	ld	a0,80(a0)
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	672080e7          	jalr	1650(ra) # 800014d6 <uvmdealloc>
    80001e6c:	85aa                	mv	a1,a0
    80001e6e:	b7e1                	j	80001e36 <growproc+0x22>

0000000080001e70 <fork>:
{
    80001e70:	7139                	addi	sp,sp,-64
    80001e72:	fc06                	sd	ra,56(sp)
    80001e74:	f822                	sd	s0,48(sp)
    80001e76:	f426                	sd	s1,40(sp)
    80001e78:	f04a                	sd	s2,32(sp)
    80001e7a:	ec4e                	sd	s3,24(sp)
    80001e7c:	e852                	sd	s4,16(sp)
    80001e7e:	e456                	sd	s5,8(sp)
    80001e80:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	c38080e7          	jalr	-968(ra) # 80001aba <myproc>
    80001e8a:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	e38080e7          	jalr	-456(ra) # 80001cc4 <allocproc>
    80001e94:	10050c63          	beqz	a0,80001fac <fork+0x13c>
    80001e98:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e9a:	048ab603          	ld	a2,72(s5)
    80001e9e:	692c                	ld	a1,80(a0)
    80001ea0:	050ab503          	ld	a0,80(s5)
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	7ce080e7          	jalr	1998(ra) # 80001672 <uvmcopy>
    80001eac:	04054863          	bltz	a0,80001efc <fork+0x8c>
  np->sz = p->sz;
    80001eb0:	048ab783          	ld	a5,72(s5)
    80001eb4:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001eb8:	058ab683          	ld	a3,88(s5)
    80001ebc:	87b6                	mv	a5,a3
    80001ebe:	058a3703          	ld	a4,88(s4)
    80001ec2:	12068693          	addi	a3,a3,288
    80001ec6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001eca:	6788                	ld	a0,8(a5)
    80001ecc:	6b8c                	ld	a1,16(a5)
    80001ece:	6f90                	ld	a2,24(a5)
    80001ed0:	01073023          	sd	a6,0(a4)
    80001ed4:	e708                	sd	a0,8(a4)
    80001ed6:	eb0c                	sd	a1,16(a4)
    80001ed8:	ef10                	sd	a2,24(a4)
    80001eda:	02078793          	addi	a5,a5,32
    80001ede:	02070713          	addi	a4,a4,32
    80001ee2:	fed792e3          	bne	a5,a3,80001ec6 <fork+0x56>
  np->trapframe->a0 = 0;
    80001ee6:	058a3783          	ld	a5,88(s4)
    80001eea:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001eee:	0d0a8493          	addi	s1,s5,208
    80001ef2:	0d0a0913          	addi	s2,s4,208
    80001ef6:	150a8993          	addi	s3,s5,336
    80001efa:	a00d                	j	80001f1c <fork+0xac>
    freeproc(np);
    80001efc:	8552                	mv	a0,s4
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	d6e080e7          	jalr	-658(ra) # 80001c6c <freeproc>
    release(&np->lock);
    80001f06:	8552                	mv	a0,s4
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	e90080e7          	jalr	-368(ra) # 80000d98 <release>
    return -1;
    80001f10:	597d                	li	s2,-1
    80001f12:	a059                	j	80001f98 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001f14:	04a1                	addi	s1,s1,8
    80001f16:	0921                	addi	s2,s2,8
    80001f18:	01348b63          	beq	s1,s3,80001f2e <fork+0xbe>
    if(p->ofile[i])
    80001f1c:	6088                	ld	a0,0(s1)
    80001f1e:	d97d                	beqz	a0,80001f14 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f20:	00003097          	auipc	ra,0x3
    80001f24:	8ac080e7          	jalr	-1876(ra) # 800047cc <filedup>
    80001f28:	00a93023          	sd	a0,0(s2)
    80001f2c:	b7e5                	j	80001f14 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f2e:	150ab503          	ld	a0,336(s5)
    80001f32:	00002097          	auipc	ra,0x2
    80001f36:	a20080e7          	jalr	-1504(ra) # 80003952 <idup>
    80001f3a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f3e:	4641                	li	a2,16
    80001f40:	158a8593          	addi	a1,s5,344
    80001f44:	158a0513          	addi	a0,s4,344
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	fe2080e7          	jalr	-30(ra) # 80000f2a <safestrcpy>
  pid = np->pid;
    80001f50:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f54:	8552                	mv	a0,s4
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	e42080e7          	jalr	-446(ra) # 80000d98 <release>
  acquire(&wait_lock);
    80001f5e:	0000f497          	auipc	s1,0xf
    80001f62:	5aa48493          	addi	s1,s1,1450 # 80011508 <wait_lock>
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	d7c080e7          	jalr	-644(ra) # 80000ce4 <acquire>
  np->parent = p;
    80001f70:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f74:	8526                	mv	a0,s1
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	e22080e7          	jalr	-478(ra) # 80000d98 <release>
  acquire(&np->lock);
    80001f7e:	8552                	mv	a0,s4
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	d64080e7          	jalr	-668(ra) # 80000ce4 <acquire>
  np->state = RUNNABLE;
    80001f88:	478d                	li	a5,3
    80001f8a:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f8e:	8552                	mv	a0,s4
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	e08080e7          	jalr	-504(ra) # 80000d98 <release>
}
    80001f98:	854a                	mv	a0,s2
    80001f9a:	70e2                	ld	ra,56(sp)
    80001f9c:	7442                	ld	s0,48(sp)
    80001f9e:	74a2                	ld	s1,40(sp)
    80001fa0:	7902                	ld	s2,32(sp)
    80001fa2:	69e2                	ld	s3,24(sp)
    80001fa4:	6a42                	ld	s4,16(sp)
    80001fa6:	6aa2                	ld	s5,8(sp)
    80001fa8:	6121                	addi	sp,sp,64
    80001faa:	8082                	ret
    return -1;
    80001fac:	597d                	li	s2,-1
    80001fae:	b7ed                	j	80001f98 <fork+0x128>

0000000080001fb0 <scheduler>:
{
    80001fb0:	7139                	addi	sp,sp,-64
    80001fb2:	fc06                	sd	ra,56(sp)
    80001fb4:	f822                	sd	s0,48(sp)
    80001fb6:	f426                	sd	s1,40(sp)
    80001fb8:	f04a                	sd	s2,32(sp)
    80001fba:	ec4e                	sd	s3,24(sp)
    80001fbc:	e852                	sd	s4,16(sp)
    80001fbe:	e456                	sd	s5,8(sp)
    80001fc0:	e05a                	sd	s6,0(sp)
    80001fc2:	0080                	addi	s0,sp,64
    80001fc4:	8792                	mv	a5,tp
  int id = r_tp();
    80001fc6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fc8:	00779a93          	slli	s5,a5,0x7
    80001fcc:	0000f717          	auipc	a4,0xf
    80001fd0:	52470713          	addi	a4,a4,1316 # 800114f0 <pid_lock>
    80001fd4:	9756                	add	a4,a4,s5
    80001fd6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fda:	0000f717          	auipc	a4,0xf
    80001fde:	54e70713          	addi	a4,a4,1358 # 80011528 <cpus+0x8>
    80001fe2:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001fe4:	498d                	li	s3,3
        p->state = RUNNING;
    80001fe6:	4b11                	li	s6,4
        c->proc = p;
    80001fe8:	079e                	slli	a5,a5,0x7
    80001fea:	0000fa17          	auipc	s4,0xf
    80001fee:	506a0a13          	addi	s4,s4,1286 # 800114f0 <pid_lock>
    80001ff2:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ff4:	00016917          	auipc	s2,0x16
    80001ff8:	a6490913          	addi	s2,s2,-1436 # 80017a58 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002000:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002004:	10079073          	csrw	sstatus,a5
    80002008:	00010497          	auipc	s1,0x10
    8000200c:	05048493          	addi	s1,s1,80 # 80012058 <proc>
    80002010:	a811                	j	80002024 <scheduler+0x74>
      release(&p->lock);
    80002012:	8526                	mv	a0,s1
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	d84080e7          	jalr	-636(ra) # 80000d98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000201c:	16848493          	addi	s1,s1,360
    80002020:	fd248ee3          	beq	s1,s2,80001ffc <scheduler+0x4c>
      acquire(&p->lock);
    80002024:	8526                	mv	a0,s1
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	cbe080e7          	jalr	-834(ra) # 80000ce4 <acquire>
      if(p->state == RUNNABLE) {
    8000202e:	4c9c                	lw	a5,24(s1)
    80002030:	ff3791e3          	bne	a5,s3,80002012 <scheduler+0x62>
        p->state = RUNNING;
    80002034:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002038:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000203c:	06048593          	addi	a1,s1,96
    80002040:	8556                	mv	a0,s5
    80002042:	00001097          	auipc	ra,0x1
    80002046:	852080e7          	jalr	-1966(ra) # 80002894 <swtch>
        c->proc = 0;
    8000204a:	020a3823          	sd	zero,48(s4)
    8000204e:	b7d1                	j	80002012 <scheduler+0x62>

0000000080002050 <sched>:
{
    80002050:	7179                	addi	sp,sp,-48
    80002052:	f406                	sd	ra,40(sp)
    80002054:	f022                	sd	s0,32(sp)
    80002056:	ec26                	sd	s1,24(sp)
    80002058:	e84a                	sd	s2,16(sp)
    8000205a:	e44e                	sd	s3,8(sp)
    8000205c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	a5c080e7          	jalr	-1444(ra) # 80001aba <myproc>
    80002066:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	c02080e7          	jalr	-1022(ra) # 80000c6a <holding>
    80002070:	c93d                	beqz	a0,800020e6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002072:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002074:	2781                	sext.w	a5,a5
    80002076:	079e                	slli	a5,a5,0x7
    80002078:	0000f717          	auipc	a4,0xf
    8000207c:	47870713          	addi	a4,a4,1144 # 800114f0 <pid_lock>
    80002080:	97ba                	add	a5,a5,a4
    80002082:	0a87a703          	lw	a4,168(a5)
    80002086:	4785                	li	a5,1
    80002088:	06f71763          	bne	a4,a5,800020f6 <sched+0xa6>
  if(p->state == RUNNING)
    8000208c:	4c98                	lw	a4,24(s1)
    8000208e:	4791                	li	a5,4
    80002090:	06f70b63          	beq	a4,a5,80002106 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002094:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002098:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000209a:	efb5                	bnez	a5,80002116 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000209c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000209e:	0000f917          	auipc	s2,0xf
    800020a2:	45290913          	addi	s2,s2,1106 # 800114f0 <pid_lock>
    800020a6:	2781                	sext.w	a5,a5
    800020a8:	079e                	slli	a5,a5,0x7
    800020aa:	97ca                	add	a5,a5,s2
    800020ac:	0ac7a983          	lw	s3,172(a5)
    800020b0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020b2:	2781                	sext.w	a5,a5
    800020b4:	079e                	slli	a5,a5,0x7
    800020b6:	0000f597          	auipc	a1,0xf
    800020ba:	47258593          	addi	a1,a1,1138 # 80011528 <cpus+0x8>
    800020be:	95be                	add	a1,a1,a5
    800020c0:	06048513          	addi	a0,s1,96
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	7d0080e7          	jalr	2000(ra) # 80002894 <swtch>
    800020cc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ce:	2781                	sext.w	a5,a5
    800020d0:	079e                	slli	a5,a5,0x7
    800020d2:	97ca                	add	a5,a5,s2
    800020d4:	0b37a623          	sw	s3,172(a5)
}
    800020d8:	70a2                	ld	ra,40(sp)
    800020da:	7402                	ld	s0,32(sp)
    800020dc:	64e2                	ld	s1,24(sp)
    800020de:	6942                	ld	s2,16(sp)
    800020e0:	69a2                	ld	s3,8(sp)
    800020e2:	6145                	addi	sp,sp,48
    800020e4:	8082                	ret
    panic("sched p->lock");
    800020e6:	00006517          	auipc	a0,0x6
    800020ea:	13250513          	addi	a0,a0,306 # 80008218 <digits+0x1d8>
    800020ee:	ffffe097          	auipc	ra,0xffffe
    800020f2:	55e080e7          	jalr	1374(ra) # 8000064c <panic>
    panic("sched locks");
    800020f6:	00006517          	auipc	a0,0x6
    800020fa:	13250513          	addi	a0,a0,306 # 80008228 <digits+0x1e8>
    800020fe:	ffffe097          	auipc	ra,0xffffe
    80002102:	54e080e7          	jalr	1358(ra) # 8000064c <panic>
    panic("sched running");
    80002106:	00006517          	auipc	a0,0x6
    8000210a:	13250513          	addi	a0,a0,306 # 80008238 <digits+0x1f8>
    8000210e:	ffffe097          	auipc	ra,0xffffe
    80002112:	53e080e7          	jalr	1342(ra) # 8000064c <panic>
    panic("sched interruptible");
    80002116:	00006517          	auipc	a0,0x6
    8000211a:	13250513          	addi	a0,a0,306 # 80008248 <digits+0x208>
    8000211e:	ffffe097          	auipc	ra,0xffffe
    80002122:	52e080e7          	jalr	1326(ra) # 8000064c <panic>

0000000080002126 <yield>:
{
    80002126:	1101                	addi	sp,sp,-32
    80002128:	ec06                	sd	ra,24(sp)
    8000212a:	e822                	sd	s0,16(sp)
    8000212c:	e426                	sd	s1,8(sp)
    8000212e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	98a080e7          	jalr	-1654(ra) # 80001aba <myproc>
    80002138:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	baa080e7          	jalr	-1110(ra) # 80000ce4 <acquire>
  p->state = RUNNABLE;
    80002142:	478d                	li	a5,3
    80002144:	cc9c                	sw	a5,24(s1)
  sched();
    80002146:	00000097          	auipc	ra,0x0
    8000214a:	f0a080e7          	jalr	-246(ra) # 80002050 <sched>
  release(&p->lock);
    8000214e:	8526                	mv	a0,s1
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	c48080e7          	jalr	-952(ra) # 80000d98 <release>
}
    80002158:	60e2                	ld	ra,24(sp)
    8000215a:	6442                	ld	s0,16(sp)
    8000215c:	64a2                	ld	s1,8(sp)
    8000215e:	6105                	addi	sp,sp,32
    80002160:	8082                	ret

0000000080002162 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002162:	7179                	addi	sp,sp,-48
    80002164:	f406                	sd	ra,40(sp)
    80002166:	f022                	sd	s0,32(sp)
    80002168:	ec26                	sd	s1,24(sp)
    8000216a:	e84a                	sd	s2,16(sp)
    8000216c:	e44e                	sd	s3,8(sp)
    8000216e:	1800                	addi	s0,sp,48
    80002170:	89aa                	mv	s3,a0
    80002172:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002174:	00000097          	auipc	ra,0x0
    80002178:	946080e7          	jalr	-1722(ra) # 80001aba <myproc>
    8000217c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	b66080e7          	jalr	-1178(ra) # 80000ce4 <acquire>
  release(lk);
    80002186:	854a                	mv	a0,s2
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	c10080e7          	jalr	-1008(ra) # 80000d98 <release>

  // Go to sleep.
  p->chan = chan;
    80002190:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002194:	4789                	li	a5,2
    80002196:	cc9c                	sw	a5,24(s1)

  sched();
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	eb8080e7          	jalr	-328(ra) # 80002050 <sched>

  // Tidy up.
  p->chan = 0;
    800021a0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021a4:	8526                	mv	a0,s1
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	bf2080e7          	jalr	-1038(ra) # 80000d98 <release>
  acquire(lk);
    800021ae:	854a                	mv	a0,s2
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	b34080e7          	jalr	-1228(ra) # 80000ce4 <acquire>
}
    800021b8:	70a2                	ld	ra,40(sp)
    800021ba:	7402                	ld	s0,32(sp)
    800021bc:	64e2                	ld	s1,24(sp)
    800021be:	6942                	ld	s2,16(sp)
    800021c0:	69a2                	ld	s3,8(sp)
    800021c2:	6145                	addi	sp,sp,48
    800021c4:	8082                	ret

00000000800021c6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021c6:	7139                	addi	sp,sp,-64
    800021c8:	fc06                	sd	ra,56(sp)
    800021ca:	f822                	sd	s0,48(sp)
    800021cc:	f426                	sd	s1,40(sp)
    800021ce:	f04a                	sd	s2,32(sp)
    800021d0:	ec4e                	sd	s3,24(sp)
    800021d2:	e852                	sd	s4,16(sp)
    800021d4:	e456                	sd	s5,8(sp)
    800021d6:	0080                	addi	s0,sp,64
    800021d8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021da:	00010497          	auipc	s1,0x10
    800021de:	e7e48493          	addi	s1,s1,-386 # 80012058 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021e2:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021e4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021e6:	00016917          	auipc	s2,0x16
    800021ea:	87290913          	addi	s2,s2,-1934 # 80017a58 <tickslock>
    800021ee:	a811                	j	80002202 <wakeup+0x3c>
      }
      release(&p->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	ba6080e7          	jalr	-1114(ra) # 80000d98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021fa:	16848493          	addi	s1,s1,360
    800021fe:	03248663          	beq	s1,s2,8000222a <wakeup+0x64>
    if(p != myproc()){
    80002202:	00000097          	auipc	ra,0x0
    80002206:	8b8080e7          	jalr	-1864(ra) # 80001aba <myproc>
    8000220a:	fea488e3          	beq	s1,a0,800021fa <wakeup+0x34>
      acquire(&p->lock);
    8000220e:	8526                	mv	a0,s1
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	ad4080e7          	jalr	-1324(ra) # 80000ce4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002218:	4c9c                	lw	a5,24(s1)
    8000221a:	fd379be3          	bne	a5,s3,800021f0 <wakeup+0x2a>
    8000221e:	709c                	ld	a5,32(s1)
    80002220:	fd4798e3          	bne	a5,s4,800021f0 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002224:	0154ac23          	sw	s5,24(s1)
    80002228:	b7e1                	j	800021f0 <wakeup+0x2a>
    }
  }
}
    8000222a:	70e2                	ld	ra,56(sp)
    8000222c:	7442                	ld	s0,48(sp)
    8000222e:	74a2                	ld	s1,40(sp)
    80002230:	7902                	ld	s2,32(sp)
    80002232:	69e2                	ld	s3,24(sp)
    80002234:	6a42                	ld	s4,16(sp)
    80002236:	6aa2                	ld	s5,8(sp)
    80002238:	6121                	addi	sp,sp,64
    8000223a:	8082                	ret

000000008000223c <reparent>:
{
    8000223c:	7179                	addi	sp,sp,-48
    8000223e:	f406                	sd	ra,40(sp)
    80002240:	f022                	sd	s0,32(sp)
    80002242:	ec26                	sd	s1,24(sp)
    80002244:	e84a                	sd	s2,16(sp)
    80002246:	e44e                	sd	s3,8(sp)
    80002248:	e052                	sd	s4,0(sp)
    8000224a:	1800                	addi	s0,sp,48
    8000224c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000224e:	00010497          	auipc	s1,0x10
    80002252:	e0a48493          	addi	s1,s1,-502 # 80012058 <proc>
      pp->parent = initproc;
    80002256:	00006a17          	auipc	s4,0x6
    8000225a:	75aa0a13          	addi	s4,s4,1882 # 800089b0 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000225e:	00015997          	auipc	s3,0x15
    80002262:	7fa98993          	addi	s3,s3,2042 # 80017a58 <tickslock>
    80002266:	a029                	j	80002270 <reparent+0x34>
    80002268:	16848493          	addi	s1,s1,360
    8000226c:	01348d63          	beq	s1,s3,80002286 <reparent+0x4a>
    if(pp->parent == p){
    80002270:	7c9c                	ld	a5,56(s1)
    80002272:	ff279be3          	bne	a5,s2,80002268 <reparent+0x2c>
      pp->parent = initproc;
    80002276:	000a3503          	ld	a0,0(s4)
    8000227a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	f4a080e7          	jalr	-182(ra) # 800021c6 <wakeup>
    80002284:	b7d5                	j	80002268 <reparent+0x2c>
}
    80002286:	70a2                	ld	ra,40(sp)
    80002288:	7402                	ld	s0,32(sp)
    8000228a:	64e2                	ld	s1,24(sp)
    8000228c:	6942                	ld	s2,16(sp)
    8000228e:	69a2                	ld	s3,8(sp)
    80002290:	6a02                	ld	s4,0(sp)
    80002292:	6145                	addi	sp,sp,48
    80002294:	8082                	ret

0000000080002296 <exit>:
{
    80002296:	7179                	addi	sp,sp,-48
    80002298:	f406                	sd	ra,40(sp)
    8000229a:	f022                	sd	s0,32(sp)
    8000229c:	ec26                	sd	s1,24(sp)
    8000229e:	e84a                	sd	s2,16(sp)
    800022a0:	e44e                	sd	s3,8(sp)
    800022a2:	e052                	sd	s4,0(sp)
    800022a4:	1800                	addi	s0,sp,48
    800022a6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	812080e7          	jalr	-2030(ra) # 80001aba <myproc>
    800022b0:	89aa                	mv	s3,a0
  if(p == initproc)
    800022b2:	00006797          	auipc	a5,0x6
    800022b6:	6fe7b783          	ld	a5,1790(a5) # 800089b0 <initproc>
    800022ba:	0d050493          	addi	s1,a0,208
    800022be:	15050913          	addi	s2,a0,336
    800022c2:	02a79363          	bne	a5,a0,800022e8 <exit+0x52>
    panic("init exiting");
    800022c6:	00006517          	auipc	a0,0x6
    800022ca:	f9a50513          	addi	a0,a0,-102 # 80008260 <digits+0x220>
    800022ce:	ffffe097          	auipc	ra,0xffffe
    800022d2:	37e080e7          	jalr	894(ra) # 8000064c <panic>
      fileclose(f);
    800022d6:	00002097          	auipc	ra,0x2
    800022da:	548080e7          	jalr	1352(ra) # 8000481e <fileclose>
      p->ofile[fd] = 0;
    800022de:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022e2:	04a1                	addi	s1,s1,8
    800022e4:	01248563          	beq	s1,s2,800022ee <exit+0x58>
    if(p->ofile[fd]){
    800022e8:	6088                	ld	a0,0(s1)
    800022ea:	f575                	bnez	a0,800022d6 <exit+0x40>
    800022ec:	bfdd                	j	800022e2 <exit+0x4c>
  begin_op();
    800022ee:	00002097          	auipc	ra,0x2
    800022f2:	064080e7          	jalr	100(ra) # 80004352 <begin_op>
  iput(p->cwd);
    800022f6:	1509b503          	ld	a0,336(s3)
    800022fa:	00002097          	auipc	ra,0x2
    800022fe:	850080e7          	jalr	-1968(ra) # 80003b4a <iput>
  end_op();
    80002302:	00002097          	auipc	ra,0x2
    80002306:	0d0080e7          	jalr	208(ra) # 800043d2 <end_op>
  p->cwd = 0;
    8000230a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000230e:	0000f497          	auipc	s1,0xf
    80002312:	1fa48493          	addi	s1,s1,506 # 80011508 <wait_lock>
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	9cc080e7          	jalr	-1588(ra) # 80000ce4 <acquire>
  reparent(p);
    80002320:	854e                	mv	a0,s3
    80002322:	00000097          	auipc	ra,0x0
    80002326:	f1a080e7          	jalr	-230(ra) # 8000223c <reparent>
  wakeup(p->parent);
    8000232a:	0389b503          	ld	a0,56(s3)
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	e98080e7          	jalr	-360(ra) # 800021c6 <wakeup>
  acquire(&p->lock);
    80002336:	854e                	mv	a0,s3
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	9ac080e7          	jalr	-1620(ra) # 80000ce4 <acquire>
  p->xstate = status;
    80002340:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002344:	4795                	li	a5,5
    80002346:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	a4c080e7          	jalr	-1460(ra) # 80000d98 <release>
  sched();
    80002354:	00000097          	auipc	ra,0x0
    80002358:	cfc080e7          	jalr	-772(ra) # 80002050 <sched>
  panic("zombie exit");
    8000235c:	00006517          	auipc	a0,0x6
    80002360:	f1450513          	addi	a0,a0,-236 # 80008270 <digits+0x230>
    80002364:	ffffe097          	auipc	ra,0xffffe
    80002368:	2e8080e7          	jalr	744(ra) # 8000064c <panic>

000000008000236c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000236c:	7179                	addi	sp,sp,-48
    8000236e:	f406                	sd	ra,40(sp)
    80002370:	f022                	sd	s0,32(sp)
    80002372:	ec26                	sd	s1,24(sp)
    80002374:	e84a                	sd	s2,16(sp)
    80002376:	e44e                	sd	s3,8(sp)
    80002378:	1800                	addi	s0,sp,48
    8000237a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000237c:	00010497          	auipc	s1,0x10
    80002380:	cdc48493          	addi	s1,s1,-804 # 80012058 <proc>
    80002384:	00015997          	auipc	s3,0x15
    80002388:	6d498993          	addi	s3,s3,1748 # 80017a58 <tickslock>
    acquire(&p->lock);
    8000238c:	8526                	mv	a0,s1
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	956080e7          	jalr	-1706(ra) # 80000ce4 <acquire>
    if(p->pid == pid){
    80002396:	589c                	lw	a5,48(s1)
    80002398:	01278d63          	beq	a5,s2,800023b2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	9fa080e7          	jalr	-1542(ra) # 80000d98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023a6:	16848493          	addi	s1,s1,360
    800023aa:	ff3491e3          	bne	s1,s3,8000238c <kill+0x20>
  }
  return -1;
    800023ae:	557d                	li	a0,-1
    800023b0:	a829                	j	800023ca <kill+0x5e>
      p->killed = 1;
    800023b2:	4785                	li	a5,1
    800023b4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023b6:	4c98                	lw	a4,24(s1)
    800023b8:	4789                	li	a5,2
    800023ba:	00f70f63          	beq	a4,a5,800023d8 <kill+0x6c>
      release(&p->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	9d8080e7          	jalr	-1576(ra) # 80000d98 <release>
      return 0;
    800023c8:	4501                	li	a0,0
}
    800023ca:	70a2                	ld	ra,40(sp)
    800023cc:	7402                	ld	s0,32(sp)
    800023ce:	64e2                	ld	s1,24(sp)
    800023d0:	6942                	ld	s2,16(sp)
    800023d2:	69a2                	ld	s3,8(sp)
    800023d4:	6145                	addi	sp,sp,48
    800023d6:	8082                	ret
        p->state = RUNNABLE;
    800023d8:	478d                	li	a5,3
    800023da:	cc9c                	sw	a5,24(s1)
    800023dc:	b7cd                	j	800023be <kill+0x52>

00000000800023de <setkilled>:

void
setkilled(struct proc *p)
{
    800023de:	1101                	addi	sp,sp,-32
    800023e0:	ec06                	sd	ra,24(sp)
    800023e2:	e822                	sd	s0,16(sp)
    800023e4:	e426                	sd	s1,8(sp)
    800023e6:	1000                	addi	s0,sp,32
    800023e8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8fa080e7          	jalr	-1798(ra) # 80000ce4 <acquire>
  p->killed = 1;
    800023f2:	4785                	li	a5,1
    800023f4:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	9a0080e7          	jalr	-1632(ra) # 80000d98 <release>
}
    80002400:	60e2                	ld	ra,24(sp)
    80002402:	6442                	ld	s0,16(sp)
    80002404:	64a2                	ld	s1,8(sp)
    80002406:	6105                	addi	sp,sp,32
    80002408:	8082                	ret

000000008000240a <killed>:

int
killed(struct proc *p)
{
    8000240a:	1101                	addi	sp,sp,-32
    8000240c:	ec06                	sd	ra,24(sp)
    8000240e:	e822                	sd	s0,16(sp)
    80002410:	e426                	sd	s1,8(sp)
    80002412:	e04a                	sd	s2,0(sp)
    80002414:	1000                	addi	s0,sp,32
    80002416:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	8cc080e7          	jalr	-1844(ra) # 80000ce4 <acquire>
  k = p->killed;
    80002420:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002424:	8526                	mv	a0,s1
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	972080e7          	jalr	-1678(ra) # 80000d98 <release>
  return k;
}
    8000242e:	854a                	mv	a0,s2
    80002430:	60e2                	ld	ra,24(sp)
    80002432:	6442                	ld	s0,16(sp)
    80002434:	64a2                	ld	s1,8(sp)
    80002436:	6902                	ld	s2,0(sp)
    80002438:	6105                	addi	sp,sp,32
    8000243a:	8082                	ret

000000008000243c <wait>:
{
    8000243c:	715d                	addi	sp,sp,-80
    8000243e:	e486                	sd	ra,72(sp)
    80002440:	e0a2                	sd	s0,64(sp)
    80002442:	fc26                	sd	s1,56(sp)
    80002444:	f84a                	sd	s2,48(sp)
    80002446:	f44e                	sd	s3,40(sp)
    80002448:	f052                	sd	s4,32(sp)
    8000244a:	ec56                	sd	s5,24(sp)
    8000244c:	e85a                	sd	s6,16(sp)
    8000244e:	e45e                	sd	s7,8(sp)
    80002450:	e062                	sd	s8,0(sp)
    80002452:	0880                	addi	s0,sp,80
    80002454:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	664080e7          	jalr	1636(ra) # 80001aba <myproc>
    8000245e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002460:	0000f517          	auipc	a0,0xf
    80002464:	0a850513          	addi	a0,a0,168 # 80011508 <wait_lock>
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	87c080e7          	jalr	-1924(ra) # 80000ce4 <acquire>
    havekids = 0;
    80002470:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002472:	4a15                	li	s4,5
        havekids = 1;
    80002474:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002476:	00015997          	auipc	s3,0x15
    8000247a:	5e298993          	addi	s3,s3,1506 # 80017a58 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000247e:	0000fc17          	auipc	s8,0xf
    80002482:	08ac0c13          	addi	s8,s8,138 # 80011508 <wait_lock>
    havekids = 0;
    80002486:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002488:	00010497          	auipc	s1,0x10
    8000248c:	bd048493          	addi	s1,s1,-1072 # 80012058 <proc>
    80002490:	a0bd                	j	800024fe <wait+0xc2>
          pid = pp->pid;
    80002492:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002496:	000b0e63          	beqz	s6,800024b2 <wait+0x76>
    8000249a:	4691                	li	a3,4
    8000249c:	02c48613          	addi	a2,s1,44
    800024a0:	85da                	mv	a1,s6
    800024a2:	05093503          	ld	a0,80(s2)
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	2d0080e7          	jalr	720(ra) # 80001776 <copyout>
    800024ae:	02054563          	bltz	a0,800024d8 <wait+0x9c>
          freeproc(pp);
    800024b2:	8526                	mv	a0,s1
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	7b8080e7          	jalr	1976(ra) # 80001c6c <freeproc>
          release(&pp->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	8da080e7          	jalr	-1830(ra) # 80000d98 <release>
          release(&wait_lock);
    800024c6:	0000f517          	auipc	a0,0xf
    800024ca:	04250513          	addi	a0,a0,66 # 80011508 <wait_lock>
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	8ca080e7          	jalr	-1846(ra) # 80000d98 <release>
          return pid;
    800024d6:	a0b5                	j	80002542 <wait+0x106>
            release(&pp->lock);
    800024d8:	8526                	mv	a0,s1
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	8be080e7          	jalr	-1858(ra) # 80000d98 <release>
            release(&wait_lock);
    800024e2:	0000f517          	auipc	a0,0xf
    800024e6:	02650513          	addi	a0,a0,38 # 80011508 <wait_lock>
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	8ae080e7          	jalr	-1874(ra) # 80000d98 <release>
            return -1;
    800024f2:	59fd                	li	s3,-1
    800024f4:	a0b9                	j	80002542 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024f6:	16848493          	addi	s1,s1,360
    800024fa:	03348463          	beq	s1,s3,80002522 <wait+0xe6>
      if(pp->parent == p){
    800024fe:	7c9c                	ld	a5,56(s1)
    80002500:	ff279be3          	bne	a5,s2,800024f6 <wait+0xba>
        acquire(&pp->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	7de080e7          	jalr	2014(ra) # 80000ce4 <acquire>
        if(pp->state == ZOMBIE){
    8000250e:	4c9c                	lw	a5,24(s1)
    80002510:	f94781e3          	beq	a5,s4,80002492 <wait+0x56>
        release(&pp->lock);
    80002514:	8526                	mv	a0,s1
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	882080e7          	jalr	-1918(ra) # 80000d98 <release>
        havekids = 1;
    8000251e:	8756                	mv	a4,s5
    80002520:	bfd9                	j	800024f6 <wait+0xba>
    if(!havekids || killed(p)){
    80002522:	c719                	beqz	a4,80002530 <wait+0xf4>
    80002524:	854a                	mv	a0,s2
    80002526:	00000097          	auipc	ra,0x0
    8000252a:	ee4080e7          	jalr	-284(ra) # 8000240a <killed>
    8000252e:	c51d                	beqz	a0,8000255c <wait+0x120>
      release(&wait_lock);
    80002530:	0000f517          	auipc	a0,0xf
    80002534:	fd850513          	addi	a0,a0,-40 # 80011508 <wait_lock>
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	860080e7          	jalr	-1952(ra) # 80000d98 <release>
      return -1;
    80002540:	59fd                	li	s3,-1
}
    80002542:	854e                	mv	a0,s3
    80002544:	60a6                	ld	ra,72(sp)
    80002546:	6406                	ld	s0,64(sp)
    80002548:	74e2                	ld	s1,56(sp)
    8000254a:	7942                	ld	s2,48(sp)
    8000254c:	79a2                	ld	s3,40(sp)
    8000254e:	7a02                	ld	s4,32(sp)
    80002550:	6ae2                	ld	s5,24(sp)
    80002552:	6b42                	ld	s6,16(sp)
    80002554:	6ba2                	ld	s7,8(sp)
    80002556:	6c02                	ld	s8,0(sp)
    80002558:	6161                	addi	sp,sp,80
    8000255a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000255c:	85e2                	mv	a1,s8
    8000255e:	854a                	mv	a0,s2
    80002560:	00000097          	auipc	ra,0x0
    80002564:	c02080e7          	jalr	-1022(ra) # 80002162 <sleep>
    havekids = 0;
    80002568:	bf39                	j	80002486 <wait+0x4a>

000000008000256a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000256a:	7179                	addi	sp,sp,-48
    8000256c:	f406                	sd	ra,40(sp)
    8000256e:	f022                	sd	s0,32(sp)
    80002570:	ec26                	sd	s1,24(sp)
    80002572:	e84a                	sd	s2,16(sp)
    80002574:	e44e                	sd	s3,8(sp)
    80002576:	e052                	sd	s4,0(sp)
    80002578:	1800                	addi	s0,sp,48
    8000257a:	84aa                	mv	s1,a0
    8000257c:	892e                	mv	s2,a1
    8000257e:	89b2                	mv	s3,a2
    80002580:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	538080e7          	jalr	1336(ra) # 80001aba <myproc>
  if(user_dst){
    8000258a:	c08d                	beqz	s1,800025ac <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000258c:	86d2                	mv	a3,s4
    8000258e:	864e                	mv	a2,s3
    80002590:	85ca                	mv	a1,s2
    80002592:	6928                	ld	a0,80(a0)
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	1e2080e7          	jalr	482(ra) # 80001776 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000259c:	70a2                	ld	ra,40(sp)
    8000259e:	7402                	ld	s0,32(sp)
    800025a0:	64e2                	ld	s1,24(sp)
    800025a2:	6942                	ld	s2,16(sp)
    800025a4:	69a2                	ld	s3,8(sp)
    800025a6:	6a02                	ld	s4,0(sp)
    800025a8:	6145                	addi	sp,sp,48
    800025aa:	8082                	ret
    memmove((char *)dst, src, len);
    800025ac:	000a061b          	sext.w	a2,s4
    800025b0:	85ce                	mv	a1,s3
    800025b2:	854a                	mv	a0,s2
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	888080e7          	jalr	-1912(ra) # 80000e3c <memmove>
    return 0;
    800025bc:	8526                	mv	a0,s1
    800025be:	bff9                	j	8000259c <either_copyout+0x32>

00000000800025c0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025c0:	7179                	addi	sp,sp,-48
    800025c2:	f406                	sd	ra,40(sp)
    800025c4:	f022                	sd	s0,32(sp)
    800025c6:	ec26                	sd	s1,24(sp)
    800025c8:	e84a                	sd	s2,16(sp)
    800025ca:	e44e                	sd	s3,8(sp)
    800025cc:	e052                	sd	s4,0(sp)
    800025ce:	1800                	addi	s0,sp,48
    800025d0:	892a                	mv	s2,a0
    800025d2:	84ae                	mv	s1,a1
    800025d4:	89b2                	mv	s3,a2
    800025d6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025d8:	fffff097          	auipc	ra,0xfffff
    800025dc:	4e2080e7          	jalr	1250(ra) # 80001aba <myproc>
  if(user_src){
    800025e0:	c08d                	beqz	s1,80002602 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025e2:	86d2                	mv	a3,s4
    800025e4:	864e                	mv	a2,s3
    800025e6:	85ca                	mv	a1,s2
    800025e8:	6928                	ld	a0,80(a0)
    800025ea:	fffff097          	auipc	ra,0xfffff
    800025ee:	218080e7          	jalr	536(ra) # 80001802 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025f2:	70a2                	ld	ra,40(sp)
    800025f4:	7402                	ld	s0,32(sp)
    800025f6:	64e2                	ld	s1,24(sp)
    800025f8:	6942                	ld	s2,16(sp)
    800025fa:	69a2                	ld	s3,8(sp)
    800025fc:	6a02                	ld	s4,0(sp)
    800025fe:	6145                	addi	sp,sp,48
    80002600:	8082                	ret
    memmove(dst, (char*)src, len);
    80002602:	000a061b          	sext.w	a2,s4
    80002606:	85ce                	mv	a1,s3
    80002608:	854a                	mv	a0,s2
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	832080e7          	jalr	-1998(ra) # 80000e3c <memmove>
    return 0;
    80002612:	8526                	mv	a0,s1
    80002614:	bff9                	j	800025f2 <either_copyin+0x32>

0000000080002616 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002616:	715d                	addi	sp,sp,-80
    80002618:	e486                	sd	ra,72(sp)
    8000261a:	e0a2                	sd	s0,64(sp)
    8000261c:	fc26                	sd	s1,56(sp)
    8000261e:	f84a                	sd	s2,48(sp)
    80002620:	f44e                	sd	s3,40(sp)
    80002622:	f052                	sd	s4,32(sp)
    80002624:	ec56                	sd	s5,24(sp)
    80002626:	e85a                	sd	s6,16(sp)
    80002628:	e45e                	sd	s7,8(sp)
    8000262a:	0880                	addi	s0,sp,80

  struct proc *p;
  char *state;

  printf("\n");
    8000262c:	00006517          	auipc	a0,0x6
    80002630:	cfc50513          	addi	a0,a0,-772 # 80008328 <digits+0x2e8>
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	062080e7          	jalr	98(ra) # 80000696 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000263c:	00010497          	auipc	s1,0x10
    80002640:	b7448493          	addi	s1,s1,-1164 # 800121b0 <proc+0x158>
    80002644:	00015917          	auipc	s2,0x15
    80002648:	56c90913          	addi	s2,s2,1388 # 80017bb0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000264c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000264e:	00006997          	auipc	s3,0x6
    80002652:	c3298993          	addi	s3,s3,-974 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002656:	00006a97          	auipc	s5,0x6
    8000265a:	c32a8a93          	addi	s5,s5,-974 # 80008288 <digits+0x248>
    printf("\n");
    8000265e:	00006a17          	auipc	s4,0x6
    80002662:	ccaa0a13          	addi	s4,s4,-822 # 80008328 <digits+0x2e8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002666:	00006b97          	auipc	s7,0x6
    8000266a:	d3ab8b93          	addi	s7,s7,-710 # 800083a0 <states>
    8000266e:	a00d                	j	80002690 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002670:	ed86a583          	lw	a1,-296(a3)
    80002674:	8556                	mv	a0,s5
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	020080e7          	jalr	32(ra) # 80000696 <printf>
    printf("\n");
    8000267e:	8552                	mv	a0,s4
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	016080e7          	jalr	22(ra) # 80000696 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002688:	16848493          	addi	s1,s1,360
    8000268c:	03248163          	beq	s1,s2,800026ae <procdump+0x98>
    if(p->state == UNUSED)
    80002690:	86a6                	mv	a3,s1
    80002692:	ec04a783          	lw	a5,-320(s1)
    80002696:	dbed                	beqz	a5,80002688 <procdump+0x72>
      state = "???";
    80002698:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000269a:	fcfb6be3          	bltu	s6,a5,80002670 <procdump+0x5a>
    8000269e:	1782                	slli	a5,a5,0x20
    800026a0:	9381                	srli	a5,a5,0x20
    800026a2:	078e                	slli	a5,a5,0x3
    800026a4:	97de                	add	a5,a5,s7
    800026a6:	6390                	ld	a2,0(a5)
    800026a8:	f661                	bnez	a2,80002670 <procdump+0x5a>
      state = "???";
    800026aa:	864e                	mv	a2,s3
    800026ac:	b7d1                	j	80002670 <procdump+0x5a>
  }
}
    800026ae:	60a6                	ld	ra,72(sp)
    800026b0:	6406                	ld	s0,64(sp)
    800026b2:	74e2                	ld	s1,56(sp)
    800026b4:	7942                	ld	s2,48(sp)
    800026b6:	79a2                	ld	s3,40(sp)
    800026b8:	7a02                	ld	s4,32(sp)
    800026ba:	6ae2                	ld	s5,24(sp)
    800026bc:	6b42                	ld	s6,16(sp)
    800026be:	6ba2                	ld	s7,8(sp)
    800026c0:	6161                	addi	sp,sp,80
    800026c2:	8082                	ret

00000000800026c4 <get_top_info>:


int get_top_info(void){
    800026c4:	7159                	addi	sp,sp,-112
    800026c6:	f486                	sd	ra,104(sp)
    800026c8:	f0a2                	sd	s0,96(sp)
    800026ca:	eca6                	sd	s1,88(sp)
    800026cc:	e8ca                	sd	s2,80(sp)
    800026ce:	e4ce                	sd	s3,72(sp)
    800026d0:	e0d2                	sd	s4,64(sp)
    800026d2:	fc56                	sd	s5,56(sp)
    800026d4:	f85a                	sd	s6,48(sp)
    800026d6:	f45e                	sd	s7,40(sp)
    800026d8:	f062                	sd	s8,32(sp)
    800026da:	ec66                	sd	s9,24(sp)
    800026dc:	e86a                	sd	s10,16(sp)
    800026de:	e46e                	sd	s11,8(sp)
    800026e0:	1880                	addi	s0,sp,112
//    consputc(t.running_process);
    int unusedCount = 0;
    int sleepCount = 0;
    int runningCount = 0;

    for (int i = 0; i < NPROC; i++) {
    800026e2:	00010797          	auipc	a5,0x10
    800026e6:	98e78793          	addi	a5,a5,-1650 # 80012070 <proc+0x18>
    800026ea:	00015697          	auipc	a3,0x15
    800026ee:	38668693          	addi	a3,a3,902 # 80017a70 <bcache>
    int runningCount = 0;
    800026f2:	4981                	li	s3,0
    int sleepCount = 0;
    800026f4:	4901                	li	s2,0
    int unusedCount = 0;
    800026f6:	4481                	li	s1,0
        if(proc[i].state == UNUSED){
            unusedCount++;
        }
        if(proc[i].state == SLEEPING){
    800026f8:	4609                	li	a2,2
            sleepCount++;
        }
        if(proc[i].state == RUNNING){
    800026fa:	4591                	li	a1,4
    800026fc:	a801                	j	8000270c <get_top_info+0x48>
        if(proc[i].state == SLEEPING){
    800026fe:	00c71b63          	bne	a4,a2,80002714 <get_top_info+0x50>
            sleepCount++;
    80002702:	2905                	addiw	s2,s2,1
    for (int i = 0; i < NPROC; i++) {
    80002704:	16878793          	addi	a5,a5,360
    80002708:	00d78a63          	beq	a5,a3,8000271c <get_top_info+0x58>
        if(proc[i].state == UNUSED){
    8000270c:	4398                	lw	a4,0(a5)
    8000270e:	fb65                	bnez	a4,800026fe <get_top_info+0x3a>
            unusedCount++;
    80002710:	2485                	addiw	s1,s1,1
        if(proc[i].state == RUNNING){
    80002712:	bfcd                	j	80002704 <get_top_info+0x40>
    80002714:	feb718e3          	bne	a4,a1,80002704 <get_top_info+0x40>
            runningCount++;
    80002718:	2985                	addiw	s3,s3,1
    8000271a:	b7ed                	j	80002704 <get_top_info+0x40>
        }


    }
    int uptime = 0;
    uptime = sys_uptime();
    8000271c:	00001097          	auipc	ra,0x1
    80002720:	904080e7          	jalr	-1788(ra) # 80003020 <sys_uptime>
    topp.uptime = uptime;
    80002724:	0005059b          	sext.w	a1,a0
    80002728:	0000fa17          	auipc	s4,0xf
    8000272c:	dc8a0a13          	addi	s4,s4,-568 # 800114f0 <pid_lock>
    80002730:	42ba3823          	sd	a1,1072(s4)
    topp.total_process = NPROC - unusedCount;
    80002734:	04000793          	li	a5,64
    80002738:	409784bb          	subw	s1,a5,s1
    8000273c:	429a2c23          	sw	s1,1080(s4)
    topp.running_process = runningCount;
    80002740:	433a2e23          	sw	s3,1084(s4)
    topp.sleeping_process = sleepCount;
    80002744:	452a2023          	sw	s2,1088(s4)
    printf("\nuptime:%d seconds",topp.uptime);
    80002748:	00006517          	auipc	a0,0x6
    8000274c:	b5050513          	addi	a0,a0,-1200 # 80008298 <digits+0x258>
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	f46080e7          	jalr	-186(ra) # 80000696 <printf>
    printf("\nTotal process: %d\n", topp.total_process);
    80002758:	438a2583          	lw	a1,1080(s4)
    8000275c:	00006517          	auipc	a0,0x6
    80002760:	b5450513          	addi	a0,a0,-1196 # 800082b0 <digits+0x270>
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	f32080e7          	jalr	-206(ra) # 80000696 <printf>
    printf("Running process: %d\n",   topp.running_process);
    8000276c:	43ca2583          	lw	a1,1084(s4)
    80002770:	00006517          	auipc	a0,0x6
    80002774:	b5850513          	addi	a0,a0,-1192 # 800082c8 <digits+0x288>
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	f1e080e7          	jalr	-226(ra) # 80000696 <printf>
    printf("Sleeping process: %d\n", topp.sleeping_process);
    80002780:	440a2583          	lw	a1,1088(s4)
    80002784:	00006517          	auipc	a0,0x6
    80002788:	b5c50513          	addi	a0,a0,-1188 # 800082e0 <digits+0x2a0>
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	f0a080e7          	jalr	-246(ra) # 80000696 <printf>

    struct proc *pointer;
    char *state;


    printf("process data:\n");
    80002794:	00006517          	auipc	a0,0x6
    80002798:	b6450513          	addi	a0,a0,-1180 # 800082f8 <digits+0x2b8>
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	efa080e7          	jalr	-262(ra) # 80000696 <printf>
    printf("name    PID    state        PPID\n" );
    800027a4:	00006517          	auipc	a0,0x6
    800027a8:	b6450513          	addi	a0,a0,-1180 # 80008308 <digits+0x2c8>
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	eea080e7          	jalr	-278(ra) # 80000696 <printf>
    for(pointer = proc; pointer < &proc[NPROC]; pointer++){
    800027b4:	00010497          	auipc	s1,0x10
    800027b8:	9fc48493          	addi	s1,s1,-1540 # 800121b0 <proc+0x158>
    800027bc:	00010a17          	auipc	s4,0x10
    800027c0:	89ca0a13          	addi	s4,s4,-1892 # 80012058 <proc>
    800027c4:	6799                	lui	a5,0x6
    800027c6:	b5878793          	addi	a5,a5,-1192 # 5b58 <_entry-0x7fffa4a8>
    800027ca:	9a3e                	add	s4,s4,a5
        if(pointer->state == UNUSED)
            continue;
        if(pointer->state >= 0 && pointer->state < NELEM(states) && states[pointer->state])
    800027cc:	4c15                	li	s8,5
            state = states[pointer->state];
        else
            state = "???";
    800027ce:	00006a97          	auipc	s5,0x6
    800027d2:	ab2a8a93          	addi	s5,s5,-1358 # 80008280 <digits+0x240>


        info.pid = pointer->pid;
    800027d6:	00010997          	auipc	s3,0x10
    800027da:	d1a98993          	addi	s3,s3,-742 # 800124f0 <proc+0x498>
        printf("%s      %d      %s",  pointer->name, info.pid, state );
    800027de:	00006b97          	auipc	s7,0x6
    800027e2:	b52b8b93          	addi	s7,s7,-1198 # 80008330 <digits+0x2f0>
        }
        else{
            info.ppid = 0;
            printf("    %d", info.ppid);
        }
        printf("\n");
    800027e6:	00006b17          	auipc	s6,0x6
    800027ea:	b42b0b13          	addi	s6,s6,-1214 # 80008328 <digits+0x2e8>
            printf("    %d", info.ppid);
    800027ee:	00006d97          	auipc	s11,0x6
    800027f2:	b6ad8d93          	addi	s11,s11,-1174 # 80008358 <digits+0x318>
            printf("        %d", info.ppid);
    800027f6:	00006c97          	auipc	s9,0x6
    800027fa:	b52c8c93          	addi	s9,s9,-1198 # 80008348 <digits+0x308>
        if(pointer->state >= 0 && pointer->state < NELEM(states) && states[pointer->state])
    800027fe:	00006d17          	auipc	s10,0x6
    80002802:	ba2d0d13          	addi	s10,s10,-1118 # 800083a0 <states>
    80002806:	a83d                	j	80002844 <get_top_info+0x180>
        info.pid = pointer->pid;
    80002808:	ed892603          	lw	a2,-296(s2)
    8000280c:	b4c9ac23          	sw	a2,-1192(s3)
        printf("%s      %d      %s",  pointer->name, info.pid, state );
    80002810:	85ca                	mv	a1,s2
    80002812:	855e                	mv	a0,s7
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	e82080e7          	jalr	-382(ra) # 80000696 <printf>
        if(pointer->parent != 0){
    8000281c:	ee093783          	ld	a5,-288(s2)
    80002820:	c3a9                	beqz	a5,80002862 <get_top_info+0x19e>
            info.ppid = pointer->parent->pid;
    80002822:	5b8c                	lw	a1,48(a5)
    80002824:	b4b9ae23          	sw	a1,-1188(s3)
            printf("        %d", info.ppid);
    80002828:	8566                	mv	a0,s9
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	e6c080e7          	jalr	-404(ra) # 80000696 <printf>
        printf("\n");
    80002832:	855a                	mv	a0,s6
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	e62080e7          	jalr	-414(ra) # 80000696 <printf>
    for(pointer = proc; pointer < &proc[NPROC]; pointer++){
    8000283c:	16848493          	addi	s1,s1,360
    80002840:	03448a63          	beq	s1,s4,80002874 <get_top_info+0x1b0>
        if(pointer->state == UNUSED)
    80002844:	8926                	mv	s2,s1
    80002846:	ec04a783          	lw	a5,-320(s1)
    8000284a:	dbed                	beqz	a5,8000283c <get_top_info+0x178>
            state = "???";
    8000284c:	86d6                	mv	a3,s5
        if(pointer->state >= 0 && pointer->state < NELEM(states) && states[pointer->state])
    8000284e:	fafc6de3          	bltu	s8,a5,80002808 <get_top_info+0x144>
    80002852:	1782                	slli	a5,a5,0x20
    80002854:	9381                	srli	a5,a5,0x20
    80002856:	078e                	slli	a5,a5,0x3
    80002858:	97ea                	add	a5,a5,s10
    8000285a:	6394                	ld	a3,0(a5)
    8000285c:	f6d5                	bnez	a3,80002808 <get_top_info+0x144>
            state = "???";
    8000285e:	86d6                	mv	a3,s5
    80002860:	b765                	j	80002808 <get_top_info+0x144>
            info.ppid = 0;
    80002862:	b409ae23          	sw	zero,-1188(s3)
            printf("    %d", info.ppid);
    80002866:	4581                	li	a1,0
    80002868:	856e                	mv	a0,s11
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	e2c080e7          	jalr	-468(ra) # 80000696 <printf>
    80002872:	b7c1                	j	80002832 <get_top_info+0x16e>



    return 0;

}
    80002874:	4501                	li	a0,0
    80002876:	70a6                	ld	ra,104(sp)
    80002878:	7406                	ld	s0,96(sp)
    8000287a:	64e6                	ld	s1,88(sp)
    8000287c:	6946                	ld	s2,80(sp)
    8000287e:	69a6                	ld	s3,72(sp)
    80002880:	6a06                	ld	s4,64(sp)
    80002882:	7ae2                	ld	s5,56(sp)
    80002884:	7b42                	ld	s6,48(sp)
    80002886:	7ba2                	ld	s7,40(sp)
    80002888:	7c02                	ld	s8,32(sp)
    8000288a:	6ce2                	ld	s9,24(sp)
    8000288c:	6d42                	ld	s10,16(sp)
    8000288e:	6da2                	ld	s11,8(sp)
    80002890:	6165                	addi	sp,sp,112
    80002892:	8082                	ret

0000000080002894 <swtch>:
    80002894:	00153023          	sd	ra,0(a0)
    80002898:	00253423          	sd	sp,8(a0)
    8000289c:	e900                	sd	s0,16(a0)
    8000289e:	ed04                	sd	s1,24(a0)
    800028a0:	03253023          	sd	s2,32(a0)
    800028a4:	03353423          	sd	s3,40(a0)
    800028a8:	03453823          	sd	s4,48(a0)
    800028ac:	03553c23          	sd	s5,56(a0)
    800028b0:	05653023          	sd	s6,64(a0)
    800028b4:	05753423          	sd	s7,72(a0)
    800028b8:	05853823          	sd	s8,80(a0)
    800028bc:	05953c23          	sd	s9,88(a0)
    800028c0:	07a53023          	sd	s10,96(a0)
    800028c4:	07b53423          	sd	s11,104(a0)
    800028c8:	0005b083          	ld	ra,0(a1)
    800028cc:	0085b103          	ld	sp,8(a1)
    800028d0:	6980                	ld	s0,16(a1)
    800028d2:	6d84                	ld	s1,24(a1)
    800028d4:	0205b903          	ld	s2,32(a1)
    800028d8:	0285b983          	ld	s3,40(a1)
    800028dc:	0305ba03          	ld	s4,48(a1)
    800028e0:	0385ba83          	ld	s5,56(a1)
    800028e4:	0405bb03          	ld	s6,64(a1)
    800028e8:	0485bb83          	ld	s7,72(a1)
    800028ec:	0505bc03          	ld	s8,80(a1)
    800028f0:	0585bc83          	ld	s9,88(a1)
    800028f4:	0605bd03          	ld	s10,96(a1)
    800028f8:	0685bd83          	ld	s11,104(a1)
    800028fc:	8082                	ret

00000000800028fe <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028fe:	1141                	addi	sp,sp,-16
    80002900:	e406                	sd	ra,8(sp)
    80002902:	e022                	sd	s0,0(sp)
    80002904:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002906:	00006597          	auipc	a1,0x6
    8000290a:	aca58593          	addi	a1,a1,-1334 # 800083d0 <states+0x30>
    8000290e:	00015517          	auipc	a0,0x15
    80002912:	14a50513          	addi	a0,a0,330 # 80017a58 <tickslock>
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	33e080e7          	jalr	830(ra) # 80000c54 <initlock>
}
    8000291e:	60a2                	ld	ra,8(sp)
    80002920:	6402                	ld	s0,0(sp)
    80002922:	0141                	addi	sp,sp,16
    80002924:	8082                	ret

0000000080002926 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002926:	1141                	addi	sp,sp,-16
    80002928:	e422                	sd	s0,8(sp)
    8000292a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000292c:	00003797          	auipc	a5,0x3
    80002930:	54478793          	addi	a5,a5,1348 # 80005e70 <kernelvec>
    80002934:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002938:	6422                	ld	s0,8(sp)
    8000293a:	0141                	addi	sp,sp,16
    8000293c:	8082                	ret

000000008000293e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000293e:	1141                	addi	sp,sp,-16
    80002940:	e406                	sd	ra,8(sp)
    80002942:	e022                	sd	s0,0(sp)
    80002944:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002946:	fffff097          	auipc	ra,0xfffff
    8000294a:	174080e7          	jalr	372(ra) # 80001aba <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000294e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002952:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002954:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002958:	00004617          	auipc	a2,0x4
    8000295c:	6a860613          	addi	a2,a2,1704 # 80007000 <_trampoline>
    80002960:	00004697          	auipc	a3,0x4
    80002964:	6a068693          	addi	a3,a3,1696 # 80007000 <_trampoline>
    80002968:	8e91                	sub	a3,a3,a2
    8000296a:	040007b7          	lui	a5,0x4000
    8000296e:	17fd                	addi	a5,a5,-1
    80002970:	07b2                	slli	a5,a5,0xc
    80002972:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002974:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002978:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000297a:	180026f3          	csrr	a3,satp
    8000297e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002980:	6d38                	ld	a4,88(a0)
    80002982:	6134                	ld	a3,64(a0)
    80002984:	6585                	lui	a1,0x1
    80002986:	96ae                	add	a3,a3,a1
    80002988:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000298a:	6d38                	ld	a4,88(a0)
    8000298c:	00000697          	auipc	a3,0x0
    80002990:	13068693          	addi	a3,a3,304 # 80002abc <usertrap>
    80002994:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002996:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002998:	8692                	mv	a3,tp
    8000299a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029a0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029a4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029ac:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ae:	6f18                	ld	a4,24(a4)
    800029b0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029b4:	6928                	ld	a0,80(a0)
    800029b6:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800029b8:	00004717          	auipc	a4,0x4
    800029bc:	6e470713          	addi	a4,a4,1764 # 8000709c <userret>
    800029c0:	8f11                	sub	a4,a4,a2
    800029c2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800029c4:	577d                	li	a4,-1
    800029c6:	177e                	slli	a4,a4,0x3f
    800029c8:	8d59                	or	a0,a0,a4
    800029ca:	9782                	jalr	a5
}
    800029cc:	60a2                	ld	ra,8(sp)
    800029ce:	6402                	ld	s0,0(sp)
    800029d0:	0141                	addi	sp,sp,16
    800029d2:	8082                	ret

00000000800029d4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029d4:	1101                	addi	sp,sp,-32
    800029d6:	ec06                	sd	ra,24(sp)
    800029d8:	e822                	sd	s0,16(sp)
    800029da:	e426                	sd	s1,8(sp)
    800029dc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029de:	00015497          	auipc	s1,0x15
    800029e2:	07a48493          	addi	s1,s1,122 # 80017a58 <tickslock>
    800029e6:	8526                	mv	a0,s1
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	2fc080e7          	jalr	764(ra) # 80000ce4 <acquire>
  ticks++;
    800029f0:	00006517          	auipc	a0,0x6
    800029f4:	fc850513          	addi	a0,a0,-56 # 800089b8 <ticks>
    800029f8:	411c                	lw	a5,0(a0)
    800029fa:	2785                	addiw	a5,a5,1
    800029fc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029fe:	fffff097          	auipc	ra,0xfffff
    80002a02:	7c8080e7          	jalr	1992(ra) # 800021c6 <wakeup>
  release(&tickslock);
    80002a06:	8526                	mv	a0,s1
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	390080e7          	jalr	912(ra) # 80000d98 <release>
}
    80002a10:	60e2                	ld	ra,24(sp)
    80002a12:	6442                	ld	s0,16(sp)
    80002a14:	64a2                	ld	s1,8(sp)
    80002a16:	6105                	addi	sp,sp,32
    80002a18:	8082                	ret

0000000080002a1a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a1a:	1101                	addi	sp,sp,-32
    80002a1c:	ec06                	sd	ra,24(sp)
    80002a1e:	e822                	sd	s0,16(sp)
    80002a20:	e426                	sd	s1,8(sp)
    80002a22:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a24:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a28:	00074d63          	bltz	a4,80002a42 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a2c:	57fd                	li	a5,-1
    80002a2e:	17fe                	slli	a5,a5,0x3f
    80002a30:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a32:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a34:	06f70363          	beq	a4,a5,80002a9a <devintr+0x80>
  }
}
    80002a38:	60e2                	ld	ra,24(sp)
    80002a3a:	6442                	ld	s0,16(sp)
    80002a3c:	64a2                	ld	s1,8(sp)
    80002a3e:	6105                	addi	sp,sp,32
    80002a40:	8082                	ret
     (scause & 0xff) == 9){
    80002a42:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a46:	46a5                	li	a3,9
    80002a48:	fed792e3          	bne	a5,a3,80002a2c <devintr+0x12>
    int irq = plic_claim();
    80002a4c:	00003097          	auipc	ra,0x3
    80002a50:	52c080e7          	jalr	1324(ra) # 80005f78 <plic_claim>
    80002a54:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a56:	47a9                	li	a5,10
    80002a58:	02f50763          	beq	a0,a5,80002a86 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a5c:	4785                	li	a5,1
    80002a5e:	02f50963          	beq	a0,a5,80002a90 <devintr+0x76>
    return 1;
    80002a62:	4505                	li	a0,1
    } else if(irq){
    80002a64:	d8f1                	beqz	s1,80002a38 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a66:	85a6                	mv	a1,s1
    80002a68:	00006517          	auipc	a0,0x6
    80002a6c:	97050513          	addi	a0,a0,-1680 # 800083d8 <states+0x38>
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	c26080e7          	jalr	-986(ra) # 80000696 <printf>
      plic_complete(irq);
    80002a78:	8526                	mv	a0,s1
    80002a7a:	00003097          	auipc	ra,0x3
    80002a7e:	522080e7          	jalr	1314(ra) # 80005f9c <plic_complete>
    return 1;
    80002a82:	4505                	li	a0,1
    80002a84:	bf55                	j	80002a38 <devintr+0x1e>
      uartintr();
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	022080e7          	jalr	34(ra) # 80000aa8 <uartintr>
    80002a8e:	b7ed                	j	80002a78 <devintr+0x5e>
      virtio_disk_intr();
    80002a90:	00004097          	auipc	ra,0x4
    80002a94:	9d8080e7          	jalr	-1576(ra) # 80006468 <virtio_disk_intr>
    80002a98:	b7c5                	j	80002a78 <devintr+0x5e>
    if(cpuid() == 0){
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	ff4080e7          	jalr	-12(ra) # 80001a8e <cpuid>
    80002aa2:	c901                	beqz	a0,80002ab2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002aa4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aa8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002aaa:	14479073          	csrw	sip,a5
    return 2;
    80002aae:	4509                	li	a0,2
    80002ab0:	b761                	j	80002a38 <devintr+0x1e>
      clockintr();
    80002ab2:	00000097          	auipc	ra,0x0
    80002ab6:	f22080e7          	jalr	-222(ra) # 800029d4 <clockintr>
    80002aba:	b7ed                	j	80002aa4 <devintr+0x8a>

0000000080002abc <usertrap>:
{
    80002abc:	1101                	addi	sp,sp,-32
    80002abe:	ec06                	sd	ra,24(sp)
    80002ac0:	e822                	sd	s0,16(sp)
    80002ac2:	e426                	sd	s1,8(sp)
    80002ac4:	e04a                	sd	s2,0(sp)
    80002ac6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002acc:	1007f793          	andi	a5,a5,256
    80002ad0:	e3b1                	bnez	a5,80002b14 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ad2:	00003797          	auipc	a5,0x3
    80002ad6:	39e78793          	addi	a5,a5,926 # 80005e70 <kernelvec>
    80002ada:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	fdc080e7          	jalr	-36(ra) # 80001aba <myproc>
    80002ae6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ae8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aea:	14102773          	csrr	a4,sepc
    80002aee:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002af0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002af4:	47a1                	li	a5,8
    80002af6:	02f70763          	beq	a4,a5,80002b24 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002afa:	00000097          	auipc	ra,0x0
    80002afe:	f20080e7          	jalr	-224(ra) # 80002a1a <devintr>
    80002b02:	892a                	mv	s2,a0
    80002b04:	c151                	beqz	a0,80002b88 <usertrap+0xcc>
  if(killed(p))
    80002b06:	8526                	mv	a0,s1
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	902080e7          	jalr	-1790(ra) # 8000240a <killed>
    80002b10:	c929                	beqz	a0,80002b62 <usertrap+0xa6>
    80002b12:	a099                	j	80002b58 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	8e450513          	addi	a0,a0,-1820 # 800083f8 <states+0x58>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	b30080e7          	jalr	-1232(ra) # 8000064c <panic>
    if(killed(p))
    80002b24:	00000097          	auipc	ra,0x0
    80002b28:	8e6080e7          	jalr	-1818(ra) # 8000240a <killed>
    80002b2c:	e921                	bnez	a0,80002b7c <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002b2e:	6cb8                	ld	a4,88(s1)
    80002b30:	6f1c                	ld	a5,24(a4)
    80002b32:	0791                	addi	a5,a5,4
    80002b34:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b36:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b3a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b3e:	10079073          	csrw	sstatus,a5
    syscall();
    80002b42:	00000097          	auipc	ra,0x0
    80002b46:	2d4080e7          	jalr	724(ra) # 80002e16 <syscall>
  if(killed(p))
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	00000097          	auipc	ra,0x0
    80002b50:	8be080e7          	jalr	-1858(ra) # 8000240a <killed>
    80002b54:	c911                	beqz	a0,80002b68 <usertrap+0xac>
    80002b56:	4901                	li	s2,0
    exit(-1);
    80002b58:	557d                	li	a0,-1
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	73c080e7          	jalr	1852(ra) # 80002296 <exit>
  if(which_dev == 2)
    80002b62:	4789                	li	a5,2
    80002b64:	04f90f63          	beq	s2,a5,80002bc2 <usertrap+0x106>
  usertrapret();
    80002b68:	00000097          	auipc	ra,0x0
    80002b6c:	dd6080e7          	jalr	-554(ra) # 8000293e <usertrapret>
}
    80002b70:	60e2                	ld	ra,24(sp)
    80002b72:	6442                	ld	s0,16(sp)
    80002b74:	64a2                	ld	s1,8(sp)
    80002b76:	6902                	ld	s2,0(sp)
    80002b78:	6105                	addi	sp,sp,32
    80002b7a:	8082                	ret
      exit(-1);
    80002b7c:	557d                	li	a0,-1
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	718080e7          	jalr	1816(ra) # 80002296 <exit>
    80002b86:	b765                	j	80002b2e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b88:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b8c:	5890                	lw	a2,48(s1)
    80002b8e:	00006517          	auipc	a0,0x6
    80002b92:	88a50513          	addi	a0,a0,-1910 # 80008418 <states+0x78>
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	b00080e7          	jalr	-1280(ra) # 80000696 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b9e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ba2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ba6:	00006517          	auipc	a0,0x6
    80002baa:	8a250513          	addi	a0,a0,-1886 # 80008448 <states+0xa8>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	ae8080e7          	jalr	-1304(ra) # 80000696 <printf>
    setkilled(p);
    80002bb6:	8526                	mv	a0,s1
    80002bb8:	00000097          	auipc	ra,0x0
    80002bbc:	826080e7          	jalr	-2010(ra) # 800023de <setkilled>
    80002bc0:	b769                	j	80002b4a <usertrap+0x8e>
    yield();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	564080e7          	jalr	1380(ra) # 80002126 <yield>
    80002bca:	bf79                	j	80002b68 <usertrap+0xac>

0000000080002bcc <kerneltrap>:
{
    80002bcc:	7179                	addi	sp,sp,-48
    80002bce:	f406                	sd	ra,40(sp)
    80002bd0:	f022                	sd	s0,32(sp)
    80002bd2:	ec26                	sd	s1,24(sp)
    80002bd4:	e84a                	sd	s2,16(sp)
    80002bd6:	e44e                	sd	s3,8(sp)
    80002bd8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bda:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bde:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002be6:	1004f793          	andi	a5,s1,256
    80002bea:	cb85                	beqz	a5,80002c1a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bf0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bf2:	ef85                	bnez	a5,80002c2a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bf4:	00000097          	auipc	ra,0x0
    80002bf8:	e26080e7          	jalr	-474(ra) # 80002a1a <devintr>
    80002bfc:	cd1d                	beqz	a0,80002c3a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bfe:	4789                	li	a5,2
    80002c00:	06f50a63          	beq	a0,a5,80002c74 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c04:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c08:	10049073          	csrw	sstatus,s1
}
    80002c0c:	70a2                	ld	ra,40(sp)
    80002c0e:	7402                	ld	s0,32(sp)
    80002c10:	64e2                	ld	s1,24(sp)
    80002c12:	6942                	ld	s2,16(sp)
    80002c14:	69a2                	ld	s3,8(sp)
    80002c16:	6145                	addi	sp,sp,48
    80002c18:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c1a:	00006517          	auipc	a0,0x6
    80002c1e:	84e50513          	addi	a0,a0,-1970 # 80008468 <states+0xc8>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	a2a080e7          	jalr	-1494(ra) # 8000064c <panic>
    panic("kerneltrap: interrupts enabled");
    80002c2a:	00006517          	auipc	a0,0x6
    80002c2e:	86650513          	addi	a0,a0,-1946 # 80008490 <states+0xf0>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	a1a080e7          	jalr	-1510(ra) # 8000064c <panic>
    printf("scause %p\n", scause);
    80002c3a:	85ce                	mv	a1,s3
    80002c3c:	00006517          	auipc	a0,0x6
    80002c40:	87450513          	addi	a0,a0,-1932 # 800084b0 <states+0x110>
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	a52080e7          	jalr	-1454(ra) # 80000696 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c4c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c50:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c54:	00006517          	auipc	a0,0x6
    80002c58:	86c50513          	addi	a0,a0,-1940 # 800084c0 <states+0x120>
    80002c5c:	ffffe097          	auipc	ra,0xffffe
    80002c60:	a3a080e7          	jalr	-1478(ra) # 80000696 <printf>
    panic("kerneltrap");
    80002c64:	00006517          	auipc	a0,0x6
    80002c68:	87450513          	addi	a0,a0,-1932 # 800084d8 <states+0x138>
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	9e0080e7          	jalr	-1568(ra) # 8000064c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	e46080e7          	jalr	-442(ra) # 80001aba <myproc>
    80002c7c:	d541                	beqz	a0,80002c04 <kerneltrap+0x38>
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	e3c080e7          	jalr	-452(ra) # 80001aba <myproc>
    80002c86:	4d18                	lw	a4,24(a0)
    80002c88:	4791                	li	a5,4
    80002c8a:	f6f71de3          	bne	a4,a5,80002c04 <kerneltrap+0x38>
    yield();
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	498080e7          	jalr	1176(ra) # 80002126 <yield>
    80002c96:	b7bd                	j	80002c04 <kerneltrap+0x38>

0000000080002c98 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c98:	1101                	addi	sp,sp,-32
    80002c9a:	ec06                	sd	ra,24(sp)
    80002c9c:	e822                	sd	s0,16(sp)
    80002c9e:	e426                	sd	s1,8(sp)
    80002ca0:	1000                	addi	s0,sp,32
    80002ca2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ca4:	fffff097          	auipc	ra,0xfffff
    80002ca8:	e16080e7          	jalr	-490(ra) # 80001aba <myproc>
  switch (n) {
    80002cac:	4795                	li	a5,5
    80002cae:	0497e163          	bltu	a5,s1,80002cf0 <argraw+0x58>
    80002cb2:	048a                	slli	s1,s1,0x2
    80002cb4:	00006717          	auipc	a4,0x6
    80002cb8:	85c70713          	addi	a4,a4,-1956 # 80008510 <states+0x170>
    80002cbc:	94ba                	add	s1,s1,a4
    80002cbe:	409c                	lw	a5,0(s1)
    80002cc0:	97ba                	add	a5,a5,a4
    80002cc2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cc4:	6d3c                	ld	a5,88(a0)
    80002cc6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cc8:	60e2                	ld	ra,24(sp)
    80002cca:	6442                	ld	s0,16(sp)
    80002ccc:	64a2                	ld	s1,8(sp)
    80002cce:	6105                	addi	sp,sp,32
    80002cd0:	8082                	ret
    return p->trapframe->a1;
    80002cd2:	6d3c                	ld	a5,88(a0)
    80002cd4:	7fa8                	ld	a0,120(a5)
    80002cd6:	bfcd                	j	80002cc8 <argraw+0x30>
    return p->trapframe->a2;
    80002cd8:	6d3c                	ld	a5,88(a0)
    80002cda:	63c8                	ld	a0,128(a5)
    80002cdc:	b7f5                	j	80002cc8 <argraw+0x30>
    return p->trapframe->a3;
    80002cde:	6d3c                	ld	a5,88(a0)
    80002ce0:	67c8                	ld	a0,136(a5)
    80002ce2:	b7dd                	j	80002cc8 <argraw+0x30>
    return p->trapframe->a4;
    80002ce4:	6d3c                	ld	a5,88(a0)
    80002ce6:	6bc8                	ld	a0,144(a5)
    80002ce8:	b7c5                	j	80002cc8 <argraw+0x30>
    return p->trapframe->a5;
    80002cea:	6d3c                	ld	a5,88(a0)
    80002cec:	6fc8                	ld	a0,152(a5)
    80002cee:	bfe9                	j	80002cc8 <argraw+0x30>
  panic("argraw");
    80002cf0:	00005517          	auipc	a0,0x5
    80002cf4:	7f850513          	addi	a0,a0,2040 # 800084e8 <states+0x148>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	954080e7          	jalr	-1708(ra) # 8000064c <panic>

0000000080002d00 <fetchaddr>:
{
    80002d00:	1101                	addi	sp,sp,-32
    80002d02:	ec06                	sd	ra,24(sp)
    80002d04:	e822                	sd	s0,16(sp)
    80002d06:	e426                	sd	s1,8(sp)
    80002d08:	e04a                	sd	s2,0(sp)
    80002d0a:	1000                	addi	s0,sp,32
    80002d0c:	84aa                	mv	s1,a0
    80002d0e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	daa080e7          	jalr	-598(ra) # 80001aba <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d18:	653c                	ld	a5,72(a0)
    80002d1a:	02f4f863          	bgeu	s1,a5,80002d4a <fetchaddr+0x4a>
    80002d1e:	00848713          	addi	a4,s1,8
    80002d22:	02e7e663          	bltu	a5,a4,80002d4e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d26:	46a1                	li	a3,8
    80002d28:	8626                	mv	a2,s1
    80002d2a:	85ca                	mv	a1,s2
    80002d2c:	6928                	ld	a0,80(a0)
    80002d2e:	fffff097          	auipc	ra,0xfffff
    80002d32:	ad4080e7          	jalr	-1324(ra) # 80001802 <copyin>
    80002d36:	00a03533          	snez	a0,a0
    80002d3a:	40a00533          	neg	a0,a0
}
    80002d3e:	60e2                	ld	ra,24(sp)
    80002d40:	6442                	ld	s0,16(sp)
    80002d42:	64a2                	ld	s1,8(sp)
    80002d44:	6902                	ld	s2,0(sp)
    80002d46:	6105                	addi	sp,sp,32
    80002d48:	8082                	ret
    return -1;
    80002d4a:	557d                	li	a0,-1
    80002d4c:	bfcd                	j	80002d3e <fetchaddr+0x3e>
    80002d4e:	557d                	li	a0,-1
    80002d50:	b7fd                	j	80002d3e <fetchaddr+0x3e>

0000000080002d52 <fetchstr>:
{
    80002d52:	7179                	addi	sp,sp,-48
    80002d54:	f406                	sd	ra,40(sp)
    80002d56:	f022                	sd	s0,32(sp)
    80002d58:	ec26                	sd	s1,24(sp)
    80002d5a:	e84a                	sd	s2,16(sp)
    80002d5c:	e44e                	sd	s3,8(sp)
    80002d5e:	1800                	addi	s0,sp,48
    80002d60:	892a                	mv	s2,a0
    80002d62:	84ae                	mv	s1,a1
    80002d64:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	d54080e7          	jalr	-684(ra) # 80001aba <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d6e:	86ce                	mv	a3,s3
    80002d70:	864a                	mv	a2,s2
    80002d72:	85a6                	mv	a1,s1
    80002d74:	6928                	ld	a0,80(a0)
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	b1a080e7          	jalr	-1254(ra) # 80001890 <copyinstr>
    80002d7e:	00054e63          	bltz	a0,80002d9a <fetchstr+0x48>
  return strlen(buf);
    80002d82:	8526                	mv	a0,s1
    80002d84:	ffffe097          	auipc	ra,0xffffe
    80002d88:	1d8080e7          	jalr	472(ra) # 80000f5c <strlen>
}
    80002d8c:	70a2                	ld	ra,40(sp)
    80002d8e:	7402                	ld	s0,32(sp)
    80002d90:	64e2                	ld	s1,24(sp)
    80002d92:	6942                	ld	s2,16(sp)
    80002d94:	69a2                	ld	s3,8(sp)
    80002d96:	6145                	addi	sp,sp,48
    80002d98:	8082                	ret
    return -1;
    80002d9a:	557d                	li	a0,-1
    80002d9c:	bfc5                	j	80002d8c <fetchstr+0x3a>

0000000080002d9e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d9e:	1101                	addi	sp,sp,-32
    80002da0:	ec06                	sd	ra,24(sp)
    80002da2:	e822                	sd	s0,16(sp)
    80002da4:	e426                	sd	s1,8(sp)
    80002da6:	1000                	addi	s0,sp,32
    80002da8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002daa:	00000097          	auipc	ra,0x0
    80002dae:	eee080e7          	jalr	-274(ra) # 80002c98 <argraw>
    80002db2:	c088                	sw	a0,0(s1)
}
    80002db4:	60e2                	ld	ra,24(sp)
    80002db6:	6442                	ld	s0,16(sp)
    80002db8:	64a2                	ld	s1,8(sp)
    80002dba:	6105                	addi	sp,sp,32
    80002dbc:	8082                	ret

0000000080002dbe <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002dbe:	1101                	addi	sp,sp,-32
    80002dc0:	ec06                	sd	ra,24(sp)
    80002dc2:	e822                	sd	s0,16(sp)
    80002dc4:	e426                	sd	s1,8(sp)
    80002dc6:	1000                	addi	s0,sp,32
    80002dc8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dca:	00000097          	auipc	ra,0x0
    80002dce:	ece080e7          	jalr	-306(ra) # 80002c98 <argraw>
    80002dd2:	e088                	sd	a0,0(s1)
}
    80002dd4:	60e2                	ld	ra,24(sp)
    80002dd6:	6442                	ld	s0,16(sp)
    80002dd8:	64a2                	ld	s1,8(sp)
    80002dda:	6105                	addi	sp,sp,32
    80002ddc:	8082                	ret

0000000080002dde <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dde:	7179                	addi	sp,sp,-48
    80002de0:	f406                	sd	ra,40(sp)
    80002de2:	f022                	sd	s0,32(sp)
    80002de4:	ec26                	sd	s1,24(sp)
    80002de6:	e84a                	sd	s2,16(sp)
    80002de8:	1800                	addi	s0,sp,48
    80002dea:	84ae                	mv	s1,a1
    80002dec:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002dee:	fd840593          	addi	a1,s0,-40
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	fcc080e7          	jalr	-52(ra) # 80002dbe <argaddr>
  return fetchstr(addr, buf, max);
    80002dfa:	864a                	mv	a2,s2
    80002dfc:	85a6                	mv	a1,s1
    80002dfe:	fd843503          	ld	a0,-40(s0)
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	f50080e7          	jalr	-176(ra) # 80002d52 <fetchstr>
}
    80002e0a:	70a2                	ld	ra,40(sp)
    80002e0c:	7402                	ld	s0,32(sp)
    80002e0e:	64e2                	ld	s1,24(sp)
    80002e10:	6942                	ld	s2,16(sp)
    80002e12:	6145                	addi	sp,sp,48
    80002e14:	8082                	ret

0000000080002e16 <syscall>:

};

void
syscall(void)
{
    80002e16:	1101                	addi	sp,sp,-32
    80002e18:	ec06                	sd	ra,24(sp)
    80002e1a:	e822                	sd	s0,16(sp)
    80002e1c:	e426                	sd	s1,8(sp)
    80002e1e:	e04a                	sd	s2,0(sp)
    80002e20:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	c98080e7          	jalr	-872(ra) # 80001aba <myproc>
    80002e2a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e2c:	05853903          	ld	s2,88(a0)
    80002e30:	0a893783          	ld	a5,168(s2)
    80002e34:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e38:	37fd                	addiw	a5,a5,-1
    80002e3a:	4759                	li	a4,22
    80002e3c:	00f76f63          	bltu	a4,a5,80002e5a <syscall+0x44>
    80002e40:	00369713          	slli	a4,a3,0x3
    80002e44:	00005797          	auipc	a5,0x5
    80002e48:	6e478793          	addi	a5,a5,1764 # 80008528 <syscalls>
    80002e4c:	97ba                	add	a5,a5,a4
    80002e4e:	639c                	ld	a5,0(a5)
    80002e50:	c789                	beqz	a5,80002e5a <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e52:	9782                	jalr	a5
    80002e54:	06a93823          	sd	a0,112(s2)
    80002e58:	a839                	j	80002e76 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e5a:	15848613          	addi	a2,s1,344
    80002e5e:	588c                	lw	a1,48(s1)
    80002e60:	00005517          	auipc	a0,0x5
    80002e64:	69050513          	addi	a0,a0,1680 # 800084f0 <states+0x150>
    80002e68:	ffffe097          	auipc	ra,0xffffe
    80002e6c:	82e080e7          	jalr	-2002(ra) # 80000696 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e70:	6cbc                	ld	a5,88(s1)
    80002e72:	577d                	li	a4,-1
    80002e74:	fbb8                	sd	a4,112(a5)
  }
}
    80002e76:	60e2                	ld	ra,24(sp)
    80002e78:	6442                	ld	s0,16(sp)
    80002e7a:	64a2                	ld	s1,8(sp)
    80002e7c:	6902                	ld	s2,0(sp)
    80002e7e:	6105                	addi	sp,sp,32
    80002e80:	8082                	ret

0000000080002e82 <sys_exit>:
#include "historyBuffer.h"


uint64
sys_exit(void)
{
    80002e82:	1101                	addi	sp,sp,-32
    80002e84:	ec06                	sd	ra,24(sp)
    80002e86:	e822                	sd	s0,16(sp)
    80002e88:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e8a:	fec40593          	addi	a1,s0,-20
    80002e8e:	4501                	li	a0,0
    80002e90:	00000097          	auipc	ra,0x0
    80002e94:	f0e080e7          	jalr	-242(ra) # 80002d9e <argint>
  exit(n);
    80002e98:	fec42503          	lw	a0,-20(s0)
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	3fa080e7          	jalr	1018(ra) # 80002296 <exit>
  return 0;  // not reached
}
    80002ea4:	4501                	li	a0,0
    80002ea6:	60e2                	ld	ra,24(sp)
    80002ea8:	6442                	ld	s0,16(sp)
    80002eaa:	6105                	addi	sp,sp,32
    80002eac:	8082                	ret

0000000080002eae <sys_getpid>:

uint64
sys_getpid(void)
{
    80002eae:	1141                	addi	sp,sp,-16
    80002eb0:	e406                	sd	ra,8(sp)
    80002eb2:	e022                	sd	s0,0(sp)
    80002eb4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	c04080e7          	jalr	-1020(ra) # 80001aba <myproc>
}
    80002ebe:	5908                	lw	a0,48(a0)
    80002ec0:	60a2                	ld	ra,8(sp)
    80002ec2:	6402                	ld	s0,0(sp)
    80002ec4:	0141                	addi	sp,sp,16
    80002ec6:	8082                	ret

0000000080002ec8 <sys_fork>:

uint64
sys_fork(void)
{
    80002ec8:	1141                	addi	sp,sp,-16
    80002eca:	e406                	sd	ra,8(sp)
    80002ecc:	e022                	sd	s0,0(sp)
    80002ece:	0800                	addi	s0,sp,16
  return fork();
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	fa0080e7          	jalr	-96(ra) # 80001e70 <fork>
}
    80002ed8:	60a2                	ld	ra,8(sp)
    80002eda:	6402                	ld	s0,0(sp)
    80002edc:	0141                	addi	sp,sp,16
    80002ede:	8082                	ret

0000000080002ee0 <sys_wait>:

uint64
sys_wait(void)
{
    80002ee0:	1101                	addi	sp,sp,-32
    80002ee2:	ec06                	sd	ra,24(sp)
    80002ee4:	e822                	sd	s0,16(sp)
    80002ee6:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002ee8:	fe840593          	addi	a1,s0,-24
    80002eec:	4501                	li	a0,0
    80002eee:	00000097          	auipc	ra,0x0
    80002ef2:	ed0080e7          	jalr	-304(ra) # 80002dbe <argaddr>
  return wait(p);
    80002ef6:	fe843503          	ld	a0,-24(s0)
    80002efa:	fffff097          	auipc	ra,0xfffff
    80002efe:	542080e7          	jalr	1346(ra) # 8000243c <wait>
}
    80002f02:	60e2                	ld	ra,24(sp)
    80002f04:	6442                	ld	s0,16(sp)
    80002f06:	6105                	addi	sp,sp,32
    80002f08:	8082                	ret

0000000080002f0a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f0a:	7179                	addi	sp,sp,-48
    80002f0c:	f406                	sd	ra,40(sp)
    80002f0e:	f022                	sd	s0,32(sp)
    80002f10:	ec26                	sd	s1,24(sp)
    80002f12:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f14:	fdc40593          	addi	a1,s0,-36
    80002f18:	4501                	li	a0,0
    80002f1a:	00000097          	auipc	ra,0x0
    80002f1e:	e84080e7          	jalr	-380(ra) # 80002d9e <argint>
  addr = myproc()->sz;
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	b98080e7          	jalr	-1128(ra) # 80001aba <myproc>
    80002f2a:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002f2c:	fdc42503          	lw	a0,-36(s0)
    80002f30:	fffff097          	auipc	ra,0xfffff
    80002f34:	ee4080e7          	jalr	-284(ra) # 80001e14 <growproc>
    80002f38:	00054863          	bltz	a0,80002f48 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f3c:	8526                	mv	a0,s1
    80002f3e:	70a2                	ld	ra,40(sp)
    80002f40:	7402                	ld	s0,32(sp)
    80002f42:	64e2                	ld	s1,24(sp)
    80002f44:	6145                	addi	sp,sp,48
    80002f46:	8082                	ret
    return -1;
    80002f48:	54fd                	li	s1,-1
    80002f4a:	bfcd                	j	80002f3c <sys_sbrk+0x32>

0000000080002f4c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f4c:	7139                	addi	sp,sp,-64
    80002f4e:	fc06                	sd	ra,56(sp)
    80002f50:	f822                	sd	s0,48(sp)
    80002f52:	f426                	sd	s1,40(sp)
    80002f54:	f04a                	sd	s2,32(sp)
    80002f56:	ec4e                	sd	s3,24(sp)
    80002f58:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f5a:	fcc40593          	addi	a1,s0,-52
    80002f5e:	4501                	li	a0,0
    80002f60:	00000097          	auipc	ra,0x0
    80002f64:	e3e080e7          	jalr	-450(ra) # 80002d9e <argint>
  acquire(&tickslock);
    80002f68:	00015517          	auipc	a0,0x15
    80002f6c:	af050513          	addi	a0,a0,-1296 # 80017a58 <tickslock>
    80002f70:	ffffe097          	auipc	ra,0xffffe
    80002f74:	d74080e7          	jalr	-652(ra) # 80000ce4 <acquire>
  ticks0 = ticks;
    80002f78:	00006917          	auipc	s2,0x6
    80002f7c:	a4092903          	lw	s2,-1472(s2) # 800089b8 <ticks>
  while(ticks - ticks0 < n){
    80002f80:	fcc42783          	lw	a5,-52(s0)
    80002f84:	cf9d                	beqz	a5,80002fc2 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f86:	00015997          	auipc	s3,0x15
    80002f8a:	ad298993          	addi	s3,s3,-1326 # 80017a58 <tickslock>
    80002f8e:	00006497          	auipc	s1,0x6
    80002f92:	a2a48493          	addi	s1,s1,-1494 # 800089b8 <ticks>
    if(killed(myproc())){
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	b24080e7          	jalr	-1244(ra) # 80001aba <myproc>
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	46c080e7          	jalr	1132(ra) # 8000240a <killed>
    80002fa6:	ed15                	bnez	a0,80002fe2 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002fa8:	85ce                	mv	a1,s3
    80002faa:	8526                	mv	a0,s1
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	1b6080e7          	jalr	438(ra) # 80002162 <sleep>
  while(ticks - ticks0 < n){
    80002fb4:	409c                	lw	a5,0(s1)
    80002fb6:	412787bb          	subw	a5,a5,s2
    80002fba:	fcc42703          	lw	a4,-52(s0)
    80002fbe:	fce7ece3          	bltu	a5,a4,80002f96 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002fc2:	00015517          	auipc	a0,0x15
    80002fc6:	a9650513          	addi	a0,a0,-1386 # 80017a58 <tickslock>
    80002fca:	ffffe097          	auipc	ra,0xffffe
    80002fce:	dce080e7          	jalr	-562(ra) # 80000d98 <release>
  return 0;
    80002fd2:	4501                	li	a0,0
}
    80002fd4:	70e2                	ld	ra,56(sp)
    80002fd6:	7442                	ld	s0,48(sp)
    80002fd8:	74a2                	ld	s1,40(sp)
    80002fda:	7902                	ld	s2,32(sp)
    80002fdc:	69e2                	ld	s3,24(sp)
    80002fde:	6121                	addi	sp,sp,64
    80002fe0:	8082                	ret
      release(&tickslock);
    80002fe2:	00015517          	auipc	a0,0x15
    80002fe6:	a7650513          	addi	a0,a0,-1418 # 80017a58 <tickslock>
    80002fea:	ffffe097          	auipc	ra,0xffffe
    80002fee:	dae080e7          	jalr	-594(ra) # 80000d98 <release>
      return -1;
    80002ff2:	557d                	li	a0,-1
    80002ff4:	b7c5                	j	80002fd4 <sys_sleep+0x88>

0000000080002ff6 <sys_kill>:

uint64
sys_kill(void)
{
    80002ff6:	1101                	addi	sp,sp,-32
    80002ff8:	ec06                	sd	ra,24(sp)
    80002ffa:	e822                	sd	s0,16(sp)
    80002ffc:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ffe:	fec40593          	addi	a1,s0,-20
    80003002:	4501                	li	a0,0
    80003004:	00000097          	auipc	ra,0x0
    80003008:	d9a080e7          	jalr	-614(ra) # 80002d9e <argint>
  return kill(pid);
    8000300c:	fec42503          	lw	a0,-20(s0)
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	35c080e7          	jalr	860(ra) # 8000236c <kill>
}
    80003018:	60e2                	ld	ra,24(sp)
    8000301a:	6442                	ld	s0,16(sp)
    8000301c:	6105                	addi	sp,sp,32
    8000301e:	8082                	ret

0000000080003020 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003020:	1101                	addi	sp,sp,-32
    80003022:	ec06                	sd	ra,24(sp)
    80003024:	e822                	sd	s0,16(sp)
    80003026:	e426                	sd	s1,8(sp)
    80003028:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000302a:	00015517          	auipc	a0,0x15
    8000302e:	a2e50513          	addi	a0,a0,-1490 # 80017a58 <tickslock>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	cb2080e7          	jalr	-846(ra) # 80000ce4 <acquire>
  xticks = ticks;
    8000303a:	00006497          	auipc	s1,0x6
    8000303e:	97e4a483          	lw	s1,-1666(s1) # 800089b8 <ticks>
  release(&tickslock);
    80003042:	00015517          	auipc	a0,0x15
    80003046:	a1650513          	addi	a0,a0,-1514 # 80017a58 <tickslock>
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	d4e080e7          	jalr	-690(ra) # 80000d98 <release>
  return xticks;
}
    80003052:	02049513          	slli	a0,s1,0x20
    80003056:	9101                	srli	a0,a0,0x20
    80003058:	60e2                	ld	ra,24(sp)
    8000305a:	6442                	ld	s0,16(sp)
    8000305c:	64a2                	ld	s1,8(sp)
    8000305e:	6105                	addi	sp,sp,32
    80003060:	8082                	ret

0000000080003062 <sys_history>:

uint64
sys_history(void)
{
    80003062:	7179                	addi	sp,sp,-48
    80003064:	f406                	sd	ra,40(sp)
    80003066:	f022                	sd	s0,32(sp)
    80003068:	ec26                	sd	s1,24(sp)
    8000306a:	e84a                	sd	s2,16(sp)
    8000306c:	1800                	addi	s0,sp,48
   // struct syshistory *history;

    int historyNum;
    argint(0, &historyNum);
    8000306e:	fdc40593          	addi	a1,s0,-36
    80003072:	4501                	li	a0,0
    80003074:	00000097          	auipc	ra,0x0
    80003078:	d2a080e7          	jalr	-726(ra) # 80002d9e <argint>
    int err = 0;
//    printf("hellooooo\n");

    int target = 0;
//    printf("[%d]", historyBuf.lastCommandIndex);
    target = historyBuf.lastCommandIndex - historyNum;
    8000307c:	0000e797          	auipc	a5,0xe
    80003080:	b2c78793          	addi	a5,a5,-1236 # 80010ba8 <historyBuf>
    80003084:	0000e917          	auipc	s2,0xe
    80003088:	36492903          	lw	s2,868(s2) # 800113e8 <historyBuf+0x840>
    8000308c:	fdc42703          	lw	a4,-36(s0)
    80003090:	40e9093b          	subw	s2,s2,a4
    80003094:	091e                	slli	s2,s2,0x7
    80003096:	f8090493          	addi	s1,s2,-128
    8000309a:	94be                	add	s1,s1,a5
    8000309c:	993e                	add	s2,s2,a5
//        printf(" ");

       // consputc(historyBuf.bufferArr[5][i]);
//    }
    for (int i = 0; i < 128; ++i) {
        consputc(historyBuf.bufferArr[target-1][i]);
    8000309e:	0004c503          	lbu	a0,0(s1)
    800030a2:	ffffd097          	auipc	ra,0xffffd
    800030a6:	294080e7          	jalr	660(ra) # 80000336 <consputc>
    for (int i = 0; i < 128; ++i) {
    800030aa:	0485                	addi	s1,s1,1
    800030ac:	ff2499e3          	bne	s1,s2,8000309e <sys_history+0x3c>

    }


    printf("\n");
    800030b0:	00005517          	auipc	a0,0x5
    800030b4:	27850513          	addi	a0,a0,632 # 80008328 <digits+0x2e8>
    800030b8:	ffffd097          	auipc	ra,0xffffd
    800030bc:	5de080e7          	jalr	1502(ra) # 80000696 <printf>

    return err;
}
    800030c0:	4501                	li	a0,0
    800030c2:	70a2                	ld	ra,40(sp)
    800030c4:	7402                	ld	s0,32(sp)
    800030c6:	64e2                	ld	s1,24(sp)
    800030c8:	6942                	ld	s2,16(sp)
    800030ca:	6145                	addi	sp,sp,48
    800030cc:	8082                	ret

00000000800030ce <sys_top>:
uint64
sys_top(void)
{
    800030ce:	1141                	addi	sp,sp,-16
    800030d0:	e406                	sd	ra,8(sp)
    800030d2:	e022                	sd	s0,0(sp)
    800030d4:	0800                	addi	s0,sp,16
    get_top_info();
    800030d6:	fffff097          	auipc	ra,0xfffff
    800030da:	5ee080e7          	jalr	1518(ra) # 800026c4 <get_top_info>

    return 0;
}
    800030de:	4501                	li	a0,0
    800030e0:	60a2                	ld	ra,8(sp)
    800030e2:	6402                	ld	s0,0(sp)
    800030e4:	0141                	addi	sp,sp,16
    800030e6:	8082                	ret

00000000800030e8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030e8:	7179                	addi	sp,sp,-48
    800030ea:	f406                	sd	ra,40(sp)
    800030ec:	f022                	sd	s0,32(sp)
    800030ee:	ec26                	sd	s1,24(sp)
    800030f0:	e84a                	sd	s2,16(sp)
    800030f2:	e44e                	sd	s3,8(sp)
    800030f4:	e052                	sd	s4,0(sp)
    800030f6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030f8:	00005597          	auipc	a1,0x5
    800030fc:	4f058593          	addi	a1,a1,1264 # 800085e8 <syscalls+0xc0>
    80003100:	00015517          	auipc	a0,0x15
    80003104:	97050513          	addi	a0,a0,-1680 # 80017a70 <bcache>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	b4c080e7          	jalr	-1204(ra) # 80000c54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003110:	0001d797          	auipc	a5,0x1d
    80003114:	96078793          	addi	a5,a5,-1696 # 8001fa70 <bcache+0x8000>
    80003118:	0001d717          	auipc	a4,0x1d
    8000311c:	bc070713          	addi	a4,a4,-1088 # 8001fcd8 <bcache+0x8268>
    80003120:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003124:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003128:	00015497          	auipc	s1,0x15
    8000312c:	96048493          	addi	s1,s1,-1696 # 80017a88 <bcache+0x18>
    b->next = bcache.head.next;
    80003130:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003132:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003134:	00005a17          	auipc	s4,0x5
    80003138:	4bca0a13          	addi	s4,s4,1212 # 800085f0 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000313c:	2b893783          	ld	a5,696(s2)
    80003140:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003142:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003146:	85d2                	mv	a1,s4
    80003148:	01048513          	addi	a0,s1,16
    8000314c:	00001097          	auipc	ra,0x1
    80003150:	4c4080e7          	jalr	1220(ra) # 80004610 <initsleeplock>
    bcache.head.next->prev = b;
    80003154:	2b893783          	ld	a5,696(s2)
    80003158:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000315a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000315e:	45848493          	addi	s1,s1,1112
    80003162:	fd349de3          	bne	s1,s3,8000313c <binit+0x54>
  }
}
    80003166:	70a2                	ld	ra,40(sp)
    80003168:	7402                	ld	s0,32(sp)
    8000316a:	64e2                	ld	s1,24(sp)
    8000316c:	6942                	ld	s2,16(sp)
    8000316e:	69a2                	ld	s3,8(sp)
    80003170:	6a02                	ld	s4,0(sp)
    80003172:	6145                	addi	sp,sp,48
    80003174:	8082                	ret

0000000080003176 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003176:	7179                	addi	sp,sp,-48
    80003178:	f406                	sd	ra,40(sp)
    8000317a:	f022                	sd	s0,32(sp)
    8000317c:	ec26                	sd	s1,24(sp)
    8000317e:	e84a                	sd	s2,16(sp)
    80003180:	e44e                	sd	s3,8(sp)
    80003182:	1800                	addi	s0,sp,48
    80003184:	892a                	mv	s2,a0
    80003186:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003188:	00015517          	auipc	a0,0x15
    8000318c:	8e850513          	addi	a0,a0,-1816 # 80017a70 <bcache>
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	b54080e7          	jalr	-1196(ra) # 80000ce4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003198:	0001d497          	auipc	s1,0x1d
    8000319c:	b904b483          	ld	s1,-1136(s1) # 8001fd28 <bcache+0x82b8>
    800031a0:	0001d797          	auipc	a5,0x1d
    800031a4:	b3878793          	addi	a5,a5,-1224 # 8001fcd8 <bcache+0x8268>
    800031a8:	02f48f63          	beq	s1,a5,800031e6 <bread+0x70>
    800031ac:	873e                	mv	a4,a5
    800031ae:	a021                	j	800031b6 <bread+0x40>
    800031b0:	68a4                	ld	s1,80(s1)
    800031b2:	02e48a63          	beq	s1,a4,800031e6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031b6:	449c                	lw	a5,8(s1)
    800031b8:	ff279ce3          	bne	a5,s2,800031b0 <bread+0x3a>
    800031bc:	44dc                	lw	a5,12(s1)
    800031be:	ff3799e3          	bne	a5,s3,800031b0 <bread+0x3a>
      b->refcnt++;
    800031c2:	40bc                	lw	a5,64(s1)
    800031c4:	2785                	addiw	a5,a5,1
    800031c6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031c8:	00015517          	auipc	a0,0x15
    800031cc:	8a850513          	addi	a0,a0,-1880 # 80017a70 <bcache>
    800031d0:	ffffe097          	auipc	ra,0xffffe
    800031d4:	bc8080e7          	jalr	-1080(ra) # 80000d98 <release>
      acquiresleep(&b->lock);
    800031d8:	01048513          	addi	a0,s1,16
    800031dc:	00001097          	auipc	ra,0x1
    800031e0:	46e080e7          	jalr	1134(ra) # 8000464a <acquiresleep>
      return b;
    800031e4:	a8b9                	j	80003242 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031e6:	0001d497          	auipc	s1,0x1d
    800031ea:	b3a4b483          	ld	s1,-1222(s1) # 8001fd20 <bcache+0x82b0>
    800031ee:	0001d797          	auipc	a5,0x1d
    800031f2:	aea78793          	addi	a5,a5,-1302 # 8001fcd8 <bcache+0x8268>
    800031f6:	00f48863          	beq	s1,a5,80003206 <bread+0x90>
    800031fa:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031fc:	40bc                	lw	a5,64(s1)
    800031fe:	cf81                	beqz	a5,80003216 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003200:	64a4                	ld	s1,72(s1)
    80003202:	fee49de3          	bne	s1,a4,800031fc <bread+0x86>
  panic("bget: no buffers");
    80003206:	00005517          	auipc	a0,0x5
    8000320a:	3f250513          	addi	a0,a0,1010 # 800085f8 <syscalls+0xd0>
    8000320e:	ffffd097          	auipc	ra,0xffffd
    80003212:	43e080e7          	jalr	1086(ra) # 8000064c <panic>
      b->dev = dev;
    80003216:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000321a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000321e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003222:	4785                	li	a5,1
    80003224:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003226:	00015517          	auipc	a0,0x15
    8000322a:	84a50513          	addi	a0,a0,-1974 # 80017a70 <bcache>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	b6a080e7          	jalr	-1174(ra) # 80000d98 <release>
      acquiresleep(&b->lock);
    80003236:	01048513          	addi	a0,s1,16
    8000323a:	00001097          	auipc	ra,0x1
    8000323e:	410080e7          	jalr	1040(ra) # 8000464a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003242:	409c                	lw	a5,0(s1)
    80003244:	cb89                	beqz	a5,80003256 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003246:	8526                	mv	a0,s1
    80003248:	70a2                	ld	ra,40(sp)
    8000324a:	7402                	ld	s0,32(sp)
    8000324c:	64e2                	ld	s1,24(sp)
    8000324e:	6942                	ld	s2,16(sp)
    80003250:	69a2                	ld	s3,8(sp)
    80003252:	6145                	addi	sp,sp,48
    80003254:	8082                	ret
    virtio_disk_rw(b, 0);
    80003256:	4581                	li	a1,0
    80003258:	8526                	mv	a0,s1
    8000325a:	00003097          	auipc	ra,0x3
    8000325e:	fda080e7          	jalr	-38(ra) # 80006234 <virtio_disk_rw>
    b->valid = 1;
    80003262:	4785                	li	a5,1
    80003264:	c09c                	sw	a5,0(s1)
  return b;
    80003266:	b7c5                	j	80003246 <bread+0xd0>

0000000080003268 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003268:	1101                	addi	sp,sp,-32
    8000326a:	ec06                	sd	ra,24(sp)
    8000326c:	e822                	sd	s0,16(sp)
    8000326e:	e426                	sd	s1,8(sp)
    80003270:	1000                	addi	s0,sp,32
    80003272:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003274:	0541                	addi	a0,a0,16
    80003276:	00001097          	auipc	ra,0x1
    8000327a:	46e080e7          	jalr	1134(ra) # 800046e4 <holdingsleep>
    8000327e:	cd01                	beqz	a0,80003296 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003280:	4585                	li	a1,1
    80003282:	8526                	mv	a0,s1
    80003284:	00003097          	auipc	ra,0x3
    80003288:	fb0080e7          	jalr	-80(ra) # 80006234 <virtio_disk_rw>
}
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	64a2                	ld	s1,8(sp)
    80003292:	6105                	addi	sp,sp,32
    80003294:	8082                	ret
    panic("bwrite");
    80003296:	00005517          	auipc	a0,0x5
    8000329a:	37a50513          	addi	a0,a0,890 # 80008610 <syscalls+0xe8>
    8000329e:	ffffd097          	auipc	ra,0xffffd
    800032a2:	3ae080e7          	jalr	942(ra) # 8000064c <panic>

00000000800032a6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032a6:	1101                	addi	sp,sp,-32
    800032a8:	ec06                	sd	ra,24(sp)
    800032aa:	e822                	sd	s0,16(sp)
    800032ac:	e426                	sd	s1,8(sp)
    800032ae:	e04a                	sd	s2,0(sp)
    800032b0:	1000                	addi	s0,sp,32
    800032b2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032b4:	01050913          	addi	s2,a0,16
    800032b8:	854a                	mv	a0,s2
    800032ba:	00001097          	auipc	ra,0x1
    800032be:	42a080e7          	jalr	1066(ra) # 800046e4 <holdingsleep>
    800032c2:	c92d                	beqz	a0,80003334 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00001097          	auipc	ra,0x1
    800032ca:	3da080e7          	jalr	986(ra) # 800046a0 <releasesleep>

  acquire(&bcache.lock);
    800032ce:	00014517          	auipc	a0,0x14
    800032d2:	7a250513          	addi	a0,a0,1954 # 80017a70 <bcache>
    800032d6:	ffffe097          	auipc	ra,0xffffe
    800032da:	a0e080e7          	jalr	-1522(ra) # 80000ce4 <acquire>
  b->refcnt--;
    800032de:	40bc                	lw	a5,64(s1)
    800032e0:	37fd                	addiw	a5,a5,-1
    800032e2:	0007871b          	sext.w	a4,a5
    800032e6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032e8:	eb05                	bnez	a4,80003318 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032ea:	68bc                	ld	a5,80(s1)
    800032ec:	64b8                	ld	a4,72(s1)
    800032ee:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032f0:	64bc                	ld	a5,72(s1)
    800032f2:	68b8                	ld	a4,80(s1)
    800032f4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032f6:	0001c797          	auipc	a5,0x1c
    800032fa:	77a78793          	addi	a5,a5,1914 # 8001fa70 <bcache+0x8000>
    800032fe:	2b87b703          	ld	a4,696(a5)
    80003302:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003304:	0001d717          	auipc	a4,0x1d
    80003308:	9d470713          	addi	a4,a4,-1580 # 8001fcd8 <bcache+0x8268>
    8000330c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000330e:	2b87b703          	ld	a4,696(a5)
    80003312:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003314:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003318:	00014517          	auipc	a0,0x14
    8000331c:	75850513          	addi	a0,a0,1880 # 80017a70 <bcache>
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	a78080e7          	jalr	-1416(ra) # 80000d98 <release>
}
    80003328:	60e2                	ld	ra,24(sp)
    8000332a:	6442                	ld	s0,16(sp)
    8000332c:	64a2                	ld	s1,8(sp)
    8000332e:	6902                	ld	s2,0(sp)
    80003330:	6105                	addi	sp,sp,32
    80003332:	8082                	ret
    panic("brelse");
    80003334:	00005517          	auipc	a0,0x5
    80003338:	2e450513          	addi	a0,a0,740 # 80008618 <syscalls+0xf0>
    8000333c:	ffffd097          	auipc	ra,0xffffd
    80003340:	310080e7          	jalr	784(ra) # 8000064c <panic>

0000000080003344 <bpin>:

void
bpin(struct buf *b) {
    80003344:	1101                	addi	sp,sp,-32
    80003346:	ec06                	sd	ra,24(sp)
    80003348:	e822                	sd	s0,16(sp)
    8000334a:	e426                	sd	s1,8(sp)
    8000334c:	1000                	addi	s0,sp,32
    8000334e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003350:	00014517          	auipc	a0,0x14
    80003354:	72050513          	addi	a0,a0,1824 # 80017a70 <bcache>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	98c080e7          	jalr	-1652(ra) # 80000ce4 <acquire>
  b->refcnt++;
    80003360:	40bc                	lw	a5,64(s1)
    80003362:	2785                	addiw	a5,a5,1
    80003364:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003366:	00014517          	auipc	a0,0x14
    8000336a:	70a50513          	addi	a0,a0,1802 # 80017a70 <bcache>
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	a2a080e7          	jalr	-1494(ra) # 80000d98 <release>
}
    80003376:	60e2                	ld	ra,24(sp)
    80003378:	6442                	ld	s0,16(sp)
    8000337a:	64a2                	ld	s1,8(sp)
    8000337c:	6105                	addi	sp,sp,32
    8000337e:	8082                	ret

0000000080003380 <bunpin>:

void
bunpin(struct buf *b) {
    80003380:	1101                	addi	sp,sp,-32
    80003382:	ec06                	sd	ra,24(sp)
    80003384:	e822                	sd	s0,16(sp)
    80003386:	e426                	sd	s1,8(sp)
    80003388:	1000                	addi	s0,sp,32
    8000338a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000338c:	00014517          	auipc	a0,0x14
    80003390:	6e450513          	addi	a0,a0,1764 # 80017a70 <bcache>
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	950080e7          	jalr	-1712(ra) # 80000ce4 <acquire>
  b->refcnt--;
    8000339c:	40bc                	lw	a5,64(s1)
    8000339e:	37fd                	addiw	a5,a5,-1
    800033a0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033a2:	00014517          	auipc	a0,0x14
    800033a6:	6ce50513          	addi	a0,a0,1742 # 80017a70 <bcache>
    800033aa:	ffffe097          	auipc	ra,0xffffe
    800033ae:	9ee080e7          	jalr	-1554(ra) # 80000d98 <release>
}
    800033b2:	60e2                	ld	ra,24(sp)
    800033b4:	6442                	ld	s0,16(sp)
    800033b6:	64a2                	ld	s1,8(sp)
    800033b8:	6105                	addi	sp,sp,32
    800033ba:	8082                	ret

00000000800033bc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033bc:	1101                	addi	sp,sp,-32
    800033be:	ec06                	sd	ra,24(sp)
    800033c0:	e822                	sd	s0,16(sp)
    800033c2:	e426                	sd	s1,8(sp)
    800033c4:	e04a                	sd	s2,0(sp)
    800033c6:	1000                	addi	s0,sp,32
    800033c8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033ca:	00d5d59b          	srliw	a1,a1,0xd
    800033ce:	0001d797          	auipc	a5,0x1d
    800033d2:	d7e7a783          	lw	a5,-642(a5) # 8002014c <sb+0x1c>
    800033d6:	9dbd                	addw	a1,a1,a5
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	d9e080e7          	jalr	-610(ra) # 80003176 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033e0:	0074f713          	andi	a4,s1,7
    800033e4:	4785                	li	a5,1
    800033e6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033ea:	14ce                	slli	s1,s1,0x33
    800033ec:	90d9                	srli	s1,s1,0x36
    800033ee:	00950733          	add	a4,a0,s1
    800033f2:	05874703          	lbu	a4,88(a4)
    800033f6:	00e7f6b3          	and	a3,a5,a4
    800033fa:	c69d                	beqz	a3,80003428 <bfree+0x6c>
    800033fc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033fe:	94aa                	add	s1,s1,a0
    80003400:	fff7c793          	not	a5,a5
    80003404:	8ff9                	and	a5,a5,a4
    80003406:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000340a:	00001097          	auipc	ra,0x1
    8000340e:	120080e7          	jalr	288(ra) # 8000452a <log_write>
  brelse(bp);
    80003412:	854a                	mv	a0,s2
    80003414:	00000097          	auipc	ra,0x0
    80003418:	e92080e7          	jalr	-366(ra) # 800032a6 <brelse>
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	64a2                	ld	s1,8(sp)
    80003422:	6902                	ld	s2,0(sp)
    80003424:	6105                	addi	sp,sp,32
    80003426:	8082                	ret
    panic("freeing free block");
    80003428:	00005517          	auipc	a0,0x5
    8000342c:	1f850513          	addi	a0,a0,504 # 80008620 <syscalls+0xf8>
    80003430:	ffffd097          	auipc	ra,0xffffd
    80003434:	21c080e7          	jalr	540(ra) # 8000064c <panic>

0000000080003438 <balloc>:
{
    80003438:	711d                	addi	sp,sp,-96
    8000343a:	ec86                	sd	ra,88(sp)
    8000343c:	e8a2                	sd	s0,80(sp)
    8000343e:	e4a6                	sd	s1,72(sp)
    80003440:	e0ca                	sd	s2,64(sp)
    80003442:	fc4e                	sd	s3,56(sp)
    80003444:	f852                	sd	s4,48(sp)
    80003446:	f456                	sd	s5,40(sp)
    80003448:	f05a                	sd	s6,32(sp)
    8000344a:	ec5e                	sd	s7,24(sp)
    8000344c:	e862                	sd	s8,16(sp)
    8000344e:	e466                	sd	s9,8(sp)
    80003450:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003452:	0001d797          	auipc	a5,0x1d
    80003456:	ce27a783          	lw	a5,-798(a5) # 80020134 <sb+0x4>
    8000345a:	10078163          	beqz	a5,8000355c <balloc+0x124>
    8000345e:	8baa                	mv	s7,a0
    80003460:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003462:	0001db17          	auipc	s6,0x1d
    80003466:	cceb0b13          	addi	s6,s6,-818 # 80020130 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000346c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003470:	6c89                	lui	s9,0x2
    80003472:	a061                	j	800034fa <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003474:	974a                	add	a4,a4,s2
    80003476:	8fd5                	or	a5,a5,a3
    80003478:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000347c:	854a                	mv	a0,s2
    8000347e:	00001097          	auipc	ra,0x1
    80003482:	0ac080e7          	jalr	172(ra) # 8000452a <log_write>
        brelse(bp);
    80003486:	854a                	mv	a0,s2
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	e1e080e7          	jalr	-482(ra) # 800032a6 <brelse>
  bp = bread(dev, bno);
    80003490:	85a6                	mv	a1,s1
    80003492:	855e                	mv	a0,s7
    80003494:	00000097          	auipc	ra,0x0
    80003498:	ce2080e7          	jalr	-798(ra) # 80003176 <bread>
    8000349c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000349e:	40000613          	li	a2,1024
    800034a2:	4581                	li	a1,0
    800034a4:	05850513          	addi	a0,a0,88
    800034a8:	ffffe097          	auipc	ra,0xffffe
    800034ac:	938080e7          	jalr	-1736(ra) # 80000de0 <memset>
  log_write(bp);
    800034b0:	854a                	mv	a0,s2
    800034b2:	00001097          	auipc	ra,0x1
    800034b6:	078080e7          	jalr	120(ra) # 8000452a <log_write>
  brelse(bp);
    800034ba:	854a                	mv	a0,s2
    800034bc:	00000097          	auipc	ra,0x0
    800034c0:	dea080e7          	jalr	-534(ra) # 800032a6 <brelse>
}
    800034c4:	8526                	mv	a0,s1
    800034c6:	60e6                	ld	ra,88(sp)
    800034c8:	6446                	ld	s0,80(sp)
    800034ca:	64a6                	ld	s1,72(sp)
    800034cc:	6906                	ld	s2,64(sp)
    800034ce:	79e2                	ld	s3,56(sp)
    800034d0:	7a42                	ld	s4,48(sp)
    800034d2:	7aa2                	ld	s5,40(sp)
    800034d4:	7b02                	ld	s6,32(sp)
    800034d6:	6be2                	ld	s7,24(sp)
    800034d8:	6c42                	ld	s8,16(sp)
    800034da:	6ca2                	ld	s9,8(sp)
    800034dc:	6125                	addi	sp,sp,96
    800034de:	8082                	ret
    brelse(bp);
    800034e0:	854a                	mv	a0,s2
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	dc4080e7          	jalr	-572(ra) # 800032a6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034ea:	015c87bb          	addw	a5,s9,s5
    800034ee:	00078a9b          	sext.w	s5,a5
    800034f2:	004b2703          	lw	a4,4(s6)
    800034f6:	06eaf363          	bgeu	s5,a4,8000355c <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800034fa:	41fad79b          	sraiw	a5,s5,0x1f
    800034fe:	0137d79b          	srliw	a5,a5,0x13
    80003502:	015787bb          	addw	a5,a5,s5
    80003506:	40d7d79b          	sraiw	a5,a5,0xd
    8000350a:	01cb2583          	lw	a1,28(s6)
    8000350e:	9dbd                	addw	a1,a1,a5
    80003510:	855e                	mv	a0,s7
    80003512:	00000097          	auipc	ra,0x0
    80003516:	c64080e7          	jalr	-924(ra) # 80003176 <bread>
    8000351a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000351c:	004b2503          	lw	a0,4(s6)
    80003520:	000a849b          	sext.w	s1,s5
    80003524:	8662                	mv	a2,s8
    80003526:	faa4fde3          	bgeu	s1,a0,800034e0 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000352a:	41f6579b          	sraiw	a5,a2,0x1f
    8000352e:	01d7d69b          	srliw	a3,a5,0x1d
    80003532:	00c6873b          	addw	a4,a3,a2
    80003536:	00777793          	andi	a5,a4,7
    8000353a:	9f95                	subw	a5,a5,a3
    8000353c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003540:	4037571b          	sraiw	a4,a4,0x3
    80003544:	00e906b3          	add	a3,s2,a4
    80003548:	0586c683          	lbu	a3,88(a3)
    8000354c:	00d7f5b3          	and	a1,a5,a3
    80003550:	d195                	beqz	a1,80003474 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003552:	2605                	addiw	a2,a2,1
    80003554:	2485                	addiw	s1,s1,1
    80003556:	fd4618e3          	bne	a2,s4,80003526 <balloc+0xee>
    8000355a:	b759                	j	800034e0 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000355c:	00005517          	auipc	a0,0x5
    80003560:	0dc50513          	addi	a0,a0,220 # 80008638 <syscalls+0x110>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	132080e7          	jalr	306(ra) # 80000696 <printf>
  return 0;
    8000356c:	4481                	li	s1,0
    8000356e:	bf99                	j	800034c4 <balloc+0x8c>

0000000080003570 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003570:	7179                	addi	sp,sp,-48
    80003572:	f406                	sd	ra,40(sp)
    80003574:	f022                	sd	s0,32(sp)
    80003576:	ec26                	sd	s1,24(sp)
    80003578:	e84a                	sd	s2,16(sp)
    8000357a:	e44e                	sd	s3,8(sp)
    8000357c:	e052                	sd	s4,0(sp)
    8000357e:	1800                	addi	s0,sp,48
    80003580:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003582:	47ad                	li	a5,11
    80003584:	02b7e763          	bltu	a5,a1,800035b2 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003588:	02059493          	slli	s1,a1,0x20
    8000358c:	9081                	srli	s1,s1,0x20
    8000358e:	048a                	slli	s1,s1,0x2
    80003590:	94aa                	add	s1,s1,a0
    80003592:	0504a903          	lw	s2,80(s1)
    80003596:	06091e63          	bnez	s2,80003612 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000359a:	4108                	lw	a0,0(a0)
    8000359c:	00000097          	auipc	ra,0x0
    800035a0:	e9c080e7          	jalr	-356(ra) # 80003438 <balloc>
    800035a4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035a8:	06090563          	beqz	s2,80003612 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800035ac:	0524a823          	sw	s2,80(s1)
    800035b0:	a08d                	j	80003612 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800035b2:	ff45849b          	addiw	s1,a1,-12
    800035b6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035ba:	0ff00793          	li	a5,255
    800035be:	08e7e563          	bltu	a5,a4,80003648 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800035c2:	08052903          	lw	s2,128(a0)
    800035c6:	00091d63          	bnez	s2,800035e0 <bmap+0x70>
      addr = balloc(ip->dev);
    800035ca:	4108                	lw	a0,0(a0)
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	e6c080e7          	jalr	-404(ra) # 80003438 <balloc>
    800035d4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035d8:	02090d63          	beqz	s2,80003612 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800035dc:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800035e0:	85ca                	mv	a1,s2
    800035e2:	0009a503          	lw	a0,0(s3)
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	b90080e7          	jalr	-1136(ra) # 80003176 <bread>
    800035ee:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035f0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035f4:	02049593          	slli	a1,s1,0x20
    800035f8:	9181                	srli	a1,a1,0x20
    800035fa:	058a                	slli	a1,a1,0x2
    800035fc:	00b784b3          	add	s1,a5,a1
    80003600:	0004a903          	lw	s2,0(s1)
    80003604:	02090063          	beqz	s2,80003624 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003608:	8552                	mv	a0,s4
    8000360a:	00000097          	auipc	ra,0x0
    8000360e:	c9c080e7          	jalr	-868(ra) # 800032a6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003612:	854a                	mv	a0,s2
    80003614:	70a2                	ld	ra,40(sp)
    80003616:	7402                	ld	s0,32(sp)
    80003618:	64e2                	ld	s1,24(sp)
    8000361a:	6942                	ld	s2,16(sp)
    8000361c:	69a2                	ld	s3,8(sp)
    8000361e:	6a02                	ld	s4,0(sp)
    80003620:	6145                	addi	sp,sp,48
    80003622:	8082                	ret
      addr = balloc(ip->dev);
    80003624:	0009a503          	lw	a0,0(s3)
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	e10080e7          	jalr	-496(ra) # 80003438 <balloc>
    80003630:	0005091b          	sext.w	s2,a0
      if(addr){
    80003634:	fc090ae3          	beqz	s2,80003608 <bmap+0x98>
        a[bn] = addr;
    80003638:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000363c:	8552                	mv	a0,s4
    8000363e:	00001097          	auipc	ra,0x1
    80003642:	eec080e7          	jalr	-276(ra) # 8000452a <log_write>
    80003646:	b7c9                	j	80003608 <bmap+0x98>
  panic("bmap: out of range");
    80003648:	00005517          	auipc	a0,0x5
    8000364c:	00850513          	addi	a0,a0,8 # 80008650 <syscalls+0x128>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	ffc080e7          	jalr	-4(ra) # 8000064c <panic>

0000000080003658 <iget>:
{
    80003658:	7179                	addi	sp,sp,-48
    8000365a:	f406                	sd	ra,40(sp)
    8000365c:	f022                	sd	s0,32(sp)
    8000365e:	ec26                	sd	s1,24(sp)
    80003660:	e84a                	sd	s2,16(sp)
    80003662:	e44e                	sd	s3,8(sp)
    80003664:	e052                	sd	s4,0(sp)
    80003666:	1800                	addi	s0,sp,48
    80003668:	89aa                	mv	s3,a0
    8000366a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000366c:	0001d517          	auipc	a0,0x1d
    80003670:	ae450513          	addi	a0,a0,-1308 # 80020150 <itable>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	670080e7          	jalr	1648(ra) # 80000ce4 <acquire>
  empty = 0;
    8000367c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000367e:	0001d497          	auipc	s1,0x1d
    80003682:	aea48493          	addi	s1,s1,-1302 # 80020168 <itable+0x18>
    80003686:	0001e697          	auipc	a3,0x1e
    8000368a:	57268693          	addi	a3,a3,1394 # 80021bf8 <log>
    8000368e:	a039                	j	8000369c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003690:	02090b63          	beqz	s2,800036c6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003694:	08848493          	addi	s1,s1,136
    80003698:	02d48a63          	beq	s1,a3,800036cc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000369c:	449c                	lw	a5,8(s1)
    8000369e:	fef059e3          	blez	a5,80003690 <iget+0x38>
    800036a2:	4098                	lw	a4,0(s1)
    800036a4:	ff3716e3          	bne	a4,s3,80003690 <iget+0x38>
    800036a8:	40d8                	lw	a4,4(s1)
    800036aa:	ff4713e3          	bne	a4,s4,80003690 <iget+0x38>
      ip->ref++;
    800036ae:	2785                	addiw	a5,a5,1
    800036b0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036b2:	0001d517          	auipc	a0,0x1d
    800036b6:	a9e50513          	addi	a0,a0,-1378 # 80020150 <itable>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	6de080e7          	jalr	1758(ra) # 80000d98 <release>
      return ip;
    800036c2:	8926                	mv	s2,s1
    800036c4:	a03d                	j	800036f2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c6:	f7f9                	bnez	a5,80003694 <iget+0x3c>
    800036c8:	8926                	mv	s2,s1
    800036ca:	b7e9                	j	80003694 <iget+0x3c>
  if(empty == 0)
    800036cc:	02090c63          	beqz	s2,80003704 <iget+0xac>
  ip->dev = dev;
    800036d0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036d4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036d8:	4785                	li	a5,1
    800036da:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036de:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036e2:	0001d517          	auipc	a0,0x1d
    800036e6:	a6e50513          	addi	a0,a0,-1426 # 80020150 <itable>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	6ae080e7          	jalr	1710(ra) # 80000d98 <release>
}
    800036f2:	854a                	mv	a0,s2
    800036f4:	70a2                	ld	ra,40(sp)
    800036f6:	7402                	ld	s0,32(sp)
    800036f8:	64e2                	ld	s1,24(sp)
    800036fa:	6942                	ld	s2,16(sp)
    800036fc:	69a2                	ld	s3,8(sp)
    800036fe:	6a02                	ld	s4,0(sp)
    80003700:	6145                	addi	sp,sp,48
    80003702:	8082                	ret
    panic("iget: no inodes");
    80003704:	00005517          	auipc	a0,0x5
    80003708:	f6450513          	addi	a0,a0,-156 # 80008668 <syscalls+0x140>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	f40080e7          	jalr	-192(ra) # 8000064c <panic>

0000000080003714 <fsinit>:
fsinit(int dev) {
    80003714:	7179                	addi	sp,sp,-48
    80003716:	f406                	sd	ra,40(sp)
    80003718:	f022                	sd	s0,32(sp)
    8000371a:	ec26                	sd	s1,24(sp)
    8000371c:	e84a                	sd	s2,16(sp)
    8000371e:	e44e                	sd	s3,8(sp)
    80003720:	1800                	addi	s0,sp,48
    80003722:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003724:	4585                	li	a1,1
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	a50080e7          	jalr	-1456(ra) # 80003176 <bread>
    8000372e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003730:	0001d997          	auipc	s3,0x1d
    80003734:	a0098993          	addi	s3,s3,-1536 # 80020130 <sb>
    80003738:	02000613          	li	a2,32
    8000373c:	05850593          	addi	a1,a0,88
    80003740:	854e                	mv	a0,s3
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	6fa080e7          	jalr	1786(ra) # 80000e3c <memmove>
  brelse(bp);
    8000374a:	8526                	mv	a0,s1
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	b5a080e7          	jalr	-1190(ra) # 800032a6 <brelse>
  if(sb.magic != FSMAGIC)
    80003754:	0009a703          	lw	a4,0(s3)
    80003758:	102037b7          	lui	a5,0x10203
    8000375c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003760:	02f71263          	bne	a4,a5,80003784 <fsinit+0x70>
  initlog(dev, &sb);
    80003764:	0001d597          	auipc	a1,0x1d
    80003768:	9cc58593          	addi	a1,a1,-1588 # 80020130 <sb>
    8000376c:	854a                	mv	a0,s2
    8000376e:	00001097          	auipc	ra,0x1
    80003772:	b40080e7          	jalr	-1216(ra) # 800042ae <initlog>
}
    80003776:	70a2                	ld	ra,40(sp)
    80003778:	7402                	ld	s0,32(sp)
    8000377a:	64e2                	ld	s1,24(sp)
    8000377c:	6942                	ld	s2,16(sp)
    8000377e:	69a2                	ld	s3,8(sp)
    80003780:	6145                	addi	sp,sp,48
    80003782:	8082                	ret
    panic("invalid file system");
    80003784:	00005517          	auipc	a0,0x5
    80003788:	ef450513          	addi	a0,a0,-268 # 80008678 <syscalls+0x150>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	ec0080e7          	jalr	-320(ra) # 8000064c <panic>

0000000080003794 <iinit>:
{
    80003794:	7179                	addi	sp,sp,-48
    80003796:	f406                	sd	ra,40(sp)
    80003798:	f022                	sd	s0,32(sp)
    8000379a:	ec26                	sd	s1,24(sp)
    8000379c:	e84a                	sd	s2,16(sp)
    8000379e:	e44e                	sd	s3,8(sp)
    800037a0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037a2:	00005597          	auipc	a1,0x5
    800037a6:	eee58593          	addi	a1,a1,-274 # 80008690 <syscalls+0x168>
    800037aa:	0001d517          	auipc	a0,0x1d
    800037ae:	9a650513          	addi	a0,a0,-1626 # 80020150 <itable>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	4a2080e7          	jalr	1186(ra) # 80000c54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037ba:	0001d497          	auipc	s1,0x1d
    800037be:	9be48493          	addi	s1,s1,-1602 # 80020178 <itable+0x28>
    800037c2:	0001e997          	auipc	s3,0x1e
    800037c6:	44698993          	addi	s3,s3,1094 # 80021c08 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037ca:	00005917          	auipc	s2,0x5
    800037ce:	ece90913          	addi	s2,s2,-306 # 80008698 <syscalls+0x170>
    800037d2:	85ca                	mv	a1,s2
    800037d4:	8526                	mv	a0,s1
    800037d6:	00001097          	auipc	ra,0x1
    800037da:	e3a080e7          	jalr	-454(ra) # 80004610 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037de:	08848493          	addi	s1,s1,136
    800037e2:	ff3498e3          	bne	s1,s3,800037d2 <iinit+0x3e>
}
    800037e6:	70a2                	ld	ra,40(sp)
    800037e8:	7402                	ld	s0,32(sp)
    800037ea:	64e2                	ld	s1,24(sp)
    800037ec:	6942                	ld	s2,16(sp)
    800037ee:	69a2                	ld	s3,8(sp)
    800037f0:	6145                	addi	sp,sp,48
    800037f2:	8082                	ret

00000000800037f4 <ialloc>:
{
    800037f4:	715d                	addi	sp,sp,-80
    800037f6:	e486                	sd	ra,72(sp)
    800037f8:	e0a2                	sd	s0,64(sp)
    800037fa:	fc26                	sd	s1,56(sp)
    800037fc:	f84a                	sd	s2,48(sp)
    800037fe:	f44e                	sd	s3,40(sp)
    80003800:	f052                	sd	s4,32(sp)
    80003802:	ec56                	sd	s5,24(sp)
    80003804:	e85a                	sd	s6,16(sp)
    80003806:	e45e                	sd	s7,8(sp)
    80003808:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000380a:	0001d717          	auipc	a4,0x1d
    8000380e:	93272703          	lw	a4,-1742(a4) # 8002013c <sb+0xc>
    80003812:	4785                	li	a5,1
    80003814:	04e7fa63          	bgeu	a5,a4,80003868 <ialloc+0x74>
    80003818:	8aaa                	mv	s5,a0
    8000381a:	8bae                	mv	s7,a1
    8000381c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000381e:	0001da17          	auipc	s4,0x1d
    80003822:	912a0a13          	addi	s4,s4,-1774 # 80020130 <sb>
    80003826:	00048b1b          	sext.w	s6,s1
    8000382a:	0044d793          	srli	a5,s1,0x4
    8000382e:	018a2583          	lw	a1,24(s4)
    80003832:	9dbd                	addw	a1,a1,a5
    80003834:	8556                	mv	a0,s5
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	940080e7          	jalr	-1728(ra) # 80003176 <bread>
    8000383e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003840:	05850993          	addi	s3,a0,88
    80003844:	00f4f793          	andi	a5,s1,15
    80003848:	079a                	slli	a5,a5,0x6
    8000384a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000384c:	00099783          	lh	a5,0(s3)
    80003850:	c3a1                	beqz	a5,80003890 <ialloc+0x9c>
    brelse(bp);
    80003852:	00000097          	auipc	ra,0x0
    80003856:	a54080e7          	jalr	-1452(ra) # 800032a6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000385a:	0485                	addi	s1,s1,1
    8000385c:	00ca2703          	lw	a4,12(s4)
    80003860:	0004879b          	sext.w	a5,s1
    80003864:	fce7e1e3          	bltu	a5,a4,80003826 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	e3850513          	addi	a0,a0,-456 # 800086a0 <syscalls+0x178>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	e26080e7          	jalr	-474(ra) # 80000696 <printf>
  return 0;
    80003878:	4501                	li	a0,0
}
    8000387a:	60a6                	ld	ra,72(sp)
    8000387c:	6406                	ld	s0,64(sp)
    8000387e:	74e2                	ld	s1,56(sp)
    80003880:	7942                	ld	s2,48(sp)
    80003882:	79a2                	ld	s3,40(sp)
    80003884:	7a02                	ld	s4,32(sp)
    80003886:	6ae2                	ld	s5,24(sp)
    80003888:	6b42                	ld	s6,16(sp)
    8000388a:	6ba2                	ld	s7,8(sp)
    8000388c:	6161                	addi	sp,sp,80
    8000388e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003890:	04000613          	li	a2,64
    80003894:	4581                	li	a1,0
    80003896:	854e                	mv	a0,s3
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	548080e7          	jalr	1352(ra) # 80000de0 <memset>
      dip->type = type;
    800038a0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038a4:	854a                	mv	a0,s2
    800038a6:	00001097          	auipc	ra,0x1
    800038aa:	c84080e7          	jalr	-892(ra) # 8000452a <log_write>
      brelse(bp);
    800038ae:	854a                	mv	a0,s2
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	9f6080e7          	jalr	-1546(ra) # 800032a6 <brelse>
      return iget(dev, inum);
    800038b8:	85da                	mv	a1,s6
    800038ba:	8556                	mv	a0,s5
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	d9c080e7          	jalr	-612(ra) # 80003658 <iget>
    800038c4:	bf5d                	j	8000387a <ialloc+0x86>

00000000800038c6 <iupdate>:
{
    800038c6:	1101                	addi	sp,sp,-32
    800038c8:	ec06                	sd	ra,24(sp)
    800038ca:	e822                	sd	s0,16(sp)
    800038cc:	e426                	sd	s1,8(sp)
    800038ce:	e04a                	sd	s2,0(sp)
    800038d0:	1000                	addi	s0,sp,32
    800038d2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038d4:	415c                	lw	a5,4(a0)
    800038d6:	0047d79b          	srliw	a5,a5,0x4
    800038da:	0001d597          	auipc	a1,0x1d
    800038de:	86e5a583          	lw	a1,-1938(a1) # 80020148 <sb+0x18>
    800038e2:	9dbd                	addw	a1,a1,a5
    800038e4:	4108                	lw	a0,0(a0)
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	890080e7          	jalr	-1904(ra) # 80003176 <bread>
    800038ee:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038f0:	05850793          	addi	a5,a0,88
    800038f4:	40c8                	lw	a0,4(s1)
    800038f6:	893d                	andi	a0,a0,15
    800038f8:	051a                	slli	a0,a0,0x6
    800038fa:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038fc:	04449703          	lh	a4,68(s1)
    80003900:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003904:	04649703          	lh	a4,70(s1)
    80003908:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000390c:	04849703          	lh	a4,72(s1)
    80003910:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003914:	04a49703          	lh	a4,74(s1)
    80003918:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000391c:	44f8                	lw	a4,76(s1)
    8000391e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003920:	03400613          	li	a2,52
    80003924:	05048593          	addi	a1,s1,80
    80003928:	0531                	addi	a0,a0,12
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	512080e7          	jalr	1298(ra) # 80000e3c <memmove>
  log_write(bp);
    80003932:	854a                	mv	a0,s2
    80003934:	00001097          	auipc	ra,0x1
    80003938:	bf6080e7          	jalr	-1034(ra) # 8000452a <log_write>
  brelse(bp);
    8000393c:	854a                	mv	a0,s2
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	968080e7          	jalr	-1688(ra) # 800032a6 <brelse>
}
    80003946:	60e2                	ld	ra,24(sp)
    80003948:	6442                	ld	s0,16(sp)
    8000394a:	64a2                	ld	s1,8(sp)
    8000394c:	6902                	ld	s2,0(sp)
    8000394e:	6105                	addi	sp,sp,32
    80003950:	8082                	ret

0000000080003952 <idup>:
{
    80003952:	1101                	addi	sp,sp,-32
    80003954:	ec06                	sd	ra,24(sp)
    80003956:	e822                	sd	s0,16(sp)
    80003958:	e426                	sd	s1,8(sp)
    8000395a:	1000                	addi	s0,sp,32
    8000395c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000395e:	0001c517          	auipc	a0,0x1c
    80003962:	7f250513          	addi	a0,a0,2034 # 80020150 <itable>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	37e080e7          	jalr	894(ra) # 80000ce4 <acquire>
  ip->ref++;
    8000396e:	449c                	lw	a5,8(s1)
    80003970:	2785                	addiw	a5,a5,1
    80003972:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003974:	0001c517          	auipc	a0,0x1c
    80003978:	7dc50513          	addi	a0,a0,2012 # 80020150 <itable>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	41c080e7          	jalr	1052(ra) # 80000d98 <release>
}
    80003984:	8526                	mv	a0,s1
    80003986:	60e2                	ld	ra,24(sp)
    80003988:	6442                	ld	s0,16(sp)
    8000398a:	64a2                	ld	s1,8(sp)
    8000398c:	6105                	addi	sp,sp,32
    8000398e:	8082                	ret

0000000080003990 <ilock>:
{
    80003990:	1101                	addi	sp,sp,-32
    80003992:	ec06                	sd	ra,24(sp)
    80003994:	e822                	sd	s0,16(sp)
    80003996:	e426                	sd	s1,8(sp)
    80003998:	e04a                	sd	s2,0(sp)
    8000399a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000399c:	c115                	beqz	a0,800039c0 <ilock+0x30>
    8000399e:	84aa                	mv	s1,a0
    800039a0:	451c                	lw	a5,8(a0)
    800039a2:	00f05f63          	blez	a5,800039c0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039a6:	0541                	addi	a0,a0,16
    800039a8:	00001097          	auipc	ra,0x1
    800039ac:	ca2080e7          	jalr	-862(ra) # 8000464a <acquiresleep>
  if(ip->valid == 0){
    800039b0:	40bc                	lw	a5,64(s1)
    800039b2:	cf99                	beqz	a5,800039d0 <ilock+0x40>
}
    800039b4:	60e2                	ld	ra,24(sp)
    800039b6:	6442                	ld	s0,16(sp)
    800039b8:	64a2                	ld	s1,8(sp)
    800039ba:	6902                	ld	s2,0(sp)
    800039bc:	6105                	addi	sp,sp,32
    800039be:	8082                	ret
    panic("ilock");
    800039c0:	00005517          	auipc	a0,0x5
    800039c4:	cf850513          	addi	a0,a0,-776 # 800086b8 <syscalls+0x190>
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	c84080e7          	jalr	-892(ra) # 8000064c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039d0:	40dc                	lw	a5,4(s1)
    800039d2:	0047d79b          	srliw	a5,a5,0x4
    800039d6:	0001c597          	auipc	a1,0x1c
    800039da:	7725a583          	lw	a1,1906(a1) # 80020148 <sb+0x18>
    800039de:	9dbd                	addw	a1,a1,a5
    800039e0:	4088                	lw	a0,0(s1)
    800039e2:	fffff097          	auipc	ra,0xfffff
    800039e6:	794080e7          	jalr	1940(ra) # 80003176 <bread>
    800039ea:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039ec:	05850593          	addi	a1,a0,88
    800039f0:	40dc                	lw	a5,4(s1)
    800039f2:	8bbd                	andi	a5,a5,15
    800039f4:	079a                	slli	a5,a5,0x6
    800039f6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039f8:	00059783          	lh	a5,0(a1)
    800039fc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a00:	00259783          	lh	a5,2(a1)
    80003a04:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a08:	00459783          	lh	a5,4(a1)
    80003a0c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a10:	00659783          	lh	a5,6(a1)
    80003a14:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a18:	459c                	lw	a5,8(a1)
    80003a1a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a1c:	03400613          	li	a2,52
    80003a20:	05b1                	addi	a1,a1,12
    80003a22:	05048513          	addi	a0,s1,80
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	416080e7          	jalr	1046(ra) # 80000e3c <memmove>
    brelse(bp);
    80003a2e:	854a                	mv	a0,s2
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	876080e7          	jalr	-1930(ra) # 800032a6 <brelse>
    ip->valid = 1;
    80003a38:	4785                	li	a5,1
    80003a3a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a3c:	04449783          	lh	a5,68(s1)
    80003a40:	fbb5                	bnez	a5,800039b4 <ilock+0x24>
      panic("ilock: no type");
    80003a42:	00005517          	auipc	a0,0x5
    80003a46:	c7e50513          	addi	a0,a0,-898 # 800086c0 <syscalls+0x198>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	c02080e7          	jalr	-1022(ra) # 8000064c <panic>

0000000080003a52 <iunlock>:
{
    80003a52:	1101                	addi	sp,sp,-32
    80003a54:	ec06                	sd	ra,24(sp)
    80003a56:	e822                	sd	s0,16(sp)
    80003a58:	e426                	sd	s1,8(sp)
    80003a5a:	e04a                	sd	s2,0(sp)
    80003a5c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a5e:	c905                	beqz	a0,80003a8e <iunlock+0x3c>
    80003a60:	84aa                	mv	s1,a0
    80003a62:	01050913          	addi	s2,a0,16
    80003a66:	854a                	mv	a0,s2
    80003a68:	00001097          	auipc	ra,0x1
    80003a6c:	c7c080e7          	jalr	-900(ra) # 800046e4 <holdingsleep>
    80003a70:	cd19                	beqz	a0,80003a8e <iunlock+0x3c>
    80003a72:	449c                	lw	a5,8(s1)
    80003a74:	00f05d63          	blez	a5,80003a8e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a78:	854a                	mv	a0,s2
    80003a7a:	00001097          	auipc	ra,0x1
    80003a7e:	c26080e7          	jalr	-986(ra) # 800046a0 <releasesleep>
}
    80003a82:	60e2                	ld	ra,24(sp)
    80003a84:	6442                	ld	s0,16(sp)
    80003a86:	64a2                	ld	s1,8(sp)
    80003a88:	6902                	ld	s2,0(sp)
    80003a8a:	6105                	addi	sp,sp,32
    80003a8c:	8082                	ret
    panic("iunlock");
    80003a8e:	00005517          	auipc	a0,0x5
    80003a92:	c4250513          	addi	a0,a0,-958 # 800086d0 <syscalls+0x1a8>
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	bb6080e7          	jalr	-1098(ra) # 8000064c <panic>

0000000080003a9e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a9e:	7179                	addi	sp,sp,-48
    80003aa0:	f406                	sd	ra,40(sp)
    80003aa2:	f022                	sd	s0,32(sp)
    80003aa4:	ec26                	sd	s1,24(sp)
    80003aa6:	e84a                	sd	s2,16(sp)
    80003aa8:	e44e                	sd	s3,8(sp)
    80003aaa:	e052                	sd	s4,0(sp)
    80003aac:	1800                	addi	s0,sp,48
    80003aae:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ab0:	05050493          	addi	s1,a0,80
    80003ab4:	08050913          	addi	s2,a0,128
    80003ab8:	a021                	j	80003ac0 <itrunc+0x22>
    80003aba:	0491                	addi	s1,s1,4
    80003abc:	01248d63          	beq	s1,s2,80003ad6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ac0:	408c                	lw	a1,0(s1)
    80003ac2:	dde5                	beqz	a1,80003aba <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ac4:	0009a503          	lw	a0,0(s3)
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	8f4080e7          	jalr	-1804(ra) # 800033bc <bfree>
      ip->addrs[i] = 0;
    80003ad0:	0004a023          	sw	zero,0(s1)
    80003ad4:	b7dd                	j	80003aba <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ad6:	0809a583          	lw	a1,128(s3)
    80003ada:	e185                	bnez	a1,80003afa <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003adc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ae0:	854e                	mv	a0,s3
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	de4080e7          	jalr	-540(ra) # 800038c6 <iupdate>
}
    80003aea:	70a2                	ld	ra,40(sp)
    80003aec:	7402                	ld	s0,32(sp)
    80003aee:	64e2                	ld	s1,24(sp)
    80003af0:	6942                	ld	s2,16(sp)
    80003af2:	69a2                	ld	s3,8(sp)
    80003af4:	6a02                	ld	s4,0(sp)
    80003af6:	6145                	addi	sp,sp,48
    80003af8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003afa:	0009a503          	lw	a0,0(s3)
    80003afe:	fffff097          	auipc	ra,0xfffff
    80003b02:	678080e7          	jalr	1656(ra) # 80003176 <bread>
    80003b06:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b08:	05850493          	addi	s1,a0,88
    80003b0c:	45850913          	addi	s2,a0,1112
    80003b10:	a021                	j	80003b18 <itrunc+0x7a>
    80003b12:	0491                	addi	s1,s1,4
    80003b14:	01248b63          	beq	s1,s2,80003b2a <itrunc+0x8c>
      if(a[j])
    80003b18:	408c                	lw	a1,0(s1)
    80003b1a:	dde5                	beqz	a1,80003b12 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b1c:	0009a503          	lw	a0,0(s3)
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	89c080e7          	jalr	-1892(ra) # 800033bc <bfree>
    80003b28:	b7ed                	j	80003b12 <itrunc+0x74>
    brelse(bp);
    80003b2a:	8552                	mv	a0,s4
    80003b2c:	fffff097          	auipc	ra,0xfffff
    80003b30:	77a080e7          	jalr	1914(ra) # 800032a6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b34:	0809a583          	lw	a1,128(s3)
    80003b38:	0009a503          	lw	a0,0(s3)
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	880080e7          	jalr	-1920(ra) # 800033bc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b44:	0809a023          	sw	zero,128(s3)
    80003b48:	bf51                	j	80003adc <itrunc+0x3e>

0000000080003b4a <iput>:
{
    80003b4a:	1101                	addi	sp,sp,-32
    80003b4c:	ec06                	sd	ra,24(sp)
    80003b4e:	e822                	sd	s0,16(sp)
    80003b50:	e426                	sd	s1,8(sp)
    80003b52:	e04a                	sd	s2,0(sp)
    80003b54:	1000                	addi	s0,sp,32
    80003b56:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b58:	0001c517          	auipc	a0,0x1c
    80003b5c:	5f850513          	addi	a0,a0,1528 # 80020150 <itable>
    80003b60:	ffffd097          	auipc	ra,0xffffd
    80003b64:	184080e7          	jalr	388(ra) # 80000ce4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b68:	4498                	lw	a4,8(s1)
    80003b6a:	4785                	li	a5,1
    80003b6c:	02f70363          	beq	a4,a5,80003b92 <iput+0x48>
  ip->ref--;
    80003b70:	449c                	lw	a5,8(s1)
    80003b72:	37fd                	addiw	a5,a5,-1
    80003b74:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b76:	0001c517          	auipc	a0,0x1c
    80003b7a:	5da50513          	addi	a0,a0,1498 # 80020150 <itable>
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	21a080e7          	jalr	538(ra) # 80000d98 <release>
}
    80003b86:	60e2                	ld	ra,24(sp)
    80003b88:	6442                	ld	s0,16(sp)
    80003b8a:	64a2                	ld	s1,8(sp)
    80003b8c:	6902                	ld	s2,0(sp)
    80003b8e:	6105                	addi	sp,sp,32
    80003b90:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b92:	40bc                	lw	a5,64(s1)
    80003b94:	dff1                	beqz	a5,80003b70 <iput+0x26>
    80003b96:	04a49783          	lh	a5,74(s1)
    80003b9a:	fbf9                	bnez	a5,80003b70 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b9c:	01048913          	addi	s2,s1,16
    80003ba0:	854a                	mv	a0,s2
    80003ba2:	00001097          	auipc	ra,0x1
    80003ba6:	aa8080e7          	jalr	-1368(ra) # 8000464a <acquiresleep>
    release(&itable.lock);
    80003baa:	0001c517          	auipc	a0,0x1c
    80003bae:	5a650513          	addi	a0,a0,1446 # 80020150 <itable>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	1e6080e7          	jalr	486(ra) # 80000d98 <release>
    itrunc(ip);
    80003bba:	8526                	mv	a0,s1
    80003bbc:	00000097          	auipc	ra,0x0
    80003bc0:	ee2080e7          	jalr	-286(ra) # 80003a9e <itrunc>
    ip->type = 0;
    80003bc4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bc8:	8526                	mv	a0,s1
    80003bca:	00000097          	auipc	ra,0x0
    80003bce:	cfc080e7          	jalr	-772(ra) # 800038c6 <iupdate>
    ip->valid = 0;
    80003bd2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00001097          	auipc	ra,0x1
    80003bdc:	ac8080e7          	jalr	-1336(ra) # 800046a0 <releasesleep>
    acquire(&itable.lock);
    80003be0:	0001c517          	auipc	a0,0x1c
    80003be4:	57050513          	addi	a0,a0,1392 # 80020150 <itable>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	0fc080e7          	jalr	252(ra) # 80000ce4 <acquire>
    80003bf0:	b741                	j	80003b70 <iput+0x26>

0000000080003bf2 <iunlockput>:
{
    80003bf2:	1101                	addi	sp,sp,-32
    80003bf4:	ec06                	sd	ra,24(sp)
    80003bf6:	e822                	sd	s0,16(sp)
    80003bf8:	e426                	sd	s1,8(sp)
    80003bfa:	1000                	addi	s0,sp,32
    80003bfc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	e54080e7          	jalr	-428(ra) # 80003a52 <iunlock>
  iput(ip);
    80003c06:	8526                	mv	a0,s1
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	f42080e7          	jalr	-190(ra) # 80003b4a <iput>
}
    80003c10:	60e2                	ld	ra,24(sp)
    80003c12:	6442                	ld	s0,16(sp)
    80003c14:	64a2                	ld	s1,8(sp)
    80003c16:	6105                	addi	sp,sp,32
    80003c18:	8082                	ret

0000000080003c1a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c1a:	1141                	addi	sp,sp,-16
    80003c1c:	e422                	sd	s0,8(sp)
    80003c1e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c20:	411c                	lw	a5,0(a0)
    80003c22:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c24:	415c                	lw	a5,4(a0)
    80003c26:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c28:	04451783          	lh	a5,68(a0)
    80003c2c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c30:	04a51783          	lh	a5,74(a0)
    80003c34:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c38:	04c56783          	lwu	a5,76(a0)
    80003c3c:	e99c                	sd	a5,16(a1)
}
    80003c3e:	6422                	ld	s0,8(sp)
    80003c40:	0141                	addi	sp,sp,16
    80003c42:	8082                	ret

0000000080003c44 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c44:	457c                	lw	a5,76(a0)
    80003c46:	0ed7e963          	bltu	a5,a3,80003d38 <readi+0xf4>
{
    80003c4a:	7159                	addi	sp,sp,-112
    80003c4c:	f486                	sd	ra,104(sp)
    80003c4e:	f0a2                	sd	s0,96(sp)
    80003c50:	eca6                	sd	s1,88(sp)
    80003c52:	e8ca                	sd	s2,80(sp)
    80003c54:	e4ce                	sd	s3,72(sp)
    80003c56:	e0d2                	sd	s4,64(sp)
    80003c58:	fc56                	sd	s5,56(sp)
    80003c5a:	f85a                	sd	s6,48(sp)
    80003c5c:	f45e                	sd	s7,40(sp)
    80003c5e:	f062                	sd	s8,32(sp)
    80003c60:	ec66                	sd	s9,24(sp)
    80003c62:	e86a                	sd	s10,16(sp)
    80003c64:	e46e                	sd	s11,8(sp)
    80003c66:	1880                	addi	s0,sp,112
    80003c68:	8b2a                	mv	s6,a0
    80003c6a:	8bae                	mv	s7,a1
    80003c6c:	8a32                	mv	s4,a2
    80003c6e:	84b6                	mv	s1,a3
    80003c70:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c72:	9f35                	addw	a4,a4,a3
    return 0;
    80003c74:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c76:	0ad76063          	bltu	a4,a3,80003d16 <readi+0xd2>
  if(off + n > ip->size)
    80003c7a:	00e7f463          	bgeu	a5,a4,80003c82 <readi+0x3e>
    n = ip->size - off;
    80003c7e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c82:	0a0a8963          	beqz	s5,80003d34 <readi+0xf0>
    80003c86:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c88:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c8c:	5c7d                	li	s8,-1
    80003c8e:	a82d                	j	80003cc8 <readi+0x84>
    80003c90:	020d1d93          	slli	s11,s10,0x20
    80003c94:	020ddd93          	srli	s11,s11,0x20
    80003c98:	05890793          	addi	a5,s2,88
    80003c9c:	86ee                	mv	a3,s11
    80003c9e:	963e                	add	a2,a2,a5
    80003ca0:	85d2                	mv	a1,s4
    80003ca2:	855e                	mv	a0,s7
    80003ca4:	fffff097          	auipc	ra,0xfffff
    80003ca8:	8c6080e7          	jalr	-1850(ra) # 8000256a <either_copyout>
    80003cac:	05850d63          	beq	a0,s8,80003d06 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cb0:	854a                	mv	a0,s2
    80003cb2:	fffff097          	auipc	ra,0xfffff
    80003cb6:	5f4080e7          	jalr	1524(ra) # 800032a6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cba:	013d09bb          	addw	s3,s10,s3
    80003cbe:	009d04bb          	addw	s1,s10,s1
    80003cc2:	9a6e                	add	s4,s4,s11
    80003cc4:	0559f763          	bgeu	s3,s5,80003d12 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003cc8:	00a4d59b          	srliw	a1,s1,0xa
    80003ccc:	855a                	mv	a0,s6
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	8a2080e7          	jalr	-1886(ra) # 80003570 <bmap>
    80003cd6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003cda:	cd85                	beqz	a1,80003d12 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003cdc:	000b2503          	lw	a0,0(s6)
    80003ce0:	fffff097          	auipc	ra,0xfffff
    80003ce4:	496080e7          	jalr	1174(ra) # 80003176 <bread>
    80003ce8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cea:	3ff4f613          	andi	a2,s1,1023
    80003cee:	40cc87bb          	subw	a5,s9,a2
    80003cf2:	413a873b          	subw	a4,s5,s3
    80003cf6:	8d3e                	mv	s10,a5
    80003cf8:	2781                	sext.w	a5,a5
    80003cfa:	0007069b          	sext.w	a3,a4
    80003cfe:	f8f6f9e3          	bgeu	a3,a5,80003c90 <readi+0x4c>
    80003d02:	8d3a                	mv	s10,a4
    80003d04:	b771                	j	80003c90 <readi+0x4c>
      brelse(bp);
    80003d06:	854a                	mv	a0,s2
    80003d08:	fffff097          	auipc	ra,0xfffff
    80003d0c:	59e080e7          	jalr	1438(ra) # 800032a6 <brelse>
      tot = -1;
    80003d10:	59fd                	li	s3,-1
  }
  return tot;
    80003d12:	0009851b          	sext.w	a0,s3
}
    80003d16:	70a6                	ld	ra,104(sp)
    80003d18:	7406                	ld	s0,96(sp)
    80003d1a:	64e6                	ld	s1,88(sp)
    80003d1c:	6946                	ld	s2,80(sp)
    80003d1e:	69a6                	ld	s3,72(sp)
    80003d20:	6a06                	ld	s4,64(sp)
    80003d22:	7ae2                	ld	s5,56(sp)
    80003d24:	7b42                	ld	s6,48(sp)
    80003d26:	7ba2                	ld	s7,40(sp)
    80003d28:	7c02                	ld	s8,32(sp)
    80003d2a:	6ce2                	ld	s9,24(sp)
    80003d2c:	6d42                	ld	s10,16(sp)
    80003d2e:	6da2                	ld	s11,8(sp)
    80003d30:	6165                	addi	sp,sp,112
    80003d32:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d34:	89d6                	mv	s3,s5
    80003d36:	bff1                	j	80003d12 <readi+0xce>
    return 0;
    80003d38:	4501                	li	a0,0
}
    80003d3a:	8082                	ret

0000000080003d3c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d3c:	457c                	lw	a5,76(a0)
    80003d3e:	10d7e863          	bltu	a5,a3,80003e4e <writei+0x112>
{
    80003d42:	7159                	addi	sp,sp,-112
    80003d44:	f486                	sd	ra,104(sp)
    80003d46:	f0a2                	sd	s0,96(sp)
    80003d48:	eca6                	sd	s1,88(sp)
    80003d4a:	e8ca                	sd	s2,80(sp)
    80003d4c:	e4ce                	sd	s3,72(sp)
    80003d4e:	e0d2                	sd	s4,64(sp)
    80003d50:	fc56                	sd	s5,56(sp)
    80003d52:	f85a                	sd	s6,48(sp)
    80003d54:	f45e                	sd	s7,40(sp)
    80003d56:	f062                	sd	s8,32(sp)
    80003d58:	ec66                	sd	s9,24(sp)
    80003d5a:	e86a                	sd	s10,16(sp)
    80003d5c:	e46e                	sd	s11,8(sp)
    80003d5e:	1880                	addi	s0,sp,112
    80003d60:	8aaa                	mv	s5,a0
    80003d62:	8bae                	mv	s7,a1
    80003d64:	8a32                	mv	s4,a2
    80003d66:	8936                	mv	s2,a3
    80003d68:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d6a:	00e687bb          	addw	a5,a3,a4
    80003d6e:	0ed7e263          	bltu	a5,a3,80003e52 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d72:	00043737          	lui	a4,0x43
    80003d76:	0ef76063          	bltu	a4,a5,80003e56 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d7a:	0c0b0863          	beqz	s6,80003e4a <writei+0x10e>
    80003d7e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d80:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d84:	5c7d                	li	s8,-1
    80003d86:	a091                	j	80003dca <writei+0x8e>
    80003d88:	020d1d93          	slli	s11,s10,0x20
    80003d8c:	020ddd93          	srli	s11,s11,0x20
    80003d90:	05848793          	addi	a5,s1,88
    80003d94:	86ee                	mv	a3,s11
    80003d96:	8652                	mv	a2,s4
    80003d98:	85de                	mv	a1,s7
    80003d9a:	953e                	add	a0,a0,a5
    80003d9c:	fffff097          	auipc	ra,0xfffff
    80003da0:	824080e7          	jalr	-2012(ra) # 800025c0 <either_copyin>
    80003da4:	07850263          	beq	a0,s8,80003e08 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003da8:	8526                	mv	a0,s1
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	780080e7          	jalr	1920(ra) # 8000452a <log_write>
    brelse(bp);
    80003db2:	8526                	mv	a0,s1
    80003db4:	fffff097          	auipc	ra,0xfffff
    80003db8:	4f2080e7          	jalr	1266(ra) # 800032a6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dbc:	013d09bb          	addw	s3,s10,s3
    80003dc0:	012d093b          	addw	s2,s10,s2
    80003dc4:	9a6e                	add	s4,s4,s11
    80003dc6:	0569f663          	bgeu	s3,s6,80003e12 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003dca:	00a9559b          	srliw	a1,s2,0xa
    80003dce:	8556                	mv	a0,s5
    80003dd0:	fffff097          	auipc	ra,0xfffff
    80003dd4:	7a0080e7          	jalr	1952(ra) # 80003570 <bmap>
    80003dd8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ddc:	c99d                	beqz	a1,80003e12 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003dde:	000aa503          	lw	a0,0(s5)
    80003de2:	fffff097          	auipc	ra,0xfffff
    80003de6:	394080e7          	jalr	916(ra) # 80003176 <bread>
    80003dea:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dec:	3ff97513          	andi	a0,s2,1023
    80003df0:	40ac87bb          	subw	a5,s9,a0
    80003df4:	413b073b          	subw	a4,s6,s3
    80003df8:	8d3e                	mv	s10,a5
    80003dfa:	2781                	sext.w	a5,a5
    80003dfc:	0007069b          	sext.w	a3,a4
    80003e00:	f8f6f4e3          	bgeu	a3,a5,80003d88 <writei+0x4c>
    80003e04:	8d3a                	mv	s10,a4
    80003e06:	b749                	j	80003d88 <writei+0x4c>
      brelse(bp);
    80003e08:	8526                	mv	a0,s1
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	49c080e7          	jalr	1180(ra) # 800032a6 <brelse>
  }

  if(off > ip->size)
    80003e12:	04caa783          	lw	a5,76(s5)
    80003e16:	0127f463          	bgeu	a5,s2,80003e1e <writei+0xe2>
    ip->size = off;
    80003e1a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e1e:	8556                	mv	a0,s5
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	aa6080e7          	jalr	-1370(ra) # 800038c6 <iupdate>

  return tot;
    80003e28:	0009851b          	sext.w	a0,s3
}
    80003e2c:	70a6                	ld	ra,104(sp)
    80003e2e:	7406                	ld	s0,96(sp)
    80003e30:	64e6                	ld	s1,88(sp)
    80003e32:	6946                	ld	s2,80(sp)
    80003e34:	69a6                	ld	s3,72(sp)
    80003e36:	6a06                	ld	s4,64(sp)
    80003e38:	7ae2                	ld	s5,56(sp)
    80003e3a:	7b42                	ld	s6,48(sp)
    80003e3c:	7ba2                	ld	s7,40(sp)
    80003e3e:	7c02                	ld	s8,32(sp)
    80003e40:	6ce2                	ld	s9,24(sp)
    80003e42:	6d42                	ld	s10,16(sp)
    80003e44:	6da2                	ld	s11,8(sp)
    80003e46:	6165                	addi	sp,sp,112
    80003e48:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e4a:	89da                	mv	s3,s6
    80003e4c:	bfc9                	j	80003e1e <writei+0xe2>
    return -1;
    80003e4e:	557d                	li	a0,-1
}
    80003e50:	8082                	ret
    return -1;
    80003e52:	557d                	li	a0,-1
    80003e54:	bfe1                	j	80003e2c <writei+0xf0>
    return -1;
    80003e56:	557d                	li	a0,-1
    80003e58:	bfd1                	j	80003e2c <writei+0xf0>

0000000080003e5a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e5a:	1141                	addi	sp,sp,-16
    80003e5c:	e406                	sd	ra,8(sp)
    80003e5e:	e022                	sd	s0,0(sp)
    80003e60:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e62:	4639                	li	a2,14
    80003e64:	ffffd097          	auipc	ra,0xffffd
    80003e68:	04c080e7          	jalr	76(ra) # 80000eb0 <strncmp>
}
    80003e6c:	60a2                	ld	ra,8(sp)
    80003e6e:	6402                	ld	s0,0(sp)
    80003e70:	0141                	addi	sp,sp,16
    80003e72:	8082                	ret

0000000080003e74 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e74:	7139                	addi	sp,sp,-64
    80003e76:	fc06                	sd	ra,56(sp)
    80003e78:	f822                	sd	s0,48(sp)
    80003e7a:	f426                	sd	s1,40(sp)
    80003e7c:	f04a                	sd	s2,32(sp)
    80003e7e:	ec4e                	sd	s3,24(sp)
    80003e80:	e852                	sd	s4,16(sp)
    80003e82:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e84:	04451703          	lh	a4,68(a0)
    80003e88:	4785                	li	a5,1
    80003e8a:	00f71a63          	bne	a4,a5,80003e9e <dirlookup+0x2a>
    80003e8e:	892a                	mv	s2,a0
    80003e90:	89ae                	mv	s3,a1
    80003e92:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e94:	457c                	lw	a5,76(a0)
    80003e96:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e98:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e9a:	e79d                	bnez	a5,80003ec8 <dirlookup+0x54>
    80003e9c:	a8a5                	j	80003f14 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e9e:	00005517          	auipc	a0,0x5
    80003ea2:	83a50513          	addi	a0,a0,-1990 # 800086d8 <syscalls+0x1b0>
    80003ea6:	ffffc097          	auipc	ra,0xffffc
    80003eaa:	7a6080e7          	jalr	1958(ra) # 8000064c <panic>
      panic("dirlookup read");
    80003eae:	00005517          	auipc	a0,0x5
    80003eb2:	84250513          	addi	a0,a0,-1982 # 800086f0 <syscalls+0x1c8>
    80003eb6:	ffffc097          	auipc	ra,0xffffc
    80003eba:	796080e7          	jalr	1942(ra) # 8000064c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ebe:	24c1                	addiw	s1,s1,16
    80003ec0:	04c92783          	lw	a5,76(s2)
    80003ec4:	04f4f763          	bgeu	s1,a5,80003f12 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec8:	4741                	li	a4,16
    80003eca:	86a6                	mv	a3,s1
    80003ecc:	fc040613          	addi	a2,s0,-64
    80003ed0:	4581                	li	a1,0
    80003ed2:	854a                	mv	a0,s2
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	d70080e7          	jalr	-656(ra) # 80003c44 <readi>
    80003edc:	47c1                	li	a5,16
    80003ede:	fcf518e3          	bne	a0,a5,80003eae <dirlookup+0x3a>
    if(de.inum == 0)
    80003ee2:	fc045783          	lhu	a5,-64(s0)
    80003ee6:	dfe1                	beqz	a5,80003ebe <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ee8:	fc240593          	addi	a1,s0,-62
    80003eec:	854e                	mv	a0,s3
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	f6c080e7          	jalr	-148(ra) # 80003e5a <namecmp>
    80003ef6:	f561                	bnez	a0,80003ebe <dirlookup+0x4a>
      if(poff)
    80003ef8:	000a0463          	beqz	s4,80003f00 <dirlookup+0x8c>
        *poff = off;
    80003efc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f00:	fc045583          	lhu	a1,-64(s0)
    80003f04:	00092503          	lw	a0,0(s2)
    80003f08:	fffff097          	auipc	ra,0xfffff
    80003f0c:	750080e7          	jalr	1872(ra) # 80003658 <iget>
    80003f10:	a011                	j	80003f14 <dirlookup+0xa0>
  return 0;
    80003f12:	4501                	li	a0,0
}
    80003f14:	70e2                	ld	ra,56(sp)
    80003f16:	7442                	ld	s0,48(sp)
    80003f18:	74a2                	ld	s1,40(sp)
    80003f1a:	7902                	ld	s2,32(sp)
    80003f1c:	69e2                	ld	s3,24(sp)
    80003f1e:	6a42                	ld	s4,16(sp)
    80003f20:	6121                	addi	sp,sp,64
    80003f22:	8082                	ret

0000000080003f24 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f24:	711d                	addi	sp,sp,-96
    80003f26:	ec86                	sd	ra,88(sp)
    80003f28:	e8a2                	sd	s0,80(sp)
    80003f2a:	e4a6                	sd	s1,72(sp)
    80003f2c:	e0ca                	sd	s2,64(sp)
    80003f2e:	fc4e                	sd	s3,56(sp)
    80003f30:	f852                	sd	s4,48(sp)
    80003f32:	f456                	sd	s5,40(sp)
    80003f34:	f05a                	sd	s6,32(sp)
    80003f36:	ec5e                	sd	s7,24(sp)
    80003f38:	e862                	sd	s8,16(sp)
    80003f3a:	e466                	sd	s9,8(sp)
    80003f3c:	1080                	addi	s0,sp,96
    80003f3e:	84aa                	mv	s1,a0
    80003f40:	8aae                	mv	s5,a1
    80003f42:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f44:	00054703          	lbu	a4,0(a0)
    80003f48:	02f00793          	li	a5,47
    80003f4c:	02f70363          	beq	a4,a5,80003f72 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f50:	ffffe097          	auipc	ra,0xffffe
    80003f54:	b6a080e7          	jalr	-1174(ra) # 80001aba <myproc>
    80003f58:	15053503          	ld	a0,336(a0)
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	9f6080e7          	jalr	-1546(ra) # 80003952 <idup>
    80003f64:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f66:	02f00913          	li	s2,47
  len = path - s;
    80003f6a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f6c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f6e:	4b85                	li	s7,1
    80003f70:	a865                	j	80004028 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f72:	4585                	li	a1,1
    80003f74:	4505                	li	a0,1
    80003f76:	fffff097          	auipc	ra,0xfffff
    80003f7a:	6e2080e7          	jalr	1762(ra) # 80003658 <iget>
    80003f7e:	89aa                	mv	s3,a0
    80003f80:	b7dd                	j	80003f66 <namex+0x42>
      iunlockput(ip);
    80003f82:	854e                	mv	a0,s3
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	c6e080e7          	jalr	-914(ra) # 80003bf2 <iunlockput>
      return 0;
    80003f8c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f8e:	854e                	mv	a0,s3
    80003f90:	60e6                	ld	ra,88(sp)
    80003f92:	6446                	ld	s0,80(sp)
    80003f94:	64a6                	ld	s1,72(sp)
    80003f96:	6906                	ld	s2,64(sp)
    80003f98:	79e2                	ld	s3,56(sp)
    80003f9a:	7a42                	ld	s4,48(sp)
    80003f9c:	7aa2                	ld	s5,40(sp)
    80003f9e:	7b02                	ld	s6,32(sp)
    80003fa0:	6be2                	ld	s7,24(sp)
    80003fa2:	6c42                	ld	s8,16(sp)
    80003fa4:	6ca2                	ld	s9,8(sp)
    80003fa6:	6125                	addi	sp,sp,96
    80003fa8:	8082                	ret
      iunlock(ip);
    80003faa:	854e                	mv	a0,s3
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	aa6080e7          	jalr	-1370(ra) # 80003a52 <iunlock>
      return ip;
    80003fb4:	bfe9                	j	80003f8e <namex+0x6a>
      iunlockput(ip);
    80003fb6:	854e                	mv	a0,s3
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	c3a080e7          	jalr	-966(ra) # 80003bf2 <iunlockput>
      return 0;
    80003fc0:	89e6                	mv	s3,s9
    80003fc2:	b7f1                	j	80003f8e <namex+0x6a>
  len = path - s;
    80003fc4:	40b48633          	sub	a2,s1,a1
    80003fc8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003fcc:	099c5463          	bge	s8,s9,80004054 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fd0:	4639                	li	a2,14
    80003fd2:	8552                	mv	a0,s4
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	e68080e7          	jalr	-408(ra) # 80000e3c <memmove>
  while(*path == '/')
    80003fdc:	0004c783          	lbu	a5,0(s1)
    80003fe0:	01279763          	bne	a5,s2,80003fee <namex+0xca>
    path++;
    80003fe4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fe6:	0004c783          	lbu	a5,0(s1)
    80003fea:	ff278de3          	beq	a5,s2,80003fe4 <namex+0xc0>
    ilock(ip);
    80003fee:	854e                	mv	a0,s3
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	9a0080e7          	jalr	-1632(ra) # 80003990 <ilock>
    if(ip->type != T_DIR){
    80003ff8:	04499783          	lh	a5,68(s3)
    80003ffc:	f97793e3          	bne	a5,s7,80003f82 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004000:	000a8563          	beqz	s5,8000400a <namex+0xe6>
    80004004:	0004c783          	lbu	a5,0(s1)
    80004008:	d3cd                	beqz	a5,80003faa <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000400a:	865a                	mv	a2,s6
    8000400c:	85d2                	mv	a1,s4
    8000400e:	854e                	mv	a0,s3
    80004010:	00000097          	auipc	ra,0x0
    80004014:	e64080e7          	jalr	-412(ra) # 80003e74 <dirlookup>
    80004018:	8caa                	mv	s9,a0
    8000401a:	dd51                	beqz	a0,80003fb6 <namex+0x92>
    iunlockput(ip);
    8000401c:	854e                	mv	a0,s3
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	bd4080e7          	jalr	-1068(ra) # 80003bf2 <iunlockput>
    ip = next;
    80004026:	89e6                	mv	s3,s9
  while(*path == '/')
    80004028:	0004c783          	lbu	a5,0(s1)
    8000402c:	05279763          	bne	a5,s2,8000407a <namex+0x156>
    path++;
    80004030:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004032:	0004c783          	lbu	a5,0(s1)
    80004036:	ff278de3          	beq	a5,s2,80004030 <namex+0x10c>
  if(*path == 0)
    8000403a:	c79d                	beqz	a5,80004068 <namex+0x144>
    path++;
    8000403c:	85a6                	mv	a1,s1
  len = path - s;
    8000403e:	8cda                	mv	s9,s6
    80004040:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004042:	01278963          	beq	a5,s2,80004054 <namex+0x130>
    80004046:	dfbd                	beqz	a5,80003fc4 <namex+0xa0>
    path++;
    80004048:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000404a:	0004c783          	lbu	a5,0(s1)
    8000404e:	ff279ce3          	bne	a5,s2,80004046 <namex+0x122>
    80004052:	bf8d                	j	80003fc4 <namex+0xa0>
    memmove(name, s, len);
    80004054:	2601                	sext.w	a2,a2
    80004056:	8552                	mv	a0,s4
    80004058:	ffffd097          	auipc	ra,0xffffd
    8000405c:	de4080e7          	jalr	-540(ra) # 80000e3c <memmove>
    name[len] = 0;
    80004060:	9cd2                	add	s9,s9,s4
    80004062:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004066:	bf9d                	j	80003fdc <namex+0xb8>
  if(nameiparent){
    80004068:	f20a83e3          	beqz	s5,80003f8e <namex+0x6a>
    iput(ip);
    8000406c:	854e                	mv	a0,s3
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	adc080e7          	jalr	-1316(ra) # 80003b4a <iput>
    return 0;
    80004076:	4981                	li	s3,0
    80004078:	bf19                	j	80003f8e <namex+0x6a>
  if(*path == 0)
    8000407a:	d7fd                	beqz	a5,80004068 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000407c:	0004c783          	lbu	a5,0(s1)
    80004080:	85a6                	mv	a1,s1
    80004082:	b7d1                	j	80004046 <namex+0x122>

0000000080004084 <dirlink>:
{
    80004084:	7139                	addi	sp,sp,-64
    80004086:	fc06                	sd	ra,56(sp)
    80004088:	f822                	sd	s0,48(sp)
    8000408a:	f426                	sd	s1,40(sp)
    8000408c:	f04a                	sd	s2,32(sp)
    8000408e:	ec4e                	sd	s3,24(sp)
    80004090:	e852                	sd	s4,16(sp)
    80004092:	0080                	addi	s0,sp,64
    80004094:	892a                	mv	s2,a0
    80004096:	8a2e                	mv	s4,a1
    80004098:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000409a:	4601                	li	a2,0
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	dd8080e7          	jalr	-552(ra) # 80003e74 <dirlookup>
    800040a4:	e93d                	bnez	a0,8000411a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a6:	04c92483          	lw	s1,76(s2)
    800040aa:	c49d                	beqz	s1,800040d8 <dirlink+0x54>
    800040ac:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ae:	4741                	li	a4,16
    800040b0:	86a6                	mv	a3,s1
    800040b2:	fc040613          	addi	a2,s0,-64
    800040b6:	4581                	li	a1,0
    800040b8:	854a                	mv	a0,s2
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	b8a080e7          	jalr	-1142(ra) # 80003c44 <readi>
    800040c2:	47c1                	li	a5,16
    800040c4:	06f51163          	bne	a0,a5,80004126 <dirlink+0xa2>
    if(de.inum == 0)
    800040c8:	fc045783          	lhu	a5,-64(s0)
    800040cc:	c791                	beqz	a5,800040d8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ce:	24c1                	addiw	s1,s1,16
    800040d0:	04c92783          	lw	a5,76(s2)
    800040d4:	fcf4ede3          	bltu	s1,a5,800040ae <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040d8:	4639                	li	a2,14
    800040da:	85d2                	mv	a1,s4
    800040dc:	fc240513          	addi	a0,s0,-62
    800040e0:	ffffd097          	auipc	ra,0xffffd
    800040e4:	e0c080e7          	jalr	-500(ra) # 80000eec <strncpy>
  de.inum = inum;
    800040e8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ec:	4741                	li	a4,16
    800040ee:	86a6                	mv	a3,s1
    800040f0:	fc040613          	addi	a2,s0,-64
    800040f4:	4581                	li	a1,0
    800040f6:	854a                	mv	a0,s2
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	c44080e7          	jalr	-956(ra) # 80003d3c <writei>
    80004100:	1541                	addi	a0,a0,-16
    80004102:	00a03533          	snez	a0,a0
    80004106:	40a00533          	neg	a0,a0
}
    8000410a:	70e2                	ld	ra,56(sp)
    8000410c:	7442                	ld	s0,48(sp)
    8000410e:	74a2                	ld	s1,40(sp)
    80004110:	7902                	ld	s2,32(sp)
    80004112:	69e2                	ld	s3,24(sp)
    80004114:	6a42                	ld	s4,16(sp)
    80004116:	6121                	addi	sp,sp,64
    80004118:	8082                	ret
    iput(ip);
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	a30080e7          	jalr	-1488(ra) # 80003b4a <iput>
    return -1;
    80004122:	557d                	li	a0,-1
    80004124:	b7dd                	j	8000410a <dirlink+0x86>
      panic("dirlink read");
    80004126:	00004517          	auipc	a0,0x4
    8000412a:	5da50513          	addi	a0,a0,1498 # 80008700 <syscalls+0x1d8>
    8000412e:	ffffc097          	auipc	ra,0xffffc
    80004132:	51e080e7          	jalr	1310(ra) # 8000064c <panic>

0000000080004136 <namei>:

struct inode*
namei(char *path)
{
    80004136:	1101                	addi	sp,sp,-32
    80004138:	ec06                	sd	ra,24(sp)
    8000413a:	e822                	sd	s0,16(sp)
    8000413c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000413e:	fe040613          	addi	a2,s0,-32
    80004142:	4581                	li	a1,0
    80004144:	00000097          	auipc	ra,0x0
    80004148:	de0080e7          	jalr	-544(ra) # 80003f24 <namex>
}
    8000414c:	60e2                	ld	ra,24(sp)
    8000414e:	6442                	ld	s0,16(sp)
    80004150:	6105                	addi	sp,sp,32
    80004152:	8082                	ret

0000000080004154 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004154:	1141                	addi	sp,sp,-16
    80004156:	e406                	sd	ra,8(sp)
    80004158:	e022                	sd	s0,0(sp)
    8000415a:	0800                	addi	s0,sp,16
    8000415c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000415e:	4585                	li	a1,1
    80004160:	00000097          	auipc	ra,0x0
    80004164:	dc4080e7          	jalr	-572(ra) # 80003f24 <namex>
}
    80004168:	60a2                	ld	ra,8(sp)
    8000416a:	6402                	ld	s0,0(sp)
    8000416c:	0141                	addi	sp,sp,16
    8000416e:	8082                	ret

0000000080004170 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004170:	1101                	addi	sp,sp,-32
    80004172:	ec06                	sd	ra,24(sp)
    80004174:	e822                	sd	s0,16(sp)
    80004176:	e426                	sd	s1,8(sp)
    80004178:	e04a                	sd	s2,0(sp)
    8000417a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000417c:	0001e917          	auipc	s2,0x1e
    80004180:	a7c90913          	addi	s2,s2,-1412 # 80021bf8 <log>
    80004184:	01892583          	lw	a1,24(s2)
    80004188:	02892503          	lw	a0,40(s2)
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	fea080e7          	jalr	-22(ra) # 80003176 <bread>
    80004194:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004196:	02c92683          	lw	a3,44(s2)
    8000419a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000419c:	02d05763          	blez	a3,800041ca <write_head+0x5a>
    800041a0:	0001e797          	auipc	a5,0x1e
    800041a4:	a8878793          	addi	a5,a5,-1400 # 80021c28 <log+0x30>
    800041a8:	05c50713          	addi	a4,a0,92
    800041ac:	36fd                	addiw	a3,a3,-1
    800041ae:	1682                	slli	a3,a3,0x20
    800041b0:	9281                	srli	a3,a3,0x20
    800041b2:	068a                	slli	a3,a3,0x2
    800041b4:	0001e617          	auipc	a2,0x1e
    800041b8:	a7860613          	addi	a2,a2,-1416 # 80021c2c <log+0x34>
    800041bc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041be:	4390                	lw	a2,0(a5)
    800041c0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041c2:	0791                	addi	a5,a5,4
    800041c4:	0711                	addi	a4,a4,4
    800041c6:	fed79ce3          	bne	a5,a3,800041be <write_head+0x4e>
  }
  bwrite(buf);
    800041ca:	8526                	mv	a0,s1
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	09c080e7          	jalr	156(ra) # 80003268 <bwrite>
  brelse(buf);
    800041d4:	8526                	mv	a0,s1
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	0d0080e7          	jalr	208(ra) # 800032a6 <brelse>
}
    800041de:	60e2                	ld	ra,24(sp)
    800041e0:	6442                	ld	s0,16(sp)
    800041e2:	64a2                	ld	s1,8(sp)
    800041e4:	6902                	ld	s2,0(sp)
    800041e6:	6105                	addi	sp,sp,32
    800041e8:	8082                	ret

00000000800041ea <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ea:	0001e797          	auipc	a5,0x1e
    800041ee:	a3a7a783          	lw	a5,-1478(a5) # 80021c24 <log+0x2c>
    800041f2:	0af05d63          	blez	a5,800042ac <install_trans+0xc2>
{
    800041f6:	7139                	addi	sp,sp,-64
    800041f8:	fc06                	sd	ra,56(sp)
    800041fa:	f822                	sd	s0,48(sp)
    800041fc:	f426                	sd	s1,40(sp)
    800041fe:	f04a                	sd	s2,32(sp)
    80004200:	ec4e                	sd	s3,24(sp)
    80004202:	e852                	sd	s4,16(sp)
    80004204:	e456                	sd	s5,8(sp)
    80004206:	e05a                	sd	s6,0(sp)
    80004208:	0080                	addi	s0,sp,64
    8000420a:	8b2a                	mv	s6,a0
    8000420c:	0001ea97          	auipc	s5,0x1e
    80004210:	a1ca8a93          	addi	s5,s5,-1508 # 80021c28 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004214:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004216:	0001e997          	auipc	s3,0x1e
    8000421a:	9e298993          	addi	s3,s3,-1566 # 80021bf8 <log>
    8000421e:	a00d                	j	80004240 <install_trans+0x56>
    brelse(lbuf);
    80004220:	854a                	mv	a0,s2
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	084080e7          	jalr	132(ra) # 800032a6 <brelse>
    brelse(dbuf);
    8000422a:	8526                	mv	a0,s1
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	07a080e7          	jalr	122(ra) # 800032a6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004234:	2a05                	addiw	s4,s4,1
    80004236:	0a91                	addi	s5,s5,4
    80004238:	02c9a783          	lw	a5,44(s3)
    8000423c:	04fa5e63          	bge	s4,a5,80004298 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004240:	0189a583          	lw	a1,24(s3)
    80004244:	014585bb          	addw	a1,a1,s4
    80004248:	2585                	addiw	a1,a1,1
    8000424a:	0289a503          	lw	a0,40(s3)
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	f28080e7          	jalr	-216(ra) # 80003176 <bread>
    80004256:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004258:	000aa583          	lw	a1,0(s5)
    8000425c:	0289a503          	lw	a0,40(s3)
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	f16080e7          	jalr	-234(ra) # 80003176 <bread>
    80004268:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000426a:	40000613          	li	a2,1024
    8000426e:	05890593          	addi	a1,s2,88
    80004272:	05850513          	addi	a0,a0,88
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	bc6080e7          	jalr	-1082(ra) # 80000e3c <memmove>
    bwrite(dbuf);  // write dst to disk
    8000427e:	8526                	mv	a0,s1
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	fe8080e7          	jalr	-24(ra) # 80003268 <bwrite>
    if(recovering == 0)
    80004288:	f80b1ce3          	bnez	s6,80004220 <install_trans+0x36>
      bunpin(dbuf);
    8000428c:	8526                	mv	a0,s1
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	0f2080e7          	jalr	242(ra) # 80003380 <bunpin>
    80004296:	b769                	j	80004220 <install_trans+0x36>
}
    80004298:	70e2                	ld	ra,56(sp)
    8000429a:	7442                	ld	s0,48(sp)
    8000429c:	74a2                	ld	s1,40(sp)
    8000429e:	7902                	ld	s2,32(sp)
    800042a0:	69e2                	ld	s3,24(sp)
    800042a2:	6a42                	ld	s4,16(sp)
    800042a4:	6aa2                	ld	s5,8(sp)
    800042a6:	6b02                	ld	s6,0(sp)
    800042a8:	6121                	addi	sp,sp,64
    800042aa:	8082                	ret
    800042ac:	8082                	ret

00000000800042ae <initlog>:
{
    800042ae:	7179                	addi	sp,sp,-48
    800042b0:	f406                	sd	ra,40(sp)
    800042b2:	f022                	sd	s0,32(sp)
    800042b4:	ec26                	sd	s1,24(sp)
    800042b6:	e84a                	sd	s2,16(sp)
    800042b8:	e44e                	sd	s3,8(sp)
    800042ba:	1800                	addi	s0,sp,48
    800042bc:	892a                	mv	s2,a0
    800042be:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042c0:	0001e497          	auipc	s1,0x1e
    800042c4:	93848493          	addi	s1,s1,-1736 # 80021bf8 <log>
    800042c8:	00004597          	auipc	a1,0x4
    800042cc:	44858593          	addi	a1,a1,1096 # 80008710 <syscalls+0x1e8>
    800042d0:	8526                	mv	a0,s1
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	982080e7          	jalr	-1662(ra) # 80000c54 <initlock>
  log.start = sb->logstart;
    800042da:	0149a583          	lw	a1,20(s3)
    800042de:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042e0:	0109a783          	lw	a5,16(s3)
    800042e4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042e6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042ea:	854a                	mv	a0,s2
    800042ec:	fffff097          	auipc	ra,0xfffff
    800042f0:	e8a080e7          	jalr	-374(ra) # 80003176 <bread>
  log.lh.n = lh->n;
    800042f4:	4d34                	lw	a3,88(a0)
    800042f6:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042f8:	02d05563          	blez	a3,80004322 <initlog+0x74>
    800042fc:	05c50793          	addi	a5,a0,92
    80004300:	0001e717          	auipc	a4,0x1e
    80004304:	92870713          	addi	a4,a4,-1752 # 80021c28 <log+0x30>
    80004308:	36fd                	addiw	a3,a3,-1
    8000430a:	1682                	slli	a3,a3,0x20
    8000430c:	9281                	srli	a3,a3,0x20
    8000430e:	068a                	slli	a3,a3,0x2
    80004310:	06050613          	addi	a2,a0,96
    80004314:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004316:	4390                	lw	a2,0(a5)
    80004318:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000431a:	0791                	addi	a5,a5,4
    8000431c:	0711                	addi	a4,a4,4
    8000431e:	fed79ce3          	bne	a5,a3,80004316 <initlog+0x68>
  brelse(buf);
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	f84080e7          	jalr	-124(ra) # 800032a6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000432a:	4505                	li	a0,1
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	ebe080e7          	jalr	-322(ra) # 800041ea <install_trans>
  log.lh.n = 0;
    80004334:	0001e797          	auipc	a5,0x1e
    80004338:	8e07a823          	sw	zero,-1808(a5) # 80021c24 <log+0x2c>
  write_head(); // clear the log
    8000433c:	00000097          	auipc	ra,0x0
    80004340:	e34080e7          	jalr	-460(ra) # 80004170 <write_head>
}
    80004344:	70a2                	ld	ra,40(sp)
    80004346:	7402                	ld	s0,32(sp)
    80004348:	64e2                	ld	s1,24(sp)
    8000434a:	6942                	ld	s2,16(sp)
    8000434c:	69a2                	ld	s3,8(sp)
    8000434e:	6145                	addi	sp,sp,48
    80004350:	8082                	ret

0000000080004352 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004352:	1101                	addi	sp,sp,-32
    80004354:	ec06                	sd	ra,24(sp)
    80004356:	e822                	sd	s0,16(sp)
    80004358:	e426                	sd	s1,8(sp)
    8000435a:	e04a                	sd	s2,0(sp)
    8000435c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000435e:	0001e517          	auipc	a0,0x1e
    80004362:	89a50513          	addi	a0,a0,-1894 # 80021bf8 <log>
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	97e080e7          	jalr	-1666(ra) # 80000ce4 <acquire>
  while(1){
    if(log.committing){
    8000436e:	0001e497          	auipc	s1,0x1e
    80004372:	88a48493          	addi	s1,s1,-1910 # 80021bf8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004376:	4979                	li	s2,30
    80004378:	a039                	j	80004386 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000437a:	85a6                	mv	a1,s1
    8000437c:	8526                	mv	a0,s1
    8000437e:	ffffe097          	auipc	ra,0xffffe
    80004382:	de4080e7          	jalr	-540(ra) # 80002162 <sleep>
    if(log.committing){
    80004386:	50dc                	lw	a5,36(s1)
    80004388:	fbed                	bnez	a5,8000437a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000438a:	509c                	lw	a5,32(s1)
    8000438c:	0017871b          	addiw	a4,a5,1
    80004390:	0007069b          	sext.w	a3,a4
    80004394:	0027179b          	slliw	a5,a4,0x2
    80004398:	9fb9                	addw	a5,a5,a4
    8000439a:	0017979b          	slliw	a5,a5,0x1
    8000439e:	54d8                	lw	a4,44(s1)
    800043a0:	9fb9                	addw	a5,a5,a4
    800043a2:	00f95963          	bge	s2,a5,800043b4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043a6:	85a6                	mv	a1,s1
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffe097          	auipc	ra,0xffffe
    800043ae:	db8080e7          	jalr	-584(ra) # 80002162 <sleep>
    800043b2:	bfd1                	j	80004386 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043b4:	0001e517          	auipc	a0,0x1e
    800043b8:	84450513          	addi	a0,a0,-1980 # 80021bf8 <log>
    800043bc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	9da080e7          	jalr	-1574(ra) # 80000d98 <release>
      break;
    }
  }
}
    800043c6:	60e2                	ld	ra,24(sp)
    800043c8:	6442                	ld	s0,16(sp)
    800043ca:	64a2                	ld	s1,8(sp)
    800043cc:	6902                	ld	s2,0(sp)
    800043ce:	6105                	addi	sp,sp,32
    800043d0:	8082                	ret

00000000800043d2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043d2:	7139                	addi	sp,sp,-64
    800043d4:	fc06                	sd	ra,56(sp)
    800043d6:	f822                	sd	s0,48(sp)
    800043d8:	f426                	sd	s1,40(sp)
    800043da:	f04a                	sd	s2,32(sp)
    800043dc:	ec4e                	sd	s3,24(sp)
    800043de:	e852                	sd	s4,16(sp)
    800043e0:	e456                	sd	s5,8(sp)
    800043e2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043e4:	0001e497          	auipc	s1,0x1e
    800043e8:	81448493          	addi	s1,s1,-2028 # 80021bf8 <log>
    800043ec:	8526                	mv	a0,s1
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	8f6080e7          	jalr	-1802(ra) # 80000ce4 <acquire>
  log.outstanding -= 1;
    800043f6:	509c                	lw	a5,32(s1)
    800043f8:	37fd                	addiw	a5,a5,-1
    800043fa:	0007891b          	sext.w	s2,a5
    800043fe:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004400:	50dc                	lw	a5,36(s1)
    80004402:	e7b9                	bnez	a5,80004450 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004404:	04091e63          	bnez	s2,80004460 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004408:	0001d497          	auipc	s1,0x1d
    8000440c:	7f048493          	addi	s1,s1,2032 # 80021bf8 <log>
    80004410:	4785                	li	a5,1
    80004412:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004414:	8526                	mv	a0,s1
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	982080e7          	jalr	-1662(ra) # 80000d98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000441e:	54dc                	lw	a5,44(s1)
    80004420:	06f04763          	bgtz	a5,8000448e <end_op+0xbc>
    acquire(&log.lock);
    80004424:	0001d497          	auipc	s1,0x1d
    80004428:	7d448493          	addi	s1,s1,2004 # 80021bf8 <log>
    8000442c:	8526                	mv	a0,s1
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	8b6080e7          	jalr	-1866(ra) # 80000ce4 <acquire>
    log.committing = 0;
    80004436:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000443a:	8526                	mv	a0,s1
    8000443c:	ffffe097          	auipc	ra,0xffffe
    80004440:	d8a080e7          	jalr	-630(ra) # 800021c6 <wakeup>
    release(&log.lock);
    80004444:	8526                	mv	a0,s1
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	952080e7          	jalr	-1710(ra) # 80000d98 <release>
}
    8000444e:	a03d                	j	8000447c <end_op+0xaa>
    panic("log.committing");
    80004450:	00004517          	auipc	a0,0x4
    80004454:	2c850513          	addi	a0,a0,712 # 80008718 <syscalls+0x1f0>
    80004458:	ffffc097          	auipc	ra,0xffffc
    8000445c:	1f4080e7          	jalr	500(ra) # 8000064c <panic>
    wakeup(&log);
    80004460:	0001d497          	auipc	s1,0x1d
    80004464:	79848493          	addi	s1,s1,1944 # 80021bf8 <log>
    80004468:	8526                	mv	a0,s1
    8000446a:	ffffe097          	auipc	ra,0xffffe
    8000446e:	d5c080e7          	jalr	-676(ra) # 800021c6 <wakeup>
  release(&log.lock);
    80004472:	8526                	mv	a0,s1
    80004474:	ffffd097          	auipc	ra,0xffffd
    80004478:	924080e7          	jalr	-1756(ra) # 80000d98 <release>
}
    8000447c:	70e2                	ld	ra,56(sp)
    8000447e:	7442                	ld	s0,48(sp)
    80004480:	74a2                	ld	s1,40(sp)
    80004482:	7902                	ld	s2,32(sp)
    80004484:	69e2                	ld	s3,24(sp)
    80004486:	6a42                	ld	s4,16(sp)
    80004488:	6aa2                	ld	s5,8(sp)
    8000448a:	6121                	addi	sp,sp,64
    8000448c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000448e:	0001da97          	auipc	s5,0x1d
    80004492:	79aa8a93          	addi	s5,s5,1946 # 80021c28 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004496:	0001da17          	auipc	s4,0x1d
    8000449a:	762a0a13          	addi	s4,s4,1890 # 80021bf8 <log>
    8000449e:	018a2583          	lw	a1,24(s4)
    800044a2:	012585bb          	addw	a1,a1,s2
    800044a6:	2585                	addiw	a1,a1,1
    800044a8:	028a2503          	lw	a0,40(s4)
    800044ac:	fffff097          	auipc	ra,0xfffff
    800044b0:	cca080e7          	jalr	-822(ra) # 80003176 <bread>
    800044b4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044b6:	000aa583          	lw	a1,0(s5)
    800044ba:	028a2503          	lw	a0,40(s4)
    800044be:	fffff097          	auipc	ra,0xfffff
    800044c2:	cb8080e7          	jalr	-840(ra) # 80003176 <bread>
    800044c6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044c8:	40000613          	li	a2,1024
    800044cc:	05850593          	addi	a1,a0,88
    800044d0:	05848513          	addi	a0,s1,88
    800044d4:	ffffd097          	auipc	ra,0xffffd
    800044d8:	968080e7          	jalr	-1688(ra) # 80000e3c <memmove>
    bwrite(to);  // write the log
    800044dc:	8526                	mv	a0,s1
    800044de:	fffff097          	auipc	ra,0xfffff
    800044e2:	d8a080e7          	jalr	-630(ra) # 80003268 <bwrite>
    brelse(from);
    800044e6:	854e                	mv	a0,s3
    800044e8:	fffff097          	auipc	ra,0xfffff
    800044ec:	dbe080e7          	jalr	-578(ra) # 800032a6 <brelse>
    brelse(to);
    800044f0:	8526                	mv	a0,s1
    800044f2:	fffff097          	auipc	ra,0xfffff
    800044f6:	db4080e7          	jalr	-588(ra) # 800032a6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044fa:	2905                	addiw	s2,s2,1
    800044fc:	0a91                	addi	s5,s5,4
    800044fe:	02ca2783          	lw	a5,44(s4)
    80004502:	f8f94ee3          	blt	s2,a5,8000449e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004506:	00000097          	auipc	ra,0x0
    8000450a:	c6a080e7          	jalr	-918(ra) # 80004170 <write_head>
    install_trans(0); // Now install writes to home locations
    8000450e:	4501                	li	a0,0
    80004510:	00000097          	auipc	ra,0x0
    80004514:	cda080e7          	jalr	-806(ra) # 800041ea <install_trans>
    log.lh.n = 0;
    80004518:	0001d797          	auipc	a5,0x1d
    8000451c:	7007a623          	sw	zero,1804(a5) # 80021c24 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004520:	00000097          	auipc	ra,0x0
    80004524:	c50080e7          	jalr	-944(ra) # 80004170 <write_head>
    80004528:	bdf5                	j	80004424 <end_op+0x52>

000000008000452a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000452a:	1101                	addi	sp,sp,-32
    8000452c:	ec06                	sd	ra,24(sp)
    8000452e:	e822                	sd	s0,16(sp)
    80004530:	e426                	sd	s1,8(sp)
    80004532:	e04a                	sd	s2,0(sp)
    80004534:	1000                	addi	s0,sp,32
    80004536:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004538:	0001d917          	auipc	s2,0x1d
    8000453c:	6c090913          	addi	s2,s2,1728 # 80021bf8 <log>
    80004540:	854a                	mv	a0,s2
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	7a2080e7          	jalr	1954(ra) # 80000ce4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000454a:	02c92603          	lw	a2,44(s2)
    8000454e:	47f5                	li	a5,29
    80004550:	06c7c563          	blt	a5,a2,800045ba <log_write+0x90>
    80004554:	0001d797          	auipc	a5,0x1d
    80004558:	6c07a783          	lw	a5,1728(a5) # 80021c14 <log+0x1c>
    8000455c:	37fd                	addiw	a5,a5,-1
    8000455e:	04f65e63          	bge	a2,a5,800045ba <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004562:	0001d797          	auipc	a5,0x1d
    80004566:	6b67a783          	lw	a5,1718(a5) # 80021c18 <log+0x20>
    8000456a:	06f05063          	blez	a5,800045ca <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000456e:	4781                	li	a5,0
    80004570:	06c05563          	blez	a2,800045da <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004574:	44cc                	lw	a1,12(s1)
    80004576:	0001d717          	auipc	a4,0x1d
    8000457a:	6b270713          	addi	a4,a4,1714 # 80021c28 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000457e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004580:	4314                	lw	a3,0(a4)
    80004582:	04b68c63          	beq	a3,a1,800045da <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004586:	2785                	addiw	a5,a5,1
    80004588:	0711                	addi	a4,a4,4
    8000458a:	fef61be3          	bne	a2,a5,80004580 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000458e:	0621                	addi	a2,a2,8
    80004590:	060a                	slli	a2,a2,0x2
    80004592:	0001d797          	auipc	a5,0x1d
    80004596:	66678793          	addi	a5,a5,1638 # 80021bf8 <log>
    8000459a:	963e                	add	a2,a2,a5
    8000459c:	44dc                	lw	a5,12(s1)
    8000459e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045a0:	8526                	mv	a0,s1
    800045a2:	fffff097          	auipc	ra,0xfffff
    800045a6:	da2080e7          	jalr	-606(ra) # 80003344 <bpin>
    log.lh.n++;
    800045aa:	0001d717          	auipc	a4,0x1d
    800045ae:	64e70713          	addi	a4,a4,1614 # 80021bf8 <log>
    800045b2:	575c                	lw	a5,44(a4)
    800045b4:	2785                	addiw	a5,a5,1
    800045b6:	d75c                	sw	a5,44(a4)
    800045b8:	a835                	j	800045f4 <log_write+0xca>
    panic("too big a transaction");
    800045ba:	00004517          	auipc	a0,0x4
    800045be:	16e50513          	addi	a0,a0,366 # 80008728 <syscalls+0x200>
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	08a080e7          	jalr	138(ra) # 8000064c <panic>
    panic("log_write outside of trans");
    800045ca:	00004517          	auipc	a0,0x4
    800045ce:	17650513          	addi	a0,a0,374 # 80008740 <syscalls+0x218>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	07a080e7          	jalr	122(ra) # 8000064c <panic>
  log.lh.block[i] = b->blockno;
    800045da:	00878713          	addi	a4,a5,8
    800045de:	00271693          	slli	a3,a4,0x2
    800045e2:	0001d717          	auipc	a4,0x1d
    800045e6:	61670713          	addi	a4,a4,1558 # 80021bf8 <log>
    800045ea:	9736                	add	a4,a4,a3
    800045ec:	44d4                	lw	a3,12(s1)
    800045ee:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045f0:	faf608e3          	beq	a2,a5,800045a0 <log_write+0x76>
  }
  release(&log.lock);
    800045f4:	0001d517          	auipc	a0,0x1d
    800045f8:	60450513          	addi	a0,a0,1540 # 80021bf8 <log>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	79c080e7          	jalr	1948(ra) # 80000d98 <release>
}
    80004604:	60e2                	ld	ra,24(sp)
    80004606:	6442                	ld	s0,16(sp)
    80004608:	64a2                	ld	s1,8(sp)
    8000460a:	6902                	ld	s2,0(sp)
    8000460c:	6105                	addi	sp,sp,32
    8000460e:	8082                	ret

0000000080004610 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004610:	1101                	addi	sp,sp,-32
    80004612:	ec06                	sd	ra,24(sp)
    80004614:	e822                	sd	s0,16(sp)
    80004616:	e426                	sd	s1,8(sp)
    80004618:	e04a                	sd	s2,0(sp)
    8000461a:	1000                	addi	s0,sp,32
    8000461c:	84aa                	mv	s1,a0
    8000461e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004620:	00004597          	auipc	a1,0x4
    80004624:	14058593          	addi	a1,a1,320 # 80008760 <syscalls+0x238>
    80004628:	0521                	addi	a0,a0,8
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	62a080e7          	jalr	1578(ra) # 80000c54 <initlock>
  lk->name = name;
    80004632:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004636:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000463a:	0204a423          	sw	zero,40(s1)
}
    8000463e:	60e2                	ld	ra,24(sp)
    80004640:	6442                	ld	s0,16(sp)
    80004642:	64a2                	ld	s1,8(sp)
    80004644:	6902                	ld	s2,0(sp)
    80004646:	6105                	addi	sp,sp,32
    80004648:	8082                	ret

000000008000464a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000464a:	1101                	addi	sp,sp,-32
    8000464c:	ec06                	sd	ra,24(sp)
    8000464e:	e822                	sd	s0,16(sp)
    80004650:	e426                	sd	s1,8(sp)
    80004652:	e04a                	sd	s2,0(sp)
    80004654:	1000                	addi	s0,sp,32
    80004656:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004658:	00850913          	addi	s2,a0,8
    8000465c:	854a                	mv	a0,s2
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	686080e7          	jalr	1670(ra) # 80000ce4 <acquire>
  while (lk->locked) {
    80004666:	409c                	lw	a5,0(s1)
    80004668:	cb89                	beqz	a5,8000467a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000466a:	85ca                	mv	a1,s2
    8000466c:	8526                	mv	a0,s1
    8000466e:	ffffe097          	auipc	ra,0xffffe
    80004672:	af4080e7          	jalr	-1292(ra) # 80002162 <sleep>
  while (lk->locked) {
    80004676:	409c                	lw	a5,0(s1)
    80004678:	fbed                	bnez	a5,8000466a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000467a:	4785                	li	a5,1
    8000467c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000467e:	ffffd097          	auipc	ra,0xffffd
    80004682:	43c080e7          	jalr	1084(ra) # 80001aba <myproc>
    80004686:	591c                	lw	a5,48(a0)
    80004688:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000468a:	854a                	mv	a0,s2
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	70c080e7          	jalr	1804(ra) # 80000d98 <release>
}
    80004694:	60e2                	ld	ra,24(sp)
    80004696:	6442                	ld	s0,16(sp)
    80004698:	64a2                	ld	s1,8(sp)
    8000469a:	6902                	ld	s2,0(sp)
    8000469c:	6105                	addi	sp,sp,32
    8000469e:	8082                	ret

00000000800046a0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046a0:	1101                	addi	sp,sp,-32
    800046a2:	ec06                	sd	ra,24(sp)
    800046a4:	e822                	sd	s0,16(sp)
    800046a6:	e426                	sd	s1,8(sp)
    800046a8:	e04a                	sd	s2,0(sp)
    800046aa:	1000                	addi	s0,sp,32
    800046ac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046ae:	00850913          	addi	s2,a0,8
    800046b2:	854a                	mv	a0,s2
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	630080e7          	jalr	1584(ra) # 80000ce4 <acquire>
  lk->locked = 0;
    800046bc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046c0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046c4:	8526                	mv	a0,s1
    800046c6:	ffffe097          	auipc	ra,0xffffe
    800046ca:	b00080e7          	jalr	-1280(ra) # 800021c6 <wakeup>
  release(&lk->lk);
    800046ce:	854a                	mv	a0,s2
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	6c8080e7          	jalr	1736(ra) # 80000d98 <release>
}
    800046d8:	60e2                	ld	ra,24(sp)
    800046da:	6442                	ld	s0,16(sp)
    800046dc:	64a2                	ld	s1,8(sp)
    800046de:	6902                	ld	s2,0(sp)
    800046e0:	6105                	addi	sp,sp,32
    800046e2:	8082                	ret

00000000800046e4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046e4:	7179                	addi	sp,sp,-48
    800046e6:	f406                	sd	ra,40(sp)
    800046e8:	f022                	sd	s0,32(sp)
    800046ea:	ec26                	sd	s1,24(sp)
    800046ec:	e84a                	sd	s2,16(sp)
    800046ee:	e44e                	sd	s3,8(sp)
    800046f0:	1800                	addi	s0,sp,48
    800046f2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046f4:	00850913          	addi	s2,a0,8
    800046f8:	854a                	mv	a0,s2
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	5ea080e7          	jalr	1514(ra) # 80000ce4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004702:	409c                	lw	a5,0(s1)
    80004704:	ef99                	bnez	a5,80004722 <holdingsleep+0x3e>
    80004706:	4481                	li	s1,0
  release(&lk->lk);
    80004708:	854a                	mv	a0,s2
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	68e080e7          	jalr	1678(ra) # 80000d98 <release>
  return r;
}
    80004712:	8526                	mv	a0,s1
    80004714:	70a2                	ld	ra,40(sp)
    80004716:	7402                	ld	s0,32(sp)
    80004718:	64e2                	ld	s1,24(sp)
    8000471a:	6942                	ld	s2,16(sp)
    8000471c:	69a2                	ld	s3,8(sp)
    8000471e:	6145                	addi	sp,sp,48
    80004720:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004722:	0284a983          	lw	s3,40(s1)
    80004726:	ffffd097          	auipc	ra,0xffffd
    8000472a:	394080e7          	jalr	916(ra) # 80001aba <myproc>
    8000472e:	5904                	lw	s1,48(a0)
    80004730:	413484b3          	sub	s1,s1,s3
    80004734:	0014b493          	seqz	s1,s1
    80004738:	bfc1                	j	80004708 <holdingsleep+0x24>

000000008000473a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000473a:	1141                	addi	sp,sp,-16
    8000473c:	e406                	sd	ra,8(sp)
    8000473e:	e022                	sd	s0,0(sp)
    80004740:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004742:	00004597          	auipc	a1,0x4
    80004746:	02e58593          	addi	a1,a1,46 # 80008770 <syscalls+0x248>
    8000474a:	0001d517          	auipc	a0,0x1d
    8000474e:	5f650513          	addi	a0,a0,1526 # 80021d40 <ftable>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	502080e7          	jalr	1282(ra) # 80000c54 <initlock>
}
    8000475a:	60a2                	ld	ra,8(sp)
    8000475c:	6402                	ld	s0,0(sp)
    8000475e:	0141                	addi	sp,sp,16
    80004760:	8082                	ret

0000000080004762 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004762:	1101                	addi	sp,sp,-32
    80004764:	ec06                	sd	ra,24(sp)
    80004766:	e822                	sd	s0,16(sp)
    80004768:	e426                	sd	s1,8(sp)
    8000476a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000476c:	0001d517          	auipc	a0,0x1d
    80004770:	5d450513          	addi	a0,a0,1492 # 80021d40 <ftable>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	570080e7          	jalr	1392(ra) # 80000ce4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000477c:	0001d497          	auipc	s1,0x1d
    80004780:	5dc48493          	addi	s1,s1,1500 # 80021d58 <ftable+0x18>
    80004784:	0001e717          	auipc	a4,0x1e
    80004788:	57470713          	addi	a4,a4,1396 # 80022cf8 <disk>
    if(f->ref == 0){
    8000478c:	40dc                	lw	a5,4(s1)
    8000478e:	cf99                	beqz	a5,800047ac <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004790:	02848493          	addi	s1,s1,40
    80004794:	fee49ce3          	bne	s1,a4,8000478c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004798:	0001d517          	auipc	a0,0x1d
    8000479c:	5a850513          	addi	a0,a0,1448 # 80021d40 <ftable>
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	5f8080e7          	jalr	1528(ra) # 80000d98 <release>
  return 0;
    800047a8:	4481                	li	s1,0
    800047aa:	a819                	j	800047c0 <filealloc+0x5e>
      f->ref = 1;
    800047ac:	4785                	li	a5,1
    800047ae:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047b0:	0001d517          	auipc	a0,0x1d
    800047b4:	59050513          	addi	a0,a0,1424 # 80021d40 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	5e0080e7          	jalr	1504(ra) # 80000d98 <release>
}
    800047c0:	8526                	mv	a0,s1
    800047c2:	60e2                	ld	ra,24(sp)
    800047c4:	6442                	ld	s0,16(sp)
    800047c6:	64a2                	ld	s1,8(sp)
    800047c8:	6105                	addi	sp,sp,32
    800047ca:	8082                	ret

00000000800047cc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047cc:	1101                	addi	sp,sp,-32
    800047ce:	ec06                	sd	ra,24(sp)
    800047d0:	e822                	sd	s0,16(sp)
    800047d2:	e426                	sd	s1,8(sp)
    800047d4:	1000                	addi	s0,sp,32
    800047d6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047d8:	0001d517          	auipc	a0,0x1d
    800047dc:	56850513          	addi	a0,a0,1384 # 80021d40 <ftable>
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	504080e7          	jalr	1284(ra) # 80000ce4 <acquire>
  if(f->ref < 1)
    800047e8:	40dc                	lw	a5,4(s1)
    800047ea:	02f05263          	blez	a5,8000480e <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047ee:	2785                	addiw	a5,a5,1
    800047f0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047f2:	0001d517          	auipc	a0,0x1d
    800047f6:	54e50513          	addi	a0,a0,1358 # 80021d40 <ftable>
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	59e080e7          	jalr	1438(ra) # 80000d98 <release>
  return f;
}
    80004802:	8526                	mv	a0,s1
    80004804:	60e2                	ld	ra,24(sp)
    80004806:	6442                	ld	s0,16(sp)
    80004808:	64a2                	ld	s1,8(sp)
    8000480a:	6105                	addi	sp,sp,32
    8000480c:	8082                	ret
    panic("filedup");
    8000480e:	00004517          	auipc	a0,0x4
    80004812:	f6a50513          	addi	a0,a0,-150 # 80008778 <syscalls+0x250>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	e36080e7          	jalr	-458(ra) # 8000064c <panic>

000000008000481e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000481e:	7139                	addi	sp,sp,-64
    80004820:	fc06                	sd	ra,56(sp)
    80004822:	f822                	sd	s0,48(sp)
    80004824:	f426                	sd	s1,40(sp)
    80004826:	f04a                	sd	s2,32(sp)
    80004828:	ec4e                	sd	s3,24(sp)
    8000482a:	e852                	sd	s4,16(sp)
    8000482c:	e456                	sd	s5,8(sp)
    8000482e:	0080                	addi	s0,sp,64
    80004830:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004832:	0001d517          	auipc	a0,0x1d
    80004836:	50e50513          	addi	a0,a0,1294 # 80021d40 <ftable>
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	4aa080e7          	jalr	1194(ra) # 80000ce4 <acquire>
  if(f->ref < 1)
    80004842:	40dc                	lw	a5,4(s1)
    80004844:	06f05163          	blez	a5,800048a6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004848:	37fd                	addiw	a5,a5,-1
    8000484a:	0007871b          	sext.w	a4,a5
    8000484e:	c0dc                	sw	a5,4(s1)
    80004850:	06e04363          	bgtz	a4,800048b6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004854:	0004a903          	lw	s2,0(s1)
    80004858:	0094ca83          	lbu	s5,9(s1)
    8000485c:	0104ba03          	ld	s4,16(s1)
    80004860:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004864:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004868:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000486c:	0001d517          	auipc	a0,0x1d
    80004870:	4d450513          	addi	a0,a0,1236 # 80021d40 <ftable>
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	524080e7          	jalr	1316(ra) # 80000d98 <release>

  if(ff.type == FD_PIPE){
    8000487c:	4785                	li	a5,1
    8000487e:	04f90d63          	beq	s2,a5,800048d8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004882:	3979                	addiw	s2,s2,-2
    80004884:	4785                	li	a5,1
    80004886:	0527e063          	bltu	a5,s2,800048c6 <fileclose+0xa8>
    begin_op();
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	ac8080e7          	jalr	-1336(ra) # 80004352 <begin_op>
    iput(ff.ip);
    80004892:	854e                	mv	a0,s3
    80004894:	fffff097          	auipc	ra,0xfffff
    80004898:	2b6080e7          	jalr	694(ra) # 80003b4a <iput>
    end_op();
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	b36080e7          	jalr	-1226(ra) # 800043d2 <end_op>
    800048a4:	a00d                	j	800048c6 <fileclose+0xa8>
    panic("fileclose");
    800048a6:	00004517          	auipc	a0,0x4
    800048aa:	eda50513          	addi	a0,a0,-294 # 80008780 <syscalls+0x258>
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	d9e080e7          	jalr	-610(ra) # 8000064c <panic>
    release(&ftable.lock);
    800048b6:	0001d517          	auipc	a0,0x1d
    800048ba:	48a50513          	addi	a0,a0,1162 # 80021d40 <ftable>
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	4da080e7          	jalr	1242(ra) # 80000d98 <release>
  }
}
    800048c6:	70e2                	ld	ra,56(sp)
    800048c8:	7442                	ld	s0,48(sp)
    800048ca:	74a2                	ld	s1,40(sp)
    800048cc:	7902                	ld	s2,32(sp)
    800048ce:	69e2                	ld	s3,24(sp)
    800048d0:	6a42                	ld	s4,16(sp)
    800048d2:	6aa2                	ld	s5,8(sp)
    800048d4:	6121                	addi	sp,sp,64
    800048d6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048d8:	85d6                	mv	a1,s5
    800048da:	8552                	mv	a0,s4
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	34c080e7          	jalr	844(ra) # 80004c28 <pipeclose>
    800048e4:	b7cd                	j	800048c6 <fileclose+0xa8>

00000000800048e6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048e6:	715d                	addi	sp,sp,-80
    800048e8:	e486                	sd	ra,72(sp)
    800048ea:	e0a2                	sd	s0,64(sp)
    800048ec:	fc26                	sd	s1,56(sp)
    800048ee:	f84a                	sd	s2,48(sp)
    800048f0:	f44e                	sd	s3,40(sp)
    800048f2:	0880                	addi	s0,sp,80
    800048f4:	84aa                	mv	s1,a0
    800048f6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048f8:	ffffd097          	auipc	ra,0xffffd
    800048fc:	1c2080e7          	jalr	450(ra) # 80001aba <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004900:	409c                	lw	a5,0(s1)
    80004902:	37f9                	addiw	a5,a5,-2
    80004904:	4705                	li	a4,1
    80004906:	04f76763          	bltu	a4,a5,80004954 <filestat+0x6e>
    8000490a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000490c:	6c88                	ld	a0,24(s1)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	082080e7          	jalr	130(ra) # 80003990 <ilock>
    stati(f->ip, &st);
    80004916:	fb840593          	addi	a1,s0,-72
    8000491a:	6c88                	ld	a0,24(s1)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	2fe080e7          	jalr	766(ra) # 80003c1a <stati>
    iunlock(f->ip);
    80004924:	6c88                	ld	a0,24(s1)
    80004926:	fffff097          	auipc	ra,0xfffff
    8000492a:	12c080e7          	jalr	300(ra) # 80003a52 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000492e:	46e1                	li	a3,24
    80004930:	fb840613          	addi	a2,s0,-72
    80004934:	85ce                	mv	a1,s3
    80004936:	05093503          	ld	a0,80(s2)
    8000493a:	ffffd097          	auipc	ra,0xffffd
    8000493e:	e3c080e7          	jalr	-452(ra) # 80001776 <copyout>
    80004942:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004946:	60a6                	ld	ra,72(sp)
    80004948:	6406                	ld	s0,64(sp)
    8000494a:	74e2                	ld	s1,56(sp)
    8000494c:	7942                	ld	s2,48(sp)
    8000494e:	79a2                	ld	s3,40(sp)
    80004950:	6161                	addi	sp,sp,80
    80004952:	8082                	ret
  return -1;
    80004954:	557d                	li	a0,-1
    80004956:	bfc5                	j	80004946 <filestat+0x60>

0000000080004958 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004958:	7179                	addi	sp,sp,-48
    8000495a:	f406                	sd	ra,40(sp)
    8000495c:	f022                	sd	s0,32(sp)
    8000495e:	ec26                	sd	s1,24(sp)
    80004960:	e84a                	sd	s2,16(sp)
    80004962:	e44e                	sd	s3,8(sp)
    80004964:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004966:	00854783          	lbu	a5,8(a0)
    8000496a:	c3d5                	beqz	a5,80004a0e <fileread+0xb6>
    8000496c:	84aa                	mv	s1,a0
    8000496e:	89ae                	mv	s3,a1
    80004970:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004972:	411c                	lw	a5,0(a0)
    80004974:	4705                	li	a4,1
    80004976:	04e78963          	beq	a5,a4,800049c8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000497a:	470d                	li	a4,3
    8000497c:	04e78d63          	beq	a5,a4,800049d6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004980:	4709                	li	a4,2
    80004982:	06e79e63          	bne	a5,a4,800049fe <fileread+0xa6>
    ilock(f->ip);
    80004986:	6d08                	ld	a0,24(a0)
    80004988:	fffff097          	auipc	ra,0xfffff
    8000498c:	008080e7          	jalr	8(ra) # 80003990 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004990:	874a                	mv	a4,s2
    80004992:	5094                	lw	a3,32(s1)
    80004994:	864e                	mv	a2,s3
    80004996:	4585                	li	a1,1
    80004998:	6c88                	ld	a0,24(s1)
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	2aa080e7          	jalr	682(ra) # 80003c44 <readi>
    800049a2:	892a                	mv	s2,a0
    800049a4:	00a05563          	blez	a0,800049ae <fileread+0x56>
      f->off += r;
    800049a8:	509c                	lw	a5,32(s1)
    800049aa:	9fa9                	addw	a5,a5,a0
    800049ac:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049ae:	6c88                	ld	a0,24(s1)
    800049b0:	fffff097          	auipc	ra,0xfffff
    800049b4:	0a2080e7          	jalr	162(ra) # 80003a52 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049b8:	854a                	mv	a0,s2
    800049ba:	70a2                	ld	ra,40(sp)
    800049bc:	7402                	ld	s0,32(sp)
    800049be:	64e2                	ld	s1,24(sp)
    800049c0:	6942                	ld	s2,16(sp)
    800049c2:	69a2                	ld	s3,8(sp)
    800049c4:	6145                	addi	sp,sp,48
    800049c6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049c8:	6908                	ld	a0,16(a0)
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	3c6080e7          	jalr	966(ra) # 80004d90 <piperead>
    800049d2:	892a                	mv	s2,a0
    800049d4:	b7d5                	j	800049b8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049d6:	02451783          	lh	a5,36(a0)
    800049da:	03079693          	slli	a3,a5,0x30
    800049de:	92c1                	srli	a3,a3,0x30
    800049e0:	4725                	li	a4,9
    800049e2:	02d76863          	bltu	a4,a3,80004a12 <fileread+0xba>
    800049e6:	0792                	slli	a5,a5,0x4
    800049e8:	0001d717          	auipc	a4,0x1d
    800049ec:	2b870713          	addi	a4,a4,696 # 80021ca0 <devsw>
    800049f0:	97ba                	add	a5,a5,a4
    800049f2:	639c                	ld	a5,0(a5)
    800049f4:	c38d                	beqz	a5,80004a16 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049f6:	4505                	li	a0,1
    800049f8:	9782                	jalr	a5
    800049fa:	892a                	mv	s2,a0
    800049fc:	bf75                	j	800049b8 <fileread+0x60>
    panic("fileread");
    800049fe:	00004517          	auipc	a0,0x4
    80004a02:	d9250513          	addi	a0,a0,-622 # 80008790 <syscalls+0x268>
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	c46080e7          	jalr	-954(ra) # 8000064c <panic>
    return -1;
    80004a0e:	597d                	li	s2,-1
    80004a10:	b765                	j	800049b8 <fileread+0x60>
      return -1;
    80004a12:	597d                	li	s2,-1
    80004a14:	b755                	j	800049b8 <fileread+0x60>
    80004a16:	597d                	li	s2,-1
    80004a18:	b745                	j	800049b8 <fileread+0x60>

0000000080004a1a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a1a:	715d                	addi	sp,sp,-80
    80004a1c:	e486                	sd	ra,72(sp)
    80004a1e:	e0a2                	sd	s0,64(sp)
    80004a20:	fc26                	sd	s1,56(sp)
    80004a22:	f84a                	sd	s2,48(sp)
    80004a24:	f44e                	sd	s3,40(sp)
    80004a26:	f052                	sd	s4,32(sp)
    80004a28:	ec56                	sd	s5,24(sp)
    80004a2a:	e85a                	sd	s6,16(sp)
    80004a2c:	e45e                	sd	s7,8(sp)
    80004a2e:	e062                	sd	s8,0(sp)
    80004a30:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a32:	00954783          	lbu	a5,9(a0)
    80004a36:	10078663          	beqz	a5,80004b42 <filewrite+0x128>
    80004a3a:	892a                	mv	s2,a0
    80004a3c:	8aae                	mv	s5,a1
    80004a3e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a40:	411c                	lw	a5,0(a0)
    80004a42:	4705                	li	a4,1
    80004a44:	02e78263          	beq	a5,a4,80004a68 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a48:	470d                	li	a4,3
    80004a4a:	02e78663          	beq	a5,a4,80004a76 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a4e:	4709                	li	a4,2
    80004a50:	0ee79163          	bne	a5,a4,80004b32 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a54:	0ac05d63          	blez	a2,80004b0e <filewrite+0xf4>
    int i = 0;
    80004a58:	4981                	li	s3,0
    80004a5a:	6b05                	lui	s6,0x1
    80004a5c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a60:	6b85                	lui	s7,0x1
    80004a62:	c00b8b9b          	addiw	s7,s7,-1024
    80004a66:	a861                	j	80004afe <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a68:	6908                	ld	a0,16(a0)
    80004a6a:	00000097          	auipc	ra,0x0
    80004a6e:	22e080e7          	jalr	558(ra) # 80004c98 <pipewrite>
    80004a72:	8a2a                	mv	s4,a0
    80004a74:	a045                	j	80004b14 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a76:	02451783          	lh	a5,36(a0)
    80004a7a:	03079693          	slli	a3,a5,0x30
    80004a7e:	92c1                	srli	a3,a3,0x30
    80004a80:	4725                	li	a4,9
    80004a82:	0cd76263          	bltu	a4,a3,80004b46 <filewrite+0x12c>
    80004a86:	0792                	slli	a5,a5,0x4
    80004a88:	0001d717          	auipc	a4,0x1d
    80004a8c:	21870713          	addi	a4,a4,536 # 80021ca0 <devsw>
    80004a90:	97ba                	add	a5,a5,a4
    80004a92:	679c                	ld	a5,8(a5)
    80004a94:	cbdd                	beqz	a5,80004b4a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a96:	4505                	li	a0,1
    80004a98:	9782                	jalr	a5
    80004a9a:	8a2a                	mv	s4,a0
    80004a9c:	a8a5                	j	80004b14 <filewrite+0xfa>
    80004a9e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	8b0080e7          	jalr	-1872(ra) # 80004352 <begin_op>
      ilock(f->ip);
    80004aaa:	01893503          	ld	a0,24(s2)
    80004aae:	fffff097          	auipc	ra,0xfffff
    80004ab2:	ee2080e7          	jalr	-286(ra) # 80003990 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ab6:	8762                	mv	a4,s8
    80004ab8:	02092683          	lw	a3,32(s2)
    80004abc:	01598633          	add	a2,s3,s5
    80004ac0:	4585                	li	a1,1
    80004ac2:	01893503          	ld	a0,24(s2)
    80004ac6:	fffff097          	auipc	ra,0xfffff
    80004aca:	276080e7          	jalr	630(ra) # 80003d3c <writei>
    80004ace:	84aa                	mv	s1,a0
    80004ad0:	00a05763          	blez	a0,80004ade <filewrite+0xc4>
        f->off += r;
    80004ad4:	02092783          	lw	a5,32(s2)
    80004ad8:	9fa9                	addw	a5,a5,a0
    80004ada:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ade:	01893503          	ld	a0,24(s2)
    80004ae2:	fffff097          	auipc	ra,0xfffff
    80004ae6:	f70080e7          	jalr	-144(ra) # 80003a52 <iunlock>
      end_op();
    80004aea:	00000097          	auipc	ra,0x0
    80004aee:	8e8080e7          	jalr	-1816(ra) # 800043d2 <end_op>

      if(r != n1){
    80004af2:	009c1f63          	bne	s8,s1,80004b10 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004af6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004afa:	0149db63          	bge	s3,s4,80004b10 <filewrite+0xf6>
      int n1 = n - i;
    80004afe:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b02:	84be                	mv	s1,a5
    80004b04:	2781                	sext.w	a5,a5
    80004b06:	f8fb5ce3          	bge	s6,a5,80004a9e <filewrite+0x84>
    80004b0a:	84de                	mv	s1,s7
    80004b0c:	bf49                	j	80004a9e <filewrite+0x84>
    int i = 0;
    80004b0e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b10:	013a1f63          	bne	s4,s3,80004b2e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b14:	8552                	mv	a0,s4
    80004b16:	60a6                	ld	ra,72(sp)
    80004b18:	6406                	ld	s0,64(sp)
    80004b1a:	74e2                	ld	s1,56(sp)
    80004b1c:	7942                	ld	s2,48(sp)
    80004b1e:	79a2                	ld	s3,40(sp)
    80004b20:	7a02                	ld	s4,32(sp)
    80004b22:	6ae2                	ld	s5,24(sp)
    80004b24:	6b42                	ld	s6,16(sp)
    80004b26:	6ba2                	ld	s7,8(sp)
    80004b28:	6c02                	ld	s8,0(sp)
    80004b2a:	6161                	addi	sp,sp,80
    80004b2c:	8082                	ret
    ret = (i == n ? n : -1);
    80004b2e:	5a7d                	li	s4,-1
    80004b30:	b7d5                	j	80004b14 <filewrite+0xfa>
    panic("filewrite");
    80004b32:	00004517          	auipc	a0,0x4
    80004b36:	c6e50513          	addi	a0,a0,-914 # 800087a0 <syscalls+0x278>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	b12080e7          	jalr	-1262(ra) # 8000064c <panic>
    return -1;
    80004b42:	5a7d                	li	s4,-1
    80004b44:	bfc1                	j	80004b14 <filewrite+0xfa>
      return -1;
    80004b46:	5a7d                	li	s4,-1
    80004b48:	b7f1                	j	80004b14 <filewrite+0xfa>
    80004b4a:	5a7d                	li	s4,-1
    80004b4c:	b7e1                	j	80004b14 <filewrite+0xfa>

0000000080004b4e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b4e:	7179                	addi	sp,sp,-48
    80004b50:	f406                	sd	ra,40(sp)
    80004b52:	f022                	sd	s0,32(sp)
    80004b54:	ec26                	sd	s1,24(sp)
    80004b56:	e84a                	sd	s2,16(sp)
    80004b58:	e44e                	sd	s3,8(sp)
    80004b5a:	e052                	sd	s4,0(sp)
    80004b5c:	1800                	addi	s0,sp,48
    80004b5e:	84aa                	mv	s1,a0
    80004b60:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b62:	0005b023          	sd	zero,0(a1)
    80004b66:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b6a:	00000097          	auipc	ra,0x0
    80004b6e:	bf8080e7          	jalr	-1032(ra) # 80004762 <filealloc>
    80004b72:	e088                	sd	a0,0(s1)
    80004b74:	c551                	beqz	a0,80004c00 <pipealloc+0xb2>
    80004b76:	00000097          	auipc	ra,0x0
    80004b7a:	bec080e7          	jalr	-1044(ra) # 80004762 <filealloc>
    80004b7e:	00aa3023          	sd	a0,0(s4)
    80004b82:	c92d                	beqz	a0,80004bf4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	070080e7          	jalr	112(ra) # 80000bf4 <kalloc>
    80004b8c:	892a                	mv	s2,a0
    80004b8e:	c125                	beqz	a0,80004bee <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b90:	4985                	li	s3,1
    80004b92:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b96:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b9a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b9e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ba2:	00004597          	auipc	a1,0x4
    80004ba6:	c0e58593          	addi	a1,a1,-1010 # 800087b0 <syscalls+0x288>
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	0aa080e7          	jalr	170(ra) # 80000c54 <initlock>
  (*f0)->type = FD_PIPE;
    80004bb2:	609c                	ld	a5,0(s1)
    80004bb4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bb8:	609c                	ld	a5,0(s1)
    80004bba:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bbe:	609c                	ld	a5,0(s1)
    80004bc0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bc4:	609c                	ld	a5,0(s1)
    80004bc6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bca:	000a3783          	ld	a5,0(s4)
    80004bce:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bd2:	000a3783          	ld	a5,0(s4)
    80004bd6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bda:	000a3783          	ld	a5,0(s4)
    80004bde:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004be2:	000a3783          	ld	a5,0(s4)
    80004be6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bea:	4501                	li	a0,0
    80004bec:	a025                	j	80004c14 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bee:	6088                	ld	a0,0(s1)
    80004bf0:	e501                	bnez	a0,80004bf8 <pipealloc+0xaa>
    80004bf2:	a039                	j	80004c00 <pipealloc+0xb2>
    80004bf4:	6088                	ld	a0,0(s1)
    80004bf6:	c51d                	beqz	a0,80004c24 <pipealloc+0xd6>
    fileclose(*f0);
    80004bf8:	00000097          	auipc	ra,0x0
    80004bfc:	c26080e7          	jalr	-986(ra) # 8000481e <fileclose>
  if(*f1)
    80004c00:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c04:	557d                	li	a0,-1
  if(*f1)
    80004c06:	c799                	beqz	a5,80004c14 <pipealloc+0xc6>
    fileclose(*f1);
    80004c08:	853e                	mv	a0,a5
    80004c0a:	00000097          	auipc	ra,0x0
    80004c0e:	c14080e7          	jalr	-1004(ra) # 8000481e <fileclose>
  return -1;
    80004c12:	557d                	li	a0,-1
}
    80004c14:	70a2                	ld	ra,40(sp)
    80004c16:	7402                	ld	s0,32(sp)
    80004c18:	64e2                	ld	s1,24(sp)
    80004c1a:	6942                	ld	s2,16(sp)
    80004c1c:	69a2                	ld	s3,8(sp)
    80004c1e:	6a02                	ld	s4,0(sp)
    80004c20:	6145                	addi	sp,sp,48
    80004c22:	8082                	ret
  return -1;
    80004c24:	557d                	li	a0,-1
    80004c26:	b7fd                	j	80004c14 <pipealloc+0xc6>

0000000080004c28 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c28:	1101                	addi	sp,sp,-32
    80004c2a:	ec06                	sd	ra,24(sp)
    80004c2c:	e822                	sd	s0,16(sp)
    80004c2e:	e426                	sd	s1,8(sp)
    80004c30:	e04a                	sd	s2,0(sp)
    80004c32:	1000                	addi	s0,sp,32
    80004c34:	84aa                	mv	s1,a0
    80004c36:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	0ac080e7          	jalr	172(ra) # 80000ce4 <acquire>
  if(writable){
    80004c40:	02090d63          	beqz	s2,80004c7a <pipeclose+0x52>
    pi->writeopen = 0;
    80004c44:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c48:	21848513          	addi	a0,s1,536
    80004c4c:	ffffd097          	auipc	ra,0xffffd
    80004c50:	57a080e7          	jalr	1402(ra) # 800021c6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c54:	2204b783          	ld	a5,544(s1)
    80004c58:	eb95                	bnez	a5,80004c8c <pipeclose+0x64>
    release(&pi->lock);
    80004c5a:	8526                	mv	a0,s1
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	13c080e7          	jalr	316(ra) # 80000d98 <release>
    kfree((char*)pi);
    80004c64:	8526                	mv	a0,s1
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	e92080e7          	jalr	-366(ra) # 80000af8 <kfree>
  } else
    release(&pi->lock);
}
    80004c6e:	60e2                	ld	ra,24(sp)
    80004c70:	6442                	ld	s0,16(sp)
    80004c72:	64a2                	ld	s1,8(sp)
    80004c74:	6902                	ld	s2,0(sp)
    80004c76:	6105                	addi	sp,sp,32
    80004c78:	8082                	ret
    pi->readopen = 0;
    80004c7a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c7e:	21c48513          	addi	a0,s1,540
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	544080e7          	jalr	1348(ra) # 800021c6 <wakeup>
    80004c8a:	b7e9                	j	80004c54 <pipeclose+0x2c>
    release(&pi->lock);
    80004c8c:	8526                	mv	a0,s1
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	10a080e7          	jalr	266(ra) # 80000d98 <release>
}
    80004c96:	bfe1                	j	80004c6e <pipeclose+0x46>

0000000080004c98 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c98:	711d                	addi	sp,sp,-96
    80004c9a:	ec86                	sd	ra,88(sp)
    80004c9c:	e8a2                	sd	s0,80(sp)
    80004c9e:	e4a6                	sd	s1,72(sp)
    80004ca0:	e0ca                	sd	s2,64(sp)
    80004ca2:	fc4e                	sd	s3,56(sp)
    80004ca4:	f852                	sd	s4,48(sp)
    80004ca6:	f456                	sd	s5,40(sp)
    80004ca8:	f05a                	sd	s6,32(sp)
    80004caa:	ec5e                	sd	s7,24(sp)
    80004cac:	e862                	sd	s8,16(sp)
    80004cae:	1080                	addi	s0,sp,96
    80004cb0:	84aa                	mv	s1,a0
    80004cb2:	8aae                	mv	s5,a1
    80004cb4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	e04080e7          	jalr	-508(ra) # 80001aba <myproc>
    80004cbe:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cc0:	8526                	mv	a0,s1
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	022080e7          	jalr	34(ra) # 80000ce4 <acquire>
  while(i < n){
    80004cca:	0b405663          	blez	s4,80004d76 <pipewrite+0xde>
  int i = 0;
    80004cce:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cd0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cd2:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cd6:	21c48b93          	addi	s7,s1,540
    80004cda:	a089                	j	80004d1c <pipewrite+0x84>
      release(&pi->lock);
    80004cdc:	8526                	mv	a0,s1
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	0ba080e7          	jalr	186(ra) # 80000d98 <release>
      return -1;
    80004ce6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ce8:	854a                	mv	a0,s2
    80004cea:	60e6                	ld	ra,88(sp)
    80004cec:	6446                	ld	s0,80(sp)
    80004cee:	64a6                	ld	s1,72(sp)
    80004cf0:	6906                	ld	s2,64(sp)
    80004cf2:	79e2                	ld	s3,56(sp)
    80004cf4:	7a42                	ld	s4,48(sp)
    80004cf6:	7aa2                	ld	s5,40(sp)
    80004cf8:	7b02                	ld	s6,32(sp)
    80004cfa:	6be2                	ld	s7,24(sp)
    80004cfc:	6c42                	ld	s8,16(sp)
    80004cfe:	6125                	addi	sp,sp,96
    80004d00:	8082                	ret
      wakeup(&pi->nread);
    80004d02:	8562                	mv	a0,s8
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	4c2080e7          	jalr	1218(ra) # 800021c6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d0c:	85a6                	mv	a1,s1
    80004d0e:	855e                	mv	a0,s7
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	452080e7          	jalr	1106(ra) # 80002162 <sleep>
  while(i < n){
    80004d18:	07495063          	bge	s2,s4,80004d78 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d1c:	2204a783          	lw	a5,544(s1)
    80004d20:	dfd5                	beqz	a5,80004cdc <pipewrite+0x44>
    80004d22:	854e                	mv	a0,s3
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	6e6080e7          	jalr	1766(ra) # 8000240a <killed>
    80004d2c:	f945                	bnez	a0,80004cdc <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d2e:	2184a783          	lw	a5,536(s1)
    80004d32:	21c4a703          	lw	a4,540(s1)
    80004d36:	2007879b          	addiw	a5,a5,512
    80004d3a:	fcf704e3          	beq	a4,a5,80004d02 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d3e:	4685                	li	a3,1
    80004d40:	01590633          	add	a2,s2,s5
    80004d44:	faf40593          	addi	a1,s0,-81
    80004d48:	0509b503          	ld	a0,80(s3)
    80004d4c:	ffffd097          	auipc	ra,0xffffd
    80004d50:	ab6080e7          	jalr	-1354(ra) # 80001802 <copyin>
    80004d54:	03650263          	beq	a0,s6,80004d78 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d58:	21c4a783          	lw	a5,540(s1)
    80004d5c:	0017871b          	addiw	a4,a5,1
    80004d60:	20e4ae23          	sw	a4,540(s1)
    80004d64:	1ff7f793          	andi	a5,a5,511
    80004d68:	97a6                	add	a5,a5,s1
    80004d6a:	faf44703          	lbu	a4,-81(s0)
    80004d6e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d72:	2905                	addiw	s2,s2,1
    80004d74:	b755                	j	80004d18 <pipewrite+0x80>
  int i = 0;
    80004d76:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004d78:	21848513          	addi	a0,s1,536
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	44a080e7          	jalr	1098(ra) # 800021c6 <wakeup>
  release(&pi->lock);
    80004d84:	8526                	mv	a0,s1
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	012080e7          	jalr	18(ra) # 80000d98 <release>
  return i;
    80004d8e:	bfa9                	j	80004ce8 <pipewrite+0x50>

0000000080004d90 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d90:	715d                	addi	sp,sp,-80
    80004d92:	e486                	sd	ra,72(sp)
    80004d94:	e0a2                	sd	s0,64(sp)
    80004d96:	fc26                	sd	s1,56(sp)
    80004d98:	f84a                	sd	s2,48(sp)
    80004d9a:	f44e                	sd	s3,40(sp)
    80004d9c:	f052                	sd	s4,32(sp)
    80004d9e:	ec56                	sd	s5,24(sp)
    80004da0:	e85a                	sd	s6,16(sp)
    80004da2:	0880                	addi	s0,sp,80
    80004da4:	84aa                	mv	s1,a0
    80004da6:	892e                	mv	s2,a1
    80004da8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	d10080e7          	jalr	-752(ra) # 80001aba <myproc>
    80004db2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004db4:	8526                	mv	a0,s1
    80004db6:	ffffc097          	auipc	ra,0xffffc
    80004dba:	f2e080e7          	jalr	-210(ra) # 80000ce4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dbe:	2184a703          	lw	a4,536(s1)
    80004dc2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dc6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dca:	02f71763          	bne	a4,a5,80004df8 <piperead+0x68>
    80004dce:	2244a783          	lw	a5,548(s1)
    80004dd2:	c39d                	beqz	a5,80004df8 <piperead+0x68>
    if(killed(pr)){
    80004dd4:	8552                	mv	a0,s4
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	634080e7          	jalr	1588(ra) # 8000240a <killed>
    80004dde:	e941                	bnez	a0,80004e6e <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004de0:	85a6                	mv	a1,s1
    80004de2:	854e                	mv	a0,s3
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	37e080e7          	jalr	894(ra) # 80002162 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dec:	2184a703          	lw	a4,536(s1)
    80004df0:	21c4a783          	lw	a5,540(s1)
    80004df4:	fcf70de3          	beq	a4,a5,80004dce <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004df8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dfa:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dfc:	05505363          	blez	s5,80004e42 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004e00:	2184a783          	lw	a5,536(s1)
    80004e04:	21c4a703          	lw	a4,540(s1)
    80004e08:	02f70d63          	beq	a4,a5,80004e42 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e0c:	0017871b          	addiw	a4,a5,1
    80004e10:	20e4ac23          	sw	a4,536(s1)
    80004e14:	1ff7f793          	andi	a5,a5,511
    80004e18:	97a6                	add	a5,a5,s1
    80004e1a:	0187c783          	lbu	a5,24(a5)
    80004e1e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e22:	4685                	li	a3,1
    80004e24:	fbf40613          	addi	a2,s0,-65
    80004e28:	85ca                	mv	a1,s2
    80004e2a:	050a3503          	ld	a0,80(s4)
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	948080e7          	jalr	-1720(ra) # 80001776 <copyout>
    80004e36:	01650663          	beq	a0,s6,80004e42 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e3a:	2985                	addiw	s3,s3,1
    80004e3c:	0905                	addi	s2,s2,1
    80004e3e:	fd3a91e3          	bne	s5,s3,80004e00 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e42:	21c48513          	addi	a0,s1,540
    80004e46:	ffffd097          	auipc	ra,0xffffd
    80004e4a:	380080e7          	jalr	896(ra) # 800021c6 <wakeup>
  release(&pi->lock);
    80004e4e:	8526                	mv	a0,s1
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	f48080e7          	jalr	-184(ra) # 80000d98 <release>
  return i;
}
    80004e58:	854e                	mv	a0,s3
    80004e5a:	60a6                	ld	ra,72(sp)
    80004e5c:	6406                	ld	s0,64(sp)
    80004e5e:	74e2                	ld	s1,56(sp)
    80004e60:	7942                	ld	s2,48(sp)
    80004e62:	79a2                	ld	s3,40(sp)
    80004e64:	7a02                	ld	s4,32(sp)
    80004e66:	6ae2                	ld	s5,24(sp)
    80004e68:	6b42                	ld	s6,16(sp)
    80004e6a:	6161                	addi	sp,sp,80
    80004e6c:	8082                	ret
      release(&pi->lock);
    80004e6e:	8526                	mv	a0,s1
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	f28080e7          	jalr	-216(ra) # 80000d98 <release>
      return -1;
    80004e78:	59fd                	li	s3,-1
    80004e7a:	bff9                	j	80004e58 <piperead+0xc8>

0000000080004e7c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e7c:	1141                	addi	sp,sp,-16
    80004e7e:	e422                	sd	s0,8(sp)
    80004e80:	0800                	addi	s0,sp,16
    80004e82:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e84:	8905                	andi	a0,a0,1
    80004e86:	c111                	beqz	a0,80004e8a <flags2perm+0xe>
      perm = PTE_X;
    80004e88:	4521                	li	a0,8
    if(flags & 0x2)
    80004e8a:	8b89                	andi	a5,a5,2
    80004e8c:	c399                	beqz	a5,80004e92 <flags2perm+0x16>
      perm |= PTE_W;
    80004e8e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e92:	6422                	ld	s0,8(sp)
    80004e94:	0141                	addi	sp,sp,16
    80004e96:	8082                	ret

0000000080004e98 <exec>:

int
exec(char *path, char **argv)
{
    80004e98:	de010113          	addi	sp,sp,-544
    80004e9c:	20113c23          	sd	ra,536(sp)
    80004ea0:	20813823          	sd	s0,528(sp)
    80004ea4:	20913423          	sd	s1,520(sp)
    80004ea8:	21213023          	sd	s2,512(sp)
    80004eac:	ffce                	sd	s3,504(sp)
    80004eae:	fbd2                	sd	s4,496(sp)
    80004eb0:	f7d6                	sd	s5,488(sp)
    80004eb2:	f3da                	sd	s6,480(sp)
    80004eb4:	efde                	sd	s7,472(sp)
    80004eb6:	ebe2                	sd	s8,464(sp)
    80004eb8:	e7e6                	sd	s9,456(sp)
    80004eba:	e3ea                	sd	s10,448(sp)
    80004ebc:	ff6e                	sd	s11,440(sp)
    80004ebe:	1400                	addi	s0,sp,544
    80004ec0:	892a                	mv	s2,a0
    80004ec2:	dea43423          	sd	a0,-536(s0)
    80004ec6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	bf0080e7          	jalr	-1040(ra) # 80001aba <myproc>
    80004ed2:	84aa                	mv	s1,a0

  begin_op();
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	47e080e7          	jalr	1150(ra) # 80004352 <begin_op>

  if((ip = namei(path)) == 0){
    80004edc:	854a                	mv	a0,s2
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	258080e7          	jalr	600(ra) # 80004136 <namei>
    80004ee6:	c93d                	beqz	a0,80004f5c <exec+0xc4>
    80004ee8:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004eea:	fffff097          	auipc	ra,0xfffff
    80004eee:	aa6080e7          	jalr	-1370(ra) # 80003990 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ef2:	04000713          	li	a4,64
    80004ef6:	4681                	li	a3,0
    80004ef8:	e5040613          	addi	a2,s0,-432
    80004efc:	4581                	li	a1,0
    80004efe:	8556                	mv	a0,s5
    80004f00:	fffff097          	auipc	ra,0xfffff
    80004f04:	d44080e7          	jalr	-700(ra) # 80003c44 <readi>
    80004f08:	04000793          	li	a5,64
    80004f0c:	00f51a63          	bne	a0,a5,80004f20 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f10:	e5042703          	lw	a4,-432(s0)
    80004f14:	464c47b7          	lui	a5,0x464c4
    80004f18:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f1c:	04f70663          	beq	a4,a5,80004f68 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f20:	8556                	mv	a0,s5
    80004f22:	fffff097          	auipc	ra,0xfffff
    80004f26:	cd0080e7          	jalr	-816(ra) # 80003bf2 <iunlockput>
    end_op();
    80004f2a:	fffff097          	auipc	ra,0xfffff
    80004f2e:	4a8080e7          	jalr	1192(ra) # 800043d2 <end_op>
  }
  return -1;
    80004f32:	557d                	li	a0,-1
}
    80004f34:	21813083          	ld	ra,536(sp)
    80004f38:	21013403          	ld	s0,528(sp)
    80004f3c:	20813483          	ld	s1,520(sp)
    80004f40:	20013903          	ld	s2,512(sp)
    80004f44:	79fe                	ld	s3,504(sp)
    80004f46:	7a5e                	ld	s4,496(sp)
    80004f48:	7abe                	ld	s5,488(sp)
    80004f4a:	7b1e                	ld	s6,480(sp)
    80004f4c:	6bfe                	ld	s7,472(sp)
    80004f4e:	6c5e                	ld	s8,464(sp)
    80004f50:	6cbe                	ld	s9,456(sp)
    80004f52:	6d1e                	ld	s10,448(sp)
    80004f54:	7dfa                	ld	s11,440(sp)
    80004f56:	22010113          	addi	sp,sp,544
    80004f5a:	8082                	ret
    end_op();
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	476080e7          	jalr	1142(ra) # 800043d2 <end_op>
    return -1;
    80004f64:	557d                	li	a0,-1
    80004f66:	b7f9                	j	80004f34 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f68:	8526                	mv	a0,s1
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	c14080e7          	jalr	-1004(ra) # 80001b7e <proc_pagetable>
    80004f72:	8b2a                	mv	s6,a0
    80004f74:	d555                	beqz	a0,80004f20 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f76:	e7042783          	lw	a5,-400(s0)
    80004f7a:	e8845703          	lhu	a4,-376(s0)
    80004f7e:	c735                	beqz	a4,80004fea <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f80:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f82:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f86:	6a05                	lui	s4,0x1
    80004f88:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f8c:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004f90:	6d85                	lui	s11,0x1
    80004f92:	7d7d                	lui	s10,0xfffff
    80004f94:	a481                	j	800051d4 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f96:	00004517          	auipc	a0,0x4
    80004f9a:	82250513          	addi	a0,a0,-2014 # 800087b8 <syscalls+0x290>
    80004f9e:	ffffb097          	auipc	ra,0xffffb
    80004fa2:	6ae080e7          	jalr	1710(ra) # 8000064c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fa6:	874a                	mv	a4,s2
    80004fa8:	009c86bb          	addw	a3,s9,s1
    80004fac:	4581                	li	a1,0
    80004fae:	8556                	mv	a0,s5
    80004fb0:	fffff097          	auipc	ra,0xfffff
    80004fb4:	c94080e7          	jalr	-876(ra) # 80003c44 <readi>
    80004fb8:	2501                	sext.w	a0,a0
    80004fba:	1aa91a63          	bne	s2,a0,8000516e <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004fbe:	009d84bb          	addw	s1,s11,s1
    80004fc2:	013d09bb          	addw	s3,s10,s3
    80004fc6:	1f74f763          	bgeu	s1,s7,800051b4 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004fca:	02049593          	slli	a1,s1,0x20
    80004fce:	9181                	srli	a1,a1,0x20
    80004fd0:	95e2                	add	a1,a1,s8
    80004fd2:	855a                	mv	a0,s6
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	196080e7          	jalr	406(ra) # 8000116a <walkaddr>
    80004fdc:	862a                	mv	a2,a0
    if(pa == 0)
    80004fde:	dd45                	beqz	a0,80004f96 <exec+0xfe>
      n = PGSIZE;
    80004fe0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004fe2:	fd49f2e3          	bgeu	s3,s4,80004fa6 <exec+0x10e>
      n = sz - i;
    80004fe6:	894e                	mv	s2,s3
    80004fe8:	bf7d                	j	80004fa6 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fea:	4901                	li	s2,0
  iunlockput(ip);
    80004fec:	8556                	mv	a0,s5
    80004fee:	fffff097          	auipc	ra,0xfffff
    80004ff2:	c04080e7          	jalr	-1020(ra) # 80003bf2 <iunlockput>
  end_op();
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	3dc080e7          	jalr	988(ra) # 800043d2 <end_op>
  p = myproc();
    80004ffe:	ffffd097          	auipc	ra,0xffffd
    80005002:	abc080e7          	jalr	-1348(ra) # 80001aba <myproc>
    80005006:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005008:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000500c:	6785                	lui	a5,0x1
    8000500e:	17fd                	addi	a5,a5,-1
    80005010:	993e                	add	s2,s2,a5
    80005012:	77fd                	lui	a5,0xfffff
    80005014:	00f977b3          	and	a5,s2,a5
    80005018:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000501c:	4691                	li	a3,4
    8000501e:	6609                	lui	a2,0x2
    80005020:	963e                	add	a2,a2,a5
    80005022:	85be                	mv	a1,a5
    80005024:	855a                	mv	a0,s6
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	4f8080e7          	jalr	1272(ra) # 8000151e <uvmalloc>
    8000502e:	8c2a                	mv	s8,a0
  ip = 0;
    80005030:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005032:	12050e63          	beqz	a0,8000516e <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005036:	75f9                	lui	a1,0xffffe
    80005038:	95aa                	add	a1,a1,a0
    8000503a:	855a                	mv	a0,s6
    8000503c:	ffffc097          	auipc	ra,0xffffc
    80005040:	708080e7          	jalr	1800(ra) # 80001744 <uvmclear>
  stackbase = sp - PGSIZE;
    80005044:	7afd                	lui	s5,0xfffff
    80005046:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005048:	df043783          	ld	a5,-528(s0)
    8000504c:	6388                	ld	a0,0(a5)
    8000504e:	c925                	beqz	a0,800050be <exec+0x226>
    80005050:	e9040993          	addi	s3,s0,-368
    80005054:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005058:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000505a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	f00080e7          	jalr	-256(ra) # 80000f5c <strlen>
    80005064:	0015079b          	addiw	a5,a0,1
    80005068:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000506c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005070:	13596663          	bltu	s2,s5,8000519c <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005074:	df043d83          	ld	s11,-528(s0)
    80005078:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000507c:	8552                	mv	a0,s4
    8000507e:	ffffc097          	auipc	ra,0xffffc
    80005082:	ede080e7          	jalr	-290(ra) # 80000f5c <strlen>
    80005086:	0015069b          	addiw	a3,a0,1
    8000508a:	8652                	mv	a2,s4
    8000508c:	85ca                	mv	a1,s2
    8000508e:	855a                	mv	a0,s6
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	6e6080e7          	jalr	1766(ra) # 80001776 <copyout>
    80005098:	10054663          	bltz	a0,800051a4 <exec+0x30c>
    ustack[argc] = sp;
    8000509c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050a0:	0485                	addi	s1,s1,1
    800050a2:	008d8793          	addi	a5,s11,8
    800050a6:	def43823          	sd	a5,-528(s0)
    800050aa:	008db503          	ld	a0,8(s11)
    800050ae:	c911                	beqz	a0,800050c2 <exec+0x22a>
    if(argc >= MAXARG)
    800050b0:	09a1                	addi	s3,s3,8
    800050b2:	fb3c95e3          	bne	s9,s3,8000505c <exec+0x1c4>
  sz = sz1;
    800050b6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ba:	4a81                	li	s5,0
    800050bc:	a84d                	j	8000516e <exec+0x2d6>
  sp = sz;
    800050be:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050c0:	4481                	li	s1,0
  ustack[argc] = 0;
    800050c2:	00349793          	slli	a5,s1,0x3
    800050c6:	f9040713          	addi	a4,s0,-112
    800050ca:	97ba                	add	a5,a5,a4
    800050cc:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc0c8>
  sp -= (argc+1) * sizeof(uint64);
    800050d0:	00148693          	addi	a3,s1,1
    800050d4:	068e                	slli	a3,a3,0x3
    800050d6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050da:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050de:	01597663          	bgeu	s2,s5,800050ea <exec+0x252>
  sz = sz1;
    800050e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050e6:	4a81                	li	s5,0
    800050e8:	a059                	j	8000516e <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050ea:	e9040613          	addi	a2,s0,-368
    800050ee:	85ca                	mv	a1,s2
    800050f0:	855a                	mv	a0,s6
    800050f2:	ffffc097          	auipc	ra,0xffffc
    800050f6:	684080e7          	jalr	1668(ra) # 80001776 <copyout>
    800050fa:	0a054963          	bltz	a0,800051ac <exec+0x314>
  p->trapframe->a1 = sp;
    800050fe:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005102:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005106:	de843783          	ld	a5,-536(s0)
    8000510a:	0007c703          	lbu	a4,0(a5)
    8000510e:	cf11                	beqz	a4,8000512a <exec+0x292>
    80005110:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005112:	02f00693          	li	a3,47
    80005116:	a039                	j	80005124 <exec+0x28c>
      last = s+1;
    80005118:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000511c:	0785                	addi	a5,a5,1
    8000511e:	fff7c703          	lbu	a4,-1(a5)
    80005122:	c701                	beqz	a4,8000512a <exec+0x292>
    if(*s == '/')
    80005124:	fed71ce3          	bne	a4,a3,8000511c <exec+0x284>
    80005128:	bfc5                	j	80005118 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    8000512a:	4641                	li	a2,16
    8000512c:	de843583          	ld	a1,-536(s0)
    80005130:	158b8513          	addi	a0,s7,344
    80005134:	ffffc097          	auipc	ra,0xffffc
    80005138:	df6080e7          	jalr	-522(ra) # 80000f2a <safestrcpy>
  oldpagetable = p->pagetable;
    8000513c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005140:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005144:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005148:	058bb783          	ld	a5,88(s7)
    8000514c:	e6843703          	ld	a4,-408(s0)
    80005150:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005152:	058bb783          	ld	a5,88(s7)
    80005156:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000515a:	85ea                	mv	a1,s10
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	abe080e7          	jalr	-1346(ra) # 80001c1a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005164:	0004851b          	sext.w	a0,s1
    80005168:	b3f1                	j	80004f34 <exec+0x9c>
    8000516a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000516e:	df843583          	ld	a1,-520(s0)
    80005172:	855a                	mv	a0,s6
    80005174:	ffffd097          	auipc	ra,0xffffd
    80005178:	aa6080e7          	jalr	-1370(ra) # 80001c1a <proc_freepagetable>
  if(ip){
    8000517c:	da0a92e3          	bnez	s5,80004f20 <exec+0x88>
  return -1;
    80005180:	557d                	li	a0,-1
    80005182:	bb4d                	j	80004f34 <exec+0x9c>
    80005184:	df243c23          	sd	s2,-520(s0)
    80005188:	b7dd                	j	8000516e <exec+0x2d6>
    8000518a:	df243c23          	sd	s2,-520(s0)
    8000518e:	b7c5                	j	8000516e <exec+0x2d6>
    80005190:	df243c23          	sd	s2,-520(s0)
    80005194:	bfe9                	j	8000516e <exec+0x2d6>
    80005196:	df243c23          	sd	s2,-520(s0)
    8000519a:	bfd1                	j	8000516e <exec+0x2d6>
  sz = sz1;
    8000519c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051a0:	4a81                	li	s5,0
    800051a2:	b7f1                	j	8000516e <exec+0x2d6>
  sz = sz1;
    800051a4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051a8:	4a81                	li	s5,0
    800051aa:	b7d1                	j	8000516e <exec+0x2d6>
  sz = sz1;
    800051ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051b0:	4a81                	li	s5,0
    800051b2:	bf75                	j	8000516e <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051b4:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051b8:	e0843783          	ld	a5,-504(s0)
    800051bc:	0017869b          	addiw	a3,a5,1
    800051c0:	e0d43423          	sd	a3,-504(s0)
    800051c4:	e0043783          	ld	a5,-512(s0)
    800051c8:	0387879b          	addiw	a5,a5,56
    800051cc:	e8845703          	lhu	a4,-376(s0)
    800051d0:	e0e6dee3          	bge	a3,a4,80004fec <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051d4:	2781                	sext.w	a5,a5
    800051d6:	e0f43023          	sd	a5,-512(s0)
    800051da:	03800713          	li	a4,56
    800051de:	86be                	mv	a3,a5
    800051e0:	e1840613          	addi	a2,s0,-488
    800051e4:	4581                	li	a1,0
    800051e6:	8556                	mv	a0,s5
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	a5c080e7          	jalr	-1444(ra) # 80003c44 <readi>
    800051f0:	03800793          	li	a5,56
    800051f4:	f6f51be3          	bne	a0,a5,8000516a <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800051f8:	e1842783          	lw	a5,-488(s0)
    800051fc:	4705                	li	a4,1
    800051fe:	fae79de3          	bne	a5,a4,800051b8 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005202:	e4043483          	ld	s1,-448(s0)
    80005206:	e3843783          	ld	a5,-456(s0)
    8000520a:	f6f4ede3          	bltu	s1,a5,80005184 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000520e:	e2843783          	ld	a5,-472(s0)
    80005212:	94be                	add	s1,s1,a5
    80005214:	f6f4ebe3          	bltu	s1,a5,8000518a <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005218:	de043703          	ld	a4,-544(s0)
    8000521c:	8ff9                	and	a5,a5,a4
    8000521e:	fbad                	bnez	a5,80005190 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005220:	e1c42503          	lw	a0,-484(s0)
    80005224:	00000097          	auipc	ra,0x0
    80005228:	c58080e7          	jalr	-936(ra) # 80004e7c <flags2perm>
    8000522c:	86aa                	mv	a3,a0
    8000522e:	8626                	mv	a2,s1
    80005230:	85ca                	mv	a1,s2
    80005232:	855a                	mv	a0,s6
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	2ea080e7          	jalr	746(ra) # 8000151e <uvmalloc>
    8000523c:	dea43c23          	sd	a0,-520(s0)
    80005240:	d939                	beqz	a0,80005196 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005242:	e2843c03          	ld	s8,-472(s0)
    80005246:	e2042c83          	lw	s9,-480(s0)
    8000524a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000524e:	f60b83e3          	beqz	s7,800051b4 <exec+0x31c>
    80005252:	89de                	mv	s3,s7
    80005254:	4481                	li	s1,0
    80005256:	bb95                	j	80004fca <exec+0x132>

0000000080005258 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005258:	7179                	addi	sp,sp,-48
    8000525a:	f406                	sd	ra,40(sp)
    8000525c:	f022                	sd	s0,32(sp)
    8000525e:	ec26                	sd	s1,24(sp)
    80005260:	e84a                	sd	s2,16(sp)
    80005262:	1800                	addi	s0,sp,48
    80005264:	892e                	mv	s2,a1
    80005266:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005268:	fdc40593          	addi	a1,s0,-36
    8000526c:	ffffe097          	auipc	ra,0xffffe
    80005270:	b32080e7          	jalr	-1230(ra) # 80002d9e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005274:	fdc42703          	lw	a4,-36(s0)
    80005278:	47bd                	li	a5,15
    8000527a:	02e7eb63          	bltu	a5,a4,800052b0 <argfd+0x58>
    8000527e:	ffffd097          	auipc	ra,0xffffd
    80005282:	83c080e7          	jalr	-1988(ra) # 80001aba <myproc>
    80005286:	fdc42703          	lw	a4,-36(s0)
    8000528a:	01a70793          	addi	a5,a4,26
    8000528e:	078e                	slli	a5,a5,0x3
    80005290:	953e                	add	a0,a0,a5
    80005292:	611c                	ld	a5,0(a0)
    80005294:	c385                	beqz	a5,800052b4 <argfd+0x5c>
    return -1;
  if(pfd)
    80005296:	00090463          	beqz	s2,8000529e <argfd+0x46>
    *pfd = fd;
    8000529a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000529e:	4501                	li	a0,0
  if(pf)
    800052a0:	c091                	beqz	s1,800052a4 <argfd+0x4c>
    *pf = f;
    800052a2:	e09c                	sd	a5,0(s1)
}
    800052a4:	70a2                	ld	ra,40(sp)
    800052a6:	7402                	ld	s0,32(sp)
    800052a8:	64e2                	ld	s1,24(sp)
    800052aa:	6942                	ld	s2,16(sp)
    800052ac:	6145                	addi	sp,sp,48
    800052ae:	8082                	ret
    return -1;
    800052b0:	557d                	li	a0,-1
    800052b2:	bfcd                	j	800052a4 <argfd+0x4c>
    800052b4:	557d                	li	a0,-1
    800052b6:	b7fd                	j	800052a4 <argfd+0x4c>

00000000800052b8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052b8:	1101                	addi	sp,sp,-32
    800052ba:	ec06                	sd	ra,24(sp)
    800052bc:	e822                	sd	s0,16(sp)
    800052be:	e426                	sd	s1,8(sp)
    800052c0:	1000                	addi	s0,sp,32
    800052c2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052c4:	ffffc097          	auipc	ra,0xffffc
    800052c8:	7f6080e7          	jalr	2038(ra) # 80001aba <myproc>
    800052cc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052ce:	0d050793          	addi	a5,a0,208
    800052d2:	4501                	li	a0,0
    800052d4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052d6:	6398                	ld	a4,0(a5)
    800052d8:	cb19                	beqz	a4,800052ee <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052da:	2505                	addiw	a0,a0,1
    800052dc:	07a1                	addi	a5,a5,8
    800052de:	fed51ce3          	bne	a0,a3,800052d6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052e2:	557d                	li	a0,-1
}
    800052e4:	60e2                	ld	ra,24(sp)
    800052e6:	6442                	ld	s0,16(sp)
    800052e8:	64a2                	ld	s1,8(sp)
    800052ea:	6105                	addi	sp,sp,32
    800052ec:	8082                	ret
      p->ofile[fd] = f;
    800052ee:	01a50793          	addi	a5,a0,26
    800052f2:	078e                	slli	a5,a5,0x3
    800052f4:	963e                	add	a2,a2,a5
    800052f6:	e204                	sd	s1,0(a2)
      return fd;
    800052f8:	b7f5                	j	800052e4 <fdalloc+0x2c>

00000000800052fa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052fa:	715d                	addi	sp,sp,-80
    800052fc:	e486                	sd	ra,72(sp)
    800052fe:	e0a2                	sd	s0,64(sp)
    80005300:	fc26                	sd	s1,56(sp)
    80005302:	f84a                	sd	s2,48(sp)
    80005304:	f44e                	sd	s3,40(sp)
    80005306:	f052                	sd	s4,32(sp)
    80005308:	ec56                	sd	s5,24(sp)
    8000530a:	e85a                	sd	s6,16(sp)
    8000530c:	0880                	addi	s0,sp,80
    8000530e:	8b2e                	mv	s6,a1
    80005310:	89b2                	mv	s3,a2
    80005312:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005314:	fb040593          	addi	a1,s0,-80
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	e3c080e7          	jalr	-452(ra) # 80004154 <nameiparent>
    80005320:	84aa                	mv	s1,a0
    80005322:	14050f63          	beqz	a0,80005480 <create+0x186>
    return 0;

  ilock(dp);
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	66a080e7          	jalr	1642(ra) # 80003990 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000532e:	4601                	li	a2,0
    80005330:	fb040593          	addi	a1,s0,-80
    80005334:	8526                	mv	a0,s1
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	b3e080e7          	jalr	-1218(ra) # 80003e74 <dirlookup>
    8000533e:	8aaa                	mv	s5,a0
    80005340:	c931                	beqz	a0,80005394 <create+0x9a>
    iunlockput(dp);
    80005342:	8526                	mv	a0,s1
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	8ae080e7          	jalr	-1874(ra) # 80003bf2 <iunlockput>
    ilock(ip);
    8000534c:	8556                	mv	a0,s5
    8000534e:	ffffe097          	auipc	ra,0xffffe
    80005352:	642080e7          	jalr	1602(ra) # 80003990 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005356:	000b059b          	sext.w	a1,s6
    8000535a:	4789                	li	a5,2
    8000535c:	02f59563          	bne	a1,a5,80005386 <create+0x8c>
    80005360:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc20c>
    80005364:	37f9                	addiw	a5,a5,-2
    80005366:	17c2                	slli	a5,a5,0x30
    80005368:	93c1                	srli	a5,a5,0x30
    8000536a:	4705                	li	a4,1
    8000536c:	00f76d63          	bltu	a4,a5,80005386 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005370:	8556                	mv	a0,s5
    80005372:	60a6                	ld	ra,72(sp)
    80005374:	6406                	ld	s0,64(sp)
    80005376:	74e2                	ld	s1,56(sp)
    80005378:	7942                	ld	s2,48(sp)
    8000537a:	79a2                	ld	s3,40(sp)
    8000537c:	7a02                	ld	s4,32(sp)
    8000537e:	6ae2                	ld	s5,24(sp)
    80005380:	6b42                	ld	s6,16(sp)
    80005382:	6161                	addi	sp,sp,80
    80005384:	8082                	ret
    iunlockput(ip);
    80005386:	8556                	mv	a0,s5
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	86a080e7          	jalr	-1942(ra) # 80003bf2 <iunlockput>
    return 0;
    80005390:	4a81                	li	s5,0
    80005392:	bff9                	j	80005370 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005394:	85da                	mv	a1,s6
    80005396:	4088                	lw	a0,0(s1)
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	45c080e7          	jalr	1116(ra) # 800037f4 <ialloc>
    800053a0:	8a2a                	mv	s4,a0
    800053a2:	c539                	beqz	a0,800053f0 <create+0xf6>
  ilock(ip);
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	5ec080e7          	jalr	1516(ra) # 80003990 <ilock>
  ip->major = major;
    800053ac:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800053b0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800053b4:	4905                	li	s2,1
    800053b6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800053ba:	8552                	mv	a0,s4
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	50a080e7          	jalr	1290(ra) # 800038c6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053c4:	000b059b          	sext.w	a1,s6
    800053c8:	03258b63          	beq	a1,s2,800053fe <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800053cc:	004a2603          	lw	a2,4(s4)
    800053d0:	fb040593          	addi	a1,s0,-80
    800053d4:	8526                	mv	a0,s1
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	cae080e7          	jalr	-850(ra) # 80004084 <dirlink>
    800053de:	06054f63          	bltz	a0,8000545c <create+0x162>
  iunlockput(dp);
    800053e2:	8526                	mv	a0,s1
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	80e080e7          	jalr	-2034(ra) # 80003bf2 <iunlockput>
  return ip;
    800053ec:	8ad2                	mv	s5,s4
    800053ee:	b749                	j	80005370 <create+0x76>
    iunlockput(dp);
    800053f0:	8526                	mv	a0,s1
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	800080e7          	jalr	-2048(ra) # 80003bf2 <iunlockput>
    return 0;
    800053fa:	8ad2                	mv	s5,s4
    800053fc:	bf95                	j	80005370 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053fe:	004a2603          	lw	a2,4(s4)
    80005402:	00003597          	auipc	a1,0x3
    80005406:	3d658593          	addi	a1,a1,982 # 800087d8 <syscalls+0x2b0>
    8000540a:	8552                	mv	a0,s4
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	c78080e7          	jalr	-904(ra) # 80004084 <dirlink>
    80005414:	04054463          	bltz	a0,8000545c <create+0x162>
    80005418:	40d0                	lw	a2,4(s1)
    8000541a:	00003597          	auipc	a1,0x3
    8000541e:	3c658593          	addi	a1,a1,966 # 800087e0 <syscalls+0x2b8>
    80005422:	8552                	mv	a0,s4
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	c60080e7          	jalr	-928(ra) # 80004084 <dirlink>
    8000542c:	02054863          	bltz	a0,8000545c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005430:	004a2603          	lw	a2,4(s4)
    80005434:	fb040593          	addi	a1,s0,-80
    80005438:	8526                	mv	a0,s1
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	c4a080e7          	jalr	-950(ra) # 80004084 <dirlink>
    80005442:	00054d63          	bltz	a0,8000545c <create+0x162>
    dp->nlink++;  // for ".."
    80005446:	04a4d783          	lhu	a5,74(s1)
    8000544a:	2785                	addiw	a5,a5,1
    8000544c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005450:	8526                	mv	a0,s1
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	474080e7          	jalr	1140(ra) # 800038c6 <iupdate>
    8000545a:	b761                	j	800053e2 <create+0xe8>
  ip->nlink = 0;
    8000545c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005460:	8552                	mv	a0,s4
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	464080e7          	jalr	1124(ra) # 800038c6 <iupdate>
  iunlockput(ip);
    8000546a:	8552                	mv	a0,s4
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	786080e7          	jalr	1926(ra) # 80003bf2 <iunlockput>
  iunlockput(dp);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	77c080e7          	jalr	1916(ra) # 80003bf2 <iunlockput>
  return 0;
    8000547e:	bdcd                	j	80005370 <create+0x76>
    return 0;
    80005480:	8aaa                	mv	s5,a0
    80005482:	b5fd                	j	80005370 <create+0x76>

0000000080005484 <sys_dup>:
{
    80005484:	7179                	addi	sp,sp,-48
    80005486:	f406                	sd	ra,40(sp)
    80005488:	f022                	sd	s0,32(sp)
    8000548a:	ec26                	sd	s1,24(sp)
    8000548c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000548e:	fd840613          	addi	a2,s0,-40
    80005492:	4581                	li	a1,0
    80005494:	4501                	li	a0,0
    80005496:	00000097          	auipc	ra,0x0
    8000549a:	dc2080e7          	jalr	-574(ra) # 80005258 <argfd>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054a0:	02054363          	bltz	a0,800054c6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054a4:	fd843503          	ld	a0,-40(s0)
    800054a8:	00000097          	auipc	ra,0x0
    800054ac:	e10080e7          	jalr	-496(ra) # 800052b8 <fdalloc>
    800054b0:	84aa                	mv	s1,a0
    return -1;
    800054b2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054b4:	00054963          	bltz	a0,800054c6 <sys_dup+0x42>
  filedup(f);
    800054b8:	fd843503          	ld	a0,-40(s0)
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	310080e7          	jalr	784(ra) # 800047cc <filedup>
  return fd;
    800054c4:	87a6                	mv	a5,s1
}
    800054c6:	853e                	mv	a0,a5
    800054c8:	70a2                	ld	ra,40(sp)
    800054ca:	7402                	ld	s0,32(sp)
    800054cc:	64e2                	ld	s1,24(sp)
    800054ce:	6145                	addi	sp,sp,48
    800054d0:	8082                	ret

00000000800054d2 <sys_read>:
{
    800054d2:	7179                	addi	sp,sp,-48
    800054d4:	f406                	sd	ra,40(sp)
    800054d6:	f022                	sd	s0,32(sp)
    800054d8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054da:	fd840593          	addi	a1,s0,-40
    800054de:	4505                	li	a0,1
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	8de080e7          	jalr	-1826(ra) # 80002dbe <argaddr>
  argint(2, &n);
    800054e8:	fe440593          	addi	a1,s0,-28
    800054ec:	4509                	li	a0,2
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	8b0080e7          	jalr	-1872(ra) # 80002d9e <argint>
  if(argfd(0, 0, &f) < 0)
    800054f6:	fe840613          	addi	a2,s0,-24
    800054fa:	4581                	li	a1,0
    800054fc:	4501                	li	a0,0
    800054fe:	00000097          	auipc	ra,0x0
    80005502:	d5a080e7          	jalr	-678(ra) # 80005258 <argfd>
    80005506:	87aa                	mv	a5,a0
    return -1;
    80005508:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000550a:	0007cc63          	bltz	a5,80005522 <sys_read+0x50>
  return fileread(f, p, n);
    8000550e:	fe442603          	lw	a2,-28(s0)
    80005512:	fd843583          	ld	a1,-40(s0)
    80005516:	fe843503          	ld	a0,-24(s0)
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	43e080e7          	jalr	1086(ra) # 80004958 <fileread>
}
    80005522:	70a2                	ld	ra,40(sp)
    80005524:	7402                	ld	s0,32(sp)
    80005526:	6145                	addi	sp,sp,48
    80005528:	8082                	ret

000000008000552a <sys_write>:
{
    8000552a:	7179                	addi	sp,sp,-48
    8000552c:	f406                	sd	ra,40(sp)
    8000552e:	f022                	sd	s0,32(sp)
    80005530:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005532:	fd840593          	addi	a1,s0,-40
    80005536:	4505                	li	a0,1
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	886080e7          	jalr	-1914(ra) # 80002dbe <argaddr>
  argint(2, &n);
    80005540:	fe440593          	addi	a1,s0,-28
    80005544:	4509                	li	a0,2
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	858080e7          	jalr	-1960(ra) # 80002d9e <argint>
  if(argfd(0, 0, &f) < 0)
    8000554e:	fe840613          	addi	a2,s0,-24
    80005552:	4581                	li	a1,0
    80005554:	4501                	li	a0,0
    80005556:	00000097          	auipc	ra,0x0
    8000555a:	d02080e7          	jalr	-766(ra) # 80005258 <argfd>
    8000555e:	87aa                	mv	a5,a0
    return -1;
    80005560:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005562:	0007cc63          	bltz	a5,8000557a <sys_write+0x50>
  return filewrite(f, p, n);
    80005566:	fe442603          	lw	a2,-28(s0)
    8000556a:	fd843583          	ld	a1,-40(s0)
    8000556e:	fe843503          	ld	a0,-24(s0)
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	4a8080e7          	jalr	1192(ra) # 80004a1a <filewrite>
}
    8000557a:	70a2                	ld	ra,40(sp)
    8000557c:	7402                	ld	s0,32(sp)
    8000557e:	6145                	addi	sp,sp,48
    80005580:	8082                	ret

0000000080005582 <sys_close>:
{
    80005582:	1101                	addi	sp,sp,-32
    80005584:	ec06                	sd	ra,24(sp)
    80005586:	e822                	sd	s0,16(sp)
    80005588:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000558a:	fe040613          	addi	a2,s0,-32
    8000558e:	fec40593          	addi	a1,s0,-20
    80005592:	4501                	li	a0,0
    80005594:	00000097          	auipc	ra,0x0
    80005598:	cc4080e7          	jalr	-828(ra) # 80005258 <argfd>
    return -1;
    8000559c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000559e:	02054463          	bltz	a0,800055c6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055a2:	ffffc097          	auipc	ra,0xffffc
    800055a6:	518080e7          	jalr	1304(ra) # 80001aba <myproc>
    800055aa:	fec42783          	lw	a5,-20(s0)
    800055ae:	07e9                	addi	a5,a5,26
    800055b0:	078e                	slli	a5,a5,0x3
    800055b2:	97aa                	add	a5,a5,a0
    800055b4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055b8:	fe043503          	ld	a0,-32(s0)
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	262080e7          	jalr	610(ra) # 8000481e <fileclose>
  return 0;
    800055c4:	4781                	li	a5,0
}
    800055c6:	853e                	mv	a0,a5
    800055c8:	60e2                	ld	ra,24(sp)
    800055ca:	6442                	ld	s0,16(sp)
    800055cc:	6105                	addi	sp,sp,32
    800055ce:	8082                	ret

00000000800055d0 <sys_fstat>:
{
    800055d0:	1101                	addi	sp,sp,-32
    800055d2:	ec06                	sd	ra,24(sp)
    800055d4:	e822                	sd	s0,16(sp)
    800055d6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800055d8:	fe040593          	addi	a1,s0,-32
    800055dc:	4505                	li	a0,1
    800055de:	ffffd097          	auipc	ra,0xffffd
    800055e2:	7e0080e7          	jalr	2016(ra) # 80002dbe <argaddr>
  if(argfd(0, 0, &f) < 0)
    800055e6:	fe840613          	addi	a2,s0,-24
    800055ea:	4581                	li	a1,0
    800055ec:	4501                	li	a0,0
    800055ee:	00000097          	auipc	ra,0x0
    800055f2:	c6a080e7          	jalr	-918(ra) # 80005258 <argfd>
    800055f6:	87aa                	mv	a5,a0
    return -1;
    800055f8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055fa:	0007ca63          	bltz	a5,8000560e <sys_fstat+0x3e>
  return filestat(f, st);
    800055fe:	fe043583          	ld	a1,-32(s0)
    80005602:	fe843503          	ld	a0,-24(s0)
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	2e0080e7          	jalr	736(ra) # 800048e6 <filestat>
}
    8000560e:	60e2                	ld	ra,24(sp)
    80005610:	6442                	ld	s0,16(sp)
    80005612:	6105                	addi	sp,sp,32
    80005614:	8082                	ret

0000000080005616 <sys_link>:
{
    80005616:	7169                	addi	sp,sp,-304
    80005618:	f606                	sd	ra,296(sp)
    8000561a:	f222                	sd	s0,288(sp)
    8000561c:	ee26                	sd	s1,280(sp)
    8000561e:	ea4a                	sd	s2,272(sp)
    80005620:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005622:	08000613          	li	a2,128
    80005626:	ed040593          	addi	a1,s0,-304
    8000562a:	4501                	li	a0,0
    8000562c:	ffffd097          	auipc	ra,0xffffd
    80005630:	7b2080e7          	jalr	1970(ra) # 80002dde <argstr>
    return -1;
    80005634:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005636:	10054e63          	bltz	a0,80005752 <sys_link+0x13c>
    8000563a:	08000613          	li	a2,128
    8000563e:	f5040593          	addi	a1,s0,-176
    80005642:	4505                	li	a0,1
    80005644:	ffffd097          	auipc	ra,0xffffd
    80005648:	79a080e7          	jalr	1946(ra) # 80002dde <argstr>
    return -1;
    8000564c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000564e:	10054263          	bltz	a0,80005752 <sys_link+0x13c>
  begin_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	d00080e7          	jalr	-768(ra) # 80004352 <begin_op>
  if((ip = namei(old)) == 0){
    8000565a:	ed040513          	addi	a0,s0,-304
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	ad8080e7          	jalr	-1320(ra) # 80004136 <namei>
    80005666:	84aa                	mv	s1,a0
    80005668:	c551                	beqz	a0,800056f4 <sys_link+0xde>
  ilock(ip);
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	326080e7          	jalr	806(ra) # 80003990 <ilock>
  if(ip->type == T_DIR){
    80005672:	04449703          	lh	a4,68(s1)
    80005676:	4785                	li	a5,1
    80005678:	08f70463          	beq	a4,a5,80005700 <sys_link+0xea>
  ip->nlink++;
    8000567c:	04a4d783          	lhu	a5,74(s1)
    80005680:	2785                	addiw	a5,a5,1
    80005682:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005686:	8526                	mv	a0,s1
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	23e080e7          	jalr	574(ra) # 800038c6 <iupdate>
  iunlock(ip);
    80005690:	8526                	mv	a0,s1
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	3c0080e7          	jalr	960(ra) # 80003a52 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000569a:	fd040593          	addi	a1,s0,-48
    8000569e:	f5040513          	addi	a0,s0,-176
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	ab2080e7          	jalr	-1358(ra) # 80004154 <nameiparent>
    800056aa:	892a                	mv	s2,a0
    800056ac:	c935                	beqz	a0,80005720 <sys_link+0x10a>
  ilock(dp);
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	2e2080e7          	jalr	738(ra) # 80003990 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056b6:	00092703          	lw	a4,0(s2)
    800056ba:	409c                	lw	a5,0(s1)
    800056bc:	04f71d63          	bne	a4,a5,80005716 <sys_link+0x100>
    800056c0:	40d0                	lw	a2,4(s1)
    800056c2:	fd040593          	addi	a1,s0,-48
    800056c6:	854a                	mv	a0,s2
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	9bc080e7          	jalr	-1604(ra) # 80004084 <dirlink>
    800056d0:	04054363          	bltz	a0,80005716 <sys_link+0x100>
  iunlockput(dp);
    800056d4:	854a                	mv	a0,s2
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	51c080e7          	jalr	1308(ra) # 80003bf2 <iunlockput>
  iput(ip);
    800056de:	8526                	mv	a0,s1
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	46a080e7          	jalr	1130(ra) # 80003b4a <iput>
  end_op();
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	cea080e7          	jalr	-790(ra) # 800043d2 <end_op>
  return 0;
    800056f0:	4781                	li	a5,0
    800056f2:	a085                	j	80005752 <sys_link+0x13c>
    end_op();
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	cde080e7          	jalr	-802(ra) # 800043d2 <end_op>
    return -1;
    800056fc:	57fd                	li	a5,-1
    800056fe:	a891                	j	80005752 <sys_link+0x13c>
    iunlockput(ip);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	4f0080e7          	jalr	1264(ra) # 80003bf2 <iunlockput>
    end_op();
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	cc8080e7          	jalr	-824(ra) # 800043d2 <end_op>
    return -1;
    80005712:	57fd                	li	a5,-1
    80005714:	a83d                	j	80005752 <sys_link+0x13c>
    iunlockput(dp);
    80005716:	854a                	mv	a0,s2
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	4da080e7          	jalr	1242(ra) # 80003bf2 <iunlockput>
  ilock(ip);
    80005720:	8526                	mv	a0,s1
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	26e080e7          	jalr	622(ra) # 80003990 <ilock>
  ip->nlink--;
    8000572a:	04a4d783          	lhu	a5,74(s1)
    8000572e:	37fd                	addiw	a5,a5,-1
    80005730:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005734:	8526                	mv	a0,s1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	190080e7          	jalr	400(ra) # 800038c6 <iupdate>
  iunlockput(ip);
    8000573e:	8526                	mv	a0,s1
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	4b2080e7          	jalr	1202(ra) # 80003bf2 <iunlockput>
  end_op();
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	c8a080e7          	jalr	-886(ra) # 800043d2 <end_op>
  return -1;
    80005750:	57fd                	li	a5,-1
}
    80005752:	853e                	mv	a0,a5
    80005754:	70b2                	ld	ra,296(sp)
    80005756:	7412                	ld	s0,288(sp)
    80005758:	64f2                	ld	s1,280(sp)
    8000575a:	6952                	ld	s2,272(sp)
    8000575c:	6155                	addi	sp,sp,304
    8000575e:	8082                	ret

0000000080005760 <sys_unlink>:
{
    80005760:	7151                	addi	sp,sp,-240
    80005762:	f586                	sd	ra,232(sp)
    80005764:	f1a2                	sd	s0,224(sp)
    80005766:	eda6                	sd	s1,216(sp)
    80005768:	e9ca                	sd	s2,208(sp)
    8000576a:	e5ce                	sd	s3,200(sp)
    8000576c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000576e:	08000613          	li	a2,128
    80005772:	f3040593          	addi	a1,s0,-208
    80005776:	4501                	li	a0,0
    80005778:	ffffd097          	auipc	ra,0xffffd
    8000577c:	666080e7          	jalr	1638(ra) # 80002dde <argstr>
    80005780:	18054163          	bltz	a0,80005902 <sys_unlink+0x1a2>
  begin_op();
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	bce080e7          	jalr	-1074(ra) # 80004352 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000578c:	fb040593          	addi	a1,s0,-80
    80005790:	f3040513          	addi	a0,s0,-208
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	9c0080e7          	jalr	-1600(ra) # 80004154 <nameiparent>
    8000579c:	84aa                	mv	s1,a0
    8000579e:	c979                	beqz	a0,80005874 <sys_unlink+0x114>
  ilock(dp);
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	1f0080e7          	jalr	496(ra) # 80003990 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057a8:	00003597          	auipc	a1,0x3
    800057ac:	03058593          	addi	a1,a1,48 # 800087d8 <syscalls+0x2b0>
    800057b0:	fb040513          	addi	a0,s0,-80
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	6a6080e7          	jalr	1702(ra) # 80003e5a <namecmp>
    800057bc:	14050a63          	beqz	a0,80005910 <sys_unlink+0x1b0>
    800057c0:	00003597          	auipc	a1,0x3
    800057c4:	02058593          	addi	a1,a1,32 # 800087e0 <syscalls+0x2b8>
    800057c8:	fb040513          	addi	a0,s0,-80
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	68e080e7          	jalr	1678(ra) # 80003e5a <namecmp>
    800057d4:	12050e63          	beqz	a0,80005910 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057d8:	f2c40613          	addi	a2,s0,-212
    800057dc:	fb040593          	addi	a1,s0,-80
    800057e0:	8526                	mv	a0,s1
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	692080e7          	jalr	1682(ra) # 80003e74 <dirlookup>
    800057ea:	892a                	mv	s2,a0
    800057ec:	12050263          	beqz	a0,80005910 <sys_unlink+0x1b0>
  ilock(ip);
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	1a0080e7          	jalr	416(ra) # 80003990 <ilock>
  if(ip->nlink < 1)
    800057f8:	04a91783          	lh	a5,74(s2)
    800057fc:	08f05263          	blez	a5,80005880 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005800:	04491703          	lh	a4,68(s2)
    80005804:	4785                	li	a5,1
    80005806:	08f70563          	beq	a4,a5,80005890 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000580a:	4641                	li	a2,16
    8000580c:	4581                	li	a1,0
    8000580e:	fc040513          	addi	a0,s0,-64
    80005812:	ffffb097          	auipc	ra,0xffffb
    80005816:	5ce080e7          	jalr	1486(ra) # 80000de0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000581a:	4741                	li	a4,16
    8000581c:	f2c42683          	lw	a3,-212(s0)
    80005820:	fc040613          	addi	a2,s0,-64
    80005824:	4581                	li	a1,0
    80005826:	8526                	mv	a0,s1
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	514080e7          	jalr	1300(ra) # 80003d3c <writei>
    80005830:	47c1                	li	a5,16
    80005832:	0af51563          	bne	a0,a5,800058dc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005836:	04491703          	lh	a4,68(s2)
    8000583a:	4785                	li	a5,1
    8000583c:	0af70863          	beq	a4,a5,800058ec <sys_unlink+0x18c>
  iunlockput(dp);
    80005840:	8526                	mv	a0,s1
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	3b0080e7          	jalr	944(ra) # 80003bf2 <iunlockput>
  ip->nlink--;
    8000584a:	04a95783          	lhu	a5,74(s2)
    8000584e:	37fd                	addiw	a5,a5,-1
    80005850:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005854:	854a                	mv	a0,s2
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	070080e7          	jalr	112(ra) # 800038c6 <iupdate>
  iunlockput(ip);
    8000585e:	854a                	mv	a0,s2
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	392080e7          	jalr	914(ra) # 80003bf2 <iunlockput>
  end_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	b6a080e7          	jalr	-1174(ra) # 800043d2 <end_op>
  return 0;
    80005870:	4501                	li	a0,0
    80005872:	a84d                	j	80005924 <sys_unlink+0x1c4>
    end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	b5e080e7          	jalr	-1186(ra) # 800043d2 <end_op>
    return -1;
    8000587c:	557d                	li	a0,-1
    8000587e:	a05d                	j	80005924 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005880:	00003517          	auipc	a0,0x3
    80005884:	f6850513          	addi	a0,a0,-152 # 800087e8 <syscalls+0x2c0>
    80005888:	ffffb097          	auipc	ra,0xffffb
    8000588c:	dc4080e7          	jalr	-572(ra) # 8000064c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005890:	04c92703          	lw	a4,76(s2)
    80005894:	02000793          	li	a5,32
    80005898:	f6e7f9e3          	bgeu	a5,a4,8000580a <sys_unlink+0xaa>
    8000589c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058a0:	4741                	li	a4,16
    800058a2:	86ce                	mv	a3,s3
    800058a4:	f1840613          	addi	a2,s0,-232
    800058a8:	4581                	li	a1,0
    800058aa:	854a                	mv	a0,s2
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	398080e7          	jalr	920(ra) # 80003c44 <readi>
    800058b4:	47c1                	li	a5,16
    800058b6:	00f51b63          	bne	a0,a5,800058cc <sys_unlink+0x16c>
    if(de.inum != 0)
    800058ba:	f1845783          	lhu	a5,-232(s0)
    800058be:	e7a1                	bnez	a5,80005906 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058c0:	29c1                	addiw	s3,s3,16
    800058c2:	04c92783          	lw	a5,76(s2)
    800058c6:	fcf9ede3          	bltu	s3,a5,800058a0 <sys_unlink+0x140>
    800058ca:	b781                	j	8000580a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058cc:	00003517          	auipc	a0,0x3
    800058d0:	f3450513          	addi	a0,a0,-204 # 80008800 <syscalls+0x2d8>
    800058d4:	ffffb097          	auipc	ra,0xffffb
    800058d8:	d78080e7          	jalr	-648(ra) # 8000064c <panic>
    panic("unlink: writei");
    800058dc:	00003517          	auipc	a0,0x3
    800058e0:	f3c50513          	addi	a0,a0,-196 # 80008818 <syscalls+0x2f0>
    800058e4:	ffffb097          	auipc	ra,0xffffb
    800058e8:	d68080e7          	jalr	-664(ra) # 8000064c <panic>
    dp->nlink--;
    800058ec:	04a4d783          	lhu	a5,74(s1)
    800058f0:	37fd                	addiw	a5,a5,-1
    800058f2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058f6:	8526                	mv	a0,s1
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	fce080e7          	jalr	-50(ra) # 800038c6 <iupdate>
    80005900:	b781                	j	80005840 <sys_unlink+0xe0>
    return -1;
    80005902:	557d                	li	a0,-1
    80005904:	a005                	j	80005924 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005906:	854a                	mv	a0,s2
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	2ea080e7          	jalr	746(ra) # 80003bf2 <iunlockput>
  iunlockput(dp);
    80005910:	8526                	mv	a0,s1
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	2e0080e7          	jalr	736(ra) # 80003bf2 <iunlockput>
  end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	ab8080e7          	jalr	-1352(ra) # 800043d2 <end_op>
  return -1;
    80005922:	557d                	li	a0,-1
}
    80005924:	70ae                	ld	ra,232(sp)
    80005926:	740e                	ld	s0,224(sp)
    80005928:	64ee                	ld	s1,216(sp)
    8000592a:	694e                	ld	s2,208(sp)
    8000592c:	69ae                	ld	s3,200(sp)
    8000592e:	616d                	addi	sp,sp,240
    80005930:	8082                	ret

0000000080005932 <sys_open>:

uint64
sys_open(void)
{
    80005932:	7131                	addi	sp,sp,-192
    80005934:	fd06                	sd	ra,184(sp)
    80005936:	f922                	sd	s0,176(sp)
    80005938:	f526                	sd	s1,168(sp)
    8000593a:	f14a                	sd	s2,160(sp)
    8000593c:	ed4e                	sd	s3,152(sp)
    8000593e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005940:	f4c40593          	addi	a1,s0,-180
    80005944:	4505                	li	a0,1
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	458080e7          	jalr	1112(ra) # 80002d9e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000594e:	08000613          	li	a2,128
    80005952:	f5040593          	addi	a1,s0,-176
    80005956:	4501                	li	a0,0
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	486080e7          	jalr	1158(ra) # 80002dde <argstr>
    80005960:	87aa                	mv	a5,a0
    return -1;
    80005962:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005964:	0a07c963          	bltz	a5,80005a16 <sys_open+0xe4>

  begin_op();
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	9ea080e7          	jalr	-1558(ra) # 80004352 <begin_op>

  if(omode & O_CREATE){
    80005970:	f4c42783          	lw	a5,-180(s0)
    80005974:	2007f793          	andi	a5,a5,512
    80005978:	cfc5                	beqz	a5,80005a30 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000597a:	4681                	li	a3,0
    8000597c:	4601                	li	a2,0
    8000597e:	4589                	li	a1,2
    80005980:	f5040513          	addi	a0,s0,-176
    80005984:	00000097          	auipc	ra,0x0
    80005988:	976080e7          	jalr	-1674(ra) # 800052fa <create>
    8000598c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000598e:	c959                	beqz	a0,80005a24 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005990:	04449703          	lh	a4,68(s1)
    80005994:	478d                	li	a5,3
    80005996:	00f71763          	bne	a4,a5,800059a4 <sys_open+0x72>
    8000599a:	0464d703          	lhu	a4,70(s1)
    8000599e:	47a5                	li	a5,9
    800059a0:	0ce7ed63          	bltu	a5,a4,80005a7a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	dbe080e7          	jalr	-578(ra) # 80004762 <filealloc>
    800059ac:	89aa                	mv	s3,a0
    800059ae:	10050363          	beqz	a0,80005ab4 <sys_open+0x182>
    800059b2:	00000097          	auipc	ra,0x0
    800059b6:	906080e7          	jalr	-1786(ra) # 800052b8 <fdalloc>
    800059ba:	892a                	mv	s2,a0
    800059bc:	0e054763          	bltz	a0,80005aaa <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059c0:	04449703          	lh	a4,68(s1)
    800059c4:	478d                	li	a5,3
    800059c6:	0cf70563          	beq	a4,a5,80005a90 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059ca:	4789                	li	a5,2
    800059cc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059d0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059d4:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059d8:	f4c42783          	lw	a5,-180(s0)
    800059dc:	0017c713          	xori	a4,a5,1
    800059e0:	8b05                	andi	a4,a4,1
    800059e2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059e6:	0037f713          	andi	a4,a5,3
    800059ea:	00e03733          	snez	a4,a4
    800059ee:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059f2:	4007f793          	andi	a5,a5,1024
    800059f6:	c791                	beqz	a5,80005a02 <sys_open+0xd0>
    800059f8:	04449703          	lh	a4,68(s1)
    800059fc:	4789                	li	a5,2
    800059fe:	0af70063          	beq	a4,a5,80005a9e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a02:	8526                	mv	a0,s1
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	04e080e7          	jalr	78(ra) # 80003a52 <iunlock>
  end_op();
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	9c6080e7          	jalr	-1594(ra) # 800043d2 <end_op>

  return fd;
    80005a14:	854a                	mv	a0,s2
}
    80005a16:	70ea                	ld	ra,184(sp)
    80005a18:	744a                	ld	s0,176(sp)
    80005a1a:	74aa                	ld	s1,168(sp)
    80005a1c:	790a                	ld	s2,160(sp)
    80005a1e:	69ea                	ld	s3,152(sp)
    80005a20:	6129                	addi	sp,sp,192
    80005a22:	8082                	ret
      end_op();
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	9ae080e7          	jalr	-1618(ra) # 800043d2 <end_op>
      return -1;
    80005a2c:	557d                	li	a0,-1
    80005a2e:	b7e5                	j	80005a16 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a30:	f5040513          	addi	a0,s0,-176
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	702080e7          	jalr	1794(ra) # 80004136 <namei>
    80005a3c:	84aa                	mv	s1,a0
    80005a3e:	c905                	beqz	a0,80005a6e <sys_open+0x13c>
    ilock(ip);
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	f50080e7          	jalr	-176(ra) # 80003990 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a48:	04449703          	lh	a4,68(s1)
    80005a4c:	4785                	li	a5,1
    80005a4e:	f4f711e3          	bne	a4,a5,80005990 <sys_open+0x5e>
    80005a52:	f4c42783          	lw	a5,-180(s0)
    80005a56:	d7b9                	beqz	a5,800059a4 <sys_open+0x72>
      iunlockput(ip);
    80005a58:	8526                	mv	a0,s1
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	198080e7          	jalr	408(ra) # 80003bf2 <iunlockput>
      end_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	970080e7          	jalr	-1680(ra) # 800043d2 <end_op>
      return -1;
    80005a6a:	557d                	li	a0,-1
    80005a6c:	b76d                	j	80005a16 <sys_open+0xe4>
      end_op();
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	964080e7          	jalr	-1692(ra) # 800043d2 <end_op>
      return -1;
    80005a76:	557d                	li	a0,-1
    80005a78:	bf79                	j	80005a16 <sys_open+0xe4>
    iunlockput(ip);
    80005a7a:	8526                	mv	a0,s1
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	176080e7          	jalr	374(ra) # 80003bf2 <iunlockput>
    end_op();
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	94e080e7          	jalr	-1714(ra) # 800043d2 <end_op>
    return -1;
    80005a8c:	557d                	li	a0,-1
    80005a8e:	b761                	j	80005a16 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a90:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a94:	04649783          	lh	a5,70(s1)
    80005a98:	02f99223          	sh	a5,36(s3)
    80005a9c:	bf25                	j	800059d4 <sys_open+0xa2>
    itrunc(ip);
    80005a9e:	8526                	mv	a0,s1
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	ffe080e7          	jalr	-2(ra) # 80003a9e <itrunc>
    80005aa8:	bfa9                	j	80005a02 <sys_open+0xd0>
      fileclose(f);
    80005aaa:	854e                	mv	a0,s3
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	d72080e7          	jalr	-654(ra) # 8000481e <fileclose>
    iunlockput(ip);
    80005ab4:	8526                	mv	a0,s1
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	13c080e7          	jalr	316(ra) # 80003bf2 <iunlockput>
    end_op();
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	914080e7          	jalr	-1772(ra) # 800043d2 <end_op>
    return -1;
    80005ac6:	557d                	li	a0,-1
    80005ac8:	b7b9                	j	80005a16 <sys_open+0xe4>

0000000080005aca <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005aca:	7175                	addi	sp,sp,-144
    80005acc:	e506                	sd	ra,136(sp)
    80005ace:	e122                	sd	s0,128(sp)
    80005ad0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	880080e7          	jalr	-1920(ra) # 80004352 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ada:	08000613          	li	a2,128
    80005ade:	f7040593          	addi	a1,s0,-144
    80005ae2:	4501                	li	a0,0
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	2fa080e7          	jalr	762(ra) # 80002dde <argstr>
    80005aec:	02054963          	bltz	a0,80005b1e <sys_mkdir+0x54>
    80005af0:	4681                	li	a3,0
    80005af2:	4601                	li	a2,0
    80005af4:	4585                	li	a1,1
    80005af6:	f7040513          	addi	a0,s0,-144
    80005afa:	00000097          	auipc	ra,0x0
    80005afe:	800080e7          	jalr	-2048(ra) # 800052fa <create>
    80005b02:	cd11                	beqz	a0,80005b1e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	0ee080e7          	jalr	238(ra) # 80003bf2 <iunlockput>
  end_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	8c6080e7          	jalr	-1850(ra) # 800043d2 <end_op>
  return 0;
    80005b14:	4501                	li	a0,0
}
    80005b16:	60aa                	ld	ra,136(sp)
    80005b18:	640a                	ld	s0,128(sp)
    80005b1a:	6149                	addi	sp,sp,144
    80005b1c:	8082                	ret
    end_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	8b4080e7          	jalr	-1868(ra) # 800043d2 <end_op>
    return -1;
    80005b26:	557d                	li	a0,-1
    80005b28:	b7fd                	j	80005b16 <sys_mkdir+0x4c>

0000000080005b2a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b2a:	7135                	addi	sp,sp,-160
    80005b2c:	ed06                	sd	ra,152(sp)
    80005b2e:	e922                	sd	s0,144(sp)
    80005b30:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	820080e7          	jalr	-2016(ra) # 80004352 <begin_op>
  argint(1, &major);
    80005b3a:	f6c40593          	addi	a1,s0,-148
    80005b3e:	4505                	li	a0,1
    80005b40:	ffffd097          	auipc	ra,0xffffd
    80005b44:	25e080e7          	jalr	606(ra) # 80002d9e <argint>
  argint(2, &minor);
    80005b48:	f6840593          	addi	a1,s0,-152
    80005b4c:	4509                	li	a0,2
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	250080e7          	jalr	592(ra) # 80002d9e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b56:	08000613          	li	a2,128
    80005b5a:	f7040593          	addi	a1,s0,-144
    80005b5e:	4501                	li	a0,0
    80005b60:	ffffd097          	auipc	ra,0xffffd
    80005b64:	27e080e7          	jalr	638(ra) # 80002dde <argstr>
    80005b68:	02054b63          	bltz	a0,80005b9e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b6c:	f6841683          	lh	a3,-152(s0)
    80005b70:	f6c41603          	lh	a2,-148(s0)
    80005b74:	458d                	li	a1,3
    80005b76:	f7040513          	addi	a0,s0,-144
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	780080e7          	jalr	1920(ra) # 800052fa <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b82:	cd11                	beqz	a0,80005b9e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	06e080e7          	jalr	110(ra) # 80003bf2 <iunlockput>
  end_op();
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	846080e7          	jalr	-1978(ra) # 800043d2 <end_op>
  return 0;
    80005b94:	4501                	li	a0,0
}
    80005b96:	60ea                	ld	ra,152(sp)
    80005b98:	644a                	ld	s0,144(sp)
    80005b9a:	610d                	addi	sp,sp,160
    80005b9c:	8082                	ret
    end_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	834080e7          	jalr	-1996(ra) # 800043d2 <end_op>
    return -1;
    80005ba6:	557d                	li	a0,-1
    80005ba8:	b7fd                	j	80005b96 <sys_mknod+0x6c>

0000000080005baa <sys_chdir>:

uint64
sys_chdir(void)
{
    80005baa:	7135                	addi	sp,sp,-160
    80005bac:	ed06                	sd	ra,152(sp)
    80005bae:	e922                	sd	s0,144(sp)
    80005bb0:	e526                	sd	s1,136(sp)
    80005bb2:	e14a                	sd	s2,128(sp)
    80005bb4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bb6:	ffffc097          	auipc	ra,0xffffc
    80005bba:	f04080e7          	jalr	-252(ra) # 80001aba <myproc>
    80005bbe:	892a                	mv	s2,a0
  
  begin_op();
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	792080e7          	jalr	1938(ra) # 80004352 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bc8:	08000613          	li	a2,128
    80005bcc:	f6040593          	addi	a1,s0,-160
    80005bd0:	4501                	li	a0,0
    80005bd2:	ffffd097          	auipc	ra,0xffffd
    80005bd6:	20c080e7          	jalr	524(ra) # 80002dde <argstr>
    80005bda:	04054b63          	bltz	a0,80005c30 <sys_chdir+0x86>
    80005bde:	f6040513          	addi	a0,s0,-160
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	554080e7          	jalr	1364(ra) # 80004136 <namei>
    80005bea:	84aa                	mv	s1,a0
    80005bec:	c131                	beqz	a0,80005c30 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	da2080e7          	jalr	-606(ra) # 80003990 <ilock>
  if(ip->type != T_DIR){
    80005bf6:	04449703          	lh	a4,68(s1)
    80005bfa:	4785                	li	a5,1
    80005bfc:	04f71063          	bne	a4,a5,80005c3c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c00:	8526                	mv	a0,s1
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	e50080e7          	jalr	-432(ra) # 80003a52 <iunlock>
  iput(p->cwd);
    80005c0a:	15093503          	ld	a0,336(s2)
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	f3c080e7          	jalr	-196(ra) # 80003b4a <iput>
  end_op();
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	7bc080e7          	jalr	1980(ra) # 800043d2 <end_op>
  p->cwd = ip;
    80005c1e:	14993823          	sd	s1,336(s2)
  return 0;
    80005c22:	4501                	li	a0,0
}
    80005c24:	60ea                	ld	ra,152(sp)
    80005c26:	644a                	ld	s0,144(sp)
    80005c28:	64aa                	ld	s1,136(sp)
    80005c2a:	690a                	ld	s2,128(sp)
    80005c2c:	610d                	addi	sp,sp,160
    80005c2e:	8082                	ret
    end_op();
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	7a2080e7          	jalr	1954(ra) # 800043d2 <end_op>
    return -1;
    80005c38:	557d                	li	a0,-1
    80005c3a:	b7ed                	j	80005c24 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c3c:	8526                	mv	a0,s1
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	fb4080e7          	jalr	-76(ra) # 80003bf2 <iunlockput>
    end_op();
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	78c080e7          	jalr	1932(ra) # 800043d2 <end_op>
    return -1;
    80005c4e:	557d                	li	a0,-1
    80005c50:	bfd1                	j	80005c24 <sys_chdir+0x7a>

0000000080005c52 <sys_exec>:

uint64
sys_exec(void)
{
    80005c52:	7145                	addi	sp,sp,-464
    80005c54:	e786                	sd	ra,456(sp)
    80005c56:	e3a2                	sd	s0,448(sp)
    80005c58:	ff26                	sd	s1,440(sp)
    80005c5a:	fb4a                	sd	s2,432(sp)
    80005c5c:	f74e                	sd	s3,424(sp)
    80005c5e:	f352                	sd	s4,416(sp)
    80005c60:	ef56                	sd	s5,408(sp)
    80005c62:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c64:	e3840593          	addi	a1,s0,-456
    80005c68:	4505                	li	a0,1
    80005c6a:	ffffd097          	auipc	ra,0xffffd
    80005c6e:	154080e7          	jalr	340(ra) # 80002dbe <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c72:	08000613          	li	a2,128
    80005c76:	f4040593          	addi	a1,s0,-192
    80005c7a:	4501                	li	a0,0
    80005c7c:	ffffd097          	auipc	ra,0xffffd
    80005c80:	162080e7          	jalr	354(ra) # 80002dde <argstr>
    80005c84:	87aa                	mv	a5,a0
    return -1;
    80005c86:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c88:	0c07c263          	bltz	a5,80005d4c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c8c:	10000613          	li	a2,256
    80005c90:	4581                	li	a1,0
    80005c92:	e4040513          	addi	a0,s0,-448
    80005c96:	ffffb097          	auipc	ra,0xffffb
    80005c9a:	14a080e7          	jalr	330(ra) # 80000de0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c9e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ca2:	89a6                	mv	s3,s1
    80005ca4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ca6:	02000a13          	li	s4,32
    80005caa:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cae:	00391793          	slli	a5,s2,0x3
    80005cb2:	e3040593          	addi	a1,s0,-464
    80005cb6:	e3843503          	ld	a0,-456(s0)
    80005cba:	953e                	add	a0,a0,a5
    80005cbc:	ffffd097          	auipc	ra,0xffffd
    80005cc0:	044080e7          	jalr	68(ra) # 80002d00 <fetchaddr>
    80005cc4:	02054a63          	bltz	a0,80005cf8 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005cc8:	e3043783          	ld	a5,-464(s0)
    80005ccc:	c3b9                	beqz	a5,80005d12 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cce:	ffffb097          	auipc	ra,0xffffb
    80005cd2:	f26080e7          	jalr	-218(ra) # 80000bf4 <kalloc>
    80005cd6:	85aa                	mv	a1,a0
    80005cd8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cdc:	cd11                	beqz	a0,80005cf8 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cde:	6605                	lui	a2,0x1
    80005ce0:	e3043503          	ld	a0,-464(s0)
    80005ce4:	ffffd097          	auipc	ra,0xffffd
    80005ce8:	06e080e7          	jalr	110(ra) # 80002d52 <fetchstr>
    80005cec:	00054663          	bltz	a0,80005cf8 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005cf0:	0905                	addi	s2,s2,1
    80005cf2:	09a1                	addi	s3,s3,8
    80005cf4:	fb491be3          	bne	s2,s4,80005caa <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cf8:	10048913          	addi	s2,s1,256
    80005cfc:	6088                	ld	a0,0(s1)
    80005cfe:	c531                	beqz	a0,80005d4a <sys_exec+0xf8>
    kfree(argv[i]);
    80005d00:	ffffb097          	auipc	ra,0xffffb
    80005d04:	df8080e7          	jalr	-520(ra) # 80000af8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d08:	04a1                	addi	s1,s1,8
    80005d0a:	ff2499e3          	bne	s1,s2,80005cfc <sys_exec+0xaa>
  return -1;
    80005d0e:	557d                	li	a0,-1
    80005d10:	a835                	j	80005d4c <sys_exec+0xfa>
      argv[i] = 0;
    80005d12:	0a8e                	slli	s5,s5,0x3
    80005d14:	fc040793          	addi	a5,s0,-64
    80005d18:	9abe                	add	s5,s5,a5
    80005d1a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d1e:	e4040593          	addi	a1,s0,-448
    80005d22:	f4040513          	addi	a0,s0,-192
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	172080e7          	jalr	370(ra) # 80004e98 <exec>
    80005d2e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d30:	10048993          	addi	s3,s1,256
    80005d34:	6088                	ld	a0,0(s1)
    80005d36:	c901                	beqz	a0,80005d46 <sys_exec+0xf4>
    kfree(argv[i]);
    80005d38:	ffffb097          	auipc	ra,0xffffb
    80005d3c:	dc0080e7          	jalr	-576(ra) # 80000af8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d40:	04a1                	addi	s1,s1,8
    80005d42:	ff3499e3          	bne	s1,s3,80005d34 <sys_exec+0xe2>
  return ret;
    80005d46:	854a                	mv	a0,s2
    80005d48:	a011                	j	80005d4c <sys_exec+0xfa>
  return -1;
    80005d4a:	557d                	li	a0,-1
}
    80005d4c:	60be                	ld	ra,456(sp)
    80005d4e:	641e                	ld	s0,448(sp)
    80005d50:	74fa                	ld	s1,440(sp)
    80005d52:	795a                	ld	s2,432(sp)
    80005d54:	79ba                	ld	s3,424(sp)
    80005d56:	7a1a                	ld	s4,416(sp)
    80005d58:	6afa                	ld	s5,408(sp)
    80005d5a:	6179                	addi	sp,sp,464
    80005d5c:	8082                	ret

0000000080005d5e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d5e:	7139                	addi	sp,sp,-64
    80005d60:	fc06                	sd	ra,56(sp)
    80005d62:	f822                	sd	s0,48(sp)
    80005d64:	f426                	sd	s1,40(sp)
    80005d66:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	d52080e7          	jalr	-686(ra) # 80001aba <myproc>
    80005d70:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d72:	fd840593          	addi	a1,s0,-40
    80005d76:	4501                	li	a0,0
    80005d78:	ffffd097          	auipc	ra,0xffffd
    80005d7c:	046080e7          	jalr	70(ra) # 80002dbe <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d80:	fc840593          	addi	a1,s0,-56
    80005d84:	fd040513          	addi	a0,s0,-48
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	dc6080e7          	jalr	-570(ra) # 80004b4e <pipealloc>
    return -1;
    80005d90:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d92:	0c054463          	bltz	a0,80005e5a <sys_pipe+0xfc>
  fd0 = -1;
    80005d96:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d9a:	fd043503          	ld	a0,-48(s0)
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	51a080e7          	jalr	1306(ra) # 800052b8 <fdalloc>
    80005da6:	fca42223          	sw	a0,-60(s0)
    80005daa:	08054b63          	bltz	a0,80005e40 <sys_pipe+0xe2>
    80005dae:	fc843503          	ld	a0,-56(s0)
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	506080e7          	jalr	1286(ra) # 800052b8 <fdalloc>
    80005dba:	fca42023          	sw	a0,-64(s0)
    80005dbe:	06054863          	bltz	a0,80005e2e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dc2:	4691                	li	a3,4
    80005dc4:	fc440613          	addi	a2,s0,-60
    80005dc8:	fd843583          	ld	a1,-40(s0)
    80005dcc:	68a8                	ld	a0,80(s1)
    80005dce:	ffffc097          	auipc	ra,0xffffc
    80005dd2:	9a8080e7          	jalr	-1624(ra) # 80001776 <copyout>
    80005dd6:	02054063          	bltz	a0,80005df6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dda:	4691                	li	a3,4
    80005ddc:	fc040613          	addi	a2,s0,-64
    80005de0:	fd843583          	ld	a1,-40(s0)
    80005de4:	0591                	addi	a1,a1,4
    80005de6:	68a8                	ld	a0,80(s1)
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	98e080e7          	jalr	-1650(ra) # 80001776 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005df0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005df2:	06055463          	bgez	a0,80005e5a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005df6:	fc442783          	lw	a5,-60(s0)
    80005dfa:	07e9                	addi	a5,a5,26
    80005dfc:	078e                	slli	a5,a5,0x3
    80005dfe:	97a6                	add	a5,a5,s1
    80005e00:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e04:	fc042503          	lw	a0,-64(s0)
    80005e08:	0569                	addi	a0,a0,26
    80005e0a:	050e                	slli	a0,a0,0x3
    80005e0c:	94aa                	add	s1,s1,a0
    80005e0e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e12:	fd043503          	ld	a0,-48(s0)
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	a08080e7          	jalr	-1528(ra) # 8000481e <fileclose>
    fileclose(wf);
    80005e1e:	fc843503          	ld	a0,-56(s0)
    80005e22:	fffff097          	auipc	ra,0xfffff
    80005e26:	9fc080e7          	jalr	-1540(ra) # 8000481e <fileclose>
    return -1;
    80005e2a:	57fd                	li	a5,-1
    80005e2c:	a03d                	j	80005e5a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e2e:	fc442783          	lw	a5,-60(s0)
    80005e32:	0007c763          	bltz	a5,80005e40 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e36:	07e9                	addi	a5,a5,26
    80005e38:	078e                	slli	a5,a5,0x3
    80005e3a:	94be                	add	s1,s1,a5
    80005e3c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e40:	fd043503          	ld	a0,-48(s0)
    80005e44:	fffff097          	auipc	ra,0xfffff
    80005e48:	9da080e7          	jalr	-1574(ra) # 8000481e <fileclose>
    fileclose(wf);
    80005e4c:	fc843503          	ld	a0,-56(s0)
    80005e50:	fffff097          	auipc	ra,0xfffff
    80005e54:	9ce080e7          	jalr	-1586(ra) # 8000481e <fileclose>
    return -1;
    80005e58:	57fd                	li	a5,-1
}
    80005e5a:	853e                	mv	a0,a5
    80005e5c:	70e2                	ld	ra,56(sp)
    80005e5e:	7442                	ld	s0,48(sp)
    80005e60:	74a2                	ld	s1,40(sp)
    80005e62:	6121                	addi	sp,sp,64
    80005e64:	8082                	ret
	...

0000000080005e70 <kernelvec>:
    80005e70:	7111                	addi	sp,sp,-256
    80005e72:	e006                	sd	ra,0(sp)
    80005e74:	e40a                	sd	sp,8(sp)
    80005e76:	e80e                	sd	gp,16(sp)
    80005e78:	ec12                	sd	tp,24(sp)
    80005e7a:	f016                	sd	t0,32(sp)
    80005e7c:	f41a                	sd	t1,40(sp)
    80005e7e:	f81e                	sd	t2,48(sp)
    80005e80:	fc22                	sd	s0,56(sp)
    80005e82:	e0a6                	sd	s1,64(sp)
    80005e84:	e4aa                	sd	a0,72(sp)
    80005e86:	e8ae                	sd	a1,80(sp)
    80005e88:	ecb2                	sd	a2,88(sp)
    80005e8a:	f0b6                	sd	a3,96(sp)
    80005e8c:	f4ba                	sd	a4,104(sp)
    80005e8e:	f8be                	sd	a5,112(sp)
    80005e90:	fcc2                	sd	a6,120(sp)
    80005e92:	e146                	sd	a7,128(sp)
    80005e94:	e54a                	sd	s2,136(sp)
    80005e96:	e94e                	sd	s3,144(sp)
    80005e98:	ed52                	sd	s4,152(sp)
    80005e9a:	f156                	sd	s5,160(sp)
    80005e9c:	f55a                	sd	s6,168(sp)
    80005e9e:	f95e                	sd	s7,176(sp)
    80005ea0:	fd62                	sd	s8,184(sp)
    80005ea2:	e1e6                	sd	s9,192(sp)
    80005ea4:	e5ea                	sd	s10,200(sp)
    80005ea6:	e9ee                	sd	s11,208(sp)
    80005ea8:	edf2                	sd	t3,216(sp)
    80005eaa:	f1f6                	sd	t4,224(sp)
    80005eac:	f5fa                	sd	t5,232(sp)
    80005eae:	f9fe                	sd	t6,240(sp)
    80005eb0:	d1dfc0ef          	jal	ra,80002bcc <kerneltrap>
    80005eb4:	6082                	ld	ra,0(sp)
    80005eb6:	6122                	ld	sp,8(sp)
    80005eb8:	61c2                	ld	gp,16(sp)
    80005eba:	7282                	ld	t0,32(sp)
    80005ebc:	7322                	ld	t1,40(sp)
    80005ebe:	73c2                	ld	t2,48(sp)
    80005ec0:	7462                	ld	s0,56(sp)
    80005ec2:	6486                	ld	s1,64(sp)
    80005ec4:	6526                	ld	a0,72(sp)
    80005ec6:	65c6                	ld	a1,80(sp)
    80005ec8:	6666                	ld	a2,88(sp)
    80005eca:	7686                	ld	a3,96(sp)
    80005ecc:	7726                	ld	a4,104(sp)
    80005ece:	77c6                	ld	a5,112(sp)
    80005ed0:	7866                	ld	a6,120(sp)
    80005ed2:	688a                	ld	a7,128(sp)
    80005ed4:	692a                	ld	s2,136(sp)
    80005ed6:	69ca                	ld	s3,144(sp)
    80005ed8:	6a6a                	ld	s4,152(sp)
    80005eda:	7a8a                	ld	s5,160(sp)
    80005edc:	7b2a                	ld	s6,168(sp)
    80005ede:	7bca                	ld	s7,176(sp)
    80005ee0:	7c6a                	ld	s8,184(sp)
    80005ee2:	6c8e                	ld	s9,192(sp)
    80005ee4:	6d2e                	ld	s10,200(sp)
    80005ee6:	6dce                	ld	s11,208(sp)
    80005ee8:	6e6e                	ld	t3,216(sp)
    80005eea:	7e8e                	ld	t4,224(sp)
    80005eec:	7f2e                	ld	t5,232(sp)
    80005eee:	7fce                	ld	t6,240(sp)
    80005ef0:	6111                	addi	sp,sp,256
    80005ef2:	10200073          	sret
    80005ef6:	00000013          	nop
    80005efa:	00000013          	nop
    80005efe:	0001                	nop

0000000080005f00 <timervec>:
    80005f00:	34051573          	csrrw	a0,mscratch,a0
    80005f04:	e10c                	sd	a1,0(a0)
    80005f06:	e510                	sd	a2,8(a0)
    80005f08:	e914                	sd	a3,16(a0)
    80005f0a:	6d0c                	ld	a1,24(a0)
    80005f0c:	7110                	ld	a2,32(a0)
    80005f0e:	6194                	ld	a3,0(a1)
    80005f10:	96b2                	add	a3,a3,a2
    80005f12:	e194                	sd	a3,0(a1)
    80005f14:	4589                	li	a1,2
    80005f16:	14459073          	csrw	sip,a1
    80005f1a:	6914                	ld	a3,16(a0)
    80005f1c:	6510                	ld	a2,8(a0)
    80005f1e:	610c                	ld	a1,0(a0)
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	30200073          	mret
	...

0000000080005f2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f2a:	1141                	addi	sp,sp,-16
    80005f2c:	e422                	sd	s0,8(sp)
    80005f2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f30:	0c0007b7          	lui	a5,0xc000
    80005f34:	4705                	li	a4,1
    80005f36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f38:	c3d8                	sw	a4,4(a5)
}
    80005f3a:	6422                	ld	s0,8(sp)
    80005f3c:	0141                	addi	sp,sp,16
    80005f3e:	8082                	ret

0000000080005f40 <plicinithart>:

void
plicinithart(void)
{
    80005f40:	1141                	addi	sp,sp,-16
    80005f42:	e406                	sd	ra,8(sp)
    80005f44:	e022                	sd	s0,0(sp)
    80005f46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	b46080e7          	jalr	-1210(ra) # 80001a8e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f50:	0085171b          	slliw	a4,a0,0x8
    80005f54:	0c0027b7          	lui	a5,0xc002
    80005f58:	97ba                	add	a5,a5,a4
    80005f5a:	40200713          	li	a4,1026
    80005f5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f62:	00d5151b          	slliw	a0,a0,0xd
    80005f66:	0c2017b7          	lui	a5,0xc201
    80005f6a:	953e                	add	a0,a0,a5
    80005f6c:	00052023          	sw	zero,0(a0)
}
    80005f70:	60a2                	ld	ra,8(sp)
    80005f72:	6402                	ld	s0,0(sp)
    80005f74:	0141                	addi	sp,sp,16
    80005f76:	8082                	ret

0000000080005f78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f78:	1141                	addi	sp,sp,-16
    80005f7a:	e406                	sd	ra,8(sp)
    80005f7c:	e022                	sd	s0,0(sp)
    80005f7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f80:	ffffc097          	auipc	ra,0xffffc
    80005f84:	b0e080e7          	jalr	-1266(ra) # 80001a8e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f88:	00d5179b          	slliw	a5,a0,0xd
    80005f8c:	0c201537          	lui	a0,0xc201
    80005f90:	953e                	add	a0,a0,a5
  return irq;
}
    80005f92:	4148                	lw	a0,4(a0)
    80005f94:	60a2                	ld	ra,8(sp)
    80005f96:	6402                	ld	s0,0(sp)
    80005f98:	0141                	addi	sp,sp,16
    80005f9a:	8082                	ret

0000000080005f9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f9c:	1101                	addi	sp,sp,-32
    80005f9e:	ec06                	sd	ra,24(sp)
    80005fa0:	e822                	sd	s0,16(sp)
    80005fa2:	e426                	sd	s1,8(sp)
    80005fa4:	1000                	addi	s0,sp,32
    80005fa6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	ae6080e7          	jalr	-1306(ra) # 80001a8e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fb0:	00d5151b          	slliw	a0,a0,0xd
    80005fb4:	0c2017b7          	lui	a5,0xc201
    80005fb8:	97aa                	add	a5,a5,a0
    80005fba:	c3c4                	sw	s1,4(a5)
}
    80005fbc:	60e2                	ld	ra,24(sp)
    80005fbe:	6442                	ld	s0,16(sp)
    80005fc0:	64a2                	ld	s1,8(sp)
    80005fc2:	6105                	addi	sp,sp,32
    80005fc4:	8082                	ret

0000000080005fc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fc6:	1141                	addi	sp,sp,-16
    80005fc8:	e406                	sd	ra,8(sp)
    80005fca:	e022                	sd	s0,0(sp)
    80005fcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fce:	479d                	li	a5,7
    80005fd0:	04a7cc63          	blt	a5,a0,80006028 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005fd4:	0001d797          	auipc	a5,0x1d
    80005fd8:	d2478793          	addi	a5,a5,-732 # 80022cf8 <disk>
    80005fdc:	97aa                	add	a5,a5,a0
    80005fde:	0187c783          	lbu	a5,24(a5)
    80005fe2:	ebb9                	bnez	a5,80006038 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fe4:	00451613          	slli	a2,a0,0x4
    80005fe8:	0001d797          	auipc	a5,0x1d
    80005fec:	d1078793          	addi	a5,a5,-752 # 80022cf8 <disk>
    80005ff0:	6394                	ld	a3,0(a5)
    80005ff2:	96b2                	add	a3,a3,a2
    80005ff4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ff8:	6398                	ld	a4,0(a5)
    80005ffa:	9732                	add	a4,a4,a2
    80005ffc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006000:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006004:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006008:	953e                	add	a0,a0,a5
    8000600a:	4785                	li	a5,1
    8000600c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006010:	0001d517          	auipc	a0,0x1d
    80006014:	d0050513          	addi	a0,a0,-768 # 80022d10 <disk+0x18>
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	1ae080e7          	jalr	430(ra) # 800021c6 <wakeup>
}
    80006020:	60a2                	ld	ra,8(sp)
    80006022:	6402                	ld	s0,0(sp)
    80006024:	0141                	addi	sp,sp,16
    80006026:	8082                	ret
    panic("free_desc 1");
    80006028:	00003517          	auipc	a0,0x3
    8000602c:	80050513          	addi	a0,a0,-2048 # 80008828 <syscalls+0x300>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	61c080e7          	jalr	1564(ra) # 8000064c <panic>
    panic("free_desc 2");
    80006038:	00003517          	auipc	a0,0x3
    8000603c:	80050513          	addi	a0,a0,-2048 # 80008838 <syscalls+0x310>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	60c080e7          	jalr	1548(ra) # 8000064c <panic>

0000000080006048 <virtio_disk_init>:
{
    80006048:	1101                	addi	sp,sp,-32
    8000604a:	ec06                	sd	ra,24(sp)
    8000604c:	e822                	sd	s0,16(sp)
    8000604e:	e426                	sd	s1,8(sp)
    80006050:	e04a                	sd	s2,0(sp)
    80006052:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006054:	00002597          	auipc	a1,0x2
    80006058:	7f458593          	addi	a1,a1,2036 # 80008848 <syscalls+0x320>
    8000605c:	0001d517          	auipc	a0,0x1d
    80006060:	dc450513          	addi	a0,a0,-572 # 80022e20 <disk+0x128>
    80006064:	ffffb097          	auipc	ra,0xffffb
    80006068:	bf0080e7          	jalr	-1040(ra) # 80000c54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000606c:	100017b7          	lui	a5,0x10001
    80006070:	4398                	lw	a4,0(a5)
    80006072:	2701                	sext.w	a4,a4
    80006074:	747277b7          	lui	a5,0x74727
    80006078:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000607c:	14f71c63          	bne	a4,a5,800061d4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006080:	100017b7          	lui	a5,0x10001
    80006084:	43dc                	lw	a5,4(a5)
    80006086:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006088:	4709                	li	a4,2
    8000608a:	14e79563          	bne	a5,a4,800061d4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000608e:	100017b7          	lui	a5,0x10001
    80006092:	479c                	lw	a5,8(a5)
    80006094:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006096:	12e79f63          	bne	a5,a4,800061d4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000609a:	100017b7          	lui	a5,0x10001
    8000609e:	47d8                	lw	a4,12(a5)
    800060a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060a2:	554d47b7          	lui	a5,0x554d4
    800060a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060aa:	12f71563          	bne	a4,a5,800061d4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ae:	100017b7          	lui	a5,0x10001
    800060b2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b6:	4705                	li	a4,1
    800060b8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ba:	470d                	li	a4,3
    800060bc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060be:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060c0:	c7ffe737          	lui	a4,0xc7ffe
    800060c4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb927>
    800060c8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060ca:	2701                	sext.w	a4,a4
    800060cc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ce:	472d                	li	a4,11
    800060d0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800060d2:	5bbc                	lw	a5,112(a5)
    800060d4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800060d8:	8ba1                	andi	a5,a5,8
    800060da:	10078563          	beqz	a5,800061e4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060de:	100017b7          	lui	a5,0x10001
    800060e2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800060e6:	43fc                	lw	a5,68(a5)
    800060e8:	2781                	sext.w	a5,a5
    800060ea:	10079563          	bnez	a5,800061f4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060ee:	100017b7          	lui	a5,0x10001
    800060f2:	5bdc                	lw	a5,52(a5)
    800060f4:	2781                	sext.w	a5,a5
  if(max == 0)
    800060f6:	10078763          	beqz	a5,80006204 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800060fa:	471d                	li	a4,7
    800060fc:	10f77c63          	bgeu	a4,a5,80006214 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	af4080e7          	jalr	-1292(ra) # 80000bf4 <kalloc>
    80006108:	0001d497          	auipc	s1,0x1d
    8000610c:	bf048493          	addi	s1,s1,-1040 # 80022cf8 <disk>
    80006110:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006112:	ffffb097          	auipc	ra,0xffffb
    80006116:	ae2080e7          	jalr	-1310(ra) # 80000bf4 <kalloc>
    8000611a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000611c:	ffffb097          	auipc	ra,0xffffb
    80006120:	ad8080e7          	jalr	-1320(ra) # 80000bf4 <kalloc>
    80006124:	87aa                	mv	a5,a0
    80006126:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006128:	6088                	ld	a0,0(s1)
    8000612a:	cd6d                	beqz	a0,80006224 <virtio_disk_init+0x1dc>
    8000612c:	0001d717          	auipc	a4,0x1d
    80006130:	bd473703          	ld	a4,-1068(a4) # 80022d00 <disk+0x8>
    80006134:	cb65                	beqz	a4,80006224 <virtio_disk_init+0x1dc>
    80006136:	c7fd                	beqz	a5,80006224 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006138:	6605                	lui	a2,0x1
    8000613a:	4581                	li	a1,0
    8000613c:	ffffb097          	auipc	ra,0xffffb
    80006140:	ca4080e7          	jalr	-860(ra) # 80000de0 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006144:	0001d497          	auipc	s1,0x1d
    80006148:	bb448493          	addi	s1,s1,-1100 # 80022cf8 <disk>
    8000614c:	6605                	lui	a2,0x1
    8000614e:	4581                	li	a1,0
    80006150:	6488                	ld	a0,8(s1)
    80006152:	ffffb097          	auipc	ra,0xffffb
    80006156:	c8e080e7          	jalr	-882(ra) # 80000de0 <memset>
  memset(disk.used, 0, PGSIZE);
    8000615a:	6605                	lui	a2,0x1
    8000615c:	4581                	li	a1,0
    8000615e:	6888                	ld	a0,16(s1)
    80006160:	ffffb097          	auipc	ra,0xffffb
    80006164:	c80080e7          	jalr	-896(ra) # 80000de0 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006168:	100017b7          	lui	a5,0x10001
    8000616c:	4721                	li	a4,8
    8000616e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006170:	4098                	lw	a4,0(s1)
    80006172:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006176:	40d8                	lw	a4,4(s1)
    80006178:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000617c:	6498                	ld	a4,8(s1)
    8000617e:	0007069b          	sext.w	a3,a4
    80006182:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006186:	9701                	srai	a4,a4,0x20
    80006188:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000618c:	6898                	ld	a4,16(s1)
    8000618e:	0007069b          	sext.w	a3,a4
    80006192:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006196:	9701                	srai	a4,a4,0x20
    80006198:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000619c:	4705                	li	a4,1
    8000619e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800061a0:	00e48c23          	sb	a4,24(s1)
    800061a4:	00e48ca3          	sb	a4,25(s1)
    800061a8:	00e48d23          	sb	a4,26(s1)
    800061ac:	00e48da3          	sb	a4,27(s1)
    800061b0:	00e48e23          	sb	a4,28(s1)
    800061b4:	00e48ea3          	sb	a4,29(s1)
    800061b8:	00e48f23          	sb	a4,30(s1)
    800061bc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800061c0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800061c4:	0727a823          	sw	s2,112(a5)
}
    800061c8:	60e2                	ld	ra,24(sp)
    800061ca:	6442                	ld	s0,16(sp)
    800061cc:	64a2                	ld	s1,8(sp)
    800061ce:	6902                	ld	s2,0(sp)
    800061d0:	6105                	addi	sp,sp,32
    800061d2:	8082                	ret
    panic("could not find virtio disk");
    800061d4:	00002517          	auipc	a0,0x2
    800061d8:	68450513          	addi	a0,a0,1668 # 80008858 <syscalls+0x330>
    800061dc:	ffffa097          	auipc	ra,0xffffa
    800061e0:	470080e7          	jalr	1136(ra) # 8000064c <panic>
    panic("virtio disk FEATURES_OK unset");
    800061e4:	00002517          	auipc	a0,0x2
    800061e8:	69450513          	addi	a0,a0,1684 # 80008878 <syscalls+0x350>
    800061ec:	ffffa097          	auipc	ra,0xffffa
    800061f0:	460080e7          	jalr	1120(ra) # 8000064c <panic>
    panic("virtio disk should not be ready");
    800061f4:	00002517          	auipc	a0,0x2
    800061f8:	6a450513          	addi	a0,a0,1700 # 80008898 <syscalls+0x370>
    800061fc:	ffffa097          	auipc	ra,0xffffa
    80006200:	450080e7          	jalr	1104(ra) # 8000064c <panic>
    panic("virtio disk has no queue 0");
    80006204:	00002517          	auipc	a0,0x2
    80006208:	6b450513          	addi	a0,a0,1716 # 800088b8 <syscalls+0x390>
    8000620c:	ffffa097          	auipc	ra,0xffffa
    80006210:	440080e7          	jalr	1088(ra) # 8000064c <panic>
    panic("virtio disk max queue too short");
    80006214:	00002517          	auipc	a0,0x2
    80006218:	6c450513          	addi	a0,a0,1732 # 800088d8 <syscalls+0x3b0>
    8000621c:	ffffa097          	auipc	ra,0xffffa
    80006220:	430080e7          	jalr	1072(ra) # 8000064c <panic>
    panic("virtio disk kalloc");
    80006224:	00002517          	auipc	a0,0x2
    80006228:	6d450513          	addi	a0,a0,1748 # 800088f8 <syscalls+0x3d0>
    8000622c:	ffffa097          	auipc	ra,0xffffa
    80006230:	420080e7          	jalr	1056(ra) # 8000064c <panic>

0000000080006234 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006234:	7119                	addi	sp,sp,-128
    80006236:	fc86                	sd	ra,120(sp)
    80006238:	f8a2                	sd	s0,112(sp)
    8000623a:	f4a6                	sd	s1,104(sp)
    8000623c:	f0ca                	sd	s2,96(sp)
    8000623e:	ecce                	sd	s3,88(sp)
    80006240:	e8d2                	sd	s4,80(sp)
    80006242:	e4d6                	sd	s5,72(sp)
    80006244:	e0da                	sd	s6,64(sp)
    80006246:	fc5e                	sd	s7,56(sp)
    80006248:	f862                	sd	s8,48(sp)
    8000624a:	f466                	sd	s9,40(sp)
    8000624c:	f06a                	sd	s10,32(sp)
    8000624e:	ec6e                	sd	s11,24(sp)
    80006250:	0100                	addi	s0,sp,128
    80006252:	8aaa                	mv	s5,a0
    80006254:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006256:	00c52d03          	lw	s10,12(a0)
    8000625a:	001d1d1b          	slliw	s10,s10,0x1
    8000625e:	1d02                	slli	s10,s10,0x20
    80006260:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006264:	0001d517          	auipc	a0,0x1d
    80006268:	bbc50513          	addi	a0,a0,-1092 # 80022e20 <disk+0x128>
    8000626c:	ffffb097          	auipc	ra,0xffffb
    80006270:	a78080e7          	jalr	-1416(ra) # 80000ce4 <acquire>
  for(int i = 0; i < 3; i++){
    80006274:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006276:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006278:	0001db97          	auipc	s7,0x1d
    8000627c:	a80b8b93          	addi	s7,s7,-1408 # 80022cf8 <disk>
  for(int i = 0; i < 3; i++){
    80006280:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006282:	0001dc97          	auipc	s9,0x1d
    80006286:	b9ec8c93          	addi	s9,s9,-1122 # 80022e20 <disk+0x128>
    8000628a:	a08d                	j	800062ec <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000628c:	00fb8733          	add	a4,s7,a5
    80006290:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006294:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006296:	0207c563          	bltz	a5,800062c0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000629a:	2905                	addiw	s2,s2,1
    8000629c:	0611                	addi	a2,a2,4
    8000629e:	05690c63          	beq	s2,s6,800062f6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800062a2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800062a4:	0001d717          	auipc	a4,0x1d
    800062a8:	a5470713          	addi	a4,a4,-1452 # 80022cf8 <disk>
    800062ac:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800062ae:	01874683          	lbu	a3,24(a4)
    800062b2:	fee9                	bnez	a3,8000628c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800062b4:	2785                	addiw	a5,a5,1
    800062b6:	0705                	addi	a4,a4,1
    800062b8:	fe979be3          	bne	a5,s1,800062ae <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800062bc:	57fd                	li	a5,-1
    800062be:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800062c0:	01205d63          	blez	s2,800062da <virtio_disk_rw+0xa6>
    800062c4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800062c6:	000a2503          	lw	a0,0(s4)
    800062ca:	00000097          	auipc	ra,0x0
    800062ce:	cfc080e7          	jalr	-772(ra) # 80005fc6 <free_desc>
      for(int j = 0; j < i; j++)
    800062d2:	2d85                	addiw	s11,s11,1
    800062d4:	0a11                	addi	s4,s4,4
    800062d6:	ffb918e3          	bne	s2,s11,800062c6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062da:	85e6                	mv	a1,s9
    800062dc:	0001d517          	auipc	a0,0x1d
    800062e0:	a3450513          	addi	a0,a0,-1484 # 80022d10 <disk+0x18>
    800062e4:	ffffc097          	auipc	ra,0xffffc
    800062e8:	e7e080e7          	jalr	-386(ra) # 80002162 <sleep>
  for(int i = 0; i < 3; i++){
    800062ec:	f8040a13          	addi	s4,s0,-128
{
    800062f0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062f2:	894e                	mv	s2,s3
    800062f4:	b77d                	j	800062a2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062f6:	f8042583          	lw	a1,-128(s0)
    800062fa:	00a58793          	addi	a5,a1,10
    800062fe:	0792                	slli	a5,a5,0x4

  if(write)
    80006300:	0001d617          	auipc	a2,0x1d
    80006304:	9f860613          	addi	a2,a2,-1544 # 80022cf8 <disk>
    80006308:	00f60733          	add	a4,a2,a5
    8000630c:	018036b3          	snez	a3,s8
    80006310:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006312:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006316:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000631a:	f6078693          	addi	a3,a5,-160
    8000631e:	6218                	ld	a4,0(a2)
    80006320:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006322:	00878513          	addi	a0,a5,8
    80006326:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006328:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000632a:	6208                	ld	a0,0(a2)
    8000632c:	96aa                	add	a3,a3,a0
    8000632e:	4741                	li	a4,16
    80006330:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006332:	4705                	li	a4,1
    80006334:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006338:	f8442703          	lw	a4,-124(s0)
    8000633c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006340:	0712                	slli	a4,a4,0x4
    80006342:	953a                	add	a0,a0,a4
    80006344:	058a8693          	addi	a3,s5,88
    80006348:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000634a:	6208                	ld	a0,0(a2)
    8000634c:	972a                	add	a4,a4,a0
    8000634e:	40000693          	li	a3,1024
    80006352:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006354:	001c3c13          	seqz	s8,s8
    80006358:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000635a:	001c6c13          	ori	s8,s8,1
    8000635e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006362:	f8842603          	lw	a2,-120(s0)
    80006366:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000636a:	0001d697          	auipc	a3,0x1d
    8000636e:	98e68693          	addi	a3,a3,-1650 # 80022cf8 <disk>
    80006372:	00258713          	addi	a4,a1,2
    80006376:	0712                	slli	a4,a4,0x4
    80006378:	9736                	add	a4,a4,a3
    8000637a:	587d                	li	a6,-1
    8000637c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006380:	0612                	slli	a2,a2,0x4
    80006382:	9532                	add	a0,a0,a2
    80006384:	f9078793          	addi	a5,a5,-112
    80006388:	97b6                	add	a5,a5,a3
    8000638a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000638c:	629c                	ld	a5,0(a3)
    8000638e:	97b2                	add	a5,a5,a2
    80006390:	4605                	li	a2,1
    80006392:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006394:	4509                	li	a0,2
    80006396:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000639a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000639e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800063a2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800063a6:	6698                	ld	a4,8(a3)
    800063a8:	00275783          	lhu	a5,2(a4)
    800063ac:	8b9d                	andi	a5,a5,7
    800063ae:	0786                	slli	a5,a5,0x1
    800063b0:	97ba                	add	a5,a5,a4
    800063b2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800063b6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800063ba:	6698                	ld	a4,8(a3)
    800063bc:	00275783          	lhu	a5,2(a4)
    800063c0:	2785                	addiw	a5,a5,1
    800063c2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800063c6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063ca:	100017b7          	lui	a5,0x10001
    800063ce:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063d2:	004aa783          	lw	a5,4(s5)
    800063d6:	02c79163          	bne	a5,a2,800063f8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800063da:	0001d917          	auipc	s2,0x1d
    800063de:	a4690913          	addi	s2,s2,-1466 # 80022e20 <disk+0x128>
  while(b->disk == 1) {
    800063e2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063e4:	85ca                	mv	a1,s2
    800063e6:	8556                	mv	a0,s5
    800063e8:	ffffc097          	auipc	ra,0xffffc
    800063ec:	d7a080e7          	jalr	-646(ra) # 80002162 <sleep>
  while(b->disk == 1) {
    800063f0:	004aa783          	lw	a5,4(s5)
    800063f4:	fe9788e3          	beq	a5,s1,800063e4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800063f8:	f8042903          	lw	s2,-128(s0)
    800063fc:	00290793          	addi	a5,s2,2
    80006400:	00479713          	slli	a4,a5,0x4
    80006404:	0001d797          	auipc	a5,0x1d
    80006408:	8f478793          	addi	a5,a5,-1804 # 80022cf8 <disk>
    8000640c:	97ba                	add	a5,a5,a4
    8000640e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006412:	0001d997          	auipc	s3,0x1d
    80006416:	8e698993          	addi	s3,s3,-1818 # 80022cf8 <disk>
    8000641a:	00491713          	slli	a4,s2,0x4
    8000641e:	0009b783          	ld	a5,0(s3)
    80006422:	97ba                	add	a5,a5,a4
    80006424:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006428:	854a                	mv	a0,s2
    8000642a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000642e:	00000097          	auipc	ra,0x0
    80006432:	b98080e7          	jalr	-1128(ra) # 80005fc6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006436:	8885                	andi	s1,s1,1
    80006438:	f0ed                	bnez	s1,8000641a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000643a:	0001d517          	auipc	a0,0x1d
    8000643e:	9e650513          	addi	a0,a0,-1562 # 80022e20 <disk+0x128>
    80006442:	ffffb097          	auipc	ra,0xffffb
    80006446:	956080e7          	jalr	-1706(ra) # 80000d98 <release>
}
    8000644a:	70e6                	ld	ra,120(sp)
    8000644c:	7446                	ld	s0,112(sp)
    8000644e:	74a6                	ld	s1,104(sp)
    80006450:	7906                	ld	s2,96(sp)
    80006452:	69e6                	ld	s3,88(sp)
    80006454:	6a46                	ld	s4,80(sp)
    80006456:	6aa6                	ld	s5,72(sp)
    80006458:	6b06                	ld	s6,64(sp)
    8000645a:	7be2                	ld	s7,56(sp)
    8000645c:	7c42                	ld	s8,48(sp)
    8000645e:	7ca2                	ld	s9,40(sp)
    80006460:	7d02                	ld	s10,32(sp)
    80006462:	6de2                	ld	s11,24(sp)
    80006464:	6109                	addi	sp,sp,128
    80006466:	8082                	ret

0000000080006468 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006468:	1101                	addi	sp,sp,-32
    8000646a:	ec06                	sd	ra,24(sp)
    8000646c:	e822                	sd	s0,16(sp)
    8000646e:	e426                	sd	s1,8(sp)
    80006470:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006472:	0001d497          	auipc	s1,0x1d
    80006476:	88648493          	addi	s1,s1,-1914 # 80022cf8 <disk>
    8000647a:	0001d517          	auipc	a0,0x1d
    8000647e:	9a650513          	addi	a0,a0,-1626 # 80022e20 <disk+0x128>
    80006482:	ffffb097          	auipc	ra,0xffffb
    80006486:	862080e7          	jalr	-1950(ra) # 80000ce4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000648a:	10001737          	lui	a4,0x10001
    8000648e:	533c                	lw	a5,96(a4)
    80006490:	8b8d                	andi	a5,a5,3
    80006492:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006494:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006498:	689c                	ld	a5,16(s1)
    8000649a:	0204d703          	lhu	a4,32(s1)
    8000649e:	0027d783          	lhu	a5,2(a5)
    800064a2:	04f70863          	beq	a4,a5,800064f2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800064a6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064aa:	6898                	ld	a4,16(s1)
    800064ac:	0204d783          	lhu	a5,32(s1)
    800064b0:	8b9d                	andi	a5,a5,7
    800064b2:	078e                	slli	a5,a5,0x3
    800064b4:	97ba                	add	a5,a5,a4
    800064b6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064b8:	00278713          	addi	a4,a5,2
    800064bc:	0712                	slli	a4,a4,0x4
    800064be:	9726                	add	a4,a4,s1
    800064c0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800064c4:	e721                	bnez	a4,8000650c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064c6:	0789                	addi	a5,a5,2
    800064c8:	0792                	slli	a5,a5,0x4
    800064ca:	97a6                	add	a5,a5,s1
    800064cc:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800064ce:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064d2:	ffffc097          	auipc	ra,0xffffc
    800064d6:	cf4080e7          	jalr	-780(ra) # 800021c6 <wakeup>

    disk.used_idx += 1;
    800064da:	0204d783          	lhu	a5,32(s1)
    800064de:	2785                	addiw	a5,a5,1
    800064e0:	17c2                	slli	a5,a5,0x30
    800064e2:	93c1                	srli	a5,a5,0x30
    800064e4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064e8:	6898                	ld	a4,16(s1)
    800064ea:	00275703          	lhu	a4,2(a4)
    800064ee:	faf71ce3          	bne	a4,a5,800064a6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800064f2:	0001d517          	auipc	a0,0x1d
    800064f6:	92e50513          	addi	a0,a0,-1746 # 80022e20 <disk+0x128>
    800064fa:	ffffb097          	auipc	ra,0xffffb
    800064fe:	89e080e7          	jalr	-1890(ra) # 80000d98 <release>
}
    80006502:	60e2                	ld	ra,24(sp)
    80006504:	6442                	ld	s0,16(sp)
    80006506:	64a2                	ld	s1,8(sp)
    80006508:	6105                	addi	sp,sp,32
    8000650a:	8082                	ret
      panic("virtio_disk_intr status");
    8000650c:	00002517          	auipc	a0,0x2
    80006510:	40450513          	addi	a0,a0,1028 # 80008910 <syscalls+0x3e8>
    80006514:	ffffa097          	auipc	ra,0xffffa
    80006518:	138080e7          	jalr	312(ra) # 8000064c <panic>
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
