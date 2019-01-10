# BestWB Package

BestWB is an enhancement built for Amiga OS 3.1.4 by Gulliver.

## Description

BestWB Package contains BestWB v1.0 created by Gulliver from EAB.

Original version of BestWB can be downloaded from http://lilliput.amiga-projects.net/BestWB.htm.

---

BestWB is a new workbench pack, much like BetterWB. It aims to be much like an enhancement, an updated extension to AmigaOS 3.1.4, without all those hardware penalties typically associated with these kind of packs. It is indeed a better 3.1.4 than 3.1.4 itself!

BestWB will suit anyone that wishes a clean AmigaOS experience without the unneeded bloat often associated with these kind of distros. It persues speed and usability and does not focus on eye candy.

**Feature list:**

- A Find system tool so that the workbench menu "Find..." gets activated (SimpleFind).
- New and Improved datatypes for gif, jpg, bmp, png, pcx, tga, tiff, and wav media.
- New Removable media partition mounter (SCSIMounter)
- New System snooper (SnoopDOS)
- Fast and easy to use floppy disk copier application (SuperDuper)
- Libraries for cpu support and better hardware detection (MMULib+BoardsLib).
- A filemanager to copy, move and delete files in an easier manner (DirWork).
- Lots of of handy commodities that make user experience much more comfortable (GrabIFF, AssignWedge, CleverWIN, FreeWheel, Rewincy, ToolsMenu, ToolAlias, NewMode, yStart, DosPrefs, BenchTrash, PowerSnap, CronTask, PM and MagicMenu).
- 58 additional workbench printer drivers (take a peek at your SYS:Storage/printers drawer).
- Complementary commands like AddMem, DMS, WBCtrl, and showboards.
- ZIP and JAZ drive support and their corresponding mountlists (IOTools).
- XPKMaster offers a data compression/decompression library available to programs that support it.
- Charmap is a tool that helps dealing with all the characters of a given font. Useful for accents and uncommon characters.
- Prepcard+ helps the user to manage many hardware on the pcmcia port
- The popular LHA, LZX, GZIP and ZIP/UNZIP archiver commands are installed in their latest incarnation.
- Compact Disk audio player with lots of great features (ACDPlay)
- Midi support for many programs with camd.library and the Midiports preferences application.
- New graphic interface that lets you read and write back adf and dms floppy images (TSGUI).
- There is a new preferences program (WBStartupPrefs) that lets you easily handle the WBStartup and Commodities drawer.
- The light weight but otherwise efficient Redit text editor is also included.
- New monitors drivers for native Amiga chipset (Film24, HD720, HighGFX, SuperPlus and Xtreme).
- FontView is an app able to browse thru available fonts and report their characteristics.
- A Backup tool that can even be made to work with non Amiga partitions (ABackup).
- Shell with command completion, scrollbars and lots of other nice features thanks to VinCed.
- A workbench friendly NSD/TD64 compatible drive defragmenter (DiskOptimizer).
- Totalcalc is a replacement calculator that can even be configured as an advanced scientific one.
- Unpacker aids the user in uncompressing archived files with a GUI.
- A very fast antivirus that supports xvs.library is now deployed (Fungicide).
- TextView is an advanced text viewer that supports html between other formats.
- DTView2 is a simple and efficient picture viewer.
- IconLib 46.4 is a fast icon.library reimplementation that allows you to see all types of icons (standard, newicons, glowicons, png, etc.).
- FullPalette will let you lock and optimise palettes.
- A complete set of manuals that explain all these new features. They are inside HELP:.
- And much more…
- Purists that believe anything beyond 3.1 is an overbloated piece of crap.
- Low end Amiga computers that are left in storage deprived from any usage, and only regarded as antiques.
- Users that refuse to pay big bucks in order to be able to somehow upgrade their Amiga workbench experience.
- Minimig users, that are restricted to a 68000 processor.
- Anyone that wishes a clean AmigaOS 3.1 like experience.

## Requirements

BestWB package can be installed on any Amiga with Amiga OS 3.1.4 and about 8MB free space on a harddrive for installation.

## Installation

Download latest release from https://github.com/henrikstengaard/bestwb-package/releases and copy it to HstWB Installer "packages" directory, which typically is "c:\Program Files (x86)\HstWB Installer\Packages".

Installation through HstWB Installer will install and configure BestWB package using defined assigns.

## Assigns

Installation of BestWB package requires and uses following assign and default value:

- SYSTEMDIR: = DH0:

BestWB files will be installed and configured in SYSTEMDIR: assign, which must be set to harddrive containing Workbench.

## Modifications

BestWB is installed from a zip files copied from BestWB adf files.

The install script for BestWB package is based on S/Startup-Sequence from MISC31_#1.adf with following changes:

- Paths has been changed: SYS: to SYSTEMDIR:.
- Removed waits for next floppy.
- Removed ENV-HANDLER patch.

## Screenshots

Screenshots of BestWB package.

![BestWB 1](screenshots/bestwb_1.png?raw=true)

![BestWB 2](screenshots/bestwb_2.png?raw=true)

![BestWB 3](screenshots/bestwb_3.png?raw=true)

![BestWB 4](screenshots/bestwb_4.png?raw=true)

![BestWB 5](screenshots/bestwb_5.png?raw=true)