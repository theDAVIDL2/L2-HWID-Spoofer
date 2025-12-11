/*
 * VM Detection Evasion Module Implementation
 */

#include "vm_detection_evasion.h"
#include "../common/utils.h"
#include "../common/config.h"

VOID EvadeCpuidDetection(UINT32 Leaf, UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx) {
    // Apply various evasion techniques based on leaf
    
    switch (Leaf) {
        case 0x00000001:
            // Hide hypervisor present bit (ECX bit 31)
            EvadeHypervisorBit(Ecx);
            HvLog(LOG_LEVEL_DEBUG, "Cleared hypervisor bit in CPUID leaf 1\n");
            break;
            
        case 0x40000000:
            // Hide hypervisor vendor string
            EvadeHypervisorVendor(Eax, Ebx, Ecx, Edx);
            HvLog(LOG_LEVEL_DEBUG, "Hidden hypervisor vendor in CPUID leaf 0x40000000\n");
            break;
            
        case 0x40000001:
        case 0x40000002:
        case 0x40000003:
        case 0x40000004:
        case 0x40000005:
        case 0x40000006:
            // Hide all hypervisor-specific leaves
            if (ShouldHideHypervisorLeaf(Leaf)) {
                *Eax = 0;
                *Ebx = 0;
                *Ecx = 0;
                *Edx = 0;
                HvLog(LOG_LEVEL_DEBUG, "Hidden hypervisor leaf 0x%08X\n", Leaf);
            }
            break;
    }
}

VOID EvadeHypervisorBit(UINT32* Ecx) {
    if (!Ecx) {
        return;
    }
    
    // Clear bit 31 (hypervisor present)
    *Ecx &= ~(1 << 31);
}

VOID EvadeHypervisorVendor(UINT32* Eax, UINT32* Ebx, UINT32* Ecx, UINT32* Edx) {
    // Leaf 0x40000000 is used by hypervisors to advertise their presence
    // Typical vendor strings:
    // - "VMwareVMware" (VMware)
    // - "Microsoft Hv" (Hyper-V)
    // - "KVMKVMKVM\0\0\0" (KVM)
    // - "XenVMMXenVMM" (Xen)
    
    // Strategy: Return all zeros to indicate no hypervisor
    if (Eax) *Eax = 0;
    if (Ebx) *Ebx = 0;
    if (Ecx) *Ecx = 0;
    if (Edx) *Edx = 0;
    
    // Alternative strategy: Return valid but misleading data
    // This can help bypass more sophisticated detection
}

BOOLEAN ShouldHideHypervisorLeaf(UINT32 Leaf) {
    // Hypervisor leaves are in range 0x40000000 - 0x400000FF
    // These are reserved for hypervisor use
    
    if (Leaf >= 0x40000000 && Leaf <= 0x400000FF) {
        return TRUE;
    }
    
    return FALSE;
}

