/*
 * AMD SVM-Specific VM Exit Handlers Implementation
 */

#include "vmexit_handlers_amd.h"
#include "../common/utils.h"
#include "../common/config.h"
#include "../spoofing/cpuid_spoof.h"
#include "../spoofing/disk_spoof.h"
#include "../evasion/vm_detection_evasion.h"
#include "../evasion/rdtsc_evasion.h"

VOID SvmHandleCpuidExit(PSVM_CPU SvmCpu) {
    PVMCB_STATE_SAVE_AREA state = &SvmCpu->VmcbVirtual->StateSaveArea;
    UINT32 leaf = (UINT32)state->Rax;
    UINT32 subleaf = (UINT32)state->Rcx;
    UINT32 eax, ebx, ecx, edx;
    
    // Execute real CPUID first
    HvCpuid(leaf, subleaf, &eax, &ebx, &ecx, &edx);
    
    // Apply spoofing if enabled
    if (ConfigIsEnabled() && g_SpoofConfig.SpoofCpu) {
        CpuidSpoof(leaf, subleaf, &eax, &ebx, &ecx, &edx);
    }
    
    // Always apply VM detection evasion
    if (g_SpoofConfig.HideHypervisor) {
        EvadeCpuidDetection(leaf, &eax, &ebx, &ecx, &edx);
    }
    
    // Store results in VMCB
    state->Rax = eax;
    // RBX, RCX, RDX are not in VMCB state save area
    // They need to be set in guest general purpose registers
    // For now, we'll need to handle this in assembly or via GPR saving
    
    HvLog(LOG_LEVEL_DEBUG, "CPUID: Leaf=0x%X, EAX=0x%X\n", leaf, eax);
}

VOID SvmHandleMsrExit(PSVM_CPU SvmCpu) {
    PVMCB_CONTROL_AREA control = &SvmCpu->VmcbVirtual->ControlArea;
    PVMCB_STATE_SAVE_AREA state = &SvmCpu->VmcbVirtual->StateSaveArea;
    UINT32 msr = (UINT32)state->Rcx;
    UINT64 msrValue;
    BOOLEAN isWrite = (control->ExitInfo1 & 1) != 0;
    
    if (isWrite) {
        // MSR write (WRMSR)
        // Value in EDX:EAX
        msrValue = ((UINT64)((UINT32)(state->Rdx)) << 32) | (UINT32)state->Rax;
        
        __try {
            HvWriteMsr(msr, msrValue);
        }
        __except(EXCEPTION_EXECUTE_HANDLER) {
            HvLog(LOG_LEVEL_ERROR, "MSR write failed: MSR=0x%X\n", msr);
        }
        
        HvLog(LOG_LEVEL_DEBUG, "MSR Write: 0x%X = 0x%llX\n", msr, msrValue);
    }
    else {
        // MSR read (RDMSR)
        __try {
            msrValue = HvReadMsr(msr);
        }
        __except(EXCEPTION_EXECUTE_HANDLER) {
            HvLog(LOG_LEVEL_ERROR, "MSR read failed: MSR=0x%X\n", msr);
            msrValue = 0;
        }
        
        // Return in EDX:EAX
        state->Rax = msrValue & 0xFFFFFFFF;
        // RDX is not in state save area, needs GPR handling
        
        HvLog(LOG_LEVEL_DEBUG, "MSR Read: 0x%X = 0x%llX\n", msr, msrValue);
    }
}

VOID SvmHandleIoExit(PSVM_CPU SvmCpu) {
    PVMCB_CONTROL_AREA control = &SvmCpu->VmcbVirtual->ControlArea;
    PVMCB_STATE_SAVE_AREA state = &SvmCpu->VmcbVirtual->StateSaveArea;
    UINT64 exitInfo1 = control->ExitInfo1;
    
    // Parse I/O exit info
    // ExitInfo1 format:
    // [0]     = Port I/O (0=MMIO, 1=Port I/O)
    // [1]     = Reserved
    // [2]     = String operation
    // [3]     = REP prefix
    // [4]     = Operand size (0=8bit, 1=16bit, 2=32bit)
    // [5]     = Reserved
    // [6]     = Direction (0=OUT, 1=IN)
    // [31:16] = Port number
    
    UINT16 port = (UINT16)((exitInfo1 >> 16) & 0xFFFF);
    BOOLEAN isInput = (exitInfo1 & (1 << 6)) != 0;
    UINT8 size = 1 << ((exitInfo1 >> 4) & 0x3);  // 1, 2, or 4 bytes
    
    HvLog(LOG_LEVEL_DEBUG, "I/O: Port=0x%X, Size=%d, Input=%d\n", port, size, isInput);
    
    // Check if this is disk-related I/O
    if (ConfigIsEnabled() && g_SpoofConfig.SpoofDisk) {
        if ((port >= 0x1F0 && port <= 0x1F7) ||  // Primary ATA
            (port >= 0x170 && port <= 0x177)) {   // Secondary ATA
            
            // Convert state to guest context for disk spoofer
            GUEST_CONTEXT guestContext = { 0 };
            guestContext.Rax = state->Rax;
            guestContext.Rsp = state->Rsp;
            
            DiskSpoofHandleIo(port, size, isInput, &guestContext);
            
            state->Rax = guestContext.Rax;
            return;
        }
    }
    
    // Emulate the I/O instruction
    if (isInput) {
        UINT32 value = 0;
        switch (size) {
            case 1: value = __inbyte(port); break;
            case 2: value = __inword(port); break;
            case 4: value = __indword(port); break;
        }
        state->Rax = (state->Rax & ~((1ULL << (size * 8)) - 1)) | value;
    }
    else {
        UINT32 value = (UINT32)state->Rax;
        switch (size) {
            case 1: __outbyte(port, (UINT8)value); break;
            case 2: __outword(port, (UINT16)value); break;
            case 4: __outdword(port, value); break;
        }
    }
}

VOID SvmHandleRdtscExit(PSVM_CPU SvmCpu) {
    PVMCB_STATE_SAVE_AREA state = &SvmCpu->VmcbVirtual->StateSaveArea;
    UINT64 tsc;
    
    // Read actual TSC
    tsc = __rdtsc();
    
    // Apply timing compensation if enabled
    if (g_SpoofConfig.CompensateTiming) {
        tsc = CompensateTscTiming(tsc);
    }
    
    // Return value in EDX:EAX
    state->Rax = tsc & 0xFFFFFFFF;
    // RDX needs to be set in GPR handling
    
    HvLog(LOG_LEVEL_DEBUG, "RDTSC: TSC=0x%llX\n", tsc);
}

VOID SvmHandleVmmcallExit(PSVM_CPU SvmCpu) {
    PVMCB_STATE_SAVE_AREA state = &SvmCpu->VmcbVirtual->StateSaveArea;
    UINT32 vmcallNumber = (UINT32)state->Rcx;
    
    // VMMCALL interface for guest-host communication
    switch (vmcallNumber) {
        case 0x1000:  // Test VMMCALL
            state->Rax = 0x12345678;
            HvLog(LOG_LEVEL_INFO, "VMMCALL: Test successful\n");
            break;
            
        case 0x1001:  // Get hypervisor status
            state->Rax = ConfigIsEnabled() ? 1 : 0;
            break;
            
        case 0x1002:  // Enable spoofing
            ConfigSetEnabled(TRUE);
            state->Rax = 0;
            break;
            
        case 0x1003:  // Disable spoofing
            ConfigSetEnabled(FALSE);
            state->Rax = 0;
            break;
            
        default:
            HvLog(LOG_LEVEL_WARNING, "VMMCALL: Unknown number 0x%X\n", vmcallNumber);
            state->Rax = 0xFFFFFFFF;  // Error
            break;
    }
}

