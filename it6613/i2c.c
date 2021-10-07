/* took code from https://github.com/ultraembedded/ecpix-5/blob/master/sw/drivers/it6613/it6613.c */
/* hacked to have a i2c verilog lut by Hirosh Dabui */
#include <stdio.h>
#include <stdint.h>

#define I2C_DELAY WAIT

static int sda = 1;
static int scl = 1;
static int sda_output = 1;
static int row = 0;

void show_row() {
  printf("%d: {scl, sda, sda_output} = {1'b%d, 1'b%d, 1'b%d};\n", row, scl, sda, sda_output);
  row++;
}

void SDA_HIGH() {
  sda = 1;
  show_row();
}
void SDA_LOW() {
  sda = 0;
  show_row();
}

void SCL_HIGH() {
  scl = 1;
  show_row();
}
void SCL_LOW() {
  scl = 0;
  show_row();
}

void SDA_INPUT() {
  sda_output = 0;
 // show_row();
}
void SDA_OUTPUT() {
  sda_output = 1;
//  show_row();
}
void WAIT() {
 // show_row();
}

void start() {
  printf("/* start */\n");
  SDA_HIGH();
  WAIT();
  SCL_HIGH();
  WAIT();
  SDA_LOW();
  WAIT();
  SCL_LOW();
  WAIT();
}

void stop() {
  printf("/* stop */\n");
  SDA_LOW();
  WAIT();
  SCL_HIGH();
  WAIT();
  SDA_HIGH();
  WAIT();
}

int send(uint8_t data) {
  int ack = 1;
  printf("/* send */\n");
  for (int i = 0; i < 8; i++) {
    (data & 0x80 ) ? SDA_HIGH() : SDA_LOW();
    data <<= 1;
    WAIT();
    SCL_HIGH();
    WAIT();
    SCL_LOW();
    WAIT();
  } 
  SDA_INPUT();
  SDA_HIGH(); SCL_HIGH();
  WAIT();
  SCL_LOW();
//    WAIT();
  // SDA_READ ///read sda should be ack == 0
  SCL_LOW();
  SDA_OUTPUT();  
  return ack;
}

/*
int recv(bool ack) {
  uint_8 data;
  SDA_HIGH;
  for (i = 0; i < 8; i++) {
    data <<= 1;
    do {
      SCL_HIGH;
    } while (SCL_READ == 0)
    WAIT;
    data |= SDA_READ;
    WAIT;
    SCL_LOW;
  }
  ack ? SDA_LOW : SDA_HIGH;
  SCL_HIGH;
  WAIT;
  SCL_LOW;
  SDA_HIGH;
  return data;
}
*/
//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
#define IT6613_I2C_ADDR    (0x98>>1)
#define IT6613_VENDORID     0xCA
#define IT6613_DEVICEID     0x13

#define REG_VENDORID         0x01
#define REG_DEVICEID         0x02
#define REG_CURBANK          0x0F

#define REG_COLOR_DEPTH      0xC1

#define REG_TX_SW_RST       0x04
    #define B_ENTEST            (1<<7)
    #define B_REF_RST           (1<<5)
    #define B_AREF_RST          (1<<4)
    #define B_VID_RST           (1<<3)
    #define B_AUD_RST           (1<<2)
    #define B_HDMI_RST          (1<<1)
    #define B_HDCP_RST          (1<<0)

#define REG_TX_AFE_DRV_CTRL 0x61
    #define B_AFE_DRV_PWD       (1<<5)
    #define B_AFE_DRV_RST       (1<<4)
    #define B_AFE_DRV_PDRXDET   (1<<2)
    #define B_AFE_DRV_TERMON    (1<<1)
    #define B_AFE_DRV_ENCAL     (1<<0)
    
#define REG_TX_AFE_XP_CTRL 0x62
    #define B_AFE_XP_GAINBIT    (1<<7)
    #define B_AFE_XP_PWDPLL     (1<<6)
    #define B_AFE_XP_ENI        (1<<5)
    #define B_AFE_XP_ER0        (1<<4)
    #define B_AFE_XP_RESETB     (1<<3)
    #define B_AFE_XP_PWDI       (1<<2)
    #define B_AFE_XP_DEI        (1<<1)
    #define B_AFE_XP_DER        (1<<0)
    
#define REG_TX_AFE_ISW_CTRL  0x63
    #define B_AFE_RTERM_SEL     (1<<7)
    #define B_AFE_IP_BYPASS     (1<<6)
    #define M_AFE_DRV_ISW       (7<<3)
    #define O_AFE_DRV_ISW       3
    #define B_AFE_DRV_ISWK      7

#define REG_TX_AFE_IP_CTRL 0x64
        
    #define B_AFE_IP_GAINBIT   (1<<7)
    #define B_AFE_IP_PWDPLL    (1<<6)
    #define M_AFE_IP_CKSEL     (3<<4)
    #define O_AFE_IP_CKSEL     4
    #define B_AFE_IP_ER0       (1<<3)
    #define B_AFE_IP_RESETB    (1<<2)
    #define B_AFE_IP_ENC       (1<<1)
    #define B_AFE_IP_EC1       (1<<0)

#define REG_TX_HDMI_MODE   0xC0
    #define B_TX_HDMI_MODE     1
    #define B_TX_DVI_MODE      0

#define REG_TX_GCP          0xC1
    #define B_CLR_AVMUTE       0
    #define B_SET_AVMUTE       1
    #define B_TX_SETAVMUTE     (1<<0)
    #define B_BLUE_SCR_MUTE    (1<<1)
    #define B_NODEF_PHASE      (1<<2)
    #define B_PHASE_RESYNC     (1<<3)


void i2c_stx() {
  start();
}
void i2c_stp() {
  stop();
}
#if 0
//-----------------------------------------------------------------
// i2c_stx: Start sequence
//-----------------------------------------------------------------
static void i2c_stx(void)
{
    gpio_output_set(1 << I2C_SDA_BIT);
    I2C_DELAY;
    gpio_output_set(1 << I2C_SCL_BIT);
    I2C_DELAY;
    gpio_output_clr(1 << I2C_SDA_BIT);
    I2C_DELAY;
    gpio_output_clr(1 << I2C_SCL_BIT);
    I2C_DELAY;
}
//-----------------------------------------------------------------
// i2c_stp: Stop sequence
//-----------------------------------------------------------------
static void i2c_stp(void)
{
    gpio_output_clr(1 << I2C_SDA_BIT);
    I2C_DELAY;
    gpio_output_set(1 << I2C_SCL_BIT);
    I2C_DELAY;
    gpio_output_set(1 << I2C_SDA_BIT);
    I2C_DELAY;
}
#endif
int i2c_tx(uint8_t data) {
  return send(data);
}

//-----------------------------------------------------------------
// i2c_start: Write start + address & RW bit
// Return: 1 if ACK'd, 0 if NACK'd
//-----------------------------------------------------------------
int i2c_start(uint8_t addr, int read)
{
//    int i;

    // Start condition
    i2c_stx();

    addr = addr << 1;
    addr|= read; //ack

    // Write address + RW bit
    return i2c_tx(addr);
}
#if 0
//-----------------------------------------------------------------
// i2c_tx:
//-----------------------------------------------------------------
static int i2c_tx(uint8_t data)
{
    int b;

    for(int x=0; x<8; x++)
    {
        if (data & 0x80) 
            gpio_output_set(1 << I2C_SDA_BIT);
        else 
           gpio_output_clr(1 << I2C_SDA_BIT);

        I2C_DELAY;
        gpio_output_set(1 << I2C_SCL_BIT);
        I2C_DELAY;

        gpio_output_clr(1 << I2C_SCL_BIT);   
        data <<= 1;
    }

    gpio_output_set(1 << I2C_SDA_BIT);
    I2C_DELAY;

    gpio_output_set(1 << I2C_SCL_BIT);
    b = gpio_input_bit(I2C_SDA_BIT);

    I2C_DELAY;
    gpio_output_clr(1 << I2C_SCL_BIT);
    gpio_output_set(1 << I2C_SDA_BIT);

    return !b;
}
#endif
//-----------------------------------------------------------------
// i2c_write: Write a byte of data.
//            If last, generate a STOP condition.
// Return: 1 if ACK'd, 0 if NACK'd
//-----------------------------------------------------------------
static int i2c_write(uint8_t data, int last)
{
    // Write byte, get ACK
    int res = i2c_tx(data);

    // If last, generate STOP
    if (last)
        i2c_stp();

    return res;
}
//-----------------------------------------------------------------
// i2c_byte_write: Perform a single byte write
// Return: ACK (1) or NACK (0)
//-----------------------------------------------------------------
int i2c_byte_write(uint8_t dev_addr, uint8_t reg_addr, uint8_t data)
{
    int res = 1;

    // AD+W -> ACK
    if (!i2c_start(dev_addr, 0))
        res = 0;

    // ADDR -> ACK
    if (!i2c_write(reg_addr, 0))
        res = 0;

    // DATA -> ACK
    if (!i2c_write(data, 1))
        res = 0;

    return res;
}

#if 0
//-----------------------------------------------------------------
// it6613_read_byte: I2C byte read
//-----------------------------------------------------------------
static inline uint8_t it6613_read_byte(uint32_t regaddr)
{
    uint8_t data = 0;
    i2c_byte_read(IT6613_I2C_ADDR, regaddr, &data);
    return data;
}
#endif
//-----------------------------------------------------------------
// it6613_write_byte: I2C byte write
//-----------------------------------------------------------------
static inline void it6613_write_byte(uint32_t regaddr, uint8_t data)
{
    i2c_byte_write(IT6613_I2C_ADDR, regaddr, data);
}
//-----------------------------------------------------------------
// it6613_enable_dvi: Basic init to enable DVI mode (RGB444 in, out)
//-----------------------------------------------------------------
int it6613_enable_dvi(uint32_t pixel_clock_hz)
{
    uint32_t vendor_id;
    uint32_t device_id;


    // Set to bank 0
    it6613_write_byte(REG_CURBANK, 0);

#if 0
    // Check device ID
    vendor_id = it6613_read_byte(REG_VENDORID);
    device_id = it6613_read_byte(REG_DEVICEID);

    printf("ITI6613: Vendor ID: 0x%.2lX (should be 0xCA), device ID: 0x%.2lX (should be 0x13)\n", vendor_id, device_id);
    if (vendor_id != IT6613_VENDORID || device_id != IT6613_DEVICEID)
    {
        printf("ERROR: Bad device ID\n");
        return -1;
    }
#endif
    // Reset
    it6613_write_byte(REG_TX_SW_RST,B_REF_RST|B_VID_RST|B_AUD_RST|B_AREF_RST|B_HDCP_RST);
//    timer_sleep(1);
    //WAIT;
    it6613_write_byte(REG_TX_SW_RST,0);

    // Select DVI mode
    it6613_write_byte(REG_TX_HDMI_MODE,B_TX_DVI_MODE);

    // Configure clock ring    
    it6613_write_byte(REG_TX_SW_RST, B_AUD_RST|B_AREF_RST|B_HDCP_RST);
    it6613_write_byte(REG_TX_AFE_DRV_CTRL,B_AFE_DRV_RST);

    if (pixel_clock_hz > 80000000)
    {
        it6613_write_byte(REG_TX_AFE_XP_CTRL,  0x88);
        it6613_write_byte(REG_TX_AFE_ISW_CTRL, 0x10);
        it6613_write_byte(REG_TX_AFE_IP_CTRL,  0x84);
    }
    else
    {
        it6613_write_byte(REG_TX_AFE_XP_CTRL,  0x18);
        it6613_write_byte(REG_TX_AFE_ISW_CTRL, 0x10);
        it6613_write_byte(REG_TX_AFE_IP_CTRL,  0x0C);
    }

    WAIT;//timer_sleep(1);

    // color depth
//    it6613_write_byte(REG_COLOR_DEPTH, 0b100<<4);
    //it6613_write_byte(0x70, 0);
    
    // Enable clock ring
    it6613_write_byte(REG_TX_AFE_DRV_CTRL,0);

    // Enable video
    it6613_write_byte(REG_TX_GCP, 0);
    
    return 0;
}


void main() {
  it6613_enable_dvi(25*1000*1000); // 25 MHz Video
}
