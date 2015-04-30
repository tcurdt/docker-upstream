package main

import (
  "os"
  "log"
  "bytes"
  "strings"
  "io/ioutil"
  "crypto/sha1"
  "path/filepath"
  "text/template"
  dockerapi "github.com/fsouza/go-dockerclient"
  flags "github.com/jessevdk/go-flags"
)

type Upstream struct {
  Name string
  Type string
  Host string
  Port string
}

type Options struct {
  Follow bool `short:"f" long:"follow" description:""`
  Docker string `short:"d" long:"docker" description:"connection to docker" default:"unix:///var/run/docker.sock"`
  Reload []string `long:"reload" description:"reload container on config change"`
  Restart []string `long:"restart" description:"restart container on config change"`
  Template flags.Filename `short:"t" long:"template" description:"template for config" required:"true"`
  Output flags.Filename `short:"o" long:"output" description:"filename for output" required:"true"`
}

var options Options
var config_hash_old []byte

func upstream_ports(list string) []string {
  ports := strings.Split(list, ",")
  for i, s := range ports { ports[i] = s + "/tcp" }
  return ports
}

func signal_container(client *dockerapi.Client, container *dockerapi.Container, signal dockerapi.Signal) {

  killOpts := dockerapi.KillContainerOptions{
    ID: container.ID,
    Signal: signal,
  }

  err := client.KillContainer(killOpts)
  if err != nil {
    log.Fatal("fatal: error sending signal to container: %s", err)
  }
}


func write_output_from_template(templatePath string, upstreams []*Upstream, output *bytes.Buffer) {

  tmpl, err := template.New(filepath.Base(templatePath)).Funcs(template.FuncMap{
    "groupBy": groupBy,
    }).ParseFiles(templatePath)
  if err != nil {
    log.Fatal("fatal: unable to parse template", err)
  }
  err = tmpl.ExecuteTemplate(output, filepath.Base(templatePath), upstreams)
  if err != nil {
    log.Fatal("fatal: unable to apply template", err)
  }
}


func update(client *dockerapi.Client) {

  upstreams := []*Upstream{}

  items, err := client.ListContainers(dockerapi.ListContainersOptions{})
  assert(err)

  containers_to_reload := []*dockerapi.Container{}
  containers_to_restart := []*dockerapi.Container{}

  for _, item := range items {

    container, err := client.InspectContainer(item.ID)
    if err != nil {
      log.Fatal("fatal: unable to inspect container:", item.ID[:12], err)
    }

    name := strings.TrimPrefix(container.Name, "/")

    if matches(name, options.Reload) {
      containers_to_reload = append(containers_to_reload, container)
    }

    if matches(name, options.Restart) {
      containers_to_restart = append(containers_to_restart, container)
    }

    if container.State.Running {
      // running container

      label := container.Config.Labels["org.vafer.upstream"]

      if label != "" {
        // upstream label found, extract ports

        ports := upstream_ports(label)

        for port,bindings := range container.HostConfig.PortBindings {
          if matches(string(port), ports) {

            // port matches, create upstream
            for _, binding := range bindings {
              upstreams = append(upstreams, &Upstream{
                Name: name,
                Type: filepath.Base(container.Config.Image),
                Host: binding.HostIp,
                Port: binding.HostPort,
              })
            }

          }
        }
      }
    }
  }

  output := bytes.Buffer{}

  write_output_from_template(string(options.Template), upstreams, &output)

  config_hash_new := sha1.Sum(output.Bytes())

  if !bytes.Equal(config_hash_old, config_hash_new[:]) {
    config_hash_old = config_hash_new[:]

    log.Println("info: new configuration file")

    err = ioutil.WriteFile(string(options.Output), output.Bytes(), 0644)
    if err != nil {
      log.Fatal("fatal: failed to save output", err)
    }

    for _, container := range containers_to_reload {
      log.Println("info: reloading ", container.Name)
      signal_container(client, container, dockerapi.SIGHUP)
    }

    for _, container := range containers_to_restart {
      log.Println("info: restarting ", container.Name)
      // TODO: SIGINT, waiting, SIGTERM, waiting, SIGKILL
      signal_container(client, container, dockerapi.SIGKILL)
    }
    
  }
}


func main() {

  parser := flags.NewParser(&options, flags.HelpFlag|flags.Default)

  _, err := parser.Parse()
  if err != nil {
    os.Exit(1)
  }

  docker, err := dockerapi.NewClient(options.Docker)
  assert(err)

  update(docker)

  if options.Follow {

    events := make(chan *dockerapi.APIEvents)
    assert(docker.AddEventListener(events))

    log.Println("info: listening for docker events...")

    for event := range events {
      _ = event
      go update(docker)
    }

    log.Fatal("fatal: docker event loop closed")
  }
}
