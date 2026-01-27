FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# 只有在 package-lock.json 存在时才一起复制
COPY package.json package-lock.json* ./
RUN npm install --frozen-lockfile || npm install

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 禁用 Next.js 遥测数据
ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# 仅复制构建产物和必要的运行文件
# 注意：如果项目中没有 public 文件夹，这一步会报错，所以我们改为按需复制或者忽略
# 由于 Next.js 14+ 推荐使用 standalone 模式，但这里我们先采用简单修复
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

USER nextjs

EXPOSE 3000

ENV PORT=3000

CMD ["npm", "start"]
