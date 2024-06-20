# zammad-macros
This is a set of scripts to replay configurations done in a Zammad instances
based of what has been logged in a `production.log`. Either by generating a
bash script with a bunch of `curl` commands or with a zapi script that can be
replayed with `run-zapi.rb`.

⚠️ Always check the scripts before you run them. Id's may be different in the
target system!

## read-production.log.rb

Run ./read-production.log.rb to parse your production.log and output a bash or
zapi script.

```bash
./read-production.log.rb <bash or zapi> <bash:host> <bash:api-token> <optional:path/to/poduction.log>
```

### Examples

Bash example:

```bash
./read-production.log.rb bash http://localhost token123 > my-script.sh
```

Zapi example:

```bash
./read-production.log.rb zapi > my-script.zapi
```

## run-zapi.rb (not included yet)

Run ./run-zapi.rb to execute a zapi script.

```
./run-zapi.rb <script.zapi> <host> <api-token>
```

# ⚠️ DANGER ZONE ⚠️

The whole idea of this project is just a proof of concept (yet). Don't use that
in any productive environment without knowing exactly what is happening here!