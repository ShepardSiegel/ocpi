#include <stdio.h>

main(argc, argv)
  int  argc;
  char *argv[];
{
FILE * fd;
int i, j;

int dcp10[2]  = {0x01, 0x0A};
int spin4[2]  = {0x00, 0x01};

  fd = fopen("/tmp/OpenCPI0_IOCtl", "w");


  for(i=0; i<2 ;i++) {
    j = dcp10[i];
    fputc(j, fd);
    printf("%s sent request %d (0x%02x)\n", argv[0], i, j);
  }

  for(i=0; i<2 ;i++) {
    j = spin4[i];
    fputc(j, fd);
    printf("%s sent request %d (0x%02x)\n", argv[0], i, j);
  }

	fclose(fd);
  return(0);
}
