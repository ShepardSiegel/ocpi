/*
 * Linux device driver for Bluespec FPGA-based interconnect networks.
 */

#include <linux/module.h>
#include <linux/pci.h>       /* pci device types, fns, etc. */
#include <linux/errno.h>     /* error codes */
#include <linux/io.h>        /* I/O mapping, reading, writing */
#include <linux/types.h>     /* size_t */
#include <linux/cdev.h>      /* struct cdev */
#include <linux/fs.h>        /* struct file_operations */
#include <linux/init.h>      /* __init, __exit, etc. */
#include <linux/ioctl.h>     /* ioctl macros */
#include <linux/interrupt.h> /* request_irq, free_irq, etc. */
#include <linux/mm.h>        /* kmalloc, kfree */
#include <linux/delay.h>     /* mdelay */
#include <asm/uaccess.h>     /* copy_to_user, copy_from_user */

#include "bluenoc.h"

/*
 * driver module data for the kernel
 */

MODULE_AUTHOR ("Bluespec, Inc.");
MODULE_DESCRIPTION ("PCIe device driver for Bluespec FPGA interconnect");
MODULE_LICENSE ("Dual BSD/GPL");

/*
 * driver configuration
 */

/* stem used for module and device names */
#define DEV_NAME "bluenoc"

/* version string for the driver */
#define DEV_VERSION "1.0"

/* Bluespec's standard vendor ID */
#define BLUESPEC_VENDOR_ID 0x1be7

/* Bluespec's NoC device ID */
#define BLUESPEC_NOC_DEVICE_ID 0xb100

/* set to 1 to enable debug messages */
#define DEBUG 0

/*
 * Per-device data
 */

/* per-device data that persists from probe to remove */
typedef struct tBoard {
  /* bars */
  void __iomem* bar0io;
  void __iomem* bar1io;
  /* pci device pointer */
  struct pci_dev* pci_dev;
  /* board identification fields */
  unsigned int       major_rev;
  unsigned int       minor_rev;
  unsigned int       build;
  unsigned int       timestamp;
  unsigned int       addr_size;
  unsigned int       bytes_per_beat;
  unsigned long long content_id;
  /* dma fields */
  unsigned int       irq_num;
  unsigned long      buffer_page;
  dma_addr_t         buffer_page_bus_addr;
  unsigned int       buffer_head;
  unsigned int       buffer_tail;
  /* link to next board */
  struct tBoard* next;
} tBoard;

static tBoard* board_list = NULL;

/* forward declarations of driver routines */
static int bluenoc_open(struct inode* inode, struct file* file);
static int bluenoc_release(struct inode* inode, struct file* file);
static int __devinit bluenoc_probe(struct pci_dev* dev, const struct pci_device_id* id);
static void __devexit bluenoc_remove(struct pci_dev* dev);
/* static int bluenoc_ioctl(struct inode* inode, struct file* file, unsigned int cmd, unsigned long arg); */

static irqreturn_t intr_handler(int irq, void* dev_id);

/*
 * driver initialization and exit
 *
 * these routines are responsible for allocating and
 * freeing kernel resources, creating device nodes,
 * registering the driver, obtaining a major and minor
 * numbers, etc.
 */

/* static device data */
static dev_t         device_number;
static struct class* bluenoc_class = NULL;
static struct cdev   cdev;
static unsigned int  open_count = 0;

/* file operations pointers */
static const struct file_operations bluenoc_fops = {
  .owner   = THIS_MODULE,
  .open    = bluenoc_open,
  .release = bluenoc_release
  /*  .ioctl   = bluenoc_ioctl */
};

/* PCI ID pattern table */
static DEFINE_PCI_DEVICE_TABLE(bluenoc_id_table) = {
  {PCI_DEVICE(BLUESPEC_VENDOR_ID, BLUESPEC_NOC_DEVICE_ID)},
  {}
};

MODULE_DEVICE_TABLE(pci, bluenoc_id_table);

/* PCI driver operations pointers */
static struct pci_driver bluenoc_driver = {
  .name     = DEV_NAME,
  .id_table = bluenoc_id_table,
  .probe    = bluenoc_probe,
  .remove   = __devexit_p(bluenoc_remove)
};

/* first routine called on module load */
static int __init bluenoc_init(void)
{
  int status;

  /* dynamically allocate a device number */
  if (alloc_chrdev_region(&device_number, 0, 1, DEV_NAME) < 0) {
    printk(KERN_ERR "%s: failed to allocate character device region\n", DEV_NAME);
    return -1;
  }

  /* initialize driver data */
  board_list = NULL;

  /* register the driver with the PCI subsystem */
  status = pci_register_driver(&bluenoc_driver);
  if (status < 0) {
    printk(KERN_ERR "%s: failed to register PCI driver\n", DEV_NAME);
    return status;
  }

  /* log the fact that we loaded the driver module */
  printk(KERN_INFO "%s: Registered Bluespec BlueNoC driver %s\n", DEV_NAME, DEV_VERSION);
  printk(KERN_INFO "%s: Major/Minor = %d/%d\n", DEV_NAME, MAJOR(device_number), MINOR (device_number));

  return 0; /* success */
}

/* routine called on module unload */
static void __exit bluenoc_exit (void)
{
  tBoard* brd_ptr;

  /* unregister the driver with the PCI subsystem */
  pci_unregister_driver(&bluenoc_driver);

  /* release reserved device numbers */
  unregister_chrdev_region(device_number, 1);

  /* log that the driver module has been unloaded */
  printk(KERN_INFO "%s: Unregistered Bluespec BlueNoC driver %s\n", DEV_NAME, DEV_VERSION);

  /* free all allocated board structures */
  brd_ptr = board_list;
  while (brd_ptr != NULL) {
    tBoard* free_me = brd_ptr;
    brd_ptr = brd_ptr->next;
    kfree(free_me);
  }
}

/* register init and exit routines */
module_init(bluenoc_init);
module_exit(bluenoc_exit);

/* driver PCI operations */

static int __devinit bluenoc_probe(struct pci_dev* dev, const struct pci_device_id* id)
{
  int err = 0;
  void __iomem* bar0_io = NULL;
  void __iomem* bar1_io = NULL;
  tBoard* this_board = NULL;
  struct device* dev_ptr = NULL;

  printk(KERN_INFO "%s: PCI probe for 0x%04x 0x%04x\n", DEV_NAME, dev->vendor, dev->device);

  /* double-check vendor and device */
  if ((dev->vendor != BLUESPEC_VENDOR_ID) || (dev->device != BLUESPEC_NOC_DEVICE_ID)) {
    printk(KERN_ERR "%s: probe with invalid vendor or device ID\n", DEV_NAME);
    err = -EINVAL;
    goto exit_bluenoc_probe;
  }

  /* enable the PCI device */
  if (pci_enable_device(dev) != 0) {
    printk(KERN_ERR "%s: failed to enable %s\n", DEV_NAME, pci_name(dev));
    err = -EFAULT;
    goto exit_bluenoc_probe;
  }

  /* setup memory regions */
  if ((pci_request_region(dev, 0, "bar0") != 0) ||
      (pci_request_region(dev, 1, "bar1") != 0))
  {
    err = -EBUSY;
    goto disable_pci_device;
  }

  /* map BARs */
  bar0_io = pci_iomap(dev, 0, 0);
  bar1_io = pci_iomap(dev, 1, 0);
  if ((bar0_io == NULL) || (bar1_io == NULL)) {
    err = -EFAULT;
    goto unmap_bars;
  }

  /* check the magic number in BAR 0 */
  {
    unsigned long long magic_num = readq(bar0_io);
    unsigned long long expected_magic = 'B'
                                      | ((unsigned long long)'l' << 8)
                                      | ((unsigned long long)'u' << 16)
                                      | ((unsigned long long)'e' << 24)
                                      | ((unsigned long long)'s' << 32)
                                      | ((unsigned long long)'p' << 40)
                                      | ((unsigned long long)'e' << 48)
                                      | ((unsigned long long)'c' << 56);
    if (magic_num != expected_magic) {
      printk(KERN_ERR "%s: magic number %llx does not match expected %llx\n", DEV_NAME, magic_num, expected_magic);
      err = -EINVAL;
      goto unmap_bars;
    }
  }

  /* allocate a structure for this board */
  this_board = (tBoard*) kmalloc(sizeof(tBoard),GFP_KERNEL);
  if (this_board == NULL) {
    printk(KERN_ERR "%s: unable to allocate memory for board structure\n", DEV_NAME);
    err = -EINVAL;
    goto unmap_bars;
  }
  else {
    unsigned int minor_rev = ioread32(bar0_io + 8);
    unsigned int major_rev = ioread32(bar0_io + 12);
    unsigned int build_version = ioread32(bar0_io + 16);
    unsigned int timestamp = ioread32(bar0_io + 20);
    unsigned int noc_params = ioread32(bar0_io + 28);
    unsigned long long board_content_id = readq(bar0_io + 32);
    unsigned long buffer_ka;
    dma_addr_t buffer_ba;
    struct msix_entry msix_entries[1];
    int result;

    /* insert board into linked list of boards */
    this_board->next = board_list;
    board_list = this_board;

    /* basic board info */

    printk(KERN_INFO "%s: revision = %d.%d\n", DEV_NAME, major_rev, minor_rev);
    printk(KERN_INFO "%s: build_version = %d\n", DEV_NAME, build_version);
    printk(KERN_INFO "%s: timestamp = %d\n", DEV_NAME, timestamp);
    printk(KERN_INFO "%s: NoC is using %d byte beats and %d bit addresses\n", DEV_NAME, (noc_params & 0xff), (noc_params & 0x100) ? 64 : 32);
    printk(KERN_INFO "%s: Content identifier is %llx\n", DEV_NAME, board_content_id);

    this_board->bar0io         = bar0_io;
    this_board->bar1io         = bar1_io;
    this_board->pci_dev        = dev;
    this_board->major_rev      = major_rev;
    this_board->minor_rev      = minor_rev;
    this_board->build          = build_version;
    this_board->timestamp      = timestamp;
    this_board->addr_size      = (noc_params & 0x100) ? 64 : 32;
    this_board->bytes_per_beat = noc_params & 0xff;
    this_board->content_id     = board_content_id;

    /* DMA setup */

    buffer_ka = __get_free_page(GFP_KERNEL);
    if (buffer_ka == 0) {
      printk(KERN_ERR "%s: Failed to get free page for DMA buffer\n", DEV_NAME);
      err = -ENOMEM;
      goto free_board;
    }
    printk(KERN_INFO "%s: Allocated DMA buffer page at %p\n", DEV_NAME, (void*)buffer_ka);
    this_board->buffer_page = buffer_ka;

    dev_ptr = &(this_board->pci_dev->dev);
    buffer_ba = dma_map_single(dev_ptr, (void*)buffer_ka, PAGE_SIZE, PCI_DMA_FROMDEVICE);
    if (dma_mapping_error(dev_ptr,buffer_ba) != 0) {
      printk(KERN_ERR "%s: Failed to map DMA buffer\n", DEV_NAME);
      err = -EFAULT;
      goto free_dma_buffer;
    }
    this_board->buffer_page_bus_addr = buffer_ba;
    printk(KERN_INFO "%s: Mapped DMA buffer to bus addr %p\n", DEV_NAME, (void*)buffer_ba);

    this_board->buffer_head = 0;
    this_board->buffer_tail = 0;
    iowrite32(this_board->buffer_page_bus_addr, bar0_io + 2048); /* set DMA buffer addr */
    iowrite32(0, bar0_io + 2052);                                /* set DMA buffer head */
    iowrite32(0, bar0_io + 2056);                                /* set DMA buffer tail */

    msix_entries[0].entry = 0;
    if (pci_enable_msix(this_board->pci_dev, msix_entries, 1) != 0) {
      printk(KERN_ERR "%s: Failed to allocate MSI-X interrupts\n", DEV_NAME);
      err = -EFAULT;
      goto unmap_dma;
    }
    this_board->irq_num = msix_entries[0].vector;
    result = request_irq(this_board->irq_num, intr_handler, 0, DEV_NAME, (void*) this_board);
    if (result != 0) {
      printk(KERN_ERR "%s: Failed to get requested IRQ %d\n", DEV_NAME, this_board->irq_num);
      err = -EBUSY;
      goto disable_intr;
    }

    printk(KERN_INFO "%s: MSI-X interrupts enabled with IRQ %d\n", DEV_NAME, this_board->irq_num);
    iowrite32(0, bar0_io + 16396); /* set MSI-X Entry 0 Vector Control value to 0 (unmasked) */
  }

  /* setup a device file if this is the first board */
  if (this_board->next == NULL) {
    open_count = 0;

    /* add the device operations */
    cdev_init(&cdev,&bluenoc_fops);
    err = cdev_add(&cdev,device_number,1);
    if (err) {
      printk(KERN_ERR "%s: cdev_add failed\n", DEV_NAME);
      err = -EFAULT;
      goto release_irq;
    }

    /* create a device node via udev */
    bluenoc_class = class_create (THIS_MODULE, "Bluespec");
    device_create(bluenoc_class, NULL, device_number, NULL, "%s", DEV_NAME);

    /* log creation of device */
    printk(KERN_INFO "%s: /dev/%s device file created\n", DEV_NAME, DEV_NAME);
  }

  goto exit_bluenoc_probe;

  /* error cleanup code */
 release_irq:
  free_irq(this_board->irq_num, (void*) this_board);
 disable_intr:
  pci_disable_msix(this_board->pci_dev);
 unmap_dma:
  dma_unmap_single(dev_ptr, this_board->buffer_page_bus_addr, PAGE_SIZE, PCI_DMA_FROMDEVICE);
 free_dma_buffer:
  free_page(this_board->buffer_page);
 free_board:
  board_list = this_board->next;
  kfree(this_board);
 unmap_bars:
  if (bar0_io != NULL) pci_iounmap(dev, bar0_io);
  if (bar1_io != NULL) pci_iounmap(dev, bar1_io);
 disable_pci_device:
  pci_disable_device(dev);
  pci_release_regions(dev);

 exit_bluenoc_probe:
  return err;
}

static void __devexit bluenoc_remove(struct pci_dev* dev)
{
  void __iomem* bar0_io = NULL;
  void __iomem* bar1_io = NULL;
  tBoard* this_board = NULL;
  tBoard* prev_board = NULL;
  struct device* dev_ptr = NULL;
  unsigned int i;
  unsigned long long pending;

  /* locate device-specific data for this board */
  for (this_board = board_list; this_board != NULL; prev_board = this_board, this_board = this_board->next) {
    if (this_board->pci_dev == dev) break;
  }
  if (this_board == NULL) {
    printk(KERN_ERR "%s: Unable to locate board when removing PCI device %p\n", DEV_NAME, dev);
    return;
  }

  bar0_io = this_board->bar0io;
  bar1_io = this_board->bar1io;

  pending = readq(bar0_io + 20480);
  printk(KERN_INFO "%s: MSI-X pending bit mask = %llx\n", DEV_NAME, pending);

  /* release the DMA irq */
  disable_irq(this_board->irq_num);
  free_irq(this_board->irq_num, (void*) this_board);

  /* turn of MSI-X interrupts */
  pci_disable_msix(dev);

  /* unmap the DMA buffer and free the memory */
  dev_ptr = &(dev->dev);
  dma_unmap_single(dev_ptr, this_board->buffer_page_bus_addr, PAGE_SIZE, PCI_DMA_FROMDEVICE);
  printk(KERN_INFO "    buffer head = %d  tail = %d", this_board->buffer_head, this_board->buffer_tail);
  for (i = 0; i < 128; i = i + 1)
    printk(KERN_INFO "    buffer[%d] = %x", i, ((char*)this_board->buffer_page)[(i + this_board->buffer_head)%4096] & 0xff);
  free_page(this_board->buffer_page);

  /* unmap BARs */
  if (bar0_io != NULL) pci_iounmap(dev, bar0_io);
  if (bar1_io != NULL) pci_iounmap(dev, bar1_io);

  /* disable the PCI device */
  pci_disable_device(dev);

  /* release the BAR regions */
  pci_release_regions(dev);

  /* free the board structure */
  if (prev_board)
    prev_board->next = this_board->next;
  else
    board_list = this_board->next;
  kfree(this_board);

  /* remove the device file if there are no more boards */
  if (board_list == NULL) {
    /* remove the device nodes via udev and release resources */
    device_destroy(bluenoc_class, device_number);
    class_destroy(bluenoc_class);

    /* delete the device */
    cdev_del(&cdev);

    /* log removal of device */
    printk(KERN_INFO "%s: /dev/%s device file removed\n", DEV_NAME, DEV_NAME);
  }
}

/*
 * interrupt handler
 */

static irqreturn_t intr_handler(int irq, void* dev_id)
{
  // tEmuTarget* emu = dev_id;

  printk(KERN_INFO "%s: got interrupt\n", DEV_NAME);

  return IRQ_HANDLED;
}


/*
 * driver file operations
 */


/* open the device file */
static int bluenoc_open(struct inode *inode, struct file *file)
{
  int err = 0;

  /* increment the open file count */
  open_count += 1;

  /* perform a little test of BAR 1 */
  if (board_list != NULL) {
    tBoard* this_board = board_list;
    void __iomem* bar0_io = this_board->bar0io;
    void __iomem* bar1_io = this_board->bar1io;

    /* enable msg xfers */
    iowrite8(3, bar0_io + 256);           /* enable recv and xmit */
    printk(KERN_INFO "%s: Device is enabled\n", DEV_NAME);

    /* send a write message (via BAR1) */
    printk(KERN_INFO "%s: Writing 0x1234abcd at Node 1 Addr 8\n", DEV_NAME);
    iowrite32(0x84010001, bar1_io); /* header: dst = 1, src = 0, mt = Write, 4B final segment */
    iowrite32(8, bar1_io);          /* addr_at_dst = 8 */
    iowrite32(0x1234abcd, bar1_io); /* payload data */

    /* send a read message (via BAR1) */
    printk(KERN_INFO "%s: Reading from Node 1 Addr 8\n", DEV_NAME);
    iowrite32(0x00120001, bar1_io); /* header: dst = 1, src = 0, mt = Request, length = 4B */
    iowrite32(8, bar1_io);          /* addr_at_dst = 8 */
    iowrite32(0xadd, bar1_io);      /* addr_at_src = add */

    /* wait a little while (10 ms) */
    printk(KERN_INFO "%s: Waiting 10ms...\n", DEV_NAME);
    mdelay(10);

    /* disable msg xfers */
    printk(KERN_INFO "%s: Disabling the device\n", DEV_NAME);
    iowrite8(0, bar0_io + 256);
  }

  /* log the operation */
  printk(KERN_INFO "%s: Opened device\n", DEV_NAME);

  goto exit_bluenoc_open;

 exit_bluenoc_open:
  return err;
}

/* close the device file */
static int bluenoc_release (struct inode *inode, struct file *file)
{
  /* decrement the open file count */
  open_count -= 1;

  /* log the operation */
  printk (KERN_INFO "%s: Closed device\n", DEV_NAME);

  return 0; /* success */
}

/*
 * driver IOCTL operations
 */

#ifdef XXX
static int bluenoc_ioctl(struct inode* inode, struct file* file,
                         unsigned int cmd, unsigned long arg)
{
  int retval = 0;

  /* basic sanity checks */
  if (_IOC_TYPE(cmd) != BS_IOC_MAGIC)
    return -ENOTTY;
  if (_IOC_NR(cmd) > BS_IOC_MAXNR)
    return -ENOTTY;

#ifdef XXX
  /* implement the IOCTL operations */
  switch (cmd) {
    case BS_IOC_XFER:
      retval = copy_from_user(&xfer_info, (tXfer __user *)arg, sizeof(tXfer));
      if (retval == 0) {
        void __iomem* bar_ptr;
        switch (xfer_info.bar) {
          case 0:  bar_ptr = emu->bar0io; break;
          case 1:  bar_ptr = emu->bar1io; break;
          // case 2:  bar_ptr = emu->bar2io; break;
          // case 4:  bar_ptr = emu->bar4io; break;
          default: retval = -EINVAL; break;
        }
        if (retval == 0) {
          void* buffer = emu->buffer;
          if (xfer_info.write != 0) {
            /* perform PCIE write */
            if (xfer_info.bytes == 1) {
              iowrite8(xfer_info.data.v32, bar_ptr + xfer_info.addr);
            } else if (xfer_info.bytes == 2) {
              iowrite16(xfer_info.data.v32, bar_ptr + xfer_info.addr);
            } else if (xfer_info.bytes == 4) {
              iowrite32(xfer_info.data.v32, bar_ptr + xfer_info.addr);
            } else if (xfer_info.bytes == 8) {
              writeq(xfer_info.data.v64, bar_ptr + xfer_info.addr);
            } else {
              copy_from_user(buffer, xfer_info.data.vptr, xfer_info.bytes);
              memcpy_toio(bar_ptr + xfer_info.addr, buffer, xfer_info.bytes);
            }
          } else {
            /* perform PCIE read */
            if (xfer_info.bytes == 1) {
              xfer_info.data.v32 = ioread8(bar_ptr + xfer_info.addr);
            } else if (xfer_info.bytes == 2) {
              xfer_info.data.v32 = ioread16(bar_ptr + xfer_info.addr);
            } else if (xfer_info.bytes == 4) {
              xfer_info.data.v32 = ioread32(bar_ptr + xfer_info.addr);
            } else if (xfer_info.bytes == 8) {
              xfer_info.data.v64 = readq(bar_ptr + xfer_info.addr);
            } else {
              memcpy_fromio(buffer, bar_ptr + xfer_info.addr, xfer_info.bytes);
              copy_to_user(xfer_info.data.vptr, buffer, xfer_info.bytes);
            }
            copy_to_user((tXfer __user *)arg, &xfer_info, sizeof(tXfer));
          }
        }
      }
      break;
    default:
      return -ENOTTY;
  }
#endif

  return retval;
}
#endif
