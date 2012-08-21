#include <unistd.h>
#include <fcntl.h>
#include <assert.h>
#include <stdio.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <errno.h>
#include <time.h>
#include <pthread.h>
#include <string.h>
#include <stdlib.h>
#include <signal.h>
#include "OCCP.h"
#include "OCDP.h"

#define WORKER_DRAM (12)
#define WORKER_DP0 (13)
#define WORKER_DP1 (14)
#define WORKER_SMA0 (2)
#define WORKER_BIAS (3)
#define WORKER_SMA1 (4)
#define OCDP_OFFSET_DP0 (32*1024)
#define OCDP_OFFSET_DP1 0

#define INST_WRITE 0x80000000
#define INST_READ  0x00000000

#define DMA_SIZE 4096

uint32_t instBuf[4096];
uint32_t recvBuf[4096];

unsigned writeBufIdx;
unsigned readBufIdx;

volatile CPI::RPL::OccpWorkerRegisters *dp0, *dp1, *sma0, *sma1, *dram, *bias;
volatile CPI::RPL::OcdpProperties *dp0Props, *dp1Props;

void sighandler(int test) {
  printf("\n\nCtrl+C detected, exiting gracefully\n\n");

  // Stop workers
  printf("Releasing: ");
  printf("%d, ", dp0->release == OCCP_SUCCESS_RESULT);
  printf("%d, ", dp1->release == OCCP_SUCCESS_RESULT);
  printf("%d, ", sma0->release == OCCP_SUCCESS_RESULT);
  printf("%d, ", sma1->release == OCCP_SUCCESS_RESULT);
  printf("%d, ", dram->release == OCCP_SUCCESS_RESULT);
  printf("%d\n\n", bias->release == OCCP_SUCCESS_RESULT);
  
  exit(0);
}

  

// Control operations on workers
static void
reset(volatile CPI::RPL::OccpWorkerRegisters *, unsigned),
  init(volatile CPI::RPL::OccpWorkerRegisters *),
  start(volatile CPI::RPL::OccpWorkerRegisters *);

// Packet of arguments required to process a stream endpoint on the cpu side
struct Stream {
  unsigned bufSize, nBufs;
  volatile uint8_t *buffers;
  volatile CPI::RPL::OcdpMetadata *metadata;
  volatile uint32_t *flags;
  volatile uint32_t *doorbell;

  int* transferBuffer;
  int transferLength;
};

static void
*doRead(void *args),
  *doWrite(void *args),
  setupStream(Stream *s, volatile CPI::RPL::OcdpProperties *p, bool isToCpu,
	      unsigned nCpuBufs, unsigned nFpgaBufs, unsigned bufSize,
	      uint8_t *cpuBase, unsigned long long dmaBase, uint32_t *offset);


int main(int argc, char *argv[])
{
  signal(SIGINT, sighandler);
  errno = 0;
  unsigned dmaMeg;
  unsigned long long
    dmaBase, dmaSize,
    bar0Base = strtoull(argv[1], NULL, 0),
    bar1Base = strtoull(argv[2], NULL, 0),
    bar1Size = strtoull(argv[3], NULL, 0);
  assert(errno == 0);
  //int fd = open("/dev/mem", O_RDWR|O_SYNC);
  int fd = open("/dev/mem", O_RDWR);
  assert(fd >= 0);

  CPI::RPL::OccpSpace *occp =
    (CPI::RPL::OccpSpace *)mmap(NULL, sizeof(CPI::RPL::OccpSpace),
				PROT_READ|PROT_WRITE, MAP_SHARED, fd, bar0Base);
  assert(occp != (CPI::RPL::OccpSpace*)-1);
  uint8_t *bar1 = (uint8_t*)mmap(NULL, bar1Size,
				 PROT_READ|PROT_WRITE, MAP_SHARED, fd, bar1Base);
  assert(bar1 != (uint8_t*)-1);
  const char *dmaEnv = getenv("CPI_DMA_MEMORY");
  assert(dmaEnv);
  unsigned count = sscanf(dmaEnv, "%uM$0x%llx", &dmaMeg,
			  (unsigned long long *) &dmaBase);
  assert(count == 2);
  dmaSize = (unsigned long long)dmaMeg * 1024 * 1024;
  uint8_t *cpuBase =
    (uint8_t*)mmap(NULL, dmaSize, PROT_READ|PROT_WRITE, MAP_SHARED, fd, dmaBase);
  assert(cpuBase != (uint8_t*)-1);
  // These have this structure of properties
  dp0Props = (CPI::RPL::OcdpProperties*)occp->config[WORKER_DP0];
  dp1Props = (CPI::RPL::OcdpProperties*)occp->config[WORKER_DP1];

  // These just have a single 32 bit scalar property
  volatile uint32_t
    *sma0Props = (uint32_t*)occp->config[WORKER_SMA0],
    *sma1Props = (uint32_t*)occp->config[WORKER_SMA1],
    *biasProps = (uint32_t*)occp->config[WORKER_BIAS],
    *dramProps = (uint32_t*)occp->config[WORKER_DRAM];


  dp0 = &occp->worker[WORKER_DP0].control;
  dp1 = &occp->worker[WORKER_DP1].control;
  sma0 = &occp->worker[WORKER_SMA0].control;
  sma1 = &occp->worker[WORKER_SMA1].control;
  dram = &occp->worker[WORKER_DRAM].control;
  bias = &occp->worker[WORKER_BIAS].control;

  // So far we have not done anything other than establish mappings and pointers

  writeBufIdx = 0;
  readBufIdx = 0;

  // Stop workers
  printf("Releasing: ");
  printf("%d, ", dp0->release == OCCP_SUCCESS_RESULT);
  printf("%d, ", dp1->release == OCCP_SUCCESS_RESULT);
  printf("%d, ", sma0->release == OCCP_SUCCESS_RESULT);
  printf("%d, ", sma1->release == OCCP_SUCCESS_RESULT);
  printf("%d, ", dram->release == OCCP_SUCCESS_RESULT);
  printf("%d\n\n", bias->release == OCCP_SUCCESS_RESULT);
  
  sleep(1);

  // Reset workers
  reset(dram,  0);
  reset(sma0,  0);
  reset(sma1,  0);
  reset(bias,  0);
  reset(dp0,  0);
  reset(dp1,  0);

  // initialize workers
  init(dram);
  init(sma0);
  init(sma1);
  init(bias);
  init(dp0);
  init(dp1);

  // configure workers as appropriate
  *sma0Props = 1; // WMI input to WSI output
  biasProps[0] = 0;
  *sma1Props = 2; // WSI input to WMI output


  // Configure streams, SW side and HW side
  const unsigned bufSize = DMA_SIZE, nFpgaBufs = 2, nCpuBufs = 200;
  printf("Transfer Size: %d, Num CPU Bufs: %d\n", bufSize, nCpuBufs);

  // These structures define the cpu-side stream endpoints
  Stream fromCpu, toCpu;
  uint32_t dmaOffset = 0; // this is our "dma buffer allocation" pointer...

  setupStream(&fromCpu, dp0Props, false,
	      nCpuBufs, nFpgaBufs, bufSize, cpuBase, dmaBase, &dmaOffset);
  setupStream(&toCpu, dp1Props, true,
	      nCpuBufs, nFpgaBufs, bufSize, cpuBase, dmaBase, &dmaOffset);


  // Clear metadata space
  int* meta = (int*)toCpu.metadata;

  for(uint i = 0; i < nCpuBufs*4; i++) {
    meta[i] = -1;
  }

  // start workers
  start(dp0);
  start(dp1);
  start(sma0);
  start(dram);
  start(bias);
  start(sma1);

  // Now everything is running, and waiting to be fed some data
  // First we'll start a thread that reads data
  pthread_t readThread;

  toCpu.transferBuffer = (int*)recvBuf;

  int r = pthread_create(&readThread, NULL, doRead, &toCpu);
  assert(r == 0);

  // Now well copy from stdin to the FPGA in the main thread
  
  uint32_t writeCounter = 0;
  while(1) {
    // generate data to transfer
    for(int i = 0; i < DMA_SIZE/4; i++)
     instBuf[i] = writeCounter++;
    
    fromCpu.transferBuffer = (int*)instBuf;
    fromCpu.transferLength = DMA_SIZE/4;
    doWrite(&fromCpu);
  }

  // Rendezvous with the background thread when it finishes reading from FPGA to stdout
  r = pthread_join(readThread, NULL);
  assert(r == 0);

  return 0;
}

// reset a worker
static void
reset(volatile CPI::RPL::OccpWorkerRegisters *w, unsigned timeout) {
  // compute log-2 timeout value
  if (!timeout)
    timeout = 16;
  unsigned logTimeout = 31;
  for (uint32_t u = 1 << logTimeout; !(u & timeout);
       u >>= 1, logTimeout--)
    ;

  // Assert Reset
  w->control =  logTimeout;
  // Take out of reset
  w->control = OCCP_CONTROL_ENABLE | logTimeout ;
}

// check a control operation return code
static void
check(uint32_t val) {
  assert(val == OCCP_SUCCESS_RESULT);
}

// initialize a worker
static void
init(volatile CPI::RPL::OccpWorkerRegisters *w) {
  check(w->initialize);
}

// start a worker
static void
start(volatile CPI::RPL::OccpWorkerRegisters *w) {
  check(w->start);
}

double convertTime(timeval t) {
  double duration;
      
  long seconds  = t.tv_sec;
  long nseconds = t.tv_usec;
  return(seconds + nseconds/1000000.0);
}

// function to run in a thread to read data from the FPGA and write it to stdout
static void *
doRead(void *args) {
  Stream *s = (Stream *)args;

  int nwrite;
  unsigned int numBuffers = 0;

  uint64_t startTimeSeconds = time(NULL);

  timeval t1, t2;
  int error = 0;

  uint32_t readCounter = 0;

  nwrite = 0;

  gettimeofday(&t1, 0);
  t2 = t1;
  while(1) {
    // Wait for buffer to be full, so we can empty it.
    while (s->flags[readBufIdx] == 0)
      ;
    nwrite = s->metadata[readBufIdx].length;
    if(nwrite == 0) {
      printf("\n\nFlag set to %d at id %d!\n", s->flags[readBufIdx], readBufIdx);
      printf("ERROR: nwrite = %d\n", nwrite);
      exit(0);
    }
    if (nwrite != 0) {
      memcpy(s->transferBuffer, (void*)&s->buffers[readBufIdx * s->bufSize], nwrite);
      int* buffInt = (int*)s->transferBuffer;
    
      // Check correctness
      for(int i = 0; i < nwrite/(sizeof(int)); i++) {
	if(buffInt[i] != readCounter++) {
	  printf("ERROR: size = %d, idx = %d, buffer data = %d, expected = %d\n", nwrite, i,buffInt[i], readCounter - 1);
	  error = 1;
	  printf("Length: %d, Opcode: %d, Counter: %d, Interval: %d\n", s->metadata[readBufIdx].length, s->metadata[readBufIdx].opCode, s->metadata[readBufIdx].tag, s->metadata[readBufIdx].interval);
	  double GBwritten = (double)numBuffers * nwrite/(1024*1024*1024);
	  printf("Total data transferred: %.2f GB in %d seconds\n", GBwritten, time(NULL) - startTimeSeconds);
	}
      }
    }

    if(error == 1) {
      sighandler(0);
      exit(1);
    }

    // mark the buffer empty.  FPGA will set it to 1 when it fills it (ready to use)
    s->flags[readBufIdx] = 0;
    // Tell hardware we have emptied it.
    *s->doorbell = 1;
    readBufIdx = (readBufIdx + 1) % s->nBufs;

    numBuffers++;

    if((numBuffers & ((1 << 17) - 1)) == 0) {
      timeval t3;
      gettimeofday(&t3, 0);

      double elapsedTime = convertTime(t3) - convertTime(t1);
      double deltaTime = convertTime(t3) - convertTime(t2);
      
      t2 = t3;

      double GBwritten = (double)numBuffers * nwrite/(1024*1024*1024);
      double MBwritten = (double)numBuffers * nwrite/(1024*1024);
      printf("Current elapsed time: %.2f, transferred %.2f GB, nwrite = %d, avg bw = %.2f MB/s, deltaTime = %.2f, cur bw = %.2f MB/s\n", elapsedTime, GBwritten, nwrite, MBwritten/elapsedTime, deltaTime, (((1<<17)*nwrite)/(1024.0*1024))/deltaTime);
    }
  }
}

// function to run in a thread to write data from stdin to the FPGA
static void *
doWrite(void* args) {
  Stream *s = (Stream*)args;
   
  // Wait for buffer to be empty, so we can fill it.
  while (s->flags[writeBufIdx] == 0)
    ;
  int transferSize = s->transferLength*sizeof(int);

  memcpy((void *)&s->buffers[writeBufIdx * s->bufSize], s->transferBuffer, transferSize);
  s->metadata[writeBufIdx].length = transferSize;
  s->metadata[writeBufIdx].opCode = 0;
  // Set it full. FPGA will set it to 1 (empty/ready to use)
  s->flags[writeBufIdx] = 0;
  // Tell hardware we have filled it.
  *s->doorbell = 1;

  writeBufIdx = (writeBufIdx + 1) % s->nBufs;
}


 static void
setupStream(Stream *s, volatile CPI::RPL::OcdpProperties *p, bool isToCpu,
	    unsigned nCpuBufs, unsigned nFpgaBufs, unsigned bufSize,
	    uint8_t *cpuBase, unsigned long long dmaBase, uint32_t *offset)
{
  s->nBufs = nCpuBufs;
  s->bufSize = bufSize;
  s->buffers = cpuBase + *offset;
  s->metadata = (CPI::RPL::OcdpMetadata *)(s->buffers + nCpuBufs * bufSize);
  s->flags = (uint32_t *)(s->metadata + nCpuBufs);
  s->doorbell = &p->nRemoteDone;
  *offset += (uint8_t *)(s->flags + nCpuBufs) - s->buffers;
  memset((void *)s->flags, isToCpu ? 0 : 1, nCpuBufs * sizeof(uint32_t));
  memset((void *)s->buffers, 0, nCpuBufs * bufSize);
  memset((void *)s->metadata, 1, nCpuBufs * sizeof(CPI::RPL::OcdpMetadata));
  p->nLocalBuffers = nFpgaBufs;
  p->nRemoteBuffers = nCpuBufs;
  p->localBufferBase = 0;
  p->localMetadataBase = nFpgaBufs * bufSize; // above 4 x 2k buffers
  p->localBufferSize = bufSize;
  p->localMetadataSize = sizeof(CPI::RPL::OcdpMetadata);
  p->memoryBytes = 32*1024;
  p->remoteBufferBase = dmaBase + (s->buffers - cpuBase);
  p->remoteMetadataBase = dmaBase + ((uint8_t*)s->metadata - cpuBase);
  p->remoteBufferSize = bufSize;
  p->remoteMetadataSize = sizeof(CPI::RPL::OcdpMetadata);
  p->remoteFlagBase = dmaBase + ((uint8_t*)s->flags - cpuBase);
  p->remoteFlagPitch = sizeof(uint32_t);
  p->control = OCDP_CONTROL(isToCpu ? OCDP_CONTROL_PRODUCER : OCDP_CONTROL_CONSUMER,
			    CPI::RPL::OCDP_ACTIVE_MESSAGE);
 }

