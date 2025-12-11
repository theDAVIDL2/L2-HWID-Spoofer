/*
 * CPUID Spoofing Module Implementation
 */

#include "cpuid_spoof.h"
#include "../common/utils.h"
#include "../common/config.h"

VOID CpuidSpoof(UINT32 Leaf, UINT32 Subleaf, UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx) {
    // Execute real CPUID first
    HvCpuid(Leaf, Subleaf, Eax, Ebx, Ecx, Edx);
    
    // Apply spoofing based on leaf
    switch (Leaf) {
        case 0x00000000:  // Vendor string
            CpuidSpoofVendor(Eax, Ebx, Ecx, Edx);
            break;
            
        case 0x00000001:  // Processor info and features
            CpuidSpoofProcessorInfo(Eax, Ebx, Ecx, Edx);
            break;
            
        case 0x80000001:  // Extended features
            CpuidSpoofExtendedFeatures(Eax, Ebx, Ecx, Edx);
            break;
            
        case 0x80000002:  // Brand string part 1
        case 0x80000003:  // Brand string part 2
        case 0x80000004:  // Brand string part 3
            CpuidSpoofBrandString(Leaf, Eax, Ebx, Ecx, Edx);
            break;
            
        default:
            // No spoofing for other leaves
            break;
    }
    
    HvLog(LOG_LEVEL_DEBUG, "CPUID spoofed: Leaf=0x%08X, EAX=0x%08X\n", Leaf, *Eax);
}

VOID CpuidSpoofVendor(UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx) {
    // Vendor string is in EBX, EDX, ECX (12 characters)
    // Examples: "GenuineIntel", "AuthenticAMD"
    
    const CHAR* vendor = g_SpoofConfig.FakeCpuVendor;
    
    if (vendor[0] == '\0') {
        return;  // No vendor string configured
    }
    
    // EAX contains max CPUID leaf, don't modify
    
    // Set vendor string
    *Ebx = *(UINT32*)&vendor[0];  // Characters 0-3
    *Edx = *(UINT32*)&vendor[4];  // Characters 4-7
    *Ecx = *(UINT32*)&vendor[8];  // Characters 8-11
    
    HvLog(LOG_LEVEL_DEBUG, "Spoofed vendor: %.12s\n", vendor);
}

VOID CpuidSpoofProcessorInfo(UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx) {
    // EAX contains processor signature
    // Format: Extended Family (8 bits) | Extended Model (4 bits) | Reserved (2 bits) | 
    //         Type (2 bits) | Family (4 bits) | Model (4 bits) | Stepping (4 bits)
    
    if (g_SpoofConfig.FakeCpuSignature != 0) {
        *Eax = g_SpoofConfig.FakeCpuSignature;
        HvLog(LOG_LEVEL_DEBUG, "Spoofed CPU signature: 0x%08X\n", *Eax);
    }
    
    // EBX contains brand index, CLFLUSH size, max addressable IDs, initial APIC ID
    // Usually not spoofed unless specific needs
    
    // ECX and EDX contain feature flags
    // We keep these as-is to maintain compatibility
    // (Changing features could cause software issues)
}

VOID CpuidSpoofBrandString(UINT32 Leaf, UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx) {
    // Brand string is 48 characters across 3 CPUID leaves
    // Leaf 0x80000002: Characters 0-15
    // Leaf 0x80000003: Characters 16-31
    // Leaf 0x80000004: Characters 32-47
    
    const CHAR* brand = g_SpoofConfig.FakeCpuBrand;
    UINT32 offset;
    
    if (brand[0] == '\0') {
        return;  // No brand string configured
    }
    
    // Calculate offset into brand string
    offset = (Leaf - 0x80000002) * 16;
    
    // Set brand string (16 characters per leaf)
    *Eax = *(UINT32*)&brand[offset + 0];
    *Ebx = *(UINT32*)&brand[offset + 4];
    *Ecx = *(UINT32*)&brand[offset + 8];
    *Edx = *(UINT32*)&brand[offset + 12];
    
    if (Leaf == 0x80000002) {
        HvLog(LOG_LEVEL_DEBUG, "Spoofed brand: %.48s\n", brand);
    }
}

VOID CpuidSpoofExtendedFeatures(UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx) {
    // Extended features
    // EAX: Extended processor signature (usually same as leaf 1)
    // EBX: Reserved
    // ECX: Extended feature flags (AMD-specific features, etc.)
    // EDX: Extended feature flags
    
    if (g_SpoofConfig.FakeCpuSignature != 0) {
        *Eax = g_SpoofConfig.FakeCpuSignature;
    }
    
    // Feature flags usually left as-is for compatibility
}

