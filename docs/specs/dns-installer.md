# DNS installer specification

## Problem Statement

DNS is currently deployed through the generic service/CI structure. The desired
workflow is a single Podman-run installer dedicated only to DNS. It must deploy
Pi-hole to both homelab hosts without copying Compose files or application
files to either host.

## Solution

Build one local installer container and run it with Podman Compose. The
installer connects to the Docker Engine API on both `onyx` and `ruby` over TCP
port `2375`, pulls `pihole/pihole:latest`, and creates or replaces the Pi-hole
container through the API.

Both hosts remain active DNS servers. They use the existing shared GlusterFS
storage and therefore see identical Pi-hole configuration and data. The
installer processes `onyx` first and stops immediately if that host is
unavailable or its deployment fails.

## User Stories

1. As a homelab operator, I want one DNS-specific installer, so that I do not
   need to use the generic deployment playbook manually.
2. As a homelab operator, I want to start the installer with Podman Compose,
   so that the local machine only needs Podman and the repository secrets.
3. As a homelab operator, I want the installer image built locally, so that the
   installation logic is reproducible and isolated from the host environment.
4. As a homelab operator, I want the installer to target both `onyx` and
   `ruby`, so that both DNS endpoints are configured consistently.
5. As a homelab operator, I want the installer to use Docker Engine API, so
   that no Compose files or application files need to be copied to servers.
6. As a homelab operator, I want Pi-hole to be pulled by the remote Docker
   Engine, so that the installer remains small and does not package Pi-hole.
7. As a homelab operator, I want repeated installer runs to be safe, so that
   an existing DNS container is updated without manual cleanup.
8. As a homelab operator, I want existing Pi-hole volumes preserved, so that
   configuration, lists, and statistics are not lost during recreation.
9. As a homelab operator, I want both DNS containers active simultaneously,
   so that either host can answer DNS requests.
10. As a homelab operator, I want both containers to use the existing shared
    storage, so that their Pi-hole state remains synchronized by GlusterFS.
11. As a homelab operator, I want the current image, ports, environment, and
    volume mappings retained, so that the DNS service behavior does not change.
12. As a homelab operator, I want the installer to use the existing `secrets/`
    convention, so that SSH credentials are not committed to the repository.
13. As a homelab operator, I want a clear health check for each Docker API,
    so that network or daemon problems are reported before deployment.
14. As a homelab operator, I want the installer to stop on the first failed
    host, so that a partial DNS rollout is never presented as successful.
15. As a homelab operator, I want the README to show the default command and
    prerequisites, so that installation does not require tribal knowledge.
16. As a CI maintainer, I want the existing CI playbook preserved, so that
    current validation and deployment workflows are not silently changed.

## Implementation Decisions

- The installer is a dedicated Podman-built container, separate from the
  generic DNS deployment playbook.
- The installer exposes one entrypoint that processes hosts in deterministic
  order: `onyx`, then `ruby`.
- Docker Engine API communication uses TCP port `2375` without TLS, as
  explicitly selected for this homelab. The README must warn that this grants
  unauthenticated Docker control to clients able to reach the port.
- The Docker API endpoint must be reachable before the installer starts. The
  installer verifies connectivity and reports the required host and port when
  unavailable; configuring the Docker daemon listener is outside this slice.
- The remote container uses image `pihole/pihole:latest`.
- The remote container keeps the existing name, ports, environment, restart
  policy, network, and Gluster-backed volume mappings.
- Deployment is idempotent: inspect the existing container, pull the image,
  recreate it when configuration or image state requires it, and preserve
  volumes.
- No service source files, Compose files, or generated application bundles are
  copied to either host.
- SSH private-key material is read from the existing `secrets/` mount only.
- The existing CI playbook remains available and is not replaced by this
  installer.
- The installer reports each host's result and exits non-zero on the first
  failure.

## Testing Decisions

- Test the installer at its highest seam: the installer container entrypoint
  against a mocked Docker Engine API.
- Tests cover API reachability, image pull, container creation, existing
  container replacement, volume preservation, host ordering, and fail-fast
  behavior.
- Tests assert external API calls and final outcomes, not helper function
  structure or shell implementation details.
- Existing Compose validation remains the CI syntax check for the service
  definition.
- A smoke check after deployment verifies that both target containers are
  running and that the configured DNS ports are published.

## Out of Scope

- Enabling or securing Docker API listeners on the target hosts.
- TLS, authentication, or remote Docker access outside the trusted homelab
  network.
- Pi-hole configuration synchronization beyond the existing GlusterFS mount.
- Conflict resolution for simultaneous writes to Pi-hole databases on the
  shared filesystem.
- Changes to K3s, NFS, GlusterFS, or the generic service playbook.
- A web UI, REST API, or long-running installer service.

## Further Notes

Both Pi-hole containers are intentionally active while sharing replicated
storage. This is an explicit operational choice. SQLite locking and database
integrity under concurrent writes must be observed after deployment.
