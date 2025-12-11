# Manual MOK Enrollment Guide

## The Problem
The automated MOK enrollment isn't triggering. We need to enroll your certificate manually.

## Solution 1: Disable Secure Boot (Temporary)

This is the **easiest** approach for testing:

### Steps:
1. **Restart** computer
2. **Enter BIOS** (F2, Del, F12, or ESC)
3. **Find "Secure Boot"** setting (usually in Security or Boot tab)
4. **Disable Secure Boot**
5. **Save and Exit**
6. **Boot from USB**
7. **Spoofer will work** (no signature needed with Secure Boot off)

### After Testing:
- If spoofer works, you can either:
  - **Keep Secure Boot disabled** (simpler)
  - **Or** continue to Solution 2 to enable it

---

## Solution 2: Manual MOK Enrollment from Windows

If you want Secure Boot ON, enroll MOK from Windows:

### Steps:

1. **Boot Windows normally** (not from USB)

2. **Open PowerShell as Admin** and run:
```powershell
# Navigate to certificate location
cd "C:\Users\davie\OneDrive\Área de Trabalho\L2 ISO project\Windows-ISO-Spoofer\02-Certificates"

# Use WSL to enroll MOK
wsl sudo mokutil --import my-key.cer
```

3. **Enter a password** when prompted (you'll need this on next boot)

4. **Restart computer**

5. **MOK enrollment screen appears** (blue screen)

6. **Follow prompts:**
   - Select "Enroll MOK"
   - Enter the password you set
   - Confirm enrollment
   - Reboot

7. **MOK is now enrolled!**

8. **Re-enable Secure Boot in BIOS** if you disabled it

9. **Run dashboard → "4. Install to System"**

---

## Solution 3: Use Without Secure Boot

If MOK enrollment is too complex, just use with Secure Boot disabled:

**Advantages:**
- ✅ Works immediately
- ✅ No MOK enrollment needed
- ✅ Simpler setup

**Disadvantages:**
- ⚠️ Secure Boot protection disabled
- ⚠️ Less secure (but functionally identical)

**How:**
1. Disable Secure Boot in BIOS
2. Run dashboard → "4. Install to System"
3. Spoofer runs every boot
4. No MOK needed

---

## Recommendation

**For Testing:** Use Solution 1 (disable Secure Boot temporarily)
- Quick to test if spoofer works
- Can re-enable later if needed

**For Production:** Use Solution 2 (manual MOK enrollment)
- Keeps Secure Boot enabled
- More secure
- One-time setup

**For Simplicity:** Use Solution 3 (keep Secure Boot disabled)
- Easiest ongoing use
- Spoofer still works perfectly
- Just less Windows security

---

## Current Status

Your spoofer is **ready to use** - you just need to either:
- Disable Secure Boot, OR
- Manually enroll MOK

Both options make the spoofer work. The choice is yours based on your security preferences.

