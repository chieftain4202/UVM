/******************************************************************************
 * MicroBlaze + four 4-bit custom AXI GPIO FND up counter
 *
 * GPIO_0 @ 0x44A00000 : btn[3:0] input
 * GPIO_1 @ 0x44A10000 : fnd_digit[3:0] output, active-low
 * GPIO_2 @ 0x44A20000 : fnd_data_high[3:0] output, segment[7:4]
 * GPIO_3 @ 0x44A30000 : fnd_data_low[3:0] output, segment[3:0]
 *
 * Button test mode:
 * - no button pressed: auto up counter
 * - button pressed   : display raw btn[3:0] value as 0001, 0002, 0004, 0008
 ******************************************************************************/

#include <stdint.h>
#include "platform.h"
#include "xil_printf.h"
#include "sleep.h"

#define GPIO_0_BASE 0x44A00000U
#define GPIO_1_BASE 0x44A10000U
#define GPIO_2_BASE 0x44A20000U
#define GPIO_3_BASE 0x44A30000U

#define GPIO_CR(base)  (*(volatile uint32_t *)((base) + 0x00U))
#define GPIO_IDR(base) (*(volatile uint32_t *)((base) + 0x04U))
#define GPIO_ODR(base) (*(volatile uint32_t *)((base) + 0x08U))

#define BTN_BASE      GPIO_0_BASE
#define DIGIT_BASE    GPIO_1_BASE
#define SEG_HIGH_BASE GPIO_2_BASE
#define SEG_LOW_BASE  GPIO_3_BASE

#define COUNTER_PERIOD_MS 100U
#define SCAN_DELAY_US     1000U
#define DEBUG_COUNTER     1

static const uint8_t seg_lut[10] = {
    0xC0, /* 0 */
    0xF9, /* 1 */
    0xA4, /* 2 */
    0xB0, /* 3 */
    0x99, /* 4 */
    0x92, /* 5 */
    0x82, /* 6 */
    0xF8, /* 7 */
    0x80, /* 8 */
    0x90  /* 9 */
};

static void fnd_write_digit(uint8_t digit, uint8_t value)
{
    uint8_t segment = seg_lut[value];
    uint8_t digit_sel = (uint8_t)(~(1U << digit) & 0x0FU);

    GPIO_ODR(DIGIT_BASE) = digit_sel;
    GPIO_ODR(SEG_LOW_BASE) = segment & 0x0FU;
    GPIO_ODR(SEG_HIGH_BASE) = (segment >> 4) & 0x0FU;
}

static void fnd_display_scan(uint16_t value)
{
    uint8_t digits[4];

    digits[0] = value % 10U;
    digits[1] = (value / 10U) % 10U;
    digits[2] = (value / 100U) % 10U;
    digits[3] = (value / 1000U) % 10U;

    for (uint8_t i = 0; i < 4U; i++) {
        fnd_write_digit(i, digits[i]);
        usleep(SCAN_DELAY_US);
    }
}

int main(void)
{
    uint16_t counter = 0;
    uint32_t elapsed_ms = 0;
#if DEBUG_COUNTER
    uint32_t debug_div = 0;
#endif

    init_platform();

    GPIO_CR(BTN_BASE) = 0x0U;
    GPIO_CR(DIGIT_BASE) = 0xFU;
    GPIO_CR(SEG_HIGH_BASE) = 0xFU;
    GPIO_CR(SEG_LOW_BASE) = 0xFU;

    GPIO_ODR(DIGIT_BASE) = 0xFU;
    GPIO_ODR(SEG_HIGH_BASE) = 0xFU;
    GPIO_ODR(SEG_LOW_BASE) = 0xFU;

    xil_printf("FND button input test start\r\n");

    while (1) {
        uint32_t btn = GPIO_IDR(BTN_BASE) & 0x0FU;
        uint16_t display_value = (btn != 0U) ? (uint16_t)btn : counter;

#if DEBUG_COUNTER
        if (++debug_div >= 50U) {
            debug_div = 0;
            xil_printf("BTN_IDR=0x%01x CNT=%d\r\n",
                       (unsigned int)btn,
                       counter);
        }
#endif

        fnd_display_scan(display_value);
        elapsed_ms += 4U;

        if (elapsed_ms >= COUNTER_PERIOD_MS) {
            elapsed_ms = 0U;
            counter++;
            if (counter > 9999U) {
                counter = 0U;
            }
        }
    }

    cleanup_platform();
    return 0;
}
