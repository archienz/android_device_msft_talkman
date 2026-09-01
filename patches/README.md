# Local patches (kernel / CAF HALs)

These are not pushed to LineageOS or Android4Lumia950 remotes. Apply from the
matching tree root:

    cd kernel/mmo/msm8994
    git apply ../../../device/msft/talkman/patches/<kernel-file>

    cd hardware/qcom/<project>
    git apply ../../../device/msft/talkman/patches/<hal-file>

RM-1104 / 4VM_08r only. No schematic PDF. Delete a patch once it has landed
in the owned tree.
