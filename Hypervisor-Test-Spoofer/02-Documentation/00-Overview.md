# Overview: Hypervisor-Based HWID Spoofing

## Table of Contents
1. [What is a Hypervisor?](#what-is-a-hypervisor)
2. [How It Enables HWID Spoofing](#how-it-enables-hwid-spoofing)
3. [Architecture](#architecture)
4. [Security Implications](#security-implications)

---

## What is a Hypervisor?

A **hypervisor** (also called Virtual Machine Monitor or VMM) is software that creates and manages virtual machines. It sits between the hardware and the operating system, controlling access to physical resources.

### Privilege Levels (x86/x64)

Modern CPUs have privilege rings that control access to system resources:

```
┌─────────────────────────────────────────┐
│ Ring 3: User Mode (Applications)       │  ← Least privileged
├─────────────────────────────────────────┤
│ Ring 2: (Unused in modern systems)     │
├─────────────────────────────────────────┤
│ Ring 1: (Unused in modern systems)     │
├─────────────────────────────────────────┤
│ Ring 0: Kernel Mode (OS Kernel)        │  ← Privileged
├─────────────────────────────────────────┤
│ Ring -1: Hypervisor (VMM)              │  ← Most privileged
└─────────────────────────────────────────┘
```

**Ring -1** (hypervisor mode) has even more privileges than Ring 0 (kernel mode). This is implemented through CPU virtualization extensions:
- **Intel VT-x** (VMX - Virtual Machine Extensions)
- **AMD-V** (SVM - Secure Virtual Machine)

### Types of Hypervisors

#### Type 1 (Bare Metal)
Runs directly on hardware:
- VMware ESXi
- Microsoft Hyper-V (standalone)
- Xen

#### Type 2 (Hosted)
Runs on top of an existing OS:
- VMware Workstation
- VirtualBox
- Our thin hypervisor (special case)

### Thin Hypervisor

Our implementation is a **thin hypervisor** - a minimal hypervisor that:
- Installs on a running OS
- Makes minimal changes to system behavior
- Intercepts only specific operations
- Transparent to most software

---

## How It Enables HWID Spoofing

### Traditional Spoofing Methods (Ring 0)

**Kernel drivers** can hook system functions, but they have limitations:
- Detectable by checking driver lists
- Can be bypassed by direct hardware access
- Signatures in kernel memory
- Limited control over CPU instructions

### Hypervisor-Based Spoofing (Ring -1)

The hypervisor sits **below** the OS kernel, giving it ultimate control:

```
Application queries HWID
         ↓
Windows Kernel processes query
         ↓
Kernel attempts hardware access (CPUID, I/O ports, etc.)
         ↓
CPU triggers "VM Exit" ← HYPERVISOR INTERCEPTS HERE
         ↓
Hypervisor modifies the result
         ↓
Returns spoofed data to kernel
         ↓
Kernel returns to application
```

### VM Exits: The Magic Behind It

When specific CPU instructions are executed, the CPU automatically transfers control to the hypervisor:

**Interceptable Instructions:**
- `CPUID` - CPU identification
- `RDMSR` - Read model-specific register
- `WRMSR` - Write model-specific register
- `IN/OUT` - I/O port access (disk, network)
- `MOV to/from CR` - Control register access
- `RDTSC` - Read timestamp counter

**Example Flow:**

```c
// Application executes
__cpuid(cpuInfo, 1);

// This triggers:
1. CPU executes CPUID
2. VM Exit occurs (automatic)
3. Hypervisor handler runs
4. Hypervisor sees:
   - Exit reason: CPUID
   - Leaf: 1
5. Hypervisor modifies result:
   EAX = FakeCPUID
   ECX &= ~(1<<31)  // Clear hypervisor bit
6. Hypervisor does VM Entry
7. Guest (Windows) continues with spoofed data
```

---

## Architecture

### High-Level Architecture

```
┌──────────────────────────────────────────────┐
│         User Applications                    │
│  (Games, Anti-Cheat, System Info Tools)     │
├──────────────────────────────────────────────┤
│         Windows Kernel (Guest OS)            │
│  - Believes it's running on bare metal      │
│  - Sees spoofed hardware IDs                 │
├══════════════════════════════════════════════╡
│    HYPERVISOR (Our Spoofer) - Ring -1       │
│  ┌────────────────────────────────────────┐ │
│  │  VM Exit Handlers                      │ │
│  │  ├─ CPUID Handler → CPU Spoofing      │ │
│  │  ├─ I/O Handler → Disk/MAC Spoofing   │ │
│  │  ├─ MSR Handler → Feature Spoofing    │ │
│  │  └─ RDTSC Handler → Timing Fix        │ │
│  ├────────────────────────────────────────┤ │
│  │  Anti-Detection                        │ │
│  │  ├─ Hide hypervisor presence bit      │ │
│  │  ├─ Clear VM vendor string            │ │
│  │  ├─ Compensate timing anomalies       │ │
│  │  └─ Fake descriptor table addresses   │ │
│  ├────────────────────────────────────────┤ │
│  │  Configuration                         │ │
│  │  ├─ Preset profiles (i5, i7, i9...)   │ │
│  │  ├─ Custom HWID values                 │ │
│  │  └─ Enable/disable per-component      │ │
│  └────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│         Physical Hardware                     │
│  (Real CPU, Disk, Network Card, etc.)        │
└──────────────────────────────────────────────┘
```

### Component Breakdown

#### 1. **VMX Engine** (`hypervisor/vmx_intel.c`)
- VMCS allocation and setup
- VM entry/exit management
- Control field configuration
- Multi-CPU support

#### 2. **VM Exit Dispatcher** (`hypervisor/vmexit_handlers.c`)
- Routes VM exits to appropriate handlers
- Manages guest register state
- Advances guest RIP after interception

#### 3. **Spoofing Modules** (`spoofing/`)
- **CPUID**: Processor ID, vendor, brand
- **Disk**: Serial numbers, model, firmware
- **MAC**: Network adapter addresses
- **Motherboard**: SMBIOS data, UUID

#### 4. **Evasion Modules** (`evasion/`)
- **VM Detection**: Hide hypervisor presence
- **Timing**: Compensate for VM exit overhead
- **Descriptor Tables**: Fake SIDT/SGDT results

#### 5. **Configuration System** (`common/config.c`)
- Hardware presets
- Random ID generation
- Per-component enable/disable
- Runtime configuration updates

---

## Security Implications

### For Anti-Cheat Developers

This tool demonstrates **why hypervisor-based attacks are hard to detect**:

#### Advantages of Hypervisor Spoofers:
✅ **Below Kernel** - Can't be detected by kernel-mode anti-cheat  
✅ **Transparent** - No visible drivers or processes  
✅ **Complete Control** - Intercepts at hardware level  
✅ **Persistent** - Survives reboots if installed in firmware  

#### Detection Strategies:

**1. VM Detection**
- Check CPUID hypervisor bit (easily spoofed)
- Test for VM vendor strings (easily hidden)
- Timing attacks (compensatable)
- Red Pill techniques (SIDT/SGDT emulation possible)

**2. Behavioral Analysis**
- HWID consistency across sessions
- Impossible hardware combinations
- Blacklist known fake serials

**3. Hardware Attestation**
- TPM-based attestation
- Secure Boot verification
- Platform integrity checks

**4. Multi-Layer Verification**
- Cross-check multiple HWID sources
- Kernel vs. user-mode consistency
- Direct hardware queries vs. OS APIs

### For Security Researchers

Hypervisor-based rootkits represent advanced persistent threats:

**Research Areas:**
- Detection mechanisms
- Performance overhead measurement
- Nested virtualization detection
- Hardware-backed security (TPM, SGX)

---

## Why This Approach?

### Compared to Other Methods:

| Method | Ring Level | Detectability | Effectiveness |
|--------|-----------|---------------|---------------|
| User-mode hooks | Ring 3 | Very Easy | Low |
| Kernel driver | Ring 0 | Easy | Medium |
| **Hypervisor** | **Ring -1** | **Hard** | **Very High** |
| Hardware interposer | Physical | Nearly Impossible | Extreme |

---

## Next Steps

- **[01-Prerequisites.md](01-Prerequisites.md)** - Setup your development environment
- **[02-Virtualization-Basics.md](02-Virtualization-Basics.md)** - Learn VMX/SVM fundamentals
- **[03-Intel-VTx-Deep-Dive.md](03-Intel-VTx-Deep-Dive.md)** - Detailed Intel implementation

---

**Understanding the architecture is crucial before proceeding to implementation.**

