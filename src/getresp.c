#include <stdio.h>

main(argc, argv)
  int  argc;
  char *argv[];
{
FILE * fd;
int c;
char str[3];
int i = 0;
int j = 0;
int v;

  fd = fopen("/tmp/OpenCPI0_Resp", "r");
  if (fd==NULL) {
    perror("Error opening named pipe");
    return(1);
  }

  // This loop for straight binary, one-byte-per-byte...
  do {
    c = getc(fd);
      printf("%s got response %d with value %d (0x%02x)\n", argv[0], i, c, c);
      i++;
  } while (c != EOF );
 
  // This way to accept two bytes per byte hex nibbles of ascii to binary...
  /*
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
  */

	fclose(fd);
  return(0);
}
