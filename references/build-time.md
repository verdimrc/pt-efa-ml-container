# Build time <!-- omit in toc -->

Measured with `docker/build.sh`.

Instance: g4dn.8xlarge, us-east-1, EBS gp3 with 10k IOPS and 1k MB/s throughput.

| Variant     | Image build time     | Apex build time+ | Image size |
| ------------| -------------------- | ---------------- | ---------- |
| pt-apex:std | 39m                  | 23m              | 11.6 GB    |
| pt-apex:opt | 42m\* / 1h:24m\*\*   | 42m              | 11.8 GB    |

+See `/build-time-apex.txt` inside the container.
\*Docker images already has `pt-apex:std`.
\*\*With EBS 3k IOPS and 125 MB/s throughput, all layers built.

NCCL compilation takes 5.5m (see `/build-time-nccl.txt` inside the container)
