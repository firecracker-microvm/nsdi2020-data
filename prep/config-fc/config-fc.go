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
)

type Machine struct {
	VCPUs       int    `json:"vcpu_count,omitempty"`
	Memory      int    `json:"mem_size_mib,omitempty"`
	CPUTemplate string `json:"cpu_template,omitempty"`
	HyperThread bool   `json:"ht_enabled,omitempty"`
}

type Kernel struct {
	ImagePath string `json:"kernel_image_path,omitempty"`
	BootArgs  string `json:"boot_args,omitempty"`
}

type Drive struct {
	DriveId      string `json:"drive_id,omitempty"`
	Path         string `json:"path_on_host,omitempty"`
	IsRootDevice bool   `json:"is_root_device,omitempty"`
	IsReadOnly   bool   `json:"is_read_only,omitempty"`
}

const commonArgs = "panic=1 pci=off reboot=k tsc=reliable ipv6.disable=1 init=/init"

const start_json = `{
    "action_type": "InstanceStart"
}`

func make_client(socket string) *http.Client {
	return &http.Client{
		Transport: &http.Transport{
			DialContext: func(_ context.Context, _, _ string) (net.Conn, error) {
				return net.Dial("unix", socket)
			},
		},
	}
}

func fc_api(client *http.Client, path, body string) error {
	uri := fmt.Sprintf("http://localhost/%s", path)
	body_buf := bytes.NewBuffer([]byte(body))
	req, e := http.NewRequest(http.MethodPut, uri, body_buf)
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
	machine_json := string(b)

	kernel := Kernel{
		ImagePath: *kernelOpt,
	}
	if *debugOpt {
		kernel.BootArgs = commonArgs + " console=ttyS0"
	} else {
		kernel.BootArgs = commonArgs + " quiet 8250.nr_uarts=0"
	}

	b, err = json.Marshal(kernel)
	if err != nil {
		panic(err)
	}
	kernel_json := string(b)

	drive := Drive{
		DriveId:      "1",
		Path:         *rootfsOpt,
		IsRootDevice: true,
		IsReadOnly:   true,
	}
	b, err = json.Marshal(drive)
	if err != nil {
		panic(err)
	}
	drive_json := string(b)

	client := make_client(*socketOpt)
	if err := fc_api(client, "machine-config", machine_json); err != nil {
		panic(err)
	}
	if err := fc_api(client, "drives/1", drive_json); err != nil {
		panic(err)
	}
	if err := fc_api(client, "boot-source", kernel_json); err != nil {
		panic(err)
	}
	if err := fc_api(client, "actions", start_json); err != nil {
		panic(err)
	}
}
