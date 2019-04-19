package main

// Perform very basic configuration of a Firecracker VM by calling its API over a Unix socket.
// This does a subset of what the bash implementation in start-fc.sh does, but cuts off ~50ms
//  by avoiding starting 'curl' repeatedly.

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"net"
	"net/http"
	"strings"
)

// Machine is the minimal information needed to create a VM
type Machine struct {
	VCPUs       int    `json:"vcpu_count,omitempty"`
	Memory      int    `json:"mem_size_mib,omitempty"`
	CPUTemplate string `json:"cpu_template,omitempty"`
	HyperThread bool   `json:"ht_enabled,omitempty"`
}

// Kernel is the minimal information needed to specify the kernel
type Kernel struct {
	ImagePath string `json:"kernel_image_path,omitempty"`
	BootArgs  string `json:"boot_args,omitempty"`
}

// Drive is the minimal information needed to attach a disk to a VM
type Drive struct {
	DriveID      string `json:"drive_id"`
	Path         string `json:"path_on_host"`
	IsRootDevice bool   `json:"is_root_device"`
	IsReadOnly   bool   `json:"is_read_only"`
}

// NetDev is the minimal information needed to attach a network device to a VM
type NetDev struct {
	InterfaceID string `json:"iface_id,omitempty"`
	GuestMAC    string `json:"guest_mac,omitempty"`
	HostDev     string `json:"host_dev_name,omitempty"`
}

const commonArgs = "panic=1 pci=off reboot=k tsc=reliable ipv6.disable=1 init=/init"

const startJSON = `{
    "action_type": "InstanceStart"
}`

func newClient(socket string) *http.Client {
	return &http.Client{
		Transport: &http.Transport{
			DialContext: func(_ context.Context, _, _ string) (net.Conn, error) {
				return net.Dial("unix", socket)
			},
		},
	}
}

func fcAPI(client *http.Client, path, body string) error {
	uri := fmt.Sprintf("http://localhost/%s", path)
	bodyBuf := bytes.NewBuffer([]byte(body))
	req, e := http.NewRequest(http.MethodPut, uri, bodyBuf)
	if e != nil {
		return e
	}
	req.Header.Set("Content-Type", "application/json; charset=utf-8")
	rsp, e := client.Do(req)
	if e != nil {
		return e
	}
	defer rsp.Body.Close()
	if rsp.StatusCode < 200 || rsp.StatusCode > 299 {
		return fmt.Errorf("Got unexpected status code %d", rsp.StatusCode)
	}
	return nil
}

func main() {

	socketOpt := flag.String("s", "", "Path to the firecracker control socket")

	kernelOpt := flag.String("k", "../img/boot-time-vmlinux", "Path to the kernel image")
	rootfsOpt := flag.String("r", "../img/boot-time-disk.img", "Path to the root disk")
	coresOpt := flag.Int("c", 1, "Number of cores for the VM")
	memOpt := flag.Int("m", 256, "Amount of memory in MB")
	diskOpt := flag.String("disk", "", "Path to additional disk")
	netOpt := flag.String("n", "", "Network configuration 'tap,tap ip,mac,vm ip,mask'")

	debugOpt := flag.Bool("d", false, "Enable debug output")

	flag.Parse()

	machine := Machine{
		VCPUs:       *coresOpt,
		Memory:      *memOpt,
		CPUTemplate: "T2",
		HyperThread: true,
	}
	b, err := json.Marshal(machine)
	if err != nil {
		panic(err)
	}
	machineJSON := string(b)

	var netJSON string
	var netArgs string
	if *netOpt != "" {
		netCfg := strings.SplitN(*netOpt, ",", 5)
		if len(netCfg) != 5 {
			panic("Network config")
		}
		netDev := NetDev{
			InterfaceID: "1",
			GuestMAC:    netCfg[2],
			HostDev:     netCfg[0],
		}
		b, err := json.Marshal(netDev)
		if err != nil {
			panic(err)
		}
		netJSON = string(b)

		netArgs = " ip=" + netCfg[3] + "::" + netCfg[1] + ":" + netCfg[4] + "::eth0:off"
	}

	kernel := Kernel{
		ImagePath: *kernelOpt,
	}
	if *debugOpt {
		kernel.BootArgs = commonArgs + netArgs + " console=ttyS0"
	} else {
		kernel.BootArgs = commonArgs + netArgs + " quiet 8250.nr_uarts=0"
	}

	b, err = json.Marshal(kernel)
	if err != nil {
		panic(err)
	}
	kernelJSON := string(b)

	drive := Drive{
		DriveID:      "1",
		Path:         *rootfsOpt,
		IsRootDevice: true,
		IsReadOnly:   true,
	}
	b, err = json.Marshal(drive)
	if err != nil {
		panic(err)
	}
	driveJSON := string(b)

	var diskJSON string
	if *diskOpt != "" {
		disk := Drive{
			DriveID:      "2",
			Path:         *diskOpt,
			IsRootDevice: false,
			IsReadOnly:   false,
		}
		b, err = json.Marshal(disk)
		if err != nil {
			panic(err)
		}
		diskJSON = string(b)
	}

	client := newClient(*socketOpt)
	if err := fcAPI(client, "machine-config", machineJSON); err != nil {
		panic(err)
	}
	if err := fcAPI(client, "drives/1", driveJSON); err != nil {
		panic(err)
	}
	if err := fcAPI(client, "boot-source", kernelJSON); err != nil {
		panic(err)
	}
	if diskJSON != "" {
		if err := fcAPI(client, "drives/2", diskJSON); err != nil {
			panic(err)
		}
	}
	if netJSON != "" {
		if err := fcAPI(client, "network-interfaces/1", netJSON); err != nil {
			panic(err)
		}
	}
	if err := fcAPI(client, "actions", startJSON); err != nil {
		panic(err)
	}
}
