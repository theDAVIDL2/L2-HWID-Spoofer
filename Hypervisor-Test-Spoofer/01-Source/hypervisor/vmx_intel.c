/*
 * Intel VT-x Hypervisor Implementation
 * Core VMX operations for thin hypervisor
 */

#include "vmx_intel.h"
#include "../common/utils.h"
#include "../common/config.h"
#include "vmexit_handlers.h"

// VMX control register bits
#define CR0_PE                      0x00000001  // Protection Enable
#define CR0_NE                      0x00000020  // Numeric Error
#define CR0_PG                      0x80000000  // Paging
#define CR4_VMXE                    0x00002000  // VMX Enable
#define CR4_PAE                     0x00000020  // Physical Address Extension

// RFLAGS bits
#define RFLAGS_CF                   (1 << 0)
#define RFLAGS_ZF                   (1 << 6)

// Segment descriptor structure
typedef struct _SEGMENT_DESCRIPTOR {
    UINT16 LimitLow;
    UINT16 BaseLow;
    UINT8 BaseMiddle;
    UINT8 AccessRights;
    UINT8 LimitHigh : 4;
    UINT8 Flags : 4;
    UINT8 BaseHigh;
} SEGMENT_DESCRIPTOR, *PSEGMENT_DESCRIPTOR;

// Descriptor table register
typedef struct _DTR {
    UINT16 Limit;
    UINT64 Base;
} DTR, *PDTR;

// Assembly helpers (implemented as inline or external)
extern VOID __vmx_vmptrld(UINT64* VmcsPhysical);
extern VOID __vmx_vmwrite(UINT32 Field, UINT64 Value);
extern UINT64 __vmx_vmread(UINT32 Field);
extern UINT8 __vmx_vmlaunch(VOID);
extern UINT8 __vmx_vmresume(VOID);
extern VOID __vmx_vmcall(VOID);
extern VOID __vmx_off(VOID);
extern UINT8 __vmx_on(UINT64* VmxonPhysical);

// Forward declarations
static NTSTATUS VmxAllocateVmxRegions(PVMX_CPU VmxCpu);
static VOID VmxFreeVmxRegions(PVMX_CPU VmxCpu);
static NTSTATUS VmxSetupControlFields(PVMX_CPU VmxCpu);
static NTSTATUS VmxSetupHostState(PVMX_CPU VmxCpu);
static NTSTATUS VmxSetupGuestState(PVMX_CPU VmxCpu);
static VOID VmxSetupMsrBitmap(PVMX_CPU VmxCpu);
static VOID VmxSetupIoBitmaps(PVMX_CPU VmxCpu);

NTSTATUS VmxInitializeCpu(PVMX_CPU VmxCpu) {
    NTSTATUS status;
    UINT32 eax, ebx, ecx, edx;
    
    if (!VmxCpu) {
        return STATUS_INVALID_PARAMETER;
    }
    
    HvZeroMemory(VmxCpu, sizeof(VMX_CPU));
    VmxCpu->ProcessorNumber = HvGetCurrentProcessorNumber();
    
    // Check for VMX support
    HvCpuid(1, 0, &eax, &ebx, &ecx, &edx);
    if (!(ecx & (1 << 5))) {
        HvLog(LOG_LEVEL_ERROR, "CPU %d: VMX not supported\n", VmxCpu->ProcessorNumber);
        return STATUS_NOT_SUPPORTED;
    }
    
    // Check if VMX is locked
    UINT64 featureControl = HvReadMsr(IA32_FEATURE_CONTROL);
    if (!(featureControl & 0x5)) {
        HvLog(LOG_LEVEL_ERROR, "CPU %d: VMX locked in BIOS\n", VmxCpu->ProcessorNumber);
        return STATUS_HV_ACCESS_DENIED;
    }
    
    // Allocate VMX regions
    status = VmxAllocateVmxRegions(VmxCpu);
    if (!NT_SUCCESS(status)) {
        HvLog(LOG_LEVEL_ERROR, "CPU %d: Failed to allocate VMX regions\n", VmxCpu->ProcessorNumber);
        return status;
    }
    
    HvLog(LOG_LEVEL_INFO, "CPU %d: VMX initialized\n", VmxCpu->ProcessorNumber);
    return STATUS_SUCCESS;
}

static NTSTATUS VmxAllocateVmxRegions(PVMX_CPU VmxCpu) {
    PHYSICAL_ADDRESS physicalAddress;
    UINT64 vmxBasicMsr;
    UINT32 vmxRevision;
    
    // Read VMX revision identifier
    vmxBasicMsr = HvReadMsr(IA32_VMX_BASIC);
    vmxRevision = (UINT32)(vmxBasicMsr & 0x7FFFFFFF);
    
    // Allocate VMXON region (4KB, must be aligned)
    VmxCpu->VmxonRegionVirtual = HvAllocateContiguousMemory(PAGE_SIZE);
    if (!VmxCpu->VmxonRegionVirtual) {
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    HvZeroMemory(VmxCpu->VmxonRegionVirtual, PAGE_SIZE);
    *(UINT32*)VmxCpu->VmxonRegionVirtual = vmxRevision;
    physicalAddress = HvGetPhysicalAddress(VmxCpu->VmxonRegionVirtual);
    VmxCpu->VmxonRegionPhysical = physicalAddress.QuadPart;
    
    // Allocate VMCS region (4KB, must be aligned)
    VmxCpu->VmcsRegionVirtual = HvAllocateContiguousMemory(PAGE_SIZE);
    if (!VmxCpu->VmcsRegionVirtual) {
        VmxFreeVmxRegions(VmxCpu);
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    HvZeroMemory(VmxCpu->VmcsRegionVirtual, PAGE_SIZE);
    *(UINT32*)VmxCpu->VmcsRegionVirtual = vmxRevision;
    physicalAddress = HvGetPhysicalAddress(VmxCpu->VmcsRegionVirtual);
    VmxCpu->VmcsRegionPhysical = physicalAddress.QuadPart;
    
    // Allocate VMM stack (16KB)
    VmxCpu->VmmStackVirtual = HvAllocateContiguousMemory(0x4000);
    if (!VmxCpu->VmmStackVirtual) {
        VmxFreeVmxRegions(VmxCpu);
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    HvZeroMemory(VmxCpu->VmmStackVirtual, 0x4000);
    physicalAddress = HvGetPhysicalAddress(VmxCpu->VmmStackVirtual);
    VmxCpu->VmmStackPhysical = physicalAddress.QuadPart;
    
    // Allocate MSR bitmap (4KB)
    VmxCpu->MsrBitmapVirtual = HvAllocateContiguousMemory(PAGE_SIZE);
    if (!VmxCpu->MsrBitmapVirtual) {
        VmxFreeVmxRegions(VmxCpu);
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    HvZeroMemory(VmxCpu->MsrBitmapVirtual, PAGE_SIZE);
    physicalAddress = HvGetPhysicalAddress(VmxCpu->MsrBitmapVirtual);
    VmxCpu->MsrBitmapPhysical = physicalAddress.QuadPart;
    
    // Allocate I/O bitmaps (2x 4KB)
    VmxCpu->IoBitmapAVirtual = HvAllocateContiguousMemory(PAGE_SIZE);
    if (!VmxCpu->IoBitmapAVirtual) {
        VmxFreeVmxRegions(VmxCpu);
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    HvZeroMemory(VmxCpu->IoBitmapAVirtual, PAGE_SIZE);
    physicalAddress = HvGetPhysicalAddress(VmxCpu->IoBitmapAVirtual);
    VmxCpu->IoBitmapAPhysical = physicalAddress.QuadPart;
    
    VmxCpu->IoBitmapBVirtual = HvAllocateContiguousMemory(PAGE_SIZE);
    if (!VmxCpu->IoBitmapBVirtual) {
        VmxFreeVmxRegions(VmxCpu);
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    HvZeroMemory(VmxCpu->IoBitmapBVirtual, PAGE_SIZE);
    physicalAddress = HvGetPhysicalAddress(VmxCpu->IoBitmapBVirtual);
    VmxCpu->IoBitmapBPhysical = physicalAddress.QuadPart;
    
    return STATUS_SUCCESS;
}

static VOID VmxFreeVmxRegions(PVMX_CPU VmxCpu) {
    if (VmxCpu->VmxonRegionVirtual) {
        HvFreeContiguousMemory(VmxCpu->VmxonRegionVirtual);
    }
    if (VmxCpu->VmcsRegionVirtual) {
        HvFreeContiguousMemory(VmxCpu->VmcsRegionVirtual);
    }
    if (VmxCpu->VmmStackVirtual) {
        HvFreeContiguousMemory(VmxCpu->VmmStackVirtual);
    }
    if (VmxCpu->MsrBitmapVirtual) {
        HvFreeContiguousMemory(VmxCpu->MsrBitmapVirtual);
    }
    if (VmxCpu->IoBitmapAVirtual) {
        HvFreeContiguousMemory(VmxCpu->IoBitmapAVirtual);
    }
    if (VmxCpu->IoBitmapBVirtual) {
        HvFreeContiguousMemory(VmxCpu->IoBitmapBVirtual);
    }
}

NTSTATUS VmxEnableVmxOperation(PVMX_CPU VmxCpu) {
    UINT64 cr0, cr4;
    UINT64 cr0Fixed0, cr0Fixed1;
    UINT64 cr4Fixed0, cr4Fixed1;
    UINT8 status;
    
    // Save original CR values
    cr0 = __readcr0();
    cr4 = __readcr4();
    VmxCpu->OriginalCr0 = cr0;
    VmxCpu->OriginalCr4 = cr4;
    
    // Adjust CR0 based on fixed bits
    cr0Fixed0 = HvReadMsr(IA32_VMX_CR0_FIXED0);
    cr0Fixed1 = HvReadMsr(IA32_VMX_CR0_FIXED1);
    cr0 |= cr0Fixed0;  // Set bits that must be 1
    cr0 &= cr0Fixed1;  // Clear bits that must be 0
    __writecr0(cr0);
    
    // Adjust CR4 and enable VMX
    cr4Fixed0 = HvReadMsr(IA32_VMX_CR4_FIXED0);
    cr4Fixed1 = HvReadMsr(IA32_VMX_CR4_FIXED1);
    cr4 |= cr4Fixed0;
    cr4 &= cr4Fixed1;
    cr4 |= CR4_VMXE;   // Enable VMX operation
    __writecr4(cr4);
    
    // Execute VMXON
    status = __vmx_on(&VmxCpu->VmxonRegionPhysical);
    if (status != 0) {
        HvLog(LOG_LEVEL_ERROR, "CPU %d: VMXON failed (status=%d)\n", 
              VmxCpu->ProcessorNumber, status);
        return STATUS_UNSUCCESSFUL;
    }
    
    VmxCpu->IsVmxEnabled = TRUE;
    HvLog(LOG_LEVEL_DEBUG, "CPU %d: VMX operation enabled\n", VmxCpu->ProcessorNumber);
    
    return STATUS_SUCCESS;
}

NTSTATUS VmxSetupVmcs(PVMX_CPU VmxCpu) {
    NTSTATUS status;
    
    // Load VMCS
    __vmx_vmptrld(&VmxCpu->VmcsRegionPhysical);
    
    // Setup control fields
    status = VmxSetupControlFields(VmxCpu);
    if (!NT_SUCCESS(status)) {
        return status;
    }
    
    // Setup host state
    status = VmxSetupHostState(VmxCpu);
    if (!NT_SUCCESS(status)) {
        return status;
    }
    
    // Setup guest state
    status = VmxSetupGuestState(VmxCpu);
    if (!NT_SUCCESS(status)) {
        return status;
    }
    
    HvLog(LOG_LEVEL_DEBUG, "CPU %d: VMCS configured\n", VmxCpu->ProcessorNumber);
    
    return STATUS_SUCCESS;
}

static NTSTATUS VmxSetupControlFields(PVMX_CPU VmxCpu) {
    UINT32 pinBasedControls, cpuBasedControls, secondaryControls;
    UINT32 vmExitControls, vmEntryControls;
    
    // Pin-based controls (minimal)
    pinBasedControls = 0;
    pinBasedControls = VmxAdjustControls(pinBasedControls, IA32_VMX_PINBASED_CTLS);
    VmxWrite(PIN_BASED_VM_EXEC_CONTROL, pinBasedControls);
    
    // CPU-based controls
    cpuBasedControls = 0;
    cpuBasedControls |= (1 << 25);  // Use MSR bitmaps
    cpuBasedControls |= (1 << 31);  // Activate secondary controls
    cpuBasedControls = VmxAdjustControls(cpuBasedControls, IA32_VMX_PROCBASED_CTLS);
    VmxWrite(CPU_BASED_VM_EXEC_CONTROL, cpuBasedControls);
    
    // Secondary controls (if supported)
    secondaryControls = 0;
    secondaryControls |= (1 << 1);  // Enable EPT (if available)
    secondaryControls = VmxAdjustControls(secondaryControls, IA32_VMX_PROCBASED_CTLS2);
    VmxWrite(SECONDARY_VM_EXEC_CONTROL, secondaryControls);
    
    // VM-exit controls
    vmExitControls = 0;
    vmExitControls |= (1 << 9);   // Host address-space size (64-bit)
    vmExitControls = VmxAdjustControls(vmExitControls, IA32_VMX_EXIT_CTLS);
    VmxWrite(VM_EXIT_CONTROLS, vmExitControls);
    
    // VM-entry controls
    vmEntryControls = 0;
    vmEntryControls |= (1 << 9);  // IA-32e mode guest
    vmEntryControls = VmxAdjustControls(vmEntryControls, IA32_VMX_ENTRY_CTLS);
    VmxWrite(VM_ENTRY_CONTROLS, vmEntryControls);
    
    // Setup MSR bitmap
    VmxSetupMsrBitmap(VmxCpu);
    
    // Setup I/O bitmaps
    VmxSetupIoBitmaps(VmxCpu);
    
    // Exception bitmap (intercept nothing by default)
    VmxWrite(EXCEPTION_BITMAP, 0);
    
    return STATUS_SUCCESS;
}

static VOID VmxSetupMsrBitmap(PVMX_CPU VmxCpu) {
    // Initially allow all MSRs (bitmap is all zeros)
    // We'll selectively intercept MSRs we want to spoof
    
    // The bitmap is divided into 4 sections:
    // 0x000-0x7FF: Read low MSRs (0x00000000-0x00001FFF)
    // 0x800-0xFFF: Read high MSRs (0xC0000000-0xC0001FFF)
    // 0x1000-0x17FF: Write low MSRs
    // 0x1800-0x1FFF: Write high MSRs
    
    // Intercept IA32_TSC reads/writes for timing compensation
    // TODO: Set specific bits in bitmap
    
    // Write bitmap address to VMCS
    __vmx_vmwrite(0x00002004, VmxCpu->MsrBitmapPhysical);  // MSR_BITMAP address
}

static VOID VmxSetupIoBitmaps(PVMX_CPU VmxCpu) {
    // Initially allow all I/O ports
    // We'll intercept specific ports for disk spoofing
    
    // Bitmap A: Ports 0x0000-0x7FFF
    // Bitmap B: Ports 0x8000-0xFFFF
    
    // TODO: Set specific bits for ATA ports (0x1F0-0x1F7, 0x170-0x177)
    
    // Write bitmap addresses to VMCS
    __vmx_vmwrite(0x00002000, VmxCpu->IoBitmapAPhysical);  // IO_BITMAP_A
    __vmx_vmwrite(0x00002002, VmxCpu->IoBitmapBPhysical);  // IO_BITMAP_B
}

static NTSTATUS VmxSetupHostState(PVMX_CPU VmxCpu) {
    DTR gdtr, idtr;
    UINT16 tr, cs, ss, ds, es, fs, gs;
    
    // Get current descriptor tables
    __sgdt(&gdtr);
    __sidt(&idtr);
    
    // Get current segment selectors
    tr = __str();
    cs = __readcs();
    ss = __readss();
    ds = __readds();
    es = __reades();
    fs = __readfs();
    gs = __readgs();
    
    // Write host segment selectors
    VmxWrite(HOST_CS_SELECTOR, cs & 0xF8);
    VmxWrite(HOST_SS_SELECTOR, ss & 0xF8);
    VmxWrite(HOST_DS_SELECTOR, ds & 0xF8);
    VmxWrite(HOST_ES_SELECTOR, es & 0xF8);
    VmxWrite(HOST_FS_SELECTOR, fs & 0xF8);
    VmxWrite(HOST_GS_SELECTOR, gs & 0xF8);
    VmxWrite(HOST_TR_SELECTOR, tr & 0xF8);
    
    // Write host control registers
    VmxWrite(HOST_CR0, __readcr0());
    VmxWrite(HOST_CR3, __readcr3());
    VmxWrite(HOST_CR4, __readcr4());
    
    // Write host base addresses
    VmxWrite(HOST_FS_BASE, HvReadMsr(0xC0000100));  // IA32_FS_BASE
    VmxWrite(HOST_GS_BASE, HvReadMsr(0xC0000101));  // IA32_GS_BASE
    
    // TR base (get from GDT)
    UINT64 trBase = 0;
    // TODO: Parse GDT to get TR base
    VmxWrite(HOST_TR_BASE, trBase);
    
    // GDTR and IDTR
    VmxWrite(HOST_GDTR_BASE, gdtr.Base);
    VmxWrite(HOST_IDTR_BASE, idtr.Base);
    
    // Host RIP (VM exit handler)
    VmxWrite(HOST_RIP, (UINT64)VmxHandleVmExit);
    
    // Host RSP (top of VMM stack)
    VmxWrite(HOST_RSP, (UINT64)VmxCpu->VmmStackVirtual + 0x4000 - 16);
    
    return STATUS_SUCCESS;
}

static NTSTATUS VmxSetupGuestState(PVMX_CPU VmxCpu) {
    // Guest state is initialized to current system state
    // This creates a "transparent" virtualization
    
    DTR gdtr, idtr;
    UINT16 cs, ss, ds, es, fs, gs, ldtr, tr;
    UINT64 cr0, cr3, cr4, rflags;
    
    // Get current state
    __sgdt(&gdtr);
    __sidt(&idtr);
    cs = __readcs();
    ss = __readss();
    ds = __readds();
    es = __reades();
    fs = __readfs();
    gs = __readgs();
    ldtr = __sldt();
    tr = __str();
    cr0 = __readcr0();
    cr3 = __readcr3();
    cr4 = __readcr4();
    rflags = __readeflags();
    
    // Write guest segment selectors
    VmxWrite(GUEST_CS_SELECTOR, cs);
    VmxWrite(GUEST_SS_SELECTOR, ss);
    VmxWrite(GUEST_DS_SELECTOR, ds);
    VmxWrite(GUEST_ES_SELECTOR, es);
    VmxWrite(GUEST_FS_SELECTOR, fs);
    VmxWrite(GUEST_GS_SELECTOR, gs);
    VmxWrite(GUEST_LDTR_SELECTOR, ldtr);
    VmxWrite(GUEST_TR_SELECTOR, tr);
    
    // Write guest control registers
    VmxWrite(GUEST_CR0, cr0);
    VmxWrite(GUEST_CR3, cr3);
    VmxWrite(GUEST_CR4, cr4);
    
    // Write guest descriptor table registers
    VmxWrite(GUEST_GDTR_BASE, gdtr.Base);
    VmxWrite(GUEST_GDTR_LIMIT, gdtr.Limit);
    VmxWrite(GUEST_IDTR_BASE, idtr.Base);
    VmxWrite(GUEST_IDTR_LIMIT, idtr.Limit);
    
    // Write guest segment bases (simplified - assumes flat memory model)
    VmxWrite(GUEST_CS_BASE, 0);
    VmxWrite(GUEST_SS_BASE, 0);
    VmxWrite(GUEST_DS_BASE, 0);
    VmxWrite(GUEST_ES_BASE, 0);
    VmxWrite(GUEST_FS_BASE, HvReadMsr(0xC0000100));
    VmxWrite(GUEST_GS_BASE, HvReadMsr(0xC0000101));
    
    // Write guest segment limits and access rights
    VmxWrite(GUEST_CS_LIMIT, 0xFFFFFFFF);
    VmxWrite(GUEST_SS_LIMIT, 0xFFFFFFFF);
    VmxWrite(GUEST_DS_LIMIT, 0xFFFFFFFF);
    VmxWrite(GUEST_ES_LIMIT, 0xFFFFFFFF);
    VmxWrite(GUEST_FS_LIMIT, 0xFFFFFFFF);
    VmxWrite(GUEST_GS_LIMIT, 0xFFFFFFFF);
    
    // Access rights (typical for 64-bit mode)
    VmxWrite(GUEST_CS_AR_BYTES, 0xA09B);  // Code, L=1, D=0
    VmxWrite(GUEST_SS_AR_BYTES, 0xC093);  // Data
    VmxWrite(GUEST_DS_AR_BYTES, 0xC093);
    VmxWrite(GUEST_ES_AR_BYTES, 0xC093);
    VmxWrite(GUEST_FS_AR_BYTES, 0xC093);
    VmxWrite(GUEST_GS_AR_BYTES, 0xC093);
    
    // Guest RFLAGS
    VmxWrite(GUEST_RFLAGS, rflags);
    
    // Guest RIP and RSP will be set just before VMLAUNCH
    
    return STATUS_SUCCESS;
}

UINT32 VmxAdjustControls(UINT32 Ctl, UINT32 Msr) {
    UINT64 msrValue = HvReadMsr(Msr);
    UINT32 allowed0 = (UINT32)msrValue;        // Bits that can be 0
    UINT32 allowed1 = (UINT32)(msrValue >> 32); // Bits that can be 1
    
    Ctl |= allowed0;   // Set bits that must be 1
    Ctl &= allowed1;   // Clear bits that must be 0
    
    return Ctl;
}

UINT64 VmxRead(UINT32 Field) {
    SIZE_T value;
    __vmx_vmread(Field, &value);
    return (UINT64)value;
}

VOID VmxWrite(UINT32 Field, UINT64 Value) {
    __vmx_vmwrite(Field, Value);
}

VOID VmxTeardownCpu(PVMX_CPU VmxCpu) {
    if (!VmxCpu) {
        return;
    }
    
    if (VmxCpu->IsVmxEnabled) {
        __vmx_off();
        
        // Restore original CR4
        __writecr4(VmxCpu->OriginalCr4);
        
        VmxCpu->IsVmxEnabled = FALSE;
    }
    
    VmxFreeVmxRegions(VmxCpu);
    
    HvLog(LOG_LEVEL_INFO, "CPU %d: VMX torn down\n", VmxCpu->ProcessorNumber);
}

