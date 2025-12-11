/*
 * Disk Spoofing Module Header
 * Intercepts disk I/O to spoof serial numbers and model information
 */

#ifndef DISK_SPOOF_H
#define DISK_SPOOF_H

#include <ntddk.h>
#include "../hypervisor/vmx_intel.h"

// ATA Commands
#define ATA_CMD_IDENTIFY_DEVICE     0xEC
#define ATA_CMD_IDENTIFY_PACKET     0xA1

// ATA I/O Ports
#define ATA_PRIMARY_DATA            0x1F0
#define ATA_PRIMARY_ERROR           0x1F1
#define ATA_PRIMARY_SECTOR_COUNT    0x1F2
#define ATA_PRIMARY_LBA_LOW         0x1F3
#define ATA_PRIMARY_LBA_MID         0x1F4
#define ATA_PRIMARY_LBA_HIGH        0x1F5
#define ATA_PRIMARY_DRIVE_SELECT    0x1F6
#define ATA_PRIMARY_COMMAND         0x1F7
#define ATA_PRIMARY_STATUS          0x1F7

// IDENTIFY DEVICE structure offsets
#define ATA_IDENTIFY_SERIAL_OFFSET  20   // Words 10-19 (20 bytes)
#define ATA_IDENTIFY_MODEL_OFFSET   54   // Words 27-46 (40 bytes)
#define ATA_IDENTIFY_FIRMWARE_OFFSET 46  // Words 23-26 (8 bytes)

/**
 * Handle I/O instruction for disk spoofing
 * @param Port: I/O port number
 * @param Size: Access size (1, 2, or 4 bytes)
 * @param IsInput: TRUE for IN, FALSE for OUT
 * @param GuestContext: Guest register state
 */
VOID DiskSpoofHandleIo(UINT16 Port, UINT8 Size, BOOLEAN IsInput, PGUEST_CONTEXT GuestContext);

/**
 * Initialize disk spoofing module
 */
NTSTATUS DiskSpoofInitialize(VOID);

/**
 * Cleanup disk spoofing module
 */
VOID DiskSpoofCleanup(VOID);

/**
 * Modify IDENTIFY DEVICE response
 * @param Buffer: IDENTIFY buffer (512 bytes)
 */
VOID DiskSpoofModifyIdentify(PVOID Buffer);

#endif // DISK_SPOOF_H

