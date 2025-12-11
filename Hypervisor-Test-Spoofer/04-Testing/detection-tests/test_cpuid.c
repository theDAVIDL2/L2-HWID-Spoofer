/*
 * CPUID-based VM Detection Test
 * Tests various CPUID-based detection techniques
 */

#include <Windows.h>
#include <stdio.h>
#include <intrin.h>

void TestHypervisorBit() {
    int cpuInfo[4];
    
    printf("[+] Testing CPUID Leaf 1 (Hypervisor Present Bit)...\n");
    
    __cpuid(cpuInfo, 1);
    
    // Check ECX bit 31
    if (cpuInfo[2] & (1 << 31)) {
        printf("  [DETECTED] Hypervisor present bit is SET\n");
        printf("  ECX = 0x%08X\n", cpuInfo[2]);
    }
    else {
        printf("  [PASS] Hypervisor present bit is CLEAR\n");
    }
}

void TestHypervisorVendor() {
    int cpuInfo[4];
    char vendor[13] = { 0 };
    
    printf("\n[+] Testing CPUID Leaf 0x40000000 (Hypervisor Vendor)...\n");
    
    __cpuid(cpuInfo, 0x40000000);
    
    // Build vendor string from EBX, ECX, EDX
    *(int*)&vendor[0] = cpuInfo[1];
    *(int*)&vendor[4] = cpuInfo[2];
    *(int*)&vendor[8] = cpuInfo[3];
    
    if (cpuInfo[0] == 0 && cpuInfo[1] == 0 && cpuInfo[2] == 0 && cpuInfo[3] == 0) {
        printf("  [PASS] No hypervisor vendor string\n");
    }
    else {
        printf("  [DETECTED] Hypervisor vendor: %.12s\n", vendor);
        printf("  EAX = 0x%08X\n", cpuInfo[0]);
        printf("  Known vendors:\n");
        printf("    - VMwareVMware (VMware)\n");
        printf("    - Microsoft Hv (Hyper-V)\n");
        printf("    - KVMKVMKVM    (KVM)\n");
        printf("    - XenVMMXenVMM (Xen)\n");
    }
}

void TestCPUSignature() {
    int cpuInfo[4];
    
    printf("\n[+] Testing CPU Signature Consistency...\n");
    
    __cpuid(cpuInfo, 1);
    
    unsigned int stepping = cpuInfo[0] & 0xF;
    unsigned int model = (cpuInfo[0] >> 4) & 0xF;
    unsigned int family = (cpuInfo[0] >> 8) & 0xF;
    unsigned int type = (cpuInfo[0] >> 12) & 0x3;
    unsigned int extModel = (cpuInfo[0] >> 16) & 0xF;
    unsigned int extFamily = (cpuInfo[0] >> 20) & 0xFF;
    
    printf("  CPU Signature: 0x%08X\n", cpuInfo[0]);
    printf("  Family: %u, Model: %u, Stepping: %u\n", family, model, stepping);
    printf("  Extended Family: %u, Extended Model: %u\n", extFamily, extModel);
    printf("  Type: %u\n", type);
    
    // Check for impossible combinations
    char cpuVendor[13] = { 0 };
    __cpuid(cpuInfo, 0);
    *(int*)&cpuVendor[0] = cpuInfo[1];
    *(int*)&cpuVendor[4] = cpuInfo[3];
    *(int*)&cpuVendor[8] = cpuInfo[2];
    
    printf("  CPU Vendor: %.12s\n", cpuVendor);
    
    // Basic sanity checks
    if (family == 0 || family > 15) {
        printf("  [WARNING] Unusual CPU family value\n");
    }
}

void TestCPUIDBrandString() {
    int cpuInfo[4];
    char brand[49] = { 0 };
    
    printf("\n[+] Testing CPU Brand String...\n");
    
    // Get brand string (48 characters)
    __cpuid(cpuInfo, 0x80000002);
    *(int*)&brand[0] = cpuInfo[0];
    *(int*)&brand[4] = cpuInfo[1];
    *(int*)&brand[8] = cpuInfo[2];
    *(int*)&brand[12] = cpuInfo[3];
    
    __cpuid(cpuInfo, 0x80000003);
    *(int*)&brand[16] = cpuInfo[0];
    *(int*)&brand[20] = cpuInfo[1];
    *(int*)&brand[24] = cpuInfo[2];
    *(int*)&brand[28] = cpuInfo[3];
    
    __cpuid(cpuInfo, 0x80000004);
    *(int*)&brand[32] = cpuInfo[0];
    *(int*)&brand[36] = cpuInfo[1];
    *(int*)&brand[40] = cpuInfo[2];
    *(int*)&brand[44] = cpuInfo[3];
    
    printf("  Brand: %.48s\n", brand);
}

int main() {
    printf("===========================================\n");
    printf("CPUID-Based VM Detection Test\n");
    printf("===========================================\n\n");
    
    TestHypervisorBit();
    TestHypervisorVendor();
    TestCPUSignature();
    TestCPUIDBrandString();
    
    printf("\n===========================================\n");
    printf("Test Complete\n");
    printf("===========================================\n");
    
    return 0;
}

