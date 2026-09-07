# Multi-stage: build the React app, then serve it with nginx.
# Self-hosters never need Node locally — `docker compose up` builds everything.
#
# --platform=$BUILDPLATFORM pins the build stage to the host's native arch even when
# cross-building for other targets (e.g. amd64 host building an arm64 image). The build
# output (static JS/CSS/HTML) is arch-independent, so there's no reason to run it under
# QEMU — and QEMU-emulated npm installs are known to corrupt esbuild/rollup's platform-
# specific native binaries, which is what breaks `vite build` with unrelated-looking
# module-resolution errors.
FROM --platform=$BUILDPLATFORM node:22-alpine AS build
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm ci 2>/dev/null || npm install
COPY frontend/ ./
RUN npm run build

# Unprivilegiertes nginx-Image (07.09.2026):
# Dockup startet den Container nicht als root. Das offizielle nginx:alpine
# will beim Start /var/cache/nginx/* auf uid 101 umschreiben und scheitert
# daran ("chown ... Operation not permitted") -> Dauer-Restart, 502.
# nginxinc/nginx-unprivileged laeuft als uid 101, ueberspringt genau diese
# chown-Schritte und legt pid/temp unter /tmp ab.
# Pfade bleiben identisch: /etc/nginx/conf.d/default.conf und
# /usr/share/nginx/html. Nur der Default-Port ist 8080 statt 80 - irrelevant,
# weil web/nginx.conf ohnehin "listen 3000" setzt (>1024, also ohne
# root-Rechte bindbar).
FROM nginxinc/nginx-unprivileged:alpine
COPY web/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 3000
# exercise media (img/gif) is mounted at runtime from the media volume
