#include <stdio.h>

main(argc, argv)
  int  argc;
  char *argv[];
{
FILE * fd;
int i;

  fd = fopen("/tmp/OpenCPI0_Req", "w");

  for(i=0; i<10 ;i++) {
    fputc(i, fd);
    printf("%s sent request %d (0x%02x)\n", argv[0], i, i);
  }

	fclose(fd);
  return(0);
}
