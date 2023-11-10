
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b1010113          	addi	sp,sp,-1264 # 80008b10 <stack0>
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
    80000056:	97e70713          	addi	a4,a4,-1666 # 800089d0 <timer_scratch>
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
    80000068:	fcc78793          	addi	a5,a5,-52 # 80006030 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb9b7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	00c78793          	addi	a5,a5,12 # 800010ba <main>
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
    80000130:	5c8080e7          	jalr	1480(ra) # 800026f4 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00001097          	auipc	ra,0x1
    80000140:	9c2080e7          	jalr	-1598(ra) # 80000afe <uartputc>
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
    8000018e:	98650513          	addi	a0,a0,-1658 # 80010b10 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	c86080e7          	jalr	-890(ra) # 80000e18 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	97648493          	addi	s1,s1,-1674 # 80010b10 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a0690913          	addi	s2,s2,-1530 # 80010ba8 <cons+0x98>
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
    800001c4:	a2e080e7          	jalr	-1490(ra) # 80001bee <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	376080e7          	jalr	886(ra) # 8000253e <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	0c0080e7          	jalr	192(ra) # 80002296 <sleep>
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
    80000216:	48c080e7          	jalr	1164(ra) # 8000269e <either_copyout>
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
    8000022a:	8ea50513          	addi	a0,a0,-1814 # 80010b10 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	c9e080e7          	jalr	-866(ra) # 80000ecc <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	8d450513          	addi	a0,a0,-1836 # 80010b10 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	c88080e7          	jalr	-888(ra) # 80000ecc <release>
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
    80000276:	92f72b23          	sw	a5,-1738(a4) # 80010ba8 <cons+0x98>
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
    if(historyBuf.lastCommandIndex == 15)
    8000028e:	00011717          	auipc	a4,0x11
    80000292:	16a72703          	lw	a4,362(a4) # 800113f8 <historyBuf+0x840>
    80000296:	47bd                	li	a5,15
    80000298:	08f70663          	beq	a4,a5,80000324 <call_sys_history+0x9c>
    for (int i = 0; historyBuf.current_cm[i] != '\n' ; ++i) {
    8000029c:	00011717          	auipc	a4,0x11
    800002a0:	16874703          	lbu	a4,360(a4) # 80011404 <historyBuf+0x84c>
    800002a4:	47a9                	li	a5,10
    800002a6:	08f70463          	beq	a4,a5,8000032e <call_sys_history+0xa6>
    800002aa:	00011717          	auipc	a4,0x11
    800002ae:	15b70713          	addi	a4,a4,347 # 80011405 <historyBuf+0x84d>
    int size = 0;
    800002b2:	4781                	li	a5,0
    for (int i = 0; historyBuf.current_cm[i] != '\n' ; ++i) {
    800002b4:	45a9                	li	a1,10
        size++;
    800002b6:	86be                	mv	a3,a5
    800002b8:	2785                	addiw	a5,a5,1
    for (int i = 0; historyBuf.current_cm[i] != '\n' ; ++i) {
    800002ba:	0705                	addi	a4,a4,1
    800002bc:	fff74603          	lbu	a2,-1(a4)
    800002c0:	feb61be3          	bne	a2,a1,800002b6 <call_sys_history+0x2e>
    historyBuf.lengthsArr[row] = size;
    800002c4:	00008817          	auipc	a6,0x8
    800002c8:	6c482803          	lw	a6,1732(a6) # 80008988 <row>
    800002cc:	20080713          	addi	a4,a6,512
    800002d0:	00271613          	slli	a2,a4,0x2
    800002d4:	00011717          	auipc	a4,0x11
    800002d8:	8e470713          	addi	a4,a4,-1820 # 80010bb8 <historyBuf>
    800002dc:	9732                	add	a4,a4,a2
    800002de:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < size ; i++) {
    800002e0:	02f05a63          	blez	a5,80000314 <call_sys_history+0x8c>
    800002e4:	00011517          	auipc	a0,0x11
    800002e8:	12050513          	addi	a0,a0,288 # 80011404 <historyBuf+0x84c>
    800002ec:	00781593          	slli	a1,a6,0x7
    800002f0:	87aa                	mv	a5,a0
        historyBuf.bufferArr[row][i]= historyBuf.current_cm[i];
    800002f2:	777d                	lui	a4,0xfffff
    800002f4:	7b470713          	addi	a4,a4,1972 # fffffffffffff7b4 <end+0xffffffff7ffdc96c>
    800002f8:	95ba                	add	a1,a1,a4
    for (int i = 0; i < size ; i++) {
    800002fa:	fff54513          	not	a0,a0
        historyBuf.bufferArr[row][i]= historyBuf.current_cm[i];
    800002fe:	0007c603          	lbu	a2,0(a5) # 10000 <_entry-0x7fff0000>
    80000302:	00b78733          	add	a4,a5,a1
    80000306:	00c70023          	sb	a2,0(a4)
    for (int i = 0; i < size ; i++) {
    8000030a:	0785                	addi	a5,a5,1
    8000030c:	00f5073b          	addw	a4,a0,a5
    80000310:	fed747e3          	blt	a4,a3,800002fe <call_sys_history+0x76>
    row++;
    80000314:	2805                	addiw	a6,a6,1
    80000316:	00008797          	auipc	a5,0x8
    8000031a:	6707a923          	sw	a6,1650(a5) # 80008988 <row>
}
    8000031e:	6422                	ld	s0,8(sp)
    80000320:	0141                	addi	sp,sp,16
    80000322:	8082                	ret
        historyBuf.lastCommandIndex = 0;
    80000324:	00011797          	auipc	a5,0x11
    80000328:	0c07aa23          	sw	zero,212(a5) # 800113f8 <historyBuf+0x840>
    8000032c:	bf85                	j	8000029c <call_sys_history+0x14>
    historyBuf.lengthsArr[row] = size;
    8000032e:	00008817          	auipc	a6,0x8
    80000332:	65a82803          	lw	a6,1626(a6) # 80008988 <row>
    80000336:	20080793          	addi	a5,a6,512
    8000033a:	00279713          	slli	a4,a5,0x2
    8000033e:	00011797          	auipc	a5,0x11
    80000342:	87a78793          	addi	a5,a5,-1926 # 80010bb8 <historyBuf>
    80000346:	97ba                	add	a5,a5,a4
    80000348:	0007a023          	sw	zero,0(a5)
    for (int i = 0; i < size ; i++) {
    8000034c:	b7e1                	j	80000314 <call_sys_history+0x8c>

000000008000034e <consputc>:
{
    8000034e:	1141                	addi	sp,sp,-16
    80000350:	e406                	sd	ra,8(sp)
    80000352:	e022                	sd	s0,0(sp)
    80000354:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000356:	10000793          	li	a5,256
    8000035a:	00f50a63          	beq	a0,a5,8000036e <consputc+0x20>
    uartputc_sync(c);
    8000035e:	00000097          	auipc	ra,0x0
    80000362:	6ce080e7          	jalr	1742(ra) # 80000a2c <uartputc_sync>
}
    80000366:	60a2                	ld	ra,8(sp)
    80000368:	6402                	ld	s0,0(sp)
    8000036a:	0141                	addi	sp,sp,16
    8000036c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000036e:	4521                	li	a0,8
    80000370:	00000097          	auipc	ra,0x0
    80000374:	6bc080e7          	jalr	1724(ra) # 80000a2c <uartputc_sync>
    80000378:	02000513          	li	a0,32
    8000037c:	00000097          	auipc	ra,0x0
    80000380:	6b0080e7          	jalr	1712(ra) # 80000a2c <uartputc_sync>
    80000384:	4521                	li	a0,8
    80000386:	00000097          	auipc	ra,0x0
    8000038a:	6a6080e7          	jalr	1702(ra) # 80000a2c <uartputc_sync>
    8000038e:	bfe1                	j	80000366 <consputc+0x18>

0000000080000390 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    80000390:	7179                	addi	sp,sp,-48
    80000392:	f406                	sd	ra,40(sp)
    80000394:	f022                	sd	s0,32(sp)
    80000396:	ec26                	sd	s1,24(sp)
    80000398:	e84a                	sd	s2,16(sp)
    8000039a:	e44e                	sd	s3,8(sp)
    8000039c:	1800                	addi	s0,sp,48
    8000039e:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800003a0:	00010517          	auipc	a0,0x10
    800003a4:	77050513          	addi	a0,a0,1904 # 80010b10 <cons>
    800003a8:	00001097          	auipc	ra,0x1
    800003ac:	a70080e7          	jalr	-1424(ra) # 80000e18 <acquire>



  switch(c){
    800003b0:	47d5                	li	a5,21
    800003b2:	0ef48163          	beq	s1,a5,80000494 <consoleintr+0x104>
    800003b6:	0297cb63          	blt	a5,s1,800003ec <consoleintr+0x5c>
    800003ba:	47a1                	li	a5,8
    800003bc:	12f48263          	beq	s1,a5,800004e0 <consoleintr+0x150>
    800003c0:	47c1                	li	a5,16
    800003c2:	04f49163          	bne	s1,a5,80000404 <consoleintr+0x74>
  case C('P'):  // Print process list.
    procdump();
    800003c6:	00002097          	auipc	ra,0x2
    800003ca:	384080e7          	jalr	900(ra) # 8000274a <procdump>




  
  release(&cons.lock);
    800003ce:	00010517          	auipc	a0,0x10
    800003d2:	74250513          	addi	a0,a0,1858 # 80010b10 <cons>
    800003d6:	00001097          	auipc	ra,0x1
    800003da:	af6080e7          	jalr	-1290(ra) # 80000ecc <release>
  //  printf(cons.w);
}
    800003de:	70a2                	ld	ra,40(sp)
    800003e0:	7402                	ld	s0,32(sp)
    800003e2:	64e2                	ld	s1,24(sp)
    800003e4:	6942                	ld	s2,16(sp)
    800003e6:	69a2                	ld	s3,8(sp)
    800003e8:	6145                	addi	sp,sp,48
    800003ea:	8082                	ret
  switch(c){
    800003ec:	07f00793          	li	a5,127
    800003f0:	0ef48863          	beq	s1,a5,800004e0 <consoleintr+0x150>
      if(c == '\x41'){
    800003f4:	04100793          	li	a5,65
    800003f8:	12f48163          	beq	s1,a5,8000051a <consoleintr+0x18a>
          else if(c == '\x42'){
    800003fc:	04200793          	li	a5,66
    80000400:	18f48763          	beq	s1,a5,8000058e <consoleintr+0x1fe>
    else if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000404:	d4e9                	beqz	s1,800003ce <consoleintr+0x3e>
    80000406:	00010717          	auipc	a4,0x10
    8000040a:	70a70713          	addi	a4,a4,1802 # 80010b10 <cons>
    8000040e:	0a072783          	lw	a5,160(a4)
    80000412:	09872703          	lw	a4,152(a4)
    80000416:	9f99                	subw	a5,a5,a4
    80000418:	07f00713          	li	a4,127
    8000041c:	faf769e3          	bltu	a4,a5,800003ce <consoleintr+0x3e>
      c = (c == '\r') ? '\n' : c;
    80000420:	47b5                	li	a5,13
    80000422:	1ef48063          	beq	s1,a5,80000602 <consoleintr+0x272>
      historyBuf.current_cm[index] = c;
    80000426:	00008617          	auipc	a2,0x8
    8000042a:	56660613          	addi	a2,a2,1382 # 8000898c <index>
    8000042e:	421c                	lw	a5,0(a2)
    80000430:	0ff4f913          	andi	s2,s1,255
    80000434:	00010717          	auipc	a4,0x10
    80000438:	78470713          	addi	a4,a4,1924 # 80010bb8 <historyBuf>
    8000043c:	00f706b3          	add	a3,a4,a5
    80000440:	6705                	lui	a4,0x1
    80000442:	9736                	add	a4,a4,a3
    80000444:	85270623          	sb	s2,-1972(a4) # 84c <_entry-0x7ffff7b4>
      index++;
    80000448:	2785                	addiw	a5,a5,1
    8000044a:	c21c                	sw	a5,0(a2)
      consputc(c);
    8000044c:	8526                	mv	a0,s1
    8000044e:	00000097          	auipc	ra,0x0
    80000452:	f00080e7          	jalr	-256(ra) # 8000034e <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000456:	00010797          	auipc	a5,0x10
    8000045a:	6ba78793          	addi	a5,a5,1722 # 80010b10 <cons>
    8000045e:	0a07a703          	lw	a4,160(a5)
    80000462:	0017069b          	addiw	a3,a4,1
    80000466:	0ad7a023          	sw	a3,160(a5)
    8000046a:	07f77713          	andi	a4,a4,127
    8000046e:	97ba                	add	a5,a5,a4
    80000470:	01278c23          	sb	s2,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000474:	47a9                	li	a5,10
    80000476:	1cf48c63          	beq	s1,a5,8000064e <consoleintr+0x2be>
    8000047a:	4791                	li	a5,4
    8000047c:	1cf48963          	beq	s1,a5,8000064e <consoleintr+0x2be>
    80000480:	00010797          	auipc	a5,0x10
    80000484:	7287a783          	lw	a5,1832(a5) # 80010ba8 <cons+0x98>
    80000488:	9e9d                	subw	a3,a3,a5
    8000048a:	08000793          	li	a5,128
    8000048e:	f4f690e3          	bne	a3,a5,800003ce <consoleintr+0x3e>
    80000492:	aa75                	j	8000064e <consoleintr+0x2be>
    while(cons.e != cons.w &&
    80000494:	00010717          	auipc	a4,0x10
    80000498:	67c70713          	addi	a4,a4,1660 # 80010b10 <cons>
    8000049c:	0a072783          	lw	a5,160(a4)
    800004a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800004a4:	00010497          	auipc	s1,0x10
    800004a8:	66c48493          	addi	s1,s1,1644 # 80010b10 <cons>
    while(cons.e != cons.w &&
    800004ac:	4929                	li	s2,10
    800004ae:	f2f700e3          	beq	a4,a5,800003ce <consoleintr+0x3e>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800004b2:	37fd                	addiw	a5,a5,-1
    800004b4:	07f7f713          	andi	a4,a5,127
    800004b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800004ba:	01874703          	lbu	a4,24(a4)
    800004be:	f12708e3          	beq	a4,s2,800003ce <consoleintr+0x3e>
      cons.e--;
    800004c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800004c6:	10000513          	li	a0,256
    800004ca:	00000097          	auipc	ra,0x0
    800004ce:	e84080e7          	jalr	-380(ra) # 8000034e <consputc>
    while(cons.e != cons.w &&
    800004d2:	0a04a783          	lw	a5,160(s1)
    800004d6:	09c4a703          	lw	a4,156(s1)
    800004da:	fcf71ce3          	bne	a4,a5,800004b2 <consoleintr+0x122>
    800004de:	bdc5                	j	800003ce <consoleintr+0x3e>
    index--;
    800004e0:	00008717          	auipc	a4,0x8
    800004e4:	4ac70713          	addi	a4,a4,1196 # 8000898c <index>
    800004e8:	431c                	lw	a5,0(a4)
    800004ea:	37fd                	addiw	a5,a5,-1
    800004ec:	c31c                	sw	a5,0(a4)
    if(cons.e != cons.w){
    800004ee:	00010717          	auipc	a4,0x10
    800004f2:	62270713          	addi	a4,a4,1570 # 80010b10 <cons>
    800004f6:	0a072783          	lw	a5,160(a4)
    800004fa:	09c72703          	lw	a4,156(a4)
    800004fe:	ecf708e3          	beq	a4,a5,800003ce <consoleintr+0x3e>
      cons.e--;
    80000502:	37fd                	addiw	a5,a5,-1
    80000504:	00010717          	auipc	a4,0x10
    80000508:	6af72623          	sw	a5,1708(a4) # 80010bb0 <cons+0xa0>
      consputc(BACKSPACE);
    8000050c:	10000513          	li	a0,256
    80000510:	00000097          	auipc	ra,0x0
    80000514:	e3e080e7          	jalr	-450(ra) # 8000034e <consputc>
    80000518:	bd5d                	j	800003ce <consoleintr+0x3e>
          last_com = (historyBuf.lastCommandIndex - 1);
    8000051a:	00011717          	auipc	a4,0x11
    8000051e:	ede72703          	lw	a4,-290(a4) # 800113f8 <historyBuf+0x840>
    80000522:	377d                	addiw	a4,a4,-1
    80000524:	0007079b          	sext.w	a5,a4
    80000528:	00008697          	auipc	a3,0x8
    8000052c:	44e6ae23          	sw	a4,1116(a3) # 80008984 <last_com>
          for (int i = 0; i < historyBuf.lengthsArr[last_com]; i++) {
    80000530:	1702                	slli	a4,a4,0x20
    80000532:	9301                	srli	a4,a4,0x20
    80000534:	20070713          	addi	a4,a4,512
    80000538:	070a                	slli	a4,a4,0x2
    8000053a:	00010697          	auipc	a3,0x10
    8000053e:	67e68693          	addi	a3,a3,1662 # 80010bb8 <historyBuf>
    80000542:	9736                	add	a4,a4,a3
    80000544:	4318                	lw	a4,0(a4)
    80000546:	e80704e3          	beqz	a4,800003ce <consoleintr+0x3e>
    8000054a:	4481                	li	s1,0
              consputc(historyBuf.bufferArr[last_com][i]);
    8000054c:	8936                	mv	s2,a3
          for (int i = 0; i < historyBuf.lengthsArr[last_com]; i++) {
    8000054e:	00008997          	auipc	s3,0x8
    80000552:	43698993          	addi	s3,s3,1078 # 80008984 <last_com>
              consputc(historyBuf.bufferArr[last_com][i]);
    80000556:	1782                	slli	a5,a5,0x20
    80000558:	9381                	srli	a5,a5,0x20
    8000055a:	079e                	slli	a5,a5,0x7
    8000055c:	97ca                	add	a5,a5,s2
    8000055e:	97a6                	add	a5,a5,s1
    80000560:	0007c503          	lbu	a0,0(a5)
    80000564:	00000097          	auipc	ra,0x0
    80000568:	dea080e7          	jalr	-534(ra) # 8000034e <consputc>
          for (int i = 0; i < historyBuf.lengthsArr[last_com]; i++) {
    8000056c:	0014869b          	addiw	a3,s1,1
    80000570:	0006849b          	sext.w	s1,a3
    80000574:	0009a783          	lw	a5,0(s3)
    80000578:	02079713          	slli	a4,a5,0x20
    8000057c:	9301                	srli	a4,a4,0x20
    8000057e:	20070713          	addi	a4,a4,512
    80000582:	070a                	slli	a4,a4,0x2
    80000584:	974a                	add	a4,a4,s2
    80000586:	4318                	lw	a4,0(a4)
    80000588:	fce4e7e3          	bltu	s1,a4,80000556 <consoleintr+0x1c6>
    8000058c:	b589                	j	800003ce <consoleintr+0x3e>
            next_com = historyBuf.lastCommandIndex + 2;
    8000058e:	00011717          	auipc	a4,0x11
    80000592:	e6a72703          	lw	a4,-406(a4) # 800113f8 <historyBuf+0x840>
    80000596:	2709                	addiw	a4,a4,2
    80000598:	0007079b          	sext.w	a5,a4
    8000059c:	00008697          	auipc	a3,0x8
    800005a0:	3ee6a223          	sw	a4,996(a3) # 80008980 <next_com>
              for (int i = 0; i < historyBuf.lengthsArr[next_com]; i++) {
    800005a4:	1702                	slli	a4,a4,0x20
    800005a6:	9301                	srli	a4,a4,0x20
    800005a8:	20070713          	addi	a4,a4,512
    800005ac:	070a                	slli	a4,a4,0x2
    800005ae:	00010697          	auipc	a3,0x10
    800005b2:	60a68693          	addi	a3,a3,1546 # 80010bb8 <historyBuf>
    800005b6:	9736                	add	a4,a4,a3
    800005b8:	4318                	lw	a4,0(a4)
    800005ba:	e0070ae3          	beqz	a4,800003ce <consoleintr+0x3e>
    800005be:	4481                	li	s1,0
                  consputc(historyBuf.bufferArr[next_com][i]);
    800005c0:	8936                	mv	s2,a3
              for (int i = 0; i < historyBuf.lengthsArr[next_com]; i++) {
    800005c2:	00008997          	auipc	s3,0x8
    800005c6:	3be98993          	addi	s3,s3,958 # 80008980 <next_com>
                  consputc(historyBuf.bufferArr[next_com][i]);
    800005ca:	1782                	slli	a5,a5,0x20
    800005cc:	9381                	srli	a5,a5,0x20
    800005ce:	079e                	slli	a5,a5,0x7
    800005d0:	97ca                	add	a5,a5,s2
    800005d2:	97a6                	add	a5,a5,s1
    800005d4:	0007c503          	lbu	a0,0(a5)
    800005d8:	00000097          	auipc	ra,0x0
    800005dc:	d76080e7          	jalr	-650(ra) # 8000034e <consputc>
              for (int i = 0; i < historyBuf.lengthsArr[next_com]; i++) {
    800005e0:	0014869b          	addiw	a3,s1,1
    800005e4:	0006849b          	sext.w	s1,a3
    800005e8:	0009a783          	lw	a5,0(s3)
    800005ec:	02079713          	slli	a4,a5,0x20
    800005f0:	9301                	srli	a4,a4,0x20
    800005f2:	20070713          	addi	a4,a4,512
    800005f6:	070a                	slli	a4,a4,0x2
    800005f8:	974a                	add	a4,a4,s2
    800005fa:	4318                	lw	a4,0(a4)
    800005fc:	fce4e7e3          	bltu	s1,a4,800005ca <consoleintr+0x23a>
    80000600:	b3f9                	j	800003ce <consoleintr+0x3e>
      historyBuf.current_cm[index] = c;
    80000602:	00008617          	auipc	a2,0x8
    80000606:	38a60613          	addi	a2,a2,906 # 8000898c <index>
    8000060a:	421c                	lw	a5,0(a2)
    8000060c:	00010717          	auipc	a4,0x10
    80000610:	5ac70713          	addi	a4,a4,1452 # 80010bb8 <historyBuf>
    80000614:	00f706b3          	add	a3,a4,a5
    80000618:	6705                	lui	a4,0x1
    8000061a:	9736                	add	a4,a4,a3
    8000061c:	44a9                	li	s1,10
    8000061e:	84970623          	sb	s1,-1972(a4) # 84c <_entry-0x7ffff7b4>
      index++;
    80000622:	2785                	addiw	a5,a5,1
    80000624:	c21c                	sw	a5,0(a2)
      consputc(c);
    80000626:	4529                	li	a0,10
    80000628:	00000097          	auipc	ra,0x0
    8000062c:	d26080e7          	jalr	-730(ra) # 8000034e <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000630:	00010797          	auipc	a5,0x10
    80000634:	4e078793          	addi	a5,a5,1248 # 80010b10 <cons>
    80000638:	0a07a703          	lw	a4,160(a5)
    8000063c:	0017069b          	addiw	a3,a4,1
    80000640:	0ad7a023          	sw	a3,160(a5)
    80000644:	07f77713          	andi	a4,a4,127
    80000648:	97ba                	add	a5,a5,a4
    8000064a:	00978c23          	sb	s1,24(a5)
        index = 0;
    8000064e:	00008797          	auipc	a5,0x8
    80000652:	3207af23          	sw	zero,830(a5) # 8000898c <index>
        call_sys_history();
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	c32080e7          	jalr	-974(ra) # 80000288 <call_sys_history>
        historyBuf.lastCommandIndex++;
    8000065e:	00011717          	auipc	a4,0x11
    80000662:	55a70713          	addi	a4,a4,1370 # 80011bb8 <topp+0x288>
    80000666:	84072783          	lw	a5,-1984(a4)
    8000066a:	2785                	addiw	a5,a5,1
    8000066c:	84f72023          	sw	a5,-1984(a4)
        cons.w = cons.e;
    80000670:	00010797          	auipc	a5,0x10
    80000674:	4a078793          	addi	a5,a5,1184 # 80010b10 <cons>
    80000678:	0a07a703          	lw	a4,160(a5)
    8000067c:	08e7ae23          	sw	a4,156(a5)
        wakeup(&cons.r);
    80000680:	00010517          	auipc	a0,0x10
    80000684:	52850513          	addi	a0,a0,1320 # 80010ba8 <cons+0x98>
    80000688:	00002097          	auipc	ra,0x2
    8000068c:	c72080e7          	jalr	-910(ra) # 800022fa <wakeup>
    80000690:	bb3d                	j	800003ce <consoleintr+0x3e>

0000000080000692 <consoleinit>:

void
consoleinit(void)
{
    80000692:	1141                	addi	sp,sp,-16
    80000694:	e406                	sd	ra,8(sp)
    80000696:	e022                	sd	s0,0(sp)
    80000698:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000069a:	00008597          	auipc	a1,0x8
    8000069e:	97658593          	addi	a1,a1,-1674 # 80008010 <etext+0x10>
    800006a2:	00010517          	auipc	a0,0x10
    800006a6:	46e50513          	addi	a0,a0,1134 # 80010b10 <cons>
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	6de080e7          	jalr	1758(ra) # 80000d88 <initlock>

  uartinit();
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	32a080e7          	jalr	810(ra) # 800009dc <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    800006ba:	00021797          	auipc	a5,0x21
    800006be:	5f678793          	addi	a5,a5,1526 # 80021cb0 <devsw>
    800006c2:	00000717          	auipc	a4,0x0
    800006c6:	aa270713          	addi	a4,a4,-1374 # 80000164 <consoleread>
    800006ca:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800006cc:	00000717          	auipc	a4,0x0
    800006d0:	a3670713          	addi	a4,a4,-1482 # 80000102 <consolewrite>
    800006d4:	ef98                	sd	a4,24(a5)
}
    800006d6:	60a2                	ld	ra,8(sp)
    800006d8:	6402                	ld	s0,0(sp)
    800006da:	0141                	addi	sp,sp,16
    800006dc:	8082                	ret

00000000800006de <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800006de:	7179                	addi	sp,sp,-48
    800006e0:	f406                	sd	ra,40(sp)
    800006e2:	f022                	sd	s0,32(sp)
    800006e4:	ec26                	sd	s1,24(sp)
    800006e6:	e84a                	sd	s2,16(sp)
    800006e8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800006ea:	c219                	beqz	a2,800006f0 <printint+0x12>
    800006ec:	08054663          	bltz	a0,80000778 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800006f0:	2501                	sext.w	a0,a0
    800006f2:	4881                	li	a7,0
    800006f4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800006f8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800006fa:	2581                	sext.w	a1,a1
    800006fc:	00008617          	auipc	a2,0x8
    80000700:	94460613          	addi	a2,a2,-1724 # 80008040 <digits>
    80000704:	883a                	mv	a6,a4
    80000706:	2705                	addiw	a4,a4,1
    80000708:	02b577bb          	remuw	a5,a0,a1
    8000070c:	1782                	slli	a5,a5,0x20
    8000070e:	9381                	srli	a5,a5,0x20
    80000710:	97b2                	add	a5,a5,a2
    80000712:	0007c783          	lbu	a5,0(a5)
    80000716:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    8000071a:	0005079b          	sext.w	a5,a0
    8000071e:	02b5553b          	divuw	a0,a0,a1
    80000722:	0685                	addi	a3,a3,1
    80000724:	feb7f0e3          	bgeu	a5,a1,80000704 <printint+0x26>

  if(sign)
    80000728:	00088b63          	beqz	a7,8000073e <printint+0x60>
    buf[i++] = '-';
    8000072c:	fe040793          	addi	a5,s0,-32
    80000730:	973e                	add	a4,a4,a5
    80000732:	02d00793          	li	a5,45
    80000736:	fef70823          	sb	a5,-16(a4)
    8000073a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000073e:	02e05763          	blez	a4,8000076c <printint+0x8e>
    80000742:	fd040793          	addi	a5,s0,-48
    80000746:	00e784b3          	add	s1,a5,a4
    8000074a:	fff78913          	addi	s2,a5,-1
    8000074e:	993a                	add	s2,s2,a4
    80000750:	377d                	addiw	a4,a4,-1
    80000752:	1702                	slli	a4,a4,0x20
    80000754:	9301                	srli	a4,a4,0x20
    80000756:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000075a:	fff4c503          	lbu	a0,-1(s1)
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	bf0080e7          	jalr	-1040(ra) # 8000034e <consputc>
  while(--i >= 0)
    80000766:	14fd                	addi	s1,s1,-1
    80000768:	ff2499e3          	bne	s1,s2,8000075a <printint+0x7c>
}
    8000076c:	70a2                	ld	ra,40(sp)
    8000076e:	7402                	ld	s0,32(sp)
    80000770:	64e2                	ld	s1,24(sp)
    80000772:	6942                	ld	s2,16(sp)
    80000774:	6145                	addi	sp,sp,48
    80000776:	8082                	ret
    x = -xx;
    80000778:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000077c:	4885                	li	a7,1
    x = -xx;
    8000077e:	bf9d                	j	800006f4 <printint+0x16>

0000000080000780 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000780:	1101                	addi	sp,sp,-32
    80000782:	ec06                	sd	ra,24(sp)
    80000784:	e822                	sd	s0,16(sp)
    80000786:	e426                	sd	s1,8(sp)
    80000788:	1000                	addi	s0,sp,32
    8000078a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000078c:	00011797          	auipc	a5,0x11
    80000790:	d007aa23          	sw	zero,-748(a5) # 800114a0 <pr+0x18>
  printf("panic: ");
    80000794:	00008517          	auipc	a0,0x8
    80000798:	88450513          	addi	a0,a0,-1916 # 80008018 <etext+0x18>
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	02e080e7          	jalr	46(ra) # 800007ca <printf>
  printf(s);
    800007a4:	8526                	mv	a0,s1
    800007a6:	00000097          	auipc	ra,0x0
    800007aa:	024080e7          	jalr	36(ra) # 800007ca <printf>
  printf("\n");
    800007ae:	00008517          	auipc	a0,0x8
    800007b2:	b7a50513          	addi	a0,a0,-1158 # 80008328 <digits+0x2e8>
    800007b6:	00000097          	auipc	ra,0x0
    800007ba:	014080e7          	jalr	20(ra) # 800007ca <printf>
  panicked = 1; // freeze uart output from other CPUs
    800007be:	4785                	li	a5,1
    800007c0:	00008717          	auipc	a4,0x8
    800007c4:	1cf72823          	sw	a5,464(a4) # 80008990 <panicked>
  for(;;)
    800007c8:	a001                	j	800007c8 <panic+0x48>

00000000800007ca <printf>:
{
    800007ca:	7131                	addi	sp,sp,-192
    800007cc:	fc86                	sd	ra,120(sp)
    800007ce:	f8a2                	sd	s0,112(sp)
    800007d0:	f4a6                	sd	s1,104(sp)
    800007d2:	f0ca                	sd	s2,96(sp)
    800007d4:	ecce                	sd	s3,88(sp)
    800007d6:	e8d2                	sd	s4,80(sp)
    800007d8:	e4d6                	sd	s5,72(sp)
    800007da:	e0da                	sd	s6,64(sp)
    800007dc:	fc5e                	sd	s7,56(sp)
    800007de:	f862                	sd	s8,48(sp)
    800007e0:	f466                	sd	s9,40(sp)
    800007e2:	f06a                	sd	s10,32(sp)
    800007e4:	ec6e                	sd	s11,24(sp)
    800007e6:	0100                	addi	s0,sp,128
    800007e8:	8a2a                	mv	s4,a0
    800007ea:	e40c                	sd	a1,8(s0)
    800007ec:	e810                	sd	a2,16(s0)
    800007ee:	ec14                	sd	a3,24(s0)
    800007f0:	f018                	sd	a4,32(s0)
    800007f2:	f41c                	sd	a5,40(s0)
    800007f4:	03043823          	sd	a6,48(s0)
    800007f8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800007fc:	00011d97          	auipc	s11,0x11
    80000800:	ca4dad83          	lw	s11,-860(s11) # 800114a0 <pr+0x18>
  if(locking)
    80000804:	020d9b63          	bnez	s11,8000083a <printf+0x70>
  if (fmt == 0)
    80000808:	040a0263          	beqz	s4,8000084c <printf+0x82>
  va_start(ap, fmt);
    8000080c:	00840793          	addi	a5,s0,8
    80000810:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000814:	000a4503          	lbu	a0,0(s4)
    80000818:	14050f63          	beqz	a0,80000976 <printf+0x1ac>
    8000081c:	4981                	li	s3,0
    if(c != '%'){
    8000081e:	02500a93          	li	s5,37
    switch(c){
    80000822:	07000b93          	li	s7,112
  consputc('x');
    80000826:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000828:	00008b17          	auipc	s6,0x8
    8000082c:	818b0b13          	addi	s6,s6,-2024 # 80008040 <digits>
    switch(c){
    80000830:	07300c93          	li	s9,115
    80000834:	06400c13          	li	s8,100
    80000838:	a82d                	j	80000872 <printf+0xa8>
    acquire(&pr.lock);
    8000083a:	00011517          	auipc	a0,0x11
    8000083e:	c4e50513          	addi	a0,a0,-946 # 80011488 <pr>
    80000842:	00000097          	auipc	ra,0x0
    80000846:	5d6080e7          	jalr	1494(ra) # 80000e18 <acquire>
    8000084a:	bf7d                	j	80000808 <printf+0x3e>
    panic("null fmt");
    8000084c:	00007517          	auipc	a0,0x7
    80000850:	7dc50513          	addi	a0,a0,2012 # 80008028 <etext+0x28>
    80000854:	00000097          	auipc	ra,0x0
    80000858:	f2c080e7          	jalr	-212(ra) # 80000780 <panic>
      consputc(c);
    8000085c:	00000097          	auipc	ra,0x0
    80000860:	af2080e7          	jalr	-1294(ra) # 8000034e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000864:	2985                	addiw	s3,s3,1
    80000866:	013a07b3          	add	a5,s4,s3
    8000086a:	0007c503          	lbu	a0,0(a5)
    8000086e:	10050463          	beqz	a0,80000976 <printf+0x1ac>
    if(c != '%'){
    80000872:	ff5515e3          	bne	a0,s5,8000085c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000876:	2985                	addiw	s3,s3,1
    80000878:	013a07b3          	add	a5,s4,s3
    8000087c:	0007c783          	lbu	a5,0(a5)
    80000880:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000884:	cbed                	beqz	a5,80000976 <printf+0x1ac>
    switch(c){
    80000886:	05778a63          	beq	a5,s7,800008da <printf+0x110>
    8000088a:	02fbf663          	bgeu	s7,a5,800008b6 <printf+0xec>
    8000088e:	09978863          	beq	a5,s9,8000091e <printf+0x154>
    80000892:	07800713          	li	a4,120
    80000896:	0ce79563          	bne	a5,a4,80000960 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000089a:	f8843783          	ld	a5,-120(s0)
    8000089e:	00878713          	addi	a4,a5,8
    800008a2:	f8e43423          	sd	a4,-120(s0)
    800008a6:	4605                	li	a2,1
    800008a8:	85ea                	mv	a1,s10
    800008aa:	4388                	lw	a0,0(a5)
    800008ac:	00000097          	auipc	ra,0x0
    800008b0:	e32080e7          	jalr	-462(ra) # 800006de <printint>
      break;
    800008b4:	bf45                	j	80000864 <printf+0x9a>
    switch(c){
    800008b6:	09578f63          	beq	a5,s5,80000954 <printf+0x18a>
    800008ba:	0b879363          	bne	a5,s8,80000960 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    800008be:	f8843783          	ld	a5,-120(s0)
    800008c2:	00878713          	addi	a4,a5,8
    800008c6:	f8e43423          	sd	a4,-120(s0)
    800008ca:	4605                	li	a2,1
    800008cc:	45a9                	li	a1,10
    800008ce:	4388                	lw	a0,0(a5)
    800008d0:	00000097          	auipc	ra,0x0
    800008d4:	e0e080e7          	jalr	-498(ra) # 800006de <printint>
      break;
    800008d8:	b771                	j	80000864 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800008da:	f8843783          	ld	a5,-120(s0)
    800008de:	00878713          	addi	a4,a5,8
    800008e2:	f8e43423          	sd	a4,-120(s0)
    800008e6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800008ea:	03000513          	li	a0,48
    800008ee:	00000097          	auipc	ra,0x0
    800008f2:	a60080e7          	jalr	-1440(ra) # 8000034e <consputc>
  consputc('x');
    800008f6:	07800513          	li	a0,120
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	a54080e7          	jalr	-1452(ra) # 8000034e <consputc>
    80000902:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000904:	03c95793          	srli	a5,s2,0x3c
    80000908:	97da                	add	a5,a5,s6
    8000090a:	0007c503          	lbu	a0,0(a5)
    8000090e:	00000097          	auipc	ra,0x0
    80000912:	a40080e7          	jalr	-1472(ra) # 8000034e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000916:	0912                	slli	s2,s2,0x4
    80000918:	34fd                	addiw	s1,s1,-1
    8000091a:	f4ed                	bnez	s1,80000904 <printf+0x13a>
    8000091c:	b7a1                	j	80000864 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    8000091e:	f8843783          	ld	a5,-120(s0)
    80000922:	00878713          	addi	a4,a5,8
    80000926:	f8e43423          	sd	a4,-120(s0)
    8000092a:	6384                	ld	s1,0(a5)
    8000092c:	cc89                	beqz	s1,80000946 <printf+0x17c>
      for(; *s; s++)
    8000092e:	0004c503          	lbu	a0,0(s1)
    80000932:	d90d                	beqz	a0,80000864 <printf+0x9a>
        consputc(*s);
    80000934:	00000097          	auipc	ra,0x0
    80000938:	a1a080e7          	jalr	-1510(ra) # 8000034e <consputc>
      for(; *s; s++)
    8000093c:	0485                	addi	s1,s1,1
    8000093e:	0004c503          	lbu	a0,0(s1)
    80000942:	f96d                	bnez	a0,80000934 <printf+0x16a>
    80000944:	b705                	j	80000864 <printf+0x9a>
        s = "(null)";
    80000946:	00007497          	auipc	s1,0x7
    8000094a:	6da48493          	addi	s1,s1,1754 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000094e:	02800513          	li	a0,40
    80000952:	b7cd                	j	80000934 <printf+0x16a>
      consputc('%');
    80000954:	8556                	mv	a0,s5
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	9f8080e7          	jalr	-1544(ra) # 8000034e <consputc>
      break;
    8000095e:	b719                	j	80000864 <printf+0x9a>
      consputc('%');
    80000960:	8556                	mv	a0,s5
    80000962:	00000097          	auipc	ra,0x0
    80000966:	9ec080e7          	jalr	-1556(ra) # 8000034e <consputc>
      consputc(c);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	9e2080e7          	jalr	-1566(ra) # 8000034e <consputc>
      break;
    80000974:	bdc5                	j	80000864 <printf+0x9a>
  if(locking)
    80000976:	020d9163          	bnez	s11,80000998 <printf+0x1ce>
}
    8000097a:	70e6                	ld	ra,120(sp)
    8000097c:	7446                	ld	s0,112(sp)
    8000097e:	74a6                	ld	s1,104(sp)
    80000980:	7906                	ld	s2,96(sp)
    80000982:	69e6                	ld	s3,88(sp)
    80000984:	6a46                	ld	s4,80(sp)
    80000986:	6aa6                	ld	s5,72(sp)
    80000988:	6b06                	ld	s6,64(sp)
    8000098a:	7be2                	ld	s7,56(sp)
    8000098c:	7c42                	ld	s8,48(sp)
    8000098e:	7ca2                	ld	s9,40(sp)
    80000990:	7d02                	ld	s10,32(sp)
    80000992:	6de2                	ld	s11,24(sp)
    80000994:	6129                	addi	sp,sp,192
    80000996:	8082                	ret
    release(&pr.lock);
    80000998:	00011517          	auipc	a0,0x11
    8000099c:	af050513          	addi	a0,a0,-1296 # 80011488 <pr>
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	52c080e7          	jalr	1324(ra) # 80000ecc <release>
}
    800009a8:	bfc9                	j	8000097a <printf+0x1b0>

00000000800009aa <printfinit>:
    ;
}

void
printfinit(void)
{
    800009aa:	1101                	addi	sp,sp,-32
    800009ac:	ec06                	sd	ra,24(sp)
    800009ae:	e822                	sd	s0,16(sp)
    800009b0:	e426                	sd	s1,8(sp)
    800009b2:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	ad448493          	addi	s1,s1,-1324 # 80011488 <pr>
    800009bc:	00007597          	auipc	a1,0x7
    800009c0:	67c58593          	addi	a1,a1,1660 # 80008038 <etext+0x38>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	3c2080e7          	jalr	962(ra) # 80000d88 <initlock>
  pr.locking = 1;
    800009ce:	4785                	li	a5,1
    800009d0:	cc9c                	sw	a5,24(s1)
}
    800009d2:	60e2                	ld	ra,24(sp)
    800009d4:	6442                	ld	s0,16(sp)
    800009d6:	64a2                	ld	s1,8(sp)
    800009d8:	6105                	addi	sp,sp,32
    800009da:	8082                	ret

00000000800009dc <uartinit>:

void uartstart();

void
uartinit(void)
{
    800009dc:	1141                	addi	sp,sp,-16
    800009de:	e406                	sd	ra,8(sp)
    800009e0:	e022                	sd	s0,0(sp)
    800009e2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800009e4:	100007b7          	lui	a5,0x10000
    800009e8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800009ec:	f8000713          	li	a4,-128
    800009f0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800009f4:	470d                	li	a4,3
    800009f6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800009fa:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800009fe:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000a02:	469d                	li	a3,7
    80000a04:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000a08:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000a0c:	00007597          	auipc	a1,0x7
    80000a10:	64c58593          	addi	a1,a1,1612 # 80008058 <digits+0x18>
    80000a14:	00011517          	auipc	a0,0x11
    80000a18:	a9450513          	addi	a0,a0,-1388 # 800114a8 <uart_tx_lock>
    80000a1c:	00000097          	auipc	ra,0x0
    80000a20:	36c080e7          	jalr	876(ra) # 80000d88 <initlock>
}
    80000a24:	60a2                	ld	ra,8(sp)
    80000a26:	6402                	ld	s0,0(sp)
    80000a28:	0141                	addi	sp,sp,16
    80000a2a:	8082                	ret

0000000080000a2c <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000a2c:	1101                	addi	sp,sp,-32
    80000a2e:	ec06                	sd	ra,24(sp)
    80000a30:	e822                	sd	s0,16(sp)
    80000a32:	e426                	sd	s1,8(sp)
    80000a34:	1000                	addi	s0,sp,32
    80000a36:	84aa                	mv	s1,a0
  push_off();
    80000a38:	00000097          	auipc	ra,0x0
    80000a3c:	394080e7          	jalr	916(ra) # 80000dcc <push_off>

  if(panicked){
    80000a40:	00008797          	auipc	a5,0x8
    80000a44:	f507a783          	lw	a5,-176(a5) # 80008990 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000a48:	10000737          	lui	a4,0x10000
  if(panicked){
    80000a4c:	c391                	beqz	a5,80000a50 <uartputc_sync+0x24>
    for(;;)
    80000a4e:	a001                	j	80000a4e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000a50:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000a54:	0207f793          	andi	a5,a5,32
    80000a58:	dfe5                	beqz	a5,80000a50 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000a5a:	0ff4f513          	andi	a0,s1,255
    80000a5e:	100007b7          	lui	a5,0x10000
    80000a62:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	406080e7          	jalr	1030(ra) # 80000e6c <pop_off>
}
    80000a6e:	60e2                	ld	ra,24(sp)
    80000a70:	6442                	ld	s0,16(sp)
    80000a72:	64a2                	ld	s1,8(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret

0000000080000a78 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000a78:	00008797          	auipc	a5,0x8
    80000a7c:	f207b783          	ld	a5,-224(a5) # 80008998 <uart_tx_r>
    80000a80:	00008717          	auipc	a4,0x8
    80000a84:	f2073703          	ld	a4,-224(a4) # 800089a0 <uart_tx_w>
    80000a88:	06f70a63          	beq	a4,a5,80000afc <uartstart+0x84>
{
    80000a8c:	7139                	addi	sp,sp,-64
    80000a8e:	fc06                	sd	ra,56(sp)
    80000a90:	f822                	sd	s0,48(sp)
    80000a92:	f426                	sd	s1,40(sp)
    80000a94:	f04a                	sd	s2,32(sp)
    80000a96:	ec4e                	sd	s3,24(sp)
    80000a98:	e852                	sd	s4,16(sp)
    80000a9a:	e456                	sd	s5,8(sp)
    80000a9c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000a9e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000aa2:	00011a17          	auipc	s4,0x11
    80000aa6:	a06a0a13          	addi	s4,s4,-1530 # 800114a8 <uart_tx_lock>
    uart_tx_r += 1;
    80000aaa:	00008497          	auipc	s1,0x8
    80000aae:	eee48493          	addi	s1,s1,-274 # 80008998 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000ab2:	00008997          	auipc	s3,0x8
    80000ab6:	eee98993          	addi	s3,s3,-274 # 800089a0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000aba:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000abe:	02077713          	andi	a4,a4,32
    80000ac2:	c705                	beqz	a4,80000aea <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000ac4:	01f7f713          	andi	a4,a5,31
    80000ac8:	9752                	add	a4,a4,s4
    80000aca:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000ace:	0785                	addi	a5,a5,1
    80000ad0:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000ad2:	8526                	mv	a0,s1
    80000ad4:	00002097          	auipc	ra,0x2
    80000ad8:	826080e7          	jalr	-2010(ra) # 800022fa <wakeup>
    
    WriteReg(THR, c);
    80000adc:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000ae0:	609c                	ld	a5,0(s1)
    80000ae2:	0009b703          	ld	a4,0(s3)
    80000ae6:	fcf71ae3          	bne	a4,a5,80000aba <uartstart+0x42>
  }
}
    80000aea:	70e2                	ld	ra,56(sp)
    80000aec:	7442                	ld	s0,48(sp)
    80000aee:	74a2                	ld	s1,40(sp)
    80000af0:	7902                	ld	s2,32(sp)
    80000af2:	69e2                	ld	s3,24(sp)
    80000af4:	6a42                	ld	s4,16(sp)
    80000af6:	6aa2                	ld	s5,8(sp)
    80000af8:	6121                	addi	sp,sp,64
    80000afa:	8082                	ret
    80000afc:	8082                	ret

0000000080000afe <uartputc>:
{
    80000afe:	7179                	addi	sp,sp,-48
    80000b00:	f406                	sd	ra,40(sp)
    80000b02:	f022                	sd	s0,32(sp)
    80000b04:	ec26                	sd	s1,24(sp)
    80000b06:	e84a                	sd	s2,16(sp)
    80000b08:	e44e                	sd	s3,8(sp)
    80000b0a:	e052                	sd	s4,0(sp)
    80000b0c:	1800                	addi	s0,sp,48
    80000b0e:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000b10:	00011517          	auipc	a0,0x11
    80000b14:	99850513          	addi	a0,a0,-1640 # 800114a8 <uart_tx_lock>
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	300080e7          	jalr	768(ra) # 80000e18 <acquire>
  if(panicked){
    80000b20:	00008797          	auipc	a5,0x8
    80000b24:	e707a783          	lw	a5,-400(a5) # 80008990 <panicked>
    80000b28:	e7c9                	bnez	a5,80000bb2 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000b2a:	00008717          	auipc	a4,0x8
    80000b2e:	e7673703          	ld	a4,-394(a4) # 800089a0 <uart_tx_w>
    80000b32:	00008797          	auipc	a5,0x8
    80000b36:	e667b783          	ld	a5,-410(a5) # 80008998 <uart_tx_r>
    80000b3a:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000b3e:	00011997          	auipc	s3,0x11
    80000b42:	96a98993          	addi	s3,s3,-1686 # 800114a8 <uart_tx_lock>
    80000b46:	00008497          	auipc	s1,0x8
    80000b4a:	e5248493          	addi	s1,s1,-430 # 80008998 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000b4e:	00008917          	auipc	s2,0x8
    80000b52:	e5290913          	addi	s2,s2,-430 # 800089a0 <uart_tx_w>
    80000b56:	00e79f63          	bne	a5,a4,80000b74 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000b5a:	85ce                	mv	a1,s3
    80000b5c:	8526                	mv	a0,s1
    80000b5e:	00001097          	auipc	ra,0x1
    80000b62:	738080e7          	jalr	1848(ra) # 80002296 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000b66:	00093703          	ld	a4,0(s2)
    80000b6a:	609c                	ld	a5,0(s1)
    80000b6c:	02078793          	addi	a5,a5,32
    80000b70:	fee785e3          	beq	a5,a4,80000b5a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000b74:	00011497          	auipc	s1,0x11
    80000b78:	93448493          	addi	s1,s1,-1740 # 800114a8 <uart_tx_lock>
    80000b7c:	01f77793          	andi	a5,a4,31
    80000b80:	97a6                	add	a5,a5,s1
    80000b82:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000b86:	0705                	addi	a4,a4,1
    80000b88:	00008797          	auipc	a5,0x8
    80000b8c:	e0e7bc23          	sd	a4,-488(a5) # 800089a0 <uart_tx_w>
  uartstart();
    80000b90:	00000097          	auipc	ra,0x0
    80000b94:	ee8080e7          	jalr	-280(ra) # 80000a78 <uartstart>
  release(&uart_tx_lock);
    80000b98:	8526                	mv	a0,s1
    80000b9a:	00000097          	auipc	ra,0x0
    80000b9e:	332080e7          	jalr	818(ra) # 80000ecc <release>
}
    80000ba2:	70a2                	ld	ra,40(sp)
    80000ba4:	7402                	ld	s0,32(sp)
    80000ba6:	64e2                	ld	s1,24(sp)
    80000ba8:	6942                	ld	s2,16(sp)
    80000baa:	69a2                	ld	s3,8(sp)
    80000bac:	6a02                	ld	s4,0(sp)
    80000bae:	6145                	addi	sp,sp,48
    80000bb0:	8082                	ret
    for(;;)
    80000bb2:	a001                	j	80000bb2 <uartputc+0xb4>

0000000080000bb4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000bb4:	1141                	addi	sp,sp,-16
    80000bb6:	e422                	sd	s0,8(sp)
    80000bb8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000bba:	100007b7          	lui	a5,0x10000
    80000bbe:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000bc2:	8b85                	andi	a5,a5,1
    80000bc4:	cb91                	beqz	a5,80000bd8 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000bc6:	100007b7          	lui	a5,0x10000
    80000bca:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000bce:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000bd2:	6422                	ld	s0,8(sp)
    80000bd4:	0141                	addi	sp,sp,16
    80000bd6:	8082                	ret
    return -1;
    80000bd8:	557d                	li	a0,-1
    80000bda:	bfe5                	j	80000bd2 <uartgetc+0x1e>

0000000080000bdc <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000bdc:	1101                	addi	sp,sp,-32
    80000bde:	ec06                	sd	ra,24(sp)
    80000be0:	e822                	sd	s0,16(sp)
    80000be2:	e426                	sd	s1,8(sp)
    80000be4:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000be6:	54fd                	li	s1,-1
    80000be8:	a029                	j	80000bf2 <uartintr+0x16>
      break;
    consoleintr(c);
    80000bea:	fffff097          	auipc	ra,0xfffff
    80000bee:	7a6080e7          	jalr	1958(ra) # 80000390 <consoleintr>
    int c = uartgetc();
    80000bf2:	00000097          	auipc	ra,0x0
    80000bf6:	fc2080e7          	jalr	-62(ra) # 80000bb4 <uartgetc>
    if(c == -1)
    80000bfa:	fe9518e3          	bne	a0,s1,80000bea <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000bfe:	00011497          	auipc	s1,0x11
    80000c02:	8aa48493          	addi	s1,s1,-1878 # 800114a8 <uart_tx_lock>
    80000c06:	8526                	mv	a0,s1
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	210080e7          	jalr	528(ra) # 80000e18 <acquire>
  uartstart();
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	e68080e7          	jalr	-408(ra) # 80000a78 <uartstart>
  release(&uart_tx_lock);
    80000c18:	8526                	mv	a0,s1
    80000c1a:	00000097          	auipc	ra,0x0
    80000c1e:	2b2080e7          	jalr	690(ra) # 80000ecc <release>
}
    80000c22:	60e2                	ld	ra,24(sp)
    80000c24:	6442                	ld	s0,16(sp)
    80000c26:	64a2                	ld	s1,8(sp)
    80000c28:	6105                	addi	sp,sp,32
    80000c2a:	8082                	ret

0000000080000c2c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000c2c:	1101                	addi	sp,sp,-32
    80000c2e:	ec06                	sd	ra,24(sp)
    80000c30:	e822                	sd	s0,16(sp)
    80000c32:	e426                	sd	s1,8(sp)
    80000c34:	e04a                	sd	s2,0(sp)
    80000c36:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000c38:	03451793          	slli	a5,a0,0x34
    80000c3c:	ebb9                	bnez	a5,80000c92 <kfree+0x66>
    80000c3e:	84aa                	mv	s1,a0
    80000c40:	00022797          	auipc	a5,0x22
    80000c44:	20878793          	addi	a5,a5,520 # 80022e48 <end>
    80000c48:	04f56563          	bltu	a0,a5,80000c92 <kfree+0x66>
    80000c4c:	47c5                	li	a5,17
    80000c4e:	07ee                	slli	a5,a5,0x1b
    80000c50:	04f57163          	bgeu	a0,a5,80000c92 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000c54:	6605                	lui	a2,0x1
    80000c56:	4585                	li	a1,1
    80000c58:	00000097          	auipc	ra,0x0
    80000c5c:	2bc080e7          	jalr	700(ra) # 80000f14 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000c60:	00011917          	auipc	s2,0x11
    80000c64:	88090913          	addi	s2,s2,-1920 # 800114e0 <kmem>
    80000c68:	854a                	mv	a0,s2
    80000c6a:	00000097          	auipc	ra,0x0
    80000c6e:	1ae080e7          	jalr	430(ra) # 80000e18 <acquire>
  r->next = kmem.freelist;
    80000c72:	01893783          	ld	a5,24(s2)
    80000c76:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000c78:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000c7c:	854a                	mv	a0,s2
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	24e080e7          	jalr	590(ra) # 80000ecc <release>
}
    80000c86:	60e2                	ld	ra,24(sp)
    80000c88:	6442                	ld	s0,16(sp)
    80000c8a:	64a2                	ld	s1,8(sp)
    80000c8c:	6902                	ld	s2,0(sp)
    80000c8e:	6105                	addi	sp,sp,32
    80000c90:	8082                	ret
    panic("kfree");
    80000c92:	00007517          	auipc	a0,0x7
    80000c96:	3ce50513          	addi	a0,a0,974 # 80008060 <digits+0x20>
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	ae6080e7          	jalr	-1306(ra) # 80000780 <panic>

0000000080000ca2 <freerange>:
{
    80000ca2:	7179                	addi	sp,sp,-48
    80000ca4:	f406                	sd	ra,40(sp)
    80000ca6:	f022                	sd	s0,32(sp)
    80000ca8:	ec26                	sd	s1,24(sp)
    80000caa:	e84a                	sd	s2,16(sp)
    80000cac:	e44e                	sd	s3,8(sp)
    80000cae:	e052                	sd	s4,0(sp)
    80000cb0:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000cb2:	6785                	lui	a5,0x1
    80000cb4:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000cb8:	94aa                	add	s1,s1,a0
    80000cba:	757d                	lui	a0,0xfffff
    80000cbc:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000cbe:	94be                	add	s1,s1,a5
    80000cc0:	0095ee63          	bltu	a1,s1,80000cdc <freerange+0x3a>
    80000cc4:	892e                	mv	s2,a1
    kfree(p);
    80000cc6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000cc8:	6985                	lui	s3,0x1
    kfree(p);
    80000cca:	01448533          	add	a0,s1,s4
    80000cce:	00000097          	auipc	ra,0x0
    80000cd2:	f5e080e7          	jalr	-162(ra) # 80000c2c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000cd6:	94ce                	add	s1,s1,s3
    80000cd8:	fe9979e3          	bgeu	s2,s1,80000cca <freerange+0x28>
}
    80000cdc:	70a2                	ld	ra,40(sp)
    80000cde:	7402                	ld	s0,32(sp)
    80000ce0:	64e2                	ld	s1,24(sp)
    80000ce2:	6942                	ld	s2,16(sp)
    80000ce4:	69a2                	ld	s3,8(sp)
    80000ce6:	6a02                	ld	s4,0(sp)
    80000ce8:	6145                	addi	sp,sp,48
    80000cea:	8082                	ret

0000000080000cec <kinit>:
{
    80000cec:	1141                	addi	sp,sp,-16
    80000cee:	e406                	sd	ra,8(sp)
    80000cf0:	e022                	sd	s0,0(sp)
    80000cf2:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000cf4:	00007597          	auipc	a1,0x7
    80000cf8:	37458593          	addi	a1,a1,884 # 80008068 <digits+0x28>
    80000cfc:	00010517          	auipc	a0,0x10
    80000d00:	7e450513          	addi	a0,a0,2020 # 800114e0 <kmem>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	084080e7          	jalr	132(ra) # 80000d88 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000d0c:	45c5                	li	a1,17
    80000d0e:	05ee                	slli	a1,a1,0x1b
    80000d10:	00022517          	auipc	a0,0x22
    80000d14:	13850513          	addi	a0,a0,312 # 80022e48 <end>
    80000d18:	00000097          	auipc	ra,0x0
    80000d1c:	f8a080e7          	jalr	-118(ra) # 80000ca2 <freerange>
}
    80000d20:	60a2                	ld	ra,8(sp)
    80000d22:	6402                	ld	s0,0(sp)
    80000d24:	0141                	addi	sp,sp,16
    80000d26:	8082                	ret

0000000080000d28 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000d28:	1101                	addi	sp,sp,-32
    80000d2a:	ec06                	sd	ra,24(sp)
    80000d2c:	e822                	sd	s0,16(sp)
    80000d2e:	e426                	sd	s1,8(sp)
    80000d30:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000d32:	00010497          	auipc	s1,0x10
    80000d36:	7ae48493          	addi	s1,s1,1966 # 800114e0 <kmem>
    80000d3a:	8526                	mv	a0,s1
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	0dc080e7          	jalr	220(ra) # 80000e18 <acquire>
  r = kmem.freelist;
    80000d44:	6c84                	ld	s1,24(s1)
  if(r)
    80000d46:	c885                	beqz	s1,80000d76 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000d48:	609c                	ld	a5,0(s1)
    80000d4a:	00010517          	auipc	a0,0x10
    80000d4e:	79650513          	addi	a0,a0,1942 # 800114e0 <kmem>
    80000d52:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000d54:	00000097          	auipc	ra,0x0
    80000d58:	178080e7          	jalr	376(ra) # 80000ecc <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000d5c:	6605                	lui	a2,0x1
    80000d5e:	4595                	li	a1,5
    80000d60:	8526                	mv	a0,s1
    80000d62:	00000097          	auipc	ra,0x0
    80000d66:	1b2080e7          	jalr	434(ra) # 80000f14 <memset>
  return (void*)r;
}
    80000d6a:	8526                	mv	a0,s1
    80000d6c:	60e2                	ld	ra,24(sp)
    80000d6e:	6442                	ld	s0,16(sp)
    80000d70:	64a2                	ld	s1,8(sp)
    80000d72:	6105                	addi	sp,sp,32
    80000d74:	8082                	ret
  release(&kmem.lock);
    80000d76:	00010517          	auipc	a0,0x10
    80000d7a:	76a50513          	addi	a0,a0,1898 # 800114e0 <kmem>
    80000d7e:	00000097          	auipc	ra,0x0
    80000d82:	14e080e7          	jalr	334(ra) # 80000ecc <release>
  if(r)
    80000d86:	b7d5                	j	80000d6a <kalloc+0x42>

0000000080000d88 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000d88:	1141                	addi	sp,sp,-16
    80000d8a:	e422                	sd	s0,8(sp)
    80000d8c:	0800                	addi	s0,sp,16
  lk->name = name;
    80000d8e:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000d90:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000d94:	00053823          	sd	zero,16(a0)
}
    80000d98:	6422                	ld	s0,8(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d9e:	411c                	lw	a5,0(a0)
    80000da0:	e399                	bnez	a5,80000da6 <holding+0x8>
    80000da2:	4501                	li	a0,0
  return r;
}
    80000da4:	8082                	ret
{
    80000da6:	1101                	addi	sp,sp,-32
    80000da8:	ec06                	sd	ra,24(sp)
    80000daa:	e822                	sd	s0,16(sp)
    80000dac:	e426                	sd	s1,8(sp)
    80000dae:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000db0:	6904                	ld	s1,16(a0)
    80000db2:	00001097          	auipc	ra,0x1
    80000db6:	e20080e7          	jalr	-480(ra) # 80001bd2 <mycpu>
    80000dba:	40a48533          	sub	a0,s1,a0
    80000dbe:	00153513          	seqz	a0,a0
}
    80000dc2:	60e2                	ld	ra,24(sp)
    80000dc4:	6442                	ld	s0,16(sp)
    80000dc6:	64a2                	ld	s1,8(sp)
    80000dc8:	6105                	addi	sp,sp,32
    80000dca:	8082                	ret

0000000080000dcc <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000dcc:	1101                	addi	sp,sp,-32
    80000dce:	ec06                	sd	ra,24(sp)
    80000dd0:	e822                	sd	s0,16(sp)
    80000dd2:	e426                	sd	s1,8(sp)
    80000dd4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dd6:	100024f3          	csrr	s1,sstatus
    80000dda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000dde:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000de0:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000de4:	00001097          	auipc	ra,0x1
    80000de8:	dee080e7          	jalr	-530(ra) # 80001bd2 <mycpu>
    80000dec:	5d3c                	lw	a5,120(a0)
    80000dee:	cf89                	beqz	a5,80000e08 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000df0:	00001097          	auipc	ra,0x1
    80000df4:	de2080e7          	jalr	-542(ra) # 80001bd2 <mycpu>
    80000df8:	5d3c                	lw	a5,120(a0)
    80000dfa:	2785                	addiw	a5,a5,1
    80000dfc:	dd3c                	sw	a5,120(a0)
}
    80000dfe:	60e2                	ld	ra,24(sp)
    80000e00:	6442                	ld	s0,16(sp)
    80000e02:	64a2                	ld	s1,8(sp)
    80000e04:	6105                	addi	sp,sp,32
    80000e06:	8082                	ret
    mycpu()->intena = old;
    80000e08:	00001097          	auipc	ra,0x1
    80000e0c:	dca080e7          	jalr	-566(ra) # 80001bd2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000e10:	8085                	srli	s1,s1,0x1
    80000e12:	8885                	andi	s1,s1,1
    80000e14:	dd64                	sw	s1,124(a0)
    80000e16:	bfe9                	j	80000df0 <push_off+0x24>

0000000080000e18 <acquire>:
{
    80000e18:	1101                	addi	sp,sp,-32
    80000e1a:	ec06                	sd	ra,24(sp)
    80000e1c:	e822                	sd	s0,16(sp)
    80000e1e:	e426                	sd	s1,8(sp)
    80000e20:	1000                	addi	s0,sp,32
    80000e22:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000e24:	00000097          	auipc	ra,0x0
    80000e28:	fa8080e7          	jalr	-88(ra) # 80000dcc <push_off>
  if(holding(lk))
    80000e2c:	8526                	mv	a0,s1
    80000e2e:	00000097          	auipc	ra,0x0
    80000e32:	f70080e7          	jalr	-144(ra) # 80000d9e <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000e36:	4705                	li	a4,1
  if(holding(lk))
    80000e38:	e115                	bnez	a0,80000e5c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000e3a:	87ba                	mv	a5,a4
    80000e3c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000e40:	2781                	sext.w	a5,a5
    80000e42:	ffe5                	bnez	a5,80000e3a <acquire+0x22>
  __sync_synchronize();
    80000e44:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000e48:	00001097          	auipc	ra,0x1
    80000e4c:	d8a080e7          	jalr	-630(ra) # 80001bd2 <mycpu>
    80000e50:	e888                	sd	a0,16(s1)
}
    80000e52:	60e2                	ld	ra,24(sp)
    80000e54:	6442                	ld	s0,16(sp)
    80000e56:	64a2                	ld	s1,8(sp)
    80000e58:	6105                	addi	sp,sp,32
    80000e5a:	8082                	ret
    panic("acquire");
    80000e5c:	00007517          	auipc	a0,0x7
    80000e60:	21450513          	addi	a0,a0,532 # 80008070 <digits+0x30>
    80000e64:	00000097          	auipc	ra,0x0
    80000e68:	91c080e7          	jalr	-1764(ra) # 80000780 <panic>

0000000080000e6c <pop_off>:

void
pop_off(void)
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	d5e080e7          	jalr	-674(ra) # 80001bd2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e7c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000e80:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000e82:	e78d                	bnez	a5,80000eac <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000e84:	5d3c                	lw	a5,120(a0)
    80000e86:	02f05b63          	blez	a5,80000ebc <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000e8a:	37fd                	addiw	a5,a5,-1
    80000e8c:	0007871b          	sext.w	a4,a5
    80000e90:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e92:	eb09                	bnez	a4,80000ea4 <pop_off+0x38>
    80000e94:	5d7c                	lw	a5,124(a0)
    80000e96:	c799                	beqz	a5,80000ea4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e9c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ea0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ea4:	60a2                	ld	ra,8(sp)
    80000ea6:	6402                	ld	s0,0(sp)
    80000ea8:	0141                	addi	sp,sp,16
    80000eaa:	8082                	ret
    panic("pop_off - interruptible");
    80000eac:	00007517          	auipc	a0,0x7
    80000eb0:	1cc50513          	addi	a0,a0,460 # 80008078 <digits+0x38>
    80000eb4:	00000097          	auipc	ra,0x0
    80000eb8:	8cc080e7          	jalr	-1844(ra) # 80000780 <panic>
    panic("pop_off");
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1d450513          	addi	a0,a0,468 # 80008090 <digits+0x50>
    80000ec4:	00000097          	auipc	ra,0x0
    80000ec8:	8bc080e7          	jalr	-1860(ra) # 80000780 <panic>

0000000080000ecc <release>:
{
    80000ecc:	1101                	addi	sp,sp,-32
    80000ece:	ec06                	sd	ra,24(sp)
    80000ed0:	e822                	sd	s0,16(sp)
    80000ed2:	e426                	sd	s1,8(sp)
    80000ed4:	1000                	addi	s0,sp,32
    80000ed6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	ec6080e7          	jalr	-314(ra) # 80000d9e <holding>
    80000ee0:	c115                	beqz	a0,80000f04 <release+0x38>
  lk->cpu = 0;
    80000ee2:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ee6:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000eea:	0f50000f          	fence	iorw,ow
    80000eee:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000ef2:	00000097          	auipc	ra,0x0
    80000ef6:	f7a080e7          	jalr	-134(ra) # 80000e6c <pop_off>
}
    80000efa:	60e2                	ld	ra,24(sp)
    80000efc:	6442                	ld	s0,16(sp)
    80000efe:	64a2                	ld	s1,8(sp)
    80000f00:	6105                	addi	sp,sp,32
    80000f02:	8082                	ret
    panic("release");
    80000f04:	00007517          	auipc	a0,0x7
    80000f08:	19450513          	addi	a0,a0,404 # 80008098 <digits+0x58>
    80000f0c:	00000097          	auipc	ra,0x0
    80000f10:	874080e7          	jalr	-1932(ra) # 80000780 <panic>

0000000080000f14 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000f14:	1141                	addi	sp,sp,-16
    80000f16:	e422                	sd	s0,8(sp)
    80000f18:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000f1a:	ca19                	beqz	a2,80000f30 <memset+0x1c>
    80000f1c:	87aa                	mv	a5,a0
    80000f1e:	1602                	slli	a2,a2,0x20
    80000f20:	9201                	srli	a2,a2,0x20
    80000f22:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000f26:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000f2a:	0785                	addi	a5,a5,1
    80000f2c:	fee79de3          	bne	a5,a4,80000f26 <memset+0x12>
  }
  return dst;
}
    80000f30:	6422                	ld	s0,8(sp)
    80000f32:	0141                	addi	sp,sp,16
    80000f34:	8082                	ret

0000000080000f36 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000f36:	1141                	addi	sp,sp,-16
    80000f38:	e422                	sd	s0,8(sp)
    80000f3a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000f3c:	ca05                	beqz	a2,80000f6c <memcmp+0x36>
    80000f3e:	fff6069b          	addiw	a3,a2,-1
    80000f42:	1682                	slli	a3,a3,0x20
    80000f44:	9281                	srli	a3,a3,0x20
    80000f46:	0685                	addi	a3,a3,1
    80000f48:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000f4a:	00054783          	lbu	a5,0(a0)
    80000f4e:	0005c703          	lbu	a4,0(a1)
    80000f52:	00e79863          	bne	a5,a4,80000f62 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000f56:	0505                	addi	a0,a0,1
    80000f58:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000f5a:	fed518e3          	bne	a0,a3,80000f4a <memcmp+0x14>
  }

  return 0;
    80000f5e:	4501                	li	a0,0
    80000f60:	a019                	j	80000f66 <memcmp+0x30>
      return *s1 - *s2;
    80000f62:	40e7853b          	subw	a0,a5,a4
}
    80000f66:	6422                	ld	s0,8(sp)
    80000f68:	0141                	addi	sp,sp,16
    80000f6a:	8082                	ret
  return 0;
    80000f6c:	4501                	li	a0,0
    80000f6e:	bfe5                	j	80000f66 <memcmp+0x30>

0000000080000f70 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000f70:	1141                	addi	sp,sp,-16
    80000f72:	e422                	sd	s0,8(sp)
    80000f74:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000f76:	c205                	beqz	a2,80000f96 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000f78:	02a5e263          	bltu	a1,a0,80000f9c <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000f7c:	1602                	slli	a2,a2,0x20
    80000f7e:	9201                	srli	a2,a2,0x20
    80000f80:	00c587b3          	add	a5,a1,a2
{
    80000f84:	872a                	mv	a4,a0
      *d++ = *s++;
    80000f86:	0585                	addi	a1,a1,1
    80000f88:	0705                	addi	a4,a4,1
    80000f8a:	fff5c683          	lbu	a3,-1(a1)
    80000f8e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000f92:	fef59ae3          	bne	a1,a5,80000f86 <memmove+0x16>

  return dst;
}
    80000f96:	6422                	ld	s0,8(sp)
    80000f98:	0141                	addi	sp,sp,16
    80000f9a:	8082                	ret
  if(s < d && s + n > d){
    80000f9c:	02061693          	slli	a3,a2,0x20
    80000fa0:	9281                	srli	a3,a3,0x20
    80000fa2:	00d58733          	add	a4,a1,a3
    80000fa6:	fce57be3          	bgeu	a0,a4,80000f7c <memmove+0xc>
    d += n;
    80000faa:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000fac:	fff6079b          	addiw	a5,a2,-1
    80000fb0:	1782                	slli	a5,a5,0x20
    80000fb2:	9381                	srli	a5,a5,0x20
    80000fb4:	fff7c793          	not	a5,a5
    80000fb8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000fba:	177d                	addi	a4,a4,-1
    80000fbc:	16fd                	addi	a3,a3,-1
    80000fbe:	00074603          	lbu	a2,0(a4)
    80000fc2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000fc6:	fee79ae3          	bne	a5,a4,80000fba <memmove+0x4a>
    80000fca:	b7f1                	j	80000f96 <memmove+0x26>

0000000080000fcc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000fcc:	1141                	addi	sp,sp,-16
    80000fce:	e406                	sd	ra,8(sp)
    80000fd0:	e022                	sd	s0,0(sp)
    80000fd2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000fd4:	00000097          	auipc	ra,0x0
    80000fd8:	f9c080e7          	jalr	-100(ra) # 80000f70 <memmove>
}
    80000fdc:	60a2                	ld	ra,8(sp)
    80000fde:	6402                	ld	s0,0(sp)
    80000fe0:	0141                	addi	sp,sp,16
    80000fe2:	8082                	ret

0000000080000fe4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000fe4:	1141                	addi	sp,sp,-16
    80000fe6:	e422                	sd	s0,8(sp)
    80000fe8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000fea:	ce11                	beqz	a2,80001006 <strncmp+0x22>
    80000fec:	00054783          	lbu	a5,0(a0)
    80000ff0:	cf89                	beqz	a5,8000100a <strncmp+0x26>
    80000ff2:	0005c703          	lbu	a4,0(a1)
    80000ff6:	00f71a63          	bne	a4,a5,8000100a <strncmp+0x26>
    n--, p++, q++;
    80000ffa:	367d                	addiw	a2,a2,-1
    80000ffc:	0505                	addi	a0,a0,1
    80000ffe:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80001000:	f675                	bnez	a2,80000fec <strncmp+0x8>
  if(n == 0)
    return 0;
    80001002:	4501                	li	a0,0
    80001004:	a809                	j	80001016 <strncmp+0x32>
    80001006:	4501                	li	a0,0
    80001008:	a039                	j	80001016 <strncmp+0x32>
  if(n == 0)
    8000100a:	ca09                	beqz	a2,8000101c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000100c:	00054503          	lbu	a0,0(a0)
    80001010:	0005c783          	lbu	a5,0(a1)
    80001014:	9d1d                	subw	a0,a0,a5
}
    80001016:	6422                	ld	s0,8(sp)
    80001018:	0141                	addi	sp,sp,16
    8000101a:	8082                	ret
    return 0;
    8000101c:	4501                	li	a0,0
    8000101e:	bfe5                	j	80001016 <strncmp+0x32>

0000000080001020 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80001020:	1141                	addi	sp,sp,-16
    80001022:	e422                	sd	s0,8(sp)
    80001024:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80001026:	872a                	mv	a4,a0
    80001028:	8832                	mv	a6,a2
    8000102a:	367d                	addiw	a2,a2,-1
    8000102c:	01005963          	blez	a6,8000103e <strncpy+0x1e>
    80001030:	0705                	addi	a4,a4,1
    80001032:	0005c783          	lbu	a5,0(a1)
    80001036:	fef70fa3          	sb	a5,-1(a4)
    8000103a:	0585                	addi	a1,a1,1
    8000103c:	f7f5                	bnez	a5,80001028 <strncpy+0x8>
    ;
  while(n-- > 0)
    8000103e:	86ba                	mv	a3,a4
    80001040:	00c05c63          	blez	a2,80001058 <strncpy+0x38>
    *s++ = 0;
    80001044:	0685                	addi	a3,a3,1
    80001046:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    8000104a:	fff6c793          	not	a5,a3
    8000104e:	9fb9                	addw	a5,a5,a4
    80001050:	010787bb          	addw	a5,a5,a6
    80001054:	fef048e3          	bgtz	a5,80001044 <strncpy+0x24>
  return os;
}
    80001058:	6422                	ld	s0,8(sp)
    8000105a:	0141                	addi	sp,sp,16
    8000105c:	8082                	ret

000000008000105e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e422                	sd	s0,8(sp)
    80001062:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001064:	02c05363          	blez	a2,8000108a <safestrcpy+0x2c>
    80001068:	fff6069b          	addiw	a3,a2,-1
    8000106c:	1682                	slli	a3,a3,0x20
    8000106e:	9281                	srli	a3,a3,0x20
    80001070:	96ae                	add	a3,a3,a1
    80001072:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001074:	00d58963          	beq	a1,a3,80001086 <safestrcpy+0x28>
    80001078:	0585                	addi	a1,a1,1
    8000107a:	0785                	addi	a5,a5,1
    8000107c:	fff5c703          	lbu	a4,-1(a1)
    80001080:	fee78fa3          	sb	a4,-1(a5)
    80001084:	fb65                	bnez	a4,80001074 <safestrcpy+0x16>
    ;
  *s = 0;
    80001086:	00078023          	sb	zero,0(a5)
  return os;
}
    8000108a:	6422                	ld	s0,8(sp)
    8000108c:	0141                	addi	sp,sp,16
    8000108e:	8082                	ret

0000000080001090 <strlen>:

int
strlen(const char *s)
{
    80001090:	1141                	addi	sp,sp,-16
    80001092:	e422                	sd	s0,8(sp)
    80001094:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001096:	00054783          	lbu	a5,0(a0)
    8000109a:	cf91                	beqz	a5,800010b6 <strlen+0x26>
    8000109c:	0505                	addi	a0,a0,1
    8000109e:	87aa                	mv	a5,a0
    800010a0:	4685                	li	a3,1
    800010a2:	9e89                	subw	a3,a3,a0
    800010a4:	00f6853b          	addw	a0,a3,a5
    800010a8:	0785                	addi	a5,a5,1
    800010aa:	fff7c703          	lbu	a4,-1(a5)
    800010ae:	fb7d                	bnez	a4,800010a4 <strlen+0x14>
    ;
  return n;
}
    800010b0:	6422                	ld	s0,8(sp)
    800010b2:	0141                	addi	sp,sp,16
    800010b4:	8082                	ret
  for(n = 0; s[n]; n++)
    800010b6:	4501                	li	a0,0
    800010b8:	bfe5                	j	800010b0 <strlen+0x20>

00000000800010ba <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    800010ba:	1141                	addi	sp,sp,-16
    800010bc:	e406                	sd	ra,8(sp)
    800010be:	e022                	sd	s0,0(sp)
    800010c0:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    800010c2:	00001097          	auipc	ra,0x1
    800010c6:	b00080e7          	jalr	-1280(ra) # 80001bc2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    800010ca:	00008717          	auipc	a4,0x8
    800010ce:	8de70713          	addi	a4,a4,-1826 # 800089a8 <started>
  if(cpuid() == 0){
    800010d2:	c139                	beqz	a0,80001118 <main+0x5e>
    while(started == 0)
    800010d4:	431c                	lw	a5,0(a4)
    800010d6:	2781                	sext.w	a5,a5
    800010d8:	dff5                	beqz	a5,800010d4 <main+0x1a>
      ;
    __sync_synchronize();
    800010da:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    800010de:	00001097          	auipc	ra,0x1
    800010e2:	ae4080e7          	jalr	-1308(ra) # 80001bc2 <cpuid>
    800010e6:	85aa                	mv	a1,a0
    800010e8:	00007517          	auipc	a0,0x7
    800010ec:	fd050513          	addi	a0,a0,-48 # 800080b8 <digits+0x78>
    800010f0:	fffff097          	auipc	ra,0xfffff
    800010f4:	6da080e7          	jalr	1754(ra) # 800007ca <printf>
    kvminithart();    // turn on paging
    800010f8:	00000097          	auipc	ra,0x0
    800010fc:	0d8080e7          	jalr	216(ra) # 800011d0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001100:	00002097          	auipc	ra,0x2
    80001104:	95a080e7          	jalr	-1702(ra) # 80002a5a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001108:	00005097          	auipc	ra,0x5
    8000110c:	f68080e7          	jalr	-152(ra) # 80006070 <plicinithart>
  }

  scheduler();        
    80001110:	00001097          	auipc	ra,0x1
    80001114:	fd4080e7          	jalr	-44(ra) # 800020e4 <scheduler>
    consoleinit();
    80001118:	fffff097          	auipc	ra,0xfffff
    8000111c:	57a080e7          	jalr	1402(ra) # 80000692 <consoleinit>
    printfinit();
    80001120:	00000097          	auipc	ra,0x0
    80001124:	88a080e7          	jalr	-1910(ra) # 800009aa <printfinit>
    printf("\n");
    80001128:	00007517          	auipc	a0,0x7
    8000112c:	20050513          	addi	a0,a0,512 # 80008328 <digits+0x2e8>
    80001130:	fffff097          	auipc	ra,0xfffff
    80001134:	69a080e7          	jalr	1690(ra) # 800007ca <printf>
    printf("xv6 kernel is booting\n");
    80001138:	00007517          	auipc	a0,0x7
    8000113c:	f6850513          	addi	a0,a0,-152 # 800080a0 <digits+0x60>
    80001140:	fffff097          	auipc	ra,0xfffff
    80001144:	68a080e7          	jalr	1674(ra) # 800007ca <printf>
    printf("\n");
    80001148:	00007517          	auipc	a0,0x7
    8000114c:	1e050513          	addi	a0,a0,480 # 80008328 <digits+0x2e8>
    80001150:	fffff097          	auipc	ra,0xfffff
    80001154:	67a080e7          	jalr	1658(ra) # 800007ca <printf>
    kinit();         // physical page allocator
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	b94080e7          	jalr	-1132(ra) # 80000cec <kinit>
    kvminit();       // create kernel page table
    80001160:	00000097          	auipc	ra,0x0
    80001164:	326080e7          	jalr	806(ra) # 80001486 <kvminit>
    kvminithart();   // turn on paging
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	068080e7          	jalr	104(ra) # 800011d0 <kvminithart>
    procinit();      // process table
    80001170:	00001097          	auipc	ra,0x1
    80001174:	99e080e7          	jalr	-1634(ra) # 80001b0e <procinit>
    trapinit();      // trap vectors
    80001178:	00002097          	auipc	ra,0x2
    8000117c:	8ba080e7          	jalr	-1862(ra) # 80002a32 <trapinit>
    trapinithart();  // install kernel trap vector
    80001180:	00002097          	auipc	ra,0x2
    80001184:	8da080e7          	jalr	-1830(ra) # 80002a5a <trapinithart>
    plicinit();      // set up interrupt controller
    80001188:	00005097          	auipc	ra,0x5
    8000118c:	ed2080e7          	jalr	-302(ra) # 8000605a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001190:	00005097          	auipc	ra,0x5
    80001194:	ee0080e7          	jalr	-288(ra) # 80006070 <plicinithart>
    binit();         // buffer cache
    80001198:	00002097          	auipc	ra,0x2
    8000119c:	084080e7          	jalr	132(ra) # 8000321c <binit>
    iinit();         // inode table
    800011a0:	00002097          	auipc	ra,0x2
    800011a4:	728080e7          	jalr	1832(ra) # 800038c8 <iinit>
    fileinit();      // file table
    800011a8:	00003097          	auipc	ra,0x3
    800011ac:	6c6080e7          	jalr	1734(ra) # 8000486e <fileinit>
    virtio_disk_init(); // emulated hard disk
    800011b0:	00005097          	auipc	ra,0x5
    800011b4:	fc8080e7          	jalr	-56(ra) # 80006178 <virtio_disk_init>
    userinit();      // first user process
    800011b8:	00001097          	auipc	ra,0x1
    800011bc:	d0e080e7          	jalr	-754(ra) # 80001ec6 <userinit>
    __sync_synchronize();
    800011c0:	0ff0000f          	fence
    started = 1;
    800011c4:	4785                	li	a5,1
    800011c6:	00007717          	auipc	a4,0x7
    800011ca:	7ef72123          	sw	a5,2018(a4) # 800089a8 <started>
    800011ce:	b789                	j	80001110 <main+0x56>

00000000800011d0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800011d0:	1141                	addi	sp,sp,-16
    800011d2:	e422                	sd	s0,8(sp)
    800011d4:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800011d6:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800011da:	00007797          	auipc	a5,0x7
    800011de:	7d67b783          	ld	a5,2006(a5) # 800089b0 <kernel_pagetable>
    800011e2:	83b1                	srli	a5,a5,0xc
    800011e4:	577d                	li	a4,-1
    800011e6:	177e                	slli	a4,a4,0x3f
    800011e8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800011ea:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800011ee:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800011f2:	6422                	ld	s0,8(sp)
    800011f4:	0141                	addi	sp,sp,16
    800011f6:	8082                	ret

00000000800011f8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800011f8:	7139                	addi	sp,sp,-64
    800011fa:	fc06                	sd	ra,56(sp)
    800011fc:	f822                	sd	s0,48(sp)
    800011fe:	f426                	sd	s1,40(sp)
    80001200:	f04a                	sd	s2,32(sp)
    80001202:	ec4e                	sd	s3,24(sp)
    80001204:	e852                	sd	s4,16(sp)
    80001206:	e456                	sd	s5,8(sp)
    80001208:	e05a                	sd	s6,0(sp)
    8000120a:	0080                	addi	s0,sp,64
    8000120c:	84aa                	mv	s1,a0
    8000120e:	89ae                	mv	s3,a1
    80001210:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001212:	57fd                	li	a5,-1
    80001214:	83e9                	srli	a5,a5,0x1a
    80001216:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001218:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000121a:	04b7f263          	bgeu	a5,a1,8000125e <walk+0x66>
    panic("walk");
    8000121e:	00007517          	auipc	a0,0x7
    80001222:	eb250513          	addi	a0,a0,-334 # 800080d0 <digits+0x90>
    80001226:	fffff097          	auipc	ra,0xfffff
    8000122a:	55a080e7          	jalr	1370(ra) # 80000780 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000122e:	060a8663          	beqz	s5,8000129a <walk+0xa2>
    80001232:	00000097          	auipc	ra,0x0
    80001236:	af6080e7          	jalr	-1290(ra) # 80000d28 <kalloc>
    8000123a:	84aa                	mv	s1,a0
    8000123c:	c529                	beqz	a0,80001286 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000123e:	6605                	lui	a2,0x1
    80001240:	4581                	li	a1,0
    80001242:	00000097          	auipc	ra,0x0
    80001246:	cd2080e7          	jalr	-814(ra) # 80000f14 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000124a:	00c4d793          	srli	a5,s1,0xc
    8000124e:	07aa                	slli	a5,a5,0xa
    80001250:	0017e793          	ori	a5,a5,1
    80001254:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001258:	3a5d                	addiw	s4,s4,-9
    8000125a:	036a0063          	beq	s4,s6,8000127a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000125e:	0149d933          	srl	s2,s3,s4
    80001262:	1ff97913          	andi	s2,s2,511
    80001266:	090e                	slli	s2,s2,0x3
    80001268:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000126a:	00093483          	ld	s1,0(s2)
    8000126e:	0014f793          	andi	a5,s1,1
    80001272:	dfd5                	beqz	a5,8000122e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001274:	80a9                	srli	s1,s1,0xa
    80001276:	04b2                	slli	s1,s1,0xc
    80001278:	b7c5                	j	80001258 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000127a:	00c9d513          	srli	a0,s3,0xc
    8000127e:	1ff57513          	andi	a0,a0,511
    80001282:	050e                	slli	a0,a0,0x3
    80001284:	9526                	add	a0,a0,s1
}
    80001286:	70e2                	ld	ra,56(sp)
    80001288:	7442                	ld	s0,48(sp)
    8000128a:	74a2                	ld	s1,40(sp)
    8000128c:	7902                	ld	s2,32(sp)
    8000128e:	69e2                	ld	s3,24(sp)
    80001290:	6a42                	ld	s4,16(sp)
    80001292:	6aa2                	ld	s5,8(sp)
    80001294:	6b02                	ld	s6,0(sp)
    80001296:	6121                	addi	sp,sp,64
    80001298:	8082                	ret
        return 0;
    8000129a:	4501                	li	a0,0
    8000129c:	b7ed                	j	80001286 <walk+0x8e>

000000008000129e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000129e:	57fd                	li	a5,-1
    800012a0:	83e9                	srli	a5,a5,0x1a
    800012a2:	00b7f463          	bgeu	a5,a1,800012aa <walkaddr+0xc>
    return 0;
    800012a6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800012a8:	8082                	ret
{
    800012aa:	1141                	addi	sp,sp,-16
    800012ac:	e406                	sd	ra,8(sp)
    800012ae:	e022                	sd	s0,0(sp)
    800012b0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800012b2:	4601                	li	a2,0
    800012b4:	00000097          	auipc	ra,0x0
    800012b8:	f44080e7          	jalr	-188(ra) # 800011f8 <walk>
  if(pte == 0)
    800012bc:	c105                	beqz	a0,800012dc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800012be:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800012c0:	0117f693          	andi	a3,a5,17
    800012c4:	4745                	li	a4,17
    return 0;
    800012c6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800012c8:	00e68663          	beq	a3,a4,800012d4 <walkaddr+0x36>
}
    800012cc:	60a2                	ld	ra,8(sp)
    800012ce:	6402                	ld	s0,0(sp)
    800012d0:	0141                	addi	sp,sp,16
    800012d2:	8082                	ret
  pa = PTE2PA(*pte);
    800012d4:	00a7d513          	srli	a0,a5,0xa
    800012d8:	0532                	slli	a0,a0,0xc
  return pa;
    800012da:	bfcd                	j	800012cc <walkaddr+0x2e>
    return 0;
    800012dc:	4501                	li	a0,0
    800012de:	b7fd                	j	800012cc <walkaddr+0x2e>

00000000800012e0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800012e0:	715d                	addi	sp,sp,-80
    800012e2:	e486                	sd	ra,72(sp)
    800012e4:	e0a2                	sd	s0,64(sp)
    800012e6:	fc26                	sd	s1,56(sp)
    800012e8:	f84a                	sd	s2,48(sp)
    800012ea:	f44e                	sd	s3,40(sp)
    800012ec:	f052                	sd	s4,32(sp)
    800012ee:	ec56                	sd	s5,24(sp)
    800012f0:	e85a                	sd	s6,16(sp)
    800012f2:	e45e                	sd	s7,8(sp)
    800012f4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800012f6:	c639                	beqz	a2,80001344 <mappages+0x64>
    800012f8:	8aaa                	mv	s5,a0
    800012fa:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800012fc:	77fd                	lui	a5,0xfffff
    800012fe:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001302:	15fd                	addi	a1,a1,-1
    80001304:	00c589b3          	add	s3,a1,a2
    80001308:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000130c:	8952                	mv	s2,s4
    8000130e:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001312:	6b85                	lui	s7,0x1
    80001314:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001318:	4605                	li	a2,1
    8000131a:	85ca                	mv	a1,s2
    8000131c:	8556                	mv	a0,s5
    8000131e:	00000097          	auipc	ra,0x0
    80001322:	eda080e7          	jalr	-294(ra) # 800011f8 <walk>
    80001326:	cd1d                	beqz	a0,80001364 <mappages+0x84>
    if(*pte & PTE_V)
    80001328:	611c                	ld	a5,0(a0)
    8000132a:	8b85                	andi	a5,a5,1
    8000132c:	e785                	bnez	a5,80001354 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000132e:	80b1                	srli	s1,s1,0xc
    80001330:	04aa                	slli	s1,s1,0xa
    80001332:	0164e4b3          	or	s1,s1,s6
    80001336:	0014e493          	ori	s1,s1,1
    8000133a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000133c:	05390063          	beq	s2,s3,8000137c <mappages+0x9c>
    a += PGSIZE;
    80001340:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001342:	bfc9                	j	80001314 <mappages+0x34>
    panic("mappages: size");
    80001344:	00007517          	auipc	a0,0x7
    80001348:	d9450513          	addi	a0,a0,-620 # 800080d8 <digits+0x98>
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	434080e7          	jalr	1076(ra) # 80000780 <panic>
      panic("mappages: remap");
    80001354:	00007517          	auipc	a0,0x7
    80001358:	d9450513          	addi	a0,a0,-620 # 800080e8 <digits+0xa8>
    8000135c:	fffff097          	auipc	ra,0xfffff
    80001360:	424080e7          	jalr	1060(ra) # 80000780 <panic>
      return -1;
    80001364:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001366:	60a6                	ld	ra,72(sp)
    80001368:	6406                	ld	s0,64(sp)
    8000136a:	74e2                	ld	s1,56(sp)
    8000136c:	7942                	ld	s2,48(sp)
    8000136e:	79a2                	ld	s3,40(sp)
    80001370:	7a02                	ld	s4,32(sp)
    80001372:	6ae2                	ld	s5,24(sp)
    80001374:	6b42                	ld	s6,16(sp)
    80001376:	6ba2                	ld	s7,8(sp)
    80001378:	6161                	addi	sp,sp,80
    8000137a:	8082                	ret
  return 0;
    8000137c:	4501                	li	a0,0
    8000137e:	b7e5                	j	80001366 <mappages+0x86>

0000000080001380 <kvmmap>:
{
    80001380:	1141                	addi	sp,sp,-16
    80001382:	e406                	sd	ra,8(sp)
    80001384:	e022                	sd	s0,0(sp)
    80001386:	0800                	addi	s0,sp,16
    80001388:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000138a:	86b2                	mv	a3,a2
    8000138c:	863e                	mv	a2,a5
    8000138e:	00000097          	auipc	ra,0x0
    80001392:	f52080e7          	jalr	-174(ra) # 800012e0 <mappages>
    80001396:	e509                	bnez	a0,800013a0 <kvmmap+0x20>
}
    80001398:	60a2                	ld	ra,8(sp)
    8000139a:	6402                	ld	s0,0(sp)
    8000139c:	0141                	addi	sp,sp,16
    8000139e:	8082                	ret
    panic("kvmmap");
    800013a0:	00007517          	auipc	a0,0x7
    800013a4:	d5850513          	addi	a0,a0,-680 # 800080f8 <digits+0xb8>
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	3d8080e7          	jalr	984(ra) # 80000780 <panic>

00000000800013b0 <kvmmake>:
{
    800013b0:	1101                	addi	sp,sp,-32
    800013b2:	ec06                	sd	ra,24(sp)
    800013b4:	e822                	sd	s0,16(sp)
    800013b6:	e426                	sd	s1,8(sp)
    800013b8:	e04a                	sd	s2,0(sp)
    800013ba:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	96c080e7          	jalr	-1684(ra) # 80000d28 <kalloc>
    800013c4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800013c6:	6605                	lui	a2,0x1
    800013c8:	4581                	li	a1,0
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	b4a080e7          	jalr	-1206(ra) # 80000f14 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800013d2:	4719                	li	a4,6
    800013d4:	6685                	lui	a3,0x1
    800013d6:	10000637          	lui	a2,0x10000
    800013da:	100005b7          	lui	a1,0x10000
    800013de:	8526                	mv	a0,s1
    800013e0:	00000097          	auipc	ra,0x0
    800013e4:	fa0080e7          	jalr	-96(ra) # 80001380 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800013e8:	4719                	li	a4,6
    800013ea:	6685                	lui	a3,0x1
    800013ec:	10001637          	lui	a2,0x10001
    800013f0:	100015b7          	lui	a1,0x10001
    800013f4:	8526                	mv	a0,s1
    800013f6:	00000097          	auipc	ra,0x0
    800013fa:	f8a080e7          	jalr	-118(ra) # 80001380 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800013fe:	4719                	li	a4,6
    80001400:	004006b7          	lui	a3,0x400
    80001404:	0c000637          	lui	a2,0xc000
    80001408:	0c0005b7          	lui	a1,0xc000
    8000140c:	8526                	mv	a0,s1
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	f72080e7          	jalr	-142(ra) # 80001380 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001416:	00007917          	auipc	s2,0x7
    8000141a:	bea90913          	addi	s2,s2,-1046 # 80008000 <etext>
    8000141e:	4729                	li	a4,10
    80001420:	80007697          	auipc	a3,0x80007
    80001424:	be068693          	addi	a3,a3,-1056 # 8000 <_entry-0x7fff8000>
    80001428:	4605                	li	a2,1
    8000142a:	067e                	slli	a2,a2,0x1f
    8000142c:	85b2                	mv	a1,a2
    8000142e:	8526                	mv	a0,s1
    80001430:	00000097          	auipc	ra,0x0
    80001434:	f50080e7          	jalr	-176(ra) # 80001380 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001438:	4719                	li	a4,6
    8000143a:	46c5                	li	a3,17
    8000143c:	06ee                	slli	a3,a3,0x1b
    8000143e:	412686b3          	sub	a3,a3,s2
    80001442:	864a                	mv	a2,s2
    80001444:	85ca                	mv	a1,s2
    80001446:	8526                	mv	a0,s1
    80001448:	00000097          	auipc	ra,0x0
    8000144c:	f38080e7          	jalr	-200(ra) # 80001380 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001450:	4729                	li	a4,10
    80001452:	6685                	lui	a3,0x1
    80001454:	00006617          	auipc	a2,0x6
    80001458:	bac60613          	addi	a2,a2,-1108 # 80007000 <_trampoline>
    8000145c:	040005b7          	lui	a1,0x4000
    80001460:	15fd                	addi	a1,a1,-1
    80001462:	05b2                	slli	a1,a1,0xc
    80001464:	8526                	mv	a0,s1
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	f1a080e7          	jalr	-230(ra) # 80001380 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000146e:	8526                	mv	a0,s1
    80001470:	00000097          	auipc	ra,0x0
    80001474:	608080e7          	jalr	1544(ra) # 80001a78 <proc_mapstacks>
}
    80001478:	8526                	mv	a0,s1
    8000147a:	60e2                	ld	ra,24(sp)
    8000147c:	6442                	ld	s0,16(sp)
    8000147e:	64a2                	ld	s1,8(sp)
    80001480:	6902                	ld	s2,0(sp)
    80001482:	6105                	addi	sp,sp,32
    80001484:	8082                	ret

0000000080001486 <kvminit>:
{
    80001486:	1141                	addi	sp,sp,-16
    80001488:	e406                	sd	ra,8(sp)
    8000148a:	e022                	sd	s0,0(sp)
    8000148c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	f22080e7          	jalr	-222(ra) # 800013b0 <kvmmake>
    80001496:	00007797          	auipc	a5,0x7
    8000149a:	50a7bd23          	sd	a0,1306(a5) # 800089b0 <kernel_pagetable>
}
    8000149e:	60a2                	ld	ra,8(sp)
    800014a0:	6402                	ld	s0,0(sp)
    800014a2:	0141                	addi	sp,sp,16
    800014a4:	8082                	ret

00000000800014a6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800014a6:	715d                	addi	sp,sp,-80
    800014a8:	e486                	sd	ra,72(sp)
    800014aa:	e0a2                	sd	s0,64(sp)
    800014ac:	fc26                	sd	s1,56(sp)
    800014ae:	f84a                	sd	s2,48(sp)
    800014b0:	f44e                	sd	s3,40(sp)
    800014b2:	f052                	sd	s4,32(sp)
    800014b4:	ec56                	sd	s5,24(sp)
    800014b6:	e85a                	sd	s6,16(sp)
    800014b8:	e45e                	sd	s7,8(sp)
    800014ba:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800014bc:	03459793          	slli	a5,a1,0x34
    800014c0:	e795                	bnez	a5,800014ec <uvmunmap+0x46>
    800014c2:	8a2a                	mv	s4,a0
    800014c4:	892e                	mv	s2,a1
    800014c6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014c8:	0632                	slli	a2,a2,0xc
    800014ca:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800014ce:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014d0:	6b05                	lui	s6,0x1
    800014d2:	0735e263          	bltu	a1,s3,80001536 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800014d6:	60a6                	ld	ra,72(sp)
    800014d8:	6406                	ld	s0,64(sp)
    800014da:	74e2                	ld	s1,56(sp)
    800014dc:	7942                	ld	s2,48(sp)
    800014de:	79a2                	ld	s3,40(sp)
    800014e0:	7a02                	ld	s4,32(sp)
    800014e2:	6ae2                	ld	s5,24(sp)
    800014e4:	6b42                	ld	s6,16(sp)
    800014e6:	6ba2                	ld	s7,8(sp)
    800014e8:	6161                	addi	sp,sp,80
    800014ea:	8082                	ret
    panic("uvmunmap: not aligned");
    800014ec:	00007517          	auipc	a0,0x7
    800014f0:	c1450513          	addi	a0,a0,-1004 # 80008100 <digits+0xc0>
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	28c080e7          	jalr	652(ra) # 80000780 <panic>
      panic("uvmunmap: walk");
    800014fc:	00007517          	auipc	a0,0x7
    80001500:	c1c50513          	addi	a0,a0,-996 # 80008118 <digits+0xd8>
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	27c080e7          	jalr	636(ra) # 80000780 <panic>
      panic("uvmunmap: not mapped");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c1c50513          	addi	a0,a0,-996 # 80008128 <digits+0xe8>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	26c080e7          	jalr	620(ra) # 80000780 <panic>
      panic("uvmunmap: not a leaf");
    8000151c:	00007517          	auipc	a0,0x7
    80001520:	c2450513          	addi	a0,a0,-988 # 80008140 <digits+0x100>
    80001524:	fffff097          	auipc	ra,0xfffff
    80001528:	25c080e7          	jalr	604(ra) # 80000780 <panic>
    *pte = 0;
    8000152c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001530:	995a                	add	s2,s2,s6
    80001532:	fb3972e3          	bgeu	s2,s3,800014d6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001536:	4601                	li	a2,0
    80001538:	85ca                	mv	a1,s2
    8000153a:	8552                	mv	a0,s4
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	cbc080e7          	jalr	-836(ra) # 800011f8 <walk>
    80001544:	84aa                	mv	s1,a0
    80001546:	d95d                	beqz	a0,800014fc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001548:	6108                	ld	a0,0(a0)
    8000154a:	00157793          	andi	a5,a0,1
    8000154e:	dfdd                	beqz	a5,8000150c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001550:	3ff57793          	andi	a5,a0,1023
    80001554:	fd7784e3          	beq	a5,s7,8000151c <uvmunmap+0x76>
    if(do_free){
    80001558:	fc0a8ae3          	beqz	s5,8000152c <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000155c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000155e:	0532                	slli	a0,a0,0xc
    80001560:	fffff097          	auipc	ra,0xfffff
    80001564:	6cc080e7          	jalr	1740(ra) # 80000c2c <kfree>
    80001568:	b7d1                	j	8000152c <uvmunmap+0x86>

000000008000156a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000156a:	1101                	addi	sp,sp,-32
    8000156c:	ec06                	sd	ra,24(sp)
    8000156e:	e822                	sd	s0,16(sp)
    80001570:	e426                	sd	s1,8(sp)
    80001572:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	7b4080e7          	jalr	1972(ra) # 80000d28 <kalloc>
    8000157c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000157e:	c519                	beqz	a0,8000158c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001580:	6605                	lui	a2,0x1
    80001582:	4581                	li	a1,0
    80001584:	00000097          	auipc	ra,0x0
    80001588:	990080e7          	jalr	-1648(ra) # 80000f14 <memset>
  return pagetable;
}
    8000158c:	8526                	mv	a0,s1
    8000158e:	60e2                	ld	ra,24(sp)
    80001590:	6442                	ld	s0,16(sp)
    80001592:	64a2                	ld	s1,8(sp)
    80001594:	6105                	addi	sp,sp,32
    80001596:	8082                	ret

0000000080001598 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001598:	7179                	addi	sp,sp,-48
    8000159a:	f406                	sd	ra,40(sp)
    8000159c:	f022                	sd	s0,32(sp)
    8000159e:	ec26                	sd	s1,24(sp)
    800015a0:	e84a                	sd	s2,16(sp)
    800015a2:	e44e                	sd	s3,8(sp)
    800015a4:	e052                	sd	s4,0(sp)
    800015a6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800015a8:	6785                	lui	a5,0x1
    800015aa:	04f67863          	bgeu	a2,a5,800015fa <uvmfirst+0x62>
    800015ae:	8a2a                	mv	s4,a0
    800015b0:	89ae                	mv	s3,a1
    800015b2:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800015b4:	fffff097          	auipc	ra,0xfffff
    800015b8:	774080e7          	jalr	1908(ra) # 80000d28 <kalloc>
    800015bc:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	4581                	li	a1,0
    800015c2:	00000097          	auipc	ra,0x0
    800015c6:	952080e7          	jalr	-1710(ra) # 80000f14 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800015ca:	4779                	li	a4,30
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	4581                	li	a1,0
    800015d2:	8552                	mv	a0,s4
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	d0c080e7          	jalr	-756(ra) # 800012e0 <mappages>
  memmove(mem, src, sz);
    800015dc:	8626                	mv	a2,s1
    800015de:	85ce                	mv	a1,s3
    800015e0:	854a                	mv	a0,s2
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	98e080e7          	jalr	-1650(ra) # 80000f70 <memmove>
}
    800015ea:	70a2                	ld	ra,40(sp)
    800015ec:	7402                	ld	s0,32(sp)
    800015ee:	64e2                	ld	s1,24(sp)
    800015f0:	6942                	ld	s2,16(sp)
    800015f2:	69a2                	ld	s3,8(sp)
    800015f4:	6a02                	ld	s4,0(sp)
    800015f6:	6145                	addi	sp,sp,48
    800015f8:	8082                	ret
    panic("uvmfirst: more than a page");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b5e50513          	addi	a0,a0,-1186 # 80008158 <digits+0x118>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	17e080e7          	jalr	382(ra) # 80000780 <panic>

000000008000160a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000160a:	1101                	addi	sp,sp,-32
    8000160c:	ec06                	sd	ra,24(sp)
    8000160e:	e822                	sd	s0,16(sp)
    80001610:	e426                	sd	s1,8(sp)
    80001612:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001614:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001616:	00b67d63          	bgeu	a2,a1,80001630 <uvmdealloc+0x26>
    8000161a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000161c:	6785                	lui	a5,0x1
    8000161e:	17fd                	addi	a5,a5,-1
    80001620:	00f60733          	add	a4,a2,a5
    80001624:	767d                	lui	a2,0xfffff
    80001626:	8f71                	and	a4,a4,a2
    80001628:	97ae                	add	a5,a5,a1
    8000162a:	8ff1                	and	a5,a5,a2
    8000162c:	00f76863          	bltu	a4,a5,8000163c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001630:	8526                	mv	a0,s1
    80001632:	60e2                	ld	ra,24(sp)
    80001634:	6442                	ld	s0,16(sp)
    80001636:	64a2                	ld	s1,8(sp)
    80001638:	6105                	addi	sp,sp,32
    8000163a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000163c:	8f99                	sub	a5,a5,a4
    8000163e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001640:	4685                	li	a3,1
    80001642:	0007861b          	sext.w	a2,a5
    80001646:	85ba                	mv	a1,a4
    80001648:	00000097          	auipc	ra,0x0
    8000164c:	e5e080e7          	jalr	-418(ra) # 800014a6 <uvmunmap>
    80001650:	b7c5                	j	80001630 <uvmdealloc+0x26>

0000000080001652 <uvmalloc>:
  if(newsz < oldsz)
    80001652:	0ab66563          	bltu	a2,a1,800016fc <uvmalloc+0xaa>
{
    80001656:	7139                	addi	sp,sp,-64
    80001658:	fc06                	sd	ra,56(sp)
    8000165a:	f822                	sd	s0,48(sp)
    8000165c:	f426                	sd	s1,40(sp)
    8000165e:	f04a                	sd	s2,32(sp)
    80001660:	ec4e                	sd	s3,24(sp)
    80001662:	e852                	sd	s4,16(sp)
    80001664:	e456                	sd	s5,8(sp)
    80001666:	e05a                	sd	s6,0(sp)
    80001668:	0080                	addi	s0,sp,64
    8000166a:	8aaa                	mv	s5,a0
    8000166c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000166e:	6985                	lui	s3,0x1
    80001670:	19fd                	addi	s3,s3,-1
    80001672:	95ce                	add	a1,a1,s3
    80001674:	79fd                	lui	s3,0xfffff
    80001676:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000167a:	08c9f363          	bgeu	s3,a2,80001700 <uvmalloc+0xae>
    8000167e:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001680:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	6a4080e7          	jalr	1700(ra) # 80000d28 <kalloc>
    8000168c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000168e:	c51d                	beqz	a0,800016bc <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001690:	6605                	lui	a2,0x1
    80001692:	4581                	li	a1,0
    80001694:	00000097          	auipc	ra,0x0
    80001698:	880080e7          	jalr	-1920(ra) # 80000f14 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000169c:	875a                	mv	a4,s6
    8000169e:	86a6                	mv	a3,s1
    800016a0:	6605                	lui	a2,0x1
    800016a2:	85ca                	mv	a1,s2
    800016a4:	8556                	mv	a0,s5
    800016a6:	00000097          	auipc	ra,0x0
    800016aa:	c3a080e7          	jalr	-966(ra) # 800012e0 <mappages>
    800016ae:	e90d                	bnez	a0,800016e0 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800016b0:	6785                	lui	a5,0x1
    800016b2:	993e                	add	s2,s2,a5
    800016b4:	fd4968e3          	bltu	s2,s4,80001684 <uvmalloc+0x32>
  return newsz;
    800016b8:	8552                	mv	a0,s4
    800016ba:	a809                	j	800016cc <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800016bc:	864e                	mv	a2,s3
    800016be:	85ca                	mv	a1,s2
    800016c0:	8556                	mv	a0,s5
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	f48080e7          	jalr	-184(ra) # 8000160a <uvmdealloc>
      return 0;
    800016ca:	4501                	li	a0,0
}
    800016cc:	70e2                	ld	ra,56(sp)
    800016ce:	7442                	ld	s0,48(sp)
    800016d0:	74a2                	ld	s1,40(sp)
    800016d2:	7902                	ld	s2,32(sp)
    800016d4:	69e2                	ld	s3,24(sp)
    800016d6:	6a42                	ld	s4,16(sp)
    800016d8:	6aa2                	ld	s5,8(sp)
    800016da:	6b02                	ld	s6,0(sp)
    800016dc:	6121                	addi	sp,sp,64
    800016de:	8082                	ret
      kfree(mem);
    800016e0:	8526                	mv	a0,s1
    800016e2:	fffff097          	auipc	ra,0xfffff
    800016e6:	54a080e7          	jalr	1354(ra) # 80000c2c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800016ea:	864e                	mv	a2,s3
    800016ec:	85ca                	mv	a1,s2
    800016ee:	8556                	mv	a0,s5
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	f1a080e7          	jalr	-230(ra) # 8000160a <uvmdealloc>
      return 0;
    800016f8:	4501                	li	a0,0
    800016fa:	bfc9                	j	800016cc <uvmalloc+0x7a>
    return oldsz;
    800016fc:	852e                	mv	a0,a1
}
    800016fe:	8082                	ret
  return newsz;
    80001700:	8532                	mv	a0,a2
    80001702:	b7e9                	j	800016cc <uvmalloc+0x7a>

0000000080001704 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001704:	7179                	addi	sp,sp,-48
    80001706:	f406                	sd	ra,40(sp)
    80001708:	f022                	sd	s0,32(sp)
    8000170a:	ec26                	sd	s1,24(sp)
    8000170c:	e84a                	sd	s2,16(sp)
    8000170e:	e44e                	sd	s3,8(sp)
    80001710:	e052                	sd	s4,0(sp)
    80001712:	1800                	addi	s0,sp,48
    80001714:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001716:	84aa                	mv	s1,a0
    80001718:	6905                	lui	s2,0x1
    8000171a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000171c:	4985                	li	s3,1
    8000171e:	a821                	j	80001736 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001720:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001722:	0532                	slli	a0,a0,0xc
    80001724:	00000097          	auipc	ra,0x0
    80001728:	fe0080e7          	jalr	-32(ra) # 80001704 <freewalk>
      pagetable[i] = 0;
    8000172c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001730:	04a1                	addi	s1,s1,8
    80001732:	03248163          	beq	s1,s2,80001754 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001736:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001738:	00f57793          	andi	a5,a0,15
    8000173c:	ff3782e3          	beq	a5,s3,80001720 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001740:	8905                	andi	a0,a0,1
    80001742:	d57d                	beqz	a0,80001730 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001744:	00007517          	auipc	a0,0x7
    80001748:	a3450513          	addi	a0,a0,-1484 # 80008178 <digits+0x138>
    8000174c:	fffff097          	auipc	ra,0xfffff
    80001750:	034080e7          	jalr	52(ra) # 80000780 <panic>
    }
  }
  kfree((void*)pagetable);
    80001754:	8552                	mv	a0,s4
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	4d6080e7          	jalr	1238(ra) # 80000c2c <kfree>
}
    8000175e:	70a2                	ld	ra,40(sp)
    80001760:	7402                	ld	s0,32(sp)
    80001762:	64e2                	ld	s1,24(sp)
    80001764:	6942                	ld	s2,16(sp)
    80001766:	69a2                	ld	s3,8(sp)
    80001768:	6a02                	ld	s4,0(sp)
    8000176a:	6145                	addi	sp,sp,48
    8000176c:	8082                	ret

000000008000176e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000176e:	1101                	addi	sp,sp,-32
    80001770:	ec06                	sd	ra,24(sp)
    80001772:	e822                	sd	s0,16(sp)
    80001774:	e426                	sd	s1,8(sp)
    80001776:	1000                	addi	s0,sp,32
    80001778:	84aa                	mv	s1,a0
  if(sz > 0)
    8000177a:	e999                	bnez	a1,80001790 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000177c:	8526                	mv	a0,s1
    8000177e:	00000097          	auipc	ra,0x0
    80001782:	f86080e7          	jalr	-122(ra) # 80001704 <freewalk>
}
    80001786:	60e2                	ld	ra,24(sp)
    80001788:	6442                	ld	s0,16(sp)
    8000178a:	64a2                	ld	s1,8(sp)
    8000178c:	6105                	addi	sp,sp,32
    8000178e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001790:	6605                	lui	a2,0x1
    80001792:	167d                	addi	a2,a2,-1
    80001794:	962e                	add	a2,a2,a1
    80001796:	4685                	li	a3,1
    80001798:	8231                	srli	a2,a2,0xc
    8000179a:	4581                	li	a1,0
    8000179c:	00000097          	auipc	ra,0x0
    800017a0:	d0a080e7          	jalr	-758(ra) # 800014a6 <uvmunmap>
    800017a4:	bfe1                	j	8000177c <uvmfree+0xe>

00000000800017a6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800017a6:	c679                	beqz	a2,80001874 <uvmcopy+0xce>
{
    800017a8:	715d                	addi	sp,sp,-80
    800017aa:	e486                	sd	ra,72(sp)
    800017ac:	e0a2                	sd	s0,64(sp)
    800017ae:	fc26                	sd	s1,56(sp)
    800017b0:	f84a                	sd	s2,48(sp)
    800017b2:	f44e                	sd	s3,40(sp)
    800017b4:	f052                	sd	s4,32(sp)
    800017b6:	ec56                	sd	s5,24(sp)
    800017b8:	e85a                	sd	s6,16(sp)
    800017ba:	e45e                	sd	s7,8(sp)
    800017bc:	0880                	addi	s0,sp,80
    800017be:	8b2a                	mv	s6,a0
    800017c0:	8aae                	mv	s5,a1
    800017c2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800017c4:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800017c6:	4601                	li	a2,0
    800017c8:	85ce                	mv	a1,s3
    800017ca:	855a                	mv	a0,s6
    800017cc:	00000097          	auipc	ra,0x0
    800017d0:	a2c080e7          	jalr	-1492(ra) # 800011f8 <walk>
    800017d4:	c531                	beqz	a0,80001820 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800017d6:	6118                	ld	a4,0(a0)
    800017d8:	00177793          	andi	a5,a4,1
    800017dc:	cbb1                	beqz	a5,80001830 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800017de:	00a75593          	srli	a1,a4,0xa
    800017e2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800017e6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800017ea:	fffff097          	auipc	ra,0xfffff
    800017ee:	53e080e7          	jalr	1342(ra) # 80000d28 <kalloc>
    800017f2:	892a                	mv	s2,a0
    800017f4:	c939                	beqz	a0,8000184a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800017f6:	6605                	lui	a2,0x1
    800017f8:	85de                	mv	a1,s7
    800017fa:	fffff097          	auipc	ra,0xfffff
    800017fe:	776080e7          	jalr	1910(ra) # 80000f70 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001802:	8726                	mv	a4,s1
    80001804:	86ca                	mv	a3,s2
    80001806:	6605                	lui	a2,0x1
    80001808:	85ce                	mv	a1,s3
    8000180a:	8556                	mv	a0,s5
    8000180c:	00000097          	auipc	ra,0x0
    80001810:	ad4080e7          	jalr	-1324(ra) # 800012e0 <mappages>
    80001814:	e515                	bnez	a0,80001840 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001816:	6785                	lui	a5,0x1
    80001818:	99be                	add	s3,s3,a5
    8000181a:	fb49e6e3          	bltu	s3,s4,800017c6 <uvmcopy+0x20>
    8000181e:	a081                	j	8000185e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001820:	00007517          	auipc	a0,0x7
    80001824:	96850513          	addi	a0,a0,-1688 # 80008188 <digits+0x148>
    80001828:	fffff097          	auipc	ra,0xfffff
    8000182c:	f58080e7          	jalr	-168(ra) # 80000780 <panic>
      panic("uvmcopy: page not present");
    80001830:	00007517          	auipc	a0,0x7
    80001834:	97850513          	addi	a0,a0,-1672 # 800081a8 <digits+0x168>
    80001838:	fffff097          	auipc	ra,0xfffff
    8000183c:	f48080e7          	jalr	-184(ra) # 80000780 <panic>
      kfree(mem);
    80001840:	854a                	mv	a0,s2
    80001842:	fffff097          	auipc	ra,0xfffff
    80001846:	3ea080e7          	jalr	1002(ra) # 80000c2c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000184a:	4685                	li	a3,1
    8000184c:	00c9d613          	srli	a2,s3,0xc
    80001850:	4581                	li	a1,0
    80001852:	8556                	mv	a0,s5
    80001854:	00000097          	auipc	ra,0x0
    80001858:	c52080e7          	jalr	-942(ra) # 800014a6 <uvmunmap>
  return -1;
    8000185c:	557d                	li	a0,-1
}
    8000185e:	60a6                	ld	ra,72(sp)
    80001860:	6406                	ld	s0,64(sp)
    80001862:	74e2                	ld	s1,56(sp)
    80001864:	7942                	ld	s2,48(sp)
    80001866:	79a2                	ld	s3,40(sp)
    80001868:	7a02                	ld	s4,32(sp)
    8000186a:	6ae2                	ld	s5,24(sp)
    8000186c:	6b42                	ld	s6,16(sp)
    8000186e:	6ba2                	ld	s7,8(sp)
    80001870:	6161                	addi	sp,sp,80
    80001872:	8082                	ret
  return 0;
    80001874:	4501                	li	a0,0
}
    80001876:	8082                	ret

0000000080001878 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001878:	1141                	addi	sp,sp,-16
    8000187a:	e406                	sd	ra,8(sp)
    8000187c:	e022                	sd	s0,0(sp)
    8000187e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001880:	4601                	li	a2,0
    80001882:	00000097          	auipc	ra,0x0
    80001886:	976080e7          	jalr	-1674(ra) # 800011f8 <walk>
  if(pte == 0)
    8000188a:	c901                	beqz	a0,8000189a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000188c:	611c                	ld	a5,0(a0)
    8000188e:	9bbd                	andi	a5,a5,-17
    80001890:	e11c                	sd	a5,0(a0)
}
    80001892:	60a2                	ld	ra,8(sp)
    80001894:	6402                	ld	s0,0(sp)
    80001896:	0141                	addi	sp,sp,16
    80001898:	8082                	ret
    panic("uvmclear");
    8000189a:	00007517          	auipc	a0,0x7
    8000189e:	92e50513          	addi	a0,a0,-1746 # 800081c8 <digits+0x188>
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	ede080e7          	jalr	-290(ra) # 80000780 <panic>

00000000800018aa <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018aa:	c6bd                	beqz	a3,80001918 <copyout+0x6e>
{
    800018ac:	715d                	addi	sp,sp,-80
    800018ae:	e486                	sd	ra,72(sp)
    800018b0:	e0a2                	sd	s0,64(sp)
    800018b2:	fc26                	sd	s1,56(sp)
    800018b4:	f84a                	sd	s2,48(sp)
    800018b6:	f44e                	sd	s3,40(sp)
    800018b8:	f052                	sd	s4,32(sp)
    800018ba:	ec56                	sd	s5,24(sp)
    800018bc:	e85a                	sd	s6,16(sp)
    800018be:	e45e                	sd	s7,8(sp)
    800018c0:	e062                	sd	s8,0(sp)
    800018c2:	0880                	addi	s0,sp,80
    800018c4:	8b2a                	mv	s6,a0
    800018c6:	8c2e                	mv	s8,a1
    800018c8:	8a32                	mv	s4,a2
    800018ca:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800018cc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800018ce:	6a85                	lui	s5,0x1
    800018d0:	a015                	j	800018f4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018d2:	9562                	add	a0,a0,s8
    800018d4:	0004861b          	sext.w	a2,s1
    800018d8:	85d2                	mv	a1,s4
    800018da:	41250533          	sub	a0,a0,s2
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	692080e7          	jalr	1682(ra) # 80000f70 <memmove>

    len -= n;
    800018e6:	409989b3          	sub	s3,s3,s1
    src += n;
    800018ea:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800018ec:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018f0:	02098263          	beqz	s3,80001914 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800018f4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018f8:	85ca                	mv	a1,s2
    800018fa:	855a                	mv	a0,s6
    800018fc:	00000097          	auipc	ra,0x0
    80001900:	9a2080e7          	jalr	-1630(ra) # 8000129e <walkaddr>
    if(pa0 == 0)
    80001904:	cd01                	beqz	a0,8000191c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001906:	418904b3          	sub	s1,s2,s8
    8000190a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000190c:	fc99f3e3          	bgeu	s3,s1,800018d2 <copyout+0x28>
    80001910:	84ce                	mv	s1,s3
    80001912:	b7c1                	j	800018d2 <copyout+0x28>
  }
  return 0;
    80001914:	4501                	li	a0,0
    80001916:	a021                	j	8000191e <copyout+0x74>
    80001918:	4501                	li	a0,0
}
    8000191a:	8082                	ret
      return -1;
    8000191c:	557d                	li	a0,-1
}
    8000191e:	60a6                	ld	ra,72(sp)
    80001920:	6406                	ld	s0,64(sp)
    80001922:	74e2                	ld	s1,56(sp)
    80001924:	7942                	ld	s2,48(sp)
    80001926:	79a2                	ld	s3,40(sp)
    80001928:	7a02                	ld	s4,32(sp)
    8000192a:	6ae2                	ld	s5,24(sp)
    8000192c:	6b42                	ld	s6,16(sp)
    8000192e:	6ba2                	ld	s7,8(sp)
    80001930:	6c02                	ld	s8,0(sp)
    80001932:	6161                	addi	sp,sp,80
    80001934:	8082                	ret

0000000080001936 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001936:	caa5                	beqz	a3,800019a6 <copyin+0x70>
{
    80001938:	715d                	addi	sp,sp,-80
    8000193a:	e486                	sd	ra,72(sp)
    8000193c:	e0a2                	sd	s0,64(sp)
    8000193e:	fc26                	sd	s1,56(sp)
    80001940:	f84a                	sd	s2,48(sp)
    80001942:	f44e                	sd	s3,40(sp)
    80001944:	f052                	sd	s4,32(sp)
    80001946:	ec56                	sd	s5,24(sp)
    80001948:	e85a                	sd	s6,16(sp)
    8000194a:	e45e                	sd	s7,8(sp)
    8000194c:	e062                	sd	s8,0(sp)
    8000194e:	0880                	addi	s0,sp,80
    80001950:	8b2a                	mv	s6,a0
    80001952:	8a2e                	mv	s4,a1
    80001954:	8c32                	mv	s8,a2
    80001956:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001958:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000195a:	6a85                	lui	s5,0x1
    8000195c:	a01d                	j	80001982 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000195e:	018505b3          	add	a1,a0,s8
    80001962:	0004861b          	sext.w	a2,s1
    80001966:	412585b3          	sub	a1,a1,s2
    8000196a:	8552                	mv	a0,s4
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	604080e7          	jalr	1540(ra) # 80000f70 <memmove>

    len -= n;
    80001974:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001978:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000197a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000197e:	02098263          	beqz	s3,800019a2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001982:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001986:	85ca                	mv	a1,s2
    80001988:	855a                	mv	a0,s6
    8000198a:	00000097          	auipc	ra,0x0
    8000198e:	914080e7          	jalr	-1772(ra) # 8000129e <walkaddr>
    if(pa0 == 0)
    80001992:	cd01                	beqz	a0,800019aa <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001994:	418904b3          	sub	s1,s2,s8
    80001998:	94d6                	add	s1,s1,s5
    if(n > len)
    8000199a:	fc99f2e3          	bgeu	s3,s1,8000195e <copyin+0x28>
    8000199e:	84ce                	mv	s1,s3
    800019a0:	bf7d                	j	8000195e <copyin+0x28>
  }
  return 0;
    800019a2:	4501                	li	a0,0
    800019a4:	a021                	j	800019ac <copyin+0x76>
    800019a6:	4501                	li	a0,0
}
    800019a8:	8082                	ret
      return -1;
    800019aa:	557d                	li	a0,-1
}
    800019ac:	60a6                	ld	ra,72(sp)
    800019ae:	6406                	ld	s0,64(sp)
    800019b0:	74e2                	ld	s1,56(sp)
    800019b2:	7942                	ld	s2,48(sp)
    800019b4:	79a2                	ld	s3,40(sp)
    800019b6:	7a02                	ld	s4,32(sp)
    800019b8:	6ae2                	ld	s5,24(sp)
    800019ba:	6b42                	ld	s6,16(sp)
    800019bc:	6ba2                	ld	s7,8(sp)
    800019be:	6c02                	ld	s8,0(sp)
    800019c0:	6161                	addi	sp,sp,80
    800019c2:	8082                	ret

00000000800019c4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800019c4:	c6c5                	beqz	a3,80001a6c <copyinstr+0xa8>
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
    800019dc:	8a2a                	mv	s4,a0
    800019de:	8b2e                	mv	s6,a1
    800019e0:	8bb2                	mv	s7,a2
    800019e2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800019e4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800019e6:	6985                	lui	s3,0x1
    800019e8:	a035                	j	80001a14 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800019ea:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800019ee:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800019f0:	0017b793          	seqz	a5,a5
    800019f4:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800019f8:	60a6                	ld	ra,72(sp)
    800019fa:	6406                	ld	s0,64(sp)
    800019fc:	74e2                	ld	s1,56(sp)
    800019fe:	7942                	ld	s2,48(sp)
    80001a00:	79a2                	ld	s3,40(sp)
    80001a02:	7a02                	ld	s4,32(sp)
    80001a04:	6ae2                	ld	s5,24(sp)
    80001a06:	6b42                	ld	s6,16(sp)
    80001a08:	6ba2                	ld	s7,8(sp)
    80001a0a:	6161                	addi	sp,sp,80
    80001a0c:	8082                	ret
    srcva = va0 + PGSIZE;
    80001a0e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001a12:	c8a9                	beqz	s1,80001a64 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001a14:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001a18:	85ca                	mv	a1,s2
    80001a1a:	8552                	mv	a0,s4
    80001a1c:	00000097          	auipc	ra,0x0
    80001a20:	882080e7          	jalr	-1918(ra) # 8000129e <walkaddr>
    if(pa0 == 0)
    80001a24:	c131                	beqz	a0,80001a68 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001a26:	41790833          	sub	a6,s2,s7
    80001a2a:	984e                	add	a6,a6,s3
    if(n > max)
    80001a2c:	0104f363          	bgeu	s1,a6,80001a32 <copyinstr+0x6e>
    80001a30:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001a32:	955e                	add	a0,a0,s7
    80001a34:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001a38:	fc080be3          	beqz	a6,80001a0e <copyinstr+0x4a>
    80001a3c:	985a                	add	a6,a6,s6
    80001a3e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001a40:	41650633          	sub	a2,a0,s6
    80001a44:	14fd                	addi	s1,s1,-1
    80001a46:	9b26                	add	s6,s6,s1
    80001a48:	00f60733          	add	a4,a2,a5
    80001a4c:	00074703          	lbu	a4,0(a4)
    80001a50:	df49                	beqz	a4,800019ea <copyinstr+0x26>
        *dst = *p;
    80001a52:	00e78023          	sb	a4,0(a5)
      --max;
    80001a56:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001a5a:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a5c:	ff0796e3          	bne	a5,a6,80001a48 <copyinstr+0x84>
      dst++;
    80001a60:	8b42                	mv	s6,a6
    80001a62:	b775                	j	80001a0e <copyinstr+0x4a>
    80001a64:	4781                	li	a5,0
    80001a66:	b769                	j	800019f0 <copyinstr+0x2c>
      return -1;
    80001a68:	557d                	li	a0,-1
    80001a6a:	b779                	j	800019f8 <copyinstr+0x34>
  int got_null = 0;
    80001a6c:	4781                	li	a5,0
  if(got_null){
    80001a6e:	0017b793          	seqz	a5,a5
    80001a72:	40f00533          	neg	a0,a5
}
    80001a76:	8082                	ret

0000000080001a78 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001a78:	7139                	addi	sp,sp,-64
    80001a7a:	fc06                	sd	ra,56(sp)
    80001a7c:	f822                	sd	s0,48(sp)
    80001a7e:	f426                	sd	s1,40(sp)
    80001a80:	f04a                	sd	s2,32(sp)
    80001a82:	ec4e                	sd	s3,24(sp)
    80001a84:	e852                	sd	s4,16(sp)
    80001a86:	e456                	sd	s5,8(sp)
    80001a88:	e05a                	sd	s6,0(sp)
    80001a8a:	0080                	addi	s0,sp,64
    80001a8c:	89aa                	mv	s3,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001a8e:	00010497          	auipc	s1,0x10
    80001a92:	5da48493          	addi	s1,s1,1498 # 80012068 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a96:	8b26                	mv	s6,s1
    80001a98:	00006a97          	auipc	s5,0x6
    80001a9c:	568a8a93          	addi	s5,s5,1384 # 80008000 <etext>
    80001aa0:	04000937          	lui	s2,0x4000
    80001aa4:	197d                	addi	s2,s2,-1
    80001aa6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aa8:	00016a17          	auipc	s4,0x16
    80001aac:	fc0a0a13          	addi	s4,s4,-64 # 80017a68 <tickslock>
    char *pa = kalloc();
    80001ab0:	fffff097          	auipc	ra,0xfffff
    80001ab4:	278080e7          	jalr	632(ra) # 80000d28 <kalloc>
    80001ab8:	862a                	mv	a2,a0
    if(pa == 0)
    80001aba:	c131                	beqz	a0,80001afe <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001abc:	416485b3          	sub	a1,s1,s6
    80001ac0:	858d                	srai	a1,a1,0x3
    80001ac2:	000ab783          	ld	a5,0(s5)
    80001ac6:	02f585b3          	mul	a1,a1,a5
    80001aca:	2585                	addiw	a1,a1,1
    80001acc:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ad0:	4719                	li	a4,6
    80001ad2:	6685                	lui	a3,0x1
    80001ad4:	40b905b3          	sub	a1,s2,a1
    80001ad8:	854e                	mv	a0,s3
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	8a6080e7          	jalr	-1882(ra) # 80001380 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ae2:	16848493          	addi	s1,s1,360
    80001ae6:	fd4495e3          	bne	s1,s4,80001ab0 <proc_mapstacks+0x38>
  }
}
    80001aea:	70e2                	ld	ra,56(sp)
    80001aec:	7442                	ld	s0,48(sp)
    80001aee:	74a2                	ld	s1,40(sp)
    80001af0:	7902                	ld	s2,32(sp)
    80001af2:	69e2                	ld	s3,24(sp)
    80001af4:	6a42                	ld	s4,16(sp)
    80001af6:	6aa2                	ld	s5,8(sp)
    80001af8:	6b02                	ld	s6,0(sp)
    80001afa:	6121                	addi	sp,sp,64
    80001afc:	8082                	ret
      panic("kalloc");
    80001afe:	00006517          	auipc	a0,0x6
    80001b02:	6da50513          	addi	a0,a0,1754 # 800081d8 <digits+0x198>
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	c7a080e7          	jalr	-902(ra) # 80000780 <panic>

0000000080001b0e <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001b0e:	7139                	addi	sp,sp,-64
    80001b10:	fc06                	sd	ra,56(sp)
    80001b12:	f822                	sd	s0,48(sp)
    80001b14:	f426                	sd	s1,40(sp)
    80001b16:	f04a                	sd	s2,32(sp)
    80001b18:	ec4e                	sd	s3,24(sp)
    80001b1a:	e852                	sd	s4,16(sp)
    80001b1c:	e456                	sd	s5,8(sp)
    80001b1e:	e05a                	sd	s6,0(sp)
    80001b20:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001b22:	00006597          	auipc	a1,0x6
    80001b26:	6be58593          	addi	a1,a1,1726 # 800081e0 <digits+0x1a0>
    80001b2a:	00010517          	auipc	a0,0x10
    80001b2e:	9d650513          	addi	a0,a0,-1578 # 80011500 <pid_lock>
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	256080e7          	jalr	598(ra) # 80000d88 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b3a:	00006597          	auipc	a1,0x6
    80001b3e:	6ae58593          	addi	a1,a1,1710 # 800081e8 <digits+0x1a8>
    80001b42:	00010517          	auipc	a0,0x10
    80001b46:	9d650513          	addi	a0,a0,-1578 # 80011518 <wait_lock>
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	23e080e7          	jalr	574(ra) # 80000d88 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b52:	00010497          	auipc	s1,0x10
    80001b56:	51648493          	addi	s1,s1,1302 # 80012068 <proc>
      initlock(&p->lock, "proc");
    80001b5a:	00006b17          	auipc	s6,0x6
    80001b5e:	69eb0b13          	addi	s6,s6,1694 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001b62:	8aa6                	mv	s5,s1
    80001b64:	00006a17          	auipc	s4,0x6
    80001b68:	49ca0a13          	addi	s4,s4,1180 # 80008000 <etext>
    80001b6c:	04000937          	lui	s2,0x4000
    80001b70:	197d                	addi	s2,s2,-1
    80001b72:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b74:	00016997          	auipc	s3,0x16
    80001b78:	ef498993          	addi	s3,s3,-268 # 80017a68 <tickslock>
      initlock(&p->lock, "proc");
    80001b7c:	85da                	mv	a1,s6
    80001b7e:	8526                	mv	a0,s1
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	208080e7          	jalr	520(ra) # 80000d88 <initlock>
      p->state = UNUSED;
    80001b88:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001b8c:	415487b3          	sub	a5,s1,s5
    80001b90:	878d                	srai	a5,a5,0x3
    80001b92:	000a3703          	ld	a4,0(s4)
    80001b96:	02e787b3          	mul	a5,a5,a4
    80001b9a:	2785                	addiw	a5,a5,1
    80001b9c:	00d7979b          	slliw	a5,a5,0xd
    80001ba0:	40f907b3          	sub	a5,s2,a5
    80001ba4:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ba6:	16848493          	addi	s1,s1,360
    80001baa:	fd3499e3          	bne	s1,s3,80001b7c <procinit+0x6e>
  }
}
    80001bae:	70e2                	ld	ra,56(sp)
    80001bb0:	7442                	ld	s0,48(sp)
    80001bb2:	74a2                	ld	s1,40(sp)
    80001bb4:	7902                	ld	s2,32(sp)
    80001bb6:	69e2                	ld	s3,24(sp)
    80001bb8:	6a42                	ld	s4,16(sp)
    80001bba:	6aa2                	ld	s5,8(sp)
    80001bbc:	6b02                	ld	s6,0(sp)
    80001bbe:	6121                	addi	sp,sp,64
    80001bc0:	8082                	ret

0000000080001bc2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001bc2:	1141                	addi	sp,sp,-16
    80001bc4:	e422                	sd	s0,8(sp)
    80001bc6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bc8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001bca:	2501                	sext.w	a0,a0
    80001bcc:	6422                	ld	s0,8(sp)
    80001bce:	0141                	addi	sp,sp,16
    80001bd0:	8082                	ret

0000000080001bd2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001bd2:	1141                	addi	sp,sp,-16
    80001bd4:	e422                	sd	s0,8(sp)
    80001bd6:	0800                	addi	s0,sp,16
    80001bd8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001bda:	2781                	sext.w	a5,a5
    80001bdc:	079e                	slli	a5,a5,0x7
  return c;
}
    80001bde:	00010517          	auipc	a0,0x10
    80001be2:	95250513          	addi	a0,a0,-1710 # 80011530 <cpus>
    80001be6:	953e                	add	a0,a0,a5
    80001be8:	6422                	ld	s0,8(sp)
    80001bea:	0141                	addi	sp,sp,16
    80001bec:	8082                	ret

0000000080001bee <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001bee:	1101                	addi	sp,sp,-32
    80001bf0:	ec06                	sd	ra,24(sp)
    80001bf2:	e822                	sd	s0,16(sp)
    80001bf4:	e426                	sd	s1,8(sp)
    80001bf6:	1000                	addi	s0,sp,32
  push_off();
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	1d4080e7          	jalr	468(ra) # 80000dcc <push_off>
    80001c00:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c02:	2781                	sext.w	a5,a5
    80001c04:	079e                	slli	a5,a5,0x7
    80001c06:	00010717          	auipc	a4,0x10
    80001c0a:	8fa70713          	addi	a4,a4,-1798 # 80011500 <pid_lock>
    80001c0e:	97ba                	add	a5,a5,a4
    80001c10:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	25a080e7          	jalr	602(ra) # 80000e6c <pop_off>
  return p;
}
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	60e2                	ld	ra,24(sp)
    80001c1e:	6442                	ld	s0,16(sp)
    80001c20:	64a2                	ld	s1,8(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret

0000000080001c26 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c26:	1141                	addi	sp,sp,-16
    80001c28:	e406                	sd	ra,8(sp)
    80001c2a:	e022                	sd	s0,0(sp)
    80001c2c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	fc0080e7          	jalr	-64(ra) # 80001bee <myproc>
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	296080e7          	jalr	662(ra) # 80000ecc <release>

  if (first) {
    80001c3e:	00007797          	auipc	a5,0x7
    80001c42:	cf27a783          	lw	a5,-782(a5) # 80008930 <first.0>
    80001c46:	eb89                	bnez	a5,80001c58 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c48:	00001097          	auipc	ra,0x1
    80001c4c:	e2a080e7          	jalr	-470(ra) # 80002a72 <usertrapret>
}
    80001c50:	60a2                	ld	ra,8(sp)
    80001c52:	6402                	ld	s0,0(sp)
    80001c54:	0141                	addi	sp,sp,16
    80001c56:	8082                	ret
    first = 0;
    80001c58:	00007797          	auipc	a5,0x7
    80001c5c:	cc07ac23          	sw	zero,-808(a5) # 80008930 <first.0>
    fsinit(ROOTDEV);
    80001c60:	4505                	li	a0,1
    80001c62:	00002097          	auipc	ra,0x2
    80001c66:	be6080e7          	jalr	-1050(ra) # 80003848 <fsinit>
    80001c6a:	bff9                	j	80001c48 <forkret+0x22>

0000000080001c6c <allocpid>:
{
    80001c6c:	1101                	addi	sp,sp,-32
    80001c6e:	ec06                	sd	ra,24(sp)
    80001c70:	e822                	sd	s0,16(sp)
    80001c72:	e426                	sd	s1,8(sp)
    80001c74:	e04a                	sd	s2,0(sp)
    80001c76:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c78:	00010917          	auipc	s2,0x10
    80001c7c:	88890913          	addi	s2,s2,-1912 # 80011500 <pid_lock>
    80001c80:	854a                	mv	a0,s2
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	196080e7          	jalr	406(ra) # 80000e18 <acquire>
  pid = nextpid;
    80001c8a:	00007797          	auipc	a5,0x7
    80001c8e:	caa78793          	addi	a5,a5,-854 # 80008934 <nextpid>
    80001c92:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c94:	0014871b          	addiw	a4,s1,1
    80001c98:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c9a:	854a                	mv	a0,s2
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	230080e7          	jalr	560(ra) # 80000ecc <release>
}
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	60e2                	ld	ra,24(sp)
    80001ca8:	6442                	ld	s0,16(sp)
    80001caa:	64a2                	ld	s1,8(sp)
    80001cac:	6902                	ld	s2,0(sp)
    80001cae:	6105                	addi	sp,sp,32
    80001cb0:	8082                	ret

0000000080001cb2 <proc_pagetable>:
{
    80001cb2:	1101                	addi	sp,sp,-32
    80001cb4:	ec06                	sd	ra,24(sp)
    80001cb6:	e822                	sd	s0,16(sp)
    80001cb8:	e426                	sd	s1,8(sp)
    80001cba:	e04a                	sd	s2,0(sp)
    80001cbc:	1000                	addi	s0,sp,32
    80001cbe:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	8aa080e7          	jalr	-1878(ra) # 8000156a <uvmcreate>
    80001cc8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001cca:	c121                	beqz	a0,80001d0a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ccc:	4729                	li	a4,10
    80001cce:	00005697          	auipc	a3,0x5
    80001cd2:	33268693          	addi	a3,a3,818 # 80007000 <_trampoline>
    80001cd6:	6605                	lui	a2,0x1
    80001cd8:	040005b7          	lui	a1,0x4000
    80001cdc:	15fd                	addi	a1,a1,-1
    80001cde:	05b2                	slli	a1,a1,0xc
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	600080e7          	jalr	1536(ra) # 800012e0 <mappages>
    80001ce8:	02054863          	bltz	a0,80001d18 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cec:	4719                	li	a4,6
    80001cee:	05893683          	ld	a3,88(s2)
    80001cf2:	6605                	lui	a2,0x1
    80001cf4:	020005b7          	lui	a1,0x2000
    80001cf8:	15fd                	addi	a1,a1,-1
    80001cfa:	05b6                	slli	a1,a1,0xd
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	5e2080e7          	jalr	1506(ra) # 800012e0 <mappages>
    80001d06:	02054163          	bltz	a0,80001d28 <proc_pagetable+0x76>
}
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	60e2                	ld	ra,24(sp)
    80001d0e:	6442                	ld	s0,16(sp)
    80001d10:	64a2                	ld	s1,8(sp)
    80001d12:	6902                	ld	s2,0(sp)
    80001d14:	6105                	addi	sp,sp,32
    80001d16:	8082                	ret
    uvmfree(pagetable, 0);
    80001d18:	4581                	li	a1,0
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	00000097          	auipc	ra,0x0
    80001d20:	a52080e7          	jalr	-1454(ra) # 8000176e <uvmfree>
    return 0;
    80001d24:	4481                	li	s1,0
    80001d26:	b7d5                	j	80001d0a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d28:	4681                	li	a3,0
    80001d2a:	4605                	li	a2,1
    80001d2c:	040005b7          	lui	a1,0x4000
    80001d30:	15fd                	addi	a1,a1,-1
    80001d32:	05b2                	slli	a1,a1,0xc
    80001d34:	8526                	mv	a0,s1
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	770080e7          	jalr	1904(ra) # 800014a6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d3e:	4581                	li	a1,0
    80001d40:	8526                	mv	a0,s1
    80001d42:	00000097          	auipc	ra,0x0
    80001d46:	a2c080e7          	jalr	-1492(ra) # 8000176e <uvmfree>
    return 0;
    80001d4a:	4481                	li	s1,0
    80001d4c:	bf7d                	j	80001d0a <proc_pagetable+0x58>

0000000080001d4e <proc_freepagetable>:
{
    80001d4e:	1101                	addi	sp,sp,-32
    80001d50:	ec06                	sd	ra,24(sp)
    80001d52:	e822                	sd	s0,16(sp)
    80001d54:	e426                	sd	s1,8(sp)
    80001d56:	e04a                	sd	s2,0(sp)
    80001d58:	1000                	addi	s0,sp,32
    80001d5a:	84aa                	mv	s1,a0
    80001d5c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d5e:	4681                	li	a3,0
    80001d60:	4605                	li	a2,1
    80001d62:	040005b7          	lui	a1,0x4000
    80001d66:	15fd                	addi	a1,a1,-1
    80001d68:	05b2                	slli	a1,a1,0xc
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	73c080e7          	jalr	1852(ra) # 800014a6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d72:	4681                	li	a3,0
    80001d74:	4605                	li	a2,1
    80001d76:	020005b7          	lui	a1,0x2000
    80001d7a:	15fd                	addi	a1,a1,-1
    80001d7c:	05b6                	slli	a1,a1,0xd
    80001d7e:	8526                	mv	a0,s1
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	726080e7          	jalr	1830(ra) # 800014a6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d88:	85ca                	mv	a1,s2
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	9e2080e7          	jalr	-1566(ra) # 8000176e <uvmfree>
}
    80001d94:	60e2                	ld	ra,24(sp)
    80001d96:	6442                	ld	s0,16(sp)
    80001d98:	64a2                	ld	s1,8(sp)
    80001d9a:	6902                	ld	s2,0(sp)
    80001d9c:	6105                	addi	sp,sp,32
    80001d9e:	8082                	ret

0000000080001da0 <freeproc>:
{
    80001da0:	1101                	addi	sp,sp,-32
    80001da2:	ec06                	sd	ra,24(sp)
    80001da4:	e822                	sd	s0,16(sp)
    80001da6:	e426                	sd	s1,8(sp)
    80001da8:	1000                	addi	s0,sp,32
    80001daa:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001dac:	6d28                	ld	a0,88(a0)
    80001dae:	c509                	beqz	a0,80001db8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	e7c080e7          	jalr	-388(ra) # 80000c2c <kfree>
  p->trapframe = 0;
    80001db8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001dbc:	68a8                	ld	a0,80(s1)
    80001dbe:	c511                	beqz	a0,80001dca <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001dc0:	64ac                	ld	a1,72(s1)
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	f8c080e7          	jalr	-116(ra) # 80001d4e <proc_freepagetable>
  p->pagetable = 0;
    80001dca:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001dce:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001dd2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001dd6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001dda:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001dde:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001de2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001de6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001dea:	0004ac23          	sw	zero,24(s1)
}
    80001dee:	60e2                	ld	ra,24(sp)
    80001df0:	6442                	ld	s0,16(sp)
    80001df2:	64a2                	ld	s1,8(sp)
    80001df4:	6105                	addi	sp,sp,32
    80001df6:	8082                	ret

0000000080001df8 <allocproc>:
{
    80001df8:	1101                	addi	sp,sp,-32
    80001dfa:	ec06                	sd	ra,24(sp)
    80001dfc:	e822                	sd	s0,16(sp)
    80001dfe:	e426                	sd	s1,8(sp)
    80001e00:	e04a                	sd	s2,0(sp)
    80001e02:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e04:	00010497          	auipc	s1,0x10
    80001e08:	26448493          	addi	s1,s1,612 # 80012068 <proc>
    80001e0c:	00016917          	auipc	s2,0x16
    80001e10:	c5c90913          	addi	s2,s2,-932 # 80017a68 <tickslock>
    acquire(&p->lock);
    80001e14:	8526                	mv	a0,s1
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	002080e7          	jalr	2(ra) # 80000e18 <acquire>
    if(p->state == UNUSED) {
    80001e1e:	4c9c                	lw	a5,24(s1)
    80001e20:	cf81                	beqz	a5,80001e38 <allocproc+0x40>
      release(&p->lock);
    80001e22:	8526                	mv	a0,s1
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	0a8080e7          	jalr	168(ra) # 80000ecc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e2c:	16848493          	addi	s1,s1,360
    80001e30:	ff2492e3          	bne	s1,s2,80001e14 <allocproc+0x1c>
  return 0;
    80001e34:	4481                	li	s1,0
    80001e36:	a889                	j	80001e88 <allocproc+0x90>
  p->pid = allocpid();
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	e34080e7          	jalr	-460(ra) # 80001c6c <allocpid>
    80001e40:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e42:	4785                	li	a5,1
    80001e44:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	ee2080e7          	jalr	-286(ra) # 80000d28 <kalloc>
    80001e4e:	892a                	mv	s2,a0
    80001e50:	eca8                	sd	a0,88(s1)
    80001e52:	c131                	beqz	a0,80001e96 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001e54:	8526                	mv	a0,s1
    80001e56:	00000097          	auipc	ra,0x0
    80001e5a:	e5c080e7          	jalr	-420(ra) # 80001cb2 <proc_pagetable>
    80001e5e:	892a                	mv	s2,a0
    80001e60:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e62:	c531                	beqz	a0,80001eae <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001e64:	07000613          	li	a2,112
    80001e68:	4581                	li	a1,0
    80001e6a:	06048513          	addi	a0,s1,96
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	0a6080e7          	jalr	166(ra) # 80000f14 <memset>
  p->context.ra = (uint64)forkret;
    80001e76:	00000797          	auipc	a5,0x0
    80001e7a:	db078793          	addi	a5,a5,-592 # 80001c26 <forkret>
    80001e7e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e80:	60bc                	ld	a5,64(s1)
    80001e82:	6705                	lui	a4,0x1
    80001e84:	97ba                	add	a5,a5,a4
    80001e86:	f4bc                	sd	a5,104(s1)
}
    80001e88:	8526                	mv	a0,s1
    80001e8a:	60e2                	ld	ra,24(sp)
    80001e8c:	6442                	ld	s0,16(sp)
    80001e8e:	64a2                	ld	s1,8(sp)
    80001e90:	6902                	ld	s2,0(sp)
    80001e92:	6105                	addi	sp,sp,32
    80001e94:	8082                	ret
    freeproc(p);
    80001e96:	8526                	mv	a0,s1
    80001e98:	00000097          	auipc	ra,0x0
    80001e9c:	f08080e7          	jalr	-248(ra) # 80001da0 <freeproc>
    release(&p->lock);
    80001ea0:	8526                	mv	a0,s1
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	02a080e7          	jalr	42(ra) # 80000ecc <release>
    return 0;
    80001eaa:	84ca                	mv	s1,s2
    80001eac:	bff1                	j	80001e88 <allocproc+0x90>
    freeproc(p);
    80001eae:	8526                	mv	a0,s1
    80001eb0:	00000097          	auipc	ra,0x0
    80001eb4:	ef0080e7          	jalr	-272(ra) # 80001da0 <freeproc>
    release(&p->lock);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	012080e7          	jalr	18(ra) # 80000ecc <release>
    return 0;
    80001ec2:	84ca                	mv	s1,s2
    80001ec4:	b7d1                	j	80001e88 <allocproc+0x90>

0000000080001ec6 <userinit>:
{
    80001ec6:	1101                	addi	sp,sp,-32
    80001ec8:	ec06                	sd	ra,24(sp)
    80001eca:	e822                	sd	s0,16(sp)
    80001ecc:	e426                	sd	s1,8(sp)
    80001ece:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ed0:	00000097          	auipc	ra,0x0
    80001ed4:	f28080e7          	jalr	-216(ra) # 80001df8 <allocproc>
    80001ed8:	84aa                	mv	s1,a0
  initproc = p;
    80001eda:	00007797          	auipc	a5,0x7
    80001ede:	aca7bf23          	sd	a0,-1314(a5) # 800089b8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ee2:	03400613          	li	a2,52
    80001ee6:	00007597          	auipc	a1,0x7
    80001eea:	a5a58593          	addi	a1,a1,-1446 # 80008940 <initcode>
    80001eee:	6928                	ld	a0,80(a0)
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	6a8080e7          	jalr	1704(ra) # 80001598 <uvmfirst>
  p->sz = PGSIZE;
    80001ef8:	6785                	lui	a5,0x1
    80001efa:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001efc:	6cb8                	ld	a4,88(s1)
    80001efe:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f02:	6cb8                	ld	a4,88(s1)
    80001f04:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f06:	4641                	li	a2,16
    80001f08:	00006597          	auipc	a1,0x6
    80001f0c:	2f858593          	addi	a1,a1,760 # 80008200 <digits+0x1c0>
    80001f10:	15848513          	addi	a0,s1,344
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	14a080e7          	jalr	330(ra) # 8000105e <safestrcpy>
  p->cwd = namei("/");
    80001f1c:	00006517          	auipc	a0,0x6
    80001f20:	2f450513          	addi	a0,a0,756 # 80008210 <digits+0x1d0>
    80001f24:	00002097          	auipc	ra,0x2
    80001f28:	346080e7          	jalr	838(ra) # 8000426a <namei>
    80001f2c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f30:	478d                	li	a5,3
    80001f32:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	f96080e7          	jalr	-106(ra) # 80000ecc <release>
}
    80001f3e:	60e2                	ld	ra,24(sp)
    80001f40:	6442                	ld	s0,16(sp)
    80001f42:	64a2                	ld	s1,8(sp)
    80001f44:	6105                	addi	sp,sp,32
    80001f46:	8082                	ret

0000000080001f48 <growproc>:
{
    80001f48:	1101                	addi	sp,sp,-32
    80001f4a:	ec06                	sd	ra,24(sp)
    80001f4c:	e822                	sd	s0,16(sp)
    80001f4e:	e426                	sd	s1,8(sp)
    80001f50:	e04a                	sd	s2,0(sp)
    80001f52:	1000                	addi	s0,sp,32
    80001f54:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	c98080e7          	jalr	-872(ra) # 80001bee <myproc>
    80001f5e:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f60:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001f62:	01204c63          	bgtz	s2,80001f7a <growproc+0x32>
  } else if(n < 0){
    80001f66:	02094663          	bltz	s2,80001f92 <growproc+0x4a>
  p->sz = sz;
    80001f6a:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f6c:	4501                	li	a0,0
}
    80001f6e:	60e2                	ld	ra,24(sp)
    80001f70:	6442                	ld	s0,16(sp)
    80001f72:	64a2                	ld	s1,8(sp)
    80001f74:	6902                	ld	s2,0(sp)
    80001f76:	6105                	addi	sp,sp,32
    80001f78:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001f7a:	4691                	li	a3,4
    80001f7c:	00b90633          	add	a2,s2,a1
    80001f80:	6928                	ld	a0,80(a0)
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	6d0080e7          	jalr	1744(ra) # 80001652 <uvmalloc>
    80001f8a:	85aa                	mv	a1,a0
    80001f8c:	fd79                	bnez	a0,80001f6a <growproc+0x22>
      return -1;
    80001f8e:	557d                	li	a0,-1
    80001f90:	bff9                	j	80001f6e <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f92:	00b90633          	add	a2,s2,a1
    80001f96:	6928                	ld	a0,80(a0)
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	672080e7          	jalr	1650(ra) # 8000160a <uvmdealloc>
    80001fa0:	85aa                	mv	a1,a0
    80001fa2:	b7e1                	j	80001f6a <growproc+0x22>

0000000080001fa4 <fork>:
{
    80001fa4:	7139                	addi	sp,sp,-64
    80001fa6:	fc06                	sd	ra,56(sp)
    80001fa8:	f822                	sd	s0,48(sp)
    80001faa:	f426                	sd	s1,40(sp)
    80001fac:	f04a                	sd	s2,32(sp)
    80001fae:	ec4e                	sd	s3,24(sp)
    80001fb0:	e852                	sd	s4,16(sp)
    80001fb2:	e456                	sd	s5,8(sp)
    80001fb4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	c38080e7          	jalr	-968(ra) # 80001bee <myproc>
    80001fbe:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	e38080e7          	jalr	-456(ra) # 80001df8 <allocproc>
    80001fc8:	10050c63          	beqz	a0,800020e0 <fork+0x13c>
    80001fcc:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fce:	048ab603          	ld	a2,72(s5)
    80001fd2:	692c                	ld	a1,80(a0)
    80001fd4:	050ab503          	ld	a0,80(s5)
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	7ce080e7          	jalr	1998(ra) # 800017a6 <uvmcopy>
    80001fe0:	04054863          	bltz	a0,80002030 <fork+0x8c>
  np->sz = p->sz;
    80001fe4:	048ab783          	ld	a5,72(s5)
    80001fe8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001fec:	058ab683          	ld	a3,88(s5)
    80001ff0:	87b6                	mv	a5,a3
    80001ff2:	058a3703          	ld	a4,88(s4)
    80001ff6:	12068693          	addi	a3,a3,288
    80001ffa:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ffe:	6788                	ld	a0,8(a5)
    80002000:	6b8c                	ld	a1,16(a5)
    80002002:	6f90                	ld	a2,24(a5)
    80002004:	01073023          	sd	a6,0(a4)
    80002008:	e708                	sd	a0,8(a4)
    8000200a:	eb0c                	sd	a1,16(a4)
    8000200c:	ef10                	sd	a2,24(a4)
    8000200e:	02078793          	addi	a5,a5,32
    80002012:	02070713          	addi	a4,a4,32
    80002016:	fed792e3          	bne	a5,a3,80001ffa <fork+0x56>
  np->trapframe->a0 = 0;
    8000201a:	058a3783          	ld	a5,88(s4)
    8000201e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002022:	0d0a8493          	addi	s1,s5,208
    80002026:	0d0a0913          	addi	s2,s4,208
    8000202a:	150a8993          	addi	s3,s5,336
    8000202e:	a00d                	j	80002050 <fork+0xac>
    freeproc(np);
    80002030:	8552                	mv	a0,s4
    80002032:	00000097          	auipc	ra,0x0
    80002036:	d6e080e7          	jalr	-658(ra) # 80001da0 <freeproc>
    release(&np->lock);
    8000203a:	8552                	mv	a0,s4
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	e90080e7          	jalr	-368(ra) # 80000ecc <release>
    return -1;
    80002044:	597d                	li	s2,-1
    80002046:	a059                	j	800020cc <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80002048:	04a1                	addi	s1,s1,8
    8000204a:	0921                	addi	s2,s2,8
    8000204c:	01348b63          	beq	s1,s3,80002062 <fork+0xbe>
    if(p->ofile[i])
    80002050:	6088                	ld	a0,0(s1)
    80002052:	d97d                	beqz	a0,80002048 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002054:	00003097          	auipc	ra,0x3
    80002058:	8ac080e7          	jalr	-1876(ra) # 80004900 <filedup>
    8000205c:	00a93023          	sd	a0,0(s2)
    80002060:	b7e5                	j	80002048 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002062:	150ab503          	ld	a0,336(s5)
    80002066:	00002097          	auipc	ra,0x2
    8000206a:	a20080e7          	jalr	-1504(ra) # 80003a86 <idup>
    8000206e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002072:	4641                	li	a2,16
    80002074:	158a8593          	addi	a1,s5,344
    80002078:	158a0513          	addi	a0,s4,344
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	fe2080e7          	jalr	-30(ra) # 8000105e <safestrcpy>
  pid = np->pid;
    80002084:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002088:	8552                	mv	a0,s4
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	e42080e7          	jalr	-446(ra) # 80000ecc <release>
  acquire(&wait_lock);
    80002092:	0000f497          	auipc	s1,0xf
    80002096:	48648493          	addi	s1,s1,1158 # 80011518 <wait_lock>
    8000209a:	8526                	mv	a0,s1
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	d7c080e7          	jalr	-644(ra) # 80000e18 <acquire>
  np->parent = p;
    800020a4:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	e22080e7          	jalr	-478(ra) # 80000ecc <release>
  acquire(&np->lock);
    800020b2:	8552                	mv	a0,s4
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	d64080e7          	jalr	-668(ra) # 80000e18 <acquire>
  np->state = RUNNABLE;
    800020bc:	478d                	li	a5,3
    800020be:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    800020c2:	8552                	mv	a0,s4
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	e08080e7          	jalr	-504(ra) # 80000ecc <release>
}
    800020cc:	854a                	mv	a0,s2
    800020ce:	70e2                	ld	ra,56(sp)
    800020d0:	7442                	ld	s0,48(sp)
    800020d2:	74a2                	ld	s1,40(sp)
    800020d4:	7902                	ld	s2,32(sp)
    800020d6:	69e2                	ld	s3,24(sp)
    800020d8:	6a42                	ld	s4,16(sp)
    800020da:	6aa2                	ld	s5,8(sp)
    800020dc:	6121                	addi	sp,sp,64
    800020de:	8082                	ret
    return -1;
    800020e0:	597d                	li	s2,-1
    800020e2:	b7ed                	j	800020cc <fork+0x128>

00000000800020e4 <scheduler>:
{
    800020e4:	7139                	addi	sp,sp,-64
    800020e6:	fc06                	sd	ra,56(sp)
    800020e8:	f822                	sd	s0,48(sp)
    800020ea:	f426                	sd	s1,40(sp)
    800020ec:	f04a                	sd	s2,32(sp)
    800020ee:	ec4e                	sd	s3,24(sp)
    800020f0:	e852                	sd	s4,16(sp)
    800020f2:	e456                	sd	s5,8(sp)
    800020f4:	e05a                	sd	s6,0(sp)
    800020f6:	0080                	addi	s0,sp,64
    800020f8:	8792                	mv	a5,tp
  int id = r_tp();
    800020fa:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020fc:	00779a93          	slli	s5,a5,0x7
    80002100:	0000f717          	auipc	a4,0xf
    80002104:	40070713          	addi	a4,a4,1024 # 80011500 <pid_lock>
    80002108:	9756                	add	a4,a4,s5
    8000210a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000210e:	0000f717          	auipc	a4,0xf
    80002112:	42a70713          	addi	a4,a4,1066 # 80011538 <cpus+0x8>
    80002116:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002118:	498d                	li	s3,3
        p->state = RUNNING;
    8000211a:	4b11                	li	s6,4
        c->proc = p;
    8000211c:	079e                	slli	a5,a5,0x7
    8000211e:	0000fa17          	auipc	s4,0xf
    80002122:	3e2a0a13          	addi	s4,s4,994 # 80011500 <pid_lock>
    80002126:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002128:	00016917          	auipc	s2,0x16
    8000212c:	94090913          	addi	s2,s2,-1728 # 80017a68 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002130:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002134:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002138:	10079073          	csrw	sstatus,a5
    8000213c:	00010497          	auipc	s1,0x10
    80002140:	f2c48493          	addi	s1,s1,-212 # 80012068 <proc>
    80002144:	a811                	j	80002158 <scheduler+0x74>
      release(&p->lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	d84080e7          	jalr	-636(ra) # 80000ecc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002150:	16848493          	addi	s1,s1,360
    80002154:	fd248ee3          	beq	s1,s2,80002130 <scheduler+0x4c>
      acquire(&p->lock);
    80002158:	8526                	mv	a0,s1
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	cbe080e7          	jalr	-834(ra) # 80000e18 <acquire>
      if(p->state == RUNNABLE) {
    80002162:	4c9c                	lw	a5,24(s1)
    80002164:	ff3791e3          	bne	a5,s3,80002146 <scheduler+0x62>
        p->state = RUNNING;
    80002168:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000216c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002170:	06048593          	addi	a1,s1,96
    80002174:	8556                	mv	a0,s5
    80002176:	00001097          	auipc	ra,0x1
    8000217a:	852080e7          	jalr	-1966(ra) # 800029c8 <swtch>
        c->proc = 0;
    8000217e:	020a3823          	sd	zero,48(s4)
    80002182:	b7d1                	j	80002146 <scheduler+0x62>

0000000080002184 <sched>:
{
    80002184:	7179                	addi	sp,sp,-48
    80002186:	f406                	sd	ra,40(sp)
    80002188:	f022                	sd	s0,32(sp)
    8000218a:	ec26                	sd	s1,24(sp)
    8000218c:	e84a                	sd	s2,16(sp)
    8000218e:	e44e                	sd	s3,8(sp)
    80002190:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002192:	00000097          	auipc	ra,0x0
    80002196:	a5c080e7          	jalr	-1444(ra) # 80001bee <myproc>
    8000219a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	c02080e7          	jalr	-1022(ra) # 80000d9e <holding>
    800021a4:	c93d                	beqz	a0,8000221a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021a6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021a8:	2781                	sext.w	a5,a5
    800021aa:	079e                	slli	a5,a5,0x7
    800021ac:	0000f717          	auipc	a4,0xf
    800021b0:	35470713          	addi	a4,a4,852 # 80011500 <pid_lock>
    800021b4:	97ba                	add	a5,a5,a4
    800021b6:	0a87a703          	lw	a4,168(a5)
    800021ba:	4785                	li	a5,1
    800021bc:	06f71763          	bne	a4,a5,8000222a <sched+0xa6>
  if(p->state == RUNNING)
    800021c0:	4c98                	lw	a4,24(s1)
    800021c2:	4791                	li	a5,4
    800021c4:	06f70b63          	beq	a4,a5,8000223a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021c8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021cc:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021ce:	efb5                	bnez	a5,8000224a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021d0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021d2:	0000f917          	auipc	s2,0xf
    800021d6:	32e90913          	addi	s2,s2,814 # 80011500 <pid_lock>
    800021da:	2781                	sext.w	a5,a5
    800021dc:	079e                	slli	a5,a5,0x7
    800021de:	97ca                	add	a5,a5,s2
    800021e0:	0ac7a983          	lw	s3,172(a5)
    800021e4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021e6:	2781                	sext.w	a5,a5
    800021e8:	079e                	slli	a5,a5,0x7
    800021ea:	0000f597          	auipc	a1,0xf
    800021ee:	34e58593          	addi	a1,a1,846 # 80011538 <cpus+0x8>
    800021f2:	95be                	add	a1,a1,a5
    800021f4:	06048513          	addi	a0,s1,96
    800021f8:	00000097          	auipc	ra,0x0
    800021fc:	7d0080e7          	jalr	2000(ra) # 800029c8 <swtch>
    80002200:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002202:	2781                	sext.w	a5,a5
    80002204:	079e                	slli	a5,a5,0x7
    80002206:	97ca                	add	a5,a5,s2
    80002208:	0b37a623          	sw	s3,172(a5)
}
    8000220c:	70a2                	ld	ra,40(sp)
    8000220e:	7402                	ld	s0,32(sp)
    80002210:	64e2                	ld	s1,24(sp)
    80002212:	6942                	ld	s2,16(sp)
    80002214:	69a2                	ld	s3,8(sp)
    80002216:	6145                	addi	sp,sp,48
    80002218:	8082                	ret
    panic("sched p->lock");
    8000221a:	00006517          	auipc	a0,0x6
    8000221e:	ffe50513          	addi	a0,a0,-2 # 80008218 <digits+0x1d8>
    80002222:	ffffe097          	auipc	ra,0xffffe
    80002226:	55e080e7          	jalr	1374(ra) # 80000780 <panic>
    panic("sched locks");
    8000222a:	00006517          	auipc	a0,0x6
    8000222e:	ffe50513          	addi	a0,a0,-2 # 80008228 <digits+0x1e8>
    80002232:	ffffe097          	auipc	ra,0xffffe
    80002236:	54e080e7          	jalr	1358(ra) # 80000780 <panic>
    panic("sched running");
    8000223a:	00006517          	auipc	a0,0x6
    8000223e:	ffe50513          	addi	a0,a0,-2 # 80008238 <digits+0x1f8>
    80002242:	ffffe097          	auipc	ra,0xffffe
    80002246:	53e080e7          	jalr	1342(ra) # 80000780 <panic>
    panic("sched interruptible");
    8000224a:	00006517          	auipc	a0,0x6
    8000224e:	ffe50513          	addi	a0,a0,-2 # 80008248 <digits+0x208>
    80002252:	ffffe097          	auipc	ra,0xffffe
    80002256:	52e080e7          	jalr	1326(ra) # 80000780 <panic>

000000008000225a <yield>:
{
    8000225a:	1101                	addi	sp,sp,-32
    8000225c:	ec06                	sd	ra,24(sp)
    8000225e:	e822                	sd	s0,16(sp)
    80002260:	e426                	sd	s1,8(sp)
    80002262:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002264:	00000097          	auipc	ra,0x0
    80002268:	98a080e7          	jalr	-1654(ra) # 80001bee <myproc>
    8000226c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	baa080e7          	jalr	-1110(ra) # 80000e18 <acquire>
  p->state = RUNNABLE;
    80002276:	478d                	li	a5,3
    80002278:	cc9c                	sw	a5,24(s1)
  sched();
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	f0a080e7          	jalr	-246(ra) # 80002184 <sched>
  release(&p->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	c48080e7          	jalr	-952(ra) # 80000ecc <release>
}
    8000228c:	60e2                	ld	ra,24(sp)
    8000228e:	6442                	ld	s0,16(sp)
    80002290:	64a2                	ld	s1,8(sp)
    80002292:	6105                	addi	sp,sp,32
    80002294:	8082                	ret

0000000080002296 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002296:	7179                	addi	sp,sp,-48
    80002298:	f406                	sd	ra,40(sp)
    8000229a:	f022                	sd	s0,32(sp)
    8000229c:	ec26                	sd	s1,24(sp)
    8000229e:	e84a                	sd	s2,16(sp)
    800022a0:	e44e                	sd	s3,8(sp)
    800022a2:	1800                	addi	s0,sp,48
    800022a4:	89aa                	mv	s3,a0
    800022a6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	946080e7          	jalr	-1722(ra) # 80001bee <myproc>
    800022b0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	b66080e7          	jalr	-1178(ra) # 80000e18 <acquire>
  release(lk);
    800022ba:	854a                	mv	a0,s2
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	c10080e7          	jalr	-1008(ra) # 80000ecc <release>

  // Go to sleep.
  p->chan = chan;
    800022c4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022c8:	4789                	li	a5,2
    800022ca:	cc9c                	sw	a5,24(s1)

  sched();
    800022cc:	00000097          	auipc	ra,0x0
    800022d0:	eb8080e7          	jalr	-328(ra) # 80002184 <sched>

  // Tidy up.
  p->chan = 0;
    800022d4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	bf2080e7          	jalr	-1038(ra) # 80000ecc <release>
  acquire(lk);
    800022e2:	854a                	mv	a0,s2
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	b34080e7          	jalr	-1228(ra) # 80000e18 <acquire>
}
    800022ec:	70a2                	ld	ra,40(sp)
    800022ee:	7402                	ld	s0,32(sp)
    800022f0:	64e2                	ld	s1,24(sp)
    800022f2:	6942                	ld	s2,16(sp)
    800022f4:	69a2                	ld	s3,8(sp)
    800022f6:	6145                	addi	sp,sp,48
    800022f8:	8082                	ret

00000000800022fa <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022fa:	7139                	addi	sp,sp,-64
    800022fc:	fc06                	sd	ra,56(sp)
    800022fe:	f822                	sd	s0,48(sp)
    80002300:	f426                	sd	s1,40(sp)
    80002302:	f04a                	sd	s2,32(sp)
    80002304:	ec4e                	sd	s3,24(sp)
    80002306:	e852                	sd	s4,16(sp)
    80002308:	e456                	sd	s5,8(sp)
    8000230a:	0080                	addi	s0,sp,64
    8000230c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000230e:	00010497          	auipc	s1,0x10
    80002312:	d5a48493          	addi	s1,s1,-678 # 80012068 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002316:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002318:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000231a:	00015917          	auipc	s2,0x15
    8000231e:	74e90913          	addi	s2,s2,1870 # 80017a68 <tickslock>
    80002322:	a811                	j	80002336 <wakeup+0x3c>
      }
      release(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	ba6080e7          	jalr	-1114(ra) # 80000ecc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000232e:	16848493          	addi	s1,s1,360
    80002332:	03248663          	beq	s1,s2,8000235e <wakeup+0x64>
    if(p != myproc()){
    80002336:	00000097          	auipc	ra,0x0
    8000233a:	8b8080e7          	jalr	-1864(ra) # 80001bee <myproc>
    8000233e:	fea488e3          	beq	s1,a0,8000232e <wakeup+0x34>
      acquire(&p->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	ad4080e7          	jalr	-1324(ra) # 80000e18 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000234c:	4c9c                	lw	a5,24(s1)
    8000234e:	fd379be3          	bne	a5,s3,80002324 <wakeup+0x2a>
    80002352:	709c                	ld	a5,32(s1)
    80002354:	fd4798e3          	bne	a5,s4,80002324 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002358:	0154ac23          	sw	s5,24(s1)
    8000235c:	b7e1                	j	80002324 <wakeup+0x2a>
    }
  }
}
    8000235e:	70e2                	ld	ra,56(sp)
    80002360:	7442                	ld	s0,48(sp)
    80002362:	74a2                	ld	s1,40(sp)
    80002364:	7902                	ld	s2,32(sp)
    80002366:	69e2                	ld	s3,24(sp)
    80002368:	6a42                	ld	s4,16(sp)
    8000236a:	6aa2                	ld	s5,8(sp)
    8000236c:	6121                	addi	sp,sp,64
    8000236e:	8082                	ret

0000000080002370 <reparent>:
{
    80002370:	7179                	addi	sp,sp,-48
    80002372:	f406                	sd	ra,40(sp)
    80002374:	f022                	sd	s0,32(sp)
    80002376:	ec26                	sd	s1,24(sp)
    80002378:	e84a                	sd	s2,16(sp)
    8000237a:	e44e                	sd	s3,8(sp)
    8000237c:	e052                	sd	s4,0(sp)
    8000237e:	1800                	addi	s0,sp,48
    80002380:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002382:	00010497          	auipc	s1,0x10
    80002386:	ce648493          	addi	s1,s1,-794 # 80012068 <proc>
      pp->parent = initproc;
    8000238a:	00006a17          	auipc	s4,0x6
    8000238e:	62ea0a13          	addi	s4,s4,1582 # 800089b8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002392:	00015997          	auipc	s3,0x15
    80002396:	6d698993          	addi	s3,s3,1750 # 80017a68 <tickslock>
    8000239a:	a029                	j	800023a4 <reparent+0x34>
    8000239c:	16848493          	addi	s1,s1,360
    800023a0:	01348d63          	beq	s1,s3,800023ba <reparent+0x4a>
    if(pp->parent == p){
    800023a4:	7c9c                	ld	a5,56(s1)
    800023a6:	ff279be3          	bne	a5,s2,8000239c <reparent+0x2c>
      pp->parent = initproc;
    800023aa:	000a3503          	ld	a0,0(s4)
    800023ae:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023b0:	00000097          	auipc	ra,0x0
    800023b4:	f4a080e7          	jalr	-182(ra) # 800022fa <wakeup>
    800023b8:	b7d5                	j	8000239c <reparent+0x2c>
}
    800023ba:	70a2                	ld	ra,40(sp)
    800023bc:	7402                	ld	s0,32(sp)
    800023be:	64e2                	ld	s1,24(sp)
    800023c0:	6942                	ld	s2,16(sp)
    800023c2:	69a2                	ld	s3,8(sp)
    800023c4:	6a02                	ld	s4,0(sp)
    800023c6:	6145                	addi	sp,sp,48
    800023c8:	8082                	ret

00000000800023ca <exit>:
{
    800023ca:	7179                	addi	sp,sp,-48
    800023cc:	f406                	sd	ra,40(sp)
    800023ce:	f022                	sd	s0,32(sp)
    800023d0:	ec26                	sd	s1,24(sp)
    800023d2:	e84a                	sd	s2,16(sp)
    800023d4:	e44e                	sd	s3,8(sp)
    800023d6:	e052                	sd	s4,0(sp)
    800023d8:	1800                	addi	s0,sp,48
    800023da:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	812080e7          	jalr	-2030(ra) # 80001bee <myproc>
    800023e4:	89aa                	mv	s3,a0
  if(p == initproc)
    800023e6:	00006797          	auipc	a5,0x6
    800023ea:	5d27b783          	ld	a5,1490(a5) # 800089b8 <initproc>
    800023ee:	0d050493          	addi	s1,a0,208
    800023f2:	15050913          	addi	s2,a0,336
    800023f6:	02a79363          	bne	a5,a0,8000241c <exit+0x52>
    panic("init exiting");
    800023fa:	00006517          	auipc	a0,0x6
    800023fe:	e6650513          	addi	a0,a0,-410 # 80008260 <digits+0x220>
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	37e080e7          	jalr	894(ra) # 80000780 <panic>
      fileclose(f);
    8000240a:	00002097          	auipc	ra,0x2
    8000240e:	548080e7          	jalr	1352(ra) # 80004952 <fileclose>
      p->ofile[fd] = 0;
    80002412:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002416:	04a1                	addi	s1,s1,8
    80002418:	01248563          	beq	s1,s2,80002422 <exit+0x58>
    if(p->ofile[fd]){
    8000241c:	6088                	ld	a0,0(s1)
    8000241e:	f575                	bnez	a0,8000240a <exit+0x40>
    80002420:	bfdd                	j	80002416 <exit+0x4c>
  begin_op();
    80002422:	00002097          	auipc	ra,0x2
    80002426:	064080e7          	jalr	100(ra) # 80004486 <begin_op>
  iput(p->cwd);
    8000242a:	1509b503          	ld	a0,336(s3)
    8000242e:	00002097          	auipc	ra,0x2
    80002432:	850080e7          	jalr	-1968(ra) # 80003c7e <iput>
  end_op();
    80002436:	00002097          	auipc	ra,0x2
    8000243a:	0d0080e7          	jalr	208(ra) # 80004506 <end_op>
  p->cwd = 0;
    8000243e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002442:	0000f497          	auipc	s1,0xf
    80002446:	0d648493          	addi	s1,s1,214 # 80011518 <wait_lock>
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	9cc080e7          	jalr	-1588(ra) # 80000e18 <acquire>
  reparent(p);
    80002454:	854e                	mv	a0,s3
    80002456:	00000097          	auipc	ra,0x0
    8000245a:	f1a080e7          	jalr	-230(ra) # 80002370 <reparent>
  wakeup(p->parent);
    8000245e:	0389b503          	ld	a0,56(s3)
    80002462:	00000097          	auipc	ra,0x0
    80002466:	e98080e7          	jalr	-360(ra) # 800022fa <wakeup>
  acquire(&p->lock);
    8000246a:	854e                	mv	a0,s3
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	9ac080e7          	jalr	-1620(ra) # 80000e18 <acquire>
  p->xstate = status;
    80002474:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002478:	4795                	li	a5,5
    8000247a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	a4c080e7          	jalr	-1460(ra) # 80000ecc <release>
  sched();
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	cfc080e7          	jalr	-772(ra) # 80002184 <sched>
  panic("zombie exit");
    80002490:	00006517          	auipc	a0,0x6
    80002494:	de050513          	addi	a0,a0,-544 # 80008270 <digits+0x230>
    80002498:	ffffe097          	auipc	ra,0xffffe
    8000249c:	2e8080e7          	jalr	744(ra) # 80000780 <panic>

00000000800024a0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024a0:	7179                	addi	sp,sp,-48
    800024a2:	f406                	sd	ra,40(sp)
    800024a4:	f022                	sd	s0,32(sp)
    800024a6:	ec26                	sd	s1,24(sp)
    800024a8:	e84a                	sd	s2,16(sp)
    800024aa:	e44e                	sd	s3,8(sp)
    800024ac:	1800                	addi	s0,sp,48
    800024ae:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024b0:	00010497          	auipc	s1,0x10
    800024b4:	bb848493          	addi	s1,s1,-1096 # 80012068 <proc>
    800024b8:	00015997          	auipc	s3,0x15
    800024bc:	5b098993          	addi	s3,s3,1456 # 80017a68 <tickslock>
    acquire(&p->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	956080e7          	jalr	-1706(ra) # 80000e18 <acquire>
    if(p->pid == pid){
    800024ca:	589c                	lw	a5,48(s1)
    800024cc:	01278d63          	beq	a5,s2,800024e6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	9fa080e7          	jalr	-1542(ra) # 80000ecc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024da:	16848493          	addi	s1,s1,360
    800024de:	ff3491e3          	bne	s1,s3,800024c0 <kill+0x20>
  }
  return -1;
    800024e2:	557d                	li	a0,-1
    800024e4:	a829                	j	800024fe <kill+0x5e>
      p->killed = 1;
    800024e6:	4785                	li	a5,1
    800024e8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024ea:	4c98                	lw	a4,24(s1)
    800024ec:	4789                	li	a5,2
    800024ee:	00f70f63          	beq	a4,a5,8000250c <kill+0x6c>
      release(&p->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	9d8080e7          	jalr	-1576(ra) # 80000ecc <release>
      return 0;
    800024fc:	4501                	li	a0,0
}
    800024fe:	70a2                	ld	ra,40(sp)
    80002500:	7402                	ld	s0,32(sp)
    80002502:	64e2                	ld	s1,24(sp)
    80002504:	6942                	ld	s2,16(sp)
    80002506:	69a2                	ld	s3,8(sp)
    80002508:	6145                	addi	sp,sp,48
    8000250a:	8082                	ret
        p->state = RUNNABLE;
    8000250c:	478d                	li	a5,3
    8000250e:	cc9c                	sw	a5,24(s1)
    80002510:	b7cd                	j	800024f2 <kill+0x52>

0000000080002512 <setkilled>:

void
setkilled(struct proc *p)
{
    80002512:	1101                	addi	sp,sp,-32
    80002514:	ec06                	sd	ra,24(sp)
    80002516:	e822                	sd	s0,16(sp)
    80002518:	e426                	sd	s1,8(sp)
    8000251a:	1000                	addi	s0,sp,32
    8000251c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	8fa080e7          	jalr	-1798(ra) # 80000e18 <acquire>
  p->killed = 1;
    80002526:	4785                	li	a5,1
    80002528:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000252a:	8526                	mv	a0,s1
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	9a0080e7          	jalr	-1632(ra) # 80000ecc <release>
}
    80002534:	60e2                	ld	ra,24(sp)
    80002536:	6442                	ld	s0,16(sp)
    80002538:	64a2                	ld	s1,8(sp)
    8000253a:	6105                	addi	sp,sp,32
    8000253c:	8082                	ret

000000008000253e <killed>:

int
killed(struct proc *p)
{
    8000253e:	1101                	addi	sp,sp,-32
    80002540:	ec06                	sd	ra,24(sp)
    80002542:	e822                	sd	s0,16(sp)
    80002544:	e426                	sd	s1,8(sp)
    80002546:	e04a                	sd	s2,0(sp)
    80002548:	1000                	addi	s0,sp,32
    8000254a:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	8cc080e7          	jalr	-1844(ra) # 80000e18 <acquire>
  k = p->killed;
    80002554:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002558:	8526                	mv	a0,s1
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	972080e7          	jalr	-1678(ra) # 80000ecc <release>
  return k;
}
    80002562:	854a                	mv	a0,s2
    80002564:	60e2                	ld	ra,24(sp)
    80002566:	6442                	ld	s0,16(sp)
    80002568:	64a2                	ld	s1,8(sp)
    8000256a:	6902                	ld	s2,0(sp)
    8000256c:	6105                	addi	sp,sp,32
    8000256e:	8082                	ret

0000000080002570 <wait>:
{
    80002570:	715d                	addi	sp,sp,-80
    80002572:	e486                	sd	ra,72(sp)
    80002574:	e0a2                	sd	s0,64(sp)
    80002576:	fc26                	sd	s1,56(sp)
    80002578:	f84a                	sd	s2,48(sp)
    8000257a:	f44e                	sd	s3,40(sp)
    8000257c:	f052                	sd	s4,32(sp)
    8000257e:	ec56                	sd	s5,24(sp)
    80002580:	e85a                	sd	s6,16(sp)
    80002582:	e45e                	sd	s7,8(sp)
    80002584:	e062                	sd	s8,0(sp)
    80002586:	0880                	addi	s0,sp,80
    80002588:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000258a:	fffff097          	auipc	ra,0xfffff
    8000258e:	664080e7          	jalr	1636(ra) # 80001bee <myproc>
    80002592:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002594:	0000f517          	auipc	a0,0xf
    80002598:	f8450513          	addi	a0,a0,-124 # 80011518 <wait_lock>
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	87c080e7          	jalr	-1924(ra) # 80000e18 <acquire>
    havekids = 0;
    800025a4:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800025a6:	4a15                	li	s4,5
        havekids = 1;
    800025a8:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025aa:	00015997          	auipc	s3,0x15
    800025ae:	4be98993          	addi	s3,s3,1214 # 80017a68 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025b2:	0000fc17          	auipc	s8,0xf
    800025b6:	f66c0c13          	addi	s8,s8,-154 # 80011518 <wait_lock>
    havekids = 0;
    800025ba:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025bc:	00010497          	auipc	s1,0x10
    800025c0:	aac48493          	addi	s1,s1,-1364 # 80012068 <proc>
    800025c4:	a0bd                	j	80002632 <wait+0xc2>
          pid = pp->pid;
    800025c6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800025ca:	000b0e63          	beqz	s6,800025e6 <wait+0x76>
    800025ce:	4691                	li	a3,4
    800025d0:	02c48613          	addi	a2,s1,44
    800025d4:	85da                	mv	a1,s6
    800025d6:	05093503          	ld	a0,80(s2)
    800025da:	fffff097          	auipc	ra,0xfffff
    800025de:	2d0080e7          	jalr	720(ra) # 800018aa <copyout>
    800025e2:	02054563          	bltz	a0,8000260c <wait+0x9c>
          freeproc(pp);
    800025e6:	8526                	mv	a0,s1
    800025e8:	fffff097          	auipc	ra,0xfffff
    800025ec:	7b8080e7          	jalr	1976(ra) # 80001da0 <freeproc>
          release(&pp->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	fffff097          	auipc	ra,0xfffff
    800025f6:	8da080e7          	jalr	-1830(ra) # 80000ecc <release>
          release(&wait_lock);
    800025fa:	0000f517          	auipc	a0,0xf
    800025fe:	f1e50513          	addi	a0,a0,-226 # 80011518 <wait_lock>
    80002602:	fffff097          	auipc	ra,0xfffff
    80002606:	8ca080e7          	jalr	-1846(ra) # 80000ecc <release>
          return pid;
    8000260a:	a0b5                	j	80002676 <wait+0x106>
            release(&pp->lock);
    8000260c:	8526                	mv	a0,s1
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	8be080e7          	jalr	-1858(ra) # 80000ecc <release>
            release(&wait_lock);
    80002616:	0000f517          	auipc	a0,0xf
    8000261a:	f0250513          	addi	a0,a0,-254 # 80011518 <wait_lock>
    8000261e:	fffff097          	auipc	ra,0xfffff
    80002622:	8ae080e7          	jalr	-1874(ra) # 80000ecc <release>
            return -1;
    80002626:	59fd                	li	s3,-1
    80002628:	a0b9                	j	80002676 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000262a:	16848493          	addi	s1,s1,360
    8000262e:	03348463          	beq	s1,s3,80002656 <wait+0xe6>
      if(pp->parent == p){
    80002632:	7c9c                	ld	a5,56(s1)
    80002634:	ff279be3          	bne	a5,s2,8000262a <wait+0xba>
        acquire(&pp->lock);
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	7de080e7          	jalr	2014(ra) # 80000e18 <acquire>
        if(pp->state == ZOMBIE){
    80002642:	4c9c                	lw	a5,24(s1)
    80002644:	f94781e3          	beq	a5,s4,800025c6 <wait+0x56>
        release(&pp->lock);
    80002648:	8526                	mv	a0,s1
    8000264a:	fffff097          	auipc	ra,0xfffff
    8000264e:	882080e7          	jalr	-1918(ra) # 80000ecc <release>
        havekids = 1;
    80002652:	8756                	mv	a4,s5
    80002654:	bfd9                	j	8000262a <wait+0xba>
    if(!havekids || killed(p)){
    80002656:	c719                	beqz	a4,80002664 <wait+0xf4>
    80002658:	854a                	mv	a0,s2
    8000265a:	00000097          	auipc	ra,0x0
    8000265e:	ee4080e7          	jalr	-284(ra) # 8000253e <killed>
    80002662:	c51d                	beqz	a0,80002690 <wait+0x120>
      release(&wait_lock);
    80002664:	0000f517          	auipc	a0,0xf
    80002668:	eb450513          	addi	a0,a0,-332 # 80011518 <wait_lock>
    8000266c:	fffff097          	auipc	ra,0xfffff
    80002670:	860080e7          	jalr	-1952(ra) # 80000ecc <release>
      return -1;
    80002674:	59fd                	li	s3,-1
}
    80002676:	854e                	mv	a0,s3
    80002678:	60a6                	ld	ra,72(sp)
    8000267a:	6406                	ld	s0,64(sp)
    8000267c:	74e2                	ld	s1,56(sp)
    8000267e:	7942                	ld	s2,48(sp)
    80002680:	79a2                	ld	s3,40(sp)
    80002682:	7a02                	ld	s4,32(sp)
    80002684:	6ae2                	ld	s5,24(sp)
    80002686:	6b42                	ld	s6,16(sp)
    80002688:	6ba2                	ld	s7,8(sp)
    8000268a:	6c02                	ld	s8,0(sp)
    8000268c:	6161                	addi	sp,sp,80
    8000268e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002690:	85e2                	mv	a1,s8
    80002692:	854a                	mv	a0,s2
    80002694:	00000097          	auipc	ra,0x0
    80002698:	c02080e7          	jalr	-1022(ra) # 80002296 <sleep>
    havekids = 0;
    8000269c:	bf39                	j	800025ba <wait+0x4a>

000000008000269e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000269e:	7179                	addi	sp,sp,-48
    800026a0:	f406                	sd	ra,40(sp)
    800026a2:	f022                	sd	s0,32(sp)
    800026a4:	ec26                	sd	s1,24(sp)
    800026a6:	e84a                	sd	s2,16(sp)
    800026a8:	e44e                	sd	s3,8(sp)
    800026aa:	e052                	sd	s4,0(sp)
    800026ac:	1800                	addi	s0,sp,48
    800026ae:	84aa                	mv	s1,a0
    800026b0:	892e                	mv	s2,a1
    800026b2:	89b2                	mv	s3,a2
    800026b4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026b6:	fffff097          	auipc	ra,0xfffff
    800026ba:	538080e7          	jalr	1336(ra) # 80001bee <myproc>
  if(user_dst){
    800026be:	c08d                	beqz	s1,800026e0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026c0:	86d2                	mv	a3,s4
    800026c2:	864e                	mv	a2,s3
    800026c4:	85ca                	mv	a1,s2
    800026c6:	6928                	ld	a0,80(a0)
    800026c8:	fffff097          	auipc	ra,0xfffff
    800026cc:	1e2080e7          	jalr	482(ra) # 800018aa <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026d0:	70a2                	ld	ra,40(sp)
    800026d2:	7402                	ld	s0,32(sp)
    800026d4:	64e2                	ld	s1,24(sp)
    800026d6:	6942                	ld	s2,16(sp)
    800026d8:	69a2                	ld	s3,8(sp)
    800026da:	6a02                	ld	s4,0(sp)
    800026dc:	6145                	addi	sp,sp,48
    800026de:	8082                	ret
    memmove((char *)dst, src, len);
    800026e0:	000a061b          	sext.w	a2,s4
    800026e4:	85ce                	mv	a1,s3
    800026e6:	854a                	mv	a0,s2
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	888080e7          	jalr	-1912(ra) # 80000f70 <memmove>
    return 0;
    800026f0:	8526                	mv	a0,s1
    800026f2:	bff9                	j	800026d0 <either_copyout+0x32>

00000000800026f4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026f4:	7179                	addi	sp,sp,-48
    800026f6:	f406                	sd	ra,40(sp)
    800026f8:	f022                	sd	s0,32(sp)
    800026fa:	ec26                	sd	s1,24(sp)
    800026fc:	e84a                	sd	s2,16(sp)
    800026fe:	e44e                	sd	s3,8(sp)
    80002700:	e052                	sd	s4,0(sp)
    80002702:	1800                	addi	s0,sp,48
    80002704:	892a                	mv	s2,a0
    80002706:	84ae                	mv	s1,a1
    80002708:	89b2                	mv	s3,a2
    8000270a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000270c:	fffff097          	auipc	ra,0xfffff
    80002710:	4e2080e7          	jalr	1250(ra) # 80001bee <myproc>
  if(user_src){
    80002714:	c08d                	beqz	s1,80002736 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002716:	86d2                	mv	a3,s4
    80002718:	864e                	mv	a2,s3
    8000271a:	85ca                	mv	a1,s2
    8000271c:	6928                	ld	a0,80(a0)
    8000271e:	fffff097          	auipc	ra,0xfffff
    80002722:	218080e7          	jalr	536(ra) # 80001936 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002726:	70a2                	ld	ra,40(sp)
    80002728:	7402                	ld	s0,32(sp)
    8000272a:	64e2                	ld	s1,24(sp)
    8000272c:	6942                	ld	s2,16(sp)
    8000272e:	69a2                	ld	s3,8(sp)
    80002730:	6a02                	ld	s4,0(sp)
    80002732:	6145                	addi	sp,sp,48
    80002734:	8082                	ret
    memmove(dst, (char*)src, len);
    80002736:	000a061b          	sext.w	a2,s4
    8000273a:	85ce                	mv	a1,s3
    8000273c:	854a                	mv	a0,s2
    8000273e:	fffff097          	auipc	ra,0xfffff
    80002742:	832080e7          	jalr	-1998(ra) # 80000f70 <memmove>
    return 0;
    80002746:	8526                	mv	a0,s1
    80002748:	bff9                	j	80002726 <either_copyin+0x32>

000000008000274a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000274a:	715d                	addi	sp,sp,-80
    8000274c:	e486                	sd	ra,72(sp)
    8000274e:	e0a2                	sd	s0,64(sp)
    80002750:	fc26                	sd	s1,56(sp)
    80002752:	f84a                	sd	s2,48(sp)
    80002754:	f44e                	sd	s3,40(sp)
    80002756:	f052                	sd	s4,32(sp)
    80002758:	ec56                	sd	s5,24(sp)
    8000275a:	e85a                	sd	s6,16(sp)
    8000275c:	e45e                	sd	s7,8(sp)
    8000275e:	0880                	addi	s0,sp,80

  struct proc *p;
  char *state;

  printf("\n");
    80002760:	00006517          	auipc	a0,0x6
    80002764:	bc850513          	addi	a0,a0,-1080 # 80008328 <digits+0x2e8>
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	062080e7          	jalr	98(ra) # 800007ca <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002770:	00010497          	auipc	s1,0x10
    80002774:	a5048493          	addi	s1,s1,-1456 # 800121c0 <proc+0x158>
    80002778:	00015917          	auipc	s2,0x15
    8000277c:	44890913          	addi	s2,s2,1096 # 80017bc0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002780:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002782:	00006997          	auipc	s3,0x6
    80002786:	afe98993          	addi	s3,s3,-1282 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000278a:	00006a97          	auipc	s5,0x6
    8000278e:	afea8a93          	addi	s5,s5,-1282 # 80008288 <digits+0x248>
    printf("\n");
    80002792:	00006a17          	auipc	s4,0x6
    80002796:	b96a0a13          	addi	s4,s4,-1130 # 80008328 <digits+0x2e8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000279a:	00006b97          	auipc	s7,0x6
    8000279e:	c06b8b93          	addi	s7,s7,-1018 # 800083a0 <states>
    800027a2:	a00d                	j	800027c4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027a4:	ed86a583          	lw	a1,-296(a3)
    800027a8:	8556                	mv	a0,s5
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	020080e7          	jalr	32(ra) # 800007ca <printf>
    printf("\n");
    800027b2:	8552                	mv	a0,s4
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	016080e7          	jalr	22(ra) # 800007ca <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027bc:	16848493          	addi	s1,s1,360
    800027c0:	03248163          	beq	s1,s2,800027e2 <procdump+0x98>
    if(p->state == UNUSED)
    800027c4:	86a6                	mv	a3,s1
    800027c6:	ec04a783          	lw	a5,-320(s1)
    800027ca:	dbed                	beqz	a5,800027bc <procdump+0x72>
      state = "???";
    800027cc:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ce:	fcfb6be3          	bltu	s6,a5,800027a4 <procdump+0x5a>
    800027d2:	1782                	slli	a5,a5,0x20
    800027d4:	9381                	srli	a5,a5,0x20
    800027d6:	078e                	slli	a5,a5,0x3
    800027d8:	97de                	add	a5,a5,s7
    800027da:	6390                	ld	a2,0(a5)
    800027dc:	f661                	bnez	a2,800027a4 <procdump+0x5a>
      state = "???";
    800027de:	864e                	mv	a2,s3
    800027e0:	b7d1                	j	800027a4 <procdump+0x5a>
  }
}
    800027e2:	60a6                	ld	ra,72(sp)
    800027e4:	6406                	ld	s0,64(sp)
    800027e6:	74e2                	ld	s1,56(sp)
    800027e8:	7942                	ld	s2,48(sp)
    800027ea:	79a2                	ld	s3,40(sp)
    800027ec:	7a02                	ld	s4,32(sp)
    800027ee:	6ae2                	ld	s5,24(sp)
    800027f0:	6b42                	ld	s6,16(sp)
    800027f2:	6ba2                	ld	s7,8(sp)
    800027f4:	6161                	addi	sp,sp,80
    800027f6:	8082                	ret

00000000800027f8 <get_top_info>:


int get_top_info(void){
    800027f8:	7159                	addi	sp,sp,-112
    800027fa:	f486                	sd	ra,104(sp)
    800027fc:	f0a2                	sd	s0,96(sp)
    800027fe:	eca6                	sd	s1,88(sp)
    80002800:	e8ca                	sd	s2,80(sp)
    80002802:	e4ce                	sd	s3,72(sp)
    80002804:	e0d2                	sd	s4,64(sp)
    80002806:	fc56                	sd	s5,56(sp)
    80002808:	f85a                	sd	s6,48(sp)
    8000280a:	f45e                	sd	s7,40(sp)
    8000280c:	f062                	sd	s8,32(sp)
    8000280e:	ec66                	sd	s9,24(sp)
    80002810:	e86a                	sd	s10,16(sp)
    80002812:	e46e                	sd	s11,8(sp)
    80002814:	1880                	addi	s0,sp,112
//    consputc(t.running_process);
    int unusedCount = 0;
    int sleepCount = 0;
    int runningCount = 0;

    for (int i = 0; i < NPROC; i++) {
    80002816:	00010797          	auipc	a5,0x10
    8000281a:	86a78793          	addi	a5,a5,-1942 # 80012080 <proc+0x18>
    8000281e:	00015697          	auipc	a3,0x15
    80002822:	26268693          	addi	a3,a3,610 # 80017a80 <bcache>
    int runningCount = 0;
    80002826:	4981                	li	s3,0
    int sleepCount = 0;
    80002828:	4901                	li	s2,0
    int unusedCount = 0;
    8000282a:	4481                	li	s1,0
        if(proc[i].state == UNUSED){
            unusedCount++;
        }
        if(proc[i].state == SLEEPING){
    8000282c:	4609                	li	a2,2
            sleepCount++;
        }
        if(proc[i].state == RUNNING){
    8000282e:	4591                	li	a1,4
    80002830:	a801                	j	80002840 <get_top_info+0x48>
        if(proc[i].state == SLEEPING){
    80002832:	00c71b63          	bne	a4,a2,80002848 <get_top_info+0x50>
            sleepCount++;
    80002836:	2905                	addiw	s2,s2,1
    for (int i = 0; i < NPROC; i++) {
    80002838:	16878793          	addi	a5,a5,360
    8000283c:	00d78a63          	beq	a5,a3,80002850 <get_top_info+0x58>
        if(proc[i].state == UNUSED){
    80002840:	4398                	lw	a4,0(a5)
    80002842:	fb65                	bnez	a4,80002832 <get_top_info+0x3a>
            unusedCount++;
    80002844:	2485                	addiw	s1,s1,1
        if(proc[i].state == RUNNING){
    80002846:	bfcd                	j	80002838 <get_top_info+0x40>
    80002848:	feb718e3          	bne	a4,a1,80002838 <get_top_info+0x40>
            runningCount++;
    8000284c:	2985                	addiw	s3,s3,1
    8000284e:	b7ed                	j	80002838 <get_top_info+0x40>
        }


    }
    int uptime = 0;
    uptime = sys_uptime();
    80002850:	00001097          	auipc	ra,0x1
    80002854:	904080e7          	jalr	-1788(ra) # 80003154 <sys_uptime>
    topp.uptime = uptime;
    80002858:	0005059b          	sext.w	a1,a0
    8000285c:	0000fa17          	auipc	s4,0xf
    80002860:	ca4a0a13          	addi	s4,s4,-860 # 80011500 <pid_lock>
    80002864:	42ba3823          	sd	a1,1072(s4)
    topp.total_process = NPROC - unusedCount;
    80002868:	04000793          	li	a5,64
    8000286c:	409784bb          	subw	s1,a5,s1
    80002870:	429a2c23          	sw	s1,1080(s4)
    topp.running_process = runningCount;
    80002874:	433a2e23          	sw	s3,1084(s4)
    topp.sleeping_process = sleepCount;
    80002878:	452a2023          	sw	s2,1088(s4)
    printf("\nuptime:%d seconds",topp.uptime);
    8000287c:	00006517          	auipc	a0,0x6
    80002880:	a1c50513          	addi	a0,a0,-1508 # 80008298 <digits+0x258>
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	f46080e7          	jalr	-186(ra) # 800007ca <printf>
    printf("\nTotal process: %d\n", topp.total_process);
    8000288c:	438a2583          	lw	a1,1080(s4)
    80002890:	00006517          	auipc	a0,0x6
    80002894:	a2050513          	addi	a0,a0,-1504 # 800082b0 <digits+0x270>
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	f32080e7          	jalr	-206(ra) # 800007ca <printf>
    printf("Running process: %d\n",   topp.running_process);
    800028a0:	43ca2583          	lw	a1,1084(s4)
    800028a4:	00006517          	auipc	a0,0x6
    800028a8:	a2450513          	addi	a0,a0,-1500 # 800082c8 <digits+0x288>
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	f1e080e7          	jalr	-226(ra) # 800007ca <printf>
    printf("Sleeping process: %d\n", topp.sleeping_process);
    800028b4:	440a2583          	lw	a1,1088(s4)
    800028b8:	00006517          	auipc	a0,0x6
    800028bc:	a2850513          	addi	a0,a0,-1496 # 800082e0 <digits+0x2a0>
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	f0a080e7          	jalr	-246(ra) # 800007ca <printf>

    struct proc *pointer;
    char *state;


    printf("process data:\n");
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	a3050513          	addi	a0,a0,-1488 # 800082f8 <digits+0x2b8>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	efa080e7          	jalr	-262(ra) # 800007ca <printf>
    printf("name    PID    state        PPID\n" );
    800028d8:	00006517          	auipc	a0,0x6
    800028dc:	a3050513          	addi	a0,a0,-1488 # 80008308 <digits+0x2c8>
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	eea080e7          	jalr	-278(ra) # 800007ca <printf>
    for(pointer = proc; pointer < &proc[NPROC]; pointer++){
    800028e8:	00010497          	auipc	s1,0x10
    800028ec:	8d848493          	addi	s1,s1,-1832 # 800121c0 <proc+0x158>
    800028f0:	0000fa17          	auipc	s4,0xf
    800028f4:	778a0a13          	addi	s4,s4,1912 # 80012068 <proc>
    800028f8:	6799                	lui	a5,0x6
    800028fa:	b5878793          	addi	a5,a5,-1192 # 5b58 <_entry-0x7fffa4a8>
    800028fe:	9a3e                	add	s4,s4,a5
        if(pointer->state == UNUSED)
            continue;
        if(pointer->state >= 0 && pointer->state < NELEM(states) && states[pointer->state])
    80002900:	4c15                	li	s8,5
            state = states[pointer->state];
        else
            state = "???";
    80002902:	00006a97          	auipc	s5,0x6
    80002906:	97ea8a93          	addi	s5,s5,-1666 # 80008280 <digits+0x240>


        info.pid = pointer->pid;
    8000290a:	00010997          	auipc	s3,0x10
    8000290e:	bf698993          	addi	s3,s3,-1034 # 80012500 <proc+0x498>
        printf("%s      %d      %s",  pointer->name, info.pid, state );
    80002912:	00006b97          	auipc	s7,0x6
    80002916:	a1eb8b93          	addi	s7,s7,-1506 # 80008330 <digits+0x2f0>
        }
        else{
            info.ppid = 0;
            printf("    %d", info.ppid);
        }
        printf("\n");
    8000291a:	00006b17          	auipc	s6,0x6
    8000291e:	a0eb0b13          	addi	s6,s6,-1522 # 80008328 <digits+0x2e8>
            printf("    %d", info.ppid);
    80002922:	00006d97          	auipc	s11,0x6
    80002926:	a36d8d93          	addi	s11,s11,-1482 # 80008358 <digits+0x318>
            printf("        %d", info.ppid);
    8000292a:	00006c97          	auipc	s9,0x6
    8000292e:	a1ec8c93          	addi	s9,s9,-1506 # 80008348 <digits+0x308>
        if(pointer->state >= 0 && pointer->state < NELEM(states) && states[pointer->state])
    80002932:	00006d17          	auipc	s10,0x6
    80002936:	a6ed0d13          	addi	s10,s10,-1426 # 800083a0 <states>
    8000293a:	a83d                	j	80002978 <get_top_info+0x180>
        info.pid = pointer->pid;
    8000293c:	ed892603          	lw	a2,-296(s2)
    80002940:	b4c9ac23          	sw	a2,-1192(s3)
        printf("%s      %d      %s",  pointer->name, info.pid, state );
    80002944:	85ca                	mv	a1,s2
    80002946:	855e                	mv	a0,s7
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	e82080e7          	jalr	-382(ra) # 800007ca <printf>
        if(pointer->parent != 0){
    80002950:	ee093783          	ld	a5,-288(s2)
    80002954:	c3a9                	beqz	a5,80002996 <get_top_info+0x19e>
            info.ppid = pointer->parent->pid;
    80002956:	5b8c                	lw	a1,48(a5)
    80002958:	b4b9ae23          	sw	a1,-1188(s3)
            printf("        %d", info.ppid);
    8000295c:	8566                	mv	a0,s9
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	e6c080e7          	jalr	-404(ra) # 800007ca <printf>
        printf("\n");
    80002966:	855a                	mv	a0,s6
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	e62080e7          	jalr	-414(ra) # 800007ca <printf>
    for(pointer = proc; pointer < &proc[NPROC]; pointer++){
    80002970:	16848493          	addi	s1,s1,360
    80002974:	03448a63          	beq	s1,s4,800029a8 <get_top_info+0x1b0>
        if(pointer->state == UNUSED)
    80002978:	8926                	mv	s2,s1
    8000297a:	ec04a783          	lw	a5,-320(s1)
    8000297e:	dbed                	beqz	a5,80002970 <get_top_info+0x178>
            state = "???";
    80002980:	86d6                	mv	a3,s5
        if(pointer->state >= 0 && pointer->state < NELEM(states) && states[pointer->state])
    80002982:	fafc6de3          	bltu	s8,a5,8000293c <get_top_info+0x144>
    80002986:	1782                	slli	a5,a5,0x20
    80002988:	9381                	srli	a5,a5,0x20
    8000298a:	078e                	slli	a5,a5,0x3
    8000298c:	97ea                	add	a5,a5,s10
    8000298e:	6394                	ld	a3,0(a5)
    80002990:	f6d5                	bnez	a3,8000293c <get_top_info+0x144>
            state = "???";
    80002992:	86d6                	mv	a3,s5
    80002994:	b765                	j	8000293c <get_top_info+0x144>
            info.ppid = 0;
    80002996:	b409ae23          	sw	zero,-1188(s3)
            printf("    %d", info.ppid);
    8000299a:	4581                	li	a1,0
    8000299c:	856e                	mv	a0,s11
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	e2c080e7          	jalr	-468(ra) # 800007ca <printf>
    800029a6:	b7c1                	j	80002966 <get_top_info+0x16e>



    return 0;

}
    800029a8:	4501                	li	a0,0
    800029aa:	70a6                	ld	ra,104(sp)
    800029ac:	7406                	ld	s0,96(sp)
    800029ae:	64e6                	ld	s1,88(sp)
    800029b0:	6946                	ld	s2,80(sp)
    800029b2:	69a6                	ld	s3,72(sp)
    800029b4:	6a06                	ld	s4,64(sp)
    800029b6:	7ae2                	ld	s5,56(sp)
    800029b8:	7b42                	ld	s6,48(sp)
    800029ba:	7ba2                	ld	s7,40(sp)
    800029bc:	7c02                	ld	s8,32(sp)
    800029be:	6ce2                	ld	s9,24(sp)
    800029c0:	6d42                	ld	s10,16(sp)
    800029c2:	6da2                	ld	s11,8(sp)
    800029c4:	6165                	addi	sp,sp,112
    800029c6:	8082                	ret

00000000800029c8 <swtch>:
    800029c8:	00153023          	sd	ra,0(a0)
    800029cc:	00253423          	sd	sp,8(a0)
    800029d0:	e900                	sd	s0,16(a0)
    800029d2:	ed04                	sd	s1,24(a0)
    800029d4:	03253023          	sd	s2,32(a0)
    800029d8:	03353423          	sd	s3,40(a0)
    800029dc:	03453823          	sd	s4,48(a0)
    800029e0:	03553c23          	sd	s5,56(a0)
    800029e4:	05653023          	sd	s6,64(a0)
    800029e8:	05753423          	sd	s7,72(a0)
    800029ec:	05853823          	sd	s8,80(a0)
    800029f0:	05953c23          	sd	s9,88(a0)
    800029f4:	07a53023          	sd	s10,96(a0)
    800029f8:	07b53423          	sd	s11,104(a0)
    800029fc:	0005b083          	ld	ra,0(a1)
    80002a00:	0085b103          	ld	sp,8(a1)
    80002a04:	6980                	ld	s0,16(a1)
    80002a06:	6d84                	ld	s1,24(a1)
    80002a08:	0205b903          	ld	s2,32(a1)
    80002a0c:	0285b983          	ld	s3,40(a1)
    80002a10:	0305ba03          	ld	s4,48(a1)
    80002a14:	0385ba83          	ld	s5,56(a1)
    80002a18:	0405bb03          	ld	s6,64(a1)
    80002a1c:	0485bb83          	ld	s7,72(a1)
    80002a20:	0505bc03          	ld	s8,80(a1)
    80002a24:	0585bc83          	ld	s9,88(a1)
    80002a28:	0605bd03          	ld	s10,96(a1)
    80002a2c:	0685bd83          	ld	s11,104(a1)
    80002a30:	8082                	ret

0000000080002a32 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a32:	1141                	addi	sp,sp,-16
    80002a34:	e406                	sd	ra,8(sp)
    80002a36:	e022                	sd	s0,0(sp)
    80002a38:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a3a:	00006597          	auipc	a1,0x6
    80002a3e:	99658593          	addi	a1,a1,-1642 # 800083d0 <states+0x30>
    80002a42:	00015517          	auipc	a0,0x15
    80002a46:	02650513          	addi	a0,a0,38 # 80017a68 <tickslock>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	33e080e7          	jalr	830(ra) # 80000d88 <initlock>
}
    80002a52:	60a2                	ld	ra,8(sp)
    80002a54:	6402                	ld	s0,0(sp)
    80002a56:	0141                	addi	sp,sp,16
    80002a58:	8082                	ret

0000000080002a5a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a5a:	1141                	addi	sp,sp,-16
    80002a5c:	e422                	sd	s0,8(sp)
    80002a5e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a60:	00003797          	auipc	a5,0x3
    80002a64:	54078793          	addi	a5,a5,1344 # 80005fa0 <kernelvec>
    80002a68:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a6c:	6422                	ld	s0,8(sp)
    80002a6e:	0141                	addi	sp,sp,16
    80002a70:	8082                	ret

0000000080002a72 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a72:	1141                	addi	sp,sp,-16
    80002a74:	e406                	sd	ra,8(sp)
    80002a76:	e022                	sd	s0,0(sp)
    80002a78:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a7a:	fffff097          	auipc	ra,0xfffff
    80002a7e:	174080e7          	jalr	372(ra) # 80001bee <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a82:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a86:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a88:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a8c:	00004617          	auipc	a2,0x4
    80002a90:	57460613          	addi	a2,a2,1396 # 80007000 <_trampoline>
    80002a94:	00004697          	auipc	a3,0x4
    80002a98:	56c68693          	addi	a3,a3,1388 # 80007000 <_trampoline>
    80002a9c:	8e91                	sub	a3,a3,a2
    80002a9e:	040007b7          	lui	a5,0x4000
    80002aa2:	17fd                	addi	a5,a5,-1
    80002aa4:	07b2                	slli	a5,a5,0xc
    80002aa6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aa8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002aac:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002aae:	180026f3          	csrr	a3,satp
    80002ab2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ab4:	6d38                	ld	a4,88(a0)
    80002ab6:	6134                	ld	a3,64(a0)
    80002ab8:	6585                	lui	a1,0x1
    80002aba:	96ae                	add	a3,a3,a1
    80002abc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002abe:	6d38                	ld	a4,88(a0)
    80002ac0:	00000697          	auipc	a3,0x0
    80002ac4:	13068693          	addi	a3,a3,304 # 80002bf0 <usertrap>
    80002ac8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002aca:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002acc:	8692                	mv	a3,tp
    80002ace:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ad4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ad8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002adc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ae0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ae2:	6f18                	ld	a4,24(a4)
    80002ae4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ae8:	6928                	ld	a0,80(a0)
    80002aea:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002aec:	00004717          	auipc	a4,0x4
    80002af0:	5b070713          	addi	a4,a4,1456 # 8000709c <userret>
    80002af4:	8f11                	sub	a4,a4,a2
    80002af6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002af8:	577d                	li	a4,-1
    80002afa:	177e                	slli	a4,a4,0x3f
    80002afc:	8d59                	or	a0,a0,a4
    80002afe:	9782                	jalr	a5
}
    80002b00:	60a2                	ld	ra,8(sp)
    80002b02:	6402                	ld	s0,0(sp)
    80002b04:	0141                	addi	sp,sp,16
    80002b06:	8082                	ret

0000000080002b08 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b08:	1101                	addi	sp,sp,-32
    80002b0a:	ec06                	sd	ra,24(sp)
    80002b0c:	e822                	sd	s0,16(sp)
    80002b0e:	e426                	sd	s1,8(sp)
    80002b10:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b12:	00015497          	auipc	s1,0x15
    80002b16:	f5648493          	addi	s1,s1,-170 # 80017a68 <tickslock>
    80002b1a:	8526                	mv	a0,s1
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	2fc080e7          	jalr	764(ra) # 80000e18 <acquire>
  ticks++;
    80002b24:	00006517          	auipc	a0,0x6
    80002b28:	e9c50513          	addi	a0,a0,-356 # 800089c0 <ticks>
    80002b2c:	411c                	lw	a5,0(a0)
    80002b2e:	2785                	addiw	a5,a5,1
    80002b30:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b32:	fffff097          	auipc	ra,0xfffff
    80002b36:	7c8080e7          	jalr	1992(ra) # 800022fa <wakeup>
  release(&tickslock);
    80002b3a:	8526                	mv	a0,s1
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	390080e7          	jalr	912(ra) # 80000ecc <release>
}
    80002b44:	60e2                	ld	ra,24(sp)
    80002b46:	6442                	ld	s0,16(sp)
    80002b48:	64a2                	ld	s1,8(sp)
    80002b4a:	6105                	addi	sp,sp,32
    80002b4c:	8082                	ret

0000000080002b4e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b4e:	1101                	addi	sp,sp,-32
    80002b50:	ec06                	sd	ra,24(sp)
    80002b52:	e822                	sd	s0,16(sp)
    80002b54:	e426                	sd	s1,8(sp)
    80002b56:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b58:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b5c:	00074d63          	bltz	a4,80002b76 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b60:	57fd                	li	a5,-1
    80002b62:	17fe                	slli	a5,a5,0x3f
    80002b64:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b66:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b68:	06f70363          	beq	a4,a5,80002bce <devintr+0x80>
  }
}
    80002b6c:	60e2                	ld	ra,24(sp)
    80002b6e:	6442                	ld	s0,16(sp)
    80002b70:	64a2                	ld	s1,8(sp)
    80002b72:	6105                	addi	sp,sp,32
    80002b74:	8082                	ret
     (scause & 0xff) == 9){
    80002b76:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b7a:	46a5                	li	a3,9
    80002b7c:	fed792e3          	bne	a5,a3,80002b60 <devintr+0x12>
    int irq = plic_claim();
    80002b80:	00003097          	auipc	ra,0x3
    80002b84:	528080e7          	jalr	1320(ra) # 800060a8 <plic_claim>
    80002b88:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b8a:	47a9                	li	a5,10
    80002b8c:	02f50763          	beq	a0,a5,80002bba <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b90:	4785                	li	a5,1
    80002b92:	02f50963          	beq	a0,a5,80002bc4 <devintr+0x76>
    return 1;
    80002b96:	4505                	li	a0,1
    } else if(irq){
    80002b98:	d8f1                	beqz	s1,80002b6c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b9a:	85a6                	mv	a1,s1
    80002b9c:	00006517          	auipc	a0,0x6
    80002ba0:	83c50513          	addi	a0,a0,-1988 # 800083d8 <states+0x38>
    80002ba4:	ffffe097          	auipc	ra,0xffffe
    80002ba8:	c26080e7          	jalr	-986(ra) # 800007ca <printf>
      plic_complete(irq);
    80002bac:	8526                	mv	a0,s1
    80002bae:	00003097          	auipc	ra,0x3
    80002bb2:	51e080e7          	jalr	1310(ra) # 800060cc <plic_complete>
    return 1;
    80002bb6:	4505                	li	a0,1
    80002bb8:	bf55                	j	80002b6c <devintr+0x1e>
      uartintr();
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	022080e7          	jalr	34(ra) # 80000bdc <uartintr>
    80002bc2:	b7ed                	j	80002bac <devintr+0x5e>
      virtio_disk_intr();
    80002bc4:	00004097          	auipc	ra,0x4
    80002bc8:	9d4080e7          	jalr	-1580(ra) # 80006598 <virtio_disk_intr>
    80002bcc:	b7c5                	j	80002bac <devintr+0x5e>
    if(cpuid() == 0){
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	ff4080e7          	jalr	-12(ra) # 80001bc2 <cpuid>
    80002bd6:	c901                	beqz	a0,80002be6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bd8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bdc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bde:	14479073          	csrw	sip,a5
    return 2;
    80002be2:	4509                	li	a0,2
    80002be4:	b761                	j	80002b6c <devintr+0x1e>
      clockintr();
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	f22080e7          	jalr	-222(ra) # 80002b08 <clockintr>
    80002bee:	b7ed                	j	80002bd8 <devintr+0x8a>

0000000080002bf0 <usertrap>:
{
    80002bf0:	1101                	addi	sp,sp,-32
    80002bf2:	ec06                	sd	ra,24(sp)
    80002bf4:	e822                	sd	s0,16(sp)
    80002bf6:	e426                	sd	s1,8(sp)
    80002bf8:	e04a                	sd	s2,0(sp)
    80002bfa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bfc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c00:	1007f793          	andi	a5,a5,256
    80002c04:	e3b1                	bnez	a5,80002c48 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c06:	00003797          	auipc	a5,0x3
    80002c0a:	39a78793          	addi	a5,a5,922 # 80005fa0 <kernelvec>
    80002c0e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	fdc080e7          	jalr	-36(ra) # 80001bee <myproc>
    80002c1a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c1c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c1e:	14102773          	csrr	a4,sepc
    80002c22:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c24:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c28:	47a1                	li	a5,8
    80002c2a:	02f70763          	beq	a4,a5,80002c58 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002c2e:	00000097          	auipc	ra,0x0
    80002c32:	f20080e7          	jalr	-224(ra) # 80002b4e <devintr>
    80002c36:	892a                	mv	s2,a0
    80002c38:	c151                	beqz	a0,80002cbc <usertrap+0xcc>
  if(killed(p))
    80002c3a:	8526                	mv	a0,s1
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	902080e7          	jalr	-1790(ra) # 8000253e <killed>
    80002c44:	c929                	beqz	a0,80002c96 <usertrap+0xa6>
    80002c46:	a099                	j	80002c8c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002c48:	00005517          	auipc	a0,0x5
    80002c4c:	7b050513          	addi	a0,a0,1968 # 800083f8 <states+0x58>
    80002c50:	ffffe097          	auipc	ra,0xffffe
    80002c54:	b30080e7          	jalr	-1232(ra) # 80000780 <panic>
    if(killed(p))
    80002c58:	00000097          	auipc	ra,0x0
    80002c5c:	8e6080e7          	jalr	-1818(ra) # 8000253e <killed>
    80002c60:	e921                	bnez	a0,80002cb0 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002c62:	6cb8                	ld	a4,88(s1)
    80002c64:	6f1c                	ld	a5,24(a4)
    80002c66:	0791                	addi	a5,a5,4
    80002c68:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c72:	10079073          	csrw	sstatus,a5
    syscall();
    80002c76:	00000097          	auipc	ra,0x0
    80002c7a:	2d4080e7          	jalr	724(ra) # 80002f4a <syscall>
  if(killed(p))
    80002c7e:	8526                	mv	a0,s1
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	8be080e7          	jalr	-1858(ra) # 8000253e <killed>
    80002c88:	c911                	beqz	a0,80002c9c <usertrap+0xac>
    80002c8a:	4901                	li	s2,0
    exit(-1);
    80002c8c:	557d                	li	a0,-1
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	73c080e7          	jalr	1852(ra) # 800023ca <exit>
  if(which_dev == 2)
    80002c96:	4789                	li	a5,2
    80002c98:	04f90f63          	beq	s2,a5,80002cf6 <usertrap+0x106>
  usertrapret();
    80002c9c:	00000097          	auipc	ra,0x0
    80002ca0:	dd6080e7          	jalr	-554(ra) # 80002a72 <usertrapret>
}
    80002ca4:	60e2                	ld	ra,24(sp)
    80002ca6:	6442                	ld	s0,16(sp)
    80002ca8:	64a2                	ld	s1,8(sp)
    80002caa:	6902                	ld	s2,0(sp)
    80002cac:	6105                	addi	sp,sp,32
    80002cae:	8082                	ret
      exit(-1);
    80002cb0:	557d                	li	a0,-1
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	718080e7          	jalr	1816(ra) # 800023ca <exit>
    80002cba:	b765                	j	80002c62 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cbc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cc0:	5890                	lw	a2,48(s1)
    80002cc2:	00005517          	auipc	a0,0x5
    80002cc6:	75650513          	addi	a0,a0,1878 # 80008418 <states+0x78>
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	b00080e7          	jalr	-1280(ra) # 800007ca <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cd2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cd6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cda:	00005517          	auipc	a0,0x5
    80002cde:	76e50513          	addi	a0,a0,1902 # 80008448 <states+0xa8>
    80002ce2:	ffffe097          	auipc	ra,0xffffe
    80002ce6:	ae8080e7          	jalr	-1304(ra) # 800007ca <printf>
    setkilled(p);
    80002cea:	8526                	mv	a0,s1
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	826080e7          	jalr	-2010(ra) # 80002512 <setkilled>
    80002cf4:	b769                	j	80002c7e <usertrap+0x8e>
    yield();
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	564080e7          	jalr	1380(ra) # 8000225a <yield>
    80002cfe:	bf79                	j	80002c9c <usertrap+0xac>

0000000080002d00 <kerneltrap>:
{
    80002d00:	7179                	addi	sp,sp,-48
    80002d02:	f406                	sd	ra,40(sp)
    80002d04:	f022                	sd	s0,32(sp)
    80002d06:	ec26                	sd	s1,24(sp)
    80002d08:	e84a                	sd	s2,16(sp)
    80002d0a:	e44e                	sd	s3,8(sp)
    80002d0c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d0e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d12:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d16:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d1a:	1004f793          	andi	a5,s1,256
    80002d1e:	cb85                	beqz	a5,80002d4e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d20:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d24:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d26:	ef85                	bnez	a5,80002d5e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	e26080e7          	jalr	-474(ra) # 80002b4e <devintr>
    80002d30:	cd1d                	beqz	a0,80002d6e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d32:	4789                	li	a5,2
    80002d34:	06f50a63          	beq	a0,a5,80002da8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d38:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d3c:	10049073          	csrw	sstatus,s1
}
    80002d40:	70a2                	ld	ra,40(sp)
    80002d42:	7402                	ld	s0,32(sp)
    80002d44:	64e2                	ld	s1,24(sp)
    80002d46:	6942                	ld	s2,16(sp)
    80002d48:	69a2                	ld	s3,8(sp)
    80002d4a:	6145                	addi	sp,sp,48
    80002d4c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d4e:	00005517          	auipc	a0,0x5
    80002d52:	71a50513          	addi	a0,a0,1818 # 80008468 <states+0xc8>
    80002d56:	ffffe097          	auipc	ra,0xffffe
    80002d5a:	a2a080e7          	jalr	-1494(ra) # 80000780 <panic>
    panic("kerneltrap: interrupts enabled");
    80002d5e:	00005517          	auipc	a0,0x5
    80002d62:	73250513          	addi	a0,a0,1842 # 80008490 <states+0xf0>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	a1a080e7          	jalr	-1510(ra) # 80000780 <panic>
    printf("scause %p\n", scause);
    80002d6e:	85ce                	mv	a1,s3
    80002d70:	00005517          	auipc	a0,0x5
    80002d74:	74050513          	addi	a0,a0,1856 # 800084b0 <states+0x110>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	a52080e7          	jalr	-1454(ra) # 800007ca <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d80:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d84:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d88:	00005517          	auipc	a0,0x5
    80002d8c:	73850513          	addi	a0,a0,1848 # 800084c0 <states+0x120>
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	a3a080e7          	jalr	-1478(ra) # 800007ca <printf>
    panic("kerneltrap");
    80002d98:	00005517          	auipc	a0,0x5
    80002d9c:	74050513          	addi	a0,a0,1856 # 800084d8 <states+0x138>
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	9e0080e7          	jalr	-1568(ra) # 80000780 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	e46080e7          	jalr	-442(ra) # 80001bee <myproc>
    80002db0:	d541                	beqz	a0,80002d38 <kerneltrap+0x38>
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	e3c080e7          	jalr	-452(ra) # 80001bee <myproc>
    80002dba:	4d18                	lw	a4,24(a0)
    80002dbc:	4791                	li	a5,4
    80002dbe:	f6f71de3          	bne	a4,a5,80002d38 <kerneltrap+0x38>
    yield();
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	498080e7          	jalr	1176(ra) # 8000225a <yield>
    80002dca:	b7bd                	j	80002d38 <kerneltrap+0x38>

0000000080002dcc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	e426                	sd	s1,8(sp)
    80002dd4:	1000                	addi	s0,sp,32
    80002dd6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	e16080e7          	jalr	-490(ra) # 80001bee <myproc>
  switch (n) {
    80002de0:	4795                	li	a5,5
    80002de2:	0497e163          	bltu	a5,s1,80002e24 <argraw+0x58>
    80002de6:	048a                	slli	s1,s1,0x2
    80002de8:	00005717          	auipc	a4,0x5
    80002dec:	72870713          	addi	a4,a4,1832 # 80008510 <states+0x170>
    80002df0:	94ba                	add	s1,s1,a4
    80002df2:	409c                	lw	a5,0(s1)
    80002df4:	97ba                	add	a5,a5,a4
    80002df6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002df8:	6d3c                	ld	a5,88(a0)
    80002dfa:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	64a2                	ld	s1,8(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret
    return p->trapframe->a1;
    80002e06:	6d3c                	ld	a5,88(a0)
    80002e08:	7fa8                	ld	a0,120(a5)
    80002e0a:	bfcd                	j	80002dfc <argraw+0x30>
    return p->trapframe->a2;
    80002e0c:	6d3c                	ld	a5,88(a0)
    80002e0e:	63c8                	ld	a0,128(a5)
    80002e10:	b7f5                	j	80002dfc <argraw+0x30>
    return p->trapframe->a3;
    80002e12:	6d3c                	ld	a5,88(a0)
    80002e14:	67c8                	ld	a0,136(a5)
    80002e16:	b7dd                	j	80002dfc <argraw+0x30>
    return p->trapframe->a4;
    80002e18:	6d3c                	ld	a5,88(a0)
    80002e1a:	6bc8                	ld	a0,144(a5)
    80002e1c:	b7c5                	j	80002dfc <argraw+0x30>
    return p->trapframe->a5;
    80002e1e:	6d3c                	ld	a5,88(a0)
    80002e20:	6fc8                	ld	a0,152(a5)
    80002e22:	bfe9                	j	80002dfc <argraw+0x30>
  panic("argraw");
    80002e24:	00005517          	auipc	a0,0x5
    80002e28:	6c450513          	addi	a0,a0,1732 # 800084e8 <states+0x148>
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	954080e7          	jalr	-1708(ra) # 80000780 <panic>

0000000080002e34 <fetchaddr>:
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	e426                	sd	s1,8(sp)
    80002e3c:	e04a                	sd	s2,0(sp)
    80002e3e:	1000                	addi	s0,sp,32
    80002e40:	84aa                	mv	s1,a0
    80002e42:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	daa080e7          	jalr	-598(ra) # 80001bee <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e4c:	653c                	ld	a5,72(a0)
    80002e4e:	02f4f863          	bgeu	s1,a5,80002e7e <fetchaddr+0x4a>
    80002e52:	00848713          	addi	a4,s1,8
    80002e56:	02e7e663          	bltu	a5,a4,80002e82 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e5a:	46a1                	li	a3,8
    80002e5c:	8626                	mv	a2,s1
    80002e5e:	85ca                	mv	a1,s2
    80002e60:	6928                	ld	a0,80(a0)
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	ad4080e7          	jalr	-1324(ra) # 80001936 <copyin>
    80002e6a:	00a03533          	snez	a0,a0
    80002e6e:	40a00533          	neg	a0,a0
}
    80002e72:	60e2                	ld	ra,24(sp)
    80002e74:	6442                	ld	s0,16(sp)
    80002e76:	64a2                	ld	s1,8(sp)
    80002e78:	6902                	ld	s2,0(sp)
    80002e7a:	6105                	addi	sp,sp,32
    80002e7c:	8082                	ret
    return -1;
    80002e7e:	557d                	li	a0,-1
    80002e80:	bfcd                	j	80002e72 <fetchaddr+0x3e>
    80002e82:	557d                	li	a0,-1
    80002e84:	b7fd                	j	80002e72 <fetchaddr+0x3e>

0000000080002e86 <fetchstr>:
{
    80002e86:	7179                	addi	sp,sp,-48
    80002e88:	f406                	sd	ra,40(sp)
    80002e8a:	f022                	sd	s0,32(sp)
    80002e8c:	ec26                	sd	s1,24(sp)
    80002e8e:	e84a                	sd	s2,16(sp)
    80002e90:	e44e                	sd	s3,8(sp)
    80002e92:	1800                	addi	s0,sp,48
    80002e94:	892a                	mv	s2,a0
    80002e96:	84ae                	mv	s1,a1
    80002e98:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	d54080e7          	jalr	-684(ra) # 80001bee <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ea2:	86ce                	mv	a3,s3
    80002ea4:	864a                	mv	a2,s2
    80002ea6:	85a6                	mv	a1,s1
    80002ea8:	6928                	ld	a0,80(a0)
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	b1a080e7          	jalr	-1254(ra) # 800019c4 <copyinstr>
    80002eb2:	00054e63          	bltz	a0,80002ece <fetchstr+0x48>
  return strlen(buf);
    80002eb6:	8526                	mv	a0,s1
    80002eb8:	ffffe097          	auipc	ra,0xffffe
    80002ebc:	1d8080e7          	jalr	472(ra) # 80001090 <strlen>
}
    80002ec0:	70a2                	ld	ra,40(sp)
    80002ec2:	7402                	ld	s0,32(sp)
    80002ec4:	64e2                	ld	s1,24(sp)
    80002ec6:	6942                	ld	s2,16(sp)
    80002ec8:	69a2                	ld	s3,8(sp)
    80002eca:	6145                	addi	sp,sp,48
    80002ecc:	8082                	ret
    return -1;
    80002ece:	557d                	li	a0,-1
    80002ed0:	bfc5                	j	80002ec0 <fetchstr+0x3a>

0000000080002ed2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ed2:	1101                	addi	sp,sp,-32
    80002ed4:	ec06                	sd	ra,24(sp)
    80002ed6:	e822                	sd	s0,16(sp)
    80002ed8:	e426                	sd	s1,8(sp)
    80002eda:	1000                	addi	s0,sp,32
    80002edc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ede:	00000097          	auipc	ra,0x0
    80002ee2:	eee080e7          	jalr	-274(ra) # 80002dcc <argraw>
    80002ee6:	c088                	sw	a0,0(s1)
}
    80002ee8:	60e2                	ld	ra,24(sp)
    80002eea:	6442                	ld	s0,16(sp)
    80002eec:	64a2                	ld	s1,8(sp)
    80002eee:	6105                	addi	sp,sp,32
    80002ef0:	8082                	ret

0000000080002ef2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ef2:	1101                	addi	sp,sp,-32
    80002ef4:	ec06                	sd	ra,24(sp)
    80002ef6:	e822                	sd	s0,16(sp)
    80002ef8:	e426                	sd	s1,8(sp)
    80002efa:	1000                	addi	s0,sp,32
    80002efc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002efe:	00000097          	auipc	ra,0x0
    80002f02:	ece080e7          	jalr	-306(ra) # 80002dcc <argraw>
    80002f06:	e088                	sd	a0,0(s1)
}
    80002f08:	60e2                	ld	ra,24(sp)
    80002f0a:	6442                	ld	s0,16(sp)
    80002f0c:	64a2                	ld	s1,8(sp)
    80002f0e:	6105                	addi	sp,sp,32
    80002f10:	8082                	ret

0000000080002f12 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f12:	7179                	addi	sp,sp,-48
    80002f14:	f406                	sd	ra,40(sp)
    80002f16:	f022                	sd	s0,32(sp)
    80002f18:	ec26                	sd	s1,24(sp)
    80002f1a:	e84a                	sd	s2,16(sp)
    80002f1c:	1800                	addi	s0,sp,48
    80002f1e:	84ae                	mv	s1,a1
    80002f20:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f22:	fd840593          	addi	a1,s0,-40
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	fcc080e7          	jalr	-52(ra) # 80002ef2 <argaddr>
  return fetchstr(addr, buf, max);
    80002f2e:	864a                	mv	a2,s2
    80002f30:	85a6                	mv	a1,s1
    80002f32:	fd843503          	ld	a0,-40(s0)
    80002f36:	00000097          	auipc	ra,0x0
    80002f3a:	f50080e7          	jalr	-176(ra) # 80002e86 <fetchstr>
}
    80002f3e:	70a2                	ld	ra,40(sp)
    80002f40:	7402                	ld	s0,32(sp)
    80002f42:	64e2                	ld	s1,24(sp)
    80002f44:	6942                	ld	s2,16(sp)
    80002f46:	6145                	addi	sp,sp,48
    80002f48:	8082                	ret

0000000080002f4a <syscall>:

};

void
syscall(void)
{
    80002f4a:	1101                	addi	sp,sp,-32
    80002f4c:	ec06                	sd	ra,24(sp)
    80002f4e:	e822                	sd	s0,16(sp)
    80002f50:	e426                	sd	s1,8(sp)
    80002f52:	e04a                	sd	s2,0(sp)
    80002f54:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	c98080e7          	jalr	-872(ra) # 80001bee <myproc>
    80002f5e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f60:	05853903          	ld	s2,88(a0)
    80002f64:	0a893783          	ld	a5,168(s2)
    80002f68:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f6c:	37fd                	addiw	a5,a5,-1
    80002f6e:	4759                	li	a4,22
    80002f70:	00f76f63          	bltu	a4,a5,80002f8e <syscall+0x44>
    80002f74:	00369713          	slli	a4,a3,0x3
    80002f78:	00005797          	auipc	a5,0x5
    80002f7c:	5b078793          	addi	a5,a5,1456 # 80008528 <syscalls>
    80002f80:	97ba                	add	a5,a5,a4
    80002f82:	639c                	ld	a5,0(a5)
    80002f84:	c789                	beqz	a5,80002f8e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002f86:	9782                	jalr	a5
    80002f88:	06a93823          	sd	a0,112(s2)
    80002f8c:	a839                	j	80002faa <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f8e:	15848613          	addi	a2,s1,344
    80002f92:	588c                	lw	a1,48(s1)
    80002f94:	00005517          	auipc	a0,0x5
    80002f98:	55c50513          	addi	a0,a0,1372 # 800084f0 <states+0x150>
    80002f9c:	ffffe097          	auipc	ra,0xffffe
    80002fa0:	82e080e7          	jalr	-2002(ra) # 800007ca <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fa4:	6cbc                	ld	a5,88(s1)
    80002fa6:	577d                	li	a4,-1
    80002fa8:	fbb8                	sd	a4,112(a5)
  }
}
    80002faa:	60e2                	ld	ra,24(sp)
    80002fac:	6442                	ld	s0,16(sp)
    80002fae:	64a2                	ld	s1,8(sp)
    80002fb0:	6902                	ld	s2,0(sp)
    80002fb2:	6105                	addi	sp,sp,32
    80002fb4:	8082                	ret

0000000080002fb6 <sys_exit>:
#include "historyBuffer.h"


uint64
sys_exit(void)
{
    80002fb6:	1101                	addi	sp,sp,-32
    80002fb8:	ec06                	sd	ra,24(sp)
    80002fba:	e822                	sd	s0,16(sp)
    80002fbc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002fbe:	fec40593          	addi	a1,s0,-20
    80002fc2:	4501                	li	a0,0
    80002fc4:	00000097          	auipc	ra,0x0
    80002fc8:	f0e080e7          	jalr	-242(ra) # 80002ed2 <argint>
  exit(n);
    80002fcc:	fec42503          	lw	a0,-20(s0)
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	3fa080e7          	jalr	1018(ra) # 800023ca <exit>
  return 0;  // not reached
}
    80002fd8:	4501                	li	a0,0
    80002fda:	60e2                	ld	ra,24(sp)
    80002fdc:	6442                	ld	s0,16(sp)
    80002fde:	6105                	addi	sp,sp,32
    80002fe0:	8082                	ret

0000000080002fe2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fe2:	1141                	addi	sp,sp,-16
    80002fe4:	e406                	sd	ra,8(sp)
    80002fe6:	e022                	sd	s0,0(sp)
    80002fe8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fea:	fffff097          	auipc	ra,0xfffff
    80002fee:	c04080e7          	jalr	-1020(ra) # 80001bee <myproc>
}
    80002ff2:	5908                	lw	a0,48(a0)
    80002ff4:	60a2                	ld	ra,8(sp)
    80002ff6:	6402                	ld	s0,0(sp)
    80002ff8:	0141                	addi	sp,sp,16
    80002ffa:	8082                	ret

0000000080002ffc <sys_fork>:

uint64
sys_fork(void)
{
    80002ffc:	1141                	addi	sp,sp,-16
    80002ffe:	e406                	sd	ra,8(sp)
    80003000:	e022                	sd	s0,0(sp)
    80003002:	0800                	addi	s0,sp,16
  return fork();
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	fa0080e7          	jalr	-96(ra) # 80001fa4 <fork>
}
    8000300c:	60a2                	ld	ra,8(sp)
    8000300e:	6402                	ld	s0,0(sp)
    80003010:	0141                	addi	sp,sp,16
    80003012:	8082                	ret

0000000080003014 <sys_wait>:

uint64
sys_wait(void)
{
    80003014:	1101                	addi	sp,sp,-32
    80003016:	ec06                	sd	ra,24(sp)
    80003018:	e822                	sd	s0,16(sp)
    8000301a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000301c:	fe840593          	addi	a1,s0,-24
    80003020:	4501                	li	a0,0
    80003022:	00000097          	auipc	ra,0x0
    80003026:	ed0080e7          	jalr	-304(ra) # 80002ef2 <argaddr>
  return wait(p);
    8000302a:	fe843503          	ld	a0,-24(s0)
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	542080e7          	jalr	1346(ra) # 80002570 <wait>
}
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret

000000008000303e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000303e:	7179                	addi	sp,sp,-48
    80003040:	f406                	sd	ra,40(sp)
    80003042:	f022                	sd	s0,32(sp)
    80003044:	ec26                	sd	s1,24(sp)
    80003046:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003048:	fdc40593          	addi	a1,s0,-36
    8000304c:	4501                	li	a0,0
    8000304e:	00000097          	auipc	ra,0x0
    80003052:	e84080e7          	jalr	-380(ra) # 80002ed2 <argint>
  addr = myproc()->sz;
    80003056:	fffff097          	auipc	ra,0xfffff
    8000305a:	b98080e7          	jalr	-1128(ra) # 80001bee <myproc>
    8000305e:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80003060:	fdc42503          	lw	a0,-36(s0)
    80003064:	fffff097          	auipc	ra,0xfffff
    80003068:	ee4080e7          	jalr	-284(ra) # 80001f48 <growproc>
    8000306c:	00054863          	bltz	a0,8000307c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003070:	8526                	mv	a0,s1
    80003072:	70a2                	ld	ra,40(sp)
    80003074:	7402                	ld	s0,32(sp)
    80003076:	64e2                	ld	s1,24(sp)
    80003078:	6145                	addi	sp,sp,48
    8000307a:	8082                	ret
    return -1;
    8000307c:	54fd                	li	s1,-1
    8000307e:	bfcd                	j	80003070 <sys_sbrk+0x32>

0000000080003080 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003080:	7139                	addi	sp,sp,-64
    80003082:	fc06                	sd	ra,56(sp)
    80003084:	f822                	sd	s0,48(sp)
    80003086:	f426                	sd	s1,40(sp)
    80003088:	f04a                	sd	s2,32(sp)
    8000308a:	ec4e                	sd	s3,24(sp)
    8000308c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000308e:	fcc40593          	addi	a1,s0,-52
    80003092:	4501                	li	a0,0
    80003094:	00000097          	auipc	ra,0x0
    80003098:	e3e080e7          	jalr	-450(ra) # 80002ed2 <argint>
  acquire(&tickslock);
    8000309c:	00015517          	auipc	a0,0x15
    800030a0:	9cc50513          	addi	a0,a0,-1588 # 80017a68 <tickslock>
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	d74080e7          	jalr	-652(ra) # 80000e18 <acquire>
  ticks0 = ticks;
    800030ac:	00006917          	auipc	s2,0x6
    800030b0:	91492903          	lw	s2,-1772(s2) # 800089c0 <ticks>
  while(ticks - ticks0 < n){
    800030b4:	fcc42783          	lw	a5,-52(s0)
    800030b8:	cf9d                	beqz	a5,800030f6 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030ba:	00015997          	auipc	s3,0x15
    800030be:	9ae98993          	addi	s3,s3,-1618 # 80017a68 <tickslock>
    800030c2:	00006497          	auipc	s1,0x6
    800030c6:	8fe48493          	addi	s1,s1,-1794 # 800089c0 <ticks>
    if(killed(myproc())){
    800030ca:	fffff097          	auipc	ra,0xfffff
    800030ce:	b24080e7          	jalr	-1244(ra) # 80001bee <myproc>
    800030d2:	fffff097          	auipc	ra,0xfffff
    800030d6:	46c080e7          	jalr	1132(ra) # 8000253e <killed>
    800030da:	ed15                	bnez	a0,80003116 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800030dc:	85ce                	mv	a1,s3
    800030de:	8526                	mv	a0,s1
    800030e0:	fffff097          	auipc	ra,0xfffff
    800030e4:	1b6080e7          	jalr	438(ra) # 80002296 <sleep>
  while(ticks - ticks0 < n){
    800030e8:	409c                	lw	a5,0(s1)
    800030ea:	412787bb          	subw	a5,a5,s2
    800030ee:	fcc42703          	lw	a4,-52(s0)
    800030f2:	fce7ece3          	bltu	a5,a4,800030ca <sys_sleep+0x4a>
  }
  release(&tickslock);
    800030f6:	00015517          	auipc	a0,0x15
    800030fa:	97250513          	addi	a0,a0,-1678 # 80017a68 <tickslock>
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	dce080e7          	jalr	-562(ra) # 80000ecc <release>
  return 0;
    80003106:	4501                	li	a0,0
}
    80003108:	70e2                	ld	ra,56(sp)
    8000310a:	7442                	ld	s0,48(sp)
    8000310c:	74a2                	ld	s1,40(sp)
    8000310e:	7902                	ld	s2,32(sp)
    80003110:	69e2                	ld	s3,24(sp)
    80003112:	6121                	addi	sp,sp,64
    80003114:	8082                	ret
      release(&tickslock);
    80003116:	00015517          	auipc	a0,0x15
    8000311a:	95250513          	addi	a0,a0,-1710 # 80017a68 <tickslock>
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	dae080e7          	jalr	-594(ra) # 80000ecc <release>
      return -1;
    80003126:	557d                	li	a0,-1
    80003128:	b7c5                	j	80003108 <sys_sleep+0x88>

000000008000312a <sys_kill>:

uint64
sys_kill(void)
{
    8000312a:	1101                	addi	sp,sp,-32
    8000312c:	ec06                	sd	ra,24(sp)
    8000312e:	e822                	sd	s0,16(sp)
    80003130:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003132:	fec40593          	addi	a1,s0,-20
    80003136:	4501                	li	a0,0
    80003138:	00000097          	auipc	ra,0x0
    8000313c:	d9a080e7          	jalr	-614(ra) # 80002ed2 <argint>
  return kill(pid);
    80003140:	fec42503          	lw	a0,-20(s0)
    80003144:	fffff097          	auipc	ra,0xfffff
    80003148:	35c080e7          	jalr	860(ra) # 800024a0 <kill>
}
    8000314c:	60e2                	ld	ra,24(sp)
    8000314e:	6442                	ld	s0,16(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret

0000000080003154 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003154:	1101                	addi	sp,sp,-32
    80003156:	ec06                	sd	ra,24(sp)
    80003158:	e822                	sd	s0,16(sp)
    8000315a:	e426                	sd	s1,8(sp)
    8000315c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000315e:	00015517          	auipc	a0,0x15
    80003162:	90a50513          	addi	a0,a0,-1782 # 80017a68 <tickslock>
    80003166:	ffffe097          	auipc	ra,0xffffe
    8000316a:	cb2080e7          	jalr	-846(ra) # 80000e18 <acquire>
  xticks = ticks;
    8000316e:	00006497          	auipc	s1,0x6
    80003172:	8524a483          	lw	s1,-1966(s1) # 800089c0 <ticks>
  release(&tickslock);
    80003176:	00015517          	auipc	a0,0x15
    8000317a:	8f250513          	addi	a0,a0,-1806 # 80017a68 <tickslock>
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	d4e080e7          	jalr	-690(ra) # 80000ecc <release>
  return xticks;
}
    80003186:	02049513          	slli	a0,s1,0x20
    8000318a:	9101                	srli	a0,a0,0x20
    8000318c:	60e2                	ld	ra,24(sp)
    8000318e:	6442                	ld	s0,16(sp)
    80003190:	64a2                	ld	s1,8(sp)
    80003192:	6105                	addi	sp,sp,32
    80003194:	8082                	ret

0000000080003196 <sys_history>:

uint64
sys_history(void)
{
    80003196:	7179                	addi	sp,sp,-48
    80003198:	f406                	sd	ra,40(sp)
    8000319a:	f022                	sd	s0,32(sp)
    8000319c:	ec26                	sd	s1,24(sp)
    8000319e:	e84a                	sd	s2,16(sp)
    800031a0:	1800                	addi	s0,sp,48
   // struct syshistory *history;

    int historyNum;
    argint(0, &historyNum);
    800031a2:	fdc40593          	addi	a1,s0,-36
    800031a6:	4501                	li	a0,0
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	d2a080e7          	jalr	-726(ra) # 80002ed2 <argint>
    int err = 0;
//    printf("hellooooo\n");

    int target = 0;
//    printf("[%d]", historyBuf.lastCommandIndex);
    target = historyBuf.lastCommandIndex - historyNum;
    800031b0:	0000e797          	auipc	a5,0xe
    800031b4:	a0878793          	addi	a5,a5,-1528 # 80010bb8 <historyBuf>
    800031b8:	0000e917          	auipc	s2,0xe
    800031bc:	24092903          	lw	s2,576(s2) # 800113f8 <historyBuf+0x840>
    800031c0:	fdc42703          	lw	a4,-36(s0)
    800031c4:	40e9093b          	subw	s2,s2,a4
    800031c8:	091e                	slli	s2,s2,0x7
    800031ca:	f8090493          	addi	s1,s2,-128
    800031ce:	94be                	add	s1,s1,a5
    800031d0:	993e                	add	s2,s2,a5
//        printf(" ");

       // consputc(historyBuf.bufferArr[5][i]);
//    }
    for (int i = 0; i < 128; ++i) {
        consputc(historyBuf.bufferArr[target-1][i]);
    800031d2:	0004c503          	lbu	a0,0(s1)
    800031d6:	ffffd097          	auipc	ra,0xffffd
    800031da:	178080e7          	jalr	376(ra) # 8000034e <consputc>
    for (int i = 0; i < 128; ++i) {
    800031de:	0485                	addi	s1,s1,1
    800031e0:	ff2499e3          	bne	s1,s2,800031d2 <sys_history+0x3c>

    }


    printf("\n");
    800031e4:	00005517          	auipc	a0,0x5
    800031e8:	14450513          	addi	a0,a0,324 # 80008328 <digits+0x2e8>
    800031ec:	ffffd097          	auipc	ra,0xffffd
    800031f0:	5de080e7          	jalr	1502(ra) # 800007ca <printf>

    return err;
}
    800031f4:	4501                	li	a0,0
    800031f6:	70a2                	ld	ra,40(sp)
    800031f8:	7402                	ld	s0,32(sp)
    800031fa:	64e2                	ld	s1,24(sp)
    800031fc:	6942                	ld	s2,16(sp)
    800031fe:	6145                	addi	sp,sp,48
    80003200:	8082                	ret

0000000080003202 <sys_top>:
uint64
sys_top(void)
{
    80003202:	1141                	addi	sp,sp,-16
    80003204:	e406                	sd	ra,8(sp)
    80003206:	e022                	sd	s0,0(sp)
    80003208:	0800                	addi	s0,sp,16
    get_top_info();
    8000320a:	fffff097          	auipc	ra,0xfffff
    8000320e:	5ee080e7          	jalr	1518(ra) # 800027f8 <get_top_info>

    return 0;
}
    80003212:	4501                	li	a0,0
    80003214:	60a2                	ld	ra,8(sp)
    80003216:	6402                	ld	s0,0(sp)
    80003218:	0141                	addi	sp,sp,16
    8000321a:	8082                	ret

000000008000321c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000321c:	7179                	addi	sp,sp,-48
    8000321e:	f406                	sd	ra,40(sp)
    80003220:	f022                	sd	s0,32(sp)
    80003222:	ec26                	sd	s1,24(sp)
    80003224:	e84a                	sd	s2,16(sp)
    80003226:	e44e                	sd	s3,8(sp)
    80003228:	e052                	sd	s4,0(sp)
    8000322a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000322c:	00005597          	auipc	a1,0x5
    80003230:	3bc58593          	addi	a1,a1,956 # 800085e8 <syscalls+0xc0>
    80003234:	00015517          	auipc	a0,0x15
    80003238:	84c50513          	addi	a0,a0,-1972 # 80017a80 <bcache>
    8000323c:	ffffe097          	auipc	ra,0xffffe
    80003240:	b4c080e7          	jalr	-1204(ra) # 80000d88 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003244:	0001d797          	auipc	a5,0x1d
    80003248:	83c78793          	addi	a5,a5,-1988 # 8001fa80 <bcache+0x8000>
    8000324c:	0001d717          	auipc	a4,0x1d
    80003250:	a9c70713          	addi	a4,a4,-1380 # 8001fce8 <bcache+0x8268>
    80003254:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003258:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000325c:	00015497          	auipc	s1,0x15
    80003260:	83c48493          	addi	s1,s1,-1988 # 80017a98 <bcache+0x18>
    b->next = bcache.head.next;
    80003264:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003266:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003268:	00005a17          	auipc	s4,0x5
    8000326c:	388a0a13          	addi	s4,s4,904 # 800085f0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003270:	2b893783          	ld	a5,696(s2)
    80003274:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003276:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000327a:	85d2                	mv	a1,s4
    8000327c:	01048513          	addi	a0,s1,16
    80003280:	00001097          	auipc	ra,0x1
    80003284:	4c4080e7          	jalr	1220(ra) # 80004744 <initsleeplock>
    bcache.head.next->prev = b;
    80003288:	2b893783          	ld	a5,696(s2)
    8000328c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000328e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003292:	45848493          	addi	s1,s1,1112
    80003296:	fd349de3          	bne	s1,s3,80003270 <binit+0x54>
  }
}
    8000329a:	70a2                	ld	ra,40(sp)
    8000329c:	7402                	ld	s0,32(sp)
    8000329e:	64e2                	ld	s1,24(sp)
    800032a0:	6942                	ld	s2,16(sp)
    800032a2:	69a2                	ld	s3,8(sp)
    800032a4:	6a02                	ld	s4,0(sp)
    800032a6:	6145                	addi	sp,sp,48
    800032a8:	8082                	ret

00000000800032aa <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032aa:	7179                	addi	sp,sp,-48
    800032ac:	f406                	sd	ra,40(sp)
    800032ae:	f022                	sd	s0,32(sp)
    800032b0:	ec26                	sd	s1,24(sp)
    800032b2:	e84a                	sd	s2,16(sp)
    800032b4:	e44e                	sd	s3,8(sp)
    800032b6:	1800                	addi	s0,sp,48
    800032b8:	892a                	mv	s2,a0
    800032ba:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032bc:	00014517          	auipc	a0,0x14
    800032c0:	7c450513          	addi	a0,a0,1988 # 80017a80 <bcache>
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	b54080e7          	jalr	-1196(ra) # 80000e18 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032cc:	0001d497          	auipc	s1,0x1d
    800032d0:	a6c4b483          	ld	s1,-1428(s1) # 8001fd38 <bcache+0x82b8>
    800032d4:	0001d797          	auipc	a5,0x1d
    800032d8:	a1478793          	addi	a5,a5,-1516 # 8001fce8 <bcache+0x8268>
    800032dc:	02f48f63          	beq	s1,a5,8000331a <bread+0x70>
    800032e0:	873e                	mv	a4,a5
    800032e2:	a021                	j	800032ea <bread+0x40>
    800032e4:	68a4                	ld	s1,80(s1)
    800032e6:	02e48a63          	beq	s1,a4,8000331a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032ea:	449c                	lw	a5,8(s1)
    800032ec:	ff279ce3          	bne	a5,s2,800032e4 <bread+0x3a>
    800032f0:	44dc                	lw	a5,12(s1)
    800032f2:	ff3799e3          	bne	a5,s3,800032e4 <bread+0x3a>
      b->refcnt++;
    800032f6:	40bc                	lw	a5,64(s1)
    800032f8:	2785                	addiw	a5,a5,1
    800032fa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032fc:	00014517          	auipc	a0,0x14
    80003300:	78450513          	addi	a0,a0,1924 # 80017a80 <bcache>
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	bc8080e7          	jalr	-1080(ra) # 80000ecc <release>
      acquiresleep(&b->lock);
    8000330c:	01048513          	addi	a0,s1,16
    80003310:	00001097          	auipc	ra,0x1
    80003314:	46e080e7          	jalr	1134(ra) # 8000477e <acquiresleep>
      return b;
    80003318:	a8b9                	j	80003376 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000331a:	0001d497          	auipc	s1,0x1d
    8000331e:	a164b483          	ld	s1,-1514(s1) # 8001fd30 <bcache+0x82b0>
    80003322:	0001d797          	auipc	a5,0x1d
    80003326:	9c678793          	addi	a5,a5,-1594 # 8001fce8 <bcache+0x8268>
    8000332a:	00f48863          	beq	s1,a5,8000333a <bread+0x90>
    8000332e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003330:	40bc                	lw	a5,64(s1)
    80003332:	cf81                	beqz	a5,8000334a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003334:	64a4                	ld	s1,72(s1)
    80003336:	fee49de3          	bne	s1,a4,80003330 <bread+0x86>
  panic("bget: no buffers");
    8000333a:	00005517          	auipc	a0,0x5
    8000333e:	2be50513          	addi	a0,a0,702 # 800085f8 <syscalls+0xd0>
    80003342:	ffffd097          	auipc	ra,0xffffd
    80003346:	43e080e7          	jalr	1086(ra) # 80000780 <panic>
      b->dev = dev;
    8000334a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000334e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003352:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003356:	4785                	li	a5,1
    80003358:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000335a:	00014517          	auipc	a0,0x14
    8000335e:	72650513          	addi	a0,a0,1830 # 80017a80 <bcache>
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	b6a080e7          	jalr	-1174(ra) # 80000ecc <release>
      acquiresleep(&b->lock);
    8000336a:	01048513          	addi	a0,s1,16
    8000336e:	00001097          	auipc	ra,0x1
    80003372:	410080e7          	jalr	1040(ra) # 8000477e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003376:	409c                	lw	a5,0(s1)
    80003378:	cb89                	beqz	a5,8000338a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000337a:	8526                	mv	a0,s1
    8000337c:	70a2                	ld	ra,40(sp)
    8000337e:	7402                	ld	s0,32(sp)
    80003380:	64e2                	ld	s1,24(sp)
    80003382:	6942                	ld	s2,16(sp)
    80003384:	69a2                	ld	s3,8(sp)
    80003386:	6145                	addi	sp,sp,48
    80003388:	8082                	ret
    virtio_disk_rw(b, 0);
    8000338a:	4581                	li	a1,0
    8000338c:	8526                	mv	a0,s1
    8000338e:	00003097          	auipc	ra,0x3
    80003392:	fd6080e7          	jalr	-42(ra) # 80006364 <virtio_disk_rw>
    b->valid = 1;
    80003396:	4785                	li	a5,1
    80003398:	c09c                	sw	a5,0(s1)
  return b;
    8000339a:	b7c5                	j	8000337a <bread+0xd0>

000000008000339c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000339c:	1101                	addi	sp,sp,-32
    8000339e:	ec06                	sd	ra,24(sp)
    800033a0:	e822                	sd	s0,16(sp)
    800033a2:	e426                	sd	s1,8(sp)
    800033a4:	1000                	addi	s0,sp,32
    800033a6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033a8:	0541                	addi	a0,a0,16
    800033aa:	00001097          	auipc	ra,0x1
    800033ae:	46e080e7          	jalr	1134(ra) # 80004818 <holdingsleep>
    800033b2:	cd01                	beqz	a0,800033ca <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033b4:	4585                	li	a1,1
    800033b6:	8526                	mv	a0,s1
    800033b8:	00003097          	auipc	ra,0x3
    800033bc:	fac080e7          	jalr	-84(ra) # 80006364 <virtio_disk_rw>
}
    800033c0:	60e2                	ld	ra,24(sp)
    800033c2:	6442                	ld	s0,16(sp)
    800033c4:	64a2                	ld	s1,8(sp)
    800033c6:	6105                	addi	sp,sp,32
    800033c8:	8082                	ret
    panic("bwrite");
    800033ca:	00005517          	auipc	a0,0x5
    800033ce:	24650513          	addi	a0,a0,582 # 80008610 <syscalls+0xe8>
    800033d2:	ffffd097          	auipc	ra,0xffffd
    800033d6:	3ae080e7          	jalr	942(ra) # 80000780 <panic>

00000000800033da <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033da:	1101                	addi	sp,sp,-32
    800033dc:	ec06                	sd	ra,24(sp)
    800033de:	e822                	sd	s0,16(sp)
    800033e0:	e426                	sd	s1,8(sp)
    800033e2:	e04a                	sd	s2,0(sp)
    800033e4:	1000                	addi	s0,sp,32
    800033e6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033e8:	01050913          	addi	s2,a0,16
    800033ec:	854a                	mv	a0,s2
    800033ee:	00001097          	auipc	ra,0x1
    800033f2:	42a080e7          	jalr	1066(ra) # 80004818 <holdingsleep>
    800033f6:	c92d                	beqz	a0,80003468 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800033f8:	854a                	mv	a0,s2
    800033fa:	00001097          	auipc	ra,0x1
    800033fe:	3da080e7          	jalr	986(ra) # 800047d4 <releasesleep>

  acquire(&bcache.lock);
    80003402:	00014517          	auipc	a0,0x14
    80003406:	67e50513          	addi	a0,a0,1662 # 80017a80 <bcache>
    8000340a:	ffffe097          	auipc	ra,0xffffe
    8000340e:	a0e080e7          	jalr	-1522(ra) # 80000e18 <acquire>
  b->refcnt--;
    80003412:	40bc                	lw	a5,64(s1)
    80003414:	37fd                	addiw	a5,a5,-1
    80003416:	0007871b          	sext.w	a4,a5
    8000341a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000341c:	eb05                	bnez	a4,8000344c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000341e:	68bc                	ld	a5,80(s1)
    80003420:	64b8                	ld	a4,72(s1)
    80003422:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003424:	64bc                	ld	a5,72(s1)
    80003426:	68b8                	ld	a4,80(s1)
    80003428:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000342a:	0001c797          	auipc	a5,0x1c
    8000342e:	65678793          	addi	a5,a5,1622 # 8001fa80 <bcache+0x8000>
    80003432:	2b87b703          	ld	a4,696(a5)
    80003436:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003438:	0001d717          	auipc	a4,0x1d
    8000343c:	8b070713          	addi	a4,a4,-1872 # 8001fce8 <bcache+0x8268>
    80003440:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003442:	2b87b703          	ld	a4,696(a5)
    80003446:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003448:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000344c:	00014517          	auipc	a0,0x14
    80003450:	63450513          	addi	a0,a0,1588 # 80017a80 <bcache>
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	a78080e7          	jalr	-1416(ra) # 80000ecc <release>
}
    8000345c:	60e2                	ld	ra,24(sp)
    8000345e:	6442                	ld	s0,16(sp)
    80003460:	64a2                	ld	s1,8(sp)
    80003462:	6902                	ld	s2,0(sp)
    80003464:	6105                	addi	sp,sp,32
    80003466:	8082                	ret
    panic("brelse");
    80003468:	00005517          	auipc	a0,0x5
    8000346c:	1b050513          	addi	a0,a0,432 # 80008618 <syscalls+0xf0>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	310080e7          	jalr	784(ra) # 80000780 <panic>

0000000080003478 <bpin>:

void
bpin(struct buf *b) {
    80003478:	1101                	addi	sp,sp,-32
    8000347a:	ec06                	sd	ra,24(sp)
    8000347c:	e822                	sd	s0,16(sp)
    8000347e:	e426                	sd	s1,8(sp)
    80003480:	1000                	addi	s0,sp,32
    80003482:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003484:	00014517          	auipc	a0,0x14
    80003488:	5fc50513          	addi	a0,a0,1532 # 80017a80 <bcache>
    8000348c:	ffffe097          	auipc	ra,0xffffe
    80003490:	98c080e7          	jalr	-1652(ra) # 80000e18 <acquire>
  b->refcnt++;
    80003494:	40bc                	lw	a5,64(s1)
    80003496:	2785                	addiw	a5,a5,1
    80003498:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000349a:	00014517          	auipc	a0,0x14
    8000349e:	5e650513          	addi	a0,a0,1510 # 80017a80 <bcache>
    800034a2:	ffffe097          	auipc	ra,0xffffe
    800034a6:	a2a080e7          	jalr	-1494(ra) # 80000ecc <release>
}
    800034aa:	60e2                	ld	ra,24(sp)
    800034ac:	6442                	ld	s0,16(sp)
    800034ae:	64a2                	ld	s1,8(sp)
    800034b0:	6105                	addi	sp,sp,32
    800034b2:	8082                	ret

00000000800034b4 <bunpin>:

void
bunpin(struct buf *b) {
    800034b4:	1101                	addi	sp,sp,-32
    800034b6:	ec06                	sd	ra,24(sp)
    800034b8:	e822                	sd	s0,16(sp)
    800034ba:	e426                	sd	s1,8(sp)
    800034bc:	1000                	addi	s0,sp,32
    800034be:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034c0:	00014517          	auipc	a0,0x14
    800034c4:	5c050513          	addi	a0,a0,1472 # 80017a80 <bcache>
    800034c8:	ffffe097          	auipc	ra,0xffffe
    800034cc:	950080e7          	jalr	-1712(ra) # 80000e18 <acquire>
  b->refcnt--;
    800034d0:	40bc                	lw	a5,64(s1)
    800034d2:	37fd                	addiw	a5,a5,-1
    800034d4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034d6:	00014517          	auipc	a0,0x14
    800034da:	5aa50513          	addi	a0,a0,1450 # 80017a80 <bcache>
    800034de:	ffffe097          	auipc	ra,0xffffe
    800034e2:	9ee080e7          	jalr	-1554(ra) # 80000ecc <release>
}
    800034e6:	60e2                	ld	ra,24(sp)
    800034e8:	6442                	ld	s0,16(sp)
    800034ea:	64a2                	ld	s1,8(sp)
    800034ec:	6105                	addi	sp,sp,32
    800034ee:	8082                	ret

00000000800034f0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034f0:	1101                	addi	sp,sp,-32
    800034f2:	ec06                	sd	ra,24(sp)
    800034f4:	e822                	sd	s0,16(sp)
    800034f6:	e426                	sd	s1,8(sp)
    800034f8:	e04a                	sd	s2,0(sp)
    800034fa:	1000                	addi	s0,sp,32
    800034fc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034fe:	00d5d59b          	srliw	a1,a1,0xd
    80003502:	0001d797          	auipc	a5,0x1d
    80003506:	c5a7a783          	lw	a5,-934(a5) # 8002015c <sb+0x1c>
    8000350a:	9dbd                	addw	a1,a1,a5
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	d9e080e7          	jalr	-610(ra) # 800032aa <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003514:	0074f713          	andi	a4,s1,7
    80003518:	4785                	li	a5,1
    8000351a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000351e:	14ce                	slli	s1,s1,0x33
    80003520:	90d9                	srli	s1,s1,0x36
    80003522:	00950733          	add	a4,a0,s1
    80003526:	05874703          	lbu	a4,88(a4)
    8000352a:	00e7f6b3          	and	a3,a5,a4
    8000352e:	c69d                	beqz	a3,8000355c <bfree+0x6c>
    80003530:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003532:	94aa                	add	s1,s1,a0
    80003534:	fff7c793          	not	a5,a5
    80003538:	8ff9                	and	a5,a5,a4
    8000353a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000353e:	00001097          	auipc	ra,0x1
    80003542:	120080e7          	jalr	288(ra) # 8000465e <log_write>
  brelse(bp);
    80003546:	854a                	mv	a0,s2
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	e92080e7          	jalr	-366(ra) # 800033da <brelse>
}
    80003550:	60e2                	ld	ra,24(sp)
    80003552:	6442                	ld	s0,16(sp)
    80003554:	64a2                	ld	s1,8(sp)
    80003556:	6902                	ld	s2,0(sp)
    80003558:	6105                	addi	sp,sp,32
    8000355a:	8082                	ret
    panic("freeing free block");
    8000355c:	00005517          	auipc	a0,0x5
    80003560:	0c450513          	addi	a0,a0,196 # 80008620 <syscalls+0xf8>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	21c080e7          	jalr	540(ra) # 80000780 <panic>

000000008000356c <balloc>:
{
    8000356c:	711d                	addi	sp,sp,-96
    8000356e:	ec86                	sd	ra,88(sp)
    80003570:	e8a2                	sd	s0,80(sp)
    80003572:	e4a6                	sd	s1,72(sp)
    80003574:	e0ca                	sd	s2,64(sp)
    80003576:	fc4e                	sd	s3,56(sp)
    80003578:	f852                	sd	s4,48(sp)
    8000357a:	f456                	sd	s5,40(sp)
    8000357c:	f05a                	sd	s6,32(sp)
    8000357e:	ec5e                	sd	s7,24(sp)
    80003580:	e862                	sd	s8,16(sp)
    80003582:	e466                	sd	s9,8(sp)
    80003584:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003586:	0001d797          	auipc	a5,0x1d
    8000358a:	bbe7a783          	lw	a5,-1090(a5) # 80020144 <sb+0x4>
    8000358e:	10078163          	beqz	a5,80003690 <balloc+0x124>
    80003592:	8baa                	mv	s7,a0
    80003594:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003596:	0001db17          	auipc	s6,0x1d
    8000359a:	baab0b13          	addi	s6,s6,-1110 # 80020140 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000359e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035a0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035a2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035a4:	6c89                	lui	s9,0x2
    800035a6:	a061                	j	8000362e <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035a8:	974a                	add	a4,a4,s2
    800035aa:	8fd5                	or	a5,a5,a3
    800035ac:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800035b0:	854a                	mv	a0,s2
    800035b2:	00001097          	auipc	ra,0x1
    800035b6:	0ac080e7          	jalr	172(ra) # 8000465e <log_write>
        brelse(bp);
    800035ba:	854a                	mv	a0,s2
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	e1e080e7          	jalr	-482(ra) # 800033da <brelse>
  bp = bread(dev, bno);
    800035c4:	85a6                	mv	a1,s1
    800035c6:	855e                	mv	a0,s7
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	ce2080e7          	jalr	-798(ra) # 800032aa <bread>
    800035d0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035d2:	40000613          	li	a2,1024
    800035d6:	4581                	li	a1,0
    800035d8:	05850513          	addi	a0,a0,88
    800035dc:	ffffe097          	auipc	ra,0xffffe
    800035e0:	938080e7          	jalr	-1736(ra) # 80000f14 <memset>
  log_write(bp);
    800035e4:	854a                	mv	a0,s2
    800035e6:	00001097          	auipc	ra,0x1
    800035ea:	078080e7          	jalr	120(ra) # 8000465e <log_write>
  brelse(bp);
    800035ee:	854a                	mv	a0,s2
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	dea080e7          	jalr	-534(ra) # 800033da <brelse>
}
    800035f8:	8526                	mv	a0,s1
    800035fa:	60e6                	ld	ra,88(sp)
    800035fc:	6446                	ld	s0,80(sp)
    800035fe:	64a6                	ld	s1,72(sp)
    80003600:	6906                	ld	s2,64(sp)
    80003602:	79e2                	ld	s3,56(sp)
    80003604:	7a42                	ld	s4,48(sp)
    80003606:	7aa2                	ld	s5,40(sp)
    80003608:	7b02                	ld	s6,32(sp)
    8000360a:	6be2                	ld	s7,24(sp)
    8000360c:	6c42                	ld	s8,16(sp)
    8000360e:	6ca2                	ld	s9,8(sp)
    80003610:	6125                	addi	sp,sp,96
    80003612:	8082                	ret
    brelse(bp);
    80003614:	854a                	mv	a0,s2
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	dc4080e7          	jalr	-572(ra) # 800033da <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000361e:	015c87bb          	addw	a5,s9,s5
    80003622:	00078a9b          	sext.w	s5,a5
    80003626:	004b2703          	lw	a4,4(s6)
    8000362a:	06eaf363          	bgeu	s5,a4,80003690 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000362e:	41fad79b          	sraiw	a5,s5,0x1f
    80003632:	0137d79b          	srliw	a5,a5,0x13
    80003636:	015787bb          	addw	a5,a5,s5
    8000363a:	40d7d79b          	sraiw	a5,a5,0xd
    8000363e:	01cb2583          	lw	a1,28(s6)
    80003642:	9dbd                	addw	a1,a1,a5
    80003644:	855e                	mv	a0,s7
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	c64080e7          	jalr	-924(ra) # 800032aa <bread>
    8000364e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003650:	004b2503          	lw	a0,4(s6)
    80003654:	000a849b          	sext.w	s1,s5
    80003658:	8662                	mv	a2,s8
    8000365a:	faa4fde3          	bgeu	s1,a0,80003614 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000365e:	41f6579b          	sraiw	a5,a2,0x1f
    80003662:	01d7d69b          	srliw	a3,a5,0x1d
    80003666:	00c6873b          	addw	a4,a3,a2
    8000366a:	00777793          	andi	a5,a4,7
    8000366e:	9f95                	subw	a5,a5,a3
    80003670:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003674:	4037571b          	sraiw	a4,a4,0x3
    80003678:	00e906b3          	add	a3,s2,a4
    8000367c:	0586c683          	lbu	a3,88(a3)
    80003680:	00d7f5b3          	and	a1,a5,a3
    80003684:	d195                	beqz	a1,800035a8 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003686:	2605                	addiw	a2,a2,1
    80003688:	2485                	addiw	s1,s1,1
    8000368a:	fd4618e3          	bne	a2,s4,8000365a <balloc+0xee>
    8000368e:	b759                	j	80003614 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003690:	00005517          	auipc	a0,0x5
    80003694:	fa850513          	addi	a0,a0,-88 # 80008638 <syscalls+0x110>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	132080e7          	jalr	306(ra) # 800007ca <printf>
  return 0;
    800036a0:	4481                	li	s1,0
    800036a2:	bf99                	j	800035f8 <balloc+0x8c>

00000000800036a4 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800036a4:	7179                	addi	sp,sp,-48
    800036a6:	f406                	sd	ra,40(sp)
    800036a8:	f022                	sd	s0,32(sp)
    800036aa:	ec26                	sd	s1,24(sp)
    800036ac:	e84a                	sd	s2,16(sp)
    800036ae:	e44e                	sd	s3,8(sp)
    800036b0:	e052                	sd	s4,0(sp)
    800036b2:	1800                	addi	s0,sp,48
    800036b4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036b6:	47ad                	li	a5,11
    800036b8:	02b7e763          	bltu	a5,a1,800036e6 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800036bc:	02059493          	slli	s1,a1,0x20
    800036c0:	9081                	srli	s1,s1,0x20
    800036c2:	048a                	slli	s1,s1,0x2
    800036c4:	94aa                	add	s1,s1,a0
    800036c6:	0504a903          	lw	s2,80(s1)
    800036ca:	06091e63          	bnez	s2,80003746 <bmap+0xa2>
      addr = balloc(ip->dev);
    800036ce:	4108                	lw	a0,0(a0)
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	e9c080e7          	jalr	-356(ra) # 8000356c <balloc>
    800036d8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800036dc:	06090563          	beqz	s2,80003746 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800036e0:	0524a823          	sw	s2,80(s1)
    800036e4:	a08d                	j	80003746 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800036e6:	ff45849b          	addiw	s1,a1,-12
    800036ea:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036ee:	0ff00793          	li	a5,255
    800036f2:	08e7e563          	bltu	a5,a4,8000377c <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800036f6:	08052903          	lw	s2,128(a0)
    800036fa:	00091d63          	bnez	s2,80003714 <bmap+0x70>
      addr = balloc(ip->dev);
    800036fe:	4108                	lw	a0,0(a0)
    80003700:	00000097          	auipc	ra,0x0
    80003704:	e6c080e7          	jalr	-404(ra) # 8000356c <balloc>
    80003708:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000370c:	02090d63          	beqz	s2,80003746 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003710:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003714:	85ca                	mv	a1,s2
    80003716:	0009a503          	lw	a0,0(s3)
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	b90080e7          	jalr	-1136(ra) # 800032aa <bread>
    80003722:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003724:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003728:	02049593          	slli	a1,s1,0x20
    8000372c:	9181                	srli	a1,a1,0x20
    8000372e:	058a                	slli	a1,a1,0x2
    80003730:	00b784b3          	add	s1,a5,a1
    80003734:	0004a903          	lw	s2,0(s1)
    80003738:	02090063          	beqz	s2,80003758 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000373c:	8552                	mv	a0,s4
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	c9c080e7          	jalr	-868(ra) # 800033da <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003746:	854a                	mv	a0,s2
    80003748:	70a2                	ld	ra,40(sp)
    8000374a:	7402                	ld	s0,32(sp)
    8000374c:	64e2                	ld	s1,24(sp)
    8000374e:	6942                	ld	s2,16(sp)
    80003750:	69a2                	ld	s3,8(sp)
    80003752:	6a02                	ld	s4,0(sp)
    80003754:	6145                	addi	sp,sp,48
    80003756:	8082                	ret
      addr = balloc(ip->dev);
    80003758:	0009a503          	lw	a0,0(s3)
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	e10080e7          	jalr	-496(ra) # 8000356c <balloc>
    80003764:	0005091b          	sext.w	s2,a0
      if(addr){
    80003768:	fc090ae3          	beqz	s2,8000373c <bmap+0x98>
        a[bn] = addr;
    8000376c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003770:	8552                	mv	a0,s4
    80003772:	00001097          	auipc	ra,0x1
    80003776:	eec080e7          	jalr	-276(ra) # 8000465e <log_write>
    8000377a:	b7c9                	j	8000373c <bmap+0x98>
  panic("bmap: out of range");
    8000377c:	00005517          	auipc	a0,0x5
    80003780:	ed450513          	addi	a0,a0,-300 # 80008650 <syscalls+0x128>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	ffc080e7          	jalr	-4(ra) # 80000780 <panic>

000000008000378c <iget>:
{
    8000378c:	7179                	addi	sp,sp,-48
    8000378e:	f406                	sd	ra,40(sp)
    80003790:	f022                	sd	s0,32(sp)
    80003792:	ec26                	sd	s1,24(sp)
    80003794:	e84a                	sd	s2,16(sp)
    80003796:	e44e                	sd	s3,8(sp)
    80003798:	e052                	sd	s4,0(sp)
    8000379a:	1800                	addi	s0,sp,48
    8000379c:	89aa                	mv	s3,a0
    8000379e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037a0:	0001d517          	auipc	a0,0x1d
    800037a4:	9c050513          	addi	a0,a0,-1600 # 80020160 <itable>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	670080e7          	jalr	1648(ra) # 80000e18 <acquire>
  empty = 0;
    800037b0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037b2:	0001d497          	auipc	s1,0x1d
    800037b6:	9c648493          	addi	s1,s1,-1594 # 80020178 <itable+0x18>
    800037ba:	0001e697          	auipc	a3,0x1e
    800037be:	44e68693          	addi	a3,a3,1102 # 80021c08 <log>
    800037c2:	a039                	j	800037d0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037c4:	02090b63          	beqz	s2,800037fa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037c8:	08848493          	addi	s1,s1,136
    800037cc:	02d48a63          	beq	s1,a3,80003800 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037d0:	449c                	lw	a5,8(s1)
    800037d2:	fef059e3          	blez	a5,800037c4 <iget+0x38>
    800037d6:	4098                	lw	a4,0(s1)
    800037d8:	ff3716e3          	bne	a4,s3,800037c4 <iget+0x38>
    800037dc:	40d8                	lw	a4,4(s1)
    800037de:	ff4713e3          	bne	a4,s4,800037c4 <iget+0x38>
      ip->ref++;
    800037e2:	2785                	addiw	a5,a5,1
    800037e4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037e6:	0001d517          	auipc	a0,0x1d
    800037ea:	97a50513          	addi	a0,a0,-1670 # 80020160 <itable>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	6de080e7          	jalr	1758(ra) # 80000ecc <release>
      return ip;
    800037f6:	8926                	mv	s2,s1
    800037f8:	a03d                	j	80003826 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037fa:	f7f9                	bnez	a5,800037c8 <iget+0x3c>
    800037fc:	8926                	mv	s2,s1
    800037fe:	b7e9                	j	800037c8 <iget+0x3c>
  if(empty == 0)
    80003800:	02090c63          	beqz	s2,80003838 <iget+0xac>
  ip->dev = dev;
    80003804:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003808:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000380c:	4785                	li	a5,1
    8000380e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003812:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003816:	0001d517          	auipc	a0,0x1d
    8000381a:	94a50513          	addi	a0,a0,-1718 # 80020160 <itable>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	6ae080e7          	jalr	1710(ra) # 80000ecc <release>
}
    80003826:	854a                	mv	a0,s2
    80003828:	70a2                	ld	ra,40(sp)
    8000382a:	7402                	ld	s0,32(sp)
    8000382c:	64e2                	ld	s1,24(sp)
    8000382e:	6942                	ld	s2,16(sp)
    80003830:	69a2                	ld	s3,8(sp)
    80003832:	6a02                	ld	s4,0(sp)
    80003834:	6145                	addi	sp,sp,48
    80003836:	8082                	ret
    panic("iget: no inodes");
    80003838:	00005517          	auipc	a0,0x5
    8000383c:	e3050513          	addi	a0,a0,-464 # 80008668 <syscalls+0x140>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	f40080e7          	jalr	-192(ra) # 80000780 <panic>

0000000080003848 <fsinit>:
fsinit(int dev) {
    80003848:	7179                	addi	sp,sp,-48
    8000384a:	f406                	sd	ra,40(sp)
    8000384c:	f022                	sd	s0,32(sp)
    8000384e:	ec26                	sd	s1,24(sp)
    80003850:	e84a                	sd	s2,16(sp)
    80003852:	e44e                	sd	s3,8(sp)
    80003854:	1800                	addi	s0,sp,48
    80003856:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003858:	4585                	li	a1,1
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	a50080e7          	jalr	-1456(ra) # 800032aa <bread>
    80003862:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003864:	0001d997          	auipc	s3,0x1d
    80003868:	8dc98993          	addi	s3,s3,-1828 # 80020140 <sb>
    8000386c:	02000613          	li	a2,32
    80003870:	05850593          	addi	a1,a0,88
    80003874:	854e                	mv	a0,s3
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	6fa080e7          	jalr	1786(ra) # 80000f70 <memmove>
  brelse(bp);
    8000387e:	8526                	mv	a0,s1
    80003880:	00000097          	auipc	ra,0x0
    80003884:	b5a080e7          	jalr	-1190(ra) # 800033da <brelse>
  if(sb.magic != FSMAGIC)
    80003888:	0009a703          	lw	a4,0(s3)
    8000388c:	102037b7          	lui	a5,0x10203
    80003890:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003894:	02f71263          	bne	a4,a5,800038b8 <fsinit+0x70>
  initlog(dev, &sb);
    80003898:	0001d597          	auipc	a1,0x1d
    8000389c:	8a858593          	addi	a1,a1,-1880 # 80020140 <sb>
    800038a0:	854a                	mv	a0,s2
    800038a2:	00001097          	auipc	ra,0x1
    800038a6:	b40080e7          	jalr	-1216(ra) # 800043e2 <initlog>
}
    800038aa:	70a2                	ld	ra,40(sp)
    800038ac:	7402                	ld	s0,32(sp)
    800038ae:	64e2                	ld	s1,24(sp)
    800038b0:	6942                	ld	s2,16(sp)
    800038b2:	69a2                	ld	s3,8(sp)
    800038b4:	6145                	addi	sp,sp,48
    800038b6:	8082                	ret
    panic("invalid file system");
    800038b8:	00005517          	auipc	a0,0x5
    800038bc:	dc050513          	addi	a0,a0,-576 # 80008678 <syscalls+0x150>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	ec0080e7          	jalr	-320(ra) # 80000780 <panic>

00000000800038c8 <iinit>:
{
    800038c8:	7179                	addi	sp,sp,-48
    800038ca:	f406                	sd	ra,40(sp)
    800038cc:	f022                	sd	s0,32(sp)
    800038ce:	ec26                	sd	s1,24(sp)
    800038d0:	e84a                	sd	s2,16(sp)
    800038d2:	e44e                	sd	s3,8(sp)
    800038d4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038d6:	00005597          	auipc	a1,0x5
    800038da:	dba58593          	addi	a1,a1,-582 # 80008690 <syscalls+0x168>
    800038de:	0001d517          	auipc	a0,0x1d
    800038e2:	88250513          	addi	a0,a0,-1918 # 80020160 <itable>
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	4a2080e7          	jalr	1186(ra) # 80000d88 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038ee:	0001d497          	auipc	s1,0x1d
    800038f2:	89a48493          	addi	s1,s1,-1894 # 80020188 <itable+0x28>
    800038f6:	0001e997          	auipc	s3,0x1e
    800038fa:	32298993          	addi	s3,s3,802 # 80021c18 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038fe:	00005917          	auipc	s2,0x5
    80003902:	d9a90913          	addi	s2,s2,-614 # 80008698 <syscalls+0x170>
    80003906:	85ca                	mv	a1,s2
    80003908:	8526                	mv	a0,s1
    8000390a:	00001097          	auipc	ra,0x1
    8000390e:	e3a080e7          	jalr	-454(ra) # 80004744 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003912:	08848493          	addi	s1,s1,136
    80003916:	ff3498e3          	bne	s1,s3,80003906 <iinit+0x3e>
}
    8000391a:	70a2                	ld	ra,40(sp)
    8000391c:	7402                	ld	s0,32(sp)
    8000391e:	64e2                	ld	s1,24(sp)
    80003920:	6942                	ld	s2,16(sp)
    80003922:	69a2                	ld	s3,8(sp)
    80003924:	6145                	addi	sp,sp,48
    80003926:	8082                	ret

0000000080003928 <ialloc>:
{
    80003928:	715d                	addi	sp,sp,-80
    8000392a:	e486                	sd	ra,72(sp)
    8000392c:	e0a2                	sd	s0,64(sp)
    8000392e:	fc26                	sd	s1,56(sp)
    80003930:	f84a                	sd	s2,48(sp)
    80003932:	f44e                	sd	s3,40(sp)
    80003934:	f052                	sd	s4,32(sp)
    80003936:	ec56                	sd	s5,24(sp)
    80003938:	e85a                	sd	s6,16(sp)
    8000393a:	e45e                	sd	s7,8(sp)
    8000393c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000393e:	0001d717          	auipc	a4,0x1d
    80003942:	80e72703          	lw	a4,-2034(a4) # 8002014c <sb+0xc>
    80003946:	4785                	li	a5,1
    80003948:	04e7fa63          	bgeu	a5,a4,8000399c <ialloc+0x74>
    8000394c:	8aaa                	mv	s5,a0
    8000394e:	8bae                	mv	s7,a1
    80003950:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003952:	0001ca17          	auipc	s4,0x1c
    80003956:	7eea0a13          	addi	s4,s4,2030 # 80020140 <sb>
    8000395a:	00048b1b          	sext.w	s6,s1
    8000395e:	0044d793          	srli	a5,s1,0x4
    80003962:	018a2583          	lw	a1,24(s4)
    80003966:	9dbd                	addw	a1,a1,a5
    80003968:	8556                	mv	a0,s5
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	940080e7          	jalr	-1728(ra) # 800032aa <bread>
    80003972:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003974:	05850993          	addi	s3,a0,88
    80003978:	00f4f793          	andi	a5,s1,15
    8000397c:	079a                	slli	a5,a5,0x6
    8000397e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003980:	00099783          	lh	a5,0(s3)
    80003984:	c3a1                	beqz	a5,800039c4 <ialloc+0x9c>
    brelse(bp);
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	a54080e7          	jalr	-1452(ra) # 800033da <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000398e:	0485                	addi	s1,s1,1
    80003990:	00ca2703          	lw	a4,12(s4)
    80003994:	0004879b          	sext.w	a5,s1
    80003998:	fce7e1e3          	bltu	a5,a4,8000395a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000399c:	00005517          	auipc	a0,0x5
    800039a0:	d0450513          	addi	a0,a0,-764 # 800086a0 <syscalls+0x178>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	e26080e7          	jalr	-474(ra) # 800007ca <printf>
  return 0;
    800039ac:	4501                	li	a0,0
}
    800039ae:	60a6                	ld	ra,72(sp)
    800039b0:	6406                	ld	s0,64(sp)
    800039b2:	74e2                	ld	s1,56(sp)
    800039b4:	7942                	ld	s2,48(sp)
    800039b6:	79a2                	ld	s3,40(sp)
    800039b8:	7a02                	ld	s4,32(sp)
    800039ba:	6ae2                	ld	s5,24(sp)
    800039bc:	6b42                	ld	s6,16(sp)
    800039be:	6ba2                	ld	s7,8(sp)
    800039c0:	6161                	addi	sp,sp,80
    800039c2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800039c4:	04000613          	li	a2,64
    800039c8:	4581                	li	a1,0
    800039ca:	854e                	mv	a0,s3
    800039cc:	ffffd097          	auipc	ra,0xffffd
    800039d0:	548080e7          	jalr	1352(ra) # 80000f14 <memset>
      dip->type = type;
    800039d4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039d8:	854a                	mv	a0,s2
    800039da:	00001097          	auipc	ra,0x1
    800039de:	c84080e7          	jalr	-892(ra) # 8000465e <log_write>
      brelse(bp);
    800039e2:	854a                	mv	a0,s2
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	9f6080e7          	jalr	-1546(ra) # 800033da <brelse>
      return iget(dev, inum);
    800039ec:	85da                	mv	a1,s6
    800039ee:	8556                	mv	a0,s5
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	d9c080e7          	jalr	-612(ra) # 8000378c <iget>
    800039f8:	bf5d                	j	800039ae <ialloc+0x86>

00000000800039fa <iupdate>:
{
    800039fa:	1101                	addi	sp,sp,-32
    800039fc:	ec06                	sd	ra,24(sp)
    800039fe:	e822                	sd	s0,16(sp)
    80003a00:	e426                	sd	s1,8(sp)
    80003a02:	e04a                	sd	s2,0(sp)
    80003a04:	1000                	addi	s0,sp,32
    80003a06:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a08:	415c                	lw	a5,4(a0)
    80003a0a:	0047d79b          	srliw	a5,a5,0x4
    80003a0e:	0001c597          	auipc	a1,0x1c
    80003a12:	74a5a583          	lw	a1,1866(a1) # 80020158 <sb+0x18>
    80003a16:	9dbd                	addw	a1,a1,a5
    80003a18:	4108                	lw	a0,0(a0)
    80003a1a:	00000097          	auipc	ra,0x0
    80003a1e:	890080e7          	jalr	-1904(ra) # 800032aa <bread>
    80003a22:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a24:	05850793          	addi	a5,a0,88
    80003a28:	40c8                	lw	a0,4(s1)
    80003a2a:	893d                	andi	a0,a0,15
    80003a2c:	051a                	slli	a0,a0,0x6
    80003a2e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a30:	04449703          	lh	a4,68(s1)
    80003a34:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a38:	04649703          	lh	a4,70(s1)
    80003a3c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a40:	04849703          	lh	a4,72(s1)
    80003a44:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a48:	04a49703          	lh	a4,74(s1)
    80003a4c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a50:	44f8                	lw	a4,76(s1)
    80003a52:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a54:	03400613          	li	a2,52
    80003a58:	05048593          	addi	a1,s1,80
    80003a5c:	0531                	addi	a0,a0,12
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	512080e7          	jalr	1298(ra) # 80000f70 <memmove>
  log_write(bp);
    80003a66:	854a                	mv	a0,s2
    80003a68:	00001097          	auipc	ra,0x1
    80003a6c:	bf6080e7          	jalr	-1034(ra) # 8000465e <log_write>
  brelse(bp);
    80003a70:	854a                	mv	a0,s2
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	968080e7          	jalr	-1688(ra) # 800033da <brelse>
}
    80003a7a:	60e2                	ld	ra,24(sp)
    80003a7c:	6442                	ld	s0,16(sp)
    80003a7e:	64a2                	ld	s1,8(sp)
    80003a80:	6902                	ld	s2,0(sp)
    80003a82:	6105                	addi	sp,sp,32
    80003a84:	8082                	ret

0000000080003a86 <idup>:
{
    80003a86:	1101                	addi	sp,sp,-32
    80003a88:	ec06                	sd	ra,24(sp)
    80003a8a:	e822                	sd	s0,16(sp)
    80003a8c:	e426                	sd	s1,8(sp)
    80003a8e:	1000                	addi	s0,sp,32
    80003a90:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a92:	0001c517          	auipc	a0,0x1c
    80003a96:	6ce50513          	addi	a0,a0,1742 # 80020160 <itable>
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	37e080e7          	jalr	894(ra) # 80000e18 <acquire>
  ip->ref++;
    80003aa2:	449c                	lw	a5,8(s1)
    80003aa4:	2785                	addiw	a5,a5,1
    80003aa6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aa8:	0001c517          	auipc	a0,0x1c
    80003aac:	6b850513          	addi	a0,a0,1720 # 80020160 <itable>
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	41c080e7          	jalr	1052(ra) # 80000ecc <release>
}
    80003ab8:	8526                	mv	a0,s1
    80003aba:	60e2                	ld	ra,24(sp)
    80003abc:	6442                	ld	s0,16(sp)
    80003abe:	64a2                	ld	s1,8(sp)
    80003ac0:	6105                	addi	sp,sp,32
    80003ac2:	8082                	ret

0000000080003ac4 <ilock>:
{
    80003ac4:	1101                	addi	sp,sp,-32
    80003ac6:	ec06                	sd	ra,24(sp)
    80003ac8:	e822                	sd	s0,16(sp)
    80003aca:	e426                	sd	s1,8(sp)
    80003acc:	e04a                	sd	s2,0(sp)
    80003ace:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ad0:	c115                	beqz	a0,80003af4 <ilock+0x30>
    80003ad2:	84aa                	mv	s1,a0
    80003ad4:	451c                	lw	a5,8(a0)
    80003ad6:	00f05f63          	blez	a5,80003af4 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ada:	0541                	addi	a0,a0,16
    80003adc:	00001097          	auipc	ra,0x1
    80003ae0:	ca2080e7          	jalr	-862(ra) # 8000477e <acquiresleep>
  if(ip->valid == 0){
    80003ae4:	40bc                	lw	a5,64(s1)
    80003ae6:	cf99                	beqz	a5,80003b04 <ilock+0x40>
}
    80003ae8:	60e2                	ld	ra,24(sp)
    80003aea:	6442                	ld	s0,16(sp)
    80003aec:	64a2                	ld	s1,8(sp)
    80003aee:	6902                	ld	s2,0(sp)
    80003af0:	6105                	addi	sp,sp,32
    80003af2:	8082                	ret
    panic("ilock");
    80003af4:	00005517          	auipc	a0,0x5
    80003af8:	bc450513          	addi	a0,a0,-1084 # 800086b8 <syscalls+0x190>
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	c84080e7          	jalr	-892(ra) # 80000780 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b04:	40dc                	lw	a5,4(s1)
    80003b06:	0047d79b          	srliw	a5,a5,0x4
    80003b0a:	0001c597          	auipc	a1,0x1c
    80003b0e:	64e5a583          	lw	a1,1614(a1) # 80020158 <sb+0x18>
    80003b12:	9dbd                	addw	a1,a1,a5
    80003b14:	4088                	lw	a0,0(s1)
    80003b16:	fffff097          	auipc	ra,0xfffff
    80003b1a:	794080e7          	jalr	1940(ra) # 800032aa <bread>
    80003b1e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b20:	05850593          	addi	a1,a0,88
    80003b24:	40dc                	lw	a5,4(s1)
    80003b26:	8bbd                	andi	a5,a5,15
    80003b28:	079a                	slli	a5,a5,0x6
    80003b2a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b2c:	00059783          	lh	a5,0(a1)
    80003b30:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b34:	00259783          	lh	a5,2(a1)
    80003b38:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b3c:	00459783          	lh	a5,4(a1)
    80003b40:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b44:	00659783          	lh	a5,6(a1)
    80003b48:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b4c:	459c                	lw	a5,8(a1)
    80003b4e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b50:	03400613          	li	a2,52
    80003b54:	05b1                	addi	a1,a1,12
    80003b56:	05048513          	addi	a0,s1,80
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	416080e7          	jalr	1046(ra) # 80000f70 <memmove>
    brelse(bp);
    80003b62:	854a                	mv	a0,s2
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	876080e7          	jalr	-1930(ra) # 800033da <brelse>
    ip->valid = 1;
    80003b6c:	4785                	li	a5,1
    80003b6e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b70:	04449783          	lh	a5,68(s1)
    80003b74:	fbb5                	bnez	a5,80003ae8 <ilock+0x24>
      panic("ilock: no type");
    80003b76:	00005517          	auipc	a0,0x5
    80003b7a:	b4a50513          	addi	a0,a0,-1206 # 800086c0 <syscalls+0x198>
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	c02080e7          	jalr	-1022(ra) # 80000780 <panic>

0000000080003b86 <iunlock>:
{
    80003b86:	1101                	addi	sp,sp,-32
    80003b88:	ec06                	sd	ra,24(sp)
    80003b8a:	e822                	sd	s0,16(sp)
    80003b8c:	e426                	sd	s1,8(sp)
    80003b8e:	e04a                	sd	s2,0(sp)
    80003b90:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b92:	c905                	beqz	a0,80003bc2 <iunlock+0x3c>
    80003b94:	84aa                	mv	s1,a0
    80003b96:	01050913          	addi	s2,a0,16
    80003b9a:	854a                	mv	a0,s2
    80003b9c:	00001097          	auipc	ra,0x1
    80003ba0:	c7c080e7          	jalr	-900(ra) # 80004818 <holdingsleep>
    80003ba4:	cd19                	beqz	a0,80003bc2 <iunlock+0x3c>
    80003ba6:	449c                	lw	a5,8(s1)
    80003ba8:	00f05d63          	blez	a5,80003bc2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bac:	854a                	mv	a0,s2
    80003bae:	00001097          	auipc	ra,0x1
    80003bb2:	c26080e7          	jalr	-986(ra) # 800047d4 <releasesleep>
}
    80003bb6:	60e2                	ld	ra,24(sp)
    80003bb8:	6442                	ld	s0,16(sp)
    80003bba:	64a2                	ld	s1,8(sp)
    80003bbc:	6902                	ld	s2,0(sp)
    80003bbe:	6105                	addi	sp,sp,32
    80003bc0:	8082                	ret
    panic("iunlock");
    80003bc2:	00005517          	auipc	a0,0x5
    80003bc6:	b0e50513          	addi	a0,a0,-1266 # 800086d0 <syscalls+0x1a8>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	bb6080e7          	jalr	-1098(ra) # 80000780 <panic>

0000000080003bd2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bd2:	7179                	addi	sp,sp,-48
    80003bd4:	f406                	sd	ra,40(sp)
    80003bd6:	f022                	sd	s0,32(sp)
    80003bd8:	ec26                	sd	s1,24(sp)
    80003bda:	e84a                	sd	s2,16(sp)
    80003bdc:	e44e                	sd	s3,8(sp)
    80003bde:	e052                	sd	s4,0(sp)
    80003be0:	1800                	addi	s0,sp,48
    80003be2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003be4:	05050493          	addi	s1,a0,80
    80003be8:	08050913          	addi	s2,a0,128
    80003bec:	a021                	j	80003bf4 <itrunc+0x22>
    80003bee:	0491                	addi	s1,s1,4
    80003bf0:	01248d63          	beq	s1,s2,80003c0a <itrunc+0x38>
    if(ip->addrs[i]){
    80003bf4:	408c                	lw	a1,0(s1)
    80003bf6:	dde5                	beqz	a1,80003bee <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003bf8:	0009a503          	lw	a0,0(s3)
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	8f4080e7          	jalr	-1804(ra) # 800034f0 <bfree>
      ip->addrs[i] = 0;
    80003c04:	0004a023          	sw	zero,0(s1)
    80003c08:	b7dd                	j	80003bee <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c0a:	0809a583          	lw	a1,128(s3)
    80003c0e:	e185                	bnez	a1,80003c2e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c10:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c14:	854e                	mv	a0,s3
    80003c16:	00000097          	auipc	ra,0x0
    80003c1a:	de4080e7          	jalr	-540(ra) # 800039fa <iupdate>
}
    80003c1e:	70a2                	ld	ra,40(sp)
    80003c20:	7402                	ld	s0,32(sp)
    80003c22:	64e2                	ld	s1,24(sp)
    80003c24:	6942                	ld	s2,16(sp)
    80003c26:	69a2                	ld	s3,8(sp)
    80003c28:	6a02                	ld	s4,0(sp)
    80003c2a:	6145                	addi	sp,sp,48
    80003c2c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c2e:	0009a503          	lw	a0,0(s3)
    80003c32:	fffff097          	auipc	ra,0xfffff
    80003c36:	678080e7          	jalr	1656(ra) # 800032aa <bread>
    80003c3a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c3c:	05850493          	addi	s1,a0,88
    80003c40:	45850913          	addi	s2,a0,1112
    80003c44:	a021                	j	80003c4c <itrunc+0x7a>
    80003c46:	0491                	addi	s1,s1,4
    80003c48:	01248b63          	beq	s1,s2,80003c5e <itrunc+0x8c>
      if(a[j])
    80003c4c:	408c                	lw	a1,0(s1)
    80003c4e:	dde5                	beqz	a1,80003c46 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c50:	0009a503          	lw	a0,0(s3)
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	89c080e7          	jalr	-1892(ra) # 800034f0 <bfree>
    80003c5c:	b7ed                	j	80003c46 <itrunc+0x74>
    brelse(bp);
    80003c5e:	8552                	mv	a0,s4
    80003c60:	fffff097          	auipc	ra,0xfffff
    80003c64:	77a080e7          	jalr	1914(ra) # 800033da <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c68:	0809a583          	lw	a1,128(s3)
    80003c6c:	0009a503          	lw	a0,0(s3)
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	880080e7          	jalr	-1920(ra) # 800034f0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c78:	0809a023          	sw	zero,128(s3)
    80003c7c:	bf51                	j	80003c10 <itrunc+0x3e>

0000000080003c7e <iput>:
{
    80003c7e:	1101                	addi	sp,sp,-32
    80003c80:	ec06                	sd	ra,24(sp)
    80003c82:	e822                	sd	s0,16(sp)
    80003c84:	e426                	sd	s1,8(sp)
    80003c86:	e04a                	sd	s2,0(sp)
    80003c88:	1000                	addi	s0,sp,32
    80003c8a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c8c:	0001c517          	auipc	a0,0x1c
    80003c90:	4d450513          	addi	a0,a0,1236 # 80020160 <itable>
    80003c94:	ffffd097          	auipc	ra,0xffffd
    80003c98:	184080e7          	jalr	388(ra) # 80000e18 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c9c:	4498                	lw	a4,8(s1)
    80003c9e:	4785                	li	a5,1
    80003ca0:	02f70363          	beq	a4,a5,80003cc6 <iput+0x48>
  ip->ref--;
    80003ca4:	449c                	lw	a5,8(s1)
    80003ca6:	37fd                	addiw	a5,a5,-1
    80003ca8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003caa:	0001c517          	auipc	a0,0x1c
    80003cae:	4b650513          	addi	a0,a0,1206 # 80020160 <itable>
    80003cb2:	ffffd097          	auipc	ra,0xffffd
    80003cb6:	21a080e7          	jalr	538(ra) # 80000ecc <release>
}
    80003cba:	60e2                	ld	ra,24(sp)
    80003cbc:	6442                	ld	s0,16(sp)
    80003cbe:	64a2                	ld	s1,8(sp)
    80003cc0:	6902                	ld	s2,0(sp)
    80003cc2:	6105                	addi	sp,sp,32
    80003cc4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cc6:	40bc                	lw	a5,64(s1)
    80003cc8:	dff1                	beqz	a5,80003ca4 <iput+0x26>
    80003cca:	04a49783          	lh	a5,74(s1)
    80003cce:	fbf9                	bnez	a5,80003ca4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003cd0:	01048913          	addi	s2,s1,16
    80003cd4:	854a                	mv	a0,s2
    80003cd6:	00001097          	auipc	ra,0x1
    80003cda:	aa8080e7          	jalr	-1368(ra) # 8000477e <acquiresleep>
    release(&itable.lock);
    80003cde:	0001c517          	auipc	a0,0x1c
    80003ce2:	48250513          	addi	a0,a0,1154 # 80020160 <itable>
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	1e6080e7          	jalr	486(ra) # 80000ecc <release>
    itrunc(ip);
    80003cee:	8526                	mv	a0,s1
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	ee2080e7          	jalr	-286(ra) # 80003bd2 <itrunc>
    ip->type = 0;
    80003cf8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003cfc:	8526                	mv	a0,s1
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	cfc080e7          	jalr	-772(ra) # 800039fa <iupdate>
    ip->valid = 0;
    80003d06:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d0a:	854a                	mv	a0,s2
    80003d0c:	00001097          	auipc	ra,0x1
    80003d10:	ac8080e7          	jalr	-1336(ra) # 800047d4 <releasesleep>
    acquire(&itable.lock);
    80003d14:	0001c517          	auipc	a0,0x1c
    80003d18:	44c50513          	addi	a0,a0,1100 # 80020160 <itable>
    80003d1c:	ffffd097          	auipc	ra,0xffffd
    80003d20:	0fc080e7          	jalr	252(ra) # 80000e18 <acquire>
    80003d24:	b741                	j	80003ca4 <iput+0x26>

0000000080003d26 <iunlockput>:
{
    80003d26:	1101                	addi	sp,sp,-32
    80003d28:	ec06                	sd	ra,24(sp)
    80003d2a:	e822                	sd	s0,16(sp)
    80003d2c:	e426                	sd	s1,8(sp)
    80003d2e:	1000                	addi	s0,sp,32
    80003d30:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	e54080e7          	jalr	-428(ra) # 80003b86 <iunlock>
  iput(ip);
    80003d3a:	8526                	mv	a0,s1
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	f42080e7          	jalr	-190(ra) # 80003c7e <iput>
}
    80003d44:	60e2                	ld	ra,24(sp)
    80003d46:	6442                	ld	s0,16(sp)
    80003d48:	64a2                	ld	s1,8(sp)
    80003d4a:	6105                	addi	sp,sp,32
    80003d4c:	8082                	ret

0000000080003d4e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d4e:	1141                	addi	sp,sp,-16
    80003d50:	e422                	sd	s0,8(sp)
    80003d52:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d54:	411c                	lw	a5,0(a0)
    80003d56:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d58:	415c                	lw	a5,4(a0)
    80003d5a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d5c:	04451783          	lh	a5,68(a0)
    80003d60:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d64:	04a51783          	lh	a5,74(a0)
    80003d68:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d6c:	04c56783          	lwu	a5,76(a0)
    80003d70:	e99c                	sd	a5,16(a1)
}
    80003d72:	6422                	ld	s0,8(sp)
    80003d74:	0141                	addi	sp,sp,16
    80003d76:	8082                	ret

0000000080003d78 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d78:	457c                	lw	a5,76(a0)
    80003d7a:	0ed7e963          	bltu	a5,a3,80003e6c <readi+0xf4>
{
    80003d7e:	7159                	addi	sp,sp,-112
    80003d80:	f486                	sd	ra,104(sp)
    80003d82:	f0a2                	sd	s0,96(sp)
    80003d84:	eca6                	sd	s1,88(sp)
    80003d86:	e8ca                	sd	s2,80(sp)
    80003d88:	e4ce                	sd	s3,72(sp)
    80003d8a:	e0d2                	sd	s4,64(sp)
    80003d8c:	fc56                	sd	s5,56(sp)
    80003d8e:	f85a                	sd	s6,48(sp)
    80003d90:	f45e                	sd	s7,40(sp)
    80003d92:	f062                	sd	s8,32(sp)
    80003d94:	ec66                	sd	s9,24(sp)
    80003d96:	e86a                	sd	s10,16(sp)
    80003d98:	e46e                	sd	s11,8(sp)
    80003d9a:	1880                	addi	s0,sp,112
    80003d9c:	8b2a                	mv	s6,a0
    80003d9e:	8bae                	mv	s7,a1
    80003da0:	8a32                	mv	s4,a2
    80003da2:	84b6                	mv	s1,a3
    80003da4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003da6:	9f35                	addw	a4,a4,a3
    return 0;
    80003da8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003daa:	0ad76063          	bltu	a4,a3,80003e4a <readi+0xd2>
  if(off + n > ip->size)
    80003dae:	00e7f463          	bgeu	a5,a4,80003db6 <readi+0x3e>
    n = ip->size - off;
    80003db2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003db6:	0a0a8963          	beqz	s5,80003e68 <readi+0xf0>
    80003dba:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dbc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dc0:	5c7d                	li	s8,-1
    80003dc2:	a82d                	j	80003dfc <readi+0x84>
    80003dc4:	020d1d93          	slli	s11,s10,0x20
    80003dc8:	020ddd93          	srli	s11,s11,0x20
    80003dcc:	05890793          	addi	a5,s2,88
    80003dd0:	86ee                	mv	a3,s11
    80003dd2:	963e                	add	a2,a2,a5
    80003dd4:	85d2                	mv	a1,s4
    80003dd6:	855e                	mv	a0,s7
    80003dd8:	fffff097          	auipc	ra,0xfffff
    80003ddc:	8c6080e7          	jalr	-1850(ra) # 8000269e <either_copyout>
    80003de0:	05850d63          	beq	a0,s8,80003e3a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003de4:	854a                	mv	a0,s2
    80003de6:	fffff097          	auipc	ra,0xfffff
    80003dea:	5f4080e7          	jalr	1524(ra) # 800033da <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dee:	013d09bb          	addw	s3,s10,s3
    80003df2:	009d04bb          	addw	s1,s10,s1
    80003df6:	9a6e                	add	s4,s4,s11
    80003df8:	0559f763          	bgeu	s3,s5,80003e46 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003dfc:	00a4d59b          	srliw	a1,s1,0xa
    80003e00:	855a                	mv	a0,s6
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	8a2080e7          	jalr	-1886(ra) # 800036a4 <bmap>
    80003e0a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e0e:	cd85                	beqz	a1,80003e46 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e10:	000b2503          	lw	a0,0(s6)
    80003e14:	fffff097          	auipc	ra,0xfffff
    80003e18:	496080e7          	jalr	1174(ra) # 800032aa <bread>
    80003e1c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e1e:	3ff4f613          	andi	a2,s1,1023
    80003e22:	40cc87bb          	subw	a5,s9,a2
    80003e26:	413a873b          	subw	a4,s5,s3
    80003e2a:	8d3e                	mv	s10,a5
    80003e2c:	2781                	sext.w	a5,a5
    80003e2e:	0007069b          	sext.w	a3,a4
    80003e32:	f8f6f9e3          	bgeu	a3,a5,80003dc4 <readi+0x4c>
    80003e36:	8d3a                	mv	s10,a4
    80003e38:	b771                	j	80003dc4 <readi+0x4c>
      brelse(bp);
    80003e3a:	854a                	mv	a0,s2
    80003e3c:	fffff097          	auipc	ra,0xfffff
    80003e40:	59e080e7          	jalr	1438(ra) # 800033da <brelse>
      tot = -1;
    80003e44:	59fd                	li	s3,-1
  }
  return tot;
    80003e46:	0009851b          	sext.w	a0,s3
}
    80003e4a:	70a6                	ld	ra,104(sp)
    80003e4c:	7406                	ld	s0,96(sp)
    80003e4e:	64e6                	ld	s1,88(sp)
    80003e50:	6946                	ld	s2,80(sp)
    80003e52:	69a6                	ld	s3,72(sp)
    80003e54:	6a06                	ld	s4,64(sp)
    80003e56:	7ae2                	ld	s5,56(sp)
    80003e58:	7b42                	ld	s6,48(sp)
    80003e5a:	7ba2                	ld	s7,40(sp)
    80003e5c:	7c02                	ld	s8,32(sp)
    80003e5e:	6ce2                	ld	s9,24(sp)
    80003e60:	6d42                	ld	s10,16(sp)
    80003e62:	6da2                	ld	s11,8(sp)
    80003e64:	6165                	addi	sp,sp,112
    80003e66:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e68:	89d6                	mv	s3,s5
    80003e6a:	bff1                	j	80003e46 <readi+0xce>
    return 0;
    80003e6c:	4501                	li	a0,0
}
    80003e6e:	8082                	ret

0000000080003e70 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e70:	457c                	lw	a5,76(a0)
    80003e72:	10d7e863          	bltu	a5,a3,80003f82 <writei+0x112>
{
    80003e76:	7159                	addi	sp,sp,-112
    80003e78:	f486                	sd	ra,104(sp)
    80003e7a:	f0a2                	sd	s0,96(sp)
    80003e7c:	eca6                	sd	s1,88(sp)
    80003e7e:	e8ca                	sd	s2,80(sp)
    80003e80:	e4ce                	sd	s3,72(sp)
    80003e82:	e0d2                	sd	s4,64(sp)
    80003e84:	fc56                	sd	s5,56(sp)
    80003e86:	f85a                	sd	s6,48(sp)
    80003e88:	f45e                	sd	s7,40(sp)
    80003e8a:	f062                	sd	s8,32(sp)
    80003e8c:	ec66                	sd	s9,24(sp)
    80003e8e:	e86a                	sd	s10,16(sp)
    80003e90:	e46e                	sd	s11,8(sp)
    80003e92:	1880                	addi	s0,sp,112
    80003e94:	8aaa                	mv	s5,a0
    80003e96:	8bae                	mv	s7,a1
    80003e98:	8a32                	mv	s4,a2
    80003e9a:	8936                	mv	s2,a3
    80003e9c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e9e:	00e687bb          	addw	a5,a3,a4
    80003ea2:	0ed7e263          	bltu	a5,a3,80003f86 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ea6:	00043737          	lui	a4,0x43
    80003eaa:	0ef76063          	bltu	a4,a5,80003f8a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eae:	0c0b0863          	beqz	s6,80003f7e <writei+0x10e>
    80003eb2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eb4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003eb8:	5c7d                	li	s8,-1
    80003eba:	a091                	j	80003efe <writei+0x8e>
    80003ebc:	020d1d93          	slli	s11,s10,0x20
    80003ec0:	020ddd93          	srli	s11,s11,0x20
    80003ec4:	05848793          	addi	a5,s1,88
    80003ec8:	86ee                	mv	a3,s11
    80003eca:	8652                	mv	a2,s4
    80003ecc:	85de                	mv	a1,s7
    80003ece:	953e                	add	a0,a0,a5
    80003ed0:	fffff097          	auipc	ra,0xfffff
    80003ed4:	824080e7          	jalr	-2012(ra) # 800026f4 <either_copyin>
    80003ed8:	07850263          	beq	a0,s8,80003f3c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003edc:	8526                	mv	a0,s1
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	780080e7          	jalr	1920(ra) # 8000465e <log_write>
    brelse(bp);
    80003ee6:	8526                	mv	a0,s1
    80003ee8:	fffff097          	auipc	ra,0xfffff
    80003eec:	4f2080e7          	jalr	1266(ra) # 800033da <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ef0:	013d09bb          	addw	s3,s10,s3
    80003ef4:	012d093b          	addw	s2,s10,s2
    80003ef8:	9a6e                	add	s4,s4,s11
    80003efa:	0569f663          	bgeu	s3,s6,80003f46 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003efe:	00a9559b          	srliw	a1,s2,0xa
    80003f02:	8556                	mv	a0,s5
    80003f04:	fffff097          	auipc	ra,0xfffff
    80003f08:	7a0080e7          	jalr	1952(ra) # 800036a4 <bmap>
    80003f0c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f10:	c99d                	beqz	a1,80003f46 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f12:	000aa503          	lw	a0,0(s5)
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	394080e7          	jalr	916(ra) # 800032aa <bread>
    80003f1e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f20:	3ff97513          	andi	a0,s2,1023
    80003f24:	40ac87bb          	subw	a5,s9,a0
    80003f28:	413b073b          	subw	a4,s6,s3
    80003f2c:	8d3e                	mv	s10,a5
    80003f2e:	2781                	sext.w	a5,a5
    80003f30:	0007069b          	sext.w	a3,a4
    80003f34:	f8f6f4e3          	bgeu	a3,a5,80003ebc <writei+0x4c>
    80003f38:	8d3a                	mv	s10,a4
    80003f3a:	b749                	j	80003ebc <writei+0x4c>
      brelse(bp);
    80003f3c:	8526                	mv	a0,s1
    80003f3e:	fffff097          	auipc	ra,0xfffff
    80003f42:	49c080e7          	jalr	1180(ra) # 800033da <brelse>
  }

  if(off > ip->size)
    80003f46:	04caa783          	lw	a5,76(s5)
    80003f4a:	0127f463          	bgeu	a5,s2,80003f52 <writei+0xe2>
    ip->size = off;
    80003f4e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f52:	8556                	mv	a0,s5
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	aa6080e7          	jalr	-1370(ra) # 800039fa <iupdate>

  return tot;
    80003f5c:	0009851b          	sext.w	a0,s3
}
    80003f60:	70a6                	ld	ra,104(sp)
    80003f62:	7406                	ld	s0,96(sp)
    80003f64:	64e6                	ld	s1,88(sp)
    80003f66:	6946                	ld	s2,80(sp)
    80003f68:	69a6                	ld	s3,72(sp)
    80003f6a:	6a06                	ld	s4,64(sp)
    80003f6c:	7ae2                	ld	s5,56(sp)
    80003f6e:	7b42                	ld	s6,48(sp)
    80003f70:	7ba2                	ld	s7,40(sp)
    80003f72:	7c02                	ld	s8,32(sp)
    80003f74:	6ce2                	ld	s9,24(sp)
    80003f76:	6d42                	ld	s10,16(sp)
    80003f78:	6da2                	ld	s11,8(sp)
    80003f7a:	6165                	addi	sp,sp,112
    80003f7c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f7e:	89da                	mv	s3,s6
    80003f80:	bfc9                	j	80003f52 <writei+0xe2>
    return -1;
    80003f82:	557d                	li	a0,-1
}
    80003f84:	8082                	ret
    return -1;
    80003f86:	557d                	li	a0,-1
    80003f88:	bfe1                	j	80003f60 <writei+0xf0>
    return -1;
    80003f8a:	557d                	li	a0,-1
    80003f8c:	bfd1                	j	80003f60 <writei+0xf0>

0000000080003f8e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f8e:	1141                	addi	sp,sp,-16
    80003f90:	e406                	sd	ra,8(sp)
    80003f92:	e022                	sd	s0,0(sp)
    80003f94:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f96:	4639                	li	a2,14
    80003f98:	ffffd097          	auipc	ra,0xffffd
    80003f9c:	04c080e7          	jalr	76(ra) # 80000fe4 <strncmp>
}
    80003fa0:	60a2                	ld	ra,8(sp)
    80003fa2:	6402                	ld	s0,0(sp)
    80003fa4:	0141                	addi	sp,sp,16
    80003fa6:	8082                	ret

0000000080003fa8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fa8:	7139                	addi	sp,sp,-64
    80003faa:	fc06                	sd	ra,56(sp)
    80003fac:	f822                	sd	s0,48(sp)
    80003fae:	f426                	sd	s1,40(sp)
    80003fb0:	f04a                	sd	s2,32(sp)
    80003fb2:	ec4e                	sd	s3,24(sp)
    80003fb4:	e852                	sd	s4,16(sp)
    80003fb6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fb8:	04451703          	lh	a4,68(a0)
    80003fbc:	4785                	li	a5,1
    80003fbe:	00f71a63          	bne	a4,a5,80003fd2 <dirlookup+0x2a>
    80003fc2:	892a                	mv	s2,a0
    80003fc4:	89ae                	mv	s3,a1
    80003fc6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc8:	457c                	lw	a5,76(a0)
    80003fca:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fcc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fce:	e79d                	bnez	a5,80003ffc <dirlookup+0x54>
    80003fd0:	a8a5                	j	80004048 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fd2:	00004517          	auipc	a0,0x4
    80003fd6:	70650513          	addi	a0,a0,1798 # 800086d8 <syscalls+0x1b0>
    80003fda:	ffffc097          	auipc	ra,0xffffc
    80003fde:	7a6080e7          	jalr	1958(ra) # 80000780 <panic>
      panic("dirlookup read");
    80003fe2:	00004517          	auipc	a0,0x4
    80003fe6:	70e50513          	addi	a0,a0,1806 # 800086f0 <syscalls+0x1c8>
    80003fea:	ffffc097          	auipc	ra,0xffffc
    80003fee:	796080e7          	jalr	1942(ra) # 80000780 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff2:	24c1                	addiw	s1,s1,16
    80003ff4:	04c92783          	lw	a5,76(s2)
    80003ff8:	04f4f763          	bgeu	s1,a5,80004046 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffc:	4741                	li	a4,16
    80003ffe:	86a6                	mv	a3,s1
    80004000:	fc040613          	addi	a2,s0,-64
    80004004:	4581                	li	a1,0
    80004006:	854a                	mv	a0,s2
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	d70080e7          	jalr	-656(ra) # 80003d78 <readi>
    80004010:	47c1                	li	a5,16
    80004012:	fcf518e3          	bne	a0,a5,80003fe2 <dirlookup+0x3a>
    if(de.inum == 0)
    80004016:	fc045783          	lhu	a5,-64(s0)
    8000401a:	dfe1                	beqz	a5,80003ff2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000401c:	fc240593          	addi	a1,s0,-62
    80004020:	854e                	mv	a0,s3
    80004022:	00000097          	auipc	ra,0x0
    80004026:	f6c080e7          	jalr	-148(ra) # 80003f8e <namecmp>
    8000402a:	f561                	bnez	a0,80003ff2 <dirlookup+0x4a>
      if(poff)
    8000402c:	000a0463          	beqz	s4,80004034 <dirlookup+0x8c>
        *poff = off;
    80004030:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004034:	fc045583          	lhu	a1,-64(s0)
    80004038:	00092503          	lw	a0,0(s2)
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	750080e7          	jalr	1872(ra) # 8000378c <iget>
    80004044:	a011                	j	80004048 <dirlookup+0xa0>
  return 0;
    80004046:	4501                	li	a0,0
}
    80004048:	70e2                	ld	ra,56(sp)
    8000404a:	7442                	ld	s0,48(sp)
    8000404c:	74a2                	ld	s1,40(sp)
    8000404e:	7902                	ld	s2,32(sp)
    80004050:	69e2                	ld	s3,24(sp)
    80004052:	6a42                	ld	s4,16(sp)
    80004054:	6121                	addi	sp,sp,64
    80004056:	8082                	ret

0000000080004058 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004058:	711d                	addi	sp,sp,-96
    8000405a:	ec86                	sd	ra,88(sp)
    8000405c:	e8a2                	sd	s0,80(sp)
    8000405e:	e4a6                	sd	s1,72(sp)
    80004060:	e0ca                	sd	s2,64(sp)
    80004062:	fc4e                	sd	s3,56(sp)
    80004064:	f852                	sd	s4,48(sp)
    80004066:	f456                	sd	s5,40(sp)
    80004068:	f05a                	sd	s6,32(sp)
    8000406a:	ec5e                	sd	s7,24(sp)
    8000406c:	e862                	sd	s8,16(sp)
    8000406e:	e466                	sd	s9,8(sp)
    80004070:	1080                	addi	s0,sp,96
    80004072:	84aa                	mv	s1,a0
    80004074:	8aae                	mv	s5,a1
    80004076:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004078:	00054703          	lbu	a4,0(a0)
    8000407c:	02f00793          	li	a5,47
    80004080:	02f70363          	beq	a4,a5,800040a6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004084:	ffffe097          	auipc	ra,0xffffe
    80004088:	b6a080e7          	jalr	-1174(ra) # 80001bee <myproc>
    8000408c:	15053503          	ld	a0,336(a0)
    80004090:	00000097          	auipc	ra,0x0
    80004094:	9f6080e7          	jalr	-1546(ra) # 80003a86 <idup>
    80004098:	89aa                	mv	s3,a0
  while(*path == '/')
    8000409a:	02f00913          	li	s2,47
  len = path - s;
    8000409e:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800040a0:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040a2:	4b85                	li	s7,1
    800040a4:	a865                	j	8000415c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800040a6:	4585                	li	a1,1
    800040a8:	4505                	li	a0,1
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	6e2080e7          	jalr	1762(ra) # 8000378c <iget>
    800040b2:	89aa                	mv	s3,a0
    800040b4:	b7dd                	j	8000409a <namex+0x42>
      iunlockput(ip);
    800040b6:	854e                	mv	a0,s3
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	c6e080e7          	jalr	-914(ra) # 80003d26 <iunlockput>
      return 0;
    800040c0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040c2:	854e                	mv	a0,s3
    800040c4:	60e6                	ld	ra,88(sp)
    800040c6:	6446                	ld	s0,80(sp)
    800040c8:	64a6                	ld	s1,72(sp)
    800040ca:	6906                	ld	s2,64(sp)
    800040cc:	79e2                	ld	s3,56(sp)
    800040ce:	7a42                	ld	s4,48(sp)
    800040d0:	7aa2                	ld	s5,40(sp)
    800040d2:	7b02                	ld	s6,32(sp)
    800040d4:	6be2                	ld	s7,24(sp)
    800040d6:	6c42                	ld	s8,16(sp)
    800040d8:	6ca2                	ld	s9,8(sp)
    800040da:	6125                	addi	sp,sp,96
    800040dc:	8082                	ret
      iunlock(ip);
    800040de:	854e                	mv	a0,s3
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	aa6080e7          	jalr	-1370(ra) # 80003b86 <iunlock>
      return ip;
    800040e8:	bfe9                	j	800040c2 <namex+0x6a>
      iunlockput(ip);
    800040ea:	854e                	mv	a0,s3
    800040ec:	00000097          	auipc	ra,0x0
    800040f0:	c3a080e7          	jalr	-966(ra) # 80003d26 <iunlockput>
      return 0;
    800040f4:	89e6                	mv	s3,s9
    800040f6:	b7f1                	j	800040c2 <namex+0x6a>
  len = path - s;
    800040f8:	40b48633          	sub	a2,s1,a1
    800040fc:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004100:	099c5463          	bge	s8,s9,80004188 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004104:	4639                	li	a2,14
    80004106:	8552                	mv	a0,s4
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	e68080e7          	jalr	-408(ra) # 80000f70 <memmove>
  while(*path == '/')
    80004110:	0004c783          	lbu	a5,0(s1)
    80004114:	01279763          	bne	a5,s2,80004122 <namex+0xca>
    path++;
    80004118:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000411a:	0004c783          	lbu	a5,0(s1)
    8000411e:	ff278de3          	beq	a5,s2,80004118 <namex+0xc0>
    ilock(ip);
    80004122:	854e                	mv	a0,s3
    80004124:	00000097          	auipc	ra,0x0
    80004128:	9a0080e7          	jalr	-1632(ra) # 80003ac4 <ilock>
    if(ip->type != T_DIR){
    8000412c:	04499783          	lh	a5,68(s3)
    80004130:	f97793e3          	bne	a5,s7,800040b6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004134:	000a8563          	beqz	s5,8000413e <namex+0xe6>
    80004138:	0004c783          	lbu	a5,0(s1)
    8000413c:	d3cd                	beqz	a5,800040de <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000413e:	865a                	mv	a2,s6
    80004140:	85d2                	mv	a1,s4
    80004142:	854e                	mv	a0,s3
    80004144:	00000097          	auipc	ra,0x0
    80004148:	e64080e7          	jalr	-412(ra) # 80003fa8 <dirlookup>
    8000414c:	8caa                	mv	s9,a0
    8000414e:	dd51                	beqz	a0,800040ea <namex+0x92>
    iunlockput(ip);
    80004150:	854e                	mv	a0,s3
    80004152:	00000097          	auipc	ra,0x0
    80004156:	bd4080e7          	jalr	-1068(ra) # 80003d26 <iunlockput>
    ip = next;
    8000415a:	89e6                	mv	s3,s9
  while(*path == '/')
    8000415c:	0004c783          	lbu	a5,0(s1)
    80004160:	05279763          	bne	a5,s2,800041ae <namex+0x156>
    path++;
    80004164:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004166:	0004c783          	lbu	a5,0(s1)
    8000416a:	ff278de3          	beq	a5,s2,80004164 <namex+0x10c>
  if(*path == 0)
    8000416e:	c79d                	beqz	a5,8000419c <namex+0x144>
    path++;
    80004170:	85a6                	mv	a1,s1
  len = path - s;
    80004172:	8cda                	mv	s9,s6
    80004174:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004176:	01278963          	beq	a5,s2,80004188 <namex+0x130>
    8000417a:	dfbd                	beqz	a5,800040f8 <namex+0xa0>
    path++;
    8000417c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000417e:	0004c783          	lbu	a5,0(s1)
    80004182:	ff279ce3          	bne	a5,s2,8000417a <namex+0x122>
    80004186:	bf8d                	j	800040f8 <namex+0xa0>
    memmove(name, s, len);
    80004188:	2601                	sext.w	a2,a2
    8000418a:	8552                	mv	a0,s4
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	de4080e7          	jalr	-540(ra) # 80000f70 <memmove>
    name[len] = 0;
    80004194:	9cd2                	add	s9,s9,s4
    80004196:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000419a:	bf9d                	j	80004110 <namex+0xb8>
  if(nameiparent){
    8000419c:	f20a83e3          	beqz	s5,800040c2 <namex+0x6a>
    iput(ip);
    800041a0:	854e                	mv	a0,s3
    800041a2:	00000097          	auipc	ra,0x0
    800041a6:	adc080e7          	jalr	-1316(ra) # 80003c7e <iput>
    return 0;
    800041aa:	4981                	li	s3,0
    800041ac:	bf19                	j	800040c2 <namex+0x6a>
  if(*path == 0)
    800041ae:	d7fd                	beqz	a5,8000419c <namex+0x144>
  while(*path != '/' && *path != 0)
    800041b0:	0004c783          	lbu	a5,0(s1)
    800041b4:	85a6                	mv	a1,s1
    800041b6:	b7d1                	j	8000417a <namex+0x122>

00000000800041b8 <dirlink>:
{
    800041b8:	7139                	addi	sp,sp,-64
    800041ba:	fc06                	sd	ra,56(sp)
    800041bc:	f822                	sd	s0,48(sp)
    800041be:	f426                	sd	s1,40(sp)
    800041c0:	f04a                	sd	s2,32(sp)
    800041c2:	ec4e                	sd	s3,24(sp)
    800041c4:	e852                	sd	s4,16(sp)
    800041c6:	0080                	addi	s0,sp,64
    800041c8:	892a                	mv	s2,a0
    800041ca:	8a2e                	mv	s4,a1
    800041cc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041ce:	4601                	li	a2,0
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	dd8080e7          	jalr	-552(ra) # 80003fa8 <dirlookup>
    800041d8:	e93d                	bnez	a0,8000424e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041da:	04c92483          	lw	s1,76(s2)
    800041de:	c49d                	beqz	s1,8000420c <dirlink+0x54>
    800041e0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041e2:	4741                	li	a4,16
    800041e4:	86a6                	mv	a3,s1
    800041e6:	fc040613          	addi	a2,s0,-64
    800041ea:	4581                	li	a1,0
    800041ec:	854a                	mv	a0,s2
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	b8a080e7          	jalr	-1142(ra) # 80003d78 <readi>
    800041f6:	47c1                	li	a5,16
    800041f8:	06f51163          	bne	a0,a5,8000425a <dirlink+0xa2>
    if(de.inum == 0)
    800041fc:	fc045783          	lhu	a5,-64(s0)
    80004200:	c791                	beqz	a5,8000420c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004202:	24c1                	addiw	s1,s1,16
    80004204:	04c92783          	lw	a5,76(s2)
    80004208:	fcf4ede3          	bltu	s1,a5,800041e2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000420c:	4639                	li	a2,14
    8000420e:	85d2                	mv	a1,s4
    80004210:	fc240513          	addi	a0,s0,-62
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	e0c080e7          	jalr	-500(ra) # 80001020 <strncpy>
  de.inum = inum;
    8000421c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004220:	4741                	li	a4,16
    80004222:	86a6                	mv	a3,s1
    80004224:	fc040613          	addi	a2,s0,-64
    80004228:	4581                	li	a1,0
    8000422a:	854a                	mv	a0,s2
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	c44080e7          	jalr	-956(ra) # 80003e70 <writei>
    80004234:	1541                	addi	a0,a0,-16
    80004236:	00a03533          	snez	a0,a0
    8000423a:	40a00533          	neg	a0,a0
}
    8000423e:	70e2                	ld	ra,56(sp)
    80004240:	7442                	ld	s0,48(sp)
    80004242:	74a2                	ld	s1,40(sp)
    80004244:	7902                	ld	s2,32(sp)
    80004246:	69e2                	ld	s3,24(sp)
    80004248:	6a42                	ld	s4,16(sp)
    8000424a:	6121                	addi	sp,sp,64
    8000424c:	8082                	ret
    iput(ip);
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	a30080e7          	jalr	-1488(ra) # 80003c7e <iput>
    return -1;
    80004256:	557d                	li	a0,-1
    80004258:	b7dd                	j	8000423e <dirlink+0x86>
      panic("dirlink read");
    8000425a:	00004517          	auipc	a0,0x4
    8000425e:	4a650513          	addi	a0,a0,1190 # 80008700 <syscalls+0x1d8>
    80004262:	ffffc097          	auipc	ra,0xffffc
    80004266:	51e080e7          	jalr	1310(ra) # 80000780 <panic>

000000008000426a <namei>:

struct inode*
namei(char *path)
{
    8000426a:	1101                	addi	sp,sp,-32
    8000426c:	ec06                	sd	ra,24(sp)
    8000426e:	e822                	sd	s0,16(sp)
    80004270:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004272:	fe040613          	addi	a2,s0,-32
    80004276:	4581                	li	a1,0
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	de0080e7          	jalr	-544(ra) # 80004058 <namex>
}
    80004280:	60e2                	ld	ra,24(sp)
    80004282:	6442                	ld	s0,16(sp)
    80004284:	6105                	addi	sp,sp,32
    80004286:	8082                	ret

0000000080004288 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004288:	1141                	addi	sp,sp,-16
    8000428a:	e406                	sd	ra,8(sp)
    8000428c:	e022                	sd	s0,0(sp)
    8000428e:	0800                	addi	s0,sp,16
    80004290:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004292:	4585                	li	a1,1
    80004294:	00000097          	auipc	ra,0x0
    80004298:	dc4080e7          	jalr	-572(ra) # 80004058 <namex>
}
    8000429c:	60a2                	ld	ra,8(sp)
    8000429e:	6402                	ld	s0,0(sp)
    800042a0:	0141                	addi	sp,sp,16
    800042a2:	8082                	ret

00000000800042a4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042a4:	1101                	addi	sp,sp,-32
    800042a6:	ec06                	sd	ra,24(sp)
    800042a8:	e822                	sd	s0,16(sp)
    800042aa:	e426                	sd	s1,8(sp)
    800042ac:	e04a                	sd	s2,0(sp)
    800042ae:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042b0:	0001e917          	auipc	s2,0x1e
    800042b4:	95890913          	addi	s2,s2,-1704 # 80021c08 <log>
    800042b8:	01892583          	lw	a1,24(s2)
    800042bc:	02892503          	lw	a0,40(s2)
    800042c0:	fffff097          	auipc	ra,0xfffff
    800042c4:	fea080e7          	jalr	-22(ra) # 800032aa <bread>
    800042c8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042ca:	02c92683          	lw	a3,44(s2)
    800042ce:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042d0:	02d05763          	blez	a3,800042fe <write_head+0x5a>
    800042d4:	0001e797          	auipc	a5,0x1e
    800042d8:	96478793          	addi	a5,a5,-1692 # 80021c38 <log+0x30>
    800042dc:	05c50713          	addi	a4,a0,92
    800042e0:	36fd                	addiw	a3,a3,-1
    800042e2:	1682                	slli	a3,a3,0x20
    800042e4:	9281                	srli	a3,a3,0x20
    800042e6:	068a                	slli	a3,a3,0x2
    800042e8:	0001e617          	auipc	a2,0x1e
    800042ec:	95460613          	addi	a2,a2,-1708 # 80021c3c <log+0x34>
    800042f0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800042f2:	4390                	lw	a2,0(a5)
    800042f4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042f6:	0791                	addi	a5,a5,4
    800042f8:	0711                	addi	a4,a4,4
    800042fa:	fed79ce3          	bne	a5,a3,800042f2 <write_head+0x4e>
  }
  bwrite(buf);
    800042fe:	8526                	mv	a0,s1
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	09c080e7          	jalr	156(ra) # 8000339c <bwrite>
  brelse(buf);
    80004308:	8526                	mv	a0,s1
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	0d0080e7          	jalr	208(ra) # 800033da <brelse>
}
    80004312:	60e2                	ld	ra,24(sp)
    80004314:	6442                	ld	s0,16(sp)
    80004316:	64a2                	ld	s1,8(sp)
    80004318:	6902                	ld	s2,0(sp)
    8000431a:	6105                	addi	sp,sp,32
    8000431c:	8082                	ret

000000008000431e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431e:	0001e797          	auipc	a5,0x1e
    80004322:	9167a783          	lw	a5,-1770(a5) # 80021c34 <log+0x2c>
    80004326:	0af05d63          	blez	a5,800043e0 <install_trans+0xc2>
{
    8000432a:	7139                	addi	sp,sp,-64
    8000432c:	fc06                	sd	ra,56(sp)
    8000432e:	f822                	sd	s0,48(sp)
    80004330:	f426                	sd	s1,40(sp)
    80004332:	f04a                	sd	s2,32(sp)
    80004334:	ec4e                	sd	s3,24(sp)
    80004336:	e852                	sd	s4,16(sp)
    80004338:	e456                	sd	s5,8(sp)
    8000433a:	e05a                	sd	s6,0(sp)
    8000433c:	0080                	addi	s0,sp,64
    8000433e:	8b2a                	mv	s6,a0
    80004340:	0001ea97          	auipc	s5,0x1e
    80004344:	8f8a8a93          	addi	s5,s5,-1800 # 80021c38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004348:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000434a:	0001e997          	auipc	s3,0x1e
    8000434e:	8be98993          	addi	s3,s3,-1858 # 80021c08 <log>
    80004352:	a00d                	j	80004374 <install_trans+0x56>
    brelse(lbuf);
    80004354:	854a                	mv	a0,s2
    80004356:	fffff097          	auipc	ra,0xfffff
    8000435a:	084080e7          	jalr	132(ra) # 800033da <brelse>
    brelse(dbuf);
    8000435e:	8526                	mv	a0,s1
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	07a080e7          	jalr	122(ra) # 800033da <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004368:	2a05                	addiw	s4,s4,1
    8000436a:	0a91                	addi	s5,s5,4
    8000436c:	02c9a783          	lw	a5,44(s3)
    80004370:	04fa5e63          	bge	s4,a5,800043cc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004374:	0189a583          	lw	a1,24(s3)
    80004378:	014585bb          	addw	a1,a1,s4
    8000437c:	2585                	addiw	a1,a1,1
    8000437e:	0289a503          	lw	a0,40(s3)
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	f28080e7          	jalr	-216(ra) # 800032aa <bread>
    8000438a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000438c:	000aa583          	lw	a1,0(s5)
    80004390:	0289a503          	lw	a0,40(s3)
    80004394:	fffff097          	auipc	ra,0xfffff
    80004398:	f16080e7          	jalr	-234(ra) # 800032aa <bread>
    8000439c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000439e:	40000613          	li	a2,1024
    800043a2:	05890593          	addi	a1,s2,88
    800043a6:	05850513          	addi	a0,a0,88
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	bc6080e7          	jalr	-1082(ra) # 80000f70 <memmove>
    bwrite(dbuf);  // write dst to disk
    800043b2:	8526                	mv	a0,s1
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	fe8080e7          	jalr	-24(ra) # 8000339c <bwrite>
    if(recovering == 0)
    800043bc:	f80b1ce3          	bnez	s6,80004354 <install_trans+0x36>
      bunpin(dbuf);
    800043c0:	8526                	mv	a0,s1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	0f2080e7          	jalr	242(ra) # 800034b4 <bunpin>
    800043ca:	b769                	j	80004354 <install_trans+0x36>
}
    800043cc:	70e2                	ld	ra,56(sp)
    800043ce:	7442                	ld	s0,48(sp)
    800043d0:	74a2                	ld	s1,40(sp)
    800043d2:	7902                	ld	s2,32(sp)
    800043d4:	69e2                	ld	s3,24(sp)
    800043d6:	6a42                	ld	s4,16(sp)
    800043d8:	6aa2                	ld	s5,8(sp)
    800043da:	6b02                	ld	s6,0(sp)
    800043dc:	6121                	addi	sp,sp,64
    800043de:	8082                	ret
    800043e0:	8082                	ret

00000000800043e2 <initlog>:
{
    800043e2:	7179                	addi	sp,sp,-48
    800043e4:	f406                	sd	ra,40(sp)
    800043e6:	f022                	sd	s0,32(sp)
    800043e8:	ec26                	sd	s1,24(sp)
    800043ea:	e84a                	sd	s2,16(sp)
    800043ec:	e44e                	sd	s3,8(sp)
    800043ee:	1800                	addi	s0,sp,48
    800043f0:	892a                	mv	s2,a0
    800043f2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800043f4:	0001e497          	auipc	s1,0x1e
    800043f8:	81448493          	addi	s1,s1,-2028 # 80021c08 <log>
    800043fc:	00004597          	auipc	a1,0x4
    80004400:	31458593          	addi	a1,a1,788 # 80008710 <syscalls+0x1e8>
    80004404:	8526                	mv	a0,s1
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	982080e7          	jalr	-1662(ra) # 80000d88 <initlock>
  log.start = sb->logstart;
    8000440e:	0149a583          	lw	a1,20(s3)
    80004412:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004414:	0109a783          	lw	a5,16(s3)
    80004418:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000441a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000441e:	854a                	mv	a0,s2
    80004420:	fffff097          	auipc	ra,0xfffff
    80004424:	e8a080e7          	jalr	-374(ra) # 800032aa <bread>
  log.lh.n = lh->n;
    80004428:	4d34                	lw	a3,88(a0)
    8000442a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000442c:	02d05563          	blez	a3,80004456 <initlog+0x74>
    80004430:	05c50793          	addi	a5,a0,92
    80004434:	0001e717          	auipc	a4,0x1e
    80004438:	80470713          	addi	a4,a4,-2044 # 80021c38 <log+0x30>
    8000443c:	36fd                	addiw	a3,a3,-1
    8000443e:	1682                	slli	a3,a3,0x20
    80004440:	9281                	srli	a3,a3,0x20
    80004442:	068a                	slli	a3,a3,0x2
    80004444:	06050613          	addi	a2,a0,96
    80004448:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000444a:	4390                	lw	a2,0(a5)
    8000444c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000444e:	0791                	addi	a5,a5,4
    80004450:	0711                	addi	a4,a4,4
    80004452:	fed79ce3          	bne	a5,a3,8000444a <initlog+0x68>
  brelse(buf);
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	f84080e7          	jalr	-124(ra) # 800033da <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000445e:	4505                	li	a0,1
    80004460:	00000097          	auipc	ra,0x0
    80004464:	ebe080e7          	jalr	-322(ra) # 8000431e <install_trans>
  log.lh.n = 0;
    80004468:	0001d797          	auipc	a5,0x1d
    8000446c:	7c07a623          	sw	zero,1996(a5) # 80021c34 <log+0x2c>
  write_head(); // clear the log
    80004470:	00000097          	auipc	ra,0x0
    80004474:	e34080e7          	jalr	-460(ra) # 800042a4 <write_head>
}
    80004478:	70a2                	ld	ra,40(sp)
    8000447a:	7402                	ld	s0,32(sp)
    8000447c:	64e2                	ld	s1,24(sp)
    8000447e:	6942                	ld	s2,16(sp)
    80004480:	69a2                	ld	s3,8(sp)
    80004482:	6145                	addi	sp,sp,48
    80004484:	8082                	ret

0000000080004486 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004486:	1101                	addi	sp,sp,-32
    80004488:	ec06                	sd	ra,24(sp)
    8000448a:	e822                	sd	s0,16(sp)
    8000448c:	e426                	sd	s1,8(sp)
    8000448e:	e04a                	sd	s2,0(sp)
    80004490:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004492:	0001d517          	auipc	a0,0x1d
    80004496:	77650513          	addi	a0,a0,1910 # 80021c08 <log>
    8000449a:	ffffd097          	auipc	ra,0xffffd
    8000449e:	97e080e7          	jalr	-1666(ra) # 80000e18 <acquire>
  while(1){
    if(log.committing){
    800044a2:	0001d497          	auipc	s1,0x1d
    800044a6:	76648493          	addi	s1,s1,1894 # 80021c08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044aa:	4979                	li	s2,30
    800044ac:	a039                	j	800044ba <begin_op+0x34>
      sleep(&log, &log.lock);
    800044ae:	85a6                	mv	a1,s1
    800044b0:	8526                	mv	a0,s1
    800044b2:	ffffe097          	auipc	ra,0xffffe
    800044b6:	de4080e7          	jalr	-540(ra) # 80002296 <sleep>
    if(log.committing){
    800044ba:	50dc                	lw	a5,36(s1)
    800044bc:	fbed                	bnez	a5,800044ae <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044be:	509c                	lw	a5,32(s1)
    800044c0:	0017871b          	addiw	a4,a5,1
    800044c4:	0007069b          	sext.w	a3,a4
    800044c8:	0027179b          	slliw	a5,a4,0x2
    800044cc:	9fb9                	addw	a5,a5,a4
    800044ce:	0017979b          	slliw	a5,a5,0x1
    800044d2:	54d8                	lw	a4,44(s1)
    800044d4:	9fb9                	addw	a5,a5,a4
    800044d6:	00f95963          	bge	s2,a5,800044e8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044da:	85a6                	mv	a1,s1
    800044dc:	8526                	mv	a0,s1
    800044de:	ffffe097          	auipc	ra,0xffffe
    800044e2:	db8080e7          	jalr	-584(ra) # 80002296 <sleep>
    800044e6:	bfd1                	j	800044ba <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800044e8:	0001d517          	auipc	a0,0x1d
    800044ec:	72050513          	addi	a0,a0,1824 # 80021c08 <log>
    800044f0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800044f2:	ffffd097          	auipc	ra,0xffffd
    800044f6:	9da080e7          	jalr	-1574(ra) # 80000ecc <release>
      break;
    }
  }
}
    800044fa:	60e2                	ld	ra,24(sp)
    800044fc:	6442                	ld	s0,16(sp)
    800044fe:	64a2                	ld	s1,8(sp)
    80004500:	6902                	ld	s2,0(sp)
    80004502:	6105                	addi	sp,sp,32
    80004504:	8082                	ret

0000000080004506 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004506:	7139                	addi	sp,sp,-64
    80004508:	fc06                	sd	ra,56(sp)
    8000450a:	f822                	sd	s0,48(sp)
    8000450c:	f426                	sd	s1,40(sp)
    8000450e:	f04a                	sd	s2,32(sp)
    80004510:	ec4e                	sd	s3,24(sp)
    80004512:	e852                	sd	s4,16(sp)
    80004514:	e456                	sd	s5,8(sp)
    80004516:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004518:	0001d497          	auipc	s1,0x1d
    8000451c:	6f048493          	addi	s1,s1,1776 # 80021c08 <log>
    80004520:	8526                	mv	a0,s1
    80004522:	ffffd097          	auipc	ra,0xffffd
    80004526:	8f6080e7          	jalr	-1802(ra) # 80000e18 <acquire>
  log.outstanding -= 1;
    8000452a:	509c                	lw	a5,32(s1)
    8000452c:	37fd                	addiw	a5,a5,-1
    8000452e:	0007891b          	sext.w	s2,a5
    80004532:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004534:	50dc                	lw	a5,36(s1)
    80004536:	e7b9                	bnez	a5,80004584 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004538:	04091e63          	bnez	s2,80004594 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000453c:	0001d497          	auipc	s1,0x1d
    80004540:	6cc48493          	addi	s1,s1,1740 # 80021c08 <log>
    80004544:	4785                	li	a5,1
    80004546:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004548:	8526                	mv	a0,s1
    8000454a:	ffffd097          	auipc	ra,0xffffd
    8000454e:	982080e7          	jalr	-1662(ra) # 80000ecc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004552:	54dc                	lw	a5,44(s1)
    80004554:	06f04763          	bgtz	a5,800045c2 <end_op+0xbc>
    acquire(&log.lock);
    80004558:	0001d497          	auipc	s1,0x1d
    8000455c:	6b048493          	addi	s1,s1,1712 # 80021c08 <log>
    80004560:	8526                	mv	a0,s1
    80004562:	ffffd097          	auipc	ra,0xffffd
    80004566:	8b6080e7          	jalr	-1866(ra) # 80000e18 <acquire>
    log.committing = 0;
    8000456a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000456e:	8526                	mv	a0,s1
    80004570:	ffffe097          	auipc	ra,0xffffe
    80004574:	d8a080e7          	jalr	-630(ra) # 800022fa <wakeup>
    release(&log.lock);
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffd097          	auipc	ra,0xffffd
    8000457e:	952080e7          	jalr	-1710(ra) # 80000ecc <release>
}
    80004582:	a03d                	j	800045b0 <end_op+0xaa>
    panic("log.committing");
    80004584:	00004517          	auipc	a0,0x4
    80004588:	19450513          	addi	a0,a0,404 # 80008718 <syscalls+0x1f0>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	1f4080e7          	jalr	500(ra) # 80000780 <panic>
    wakeup(&log);
    80004594:	0001d497          	auipc	s1,0x1d
    80004598:	67448493          	addi	s1,s1,1652 # 80021c08 <log>
    8000459c:	8526                	mv	a0,s1
    8000459e:	ffffe097          	auipc	ra,0xffffe
    800045a2:	d5c080e7          	jalr	-676(ra) # 800022fa <wakeup>
  release(&log.lock);
    800045a6:	8526                	mv	a0,s1
    800045a8:	ffffd097          	auipc	ra,0xffffd
    800045ac:	924080e7          	jalr	-1756(ra) # 80000ecc <release>
}
    800045b0:	70e2                	ld	ra,56(sp)
    800045b2:	7442                	ld	s0,48(sp)
    800045b4:	74a2                	ld	s1,40(sp)
    800045b6:	7902                	ld	s2,32(sp)
    800045b8:	69e2                	ld	s3,24(sp)
    800045ba:	6a42                	ld	s4,16(sp)
    800045bc:	6aa2                	ld	s5,8(sp)
    800045be:	6121                	addi	sp,sp,64
    800045c0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c2:	0001da97          	auipc	s5,0x1d
    800045c6:	676a8a93          	addi	s5,s5,1654 # 80021c38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045ca:	0001da17          	auipc	s4,0x1d
    800045ce:	63ea0a13          	addi	s4,s4,1598 # 80021c08 <log>
    800045d2:	018a2583          	lw	a1,24(s4)
    800045d6:	012585bb          	addw	a1,a1,s2
    800045da:	2585                	addiw	a1,a1,1
    800045dc:	028a2503          	lw	a0,40(s4)
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	cca080e7          	jalr	-822(ra) # 800032aa <bread>
    800045e8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800045ea:	000aa583          	lw	a1,0(s5)
    800045ee:	028a2503          	lw	a0,40(s4)
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	cb8080e7          	jalr	-840(ra) # 800032aa <bread>
    800045fa:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800045fc:	40000613          	li	a2,1024
    80004600:	05850593          	addi	a1,a0,88
    80004604:	05848513          	addi	a0,s1,88
    80004608:	ffffd097          	auipc	ra,0xffffd
    8000460c:	968080e7          	jalr	-1688(ra) # 80000f70 <memmove>
    bwrite(to);  // write the log
    80004610:	8526                	mv	a0,s1
    80004612:	fffff097          	auipc	ra,0xfffff
    80004616:	d8a080e7          	jalr	-630(ra) # 8000339c <bwrite>
    brelse(from);
    8000461a:	854e                	mv	a0,s3
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	dbe080e7          	jalr	-578(ra) # 800033da <brelse>
    brelse(to);
    80004624:	8526                	mv	a0,s1
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	db4080e7          	jalr	-588(ra) # 800033da <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000462e:	2905                	addiw	s2,s2,1
    80004630:	0a91                	addi	s5,s5,4
    80004632:	02ca2783          	lw	a5,44(s4)
    80004636:	f8f94ee3          	blt	s2,a5,800045d2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000463a:	00000097          	auipc	ra,0x0
    8000463e:	c6a080e7          	jalr	-918(ra) # 800042a4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004642:	4501                	li	a0,0
    80004644:	00000097          	auipc	ra,0x0
    80004648:	cda080e7          	jalr	-806(ra) # 8000431e <install_trans>
    log.lh.n = 0;
    8000464c:	0001d797          	auipc	a5,0x1d
    80004650:	5e07a423          	sw	zero,1512(a5) # 80021c34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004654:	00000097          	auipc	ra,0x0
    80004658:	c50080e7          	jalr	-944(ra) # 800042a4 <write_head>
    8000465c:	bdf5                	j	80004558 <end_op+0x52>

000000008000465e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000465e:	1101                	addi	sp,sp,-32
    80004660:	ec06                	sd	ra,24(sp)
    80004662:	e822                	sd	s0,16(sp)
    80004664:	e426                	sd	s1,8(sp)
    80004666:	e04a                	sd	s2,0(sp)
    80004668:	1000                	addi	s0,sp,32
    8000466a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000466c:	0001d917          	auipc	s2,0x1d
    80004670:	59c90913          	addi	s2,s2,1436 # 80021c08 <log>
    80004674:	854a                	mv	a0,s2
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	7a2080e7          	jalr	1954(ra) # 80000e18 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000467e:	02c92603          	lw	a2,44(s2)
    80004682:	47f5                	li	a5,29
    80004684:	06c7c563          	blt	a5,a2,800046ee <log_write+0x90>
    80004688:	0001d797          	auipc	a5,0x1d
    8000468c:	59c7a783          	lw	a5,1436(a5) # 80021c24 <log+0x1c>
    80004690:	37fd                	addiw	a5,a5,-1
    80004692:	04f65e63          	bge	a2,a5,800046ee <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004696:	0001d797          	auipc	a5,0x1d
    8000469a:	5927a783          	lw	a5,1426(a5) # 80021c28 <log+0x20>
    8000469e:	06f05063          	blez	a5,800046fe <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046a2:	4781                	li	a5,0
    800046a4:	06c05563          	blez	a2,8000470e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046a8:	44cc                	lw	a1,12(s1)
    800046aa:	0001d717          	auipc	a4,0x1d
    800046ae:	58e70713          	addi	a4,a4,1422 # 80021c38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046b2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046b4:	4314                	lw	a3,0(a4)
    800046b6:	04b68c63          	beq	a3,a1,8000470e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046ba:	2785                	addiw	a5,a5,1
    800046bc:	0711                	addi	a4,a4,4
    800046be:	fef61be3          	bne	a2,a5,800046b4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046c2:	0621                	addi	a2,a2,8
    800046c4:	060a                	slli	a2,a2,0x2
    800046c6:	0001d797          	auipc	a5,0x1d
    800046ca:	54278793          	addi	a5,a5,1346 # 80021c08 <log>
    800046ce:	963e                	add	a2,a2,a5
    800046d0:	44dc                	lw	a5,12(s1)
    800046d2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046d4:	8526                	mv	a0,s1
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	da2080e7          	jalr	-606(ra) # 80003478 <bpin>
    log.lh.n++;
    800046de:	0001d717          	auipc	a4,0x1d
    800046e2:	52a70713          	addi	a4,a4,1322 # 80021c08 <log>
    800046e6:	575c                	lw	a5,44(a4)
    800046e8:	2785                	addiw	a5,a5,1
    800046ea:	d75c                	sw	a5,44(a4)
    800046ec:	a835                	j	80004728 <log_write+0xca>
    panic("too big a transaction");
    800046ee:	00004517          	auipc	a0,0x4
    800046f2:	03a50513          	addi	a0,a0,58 # 80008728 <syscalls+0x200>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	08a080e7          	jalr	138(ra) # 80000780 <panic>
    panic("log_write outside of trans");
    800046fe:	00004517          	auipc	a0,0x4
    80004702:	04250513          	addi	a0,a0,66 # 80008740 <syscalls+0x218>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	07a080e7          	jalr	122(ra) # 80000780 <panic>
  log.lh.block[i] = b->blockno;
    8000470e:	00878713          	addi	a4,a5,8
    80004712:	00271693          	slli	a3,a4,0x2
    80004716:	0001d717          	auipc	a4,0x1d
    8000471a:	4f270713          	addi	a4,a4,1266 # 80021c08 <log>
    8000471e:	9736                	add	a4,a4,a3
    80004720:	44d4                	lw	a3,12(s1)
    80004722:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004724:	faf608e3          	beq	a2,a5,800046d4 <log_write+0x76>
  }
  release(&log.lock);
    80004728:	0001d517          	auipc	a0,0x1d
    8000472c:	4e050513          	addi	a0,a0,1248 # 80021c08 <log>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	79c080e7          	jalr	1948(ra) # 80000ecc <release>
}
    80004738:	60e2                	ld	ra,24(sp)
    8000473a:	6442                	ld	s0,16(sp)
    8000473c:	64a2                	ld	s1,8(sp)
    8000473e:	6902                	ld	s2,0(sp)
    80004740:	6105                	addi	sp,sp,32
    80004742:	8082                	ret

0000000080004744 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004744:	1101                	addi	sp,sp,-32
    80004746:	ec06                	sd	ra,24(sp)
    80004748:	e822                	sd	s0,16(sp)
    8000474a:	e426                	sd	s1,8(sp)
    8000474c:	e04a                	sd	s2,0(sp)
    8000474e:	1000                	addi	s0,sp,32
    80004750:	84aa                	mv	s1,a0
    80004752:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004754:	00004597          	auipc	a1,0x4
    80004758:	00c58593          	addi	a1,a1,12 # 80008760 <syscalls+0x238>
    8000475c:	0521                	addi	a0,a0,8
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	62a080e7          	jalr	1578(ra) # 80000d88 <initlock>
  lk->name = name;
    80004766:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000476a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000476e:	0204a423          	sw	zero,40(s1)
}
    80004772:	60e2                	ld	ra,24(sp)
    80004774:	6442                	ld	s0,16(sp)
    80004776:	64a2                	ld	s1,8(sp)
    80004778:	6902                	ld	s2,0(sp)
    8000477a:	6105                	addi	sp,sp,32
    8000477c:	8082                	ret

000000008000477e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000477e:	1101                	addi	sp,sp,-32
    80004780:	ec06                	sd	ra,24(sp)
    80004782:	e822                	sd	s0,16(sp)
    80004784:	e426                	sd	s1,8(sp)
    80004786:	e04a                	sd	s2,0(sp)
    80004788:	1000                	addi	s0,sp,32
    8000478a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000478c:	00850913          	addi	s2,a0,8
    80004790:	854a                	mv	a0,s2
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	686080e7          	jalr	1670(ra) # 80000e18 <acquire>
  while (lk->locked) {
    8000479a:	409c                	lw	a5,0(s1)
    8000479c:	cb89                	beqz	a5,800047ae <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000479e:	85ca                	mv	a1,s2
    800047a0:	8526                	mv	a0,s1
    800047a2:	ffffe097          	auipc	ra,0xffffe
    800047a6:	af4080e7          	jalr	-1292(ra) # 80002296 <sleep>
  while (lk->locked) {
    800047aa:	409c                	lw	a5,0(s1)
    800047ac:	fbed                	bnez	a5,8000479e <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047ae:	4785                	li	a5,1
    800047b0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047b2:	ffffd097          	auipc	ra,0xffffd
    800047b6:	43c080e7          	jalr	1084(ra) # 80001bee <myproc>
    800047ba:	591c                	lw	a5,48(a0)
    800047bc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047be:	854a                	mv	a0,s2
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	70c080e7          	jalr	1804(ra) # 80000ecc <release>
}
    800047c8:	60e2                	ld	ra,24(sp)
    800047ca:	6442                	ld	s0,16(sp)
    800047cc:	64a2                	ld	s1,8(sp)
    800047ce:	6902                	ld	s2,0(sp)
    800047d0:	6105                	addi	sp,sp,32
    800047d2:	8082                	ret

00000000800047d4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047d4:	1101                	addi	sp,sp,-32
    800047d6:	ec06                	sd	ra,24(sp)
    800047d8:	e822                	sd	s0,16(sp)
    800047da:	e426                	sd	s1,8(sp)
    800047dc:	e04a                	sd	s2,0(sp)
    800047de:	1000                	addi	s0,sp,32
    800047e0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047e2:	00850913          	addi	s2,a0,8
    800047e6:	854a                	mv	a0,s2
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	630080e7          	jalr	1584(ra) # 80000e18 <acquire>
  lk->locked = 0;
    800047f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047f4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800047f8:	8526                	mv	a0,s1
    800047fa:	ffffe097          	auipc	ra,0xffffe
    800047fe:	b00080e7          	jalr	-1280(ra) # 800022fa <wakeup>
  release(&lk->lk);
    80004802:	854a                	mv	a0,s2
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	6c8080e7          	jalr	1736(ra) # 80000ecc <release>
}
    8000480c:	60e2                	ld	ra,24(sp)
    8000480e:	6442                	ld	s0,16(sp)
    80004810:	64a2                	ld	s1,8(sp)
    80004812:	6902                	ld	s2,0(sp)
    80004814:	6105                	addi	sp,sp,32
    80004816:	8082                	ret

0000000080004818 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004818:	7179                	addi	sp,sp,-48
    8000481a:	f406                	sd	ra,40(sp)
    8000481c:	f022                	sd	s0,32(sp)
    8000481e:	ec26                	sd	s1,24(sp)
    80004820:	e84a                	sd	s2,16(sp)
    80004822:	e44e                	sd	s3,8(sp)
    80004824:	1800                	addi	s0,sp,48
    80004826:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004828:	00850913          	addi	s2,a0,8
    8000482c:	854a                	mv	a0,s2
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	5ea080e7          	jalr	1514(ra) # 80000e18 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004836:	409c                	lw	a5,0(s1)
    80004838:	ef99                	bnez	a5,80004856 <holdingsleep+0x3e>
    8000483a:	4481                	li	s1,0
  release(&lk->lk);
    8000483c:	854a                	mv	a0,s2
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	68e080e7          	jalr	1678(ra) # 80000ecc <release>
  return r;
}
    80004846:	8526                	mv	a0,s1
    80004848:	70a2                	ld	ra,40(sp)
    8000484a:	7402                	ld	s0,32(sp)
    8000484c:	64e2                	ld	s1,24(sp)
    8000484e:	6942                	ld	s2,16(sp)
    80004850:	69a2                	ld	s3,8(sp)
    80004852:	6145                	addi	sp,sp,48
    80004854:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004856:	0284a983          	lw	s3,40(s1)
    8000485a:	ffffd097          	auipc	ra,0xffffd
    8000485e:	394080e7          	jalr	916(ra) # 80001bee <myproc>
    80004862:	5904                	lw	s1,48(a0)
    80004864:	413484b3          	sub	s1,s1,s3
    80004868:	0014b493          	seqz	s1,s1
    8000486c:	bfc1                	j	8000483c <holdingsleep+0x24>

000000008000486e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000486e:	1141                	addi	sp,sp,-16
    80004870:	e406                	sd	ra,8(sp)
    80004872:	e022                	sd	s0,0(sp)
    80004874:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004876:	00004597          	auipc	a1,0x4
    8000487a:	efa58593          	addi	a1,a1,-262 # 80008770 <syscalls+0x248>
    8000487e:	0001d517          	auipc	a0,0x1d
    80004882:	4d250513          	addi	a0,a0,1234 # 80021d50 <ftable>
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	502080e7          	jalr	1282(ra) # 80000d88 <initlock>
}
    8000488e:	60a2                	ld	ra,8(sp)
    80004890:	6402                	ld	s0,0(sp)
    80004892:	0141                	addi	sp,sp,16
    80004894:	8082                	ret

0000000080004896 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004896:	1101                	addi	sp,sp,-32
    80004898:	ec06                	sd	ra,24(sp)
    8000489a:	e822                	sd	s0,16(sp)
    8000489c:	e426                	sd	s1,8(sp)
    8000489e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048a0:	0001d517          	auipc	a0,0x1d
    800048a4:	4b050513          	addi	a0,a0,1200 # 80021d50 <ftable>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	570080e7          	jalr	1392(ra) # 80000e18 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048b0:	0001d497          	auipc	s1,0x1d
    800048b4:	4b848493          	addi	s1,s1,1208 # 80021d68 <ftable+0x18>
    800048b8:	0001e717          	auipc	a4,0x1e
    800048bc:	45070713          	addi	a4,a4,1104 # 80022d08 <disk>
    if(f->ref == 0){
    800048c0:	40dc                	lw	a5,4(s1)
    800048c2:	cf99                	beqz	a5,800048e0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048c4:	02848493          	addi	s1,s1,40
    800048c8:	fee49ce3          	bne	s1,a4,800048c0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048cc:	0001d517          	auipc	a0,0x1d
    800048d0:	48450513          	addi	a0,a0,1156 # 80021d50 <ftable>
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	5f8080e7          	jalr	1528(ra) # 80000ecc <release>
  return 0;
    800048dc:	4481                	li	s1,0
    800048de:	a819                	j	800048f4 <filealloc+0x5e>
      f->ref = 1;
    800048e0:	4785                	li	a5,1
    800048e2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048e4:	0001d517          	auipc	a0,0x1d
    800048e8:	46c50513          	addi	a0,a0,1132 # 80021d50 <ftable>
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	5e0080e7          	jalr	1504(ra) # 80000ecc <release>
}
    800048f4:	8526                	mv	a0,s1
    800048f6:	60e2                	ld	ra,24(sp)
    800048f8:	6442                	ld	s0,16(sp)
    800048fa:	64a2                	ld	s1,8(sp)
    800048fc:	6105                	addi	sp,sp,32
    800048fe:	8082                	ret

0000000080004900 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004900:	1101                	addi	sp,sp,-32
    80004902:	ec06                	sd	ra,24(sp)
    80004904:	e822                	sd	s0,16(sp)
    80004906:	e426                	sd	s1,8(sp)
    80004908:	1000                	addi	s0,sp,32
    8000490a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000490c:	0001d517          	auipc	a0,0x1d
    80004910:	44450513          	addi	a0,a0,1092 # 80021d50 <ftable>
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	504080e7          	jalr	1284(ra) # 80000e18 <acquire>
  if(f->ref < 1)
    8000491c:	40dc                	lw	a5,4(s1)
    8000491e:	02f05263          	blez	a5,80004942 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004922:	2785                	addiw	a5,a5,1
    80004924:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004926:	0001d517          	auipc	a0,0x1d
    8000492a:	42a50513          	addi	a0,a0,1066 # 80021d50 <ftable>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	59e080e7          	jalr	1438(ra) # 80000ecc <release>
  return f;
}
    80004936:	8526                	mv	a0,s1
    80004938:	60e2                	ld	ra,24(sp)
    8000493a:	6442                	ld	s0,16(sp)
    8000493c:	64a2                	ld	s1,8(sp)
    8000493e:	6105                	addi	sp,sp,32
    80004940:	8082                	ret
    panic("filedup");
    80004942:	00004517          	auipc	a0,0x4
    80004946:	e3650513          	addi	a0,a0,-458 # 80008778 <syscalls+0x250>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	e36080e7          	jalr	-458(ra) # 80000780 <panic>

0000000080004952 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004952:	7139                	addi	sp,sp,-64
    80004954:	fc06                	sd	ra,56(sp)
    80004956:	f822                	sd	s0,48(sp)
    80004958:	f426                	sd	s1,40(sp)
    8000495a:	f04a                	sd	s2,32(sp)
    8000495c:	ec4e                	sd	s3,24(sp)
    8000495e:	e852                	sd	s4,16(sp)
    80004960:	e456                	sd	s5,8(sp)
    80004962:	0080                	addi	s0,sp,64
    80004964:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004966:	0001d517          	auipc	a0,0x1d
    8000496a:	3ea50513          	addi	a0,a0,1002 # 80021d50 <ftable>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	4aa080e7          	jalr	1194(ra) # 80000e18 <acquire>
  if(f->ref < 1)
    80004976:	40dc                	lw	a5,4(s1)
    80004978:	06f05163          	blez	a5,800049da <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000497c:	37fd                	addiw	a5,a5,-1
    8000497e:	0007871b          	sext.w	a4,a5
    80004982:	c0dc                	sw	a5,4(s1)
    80004984:	06e04363          	bgtz	a4,800049ea <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004988:	0004a903          	lw	s2,0(s1)
    8000498c:	0094ca83          	lbu	s5,9(s1)
    80004990:	0104ba03          	ld	s4,16(s1)
    80004994:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004998:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000499c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049a0:	0001d517          	auipc	a0,0x1d
    800049a4:	3b050513          	addi	a0,a0,944 # 80021d50 <ftable>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	524080e7          	jalr	1316(ra) # 80000ecc <release>

  if(ff.type == FD_PIPE){
    800049b0:	4785                	li	a5,1
    800049b2:	04f90d63          	beq	s2,a5,80004a0c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049b6:	3979                	addiw	s2,s2,-2
    800049b8:	4785                	li	a5,1
    800049ba:	0527e063          	bltu	a5,s2,800049fa <fileclose+0xa8>
    begin_op();
    800049be:	00000097          	auipc	ra,0x0
    800049c2:	ac8080e7          	jalr	-1336(ra) # 80004486 <begin_op>
    iput(ff.ip);
    800049c6:	854e                	mv	a0,s3
    800049c8:	fffff097          	auipc	ra,0xfffff
    800049cc:	2b6080e7          	jalr	694(ra) # 80003c7e <iput>
    end_op();
    800049d0:	00000097          	auipc	ra,0x0
    800049d4:	b36080e7          	jalr	-1226(ra) # 80004506 <end_op>
    800049d8:	a00d                	j	800049fa <fileclose+0xa8>
    panic("fileclose");
    800049da:	00004517          	auipc	a0,0x4
    800049de:	da650513          	addi	a0,a0,-602 # 80008780 <syscalls+0x258>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	d9e080e7          	jalr	-610(ra) # 80000780 <panic>
    release(&ftable.lock);
    800049ea:	0001d517          	auipc	a0,0x1d
    800049ee:	36650513          	addi	a0,a0,870 # 80021d50 <ftable>
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	4da080e7          	jalr	1242(ra) # 80000ecc <release>
  }
}
    800049fa:	70e2                	ld	ra,56(sp)
    800049fc:	7442                	ld	s0,48(sp)
    800049fe:	74a2                	ld	s1,40(sp)
    80004a00:	7902                	ld	s2,32(sp)
    80004a02:	69e2                	ld	s3,24(sp)
    80004a04:	6a42                	ld	s4,16(sp)
    80004a06:	6aa2                	ld	s5,8(sp)
    80004a08:	6121                	addi	sp,sp,64
    80004a0a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a0c:	85d6                	mv	a1,s5
    80004a0e:	8552                	mv	a0,s4
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	34c080e7          	jalr	844(ra) # 80004d5c <pipeclose>
    80004a18:	b7cd                	j	800049fa <fileclose+0xa8>

0000000080004a1a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a1a:	715d                	addi	sp,sp,-80
    80004a1c:	e486                	sd	ra,72(sp)
    80004a1e:	e0a2                	sd	s0,64(sp)
    80004a20:	fc26                	sd	s1,56(sp)
    80004a22:	f84a                	sd	s2,48(sp)
    80004a24:	f44e                	sd	s3,40(sp)
    80004a26:	0880                	addi	s0,sp,80
    80004a28:	84aa                	mv	s1,a0
    80004a2a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a2c:	ffffd097          	auipc	ra,0xffffd
    80004a30:	1c2080e7          	jalr	450(ra) # 80001bee <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a34:	409c                	lw	a5,0(s1)
    80004a36:	37f9                	addiw	a5,a5,-2
    80004a38:	4705                	li	a4,1
    80004a3a:	04f76763          	bltu	a4,a5,80004a88 <filestat+0x6e>
    80004a3e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a40:	6c88                	ld	a0,24(s1)
    80004a42:	fffff097          	auipc	ra,0xfffff
    80004a46:	082080e7          	jalr	130(ra) # 80003ac4 <ilock>
    stati(f->ip, &st);
    80004a4a:	fb840593          	addi	a1,s0,-72
    80004a4e:	6c88                	ld	a0,24(s1)
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	2fe080e7          	jalr	766(ra) # 80003d4e <stati>
    iunlock(f->ip);
    80004a58:	6c88                	ld	a0,24(s1)
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	12c080e7          	jalr	300(ra) # 80003b86 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a62:	46e1                	li	a3,24
    80004a64:	fb840613          	addi	a2,s0,-72
    80004a68:	85ce                	mv	a1,s3
    80004a6a:	05093503          	ld	a0,80(s2)
    80004a6e:	ffffd097          	auipc	ra,0xffffd
    80004a72:	e3c080e7          	jalr	-452(ra) # 800018aa <copyout>
    80004a76:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a7a:	60a6                	ld	ra,72(sp)
    80004a7c:	6406                	ld	s0,64(sp)
    80004a7e:	74e2                	ld	s1,56(sp)
    80004a80:	7942                	ld	s2,48(sp)
    80004a82:	79a2                	ld	s3,40(sp)
    80004a84:	6161                	addi	sp,sp,80
    80004a86:	8082                	ret
  return -1;
    80004a88:	557d                	li	a0,-1
    80004a8a:	bfc5                	j	80004a7a <filestat+0x60>

0000000080004a8c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a8c:	7179                	addi	sp,sp,-48
    80004a8e:	f406                	sd	ra,40(sp)
    80004a90:	f022                	sd	s0,32(sp)
    80004a92:	ec26                	sd	s1,24(sp)
    80004a94:	e84a                	sd	s2,16(sp)
    80004a96:	e44e                	sd	s3,8(sp)
    80004a98:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a9a:	00854783          	lbu	a5,8(a0)
    80004a9e:	c3d5                	beqz	a5,80004b42 <fileread+0xb6>
    80004aa0:	84aa                	mv	s1,a0
    80004aa2:	89ae                	mv	s3,a1
    80004aa4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004aa6:	411c                	lw	a5,0(a0)
    80004aa8:	4705                	li	a4,1
    80004aaa:	04e78963          	beq	a5,a4,80004afc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aae:	470d                	li	a4,3
    80004ab0:	04e78d63          	beq	a5,a4,80004b0a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ab4:	4709                	li	a4,2
    80004ab6:	06e79e63          	bne	a5,a4,80004b32 <fileread+0xa6>
    ilock(f->ip);
    80004aba:	6d08                	ld	a0,24(a0)
    80004abc:	fffff097          	auipc	ra,0xfffff
    80004ac0:	008080e7          	jalr	8(ra) # 80003ac4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ac4:	874a                	mv	a4,s2
    80004ac6:	5094                	lw	a3,32(s1)
    80004ac8:	864e                	mv	a2,s3
    80004aca:	4585                	li	a1,1
    80004acc:	6c88                	ld	a0,24(s1)
    80004ace:	fffff097          	auipc	ra,0xfffff
    80004ad2:	2aa080e7          	jalr	682(ra) # 80003d78 <readi>
    80004ad6:	892a                	mv	s2,a0
    80004ad8:	00a05563          	blez	a0,80004ae2 <fileread+0x56>
      f->off += r;
    80004adc:	509c                	lw	a5,32(s1)
    80004ade:	9fa9                	addw	a5,a5,a0
    80004ae0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ae2:	6c88                	ld	a0,24(s1)
    80004ae4:	fffff097          	auipc	ra,0xfffff
    80004ae8:	0a2080e7          	jalr	162(ra) # 80003b86 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004aec:	854a                	mv	a0,s2
    80004aee:	70a2                	ld	ra,40(sp)
    80004af0:	7402                	ld	s0,32(sp)
    80004af2:	64e2                	ld	s1,24(sp)
    80004af4:	6942                	ld	s2,16(sp)
    80004af6:	69a2                	ld	s3,8(sp)
    80004af8:	6145                	addi	sp,sp,48
    80004afa:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004afc:	6908                	ld	a0,16(a0)
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	3c6080e7          	jalr	966(ra) # 80004ec4 <piperead>
    80004b06:	892a                	mv	s2,a0
    80004b08:	b7d5                	j	80004aec <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b0a:	02451783          	lh	a5,36(a0)
    80004b0e:	03079693          	slli	a3,a5,0x30
    80004b12:	92c1                	srli	a3,a3,0x30
    80004b14:	4725                	li	a4,9
    80004b16:	02d76863          	bltu	a4,a3,80004b46 <fileread+0xba>
    80004b1a:	0792                	slli	a5,a5,0x4
    80004b1c:	0001d717          	auipc	a4,0x1d
    80004b20:	19470713          	addi	a4,a4,404 # 80021cb0 <devsw>
    80004b24:	97ba                	add	a5,a5,a4
    80004b26:	639c                	ld	a5,0(a5)
    80004b28:	c38d                	beqz	a5,80004b4a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b2a:	4505                	li	a0,1
    80004b2c:	9782                	jalr	a5
    80004b2e:	892a                	mv	s2,a0
    80004b30:	bf75                	j	80004aec <fileread+0x60>
    panic("fileread");
    80004b32:	00004517          	auipc	a0,0x4
    80004b36:	c5e50513          	addi	a0,a0,-930 # 80008790 <syscalls+0x268>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	c46080e7          	jalr	-954(ra) # 80000780 <panic>
    return -1;
    80004b42:	597d                	li	s2,-1
    80004b44:	b765                	j	80004aec <fileread+0x60>
      return -1;
    80004b46:	597d                	li	s2,-1
    80004b48:	b755                	j	80004aec <fileread+0x60>
    80004b4a:	597d                	li	s2,-1
    80004b4c:	b745                	j	80004aec <fileread+0x60>

0000000080004b4e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b4e:	715d                	addi	sp,sp,-80
    80004b50:	e486                	sd	ra,72(sp)
    80004b52:	e0a2                	sd	s0,64(sp)
    80004b54:	fc26                	sd	s1,56(sp)
    80004b56:	f84a                	sd	s2,48(sp)
    80004b58:	f44e                	sd	s3,40(sp)
    80004b5a:	f052                	sd	s4,32(sp)
    80004b5c:	ec56                	sd	s5,24(sp)
    80004b5e:	e85a                	sd	s6,16(sp)
    80004b60:	e45e                	sd	s7,8(sp)
    80004b62:	e062                	sd	s8,0(sp)
    80004b64:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b66:	00954783          	lbu	a5,9(a0)
    80004b6a:	10078663          	beqz	a5,80004c76 <filewrite+0x128>
    80004b6e:	892a                	mv	s2,a0
    80004b70:	8aae                	mv	s5,a1
    80004b72:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b74:	411c                	lw	a5,0(a0)
    80004b76:	4705                	li	a4,1
    80004b78:	02e78263          	beq	a5,a4,80004b9c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b7c:	470d                	li	a4,3
    80004b7e:	02e78663          	beq	a5,a4,80004baa <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b82:	4709                	li	a4,2
    80004b84:	0ee79163          	bne	a5,a4,80004c66 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b88:	0ac05d63          	blez	a2,80004c42 <filewrite+0xf4>
    int i = 0;
    80004b8c:	4981                	li	s3,0
    80004b8e:	6b05                	lui	s6,0x1
    80004b90:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b94:	6b85                	lui	s7,0x1
    80004b96:	c00b8b9b          	addiw	s7,s7,-1024
    80004b9a:	a861                	j	80004c32 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b9c:	6908                	ld	a0,16(a0)
    80004b9e:	00000097          	auipc	ra,0x0
    80004ba2:	22e080e7          	jalr	558(ra) # 80004dcc <pipewrite>
    80004ba6:	8a2a                	mv	s4,a0
    80004ba8:	a045                	j	80004c48 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004baa:	02451783          	lh	a5,36(a0)
    80004bae:	03079693          	slli	a3,a5,0x30
    80004bb2:	92c1                	srli	a3,a3,0x30
    80004bb4:	4725                	li	a4,9
    80004bb6:	0cd76263          	bltu	a4,a3,80004c7a <filewrite+0x12c>
    80004bba:	0792                	slli	a5,a5,0x4
    80004bbc:	0001d717          	auipc	a4,0x1d
    80004bc0:	0f470713          	addi	a4,a4,244 # 80021cb0 <devsw>
    80004bc4:	97ba                	add	a5,a5,a4
    80004bc6:	679c                	ld	a5,8(a5)
    80004bc8:	cbdd                	beqz	a5,80004c7e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004bca:	4505                	li	a0,1
    80004bcc:	9782                	jalr	a5
    80004bce:	8a2a                	mv	s4,a0
    80004bd0:	a8a5                	j	80004c48 <filewrite+0xfa>
    80004bd2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	8b0080e7          	jalr	-1872(ra) # 80004486 <begin_op>
      ilock(f->ip);
    80004bde:	01893503          	ld	a0,24(s2)
    80004be2:	fffff097          	auipc	ra,0xfffff
    80004be6:	ee2080e7          	jalr	-286(ra) # 80003ac4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004bea:	8762                	mv	a4,s8
    80004bec:	02092683          	lw	a3,32(s2)
    80004bf0:	01598633          	add	a2,s3,s5
    80004bf4:	4585                	li	a1,1
    80004bf6:	01893503          	ld	a0,24(s2)
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	276080e7          	jalr	630(ra) # 80003e70 <writei>
    80004c02:	84aa                	mv	s1,a0
    80004c04:	00a05763          	blez	a0,80004c12 <filewrite+0xc4>
        f->off += r;
    80004c08:	02092783          	lw	a5,32(s2)
    80004c0c:	9fa9                	addw	a5,a5,a0
    80004c0e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c12:	01893503          	ld	a0,24(s2)
    80004c16:	fffff097          	auipc	ra,0xfffff
    80004c1a:	f70080e7          	jalr	-144(ra) # 80003b86 <iunlock>
      end_op();
    80004c1e:	00000097          	auipc	ra,0x0
    80004c22:	8e8080e7          	jalr	-1816(ra) # 80004506 <end_op>

      if(r != n1){
    80004c26:	009c1f63          	bne	s8,s1,80004c44 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c2a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c2e:	0149db63          	bge	s3,s4,80004c44 <filewrite+0xf6>
      int n1 = n - i;
    80004c32:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c36:	84be                	mv	s1,a5
    80004c38:	2781                	sext.w	a5,a5
    80004c3a:	f8fb5ce3          	bge	s6,a5,80004bd2 <filewrite+0x84>
    80004c3e:	84de                	mv	s1,s7
    80004c40:	bf49                	j	80004bd2 <filewrite+0x84>
    int i = 0;
    80004c42:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c44:	013a1f63          	bne	s4,s3,80004c62 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c48:	8552                	mv	a0,s4
    80004c4a:	60a6                	ld	ra,72(sp)
    80004c4c:	6406                	ld	s0,64(sp)
    80004c4e:	74e2                	ld	s1,56(sp)
    80004c50:	7942                	ld	s2,48(sp)
    80004c52:	79a2                	ld	s3,40(sp)
    80004c54:	7a02                	ld	s4,32(sp)
    80004c56:	6ae2                	ld	s5,24(sp)
    80004c58:	6b42                	ld	s6,16(sp)
    80004c5a:	6ba2                	ld	s7,8(sp)
    80004c5c:	6c02                	ld	s8,0(sp)
    80004c5e:	6161                	addi	sp,sp,80
    80004c60:	8082                	ret
    ret = (i == n ? n : -1);
    80004c62:	5a7d                	li	s4,-1
    80004c64:	b7d5                	j	80004c48 <filewrite+0xfa>
    panic("filewrite");
    80004c66:	00004517          	auipc	a0,0x4
    80004c6a:	b3a50513          	addi	a0,a0,-1222 # 800087a0 <syscalls+0x278>
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	b12080e7          	jalr	-1262(ra) # 80000780 <panic>
    return -1;
    80004c76:	5a7d                	li	s4,-1
    80004c78:	bfc1                	j	80004c48 <filewrite+0xfa>
      return -1;
    80004c7a:	5a7d                	li	s4,-1
    80004c7c:	b7f1                	j	80004c48 <filewrite+0xfa>
    80004c7e:	5a7d                	li	s4,-1
    80004c80:	b7e1                	j	80004c48 <filewrite+0xfa>

0000000080004c82 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c82:	7179                	addi	sp,sp,-48
    80004c84:	f406                	sd	ra,40(sp)
    80004c86:	f022                	sd	s0,32(sp)
    80004c88:	ec26                	sd	s1,24(sp)
    80004c8a:	e84a                	sd	s2,16(sp)
    80004c8c:	e44e                	sd	s3,8(sp)
    80004c8e:	e052                	sd	s4,0(sp)
    80004c90:	1800                	addi	s0,sp,48
    80004c92:	84aa                	mv	s1,a0
    80004c94:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c96:	0005b023          	sd	zero,0(a1)
    80004c9a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c9e:	00000097          	auipc	ra,0x0
    80004ca2:	bf8080e7          	jalr	-1032(ra) # 80004896 <filealloc>
    80004ca6:	e088                	sd	a0,0(s1)
    80004ca8:	c551                	beqz	a0,80004d34 <pipealloc+0xb2>
    80004caa:	00000097          	auipc	ra,0x0
    80004cae:	bec080e7          	jalr	-1044(ra) # 80004896 <filealloc>
    80004cb2:	00aa3023          	sd	a0,0(s4)
    80004cb6:	c92d                	beqz	a0,80004d28 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	070080e7          	jalr	112(ra) # 80000d28 <kalloc>
    80004cc0:	892a                	mv	s2,a0
    80004cc2:	c125                	beqz	a0,80004d22 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cc4:	4985                	li	s3,1
    80004cc6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004cca:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004cce:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004cd2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004cd6:	00004597          	auipc	a1,0x4
    80004cda:	ada58593          	addi	a1,a1,-1318 # 800087b0 <syscalls+0x288>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	0aa080e7          	jalr	170(ra) # 80000d88 <initlock>
  (*f0)->type = FD_PIPE;
    80004ce6:	609c                	ld	a5,0(s1)
    80004ce8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004cec:	609c                	ld	a5,0(s1)
    80004cee:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004cf2:	609c                	ld	a5,0(s1)
    80004cf4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004cf8:	609c                	ld	a5,0(s1)
    80004cfa:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004cfe:	000a3783          	ld	a5,0(s4)
    80004d02:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d06:	000a3783          	ld	a5,0(s4)
    80004d0a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d0e:	000a3783          	ld	a5,0(s4)
    80004d12:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d16:	000a3783          	ld	a5,0(s4)
    80004d1a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d1e:	4501                	li	a0,0
    80004d20:	a025                	j	80004d48 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d22:	6088                	ld	a0,0(s1)
    80004d24:	e501                	bnez	a0,80004d2c <pipealloc+0xaa>
    80004d26:	a039                	j	80004d34 <pipealloc+0xb2>
    80004d28:	6088                	ld	a0,0(s1)
    80004d2a:	c51d                	beqz	a0,80004d58 <pipealloc+0xd6>
    fileclose(*f0);
    80004d2c:	00000097          	auipc	ra,0x0
    80004d30:	c26080e7          	jalr	-986(ra) # 80004952 <fileclose>
  if(*f1)
    80004d34:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d38:	557d                	li	a0,-1
  if(*f1)
    80004d3a:	c799                	beqz	a5,80004d48 <pipealloc+0xc6>
    fileclose(*f1);
    80004d3c:	853e                	mv	a0,a5
    80004d3e:	00000097          	auipc	ra,0x0
    80004d42:	c14080e7          	jalr	-1004(ra) # 80004952 <fileclose>
  return -1;
    80004d46:	557d                	li	a0,-1
}
    80004d48:	70a2                	ld	ra,40(sp)
    80004d4a:	7402                	ld	s0,32(sp)
    80004d4c:	64e2                	ld	s1,24(sp)
    80004d4e:	6942                	ld	s2,16(sp)
    80004d50:	69a2                	ld	s3,8(sp)
    80004d52:	6a02                	ld	s4,0(sp)
    80004d54:	6145                	addi	sp,sp,48
    80004d56:	8082                	ret
  return -1;
    80004d58:	557d                	li	a0,-1
    80004d5a:	b7fd                	j	80004d48 <pipealloc+0xc6>

0000000080004d5c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d5c:	1101                	addi	sp,sp,-32
    80004d5e:	ec06                	sd	ra,24(sp)
    80004d60:	e822                	sd	s0,16(sp)
    80004d62:	e426                	sd	s1,8(sp)
    80004d64:	e04a                	sd	s2,0(sp)
    80004d66:	1000                	addi	s0,sp,32
    80004d68:	84aa                	mv	s1,a0
    80004d6a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	0ac080e7          	jalr	172(ra) # 80000e18 <acquire>
  if(writable){
    80004d74:	02090d63          	beqz	s2,80004dae <pipeclose+0x52>
    pi->writeopen = 0;
    80004d78:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d7c:	21848513          	addi	a0,s1,536
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	57a080e7          	jalr	1402(ra) # 800022fa <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d88:	2204b783          	ld	a5,544(s1)
    80004d8c:	eb95                	bnez	a5,80004dc0 <pipeclose+0x64>
    release(&pi->lock);
    80004d8e:	8526                	mv	a0,s1
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	13c080e7          	jalr	316(ra) # 80000ecc <release>
    kfree((char*)pi);
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	e92080e7          	jalr	-366(ra) # 80000c2c <kfree>
  } else
    release(&pi->lock);
}
    80004da2:	60e2                	ld	ra,24(sp)
    80004da4:	6442                	ld	s0,16(sp)
    80004da6:	64a2                	ld	s1,8(sp)
    80004da8:	6902                	ld	s2,0(sp)
    80004daa:	6105                	addi	sp,sp,32
    80004dac:	8082                	ret
    pi->readopen = 0;
    80004dae:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004db2:	21c48513          	addi	a0,s1,540
    80004db6:	ffffd097          	auipc	ra,0xffffd
    80004dba:	544080e7          	jalr	1348(ra) # 800022fa <wakeup>
    80004dbe:	b7e9                	j	80004d88 <pipeclose+0x2c>
    release(&pi->lock);
    80004dc0:	8526                	mv	a0,s1
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	10a080e7          	jalr	266(ra) # 80000ecc <release>
}
    80004dca:	bfe1                	j	80004da2 <pipeclose+0x46>

0000000080004dcc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004dcc:	711d                	addi	sp,sp,-96
    80004dce:	ec86                	sd	ra,88(sp)
    80004dd0:	e8a2                	sd	s0,80(sp)
    80004dd2:	e4a6                	sd	s1,72(sp)
    80004dd4:	e0ca                	sd	s2,64(sp)
    80004dd6:	fc4e                	sd	s3,56(sp)
    80004dd8:	f852                	sd	s4,48(sp)
    80004dda:	f456                	sd	s5,40(sp)
    80004ddc:	f05a                	sd	s6,32(sp)
    80004dde:	ec5e                	sd	s7,24(sp)
    80004de0:	e862                	sd	s8,16(sp)
    80004de2:	1080                	addi	s0,sp,96
    80004de4:	84aa                	mv	s1,a0
    80004de6:	8aae                	mv	s5,a1
    80004de8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	e04080e7          	jalr	-508(ra) # 80001bee <myproc>
    80004df2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004df4:	8526                	mv	a0,s1
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	022080e7          	jalr	34(ra) # 80000e18 <acquire>
  while(i < n){
    80004dfe:	0b405663          	blez	s4,80004eaa <pipewrite+0xde>
  int i = 0;
    80004e02:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e04:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e06:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e0a:	21c48b93          	addi	s7,s1,540
    80004e0e:	a089                	j	80004e50 <pipewrite+0x84>
      release(&pi->lock);
    80004e10:	8526                	mv	a0,s1
    80004e12:	ffffc097          	auipc	ra,0xffffc
    80004e16:	0ba080e7          	jalr	186(ra) # 80000ecc <release>
      return -1;
    80004e1a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e1c:	854a                	mv	a0,s2
    80004e1e:	60e6                	ld	ra,88(sp)
    80004e20:	6446                	ld	s0,80(sp)
    80004e22:	64a6                	ld	s1,72(sp)
    80004e24:	6906                	ld	s2,64(sp)
    80004e26:	79e2                	ld	s3,56(sp)
    80004e28:	7a42                	ld	s4,48(sp)
    80004e2a:	7aa2                	ld	s5,40(sp)
    80004e2c:	7b02                	ld	s6,32(sp)
    80004e2e:	6be2                	ld	s7,24(sp)
    80004e30:	6c42                	ld	s8,16(sp)
    80004e32:	6125                	addi	sp,sp,96
    80004e34:	8082                	ret
      wakeup(&pi->nread);
    80004e36:	8562                	mv	a0,s8
    80004e38:	ffffd097          	auipc	ra,0xffffd
    80004e3c:	4c2080e7          	jalr	1218(ra) # 800022fa <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e40:	85a6                	mv	a1,s1
    80004e42:	855e                	mv	a0,s7
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	452080e7          	jalr	1106(ra) # 80002296 <sleep>
  while(i < n){
    80004e4c:	07495063          	bge	s2,s4,80004eac <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004e50:	2204a783          	lw	a5,544(s1)
    80004e54:	dfd5                	beqz	a5,80004e10 <pipewrite+0x44>
    80004e56:	854e                	mv	a0,s3
    80004e58:	ffffd097          	auipc	ra,0xffffd
    80004e5c:	6e6080e7          	jalr	1766(ra) # 8000253e <killed>
    80004e60:	f945                	bnez	a0,80004e10 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e62:	2184a783          	lw	a5,536(s1)
    80004e66:	21c4a703          	lw	a4,540(s1)
    80004e6a:	2007879b          	addiw	a5,a5,512
    80004e6e:	fcf704e3          	beq	a4,a5,80004e36 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e72:	4685                	li	a3,1
    80004e74:	01590633          	add	a2,s2,s5
    80004e78:	faf40593          	addi	a1,s0,-81
    80004e7c:	0509b503          	ld	a0,80(s3)
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	ab6080e7          	jalr	-1354(ra) # 80001936 <copyin>
    80004e88:	03650263          	beq	a0,s6,80004eac <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e8c:	21c4a783          	lw	a5,540(s1)
    80004e90:	0017871b          	addiw	a4,a5,1
    80004e94:	20e4ae23          	sw	a4,540(s1)
    80004e98:	1ff7f793          	andi	a5,a5,511
    80004e9c:	97a6                	add	a5,a5,s1
    80004e9e:	faf44703          	lbu	a4,-81(s0)
    80004ea2:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ea6:	2905                	addiw	s2,s2,1
    80004ea8:	b755                	j	80004e4c <pipewrite+0x80>
  int i = 0;
    80004eaa:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004eac:	21848513          	addi	a0,s1,536
    80004eb0:	ffffd097          	auipc	ra,0xffffd
    80004eb4:	44a080e7          	jalr	1098(ra) # 800022fa <wakeup>
  release(&pi->lock);
    80004eb8:	8526                	mv	a0,s1
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	012080e7          	jalr	18(ra) # 80000ecc <release>
  return i;
    80004ec2:	bfa9                	j	80004e1c <pipewrite+0x50>

0000000080004ec4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ec4:	715d                	addi	sp,sp,-80
    80004ec6:	e486                	sd	ra,72(sp)
    80004ec8:	e0a2                	sd	s0,64(sp)
    80004eca:	fc26                	sd	s1,56(sp)
    80004ecc:	f84a                	sd	s2,48(sp)
    80004ece:	f44e                	sd	s3,40(sp)
    80004ed0:	f052                	sd	s4,32(sp)
    80004ed2:	ec56                	sd	s5,24(sp)
    80004ed4:	e85a                	sd	s6,16(sp)
    80004ed6:	0880                	addi	s0,sp,80
    80004ed8:	84aa                	mv	s1,a0
    80004eda:	892e                	mv	s2,a1
    80004edc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ede:	ffffd097          	auipc	ra,0xffffd
    80004ee2:	d10080e7          	jalr	-752(ra) # 80001bee <myproc>
    80004ee6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ee8:	8526                	mv	a0,s1
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	f2e080e7          	jalr	-210(ra) # 80000e18 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ef2:	2184a703          	lw	a4,536(s1)
    80004ef6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004efa:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004efe:	02f71763          	bne	a4,a5,80004f2c <piperead+0x68>
    80004f02:	2244a783          	lw	a5,548(s1)
    80004f06:	c39d                	beqz	a5,80004f2c <piperead+0x68>
    if(killed(pr)){
    80004f08:	8552                	mv	a0,s4
    80004f0a:	ffffd097          	auipc	ra,0xffffd
    80004f0e:	634080e7          	jalr	1588(ra) # 8000253e <killed>
    80004f12:	e941                	bnez	a0,80004fa2 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f14:	85a6                	mv	a1,s1
    80004f16:	854e                	mv	a0,s3
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	37e080e7          	jalr	894(ra) # 80002296 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f20:	2184a703          	lw	a4,536(s1)
    80004f24:	21c4a783          	lw	a5,540(s1)
    80004f28:	fcf70de3          	beq	a4,a5,80004f02 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f2c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f2e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f30:	05505363          	blez	s5,80004f76 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004f34:	2184a783          	lw	a5,536(s1)
    80004f38:	21c4a703          	lw	a4,540(s1)
    80004f3c:	02f70d63          	beq	a4,a5,80004f76 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f40:	0017871b          	addiw	a4,a5,1
    80004f44:	20e4ac23          	sw	a4,536(s1)
    80004f48:	1ff7f793          	andi	a5,a5,511
    80004f4c:	97a6                	add	a5,a5,s1
    80004f4e:	0187c783          	lbu	a5,24(a5)
    80004f52:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f56:	4685                	li	a3,1
    80004f58:	fbf40613          	addi	a2,s0,-65
    80004f5c:	85ca                	mv	a1,s2
    80004f5e:	050a3503          	ld	a0,80(s4)
    80004f62:	ffffd097          	auipc	ra,0xffffd
    80004f66:	948080e7          	jalr	-1720(ra) # 800018aa <copyout>
    80004f6a:	01650663          	beq	a0,s6,80004f76 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f6e:	2985                	addiw	s3,s3,1
    80004f70:	0905                	addi	s2,s2,1
    80004f72:	fd3a91e3          	bne	s5,s3,80004f34 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f76:	21c48513          	addi	a0,s1,540
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	380080e7          	jalr	896(ra) # 800022fa <wakeup>
  release(&pi->lock);
    80004f82:	8526                	mv	a0,s1
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	f48080e7          	jalr	-184(ra) # 80000ecc <release>
  return i;
}
    80004f8c:	854e                	mv	a0,s3
    80004f8e:	60a6                	ld	ra,72(sp)
    80004f90:	6406                	ld	s0,64(sp)
    80004f92:	74e2                	ld	s1,56(sp)
    80004f94:	7942                	ld	s2,48(sp)
    80004f96:	79a2                	ld	s3,40(sp)
    80004f98:	7a02                	ld	s4,32(sp)
    80004f9a:	6ae2                	ld	s5,24(sp)
    80004f9c:	6b42                	ld	s6,16(sp)
    80004f9e:	6161                	addi	sp,sp,80
    80004fa0:	8082                	ret
      release(&pi->lock);
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	f28080e7          	jalr	-216(ra) # 80000ecc <release>
      return -1;
    80004fac:	59fd                	li	s3,-1
    80004fae:	bff9                	j	80004f8c <piperead+0xc8>

0000000080004fb0 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004fb0:	1141                	addi	sp,sp,-16
    80004fb2:	e422                	sd	s0,8(sp)
    80004fb4:	0800                	addi	s0,sp,16
    80004fb6:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004fb8:	8905                	andi	a0,a0,1
    80004fba:	c111                	beqz	a0,80004fbe <flags2perm+0xe>
      perm = PTE_X;
    80004fbc:	4521                	li	a0,8
    if(flags & 0x2)
    80004fbe:	8b89                	andi	a5,a5,2
    80004fc0:	c399                	beqz	a5,80004fc6 <flags2perm+0x16>
      perm |= PTE_W;
    80004fc2:	00456513          	ori	a0,a0,4
    return perm;
}
    80004fc6:	6422                	ld	s0,8(sp)
    80004fc8:	0141                	addi	sp,sp,16
    80004fca:	8082                	ret

0000000080004fcc <exec>:

int
exec(char *path, char **argv)
{
    80004fcc:	de010113          	addi	sp,sp,-544
    80004fd0:	20113c23          	sd	ra,536(sp)
    80004fd4:	20813823          	sd	s0,528(sp)
    80004fd8:	20913423          	sd	s1,520(sp)
    80004fdc:	21213023          	sd	s2,512(sp)
    80004fe0:	ffce                	sd	s3,504(sp)
    80004fe2:	fbd2                	sd	s4,496(sp)
    80004fe4:	f7d6                	sd	s5,488(sp)
    80004fe6:	f3da                	sd	s6,480(sp)
    80004fe8:	efde                	sd	s7,472(sp)
    80004fea:	ebe2                	sd	s8,464(sp)
    80004fec:	e7e6                	sd	s9,456(sp)
    80004fee:	e3ea                	sd	s10,448(sp)
    80004ff0:	ff6e                	sd	s11,440(sp)
    80004ff2:	1400                	addi	s0,sp,544
    80004ff4:	892a                	mv	s2,a0
    80004ff6:	dea43423          	sd	a0,-536(s0)
    80004ffa:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ffe:	ffffd097          	auipc	ra,0xffffd
    80005002:	bf0080e7          	jalr	-1040(ra) # 80001bee <myproc>
    80005006:	84aa                	mv	s1,a0

  begin_op();
    80005008:	fffff097          	auipc	ra,0xfffff
    8000500c:	47e080e7          	jalr	1150(ra) # 80004486 <begin_op>

  if((ip = namei(path)) == 0){
    80005010:	854a                	mv	a0,s2
    80005012:	fffff097          	auipc	ra,0xfffff
    80005016:	258080e7          	jalr	600(ra) # 8000426a <namei>
    8000501a:	c93d                	beqz	a0,80005090 <exec+0xc4>
    8000501c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000501e:	fffff097          	auipc	ra,0xfffff
    80005022:	aa6080e7          	jalr	-1370(ra) # 80003ac4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005026:	04000713          	li	a4,64
    8000502a:	4681                	li	a3,0
    8000502c:	e5040613          	addi	a2,s0,-432
    80005030:	4581                	li	a1,0
    80005032:	8556                	mv	a0,s5
    80005034:	fffff097          	auipc	ra,0xfffff
    80005038:	d44080e7          	jalr	-700(ra) # 80003d78 <readi>
    8000503c:	04000793          	li	a5,64
    80005040:	00f51a63          	bne	a0,a5,80005054 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005044:	e5042703          	lw	a4,-432(s0)
    80005048:	464c47b7          	lui	a5,0x464c4
    8000504c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005050:	04f70663          	beq	a4,a5,8000509c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005054:	8556                	mv	a0,s5
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	cd0080e7          	jalr	-816(ra) # 80003d26 <iunlockput>
    end_op();
    8000505e:	fffff097          	auipc	ra,0xfffff
    80005062:	4a8080e7          	jalr	1192(ra) # 80004506 <end_op>
  }
  return -1;
    80005066:	557d                	li	a0,-1
}
    80005068:	21813083          	ld	ra,536(sp)
    8000506c:	21013403          	ld	s0,528(sp)
    80005070:	20813483          	ld	s1,520(sp)
    80005074:	20013903          	ld	s2,512(sp)
    80005078:	79fe                	ld	s3,504(sp)
    8000507a:	7a5e                	ld	s4,496(sp)
    8000507c:	7abe                	ld	s5,488(sp)
    8000507e:	7b1e                	ld	s6,480(sp)
    80005080:	6bfe                	ld	s7,472(sp)
    80005082:	6c5e                	ld	s8,464(sp)
    80005084:	6cbe                	ld	s9,456(sp)
    80005086:	6d1e                	ld	s10,448(sp)
    80005088:	7dfa                	ld	s11,440(sp)
    8000508a:	22010113          	addi	sp,sp,544
    8000508e:	8082                	ret
    end_op();
    80005090:	fffff097          	auipc	ra,0xfffff
    80005094:	476080e7          	jalr	1142(ra) # 80004506 <end_op>
    return -1;
    80005098:	557d                	li	a0,-1
    8000509a:	b7f9                	j	80005068 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000509c:	8526                	mv	a0,s1
    8000509e:	ffffd097          	auipc	ra,0xffffd
    800050a2:	c14080e7          	jalr	-1004(ra) # 80001cb2 <proc_pagetable>
    800050a6:	8b2a                	mv	s6,a0
    800050a8:	d555                	beqz	a0,80005054 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050aa:	e7042783          	lw	a5,-400(s0)
    800050ae:	e8845703          	lhu	a4,-376(s0)
    800050b2:	c735                	beqz	a4,8000511e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050b4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050b6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800050ba:	6a05                	lui	s4,0x1
    800050bc:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050c0:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800050c4:	6d85                	lui	s11,0x1
    800050c6:	7d7d                	lui	s10,0xfffff
    800050c8:	a481                	j	80005308 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050ca:	00003517          	auipc	a0,0x3
    800050ce:	6ee50513          	addi	a0,a0,1774 # 800087b8 <syscalls+0x290>
    800050d2:	ffffb097          	auipc	ra,0xffffb
    800050d6:	6ae080e7          	jalr	1710(ra) # 80000780 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050da:	874a                	mv	a4,s2
    800050dc:	009c86bb          	addw	a3,s9,s1
    800050e0:	4581                	li	a1,0
    800050e2:	8556                	mv	a0,s5
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	c94080e7          	jalr	-876(ra) # 80003d78 <readi>
    800050ec:	2501                	sext.w	a0,a0
    800050ee:	1aa91a63          	bne	s2,a0,800052a2 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    800050f2:	009d84bb          	addw	s1,s11,s1
    800050f6:	013d09bb          	addw	s3,s10,s3
    800050fa:	1f74f763          	bgeu	s1,s7,800052e8 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    800050fe:	02049593          	slli	a1,s1,0x20
    80005102:	9181                	srli	a1,a1,0x20
    80005104:	95e2                	add	a1,a1,s8
    80005106:	855a                	mv	a0,s6
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	196080e7          	jalr	406(ra) # 8000129e <walkaddr>
    80005110:	862a                	mv	a2,a0
    if(pa == 0)
    80005112:	dd45                	beqz	a0,800050ca <exec+0xfe>
      n = PGSIZE;
    80005114:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005116:	fd49f2e3          	bgeu	s3,s4,800050da <exec+0x10e>
      n = sz - i;
    8000511a:	894e                	mv	s2,s3
    8000511c:	bf7d                	j	800050da <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000511e:	4901                	li	s2,0
  iunlockput(ip);
    80005120:	8556                	mv	a0,s5
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	c04080e7          	jalr	-1020(ra) # 80003d26 <iunlockput>
  end_op();
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	3dc080e7          	jalr	988(ra) # 80004506 <end_op>
  p = myproc();
    80005132:	ffffd097          	auipc	ra,0xffffd
    80005136:	abc080e7          	jalr	-1348(ra) # 80001bee <myproc>
    8000513a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000513c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005140:	6785                	lui	a5,0x1
    80005142:	17fd                	addi	a5,a5,-1
    80005144:	993e                	add	s2,s2,a5
    80005146:	77fd                	lui	a5,0xfffff
    80005148:	00f977b3          	and	a5,s2,a5
    8000514c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005150:	4691                	li	a3,4
    80005152:	6609                	lui	a2,0x2
    80005154:	963e                	add	a2,a2,a5
    80005156:	85be                	mv	a1,a5
    80005158:	855a                	mv	a0,s6
    8000515a:	ffffc097          	auipc	ra,0xffffc
    8000515e:	4f8080e7          	jalr	1272(ra) # 80001652 <uvmalloc>
    80005162:	8c2a                	mv	s8,a0
  ip = 0;
    80005164:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005166:	12050e63          	beqz	a0,800052a2 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000516a:	75f9                	lui	a1,0xffffe
    8000516c:	95aa                	add	a1,a1,a0
    8000516e:	855a                	mv	a0,s6
    80005170:	ffffc097          	auipc	ra,0xffffc
    80005174:	708080e7          	jalr	1800(ra) # 80001878 <uvmclear>
  stackbase = sp - PGSIZE;
    80005178:	7afd                	lui	s5,0xfffff
    8000517a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000517c:	df043783          	ld	a5,-528(s0)
    80005180:	6388                	ld	a0,0(a5)
    80005182:	c925                	beqz	a0,800051f2 <exec+0x226>
    80005184:	e9040993          	addi	s3,s0,-368
    80005188:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000518c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000518e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005190:	ffffc097          	auipc	ra,0xffffc
    80005194:	f00080e7          	jalr	-256(ra) # 80001090 <strlen>
    80005198:	0015079b          	addiw	a5,a0,1
    8000519c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051a0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800051a4:	13596663          	bltu	s2,s5,800052d0 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051a8:	df043d83          	ld	s11,-528(s0)
    800051ac:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051b0:	8552                	mv	a0,s4
    800051b2:	ffffc097          	auipc	ra,0xffffc
    800051b6:	ede080e7          	jalr	-290(ra) # 80001090 <strlen>
    800051ba:	0015069b          	addiw	a3,a0,1
    800051be:	8652                	mv	a2,s4
    800051c0:	85ca                	mv	a1,s2
    800051c2:	855a                	mv	a0,s6
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	6e6080e7          	jalr	1766(ra) # 800018aa <copyout>
    800051cc:	10054663          	bltz	a0,800052d8 <exec+0x30c>
    ustack[argc] = sp;
    800051d0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051d4:	0485                	addi	s1,s1,1
    800051d6:	008d8793          	addi	a5,s11,8
    800051da:	def43823          	sd	a5,-528(s0)
    800051de:	008db503          	ld	a0,8(s11)
    800051e2:	c911                	beqz	a0,800051f6 <exec+0x22a>
    if(argc >= MAXARG)
    800051e4:	09a1                	addi	s3,s3,8
    800051e6:	fb3c95e3          	bne	s9,s3,80005190 <exec+0x1c4>
  sz = sz1;
    800051ea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051ee:	4a81                	li	s5,0
    800051f0:	a84d                	j	800052a2 <exec+0x2d6>
  sp = sz;
    800051f2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051f4:	4481                	li	s1,0
  ustack[argc] = 0;
    800051f6:	00349793          	slli	a5,s1,0x3
    800051fa:	f9040713          	addi	a4,s0,-112
    800051fe:	97ba                	add	a5,a5,a4
    80005200:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc0b8>
  sp -= (argc+1) * sizeof(uint64);
    80005204:	00148693          	addi	a3,s1,1
    80005208:	068e                	slli	a3,a3,0x3
    8000520a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000520e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005212:	01597663          	bgeu	s2,s5,8000521e <exec+0x252>
  sz = sz1;
    80005216:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000521a:	4a81                	li	s5,0
    8000521c:	a059                	j	800052a2 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000521e:	e9040613          	addi	a2,s0,-368
    80005222:	85ca                	mv	a1,s2
    80005224:	855a                	mv	a0,s6
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	684080e7          	jalr	1668(ra) # 800018aa <copyout>
    8000522e:	0a054963          	bltz	a0,800052e0 <exec+0x314>
  p->trapframe->a1 = sp;
    80005232:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005236:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000523a:	de843783          	ld	a5,-536(s0)
    8000523e:	0007c703          	lbu	a4,0(a5)
    80005242:	cf11                	beqz	a4,8000525e <exec+0x292>
    80005244:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005246:	02f00693          	li	a3,47
    8000524a:	a039                	j	80005258 <exec+0x28c>
      last = s+1;
    8000524c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005250:	0785                	addi	a5,a5,1
    80005252:	fff7c703          	lbu	a4,-1(a5)
    80005256:	c701                	beqz	a4,8000525e <exec+0x292>
    if(*s == '/')
    80005258:	fed71ce3          	bne	a4,a3,80005250 <exec+0x284>
    8000525c:	bfc5                	j	8000524c <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    8000525e:	4641                	li	a2,16
    80005260:	de843583          	ld	a1,-536(s0)
    80005264:	158b8513          	addi	a0,s7,344
    80005268:	ffffc097          	auipc	ra,0xffffc
    8000526c:	df6080e7          	jalr	-522(ra) # 8000105e <safestrcpy>
  oldpagetable = p->pagetable;
    80005270:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005274:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005278:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000527c:	058bb783          	ld	a5,88(s7)
    80005280:	e6843703          	ld	a4,-408(s0)
    80005284:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005286:	058bb783          	ld	a5,88(s7)
    8000528a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000528e:	85ea                	mv	a1,s10
    80005290:	ffffd097          	auipc	ra,0xffffd
    80005294:	abe080e7          	jalr	-1346(ra) # 80001d4e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005298:	0004851b          	sext.w	a0,s1
    8000529c:	b3f1                	j	80005068 <exec+0x9c>
    8000529e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052a2:	df843583          	ld	a1,-520(s0)
    800052a6:	855a                	mv	a0,s6
    800052a8:	ffffd097          	auipc	ra,0xffffd
    800052ac:	aa6080e7          	jalr	-1370(ra) # 80001d4e <proc_freepagetable>
  if(ip){
    800052b0:	da0a92e3          	bnez	s5,80005054 <exec+0x88>
  return -1;
    800052b4:	557d                	li	a0,-1
    800052b6:	bb4d                	j	80005068 <exec+0x9c>
    800052b8:	df243c23          	sd	s2,-520(s0)
    800052bc:	b7dd                	j	800052a2 <exec+0x2d6>
    800052be:	df243c23          	sd	s2,-520(s0)
    800052c2:	b7c5                	j	800052a2 <exec+0x2d6>
    800052c4:	df243c23          	sd	s2,-520(s0)
    800052c8:	bfe9                	j	800052a2 <exec+0x2d6>
    800052ca:	df243c23          	sd	s2,-520(s0)
    800052ce:	bfd1                	j	800052a2 <exec+0x2d6>
  sz = sz1;
    800052d0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052d4:	4a81                	li	s5,0
    800052d6:	b7f1                	j	800052a2 <exec+0x2d6>
  sz = sz1;
    800052d8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052dc:	4a81                	li	s5,0
    800052de:	b7d1                	j	800052a2 <exec+0x2d6>
  sz = sz1;
    800052e0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052e4:	4a81                	li	s5,0
    800052e6:	bf75                	j	800052a2 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052e8:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ec:	e0843783          	ld	a5,-504(s0)
    800052f0:	0017869b          	addiw	a3,a5,1
    800052f4:	e0d43423          	sd	a3,-504(s0)
    800052f8:	e0043783          	ld	a5,-512(s0)
    800052fc:	0387879b          	addiw	a5,a5,56
    80005300:	e8845703          	lhu	a4,-376(s0)
    80005304:	e0e6dee3          	bge	a3,a4,80005120 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005308:	2781                	sext.w	a5,a5
    8000530a:	e0f43023          	sd	a5,-512(s0)
    8000530e:	03800713          	li	a4,56
    80005312:	86be                	mv	a3,a5
    80005314:	e1840613          	addi	a2,s0,-488
    80005318:	4581                	li	a1,0
    8000531a:	8556                	mv	a0,s5
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	a5c080e7          	jalr	-1444(ra) # 80003d78 <readi>
    80005324:	03800793          	li	a5,56
    80005328:	f6f51be3          	bne	a0,a5,8000529e <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000532c:	e1842783          	lw	a5,-488(s0)
    80005330:	4705                	li	a4,1
    80005332:	fae79de3          	bne	a5,a4,800052ec <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005336:	e4043483          	ld	s1,-448(s0)
    8000533a:	e3843783          	ld	a5,-456(s0)
    8000533e:	f6f4ede3          	bltu	s1,a5,800052b8 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005342:	e2843783          	ld	a5,-472(s0)
    80005346:	94be                	add	s1,s1,a5
    80005348:	f6f4ebe3          	bltu	s1,a5,800052be <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000534c:	de043703          	ld	a4,-544(s0)
    80005350:	8ff9                	and	a5,a5,a4
    80005352:	fbad                	bnez	a5,800052c4 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005354:	e1c42503          	lw	a0,-484(s0)
    80005358:	00000097          	auipc	ra,0x0
    8000535c:	c58080e7          	jalr	-936(ra) # 80004fb0 <flags2perm>
    80005360:	86aa                	mv	a3,a0
    80005362:	8626                	mv	a2,s1
    80005364:	85ca                	mv	a1,s2
    80005366:	855a                	mv	a0,s6
    80005368:	ffffc097          	auipc	ra,0xffffc
    8000536c:	2ea080e7          	jalr	746(ra) # 80001652 <uvmalloc>
    80005370:	dea43c23          	sd	a0,-520(s0)
    80005374:	d939                	beqz	a0,800052ca <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005376:	e2843c03          	ld	s8,-472(s0)
    8000537a:	e2042c83          	lw	s9,-480(s0)
    8000537e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005382:	f60b83e3          	beqz	s7,800052e8 <exec+0x31c>
    80005386:	89de                	mv	s3,s7
    80005388:	4481                	li	s1,0
    8000538a:	bb95                	j	800050fe <exec+0x132>

000000008000538c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000538c:	7179                	addi	sp,sp,-48
    8000538e:	f406                	sd	ra,40(sp)
    80005390:	f022                	sd	s0,32(sp)
    80005392:	ec26                	sd	s1,24(sp)
    80005394:	e84a                	sd	s2,16(sp)
    80005396:	1800                	addi	s0,sp,48
    80005398:	892e                	mv	s2,a1
    8000539a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000539c:	fdc40593          	addi	a1,s0,-36
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	b32080e7          	jalr	-1230(ra) # 80002ed2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053a8:	fdc42703          	lw	a4,-36(s0)
    800053ac:	47bd                	li	a5,15
    800053ae:	02e7eb63          	bltu	a5,a4,800053e4 <argfd+0x58>
    800053b2:	ffffd097          	auipc	ra,0xffffd
    800053b6:	83c080e7          	jalr	-1988(ra) # 80001bee <myproc>
    800053ba:	fdc42703          	lw	a4,-36(s0)
    800053be:	01a70793          	addi	a5,a4,26
    800053c2:	078e                	slli	a5,a5,0x3
    800053c4:	953e                	add	a0,a0,a5
    800053c6:	611c                	ld	a5,0(a0)
    800053c8:	c385                	beqz	a5,800053e8 <argfd+0x5c>
    return -1;
  if(pfd)
    800053ca:	00090463          	beqz	s2,800053d2 <argfd+0x46>
    *pfd = fd;
    800053ce:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053d2:	4501                	li	a0,0
  if(pf)
    800053d4:	c091                	beqz	s1,800053d8 <argfd+0x4c>
    *pf = f;
    800053d6:	e09c                	sd	a5,0(s1)
}
    800053d8:	70a2                	ld	ra,40(sp)
    800053da:	7402                	ld	s0,32(sp)
    800053dc:	64e2                	ld	s1,24(sp)
    800053de:	6942                	ld	s2,16(sp)
    800053e0:	6145                	addi	sp,sp,48
    800053e2:	8082                	ret
    return -1;
    800053e4:	557d                	li	a0,-1
    800053e6:	bfcd                	j	800053d8 <argfd+0x4c>
    800053e8:	557d                	li	a0,-1
    800053ea:	b7fd                	j	800053d8 <argfd+0x4c>

00000000800053ec <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053ec:	1101                	addi	sp,sp,-32
    800053ee:	ec06                	sd	ra,24(sp)
    800053f0:	e822                	sd	s0,16(sp)
    800053f2:	e426                	sd	s1,8(sp)
    800053f4:	1000                	addi	s0,sp,32
    800053f6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053f8:	ffffc097          	auipc	ra,0xffffc
    800053fc:	7f6080e7          	jalr	2038(ra) # 80001bee <myproc>
    80005400:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005402:	0d050793          	addi	a5,a0,208
    80005406:	4501                	li	a0,0
    80005408:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000540a:	6398                	ld	a4,0(a5)
    8000540c:	cb19                	beqz	a4,80005422 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000540e:	2505                	addiw	a0,a0,1
    80005410:	07a1                	addi	a5,a5,8
    80005412:	fed51ce3          	bne	a0,a3,8000540a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005416:	557d                	li	a0,-1
}
    80005418:	60e2                	ld	ra,24(sp)
    8000541a:	6442                	ld	s0,16(sp)
    8000541c:	64a2                	ld	s1,8(sp)
    8000541e:	6105                	addi	sp,sp,32
    80005420:	8082                	ret
      p->ofile[fd] = f;
    80005422:	01a50793          	addi	a5,a0,26
    80005426:	078e                	slli	a5,a5,0x3
    80005428:	963e                	add	a2,a2,a5
    8000542a:	e204                	sd	s1,0(a2)
      return fd;
    8000542c:	b7f5                	j	80005418 <fdalloc+0x2c>

000000008000542e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000542e:	715d                	addi	sp,sp,-80
    80005430:	e486                	sd	ra,72(sp)
    80005432:	e0a2                	sd	s0,64(sp)
    80005434:	fc26                	sd	s1,56(sp)
    80005436:	f84a                	sd	s2,48(sp)
    80005438:	f44e                	sd	s3,40(sp)
    8000543a:	f052                	sd	s4,32(sp)
    8000543c:	ec56                	sd	s5,24(sp)
    8000543e:	e85a                	sd	s6,16(sp)
    80005440:	0880                	addi	s0,sp,80
    80005442:	8b2e                	mv	s6,a1
    80005444:	89b2                	mv	s3,a2
    80005446:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005448:	fb040593          	addi	a1,s0,-80
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	e3c080e7          	jalr	-452(ra) # 80004288 <nameiparent>
    80005454:	84aa                	mv	s1,a0
    80005456:	14050f63          	beqz	a0,800055b4 <create+0x186>
    return 0;

  ilock(dp);
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	66a080e7          	jalr	1642(ra) # 80003ac4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005462:	4601                	li	a2,0
    80005464:	fb040593          	addi	a1,s0,-80
    80005468:	8526                	mv	a0,s1
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	b3e080e7          	jalr	-1218(ra) # 80003fa8 <dirlookup>
    80005472:	8aaa                	mv	s5,a0
    80005474:	c931                	beqz	a0,800054c8 <create+0x9a>
    iunlockput(dp);
    80005476:	8526                	mv	a0,s1
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	8ae080e7          	jalr	-1874(ra) # 80003d26 <iunlockput>
    ilock(ip);
    80005480:	8556                	mv	a0,s5
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	642080e7          	jalr	1602(ra) # 80003ac4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000548a:	000b059b          	sext.w	a1,s6
    8000548e:	4789                	li	a5,2
    80005490:	02f59563          	bne	a1,a5,800054ba <create+0x8c>
    80005494:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc1fc>
    80005498:	37f9                	addiw	a5,a5,-2
    8000549a:	17c2                	slli	a5,a5,0x30
    8000549c:	93c1                	srli	a5,a5,0x30
    8000549e:	4705                	li	a4,1
    800054a0:	00f76d63          	bltu	a4,a5,800054ba <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800054a4:	8556                	mv	a0,s5
    800054a6:	60a6                	ld	ra,72(sp)
    800054a8:	6406                	ld	s0,64(sp)
    800054aa:	74e2                	ld	s1,56(sp)
    800054ac:	7942                	ld	s2,48(sp)
    800054ae:	79a2                	ld	s3,40(sp)
    800054b0:	7a02                	ld	s4,32(sp)
    800054b2:	6ae2                	ld	s5,24(sp)
    800054b4:	6b42                	ld	s6,16(sp)
    800054b6:	6161                	addi	sp,sp,80
    800054b8:	8082                	ret
    iunlockput(ip);
    800054ba:	8556                	mv	a0,s5
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	86a080e7          	jalr	-1942(ra) # 80003d26 <iunlockput>
    return 0;
    800054c4:	4a81                	li	s5,0
    800054c6:	bff9                	j	800054a4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800054c8:	85da                	mv	a1,s6
    800054ca:	4088                	lw	a0,0(s1)
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	45c080e7          	jalr	1116(ra) # 80003928 <ialloc>
    800054d4:	8a2a                	mv	s4,a0
    800054d6:	c539                	beqz	a0,80005524 <create+0xf6>
  ilock(ip);
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	5ec080e7          	jalr	1516(ra) # 80003ac4 <ilock>
  ip->major = major;
    800054e0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800054e4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800054e8:	4905                	li	s2,1
    800054ea:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800054ee:	8552                	mv	a0,s4
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	50a080e7          	jalr	1290(ra) # 800039fa <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054f8:	000b059b          	sext.w	a1,s6
    800054fc:	03258b63          	beq	a1,s2,80005532 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005500:	004a2603          	lw	a2,4(s4)
    80005504:	fb040593          	addi	a1,s0,-80
    80005508:	8526                	mv	a0,s1
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	cae080e7          	jalr	-850(ra) # 800041b8 <dirlink>
    80005512:	06054f63          	bltz	a0,80005590 <create+0x162>
  iunlockput(dp);
    80005516:	8526                	mv	a0,s1
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	80e080e7          	jalr	-2034(ra) # 80003d26 <iunlockput>
  return ip;
    80005520:	8ad2                	mv	s5,s4
    80005522:	b749                	j	800054a4 <create+0x76>
    iunlockput(dp);
    80005524:	8526                	mv	a0,s1
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	800080e7          	jalr	-2048(ra) # 80003d26 <iunlockput>
    return 0;
    8000552e:	8ad2                	mv	s5,s4
    80005530:	bf95                	j	800054a4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005532:	004a2603          	lw	a2,4(s4)
    80005536:	00003597          	auipc	a1,0x3
    8000553a:	2a258593          	addi	a1,a1,674 # 800087d8 <syscalls+0x2b0>
    8000553e:	8552                	mv	a0,s4
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	c78080e7          	jalr	-904(ra) # 800041b8 <dirlink>
    80005548:	04054463          	bltz	a0,80005590 <create+0x162>
    8000554c:	40d0                	lw	a2,4(s1)
    8000554e:	00003597          	auipc	a1,0x3
    80005552:	29258593          	addi	a1,a1,658 # 800087e0 <syscalls+0x2b8>
    80005556:	8552                	mv	a0,s4
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	c60080e7          	jalr	-928(ra) # 800041b8 <dirlink>
    80005560:	02054863          	bltz	a0,80005590 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005564:	004a2603          	lw	a2,4(s4)
    80005568:	fb040593          	addi	a1,s0,-80
    8000556c:	8526                	mv	a0,s1
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	c4a080e7          	jalr	-950(ra) # 800041b8 <dirlink>
    80005576:	00054d63          	bltz	a0,80005590 <create+0x162>
    dp->nlink++;  // for ".."
    8000557a:	04a4d783          	lhu	a5,74(s1)
    8000557e:	2785                	addiw	a5,a5,1
    80005580:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	474080e7          	jalr	1140(ra) # 800039fa <iupdate>
    8000558e:	b761                	j	80005516 <create+0xe8>
  ip->nlink = 0;
    80005590:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005594:	8552                	mv	a0,s4
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	464080e7          	jalr	1124(ra) # 800039fa <iupdate>
  iunlockput(ip);
    8000559e:	8552                	mv	a0,s4
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	786080e7          	jalr	1926(ra) # 80003d26 <iunlockput>
  iunlockput(dp);
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	77c080e7          	jalr	1916(ra) # 80003d26 <iunlockput>
  return 0;
    800055b2:	bdcd                	j	800054a4 <create+0x76>
    return 0;
    800055b4:	8aaa                	mv	s5,a0
    800055b6:	b5fd                	j	800054a4 <create+0x76>

00000000800055b8 <sys_dup>:
{
    800055b8:	7179                	addi	sp,sp,-48
    800055ba:	f406                	sd	ra,40(sp)
    800055bc:	f022                	sd	s0,32(sp)
    800055be:	ec26                	sd	s1,24(sp)
    800055c0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055c2:	fd840613          	addi	a2,s0,-40
    800055c6:	4581                	li	a1,0
    800055c8:	4501                	li	a0,0
    800055ca:	00000097          	auipc	ra,0x0
    800055ce:	dc2080e7          	jalr	-574(ra) # 8000538c <argfd>
    return -1;
    800055d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055d4:	02054363          	bltz	a0,800055fa <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800055d8:	fd843503          	ld	a0,-40(s0)
    800055dc:	00000097          	auipc	ra,0x0
    800055e0:	e10080e7          	jalr	-496(ra) # 800053ec <fdalloc>
    800055e4:	84aa                	mv	s1,a0
    return -1;
    800055e6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055e8:	00054963          	bltz	a0,800055fa <sys_dup+0x42>
  filedup(f);
    800055ec:	fd843503          	ld	a0,-40(s0)
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	310080e7          	jalr	784(ra) # 80004900 <filedup>
  return fd;
    800055f8:	87a6                	mv	a5,s1
}
    800055fa:	853e                	mv	a0,a5
    800055fc:	70a2                	ld	ra,40(sp)
    800055fe:	7402                	ld	s0,32(sp)
    80005600:	64e2                	ld	s1,24(sp)
    80005602:	6145                	addi	sp,sp,48
    80005604:	8082                	ret

0000000080005606 <sys_read>:
{
    80005606:	7179                	addi	sp,sp,-48
    80005608:	f406                	sd	ra,40(sp)
    8000560a:	f022                	sd	s0,32(sp)
    8000560c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000560e:	fd840593          	addi	a1,s0,-40
    80005612:	4505                	li	a0,1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	8de080e7          	jalr	-1826(ra) # 80002ef2 <argaddr>
  argint(2, &n);
    8000561c:	fe440593          	addi	a1,s0,-28
    80005620:	4509                	li	a0,2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	8b0080e7          	jalr	-1872(ra) # 80002ed2 <argint>
  if(argfd(0, 0, &f) < 0)
    8000562a:	fe840613          	addi	a2,s0,-24
    8000562e:	4581                	li	a1,0
    80005630:	4501                	li	a0,0
    80005632:	00000097          	auipc	ra,0x0
    80005636:	d5a080e7          	jalr	-678(ra) # 8000538c <argfd>
    8000563a:	87aa                	mv	a5,a0
    return -1;
    8000563c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000563e:	0007cc63          	bltz	a5,80005656 <sys_read+0x50>
  return fileread(f, p, n);
    80005642:	fe442603          	lw	a2,-28(s0)
    80005646:	fd843583          	ld	a1,-40(s0)
    8000564a:	fe843503          	ld	a0,-24(s0)
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	43e080e7          	jalr	1086(ra) # 80004a8c <fileread>
}
    80005656:	70a2                	ld	ra,40(sp)
    80005658:	7402                	ld	s0,32(sp)
    8000565a:	6145                	addi	sp,sp,48
    8000565c:	8082                	ret

000000008000565e <sys_write>:
{
    8000565e:	7179                	addi	sp,sp,-48
    80005660:	f406                	sd	ra,40(sp)
    80005662:	f022                	sd	s0,32(sp)
    80005664:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005666:	fd840593          	addi	a1,s0,-40
    8000566a:	4505                	li	a0,1
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	886080e7          	jalr	-1914(ra) # 80002ef2 <argaddr>
  argint(2, &n);
    80005674:	fe440593          	addi	a1,s0,-28
    80005678:	4509                	li	a0,2
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	858080e7          	jalr	-1960(ra) # 80002ed2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005682:	fe840613          	addi	a2,s0,-24
    80005686:	4581                	li	a1,0
    80005688:	4501                	li	a0,0
    8000568a:	00000097          	auipc	ra,0x0
    8000568e:	d02080e7          	jalr	-766(ra) # 8000538c <argfd>
    80005692:	87aa                	mv	a5,a0
    return -1;
    80005694:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005696:	0007cc63          	bltz	a5,800056ae <sys_write+0x50>
  return filewrite(f, p, n);
    8000569a:	fe442603          	lw	a2,-28(s0)
    8000569e:	fd843583          	ld	a1,-40(s0)
    800056a2:	fe843503          	ld	a0,-24(s0)
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	4a8080e7          	jalr	1192(ra) # 80004b4e <filewrite>
}
    800056ae:	70a2                	ld	ra,40(sp)
    800056b0:	7402                	ld	s0,32(sp)
    800056b2:	6145                	addi	sp,sp,48
    800056b4:	8082                	ret

00000000800056b6 <sys_close>:
{
    800056b6:	1101                	addi	sp,sp,-32
    800056b8:	ec06                	sd	ra,24(sp)
    800056ba:	e822                	sd	s0,16(sp)
    800056bc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056be:	fe040613          	addi	a2,s0,-32
    800056c2:	fec40593          	addi	a1,s0,-20
    800056c6:	4501                	li	a0,0
    800056c8:	00000097          	auipc	ra,0x0
    800056cc:	cc4080e7          	jalr	-828(ra) # 8000538c <argfd>
    return -1;
    800056d0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056d2:	02054463          	bltz	a0,800056fa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056d6:	ffffc097          	auipc	ra,0xffffc
    800056da:	518080e7          	jalr	1304(ra) # 80001bee <myproc>
    800056de:	fec42783          	lw	a5,-20(s0)
    800056e2:	07e9                	addi	a5,a5,26
    800056e4:	078e                	slli	a5,a5,0x3
    800056e6:	97aa                	add	a5,a5,a0
    800056e8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800056ec:	fe043503          	ld	a0,-32(s0)
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	262080e7          	jalr	610(ra) # 80004952 <fileclose>
  return 0;
    800056f8:	4781                	li	a5,0
}
    800056fa:	853e                	mv	a0,a5
    800056fc:	60e2                	ld	ra,24(sp)
    800056fe:	6442                	ld	s0,16(sp)
    80005700:	6105                	addi	sp,sp,32
    80005702:	8082                	ret

0000000080005704 <sys_fstat>:
{
    80005704:	1101                	addi	sp,sp,-32
    80005706:	ec06                	sd	ra,24(sp)
    80005708:	e822                	sd	s0,16(sp)
    8000570a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000570c:	fe040593          	addi	a1,s0,-32
    80005710:	4505                	li	a0,1
    80005712:	ffffd097          	auipc	ra,0xffffd
    80005716:	7e0080e7          	jalr	2016(ra) # 80002ef2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000571a:	fe840613          	addi	a2,s0,-24
    8000571e:	4581                	li	a1,0
    80005720:	4501                	li	a0,0
    80005722:	00000097          	auipc	ra,0x0
    80005726:	c6a080e7          	jalr	-918(ra) # 8000538c <argfd>
    8000572a:	87aa                	mv	a5,a0
    return -1;
    8000572c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000572e:	0007ca63          	bltz	a5,80005742 <sys_fstat+0x3e>
  return filestat(f, st);
    80005732:	fe043583          	ld	a1,-32(s0)
    80005736:	fe843503          	ld	a0,-24(s0)
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	2e0080e7          	jalr	736(ra) # 80004a1a <filestat>
}
    80005742:	60e2                	ld	ra,24(sp)
    80005744:	6442                	ld	s0,16(sp)
    80005746:	6105                	addi	sp,sp,32
    80005748:	8082                	ret

000000008000574a <sys_link>:
{
    8000574a:	7169                	addi	sp,sp,-304
    8000574c:	f606                	sd	ra,296(sp)
    8000574e:	f222                	sd	s0,288(sp)
    80005750:	ee26                	sd	s1,280(sp)
    80005752:	ea4a                	sd	s2,272(sp)
    80005754:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005756:	08000613          	li	a2,128
    8000575a:	ed040593          	addi	a1,s0,-304
    8000575e:	4501                	li	a0,0
    80005760:	ffffd097          	auipc	ra,0xffffd
    80005764:	7b2080e7          	jalr	1970(ra) # 80002f12 <argstr>
    return -1;
    80005768:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000576a:	10054e63          	bltz	a0,80005886 <sys_link+0x13c>
    8000576e:	08000613          	li	a2,128
    80005772:	f5040593          	addi	a1,s0,-176
    80005776:	4505                	li	a0,1
    80005778:	ffffd097          	auipc	ra,0xffffd
    8000577c:	79a080e7          	jalr	1946(ra) # 80002f12 <argstr>
    return -1;
    80005780:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005782:	10054263          	bltz	a0,80005886 <sys_link+0x13c>
  begin_op();
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	d00080e7          	jalr	-768(ra) # 80004486 <begin_op>
  if((ip = namei(old)) == 0){
    8000578e:	ed040513          	addi	a0,s0,-304
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	ad8080e7          	jalr	-1320(ra) # 8000426a <namei>
    8000579a:	84aa                	mv	s1,a0
    8000579c:	c551                	beqz	a0,80005828 <sys_link+0xde>
  ilock(ip);
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	326080e7          	jalr	806(ra) # 80003ac4 <ilock>
  if(ip->type == T_DIR){
    800057a6:	04449703          	lh	a4,68(s1)
    800057aa:	4785                	li	a5,1
    800057ac:	08f70463          	beq	a4,a5,80005834 <sys_link+0xea>
  ip->nlink++;
    800057b0:	04a4d783          	lhu	a5,74(s1)
    800057b4:	2785                	addiw	a5,a5,1
    800057b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	23e080e7          	jalr	574(ra) # 800039fa <iupdate>
  iunlock(ip);
    800057c4:	8526                	mv	a0,s1
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	3c0080e7          	jalr	960(ra) # 80003b86 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057ce:	fd040593          	addi	a1,s0,-48
    800057d2:	f5040513          	addi	a0,s0,-176
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	ab2080e7          	jalr	-1358(ra) # 80004288 <nameiparent>
    800057de:	892a                	mv	s2,a0
    800057e0:	c935                	beqz	a0,80005854 <sys_link+0x10a>
  ilock(dp);
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	2e2080e7          	jalr	738(ra) # 80003ac4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057ea:	00092703          	lw	a4,0(s2)
    800057ee:	409c                	lw	a5,0(s1)
    800057f0:	04f71d63          	bne	a4,a5,8000584a <sys_link+0x100>
    800057f4:	40d0                	lw	a2,4(s1)
    800057f6:	fd040593          	addi	a1,s0,-48
    800057fa:	854a                	mv	a0,s2
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	9bc080e7          	jalr	-1604(ra) # 800041b8 <dirlink>
    80005804:	04054363          	bltz	a0,8000584a <sys_link+0x100>
  iunlockput(dp);
    80005808:	854a                	mv	a0,s2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	51c080e7          	jalr	1308(ra) # 80003d26 <iunlockput>
  iput(ip);
    80005812:	8526                	mv	a0,s1
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	46a080e7          	jalr	1130(ra) # 80003c7e <iput>
  end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	cea080e7          	jalr	-790(ra) # 80004506 <end_op>
  return 0;
    80005824:	4781                	li	a5,0
    80005826:	a085                	j	80005886 <sys_link+0x13c>
    end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	cde080e7          	jalr	-802(ra) # 80004506 <end_op>
    return -1;
    80005830:	57fd                	li	a5,-1
    80005832:	a891                	j	80005886 <sys_link+0x13c>
    iunlockput(ip);
    80005834:	8526                	mv	a0,s1
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	4f0080e7          	jalr	1264(ra) # 80003d26 <iunlockput>
    end_op();
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	cc8080e7          	jalr	-824(ra) # 80004506 <end_op>
    return -1;
    80005846:	57fd                	li	a5,-1
    80005848:	a83d                	j	80005886 <sys_link+0x13c>
    iunlockput(dp);
    8000584a:	854a                	mv	a0,s2
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	4da080e7          	jalr	1242(ra) # 80003d26 <iunlockput>
  ilock(ip);
    80005854:	8526                	mv	a0,s1
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	26e080e7          	jalr	622(ra) # 80003ac4 <ilock>
  ip->nlink--;
    8000585e:	04a4d783          	lhu	a5,74(s1)
    80005862:	37fd                	addiw	a5,a5,-1
    80005864:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005868:	8526                	mv	a0,s1
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	190080e7          	jalr	400(ra) # 800039fa <iupdate>
  iunlockput(ip);
    80005872:	8526                	mv	a0,s1
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	4b2080e7          	jalr	1202(ra) # 80003d26 <iunlockput>
  end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	c8a080e7          	jalr	-886(ra) # 80004506 <end_op>
  return -1;
    80005884:	57fd                	li	a5,-1
}
    80005886:	853e                	mv	a0,a5
    80005888:	70b2                	ld	ra,296(sp)
    8000588a:	7412                	ld	s0,288(sp)
    8000588c:	64f2                	ld	s1,280(sp)
    8000588e:	6952                	ld	s2,272(sp)
    80005890:	6155                	addi	sp,sp,304
    80005892:	8082                	ret

0000000080005894 <sys_unlink>:
{
    80005894:	7151                	addi	sp,sp,-240
    80005896:	f586                	sd	ra,232(sp)
    80005898:	f1a2                	sd	s0,224(sp)
    8000589a:	eda6                	sd	s1,216(sp)
    8000589c:	e9ca                	sd	s2,208(sp)
    8000589e:	e5ce                	sd	s3,200(sp)
    800058a0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058a2:	08000613          	li	a2,128
    800058a6:	f3040593          	addi	a1,s0,-208
    800058aa:	4501                	li	a0,0
    800058ac:	ffffd097          	auipc	ra,0xffffd
    800058b0:	666080e7          	jalr	1638(ra) # 80002f12 <argstr>
    800058b4:	18054163          	bltz	a0,80005a36 <sys_unlink+0x1a2>
  begin_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	bce080e7          	jalr	-1074(ra) # 80004486 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058c0:	fb040593          	addi	a1,s0,-80
    800058c4:	f3040513          	addi	a0,s0,-208
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	9c0080e7          	jalr	-1600(ra) # 80004288 <nameiparent>
    800058d0:	84aa                	mv	s1,a0
    800058d2:	c979                	beqz	a0,800059a8 <sys_unlink+0x114>
  ilock(dp);
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	1f0080e7          	jalr	496(ra) # 80003ac4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058dc:	00003597          	auipc	a1,0x3
    800058e0:	efc58593          	addi	a1,a1,-260 # 800087d8 <syscalls+0x2b0>
    800058e4:	fb040513          	addi	a0,s0,-80
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	6a6080e7          	jalr	1702(ra) # 80003f8e <namecmp>
    800058f0:	14050a63          	beqz	a0,80005a44 <sys_unlink+0x1b0>
    800058f4:	00003597          	auipc	a1,0x3
    800058f8:	eec58593          	addi	a1,a1,-276 # 800087e0 <syscalls+0x2b8>
    800058fc:	fb040513          	addi	a0,s0,-80
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	68e080e7          	jalr	1678(ra) # 80003f8e <namecmp>
    80005908:	12050e63          	beqz	a0,80005a44 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000590c:	f2c40613          	addi	a2,s0,-212
    80005910:	fb040593          	addi	a1,s0,-80
    80005914:	8526                	mv	a0,s1
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	692080e7          	jalr	1682(ra) # 80003fa8 <dirlookup>
    8000591e:	892a                	mv	s2,a0
    80005920:	12050263          	beqz	a0,80005a44 <sys_unlink+0x1b0>
  ilock(ip);
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	1a0080e7          	jalr	416(ra) # 80003ac4 <ilock>
  if(ip->nlink < 1)
    8000592c:	04a91783          	lh	a5,74(s2)
    80005930:	08f05263          	blez	a5,800059b4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005934:	04491703          	lh	a4,68(s2)
    80005938:	4785                	li	a5,1
    8000593a:	08f70563          	beq	a4,a5,800059c4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000593e:	4641                	li	a2,16
    80005940:	4581                	li	a1,0
    80005942:	fc040513          	addi	a0,s0,-64
    80005946:	ffffb097          	auipc	ra,0xffffb
    8000594a:	5ce080e7          	jalr	1486(ra) # 80000f14 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000594e:	4741                	li	a4,16
    80005950:	f2c42683          	lw	a3,-212(s0)
    80005954:	fc040613          	addi	a2,s0,-64
    80005958:	4581                	li	a1,0
    8000595a:	8526                	mv	a0,s1
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	514080e7          	jalr	1300(ra) # 80003e70 <writei>
    80005964:	47c1                	li	a5,16
    80005966:	0af51563          	bne	a0,a5,80005a10 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000596a:	04491703          	lh	a4,68(s2)
    8000596e:	4785                	li	a5,1
    80005970:	0af70863          	beq	a4,a5,80005a20 <sys_unlink+0x18c>
  iunlockput(dp);
    80005974:	8526                	mv	a0,s1
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	3b0080e7          	jalr	944(ra) # 80003d26 <iunlockput>
  ip->nlink--;
    8000597e:	04a95783          	lhu	a5,74(s2)
    80005982:	37fd                	addiw	a5,a5,-1
    80005984:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005988:	854a                	mv	a0,s2
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	070080e7          	jalr	112(ra) # 800039fa <iupdate>
  iunlockput(ip);
    80005992:	854a                	mv	a0,s2
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	392080e7          	jalr	914(ra) # 80003d26 <iunlockput>
  end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	b6a080e7          	jalr	-1174(ra) # 80004506 <end_op>
  return 0;
    800059a4:	4501                	li	a0,0
    800059a6:	a84d                	j	80005a58 <sys_unlink+0x1c4>
    end_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	b5e080e7          	jalr	-1186(ra) # 80004506 <end_op>
    return -1;
    800059b0:	557d                	li	a0,-1
    800059b2:	a05d                	j	80005a58 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059b4:	00003517          	auipc	a0,0x3
    800059b8:	e3450513          	addi	a0,a0,-460 # 800087e8 <syscalls+0x2c0>
    800059bc:	ffffb097          	auipc	ra,0xffffb
    800059c0:	dc4080e7          	jalr	-572(ra) # 80000780 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059c4:	04c92703          	lw	a4,76(s2)
    800059c8:	02000793          	li	a5,32
    800059cc:	f6e7f9e3          	bgeu	a5,a4,8000593e <sys_unlink+0xaa>
    800059d0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059d4:	4741                	li	a4,16
    800059d6:	86ce                	mv	a3,s3
    800059d8:	f1840613          	addi	a2,s0,-232
    800059dc:	4581                	li	a1,0
    800059de:	854a                	mv	a0,s2
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	398080e7          	jalr	920(ra) # 80003d78 <readi>
    800059e8:	47c1                	li	a5,16
    800059ea:	00f51b63          	bne	a0,a5,80005a00 <sys_unlink+0x16c>
    if(de.inum != 0)
    800059ee:	f1845783          	lhu	a5,-232(s0)
    800059f2:	e7a1                	bnez	a5,80005a3a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059f4:	29c1                	addiw	s3,s3,16
    800059f6:	04c92783          	lw	a5,76(s2)
    800059fa:	fcf9ede3          	bltu	s3,a5,800059d4 <sys_unlink+0x140>
    800059fe:	b781                	j	8000593e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a00:	00003517          	auipc	a0,0x3
    80005a04:	e0050513          	addi	a0,a0,-512 # 80008800 <syscalls+0x2d8>
    80005a08:	ffffb097          	auipc	ra,0xffffb
    80005a0c:	d78080e7          	jalr	-648(ra) # 80000780 <panic>
    panic("unlink: writei");
    80005a10:	00003517          	auipc	a0,0x3
    80005a14:	e0850513          	addi	a0,a0,-504 # 80008818 <syscalls+0x2f0>
    80005a18:	ffffb097          	auipc	ra,0xffffb
    80005a1c:	d68080e7          	jalr	-664(ra) # 80000780 <panic>
    dp->nlink--;
    80005a20:	04a4d783          	lhu	a5,74(s1)
    80005a24:	37fd                	addiw	a5,a5,-1
    80005a26:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a2a:	8526                	mv	a0,s1
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	fce080e7          	jalr	-50(ra) # 800039fa <iupdate>
    80005a34:	b781                	j	80005974 <sys_unlink+0xe0>
    return -1;
    80005a36:	557d                	li	a0,-1
    80005a38:	a005                	j	80005a58 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a3a:	854a                	mv	a0,s2
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	2ea080e7          	jalr	746(ra) # 80003d26 <iunlockput>
  iunlockput(dp);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	2e0080e7          	jalr	736(ra) # 80003d26 <iunlockput>
  end_op();
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	ab8080e7          	jalr	-1352(ra) # 80004506 <end_op>
  return -1;
    80005a56:	557d                	li	a0,-1
}
    80005a58:	70ae                	ld	ra,232(sp)
    80005a5a:	740e                	ld	s0,224(sp)
    80005a5c:	64ee                	ld	s1,216(sp)
    80005a5e:	694e                	ld	s2,208(sp)
    80005a60:	69ae                	ld	s3,200(sp)
    80005a62:	616d                	addi	sp,sp,240
    80005a64:	8082                	ret

0000000080005a66 <sys_open>:

uint64
sys_open(void)
{
    80005a66:	7131                	addi	sp,sp,-192
    80005a68:	fd06                	sd	ra,184(sp)
    80005a6a:	f922                	sd	s0,176(sp)
    80005a6c:	f526                	sd	s1,168(sp)
    80005a6e:	f14a                	sd	s2,160(sp)
    80005a70:	ed4e                	sd	s3,152(sp)
    80005a72:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005a74:	f4c40593          	addi	a1,s0,-180
    80005a78:	4505                	li	a0,1
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	458080e7          	jalr	1112(ra) # 80002ed2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a82:	08000613          	li	a2,128
    80005a86:	f5040593          	addi	a1,s0,-176
    80005a8a:	4501                	li	a0,0
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	486080e7          	jalr	1158(ra) # 80002f12 <argstr>
    80005a94:	87aa                	mv	a5,a0
    return -1;
    80005a96:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a98:	0a07c963          	bltz	a5,80005b4a <sys_open+0xe4>

  begin_op();
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	9ea080e7          	jalr	-1558(ra) # 80004486 <begin_op>

  if(omode & O_CREATE){
    80005aa4:	f4c42783          	lw	a5,-180(s0)
    80005aa8:	2007f793          	andi	a5,a5,512
    80005aac:	cfc5                	beqz	a5,80005b64 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005aae:	4681                	li	a3,0
    80005ab0:	4601                	li	a2,0
    80005ab2:	4589                	li	a1,2
    80005ab4:	f5040513          	addi	a0,s0,-176
    80005ab8:	00000097          	auipc	ra,0x0
    80005abc:	976080e7          	jalr	-1674(ra) # 8000542e <create>
    80005ac0:	84aa                	mv	s1,a0
    if(ip == 0){
    80005ac2:	c959                	beqz	a0,80005b58 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ac4:	04449703          	lh	a4,68(s1)
    80005ac8:	478d                	li	a5,3
    80005aca:	00f71763          	bne	a4,a5,80005ad8 <sys_open+0x72>
    80005ace:	0464d703          	lhu	a4,70(s1)
    80005ad2:	47a5                	li	a5,9
    80005ad4:	0ce7ed63          	bltu	a5,a4,80005bae <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	dbe080e7          	jalr	-578(ra) # 80004896 <filealloc>
    80005ae0:	89aa                	mv	s3,a0
    80005ae2:	10050363          	beqz	a0,80005be8 <sys_open+0x182>
    80005ae6:	00000097          	auipc	ra,0x0
    80005aea:	906080e7          	jalr	-1786(ra) # 800053ec <fdalloc>
    80005aee:	892a                	mv	s2,a0
    80005af0:	0e054763          	bltz	a0,80005bde <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005af4:	04449703          	lh	a4,68(s1)
    80005af8:	478d                	li	a5,3
    80005afa:	0cf70563          	beq	a4,a5,80005bc4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005afe:	4789                	li	a5,2
    80005b00:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b04:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b08:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b0c:	f4c42783          	lw	a5,-180(s0)
    80005b10:	0017c713          	xori	a4,a5,1
    80005b14:	8b05                	andi	a4,a4,1
    80005b16:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b1a:	0037f713          	andi	a4,a5,3
    80005b1e:	00e03733          	snez	a4,a4
    80005b22:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b26:	4007f793          	andi	a5,a5,1024
    80005b2a:	c791                	beqz	a5,80005b36 <sys_open+0xd0>
    80005b2c:	04449703          	lh	a4,68(s1)
    80005b30:	4789                	li	a5,2
    80005b32:	0af70063          	beq	a4,a5,80005bd2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b36:	8526                	mv	a0,s1
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	04e080e7          	jalr	78(ra) # 80003b86 <iunlock>
  end_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	9c6080e7          	jalr	-1594(ra) # 80004506 <end_op>

  return fd;
    80005b48:	854a                	mv	a0,s2
}
    80005b4a:	70ea                	ld	ra,184(sp)
    80005b4c:	744a                	ld	s0,176(sp)
    80005b4e:	74aa                	ld	s1,168(sp)
    80005b50:	790a                	ld	s2,160(sp)
    80005b52:	69ea                	ld	s3,152(sp)
    80005b54:	6129                	addi	sp,sp,192
    80005b56:	8082                	ret
      end_op();
    80005b58:	fffff097          	auipc	ra,0xfffff
    80005b5c:	9ae080e7          	jalr	-1618(ra) # 80004506 <end_op>
      return -1;
    80005b60:	557d                	li	a0,-1
    80005b62:	b7e5                	j	80005b4a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b64:	f5040513          	addi	a0,s0,-176
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	702080e7          	jalr	1794(ra) # 8000426a <namei>
    80005b70:	84aa                	mv	s1,a0
    80005b72:	c905                	beqz	a0,80005ba2 <sys_open+0x13c>
    ilock(ip);
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	f50080e7          	jalr	-176(ra) # 80003ac4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b7c:	04449703          	lh	a4,68(s1)
    80005b80:	4785                	li	a5,1
    80005b82:	f4f711e3          	bne	a4,a5,80005ac4 <sys_open+0x5e>
    80005b86:	f4c42783          	lw	a5,-180(s0)
    80005b8a:	d7b9                	beqz	a5,80005ad8 <sys_open+0x72>
      iunlockput(ip);
    80005b8c:	8526                	mv	a0,s1
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	198080e7          	jalr	408(ra) # 80003d26 <iunlockput>
      end_op();
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	970080e7          	jalr	-1680(ra) # 80004506 <end_op>
      return -1;
    80005b9e:	557d                	li	a0,-1
    80005ba0:	b76d                	j	80005b4a <sys_open+0xe4>
      end_op();
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	964080e7          	jalr	-1692(ra) # 80004506 <end_op>
      return -1;
    80005baa:	557d                	li	a0,-1
    80005bac:	bf79                	j	80005b4a <sys_open+0xe4>
    iunlockput(ip);
    80005bae:	8526                	mv	a0,s1
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	176080e7          	jalr	374(ra) # 80003d26 <iunlockput>
    end_op();
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	94e080e7          	jalr	-1714(ra) # 80004506 <end_op>
    return -1;
    80005bc0:	557d                	li	a0,-1
    80005bc2:	b761                	j	80005b4a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bc4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005bc8:	04649783          	lh	a5,70(s1)
    80005bcc:	02f99223          	sh	a5,36(s3)
    80005bd0:	bf25                	j	80005b08 <sys_open+0xa2>
    itrunc(ip);
    80005bd2:	8526                	mv	a0,s1
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	ffe080e7          	jalr	-2(ra) # 80003bd2 <itrunc>
    80005bdc:	bfa9                	j	80005b36 <sys_open+0xd0>
      fileclose(f);
    80005bde:	854e                	mv	a0,s3
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	d72080e7          	jalr	-654(ra) # 80004952 <fileclose>
    iunlockput(ip);
    80005be8:	8526                	mv	a0,s1
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	13c080e7          	jalr	316(ra) # 80003d26 <iunlockput>
    end_op();
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	914080e7          	jalr	-1772(ra) # 80004506 <end_op>
    return -1;
    80005bfa:	557d                	li	a0,-1
    80005bfc:	b7b9                	j	80005b4a <sys_open+0xe4>

0000000080005bfe <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bfe:	7175                	addi	sp,sp,-144
    80005c00:	e506                	sd	ra,136(sp)
    80005c02:	e122                	sd	s0,128(sp)
    80005c04:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	880080e7          	jalr	-1920(ra) # 80004486 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c0e:	08000613          	li	a2,128
    80005c12:	f7040593          	addi	a1,s0,-144
    80005c16:	4501                	li	a0,0
    80005c18:	ffffd097          	auipc	ra,0xffffd
    80005c1c:	2fa080e7          	jalr	762(ra) # 80002f12 <argstr>
    80005c20:	02054963          	bltz	a0,80005c52 <sys_mkdir+0x54>
    80005c24:	4681                	li	a3,0
    80005c26:	4601                	li	a2,0
    80005c28:	4585                	li	a1,1
    80005c2a:	f7040513          	addi	a0,s0,-144
    80005c2e:	00000097          	auipc	ra,0x0
    80005c32:	800080e7          	jalr	-2048(ra) # 8000542e <create>
    80005c36:	cd11                	beqz	a0,80005c52 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	0ee080e7          	jalr	238(ra) # 80003d26 <iunlockput>
  end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	8c6080e7          	jalr	-1850(ra) # 80004506 <end_op>
  return 0;
    80005c48:	4501                	li	a0,0
}
    80005c4a:	60aa                	ld	ra,136(sp)
    80005c4c:	640a                	ld	s0,128(sp)
    80005c4e:	6149                	addi	sp,sp,144
    80005c50:	8082                	ret
    end_op();
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	8b4080e7          	jalr	-1868(ra) # 80004506 <end_op>
    return -1;
    80005c5a:	557d                	li	a0,-1
    80005c5c:	b7fd                	j	80005c4a <sys_mkdir+0x4c>

0000000080005c5e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c5e:	7135                	addi	sp,sp,-160
    80005c60:	ed06                	sd	ra,152(sp)
    80005c62:	e922                	sd	s0,144(sp)
    80005c64:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	820080e7          	jalr	-2016(ra) # 80004486 <begin_op>
  argint(1, &major);
    80005c6e:	f6c40593          	addi	a1,s0,-148
    80005c72:	4505                	li	a0,1
    80005c74:	ffffd097          	auipc	ra,0xffffd
    80005c78:	25e080e7          	jalr	606(ra) # 80002ed2 <argint>
  argint(2, &minor);
    80005c7c:	f6840593          	addi	a1,s0,-152
    80005c80:	4509                	li	a0,2
    80005c82:	ffffd097          	auipc	ra,0xffffd
    80005c86:	250080e7          	jalr	592(ra) # 80002ed2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c8a:	08000613          	li	a2,128
    80005c8e:	f7040593          	addi	a1,s0,-144
    80005c92:	4501                	li	a0,0
    80005c94:	ffffd097          	auipc	ra,0xffffd
    80005c98:	27e080e7          	jalr	638(ra) # 80002f12 <argstr>
    80005c9c:	02054b63          	bltz	a0,80005cd2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ca0:	f6841683          	lh	a3,-152(s0)
    80005ca4:	f6c41603          	lh	a2,-148(s0)
    80005ca8:	458d                	li	a1,3
    80005caa:	f7040513          	addi	a0,s0,-144
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	780080e7          	jalr	1920(ra) # 8000542e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cb6:	cd11                	beqz	a0,80005cd2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	06e080e7          	jalr	110(ra) # 80003d26 <iunlockput>
  end_op();
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	846080e7          	jalr	-1978(ra) # 80004506 <end_op>
  return 0;
    80005cc8:	4501                	li	a0,0
}
    80005cca:	60ea                	ld	ra,152(sp)
    80005ccc:	644a                	ld	s0,144(sp)
    80005cce:	610d                	addi	sp,sp,160
    80005cd0:	8082                	ret
    end_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	834080e7          	jalr	-1996(ra) # 80004506 <end_op>
    return -1;
    80005cda:	557d                	li	a0,-1
    80005cdc:	b7fd                	j	80005cca <sys_mknod+0x6c>

0000000080005cde <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cde:	7135                	addi	sp,sp,-160
    80005ce0:	ed06                	sd	ra,152(sp)
    80005ce2:	e922                	sd	s0,144(sp)
    80005ce4:	e526                	sd	s1,136(sp)
    80005ce6:	e14a                	sd	s2,128(sp)
    80005ce8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005cea:	ffffc097          	auipc	ra,0xffffc
    80005cee:	f04080e7          	jalr	-252(ra) # 80001bee <myproc>
    80005cf2:	892a                	mv	s2,a0
  
  begin_op();
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	792080e7          	jalr	1938(ra) # 80004486 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005cfc:	08000613          	li	a2,128
    80005d00:	f6040593          	addi	a1,s0,-160
    80005d04:	4501                	li	a0,0
    80005d06:	ffffd097          	auipc	ra,0xffffd
    80005d0a:	20c080e7          	jalr	524(ra) # 80002f12 <argstr>
    80005d0e:	04054b63          	bltz	a0,80005d64 <sys_chdir+0x86>
    80005d12:	f6040513          	addi	a0,s0,-160
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	554080e7          	jalr	1364(ra) # 8000426a <namei>
    80005d1e:	84aa                	mv	s1,a0
    80005d20:	c131                	beqz	a0,80005d64 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d22:	ffffe097          	auipc	ra,0xffffe
    80005d26:	da2080e7          	jalr	-606(ra) # 80003ac4 <ilock>
  if(ip->type != T_DIR){
    80005d2a:	04449703          	lh	a4,68(s1)
    80005d2e:	4785                	li	a5,1
    80005d30:	04f71063          	bne	a4,a5,80005d70 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d34:	8526                	mv	a0,s1
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	e50080e7          	jalr	-432(ra) # 80003b86 <iunlock>
  iput(p->cwd);
    80005d3e:	15093503          	ld	a0,336(s2)
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	f3c080e7          	jalr	-196(ra) # 80003c7e <iput>
  end_op();
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	7bc080e7          	jalr	1980(ra) # 80004506 <end_op>
  p->cwd = ip;
    80005d52:	14993823          	sd	s1,336(s2)
  return 0;
    80005d56:	4501                	li	a0,0
}
    80005d58:	60ea                	ld	ra,152(sp)
    80005d5a:	644a                	ld	s0,144(sp)
    80005d5c:	64aa                	ld	s1,136(sp)
    80005d5e:	690a                	ld	s2,128(sp)
    80005d60:	610d                	addi	sp,sp,160
    80005d62:	8082                	ret
    end_op();
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	7a2080e7          	jalr	1954(ra) # 80004506 <end_op>
    return -1;
    80005d6c:	557d                	li	a0,-1
    80005d6e:	b7ed                	j	80005d58 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d70:	8526                	mv	a0,s1
    80005d72:	ffffe097          	auipc	ra,0xffffe
    80005d76:	fb4080e7          	jalr	-76(ra) # 80003d26 <iunlockput>
    end_op();
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	78c080e7          	jalr	1932(ra) # 80004506 <end_op>
    return -1;
    80005d82:	557d                	li	a0,-1
    80005d84:	bfd1                	j	80005d58 <sys_chdir+0x7a>

0000000080005d86 <sys_exec>:

uint64
sys_exec(void)
{
    80005d86:	7145                	addi	sp,sp,-464
    80005d88:	e786                	sd	ra,456(sp)
    80005d8a:	e3a2                	sd	s0,448(sp)
    80005d8c:	ff26                	sd	s1,440(sp)
    80005d8e:	fb4a                	sd	s2,432(sp)
    80005d90:	f74e                	sd	s3,424(sp)
    80005d92:	f352                	sd	s4,416(sp)
    80005d94:	ef56                	sd	s5,408(sp)
    80005d96:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005d98:	e3840593          	addi	a1,s0,-456
    80005d9c:	4505                	li	a0,1
    80005d9e:	ffffd097          	auipc	ra,0xffffd
    80005da2:	154080e7          	jalr	340(ra) # 80002ef2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005da6:	08000613          	li	a2,128
    80005daa:	f4040593          	addi	a1,s0,-192
    80005dae:	4501                	li	a0,0
    80005db0:	ffffd097          	auipc	ra,0xffffd
    80005db4:	162080e7          	jalr	354(ra) # 80002f12 <argstr>
    80005db8:	87aa                	mv	a5,a0
    return -1;
    80005dba:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005dbc:	0c07c263          	bltz	a5,80005e80 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005dc0:	10000613          	li	a2,256
    80005dc4:	4581                	li	a1,0
    80005dc6:	e4040513          	addi	a0,s0,-448
    80005dca:	ffffb097          	auipc	ra,0xffffb
    80005dce:	14a080e7          	jalr	330(ra) # 80000f14 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005dd2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005dd6:	89a6                	mv	s3,s1
    80005dd8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dda:	02000a13          	li	s4,32
    80005dde:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005de2:	00391793          	slli	a5,s2,0x3
    80005de6:	e3040593          	addi	a1,s0,-464
    80005dea:	e3843503          	ld	a0,-456(s0)
    80005dee:	953e                	add	a0,a0,a5
    80005df0:	ffffd097          	auipc	ra,0xffffd
    80005df4:	044080e7          	jalr	68(ra) # 80002e34 <fetchaddr>
    80005df8:	02054a63          	bltz	a0,80005e2c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005dfc:	e3043783          	ld	a5,-464(s0)
    80005e00:	c3b9                	beqz	a5,80005e46 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e02:	ffffb097          	auipc	ra,0xffffb
    80005e06:	f26080e7          	jalr	-218(ra) # 80000d28 <kalloc>
    80005e0a:	85aa                	mv	a1,a0
    80005e0c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e10:	cd11                	beqz	a0,80005e2c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e12:	6605                	lui	a2,0x1
    80005e14:	e3043503          	ld	a0,-464(s0)
    80005e18:	ffffd097          	auipc	ra,0xffffd
    80005e1c:	06e080e7          	jalr	110(ra) # 80002e86 <fetchstr>
    80005e20:	00054663          	bltz	a0,80005e2c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e24:	0905                	addi	s2,s2,1
    80005e26:	09a1                	addi	s3,s3,8
    80005e28:	fb491be3          	bne	s2,s4,80005dde <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e2c:	10048913          	addi	s2,s1,256
    80005e30:	6088                	ld	a0,0(s1)
    80005e32:	c531                	beqz	a0,80005e7e <sys_exec+0xf8>
    kfree(argv[i]);
    80005e34:	ffffb097          	auipc	ra,0xffffb
    80005e38:	df8080e7          	jalr	-520(ra) # 80000c2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e3c:	04a1                	addi	s1,s1,8
    80005e3e:	ff2499e3          	bne	s1,s2,80005e30 <sys_exec+0xaa>
  return -1;
    80005e42:	557d                	li	a0,-1
    80005e44:	a835                	j	80005e80 <sys_exec+0xfa>
      argv[i] = 0;
    80005e46:	0a8e                	slli	s5,s5,0x3
    80005e48:	fc040793          	addi	a5,s0,-64
    80005e4c:	9abe                	add	s5,s5,a5
    80005e4e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e52:	e4040593          	addi	a1,s0,-448
    80005e56:	f4040513          	addi	a0,s0,-192
    80005e5a:	fffff097          	auipc	ra,0xfffff
    80005e5e:	172080e7          	jalr	370(ra) # 80004fcc <exec>
    80005e62:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e64:	10048993          	addi	s3,s1,256
    80005e68:	6088                	ld	a0,0(s1)
    80005e6a:	c901                	beqz	a0,80005e7a <sys_exec+0xf4>
    kfree(argv[i]);
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	dc0080e7          	jalr	-576(ra) # 80000c2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e74:	04a1                	addi	s1,s1,8
    80005e76:	ff3499e3          	bne	s1,s3,80005e68 <sys_exec+0xe2>
  return ret;
    80005e7a:	854a                	mv	a0,s2
    80005e7c:	a011                	j	80005e80 <sys_exec+0xfa>
  return -1;
    80005e7e:	557d                	li	a0,-1
}
    80005e80:	60be                	ld	ra,456(sp)
    80005e82:	641e                	ld	s0,448(sp)
    80005e84:	74fa                	ld	s1,440(sp)
    80005e86:	795a                	ld	s2,432(sp)
    80005e88:	79ba                	ld	s3,424(sp)
    80005e8a:	7a1a                	ld	s4,416(sp)
    80005e8c:	6afa                	ld	s5,408(sp)
    80005e8e:	6179                	addi	sp,sp,464
    80005e90:	8082                	ret

0000000080005e92 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e92:	7139                	addi	sp,sp,-64
    80005e94:	fc06                	sd	ra,56(sp)
    80005e96:	f822                	sd	s0,48(sp)
    80005e98:	f426                	sd	s1,40(sp)
    80005e9a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e9c:	ffffc097          	auipc	ra,0xffffc
    80005ea0:	d52080e7          	jalr	-686(ra) # 80001bee <myproc>
    80005ea4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ea6:	fd840593          	addi	a1,s0,-40
    80005eaa:	4501                	li	a0,0
    80005eac:	ffffd097          	auipc	ra,0xffffd
    80005eb0:	046080e7          	jalr	70(ra) # 80002ef2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005eb4:	fc840593          	addi	a1,s0,-56
    80005eb8:	fd040513          	addi	a0,s0,-48
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	dc6080e7          	jalr	-570(ra) # 80004c82 <pipealloc>
    return -1;
    80005ec4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ec6:	0c054463          	bltz	a0,80005f8e <sys_pipe+0xfc>
  fd0 = -1;
    80005eca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ece:	fd043503          	ld	a0,-48(s0)
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	51a080e7          	jalr	1306(ra) # 800053ec <fdalloc>
    80005eda:	fca42223          	sw	a0,-60(s0)
    80005ede:	08054b63          	bltz	a0,80005f74 <sys_pipe+0xe2>
    80005ee2:	fc843503          	ld	a0,-56(s0)
    80005ee6:	fffff097          	auipc	ra,0xfffff
    80005eea:	506080e7          	jalr	1286(ra) # 800053ec <fdalloc>
    80005eee:	fca42023          	sw	a0,-64(s0)
    80005ef2:	06054863          	bltz	a0,80005f62 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ef6:	4691                	li	a3,4
    80005ef8:	fc440613          	addi	a2,s0,-60
    80005efc:	fd843583          	ld	a1,-40(s0)
    80005f00:	68a8                	ld	a0,80(s1)
    80005f02:	ffffc097          	auipc	ra,0xffffc
    80005f06:	9a8080e7          	jalr	-1624(ra) # 800018aa <copyout>
    80005f0a:	02054063          	bltz	a0,80005f2a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f0e:	4691                	li	a3,4
    80005f10:	fc040613          	addi	a2,s0,-64
    80005f14:	fd843583          	ld	a1,-40(s0)
    80005f18:	0591                	addi	a1,a1,4
    80005f1a:	68a8                	ld	a0,80(s1)
    80005f1c:	ffffc097          	auipc	ra,0xffffc
    80005f20:	98e080e7          	jalr	-1650(ra) # 800018aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f24:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f26:	06055463          	bgez	a0,80005f8e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f2a:	fc442783          	lw	a5,-60(s0)
    80005f2e:	07e9                	addi	a5,a5,26
    80005f30:	078e                	slli	a5,a5,0x3
    80005f32:	97a6                	add	a5,a5,s1
    80005f34:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f38:	fc042503          	lw	a0,-64(s0)
    80005f3c:	0569                	addi	a0,a0,26
    80005f3e:	050e                	slli	a0,a0,0x3
    80005f40:	94aa                	add	s1,s1,a0
    80005f42:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f46:	fd043503          	ld	a0,-48(s0)
    80005f4a:	fffff097          	auipc	ra,0xfffff
    80005f4e:	a08080e7          	jalr	-1528(ra) # 80004952 <fileclose>
    fileclose(wf);
    80005f52:	fc843503          	ld	a0,-56(s0)
    80005f56:	fffff097          	auipc	ra,0xfffff
    80005f5a:	9fc080e7          	jalr	-1540(ra) # 80004952 <fileclose>
    return -1;
    80005f5e:	57fd                	li	a5,-1
    80005f60:	a03d                	j	80005f8e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005f62:	fc442783          	lw	a5,-60(s0)
    80005f66:	0007c763          	bltz	a5,80005f74 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005f6a:	07e9                	addi	a5,a5,26
    80005f6c:	078e                	slli	a5,a5,0x3
    80005f6e:	94be                	add	s1,s1,a5
    80005f70:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f74:	fd043503          	ld	a0,-48(s0)
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	9da080e7          	jalr	-1574(ra) # 80004952 <fileclose>
    fileclose(wf);
    80005f80:	fc843503          	ld	a0,-56(s0)
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	9ce080e7          	jalr	-1586(ra) # 80004952 <fileclose>
    return -1;
    80005f8c:	57fd                	li	a5,-1
}
    80005f8e:	853e                	mv	a0,a5
    80005f90:	70e2                	ld	ra,56(sp)
    80005f92:	7442                	ld	s0,48(sp)
    80005f94:	74a2                	ld	s1,40(sp)
    80005f96:	6121                	addi	sp,sp,64
    80005f98:	8082                	ret
    80005f9a:	0000                	unimp
    80005f9c:	0000                	unimp
	...

0000000080005fa0 <kernelvec>:
    80005fa0:	7111                	addi	sp,sp,-256
    80005fa2:	e006                	sd	ra,0(sp)
    80005fa4:	e40a                	sd	sp,8(sp)
    80005fa6:	e80e                	sd	gp,16(sp)
    80005fa8:	ec12                	sd	tp,24(sp)
    80005faa:	f016                	sd	t0,32(sp)
    80005fac:	f41a                	sd	t1,40(sp)
    80005fae:	f81e                	sd	t2,48(sp)
    80005fb0:	fc22                	sd	s0,56(sp)
    80005fb2:	e0a6                	sd	s1,64(sp)
    80005fb4:	e4aa                	sd	a0,72(sp)
    80005fb6:	e8ae                	sd	a1,80(sp)
    80005fb8:	ecb2                	sd	a2,88(sp)
    80005fba:	f0b6                	sd	a3,96(sp)
    80005fbc:	f4ba                	sd	a4,104(sp)
    80005fbe:	f8be                	sd	a5,112(sp)
    80005fc0:	fcc2                	sd	a6,120(sp)
    80005fc2:	e146                	sd	a7,128(sp)
    80005fc4:	e54a                	sd	s2,136(sp)
    80005fc6:	e94e                	sd	s3,144(sp)
    80005fc8:	ed52                	sd	s4,152(sp)
    80005fca:	f156                	sd	s5,160(sp)
    80005fcc:	f55a                	sd	s6,168(sp)
    80005fce:	f95e                	sd	s7,176(sp)
    80005fd0:	fd62                	sd	s8,184(sp)
    80005fd2:	e1e6                	sd	s9,192(sp)
    80005fd4:	e5ea                	sd	s10,200(sp)
    80005fd6:	e9ee                	sd	s11,208(sp)
    80005fd8:	edf2                	sd	t3,216(sp)
    80005fda:	f1f6                	sd	t4,224(sp)
    80005fdc:	f5fa                	sd	t5,232(sp)
    80005fde:	f9fe                	sd	t6,240(sp)
    80005fe0:	d21fc0ef          	jal	ra,80002d00 <kerneltrap>
    80005fe4:	6082                	ld	ra,0(sp)
    80005fe6:	6122                	ld	sp,8(sp)
    80005fe8:	61c2                	ld	gp,16(sp)
    80005fea:	7282                	ld	t0,32(sp)
    80005fec:	7322                	ld	t1,40(sp)
    80005fee:	73c2                	ld	t2,48(sp)
    80005ff0:	7462                	ld	s0,56(sp)
    80005ff2:	6486                	ld	s1,64(sp)
    80005ff4:	6526                	ld	a0,72(sp)
    80005ff6:	65c6                	ld	a1,80(sp)
    80005ff8:	6666                	ld	a2,88(sp)
    80005ffa:	7686                	ld	a3,96(sp)
    80005ffc:	7726                	ld	a4,104(sp)
    80005ffe:	77c6                	ld	a5,112(sp)
    80006000:	7866                	ld	a6,120(sp)
    80006002:	688a                	ld	a7,128(sp)
    80006004:	692a                	ld	s2,136(sp)
    80006006:	69ca                	ld	s3,144(sp)
    80006008:	6a6a                	ld	s4,152(sp)
    8000600a:	7a8a                	ld	s5,160(sp)
    8000600c:	7b2a                	ld	s6,168(sp)
    8000600e:	7bca                	ld	s7,176(sp)
    80006010:	7c6a                	ld	s8,184(sp)
    80006012:	6c8e                	ld	s9,192(sp)
    80006014:	6d2e                	ld	s10,200(sp)
    80006016:	6dce                	ld	s11,208(sp)
    80006018:	6e6e                	ld	t3,216(sp)
    8000601a:	7e8e                	ld	t4,224(sp)
    8000601c:	7f2e                	ld	t5,232(sp)
    8000601e:	7fce                	ld	t6,240(sp)
    80006020:	6111                	addi	sp,sp,256
    80006022:	10200073          	sret
    80006026:	00000013          	nop
    8000602a:	00000013          	nop
    8000602e:	0001                	nop

0000000080006030 <timervec>:
    80006030:	34051573          	csrrw	a0,mscratch,a0
    80006034:	e10c                	sd	a1,0(a0)
    80006036:	e510                	sd	a2,8(a0)
    80006038:	e914                	sd	a3,16(a0)
    8000603a:	6d0c                	ld	a1,24(a0)
    8000603c:	7110                	ld	a2,32(a0)
    8000603e:	6194                	ld	a3,0(a1)
    80006040:	96b2                	add	a3,a3,a2
    80006042:	e194                	sd	a3,0(a1)
    80006044:	4589                	li	a1,2
    80006046:	14459073          	csrw	sip,a1
    8000604a:	6914                	ld	a3,16(a0)
    8000604c:	6510                	ld	a2,8(a0)
    8000604e:	610c                	ld	a1,0(a0)
    80006050:	34051573          	csrrw	a0,mscratch,a0
    80006054:	30200073          	mret
	...

000000008000605a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000605a:	1141                	addi	sp,sp,-16
    8000605c:	e422                	sd	s0,8(sp)
    8000605e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006060:	0c0007b7          	lui	a5,0xc000
    80006064:	4705                	li	a4,1
    80006066:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006068:	c3d8                	sw	a4,4(a5)
}
    8000606a:	6422                	ld	s0,8(sp)
    8000606c:	0141                	addi	sp,sp,16
    8000606e:	8082                	ret

0000000080006070 <plicinithart>:

void
plicinithart(void)
{
    80006070:	1141                	addi	sp,sp,-16
    80006072:	e406                	sd	ra,8(sp)
    80006074:	e022                	sd	s0,0(sp)
    80006076:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	b4a080e7          	jalr	-1206(ra) # 80001bc2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006080:	0085171b          	slliw	a4,a0,0x8
    80006084:	0c0027b7          	lui	a5,0xc002
    80006088:	97ba                	add	a5,a5,a4
    8000608a:	40200713          	li	a4,1026
    8000608e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006092:	00d5151b          	slliw	a0,a0,0xd
    80006096:	0c2017b7          	lui	a5,0xc201
    8000609a:	953e                	add	a0,a0,a5
    8000609c:	00052023          	sw	zero,0(a0)
}
    800060a0:	60a2                	ld	ra,8(sp)
    800060a2:	6402                	ld	s0,0(sp)
    800060a4:	0141                	addi	sp,sp,16
    800060a6:	8082                	ret

00000000800060a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060a8:	1141                	addi	sp,sp,-16
    800060aa:	e406                	sd	ra,8(sp)
    800060ac:	e022                	sd	s0,0(sp)
    800060ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060b0:	ffffc097          	auipc	ra,0xffffc
    800060b4:	b12080e7          	jalr	-1262(ra) # 80001bc2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060b8:	00d5179b          	slliw	a5,a0,0xd
    800060bc:	0c201537          	lui	a0,0xc201
    800060c0:	953e                	add	a0,a0,a5
  return irq;
}
    800060c2:	4148                	lw	a0,4(a0)
    800060c4:	60a2                	ld	ra,8(sp)
    800060c6:	6402                	ld	s0,0(sp)
    800060c8:	0141                	addi	sp,sp,16
    800060ca:	8082                	ret

00000000800060cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060cc:	1101                	addi	sp,sp,-32
    800060ce:	ec06                	sd	ra,24(sp)
    800060d0:	e822                	sd	s0,16(sp)
    800060d2:	e426                	sd	s1,8(sp)
    800060d4:	1000                	addi	s0,sp,32
    800060d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	aea080e7          	jalr	-1302(ra) # 80001bc2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060e0:	00d5151b          	slliw	a0,a0,0xd
    800060e4:	0c2017b7          	lui	a5,0xc201
    800060e8:	97aa                	add	a5,a5,a0
    800060ea:	c3c4                	sw	s1,4(a5)
}
    800060ec:	60e2                	ld	ra,24(sp)
    800060ee:	6442                	ld	s0,16(sp)
    800060f0:	64a2                	ld	s1,8(sp)
    800060f2:	6105                	addi	sp,sp,32
    800060f4:	8082                	ret

00000000800060f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060f6:	1141                	addi	sp,sp,-16
    800060f8:	e406                	sd	ra,8(sp)
    800060fa:	e022                	sd	s0,0(sp)
    800060fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060fe:	479d                	li	a5,7
    80006100:	04a7cc63          	blt	a5,a0,80006158 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006104:	0001d797          	auipc	a5,0x1d
    80006108:	c0478793          	addi	a5,a5,-1020 # 80022d08 <disk>
    8000610c:	97aa                	add	a5,a5,a0
    8000610e:	0187c783          	lbu	a5,24(a5)
    80006112:	ebb9                	bnez	a5,80006168 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006114:	00451613          	slli	a2,a0,0x4
    80006118:	0001d797          	auipc	a5,0x1d
    8000611c:	bf078793          	addi	a5,a5,-1040 # 80022d08 <disk>
    80006120:	6394                	ld	a3,0(a5)
    80006122:	96b2                	add	a3,a3,a2
    80006124:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006128:	6398                	ld	a4,0(a5)
    8000612a:	9732                	add	a4,a4,a2
    8000612c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006130:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006134:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006138:	953e                	add	a0,a0,a5
    8000613a:	4785                	li	a5,1
    8000613c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006140:	0001d517          	auipc	a0,0x1d
    80006144:	be050513          	addi	a0,a0,-1056 # 80022d20 <disk+0x18>
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	1b2080e7          	jalr	434(ra) # 800022fa <wakeup>
}
    80006150:	60a2                	ld	ra,8(sp)
    80006152:	6402                	ld	s0,0(sp)
    80006154:	0141                	addi	sp,sp,16
    80006156:	8082                	ret
    panic("free_desc 1");
    80006158:	00002517          	auipc	a0,0x2
    8000615c:	6d050513          	addi	a0,a0,1744 # 80008828 <syscalls+0x300>
    80006160:	ffffa097          	auipc	ra,0xffffa
    80006164:	620080e7          	jalr	1568(ra) # 80000780 <panic>
    panic("free_desc 2");
    80006168:	00002517          	auipc	a0,0x2
    8000616c:	6d050513          	addi	a0,a0,1744 # 80008838 <syscalls+0x310>
    80006170:	ffffa097          	auipc	ra,0xffffa
    80006174:	610080e7          	jalr	1552(ra) # 80000780 <panic>

0000000080006178 <virtio_disk_init>:
{
    80006178:	1101                	addi	sp,sp,-32
    8000617a:	ec06                	sd	ra,24(sp)
    8000617c:	e822                	sd	s0,16(sp)
    8000617e:	e426                	sd	s1,8(sp)
    80006180:	e04a                	sd	s2,0(sp)
    80006182:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006184:	00002597          	auipc	a1,0x2
    80006188:	6c458593          	addi	a1,a1,1732 # 80008848 <syscalls+0x320>
    8000618c:	0001d517          	auipc	a0,0x1d
    80006190:	ca450513          	addi	a0,a0,-860 # 80022e30 <disk+0x128>
    80006194:	ffffb097          	auipc	ra,0xffffb
    80006198:	bf4080e7          	jalr	-1036(ra) # 80000d88 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000619c:	100017b7          	lui	a5,0x10001
    800061a0:	4398                	lw	a4,0(a5)
    800061a2:	2701                	sext.w	a4,a4
    800061a4:	747277b7          	lui	a5,0x74727
    800061a8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061ac:	14f71c63          	bne	a4,a5,80006304 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061b0:	100017b7          	lui	a5,0x10001
    800061b4:	43dc                	lw	a5,4(a5)
    800061b6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061b8:	4709                	li	a4,2
    800061ba:	14e79563          	bne	a5,a4,80006304 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061be:	100017b7          	lui	a5,0x10001
    800061c2:	479c                	lw	a5,8(a5)
    800061c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061c6:	12e79f63          	bne	a5,a4,80006304 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061ca:	100017b7          	lui	a5,0x10001
    800061ce:	47d8                	lw	a4,12(a5)
    800061d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061d2:	554d47b7          	lui	a5,0x554d4
    800061d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061da:	12f71563          	bne	a4,a5,80006304 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061de:	100017b7          	lui	a5,0x10001
    800061e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e6:	4705                	li	a4,1
    800061e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061ea:	470d                	li	a4,3
    800061ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061ee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061f0:	c7ffe737          	lui	a4,0xc7ffe
    800061f4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb917>
    800061f8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061fa:	2701                	sext.w	a4,a4
    800061fc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061fe:	472d                	li	a4,11
    80006200:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006202:	5bbc                	lw	a5,112(a5)
    80006204:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006208:	8ba1                	andi	a5,a5,8
    8000620a:	10078563          	beqz	a5,80006314 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000620e:	100017b7          	lui	a5,0x10001
    80006212:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006216:	43fc                	lw	a5,68(a5)
    80006218:	2781                	sext.w	a5,a5
    8000621a:	10079563          	bnez	a5,80006324 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000621e:	100017b7          	lui	a5,0x10001
    80006222:	5bdc                	lw	a5,52(a5)
    80006224:	2781                	sext.w	a5,a5
  if(max == 0)
    80006226:	10078763          	beqz	a5,80006334 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000622a:	471d                	li	a4,7
    8000622c:	10f77c63          	bgeu	a4,a5,80006344 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006230:	ffffb097          	auipc	ra,0xffffb
    80006234:	af8080e7          	jalr	-1288(ra) # 80000d28 <kalloc>
    80006238:	0001d497          	auipc	s1,0x1d
    8000623c:	ad048493          	addi	s1,s1,-1328 # 80022d08 <disk>
    80006240:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006242:	ffffb097          	auipc	ra,0xffffb
    80006246:	ae6080e7          	jalr	-1306(ra) # 80000d28 <kalloc>
    8000624a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000624c:	ffffb097          	auipc	ra,0xffffb
    80006250:	adc080e7          	jalr	-1316(ra) # 80000d28 <kalloc>
    80006254:	87aa                	mv	a5,a0
    80006256:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006258:	6088                	ld	a0,0(s1)
    8000625a:	cd6d                	beqz	a0,80006354 <virtio_disk_init+0x1dc>
    8000625c:	0001d717          	auipc	a4,0x1d
    80006260:	ab473703          	ld	a4,-1356(a4) # 80022d10 <disk+0x8>
    80006264:	cb65                	beqz	a4,80006354 <virtio_disk_init+0x1dc>
    80006266:	c7fd                	beqz	a5,80006354 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006268:	6605                	lui	a2,0x1
    8000626a:	4581                	li	a1,0
    8000626c:	ffffb097          	auipc	ra,0xffffb
    80006270:	ca8080e7          	jalr	-856(ra) # 80000f14 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006274:	0001d497          	auipc	s1,0x1d
    80006278:	a9448493          	addi	s1,s1,-1388 # 80022d08 <disk>
    8000627c:	6605                	lui	a2,0x1
    8000627e:	4581                	li	a1,0
    80006280:	6488                	ld	a0,8(s1)
    80006282:	ffffb097          	auipc	ra,0xffffb
    80006286:	c92080e7          	jalr	-878(ra) # 80000f14 <memset>
  memset(disk.used, 0, PGSIZE);
    8000628a:	6605                	lui	a2,0x1
    8000628c:	4581                	li	a1,0
    8000628e:	6888                	ld	a0,16(s1)
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	c84080e7          	jalr	-892(ra) # 80000f14 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006298:	100017b7          	lui	a5,0x10001
    8000629c:	4721                	li	a4,8
    8000629e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800062a0:	4098                	lw	a4,0(s1)
    800062a2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800062a6:	40d8                	lw	a4,4(s1)
    800062a8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800062ac:	6498                	ld	a4,8(s1)
    800062ae:	0007069b          	sext.w	a3,a4
    800062b2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800062b6:	9701                	srai	a4,a4,0x20
    800062b8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800062bc:	6898                	ld	a4,16(s1)
    800062be:	0007069b          	sext.w	a3,a4
    800062c2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800062c6:	9701                	srai	a4,a4,0x20
    800062c8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800062cc:	4705                	li	a4,1
    800062ce:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800062d0:	00e48c23          	sb	a4,24(s1)
    800062d4:	00e48ca3          	sb	a4,25(s1)
    800062d8:	00e48d23          	sb	a4,26(s1)
    800062dc:	00e48da3          	sb	a4,27(s1)
    800062e0:	00e48e23          	sb	a4,28(s1)
    800062e4:	00e48ea3          	sb	a4,29(s1)
    800062e8:	00e48f23          	sb	a4,30(s1)
    800062ec:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800062f0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f4:	0727a823          	sw	s2,112(a5)
}
    800062f8:	60e2                	ld	ra,24(sp)
    800062fa:	6442                	ld	s0,16(sp)
    800062fc:	64a2                	ld	s1,8(sp)
    800062fe:	6902                	ld	s2,0(sp)
    80006300:	6105                	addi	sp,sp,32
    80006302:	8082                	ret
    panic("could not find virtio disk");
    80006304:	00002517          	auipc	a0,0x2
    80006308:	55450513          	addi	a0,a0,1364 # 80008858 <syscalls+0x330>
    8000630c:	ffffa097          	auipc	ra,0xffffa
    80006310:	474080e7          	jalr	1140(ra) # 80000780 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006314:	00002517          	auipc	a0,0x2
    80006318:	56450513          	addi	a0,a0,1380 # 80008878 <syscalls+0x350>
    8000631c:	ffffa097          	auipc	ra,0xffffa
    80006320:	464080e7          	jalr	1124(ra) # 80000780 <panic>
    panic("virtio disk should not be ready");
    80006324:	00002517          	auipc	a0,0x2
    80006328:	57450513          	addi	a0,a0,1396 # 80008898 <syscalls+0x370>
    8000632c:	ffffa097          	auipc	ra,0xffffa
    80006330:	454080e7          	jalr	1108(ra) # 80000780 <panic>
    panic("virtio disk has no queue 0");
    80006334:	00002517          	auipc	a0,0x2
    80006338:	58450513          	addi	a0,a0,1412 # 800088b8 <syscalls+0x390>
    8000633c:	ffffa097          	auipc	ra,0xffffa
    80006340:	444080e7          	jalr	1092(ra) # 80000780 <panic>
    panic("virtio disk max queue too short");
    80006344:	00002517          	auipc	a0,0x2
    80006348:	59450513          	addi	a0,a0,1428 # 800088d8 <syscalls+0x3b0>
    8000634c:	ffffa097          	auipc	ra,0xffffa
    80006350:	434080e7          	jalr	1076(ra) # 80000780 <panic>
    panic("virtio disk kalloc");
    80006354:	00002517          	auipc	a0,0x2
    80006358:	5a450513          	addi	a0,a0,1444 # 800088f8 <syscalls+0x3d0>
    8000635c:	ffffa097          	auipc	ra,0xffffa
    80006360:	424080e7          	jalr	1060(ra) # 80000780 <panic>

0000000080006364 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006364:	7119                	addi	sp,sp,-128
    80006366:	fc86                	sd	ra,120(sp)
    80006368:	f8a2                	sd	s0,112(sp)
    8000636a:	f4a6                	sd	s1,104(sp)
    8000636c:	f0ca                	sd	s2,96(sp)
    8000636e:	ecce                	sd	s3,88(sp)
    80006370:	e8d2                	sd	s4,80(sp)
    80006372:	e4d6                	sd	s5,72(sp)
    80006374:	e0da                	sd	s6,64(sp)
    80006376:	fc5e                	sd	s7,56(sp)
    80006378:	f862                	sd	s8,48(sp)
    8000637a:	f466                	sd	s9,40(sp)
    8000637c:	f06a                	sd	s10,32(sp)
    8000637e:	ec6e                	sd	s11,24(sp)
    80006380:	0100                	addi	s0,sp,128
    80006382:	8aaa                	mv	s5,a0
    80006384:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006386:	00c52d03          	lw	s10,12(a0)
    8000638a:	001d1d1b          	slliw	s10,s10,0x1
    8000638e:	1d02                	slli	s10,s10,0x20
    80006390:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006394:	0001d517          	auipc	a0,0x1d
    80006398:	a9c50513          	addi	a0,a0,-1380 # 80022e30 <disk+0x128>
    8000639c:	ffffb097          	auipc	ra,0xffffb
    800063a0:	a7c080e7          	jalr	-1412(ra) # 80000e18 <acquire>
  for(int i = 0; i < 3; i++){
    800063a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063a6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063a8:	0001db97          	auipc	s7,0x1d
    800063ac:	960b8b93          	addi	s7,s7,-1696 # 80022d08 <disk>
  for(int i = 0; i < 3; i++){
    800063b0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063b2:	0001dc97          	auipc	s9,0x1d
    800063b6:	a7ec8c93          	addi	s9,s9,-1410 # 80022e30 <disk+0x128>
    800063ba:	a08d                	j	8000641c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800063bc:	00fb8733          	add	a4,s7,a5
    800063c0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800063c4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800063c6:	0207c563          	bltz	a5,800063f0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800063ca:	2905                	addiw	s2,s2,1
    800063cc:	0611                	addi	a2,a2,4
    800063ce:	05690c63          	beq	s2,s6,80006426 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800063d2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800063d4:	0001d717          	auipc	a4,0x1d
    800063d8:	93470713          	addi	a4,a4,-1740 # 80022d08 <disk>
    800063dc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800063de:	01874683          	lbu	a3,24(a4)
    800063e2:	fee9                	bnez	a3,800063bc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800063e4:	2785                	addiw	a5,a5,1
    800063e6:	0705                	addi	a4,a4,1
    800063e8:	fe979be3          	bne	a5,s1,800063de <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800063ec:	57fd                	li	a5,-1
    800063ee:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800063f0:	01205d63          	blez	s2,8000640a <virtio_disk_rw+0xa6>
    800063f4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800063f6:	000a2503          	lw	a0,0(s4)
    800063fa:	00000097          	auipc	ra,0x0
    800063fe:	cfc080e7          	jalr	-772(ra) # 800060f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006402:	2d85                	addiw	s11,s11,1
    80006404:	0a11                	addi	s4,s4,4
    80006406:	ffb918e3          	bne	s2,s11,800063f6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000640a:	85e6                	mv	a1,s9
    8000640c:	0001d517          	auipc	a0,0x1d
    80006410:	91450513          	addi	a0,a0,-1772 # 80022d20 <disk+0x18>
    80006414:	ffffc097          	auipc	ra,0xffffc
    80006418:	e82080e7          	jalr	-382(ra) # 80002296 <sleep>
  for(int i = 0; i < 3; i++){
    8000641c:	f8040a13          	addi	s4,s0,-128
{
    80006420:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006422:	894e                	mv	s2,s3
    80006424:	b77d                	j	800063d2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006426:	f8042583          	lw	a1,-128(s0)
    8000642a:	00a58793          	addi	a5,a1,10
    8000642e:	0792                	slli	a5,a5,0x4

  if(write)
    80006430:	0001d617          	auipc	a2,0x1d
    80006434:	8d860613          	addi	a2,a2,-1832 # 80022d08 <disk>
    80006438:	00f60733          	add	a4,a2,a5
    8000643c:	018036b3          	snez	a3,s8
    80006440:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006442:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006446:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000644a:	f6078693          	addi	a3,a5,-160
    8000644e:	6218                	ld	a4,0(a2)
    80006450:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006452:	00878513          	addi	a0,a5,8
    80006456:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006458:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000645a:	6208                	ld	a0,0(a2)
    8000645c:	96aa                	add	a3,a3,a0
    8000645e:	4741                	li	a4,16
    80006460:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006462:	4705                	li	a4,1
    80006464:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006468:	f8442703          	lw	a4,-124(s0)
    8000646c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006470:	0712                	slli	a4,a4,0x4
    80006472:	953a                	add	a0,a0,a4
    80006474:	058a8693          	addi	a3,s5,88
    80006478:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000647a:	6208                	ld	a0,0(a2)
    8000647c:	972a                	add	a4,a4,a0
    8000647e:	40000693          	li	a3,1024
    80006482:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006484:	001c3c13          	seqz	s8,s8
    80006488:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000648a:	001c6c13          	ori	s8,s8,1
    8000648e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006492:	f8842603          	lw	a2,-120(s0)
    80006496:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000649a:	0001d697          	auipc	a3,0x1d
    8000649e:	86e68693          	addi	a3,a3,-1938 # 80022d08 <disk>
    800064a2:	00258713          	addi	a4,a1,2
    800064a6:	0712                	slli	a4,a4,0x4
    800064a8:	9736                	add	a4,a4,a3
    800064aa:	587d                	li	a6,-1
    800064ac:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064b0:	0612                	slli	a2,a2,0x4
    800064b2:	9532                	add	a0,a0,a2
    800064b4:	f9078793          	addi	a5,a5,-112
    800064b8:	97b6                	add	a5,a5,a3
    800064ba:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800064bc:	629c                	ld	a5,0(a3)
    800064be:	97b2                	add	a5,a5,a2
    800064c0:	4605                	li	a2,1
    800064c2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064c4:	4509                	li	a0,2
    800064c6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800064ca:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064ce:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800064d2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064d6:	6698                	ld	a4,8(a3)
    800064d8:	00275783          	lhu	a5,2(a4)
    800064dc:	8b9d                	andi	a5,a5,7
    800064de:	0786                	slli	a5,a5,0x1
    800064e0:	97ba                	add	a5,a5,a4
    800064e2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800064e6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064ea:	6698                	ld	a4,8(a3)
    800064ec:	00275783          	lhu	a5,2(a4)
    800064f0:	2785                	addiw	a5,a5,1
    800064f2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064f6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064fa:	100017b7          	lui	a5,0x10001
    800064fe:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006502:	004aa783          	lw	a5,4(s5)
    80006506:	02c79163          	bne	a5,a2,80006528 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000650a:	0001d917          	auipc	s2,0x1d
    8000650e:	92690913          	addi	s2,s2,-1754 # 80022e30 <disk+0x128>
  while(b->disk == 1) {
    80006512:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006514:	85ca                	mv	a1,s2
    80006516:	8556                	mv	a0,s5
    80006518:	ffffc097          	auipc	ra,0xffffc
    8000651c:	d7e080e7          	jalr	-642(ra) # 80002296 <sleep>
  while(b->disk == 1) {
    80006520:	004aa783          	lw	a5,4(s5)
    80006524:	fe9788e3          	beq	a5,s1,80006514 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006528:	f8042903          	lw	s2,-128(s0)
    8000652c:	00290793          	addi	a5,s2,2
    80006530:	00479713          	slli	a4,a5,0x4
    80006534:	0001c797          	auipc	a5,0x1c
    80006538:	7d478793          	addi	a5,a5,2004 # 80022d08 <disk>
    8000653c:	97ba                	add	a5,a5,a4
    8000653e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006542:	0001c997          	auipc	s3,0x1c
    80006546:	7c698993          	addi	s3,s3,1990 # 80022d08 <disk>
    8000654a:	00491713          	slli	a4,s2,0x4
    8000654e:	0009b783          	ld	a5,0(s3)
    80006552:	97ba                	add	a5,a5,a4
    80006554:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006558:	854a                	mv	a0,s2
    8000655a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000655e:	00000097          	auipc	ra,0x0
    80006562:	b98080e7          	jalr	-1128(ra) # 800060f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006566:	8885                	andi	s1,s1,1
    80006568:	f0ed                	bnez	s1,8000654a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000656a:	0001d517          	auipc	a0,0x1d
    8000656e:	8c650513          	addi	a0,a0,-1850 # 80022e30 <disk+0x128>
    80006572:	ffffb097          	auipc	ra,0xffffb
    80006576:	95a080e7          	jalr	-1702(ra) # 80000ecc <release>
}
    8000657a:	70e6                	ld	ra,120(sp)
    8000657c:	7446                	ld	s0,112(sp)
    8000657e:	74a6                	ld	s1,104(sp)
    80006580:	7906                	ld	s2,96(sp)
    80006582:	69e6                	ld	s3,88(sp)
    80006584:	6a46                	ld	s4,80(sp)
    80006586:	6aa6                	ld	s5,72(sp)
    80006588:	6b06                	ld	s6,64(sp)
    8000658a:	7be2                	ld	s7,56(sp)
    8000658c:	7c42                	ld	s8,48(sp)
    8000658e:	7ca2                	ld	s9,40(sp)
    80006590:	7d02                	ld	s10,32(sp)
    80006592:	6de2                	ld	s11,24(sp)
    80006594:	6109                	addi	sp,sp,128
    80006596:	8082                	ret

0000000080006598 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006598:	1101                	addi	sp,sp,-32
    8000659a:	ec06                	sd	ra,24(sp)
    8000659c:	e822                	sd	s0,16(sp)
    8000659e:	e426                	sd	s1,8(sp)
    800065a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065a2:	0001c497          	auipc	s1,0x1c
    800065a6:	76648493          	addi	s1,s1,1894 # 80022d08 <disk>
    800065aa:	0001d517          	auipc	a0,0x1d
    800065ae:	88650513          	addi	a0,a0,-1914 # 80022e30 <disk+0x128>
    800065b2:	ffffb097          	auipc	ra,0xffffb
    800065b6:	866080e7          	jalr	-1946(ra) # 80000e18 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065ba:	10001737          	lui	a4,0x10001
    800065be:	533c                	lw	a5,96(a4)
    800065c0:	8b8d                	andi	a5,a5,3
    800065c2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065c4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065c8:	689c                	ld	a5,16(s1)
    800065ca:	0204d703          	lhu	a4,32(s1)
    800065ce:	0027d783          	lhu	a5,2(a5)
    800065d2:	04f70863          	beq	a4,a5,80006622 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800065d6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065da:	6898                	ld	a4,16(s1)
    800065dc:	0204d783          	lhu	a5,32(s1)
    800065e0:	8b9d                	andi	a5,a5,7
    800065e2:	078e                	slli	a5,a5,0x3
    800065e4:	97ba                	add	a5,a5,a4
    800065e6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065e8:	00278713          	addi	a4,a5,2
    800065ec:	0712                	slli	a4,a4,0x4
    800065ee:	9726                	add	a4,a4,s1
    800065f0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800065f4:	e721                	bnez	a4,8000663c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065f6:	0789                	addi	a5,a5,2
    800065f8:	0792                	slli	a5,a5,0x4
    800065fa:	97a6                	add	a5,a5,s1
    800065fc:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800065fe:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006602:	ffffc097          	auipc	ra,0xffffc
    80006606:	cf8080e7          	jalr	-776(ra) # 800022fa <wakeup>

    disk.used_idx += 1;
    8000660a:	0204d783          	lhu	a5,32(s1)
    8000660e:	2785                	addiw	a5,a5,1
    80006610:	17c2                	slli	a5,a5,0x30
    80006612:	93c1                	srli	a5,a5,0x30
    80006614:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006618:	6898                	ld	a4,16(s1)
    8000661a:	00275703          	lhu	a4,2(a4)
    8000661e:	faf71ce3          	bne	a4,a5,800065d6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006622:	0001d517          	auipc	a0,0x1d
    80006626:	80e50513          	addi	a0,a0,-2034 # 80022e30 <disk+0x128>
    8000662a:	ffffb097          	auipc	ra,0xffffb
    8000662e:	8a2080e7          	jalr	-1886(ra) # 80000ecc <release>
}
    80006632:	60e2                	ld	ra,24(sp)
    80006634:	6442                	ld	s0,16(sp)
    80006636:	64a2                	ld	s1,8(sp)
    80006638:	6105                	addi	sp,sp,32
    8000663a:	8082                	ret
      panic("virtio_disk_intr status");
    8000663c:	00002517          	auipc	a0,0x2
    80006640:	2d450513          	addi	a0,a0,724 # 80008910 <syscalls+0x3e8>
    80006644:	ffffa097          	auipc	ra,0xffffa
    80006648:	13c080e7          	jalr	316(ra) # 80000780 <panic>
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
