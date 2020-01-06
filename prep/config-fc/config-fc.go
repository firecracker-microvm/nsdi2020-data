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
	"io/ioutil"
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

// BootSource is the minimal information needed to specify the kernel
type BootSource struct {
	Path string `json:"kernel_image_path,omitempty"`
	Args string `json:"boot_args,omitempty"`
}

// Drive is the minimal information needed to attach a disk to a VM
type Drive struct {
	ID           string `json:"drive_id"`
	Path         string `json:"path_on_host"`
	IsRootDevice bool   `json:"is_root_device"`
	IsReadOnly   bool   `json:"is_read_only"`
}

// Logger is the minimal information needed to add a logger
type Logger struct {
	LogFifo     string `json:"log_fifo,omitempty"`
	MetricsFifo string `json:"metrics_fifo,omitempty"`
	Level       string `json:"level,omitempty"`
}

// NetDev is the minimal information needed to attach a network device to a VM
type NetDev struct {
	ID       string `json:"iface_id,omitempty"`
	GuestMAC string `json:"guest_mac,omitempty"`
	HostDev  string `json:"host_dev_name,omitempty"`
}

const commonArgs = "panic=1 pci=off reboot=k tsc=reliable ipv6.disable=1 init=/init"

// Config is a full configuration of a VM (used for config file based start)
type Config struct {
	Machine    Machine    `json:"machine-config,omitempty"`
	BootSource BootSource `json:"boot-source,omitempty"`
	Drives     []Drive    `json:"drives,omitempty"`
	NetDevs    []NetDev   `json:"network-interfaces,omitempty"`
}

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
	outOpt := flag.String("o", "", "Path to output file for config")

	kernelOpt := flag.String("k", "../img/boot-time-vmlinux", "Path to the kernel image")
	rootfsOpt := flag.String("r", "../img/boot-time-disk.img", "Path to the root disk")
	coresOpt := flag.Int("c", 1, "Number of cores for the VM")
	memOpt := flag.Int("m", 256, "Amount of memory in MB")
	diskOpt := flag.String("disk", "", "Path to additional disk")
	netOpt := flag.String("n", "", "Network configuration 'tap,tap ip,mac,vm ip,mask'")
	logOpt := flag.String("l", "", "Logger and Metric fifos. comma separated")

	debugOpt := flag.Bool("d", false, "Enable debug output")

	flag.Parse()

	if *socketOpt == "" && *outOpt == "" {
		panic("-s or -o required")
	}
	if *socketOpt != "" && *outOpt != "" {
		panic("Either specify -s or -o, bit not both")
	}

	config := Config{}

	machine := Machine{
		VCPUs:       *coresOpt,
		Memory:      *memOpt,
		CPUTemplate: "T2",
		HyperThread: true,
	}
	config.Machine = machine
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
			ID:       "1",
			GuestMAC: netCfg[2],
			HostDev:  netCfg[0],
		}
		config.NetDevs = append(config.NetDevs, netDev)
		b, err := json.Marshal(netDev)
		if err != nil {
			panic(err)
		}
		netJSON = string(b)

		netArgs = " ip=" + netCfg[3] + "::" + netCfg[1] + ":" + netCfg[4] + "::eth0:off"
	}

	boot := BootSource{
		Path: *kernelOpt,
	}
	if *debugOpt {
		boot.Args = commonArgs + netArgs + " console=ttyS0"
	} else {
		boot.Args = commonArgs + netArgs + " quiet 8250.nr_uarts=0"
	}
	config.BootSource = boot
	b, err = json.Marshal(boot)
	if err != nil {
		panic(err)
	}
	bootJSON := string(b)

	drive := Drive{
		ID:           "1",
		Path:         *rootfsOpt,
		IsRootDevice: true,
		IsReadOnly:   true,
	}
	config.Drives = append(config.Drives, drive)
	b, err = json.Marshal(drive)
	if err != nil {
		panic(err)
	}
	driveJSON := string(b)

	var diskJSON string
	if *diskOpt != "" {
		disk := Drive{
			ID:           "2",
			Path:         *diskOpt,
			IsRootDevice: false,
			IsReadOnly:   false,
		}
		config.Drives = append(config.Drives, drive)
		b, err = json.Marshal(disk)
		if err != nil {
			panic(err)
		}
		diskJSON = string(b)
	}

	var loggerJSON string
	if *logOpt != "" {
		logCfg := strings.SplitN(*logOpt, ",", 2)
		if len(logCfg) != 2 {
			panic("Logger config")
		}
		logger := Logger{
			LogFifo:     logCfg[0],
			MetricsFifo: logCfg[1],
			Level:       "Info",
		}
		b, err = json.Marshal(logger)
		if err != nil {
			panic(err)
		}
		loggerJSON = string(b)
	}

	// Write the config to a file if requested
	if *outOpt != "" {
		b, err := json.Marshal(config)
		if err != nil {
			panic(err)
		}
		if err := ioutil.WriteFile(*outOpt, b, 0644); err != nil {
			panic(err)
		}
		return
	}

	client := newClient(*socketOpt)
	if err := fcAPI(client, "machine-config", machineJSON); err != nil {
		panic(err)
	}
	if err := fcAPI(client, "drives/1", driveJSON); err != nil {
		panic(err)
	}
	if err := fcAPI(client, "boot-source", bootJSON); err != nil {
		panic(err)
	}
	if loggerJSON != "" {
		if err := fcAPI(client, "logger", loggerJSON); err != nil {
			panic(err)
		}
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
