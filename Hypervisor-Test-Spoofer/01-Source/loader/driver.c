/*
 * Kernel Driver Entry Point
 * Main driver for hypervisor spoofer
 */

#include <ntddk.h>
#include "../hypervisor/hypervisor.h"
#include "../common/utils.h"
#include "../common/config.h"

// Device and symbolic link names
#define DEVICE_NAME     L"\\Device\\HypervisorSpoofer"
#define SYMLINK_NAME    L"\\DosDevices\\HypervisorSpoofer"

// IOCTL codes
#define IOCTL_HV_START          CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_HV_STOP           CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_HV_GET_STATUS     CTL_CODE(FILE_DEVICE_UNKNOWN, 0x802, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_HV_SET_CONFIG     CTL_CODE(FILE_DEVICE_UNKNOWN, 0x803, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_HV_GET_CONFIG     CTL_CODE(FILE_DEVICE_UNKNOWN, 0x804, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_HV_ENABLE_SPOOF   CTL_CODE(FILE_DEVICE_UNKNOWN, 0x805, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_HV_DISABLE_SPOOF  CTL_CODE(FILE_DEVICE_UNKNOWN, 0x806, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_HV_LOAD_PRESET    CTL_CODE(FILE_DEVICE_UNKNOWN, 0x807, METHOD_BUFFERED, FILE_ANY_ACCESS)

// Global device object
static PDEVICE_OBJECT g_DeviceObject = NULL;

// Forward declarations
NTSTATUS DriverCreateClose(_In_ PDEVICE_OBJECT DeviceObject, _In_ PIRP Irp);
NTSTATUS DriverIoControl(_In_ PDEVICE_OBJECT DeviceObject, _In_ PIRP Irp);
VOID DriverUnload(_In_ PDRIVER_OBJECT DriverObject);

/**
 * Driver Entry Point
 */
NTSTATUS DriverEntry(
    _In_ PDRIVER_OBJECT DriverObject,
    _In_ PUNICODE_STRING RegistryPath
) {
    NTSTATUS status;
    UNICODE_STRING deviceName, symlinkName;
    
    UNREFERENCED_PARAMETER(RegistryPath);
    
    DbgPrint("[HypervisorSpoofer] Driver loading...\n");
    
    // Initialize logging
    HvInitializeLogging(LOG_LEVEL_INFO);
    
    HvLog(LOG_LEVEL_INFO, "===========================================\n");
    HvLog(LOG_LEVEL_INFO, "Hypervisor-Based HWID Spoofer Driver\n");
    HvLog(LOG_LEVEL_INFO, "Version: 1.0.0\n");
    HvLog(LOG_LEVEL_INFO, "===========================================\n");
    
    // Create device object
    RtlInitUnicodeString(&deviceName, DEVICE_NAME);
    
    status = IoCreateDevice(
        DriverObject,
        0,
        &deviceName,
        FILE_DEVICE_UNKNOWN,
        FILE_DEVICE_SECURE_OPEN,
        FALSE,
        &g_DeviceObject
    );
    
    if (!NT_SUCCESS(status)) {
        HvLog(LOG_LEVEL_ERROR, "Failed to create device: 0x%08X\n", status);
        return status;
    }
    
    // Create symbolic link
    RtlInitUnicodeString(&symlinkName, SYMLINK_NAME);
    
    status = IoCreateSymbolicLink(&symlinkName, &deviceName);
    if (!NT_SUCCESS(status)) {
        HvLog(LOG_LEVEL_ERROR, "Failed to create symbolic link: 0x%08X\n", status);
        IoDeleteDevice(g_DeviceObject);
        return status;
    }
    
    // Set dispatch routines
    DriverObject->MajorFunction[IRP_MJ_CREATE] = DriverCreateClose;
    DriverObject->MajorFunction[IRP_MJ_CLOSE] = DriverCreateClose;
    DriverObject->MajorFunction[IRP_MJ_DEVICE_CONTROL] = DriverIoControl;
    DriverObject->DriverUnload = DriverUnload;
    
    // Initialize hypervisor
    status = HypervisorInitialize();
    if (!NT_SUCCESS(status)) {
        HvLog(LOG_LEVEL_ERROR, "Failed to initialize hypervisor: 0x%08X\n", status);
        IoDeleteSymbolicLink(&symlinkName);
        IoDeleteDevice(g_DeviceObject);
        return status;
    }
    
    HvLog(LOG_LEVEL_INFO, "Driver loaded successfully\n");
    HvLog(LOG_LEVEL_INFO, "Device: %wZ\n", &deviceName);
    HvLog(LOG_LEVEL_INFO, "Symlink: %wZ\n", &symlinkName);
    
    return STATUS_SUCCESS;
}

/**
 * Driver Unload
 */
VOID DriverUnload(_In_ PDRIVER_OBJECT DriverObject) {
    UNICODE_STRING symlinkName;
    
    UNREFERENCED_PARAMETER(DriverObject);
    
    HvLog(LOG_LEVEL_INFO, "Driver unloading...\n");
    
    // Cleanup hypervisor
    HypervisorCleanup();
    
    // Delete symbolic link
    RtlInitUnicodeString(&symlinkName, SYMLINK_NAME);
    IoDeleteSymbolicLink(&symlinkName);
    
    // Delete device object
    if (g_DeviceObject) {
        IoDeleteDevice(g_DeviceObject);
    }
    
    HvLog(LOG_LEVEL_INFO, "Driver unloaded\n");
}

/**
 * Create/Close handler
 */
NTSTATUS DriverCreateClose(_In_ PDEVICE_OBJECT DeviceObject, _In_ PIRP Irp) {
    UNREFERENCED_PARAMETER(DeviceObject);
    
    Irp->IoStatus.Status = STATUS_SUCCESS;
    Irp->IoStatus.Information = 0;
    IoCompleteRequest(Irp, IO_NO_INCREMENT);
    
    return STATUS_SUCCESS;
}

/**
 * IOCTL handler
 */
NTSTATUS DriverIoControl(_In_ PDEVICE_OBJECT DeviceObject, _In_ PIRP Irp) {
    NTSTATUS status = STATUS_SUCCESS;
    PIO_STACK_LOCATION stack;
    ULONG ioControlCode;
    PVOID inputBuffer, outputBuffer;
    ULONG inputLength, outputLength;
    ULONG bytesReturned = 0;
    
    UNREFERENCED_PARAMETER(DeviceObject);
    
    stack = IoGetCurrentIrpStackLocation(Irp);
    ioControlCode = stack->Parameters.DeviceIoControl.IoControlCode;
    
    inputBuffer = Irp->AssociatedIrp.SystemBuffer;
    outputBuffer = Irp->AssociatedIrp.SystemBuffer;
    inputLength = stack->Parameters.DeviceIoControl.InputBufferLength;
    outputLength = stack->Parameters.DeviceIoControl.OutputBufferLength;
    
    HvLog(LOG_LEVEL_DEBUG, "IOCTL received: 0x%08X\n", ioControlCode);
    
    switch (ioControlCode) {
        case IOCTL_HV_START:
            HvLog(LOG_LEVEL_INFO, "IOCTL: Start hypervisor\n");
            status = HypervisorStart();
            break;
            
        case IOCTL_HV_STOP:
            HvLog(LOG_LEVEL_INFO, "IOCTL: Stop hypervisor\n");
            HypervisorStop();
            break;
            
        case IOCTL_HV_GET_STATUS:
            HvLog(LOG_LEVEL_DEBUG, "IOCTL: Get status\n");
            if (outputLength >= 256) {
                HypervisorGetStatus((CHAR*)outputBuffer, outputLength);
                bytesReturned = (ULONG)strlen((CHAR*)outputBuffer) + 1;
            }
            else {
                status = STATUS_BUFFER_TOO_SMALL;
            }
            break;
            
        case IOCTL_HV_SET_CONFIG:
            HvLog(LOG_LEVEL_INFO, "IOCTL: Set configuration\n");
            if (inputLength >= sizeof(SPOOF_CONFIG)) {
                status = ConfigSet((PSPOOF_CONFIG)inputBuffer);
            }
            else {
                status = STATUS_INVALID_PARAMETER;
            }
            break;
            
        case IOCTL_HV_GET_CONFIG:
            HvLog(LOG_LEVEL_DEBUG, "IOCTL: Get configuration\n");
            if (outputLength >= sizeof(SPOOF_CONFIG)) {
                ConfigGet((PSPOOF_CONFIG)outputBuffer);
                bytesReturned = sizeof(SPOOF_CONFIG);
            }
            else {
                status = STATUS_BUFFER_TOO_SMALL;
            }
            break;
            
        case IOCTL_HV_ENABLE_SPOOF:
            HvLog(LOG_LEVEL_INFO, "IOCTL: Enable spoofing\n");
            ConfigSetEnabled(TRUE);
            break;
            
        case IOCTL_HV_DISABLE_SPOOF:
            HvLog(LOG_LEVEL_INFO, "IOCTL: Disable spoofing\n");
            ConfigSetEnabled(FALSE);
            break;
            
        case IOCTL_HV_LOAD_PRESET:
            HvLog(LOG_LEVEL_INFO, "IOCTL: Load preset\n");
            if (inputLength >= sizeof(UINT32)) {
                UINT32 preset = *(UINT32*)inputBuffer;
                status = ConfigLoadPreset((HWID_PRESET)preset);
            }
            else {
                status = STATUS_INVALID_PARAMETER;
            }
            break;
            
        default:
            HvLog(LOG_LEVEL_WARNING, "Unknown IOCTL: 0x%08X\n", ioControlCode);
            status = STATUS_INVALID_DEVICE_REQUEST;
            break;
    }
    
    Irp->IoStatus.Status = status;
    Irp->IoStatus.Information = bytesReturned;
    IoCompleteRequest(Irp, IO_NO_INCREMENT);
    
    return status;
}

