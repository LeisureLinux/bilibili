#### 如何在 macOS 上使用 QEMU 创建 Linux 虚拟机（而不是 Virtualbox）
 0. [B站讲解视频](https://www.bilibili.com/video/BV1fq4y1h7e1/)
 1. brew install qemu libvirt
 2. brew services start libvirt
 3. virsh define --file ubuntu-01.xml
 4. virsh start ubuntu-01
 5. 注意事项：
   - 虚拟机的 Domain Name ubuntu-01 可以自行修改
   - 内存数量和CPU 数量根据自己的需要修改
   - qcow2 的 source 修改成自己的 qcow2 文件路径
   - VNC 的端口号 5999 和 ssh 端口 2222 可以根据自己的需要修改
   - QEMU 网络故意修改成了 192.168.76.0/24，如果去掉 net= 和 dhcpstart 可以恢复为默认 10.0.2.0
   - 如果不能 ssh 进入，需要自己解决虚拟机的网络配置，NetManager 的话，可以用 nmtui 命令修改，如果是 NetPlan 的话，修改网络配置文件后，用 netplan apply 生效

 Appendix. $ cat ubuntu-01.xml
 <domain type='qemu' id='1' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <name>ubuntu-01</name>
  <memory unit='KiB'>1953792</memory>
  <currentMemory unit='KiB'>1953128</currentMemory>
  <vcpu placement='static'>2</vcpu>
  <os>
    <type arch='x86_64' machine='pc-q35-6.2'>hvm</type>
    <boot dev='hd'/>
    <bootmenu enable='yes'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='custom' match='exact' check='full'>
    <model fallback='forbid'>Westmere</model>
    <feature policy='require' name='vme'/>
    <feature policy='require' name='pclmuldq'/>
    <feature policy='require' name='hypervisor'/>
    <feature policy='require' name='arat'/>
  </cpu>
  <clock offset='localtime'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/local/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='qcow2-imagefile.qcow2' index='1'/>
      <backingStore/>
      <target dev='vda' bus='virtio'/>
      <alias name='virtio-disk0'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
    </disk>
    <controller type='usb' index='0' model='ehci'>
      <alias name='usb'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x01' function='0x0'/>
    </controller>
    <controller type='sata' index='0'>
      <alias name='ide'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pcie-root'>
      <alias name='pcie.0'/>
    </controller>
    <controller type='pci' index='1' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='1' port='0x10'/>
      <alias name='pci.1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
    </controller>
    <controller type='pci' index='2' model='pcie-to-pci-bridge'>
      <model name='pcie-pci-bridge'/>
      <alias name='pci.2'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </controller>
    <controller type='pci' index='3' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='3' port='0x11'/>
      <alias name='pci.3'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
    </controller>
    <controller type='pci' index='4' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='4' port='0x12'/>
      <alias name='pci.4'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
    </controller>
    <controller type='pci' index='5' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='5' port='0x13'/>
      <alias name='pci.5'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
    </controller>
    <serial type='pty'>
      <source path='/dev/ttys000'/>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/ttys000'>
      <source path='/dev/ttys000'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='tablet' bus='usb'>
      <alias name='input0'/>
      <address type='usb' bus='0' port='1'/>
    </input>
    <input type='keyboard' bus='usb'>
      <alias name='input1'/>
      <address type='usb' bus='0' port='2'/>
    </input>
    <input type='mouse' bus='ps2'>
      <alias name='input2'/>
    </input>
    <input type='keyboard' bus='ps2'>
      <alias name='input3'/>
    </input>
    <graphics type='vnc' port='5999' autoport='no' listen='127.0.0.1'>
      <listen type='address' address='127.0.0.1'/>
    </graphics>
    <audio id='1' type='none'/>
    <video>
      <model type='virtio' vram='16384' heads='1' primary='yes'/>
      <alias name='video0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
    </memballoon>
  </devices>
  <seclabel type='none' model='none'/>
  <qemu:commandline>
    <qemu:arg value='-machine'/>
    <qemu:arg value='type=q35,accel=hvf'/>
    <qemu:arg value='-netdev'/>
    <qemu:arg value='user,id=n1,hostfwd=tcp::2222-:22,net=192.168.76.0/24,dhcpstart=192.168.76.99'/>
    <qemu:arg value='-device'/>
    <qemu:arg value='virtio-net-pci,netdev=n1,bus=pcie.0,addr=0x19'/>
  </qemu:commandline>
</domain>

