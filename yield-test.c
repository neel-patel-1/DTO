#include <linux/idxd.h>
#include <sched.h>
#include <x86intrin.h>
#include <limits.h>
/* When using threads that yield to each other ... When using threads that block for offload completion ...
Responsiveness ...
*/

#define UMWAIT_DELAY 100000
/* C0.1 state */
#define UMWAIT_STATE 1


struct dto_wq {
	struct accfg_wq *acc_wq;
	char wq_path[PATH_MAX];
	uint64_t dsa_gencap;
	int wq_size;
	uint32_t max_transfer_size;
	int wq_fd;
	void *wq_portal;
};

static __always_inline void umonitor(const volatile void *addr)
{
	asm volatile(".byte 0xf3, 0x48, 0x0f, 0xae, 0xf0" : : "a"(addr));
}

static __always_inline int umwait(unsigned long timeout, unsigned int state)
{
	uint8_t r;
	uint32_t timeout_low = (uint32_t)timeout;
	uint32_t timeout_high = (uint32_t)(timeout >> 32);

	asm volatile(".byte 0xf2, 0x48, 0x0f, 0xae, 0xf1\t\n"
		"setc %0\t\n"
		: "=r"(r)
		: "c"(state), "a"(timeout_low), "d"(timeout_high));
	return r;
}

static __always_inline void dsa_wait_yield(const volatile uint8_t *comp)
{
	while (*comp == 0)
		sched_yield();
}

static __always_inline void __dsa_wait_umwait(const volatile uint8_t *comp)
{
	umonitor(comp);

	// Hardware never writes 0 to this field. Software should initialize this field to 0
	// so it can detect when the completion record has been written
	if (*comp == 0) {
		uint64_t delay = __rdtsc() + UMWAIT_DELAY;

		umwait(delay, UMWAIT_STATE);
	}
}

static __always_inline void dsa_wait_umwait(const volatile uint8_t *comp)
{

	while (*comp == 0)
		__dsa_wait_umwait(comp);
}

static __always_inline void dsa_wait_busy_poll(const volatile uint8_t *comp)
{
	while (*comp == 0){}
		_mm_pause();
}

int main(){
  struct dsa_completion_record comp __attribute__((aligned(32)));
  dsa_wait_yield(&comp);
}