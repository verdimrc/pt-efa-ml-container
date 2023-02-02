# Build time <!-- omit in toc -->

Instance: g4dn.8xlarge, us-east-1, EBS gp3 with 3k IOPS and 125 MB/s throughput.

| Variant           | Image build time | Apex build time\* |
| ----------------- | ---------------- | ----------------- |
| Apex: Amr's flags | 1h:24m           |                   |
| Apex: DLC's flags |                  |                   |

\*: see `/build-time-apex.txt` inside the container.

Image size:

```console
$ docker images
asdf
```
