# How do I use the USB Recovery Tool on my ReadyNAS OS 6 storage system?
<sup>_copied from: https://kb.netgear.com/29952/How-do-I-use-the-USB-Recovery-Tool-on-my-ReadyNAS-OS-6-storage-system_</sup>

If you cannot access your ReadyNAS storage system but it is currently able to 
boot, visit [ReadyNAS Not Accessible FAQ](https://kb.netgear.com/app/answers/detail/a_id/29792)

If a firmware upgrade fails, your ReadyNAS storage system might be unable to 
boot. You can use the USB Recovery Tool to reload current firmware onto your 
ReadyNAS storage system for recovery purposes only.

> **Warning**
>
> **If you use the USB Recovery Tool incorrectly or if you attempt to use the USB
> Recovery Tool to downgrade to an older firmware version, you might cause 
> permanent damage to your ReadyNAS system. Only use the USB Recovery Tool when
> NETGEAR Technical Support recommends it.**

Generally, firmware upgrade failure happens because the new ReadyNAS firmware
was not fully written to your ReadyNAS system due to something unexpected 
during upgrade. When the ReadyNAS system reboots into normal mode, it might
proceed with trying to upgrade your system with the poorly copied firmware
image, fail, and still try to start up.

The USB Recovery Tool only works on Windows PCs, but if you need to manually
create a recovery USB drive on an ARM-based computer system, jump to 
[To create a USB recovery drive for an ARM-based ReadyNAS system](#to-create-a-usb-recovery-drive-for-an-arm-based-system).

> **Note** 
> 
> Manually created USB recovery drives only work on ARM-based ReadyNAS systems.
> If you need to perform USB recovery on an x86 ReadyNAS system, you must use the
> USB Recovery Tool.

## Warnings

This tool must only be used at the recommendation of NETGEAR Technical Support.
Read through all of the steps and make sure you feel comfortable with the
process before proceeding. Otherwise, do not proceed with these.

The USB Recovery Tool attempts to overwrite existing firmware data on the
ReadyNAS system. Using the USB Recovery Tool incorrectly can cause irreparable
damage to the ReadyNAS system. To avoid permanent damage to your ReadyNAS
system, observe the following precautions:

* Do not power down the ReadyNAS system prematurely during write operations.
* Do not attempt to downgrade the firmware of the ReadyNAS system.

Use of the USB Recovery Tool is at your own risk.

## To prepare the software:

1) Download the [USB Recovery Tool](contrib/os6-recovery-tool-v2.0.r17.zip).
1) Extract os6-recovery-tool.zip to a new folder on your desktop.
1) Download the latest firmware package for your ReadyNAS model, visit ReadyNAS OS 6 Support.
   * If you're using a _ReadyNAS 100, 200, 210, or 2120_ series model,
      download the ARM firmware package.
   * If you're using any other ReadyNAS series, download the x86 package.
1) Extract the firmware file (.img) and release notes from the zip file to the
   same folder you used for the USB Recovery Tool.
1) Open the Recovery Tool folder on your desktop and move the firmware file into it:
   * If the ReadyNAS is an _RN100 or RN2120_ series model, move the firmware file into the `Arm` folder.
   * If the ReadyNAS is a _200 or 210 series_ model, move the firmware file into the `rn2xx` folder.
   * If the ReadyNAS is a _310, 420, 510, 520, 620, 710, 3130/3138, 3220, 3312, 4220, or 4300_ series
     model, move the firmware file into the `x86` folder.

## To prepare the USB drive:
1) Find a USB drive with a capacity that is greater than 256 MB, but no more than 32 GB.
1) Ensure that the USB drive has only one partition.
1) Format the USB drive as FAT-32.
1) Make a note of the drive letter your USB drive is assigned after formatting.

## To create the Recovery Tool USB drive:
1) From the Recovery Tool folder on your desktop, open `usbrecovery.exe`.
1) Select the drive letter the USB was assigned under “To prepare the USB drive.” Click **Format**.
1) Select the appropriate options for your ReadyNAS system under **Select a product, Select a model, and Select Firmware Image**. 
1) Click **Create**.

## To boot your desktop model ReadyNAS from USB:
For rack-mount models, see [To boot your rack-mount model ReadyNAS from USB](#to-boot-your-rack-mount-model-readynas-from-usb).
1) Power down your ReadyNAS storage system.
1) Insert the prepared USB drive into the **front** USB port.
1) Press and hold the **Backup** button, then power on the ReadyNAS system 
   and **continue** to hold the **Backup** button for up to 15 seconds, 
   depending on your ReadyNAS model.
   * If your ReadyNAS system is an _RN316, RN516, or RN716X_:
     - After powering on the ReadyNAS system, wait for the backlight around
       the touchpad to turn off.
     - Instead of the **Backup** button, press and hold the **OK** button for 
       up to 30 seconds, until the LCD confirms that the ReadyNAS is attempting
       to boot from the USB drive.
   * If your ReadyNAS system is an _RN420, RN520, or RN620_ series:
     - After powering on the ReadyNAS system, wait for the backlight on the 
       navigational buttons to turn off.
     - Instead of the **Backup** button, press and hold the **OK** button
       (the center of the navigational buttons) for up to 30 seconds, until the
       LCD confirms that the ReadyNAS is attempting to boot from the USB drive.
   * If your ReadyNAS system has an LCD, the LCD confirms that the ReadyNAS is
     in USB Recovery mode.
   * If your ReadyNAS system is a 2-bay model, you might not know when the unit
     is entering USB Recovery mode unless your USB drive has an activity 
     indicator. If your USB drive does not have an activity indicator, hold the
     **Reset** button for a full 30 seconds to ensure that your ReadyNAS system
     is in USB Recovery mode.
1) Wait for the ReadyNAS system to finish with the recovery and power down.
1) After the system powers down, remove the USB drive and try booting normally.

## To boot your rack-mount model ReadyNAS from USB:
1) Insert the prepared USB drive into any available USB port.
1) Press and hold the **Reset** button. Power on the ReadyNAS system and 
   continue to hold the **Reset** button for up to 15 seconds, depending on 
   your ReadyNAS model.
   * If your ReadyNAS has an LCD, hold the **Reset** button until the LCD 
     confirms that the ReadyNAS is in USB Recovery mode.
   * On the _ReadyNAS 2120_, hold the **Reset** button until the LEDs begin
     blinking rapidly, after about 5 to 10 seconds.
1) _(Optional)_ If your ReadyNAS system has a VGA or HDMI port, you can 
   connect a display to watch the update process.
1) Wait for the ReadyNAS system to finish with the recovery and power down.
1) After the system powers down, remove the USB drive and try booting normally.

## Troubleshooting USB recovery problems
* If your ReadyNAS is still powered on after 20 minutes, the recovery process
  probably failed. Some USB drives report incorrect information during the 
  recovery process that makes the USB unmountable. If this happens, the 
  ReadyNAS system does not attempt to overwrite its flash memory. Try several
  different USB drives until the ReadyNAS completes the recovery process.
* If you are upgrading and your system is unable to boot properly, you might
  need to perform an OS reinstall and re-extract the system firmware. For 
  directions, visit [ReadyNAS & ReadyDATA: Boot Menu](https://kb.netgear.com/app/answers/detail/a_id/20898)
* If you attempt to downgrade your ReadyNAS system’s firmware, your ReadyNAS
  system can become permanently unbootable, even from USB. Many changes happen 
  between large firmware releases, including changes to bootloaders and 
  internal components. Only perform USB Recovery with the same or newer 
  ReadyNAS OS firmware.
* If the USB Recovery Tool resolves your booting issue but you still have a
  different issue, consider performing a factory reset and restoring your 
  ReadyNAS system from your pre-upgrade backup.

## To create a USB recovery drive for an ARM-based system:
You can use these instructions for recovering ARM-based ReadyNAS storage systems.
If your ReadyNAS system is x86-based, you must use the USB Recovery Tool software, which is only supported on Windows.

1) Find a USB drive with a capacity that is greater than 256 MB, but no more than 32 GB.
1) Ensure that the USB drive has only one partition.
1) Format the USB drive as FAT, FAT-32, or MS-DOS file system.
1) Make a note of the drive letter your USB drive is assigned after formatting.
1) Copy data to the USB:
   * If your ReadyNAS system is an _RN102, RN104, or RN2120_, copy 
     `initrd-recovery.gz` and `NTGR_USBBOOT_INFO.txt` files from the `Arm`
      directory onto the USB drive. Then copy to the USB drive the 
      `uImage-recovery` file from the `Arm/<MODEL>` directory, where
      `<MODEL>` is rn102, rn104, or rn2120.
   * If your ReadyNAS system is an _RN200 or RN210_ series, copy 
     `initrd-recovery.gz`, `NTGR_USBBOOT_INFO.txt`, and `uImage-recovery` from
     the rn2xx folder to your USB drive.
1) After you prepare the USB drive, follow the directions in this guide under 
  [To boot your desktop model ReadyNAS from USB](#to-boot-your-desktop-model-readynas-from-usb) 
  or 
  [To boot your rack-mount model ReadyNAS from USB](#to-boot-your-rack-mount-model-readynas-from-usb).
