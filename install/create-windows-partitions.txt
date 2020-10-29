rem == This file is based on: https://goo.gl/R4fjYh
rem == CONFIGURE ME HERE: replace `???` with the correct disk number and remove
rem == the exit line.
exit
select disk ???
clean
convert gpt
rem == 1. UEFI System partition
create partition efi size=550
format quick fs=fat32 label="System"
assign letter="S"
rem == 2. Microsoft Reserved (MSR) partition =======
create partition msr size=16
rem == 3. Recovery tools partition
create partition primary size=500
format quick fs=ntfs label="Recovery tools"
assign letter="R"
set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
gpt attributes=0x8000000000000001
rem == 4. Windows partition
create partition primary size=76875
format quick fs=ntfs label="Windows"
assign letter="W"
list volume
exit
