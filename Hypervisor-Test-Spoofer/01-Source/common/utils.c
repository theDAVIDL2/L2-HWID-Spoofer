/*
 * Common Utilities Implementation
 */

#include "utils.h"
#include <stdarg.h>

// Global log level
static LOG_LEVEL g_MinLogLevel = LOG_LEVEL_INFO;

PVOID HvAllocateMemory(SIZE_T Size) {
    return ExAllocatePoolWithTag(NonPagedPool, Size, POOL_TAG);
}

VOID HvFreeMemory(PVOID Address) {
    if (Address) {
        ExFreePoolWithTag(Address, POOL_TAG);
    }
}

PVOID HvAllocateContiguousMemory(SIZE_T Size) {
    PHYSICAL_ADDRESS highestAcceptableAddress;
    highestAcceptableAddress.QuadPart = ~0ULL;
    
    return MmAllocateContiguousMemory(Size, highestAcceptableAddress);
}

VOID HvFreeContiguousMemory(PVOID Address) {
    if (Address) {
        MmFreeContiguousMemory(Address);
    }
}

PHYSICAL_ADDRESS HvGetPhysicalAddress(PVOID VirtualAddress) {
    return MmGetPhysicalAddress(VirtualAddress);
}

UINT64 HvReadMsr(UINT32 Msr) {
    return __readmsr(Msr);
}

VOID HvWriteMsr(UINT32 Msr, UINT64 Value) {
    __writemsr(Msr, Value);
}

UINT8 HvDetectCpuVendor(VOID) {
    CHAR vendorString[13] = { 0 };
    UINT32 eax, ebx, ecx, edx;
    
    // Get vendor string
    HvCpuid(0, 0, &eax, &ebx, &ecx, &edx);
    
    // Build vendor string: EBX + EDX + ECX
    *(UINT32*)&vendorString[0] = ebx;
    *(UINT32*)&vendorString[4] = edx;
    *(UINT32*)&vendorString[8] = ecx;
    vendorString[12] = '\0';
    
    // Check vendor
    if (RtlCompareMemory(vendorString, "GenuineIntel", 12) == 12) {
        return CPU_VENDOR_INTEL;
    }
    else if (RtlCompareMemory(vendorString, "AuthenticAMD", 12) == 12) {
        return CPU_VENDOR_AMD;
    }
    
    return CPU_VENDOR_UNKNOWN;
}

VOID HvGetCpuVendorString(CHAR* Buffer) {
    UINT32 eax, ebx, ecx, edx;
    
    if (!Buffer) {
        return;
    }
    
    HvCpuid(0, 0, &eax, &ebx, &ecx, &edx);
    
    *(UINT32*)&Buffer[0] = ebx;
    *(UINT32*)&Buffer[4] = edx;
    *(UINT32*)&Buffer[8] = ecx;
    Buffer[12] = '\0';
}

VOID HvCpuid(UINT32 Leaf, UINT32 Subleaf, UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx) {
    INT32 cpuInfo[4];
    
    __cpuidex(cpuInfo, (INT32)Leaf, (INT32)Subleaf);
    
    if (Eax) *Eax = cpuInfo[0];
    if (Ebx) *Ebx = cpuInfo[1];
    if (Ecx) *Ecx = cpuInfo[2];
    if (Edx) *Edx = cpuInfo[3];
}

VOID HvInitializeLogging(LOG_LEVEL MinLevel) {
    g_MinLogLevel = MinLevel;
    HvLog(LOG_LEVEL_INFO, "[HV] Logging initialized (MinLevel=%d)\n", MinLevel);
}

VOID HvLog(LOG_LEVEL Level, const char* Format, ...) {
    va_list args;
    CHAR buffer[512];
    
    // Filter by log level
    if (Level > g_MinLogLevel) {
        return;
    }
    
    // Build message
    va_start(args, Format);
    RtlStringCbVPrintfA(buffer, sizeof(buffer), Format, args);
    va_end(args);
    
    // Print based on level
    switch (Level) {
        case LOG_LEVEL_ERROR:
            DbgPrint("[HV-ERROR] %s", buffer);
            break;
        case LOG_LEVEL_WARNING:
            DbgPrint("[HV-WARN] %s", buffer);
            break;
        case LOG_LEVEL_INFO:
            DbgPrint("[HV-INFO] %s", buffer);
            break;
        case LOG_LEVEL_DEBUG:
            DbgPrint("[HV-DEBUG] %s", buffer);
            break;
    }
}

BOOLEAN HvIsVirtualizationSupported(VOID) {
    UINT32 eax, ebx, ecx, edx;
    UINT8 vendor = HvDetectCpuVendor();
    
    if (vendor == CPU_VENDOR_INTEL) {
        // Check CPUID.1:ECX.VMX[bit 5]
        HvCpuid(1, 0, &eax, &ebx, &ecx, &edx);
        return (ecx & (1 << 5)) != 0;
    }
    else if (vendor == CPU_VENDOR_AMD) {
        // Check CPUID.0x80000001:ECX.SVM[bit 2]
        HvCpuid(0x80000001, 0, &eax, &ebx, &ecx, &edx);
        return (ecx & (1 << 2)) != 0;
    }
    
    return FALSE;
}

BOOLEAN HvIsVirtualizationEnabled(VOID) {
    UINT8 vendor = HvDetectCpuVendor();
    
    if (vendor == CPU_VENDOR_INTEL) {
        // Check IA32_FEATURE_CONTROL MSR
        UINT64 featureControl = HvReadMsr(0x3A);  // IA32_FEATURE_CONTROL
        
        // Bit 0: Lock bit
        // Bit 2: Enable VMX outside SMX operation
        return (featureControl & 0x5) == 0x5;
    }
    else if (vendor == CPU_VENDOR_AMD) {
        // Check VM_CR MSR
        UINT64 vmCr = HvReadMsr(0xC0010114);  // VM_CR
        
        // Bit 4: SVMDIS (if set, SVM is disabled)
        return (vmCr & (1 << 4)) == 0;
    }
    
    return FALSE;
}

UINT32 HvGetCurrentProcessorNumber(VOID) {
    return (UINT32)KeGetCurrentProcessorNumber();
}

VOID HvZeroMemory(PVOID Destination, SIZE_T Length) {
    RtlZeroMemory(Destination, Length);
}

VOID HvCopyMemory(PVOID Destination, const VOID* Source, SIZE_T Length) {
    RtlCopyMemory(Destination, Source, Length);
}

