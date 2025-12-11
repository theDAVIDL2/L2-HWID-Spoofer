/*
 * Disk Spoofing Module Implementation
 */

#include "disk_spoof.h"
#include "../common/utils.h"
#include "../common/config.h"

// State tracking for ATA I/O
typedef struct _ATA_STATE {
    UINT8 LastCommand;
    UINT8 DriveSelect;
    BOOLEAN IdentifyPending;
    PVOID IdentifyBuffer;
} ATA_STATE, *PATA_STATE;

static ATA_STATE g_AtaState = { 0 };

NTSTATUS DiskSpoofInitialize(VOID) {
    HvZeroMemory(&g_AtaState, sizeof(g_AtaState));
    
    // Allocate buffer for IDENTIFY response
    g_AtaState.IdentifyBuffer = HvAllocateMemory(512);
    if (!g_AtaState.IdentifyBuffer) {
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    
    HvLog(LOG_LEVEL_INFO, "Disk spoofing initialized\n");
    return STATUS_SUCCESS;
}

VOID DiskSpoofCleanup(VOID) {
    if (g_AtaState.IdentifyBuffer) {
        HvFreeMemory(g_AtaState.IdentifyBuffer);
        g_AtaState.IdentifyBuffer = NULL;
    }
}

VOID DiskSpoofHandleIo(UINT16 Port, UINT8 Size, BOOLEAN IsInput, PGUEST_CONTEXT GuestContext) {
    UINT32 value = 0;
    
    if (IsInput) {
        // IN instruction - read from port
        switch (Size) {
            case 1:
                value = __inbyte(Port);
                break;
            case 2:
                value = __inword(Port);
                break;
            case 4:
                value = __indword(Port);
                break;
        }
        
        // Check if reading data after IDENTIFY command
        if (Port == ATA_PRIMARY_DATA && g_AtaState.IdentifyPending) {
            // Intercept IDENTIFY data reads
            // This is simplified - real implementation would need buffering
            HvLog(LOG_LEVEL_DEBUG, "Intercepted IDENTIFY data read\n");
            
            // For demonstration, we'd read from our spoofed buffer
            // (Full implementation would track byte offset)
        }
        
        GuestContext->Rax = (GuestContext->Rax & ~((1ULL << (Size * 8)) - 1)) | value;
    }
    else {
        // OUT instruction - write to port
        value = (UINT32)GuestContext->Rax;
        
        // Track commands
        if (Port == ATA_PRIMARY_COMMAND) {
            g_AtaState.LastCommand = (UINT8)value;
            
            if (value == ATA_CMD_IDENTIFY_DEVICE) {
                HvLog(LOG_LEVEL_INFO, "ATA IDENTIFY DEVICE command detected\n");
                g_AtaState.IdentifyPending = TRUE;
                
                // Read real IDENTIFY data first
                // Then modify it with our spoofed values
                // (Simplified - real implementation would be more complex)
            }
        }
        else if (Port == ATA_PRIMARY_DRIVE_SELECT) {
            g_AtaState.DriveSelect = (UINT8)value;
        }
        
        // Write to port
        switch (Size) {
            case 1:
                __outbyte(Port, (UINT8)value);
                break;
            case 2:
                __outword(Port, (UINT16)value);
                break;
            case 4:
                __outdword(Port, value);
                break;
        }
    }
}

VOID DiskSpoofModifyIdentify(PVOID Buffer) {
    UINT16* identifyData = (UINT16*)Buffer;
    UINT32 i;
    
    if (!Buffer) {
        return;
    }
    
    HvLog(LOG_LEVEL_INFO, "Modifying IDENTIFY DEVICE response\n");
    
    // Spoof serial number (words 10-19, 20 bytes)
    if (g_SpoofConfig.FakeDiskSerial[0] != '\0') {
        // ATA strings are word-swapped
        CHAR tempSerial[20];
        HvZeroMemory(tempSerial, 20);
        RtlCopyMemory(tempSerial, g_SpoofConfig.FakeDiskSerial, 
                     min(strlen(g_SpoofConfig.FakeDiskSerial), 20));
        
        // Word-swap the string
        for (i = 0; i < 20; i += 2) {
            identifyData[10 + i/2] = (tempSerial[i+1] << 8) | tempSerial[i];
        }
        
        HvLog(LOG_LEVEL_INFO, "Spoofed disk serial: %s\n", g_SpoofConfig.FakeDiskSerial);
    }
    
    // Spoof model number (words 27-46, 40 bytes)
    if (g_SpoofConfig.FakeDiskModel[0] != '\0') {
        CHAR tempModel[40];
        HvZeroMemory(tempModel, 40);
        RtlCopyMemory(tempModel, g_SpoofConfig.FakeDiskModel,
                     min(strlen(g_SpoofConfig.FakeDiskModel), 40));
        
        // Word-swap the string
        for (i = 0; i < 40; i += 2) {
            identifyData[27 + i/2] = (tempModel[i+1] << 8) | tempModel[i];
        }
        
        HvLog(LOG_LEVEL_INFO, "Spoofed disk model: %s\n", g_SpoofConfig.FakeDiskModel);
    }
    
    // Spoof firmware revision (words 23-26, 8 bytes)
    if (g_SpoofConfig.FakeDiskFirmware[0] != '\0') {
        CHAR tempFirmware[8];
        HvZeroMemory(tempFirmware, 8);
        RtlCopyMemory(tempFirmware, g_SpoofConfig.FakeDiskFirmware,
                     min(strlen(g_SpoofConfig.FakeDiskFirmware), 8));
        
        // Word-swap the string
        for (i = 0; i < 8; i += 2) {
            identifyData[23 + i/2] = (tempFirmware[i+1] << 8) | tempFirmware[i];
        }
        
        HvLog(LOG_LEVEL_INFO, "Spoofed disk firmware: %s\n", g_SpoofConfig.FakeDiskFirmware);
    }
}

