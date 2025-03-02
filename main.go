package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"

	"github.com/godbus/dbus/v5"
)

func main() {
	// Check if the whipper command is provided
	if len(os.Args) < 2 {
		log.Fatalf("Command is required")
	}

	// whipper cd rip --offset 6 --cover-art complete --working-directory /mnt/music/process
	whipperCommand := os.Args[1]
	fmt.Println("Executing on CD insert: ", whipperCommand)

	conn, err := dbus.SystemBus()
	if err != nil {
		log.Fatalf("Failed to connect to system bus: %v", err)
	}

	signal := make(chan *dbus.Signal, 10)
	conn.Signal(signal)

	match := "type='signal',interface='org.freedesktop.systemd1.Manager'"
	call := conn.BusObject().Call("org.freedesktop.DBus.AddMatch", 0, match)
	if call.Err != nil {
		log.Fatalf("Failed to add match rule: %v", call.Err)
	}

	fmt.Println("Listening for dev-sr0.device events...")
	for s := range signal {
		if len(s.Body) > 0 {
			devicePath, ok := s.Body[0].(string)
			if ok && devicePath == "dev-sr0.device" {
				switch s.Name {
				case "org.freedesktop.systemd1.Manager.UnitNew":
					fmt.Println("Insert")
					// Execute the whipperCommand on Insert
					cmd := exec.Command("sh", "-c", whipperCommand)
					stdout, err := cmd.StdoutPipe()
					if err != nil {
						log.Fatalf("Failed to get stdout pipe: %v", err)
					}
					stderr, err := cmd.StderrPipe()
					if err != nil {
						log.Fatalf("Failed to get stderr pipe: %v", err)
					}

					if err := cmd.Start(); err != nil {
						log.Fatalf("Failed to start command: %v", err)
					}

					go func() {
						scanner := bufio.NewScanner(stdout)
						for scanner.Scan() {
							fmt.Println(scanner.Text())
						}
					}()

					go func() {
						scanner := bufio.NewScanner(stderr)
						for scanner.Scan() {
							fmt.Println(scanner.Text())
						}
					}()

					if err := cmd.Wait(); err != nil {
						log.Fatalf("Command execution failed: %v", err)
					}
				case "org.freedesktop.systemd1.Manager.UnitRemoved":
					fmt.Println("Eject")
				}
			}
		}
	}
}
