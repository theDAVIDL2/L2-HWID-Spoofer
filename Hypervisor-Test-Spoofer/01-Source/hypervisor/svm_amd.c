/*
 * AMD-V (SVM) Hypervisor Implementation
 * Core SVM operations for thin hypervisor
 */

#include "svm_amd.h"
#include "../common/utils.h"
#include "../common/config.h"
#include "vmexit_handlers_amd.h"

// Forward declarations
static NTSTATUS SvmAllocateVmcbRegions(PSVM_CPU SvmCpu);
static VOID SvmFreeVmcbRegions(PSVM_CPU SvmCpu);
static NTSTATUS SvmSetupControlArea(PSVM_CPU SvmCpu);
static NTSTATUS SvmSetupStateSaveArea(PSVM_CPU SvmCpu);
static UINT16 SvmGetSegmentAttributes(UINT16 Selector, UINT64 GdtBase);

NTSTATUS SvmInitializeCpu(PSVM_CPU SvmCpu) {
    NTSTATUS status;
    UINT32 eax, ebx, ecx, edx;
    UINT64 vmCr;
    
    if (!SvmCpu) {
        return STATUS_INVALID_PARAMETER;
    }
    
    HvZeroMemory(SvmCpu, sizeof(SVM_CPU));
    SvmCpu->ProcessorNumber = HvGetCurrentProcessorNumber();
    
    // Check for SVM support (CPUID 0x80000001, ECX bit 2)
    HvCpuid(0x80000001, 0, &eax, &ebx, &ecx, &edx);
    if (!(ecx & (1 << 2))) {
        HvLog(LOG_LEVEL_ERROR, "CPU %d: SVM not supported\n", SvmCpu->ProcessorNumber);
        return STATUS_NOT_SUPPORTED;
    }
    
    // Check if SVM is disabled in VM_CR
    vmCr = HvReadMsr(MSR_VM_CR);
    if (vmCr & VM_CR_SVMDIS) {
        HvLog(LOG_LEVEL_ERROR, "CPU %d: SVM disabled in BIOS (VM_CR.SVMDIS set)\n", 
              SvmCpu->ProcessorNumber);
        return STATUS_HV_ACCESS_DENIED;
    }
    
    // Allocate VMCB and related structures
    status = SvmAllocateVmcbRegions(SvmCpu);
    if (!NT_SUCCESS(status)) {
        HvLog(LOG_LEVEL_ERROR, "CPU %d: Failed to allocate VMCB regions\n", 
              SvmCpu->ProcessorNumber);
        return status;
    }
    
    HvLog(LOG_LEVEL_INFO, "CPU %d: SVM initialized\n", SvmCpu->ProcessorNumber);
    return STATUS_SUCCESS;
}

static NTSTATUS SvmAllocateVmcbRegions(PSVM_CPU SvmCpu) {
    PHYSICAL_ADDRESS physicalAddress;
    
    // Allocate VMCB (4KB aligned)
    SvmCpu->VmcbVirtual = (PVMCB)HvAllocateContiguousMemory(PAGE_SIZE);
    if (!SvmCpu->VmcbVirtual) {
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    HvZeroMemory(SvmCpu->VmcbVirtual, PAGE_SIZE);
    physicalAddress = HvGetPhysicalAddress(SvmCpu->VmcbVirtual);
    SvmCpu->VmcbPhysical = physicalAddress.QuadPart;
    
    // Allocate host save area (4KB)
    SvmCpu->HostSaveVirtual = HvAllocateContiguousMemory(PAGE_SIZE);
    if (!SvmCpu->HostSaveVirtual) {
        SvmFreeVmcbRegions(SvmCpu);
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    HvZeroMemory(SvmCpu->HostSaveVirtual, PAGE_SIZE);
    physicalAddress = HvGetPhysicalAddress(SvmCpu->HostSaveVirtual);
    SvmCpu->HostSavePhysical = physicalAddress.QuadPart;
    
    // Allocate MSR permission map (2 pages = 8KB)
    SvmCpu->MsrpmVirtual = HvAllocateContiguousMemory(PAGE_SIZE * 2);
    if (!SvmCpu->MsrpmVirtual) {
        SvmFreeVmcbRegions(SvmCpu);
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    // Initialize to 0xFF (intercept all MSRs by default)
    RtlFillMemory(SvmCpu->MsrpmVirtual, PAGE_SIZE * 2, 0xFF);
    physicalAddress = HvGetPhysicalAddress(SvmCpu->MsrpmVirtual);
    SvmCpu->MsrpmPhysical = physicalAddress.QuadPart;
    
    // Allocate I/O permission map (3 pages = 12KB)
    SvmCpu->IopmVirtual = HvAllocateContiguousMemory(PAGE_SIZE * 3);
    if (!SvmCpu->IopmVirtual) {
        SvmFreeVmcbRegions(SvmCpu);
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    // Initialize to 0xFF (intercept all I/O by default)
    RtlFillMemory(SvmCpu->IopmVirtual, PAGE_SIZE * 3, 0xFF);
    physicalAddress = HvGetPhysicalAddress(SvmCpu->IopmVirtual);
    SvmCpu->IopmPhysical = physicalAddress.QuadPart;
    
    // Assign ASID (Address Space ID) - must be non-zero
    SvmCpu->Asid = SvmCpu->ProcessorNumber + 1;
    
    return STATUS_SUCCESS;
}

static VOID SvmFreeVmcbRegions(PSVM_CPU SvmCpu) {
    if (SvmCpu->VmcbVirtual) {
        HvFreeContiguousMemory(SvmCpu->VmcbVirtual);
    }
    if (SvmCpu->HostSaveVirtual) {
        HvFreeContiguousMemory(SvmCpu->HostSaveVirtual);
    }
    if (SvmCpu->MsrpmVirtual) {
        HvFreeContiguousMemory(SvmCpu->MsrpmVirtual);
    }
    if (SvmCpu->IopmVirtual) {
        HvFreeContiguousMemory(SvmCpu->IopmVirtual);
    }
}

NTSTATUS SvmEnableSvmOperation(PSVM_CPU SvmCpu) {
    UINT64 efer;
    
    // Save original EFER
    efer = HvReadMsr(MSR_EFER);
    SvmCpu->OriginalEfer = efer;
    
    // Enable SVM by setting EFER.SVME (bit 12)
    efer |= EFER_SVME;
    HvWriteMsr(MSR_EFER, efer);
    
    // Set host save area physical address
    HvWriteMsr(MSR_VM_HSAVE_PA, SvmCpu->HostSavePhysical);
    
    SvmCpu->IsSvmEnabled = TRUE;
    HvLog(LOG_LEVEL_DEBUG, "CPU %d: SVM operation enabled\n", SvmCpu->ProcessorNumber);
    
    return STATUS_SUCCESS;
}

NTSTATUS SvmSetupVmcb(PSVM_CPU SvmCpu) {
    NTSTATUS status;
    
    // Setup control area
    status = SvmSetupControlArea(SvmCpu);
    if (!NT_SUCCESS(status)) {
        return status;
    }
    
    // Setup state save area (guest state)
    status = SvmSetupStateSaveArea(SvmCpu);
    if (!NT_SUCCESS(status)) {
        return status;
    }
    
    // Setup intercepts
    SvmSetupIntercepts(SvmCpu);
    
    // Setup permission maps
    SvmSetupMsrpm(SvmCpu);
    SvmSetupIopm(SvmCpu);
    
    HvLog(LOG_LEVEL_DEBUG, "CPU %d: VMCB configured\n", SvmCpu->ProcessorNumber);
    
    return STATUS_SUCCESS;
}

static NTSTATUS SvmSetupControlArea(PSVM_CPU SvmCpu) {
    PVMCB_CONTROL_AREA control = &SvmCpu->VmcbVirtual->ControlArea;
    
    // Set ASID (required, must be non-zero)
    control->GuestAsid = SvmCpu->Asid;
    
    // Set MSR permission map
    control->MsrpmBasePa = SvmCpu->MsrpmPhysical;
    
    // Set I/O permission map
    control->IopmBasePa = SvmCpu->IopmPhysical;
    
    // TLB control (flush all ASIDs on VMRUN)
    control->TlbControl = 1;
    
    // Nested paging disabled for now (would require NPT setup)
    control->NpEnable = 0;
    
    return STATUS_SUCCESS;
}

static NTSTATUS SvmSetupStateSaveArea(PSVM_CPU SvmCpu) {
    PVMCB_STATE_SAVE_AREA state = &SvmCpu->VmcbVirtual->StateSaveArea;
    UINT16 cs, ss, ds, es, fs, gs;
    UINT64 gdtBase, idtBase;
    UINT16 gdtLimit, idtLimit;
    DESCRIPTOR_TABLE_REGISTER gdtr, idtr;
    
    // Get current segment selectors
    cs = __readcs();
    ss = __readss();
    ds = __readds();
    es = __reades();
    fs = __readfs();
    gs = __readgs();
    
    // Get descriptor tables
    __sgdt(&gdtr);
    __sidt(&idtr);
    gdtBase = (UINT64)gdtr.BaseAddress;
    gdtLimit = gdtr.Limit;
    idtBase = (UINT64)idtr.BaseAddress;
    idtLimit = idtr.Limit;
    
    // Setup segment registers
    state->Es.Selector = es;
    state->Es.Attributes = SvmGetSegmentAttributes(es, gdtBase);
    state->Es.Limit = 0xFFFFFFFF;
    state->Es.Base = 0;
    
    state->Cs.Selector = cs;
    state->Cs.Attributes = 0x29B;  // Code segment, L=1, D=0, Present=1
    state->Cs.Limit = 0xFFFFFFFF;
    state->Cs.Base = 0;
    
    state->Ss.Selector = ss;
    state->Ss.Attributes = 0x293;  // Data segment
    state->Ss.Limit = 0xFFFFFFFF;
    state->Ss.Base = 0;
    
    state->Ds.Selector = ds;
    state->Ds.Attributes = 0x293;
    state->Ds.Limit = 0xFFFFFFFF;
    state->Ds.Base = 0;
    
    state->Fs.Selector = fs;
    state->Fs.Attributes = 0x293;
    state->Fs.Limit = 0xFFFFFFFF;
    state->Fs.Base = HvReadMsr(0xC0000100);  // IA32_FS_BASE
    
    state->Gs.Selector = gs;
    state->Gs.Attributes = 0x293;
    state->Gs.Limit = 0xFFFFFFFF;
    state->Gs.Base = HvReadMsr(0xC0000101);  // IA32_GS_BASE
    
    // Setup descriptor table registers
    state->Gdtr.Selector = 0;
    state->Gdtr.Attributes = 0;
    state->Gdtr.Limit = gdtLimit;
    state->Gdtr.Base = gdtBase;
    
    state->Idtr.Selector = 0;
    state->Idtr.Attributes = 0;
    state->Idtr.Limit = idtLimit;
    state->Idtr.Base = idtBase;
    
    // Setup control registers
    state->Cr0 = __readcr0();
    state->Cr3 = __readcr3();
    state->Cr4 = __readcr4();
    state->Cr2 = __readcr2();
    
    // Setup EFER
    state->Efer = HvReadMsr(MSR_EFER);
    
    // Setup RFLAGS
    state->Rflags = __readeflags();
    
    // RIP and RSP will be set before VMRUN
    state->Rip = 0;  // Will be set to guest continuation point
    state->Rsp = 0;  // Will be set to guest stack
    
    // CPL (Current Privilege Level)
    state->Cpl = 0;  // Kernel mode
    
    return STATUS_SUCCESS;
}

VOID SvmSetupIntercepts(PSVM_CPU SvmCpu) {
    PVMCB_CONTROL_AREA control = &SvmCpu->VmcbVirtual->ControlArea;
    
    // Intercept CPUID
    control->InterceptMisc1 |= SVM_INTERCEPT_CPUID;
    
    // Intercept MSR access
    control->InterceptMisc1 |= SVM_INTERCEPT_MSR_PROT;
    
    // Intercept I/O instructions
    control->InterceptMisc1 |= SVM_INTERCEPT_IOIO_PROT;
    
    // Intercept RDTSC
    control->InterceptMisc1 |= SVM_INTERCEPT_RDTSC;
    
    // Intercept VMMCALL
    // (VMEXIT_VMMCALL will occur automatically when guest executes VMMCALL)
    
    HvLog(LOG_LEVEL_DEBUG, "CPU %d: Intercepts configured\n", SvmCpu->ProcessorNumber);
}

VOID SvmSetupMsrpm(PSVM_CPU SvmCpu) {
    // MSR permission map is 2 pages (8KB)
    // Each MSR has 2 bits: bit 0 = read intercept, bit 1 = write intercept
    
    // By default, we've initialized to 0xFF (intercept all)
    // Now we'll allow specific MSRs that we don't need to intercept
    
    UINT8* msrpm = (UINT8*)SvmCpu->MsrpmVirtual;
    
    // For now, intercept all MSRs
    // TODO: Allow specific MSRs for performance
    
    HvLog(LOG_LEVEL_DEBUG, "CPU %d: MSRPM configured\n", SvmCpu->ProcessorNumber);
}

VOID SvmSetupIopm(PSVM_CPU SvmCpu) {
    // I/O permission map is 3 pages (12KB)
    // Each I/O port has 1 bit: 1 = intercept, 0 = allow
    // Covers ports 0x0000 - 0xFFFF
    
    UINT8* iopm = (UINT8*)SvmCpu->IopmVirtual;
    
    // By default, we've initialized to 0xFF (intercept all)
    // Now we'll clear bits for ports we want to intercept for spoofing
    
    // For disk spoofing, intercept ATA ports
    // Primary ATA: 0x1F0-0x1F7
    // Secondary ATA: 0x170-0x177
    
    // Port 0x1F0-0x1F7 (primary ATA)
    for (UINT16 port = 0x1F0; port <= 0x1F7; port++) {
        UINT32 byteOffset = port / 8;
        UINT8 bitOffset = port % 8;
        iopm[byteOffset] |= (1 << bitOffset);
    }
    
    // Port 0x170-0x177 (secondary ATA)
    for (UINT16 port = 0x170; port <= 0x177; port++) {
        UINT32 byteOffset = port / 8;
        UINT8 bitOffset = port % 8;
        iopm[byteOffset] |= (1 << bitOffset);
    }
    
    HvLog(LOG_LEVEL_DEBUG, "CPU %d: IOPM configured\n", SvmCpu->ProcessorNumber);
}

static UINT16 SvmGetSegmentAttributes(UINT16 Selector, UINT64 GdtBase) {
    // Simplified - return typical attributes for 64-bit code/data segments
    // In production, would parse GDT to get actual attributes
    return 0x293;  // Present, DPL=0, Type=Data
}

VOID SvmTeardownCpu(PSVM_CPU SvmCpu) {
    if (!SvmCpu) {
        return;
    }
    
    if (SvmCpu->IsSvmEnabled) {
        // Disable SVM
        UINT64 efer = HvReadMsr(MSR_EFER);
        efer &= ~EFER_SVME;
        HvWriteMsr(MSR_EFER, efer);
        
        SvmCpu->IsSvmEnabled = FALSE;
    }
    
    SvmFreeVmcbRegions(SvmCpu);
    
    HvLog(LOG_LEVEL_INFO, "CPU %d: SVM torn down\n", SvmCpu->ProcessorNumber);
}

BOOLEAN SvmHandleVmExit(PSVM_CPU SvmCpu) {
    PVMCB_CONTROL_AREA control = &SvmCpu->VmcbVirtual->ControlArea;
    PVMCB_STATE_SAVE_AREA state = &SvmCpu->VmcbVirtual->StateSaveArea;
    UINT64 exitCode = control->ExitCode;
    BOOLEAN continueVm = TRUE;
    
    HvLog(LOG_LEVEL_DEBUG, "VMEXIT: Code=0x%llX, Info1=0x%llX, Info2=0x%llX\n",
          exitCode, control->ExitInfo1, control->ExitInfo2);
    
    // Dispatch based on exit code
    switch (exitCode) {
        case VMEXIT_CPUID:
            HvLog(LOG_LEVEL_DEBUG, "VMEXIT: CPUID\n");
            SvmHandleCpuidExit(SvmCpu);
            break;
            
        case VMEXIT_MSR:
            HvLog(LOG_LEVEL_DEBUG, "VMEXIT: MSR\n");
            SvmHandleMsrExit(SvmCpu);
            break;
            
        case VMEXIT_IOIO:
            HvLog(LOG_LEVEL_DEBUG, "VMEXIT: I/O\n");
            SvmHandleIoExit(SvmCpu);
            break;
            
        case VMEXIT_RDTSC:
            HvLog(LOG_LEVEL_DEBUG, "VMEXIT: RDTSC\n");
            SvmHandleRdtscExit(SvmCpu);
            break;
            
        case VMEXIT_VMMCALL:
            HvLog(LOG_LEVEL_DEBUG, "VMEXIT: VMMCALL\n");
            SvmHandleVmmcallExit(SvmCpu);
            break;
            
        case VMEXIT_NPF:
            HvLog(LOG_LEVEL_WARNING, "VMEXIT: Nested Page Fault\n");
            // Handle NPF (if NPT is enabled)
            break;
            
        default:
            HvLog(LOG_LEVEL_WARNING, "VMEXIT: Unhandled exit code 0x%llX\n", exitCode);
            break;
    }
    
    // Advance RIP if needed (NRIP contains next instruction address)
    if (control->NRip != 0) {
        state->Rip = control->NRip;
    }
    
    return continueVm;
}

