{{ range $upstream, $servers := groupBy . "Type" }}
upstream {{$upstream}} {
{{ range $servers }}  server {{.Host}}:{{.Port}};
{{ end }}}
{{ end }}