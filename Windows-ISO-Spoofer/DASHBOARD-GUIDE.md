# 🎛️ Dashboard & Compilation Guide

## 🎉 **NEW: Complete GUI Dashboard!**

I've created a **complete Windows Forms dashboard** that gives you one-click control over your spoofer!

---

## 🚀 Quick Start

### Launch the Dashboard:

**Method 1: Double-Click (Easiest)**
```
Right-click: LAUNCH-DASHBOARD.bat
Select: "Run as Administrator"
```

**Method 2: PowerShell**
```powershell
cd "Windows-ISO-Spoofer"
.\SPOOFER-DASHBOARD.ps1
```

---

## 🎛️ Dashboard Features

### Main Window:

```
╔═══════════════════════════════════════════════════════╗
║         🔐 EFI Spoofer Management Dashboard           ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  📊 Current Status                                    ║
║  ├─ Spoofer Status: ✅ Installed / ❌ Not Installed  ║
║  ├─ Secure Boot: ✅ Enabled / ⚠️ Disabled            ║
║  ├─ Certificate: ✅ Generated / ❌ Not Generated     ║
║  └─ SMBIOS: Current values                           ║
║                                                       ║
║  ⚡ Actions                                           ║
║  ├─ [✅ Install Spoofer to Live System]             ║
║  ├─ [🗑️ Remove Spoofer from Live System]            ║
║  └─ [📀 Build Distributable ISO]                     ║
║                                                       ║
║  🛠️ Tools                                             ║
║  ├─ [🔑 Generate Signing Certificate]                ║
║  ├─ [✍️ Sign Spoofer with Certificate]               ║
║  ├─ [⚙️ Edit Config] [📄 View Logs]                  ║
║                                                       ║
║  📜 Output                                            ║
║  └─ [Real-time log output...]                        ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

---

## ✨ Dashboard Capabilities

### One-Click Operations:

1. **Install Spoofer** ✅
   - Automatically mounts ESP
   - Backs up original bootloader
   - Copies signed spoofer
   - Installs shim bootloader
   - Configures boot chain
   - Prompts for reboot

2. **Remove Spoofer** 🗑️
   - Restores original bootloader
   - Removes all spoofer files
   - Cleans up completely
   - Prompts for reboot

3. **Build ISO** 📀
   - Creates distributable ISO
   - Includes all components
   - Ready to share

### Smart Status Monitoring:

- ✅ **Real-time status checks**
- ✅ **Color-coded indicators**
- ✅ **Automatic refresh**
- ✅ **SMBIOS value display**

### Integrated Tools:

- 🔑 **Generate Certificate** - One click
- ✍️ **Sign Spoofer** - Automatic signing
- ⚙️ **Edit Config** - Opens config.ini
- 📄 **View Logs** - Check spoofer logs

---

## 🔨 **IMPORTANT: Compiling Your Spoofer**

### The Missing Piece!

The dashboard assumes you have `spoofer.efi` compiled. Here's how to create it:

**📖 Read:** `04-EFI-Spoofer\HOW-TO-COMPILE-EFI.md`

---

## 🚀 Quick Compilation Guide

### Option 1: gnu-efi (Easiest)

```bash
# In WSL (Windows Subsystem for Linux):

# 1. Install tools
sudo apt-get install -y build-essential gnu-efi

# 2. Create spoofer.c (see HOW-TO-COMPILE-EFI.md for code)

# 3. Create Makefile (see HOW-TO-COMPILE-EFI.md)

# 4. Compile
make

# 5. Copy to Windows
cp spoofer.efi "/mnt/c/Users/davie/OneDrive/Área de Trabalho/L2 ISO project/Windows-ISO-Spoofer/04-EFI-Spoofer/"
```

### Option 2: Download Example Spoofer

**I can provide a basic example spoofer if you want to test the system first!**

---

## 📊 Complete Workflow

### Full Process (From Scratch):

```
┌─────────────────────────────────────┐
│ 1. Compile Spoofer                  │
│    └─ See HOW-TO-COMPILE-EFI.md     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 2. Launch Dashboard                 │
│    └─ Double-click LAUNCH-DASHBOARD │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 3. Generate Certificate             │
│    └─ Click "Generate Certificate"  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 4. Sign Spoofer                     │
│    └─ Click "Sign Spoofer"          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 5. Edit Configuration               │
│    └─ Click "Edit Config"           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 6. Install to Live System           │
│    └─ Click "Install Spoofer"       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 7. Reboot & Enroll MOK              │
│    └─ Follow on-screen prompts      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 8. Verify & Test                    │
│    └─ Check status in dashboard     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 9. (Optional) Build ISO             │
│    └─ For distribution              │
└─────────────────────────────────────┘
```

---

## 🎯 Dashboard Features in Detail

### Status Panel:

**Real-time monitoring of:**
- Spoofer installation status
- Secure Boot state
- Certificate generation
- Current SMBIOS values

**Auto-refresh:** Click "🔄 Refresh Status"

### Action Panel:

**One-click operations:**

1. **Install Spoofer**
   - Checks prerequisites
   - Runs installation script
   - Shows real-time progress
   - Prompts for reboot

2. **Remove Spoofer**
   - Confirms action
   - Restores original files
   - Complete cleanup
   - Safe and reversible

3. **Build ISO**
   - Creates distributable ISO
   - Includes all components
   - Ready to share

### Tools Panel:

**Quick access to:**

1. **Generate Certificate**
   - Opens certificate generator
   - Creates YOUR signing certificate
   - Stores in 07-Keys-And-Certs/

2. **Sign Spoofer**
   - Signs spoofer.efi
   - Uses YOUR certificate
   - Required before installation

3. **Edit Config**
   - Opens config.ini in notepad
   - Configure SMBIOS values
   - Easy editing

4. **View Logs**
   - Shows spoofer.log
   - Real-time debugging
   - Check what spoofer did

### Output Panel:

**Real-time logging:**
- All operations logged
- Color-coded messages
- Scrollable output
- Timestamp included

---

## 🔧 Configuration

### Edit SMBIOS Values:

**In Dashboard:**
1. Click "⚙️ Edit Config"
2. Modify values in config.ini
3. Save and close
4. Click "Install Spoofer" to apply

**config.ini format:**
```ini
[SMBIOS]
SystemManufacturer=ASUSTeK COMPUTER INC.
SystemProductName=TUF GAMING A520M-PLUS II
SystemSerialNumber=SPOOFED-SERIAL-001
SystemUUID=12345678-9ABC-DEF0-1234-567890ABCDEF
```

---

## 🐛 Troubleshooting

### "spoofer.efi not found"

**Problem:** No compiled spoofer

**Solution:**
1. Read `04-EFI-Spoofer\HOW-TO-COMPILE-EFI.md`
2. Compile using gnu-efi, EDK II, or Rust
3. Copy to `04-EFI-Spoofer\spoofer.efi`

### "Must run as Administrator"

**Problem:** Dashboard needs admin rights

**Solution:**
- Right-click LAUNCH-DASHBOARD.bat
- Select "Run as Administrator"

### Dashboard doesn't open

**Problem:** PowerShell execution policy

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\SPOOFER-DASHBOARD.ps1
```

### Status shows "Cannot Check"

**Problem:** ESP not accessible

**Solution:**
- Ensure UEFI boot mode (not Legacy)
- Run as Administrator
- Check BIOS settings

---

## ✅ Success Checklist

### Before Using Dashboard:

- [ ] Compiled spoofer.efi
- [ ] Spoofer in `04-EFI-Spoofer\` directory
- [ ] Config.ini configured
- [ ] Running Windows as Administrator

### After Installation:

- [ ] Status shows "Installed"
- [ ] Secure Boot enabled
- [ ] MOK enrolled
- [ ] SMBIOS shows spoofed values
- [ ] Can reboot successfully

---

## 📊 Files Created

| File | Purpose |
|------|---------|
| **SPOOFER-DASHBOARD.ps1** | Main GUI dashboard |
| **LAUNCH-DASHBOARD.bat** | Easy launcher (double-click) |
| **04-EFI-Spoofer/HOW-TO-COMPILE-EFI.md** | Complete compilation guide |
| **DASHBOARD-GUIDE.md** | This file |

---

## 🎓 Learning Path

### For Beginners:

```
1. Read: HOW-TO-COMPILE-EFI.md
   └─ Understand EFI compilation

2. Compile: Basic spoofer
   └─ Use gnu-efi method

3. Test: Using dashboard
   └─ Install to live system

4. Iterate: Improve spoofer
   └─ Add features, fix bugs

5. Distribute: Build ISO
   └─ Share with others
```

---

## 🚀 Next Steps

### 1. Compile Your Spoofer

```bash
# Read the guide:
# 04-EFI-Spoofer\HOW-TO-COMPILE-EFI.md

# Quick start (WSL):
sudo apt-get install -y build-essential gnu-efi
# ... (see full guide)
```

### 2. Launch Dashboard

```
Double-click: LAUNCH-DASHBOARD.bat
(as Administrator)
```

### 3. One-Click Install

```
In dashboard:
1. Click "Generate Certificate"
2. Click "Sign Spoofer"
3. Click "Install Spoofer"
4. Reboot & Enroll MOK
5. Done!
```

---

## 📝 Summary

### What You Get:

✅ **Complete GUI Dashboard**
- One-click install/remove
- Real-time status monitoring
- Integrated tools
- Live log output

✅ **Compilation Guide**
- 3 methods (gnu-efi, EDK II, Rust)
- Example source code
- Step-by-step instructions
- Makefile included

✅ **Full Automation**
- No manual ESP mounting
- Automatic backups
- Safe and reversible
- Error handling

---

## 🎉 You're Ready!

### To Start:

1. **Compile spoofer** (see HOW-TO-COMPILE-EFI.md)
2. **Launch dashboard** (LAUNCH-DASHBOARD.bat)
3. **Click buttons** (it's that easy!)

---

**Questions?**

- **Compilation:** Read `04-EFI-Spoofer\HOW-TO-COMPILE-EFI.md`
- **Dashboard:** Read this file
- **Testing:** Read `08-Testing\TEST-ON-LIVE-SYSTEM.md`
- **Signing:** Read `SIGNING-SUMMARY.md`

---

*The dashboard makes spoofer management as easy as clicking buttons!* 🖱️


