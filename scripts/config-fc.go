package main

// Perform very basic configuration of a Firecracker VM by calling its API over a Unix socket.
// This does a subset of what the bash implementation in start-fc.sh does, but cuts off ~50ms
//  by avoiding starting 'curl' repeatedly.

import (
	"bytes"
	"context"
	"fmt"
	"net"
	"net/http"
	"os"
)

const machine_json = `{
    "vcpu_count": 1,
    "mem_size_mib": 256,
    "cpu_template": "T2",
    "ht_enabled": true
}`

const kernel_json = `{
  "kernel_image_path": "../img/boot-time-vmlinux",
  "boot_args": "panic=1 pci=off reboot=k tsc=reliable ipv6.disable=1 init=/init quiet 8250.nr_uarts=0"
}`

const drive_json = `{
  "drive_id": "1",
  "path_on_host": "../img/boot-time-disk.img",
  "is_root_device": true,
  "is_read_only": true
}`

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
	client := make_client(os.Args[1])
	if e := fc_api(client, "machine-config", machine_json); e != nil {
		panic(e)
	}
	if e := fc_api(client, "drives/1", drive_json); e != nil {
		panic(e)
	}
	if e := fc_api(client, "boot-source", kernel_json); e != nil {
		panic(e)
	}
	if e := fc_api(client, "actions", start_json); e != nil {
		panic(e)
	}
}
