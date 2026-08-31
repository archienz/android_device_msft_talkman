# CAF librmnetctl/rmnetcli: MSM8992 rmnet_data netlink (IPA/BAM, DATA5_CNTL).
# Leftover bullhead QMI userspace kept. Not rild. RIL is P2 Not Working.

ifneq ($(filter talkman, $(TARGET_DEVICE)),)
include $(call all-subdir-makefiles)
endif

