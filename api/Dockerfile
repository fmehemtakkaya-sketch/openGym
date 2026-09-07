# Build-Context ist das Repo-Root, nicht api/.
# Dockup kennt nur "dockerfile: <pfad>", keinen eigenen Context — gebaut wird
# immer vom Repo-Root aus. Deshalb sind die COPY-Pfade mit "api/" praefixiert.
# docker-compose.yml setzt denselben Context, damit lokal und auf Dockup
# dasselbe Image entsteht.
FROM node:22-alpine
WORKDIR /app
COPY api/package.json api/package-lock.json* ./
RUN npm install --omit=dev && npm cache clean --force
COPY api/server.js ./
ENV NODE_ENV=production
EXPOSE 3000

# Dockup startet Container nicht als root (siehe Kommentar im Root-Dockerfile).
# Ohne festen USER waere die uid unbestimmt und das /data-Volume — Nutzer,
# Passkeys, Sitzungsschluessel — nicht beschreibbar. "node" ist im offiziellen
# node-Image uid/gid 1000; genau darauf steht der Owner des Dockup-Volumes.
USER node
CMD ["node", "server.js"]
