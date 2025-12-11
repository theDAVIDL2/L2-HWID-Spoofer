/*
 * CPUID Spoofing Module Header
 * Intercepts and modifies CPUID instruction results
 */

#ifndef CPUID_SPOOF_H
#define CPUID_SPOOF_H

#include <ntddk.h>

/**
 * Spoof CPUID instruction
 * @param Leaf: CPUID leaf (function)
 * @param Subleaf: CPUID subleaf (subfunction)
 * @param Eax: Pointer to EAX register
 * @param Ebx: Pointer to EBX register
 * @param Ecx: Pointer to ECX register
 * @param Edx: Pointer to EDX register
 */
VOID CpuidSpoof(UINT32 Leaf, UINT32 Subleaf, UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx);

/**
 * Spoof processor vendor string (leaf 0)
 */
VOID CpuidSpoofVendor(UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx);

/**
 * Spoof processor info and features (leaf 1)
 */
VOID CpuidSpoofProcessorInfo(UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx);

/**
 * Spoof processor brand string (leaves 0x80000002-0x80000004)
 */
VOID CpuidSpoofBrandString(UINT32 Leaf, UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx);

/**
 * Spoof extended processor features (leaf 0x80000001)
 */
VOID CpuidSpoofExtendedFeatures(UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx);

#endif // CPUID_SPOOF_H

