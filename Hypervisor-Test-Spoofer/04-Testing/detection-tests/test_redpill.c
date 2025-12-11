/*
 * Red Pill VM Detection Test
 * Tests SIDT/SGDT-based detection (descriptor table location)
 */

#include <Windows.h>
#include <stdio.h>

// Descriptor table register structure
#pragma pack(push, 1)
typedef struct {
    unsigned short limit;
    unsigned __int64 base;
} DTR;
#pragma pack(pop)

void TestSIDT() {
    DTR idtr;
    
    printf("[+] Testing SIDT (Interrupt Descriptor Table)...\n");
    
    // Execute SIDT instruction
    __sidt(&idtr);
    
    printf("  IDT Base:  0x%016llX\n", idtr.base);
    printf("  IDT Limit: 0x%04X\n", idtr.limit);
    
    // On real hardware, IDT is typically in low memory
    // In VMs, IDT might be in high memory (hypervisor space)
    
    if (idtr.base > 0xFFFF000000000000ULL) {
        printf("  [DETECTED] IDT in high memory (typical for VM)\n");
        printf("  The IDT base suggests hypervisor memory space\n");
    }
    else if (idtr.base < 0x1000) {
        printf("  [SUSPICIOUS] IDT in very low memory\n");
    }
    else {
        printf("  [PASS] IDT location appears normal\n");
    }
}

void TestSGDT() {
    DTR gdtr;
    
    printf("\n[+] Testing SGDT (Global Descriptor Table)...\n");
    
    // Execute SGDT instruction
    __sgdt(&gdtr);
    
    printf("  GDT Base:  0x%016llX\n", gdtr.base);
    printf("  GDT Limit: 0x%04X\n", gdtr.limit);
    
    // Similar analysis as SIDT
    if (gdtr.base > 0xFFFF000000000000ULL) {
        printf("  [DETECTED] GDT in high memory (typical for VM)\n");
    }
    else if (gdtr.base < 0x1000) {
        printf("  [SUSPICIOUS] GDT in very low memory\n");
    }
    else {
        printf("  [PASS] GDT location appears normal\n");
    }
}

void TestSLDT() {
    unsigned short ldtr;
    
    printf("\n[+] Testing SLDT (Local Descriptor Table)...\n");
    
    // Execute SLDT instruction
    __asm {
        sldt ax
        mov ldtr, ax
    }
    
    printf("  LDT Selector: 0x%04X\n", ldtr);
    
    // LDT is rarely used in modern Windows
    // Non-zero value might indicate virtualization
    if (ldtr != 0) {
        printf("  [INFO] LDT is in use (value: 0x%04X)\n", ldtr);
    }
    else {
        printf("  [PASS] LDT not in use (typical for Windows)\n");
    }
}

void TestSTR() {
    unsigned short tr;
    
    printf("\n[+] Testing STR (Task Register)...\n");
    
    // Execute STR instruction
    __asm {
        str ax
        mov tr, ax
    }
    
    printf("  TR Selector: 0x%04X\n", tr);
    
    // TR should always be non-zero on running system
    if (tr == 0) {
        printf("  [SUSPICIOUS] TR is zero (unusual)\n");
    }
    else {
        printf("  [PASS] TR has valid value\n");
    }
}

void TestDescriptorTableComparison() {
    DTR idtr1, idtr2;
    
    printf("\n[+] Testing Descriptor Table Stability...\n");
    
    // Read IDT twice
    __sidt(&idtr1);
    Sleep(100);  // Small delay
    __sidt(&idtr2);
    
    if (idtr1.base != idtr2.base || idtr1.limit != idtr2.limit) {
        printf("  [DETECTED] IDT changed between reads!\n");
        printf("  First:  Base=0x%016llX, Limit=0x%04X\n", idtr1.base, idtr1.limit);
        printf("  Second: Base=0x%016llX, Limit=0x%04X\n", idtr2.base, idtr2.limit);
        printf("  This suggests VM migration or dynamic remapping\n");
    }
    else {
        printf("  [PASS] IDT stable across reads\n");
    }
}

int main() {
    printf("===========================================\n");
    printf("Red Pill VM Detection Test\n");
    printf("SIDT/SGDT/SLDT/STR Analysis\n");
    printf("===========================================\n\n");
    
    printf("Note: These tests examine descriptor table locations\n");
    printf("      to detect virtualization. VMs often place these\n");
    printf("      tables in different memory regions than bare metal.\n\n");
    
    TestSIDT();
    TestSGDT();
    TestSLDT();
    TestSTR();
    TestDescriptorTableComparison();
    
    printf("\n===========================================\n");
    printf("Test Complete\n");
    printf("===========================================\n");
    
    printf("\n");
    printf("Interpretation:\n");
    printf("  - IDT/GDT in high memory (>0xFFFF000000000000): Likely VM\n");
    printf("  - IDT/GDT in normal range: Likely bare metal\n");
    printf("  - Changing values: Possible VM migration\n");
    
    return 0;
}

