/*
 * VM Exit Handlers Header
 * Handles various VM exit reasons and dispatches to appropriate spoofing modules
 */

#ifndef VMEXIT_HANDLERS_H
#define VMEXIT_HANDLERS_H

#include <ntddk.h>
#include "vmx_intel.h"

/**
 * Main VM exit dispatcher
 * Called from VMX exit handler
 * @param GuestContext: Guest register state
 * @return TRUE to continue VM, FALSE to exit VMX
 */
BOOLEAN HandleVmExit(PGUEST_CONTEXT GuestContext);

/**
 * Handle CPUID instruction
 * @param GuestContext: Guest register state
 */
VOID HandleCpuidExit(PGUEST_CONTEXT GuestContext);

/**
 * Handle MSR read (RDMSR)
 * @param GuestContext: Guest register state
 */
VOID HandleMsrRead(PGUEST_CONTEXT GuestContext);

/**
 * Handle MSR write (WRMSR)
 * @param GuestContext: Guest register state
 */
VOID HandleMsrWrite(PGUEST_CONTEXT GuestContext);

/**
 * Handle I/O instruction (IN/OUT)
 * @param GuestContext: Guest register state
 */
VOID HandleIoInstruction(PGUEST_CONTEXT GuestContext);

/**
 * Handle control register access
 * @param GuestContext: Guest register state
 */
VOID HandleCrAccess(PGUEST_CONTEXT GuestContext);

/**
 * Handle RDTSC/RDTSCP instruction
 * @param GuestContext: Guest register state
 */
VOID HandleRdtsc(PGUEST_CONTEXT GuestContext);

/**
 * Handle VMCALL instruction
 * @param GuestContext: Guest register state
 */
VOID HandleVmCall(PGUEST_CONTEXT GuestContext);

/**
 * Handle exception/NMI
 * @param GuestContext: Guest register state
 */
VOID HandleException(PGUEST_CONTEXT GuestContext);

/**
 * Advance guest RIP past current instruction
 */
VOID VmExitAdvanceRip(VOID);

/**
 * Inject exception into guest
 * @param Vector: Exception vector
 * @param ErrorCode: Error code (if applicable)
 * @param HasErrorCode: TRUE if exception has error code
 */
VOID VmExitInjectException(UINT8 Vector, UINT32 ErrorCode, BOOLEAN HasErrorCode);

#endif // VMEXIT_HANDLERS_H

