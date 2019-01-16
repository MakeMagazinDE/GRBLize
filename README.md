![GitHub Logo](http://www.heise.de/make/icons/make_logo.png)

Maker Media GmbH und c't, Heise Zeitschriften Verlag

***

# GRBLize V1.4

### CNC-Steuerung für GRBL-JOG Projekt

Erstellt mit Delphi XE8 Starter. Bitte beachten Sie unbedingt den Artikel in **[c't Hacks 4/2014](http://shop.heise.de/katalog/ct-hacks-4-2014)**. 

**Derzeit gibt es [Delphi 10.1 Berlin Starter](https://www.embarcadero.com/de/products/delphi/starter/promotional-download) kostenlos!** 

Ausführbare Datei (.EXE, Win32) im Verzeichnis 
**[/bin](https://github.com/heise/GRBLize/tree/master/bin)**, benötigt 
"default.job", ggf. die Beispiel-Plot-Dateien und gegebenenfalls ftd2xx.dll, 
letzteres aber nur, falls nicht ohnehin schon im System vom FTDI-Treiber-
Download installiert.

Auf der rechten Spalte der Github-Seite finden Sie den Button "Download ZIP". 
Dies lädt das komplette Projekt herunter einschl. Sourcen. Nach Entpacken findet 
sich das Windows-Executable (32 Bit) im Unterverzeichnis /bin.

Das Projekt befindet sich noch in Entwicklung, bitte auf evt. Updates prüfen. 
Die passende GRBL-Steuerplatine finden Sie in unserem Github-Repo **[GRBL-
JOG](https://github.com/heise/GRBL-JOG)**. Die neueste Version unterstützt jetzt 
auch GRBL 0.9j sowie GRBL auf Arduino und ähnlichen Boards.

### Version History

- 1.5 noGL: Version ohne das recht umständlich zu installierende OpenGL-Derivat "GLscene"
- 1.5: Unterstützung für GRBL 1.1 kompilierbar, noch nicht vollständig getestet. 
Binary ist für GRBL 0.9j. Korrekte Behandlung der File-XY-Offsets auch bei Roatation/Mirror, Pfade im 
Drawing Window einzeln deaktivierbar. Instant-Mill-Funktionen für Kreise und Rechtecke ab Tool-Position.
- 1.4: Stark umgebaute Programmstruktur. CANCEL funktioniert endlich wie es soll. Ausgabe optimiert. ATC getestet. PCB Import stark vereinfacht. 
- 1.1b: Interface for pcb2gcode.exe in Utilities/Tools tab. Revised interpreter for excellon files. Added 2D G-Code and simple SVG import to interface with pcb2gcode.
- 1.0b: Supports serial COM port as well as direct FTDI serial communications. Re-written robust protocol engine. New simulation for G-Codes as a finite elements model in 3 resolutions. Some bugs fixed. Suports GRBL 0.8x and new GRBL 0.9j. New on-screen jog pad for use with other boards than GRBL-JOG. Supports GRBL running on a plain Arduino.
- 0.96d: On run, will keep Z up at park position height until first mill to clear work part. 
- 0.96b: bugfix on FTDI class, new "Z Feed Scaling" parameter, multiplies XY feed value for Z to prevent tool damage (<1 = slower). Also useful with c't woodmill (>1 = faster, otherwise Z feed will be too slow).
- 0.95b: First public beta
- 0.94a: Internal alpha, some serious bugs

### CNC Control Software for GRBL Jogger Project

Executable for Windows XP/7/8 in folder **[/bin](https://github.com/heise/GRBLize/tree/master/bin)**. No Installation required, but configuration file "default.job" and example plot files 
must be placed in same folder. Please see article in **[c't Hacks 4/2014](http://shop.heise.de/katalog/ct-hacks-4-2014)** for usage.

Version in Master branch made with Delphi 2005 PE. Sources to be compiled with Borland Delphi 2005 Personal Edition (and up) for those interested in improving it. GRBLize 
uses ftdiclass component from Michael "Zipplet" Nixon, Clipper library by Angus Johnson and GLscene OpenGL component.

Borland Delphi 2005 Personal Edition was downloadable for free some time ago, also included on some computer magazine CDs/DVDs as on c't 13/2005. It should be still available for free on http://delphi.developpez.com/delphi2005/

Delphi 2005 still works fine on Windows 7 if you add the new string value "$(BDS)\Bin\delphicoreide90.bpl" = "Delphi Core IDE" 
to the "HKEY_CURRENT_USER\Software\Borland\BDS\3.0\Known IDE Packages" registry key. Otherwise you'll get an access 
violation error on rtl90.bpl on exit of IDE. 

On Windows 7 latest update, the DZ Line Editor Fix (http://sourceforge.net/projects/dzeditorlineendsfix/) must be installed.

For Delphi 2005 PE, if you want to compile and install the design-time support for GLScene in folder Delphi2005, you 
will need to:

- rename FAKE_xmlrtl.dcp to xmlrtl.dcp
- copy/move it to your BDS\3.0\lib directory

This will take care of the warning (doesn't add xmlrtl functionality however, the dcp is empty). Source:
http://andy.jgknet.de/oss/kylix/wiki/index.php/Delphi_2005_Personal_Edition_xmlrtl.dcp_fake

Do not hesitate to port the project to [Lazarus](http://www.lazarus.freepascal.org), a free Delphi clone available for Linux and Windows.

Please note: some parts may rely on comma as a decimal separator in tables, please check first.

(c) by Carsten Meyer, Redaktion c't Hacks/Make Deutschland, cm@ct.de, 12/2014.
