# RNX-Alpine

Creates an ISO image for an automated installer that replaces ReadyNAS OS with 
[Alpine Linux](https://alpinelinux.org) while at the same time
- leaving the data intact
- preserve all SMB shares
- migrating user accounts over to alpine

## Prerequisites

- ReadyNAS running ReadyNAS OS 6.x
- USB drive with at least 2GB of storage space
- working internet connection
- _curious and adventurous mindset highly recommended_

## Quick Start / Usage

If you want to jump right into the fry just grab the latest ISO image from [Releases](./releases),
and burn it on an USB stick. Next, follow the procedure to boot your ReadyNAS from that stick as
outelined in [NETGEAR Support: How do I use the USB Recovery Tool on my ReadyNAS OS 6 storage system?](https://kb.netgear.com/29952/How-do-I-use-the-USB-Recovery-Tool-on-my-ReadyNAS-OS-6-storage-system#Desktop_ReadyNAS).

If all goes well the ReadyNAS will boot from the USB stick, the converter will do its thing and when
it's done it will finish the conversion with a reboot. You then have an converted ReadyNAS that

- runs the latest stable [Alpine Linux (Extended)](https://alpinelinux.org)
- can be accessed via `ssh` using `root` as the username and `password` as password
- has all the old data located in `/data`
- has the user's home data from the ReadyNAS located in `/home`
- has all the previously installed apps in `/apps` (but disabled!)
- runs all the sharing services previoulsy enabled on the ReadyNAS (samba, nfs, ftp, rsync)

### Things to note:**

1) **Installed apps are disabled**
  
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

      - all passwords for newly created users are reset to `password`. Feel free to come up with a
        better solution, I'd be grateful.
    
   Either way, s ince the passwords aren't transferred _**users must login once using ssh to set an
   individual password**_.

1) No web interface

   The converted system will only provide the raw services like SMB, ssh, FTP and the like but no
   web based interface to manage those. Might come later as a Golang tool or whatever. I don't know yet.
   Basically the converted system is just a Linux box with the needed services enabled but no
   other amenities.


## Building

If you want to tweak the converter you will need to roll your own ISO.

### Build requirements

- working [Alpine Linux (Extended)](https://alpinelinux.org/downloads/) system (bare metal or virtual) with
  - at least 2 virtual CPUs (the more the better)
  - at least 2 GB of RAM (the more the better)
  - at least 4 GB hard disk space (the more ... you got it by now, I guess)
  - SSD preferred but not required (it's your time after all)
  - working internet connection
- `git` installed on the Alpine Linux host

### Preparing for the build

#### As user `root`
1) Login to your Alpine box as user `root`
1) clone this repo:

   `git clone https://github.com/RustyDust/rnx-alpine`
1) run the script to create the build user (optional if you already have one):

   `root_user/create_build_user.sh`
1) switch to the build user:

   `su - build`

#### As the build user

1) check out the repo again (yeah, I know ...)

   `git clone https://github.com/RustyDust/rnx-alpine`
1) make necessary/intended changes to 
   - `template/genapkovl.template`
   - `template/preseed.template`

1) When done, run the script to generate the ISO

   ``` bash
   cd build_user
   ./make_iso.sh
   ```
1) Sit back and wait for approx 15 minutes 

## Submitting patches

All enhancements and improvements to this tool are very welcome!
So if you feel you can improve the general working, provide more functionality or fix some
bugs (hopefully not) feel free to submit a PR.

**Please note**
- base your PRs on the `develop` branch, **not "main"**
- sign your commits (`git commit -s`)
- provide some information about what your modifications do
