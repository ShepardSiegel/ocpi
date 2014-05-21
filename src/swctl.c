#include <sys/mman.h>
#include <sys/time.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stddef.h>
typedef struct {
  uint32_t 
    Open,
    CPI,
    revision,
    birthday,
    workerMask,
    pci_id,
    attention,
    cpStatus,
    scratch20,
    scratch24,
    cpControl,
    rsvd2C,
    timeStatus,
    timeControl,
    gpsTimeMS,
    gpsTimeLS,
    deltaTimeMS,
    deltaTimeLS,
    refPerPPS,
    buf4C,
    dnaLS, dnaMS,
    buf58,buf5C,
    buf60,buf64,buf68,buf6C,
    buf70,buf74,buf78,
    numDPMemRegions,
    dpInfo[16],
    uuid[16];
} OCCP_Admin;

typedef struct {
  uint32_t
    initialize,
    start,
    stop,
    release,
    test,
    before_query,
    after_config,
    reserved7,
    status,
    control,
    config_addr,
    stickyClear,
    pageWindow,
    pad[3];
} OCCP_WorkerControl;

typedef struct {
  uint32_t
    bar,      // The PCIe BAR this memory belongs to
    offset,   // The Offset into the BAR in 4KB pages
    size;     // The Size of the BAR in 4KB pages
 } OCDPMemRegionDescriptor;

#define OCCP_WORKER_CONFIG_SIZE (1<<20)
#define OCCP_WORKER_CONTROL_SIZE (1<<16)
#define OCCP_NWORKERS 15

typedef struct {
  OCCP_WorkerControl wc;
  uint8_t pad[OCCP_WORKER_CONTROL_SIZE - sizeof(OCCP_WorkerControl)];
} OCCP_WorkerControlSpace;

typedef struct {
  OCCP_Admin admin;
  uint8_t pad[OCCP_WORKER_CONTROL_SIZE - sizeof(OCCP_Admin)];
  OCCP_WorkerControlSpace control[OCCP_NWORKERS];
  uint8_t config[OCCP_NWORKERS][OCCP_WORKER_CONFIG_SIZE];
} OCCP_Space;

typedef struct {
  uint32_t
    start, // write to cause event, indicating start of movement, data not used
    done,  // movement done event, data not used
    remoteAvailable, // a remote buffer has become available EVENT, data not used
    scratch,
    ready, // a transfer can be started BOOL, LSBit
    remoteCurrent; // if a transfer is in progress (between start and done) this is the remote buffer ordinal that is active.  if no transfer in progress (outside of start->done), it is the buffer that will be used by "start".
} OCDP_Control;
typedef struct {
  uint32_t
    length,
    opcode,
    counter,
    deltaClks;
} OCDP_Meta;

#define OCDP_SIZE (32*1024)
#define OCDP_NBUFFERS 4
#define OCDP_BUFFER_SIZE (2*1024)
#define OCDP_BUFFER_SPACE_SIZE (OCDP_BUFFER_SIZE*OCDP_NBUFFERS)
#define OCDP_META_SIZE (8*1024)
#define OCDP_MESSAGE_SIZE 16
typedef struct {
  uint8_t buffers[OCDP_BUFFER_SPACE_SIZE];
  OCDP_Meta meta[4];
  uint8_t pad0[OCDP_META_SIZE - sizeof(OCDP_Meta)*4];
  OCDP_Control control;
  uint8_t pad1[OCDP_SIZE - OCDP_BUFFER_SPACE_SIZE - OCDP_META_SIZE - sizeof(OCDP_Control)];
} OCDP_Space;


typedef int func(volatile OCCP_Space *, char **, volatile OCCP_WorkerControl *, volatile uint8_t *, volatile OCDP_Space *);
static func admin, wdump, wread, wwrite, wadmin, radmin, wadmin64, radmin64, settime, deltatime, wop, wwctl, wwpage, dtest, smtest, dmeta, dpnd, dread, dwrite, wunreset, wreset, mwpost;

typedef struct {
  char *name;
  func *command;
  int   worker;
} OCCP_Command;

static OCCP_Command commands[] = {
  {"admin", admin},	         // dump admin
  {"wdump", wdump, 1},       // dump worker controls
  {"wread", wread, 1},       // read worker config
  {"wwrite", wwrite, 1},     // write worker config
  {"wadmin", wadmin},        // write admin space
  {"radmin", radmin},        // read  admin space
  {"wadmin64", wadmin64},    // write admin space 64b
  {"radmin64", radmin64},    // read  admin space 64b
  {"settime", settime},      // set the FPGA to system time
  {"deltatime", deltatime},  // Measure the difference of FPGA-Host (+ means FPGA leading)
  {"wop", wop, 1},           // do control op
  {"wwctl", wwctl, 1},       // write worker control register
  {"wwpage", wwpage, 1},     // write worker pageWindow register
  {"dtest", dtest, 1},       // Perform test on data memory
  {"smtest", smtest, 1},     // Perform test on SelectMAP ICAP 
  {"dmeta", dmeta},          // Dump metadata
  {"dpnd", dpnd},            // Pull without copying data
  {"dread", dread},          // Dump some data plane
  {"dwrite", dwrite},        // Write some data plane
  {"wunreset", wunreset, 1}, // deassert reset for worker
  {"wreset", wreset, 1},     // assert reset for worker
  {"mwpost", mwpost},        // meassure write post rate
  {0}
};

typedef struct {
  char *name;     // From table 6-26 in UG360 (v3.1)
  int address;    // 5b to fill Type 1 packet bits [17:13]
  int readable;   // 1 if register is readable
  int writable;   // 1 if register is writable
} XIL_T1_PacketRegisters;

static XIL_T1_PacketRegisters xt1pr[] = {
  {"CRC",    0x00, 1, 1},
  {"FAR",    0x01, 1, 1},
  {"FDRI",   0x02, 0, 1},
  {"FDRO",   0x03, 1, 0},
  {"CMD",    0x04, 1, 1},
  {"CTL0",   0x05, 1, 1},
  {"MASK",   0x06, 1, 1},
  {"STAT",   0x07, 1, 0},
  {"LOUT",   0x08, 0, 1},
  {"COR0",   0x09, 1, 1},
  {"MFWR",   0x0A, 0, 1},
  {"CBC",    0x0B, 0, 1},
  {"IDCODE", 0x0C, 1, 1},
  {"AXSS",   0x0D, 1, 1},
  {"COR1",   0x0E, 1, 1},
  {"CSOB",   0x0F, 0, 1},
  {"WBSTAR", 0x10, 1, 1},
  {"TIMER",  0x11, 1, 1},
  {"BOOTSTS",0x16, 1, 0},
  {"CTL1",   0x18, 1, 1},
  {"DWC",    0x1A, 1, 1},
  {0}
};

 static int
atoi_any(char *arg, uint8_t *sizep)
{
  int value ;

  if(strncmp(arg,"0x",2) != 0)
    sscanf(arg,"%u",&value) ;
  else
    sscanf(arg,"0x%x",&value) ;
  if (sizep) {
    char *sp;
    if ((sp = strchr(arg, '/')))
      switch(*++sp) {
      default:
	fprintf(stderr, "Bad size specifier: must be 1, 2, or 4");
	abort();
      case '1':
      case '2':
      case '4':
      case '8':
	*sizep = *sp - '0';
      }
    else
      *sizep = 4;
  }
  return value ;
}

  int
 main(int argc, char **argv)
 {
   int fd;
   off_t off, dp;
   volatile OCCP_Space *p;
   OCCP_Command *c;
   volatile OCDP_Space *d;
   char **ap = argv + 1;


   assert(argc >= 3);
   errno = 0;
   off = strtoul(*ap++, NULL, 16);
   dp = strtoul(*ap++, NULL, 16);
   assert(errno == 0);
   assert((fd = open("/dev/mem", O_RDWR)) != -1);
   assert ((p = mmap(NULL, sizeof(OCCP_Space), PROT_READ|PROT_WRITE, MAP_SHARED, fd, off)) != (void*)-1);
   assert ((d = mmap(NULL, sizeof(OCDP_Space) * 2, PROT_READ|PROT_WRITE, MAP_SHARED, fd, dp)) != (void*)-1);
   for (c = commands; c->name; c++)
     if (strcmp(c->name, *ap) == 0) {
       if (c->worker) {
	 char *cp = *++ap;
	 assert(cp);
	 char **arg = ++ap;

	 do {
	   unsigned n = strtoul(cp, &cp, 10);
	   if (n > OCCP_NWORKERS-1) {
	     fprintf(stderr, "Worker number `%s' invalid\n", *ap ? *ap : "<null>");
	     return 1;
	   }
	   if (c->command(p, arg, &p->control[n].wc, p->config[n], d))
	     return 1;
	 } while (*cp++);
	 return 0;
       } else
	 return c->command(p, ++ap, 0, 0, d);
     }
   fprintf(stderr, "wctl: unknown command: %s\n", *ap);
   return 1;
 }

 static int
admin(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *d)
{
  uint32_t i, j, k;
  time_t epochtime, nowtime;
  struct tm *etime, *ntime;
  static union {
    uint32_t uint;
    char c[sizeof(uint32_t) + 1];
  } u;
  uint64_t x, y, *z = (uint64_t*)p;
  x = z[0];
  y = z[1];

  epochtime = (time_t)p->admin.birthday;
  etime = gmtime(&epochtime); 
  //printf("%lld%lld\n", (long long)x, (long long)y);
  printf("OCCP Admin Space\n");
  u.uint = p->admin.Open;
  printf(" Open:         0x%08x \"%s\"\n", u.uint, u.c);
  u.uint = p->admin.CPI;
  printf(" CPI:          0x%08x \"%s\"\n", u.uint, u.c);
  printf(" revision:     0x%08x\n", p->admin.revision);
  printf(" birthday:     0x%08x %s", p->admin.birthday, asctime(etime));
  printf(" workerMask:   0x%08x workers", (j = p->admin.workerMask));
  for (i = 0; i < sizeof(uint32_t) * 8; i++)
    if (j & (1 << i))
      printf(" %d", i);
  printf(" exist\n");
  printf(" pci_dev_id:   0x%08x\n", p->admin.pci_id);
  printf(" attention:    0x%08x\n", p->admin.attention);
  printf(" cpStatus:     0x%08x\n", p->admin.cpStatus);
  printf(" scratch20:    0x%08x\n", p->admin.scratch20);
  printf(" scratch24:    0x%08x\n", p->admin.scratch24);
  printf(" cpControl:    0x%08x\n", p->admin.cpControl);

  nowtime = (time_t)p->admin.gpsTimeMS;
  ntime = gmtime(&nowtime); 
  printf(" timeStatus:   0x%08x ", p->admin.timeStatus);
    if(p->admin.timeStatus&0x80000000) printf("ppsLostSticky ");
    if(p->admin.timeStatus&0x40000000) printf("gpsInSticky ");
    if(p->admin.timeStatus&0x20000000) printf("ppsInSticky ");
    if(p->admin.timeStatus&0x10000000) printf("timeSetSticky ");
    if(p->admin.timeStatus&0x08000000) printf("ppsOK ");
    if(p->admin.timeStatus&0x04000000) printf("ppsLost ");
  printf("\n");
  printf(" timeControl:  0x%08x\n", p->admin.timeControl);
  printf(" gpsTimeMS:    0x%08x (%u) %s", p->admin.gpsTimeMS,  p->admin.gpsTimeMS, asctime(ntime));
  printf(" gpsTimeLS:    0x%08x (%u)\n",  p->admin.gpsTimeLS,  p->admin.gpsTimeLS);
  printf(" deltaTimeMS:  0x%08x\n", p->admin.deltaTimeMS);
  printf(" deltaTimeLS:  0x%08x\n", p->admin.deltaTimeLS);
  printf(" refPerPPS:    0x%08x (%d)\n", p->admin.refPerPPS, p->admin.refPerPPS);
  printf(" dnaLS:        0x%08x\n", p->admin.dnaLS);
  printf(" dnaMS:        0x%08x\n", p->admin.dnaMS);
  printf(" numDPMemReg:  0x%08x (%d)\n", p->admin.numDPMemRegions, p->admin.numDPMemRegions);
  if (p->admin.numDPMemRegions < 16) 
    for (k=0; k<p->admin.numDPMemRegions; k++)
      printf(" DP%2d:      0x%08x\n", k, p->admin.dpInfo[k]);

  // Print out the 64B 16DW UUID in little-endian looking format...
  for (k=0;k<16;k+=4)
    printf(" UUID[%2d:%2d]: 0x%08x 0x%08x 0x%08x 0x%08x\n",
        k+3, k, p->admin.uuid[k+3], p->admin.uuid[k+2], p->admin.uuid[k+1], p->admin.uuid[k]);

  return 0;
}

 static int
 wadmin(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  unsigned off = atoi_any(*ap++, 0);
  unsigned val = atoi_any(*ap, 0);
  uint32_t *pv = (uint32_t *)((uint8_t *)&p->admin + off);

  printf("Admin space, offset 0x%x, writing value: 0x%x\n", off, val);
  *pv = val;
  return 0;
}

 static int
 radmin(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  unsigned off = atoi_any(*ap, 0);
  uint32_t *pv = (uint32_t *)((uint8_t *)&p->admin + off);

  printf("Admin space, offset 0x%x, read value: 0x%x\n", off, *pv);
  return 0;
}

 static int
 wadmin64(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  unsigned off = atoi_any(*ap++, 0);
  //unsigned val = atoi_any(*ap, 0); // Does not handle 64b properly, use strtoull() instead
  char *end;
  unsigned long long val = strtoull(*ap, &end, 16);
  uint64_t *pv = (uint64_t *)((uint8_t *)&p->admin + off);

  printf("Admin space, offset 0x%x, writing 64b value: 0x%016llx\n", off, val);
  *pv = val;
  return 0;
}

 static int
 radmin64(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  unsigned off = atoi_any(*ap, 0);
  uint64_t *pv = (uint64_t *)((uint8_t *)&p->admin + off);
  unsigned long long val = *pv;

  printf("Admin space, offset 0x%x, read 64b value: 0x%016llx\n", off, val);
  return 0;
}

 static int
 settime(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  struct timeval tv;
  gettimeofday(&tv, NULL); 
  uint32_t fraction = (uint64_t)tv.tv_usec * 1000 *
    ((uint64_t)1 << 32) / (uint64_t)1000000000;
  // Write 64 bit value
  // When it goes on the PCIe wire, it will be "endianized".
  // On intel, first DW will be LSB.  On PPC, first DW will be MSB.
  // Does this need to be handled in SW?
  
#define FPGA_IS_OPPOSITE_ENDIAN_FROM_CPU 1

#if FPGA_IS_OPPOSITE_ENDIAN_FROM_CPU
  *(uint64_t *)(&p->admin.gpsTimeMS) = ((uint64_t)fraction << 32) | tv.tv_sec;
#else
  *(uint64_t *)(&p->admin.gpsTimeMS) = ((uint64_t)tv.tv_sec << 32) | fraction;
#endif

  /*
  // Write 32 bit value to timeMS register
  //p->admin.gpsTimeMS = tv.tv_sec;
  p->admin.ppsCount = tv.tv_sec;
  printf(" Set FPGA Time to host GMT: %s (s 0x%x/%u u 0x%x/%u f 0x%x/%u)\n",
	 ctime(&tv.tv_sec), (unsigned)tv.tv_sec, (unsigned)tv.tv_sec,
	 (unsigned)tv.tv_usec, (unsigned)tv.tv_usec,
	 fraction, fraction);
  */

  return 0;
}

 static int
 deltatime(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{

int i;
for (i=0; i<20; i++) {

  struct timeval tv;
  gettimeofday(&tv, NULL); 
  uint32_t fraction = (uint64_t)tv.tv_usec * 1000 *
    ((uint64_t)1 << 32) / (uint64_t)1000000000;
  // Write 64 bit value
  // When it goes on the PCIe wire, it will be "endianized".
  // On intel, first DW will be LSB.  On PPC, first DW will be MSB.
  // Does this need to be handled in SW?
  
#define FPGA_IS_OPPOSITE_ENDIAN_FROM_CPU 1

#if FPGA_IS_OPPOSITE_ENDIAN_FROM_CPU
  *(uint64_t *)(&p->admin.deltaTimeMS) = ((uint64_t)fraction << 32) | tv.tv_sec;
#else
  *(uint64_t *)(&p->admin.deltaTimeMS) = ((uint64_t)tv.tv_sec << 32) | fraction;
#endif

  //printf(" deltaTimeMS:  0x%08x\n", p->admin.deltaTimeMS);
  //printf(" deltaTimeLS:  0x%08x\n", p->admin.deltaTimeLS);

  uint64_t del64  = ((uint64_t)(p->admin.deltaTimeMS)<<32) | (p->admin.deltaTimeLS);
  double delD = ((double) del64) / 4294967296.0 ;
  printf(" deltaTime:  %lf\n", delD);
}

}

static int
wread(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  uint8_t size;
  uint64_t val;
  unsigned n;
  unsigned offset = atoi_any(*ap++, &size);  

  unsigned off = offset;
  uint8_t *p8 = (uint8_t *)&config[off];

  for (n = *ap ? atoi_any(*ap, 0) : 1;
       n--;
       p8 += size, off += size) {
    switch(size) {
    case 1:
      val = *p8;
      break;
    case 2:
      val = *((uint16_t *)p8);
      break;
    default:
      size = 4;
    case 4:
      val = *((uint32_t *)p8);
      break;
    case 8:
      val = *((uint64_t *)p8);
    }
    printf("Worker %ld, offset:0x%08x(%d), hexVal:0x%08llx decVal:%lld, %d\n",
	   (OCCP_WorkerControlSpace *)w - p->control, off, size, (long long)val, (long long)val, (int)sizeof(val));
  }
  return 0;
}

static struct {
  char *name;
  unsigned off;
} ops[] = {
  {"initialize", offsetof(OCCP_WorkerControl,initialize) },
  {"start", offsetof(OCCP_WorkerControl,start) },
  {"stop", offsetof(OCCP_WorkerControl,stop) },
  {"release", offsetof(OCCP_WorkerControl,release) },
  {"test", offsetof(OCCP_WorkerControl,test) },
  {"before", offsetof(OCCP_WorkerControl,before_query) },
  {"after", offsetof(OCCP_WorkerControl,after_config) },
  {"reserved7", offsetof(OCCP_WorkerControl,reserved7) },
  {0}
};

static int
wop(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  unsigned i;
  for (i = 0; ops[i].name; i++)
    if (*ap && strcmp(*ap, ops[i].name) == 0) {
      unsigned off = ops[i].off;
      uint32_t v, *cp = (uint32_t *)((uint8_t *)w + off);
      printf("Worker %ld control op: %s(%x)\n", (OCCP_WorkerControlSpace *)w - p->control, *ap, off);
      v = *cp;
      printf("Result: 0x%08x\n", v);
      return 0;
    }
  fprintf(stderr, "Unknown control operation: `%s'\n", *ap);
  return 1;
}

static int
wwrite(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  uint8_t size;
  unsigned off = atoi_any(*ap++, &size);
  unsigned val = atoi_any(*ap, 0);
#if 0
  if ((0xffffffffu >> (32 - size*8)) & (val & (-1<<(size*8)))) {
    fprintf(stderr, "Value `%s' too large for size (%d)\n", *ap, size);
    return 1;
  }
#endif
  uint32_t *p32 = (uint32_t *)&config[off];
  printf("Worker %ld, offset 0x%x, writing value: 0x%x\n", (OCCP_WorkerControlSpace *)w - p->control, off, val);
  
  switch(size) {
    case 1:
      *((uint8_t *)p32) = val;
      break;
    case 2:
      *((uint16_t *)p32) = val;
      break;
    default:
      *p32 = val;
    }
  return 0;
}

// ML605 has 512MB, 256MB OK
// Schist has 
#define DRAM_L2NPAGES  8    // 8=128MB 9=256MB, 10=512MB 
#define DRAM_L2PAGESZ  17 
#define DRAM_NPAGES    (1<<DRAM_L2NPAGES)  
#define DRAM_PAGESZ    (1<<DRAM_L2PAGESZ)  

static int
dtest(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  uint8_t size;
  unsigned  off = atoi_any(*ap++,  &size);
  unsigned coff = atoi_any("0x50", &size);
  unsigned  val = atoi_any(*ap, 0);
  uint32_t *p32 = (uint32_t *)&config[off];
  uint32_t *c32 = (uint32_t *)&config[coff];

  printf("dtest\n"); fflush(stdout);

  printf("npages:2^%d  pagesz(4B words):2^%d  memoryBytes:2^%d\n", DRAM_L2NPAGES, DRAM_L2PAGESZ, DRAM_L2NPAGES+DRAM_L2PAGESZ+2);
  printf("Worker %ld, memory test offset 0x%x, test loop count: %d\n", (OCCP_WorkerControlSpace *)w - p->control, off, val);
  fflush(stdout);
  
  unsigned int exp, got, i, j, k, pg;
  int errors = 0;

  for (k=0;k<val;k++) {

    for (pg=0x0;pg<DRAM_NPAGES;pg++) { 
      *c32 = pg; printf("k:%02d Wr:%03x\r",k,pg); fflush(stdout);
      for (i=0;i<DRAM_PAGESZ;i++) { 
        p32[i] = i+pg+k;
      }
    }

    for (pg=0x0;pg<DRAM_NPAGES;pg++) {
      *c32 = pg; printf("k:%02d Rd:%03x\r",k,pg); fflush(stdout);
      for (j=0;j<DRAM_PAGESZ;j++) {
        exp = j+pg+k;
        got = p32[j];
        if (got!=exp) {
          printf("Mismatch: Loop:%d Page:%x Word:%x Exp:%x, Got:%x\n", k, pg, j, exp, got);
          errors++;
          if (errors>32) { printf("at least %d errors, exiting\n", errors); return 0; }
        }
      }
    }
  }

  if (errors==0) printf("\nSuccess\n");
  else           printf("\n%d  Errors\n", errors);
  return 0;
}

static int
smtest(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  uint8_t size;
  unsigned  off  = atoi_any(*ap++,  &size);
  unsigned soff  = atoi_any("0x00", &size);  // status
  unsigned coff  = atoi_any("0x04", &size);  // control
  unsigned woff  = atoi_any("0x08", &size);  // write config
  unsigned roff  = atoi_any("0x0C", &size);  // read config
  unsigned icoff = atoi_any("0x48", &size);  // inCount
  unsigned ocoff = atoi_any("0x4C", &size);  // outCount
  uint32_t *p32  = (uint32_t *)&config[off];
  uint32_t *s32  = (uint32_t *)&config[soff];
  uint32_t *c32  = (uint32_t *)&config[coff];
  uint32_t *w32  = (uint32_t *)&config[woff];
  uint32_t *r32  = (uint32_t *)&config[roff];
  uint32_t *ic32 = (uint32_t *)&config[icoff];
  uint32_t *oc32 = (uint32_t *)&config[ocoff];
  unsigned int ugot32;
  unsigned int pollCount = 0;

  printf("Worker %ld, SelectMAP ICAP Communication Test \n", (OCCP_WorkerControlSpace *)w - p->control);

  printf("Worker Status  is: 0x%08x\n", *s32);
  printf("Enabling Write ICAP\n");
  *c32 = 0x00000001;
  printf("Worker Control is: 0x%08x\n", *c32);
  printf("Worker Status  is: 0x%08x\n", *s32);
  printf("InCount        is: 0x%08x\n", *ic32);
  printf("OutCount       is: 0x%08x\n", *oc32);

  // See table 7-1 in Xilinx V6 UG360 v3.1 on page 125...
  //
  *w32 = 0xFFFFFFFF; // Dummy Word
  *w32 = 0x000000BB; // Bus Width Sync Word
  *w32 = 0x11220044; // Bus Width Detect
  *w32 = 0xFFFFFFFF; // Dummy Word
  *w32 = 0xAA995566; // Sync Word
  *w32 = 0x20000000; // NOOP
  *w32 = 0x20000000; // NOOP
//  *w32 = 0x2800E001; // Type 1 packet header to read STAT register
  *w32 = 0x28018004; // Type 1 packet header to read IDCODE register
  *w32 = 0x20000000; // NOOP
  *w32 = 0x20000000; // NOOP


  *c32 = 0x00000002;
  printf("\nEnabling Read ICAP\n");
  printf("Worker Control is: 0x%08x\n", *c32);
  printf("Worker Status  is: 0x%08x\n", *s32);
  printf("InCount        is: 0x%08x\n", *ic32);
  printf("OutCount       is: 0x%08x\n", *oc32);

  // Don't attempt to reference *r32 until there is something  to read...
  do {
    ugot32 = *s32;
    pollCount++;
    if (pollCount > 1000) {
      printf("Did not see coutF.notEmpty True after %d polls (workerStatus:0x%08x)\n", pollCount, ugot32);
      printf("Worker Control is: 0x%08x\n", *c32);
      printf("Worker Status  is: 0x%08x\n", *s32);
      printf("InCount        is: 0x%08x\n", *ic32);
      printf("OutCount       is: 0x%08x\n", *oc32);
      return(1);
    }
  } while (!(ugot32 & 0x00000004));  // wait for Bit 2 to go true
  printf("Found workerStatus bit 2 set after %d polls (workerStatus:0x%08x)\n", pollCount, ugot32);

  ugot32 = *r32;     // Read one word from STAT register
  printf("STAT register read returned 0x%08x\n", ugot32);
  ugot32 = *r32;     // Read one word from STAT register
  printf("STAT register read returned 0x%08x\n", ugot32);
  ugot32 = *r32;     // Read one word from STAT register
  printf("STAT register read returned 0x%08x\n", ugot32);
  ugot32 = *r32;     // Read one word from STAT register
  printf("STAT register read returned 0x%08x\n", ugot32);
  ugot32 = *r32;     // Read one word from STAT register
  printf("STAT register read returned 0x%08x\n", ugot32);

  printf("Worker Status is: 0x%08x\n", *s32);
  printf("Enabling Write ICAP\n");
  *c32 = 0x00000001;
  printf("Worker Control is: 0x%08x\n", *c32);
  printf("Worker Status  is: 0x%08x\n", *s32);

  *w32 = 0x30008001; // Type 1 Write 1 Word to CMD
  *w32 = 0x0000000D; // DESYNC Command
  *w32 = 0x20000000; // NOOP
  *w32 = 0x20000000; // NOOP

  return 0;
}


static int
wwctl(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  unsigned val = atoi_any(*ap, 0);
  uint32_t *p32 = (uint32_t *)&w->control;
  printf("Worker %ld, writing control register value: 0x%x\n", (OCCP_WorkerControlSpace *)w - p->control, val);
  
  *p32 = val;
  return 0;
}

static int
wwpage(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  unsigned val = atoi_any(*ap, 0);
  uint32_t *p32 = (uint32_t *)&w->pageWindow;
  printf("Worker %ld, pageWindow register value: 0x%x\n", (OCCP_WorkerControlSpace *)w - p->control, val);
  
  *p32 = val;
  return 0;
}

static int
wunreset(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  volatile uint32_t *p32 = (uint32_t *)&w->control;
  uint32_t val = *p32;
  printf("Worker %ld, writing control register value to unreset: 0x%x\n", (OCCP_WorkerControlSpace *)w - p->control, val | 0x80000000);
  
  *p32 = val | 0x80000000;
  return 0;
}

static int
wreset(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  volatile uint32_t *p32 = (uint32_t *)&w->control;
  uint32_t val = *p32;
  printf("Worker %ld, writing control register value to reset: 0x%x\n", (OCCP_WorkerControlSpace *)w - p->control, val & ~0x80000000);
  
  *p32 = val & ~0x80000000;
  return 0;
}

static int
wdump(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  printf("Worker %ld\n", (OCCP_WorkerControlSpace *)w - p->control);
  printf(" Status:     0x%08x\n", w->status);
  printf(" Control:    0x%08x\n", w->control);
  printf(" ConfigAddr: 0x%08x\n", w->config_addr);
  printf(" pageWindow: 0x%08x\n", w->pageWindow);
  return 0;
}

 static int
dmeta(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *d)
{
  uint32_t *pv = (uint32_t *)((uint8_t *)&p->admin);
  unsigned int  mb, b, dp;
  
  // Metadata offset is 8KB into the BRAM buffer (0x800 DWORDS)
  // Dataplanes each take up 32KB (0x2000 DWORDS)

  for (dp=0;dp<2;dp++)
    for (mb=0;mb<4;mb++)  {
      b = 0x800 + (mb*4) + (dp*0x2000);
      printf("dp:%d metabuf:%x: len:%x, op:%x, tag:%x, deltime:%x \n",
          dp, mb, pv[b+0], pv[b+1], pv[b+2], pv[b+3]);
    }

  return 0;
}

 static int
 dpnd(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  unsigned chan = atoi_any(*ap++, 0);
  unsigned n = *ap ? atoi_any(*ap++, 0) : 0;
  volatile OCDP_Space *d = dp + chan;
  unsigned b;
  printf("BEFORE\n");
  printf("Control: Scratch 0x%x ready %x remoteCurrent %d\n",
	 d->control.scratch,
	 d->control.ready,
	 d->control.remoteCurrent);
  for (b = 0; b < 4; b++)
    printf("MetaData %d: Length %d opcode 0x%x counter %d delta %d\n", b,
	   d->meta[b].length,
	   d->meta[b].opcode,
	   d->meta[b].counter,
	   d->meta[b].deltaClks);
  while (n) {
    unsigned b;
    uint32_t buf[16/sizeof(uint32_t)], *p32, *lp;
    // Initial condition is that no remote buffers are available but local buffers may already be filled because Shep doesn't like CONTROL PLANES 
    d->control.remoteAvailable = 1;
    while (!d->control.ready)
      ;
    b = d->control.remoteCurrent;
    printf("About to consume buffer %d, counter: %d delta: %d\n", b,
	   d->meta[b].counter, 
	   d->meta[b].deltaClks);
	   
    // SHEP FIXME FOR PIO TO BE UNNECESSARY

    d->control.start = 1; // now is when we would move data
    p32 = (uint32_t *)&d->buffers[b * OCDP_BUFFER_SIZE];
    lp = buf;
    *lp++ = *p32++;
    *lp++ = *p32++;
    *lp++ = *p32++;
    *lp++ = *p32++;
    d->control.done = 1;  // we indicate that the local buffer we moved FROM is now available
    printf("Buffer %d: 0x%08x 0x%08x 0x%08x 0x%08x\n", b,
	   buf[0], buf[1], buf[2], buf[3]);
    n--;
  }
  printf("AFTER\n");
  printf("Control: Scratch 0x%x ready %x remoteCurrent %d\n",
	 d->control.scratch,
	 d->control.ready,
	 d->control.remoteCurrent);
  for (b = 0; b < 4; b++) {
    printf("MetaData %d: Length %d opcode 0x%x counter %d delta %d\n", b,
	   d->meta[b].length,
	   d->meta[b].opcode,
	   d->meta[b].counter,
	   d->meta[b].deltaClks);
  }
  return 0;
}


static int
dread(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  unsigned start = atoi_any(*ap++, 0);
  unsigned n = *ap ? atoi_any(*ap++, 0) : 1;
  if (*ap) {
    uint64_t *mp = (uint64_t *)dp;
    mp += start/8;
    while (n) {
      printf("0x%08x: 0x%016llx\n", start, (long long unsigned)*mp++);
      start += 8;
      n--;
    }
  } else {
    uint32_t *mp = (uint32_t *)dp;
    mp += start/4;
    while (n) {
      printf("0x%08x: 0x%08x\n", start, *mp++);
      start += 4;
      n--;
    }
  }
  return 0;
}

static int
dwrite(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  uint32_t *mp = (uint32_t *)dp;
  unsigned start = atoi_any(*ap++, 0);
  mp += start/4;

  while(*ap) {
    uint32_t val = atoi_any(*ap++, 0);
    *mp++ = val;
  }
  return 0;
}

 static int
 mwpost(volatile OCCP_Space *p, char **ap, volatile OCCP_WorkerControl *w, volatile uint8_t *config, volatile OCDP_Space *dp)
{
  unsigned off = atoi_any(*ap++, 0);
  unsigned val = atoi_any(*ap, 0);
  uint32_t *pv = (uint32_t *)((uint8_t *)&p->admin + off);
  struct timeval tv0, tv1;
  unsigned i;
  printf("Admin space, offset 0x%x, writing value: 0x%x\n", off, val);

  gettimeofday(&tv0, NULL); 
  for (i=0;i<1000000;i++) {
    *pv = val;
  }
  gettimeofday(&tv1, NULL); 

  uint64_t t0 = tv0.tv_sec * 1000000LL + tv0.tv_usec;
  uint64_t t1 = tv1.tv_sec * 1000000LL + tv1.tv_usec;
  uint64_t dt = t1 - t0;
  printf("1M DWORD writes in %lld uS (%f MB/S)\n", dt, 4000000.0/(double)dt);

  return 0;
}
