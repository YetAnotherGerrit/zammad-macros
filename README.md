# ⚠️ DANGER ZONE ⚠️

The whole idea of this project is just a proof of concept (yet). Don't use that
in any productive environment without knowing exactly what is happening here!

# zammad-macros
This is a set of scripts to replay configurations done in a Zammad instances
based of what has been logged in a `production.log`.

⚠️ Always check the scripts before you run them. Id's may be different in the
target system!

## read-production.log.rb

Run read-production.log.rb to parse your production.log and output a zapi
script.

```bash
./read-production.log.rb <optional:path/to/poduction.log>
```

### Examples

```bash
./read-production.log.rb zapi > my-script.zapi
```

## run-zapi.rb

Run run-zapi.rb to execute a zapi script.

```
./run-zapi.rb <my-script.zapi> <host> <api-token>
```