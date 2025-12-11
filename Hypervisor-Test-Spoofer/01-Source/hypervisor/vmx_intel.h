/*
 * Intel VT-x Hypervisor Implementation Header
 * Implements VMX (Virtual Machine Extensions) operations
 */

#ifndef VMX_INTEL_H
#define VMX_INTEL_H

#include <ntddk.h>

// VMX MSRs
#define IA32_FEATURE_CONTROL        0x0000003A
#define IA32_VMX_BASIC              0x00000480
#define IA32_VMX_PINBASED_CTLS      0x00000481
#define IA32_VMX_PROCBASED_CTLS     0x00000482
#define IA32_VMX_EXIT_CTLS          0x00000483
#define IA32_VMX_ENTRY_CTLS         0x00000484
#define IA32_VMX_CR0_FIXED0         0x00000486
#define IA32_VMX_CR0_FIXED1         0x00000487
#define IA32_VMX_CR4_FIXED0         0x00000488
#define IA32_VMX_CR4_FIXED1         0x00000489
#define IA32_VMX_PROCBASED_CTLS2    0x0000048B

// VMCS Encoding - Guest State
#define GUEST_ES_SELECTOR           0x00000800
#define GUEST_CS_SELECTOR           0x00000802
#define GUEST_SS_SELECTOR           0x00000804
#define GUEST_DS_SELECTOR           0x00000806
#define GUEST_FS_SELECTOR           0x00000808
#define GUEST_GS_SELECTOR           0x0000080A
#define GUEST_LDTR_SELECTOR         0x0000080C
#define GUEST_TR_SELECTOR           0x0000080E
#define GUEST_ES_LIMIT              0x00004800
#define GUEST_CS_LIMIT              0x00004802
#define GUEST_SS_LIMIT              0x00004804
#define GUEST_DS_LIMIT              0x00004806
#define GUEST_FS_LIMIT              0x00004808
#define GUEST_GS_LIMIT              0x0000480A
#define GUEST_LDTR_LIMIT            0x0000480C
#define GUEST_TR_LIMIT              0x0000480E
#define GUEST_GDTR_LIMIT            0x00004810
#define GUEST_IDTR_LIMIT            0x00004812
#define GUEST_ES_AR_BYTES           0x00004814
#define GUEST_CS_AR_BYTES           0x00004816
#define GUEST_SS_AR_BYTES           0x00004818
#define GUEST_DS_AR_BYTES           0x0000481A
#define GUEST_FS_AR_BYTES           0x0000481C
#define GUEST_GS_AR_BYTES           0x0000481E
#define GUEST_LDTR_AR_BYTES         0x00004820
#define GUEST_TR_AR_BYTES           0x00004822
#define GUEST_SYSENTER_CS           0x0000482A
#define GUEST_CR0                   0x00006800
#define GUEST_CR3                   0x00006802
#define GUEST_CR4                   0x00006804
#define GUEST_ES_BASE               0x00006806
#define GUEST_CS_BASE               0x00006808
#define GUEST_SS_BASE               0x0000680A
#define GUEST_DS_BASE               0x0000680C
#define GUEST_FS_BASE               0x0000680E
#define GUEST_GS_BASE               0x00006810
#define GUEST_LDTR_BASE             0x00006812
#define GUEST_TR_BASE               0x00006814
#define GUEST_GDTR_BASE             0x00006816
#define GUEST_IDTR_BASE             0x00006818
#define GUEST_DR7                   0x0000681A
#define GUEST_RSP                   0x0000681C
#define GUEST_RIP                   0x0000681E
#define GUEST_RFLAGS                0x00006820
#define GUEST_SYSENTER_ESP          0x00006824
#define GUEST_SYSENTER_EIP          0x00006826

// VMCS Encoding - Host State
#define HOST_ES_SELECTOR            0x00000C00
#define HOST_CS_SELECTOR            0x00000C02
#define HOST_SS_SELECTOR            0x00000C04
#define HOST_DS_SELECTOR            0x00000C06
#define HOST_FS_SELECTOR            0x00000C08
#define HOST_GS_SELECTOR            0x00000C0A
#define HOST_TR_SELECTOR            0x00000C0C
#define HOST_CR0                    0x00006C00
#define HOST_CR3                    0x00006C02
#define HOST_CR4                    0x00006C04
#define HOST_FS_BASE                0x00006C06
#define HOST_GS_BASE                0x00006C08
#define HOST_TR_BASE                0x00006C0A
#define HOST_GDTR_BASE              0x00006C0C
#define HOST_IDTR_BASE              0x00006C0E
#define HOST_SYSENTER_ESP           0x00006C10
#define HOST_SYSENTER_EIP           0x00006C12
#define HOST_RSP                    0x00006C14
#define HOST_RIP                    0x00006C16

// VMCS Encoding - Control Fields
#define PIN_BASED_VM_EXEC_CONTROL   0x00004000
#define CPU_BASED_VM_EXEC_CONTROL   0x00004002
#define EXCEPTION_BITMAP            0x00004004
#define VM_EXIT_CONTROLS            0x0000400C
#define VM_ENTRY_CONTROLS           0x00004012
#define SECONDARY_VM_EXEC_CONTROL   0x0000401E
#define VM_EXIT_REASON              0x00004402
#define VM_EXIT_INTR_INFO           0x00004404
#define VM_EXIT_INTR_ERROR_CODE     0x00004406
#define VM_EXIT_INSTRUCTION_LEN     0x0000440C
#define EXIT_QUALIFICATION          0x00006400

// VM Exit Reasons
#define EXIT_REASON_EXCEPTION_NMI       0
#define EXIT_REASON_EXTERNAL_INTERRUPT  1
#define EXIT_REASON_TRIPLE_FAULT        2
#define EXIT_REASON_INIT                3
#define EXIT_REASON_SIPI                4
#define EXIT_REASON_IO_SMI              5
#define EXIT_REASON_OTHER_SMI           6
#define EXIT_REASON_PENDING_VIRT_INTR   7
#define EXIT_REASON_PENDING_VIRT_NMI    8
#define EXIT_REASON_TASK_SWITCH         9
#define EXIT_REASON_CPUID               10
#define EXIT_REASON_HLT                 12
#define EXIT_REASON_INVD                13
#define EXIT_REASON_INVLPG              14
#define EXIT_REASON_RDPMC               15
#define EXIT_REASON_RDTSC               16
#define EXIT_REASON_RSM                 17
#define EXIT_REASON_VMCALL              18
#define EXIT_REASON_VMCLEAR             19
#define EXIT_REASON_VMLAUNCH            20
#define EXIT_REASON_VMPTRLD             21
#define EXIT_REASON_VMPTRST             22
#define EXIT_REASON_VMREAD              23
#define EXIT_REASON_VMRESUME            24
#define EXIT_REASON_VMWRITE             25
#define EXIT_REASON_VMXOFF              26
#define EXIT_REASON_VMXON               27
#define EXIT_REASON_CR_ACCESS           28
#define EXIT_REASON_DR_ACCESS           29
#define EXIT_REASON_IO_INSTRUCTION      30
#define EXIT_REASON_MSR_READ            31
#define EXIT_REASON_MSR_WRITE           32
#define EXIT_REASON_INVALID_GUEST_STATE 33
#define EXIT_REASON_MSR_LOADING         34
#define EXIT_REASON_MWAIT_INSTRUCTION   36
#define EXIT_REASON_MONITOR_TRAP_FLAG   37
#define EXIT_REASON_MONITOR_INSTRUCTION 39
#define EXIT_REASON_PAUSE_INSTRUCTION   40
#define EXIT_REASON_MCE_DURING_VMENTRY  41
#define EXIT_REASON_TPR_BELOW_THRESHOLD 43
#define EXIT_REASON_APIC_ACCESS         44
#define EXIT_REASON_EOI_INDUCED         45
#define EXIT_REASON_GDTR_IDTR           46
#define EXIT_REASON_LDTR_TR             47
#define EXIT_REASON_EPT_VIOLATION       48
#define EXIT_REASON_EPT_MISCONFIG       49
#define EXIT_REASON_INVEPT              50
#define EXIT_REASON_RDTSCP              51
#define EXIT_REASON_VMX_PREEMPTION_TIMER_EXPIRED 52
#define EXIT_REASON_INVVPID             53
#define EXIT_REASON_WBINVD              54
#define EXIT_REASON_XSETBV              55

// VMX per-CPU data structure
typedef struct _VMX_CPU {
    UINT64 VmxonRegionPhysical;
    PVOID VmxonRegionVirtual;
    
    UINT64 VmcsRegionPhysical;
    PVOID VmcsRegionVirtual;
    
    UINT64 VmmStackPhysical;
    PVOID VmmStackVirtual;
    
    UINT64 MsrBitmapPhysical;
    PVOID MsrBitmapVirtual;
    
    UINT64 IoBitmapAPhysical;
    PVOID IoBitmapAVirtual;
    
    UINT64 IoBitmapBPhysical;
    PVOID IoBitmapBVirtual;
    
    UINT64 OriginalCr0;
    UINT64 OriginalCr4;
    
    BOOLEAN IsVmxEnabled;
    UINT32 ProcessorNumber;
    
} VMX_CPU, *PVMX_CPU;

// Guest context (saved on VM exit)
typedef struct _GUEST_CONTEXT {
    UINT64 Rax;
    UINT64 Rcx;
    UINT64 Rdx;
    UINT64 Rbx;
    UINT64 Rsp;
    UINT64 Rbp;
    UINT64 Rsi;
    UINT64 Rdi;
    UINT64 R8;
    UINT64 R9;
    UINT64 R10;
    UINT64 R11;
    UINT64 R12;
    UINT64 R13;
    UINT64 R14;
    UINT64 R15;
} GUEST_CONTEXT, *PGUEST_CONTEXT;

/**
 * Initialize VMX on current CPU
 * @param VmxCpu: Per-CPU VMX data structure
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS VmxInitializeCpu(PVMX_CPU VmxCpu);

/**
 * Enable VMX operation on current CPU
 * @param VmxCpu: Per-CPU VMX data structure
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS VmxEnableVmxOperation(PVMX_CPU VmxCpu);

/**
 * Setup VMCS for current CPU
 * @param VmxCpu: Per-CPU VMX data structure
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS VmxSetupVmcs(PVMX_CPU VmxCpu);

/**
 * Launch VM on current CPU
 * @param VmxCpu: Per-CPU VMX data structure
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS VmxLaunchVm(PVMX_CPU VmxCpu);

/**
 * Teardown VMX on current CPU
 * @param VmxCpu: Per-CPU VMX data structure
 */
VOID VmxTeardownCpu(PVMX_CPU VmxCpu);

/**
 * VM Exit handler (called from assembly stub)
 * @param GuestContext: Guest register state
 * @return TRUE to continue VM, FALSE to exit VMX
 */
BOOLEAN VmxHandleVmExit(PGUEST_CONTEXT GuestContext);

/**
 * Read VMCS field
 * @param Field: VMCS field encoding
 * @return Field value
 */
UINT64 VmxRead(UINT32 Field);

/**
 * Write VMCS field
 * @param Field: VMCS field encoding
 * @param Value: Value to write
 */
VOID VmxWrite(UINT32 Field, UINT64 Value);

/**
 * Get segment descriptor
 */
VOID VmxGetSegmentDescriptor(UINT16 Selector, UINT64 GdtBase, PVOID SegmentDescriptor);

/**
 * Adjust VMX controls based on MSR capabilities
 */
UINT32 VmxAdjustControls(UINT32 Ctl, UINT32 Msr);

#endif // VMX_INTEL_H

