# Prerequisites

## Table of Contents
1. [Hardware Requirements](#hardware-requirements)
2. [Software Requirements](#software-requirements)
3. [Knowledge Requirements](#knowledge-requirements)
4. [Development Environment Setup](#development-environment-setup)
5. [Test Signing Mode](#test-signing-mode)

---

## Hardware Requirements

### Minimum Requirements
- **CPU**: Intel Core i5 or AMD Ryzen 5 (4 cores)
- **RAM**: 8GB (16GB recommended)
- **Storage**: 50GB free space
- **Virtualization**: VT-x (Intel) or AMD-V enabled in BIOS

### Checking VT-x/AMD-V Support

#### Method 1: CPU-Z
1. Download CPU-Z
2. Check "Instructions" tab
3. Look for:
   - Intel: `VT-x`
   - AMD: `AMD-V`

#### Method 2: Task Manager (Windows 10/11)
1. Open Task Manager (`Ctrl+Shift+Esc`)
2. Go to Performance tab
3. Click CPU
4. Check "Virtualization: Enabled"

#### Method 3: Command Line
```powershell
systeminfo | findstr /C:"Virtualization"
```

Should show: `Virtualization Enabled In Firmware: Yes`

### Enabling Virtualization in BIOS

**Intel VT-x:**
1. Reboot and enter BIOS (usually `Del`, `F2`, or `F12`)
2. Navigate to Advanced Settings
3. Find "Intel Virtualization Technology" or "VT-x"
4. Set to **Enabled**
5. Save and exit

**AMD-V:**
1. Reboot and enter BIOS
2. Navigate to Advanced Settings
3. Find "SVM Mode" or "AMD-V"
4. Set to **Enabled**
5. Save and exit

---

## Software Requirements

### Operating System
- **Windows 10 (64-bit)** - Version 1809 or later
- **Windows 11 (64-bit)** - Any version
- **NOTE**: 32-bit Windows is NOT supported

### Development Tools

#### 1. Visual Studio 2022
- **Edition**: Community (free), Professional, or Enterprise
- **Workload**: Desktop development with C++

**Download**: https://visualstudio.microsoft.com/

**Installation Steps:**
1. Download Visual Studio Installer
2. Select "Desktop development with C++"
3. Optional components:
   - C++ ATL for latest build tools
   - C++ MFC for latest build tools
4. Install

#### 2. Windows Driver Kit (WDK)
- **Version**: WDK for Windows 11, version 22H2

**Download**: https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk

**Installation Steps:**
1. Install Visual Studio first (see above)
2. Download WDK installer
3. Run installer
4. Select all components
5. Install

**Verify Installation:**
```cmd
dir "C:\Program Files (x86)\Windows Kits\10\Include\wdf"
```

Should show driver headers.

#### 3. Windows SDK
Usually installed with Visual Studio, but can be installed separately:

**Download**: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/

#### 4. Debugging Tools

**WinDbg Preview** (Recommended):
- Download from Microsoft Store
- Or download standalone: https://aka.ms/windbg/download

**Classic WinDbg**:
- Included in Windows SDK

---

## Knowledge Requirements

### Essential Knowledge

#### 1. **C Programming** (Required)
- Pointers and memory management
- Structures and unions
- Bit manipulation
- Function pointers
- Preprocessor directives

#### 2. **x86/x64 Assembly** (Recommended)
- Basic instructions (`MOV`, `ADD`, `SUB`, etc.)
- Registers (`RAX`, `RBX`, `RCX`, `RDX`, etc.)
- Stack operations (`PUSH`, `POP`, `CALL`, `RET`)
- Special instructions (`CPUID`, `RDMSR`, `WRMSR`)

#### 3. **Operating System Concepts** (Required)
- Process vs. Thread
- Virtual memory and paging
- Privilege levels (Ring 0 vs Ring 3)
- Kernel vs. User mode
- Device drivers

#### 4. **Windows Driver Development** (Recommended)
- Driver entry point (`DriverEntry`)
- IRP (I/O Request Packet) handling
- IOCTL communication
- Driver unload routines

#### 5. **Virtualization Concepts** (Required)
- What is a hypervisor
- Type 1 vs. Type 2 hypervisors
- Guest vs. Host
- VM exits and VM entries
- VMCS (Intel) or VMCB (AMD)

### Learning Resources

**Books:**
- "Intel® 64 and IA-32 Architectures Software Developer's Manual" (Free PDF from Intel)
- "Windows Kernel Programming" by Pavel Yosifovich
- "Windows Internals" by Mark Russinovich

**Online:**
- Intel Developer Zone: https://software.intel.com/
- OSdev Wiki: https://wiki.osdev.org/
- Windows Driver Samples: https://github.com/Microsoft/Windows-driver-samples

---

## Development Environment Setup

### Step 1: Visual Studio Configuration

1. **Open Visual Studio 2022**

2. **Create Test Project** (verify setup):
```
File → New → Project → Windows Kernel Mode Driver (KMDF)
```

3. **Set Platform to x64**:
```
Configuration Manager → Active Solution Platform → x64
```

4. **Test Build**:
```
Build → Build Solution (Ctrl+Shift+B)
```

### Step 2: Driver Signature Settings

For development and testing, you need to enable test signing.

#### Enable Test Signing (Admin PowerShell):
```powershell
bcdedit /set testsigning on
bcdedit /set nointegritychecks on
```

**Reboot required.**

#### Verify Test Signing:
After reboot, you should see "Test Mode" watermark in bottom-right corner of desktop.

#### Disable Test Signing (when done):
```powershell
bcdedit /set testsigning off
bcdedit /set nointegritychecks off
```

### Step 3: Debugging Setup

#### Kernel Debugging Over Serial (Recommended for VMs):

**Host Machine:**
```cmd
bcdedit /debug on
bcdedit /dbgsettings serial debugport:1 baudrate:115200
```

**VM Configuration** (VMware/VirtualBox):
- Add serial port
- Use named pipe or COM port
- Connect to WinDbg on host

#### Kernel Debugging Over Network:

```cmd
bcdedit /debug on
bcdedit /dbgsettings net hostip:192.168.1.100 port:50000 key:1.2.3.4
```

Replace with your actual host IP and choose a random key.

### Step 4: Safety Measures

#### Create VM for Testing

**DO NOT test kernel drivers on your main system!**

**Recommended VMs:**
- VMware Workstation Pro
- VirtualBox (free)
- Hyper-V (Windows 11 Pro)

**VM Configuration:**
- 2-4 CPU cores
- 4-8GB RAM
- 50GB disk
- Enable VT-x/AMD-V passthrough (if supported)

#### Snapshot Before Testing

Always create a VM snapshot before loading the driver:
```
VMware: VM → Snapshot → Take Snapshot
VirtualBox: Machine → Take Snapshot
```

---

## Test Signing Mode

### What is Test Signing?

Windows requires all kernel drivers to be **digitally signed**. For development:
- **Production**: Microsoft-signed certificate (requires approval)
- **Development**: Test signing mode (self-signed certificates)

### Enabling Test Signing

```cmd
bcdedit /set testsigning on
```

### Creating Test Certificate

```powershell
# Create self-signed certificate
makecert -r -pe -ss PrivateCertStore -n "CN=MyTestCert" MyTestCert.cer

# Install certificate
certmgr.exe /add MyTestCert.cer /s /r localMachine root
```

### Signing Your Driver

```cmd
signtool sign /v /s PrivateCertStore /n "MyTestCert" /t http://timestamp.digicert.com HypervisorSpoofer.sys
```

### Verifying Signature

```cmd
signtool verify /v /pa HypervisorSpoofer.sys
```

---

## Verification Checklist

Before proceeding to implementation, verify:

- [ ] VT-x/AMD-V enabled in BIOS
- [ ] Visual Studio 2022 installed with C++ workload
- [ ] WDK installed and integrated with Visual Studio
- [ ] Test signing mode enabled
- [ ] VM created for testing
- [ ] VM snapshot taken
- [ ] WinDbg installed and configured
- [ ] Serial/network debugging configured
- [ ] Basic C knowledge
- [ ] Basic assembly knowledge
- [ ] Understanding of OS concepts

---

## Common Issues

### Issue: "VT-x is disabled" error

**Solution:**
- Enable VT-x in BIOS
- Check if Hyper-V is running (conflicts with other hypervisors)
- Disable Hyper-V: `bcdedit /set hypervisorlaunchtype off`

### Issue: "WDK not found" in Visual Studio

**Solution:**
1. Repair WDK installation
2. Ensure Visual Studio installed first
3. Check paths in Visual Studio: Tools → Options → Projects → VC++ Directories

### Issue: "Test Mode" watermark not showing

**Solution:**
```cmd
bcdedit /set testsigning on
bcdedit /set nointegritychecks on
shutdown /r /t 0
```

Force reboot and check again.

### Issue: Driver won't load

**Check:**
```cmd
sc query HypervisorSpoofer
```

**View errors:**
```cmd
eventvwr.msc
```

Check Windows Logs → System for driver errors.

---

## Next Steps

Now that your environment is set up:
- **[02-Virtualization-Basics.md](02-Virtualization-Basics.md)** - Learn core concepts
- **[03-Intel-VTx-Deep-Dive.md](03-Intel-VTx-Deep-Dive.md)** - Intel VT-x details
- **[09-Building-And-Testing.md](09-Building-And-Testing.md)** - Build the project

---

**Proper setup is crucial for successful development and testing.**

