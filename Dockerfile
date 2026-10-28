FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package.json ./
# Після першого npm install закомітьте package-lock.json і замініть на `npm ci --omit=dev`
RUN npm install --omit=dev && npm cache clean --force
COPY . .
RUN mkdir -p /data/uploads && chown -R node:node /app /data
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://127.0.0.1:3000/api/health || exit 1
CMD ["node", "src/server.js"]
