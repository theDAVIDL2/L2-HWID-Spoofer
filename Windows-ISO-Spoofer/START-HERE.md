# 🚀 START HERE - Quick Start Guide

## ⚠️ STOP! Read This First

### Are you here because a guide told you to:
- "Sign with Microsoft's 2023 UEFI certificate"?
- "Obtain the Microsoft UEFI CA certificate"?
- "Use signtool with Microsoft certificates"?

### **THOSE GUIDES ARE WRONG.**

**You CANNOT use Microsoft certificates. They don't exist for public use.**

---

## ✅ What You Actually Do

### 🎛️ **NEW: GUI Dashboard Available!**

**Option 1: Use the Dashboard (Easiest) ⭐ RECOMMENDED**
```
1. Compile your spoofer (see: 04-EFI-Spoofer\HOW-TO-COMPILE-EFI.md)
2. Double-click: LAUNCH-DASHBOARD.bat (as Administrator)
3. Click buttons in the GUI to:
   - Generate certificate
   - Sign spoofer
   - Install to live system
   - Test immediately!
4. Done!
```

**📖 Read: [DASHBOARD-GUIDE.md](DASHBOARD-GUIDE.md)** for complete dashboard documentation

---

**Option 2: Manual Commands (Traditional)**
```powershell
# 1. Compile YOUR spoofer (IMPORTANT!)
# See: 04-EFI-Spoofer\HOW-TO-COMPILE-EFI.md
# Place compiled file in: 04-EFI-Spoofer\spoofer.efi

# 2. Generate YOUR certificate
cd Windows-ISO-Spoofer\07-Keys-And-Certs
.\generate-keys.ps1

# 3. Test on live system (fastest!)
cd ..\08-Testing
.\install-to-live-system.ps1

# OR build ISO for distribution
cd ..\03-Build-Scripts
.\00-BUILD-ALL.ps1

# Done!
```

---

## 📚 Documentation Index

### 🎛️ **NEW! GUI Dashboard & Compilation:**

1. **[DASHBOARD-GUIDE.md](DASHBOARD-GUIDE.md)** 🎛️ **NEW!**
   - Complete dashboard documentation
   - One-click operations
   - GUI walkthrough

2. **[HOW-TO-COMPILE-EFI.md](04-EFI-Spoofer/HOW-TO-COMPILE-EFI.md)** 🔨 **IMPORTANT!**
   - How to compile your spoofer.efi
   - 3 methods: gnu-efi, EDK II, Rust
   - Example source code
   - **Read this to create your spoofer!**

### 🔥 **Certificate & Signing:**

3. **[SIGNING-SUMMARY.md](SIGNING-SUMMARY.md)** ⭐ **ESSENTIAL**
   - Reality check on Microsoft certificates
   - What you CAN and CANNOT do
   - Complete signing workflow
   - **Read this if you're confused about certificates!**

4. **[Quick Signing Guide](01-Documentation/09-Quick-Signing-Guide.md)** ⚡
   - 30-second quick reference
   - Copy-paste commands
   - Tool comparison

5. **[Certificate Signing Reality](01-Documentation/08-Certificate-Signing-Reality.md)** 🔐
   - Deep dive on why Microsoft certificates are unavailable
   - Explains self-signed + MOK approach
   - Industry standard practices

### 📖 **Complete Guides:**

6. **[Master Guide](01-Documentation/00-MASTER-GUIDE.md)** 📖
   - Full step-by-step walkthrough
   - From setup to deployment
   - Troubleshooting

7. **[TEST-ON-LIVE-SYSTEM.md](08-Testing/TEST-ON-LIVE-SYSTEM.md)** 🧪
   - Test without ISO creation
   - Fastest testing method
   - Fully reversible

8. **[README.md](README.md)** 📋
   - Project overview
   - Architecture explanation
   - FAQ

---

## 🎯 The Truth About Certificates

### ❌ **What You CANNOT Do:**
```
Use Microsoft certificates
├─ They are NOT available
├─ They CANNOT be obtained
├─ They are NOT necessary
└─ Anyone claiming otherwise is wrong
```

### ✅ **What You WILL Do:**
```
Use YOUR certificate with MOK
├─ Generate self-signed certificate
├─ Sign spoofer with YOUR certificate
├─ Use Microsoft-signed shim bootloader
├─ Enroll YOUR certificate in MOK
└─ Keep Secure Boot ENABLED
```

**This is the PROFESSIONAL approach used by Ubuntu, Fedora, and all major Linux distributions.**

---

## 🛠️ Required Tools

### ✅ Correct Tool: sbsign

```bash
# For EFI files (what you need)
sbsign --key my-key.key --cert my-cert.crt --output signed.efi unsigned.efi
```

**Install:**
```bash
# MSYS2 (Recommended for Windows)
pacman -S mingw-w64-x86_64-sbsigntools

# WSL
wsl sudo apt-get install sbsigntool
```

### ❌ Wrong Tool: signtool

```powershell
# For Windows .exe files (NOT what you need)
signtool sign /f cert.pfx /p password file.exe
```

**DON'T use signtool for EFI files!**

---

## 📊 Comparison: Signing Methods

| Aspect | Microsoft Cert | YOUR Cert + MOK |
|--------|----------------|-----------------|
| **Availability** | ❌ Impossible | ✅ Yes |
| **Secure Boot** | N/A | ✅ Enabled |
| **Industry Standard** | N/A | ✅ Yes |
| **Legal** | ❌ Can't obtain | ✅ Yes |
| **Works** | ❌ No | ✅ Yes |

---

## 🔥 Quick Commands

### Setup and Build
```powershell
# Navigate to project
cd "C:\Users\davie\OneDrive\Área de Trabalho\L2 ISO project\Windows-ISO-Spoofer"

# 1. Initial setup
cd 03-Build-Scripts
.\00-SETUP.ps1

# 2. Generate YOUR certificate
cd ..\07-Keys-And-Certs
.\generate-keys.ps1

# 3. Build ISO (includes signing)
cd ..\03-Build-Scripts
.\00-BUILD-ALL.ps1
```

### Verify Certificate
```powershell
# Check certificate exists
cd 07-Keys-And-Certs
dir my-signing-*

# Should show:
# - my-signing-key.key (private)
# - my-signing-cert.crt (public)
# - my-signing-cert.cer (for MOK)
```

### Verify Signature
```bash
# If sbverify available
sbverify --cert my-signing-cert.crt spoofer.efi
```

---

## 🎓 Understanding MOK

**MOK = Machine Owner Key**

### What is it?
- User-controlled certificate store
- Built into shim bootloader
- Allows custom certificates
- Doesn't disable Secure Boot

### How it works:
```
UEFI Firmware
    ↓ trusts
Microsoft (built-in certificate)
    ↓ signed
Shim Bootloader
    ↓ checks
MOK Database (YOUR certificate)
    ↓ trusts
YOUR Spoofer (signed with YOUR cert)
    ↓ chainloads
Windows
```

### One-time enrollment:
1. Boot from USB
2. MOK Management appears
3. Enroll YOUR certificate
4. Reboot
5. ✅ Trusted forever!

---

## ⚡ Fastest Path to Success

### 5-Minute Checklist

```
[ ] Read SIGNING-SUMMARY.md (understand the truth)
[ ] Install sbsigntools (MSYS2 or WSL)
[ ] Generate YOUR certificate
[ ] Copy spoofer.efi to project
[ ] Copy Windows10.iso to project
[ ] Run 00-BUILD-ALL.ps1
[ ] Test in VM
[ ] Deploy to hardware
[ ] Enroll MOK on first boot
[ ] Verify spoofing works
[ ] Done!
```

---

## 🐛 Common Issues

### Issue 1: "I can't find Microsoft certificate"
**Answer:** Because it doesn't exist for public use. Use YOUR certificate.

### Issue 2: "signtool doesn't work"
**Answer:** Wrong tool. Use sbsign for EFI files.

### Issue 3: "sbsign not found"
**Answer:** Install sbsigntools via MSYS2 or WSL.

### Issue 4: "Signature verification failed"
**Answer:** Enroll MOK on first boot.

---

## 📖 Documentation Priority

### Must Read (in order):
1. **SIGNING-SUMMARY.md** ← You are here / Start here
2. **09-Quick-Signing-Guide.md** ← Quick reference
3. **00-MASTER-GUIDE.md** ← Complete walkthrough

### Optional but Recommended:
4. **08-Certificate-Signing-Reality.md** ← Deep dive
5. **README.md** ← Project overview

---

## ✅ Success Criteria

### You'll know you've succeeded when:
- ✅ Certificate generated (YOUR certificate, not Microsoft's)
- ✅ Spoofer signed with sbsign (not signtool)
- ✅ ISO builds successfully
- ✅ VM boots with Secure Boot enabled
- ✅ MOK enrollment succeeds
- ✅ Windows shows spoofed SMBIOS values
- ✅ `Confirm-SecureBootUEFI` returns True

---

## 🎯 Key Points (Memorize These)

1. **Microsoft certificates = IMPOSSIBLE to get**
2. **YOUR certificate = Easy to generate**
3. **sbsign = Correct tool for EFI**
4. **signtool = Wrong tool (for Windows PE)**
5. **MOK = Makes YOUR certificate trusted**
6. **Secure Boot = Stays ENABLED**
7. **This = Professional standard approach**

---

## 🚀 Ready to Start?

### Option 1: Quick Start (Experienced Users)
```powershell
cd Windows-ISO-Spoofer\03-Build-Scripts
.\00-BUILD-ALL.ps1
```

### Option 2: Step-by-Step (New Users)
1. Read **SIGNING-SUMMARY.md**
2. Follow **00-MASTER-GUIDE.md**

### Option 3: Quick Reference (Returning Users)
- See **09-Quick-Signing-Guide.md**

---

## ❓ Still Confused?

### Read in this order:
1. **SIGNING-SUMMARY.md** - The truth about certificates
2. **08-Certificate-Signing-Reality.md** - Why Microsoft certs don't work
3. **09-Quick-Signing-Guide.md** - Quick commands
4. **00-MASTER-GUIDE.md** - Complete tutorial

### Key Question to Ask Yourself:
> "Am I trying to use Microsoft's certificate, or MY OWN certificate with MOK?"

**Correct answer:** YOUR OWN certificate with MOK!

---

## 🎉 Bottom Line

### The Simple Truth:

```
You do NOT need Microsoft certificates.
You CANNOT get Microsoft certificates.
You WILL use YOUR OWN certificates.

This is NOT a workaround.
This IS the professional standard.

Ubuntu does it.
Fedora does it.
You will do it.

It works perfectly.
```

---

**NOW GO BUILD YOUR ISO! 🚀**

```powershell
cd Windows-ISO-Spoofer\03-Build-Scripts
.\00-BUILD-ALL.ps1
```

---

*Remember: If ANY guide tells you to use Microsoft certificates, that guide is WRONG. You create YOUR OWN certificate and enroll it in MOK. This is the correct, professional, and legal approach.*

**Questions? Read:** [SIGNING-SUMMARY.md](SIGNING-SUMMARY.md)

**Need commands? Read:** [09-Quick-Signing-Guide.md](01-Documentation/09-Quick-Signing-Guide.md)

**Want full tutorial? Read:** [00-MASTER-GUIDE.md](01-Documentation/00-MASTER-GUIDE.md)

