/*
 * Unified Hypervisor Interface Implementation
 */

#include "hypervisor.h"
#include "vmx_intel.h"
#include "svm_amd.h"
#include "../common/utils.h"
#include "../common/config.h"
#include "../spoofing/disk_spoof.h"
#include "../evasion/rdtsc_evasion.h"

// CPU vendor type
static UINT8 g_CpuVendor = CPU_VENDOR_UNKNOWN;

// Per-CPU hypervisor data (union for Intel or AMD)
typedef union _HV_CPU_DATA {
    PVMX_CPU VmxCpu;
    PSVM_CPU SvmCpu;
    PVOID Generic;
} HV_CPU_DATA, *PHV_CPU_DATA;

static HV_CPU_DATA* g_HvCpuData = NULL;
static UINT32 g_ProcessorCount = 0;
static BOOLEAN g_HypervisorRunning = FALSE;

// DPC routine for per-CPU initialization
static VOID HypervisorInitDpc(
    _In_ struct _KDPC* Dpc,
    _In_opt_ PVOID DeferredContext,
    _In_opt_ PVOID SystemArgument1,
    _In_opt_ PVOID SystemArgument2
);

// DPC routine for per-CPU start
static VOID HypervisorStartDpc(
    _In_ struct _KDPC* Dpc,
    _In_opt_ PVOID DeferredContext,
    _In_opt_ PVOID SystemArgument1,
    _In_opt_ PVOID SystemArgument2
);

// DPC routine for per-CPU stop
static VOID HypervisorStopDpc(
    _In_ struct _KDPC* Dpc,
    _In_opt_ PVOID DeferredContext,
    _In_opt_ PVOID SystemArgument1,
    _In_opt_ PVOID SystemArgument2
);

NTSTATUS HypervisorInitialize(VOID) {
    NTSTATUS status;
    UINT32 i;
    
    HvLog(LOG_LEVEL_INFO, "Initializing hypervisor...\n");
    
    // Detect CPU vendor
    g_CpuVendor = HvDetectCpuVendor();
    if (g_CpuVendor == CPU_VENDOR_INTEL) {
        HvLog(LOG_LEVEL_INFO, "Intel CPU detected - using VT-x\n");
    }
    else if (g_CpuVendor == CPU_VENDOR_AMD) {
        HvLog(LOG_LEVEL_INFO, "AMD CPU detected - using AMD-V (SVM)\n");
    }
    else {
        HvLog(LOG_LEVEL_ERROR, "Unknown CPU vendor\n");
        return STATUS_NOT_SUPPORTED;
    }
    
    // Check virtualization support
    if (!HvIsVirtualizationSupported()) {
        HvLog(LOG_LEVEL_ERROR, "Virtualization not supported by CPU\n");
        return STATUS_NOT_SUPPORTED;
    }
    
    if (!HvIsVirtualizationEnabled()) {
        HvLog(LOG_LEVEL_ERROR, "Virtualization not enabled in BIOS\n");
        return STATUS_HV_ACCESS_DENIED;
    }
    
    // Get processor count
    g_ProcessorCount = KeQueryActiveProcessorCount(NULL);
    HvLog(LOG_LEVEL_INFO, "Processor count: %d\n", g_ProcessorCount);
    
    // Allocate per-CPU data structures
    g_HvCpuData = (HV_CPU_DATA*)HvAllocateMemory(g_ProcessorCount * sizeof(HV_CPU_DATA));
    if (!g_HvCpuData) {
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    
    // Allocate vendor-specific structures
    for (i = 0; i < g_ProcessorCount; i++) {
        if (g_CpuVendor == CPU_VENDOR_INTEL) {
            g_HvCpuData[i].VmxCpu = (PVMX_CPU)HvAllocateMemory(sizeof(VMX_CPU));
            if (!g_HvCpuData[i].VmxCpu) {
                HypervisorCleanup();
                return STATUS_INSUFFICIENT_RESOURCES;
            }
        }
        else if (g_CpuVendor == CPU_VENDOR_AMD) {
            g_HvCpuData[i].SvmCpu = (PSVM_CPU)HvAllocateMemory(sizeof(SVM_CPU));
            if (!g_HvCpuData[i].SvmCpu) {
                HypervisorCleanup();
                return STATUS_INSUFFICIENT_RESOURCES;
            }
        }
    }
    
    // Initialize on each CPU
    for (i = 0; i < g_ProcessorCount; i++) {
        KeSetSystemAffinityThread((KAFFINITY)(1ULL << i));
        
        if (g_CpuVendor == CPU_VENDOR_INTEL) {
            status = VmxInitializeCpu(g_HvCpuData[i].VmxCpu);
        }
        else if (g_CpuVendor == CPU_VENDOR_AMD) {
            status = SvmInitializeCpu(g_HvCpuData[i].SvmCpu);
        }
        else {
            status = STATUS_NOT_SUPPORTED;
        }
        
        if (!NT_SUCCESS(status)) {
            HvLog(LOG_LEVEL_ERROR, "Failed to initialize CPU %d: 0x%08X\n", i, status);
            KeRevertToUserAffinityThread();
            HypervisorCleanup();
            return status;
        }
    }
    
    KeRevertToUserAffinityThread();
    
    // Initialize modules
    status = ConfigInitialize();
    if (!NT_SUCCESS(status)) {
        HvLog(LOG_LEVEL_ERROR, "Failed to initialize config\n");
        HypervisorCleanup();
        return status;
    }
    
    status = DiskSpoofInitialize();
    if (!NT_SUCCESS(status)) {
        HvLog(LOG_LEVEL_ERROR, "Failed to initialize disk spoofing\n");
        HypervisorCleanup();
        return status;
    }
    
    status = RdtscEvasionInitialize();
    if (!NT_SUCCESS(status)) {
        HvLog(LOG_LEVEL_ERROR, "Failed to initialize RDTSC evasion\n");
        HypervisorCleanup();
        return status;
    }
    
    HvLog(LOG_LEVEL_INFO, "Hypervisor initialized successfully\n");
    
    return STATUS_SUCCESS;
}

NTSTATUS HypervisorStart(VOID) {
    NTSTATUS status;
    UINT32 i;
    
    if (g_HypervisorRunning) {
        return STATUS_ALREADY_REGISTERED;
    }
    
    HvLog(LOG_LEVEL_INFO, "Starting hypervisor on all CPUs...\n");
    
    // Start on each CPU
    for (i = 0; i < g_ProcessorCount; i++) {
        KeSetSystemAffinityThread((KAFFINITY)(1ULL << i));
        
        if (g_CpuVendor == CPU_VENDOR_INTEL) {
            // Enable VMX operation
            status = VmxEnableVmxOperation(g_HvCpuData[i].VmxCpu);
            if (!NT_SUCCESS(status)) {
                HvLog(LOG_LEVEL_ERROR, "Failed to enable VMX on CPU %d\n", i);
                KeRevertToUserAffinityThread();
                HypervisorStop();
                return status;
            }
            
            // Setup VMCS
            status = VmxSetupVmcs(g_HvCpuData[i].VmxCpu);
            if (!NT_SUCCESS(status)) {
                HvLog(LOG_LEVEL_ERROR, "Failed to setup VMCS on CPU %d\n", i);
                KeRevertToUserAffinityThread();
                HypervisorStop();
                return status;
            }
        }
        else if (g_CpuVendor == CPU_VENDOR_AMD) {
            // Enable SVM operation
            status = SvmEnableSvmOperation(g_HvCpuData[i].SvmCpu);
            if (!NT_SUCCESS(status)) {
                HvLog(LOG_LEVEL_ERROR, "Failed to enable SVM on CPU %d\n", i);
                KeRevertToUserAffinityThread();
                HypervisorStop();
                return status;
            }
            
            // Setup VMCB
            status = SvmSetupVmcb(g_HvCpuData[i].SvmCpu);
            if (!NT_SUCCESS(status)) {
                HvLog(LOG_LEVEL_ERROR, "Failed to setup VMCB on CPU %d\n", i);
                KeRevertToUserAffinityThread();
                HypervisorStop();
                return status;
            }
        }
        
        HvLog(LOG_LEVEL_INFO, "CPU %d: Hypervisor ready (launch requires assembly stubs)\n", i);
    }
    
    KeRevertToUserAffinityThread();
    
    g_HypervisorRunning = TRUE;
    HvLog(LOG_LEVEL_INFO, "Hypervisor started on all CPUs\n");
    
    return STATUS_SUCCESS;
}

VOID HypervisorStop(VOID) {
    UINT32 i;
    
    if (!g_HypervisorRunning) {
        return;
    }
    
    HvLog(LOG_LEVEL_INFO, "Stopping hypervisor on all CPUs...\n");
    
    // Stop on each CPU
    for (i = 0; i < g_ProcessorCount; i++) {
        if (g_HvCpuData && g_HvCpuData[i].Generic) {
            KeSetSystemAffinityThread((KAFFINITY)(1ULL << i));
            
            if (g_CpuVendor == CPU_VENDOR_INTEL) {
                VmxTeardownCpu(g_HvCpuData[i].VmxCpu);
            }
            else if (g_CpuVendor == CPU_VENDOR_AMD) {
                SvmTeardownCpu(g_HvCpuData[i].SvmCpu);
            }
        }
    }
    
    KeRevertToUserAffinityThread();
    
    g_HypervisorRunning = FALSE;
    HvLog(LOG_LEVEL_INFO, "Hypervisor stopped\n");
}

VOID HypervisorCleanup(VOID) {
    UINT32 i;
    
    HvLog(LOG_LEVEL_INFO, "Cleaning up hypervisor...\n");
    
    // Stop if running
    if (g_HypervisorRunning) {
        HypervisorStop();
    }
    
    // Cleanup modules
    DiskSpoofCleanup();
    
    // Free per-CPU data
    if (g_HvCpuData) {
        for (i = 0; i < g_ProcessorCount; i++) {
            if (g_HvCpuData[i].Generic) {
                HvFreeMemory(g_HvCpuData[i].Generic);
            }
        }
        HvFreeMemory(g_HvCpuData);
        g_HvCpuData = NULL;
    }
    
    g_ProcessorCount = 0;
    g_CpuVendor = CPU_VENDOR_UNKNOWN;
    
    HvLog(LOG_LEVEL_INFO, "Hypervisor cleanup complete\n");
}

BOOLEAN HypervisorIsRunning(VOID) {
    return g_HypervisorRunning;
}

VOID HypervisorGetStatus(CHAR* Buffer, SIZE_T BufferSize) {
    const char* vendorName = "Unknown";
    const char* vmTech = "None";
    
    if (!Buffer || BufferSize == 0) {
        return;
    }
    
    if (g_CpuVendor == CPU_VENDOR_INTEL) {
        vendorName = "Intel";
        vmTech = "VT-x (VMX)";
    }
    else if (g_CpuVendor == CPU_VENDOR_AMD) {
        vendorName = "AMD";
        vmTech = "AMD-V (SVM)";
    }
    
    RtlStringCbPrintfA(Buffer, BufferSize,
        "Hypervisor Status:\n"
        "  Running: %s\n"
        "  CPUs: %d\n"
        "  Vendor: %s\n"
        "  Technology: %s\n"
        "  Spoofing: %s\n",
        g_HypervisorRunning ? "Yes" : "No",
        g_ProcessorCount,
        vendorName,
        vmTech,
        ConfigIsEnabled() ? "Enabled" : "Disabled"
    );
}

