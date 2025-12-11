/*
 * Common Utilities Header
 * Provides basic utilities for memory management, MSR access, and CPU detection
 */

#ifndef UTILS_H
#define UTILS_H

#include <ntddk.h>
#include <intrin.h>

// CPU Vendor IDs
#define CPU_VENDOR_INTEL    0x01
#define CPU_VENDOR_AMD      0x02
#define CPU_VENDOR_UNKNOWN  0x00

// Memory pool tag
#define POOL_TAG 'RPYH'  // 'HYPR' reversed

// Logging levels
typedef enum _LOG_LEVEL {
    LOG_LEVEL_ERROR = 0,
    LOG_LEVEL_WARNING = 1,
    LOG_LEVEL_INFO = 2,
    LOG_LEVEL_DEBUG = 3
} LOG_LEVEL;

// Function declarations

/**
 * Allocate non-paged memory
 * @param Size: Size in bytes
 * @return Pointer to allocated memory or NULL on failure
 */
PVOID HvAllocateMemory(SIZE_T Size);

/**
 * Free memory allocated with HvAllocateMemory
 * @param Address: Pointer to memory to free
 */
VOID HvFreeMemory(PVOID Address);

/**
 * Allocate physically contiguous memory (required for VMCS, VMCB)
 * @param Size: Size in bytes
 * @return Pointer to allocated memory or NULL on failure
 */
PVOID HvAllocateContiguousMemory(SIZE_T Size);

/**
 * Free contiguous memory
 * @param Address: Pointer to memory to free
 */
VOID HvFreeContiguousMemory(PVOID Address);

/**
 * Get physical address from virtual address
 * @param VirtualAddress: Virtual address to convert
 * @return Physical address
 */
PHYSICAL_ADDRESS HvGetPhysicalAddress(PVOID VirtualAddress);

/**
 * Read Model Specific Register
 * @param Msr: MSR index
 * @return MSR value (64-bit)
 */
UINT64 HvReadMsr(UINT32 Msr);

/**
 * Write Model Specific Register
 * @param Msr: MSR index
 * @param Value: Value to write (64-bit)
 */
VOID HvWriteMsr(UINT32 Msr, UINT64 Value);

/**
 * Detect CPU vendor
 * @return CPU_VENDOR_INTEL, CPU_VENDOR_AMD, or CPU_VENDOR_UNKNOWN
 */
UINT8 HvDetectCpuVendor(VOID);

/**
 * Get CPU vendor string
 * @param Buffer: Buffer to store vendor string (must be at least 13 bytes)
 */
VOID HvGetCpuVendorString(CHAR* Buffer);

/**
 * Execute CPUID instruction
 * @param Leaf: CPUID leaf
 * @param Subleaf: CPUID subleaf
 * @param Eax: Pointer to store EAX
 * @param Ebx: Pointer to store EBX
 * @param Ecx: Pointer to store ECX
 * @param Edx: Pointer to store EDX
 */
VOID HvCpuid(UINT32 Leaf, UINT32 Subleaf, UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx);

/**
 * Log message
 * @param Level: Log level
 * @param Format: Printf-style format string
 */
VOID HvLog(LOG_LEVEL Level, const char* Format, ...);

/**
 * Initialize logging system
 * @param MinLevel: Minimum log level to display
 */
VOID HvInitializeLogging(LOG_LEVEL MinLevel);

/**
 * Check if virtualization is supported
 * @return TRUE if VT-x or AMD-V is supported, FALSE otherwise
 */
BOOLEAN HvIsVirtualizationSupported(VOID);

/**
 * Check if virtualization is enabled in BIOS
 * @return TRUE if enabled, FALSE otherwise
 */
BOOLEAN HvIsVirtualizationEnabled(VOID);

/**
 * Get current processor number
 * @return Processor number
 */
UINT32 HvGetCurrentProcessorNumber(VOID);

/**
 * Zero memory
 * @param Destination: Memory to zero
 * @param Length: Number of bytes
 */
VOID HvZeroMemory(PVOID Destination, SIZE_T Length);

/**
 * Copy memory
 * @param Destination: Destination buffer
 * @param Source: Source buffer
 * @param Length: Number of bytes
 */
VOID HvCopyMemory(PVOID Destination, const VOID* Source, SIZE_T Length);

#endif // UTILS_H

