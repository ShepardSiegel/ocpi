#include <stdio.h>

main(argc, argv)
  int  argc;
  char *argv[];
{
FILE * fd;
int c;
char str[3];
int i, j = 0;
int v;

  fd = fopen("/tmp/OpenCPI0_Resp", "r");
  if (fd==NULL) {
    perror("Error opening named pipe");
    return(1);
  }
 
  do {
    c = getc(fd);
    if (j%2) {
      str[1] = (char)c;
      str[2] = (char)NULL;
      sscanf(str,"%x",&v);
      printf("%s got response %d with value %d\n", argv[0], i, v);
      i++;
    }
  else
    str[0] = (char)c;
  j++;
  } while (c != EOF );

	fclose(fd);
  return(0);
}
