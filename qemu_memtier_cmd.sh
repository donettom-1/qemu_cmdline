ROOT_DISK=jammy-server-cloudimg-ppc64el.img
KERNEL=vmlinux
KERNEL_ARGS='root=/dev/vda1 ro console=hvc0 earlyprintk rootfstype=ext4'

QEMU_MONITOR_PORT=55555
cmd_monitor="-monitor telnet:127.0.0.1:$QEMU_MONITOR_PORT,server,nowait -serial mon:stdio "

PMEM_DISK_1=/run/1.img
PMEM_SIZE=$(expr 10737418240 + 131072)

file $KERNEL | grep "LSB executable"
if [ $? -ne 0 ]; then
        echo "Not a LE kernel"
        exit 1;
fi

qemu-system-ppc64 \
    -m size=100G,slots=32,maxmem=180G \
    -smp 40,threads=4 \
    -enable-kvm \
    -machine pseries,nvdimm=on,cap-htm=off,kernel-irqchip=off,cap-ccf-assist=off,cap-cfpc=broken   \
    -kernel $KERNEL -append "$KERNEL_ARGS"  \
    -vga none -nographic \
    -drive file=$ROOT_DISK,if=virtio,format=qcow2 \
    -net nic,model=virtio -net user,hostfwd=tcp:127.0.0.1:2001-:22 -gdb tcp::1235 \
    -object memory-backend-ram,size=50G,id=mem0 \
    -object memory-backend-ram,size=50G,id=mem1 \
    -numa node,cpus=0-11,memdev=mem0 \
    -numa node,cpus=12-37,memdev=mem1 \
    -numa node \
    -object memory-backend-file,id=memnvdimm1,prealloc=yes,mem-path=$PMEM_DISK_1,share=yes,size=${PMEM_SIZE}  \
    -device nvdimm,label-size=128K,memdev=memnvdimm1,id=nvdimm1,slot=1,node=2,uuid=72511b67-0b3b-42fd-8d1d-5be3cae8bcaa \
