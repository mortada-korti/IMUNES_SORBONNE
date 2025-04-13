#!/usr/bin/env wish

# Tcl/Tk interface for QEMU

# Function to launch QEMU with selected options
proc launchQEMU {memory disk cpus} {
    set cmd "qemu-system-x86_64 -m $memory -drive file=$disk -smp $cpus"
    exec $cmd &

# ici on ajoute les code qui font que les interface se connect
}

# Function to open file dialog and set selected disk image
proc selectDisk {} {
    set selectedDisk [tk_getOpenFile -filetypes {{"Disk Images" {.img .iso}}}]
    if {$selectedDisk ne ""} {
        .diskEntry delete 0 end
        .diskEntry insert 0 $selectedDisk
    }
}

# GUI setup
wm title . "QEMU Interface"
label .memLabel -text "Memory (MB):"
entry .memEntry -width 10
label .diskLabel -text "Disk Image:"
entry .diskEntry -width 30
button .browseBtn -text "Browse" -command selectDisk
label .cpuLabel -text "CPUs:"
entry .cpuEntry -width 5

button .launchBtn -text "Launch QEMU" -command {
    set memory [string trim [.memEntry get]]
    set disk [string trim [.diskEntry get]]
    set cpus [string trim [.cpuEntry get]]
    if {$memory eq "" || $disk eq "" || $cpus eq ""} {
        tk_messageBox -title "Error" -message "Please fill in all fields."
    } else {
        launchQEMU $memory $disk $cpus
    }
}

# Layout
grid .memLabel -row 0 -column 0 -sticky e
grid .memEntry -row 0 -column 1 -sticky w
grid .diskLabel -row 1 -column 0 -sticky e
grid .diskEntry -row 1 -column 1 -sticky w
grid .browseBtn -row 1 -column 2
grid .cpuLabel -row 2 -column 0 -sticky e
grid .cpuEntry -row 2 -column 1 -sticky w
grid .launchBtn -row 3 -columnspan 3

# Start GUI event loop
pack propagate . 0