include scripts/kconfig/Makefile
-include .config

CC = gcc
LD = $(CC)
CFLAGS =
LDFLAGS =

INITSRC = src/init/fastrc.c
INITOBJ = src/init/fastrc.o
CTLSRC = src/ctl/fastctl.c
CTLOBJ = src/ctl/fastctl.o
ALLSRC = $(INITSRC) $(CTLSRC)
ALLOBJ = $(INITOBJ) $(CTLOBJ)

ifeq ($(CONFIG_STATIC),y)
LDFLAGS += -static
endif

ifeq ($(CONFIG_TARGET_I386),y)
CFLAGS += -m32
LDFLAGS += -m32
else ifeq ($(CONFIG_TARGET_X86_64),y)
CFLAGS += -m64
LDFLAGS += -m64
endif

all: configcheck output/fastrc output/fastctl

configcheck:
	@if [ ! -f .config ]; then \
		echo ".config dosen't exist, please run 'make menuconfig'."; \
		exit 1; \
	fi

src/init/%.o: src/init/%.c configcheck
	@echo "  CC      $@"
	@$(CC) $(CFLAGS) -c $< -o $@

src/ctl/%.o: src/ctl/%.c configcheck
	@echo "  CC      $@"
	@$(CC) $(CFLAGS) -c $< -o $@

output/fastrc: configcheck $(INITOBJ)
	@[ -d output ] || mkdir output
	@echo "  LD      $@"
	@$(LD) $(LDFLAGS) -o $@ $(INITOBJ)
	@echo "  STRIP   $@"
	@strip $@

output/fastctl: configcheck $(CTLOBJ)
	@[ -d output ] || mkdir output
	@echo "  LD      $@"
	@$(LD) $(LDFLAGS) -o $@ $(CTLOBJ)
	@echo "  STRIP   $@"
	@strip $@
	@echo "  LN      $@ -> output/poweroff"
	@cd output && { [ ! -f poweroff ] || rm -f poweroff; ln -s fastctl poweroff; }
	@echo "  LN      $@ -> output/reboot"
	@cd output && { [ ! -f reboot ] || rm -f reboot; ln -s fastctl reboot; }

menuconfig: scripts/kconfig/mconf
	@scripts/kconfig/mconf Kconfig

clean:
	@echo "  RM      src/*.o output"
	@rm -rf $(ALLOBJ) output

mrproper:
	@echo "  RM      src/*.o output"
	@rm -rf $(ALLOBJ) output
	@echo "  RM      include"
	@rm -rf include
	@echo "  RM      scripts/kconfig/mconf scripts/kconfig/conf scripts/kconfig/*.o scripts/kconfig/lxdialog/*.o .config .config.old"
	@rm -f scripts/kconfig/mconf scripts/kconfig/conf scripts/kconfig/*.o scripts/kconfig/lxdialog/*.o .config .config.old
