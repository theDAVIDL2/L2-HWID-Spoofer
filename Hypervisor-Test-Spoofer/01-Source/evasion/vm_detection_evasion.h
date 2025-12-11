/*
 * VM Detection Evasion Module Header
 * Hides hypervisor presence from VM detection techniques
 */

#ifndef VM_DETECTION_EVASION_H
#define VM_DETECTION_EVASION_H

#include <ntddk.h>

/**
 * Evade CPUID-based VM detection
 * Modifies CPUID results to hide hypervisor presence
 * @param Leaf: CPUID leaf
 * @param Eax: Pointer to EAX register
 * @param Ebx: Pointer to EBX register
 * @param Ecx: Pointer to ECX register
 * @param Edx: Pointer to EDX register
 */
VOID EvadeCpuidDetection(UINT32 Leaf, UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx);

/**
 * Hide hypervisor bit in CPUID leaf 1
 * Clears ECX bit 31 (hypervisor present)
 * @param Ecx: Pointer to ECX register
 */
VOID EvadeHypervisorBit(UINT32* Ecx);

/**
 * Hide hypervisor vendor string in CPUID leaf 0x40000000
 * Returns zeros instead of vendor string
 * @param Eax: Pointer to EAX register
 * @param Ebx: Pointer to EBX register
 * @param Ecx: Pointer to ECX register
 * @param Edx: Pointer to EDX register
 */
VOID EvadeHypervisorVendor(UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx);

/**
 * Check if hypervisor leaves should be hidden
 * @param Leaf: CPUID leaf
 * @return TRUE if leaf should be hidden
 */
BOOLEAN ShouldHideHypervisorLeaf(UINT32 Leaf);

#endif // VM_DETECTION_EVASION_H

