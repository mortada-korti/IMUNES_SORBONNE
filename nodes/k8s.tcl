# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

# $Id: k8s.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/k8s.tcl
# NAME
#  k8s.tcl -- defines k8s specific procedures
# FUNCTION
#  This module is used to define all the k8s specific procedures.
# NOTES
#  Procedures in this module start with the keyword k8s and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE k8s

registerModule $MODULE

#****f* k8s.tcl/k8s.confNewIfc
# NAME
#   k8s.confNewIfc -- configure new interface
# SYNOPSIS
#   k8s.confNewIfc $node $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node ifc } {
    global changeAddressRange changeAddressRange6
    set changeAddressRange 0
    set changeAddressRange6 0
    autoIPv4addr $node $ifc
    autoIPv6addr $node $ifc
    autoMACaddr $node $ifc
    autoIPv4defaultroute $node $ifc
    autoIPv6defaultroute $node $ifc
}

#****f* k8s.tcl/k8s.confNewNode
# NAME
#   k8s.confNewNode -- configure new node
# SYNOPSIS
#   k8s.confNewNode $node
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType k8s $nodeNamingBase(k8s)]" \
	! ]
    lappend $node "network-config [list $nconfig]"
    lappend $node "node-type worker"

    setLogIfcType $node lo0 lo
    setIfcIPv4addr $node lo0 "127.0.0.1/8"
    setIfcIPv6addr $node lo0 "::1/128"
}

#****f* k8s.tcl/k8s.icon
# NAME
#   k8s.icon -- icon
# SYNOPSIS
#   k8s.icon $size
# FUNCTION
#   Returns path to node icon, depending on the specified size.
# INPUTS
#   * size -- "normal", "small" or "toolbar"
# RESULT
#   * path -- path to icon
#****
proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR
    switch $size {
      normal {
	return $ROOTDIR/$LIBDIR/icons/normal/k8s.png
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/k8s.png
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/k8s.png
      }
    }
}

#****f* k8s.tcl/k8s.toolbarIconDescr
# NAME
#   k8s.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   k8s.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new k8s"
}

#****f* k8s.tcl/k8s.notebookDimensions
# NAME
#   k8s.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   k8s.notebookDimensions $wi
# FUNCTION
#   Returns the specified notebook height and width.
# INPUTS
#   * wi -- widget
# RESULT
#   * size -- notebook size as {height width}
#****
proc $MODULE.notebookDimensions { wi } {
    set h 210
    set w 507

    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Configuration" } {
	set h 270
	set w 507
    }
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    return [list $h $w]
}

#****f* k8s.tcl/k8s.ifcName
# NAME
#   k8s.ifcName -- interface name
# SYNOPSIS
#   k8s.ifcName
# FUNCTION
#   Returns k8s interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
}

#****f* k8s.tcl/k8s.IPAddrRange
# NAME
#   k8s.IPAddrRange -- IP address range
# SYNOPSIS
#   k8s.IPAddrRange
# FUNCTION
#   Returns k8s IP address range
# RESULT
#   * range -- k8s IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* k8s.tcl/k8s.layer
# NAME
#   k8s.layer -- layer
# SYNOPSIS
#   set layer [k8s.layer]
# FUNCTION
#   Returns the layer on which the k8s communicates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* k8s.tcl/k8s.virtlayer
# NAME
#   k8s.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [k8s.virtlayer]
# FUNCTION
#   Returns the layer on which the k8s is instantiated i.e. returns VIMAGE.
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return K8S
}

#****f* k8s.tcl/k8s.cfggen
# NAME
#   k8s.cfggen -- configuration generator
# SYNOPSIS
#   set config [k8s.cfggen $node]
# FUNCTION
#   Returns the generated configuration. This configuration represents
#   the configuration loaded on the booting time of the virtual nodes
#   and it is closly related to the procedure k8s.bootcmd.
#   For each interface in the interface list of the node, ip address is
#   configured and each static route from the simulator is added.
# INPUTS
#   * node -- node id (type of the node is k8s)
# RESULT
#   * congif -- generated configuration
#****
proc $MODULE.cfggen { node } {

    set cfg {}
    set cfg [concat $cfg [nodeCfggenIfcIPv4 $node]]
    set cfg [concat $cfg [nodeCfggenIfcIPv6 $node]]
    lappend cfg ""

    set cfg [concat $cfg [nodeCfggenRouteIPv4 $node]]
    set cfg [concat $cfg [nodeCfggenRouteIPv6 $node]]
    return $cfg
}

#****f* k8s.tcl/k8s.bootcmd
# NAME
#   k8s.bootcmd -- boot command
# SYNOPSIS
#   set appl [k8s.bootcmd $node]
# FUNCTION
#   Procedure bootcmd returns the application that reads and employes the
#   configuration generated in k8s.cfggen.
#   In this case (procedure k8s.bootcmd) specific application is /bin/sh
# INPUTS
#   * node -- node id (type of the node is k8s)
# RESULT
#   * appl -- application that reads the configuration (/bin/sh)
#****

proc $MODULE.bootcmd { node } { 
    return "/bin/sh"
}

#****f* k8s.tcl/k8s.shellcmds
# NAME
#   k8s.shellcmds -- shell commands
# SYNOPSIS
#   set shells [k8s.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the k8s node
#****
proc $MODULE.shellcmds {} {
    return "csh bash sh tcsh"
}

#****f* k8s.tcl/k8s.instantiate
# NAME
#   k8s.instantiate -- instantiate
# SYNOPSIS
#   k8s.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure k8s.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is k8s)
#****
proc $MODULE.instantiate { eid node } {
    l3node.instantiateK $eid $node
}

#****f* k8s.tcl/k8s.start
# NAME
#   k8s.start -- start
# SYNOPSIS
#   k8s.start $eid $node
# FUNCTION
#   Starts a new k8s. The node can be started if it is instantiated.
#   Simulates the booting proces of a k8s, by calling l3node.start procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is k8s)
#****
proc $MODULE.start { eid node } {
    l3node.start $eid $node
}

#****f* k8s.tcl/k8s.shutdown
# NAME
#   k8s.shutdown -- shutdown
# SYNOPSIS
#   k8s.shutdown $eid $node
# FUNCTION
#   Shutdowns a k8s. Simulates the shutdown proces of a k8s,
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is k8s)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* k8s.tcl/k8s.destroy
# NAME
#   k8s.destroy -- destroy
# SYNOPSIS
#   k8s.destroy $eid $node
# FUNCTION
#   Destroys a k8s. Destroys all the interfaces of the k8s
#   and the vimage itself by calling l3node.destroy procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is k8s)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* k8s.tcl/k8s.nghook
# NAME
#   k8s.nghook -- nghook
# SYNOPSIS
#   k8s.nghook $eid $node $ifc
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node ifc } {
    return [l3node.nghook $eid $node $ifc]
}

#****f* k8s.tcl/k8s.configGUI
# NAME
#   k8s.configGUI -- configuration GUI
# SYNOPSIS
#   k8s.configGUI $c $node
# FUNCTION
#   Defines the structure of the k8s configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****
proc $MODULE.configGUI { c node } {
    global wi
    global guielements treecolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "k8s configuration"
    configGUI_nodeName $wi $node "Node name:"

    set tabs [configGUI_addNotebook $wi $node {"Configuration" "Interfaces" "master/worker"}]
    set configtab [lindex $tabs 0]
    set ifctab [lindex $tabs 1]
    set mwtab [lindex $tabs 2]

    set treecolumns {"OperState State" "IPv4addr IPv4 addr" "IPv6addr IPv6 addr" \
	    "MACaddr MAC addr" "MTU MTU" "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}

    configGUI_addTree $ifctab $node
    
    configGUI_dockerImage $configtab $node
    configGUI_attachDockerToExt $configtab $node
    configGUI_servicesConfig $configtab $node
    configGUI_staticRoutes $configtab $node
    configGUI_snapshots $configtab $node
    configGUI_customConfig $configtab $node
    configGUI_K8S $mwtab $node
    configGUI_buttonsACNode $wi $node
}

#****f* k8s.tcl/k8s.configInterfacesGUI
# NAME
#   k8s.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   k8s.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the k8s configuration window. It is done by calling procedures for adding
#   certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.configInterfacesGUI { wi node ifc } {
    global guielements

    configGUI_ifcEssentials $wi $node $ifc
    configGUI_ifcQueueConfig $wi $node $ifc
    configGUI_ifcMACAddress $wi $node $ifc
    configGUI_ifcIPv4Address $wi $node $ifc
    configGUI_ifcIPv6Address $wi $node $ifc
}
