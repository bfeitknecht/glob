# `infra/` — go-live runbook (disposable)

Everything in this directory exists for one reason: to get `blog.0xbf.ch` running on
`bfeitknecht/infra`. **Delete `infra/` once the site is live** — nothing else in this repository
depends on it (`site.typ`, `posts/`, `fonts/`, `vendor/`, the `Dockerfile`, and the workflows are
self-contained; `.dockerignore` already excludes this directory from the image).

| File | Purpose |
| --- | --- |
| `glob/namespace.yaml` | `glob` namespace |
| `glob/deployment.yaml` | 1 replica, `:latest`, read-only rootfs, non-root, Keel `poll`/`force` annotations |
| `glob/service.yaml` | ClusterIP `glob:80` → container `8080` |
| `glob/httproute.yaml` | `blog.0xbf.ch` on `traefik-gateway` (`websecure`) |
| `glob/serviceaccount.yaml` | default SA with the `dockerconfigjson` pull secret |
| `glob/kustomization.yaml` | resource list (expects a `ghcr.sops.yaml` you create in `infra`) |
| `applications-entry.yaml` | Flux `Kustomization` to append to `kubernetes/cluster/applications.yaml` |

## Steps

1. **Publish an image first** — the manifests point at `ghcr.io/bfeitknecht/glob:latest`, and Keel
   cannot roll a tag that does not exist yet. From this repository:
   ```sh
   just build          # optional local check of the exact container build
   just release v0.1.0 "initial release"
   ```
   The `v*` tag triggers `publish-image.yaml` → `linux/amd64,linux/arm64` image. To republish the
   current `HEAD` without burning a tag: `gh workflow run publish-image.yaml`.

2. **Copy the manifests** into the infra repository:
   ```sh
   cp -r glob/infra/glob <infra>/kubernetes/applications/glob
   ```

3. **Create the pull secret** (`kustomization.yaml` expects it, so the copy in step 2 will not
   reconcile until this file exists):
   ```sh
   sops -d kubernetes/applications/apex/ghcr.sops.yaml \
     | sed 's/namespace: apex/namespace: glob/' \
     > kubernetes/applications/glob/ghcr.sops.yaml
   sops -e -i kubernetes/applications/glob/ghcr.sops.yaml
   ```

4. **Register the Flux application**: append `glob/infra/applications-entry.yaml` to
   `kubernetes/cluster/applications.yaml`. It keeps `spec.ignore` on
   `/spec/template/spec/containers/0/image` so Flux does not fight Keel over the tag.

5. **Commit and push infra**, then verify:
   ```sh
   kubectl -n glob get deploy,pod
   kubectl -n glob logs deploy/glob --tail 20
   curl -sI https://blog.0xbf.ch | head -3          # 200, text/html
   curl -s  https://blog.0xbf.ch/rss.xml | head -2  # feed present
   ```
   Wildcard DNS (`*.0xbf.ch`) and `wildcard-domain-tls` on `traefik-gateway` already cover the host,
   so no DNS or certificate work is needed.

6. **After go-live**: `git rm -r infra/` here, drop this section from the README, and commit. From
   then on, deploying is `just release vX.Y.Z "…"` + Keel.

## Notes

- The Deployment pins `:latest` on purpose; Keel follows the digest (`keel.sh/policy: force`,
  `match-tag: "true"`).
- `ghcr.sops.yaml` is **never** committed to this repository — it is derived from the `apex` secret
  inside infra.
- Typst bundles are immutable per build, so a rollback is a revert + new tag, not a pod edit.
