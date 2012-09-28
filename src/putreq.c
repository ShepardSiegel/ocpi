#include <stdio.h>

main(argc, argv)
  int  argc;
  char *argv[];
{
FILE * fd;
int i;

  fd = fopen("/tmp/OpenCPI0_Req", "w");

  for(i=0; i<256 ;i++) {
    fputc(i, fd);
    printf("%s sent request %d\n", argv[0], i);
  }

	fclose(fd);
  return(0);
}
