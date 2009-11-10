# ----------------------------------------------------------------------------
# Hyper Operating System V4 Advance
#
# Copyright (C) 1998-2008 by Project HOS
# http://sourceforge.jp/projects/hos/
# ----------------------------------------------------------------------------



# --------------------------------------
#  %jp{�e��ݒ�}{setting}
# --------------------------------------

# %jp{�^�[�Q�b�g��}%en{target name}
TARGET ?= sample


# %jp{�c�[����`}%en{tools}
GCC_ARCH    ?= mips-elf-
CMD_CC      ?= $(GCC_ARCH)gcc
CMD_ASM     ?= $(GCC_ARCH)gcc
CMD_LINK    ?= $(GCC_ARCH)gcc
CMD_OBJCNV  ?= $(GCC_ARCH)objcopy
CMD_OBJDUMP ?= $(GCC_ARCH)objdump



# %jp{�A�[�L�e�N�`����`}%en{architecture}
ARCH_NAME ?= jelly
ARCH_CC   ?= gcc
EXT_EXE   ?= elf


# %jp{�f�B���N�g����`}%en{directories}
HOS_DIR           = $(HOME)/hos-v4a
KERNEL_DIR        = $(HOS_DIR)/kernel
KERNEL_CFGRTR_DIR = $(HOS_DIR)/cfgrtr/build/gcc
KERNEL_MAKINC_DIR = $(KERNEL_DIR)/build/common/gmake
KERNEL_BUILD_DIR  = $(KERNEL_DIR)/build/mips/jelly/gcc
TOOLS_DIR         = ../../../../../tools


# %jp{�R���t�B�M�����[�^��`}
KERNEL_CFGRTR = $(KERNEL_CFGRTR_DIR)/h4acfg-$(ARCH_NAME)


# %jp{���ʒ�`�Ǎ���}%jp{common setting}
include $(KERNEL_MAKINC_DIR)/common.inc


# %jp{�����J�X�N���v�g}%en{linker script}
LINK_SCRIPT = rom.lds


# %jp{����RAM}%en{internal RAM}
ifeq ($(MEMMAP),ram)
LINK_SCRIPT  = ram.lds
TARGET      := $(TARGET)_ram
endif


# %jp{�p�X�ݒ�}%en{add source directories}
INC_DIRS += . ..
SRC_DIRS += . ..


# %jp{�I�v�V�����t���O}%en{option flags}
AFLAGS  = -march=mips1 -msoft-float -G 0
CFLAGS  = -march=mips1 -msoft-float -G 0
LNFLAGS = -march=mips1 -msoft-float -G 0 -nostartfiles -Wl,-Map,$(TARGET).map,-T$(LINK_SCRIPT)


# %jp{�R���p�C���ˑ��̐ݒ�Ǎ���}%en{compiler dependent definitions}
include $(KERNEL_MAKINC_DIR)/$(ARCH_CC)_d.inc

# %jp{���s�t�@�C�������p�ݒ�Ǎ���}%en{definitions for exection file}
include $(KERNEL_MAKINC_DIR)/makexe_d.inc


# %jp{�o�̓t�@�C����}%en{output files}
TARGET_EXE = $(TARGET).$(EXT_EXE)
TARGET_BIN = $(TARGET).$(EXT_BIN)

TARGETS = $(TARGET_EXE) $(TARGET_BIN)



# --------------------------------------
#  %jp{�\�[�X�t�@�C��}%en{source files}
# --------------------------------------

# %jp{�A�Z���u���t�@�C���̒ǉ�}%en{assembry sources}
ASRCS += ./crt0.S


# %jp{C����t�@�C���̒ǉ�}%en{C sources}
CSRCS += ../main.c
CSRCS += ../kernel_cfg.c
CSRCS += ../sample.c
CSRCS += ../uart.c
CSRCS += ../ostimer.c



# --------------------------------------
#  %jp{���[����`}%en{rules}
# --------------------------------------

# %jp{ALL}%en{all}
.PHONY : all
all: kernel_make makeexe_all $(TARGETS)
	$(CMD_OBJDUMP) -D $(TARGET_EXE)            > $(TARGET).das
	$(TOOLS_DIR)/bin2hex.pl $(TARGET_BIN) 4096 > $(TARGET).hex

.PHONY : run
run: $(TARGET_BIN)
	jelly_loader -r $(TARGET_BIN)

# %jp{�N���[��}%en{clean}
.PHONY : clean
clean: makeexe_clean
	rm -f $(TARGETS) $(TARGET).hex $(OBJS) ../kernel_cfg.c ../kernel_id.h

# %jp{�ˑ��֌W�X�V}%en{depend}
.PHONY : depend
depend: makeexe_depend

# %jp{�\�[�X�ꊇ�R�s�[}%en{source files copy}
.PHONY : srccpy
srccpy: makeexe_srccpy

# %jp{�J�[�l�����ƃN���[��}%en{mostlyclean}
.PHONY : mostlyclean
mostlyclean: clean kernel_clean


# %jp{�R���t�B�M�����[�^���s}%en{configurator}
../kernel_cfg.c ../kernel_id.h: ../system.cfg $(KERNEL_CFGRTR)
	cpp -E ../system.cfg ../system.i
	$(KERNEL_CFGRTR) ../system.i -c ../kernel_cfg.c -i ../kernel_id.h


# %jp{���s�t�@�C�������p�ݒ�Ǎ���}%en{rules for exection file}
include $(KERNEL_MAKINC_DIR)/makexe_r.inc

# %jp{�R���p�C���ˑ��̃��[����`�Ǎ���}%en{rules for compiler}
include $(KERNEL_MAKINC_DIR)/$(ARCH_CC)_r.inc




# --------------------------------------
#  %jp{�ˑ��֌W}%en{dependency}
# --------------------------------------

$(TARGET_EXE): $(LINK_SCRIPT)

$(OBJS_DIR)/sample.$(EXT_OBJ) : ../kernel_id.h



# end of file

