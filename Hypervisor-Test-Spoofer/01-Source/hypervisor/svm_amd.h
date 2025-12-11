/*
 * AMD-V (SVM) Hypervisor Implementation Header
 * Implements SVM (Secure Virtual Machine) operations for AMD CPUs
 */

#ifndef SVM_AMD_H
#define SVM_AMD_H

#include <ntddk.h>

// SVM MSRs
#define MSR_VM_CR                   0xC0010114  // VM_CR - SVM control
#define MSR_VM_HSAVE_PA             0xC0010117  // Host save area physical address
#define MSR_EFER                    0xC0000080  // Extended Feature Enable Register

// EFER bits
#define EFER_SVME                   (1ULL << 12)  // SVM Enable

// VM_CR bits
#define VM_CR_SVMDIS                (1 << 4)   // SVM Disable

// VMCB Control Area offsets
#define VMCB_CONTROL_INTERCEPT_CR_READ      0x000
#define VMCB_CONTROL_INTERCEPT_CR_WRITE     0x010
#define VMCB_CONTROL_INTERCEPT_DR_READ      0x020
#define VMCB_CONTROL_INTERCEPT_DR_WRITE     0x030
#define VMCB_CONTROL_INTERCEPT_EXCEPTION    0x040
#define VMCB_CONTROL_INTERCEPT_MISC1        0x048
#define VMCB_CONTROL_INTERCEPT_MISC2        0x04C
#define VMCB_CONTROL_INTERCEPT_MISC3        0x050
#define VMCB_CONTROL_PAUSE_FILTER_THRESHOLD 0x058
#define VMCB_CONTROL_PAUSE_FILTER_COUNT     0x05C
#define VMCB_CONTROL_IOPM_BASE_PA           0x060
#define VMCB_CONTROL_MSRPM_BASE_PA          0x068
#define VMCB_CONTROL_TSC_OFFSET             0x070
#define VMCB_CONTROL_GUEST_ASID             0x078
#define VMCB_CONTROL_TLB_CONTROL            0x07C
#define VMCB_CONTROL_V_TPR                  0x080
#define VMCB_CONTROL_V_IRQ                  0x088
#define VMCB_CONTROL_INTERRUPT_SHADOW       0x090
#define VMCB_CONTROL_EXITCODE               0x098
#define VMCB_CONTROL_EXITINFO1              0x0A0
#define VMCB_CONTROL_EXITINFO2              0x0A8
#define VMCB_CONTROL_EXITINTINFO            0x0B0
#define VMCB_CONTROL_NP_ENABLE              0x0B8
#define VMCB_CONTROL_AVIC_APIC_BAR          0x0C0
#define VMCB_CONTROL_GUEST_PA_OF_GHCB       0x0C8
#define VMCB_CONTROL_EVENTINJ               0x0D0
#define VMCB_CONTROL_N_CR3                  0x0D8
#define VMCB_CONTROL_LBR_VIRTUALIZATION_ENABLE  0x0E0
#define VMCB_CONTROL_VMCB_CLEAN             0x0E8
#define VMCB_CONTROL_NRIP                   0x0F0
#define VMCB_CONTROL_NUMBER_OF_BYTES_FETCHED    0x0F8
#define VMCB_CONTROL_GUEST_INSTRUCTION_BYTES    0x0FA

// VMEXIT codes
#define VMEXIT_CR0_READ             0x00
#define VMEXIT_CR1_READ             0x01
#define VMEXIT_CR2_READ             0x02
#define VMEXIT_CR3_READ             0x03
#define VMEXIT_CR4_READ             0x04
#define VMEXIT_CR0_WRITE            0x10
#define VMEXIT_CR1_WRITE            0x11
#define VMEXIT_CR2_WRITE            0x12
#define VMEXIT_CR3_WRITE            0x13
#define VMEXIT_CR4_WRITE            0x14
#define VMEXIT_DR0_READ             0x20
#define VMEXIT_DR1_READ             0x21
#define VMEXIT_DR2_READ             0x22
#define VMEXIT_DR3_READ             0x23
#define VMEXIT_DR0_WRITE            0x30
#define VMEXIT_DR1_WRITE            0x31
#define VMEXIT_DR2_WRITE            0x32
#define VMEXIT_DR3_WRITE            0x33
#define VMEXIT_EXCEPTION_DE         0x40
#define VMEXIT_EXCEPTION_DB         0x41
#define VMEXIT_EXCEPTION_NMI        0x42
#define VMEXIT_EXCEPTION_BP         0x43
#define VMEXIT_EXCEPTION_OF         0x44
#define VMEXIT_EXCEPTION_BR         0x45
#define VMEXIT_EXCEPTION_UD         0x46
#define VMEXIT_EXCEPTION_NM         0x47
#define VMEXIT_EXCEPTION_DF         0x48
#define VMEXIT_EXCEPTION_09         0x49
#define VMEXIT_EXCEPTION_TS         0x4A
#define VMEXIT_EXCEPTION_NP         0x4B
#define VMEXIT_EXCEPTION_SS         0x4C
#define VMEXIT_EXCEPTION_GP         0x4D
#define VMEXIT_EXCEPTION_PF         0x4E
#define VMEXIT_EXCEPTION_15         0x4F
#define VMEXIT_EXCEPTION_MF         0x50
#define VMEXIT_EXCEPTION_AC         0x51
#define VMEXIT_EXCEPTION_MC         0x52
#define VMEXIT_EXCEPTION_XF         0x53
#define VMEXIT_INTR                 0x60
#define VMEXIT_NMI                  0x61
#define VMEXIT_SMI                  0x62
#define VMEXIT_INIT                 0x63
#define VMEXIT_VINTR                0x64
#define VMEXIT_CR0_SEL_WRITE        0x65
#define VMEXIT_IDTR_READ            0x66
#define VMEXIT_GDTR_READ            0x67
#define VMEXIT_LDTR_READ            0x68
#define VMEXIT_TR_READ              0x69
#define VMEXIT_IDTR_WRITE           0x6A
#define VMEXIT_GDTR_WRITE           0x6B
#define VMEXIT_LDTR_WRITE           0x6C
#define VMEXIT_TR_WRITE             0x6D
#define VMEXIT_RDTSC                0x6E
#define VMEXIT_RDPMC                0x6F
#define VMEXIT_PUSHF                0x70
#define VMEXIT_POPF                 0x71
#define VMEXIT_CPUID                0x72
#define VMEXIT_RSM                  0x73
#define VMEXIT_IRET                 0x74
#define VMEXIT_SWINT                0x75
#define VMEXIT_INVD                 0x76
#define VMEXIT_PAUSE                0x77
#define VMEXIT_HLT                  0x78
#define VMEXIT_INVLPG               0x79
#define VMEXIT_INVLPGA              0x7A
#define VMEXIT_IOIO                 0x7B
#define VMEXIT_MSR                  0x7C
#define VMEXIT_TASK_SWITCH          0x7D
#define VMEXIT_FERR_FREEZE          0x7E
#define VMEXIT_SHUTDOWN             0x7F
#define VMEXIT_VMRUN                0x80
#define VMEXIT_VMMCALL              0x81
#define VMEXIT_VMLOAD               0x82
#define VMEXIT_VMSAVE               0x83
#define VMEXIT_STGI                 0x84
#define VMEXIT_CLGI                 0x85
#define VMEXIT_SKINIT               0x86
#define VMEXIT_RDTSCP               0x87
#define VMEXIT_ICEBP                0x88
#define VMEXIT_WBINVD               0x89
#define VMEXIT_MONITOR              0x8A
#define VMEXIT_MWAIT                0x8B
#define VMEXIT_MWAIT_CONDITIONAL    0x8C
#define VMEXIT_XSETBV               0x8D
#define VMEXIT_NPF                  0x400
#define VMEXIT_INVALID              -1

// Intercept bits (MISC1)
#define SVM_INTERCEPT_INTR          (1 << 0)
#define SVM_INTERCEPT_NMI           (1 << 1)
#define SVM_INTERCEPT_SMI           (1 << 2)
#define SVM_INTERCEPT_INIT          (1 << 3)
#define SVM_INTERCEPT_VINTR         (1 << 4)
#define SVM_INTERCEPT_CR0_SEL_WRITE (1 << 5)
#define SVM_INTERCEPT_IDTR_READ     (1 << 6)
#define SVM_INTERCEPT_GDTR_READ     (1 << 7)
#define SVM_INTERCEPT_LDTR_READ     (1 << 8)
#define SVM_INTERCEPT_TR_READ       (1 << 9)
#define SVM_INTERCEPT_IDTR_WRITE    (1 << 10)
#define SVM_INTERCEPT_GDTR_WRITE    (1 << 11)
#define SVM_INTERCEPT_LDTR_WRITE    (1 << 12)
#define SVM_INTERCEPT_TR_WRITE      (1 << 13)
#define SVM_INTERCEPT_RDTSC         (1 << 14)
#define SVM_INTERCEPT_RDPMC         (1 << 15)
#define SVM_INTERCEPT_PUSHF         (1 << 16)
#define SVM_INTERCEPT_POPF          (1 << 17)
#define SVM_INTERCEPT_CPUID         (1 << 18)
#define SVM_INTERCEPT_RSM           (1 << 19)
#define SVM_INTERCEPT_IRET          (1 << 20)
#define SVM_INTERCEPT_SWINT         (1 << 21)
#define SVM_INTERCEPT_INVD          (1 << 22)
#define SVM_INTERCEPT_PAUSE         (1 << 23)
#define SVM_INTERCEPT_HLT           (1 << 24)
#define SVM_INTERCEPT_INVLPG        (1 << 25)
#define SVM_INTERCEPT_INVLPGA       (1 << 26)
#define SVM_INTERCEPT_IOIO_PROT     (1 << 27)
#define SVM_INTERCEPT_MSR_PROT      (1 << 28)
#define SVM_INTERCEPT_TASK_SWITCH   (1 << 29)
#define SVM_INTERCEPT_FERR_FREEZE   (1 << 30)
#define SVM_INTERCEPT_SHUTDOWN      (1U << 31)

// Segment attributes
typedef struct _SVM_SEGMENT_ATTRIBUTE {
    UINT16 Type : 4;
    UINT16 System : 1;
    UINT16 Dpl : 2;
    UINT16 Present : 1;
    UINT16 Available : 1;
    UINT16 LongMode : 1;
    UINT16 DefaultBig : 1;
    UINT16 Granularity : 1;
    UINT16 Reserved : 4;
} SVM_SEGMENT_ATTRIBUTE, *PSVM_SEGMENT_ATTRIBUTE;

// Segment descriptor
typedef struct _SVM_SEGMENT {
    UINT16 Selector;
    UINT16 Attributes;
    UINT32 Limit;
    UINT64 Base;
} SVM_SEGMENT, *PSVM_SEGMENT;

// VMCB State Save Area (Guest state)
typedef struct _VMCB_STATE_SAVE_AREA {
    SVM_SEGMENT Es;
    SVM_SEGMENT Cs;
    SVM_SEGMENT Ss;
    SVM_SEGMENT Ds;
    SVM_SEGMENT Fs;
    SVM_SEGMENT Gs;
    SVM_SEGMENT Gdtr;
    SVM_SEGMENT Ldtr;
    SVM_SEGMENT Idtr;
    SVM_SEGMENT Tr;
    UINT8 Reserved1[43];
    UINT8 Cpl;
    UINT8 Reserved2[4];
    UINT64 Efer;
    UINT8 Reserved3[112];
    UINT64 Cr4;
    UINT64 Cr3;
    UINT64 Cr0;
    UINT64 Dr7;
    UINT64 Dr6;
    UINT64 Rflags;
    UINT64 Rip;
    UINT8 Reserved4[88];
    UINT64 Rsp;
    UINT8 Reserved5[24];
    UINT64 Rax;
    UINT64 Star;
    UINT64 LStar;
    UINT64 CStar;
    UINT64 SfMask;
    UINT64 KernelGsBase;
    UINT64 SysenterCs;
    UINT64 SysenterEsp;
    UINT64 SysenterEip;
    UINT64 Cr2;
    UINT8 Reserved6[32];
    UINT64 GPat;
    UINT64 DbgCtl;
    UINT64 BrFrom;
    UINT64 BrTo;
    UINT64 LastExcpFrom;
    UINT64 LastExcpTo;
} VMCB_STATE_SAVE_AREA, *PVMCB_STATE_SAVE_AREA;

// VMCB Control Area
typedef struct _VMCB_CONTROL_AREA {
    UINT32 InterceptCrRead;        // +0x000
    UINT32 InterceptCrWrite;       // +0x004
    UINT32 InterceptDrRead;        // +0x008
    UINT32 InterceptDrWrite;       // +0x00C
    UINT32 InterceptException;     // +0x010
    UINT32 InterceptMisc1;         // +0x014
    UINT32 InterceptMisc2;         // +0x018
    UINT32 InterceptMisc3;         // +0x01C
    UINT8 Reserved1[36];           // +0x020
    UINT16 PauseFilterThreshold;  // +0x044
    UINT16 PauseFilterCount;       // +0x046
    UINT64 IopmBasePa;             // +0x048
    UINT64 MsrpmBasePa;            // +0x050
    UINT64 TscOffset;              // +0x058
    UINT32 GuestAsid;              // +0x060
    UINT32 TlbControl;             // +0x064
    UINT64 VIntr;                  // +0x068
    UINT64 InterruptShadow;        // +0x070
    UINT64 ExitCode;               // +0x078
    UINT64 ExitInfo1;              // +0x080
    UINT64 ExitInfo2;              // +0x088
    UINT64 ExitIntInfo;            // +0x090
    UINT64 NpEnable;               // +0x098
    UINT64 AvicApicBar;            // +0x0A0
    UINT64 GuestPaOfGhcb;          // +0x0A8
    UINT64 EventInj;               // +0x0B0
    UINT64 NCr3;                   // +0x0B8
    UINT64 LbrVirtualizationEnable;// +0x0C0
    UINT64 VmcbClean;              // +0x0C8
    UINT64 NRip;                   // +0x0D0
    UINT8 NumOfBytesFetched;       // +0x0D8
    UINT8 GuestInstructionBytes[15];// +0x0D9
    UINT8 Reserved2[800];          // Padding to 1024 bytes
} VMCB_CONTROL_AREA, *PVMCB_CONTROL_AREA;

// Complete VMCB (4KB)
typedef struct _VMCB {
    VMCB_CONTROL_AREA ControlArea;
    VMCB_STATE_SAVE_AREA StateSaveArea;
    UINT8 Reserved[2048];  // Padding to 4KB
} VMCB, *PVMCB;

// SVM per-CPU data structure
typedef struct _SVM_CPU {
    UINT64 VmcbPhysical;
    PVMCB VmcbVirtual;
    
    UINT64 HostSavePhysical;
    PVOID HostSaveVirtual;
    
    UINT64 MsrpmPhysical;
    PVOID MsrpmVirtual;
    
    UINT64 IopmPhysical;
    PVOID IopmVirtual;
    
    UINT64 OriginalEfer;
    
    BOOLEAN IsSvmEnabled;
    UINT32 ProcessorNumber;
    UINT32 Asid;
    
} SVM_CPU, *PSVM_CPU;

/**
 * Initialize SVM on current CPU
 * @param SvmCpu: Per-CPU SVM data structure
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS SvmInitializeCpu(PSVM_CPU SvmCpu);

/**
 * Enable SVM operation on current CPU
 * @param SvmCpu: Per-CPU SVM data structure
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS SvmEnableSvmOperation(PSVM_CPU SvmCpu);

/**
 * Setup VMCB for current CPU
 * @param SvmCpu: Per-CPU SVM data structure
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS SvmSetupVmcb(PSVM_CPU SvmCpu);

/**
 * Launch VM on current CPU
 * @param SvmCpu: Per-CPU SVM data structure
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS SvmLaunchVm(PSVM_CPU SvmCpu);

/**
 * Teardown SVM on current CPU
 * @param SvmCpu: Per-CPU SVM data structure
 */
VOID SvmTeardownCpu(PSVM_CPU SvmCpu);

/**
 * VM Exit handler (called from assembly stub)
 * @param SvmCpu: Per-CPU data
 * @return TRUE to continue VM, FALSE to exit SVM
 */
BOOLEAN SvmHandleVmExit(PSVM_CPU SvmCpu);

/**
 * Setup intercepts in VMCB
 */
VOID SvmSetupIntercepts(PSVM_CPU SvmCpu);

/**
 * Setup MSR permission map
 */
VOID SvmSetupMsrpm(PSVM_CPU SvmCpu);

/**
 * Setup I/O permission map
 */
VOID SvmSetupIopm(PSVM_CPU SvmCpu);

#endif // SVM_AMD_H

