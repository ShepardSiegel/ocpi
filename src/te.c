#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
//#include <netpacket/packet.h>
#include <net/ethernet.h>
#include <arpa/inet.h>
//#define __USE_MISC
#include <net/if.h>
#include <linux/if_arp.h>
#include <ifaddrs.h>

int main(int argc, char **argv) {

  int r;
  int s = socket(PF_PACKET, SOCK_DGRAM, htons(0xf040)); // ETH_P_ALL));
  assert(s >= 0);
  unsigned index = -1;
  {
    unsigned i = 0;
    struct ifreq ifr;
    do {
      ifr.ifr_ifindex = i;
      r = ioctl(s, SIOCGIFNAME, &ifr);
      if (r >= 0) {
	int up;
	printf("Index %d: r: %d errno %d name: %10s",
	       i, r, errno, ifr.ifr_name);
	r = ioctl(s, SIOCGIFFLAGS, &ifr);
	assert(r >= 0);
	printf(" flags 0x%05x", ifr.ifr_flags);
	up = ifr.ifr_flags & IFF_UP;
	r = ioctl(s, SIOCGIFHWADDR, &ifr);
	assert(r >= 0);
	printf(" addr family %d ", ifr.ifr_hwaddr.sa_family);
	if (ifr.ifr_hwaddr.sa_family == ARPHRD_ETHER) {
	  printf("ethernet %s ", up ? "up" : "down");
	  uint8_t *addr = (uint8_t *)ifr.ifr_hwaddr.sa_data;
	  for (unsigned n = 0; n < 6; n++)
	    printf("%s%02X", n ? ":" : "", addr[n]);
	  if (up)
	    index = i;
	}
	printf("\n");
      }
    } while (++i < 10);
  }
  assert(index >= 0);
  static char buf[10000];
  static char req[] ={0x00, 0x0A,0x00, 0x00, 0x0F, 0x05, 0x80, 0x00, 0x00, 0x01};
    
  struct sockaddr_ll addr;
  addr.sll_protocol = htons(0xf040);
  addr.sll_ifindex = argv[1] ? atoi(argv[1]) : index;
  addr.sll_family = PF_PACKET;
  addr.sll_pkttype = PACKET_HOST;
  memset(addr.sll_addr, 0xff, sizeof(addr.sll_addr));
  r = bind(s, (struct sockaddr *)&addr, sizeof(addr));
  assert(r >= 0);
  for (unsigned i = 0; i < 10; i++) {
    socklen_t alen = sizeof(addr);
    addr.sll_protocol = htons(0xf040);
    addr.sll_ifindex = argv[1] ? atoi(argv[1]) : index;
    addr.sll_family = PF_PACKET;
    addr.sll_pkttype = PACKET_HOST;
    memset(addr.sll_addr, 0xff, sizeof(addr.sll_addr));
    ssize_t ss = sendto(s, req, sizeof(req), 0, (struct sockaddr *)&addr, alen);
    printf("ss %5zd\n", ss);
    ssize_t sr = recvfrom(s, buf, 10000, 0, (struct sockaddr *)&addr, &alen);
    printf("sr %5zd, alen %zd %d, errno %d, addr.fam %d proto 0x%x if %d %d %d ", 
	   sr, sizeof(addr), alen, errno, addr.sll_family, ntohs(addr.sll_protocol),
	   addr.sll_ifindex, addr.sll_pkttype, addr.sll_halen);
    for (unsigned n = 0; n < addr.sll_halen; n++)
      printf("%s%02X", n ? ":" : "", addr.sll_addr[n]);
    printf("\n");
    fflush(stdout);
  }
#if 0
discovery: send broadcast from all infaces explicitly, and be reading from all interfaces 
for our packet type.  This should return mac addresses and identifiers from all those on enet.
  for the "control plane driver" aspect, we have the potential to reach the same things multiple times.
So when we get the uuid, we can use the preference.
So a "control plane driver" will give us a name-string for access using that driver, as well as the DNA.
Then when we create the container we provide the control-plane driver to it.
Just use more drivers in the same file as the container.
So we need a new class of driver and a new device class for each.
hdl-device class...
  so we need to be sure that the driver manager for hdl-devices is configured (and thus scanned) before the container driver manager.
So perhaps we can have the driver managers ordered in their configure.
Then the methods for the hdl-devices are initially control-only.
So essentially some hdl container methods are delegated to their devices.
This raises the multiple-dataplane issues in the containers too.


#endif
  return 0;
}
