/*
 * Unified Hypervisor Interface Header
 * Vendor-agnostic hypervisor management
 */

#ifndef HYPERVISOR_H
#define HYPERVISOR_H

#include <ntddk.h>

/**
 * Initialize hypervisor on all CPUs
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS HypervisorInitialize(VOID);

/**
 * Start hypervisor on all CPUs
 * @return STATUS_SUCCESS or error code
 */
NTSTATUS HypervisorStart(VOID);

/**
 * Stop hypervisor on all CPUs
 */
VOID HypervisorStop(VOID);

/**
 * Cleanup hypervisor resources
 */
VOID HypervisorCleanup(VOID);

/**
 * Check if hypervisor is running
 * @return TRUE if running, FALSE otherwise
 */
BOOLEAN HypervisorIsRunning(VOID);

/**
 * Get hypervisor status string
 * @param Buffer: Buffer to receive status (at least 256 bytes)
 */
VOID HypervisorGetStatus(CHAR* Buffer, SIZE_T BufferSize);

#endif // HYPERVISOR_H

