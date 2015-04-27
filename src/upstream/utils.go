package main

import (
  "log"
  "reflect"
  "strings"
)

func assert(err error) {
  if err != nil {
    log.Fatal("fatal: ", err)
  }
}

func matches(a string, list []string) bool {
  for _, b := range list {
    if b == a {
      return true
    }
  }
  return false
}

func stripPrefix(s, prefix string) string {
  path := s
  for {
    if strings.HasPrefix(path, ".") {
      path = path[1:]
      continue
    }
    break
  }
  return path
}

func deepGet(item interface{}, path string) interface{} {
  if path == "" {
    return item
  }

  path = stripPrefix(path, ".")
  parts := strings.Split(path, ".")
  itemValue := reflect.ValueOf(item)

  if len(parts) > 0 {
    switch itemValue.Kind() {
    case reflect.Struct:
      fieldValue := itemValue.FieldByName(parts[0])
      if fieldValue.IsValid() {
        return deepGet(fieldValue.Interface(), strings.Join(parts[1:], "."))
      }
    case reflect.Map:
      mapValue := itemValue.MapIndex(reflect.ValueOf(parts[0]))
      if mapValue.IsValid() {
        return deepGet(mapValue.Interface(), strings.Join(parts[1:], "."))
      }
    default:
      log.Printf("can't group by %s\n", path)
    }
    return nil
  }

  return itemValue.Interface()
}

func groupBy(entries []*Upstream, key string) map[string][]*Upstream {
  groups := make(map[string][]*Upstream)
  for _, v := range entries {
    value := deepGet(*v, key)
    if value != nil {
      groups[value.(string)] = append(groups[value.(string)], v)
    }
  }
  return groups
}
