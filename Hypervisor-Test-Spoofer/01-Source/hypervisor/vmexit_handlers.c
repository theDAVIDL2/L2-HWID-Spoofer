/*
 * VM Exit Handlers Implementation
 */

#include "vmexit_handlers.h"
#include "vmx_intel.h"
#include "../common/utils.h"
#include "../common/config.h"
#include "../spoofing/cpuid_spoof.h"
#include "../spoofing/disk_spoof.h"
#include "../evasion/vm_detection_evasion.h"
#include "../evasion/rdtsc_evasion.h"

// VM exit reasons (from vmx_intel.h)
extern UINT64 VmxRead(UINT32 Field);
extern VOID VmxWrite(UINT32 Field, UINT64 Value);

BOOLEAN HandleVmExit(PGUEST_CONTEXT GuestContext) {
    UINT32 exitReason;
    UINT64 exitQualification;
    BOOLEAN continueVm = TRUE;
    
    // Read exit reason
    exitReason = (UINT32)VmxRead(0x00004402);  // VM_EXIT_REASON
    exitReason &= 0xFFFF;  // Mask off high bits
    
    // Read exit qualification (additional info)
    exitQualification = VmxRead(0x00006400);  // EXIT_QUALIFICATION
    
    // Dispatch based on exit reason
    switch (exitReason) {
        case EXIT_REASON_CPUID:
            HvLog(LOG_LEVEL_DEBUG, "VM Exit: CPUID\n");
            HandleCpuidExit(GuestContext);
            VmExitAdvanceRip();
            break;
            
        case EXIT_REASON_MSR_READ:
            HvLog(LOG_LEVEL_DEBUG, "VM Exit: MSR Read (MSR=0x%X)\n", (UINT32)GuestContext->Rcx);
            HandleMsrRead(GuestContext);
            VmExitAdvanceRip();
            break;
            
        case EXIT_REASON_MSR_WRITE:
            HvLog(LOG_LEVEL_DEBUG, "VM Exit: MSR Write (MSR=0x%X)\n", (UINT32)GuestContext->Rcx);
            HandleMsrWrite(GuestContext);
            VmExitAdvanceRip();
            break;
            
        case EXIT_REASON_IO_INSTRUCTION:
            HvLog(LOG_LEVEL_DEBUG, "VM Exit: I/O Instruction\n");
            HandleIoInstruction(GuestContext);
            VmExitAdvanceRip();
            break;
            
        case EXIT_REASON_CR_ACCESS:
            HvLog(LOG_LEVEL_DEBUG, "VM Exit: CR Access\n");
            HandleCrAccess(GuestContext);
            VmExitAdvanceRip();
            break;
            
        case EXIT_REASON_RDTSC:
            HvLog(LOG_LEVEL_DEBUG, "VM Exit: RDTSC\n");
            HandleRdtsc(GuestContext);
            VmExitAdvanceRip();
            break;
            
        case EXIT_REASON_VMCALL:
            HvLog(LOG_LEVEL_DEBUG, "VM Exit: VMCALL\n");
            HandleVmCall(GuestContext);
            VmExitAdvanceRip();
            break;
            
        case EXIT_REASON_EXCEPTION_NMI:
            HvLog(LOG_LEVEL_DEBUG, "VM Exit: Exception/NMI\n");
            HandleException(GuestContext);
            break;
            
        case EXIT_REASON_VMXOFF:
            HvLog(LOG_LEVEL_INFO, "VM Exit: VMXOFF - Stopping hypervisor\n");
            continueVm = FALSE;
            break;
            
        default:
            HvLog(LOG_LEVEL_WARNING, "VM Exit: Unhandled reason %d\n", exitReason);
            VmExitAdvanceRip();
            break;
    }
    
    return continueVm;
}

VOID HandleCpuidExit(PGUEST_CONTEXT GuestContext) {
    UINT32 leaf = (UINT32)GuestContext->Rax;
    UINT32 subleaf = (UINT32)GuestContext->Rcx;
    
    // Check if spoofing is enabled
    if (ConfigIsEnabled() && g_SpoofConfig.SpoofCpu) {
        // Call CPUID spoofer
        CpuidSpoof(leaf, subleaf, 
                   (UINT32*)&GuestContext->Rax,
                   (UINT32*)&GuestContext->Rbx,
                   (UINT32*)&GuestContext->Rcx,
                   (UINT32*)&GuestContext->Rdx);
    }
    else {
        // Execute real CPUID
        INT32 cpuInfo[4];
        __cpuidex(cpuInfo, (INT32)leaf, (INT32)subleaf);
        GuestContext->Rax = cpuInfo[0];
        GuestContext->Rbx = cpuInfo[1];
        GuestContext->Rcx = cpuInfo[2];
        GuestContext->Rdx = cpuInfo[3];
    }
    
    // Always apply VM detection evasion
    if (g_SpoofConfig.HideHypervisor) {
        EvadeCpuidDetection(leaf, 
                           (UINT32*)&GuestContext->Rax,
                           (UINT32*)&GuestContext->Rbx,
                           (UINT32*)&GuestContext->Rcx,
                           (UINT32*)&GuestContext->Rdx);
    }
}

VOID HandleMsrRead(PGUEST_CONTEXT GuestContext) {
    UINT32 msr = (UINT32)GuestContext->Rcx;
    UINT64 msrValue;
    
    // Read the actual MSR
    __try {
        msrValue = __readmsr(msr);
    }
    __except(EXCEPTION_EXECUTE_HANDLER) {
        // MSR doesn't exist, inject #GP
        VmExitInjectException(13, 0, FALSE);  // #GP
        return;
    }
    
    // Apply spoofing if needed
    // TODO: Hook specific MSRs for anti-detection
    
    // Return value in EDX:EAX
    GuestContext->Rax = msrValue & 0xFFFFFFFF;
    GuestContext->Rdx = msrValue >> 32;
}

VOID HandleMsrWrite(PGUEST_CONTEXT GuestContext) {
    UINT32 msr = (UINT32)GuestContext->Rcx;
    UINT64 msrValue = (GuestContext->Rax & 0xFFFFFFFF) | (GuestContext->Rdx << 32);
    
    // Write the MSR
    __try {
        __writemsr(msr, msrValue);
    }
    __except(EXCEPTION_EXECUTE_HANDLER) {
        // MSR doesn't exist or write failed, inject #GP
        VmExitInjectException(13, 0, FALSE);  // #GP
        return;
    }
}

VOID HandleIoInstruction(PGUEST_CONTEXT GuestContext) {
    UINT64 exitQualification = VmxRead(0x00006400);  // EXIT_QUALIFICATION
    
    UINT16 port = (UINT16)((exitQualification >> 16) & 0xFFFF);
    UINT8 size = (UINT8)(((exitQualification >> 0) & 0x7) + 1);  // 1, 2, or 4 bytes
    BOOLEAN isInput = (exitQualification & 0x8) != 0;
    BOOLEAN isString = (exitQualification & 0x10) != 0;
    
    HvLog(LOG_LEVEL_DEBUG, "I/O: Port=0x%X, Size=%d, Input=%d\n", 
          port, size, isInput);
    
    // Check if this is a disk-related I/O port
    if (ConfigIsEnabled() && g_SpoofConfig.SpoofDisk) {
        if ((port >= 0x1F0 && port <= 0x1F7) ||  // Primary ATA
            (port >= 0x170 && port <= 0x177)) {   // Secondary ATA
            
            // Let disk spoofer handle it
            DiskSpoofHandleIo(port, size, isInput, GuestContext);
            return;
        }
    }
    
    // For other I/O, emulate the instruction
    if (isInput) {
        UINT32 value = 0;
        switch (size) {
            case 1: value = __inbyte(port); break;
            case 2: value = __inword(port); break;
            case 4: value = __indword(port); break;
        }
        GuestContext->Rax = (GuestContext->Rax & ~((1ULL << (size * 8)) - 1)) | value;
    }
    else {
        UINT32 value = (UINT32)GuestContext->Rax;
        switch (size) {
            case 1: __outbyte(port, (UINT8)value); break;
            case 2: __outword(port, (UINT16)value); break;
            case 4: __outdword(port, value); break;
        }
    }
}

VOID HandleCrAccess(PGUEST_CONTEXT GuestContext) {
    UINT64 exitQualification = VmxRead(0x00006400);
    
    UINT8 crNum = (UINT8)(exitQualification & 0xF);
    UINT8 accessType = (UINT8)((exitQualification >> 4) & 0x3);  // 0=MOV to CR, 1=MOV from CR
    UINT8 gpr = (UINT8)((exitQualification >> 8) & 0xF);
    
    HvLog(LOG_LEVEL_DEBUG, "CR Access: CR%d, Type=%d, GPR=%d\n", 
          crNum, accessType, gpr);
    
    // For now, just emulate the access
    // TODO: Intercept if needed for anti-detection
    
    if (accessType == 0) {
        // MOV to CR
        // Get value from GPR and write to CR
        // (Implementation simplified)
    }
    else if (accessType == 1) {
        // MOV from CR
        // Read CR and write to GPR
        // (Implementation simplified)
    }
}

VOID HandleRdtsc(PGUEST_CONTEXT GuestContext) {
    UINT64 tsc;
    
    // Read actual TSC
    tsc = __rdtsc();
    
    // Apply timing compensation if enabled
    if (g_SpoofConfig.CompensateTiming) {
        tsc = CompensateTscTiming(tsc);
    }
    
    // Return value in EDX:EAX
    GuestContext->Rax = tsc & 0xFFFFFFFF;
    GuestContext->Rdx = tsc >> 32;
}

VOID HandleVmCall(PGUEST_CONTEXT GuestContext) {
    UINT32 vmcallNumber = (UINT32)GuestContext->Rcx;
    
    // VMCALL interface for communication with guest
    // Can be used for configuration updates, etc.
    
    switch (vmcallNumber) {
        case 0x1000:  // Test VMCALL
            GuestContext->Rax = 0x12345678;
            HvLog(LOG_LEVEL_INFO, "VMCALL: Test successful\n");
            break;
            
        case 0x1001:  // Get hypervisor status
            GuestContext->Rax = ConfigIsEnabled() ? 1 : 0;
            break;
            
        case 0x1002:  // Enable spoofing
            ConfigSetEnabled(TRUE);
            GuestContext->Rax = 0;
            break;
            
        case 0x1003:  // Disable spoofing
            ConfigSetEnabled(FALSE);
            GuestContext->Rax = 0;
            break;
            
        default:
            HvLog(LOG_LEVEL_WARNING, "VMCALL: Unknown number 0x%X\n", vmcallNumber);
            GuestContext->Rax = 0xFFFFFFFF;  // Error
            break;
    }
}

VOID HandleException(PGUEST_CONTEXT GuestContext) {
    UINT32 intrInfo = (UINT32)VmxRead(0x00004404);  // VM_EXIT_INTR_INFO
    UINT8 vector = (UINT8)(intrInfo & 0xFF);
    
    HvLog(LOG_LEVEL_WARNING, "Exception: Vector %d\n", vector);
    
    // Re-inject the exception into guest
    VmExitInjectException(vector, 0, FALSE);
}

VOID VmExitAdvanceRip(VOID) {
    UINT64 guestRip = VmxRead(GUEST_RIP);
    UINT32 instructionLength = (UINT32)VmxRead(0x0000440C);  // VM_EXIT_INSTRUCTION_LEN
    
    VmxWrite(GUEST_RIP, guestRip + instructionLength);
}

VOID VmExitInjectException(UINT8 Vector, UINT32 ErrorCode, BOOLEAN HasErrorCode) {
    UINT32 intrInfo = Vector | (3 << 8) | (1 << 31);  // Hardware exception, valid
    
    if (HasErrorCode) {
        intrInfo |= (1 << 11);  // Error code valid
        VmxWrite(0x00004406, ErrorCode);  // VM_ENTRY_EXCEPTION_ERROR_CODE
    }
    
    VmxWrite(0x00004016, intrInfo);  // VM_ENTRY_INTR_INFO_FIELD
}

