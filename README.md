# RNX-Alpine

Creates an ISO image for an automated installer that replaces ReadyNAS OS with 
[Alpine Linux](https://alpinelinux.org) while at the same time
- leaving the data intact
- preserve all SMB shares
- migrating user accounts over to alpine

## Quick Start

If you want to jump right into the fry just grab the latest ISO image from [Releases](./releases),
and burn it on an USB stick. Next, follow the procedure to boot your ReadyNAS from that stick as
outelined in [NETGEAR Support: How do I use the USB Recovery Tool on my ReadyNAS OS 6 storage system?](https://kb.netgear.com/29952/How-do-I-use-the-USB-Recovery-Tool-on-my-ReadyNAS-OS-6-storage-system#Desktop_ReadyNAS).

If all goes well the ReadyNAS will boot from the USB stick, the converter will do its thing and when
it's done it will finish the conversion with a reboot. You then have an converted ReadyNAS that

- runs the latest stable [Alpine Linux](https://www.alpinelinux.org)
- can be accessed via `ssh` using `root` as the username and `password` as password
- has all the old data located in `/data`
- has the user's home data from the ReadyNAS located in `/home`
- has all the previously installed apps in `/apps` (but disabled!)
- runs all the sharing services previoulsy enabled on the ReadyNAS (samba, nfs, ftp, rsync)

### Things to note:**

1) **Apps are disabled**
  
   As noted above, apps previously installed on the ReadyNAS are transferred to the converted system 
   but they are **disabled**. The reason for this is that Alpine doesn't use [systemd](https://systemd.io)
   but relies on [OpenRC](https://wiki.gentoo.org/wiki/OpenRC) instead.
   To convert between these systems automatically is nearly impossible so it's left as an eductational
   task for the user.

1) **Passwords aren't preserved/transferred**

   Because of the differences in user and group manangement it is not easy to transfer password between
   different Linux distributions, even when doing an in-place switch. Thus, the current approach is:
   
   - ignore all system accounts from the ReadyNAS
   - for all the "normal accounts"

      - if they exist in Alpine Linux change all the file-/directory 
        ownerships to the ids used by the corresponsing Alpine users/groups

      - if they don't exist create new users/groups with ids as closely matching to the originals
        as possible. Where this doesn't work change the file/directory ownership to the ids of the
        newly created users/groups
    
   Either way, since the passwords couldn't 


## Prerequisites

- ReadyNAS running ReadyNAS OS 6.x
- USB drive with at least 2GB of storage space
- working internet connection
- _curious and adventurous mindset highly recommended_

## Build requirements

- working Alpine Linux system (bare metal or virtual)
- `git`installed on the Alpine Linux host


