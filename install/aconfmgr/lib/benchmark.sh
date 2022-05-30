# AddPackage hdparm # A shell utility for manipulating Linux IDE drive/driver parameters
AddPackage i7z # A better i7 (and now i3, i5) reporting tool for Linux
# AddPackage bonnie++ # Based on the Bonnie hard drive benchmark by Tim Bray
AddPackage stress # A tool that stress tests your system (CPU, memory, I/O, disks)
# AddPackage sysbench # Scriptable multi-threaded benchmark tool for databases and systems
AddPackage gsmartcontrol # A graphical user interface for the smartctl hard disk drive health inspection tool.
AddPackage nvme-cli      # NVM-Express user space tooling for Linux
IgnorePath '/etc/nvme/*'
# AddPackage --foreign linpack # Benchmark based on linear algebra excellent app for stress testing.
# AddPackage --foreign mprime-bin # A GIMPS, distributed computing project client, dedicated to finding Mersenne primes. Precompiled binary version.
# AddPackage --foreign systester-cli # System Stability Tester is a RAM/CPU burning and benchmarking program based on calculating pi.

# For memtest, the Arch installation can be used without installing from the AUR
# AddPackage --foreign memtest86-efi # A free, thorough, stand alone memory test as an EFI application
# CopyFile /boot/efi/EFI/memtest86/blacklist.cfg 755
# CopyFile /boot/efi/EFI/memtest86/MemTest86.log 755
# CopyFile /boot/efi/EFI/memtest86/memtestx64.efi 755
# CopyFile /boot/efi/EFI/memtest86/mt86.png 755
# CopyFile /boot/efi/EFI/memtest86/unifont.bin 755
# CopyFile /etc/memtest86-efi/memtest86-efi.conf
